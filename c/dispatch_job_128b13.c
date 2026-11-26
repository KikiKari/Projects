// abstraction-provenance: {"artifact_sha256": "ec26fa7642711da0c5b843ebd5380cbc5d23a1e50da2740540e696ad650d171f", "source_sha256": "128b137e5c7d86f81ea7fdb61718540c70e4ed38de4430ae6a23a5739962c024", "target_language": "c"}
// dispatch_job.py — portiert nach c
// Quelle: python, OpenClaw@gateway2:skills/multi-nodes-utils/scripts/dispatch_job.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/wait.h>

/**
 * Job Dispatcher - Verteilt Jobs auf passende Nodes
 */

// Node-Konfiguration
typedef struct {
    const char* id;
    int always_available;
    const char* capacity;
    int priority;
    const char* device;
} Node;

Node NODES[] = {
    {"node1", 1, "medium", 2, NULL},
    {"node2", 1, "medium", 3, NULL},
    {"node3", 0, "medium", 4, NULL},
    {"node5", 0, "low", 5, "Redmi Note 11S"},
    {"node7", 1, "high", 1, NULL}
};

int NODE_COUNT = 5;

typedef struct {
    const char* job;
    const char* weight;
    const char* selected_node;
    char** target_langs;
    int target_langs_count;
    const char* status;
} DispatchResult;

const char* get_job_weight(const char* script_path, int target_langs_count) {
    /** Bewertet Job-Gewicht */
    struct stat st;
    if (stat(script_path, &st) != 0) {
        return "medium";
    }
    
    long script_size = st.st_size;
    long total_work = script_size * target_langs_count;
    
    if (total_work > 50000) {  // > 50KB
        return "heavy";
    } else if (total_work > 10000) {  // > 10KB
        return "medium";
    } else {
        return "light";
    }
}

int check_node_available(const char* node_id) {
    /** Prüft ob Node erreichbar ist */
    Node* node = NULL;
    for (int i = 0; i < NODE_COUNT; i++) {
        if (strcmp(NODES[i].id, node_id) == 0) {
            node = &NODES[i];
            break;
        }
    }
    
    if (!node) {
        return 0;
    }
    
    // Nicht immer-verfügbare Nodes nur wenn explizit requested
    if (!node->always_available) {
        // Für light-jobs prüfen wir ob online
        if (strcmp(node_id, "node5") == 0) {  // Redmi
            // _check_mobile_online simulation
            pid_t pid = fork();
            if (pid == 0) {
                execlp("openclaw", "openclaw", "nodes", "status", "node5", NULL);
                exit(1);
            } else if (pid > 0) {
                int status;
                waitpid(pid, &status, 0);
                return WIFEXITED(status) && WEXITSTATUS(status) == 0;
            }
            return 0;
        }
        return 0;
    }
    
    // Für immer-verfügbare Nodes: prüfe ob wirklich online
    pid_t pid = fork();
    if (pid == 0) {
        execlp("openclaw", "openclaw", "nodes", "status", node_id, NULL);
        exit(1);
    } else if (pid > 0) {
        int status;
        waitpid(pid, &status, 0);
        return WIFEXITED(status) && WEXITSTATUS(status) == 0;
    }
    return node->always_available;
}

const char* select_node(const char* job_weight) {
    /** Wählt besten Node basierend auf Job-Gewicht */
    const char** preferred = NULL;
    int preferred_count = 0;
    
    if (strcmp(job_weight, "heavy") == 0) {
        // Schwere Jobs → Node 7 (Docker), dann Node 2, dann Node 1
        static const char* heavy_nodes[] = {"node7", "node2", "node1"};
        preferred = heavy_nodes;
        preferred_count = 3;
    } else if (strcmp(job_weight, "medium") == 0) {
        // Mittlere Jobs → Stable Nodes
        static const char* medium_nodes[] = {"node2", "node1", "node7"};
        preferred = medium_nodes;
        preferred_count = 3;
    } else {  // light
        // Leichte Jobs → Mobile/verfügbare Nodes
        static const char* light_nodes[] = {"node5", "node1", "node2"};
        preferred = light_nodes;
        preferred_count = 3;
    }
    
    // Prüfe Verfügbarkeit
    for (int i = 0; i < preferred_count; i++) {
        if (check_node_available(preferred[i])) {
            return preferred[i];
        }
    }
    
    // Fallback
    return "node1";
}

