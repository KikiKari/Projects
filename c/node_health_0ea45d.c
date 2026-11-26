// abstraction-provenance: {"artifact_sha256": "b03ee00270475afaa03281288651f420d761962a237430f168f47b140bb0cd30", "source_sha256": "0ea45de4496e55f73aa9b10188cc6a04921d74e1cadbe0ac04a948d0f2772243", "target_language": "c"}
// node_health.py — portiert nach c
// Quelle: python, OpenClaw@gateway2:skills/node-health-monitor/scripts/node_health.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <time.h>
#include <sys/stat.h>
#include <errno.h>
#include <libgen.h>

#define MAX_NODES 10
#define MAX_LINE_LENGTH 1024
#define WORKSPACE "/home/openclaw/.openclaw/workspace"
#define HEALTH_DB WORKSPACE "/db/health.db"
#define LOG_FILE WORKSPACE "/logs/node-health.log"

typedef struct {
    char id[32];
    char name[64];
    char host[64];
    char user[32];
    char ssh_key[128];
    char ssh_opts[128];
    int port;
    int critical;
    int optional;
    int disk_warning;
} NodeConfig;

typedef struct {
    char timestamp[64];
    int available;
    float cpu;
    float ram;
    int disk;
    float load;
    char gateway_status[32];
} NodeMetrics;

typedef struct {
    char level[16];
    char message[256];
} Alert;

NodeConfig NODES[MAX_NODES] = {
    {"node1", "Node 1", "localhost", "openclaw", "", "", 0, 1, 0, 85},
    {"node2", "Node 2", "10.10.0.2", "root", "~/.ssh/id_rsa", "-o ConnectTimeout=10 -o BatchMode=yes", 0, 0, 0, 85},
    {"node3", "Node 3", "localhost", "root", "", "-p 18794 -o ConnectTimeout=10 -o BatchMode=yes", 18794, 0, 0, 85},
    {"node5", "Redmi", "192.168.1.x", "openclaw", "", "", 0, 0, 1, 85}
};

int NODE_COUNT = 4;

void log_message(const char* message, const char* level) {
    time_t now;
    struct tm *tm_info;
    char timestamp[64];
    
    time(&now);
    tm_info = localtime(&now);
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", tm_info);
    
    char entry[1024];
    snprintf(entry, sizeof(entry), "[%s] [%s] %s\n", timestamp, level, message);
    printf("%s", entry);
    
    // Create directory if needed
    char log_dir[256];
    strcpy(log_dir, LOG_FILE);
    dirname(log_dir);
    mkdir(log_dir, 0755);
    
    FILE* f = fopen(LOG_FILE, "a");
    if (f) {
        fprintf(f, "%s", entry);
        fclose(f);
    }
}

int run_command(const char* cmd, char* output, size_t output_size, int timeout) {
    FILE* pipe = popen(cmd, "r");
    if (!pipe) return -1;
    
    if (output && output_size > 0) {
        fgets(output, output_size, pipe);
        output[strcspn(output, "\n")] = 0; // Remove newline
    }
    
    int status = pclose(pipe);
    return WEXITSTATUS(status);
}

int check_ping(const char* host, int timeout) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "ping -c 1 -W %d %s >/dev/null 2>&1", timeout, host);
    return system(cmd) == 0;
}

int check_ssh(NodeConfig* node_config) {
    char cmd[512];
    if (node_config->port > 0) {
        snprintf(cmd, sizeof(cmd), "ssh %s -p %d -o ConnectTimeout=10 -o BatchMode=yes %s@%s echo OK 2>/dev/null | grep -q OK",
                 node_config->ssh_opts, node_config->port, node_config->user, node_config->host);
    } else {
        snprintf(cmd, sizeof(cmd), "ssh %s -o ConnectTimeout=10 -o BatchMode=yes %s@%s echo OK 2>/dev/null | grep -q OK",
                 node_config->ssh_opts, node_config->user, node_config->host);
    }
    return system(cmd) == 0;
}

