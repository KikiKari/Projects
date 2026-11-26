// abstraction-provenance: {"artifact_sha256": "c56c531d7ca02a8eb7caf2d81693c915a7487da8393707de6b1baf19cd4844c9", "source_sha256": "5a841c728d9c1585b5c3191e88fdd38cf887a0d51560ce803b8c0172412bef3d", "target_language": "c"}
// check_nodes.py — portiert nach c
// Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/check_nodes.py
// auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/check_nodes.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/wait.h>
#include <unistd.h>
#include <errno.h>

#define BUFFER_SIZE 1024
#define MAX_NODES 100

typedef struct {
    char id[32];
    int always_available;
    char capacity[32];
    int priority;
    char description[128];
    char device[64];
} NodeConfig;

typedef struct {
    char id[32];
    int online;
    int available;
    char response[128];
} NodeStatus;

NodeConfig NODES[] = {
    {"node1", 1, "medium", 2, "Gateway-Master", ""},
    {"node2", 1, "medium", 3, "Stable Worker", ""},
    {"node3", 0, "medium", 4, "Bald verfuegbar (nach Reorganisation)", ""},
    {"node5", 0, "low", 5, "Mobile (bei Internet verfuegbar)", "Redmi Note 11S"},
    {"node7", 1, "high", 1, "Docker Hauptarbeitspferd (bald verfuegbar)", ""}
};

int NODE_COUNT = 5;

void get_current_time(char* buffer, size_t size) {
    time_t now = time(NULL);
    strftime(buffer, size, "%Y-%m-%d %H:%M:%S", localtime(&now));
}

void get_iso_time(char* buffer, size_t size) {
    time_t now = time(NULL);
    strftime(buffer, size, "%Y-%m-%dT%H:%M:%S", localtime(&now));
    strcat(buffer, "+00:00"); // Simplified timezone
}

int run_command(const char* cmd, char* output, size_t output_size, int timeout_seconds) {
    FILE* pipe = popen(cmd, "r");
    if (!pipe) return -1;

    time_t start_time = time(NULL);
    size_t pos = 0;
    int c;

    while ((c = fgetc(pipe)) != EOF && pos < output_size - 1) {
        if (time(NULL) - start_time > timeout_seconds) {
            pclose(pipe);
            return -2; // Timeout
        }
        output[pos++] = (char)c;
    }
    output[pos] = '\0';

    int status = pclose(pipe);
    return WEXITSTATUS(status);
}

NodeStatus check_node_status(const char* node_id) {
    NodeStatus status;
    strncpy(status.id, node_id, sizeof(status.id) - 1);
    status.id[sizeof(status.id) - 1] = '\0';
    status.online = 0;
    status.available = 0;
    strcpy(status.response, "No response");

    // Find node config
    NodeConfig* config = NULL;
    for (int i = 0; i < NODE_COUNT; i++) {
        if (strcmp(NODES[i].id, node_id) == 0) {
            config = &NODES[i];
            break;
        }
    }

    if (config) {
        status.available = config->always_available;
    }

    // Build command
    char cmd[BUFFER_SIZE];
    snprintf(cmd, sizeof(cmd), "openclaw nodes status %s", node_id);

    char output[BUFFER_SIZE];
    int result = run_command(cmd, output, sizeof(output), 5);

    if (result == -2) {
        strcpy(status.response, "Timeout");
    } else if (result == -1) {
        strcpy(status.response, "Error executing command");
    } else {
        status.online = (result == 0);
        
        // Check for keywords in output
        char lower_output[BUFFER_SIZE];
        strcpy(lower_output, output);
        for (int i = 0; lower_output[i]; i++) {
            lower_output[i] = tolower(lower_output[i]);
        }
        
        if (strstr(lower_output, "online") || strstr(lower_output, "active")) {
            status.online = 1;
        }
        
        // Copy first 100 characters of output
        size_t len = strlen(output);
        if (len > 100) len = 100;
        if (len > 0) {
            strncpy(status.response, output, len);
            status.response[len] = '\0';
        } else {
            strcpy(status.response, "No response");
        }
    }

    return status;
}

void print_table(NodeStatus* nodes_status, int count) {
    printf("\n%s\n", "==========================================================================================");
    printf("%-8s %-12s %-12s %-10s %-10s %s\n", "Node", "Status", "Verfuegbar", "Kapazitaet", "Prioritaet", "Geraet/Beschreibung");
    printf("%s\n", "==========================================================================================");
    
    for (int i = 0; i < count; i++) {
        NodeStatus* status = &nodes_status[i];
        NodeConfig* config = NULL;
        
        for (int j = 0; j < NODE_COUNT; j++) {
            if (strcmp(NODES[j].id, status->id) == 0) {
                config = &NODES[j];
                break;
            }
        }
        
        const char* status_icon = status->online ? "🟢 Online" : "🔴 Offline";
        const char* avail_icon = status->available ? "✅ Immer" : "📱 Bedingt";
        const char* capacity = config ? config->capacity : "unknown";
        char priority_str[16];
        snprintf(priority_str, sizeof(priority_str), "%d", config ? config->priority : 0);
        const char* device = config ? (strlen(config->device) > 0 ? config->device : config->description) : "";
        
        printf("%-8s %-12s %-12s %-10s %-10s %s\n", 
               status->id, status_icon, avail_icon, capacity, 
               config ? priority_str : "-", device);
    }
    
    printf("%s\n", "==========================================================================================");
    
    char time_str[64];
    get_current_time(time_str, sizeof(time_str));
    printf("\nGeprueft am: %s\n", time_str);
}

