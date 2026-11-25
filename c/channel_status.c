// abstraction-provenance: {"artifact_sha256": "c3186c431c1a2e75c3bd36da3097098423f93b4b412c0a5c1c9426273efa7a3e", "source_sha256": "705cb2cc5900c507db1038d107f06e2f8452a95c37d0611cd27dfe2ed61dd498", "target_language": "c"}
// channel_status.py — portiert nach c
// Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
// auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/stat.h>
#include <unistd.h>

#define WORKSPACE "/home/openclaw/.openclaw/workspace"
#define LOGS_DB WORKSPACE "/db/logs.db"
#define CONFIG_FILE WORKSPACE "/config/channel-status.json"
#define LOG_FILE WORKSPACE "/logs/channel-status.log"

// Logging function
void log_message(const char* message, const char* level) {
    FILE* log_file = fopen(LOG_FILE, "a");
    if (log_file == NULL) {
        printf("Failed to open log file\n");
        return;
    }

    time_t now = time(NULL);
    struct tm* local_time = localtime(&now);
    char timestamp[20];
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", local_time);

    fprintf(log_file, "[%s] [%s] %s\n", timestamp, level, message);
    fclose(log_file);
    printf("[%s] [%s] %s\n", timestamp, level, message);
}

// Get system metrics
char* get_disk_usage() {
    static char disk_usage[10];
    FILE* fp = popen("df -h / | awk 'NR==2 {print $5}'", "r");
    if (fp != NULL) {
        fgets(disk_usage, sizeof(disk_usage), fp);
        pclose(fp);
        // Remove newline
        disk_usage[strcspn(disk_usage, "\n")] = 0;
    } else {
        strcpy(disk_usage, "N/A");
    }
    return disk_usage;
}

void get_ram_usage(char* ram_total, char* ram_used) {
    FILE* fp = popen("free -h | awk 'NR==2 {print $2, $3}'", "r");
    if (fp != NULL) {
        fscanf(fp, "%s %s", ram_total, ram_used);
        pclose(fp);
    } else {
        strcpy(ram_total, "N/A");
        strcpy(ram_used, "N/A");
    }
}

int get_active_cron_jobs() {
    FILE* fp = popen("crontab -l 2>/dev/null | grep -v '^#' | wc -l", "r");
    int count = 0;
    if (fp != NULL) {
        fscanf(fp, "%d", &count);
        pclose(fp);
    }
    return count;
}

// Format daily status
void format_daily_status(char* buffer, size_t buffer_size) {
    time_t now = time(NULL);
    struct tm* local_time = localtime(&now);
    char date_str[20];
    strftime(date_str, sizeof(date_str), "%Y-%m-%d %H:%M", local_time);

    char disk_usage[10];
    strcpy(disk_usage, get_disk_usage());

    char ram_total[10], ram_used[10];
    get_ram_usage(ram_total, ram_used);

    int active_crons = get_active_cron_jobs();

    snprintf(buffer, buffer_size,
        "📊 **Täglicher Status-Report**\n"
        "🗓️ %s\n\n"
        "**🖥️ Nodes (3/5 online):**\n"
        "🟢 Gateway: online\n"
        "🟢 Worker: online\n"
        "🔴 Relay: offline (disk full)\n"
        "🟡 Redmi: intermittent\n"
        "🔵 Docker: planned\n\n"
        "**🤖 Agents:**\n"
        "Aktive Cron-Jobs: %d\n\n"
        "**💾 System:**\n"
        "Disk: %s belegt\n"
        "RAM: %s / %s\n",
        date_str, active_crons, disk_usage, ram_used, ram_total);
}

// Format weekly status
void format_weekly_status(char* buffer, size_t buffer_size) {
    time_t now = time(NULL);
    struct tm* local_time = localtime(&now);
    char week_str[10];
    strftime(week_str, sizeof(week_str), "%V", local_time);
    char year_str[10];
    strftime(year_str, sizeof(year_str), "%Y", local_time);

    snprintf(buffer, buffer_size,
        "📈 **Wöchentlicher Report**\n"
        "📅 Woche %s - %s\n\n"
        "**Zusammenfassung:**\n"
        "- 5 aktive Sub-Agents\n"
        "- 11 Skills synchronisiert\n"
        "- 3 neue Features implementiert\n\n"
        "**Top-Ereignisse:**\n"
        "1. ClawHub-Git Sync implementiert ✅\n"
        "2. Node 3 Disk voll (95%) ⚠️\n"
        "3. Channel-Status-Agent aktiviert 🆕\n\n"
        "**Geplante Wartungen:**\n"
        "- Node 3: Disk-Cleanup erforderlich\n"
        "- Node 7: Docker-Setup ausstehend\n",
        week_str, year_str);
}

// Send message to channel
int send_to_channel(const char* message, const char* channel_type, const char* channel_id) {
    if (strcmp(channel_type, "telegram") != 0) {
        log_message("Channel type not implemented", "WARN");
        return 0;
    }

    char cmd[1024];
    snprintf(cmd, sizeof(cmd), "openclaw message send --target %s --message \"%s\"", channel_id, message);

    int result = system(cmd);
    if (result == 0) {
        log_message("Message sent successfully", "INFO");
        return 1;
    } else {
        log_message("Failed to send message", "ERROR");
        return 0;
    }
}

int main(int argc, char* argv[]) {
    // Create logs directory if it doesn't exist
    char log_dir[256];
    snprintf(log_dir, sizeof(log_dir), "%s/logs", WORKSPACE);
    mkdir(log_dir, 0755);

    if (argc < 2) {
        printf("Usage: %s --type [daily|weekly|alert] [--message MESSAGE] [--channel CHANNEL] [--dry-run]\n", argv[0]);
        return 1;
    }

    char type[20] = "";
    char message[1024] = "";
    char channel[50] = "-1002381931352";
    int dry_run = 0;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--type") == 0 && i + 1 < argc) {
            strncpy(type, argv[++i], sizeof(type) - 1);
        } else if (strcmp(argv[i], "--message") == 0 && i + 1 < argc) {
            strncpy(message, argv[++i], sizeof(message) - 1);
        } else if (strcmp(argv[i], "--channel") == 0 && i + 1 < argc) {
            strncpy(channel, argv[++i], sizeof(channel) - 1);
        } else if (strcmp(argv[i], "--dry-run") == 0) {
            dry_run = 1;
        }
    }

    if (strlen(type) == 0) {
        printf("Error: --type is required\n");
        return 1;
    }

    char log_msg[256];
    snprintf(log_msg, sizeof(log_msg), "Starting %s status update", type);
    log_message(log_msg, "INFO");

    char formatted_message[4096];

    if (strcmp(type, "daily") == 0) {
        format_daily_status(formatted_message, sizeof(formatted_message));
    } else if (strcmp(type, "weekly") == 0) {
        format_weekly_status(formatted_message, sizeof(formatted_message));
    } else if (strcmp(type, "alert") == 0) {
        if (strlen(message) > 0) {
            snprintf(formatted_message, sizeof(formatted_message), "🚨 **ALERT**\n%s", message);
        } else {
            snprintf(formatted_message, sizeof(formatted_message), "🚨 **ALERT**\nManual alert");
        }
    } else {
        printf("Invalid type. Use daily, weekly, or alert\n");
        return 1;
    }

    if (dry_run) {
        printf("\n--- DRY RUN ---\n");
        printf("%s", formatted_message);
        printf("\n--- END ---\n");
    } else {
        send_to_channel(formatted_message, "telegram", channel);
    }

    log_message("Status update completed", "INFO");
    return 0;
}
