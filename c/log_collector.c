// abstraction-provenance: {"artifact_sha256": "91adcc943238ab5e542a094779ab4366143e4bab0bdce86a0e80d4399ca33a0f", "source_sha256": "5081f9f0745ca8b2223c2de657aa97d48e58ccf61c24467e46c9d562803e34a6", "target_language": "c"}
// log_collector.py — portiert nach c
// Quelle: python, OpenClaw@gateway1:skills/log-collector/scripts/log_collector.py
// auch in: OpenClaw@gateway2:skills/log-collector/scripts/log_collector.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sqlite3.h>
#include <time.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/wait.h>
#include <fcntl.h>

#define WORKSPACE "/home/openclaw/.openclaw/workspace"
#define DB_PATH WORKSPACE "/db/logs.db"
#define LOG_DIR WORKSPACE "/logs/log-collector"

typedef struct {
    char log_file[256];
} Logger;

typedef struct {
    Logger logger;
    sqlite3* conn;
} LogCollector;

void init_workspace() {
    char dirs[][256] = {
        WORKSPACE,
        WORKSPACE "/db",
        WORKSPACE "/logs",
        LOG_DIR
    };
    
    for (int i = 0; i < 4; i++) {
        mkdir(dirs[i], 0755);
    }
}

void logger_init(Logger* logger) {
    time_t now = time(NULL);
    struct tm* tm_now = localtime(&now);
    strftime(logger->log_file, sizeof(logger->log_file), 
             LOG_DIR "/%Y-%m-%d.log", tm_now);
}

void logger_log(Logger* logger, const char* level, const char* msg) {
    time_t rawtime;
    struct tm* timeinfo;
    char timestamp[64];
    
    time(&rawtime);
    timeinfo = localtime(&rawtime);
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%dT%H:%M:%S", timeinfo);
    
    char line[1024];
    snprintf(line, sizeof(line), "[%s] [%s] %s\n", timestamp, level, msg);
    printf("%s", line);
    
    FILE* f = fopen(logger->log_file, "a");
    if (f) {
        fputs(line, f);
        fclose(f);
    }
}

void logger_info(Logger* logger, const char* msg) {
    logger_log(logger, "INFO", msg);
}

void logger_error(Logger* logger, const char* msg) {
    logger_log(logger, "ERROR", msg);
}

int connect_db(LogCollector* collector) {
    int rc = sqlite3_open(DB_PATH, &collector->conn);
    if (rc) {
        fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(collector->conn));
        return rc;
    }
    sqlite3_stmt* stmt;
    rc = sqlite3_prepare_v2(collector->conn, 
                           "SELECT name FROM sqlite_master WHERE type='table'", 
                           -1, &stmt, NULL);
    
    int has_tables = 0;
    if (rc == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            has_tables = 1;
        }
        sqlite3_finalize(stmt);
    }
    
    if (!has_tables) {
        char schema_path[256];
        snprintf(schema_path, sizeof(schema_path), "%s/db/logs.db.schema.sql", WORKSPACE);
        FILE* f = fopen(schema_path, "r");
        if (f) {
            fseek(f, 0, SEEK_END);
            long fsize = ftell(f);
            fseek(f, 0, SEEK_SET);
            
            char* schema = malloc(fsize + 1);
            fread(schema, 1, fsize, f);
            schema[fsize] = '\0';
            
            char* errmsg;
            rc = sqlite3_exec(collector->conn, schema, 0, 0, &errmsg);
            if (rc != SQLITE_OK) {
                fprintf(stderr, "SQL error: %s\n", errmsg);
                sqlite3_free(errmsg);
            }
            free(schema);
            fclose(f);
        }
    }
    
    return rc;
}

typedef struct {
    char node_id[64];
    char vpn_ip[64];
    char tailscale_ip[64];
    char wireguard_ip[64];
} Node;

Node* get_nodes(LogCollector* collector, int* count) {
    sqlite3_stmt* stmt;
    int rc = sqlite3_prepare_v2(collector->conn, 
                               "SELECT node_id, vpn_ip, tailscale_ip, wireguard_ip FROM nodes", 
                               -1, &stmt, NULL);
    
    if (rc != SQLITE_OK) return NULL;
    
    Node* nodes = NULL;
    *count = 0;
    int capacity = 10;
    nodes = malloc(capacity * sizeof(Node));
    
    while ((rc = sqlite3_step(stmt)) == SQLITE_ROW) {
        if (*count >= capacity) {
            capacity *= 2;
            nodes = realloc(nodes, capacity * sizeof(Node));
        }
        
        const char* node_id = (const char*)sqlite3_column_text(stmt, 0);
        const char* vpn_ip = (const char*)sqlite3_column_text(stmt, 1);
        const char* tailscale_ip = (const char*)sqlite3_column_text(stmt, 2);
        const char* wireguard_ip = (const char*)sqlite3_column_text(stmt, 3);
        
        strncpy(nodes[*count].node_id, node_id ? node_id : "", sizeof(nodes[*count].node_id)-1);
        strncpy(nodes[*count].vpn_ip, vpn_ip ? vpn_ip : "", sizeof(nodes[*count].vpn_ip)-1);
        strncpy(nodes[*count].tailscale_ip, tailscale_ip ? tailscale_ip : "", sizeof(nodes[*count].tailscale_ip)-1);
        strncpy(nodes[*count].wireguard_ip, wireguard_ip ? wireguard_ip : "", sizeof(nodes[*count].wireguard_ip)-1);
        
        (*count)++;
    }
    
    sqlite3_finalize(stmt);
    return nodes;
}

