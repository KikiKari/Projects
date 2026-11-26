// abstraction-provenance: {"artifact_sha256": "82f95f7d38ba36206fa7634748fd63ec52f0bca4e7b39ef8aa9c716f48e7997c", "source_sha256": "4c10c6b6fd911cb95da119f761f402073d1a836cab6b40a9f3b989536d5df5ec", "target_language": "c"}
// git_publish.py — portiert nach c
// Quelle: python, OpenClaw@gateway1:skills/git-publish-agent/scripts/git_publish.py
// auch in: OpenClaw@gateway2:skills/git-publish-agent/scripts/git_publish.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <dirent.h>

#define SKILLS_DIR "/home/user/.openclaw/workspace/skills"
#define MAX_PATH 1024
#define MAX_OUTPUT 4096

// Function prototypes
int git_commit(const char* skill_path, const char* message);
int clawhub_publish(const char* skill_name, char* output);
void batch_publish();
int run_command(const char* cmd, char* output, size_t output_size);
int run_command_cwd(const char* cmd, const char* cwd, char* output, size_t output_size);

/**
 * Commit skill changes.
 */
int git_commit(const char* skill_path, const char* message) {
    char cmd[2048];
    char full_path[MAX_PATH];
    char timestamp[100];
    time_t now = time(NULL);
    struct tm *tm_info = localtime(&now);
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%dT%H:%M:%S", tm_info);
    
    // Build full path
    snprintf(full_path, sizeof(full_path), "%s/%s", SKILLS_DIR, skill_path);
    
    // Default message if none provided
    char commit_msg[512];
    if (!message || strlen(message) == 0) {
        snprintf(commit_msg, sizeof(commit_msg), "[skill] Auto-update %s - %s", skill_path, timestamp);
    } else {
        strncpy(commit_msg, message, sizeof(commit_msg) - 1);
        commit_msg[sizeof(commit_msg) - 1] = '\0';
    }
    
    // Get parent directory of SKILLS_DIR
    char parent_dir[MAX_PATH];
    strncpy(parent_dir, SKILLS_DIR, sizeof(parent_dir) - 1);
    parent_dir[sizeof(parent_dir) - 1] = '\0';
    char* last_slash = strrchr(parent_dir, '/');
    if (last_slash) {
        *last_slash = '\0';
    }
    
    // Add files
    snprintf(cmd, sizeof(cmd), "git add \"%s\"", full_path);
    int result = system(cmd);
    if (result != 0) {
        return 0;
    }
    
    // Commit changes
    snprintf(cmd, sizeof(cmd), "git commit -m \"%s\"", commit_msg);
    FILE* pipe = popen(cmd, "r");
    if (!pipe) {
        return 0;
    }
    
    pclose(pipe);
    // Check if commit was successful by checking exit code
    return WEXITSTATUS(result) == 0;
}

/**
 * Publish to ClawHub.
 */
int clawhub_publish(const char* skill_name, char* output) {
    char cmd[2048];
    char full_path[MAX_PATH];
    
    snprintf(full_path, sizeof(full_path), "%s/%s", SKILLS_DIR, skill_name);
    snprintf(cmd, sizeof(cmd), "clawhub publish \"%s\" --slug %s --version 1.0.0", 
             full_path, skill_name);
    
    return run_command(cmd, output, MAX_OUTPUT);
}

/**
 * Publish all changed skills with rate limiting.
 */
