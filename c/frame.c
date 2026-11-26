// abstraction-provenance: {"artifact_sha256": "90428b12d24d8eedfa2aadc57ed49e91b783f8b7860e7a138c358c9d608cab15", "source_sha256": "b339455e9e618c836ccf2e3732e4fec9897f079730d8814eadb716e2459df453", "target_language": "c"}
// frame.sh — portiert nach c
// Quelle: shell, OpenClaw@gateway1:skills/video-frames/scripts/frame.sh
// auch in: OpenClaw@gateway2:skills/video-frames/scripts/frame.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/wait.h>

void usage() {
    fprintf(stderr, "Usage:\n");
    fprintf(stderr, "  frame <video-file> [--time HH:MM:SS] [--index N] --out /path/to/frame.jpg\n\n");
    fprintf(stderr, "Examples:\n");
    fprintf(stderr, "  frame video.mp4 --out /tmp/frame.jpg\n");
    fprintf(stderr, "  frame video.mp4 --time 00:00:10 --out /tmp/frame-10s.jpg\n");
    fprintf(stderr, "  frame video.mp4 --index 0 --out /tmp/frame0.png\n");
    exit(2);
}

int file_exists(const char *filename) {
    struct stat buffer;
    return (stat(filename, &buffer) == 0);
}

char* dirname(const char *path) {
    char *result = strdup(path);
    char *last_slash = strrchr(result, '/');
    if (last_slash != NULL) {
        *last_slash = '\0';
    } else {
        strcpy(result, ".");
    }
    return result;
}

void mkdir_p(const char *dir) {
    char *path = strdup(dir);
    char *p = path;
    
    while (*p) {
        if (*p == '/') {
            *p = '\0';
            if (strlen(path) > 0) {
                mkdir(path, 0755);
            }
            *p = '/';
        }
        p++;
    }
    
    if (strlen(path) > 0) {
        mkdir(path, 0755);
    }
    
    free(path);
}

int main(int argc, char *argv[]) {
    if (argc < 2 || strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0) {
        usage();
    }

    const char *in = argv[1];
    char *time = NULL;
    char *index = NULL;
    char *out = NULL;

    int i = 2;
    while (i < argc) {
        if (strcmp(argv[i], "--time") == 0 && i + 1 < argc) {
            time = argv[i + 1];
            i += 2;
        } else if (strcmp(argv[i], "--index") == 0 && i + 1 < argc) {
            index = argv[i + 1];
            i += 2;
        } else if (strcmp(argv[i], "--out") == 0 && i + 1 < argc) {
            out = argv[i + 1];
            i += 2;
        } else {
            fprintf(stderr, "Unknown arg: %s\n", argv[i]);
            usage();
        }
    }

    if (!file_exists(in)) {
        fprintf(stderr, "File not found: %s\n", in);
        exit(1);
    }

    if (out == NULL) {
        fprintf(stderr, "Missing --out\n");
        usage();
    }

    char *outdir = dirname(out);
    mkdir_p(outdir);
    free(outdir);

    char *ffmpeg_cmd[20];
    int cmd_index = 0;

    ffmpeg_cmd[cmd_index++] = "ffmpeg";
    ffmpeg_cmd[cmd_index++] = "-hide_banner";
    ffmpeg_cmd[cmd_index++] = "-loglevel";
    ffmpeg_cmd[cmd_index++] = "error";
    ffmpeg_cmd[cmd_index++] = "-y";

    if (index != NULL) {
        ffmpeg_cmd[cmd_index++] = "-i";
        ffmpeg_cmd[cmd_index++] = (char *)in;
        ffmpeg_cmd[cmd_index++] = "-vf";
        
        char select_filter[100];
        snprintf(select_filter, sizeof(select_filter), "select=eq(n\\,%s)", index);
        ffmpeg_cmd[cmd_index++] = strdup(select_filter);
        
        ffmpeg_cmd[cmd_index++] = "-vframes";
        ffmpeg_cmd[cmd_index++] = "1";
        ffmpeg_cmd[cmd_index++] = out;
        ffmpeg_cmd[cmd_index] = NULL;
    } else if (time != NULL) {
        ffmpeg_cmd[cmd_index++] = "-ss";
        ffmpeg_cmd[cmd_index++] = time;
        ffmpeg_cmd[cmd_index++] = "-i";
        ffmpeg_cmd[cmd_index++] = (char *)in;
        ffmpeg_cmd[cmd_index++] = "-frames:v";
        ffmpeg_cmd[cmd_index++] = "1";
        ffmpeg_cmd[cmd_index++] = out;
        ffmpeg_cmd[cmd_index] = NULL;
    } else {
        ffmpeg_cmd[cmd_index++] = "-i";
        ffmpeg_cmd[cmd_index++] = (char *)in;
        ffmpeg_cmd[cmd_index++] = "-vf";
        ffmpeg_cmd[cmd_index++] = "select=eq(n\\,0)";
        ffmpeg_cmd[cmd_index++] = "-vframes";
        ffmpeg_cmd[cmd_index++] = "1";
        ffmpeg_cmd[cmd_index++] = out;
        ffmpeg_cmd[cmd_index] = NULL;
    }

    pid_t pid = fork();
    if (pid == 0) {
        execvp("ffmpeg", ffmpeg_cmd);
        perror("execvp failed");
        exit(1);
    } else if (pid > 0) {
        int status;
        waitpid(pid, &status, 0);
        if (WIFEXITED(status) && WEXITSTATUS(status) != 0) {
            exit(WEXITSTATUS(status));
        }
    } else {
        perror("fork failed");
        exit(1);
    }

    printf("%s\n", out);
    
    // Free allocated memory for select filter if used
    if (index != NULL) {
        free(ffmpeg_cmd[8]);
    }

    return 0;
}
