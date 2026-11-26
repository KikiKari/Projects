// abstraction-provenance: {"artifact_sha256": "cdbeab85d341599e0adc57f81d52d73dd0d2367c2fcc80d95f1721293d797ed7", "source_sha256": "8cb73cb9ea3a2ccee09205fcea5d8d2e1f29c369b21a3dfcf948b8029436a339", "target_language": "c"}
// node_health.py — portiert nach c
// Quelle: python, OpenClaw@gateway1:skills/node-health-monitor/scripts/node_health.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/wait.h>
#include <dirent.h>
#include <libgen.h>

#define MAX_NODES 10
#define MAX_LINE_LENGTH 1024
#define MAX_CMD_LENGTH 2048

// Konfiguration
const char* WORKSPACE = "/home/openclaw/.openclaw/workspace";
const char* HEALTH_DB = "/home/openclaw/.openclaw/workspace/db/health.db";
const char* LOG_FILE = "/home/openclaw/.openclaw/workspace/logs/node-health.log";

// Node Struktur
typedef struct {
    char id[32];
    char name[64];
    char host[64];
    char user[32];
    char ssh_key[128];
    int critical;
    int optional;
    int disk_warning;
} Node;

// Metrik Struktur
typedef struct {
    char timestamp[64];
    int available;
    double cpu;
    double ram;
    int disk;
    double load;
    char gateway_status[32];
} Metrics;

// Alert Struktur
typedef struct {
    char level[16];
    char message[MAX_LINE_LENGTH];
} Alert;

// Globale Nodes
Node NODES[MAX_NODES];
int node_count = 0;

void init_nodes() {
    // node1
    strcpy(NODES[node_count].id, "node1");
    strcpy(NODES[node_count].name, "Gateway");
    strcpy(NODES[node_count].host, "localhost");
    strcpy(NODES[node_count].user, "openclaw");
    NODES[node_count].critical = 1;
    NODES[node_count].optional = 0;
    NODES[node_count].disk_warning = 85;
    node_count++;

    // node2
    strcpy(NODES[node_count].id, "node2");
    strcpy(NODES[node_count].name, "Worker");
    strcpy(NODES[node_count].host, "100.92.155.34");
    strcpy(NODES[node_count].user, "root");
    strcpy(NODES[node_count].ssh_key, "~/.ssh/id_rsa");
    NODES[node_count].critical = 0;
    NODES[node_count].optional = 0;
    NODES[node_count].disk_warning = 85;
    node_count++;

    // node3
    strcpy(NODES[node_count].id, "node3");
    strcpy(NODES[node_count].name, "Relay");
    strcpy(NODES[node_count].host, "185.242.xxx.xxx");
    strcpy(NODES[node_count].user, "root");
    NODES[node_count].ssh_key[0] = '\0';
    NODES[node_count].critical = 0;
    NODES[node_count].optional = 0;
    NODES[node_count].disk_warning = 85;
    node_count++;

    // node5
    strcpy(NODES[node_count].id, "node5");
    strcpy(NODES[node_count].name, "Redmi");
    strcpy(NODES[node_count].host, "192.168.1.x");
    strcpy(NODES[node_count].user, "openclaw");
    NODES[node_count].ssh_key[0] = '\0';
    NODES[node_count].critical = 0;
    NODES[node_count].optional = 1;
    NODES[node_count].disk_warning = 85;
    node_count++;
}

void ensure_log_dir() {
    char log_dir[512];
    strcpy(log_dir, LOG_FILE);
    dirname(log_dir);
    
    char cmd[512];
    snprintf(cmd, sizeof(cmd), "mkdir -p %s", log_dir);
    system(cmd);
}

void log_message(const char* message, const char* level) {
    time_t now;
    struct tm *tm_info;
    char timestamp[32];
    
    time(&now);
    tm_info = localtime(&now);
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", tm_info);
    
    char entry[MAX_LINE_LENGTH];
    snprintf(entry, sizeof(entry), "[%s] [%s] %s\n", timestamp, level, message);
    printf("%s", entry);
    
    ensure_log_dir();
    
    FILE* f = fopen(LOG_FILE, "a");
    if (f) {
        fprintf(f, "%s", entry);
        fclose(f);
    }
}

int check_ping(const char* host, int timeout) {
    if (strcmp(host, "localhost") == 0) {
        return 1;
    }
    
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "ping -c 1 -W %d %s >/dev/null 2>&1", timeout, host);
    return system(cmd) == 0 ? 1 : 0;
}