int check_vpn(const char* ip) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "ping -c 1 -W 3 %s >/dev/null 2>&1", ip);
    return system(cmd) == 0;
}

char* run_command(const char* cmd, int timeout_seconds) {
    FILE* pipe = popen(cmd, "r");
    if (!pipe) return NULL;
    
    char* output = malloc(65536);
    size_t len = 0;
    char buffer[4096];
    
    // Note: This simplified version doesn't implement actual timeout
    // A full implementation would need signal handling or select()
    while (fgets(buffer, sizeof(buffer), pipe)) {
        size_t buf_len = strlen(buffer);
        if (len + buf_len < 65535) {
            strcpy(output + len, buffer);
            len += buf_len;
        }
    }
    
    pclose(pipe);
    output[len] = '\0';
    return output;
}

void log_ssh_connection(LogCollector* collector, const char* node_id, 
                       const char* conn_type, int success, const char* error) {
    sqlite3_stmt* stmt;
    const char* sql = "INSERT INTO ssh_connections (node_id, connection_type, success, error_message) VALUES (?, ?, ?, ?)";
    
    int rc = sqlite3_prepare_v2(collector->conn, sql, -1, &stmt, NULL);
    if (rc == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, node_id, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 2, conn_type, -1, SQLITE_STATIC);
        sqlite3_bind_int(stmt, 3, success);
        sqlite3_bind_text(stmt, 4, error, -1, SQLITE_STATIC);
        
        sqlite3_step(stmt);
        sqlite3_finalize(stmt);
    }
}

void insert_logs(LogCollector* collector, const char* node_id, const char* command, const char* output) {
    sqlite3_stmt* stmt;
    const char* sql = "INSERT INTO logs (node_id, log_type, source, content, severity, collected_by, collection_method, retention_until) VALUES (?, 'system', ?, ?, 'info', ?, 'ssh', datetime('now', '+30 days'))";
    
    int rc = sqlite3_prepare_v2(collector->conn, sql, -1, &stmt, NULL);
    if (rc == SQLITE_OK) {
        char source[51];
        strncpy(source, command, 50);
        source[50] = '\0';
        
        char content[10001];
        strncpy(content, output, 10000);
        content[10000] = '\0';
        
        sqlite3_bind_text(stmt, 1, node_id, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 2, source, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 3, content, -1, SQLITE_STATIC);
        sqlite3_bind_text(stmt, 4, "node1", -1, SQLITE_STATIC);
        
        sqlite3_step(stmt);
        sqlite3_finalize(stmt);
    }
}

int ssh_connect_and_collect(LogCollector* collector, Node* node) {
    const char* node_id = node->node_id;
    const char* vpn_ip = node->vpn_ip[0] ? node->vpn_ip : 
                        (node->tailscale_ip[0] ? node->tailscale_ip : 
                         (node->wireguard_ip[0] ? node->wireguard_ip : NULL));
    
    if (!vpn_ip) {
        char msg[256];
        snprintf(msg, sizeof(msg), "%s: Keine VPN-IP konfiguriert", node_id);
        logger_error(&collector->logger, msg);
        return -1;
    }
    
    char msg[256];
    snprintf(msg, sizeof(msg), "%s: Prüfe VPN %s...", node_id, vpn_ip);
    logger_info(&collector->logger, msg);
    
    if (!check_vpn(vpn_ip)) {
        char msg[256];
        snprintf(msg, sizeof(msg), "%s: VPN nicht erreichbar", node_id);
        logger_error(&collector->logger, msg);
        log_ssh_connection(collector, node_id, "tailscale", 0, "VPN unreachable");
        return -1;
    }
    
    snprintf(msg, sizeof(msg), "%s: Verbinde via SSH...", node_id);
    logger_info(&collector->logger, msg);
    
    const char* log_commands[] = {
        "journalctl -n 500 --no-pager",
        "tail -n 200 /var/log/syslog 2>/dev/null || echo 'no syslog'",
        "tail -n 200 ~/.openclaw/logs/*.log 2>/dev/null || echo 'no openclaw logs'",
        NULL
    };
    
    int log_count = 0;
    for (int i = 0; log_commands[i]; i++) {
        char ssh_cmd[512];
        snprintf(ssh_cmd, sizeof(ssh_cmd), 
                 "ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no openclaw@%s '%s'", 
                 vpn_ip, log_commands[i]);
        
        char* output = run_command(ssh_cmd, 30);
        if (output) {
            insert_logs(collector, node_id, log_commands[i], output);
            free(output);
            log_count++;
        }
    }
    
    log_ssh_connection(collector, node_id, "ssh", 1, NULL);
    
    char result_msg[256];
    snprintf(result_msg, sizeof(result_msg), "%s: %d Log-Einträge gespeichert", node_id, log_count);
    logger_info(&collector->logger, result_msg);
    
    return log_count;
}