void print_json(NodeStatus* nodes_status, int count) {
    char iso_time[64];
    get_iso_time(iso_time, sizeof(iso_time));
    
    printf("{\n");
    printf("  \"timestamp\": \"%s\",\n", iso_time);
    printf("  \"nodes\": {\n");
    
    for (int i = 0; i < count; i++) {
        NodeStatus* status = &nodes_status[i];
        NodeConfig* config = NULL;
        
        for (int j = 0; j < NODE_COUNT; j++) {
            if (strcmp(NODES[j].id, status->id) == 0) {
                config = &NODES[j];
                break;
            }
        }
        
        printf("    \"%s\": {\n", status->id);
        printf("      \"status\": {\n");
        printf("        \"id\": \"%s\",\n", status->id);
        printf("        \"online\": %s,\n", status->online ? "true" : "false");
        printf("        \"available\": %s,\n", status->available ? "true" : "false");
        printf("        \"response\": \"%s\"\n", status->response);
        printf("      },\n");
        printf("      \"config\": {\n");
        if (config) {
            printf("        \"always_available\": %s,\n", config->always_available ? "true" : "false");
            printf("        \"capacity\": \"%s\",\n", config->capacity);
            printf("        \"priority\": %d,\n", config->priority);
            if (strlen(config->description) > 0) {
                printf("        \"description\": \"%s\",\n", config->description);
            }
            if (strlen(config->device) > 0) {
                printf("        \"device\": \"%s\",\n", config->device);
            }
        }
        printf("      }\n");
        printf("    }%s\n", (i < count - 1) ? "," : "");
    }
    
    printf("  }\n");
    printf("}\n");
}

void save_to_file(NodeStatus* nodes_status, int count, const char* filename) {
    FILE* file = fopen(filename, "w");
    if (!file) {
        perror("Fehler beim Oeffnen der Datei");
        return;
    }
    
    char iso_time[64];
    get_iso_time(iso_time, sizeof(iso_time));
    
    fprintf(file, "{\n");
    fprintf(file, "  \"timestamp\": \"%s\",\n", iso_time);
    fprintf(file, "  \"nodes\": {\n");
    
    for (int i = 0; i < count; i++) {
        NodeStatus* status = &nodes_status[i];
        fprintf(file, "    \"%s\": {\n", status->id);
        fprintf(file, "      \"id\": \"%s\",\n", status->id);
        fprintf(file, "      \"online\": %s,\n", status->online ? "true" : "false");
        fprintf(file, "      \"available\": %s,\n", status->available ? "true" : "false");
        fprintf(file, "      \"response\": \"%s\"\n", status->response);
        fprintf(file, "    }%s\n", (i < count - 1) ? "," : "");
    }
    
    fprintf(file, "  }\n");
    fprintf(file, "}\n");
    
    fclose(file);
    printf("\n💾 Gespeichert: %s\n", filename);
}

int main(int argc, char* argv[]) {
    int format_table = 1; // Default to table
    char save_filename[256] = "";
    
    // Simple argument parsing
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--format") == 0 || strcmp(argv[i], "-f") == 0) {
            if (i + 1 < argc) {
                if (strcmp(argv[i + 1], "json") == 0) {
                    format_table = 0;
                }
                i++;
            }
        } else if (strcmp(argv[i], "--save") == 0 || strcmp(argv[i], "-s") == 0) {
            if (i + 1 < argc) {
                strncpy(save_filename, argv[i + 1], sizeof(save_filename) - 1);
                save_filename[sizeof(save_filename) - 1] = '\0';
                i++;
            }
        }
    }
    
    printf("🔍 Pruefe Node-Status...\n");
    
    NodeStatus nodes_status[MAX_NODES];
    int node_count = 0;
    
    // Check all nodes
    for (int i = 0; i < NODE_COUNT; i++) {
        printf("  → %s... ", NODES[i].id);
        fflush(stdout);
        
        nodes_status[node_count] = check_node_status(NODES[i].id);
        printf("%s\n", nodes_status[node_count].online ? "✓" : "✗");
        node_count++;
    }
    
    // Output results
    if (format_table) {
        print_table(nodes_status, node_count);
    } else {
        print_json(nodes_status, node_count);
    }
    
    // Save to file if requested
    if (strlen(save_filename) > 0) {
        save_to_file(nodes_status, node_count, save_filename);
    }
    
    // Summary
    int online_count = 0;
    for (int i = 0; i < node_count; i++) {
        if (nodes_status[i].online) {
            online_count++;
        }
    }
    printf("\n📊 Zusammenfassung: %d/%d Nodes online\n", online_count, node_count);
    
    return 0;
}
