// abstraction-provenance: {"artifact_sha256": "b011e1c32baf951586e0ef7d636532fd4c80baa1ef3e1e03c022ce152e3982c0", "source_sha256": "b00f64d55d344bbcc351ae7ade12137f0d9293b556aa0881ede43bef5bcb778b", "target_language": "c"}
// extract-tiktok-yt-dlp.sh — portiert nach c
// Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-yt-dlp.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <time.h>
#include <ctype.h>
#include <libgen.h>

#define MAX_BUFFER 4096
#define TMP_DIR_TEMPLATE "/tmp/tiktok-yt-dlp.XXXXXX"

// Function to execute a command and capture its output
int execute_command(const char* cmd, char* output, size_t output_size) {
    FILE *fp;
    size_t len;

    fp = popen(cmd, "r");
    if (fp == NULL) {
        return -1;
    }

    if (fgets(output, output_size, fp) == NULL) {
        pclose(fp);
        return -1;
    }

    // Remove trailing newline if present
    len = strlen(output);
    if (len > 0 && output[len-1] == '\n') {
        output[len-1] = '\0';
    }

    pclose(fp);
    return 0;
}

// Function to emit JSON response
void emit_json(const char* success, const char* method, const char* username,
               const char* url, const char* format, const char* error,
               const char* timestamp, const char* status) {
    printf("{");
    int first = 1;
    
    if (success && strlen(success) > 0) {
        if (!first) printf(",");
        printf("\"success\":%s", (strcmp(success, "true") == 0) ? "true" : "false");
        first = 0;
    }
    
    if (method && strlen(method) > 0) {
        if (!first) printf(",");
        printf("\"method\":\"%s\"", method);
        first = 0;
    }
    
    if (username && strlen(username) > 0) {
        if (!first) printf(",");
        printf("\"username\":\"%s\"", username);
        first = 0;
    }
    
    if (url && strlen(url) > 0) {
        if (!first) printf(",");
        printf("\"url\":\"%s\"", url);
        first = 0;
    }
    
    if (format && strlen(format) > 0) {
        if (!first) printf(",");
        printf("\"format\":\"%s\"", format);
        first = 0;
    }
    
    if (error && strlen(error) > 0) {
        if (!first) printf(",");
        printf("\"error\":\"%s\"", error);
        first = 0;
    }
    
    if (timestamp && strlen(timestamp) > 0) {
        if (!first) printf(",");
        printf("\"timestamp\":\"%s\"", timestamp);
        first = 0;
    }
    
    if (status && strlen(status) > 0) {
        if (!first) printf(",");
        printf("\"status\":\"%s\"", status);
        first = 0;
    }
    
    printf("}\n");
}

// Function to get current UTC timestamp
void get_timestamp(char* buffer, size_t size) {
    time_t now;
    struct tm *utc_tm;
    
    time(&now);
    utc_tm = gmtime(&now);
    strftime(buffer, size, "%Y-%m-%dT%H:%M:%SZ", utc_tm);
}

// Function to validate TikTok username
int is_valid_username(const char* username) {
    size_t len = strlen(username);
    if (len < 1 || len > 24) {
        return 0;
    }
    
    for (size_t i = 0; i < len; i++) {
        char c = username[i];
        if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || 
              (c >= '0' && c <= '9') || c == '.' || c == '_')) {
            return 0;
        }
    }
    
    return 1;
}

// Function to check if format is valid
int is_valid_format(const char* format) {
    const char* valid_formats[] = {
        "hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld",
        "hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld",
        "hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld",
        "hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld",
        "hls-sd/hls-ld/flv-sd/flv-ld",
        "hls-ld/flv-ld",
        "hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld",
        NULL
    };
    
    for (int i = 0; valid_formats[i] != NULL; i++) {
        if (strcmp(format, valid_formats[i]) == 0) {
            return 1;
        }
    }
    
    return 0;
}