void get_node_metrics(NodeConfig* node_config, NodeMetrics* metrics) {
    time_t now;
    struct tm *tm_info;
    
    time(&now);
    tm_info = localtime(&now);
    strftime(metrics->timestamp, sizeof(metrics->timestamp), "%Y-%m-%dT%H:%M:%S", tm_info);
    
    metrics->available = 0;
    metrics->cpu = -1;
    metrics->ram = -1;
    metrics->disk = -1;
    metrics->load = -1;
    strcpy(metrics->gateway_status, "");
    
    if (strcmp(node_config->host, "localhost") == 0) {
        metrics->available = 1;
        
        // CPU
        FILE* fp = popen("top -bn1 | grep \"Cpu(s)\" | awk '{print $2}' | cut -d'%' -f1", "r");
        if (fp) {
            char buffer[32];
            if (fgets(buffer, sizeof(buffer), fp)) {
                metrics->cpu = atof(buffer);
            }
            pclose(fp);
        }
        
        // RAM
        fp = popen("free | grep Mem | awk '{print ($3/$2) * 100.0}'", "r");
        if (fp) {
            char buffer[32];
            if (fgets(buffer, sizeof(buffer), fp)) {
                metrics->ram = atof(buffer);
            }
            pclose(fp);
        }
        
        // Disk
        fp = popen("df -h / | tail -1 | awk '{print $5}' | tr -d '%'", "r");
        if (fp) {
            char buffer[32];
            if (fgets(buffer, sizeof(buffer), fp)) {
                metrics->disk = atoi(buffer);
            }
            pclose(fp);
        }
        
        // Load
        fp = popen("uptime | awk -F\"load average:\" '{print $2}' | awk '{print $1}' | tr -d ','", "r");
        if (fp) {
            char buffer[32];
            if (fgets(buffer, sizeof(buffer), fp)) {
                metrics->load = atof(buffer);
            }
            pclose(fp);
        }
        
        // Gateway Status
        if (system("command -v openclaw >/dev/null 2>&1") == 0) {
            fp = popen("systemctl is-active openclaw-gateway 2>/dev/null", "r");
            if (fp) {
                char buffer[32];
                if (fgets(buffer, sizeof(buffer), fp)) {
                    buffer[strcspn(buffer, "\n")] = 0;
                    strcpy(metrics->gateway_status, buffer);
                }
                pclose(fp);
            }
        }
    } else {
        char cmd[2048];
        snprintf(cmd, sizeof(cmd),
                 "ssh -o ConnectTimeout=10 %s@%s '"
                 "echo \"CPU:$(top -bn1 | grep \\\"Cpu(s)\\\" | awk \\\"{print \\\\\\$2}\\\" | cut -d\\\"%%\\\" -f1)\";"
                 "echo \"RAM:$(free | grep Mem | awk \\\"{print (\\\\\$3/\\\\\$2) * 100.0}\\\")\";"
                 "echo \"DISK:$(df -h / | tail -1 | awk \\\"{print \\\\\\$5}\\\" | tr -d \\\"%%%%\\\")\";"
                 "echo \"LOAD:$(uptime | awk -F\\\"load average:\\\" \\\"{print \\\\\\$2}\\\" | awk \\\"{print \\\\\\$1}\\\" | tr -d \\\"\\\\,\\\")\";"
                 "if command -v openclaw >/dev/null 2>&1; then "
                 "systemctl is-active openclaw-gateway 2>/dev/null || echo \\\"GATEWAY:inactive\\\"; "
                 "fi'",
                 node_config->user, node_config->host);
        
        FILE* fp = popen(cmd, "r");
        if (fp) {
            char line[256];
            metrics->available = 1;
            
            while (fgets(line, sizeof(line), fp)) {
                line[strcspn(line, "\n")] = 0;
                
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
                        strcpy(metrics->gateway_status, value);
                    }
                }
            }
            pclose(fp);
        }
    }
}

int check_alerts(const char* node_id, NodeConfig* node_config, NodeMetrics* metrics, Alert* alerts) {
    int alert_count = 0;
    
    // Verfügbarkeit
    if (!metrics->available) {
        if (!node_config->optional) {
            strcpy(alerts[alert_count].level, "CRITICAL");
            snprintf(alerts[alert_count].message, sizeof(alerts[alert_count].message),
                     "Node %s nicht erreichbar!", node_config->name);
            alert_count++;
        }
    } else {
        // CPU
        if (metrics->cpu > 0 && metrics->cpu > 90) {
            strcpy(alerts[alert_count].level, "WARNING");
            snprintf(alerts[alert_count].message, sizeof(alerts[alert_count].message),
                     "Node %s: CPU bei %.1f%%", node_config->name, metrics->cpu);
            alert_count++;
        }
        
        // RAM
        if (metrics->ram > 0 && metrics->ram > 90) {
            strcpy(alerts[alert_count].level, "WARNING");
            snprintf(alerts[alert_count].message, sizeof(alerts[alert_count].message),
                     "Node %s: RAM bei %.1f%%", node_config->name, metrics->ram);
            alert_count++;
        }
        
        // Disk
        int disk_threshold = node_config->disk_warning > 0 ? node_config->disk_warning : 85;
        if (metrics->disk > 0 && metrics->disk > disk_threshold) {
            if (metrics->disk > 95) {
                strcpy(alerts[alert_count].level, "CRITICAL");
            } else {
                strcpy(alerts[alert_count].level, "WARNING");
            }
            snprintf(alerts[alert_count].message, sizeof(alerts[alert_count].message),
                     "Node %s: Disk bei %d%%", node_config->name, metrics->disk);
            alert_count++;
        }
        
        // Gateway
        if (node_config->critical && strcmp(metrics->gateway_status, "active") != 0) {
            strcpy(alerts[alert_count].level, "CRITICAL");
            snprintf(alerts[alert_count].message, sizeof(alerts[alert_count].message),
                     "Node %s: OpenClaw Gateway nicht aktiv!", node_config->name);
            alert_count++;
        }
    }
    
    return alert_count;
}