int check_ssh(Node* node_config) {
    char cmd[512];
    snprintf(cmd, sizeof(cmd), 
             "ssh -o ConnectTimeout=10 -o BatchMode=yes %s@%s 'echo \"OK\"' 2>/dev/null | grep -q 'OK'",
             node_config->user, node_config->host);
    return system(cmd) == 0 ? 1 : 0;
}

void get_current_timestamp(char* buffer, size_t size) {
    time_t now;
    struct tm *tm_info;
    
    time(&now);
    tm_info = localtime(&now);
    strftime(buffer, size, "%Y-%m-%dT%H:%M:%S", tm_info);
}

void execute_ssh_command(const char* user, const char* host, const char* remote_cmd, char* output, size_t output_size) {
    char full_cmd[MAX_CMD_LENGTH];
    snprintf(full_cmd, sizeof(full_cmd), 
             "ssh -o ConnectTimeout=10 %s@%s '%s' 2>/dev/null", 
             user, host, remote_cmd);
    
    FILE* pipe = popen(full_cmd, "r");
    if (!pipe) {
        output[0] = '\0';
        return;
    }
    
    char buffer[1024];
    size_t total_len = 0;
    while (fgets(buffer, sizeof(buffer), pipe) != NULL && total_len < output_size - 1) {
        size_t len = strlen(buffer);
        if (total_len + len < output_size - 1) {
            strcpy(output + total_len, buffer);
            total_len += len;
        } else {
            break;
        }
    }
    output[total_len] = '\0';
    
    pclose(pipe);
}

void parse_metrics(Metrics* metrics, const char* output) {
    char* line = strtok((char*)output, "\n");
    while (line != NULL) {
        char* colon = strchr(line, ':');
        if (colon) {
            *colon = '\0';
            char* key = line;
            char* value = colon + 1;
            
            if (strcmp(key, "CPU") == 0) {
                metrics->cpu = atof(value);
            } else if (strcmp(key, "RAM") == 0) {
                metrics->ram = atof(value);
            } else if (strcmp(key, "DISK") == 0) {
                metrics->disk = atoi(value);
            } else if (strcmp(key, "LOAD") == 0) {
                metrics->load = atof(value);
            } else if (strcmp(key, "GATEWAY") == 0) {
                strncpy(metrics->gateway_status, value, sizeof(metrics->gateway_status) - 1);
                metrics->gateway_status[sizeof(metrics->gateway_status) - 1] = '\0';
            }
        }
        line = strtok(NULL, "\n");
    }
}

void get_node_metrics(Node* node_config, Metrics* metrics) {
    // Initialisierung
    memset(metrics, 0, sizeof(Metrics));
    get_current_timestamp(metrics->timestamp, sizeof(metrics->timestamp));
    metrics->available = 0;
    metrics->gateway_status[0] = '\0';
    
    if (strcmp(node_config->host, "localhost") == 0) {
        // Lokale Metriken
        FILE* fp;
        char buffer[128];
        
        // CPU
        fp = popen("top -bn1 | grep \"Cpu(s)\" | awk '{print $2}' | cut -d'%' -f1", "r");
        if (fp && fgets(buffer, sizeof(buffer), fp)) {
            metrics->cpu = atof(buffer);
        }
        if (fp) pclose(fp);
        
        // RAM
        fp = popen("free | grep Mem | awk '{print ($3/$2) * 100.0}'", "r");
        if (fp && fgets(buffer, sizeof(buffer), fp)) {
            metrics->ram = atof(buffer);
        }
        if (fp) pclose(fp);
        
        // Disk
        fp = popen("df -h / | tail -1 | awk '{print $5}' | tr -d '%'", "r");
        if (fp && fgets(buffer, sizeof(buffer), fp)) {
            metrics->disk = atoi(buffer);
        }
        if (fp) pclose(fp);
        
        // Load
        fp = popen("uptime | awk -F\"load average:\" '{print $2}' | awk '{print $1}' | tr -d ','", "r");
        if (fp && fgets(buffer, sizeof(buffer), fp)) {
            metrics->load = atof(buffer);
        }
        if (fp) pclose(fp);
        
        metrics->available = 1;
    } else {
        // Remote Metriken via SSH
        char remote_cmd[] = "# CPU\n"
                           "echo \"CPU:$(top -bn1 | grep \\\"Cpu(s)\\\" | awk \\\"{print \\\\\\$2}\\\" | cut -d\\\"%\\\" -f1)\"\n"
                           "\n# RAM\n"
                           "echo \"RAM:$(free | grep Mem | awk \\\"{print (\\\\\\$3/\\\\\\$2) * 100.0}\\\")\"\n"
                           "\n# Disk\n"
                           "echo \"DISK:$(df -h / | tail -1 | awk \\\"{print \\\\\\$5}\\\" | tr -d \\\"%\\\")\"\n"
                           "\n# Load\n"
                           "echo \"LOAD:$(uptime | awk -F\\\"load average:\\\" \\\"{print \\\\\\$2}\\\" | awk \\\"{print \\\\\\$1}\\\" | tr -d \\\",\\\")\"\n"
                           "\n# Gateway Status\n"
                           "if command -v openclaw >/dev/null 2>&1; then\n"
                           "    systemctl is-active openclaw-gateway 2>/dev/null || echo \\\"GATEWAY:inactive\\\"\n"
                           "fi";
        
        char output[MAX_LINE_LENGTH * 4];
        execute_ssh_command(node_config->user, node_config->host, remote_cmd, output, sizeof(output));
        
        if (strlen(output) > 0) {
            metrics->available = 1;
            parse_metrics(metrics, output);
        }
    }
}

