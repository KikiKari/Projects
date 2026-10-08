#include <jni.h>
#include <dlfcn.h>
#include <stdatomic.h>
#include "tlc_peak_limiter.h"

/* libVLC 3 audio callback ABI. Resolve against the already loaded, pinned
 * libvlc-all AAR; do not ship a second VLC or inspect private Java fields. */
typedef void (*play_cb)(void *, const void *, unsigned, int64_t);
typedef void (*pause_cb)(void *, int64_t);
typedef void (*flush_cb)(void *, int64_t);
typedef void (*drain_cb)(void *);
typedef void (*set_callbacks_fn)(void *, play_cb, pause_cb, pause_cb, flush_cb, drain_cb, void *);
typedef void (*set_format_fn)(void *, const char *, unsigned, unsigned);
typedef int64_t (*clock_fn)(void);
typedef struct {
    JavaVM *vm;
    jobject sink;
    jmethodID write, control;
    void *library, *player;
    set_callbacks_fn callbacks;
    clock_fn clock;
    tlc_peak_limiter *limiter;
    atomic_int enabled, strength;
    float buffer[2048 * 2];
} tlc_audio;

static JNIEnv *environment(tlc_audio *s, int *attached) {
    JNIEnv *env = NULL; *attached = 0;
    if ((*s->vm)->GetEnv(s->vm, (void **)&env, JNI_VERSION_1_6) == JNI_OK) return env;
    if ((*s->vm)->AttachCurrentThread(s->vm, (void *)&env, NULL) != JNI_OK) return NULL;
    *attached = 1; return env;
}

static void finish(tlc_audio *s, JNIEnv *env, int attached) {
    /* Java sink catches output errors and reports unavailable. Never leave a
     * pending Java exception on a thread owned by VLC. */
    if ((*env)->ExceptionCheck(env)) (*env)->ExceptionClear(env);
    if (attached) (*s->vm)->DetachCurrentThread(s->vm);
}

static void deliver(tlc_audio *s, const float *input, unsigned count, int64_t pts) {
    int attached; JNIEnv *env = environment(s, &attached);
    if (!env) return;
    for (unsigned offset = 0; offset < count; ) {
        unsigned frames = count - offset; if (frames > 2048) frames = 2048;
        tlc_peak_report report = tlc_peak_process(s->limiter,
            input ? input + offset * 2 : NULL, s->buffer, frames,
            atomic_load(&s->enabled), atomic_load(&s->strength));
        jfloatArray pcm = (*env)->NewFloatArray(env, (jsize)(frames * 2));
        if (!pcm) break;
        (*env)->SetFloatArrayRegion(env, pcm, 0, (jsize)(frames * 2), s->buffer);
        (*env)->CallVoidMethod(env, s->sink, s->write, pcm,
            (jlong)(pts + offset * 1000000LL / 48000 - s->clock()),
            report.input_dbfs, report.output_dbfs, report.reduction_db);
        (*env)->DeleteLocalRef(env, pcm);
        if ((*env)->ExceptionCheck(env)) break;
        offset += frames;
    }
    finish(s, env, attached);
}

static void play(void *opaque, const void *samples, unsigned count, int64_t pts) {
    deliver((tlc_audio *)opaque, (const float *)samples, count, pts);
}
static void control(tlc_audio *s, int operation) {
    int attached; JNIEnv *env = environment(s, &attached);
    if (!env) return;
    (*env)->CallVoidMethod(env, s->sink, s->control, (jint)operation);
    finish(s, env, attached);
}
static void pause_audio(void *opaque, int64_t pts) { (void)pts; control(opaque, 0); }
static void resume_audio(void *opaque, int64_t pts) { (void)pts; control(opaque, 1); }
static void flush_audio(void *opaque, int64_t pts) {
    (void)pts; tlc_audio *s = opaque;
    tlc_peak_reset(s->limiter); control(s, 2);
}
static void drain_audio(void *opaque) {
    tlc_audio *s = opaque;
    deliver(s, NULL, s->limiter->delay, s->clock()); control(s, 3);
}

JNIEXPORT jlong JNICALL Java_app_tiktoklivecompanion_NativeVlcAudio_attach(
        JNIEnv *env, jobject self, jlong player) {
    if (!player) return 0;
    tlc_audio *s = calloc(1, sizeof(*s)); if (!s) return 0;
    s->library = dlopen("libvlc.so", RTLD_NOW | RTLD_LOCAL);
    if (!s->library) { free(s); return 0; }
    s->callbacks = (set_callbacks_fn)dlsym(s->library, "libvlc_audio_set_callbacks");
    set_format_fn format = (set_format_fn)dlsym(s->library, "libvlc_audio_set_format");
    s->clock = (clock_fn)dlsym(s->library, "libvlc_clock");
    s->limiter = tlc_peak_create(48000, 2);
    if (!s->callbacks || !format || !s->clock || !s->limiter) {
        tlc_peak_destroy(s->limiter); dlclose(s->library); free(s); return 0;
    }
    (*env)->GetJavaVM(env, &s->vm);
    jclass klass = (*env)->GetObjectClass(env, self);
    s->write = (*env)->GetMethodID(env, klass, "writePcm", "([FJDDD)V");
    s->control = (*env)->GetMethodID(env, klass, "controlOutput", "(I)V");
    (*env)->DeleteLocalRef(env, klass);
    s->sink = (*env)->NewGlobalRef(env, self);
    if (!s->write || !s->control || !s->sink) {
        if (s->sink) (*env)->DeleteGlobalRef(env, s->sink);
        tlc_peak_destroy(s->limiter); dlclose(s->library); free(s); return 0;
    }
    s->player = (void *)(intptr_t)player;
    atomic_init(&s->enabled, 0); atomic_init(&s->strength, 30);
    format(s->player, "FL32", 48000, 2);
    s->callbacks(s->player, play, pause_audio, resume_audio, flush_audio, drain_audio, s);
    return (jlong)(intptr_t)s;
}
JNIEXPORT void JNICALL Java_app_tiktoklivecompanion_NativeVlcAudio_configure(
        JNIEnv *env, jobject self, jlong handle, jboolean enabled, jint strength) {
    (void)env; (void)self; tlc_audio *s = (tlc_audio *)(intptr_t)handle;
    if (!s) return;
    atomic_store(&s->strength, strength < 0 ? 0 : strength > 100 ? 100 : strength);
    atomic_store(&s->enabled, enabled ? 1 : 0);
}
/* Caller MUST stop MediaPlayer synchronously before detach. */
JNIEXPORT void JNICALL Java_app_tiktoklivecompanion_NativeVlcAudio_detach(
        JNIEnv *env, jobject self, jlong handle) {
    (void)self; tlc_audio *s = (tlc_audio *)(intptr_t)handle; if (!s) return;
    s->callbacks(s->player, NULL, NULL, NULL, NULL, NULL, NULL);
    (*env)->DeleteGlobalRef(env, s->sink);
    tlc_peak_destroy(s->limiter); dlclose(s->library); free(s);
}