int cleanup_retention(LogCollector* collector) {
    sqlite3_stmt* stmt;
    const char* sql = "DELETE FROM logs WHERE retention_until < datetime('now')";
    
    int rc = sqlite3_prepare_v2(collector->conn, sql, -1, &stmt, NULL);
    int deleted = 0;
    
    if (rc == SQLITE_OK) {
        rc = sqlite3_step(stmt);
        if (rc == SQLITE_DONE) {
            deleted = sqlite3_changes(collector->conn);
        }
        sqlite3_finalize(stmt);
    }
    
    char msg[256];
    snprintf(msg, sizeof(msg), "Retention-Cleanup: %d alte Logs gelöscht", deleted);
    logger_info(&collector->logger, msg);
    
    return deleted;
}

void run_collection_cycle(LogCollector* collector) {
    logger_info(&collector->logger, "============================================================");
    logger_info(&collector->logger, "LOG COLLECTOR CYCLE START");
    logger_info(&collector->logger, "============================================================");
    
    if (connect_db(collector) != SQLITE_OK) {
        logger_error(&collector->logger, "Failed to connect to database");
        return;
    }
    
    int node_count;
    Node* nodes = get_nodes(collector, &node_count);
    
    char msg[256];
    snprintf(msg, sizeof(msg), "Gefunden: %d Nodes", node_count);
    logger_info(&collector->logger, msg);
    
    sqlite3_stmt* stmt;
    const char* insert_run_sql = "INSERT INTO collection_runs (started_at, nodes_total) VALUES (CURRENT_TIMESTAMP, ?)";
    sqlite3_prepare_v2(collector->conn, insert_run_sql, -1, &stmt, NULL);
    sqlite3_bind_int(stmt, 1, node_count);
    sqlite3_step(stmt);
    int run_id = sqlite3_last_insert_rowid(collector->conn);
    sqlite3_finalize(stmt);
    
    int success_count = 0;
    int failed_count = 0;
    int total_logs = 0;
    
    for (int i = 0; i < node_count; i++) {
        if (strcmp(nodes[i].node_id, "node1") == 0) {
            logger_info(&collector->logger, "node1: Lokale Collection (Gateway)");
            success_count++;
        } else {
            int result = ssh_connect_and_collect(collector, &nodes[i]);
            if (result >= 0) {
                success_count++;
                total_logs += result;
            } else {
                failed_count++;
            }
        }
    }
    
    const char* update_run_sql = "UPDATE collection_runs SET finished_at = CURRENT_TIMESTAMP, nodes_success = ?, nodes_failed = ?, logs_collected = ? WHERE run_id = ?";
    sqlite3_prepare_v2(collector->conn, update_run_sql, -1, &stmt, NULL);
    sqlite3_bind_int(stmt, 1, success_count);
    sqlite3_bind_int(stmt, 2, failed_count);
    sqlite3_bind_int(stmt, 3, total_logs);
    sqlite3_bind_int(stmt, 4, run_id);
    sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    
    logger_info(&collector->logger, "Retention-Cleanup (30 Tage)...");
    cleanup_retention(collector);
    
    logger_info(&collector->logger, "============================================================");
    char summary[256];
    snprintf(summary, sizeof(summary), "SUMMARY: %d OK, %d Failed, %d Logs", success_count, failed_count, total_logs);
    logger_info(&collector->logger, summary);
    logger_info(&collector->logger, "============================================================");
    
    free(nodes);
    sqlite3_close(collector->conn);
}

int main() {
    printf("============================================================\n");
    printf("LOG COLLECTOR\n");
    printf("============================================================\n");
    
    init_workspace();
    
    LogCollector collector;
    logger_init(&collector.logger);
    
    run_collection_cycle(&collector);
    
    return 0;
}