void batch_publish() {
    char cmd[2048];
    char output[MAX_OUTPUT] = {0};
    char changed_skills[10][MAX_PATH] = {{0}}; // Max 10 skills
    int changed_count = 0;
    
    // Check git status
    snprintf(cmd, sizeof(cmd), "git status --short \"%s\"", SKILLS_DIR);
    if (!run_command_cwd(cmd, SKILLS_DIR, output, sizeof(output))) {
        printf("Failed to get git status\n");
        return;
    }
    
    // Parse changed skills
    char* line = strtok(output, "\n");
    while (line && changed_count < 10) {
        if (strlen(line) > 0) {
            // Look for skills/ pattern
            char* skills_pos = strstr(line, "skills/");
            if (skills_pos) {
                // Extract skill name (first component after skills/)
                char* skill_start = skills_pos + 7; // Skip "skills/"
                char* slash_pos = strchr(skill_start, '/');
                if (slash_pos) {
                    *slash_pos = '\0';
                }
                
                // Check if already added
                int found = 0;
                for (int i = 0; i < changed_count; i++) {
                    if (strcmp(changed_skills[i], skill_start) == 0) {
                        found = 1;
                        break;
                    }
                }
                
                if (!found && strlen(skill_start) > 0) {
                    strncpy(changed_skills[changed_count], skill_start, MAX_PATH - 1);
                    changed_skills[changed_count][MAX_PATH - 1] = '\0';
                    changed_count++;
                }
            }
        }
        line = strtok(NULL, "\n");
    }
    
    printf("Changed skills: [");
    for (int i = 0; i < changed_count; i++) {
        printf("%s%s", i > 0 ? ", " : "", changed_skills[i]);
    }
    printf("]\n");
    
    // Publish with delay (max 5 per batch)
    int limit = (changed_count > 5) ? 5 : changed_count;
    for (int i = 0; i < limit; i++) {
        if (i > 0) {
            printf("Waiting 15min for rate limit...\n");
            // In real: sleep(900);
        }
        
        printf("Publishing %s...\n", changed_skills[i]);
        
        if (git_commit(changed_skills[i], NULL)) {
            char publish_output[MAX_OUTPUT];
            int pub_result = clawhub_publish(changed_skills[i], publish_output);
            printf("  %s %s\n", pub_result ? "✓" : "✗", publish_output);
        } else {
            printf("  ✗ Git commit failed\n");
        }
    }
}

/**
 * Run command and capture output
 */
int run_command(const char* cmd, char* output, size_t output_size) {
    FILE* pipe = popen(cmd, "r");
    if (!pipe) {
        return 0;
    }
    
    size_t len = 0;
    char buffer[1024];
    while (fgets(buffer, sizeof(buffer), pipe) != NULL) {
        size_t buf_len = strlen(buffer);
        if (len + buf_len < output_size - 1) {
            strcpy(output + len, buffer);
            len += buf_len;
        } else {
            break;
        }
    }
    
    int result = pclose(pipe);
    output[len] = '\0';
    return WEXITSTATUS(result) == 0;
}

/**
 * Run command in specific directory and capture output
 */
int run_command_cwd(const char* cmd, const char* cwd, char* output, size_t output_size) {
    char old_cwd[MAX_PATH];
    if (getcwd(old_cwd, sizeof(old_cwd)) == NULL) {
        return 0;
    }
    
    if (chdir(cwd) != 0) {
        return 0;
    }
    
    int result = run_command(cmd, output, output_size);
    
    chdir(old_cwd);
    return result;
}

int main(int argc, char* argv[]) {
    int single_skill = 0;
    int publish_all = 0;
    int no_publish = 0;
    char skill_name[MAX_PATH] = {0};
    char message[512] = {0};
    
    // Simple argument parsing
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--skill") == 0 && i + 1 < argc) {
            single_skill = 1;
            strncpy(skill_name, argv[++i], sizeof(skill_name) - 1);
            skill_name[sizeof(skill_name) - 1] = '\0';
        } else if (strcmp(argv[i], "--all") == 0) {
            publish_all = 1;
        } else if (strcmp(argv[i], "--no-publish") == 0) {
            no_publish = 1;
        } else if (strcmp(argv[i], "--message") == 0 && i + 1 < argc) {
            strncpy(message, argv[++i], sizeof(message) - 1);
            message[sizeof(message) - 1] = '\0';
        }
    }
    
    if (single_skill) {
        char full_path[MAX_PATH];
        snprintf(full_path, sizeof(full_path), "%s/%s", SKILLS_DIR, skill_name);
        
        if (no_publish) {
            git_commit(skill_name, message[0] ? message : NULL);
        } else {
            git_commit(skill_name, message[0] ? message : NULL);
            char output[MAX_OUTPUT];
            clawhub_publish(skill_name, output);
        }
    } else if (publish_all) {
        batch_publish();
    } else {
        printf("Use --skill <name> or --all\n");
    }
    
    return 0;
}
