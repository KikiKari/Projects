// abstraction-provenance: {"artifact_sha256": "fa47a174eb66a4bd27355999a24d92d123977fc466f29295c768b779068868fa", "source_sha256": "1b01ca0f5943b16d3905faf557953600ee54f15ecf1dc18c1461585eba94d376", "target_language": "c"}
// abstractions-manager-cron.sh — portiert nach c
// Quelle: shell, OpenClaw@gateway1:scripts/abstractions-manager-cron.sh
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <fcntl.h>

int main(int argc, char *argv[]) {
    // Set environment variables
    setenv("PATH", "/home/openclaw/.local/bin:/usr/local/bin:/usr/bin:/bin", 1);

    // Load environment variables from .env file
    FILE *env_file = fopen("/home/openclaw/.openclaw/.env", "r");
    if (env_file != NULL) {
        char line[256];
        while (fgets(line, sizeof(line), env_file)) {
            char *key = strtok(line, "=");
            char *value = strtok(NULL, "\n");
            if (key != NULL && value != NULL) {
                setenv(key, value, 1);
            }
        }
        fclose(env_file);
    }

    // Check if OPENROUTER_API_KEY is set
    if (getenv("OPENROUTER_API_KEY") == NULL) {
        fprintf(stderr, "OPENROUTER_API_KEY fehlt\n");
        return 1;
    }

    // Set GITHUB_TOKEN if not already set
    if (getenv("GITHUB_TOKEN") == NULL) {
        if (getenv("GH_TOKEN") != NULL) {
            setenv("GITHUB_TOKEN", getenv("GH_TOKEN"), 1);
        } else if (getenv("GH_ACCESS_TOKEN") != NULL) {
            setenv("GITHUB_TOKEN", getenv("GH_ACCESS_TOKEN"), 1);
        }
    }

    // Create or open the lock file
    int lock_fd = open("/home/openclaw/.openclaw/locks/abstractions-manager.lock", O_RDWR | O_CREAT, 0666);
    if (lock_fd == -1) {
        perror("Failed to open lock file");
        return 1;
    }

    // Try to acquire the lock
    if (flock(lock_fd, LOCK_EX | LOCK_NB) == -1) {
        perror("Failed to acquire lock");
        close(lock_fd);
        return 1;
    }

    // Execute the Python script
    char *args[] = {"/usr/bin/python3", "/home/openclaw/.openclaw/workspace/skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py", NULL};
    for (int i = 1; i < argc; i++) {
        args[i + 1] = argv[i];
    }
    execv(args[0], args);

    // If execv returns, there was an error
    perror("Failed to execute Python script");
    flock(lock_fd, LOCK_UN);
    close(lock_fd);
    return 1;
}