void send_alert(Alert* alert) {
    char cmd[1024];
    snprintf(cmd, sizeof(cmd),
             "python3 " WORKSPACE "/skills/channel-status-agent/scripts/channel_status.py "
             "--type alert --message \"%s: %s\" >/dev/null 2>&1",
             alert->level, alert->message);
    
    system(cmd);
    char log_msg[512];
    snprintf(log_msg, sizeof(log_msg), "Alert sent: %s", alert->message);
    log_message(log_msg, "INFO");
}

int find_node_index(const char* node_id) {
    for (int i = 0; i < NODE_COUNT; i++) {
        if (strcmp(NODES[i].id, node_id) == 0) {
            return i;
        }
    }
    return -1;
}

int main(int argc, char* argv[]) {
    char node_arg[32] = "all";
    char check_arg[32] = "all";
    int alert_flag = 0;
    
    // Simple argument parsing
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--node") == 0 && i + 1 < argc) {
            strncpy(node_arg, argv[++i], sizeof(node_arg) - 1);
        } else if (strcmp(argv[i], "--check") == 0 && i + 1 < argc) {
            strncpy(check_arg, argv[++i], sizeof(check_arg) - 1);
        } else if (strcmp(argv[i], "--alert") == 0) {
            alert_flag = 1;
        }
    }
    
    NodeConfig* nodes_to_check[MAX_NODES];
    int nodes_count = 0;
    
    if (strcmp(node_arg, "all") == 0) {
        for (int i = 0; i < NODE_COUNT; i++) {
            nodes_to_check[nodes_count++] = &NODES[i];
        }
    } else {
        int idx = find_node_index(node_arg);
        if (idx >= 0) {
            nodes_to_check[0] = &NODES[idx];
            nodes_count = 1;
        } else {
            char error_msg[128];
            snprintf(error_msg, sizeof(error_msg), "Unknown node: %s", node_arg);
            log_message(error_msg, "ERROR");
            return 1;
        }
    }
    
    Alert all_alerts[100];
    int total_alerts = 0;
    
    for (int i = 0; i < nodes_count; i++) {
        NodeConfig* node_config = nodes_to_check[i];
        char log_msg[256];
        snprintf(log_msg, sizeof(log_msg), "Checking %s (%s)", node_config->name, node_config->id);
        log_message(log_msg, "INFO");
        
        // Ping
        if (strcmp(check_arg, "ping") == 0 || strcmp(check_arg, "all") == 0) {
            if (strcmp(node_config->host, "localhost") != 0) {
                int ping_ok = check_ping(node_config->host, 10);
                log_message(ping_ok ? "  Ping: OK" : "  Ping: FAILED", "INFO");
            }
        }
        
        // SSH
        if (strcmp(check_arg, "ssh") == 0 || strcmp(check_arg, "all") == 0) {
            int ssh_ok = check_ssh(node_config);
            log_message(ssh_ok ? "  SSH: OK" : "  SSH: FAILED", "INFO");
        }
        
        // Metriken
        if (strcmp(check_arg, "metrics") == 0 || strcmp(check_arg, "all") == 0) {
            NodeMetrics metrics;
            get_node_metrics(node_config, &metrics);
            
            if (metrics.available) {
                char msg[64];
                if (metrics.cpu >= 0) {
                    snprintf(msg, sizeof(msg), "  CPU: %.1f%%", metrics.cpu);
                    log_message(msg, "INFO");
                } else {
                    log_message("  CPU: N/A", "INFO");
                }
                
                if (metrics.ram >= 0) {
                    snprintf(msg, sizeof(msg), "  RAM: %.1f%%", metrics.ram);
                    log_message(msg, "INFO");
                } else {
                    log_message("  RAM: N/A", "INFO");
                }
                
                if (metrics.disk >= 0) {
                    snprintf(msg, sizeof(msg), "  Disk: %d%%", metrics.disk);
                    log_message(msg, "INFO");
                } else {
                    log_message("  Disk: N/A", "INFO");
                }
                
                if (metrics.load >= 0) {
                    snprintf(msg, sizeof(msg), "  Load: %.2f", metrics.load);
                    log_message(msg, "INFO");
                } else {
                    log_message("  Load: N/A", "INFO");
                }
            } else {
                log_message("  Metrics: UNAVAILABLE", "INFO");
            }
            
            // Alerts prüfen
            Alert node_alerts[20];
            int alert_count = check_alerts(node_config->id, node_config, &metrics, node_alerts);
            
            for (int j = 0; j < alert_count; j++) {
                all_alerts[total_alerts++] = node_alerts[j];
            }
        }
    }
    
    // Alerts senden
    if (alert_flag && total_alerts > 0) {
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