// Function to check system load
int is_system_overloaded(float max_load) {
    FILE *fp;
    char buffer[256];
    float load_avg, cpu_count, load_per_cpu;
    
    // Get CPU count
    fp = popen("nproc", "r");
    if (fp == NULL) {
        cpu_count = 1.0;
    } else {
        if (fgets(buffer, sizeof(buffer), fp) != NULL) {
            cpu_count = atof(buffer);
            if (cpu_count <= 0) cpu_count = 1.0;
        } else {
            cpu_count = 1.0;
        }
        pclose(fp);
    }
    
    // Get load average
    fp = popen("uptime | awk '{print $(NF-2)}' | sed 's/,//'", "r");
    if (fp == NULL) {
        return 0; // Assume not overloaded if we can't determine
    }
    
    if (fgets(buffer, sizeof(buffer), fp) != NULL) {
        load_avg = atof(buffer);
        pclose(fp);
        
        load_per_cpu = load_avg / cpu_count;
        return (load_per_cpu > max_load);
    }
    
    pclose(fp);
    return 0;
}

// Function to check if command exists
int command_exists(const char* cmd) {
    char command[256];
    snprintf(command, sizeof(command), "command -v %s >/dev/null 2>&1", cmd);
    return (system(command) == 0);
}

// Function to read file content
int read_file(const char* filename, char* buffer, size_t buffer_size) {
    FILE *fp;
    size_t bytes_read;
    
    fp = fopen(filename, "r");
    if (fp == NULL) {
        return -1;
    }
    
    bytes_read = fread(buffer, 1, buffer_size - 1, fp);
    buffer[bytes_read] = '\0';
    
    fclose(fp);
    return 0;
}

// Function to extract URL from JSON
int extract_url_from_json(const char* json_content, char* url_buffer, size_t buffer_size) {
    // This is a simplified parser - in production you'd want a proper JSON library
    const char* patterns[] = {"\"url\":\"https://", "\"url\":\"http://", NULL};
    
    for (int i = 0; patterns[i] != NULL; i++) {
        char* pos = strstr(json_content, patterns[i]);
        if (pos != NULL) {
            pos += strlen(patterns[i]) - 8; // Move back to 'https://' or 'http://'
            
            char* end_pos = strchr(pos, '"');
            if (end_pos != NULL) {
                size_t url_len = end_pos - pos;
                if (url_len < buffer_size - 1) {
                    strncpy(url_buffer, pos, url_len);
                    url_buffer[url_len] = '\0';
                    
                    // Check if it's a valid stream URL (contains .m3u8 or .flv but not only_audio=1)
                    if ((strstr(url_buffer, ".m3u8") || strstr(url_buffer, ".flv")) &&
                        !strstr(url_buffer, "only_audio=1")) {
                        return 0;
                    }
                }
            }
        }
    }
    
    return -1;
}