DispatchResult dispatch(const char* job_script, char** target_langs, int target_langs_count) {
    /** Dispatched Job und gibt Info zurück */
    if (!target_langs) {
        static char* default_langs[] = {"perl5"};
        target_langs = default_langs;
        target_langs_count = 1;
    }
    
    const char* weight = get_job_weight(job_script, target_langs_count);
    const char* selected_node = select_node(weight);
    
    DispatchResult result;
    result.job = job_script;
    result.weight = weight;
    result.selected_node = selected_node;
    result.target_langs = target_langs;
    result.target_langs_count = target_langs_count;
    result.status = "dispatched";
    
    return result;
}

void print_usage(const char* prog_name) {
    printf("Usage: %s --job JOB_SCRIPT [--langs LANGS] [--weight WEIGHT] [--execute]\n", prog_name);
    printf("Dispatch job to optimal node\n");
    printf("\nOptions:\n");
    printf("  --job, -j       Path to job script\n");
    printf("  --langs, -l     Comma-separated target languages (default: perl5)\n");
    printf("  --weight, -w    Force job weight (light, medium, heavy)\n");
    printf("  --execute, -x   Actually execute on selected node\n");
}

int main(int argc, char* argv[]) {
    const char* job_path = NULL;
    char* langs_str = "perl5";
    const char* weight_override = NULL;
    int execute = 0;
    
    // Simple argument parsing
    for (int i = 1; i < argc; i++) {
        if ((strcmp(argv[i], "--job") == 0 || strcmp(argv[i], "-j") == 0) && i + 1 < argc) {
            job_path = argv[++i];
        } else if ((strcmp(argv[i], "--langs") == 0 || strcmp(argv[i], "-l") == 0) && i + 1 < argc) {
            langs_str = argv[++i];
        } else if ((strcmp(argv[i], "--weight") == 0 || strcmp(argv[i], "-w") == 0) && i + 1 < argc) {
            weight_override = argv[++i];
        } else if (strcmp(argv[i], "--execute") == 0 || strcmp(argv[i], "-x") == 0) {
            execute = 1;
        } else if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
            print_usage(argv[0]);
            return 0;
        }
    }
    
    if (!job_path) {
        fprintf(stderr, "❌ Job path is required\n");
        print_usage(argv[0]);
        return 1;
    }
    
    // Check if job exists
    if (access(job_path, F_OK) != 0) {
        fprintf(stderr, "❌ Job not found: %s\n", job_path);
        return 1;
    }
    
    // Parse target languages
    char** target_langs = malloc(sizeof(char*) * 10); // Max 10 languages
    int lang_count = 0;
    char* token = strtok(langs_str, ",");
    while (token && lang_count < 10) {
        target_langs[lang_count++] = strdup(token);
        token = strtok(NULL, ",");
    }
    
    // Determine weight
    const char* weight;
    if (weight_override) {
        weight = weight_override;
    } else {
        weight = get_job_weight(job_path, lang_count);
    }
    
    // Select node
    const char* selected_node = select_node(weight);
    
    // Get file size
    struct stat st;
    stat(job_path, &st);
    long file_size = st.st_size;
    
    // Output
    printf("📦 Job Dispatch Information\n");
    printf("==================================================\n");
    printf("Job: %s\n", job_path);
    printf("Size: %ld bytes\n", file_size);
    printf("Target langs: ");
    for (int i = 0; i < lang_count; i++) {
        printf("%s%s", target_langs[i], (i < lang_count - 1) ? ", " : "");
    }
    printf("\n");
    printf("Job weight: %s\n", weight);
    printf("Selected node: %s\n", selected_node);
    printf("==================================================\n");
    
    if (execute) {
        printf("\n🚀 Executing on %s...\n", selected_node);
        printf("(Remote execution not yet implemented)\n");
    } else {
        printf("\n💡 To execute: %s --job %s --execute\n", argv[0], job_path);
    }
    
    // Cleanup
    for (int i = 0; i < lang_count; i++) {
        free(target_langs[i]);
    }
    free(target_langs);
    
    return 0;
}
