// abstraction-provenance: {"artifact_sha256": "2441462d68a3590c1f66c9ba075e8c16cc7a03b01574dd38b6407acb5de5b2a2", "source_sha256": "748c0fc07a58caf07d4983d358cf0e1ce57c4e180b87ae617d598f53c61efcec", "target_language": "c"}
// dispatch_job.py — portiert nach c
// Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/dispatch_job.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <uuid/uuid.h>
#include <json-c/json.h>
#include <limits.h>

#define MAX_NODES 6
#define MAX_LANGS 10
#define MAX_BUFFER 1024

typedef enum {
    LIGHT,
    MEDIUM,
    HEAVY
} job_weight_t;

typedef struct {
    char id[32];
    char name[64];
    int always_available;
    char capacity[16];
    int priority;
    char description[128];
    char device[128];
} node_config_t;

typedef struct {
    char node_id[32];
    int connected;
} node_status_t;

node_config_t NODES[] = {
    {"node1", "node1", 1, "medium", 3, "Gateway", ""},
    {"node2", "node2", 0, "high", 1, "ARM Server", ""},
    {"node3", "node3", 0, "medium", 4, "AMD Server", ""},
    {"node4", "node4", 0, "low", 5, "", "Redmi Note 11S"},
    {"node5", "node5", 0, "high", 2, "", "Lenovo"},
    {"node6", "node6", 0, "", 0, "", "Lenovo (Docker)"}
};

const char* NODE_NAMES[][5] = {
    {"openclaw-node2", "arm64-node", "v2202604104722449961", "v2202604104722449961.taild25fea.ts.net", "100.82.198.122"},
    {"openclaw-node3", "openclaw-node3.taild25fea.ts.net", "100.73.154.125", NULL, NULL},
    {"openclaw-node4", "redmi-note-11s", "redmi-note-11s.taild25fea.ts.net", "100.94.134.39", NULL},
    {"openclaw-node5", "windows node (lenovo-7)", NULL, NULL, NULL},
    {"openclaw-node6", NULL, NULL, NULL, NULL}
};

int _job_weight_bytes(const char* script_path, int target_langs_count) {
    struct stat st;
    if (stat(script_path, &st) == 0) {
        return (int)(st.st_size * target_langs_count);
    }
    return 0;
}

job_weight_t get_job_weight(const char* script_path, int target_langs_count) {
    struct stat st;
    if (stat(script_path, &st) != 0) {
        return MEDIUM;
    }
    
    int total_work = _job_weight_bytes(script_path, target_langs_count);
    
    if (total_work > 50000) {
        return HEAVY;
    } else if (total_work > 10000) {
        return MEDIUM;
    } else {
        return LIGHT;
    }
}

node_status_t* fetch_node_status(int* count) {
    FILE *fp;
    char buffer[MAX_BUFFER];
    char result[MAX_BUFFER * 10];
    size_t result_len = 0;
    
    // Execute command
    fp = popen("openclaw nodes status --json", "r");
    if (fp == NULL) {
        *count = 0;
        return NULL;
    }
    
    result[0] = '\0';
    while (fgets(buffer, sizeof(buffer), fp) != NULL) {
        strcat(result, buffer);
    }
    pclose(fp);
    
    // Parse JSON
    json_object *root = json_tokener_parse(result);
    if (!root) {
        *count = 0;
        return NULL;
    }
    
    json_object *nodes_obj;
    if (!json_object_object_get_ex(root, "nodes", &nodes_obj) || 
        json_object_get_type(nodes_obj) != json_type_array) {
        json_object_put(root);
        *count = 0;
        return NULL;
    }
    
    int array_len = json_object_array_length(nodes_obj);
    node_status_t *states = malloc(sizeof(node_status_t) * MAX_NODES);
    *count = 0;
    
    for (int i = 0; i < MAX_NODES; i++) {
        strcpy(states[i].node_id, NODES[i].id);
        states[i].connected = 0;
    }
    
    for (int i = 0; i < array_len; i++) {
        json_object *item = json_object_array_get_idx(nodes_obj, i);
        if (!item || json_object_get_type(item) != json_type_object) {
            continue;
        }
        
        json_object *display_name_obj, *node_id_obj, *remote_ip_obj, *connected_obj;
        const char *display_name = "", *node_id = "", *remote_ip = "";
        int connected = 0;
        
        if (json_object_object_get_ex(item, "displayName", &display_name_obj)) {
            display_name = json_object_get_string(display_name_obj);
        }
        if (json_object_object_get_ex(item, "nodeId", &node_id_obj)) {
            node_id = json_object_get_string(node_id_obj);
        }
        if (json_object_object_get_ex(item, "remoteIp", &remote_ip_obj)) {
            remote_ip = json_object_get_string(remote_ip_obj);
        }
        if (json_object_object_get_ex(item, "connected", &connected_obj)) {
            connected = json_object_get_boolean(connected_obj);
        }
        
        // Check against known nodes
        for (int j = 1; j < MAX_NODES; j++) { // Skip node1
            int found = 0;
            for (int k = 0; NODE_NAMES[j-1][k] != NULL; k++) {
                if (strcasecmp(NODE_NAMES[j-1][k], display_name) == 0 ||
                    strcasecmp(NODE_NAMES[j-1][k], node_id) == 0 ||
                    strcasecmp(NODE_NAMES[j-1][k], remote_ip) == 0) {
                    found = 1;
                    break;
                }
            }
            
            if (found && connected) {
                strcpy(states[j].node_id, NODES[j].id);
                states[j].connected = 1;
                (*count)++;
                break;
            }
        }
    }
    
    // Gateway always available if we got this far
    states[0].connected = 1;
    (*count)++;
    
    json_object_put(root);
    return states;
}

