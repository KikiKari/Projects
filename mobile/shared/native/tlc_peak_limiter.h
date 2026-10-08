#ifndef TLC_PEAK_LIMITER_H
#define TLC_PEAK_LIMITER_H

/* Streaming counterpart of content-core.js createPeakLimiter.
 * The owner serializes reset/process; no allocation occurs in process.
 * Interleaved float PCM, linked channels, 5 ms lookahead, 60 ms release.
 */
#include <math.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    unsigned rate, channels, delay, size, queue_size, head, tail;
    uint64_t clock;
    double gain, release;
    float *samples, *peaks;
    uint64_t *times;
} tlc_peak_limiter;

typedef struct {
    double input_dbfs, output_dbfs, reduction_db, lookahead_ms;
} tlc_peak_report;

static inline double tlc_peak_db(double value) {
    return value > 0 ? fmax(-100, 20 * log10(value)) : -100;
}

static inline void tlc_peak_destroy(tlc_peak_limiter *p) {
    if (!p) return;
    free(p->samples); free(p->peaks); free(p->times); free(p);
}

static inline tlc_peak_limiter *tlc_peak_create(unsigned rate, unsigned channels) {
    if (rate < 8000 || rate > 192000 || channels < 1 || channels > 8) return NULL;
    tlc_peak_limiter *p = (tlc_peak_limiter *)calloc(1, sizeof(*p));
    if (!p) return NULL;
    p->rate = rate; p->channels = channels;
    p->delay = (unsigned)floor(rate * 0.005 + 0.5);
    p->size = p->delay + 1; p->queue_size = p->size + 1;
    p->gain = 1; p->release = exp(-1.0 / (rate * 0.06));
    p->samples = (float *)calloc(p->size * channels, sizeof(float));
    p->peaks = (float *)calloc(p->queue_size, sizeof(float));
    p->times = (uint64_t *)calloc(p->queue_size, sizeof(uint64_t));
    if (!p->samples || !p->peaks || !p->times) { tlc_peak_destroy(p); return NULL; }
    return p;
}

static inline void tlc_peak_reset(tlc_peak_limiter *p) {
    memset(p->samples, 0, p->size * p->channels * sizeof(float));
    p->head = p->tail = 0; p->clock = 0; p->gain = 1;
}

/* input and output may alias. Feed delay zero frames to drain the last samples. */
static inline tlc_peak_report tlc_peak_process(tlc_peak_limiter *p,
        const float *input, float *output, unsigned frames, int enabled, double strength) {
    double in_peak = 0, out_peak = 0, min_gain = 1;
    if (!isfinite(strength)) strength = 0;
    double ceiling = pow(10, (-4 - fmax(0, fmin(100, strength)) * 0.26) / 20);
    for (unsigned i = 0; i < frames; ++i, ++p->clock) {
        double peak = 0;
        unsigned write = (unsigned)(p->clock % p->size) * p->channels;
        for (unsigned c = 0; c < p->channels; ++c) {
            float sample = input ? input[i * p->channels + c] : 0;
            if (!isfinite(sample)) sample = 0;
            p->samples[write + c] = sample;
            peak = fmax(peak, fabs(sample));
        }
        in_peak = fmax(in_peak, peak);
        while (p->head != p->tail && p->clock > p->delay &&
                p->times[p->head] < p->clock - p->delay)
            p->head = (p->head + 1) % p->queue_size;
        while (p->head != p->tail) {
            unsigned previous = (p->tail + p->queue_size - 1) % p->queue_size;
            if (p->peaks[previous] > peak) break;
            p->tail = previous;
        }
        p->peaks[p->tail] = (float)peak; p->times[p->tail] = p->clock;
        p->tail = (p->tail + 1) % p->queue_size;
        double target = enabled ? fmin(1, ceiling / fmax(p->peaks[p->head], 1e-12)) : 1;
        p->gain = enabled ? fmin(target, 1 - (1 - p->gain) * p->release) : 1;
        min_gain = fmin(min_gain, p->gain);
        unsigned read = p->clock >= p->delay ?
            (unsigned)((p->clock - p->delay) % p->size) * p->channels : 0;
        for (unsigned c = 0; c < p->channels; ++c) {
            double value = p->clock >= p->delay ? p->samples[read + c] * p->gain : 0;
            output[i * p->channels + c] = (float)value;
            out_peak = fmax(out_peak, fabs(value));
        }
    }
    tlc_peak_report report = {tlc_peak_db(in_peak), tlc_peak_db(out_peak),
        -tlc_peak_db(min_gain), p->delay * 1000.0 / p->rate};
    return report;
}
#endif