int check_alerts(const char* node_id, Node* node_config, Metrics* metrics, Alert* alerts, int max_alerts) {
    int alert_count = 0;
    
    // Verfügbarkeit
    if (!metrics->available) {
        if (!node_config->optional) {
            strncpy(alerts[alert_count].level, "CRITICAL", sizeof(alerts[alert_count].level) - 1);
            alerts[alert_count].level[sizeof(alerts[alert_count].level) - 1] = '\0';
            snprintf(alerts[alert_count].message, sizeof(alerts[alert_count].message),
                     "Node %s nicht erreichbar!", node_config->name);
            alert_count++;
        }
    } else {
        // CPU
        if (metrics->cpu > 90) {
            strncpy(alerts[alert_count].level, "WARNING", sizeof(alerts[alert_count].level) - 1);
            alerts[alert_count].level[sizeof(alerts[alert_count].level) - 1] = '\0';
            snprintf(alerts[alert_count].message, sizeof(alerts[alert_count].message),
                     "Node %s: CPU bei %.1f%%", node_config->name, metrics->cpu);
            alert_count++;
        }
        
        // RAM
        if (metrics->ram > 90) {
            strncpy(alerts[alert_count].level, "WARNING", sizeof(alerts[alert_count].level) - 1);
            alerts[alert_count].level[sizeof(alerts[alert_count].level) - 1] = '\0';
            snprintf(alerts[alert_count].message, sizeof(alerts[alert_count].message),
                     "Node %s: RAM bei %.1f%%", node_config->name, metrics->ram);
            alert_count++;
        }
        
        // Disk
        int disk_threshold = node_config->disk_warning;
        if (metrics->disk > disk_threshold) {
            const char* level = (metrics->disk > 95) ? "CRITICAL" : "WARNING";
            strncpy(alerts[alert_count].level, level, sizeof(alerts[alert_count].level) - 1);
            alerts[alert_count].level[sizeof(alerts[alert_count].level) - 1] = '\0';
            snprintf(alerts[alert_count].message, sizeof(alerts[alert_count].message),
                     "Node %s: Disk bei %d%%", node_config->name, metrics->disk);
            alert_count++;
        }
        
        // Gateway
        if (node_config->critical && strcmp(metrics->gateway_status, "inactive") == 0) {
            strncpy(alerts[alert_count].level, "CRITICAL", sizeof(alerts[alert_count].level) - 1);
            alerts[alert_count].level[sizeof(alerts[alert_count].level) - 1] = '\0';
            snprintf(alerts[alert_count].message, sizeof(alerts[alert_count].message),
                     "Node %s: OpenClaw Gateway nicht aktiv!", node_config->name);
            alert_count++;
        }
    }
    
    return alert_count;
}

void send_alert(Alert* alert) {
    char cmd[MAX_CMD_LENGTH];
    snprintf(cmd, sizeof(cmd),
             "python3 %s/skills/channel-status-agent/scripts/channel_status.py --type alert --message \"%s: %s\" >/dev/null 2>&1",
             WORKSPACE, alert->level, alert->message);
    
    system(cmd);
    char log_msg[MAX_LINE_LENGTH];
    snprintf(log_msg, sizeof(log_msg), "Alert sent: %s", alert->message);
    log_message(log_msg, "INFO");
}

int find_node_index(const char* node_id) {
    for (int i = 0; i < node_count; i++) {
        if (strcmp(NODES[i].id, node_id) == 0) {
            return i;
        }
    }
    return -1;
}