const char* select_node(job_weight_t job_weight, node_status_t* states, int states_count) {
    const char** preferred;
    int preferred_count;
    
    static const char* heavy_nodes[] = {"node1", "node2", "node5", "node6"};
    static const char* medium_nodes[] = {"node1", "node2", "node3", "node6"};
    static const char* light_nodes[] = {"node2", "node1", "node3", "node4"};
    
    switch (job_weight) {
        case HEAVY:
            preferred = heavy_nodes;
            preferred_count = 4;
            break;
        case MEDIUM:
            preferred = medium_nodes;
            preferred_count = 4;
            break;
        case LIGHT:
            preferred = light_nodes;
            preferred_count = 4;
            break;
        default:
            return NULL;
    }
    
    if (!states) {
        return NULL;
    }
    
    for (int i = 0; i < preferred_count; i++) {
        for (int j = 0; j < MAX_NODES; j++) {
            if (strcmp(states[j].node_id, preferred[i]) == 0 && states[j].connected) {
                return preferred[i];
            }
        }
    }
    
    return NULL;
}

int check_node_available(const char* node_id) {
    int count;
    node_status_t* states = fetch_node_status(&count);
    
    if (!states) {
        return 0;
    }
    
    for (int i = 0; i < MAX_NODES; i++) {
        if (strcmp(states[i].node_id, node_id) == 0 && states[i].connected) {
            free(states);
            return 1;
        }
    }
    
    free(states);
    return 0;
}

void generate_uuid(char* uuid_str) {
    uuid_t uuid;
    uuid_generate(uuid);
    uuid_unparse_lower(uuid, uuid_str);
}

typedef struct {
    char job_id[64];
    char source[PATH_MAX];
    char target_language[32];
    char selected_node[32];
    char source_text[1024];
    char source_language[32];
    int has_source_text;
    int has_source_language;
} translation_job_t;

typedef struct {
    char job[PATH_MAX];
    char weight_str[16];
    char selected_node[32];
    char target_langs[MAX_LANGS][32];
    int target_langs_count;
    translation_job_t translation_jobs[MAX_LANGS];
    int translation_jobs_count;
    char status[32];
} dispatch_result_t;

dispatch_result_t dispatch_job(const char* job_script, char target_langs[][32], int target_langs_count,
                               const char* source_text, const char* source_language) {
    dispatch_result_t result;
    
    strcpy(result.job, job_script);
    
    job_weight_t weight = get_job_weight(job_script, target_langs_count);
    switch (weight) {
        case LIGHT: strcpy(result.weight_str, "light"); break;
        case MEDIUM: strcpy(result.weight_str, "medium"); break;
        case HEAVY: strcpy(result.weight_str, "heavy"); break;
    }
    
    int states_count;
    node_status_t* states = fetch_node_status(&states_count);
    const char* selected_node = select_node(weight, states, states_count);
    
    if (selected_node) {
        strcpy(result.selected_node, selected_node);
        strcpy(result.status, "selected");
    } else {
        strcpy(result.selected_node, "none");
        strcpy(result.status, "unavailable");
    }
    
    result.target_langs_count = target_langs_count;
    for (int i = 0; i < target_langs_count && i < MAX_LANGS; i++) {
        strcpy(result.target_langs[i], target_langs[i]);
    }
    
    result.translation_jobs_count = target_langs_count;
    for (int i = 0; i < target_langs_count && i < MAX_LANGS; i++) {
        strcpy(result.translation_jobs[i].source, job_script);
        strcpy(result.translation_jobs[i].target_language, target_langs[i]);
        if (selected_node) {
            strcpy(result.translation_jobs[i].selected_node, selected_node);
        } else {
            strcpy(result.translation_jobs[i].selected_node, "");
        }
        
        generate_uuid(result.translation_jobs[i].job_id);
        
        if (source_text) {
            strcpy(result.translation_jobs[i].source_text, source_text);
            result.translation_jobs[i].has_source_text = 1;
        } else {
            result.translation_jobs[i].has_source_text = 0;
        }
        
        if (source_language) {
            strcpy(result.translation_jobs[i].source_language, source_language);
            result.translation_jobs[i].has_source_language = 1;
        } else {
            result.translation_jobs[i].has_source_language = 0;
        }
    }
    
    if (states) free(states);
    return result;
}