int main(int argc, char *argv[]) {
    char username[256] = {0};
    char format[256] = "best";
    char json_flag[16] = {0};
    char timestamp[32] = {0};
    char tmp_dir[256] = {0};
    char stdout_file[256] = {0};
    char stderr_file[256] = {0};
    char command[2048] = {0};
    char output[MAX_BUFFER] = {0};
    char error_output[MAX_BUFFER] = {0};
    char url[MAX_BUFFER] = {0};
    char max_load_str[32] = {0};
    float max_load = 1.5;
    int exit_code;
    
    // Parse arguments
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <username> [format] [--json]\n", argv[0]);
        return 64;
    }
    
    // Remove @ prefix if present
    if (argv[1][0] == '@') {
        strcpy(username, argv[1] + 1);
    } else {
        strcpy(username, argv[1]);
    }
    
    if (argc >= 3) {
        strcpy(format, argv[2]);
    }
    
    if (argc >= 4 && strcmp(argv[3], "--json") == 0) {
        strcpy(json_flag, "--json");
    }
    
    // Validate username
    if (!is_valid_username(username)) {
        fprintf(stderr, "Invalid TikTok username\n");
        return 64;
    }
    
    // Validate format
    if (!is_valid_format(format)) {
        fprintf(stderr, "Invalid yt-dlp format\n");
        return 64;
    }
    
    // Get timestamp
    get_timestamp(timestamp, sizeof(timestamp));
    
    // Create temporary directory
    strcpy(tmp_dir, TMP_DIR_TEMPLATE);
    if (mkdtemp(tmp_dir) == NULL) {
        perror("Failed to create temporary directory");
        return 1;
    }
    
    // Set up cleanup handler
    atexit(cleanup_tmp_dir);
    
    // Build file paths
    snprintf(stdout_file, sizeof(stdout_file), "%s/stdout.json", tmp_dir);
    snprintf(stderr_file, sizeof(stderr_file), "%s/stderr.log", tmp_dir);
    
    // Check system load
    char* max_load_env = getenv("TIKTOK_MAX_LOAD_PER_CPU");
    if (max_load_env != NULL) {
        max_load = atof(max_load_env);
    }
    
    if (is_system_overloaded(max_load)) {
        if (strcmp(json_flag, "--json") == 0) {
            emit_json("false", "yt-dlp", username, "", format, "host overloaded", timestamp, "overloaded");
        }
        return 75;
    }
    
    // Check if yt-dlp is installed
    if (!command_exists("yt-dlp")) {
        if (strcmp(json_flag, "--json") == 0) {
            emit_json("false", "yt-dlp", username, "", format, "yt-dlp not installed", timestamp, "dependency_missing");
        }
        return 2;
    }
    
    // Build yt-dlp command
    snprintf(command, sizeof(command), 
             "yt-dlp --no-warnings --dump-single-json --skip-download --format \"%s\" \"https://www.tiktok.com/@%s/live\" >\"%s\" 2>\"%s\"",
             format, username, stdout_file, stderr_file);
    
    // Execute yt-dlp command
    exit_code = system(command);
    
    if (WIFEXITED(exit_code)) {
        exit_code = WEXITSTATUS(exit_code);
    } else {
        exit_code = 1;
    }
    
    if (exit_code != 0) {
        // Read error output
        FILE *fp = fopen(stderr_file, "r");
        if (fp != NULL) {
            size_t bytes_read = fread(error_output, 1, sizeof(error_output) - 1, fp);
            error_output[bytes_read] = '\0';
            fclose(fp);
            
            // Truncate to 1000 characters
            if (strlen(error_output) > 1000) {
                error_output[1000] = '\0';
            }
        }
        
        const char* status;
        int code;
        
        if (strstr(error_output, "not currently live") || 
            strstr(error_output, "No live cdn found") || 
            strstr(error_output, "not available") || 
            strstr(error_output, "private video")) {
            status = "offline";
            code = 1;
        } else {
            status = "technical_error";
            code = 2;
        }
        
        if (strcmp(json_flag, "--json") == 0) {
            emit_json("false", "yt-dlp", username, "", format, error_output, timestamp, status);
        }
        return code;
    }
    
    // Read JSON output
    FILE *fp = fopen(stdout_file, "r");
    if (fp == NULL) {
        if (strcmp(json_flag, "--json") == 0) {
            emit_json("false", "yt-dlp", username, "", format, "could not read JSON output", timestamp, "offline");
        }
        return 1;
    }
    
    fseek(fp, 0, SEEK_END);
    long file_size = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    
    char *json_content = malloc(file_size + 1);
    if (json_content == NULL) {
        fclose(fp);
        if (strcmp(json_flag, "--json") == 0) {
            emit_json("false", "yt-dlp", username, "", format, "memory allocation failed", timestamp, "technical_error");
        }
        return 1;
    }
    
    fread(json_content, 1, file_size, fp);
    json_content[file_size] = '\0';
    fclose(fp);
    
    // Extract URL from JSON
    if (extract_url_from_json(json_content, url, sizeof(url)) != 0) {
        free(json_content);
        if (strcmp(json_flag, "--json") == 0) {
            emit_json("false", "yt-dlp", username, "", format, "could not extract HTTPS video URL", timestamp, "offline");
        }
        return 1;
    }
    
    free(json_content);
    
    // Output result
    if (strcmp(json_flag, "--json") == 0) {
        emit_json("true", "yt-dlp", username, url, format, "", timestamp, "live");
    } else {
        printf("%s\n", url);
    }
    
    return 0;
}