int main(int argc, char* argv[]) {
    // Argumente parsen
    char node_arg[32] = "all";
    char check_arg[16] = "all";
    int send_alerts = 0;
    
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--node") == 0 && i + 1 < argc) {
            strncpy(node_arg, argv[++i], sizeof(node_arg) - 1);
            node_arg[sizeof(node_arg) - 1] = '\0';
        } else if (strcmp(argv[i], "--check") == 0 && i + 1 < argc) {
            strncpy(check_arg, argv[++i], sizeof(check_arg) - 1);
            check_arg[sizeof(check_arg) - 1] = '\0';
        } else if (strcmp(argv[i], "--alert") == 0) {
            send_alerts = 1;
        }
    }
    
    init_nodes();
    
    // Nodes bestimmen
    Node* nodes_to_check[MAX_NODES];
    int nodes_to_check_count = 0;
    
    if (strcmp(node_arg, "all") == 0) {
        for (int i = 0; i < node_count; i++) {
            nodes_to_check[nodes_to_check_count++] = &NODES[i];
        }
    } else {
        int index = find_node_index(node_arg);
        if (index >= 0) {
            nodes_to_check[nodes_to_check_count++] = &NODES[index];
        } else {
            char error_msg[128];
            snprintf(error_msg, sizeof(error_msg), "Unknown node: %s", node_arg);
            log_message(error_msg, "ERROR");
            return 1;
        }
    }
    
    // Health-Checks durchführen
    Alert all_alerts[MAX_NODES * 4];
    int total_alerts = 0;
    
    for (int i = 0; i < nodes_to_check_count; i++) {
        Node* node_config = nodes_to_check[i];
        char log_msg[128];
        snprintf(log_msg, sizeof(log_msg), "Checking %s (%s)", node_config->name, node_config->id);
        log_message(log_msg, "INFO");
        
        // Ping
        if (strcmp(check_arg, "ping") == 0 || strcmp(check_arg, "all") == 0) {
            if (strcmp(node_config->host, "localhost") != 0) {
                int ping_ok = check_ping(node_config->host, 5);
                snprintf(log_msg, sizeof(log_msg), "  Ping: %s", ping_ok ? "OK" : "FAILED");
                log_message(log_msg, "INFO");
            }
        }
        
        // SSH
        if (strcmp(check_arg, "ssh") == 0 || strcmp(check_arg, "all") == 0) {
            int ssh_ok = check_ssh(node_config);
            snprintf(log_msg, sizeof(log_msg), "  SSH: %s", ssh_ok ? "OK" : "FAILED");
            log_message(log_msg, "INFO");
        }
        
        // Metriken
        if (strcmp(check_arg, "metrics") == 0 || strcmp(check_arg, "all") == 0) {
            Metrics metrics;
            get_node_metrics(node_config, &metrics);
            
            if (metrics.available) {
                snprintf(log_msg, sizeof(log_msg), "  CPU: %.1f%%", metrics.cpu);
                log_message(log_msg, "INFO");
                snprintf(log_msg, sizeof(log_msg), "  RAM: %.1f%%", metrics.ram);
                log_message(log_msg, "INFO");
                snprintf(log_msg, sizeof(log_msg), "  Disk: %d%%", metrics.disk);
                log_message(log_msg, "INFO");
                snprintf(log_msg, sizeof(log_msg), "  Load: %.2f", metrics.load);
                log_message(log_msg, "INFO");
            } else {
                log_message("  Metrics: UNAVAILABLE", "INFO");
            }
            
            // Alerts prüfen
            Alert node_alerts[4];
            int alert_count = check_alerts(node_config->id, node_config, &metrics, node_alerts, 4);
            for (int j = 0; j < alert_count; j++) {
                strncpy(all_alerts[total_alerts].level, node_alerts[j].level, sizeof(all_alerts[total_alerts].level) - 1);
                all_alerts[total_alerts].level[sizeof(all_alerts[total_alerts].level) - 1] = '\0';
                strncpy(all_alerts[total_alerts].message, node_alerts[j].message, sizeof(all_alerts[total_alerts].message) - 1);
                all_alerts[total_alerts].message[sizeof(all_alerts[total_alerts].message) - 1] = '\0';
                total_alerts++;
            }
        }
    }
    
    // Alerts senden
    if (send_alerts && total_alerts > 0) {
        char log_msg[128];
        snprintf(log_msg, sizeof(log_msg), "\nSending %d alerts...", total_alerts);
        log_message(log_msg, "INFO");
        for (int i = 0; i < total_alerts; i++) {
            send_alert(&all_alerts[i]);
        }
    } else if (total_alerts > 0) {
        char log_msg[128];
        snprintf(log_msg, sizeof(log_msg), "\n%d alerts found (use --alert to send)", total_alerts);
        log_message(log_msg, "INFO");
    } else {
        log_message("\nAll nodes healthy!", "INFO");
    }
    
    return 0;
}