void print_dispatch_info(const dispatch_result_t* result, int execute) {
    printf("📦 Job Dispatch Information\n");
    printf("==================================================\n");
    printf("Job: %s\n", result->job);
    
    struct stat st;
    if (stat(result->job, &st) == 0) {
        printf("Size: %ld bytes\n", st.st_size);
    }
    
    printf("Target langs: ");
    for (int i = 0; i < result->target_langs_count; i++) {
        printf("%s", result->target_langs[i]);
        if (i < result->target_langs_count - 1) printf(", ");
    }
    printf("\n");
    
    printf("Job weight: %s\n", result->weight_str);
    printf("Selected node: %s\n", result->selected_node);
    printf("==================================================\n");
    
    if (execute) {
        fprintf(stderr, "\nTranslation dispatch on %s is not implemented.\n", result->selected_node);
    } else {
        char cmd[PATH_MAX + 256];
        snprintf(cmd, sizeof(cmd), "💡 To execute: %s --job %s --execute", "dispatch_job", result->job);
        printf("\n%s\n", cmd);
    }
}

int main(int argc, char *argv[]) {
    char job_path[PATH_MAX] = "";
    char langs_str[1024] = "perl5";
    char weight_str[16] = "";
    int execute = 0;
    
    // Simple argument parsing
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--job") == 0 || strcmp(argv[i], "-j") == 0) {
            if (i + 1 < argc) {
                strncpy(job_path, argv[++i], sizeof(job_path) - 1);
            }
        } else if (strcmp(argv[i], "--langs") == 0 || strcmp(argv[i], "-l") == 0) {
            if (i + 1 < argc) {
                strncpy(langs_str, argv[++i], sizeof(langs_str) - 1);
            }
        } else if (strcmp(argv[i], "--weight") == 0 || strcmp(argv[i], "-w") == 0) {
            if (i + 1 < argc) {
                strncpy(weight_str, argv[++i], sizeof(weight_str) - 1);
            }
        } else if (strcmp(argv[i], "--execute") == 0 || strcmp(argv[i], "-x") == 0) {
            execute = 1;
        }
    }
    
    if (strlen(job_path) == 0) {
        fprintf(stderr, "❌ Job path is required\n");
        return 1;
    }
    
    if (access(job_path, F_OK) != 0) {
        fprintf(stderr, "❌ Job not found: %s\n", job_path);
        return 1;
    }
    
    // Parse languages
    char target_langs[MAX_LANGS][32];
    int target_langs_count = 0;
    
    char *token = strtok(langs_str, ",");
    while (token && target_langs_count < MAX_LANGS) {
        strncpy(target_langs[target_langs_count], token, sizeof(target_langs[target_langs_count]) - 1);
        target_langs_count++;
        token = strtok(NULL, ",");
    }
    
    // Determine weight
    job_weight_t weight;
    if (strlen(weight_str) > 0) {
        if (strcmp(weight_str, "light") == 0) weight = LIGHT;
        else if (strcmp(weight_str, "medium") == 0) weight = MEDIUM;
        else if (strcmp(weight_str, "heavy") == 0) weight = HEAVY;
        else weight = MEDIUM;
    } else {
        weight = get_job_weight(job_path, target_langs_count);
    }
    
    // Select node
    int states_count;
    node_status_t* states = fetch_node_status(&states_count);
    const char* selected_node = select_node(weight, states, states_count);
    
    // Create result structure for printing
    dispatch_result_t result;
    strcpy(result.job, job_path);
    switch (weight) {
        case LIGHT: strcpy(result.weight_str, "light"); break;
        case MEDIUM: strcpy(result.weight_str, "medium"); break;
        case HEAVY: strcpy(result.weight_str, "heavy"); break;
    }
    if (selected_node) {
        strcpy(result.selected_node, selected_node);
    } else {
        strcpy(result.selected_node, "none");
    }
    
    result.target_langs_count = target_langs_count;
    for (int i = 0; i < target_langs_count && i < MAX_LANGS; i++) {
        strcpy(result.target_langs[i], target_langs[i]);
    }
    
    print_dispatch_info(&result, execute);
    
    if (states) free(states);
    return execute ? 1 : 0;
}
