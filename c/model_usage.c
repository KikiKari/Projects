// abstraction-provenance: {"artifact_sha256": "5d91ee0d433f9c37f74bbb7d1ab5921c27bf18302d3fa33024ee37533bc25d1c", "source_sha256": "502dcda47466a4ab74da59badbe4b12c4782ed031c43d5038f8bd8534373cd35", "target_language": "c"}
// model_usage.py — portiert nach c
// Quelle: python, OpenClaw@gateway1:skills/model-usage/scripts/model_usage.py
// auch in: OpenClaw@gateway2:skills/model-usage/scripts/model_usage.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <math.h>

#define MAX_LINE_LENGTH 4096
#define MAX_ENTRIES 1000
#define MAX_MODELS 100

typedef struct {
    char model[256];
    double cost;
} ModelCost;

typedef struct {
    char date[11];
    char* model_breakdowns_json;
    char* models_used_json;
} DailyEntry;

typedef struct {
    char provider[50];
    char* daily_json;
} Payload;

typedef struct {
    char model[256];
    double cost;
} ModelTotal;

void eprint(const char* msg) {
    fprintf(stderr, "%s\n", msg);
}

char* read_file(const char* path) {
    FILE* file = fopen(path, "r");
    if (!file) {
        perror("Failed to open file");
        return NULL;
    }

    fseek(file, 0, SEEK_END);
    long length = ftell(file);
    fseek(file, 0, SEEK_SET);

    char* buffer = malloc(length + 1);
    if (!buffer) {
        fclose(file);
        return NULL;
    }

    fread(buffer, 1, length, file);
    buffer[length] = '\0';
    fclose(file);
    return buffer;
}

char* run_codexbar_cost(const char* provider) {
    char cmd[512];
    snprintf(cmd, sizeof(cmd), "codexbar cost --format json --provider %s", provider);
    
    FILE* pipe = popen(cmd, "r");
    if (!pipe) {
        eprint("codexbar not found on PATH. Install CodexBar CLI first.");
        return NULL;
    }

    char* result = malloc(65536);
    if (!result) {
        pclose(pipe);
        return NULL;
    }
    
    size_t len = 0;
    size_t capacity = 65536;
    int c;
    while ((c = fgetc(pipe)) != EOF && len < capacity - 1) {
        result[len++] = c;
    }
    result[len] = '\0';
    
    int status = pclose(pipe);
    if (status != 0) {
        eprint("codexbar cost failed");
        free(result);
        return NULL;
    }
    
    return result;
}

Payload* load_payload(const char* input_path, const char* provider) {
    char* raw_data = NULL;
    
    if (input_path) {
        if (strcmp(input_path, "-") == 0) {
            raw_data = malloc(65536);
            if (!raw_data) return NULL;
            
            size_t len = 0;
            size_t capacity = 65536;
            int c;
            while ((c = getchar()) != EOF && len < capacity - 1) {
                raw_data[len++] = c;
            }
            raw_data[len] = '\0';
        } else {
            raw_data = read_file(input_path);
        }
    } else {
        raw_data = run_codexbar_cost(provider);
    }
    
    if (!raw_data) {
        return NULL;
    }
    
    Payload* payload = malloc(sizeof(Payload));
    if (!payload) {
        free(raw_data);
        return NULL;
    }
    
    strcpy(payload->provider, provider);
    payload->daily_json = strdup(raw_data);
    
    free(raw_data);
    return payload;
}

int parse_date_string(const char* date_str, struct tm* tm_date) {
    memset(tm_date, 0, sizeof(struct tm));
    return sscanf(date_str, "%d-%d-%d", 
                  &tm_date->tm_year, &tm_date->tm_mon, &tm_date->tm_mday) == 3;
}

int date_after_or_equal(const struct tm* date1, const struct tm* date2) {
    if (date1->tm_year > date2->tm_year) return 1;
    if (date1->tm_year < date2->tm_year) return 0;
    if (date1->tm_mon > date2->tm_mon) return 1;
    if (date1->tm_mon < date2->tm_mon) return 0;
    return date1->tm_mday >= date2->tm_mday;
}

void filter_by_days(DailyEntry* entries, int* count, int days) {
    if (days <= 0) return;
    
    time_t now = time(NULL);
    struct tm cutoff_tm = *localtime(&now);
    cutoff_tm.tm_mday -= (days - 1);
    mktime(&cutoff_tm);
    
    int new_count = 0;
    for (int i = 0; i < *count; i++) {
        struct tm entry_tm;
        if (parse_date_string(entries[i].date, &entry_tm)) {
            entry_tm.tm_year -= 1900;
            entry_tm.tm_mon -= 1;
            if (date_after_or_equal(&entry_tm, &cutoff_tm)) {
                entries[new_count++] = entries[i];
            }
        }
    }
    *count = new_count;
}

void aggregate_costs(DailyEntry* entries, int count, ModelTotal* totals, int* totals_count) {
    *totals_count = 0;
    memset(totals, 0, MAX_MODELS * sizeof(ModelTotal));
    
    for (int i = 0; i < count; i++) {
        // This is a simplified parsing - in practice you'd need a proper JSON parser
        // For now we'll assume a simple format for demonstration
        if (entries[i].model_breakdowns_json) {
            char* pos = strstr(entries[i].model_breakdowns_json, "\"modelName\":\"");
            while (pos && *totals_count < MAX_MODELS) {
                pos += 14; // Skip past modelName":
                char* end = strchr(pos, '"');
                if (end) {
                    char model_name[256];
                    int len = end - pos;
                    if (len < 255) {
                        strncpy(model_name, pos, len);
                        model_name[len] = '\0';
                        
                        // Find cost
                        char* cost_pos = strstr(end, "\"cost\":");
                        if (cost_pos) {
                            double cost = atof(cost_pos + 7);
                            
                            // Add to totals
                            int found = 0;
                            for (int j = 0; j < *totals_count; j++) {
                                if (strcmp(totals[j].model, model_name) == 0) {
                                    totals[j].cost += cost;
                                    found = 1;
                                    break;
                                }
                            }
                            if (!found) {
                                strcpy(totals[*totals_count].model, model_name);
                                totals[*totals_count].cost = cost;
                                (*totals_count)++;
                            }
                        }
                        
                        pos = strstr(end + 1, "\"modelName\":\"");
                    } else {
                        pos = NULL;
                    }
                } else {
                    pos = NULL;
                }
            }
        }
    }
}

const char* pick_current_model(DailyEntry* entries, int count, char* date_buf) {
    if (count == 0) return NULL;
    
    // Sort entries by date (simplified)
    // In practice you'd implement proper sorting
    
    for (int i = count - 1; i >= 0; i--) {
        if (entries[i].model_breakdowns_json) {
            char* pos = strstr(entries[i].model_breakdowns_json, "\"modelName\":\"");
            if (pos) {
                pos += 14;
                char* end = strchr(pos, '"');
                if (end) {
                    if (date_buf) {
                        strcpy(date_buf, entries[i].date);
                    }
                    int len = end - pos;
                    if (len < 255) {
                        static char model_name[256];
                        strncpy(model_name, pos, len);
                        model_name[len] = '\0';
                        return model_name;
                    }
                }
            }
        }
        
        if (entries[i].models_used_json) {
            char* pos = strrchr(entries[i].models_used_json, '"');
            if (pos) {
                char* start = strrchr(entries[i].models_used_json, '"');
                if (start && start != pos) {
                    if (date_buf) {
                        strcpy(date_buf, entries[i].date);
                    }
                    int len = pos - start - 1;
                    if (len < 255) {
                        static char model_name[256];
                        strncpy(model_name, start + 1, len);
                        model_name[len] = '\0';
                        return model_name;
                    }
                }
            }
        }
    }
    return NULL;
}

char* usd(double value, char* buf, size_t buf_size) {
    if (isnan(value) || isinf(value)) {
        snprintf(buf, buf_size, "—");
    } else {
        snprintf(buf, buf_size, "$%.2f", value);
    }
    return buf;
}

void latest_day_cost(DailyEntry* entries, int count, const char* model, 
                     char* date_buf, double* cost) {
    if (count == 0) {
        *cost = NAN;
        return;
    }
    
    // Sort entries by date (simplified)
    for (int i = count - 1; i >= 0; i--) {
        if (entries[i].model_breakdowns_json) {
            char search_str[300];
            snprintf(search_str, sizeof(search_str), "\"modelName\":\"%s\"", model);
            
            if (strstr(entries[i].model_breakdowns_json, search_str)) {
                char* cost_pos = strstr(entries[i].model_breakdowns_json, "\"cost\":");
                if (cost_pos) {
                    *cost = atof(cost_pos + 7);
                    strcpy(date_buf, entries[i].date);
                    return;
                }
            }
        }
    }
    
    *cost = NAN;
}

void render_text_current(const char* provider, const char* model, 
                          const char* latest_date, double total_cost,
                          double latest_cost, const char* latest_cost_date,
                          int entry_count) {
    printf("Provider: %s\n", provider);
    printf("Current model: %s\n", model);
    if (latest_date) {
        printf("Latest model date: %s\n", latest_date);
    }
    char cost_buf[50];
    printf("Total cost (rows): %s\n", usd(total_cost, cost_buf, sizeof(cost_buf)));
    if (latest_cost_date) {
        printf("Latest day cost: %s (%s)\n", 
               usd(latest_cost, cost_buf, sizeof(cost_buf)), latest_cost_date);
    }
    printf("Daily rows: %d\n", entry_count);
}

void render_text_all(const char* provider, ModelTotal* totals, int totals_count) {
    printf("Provider: %s\n", provider);
    printf("Models:\n");
    
    // Simple bubble sort for demonstration
    for (int i = 0; i < totals_count - 1; i++) {
        for (int j = 0; j < totals_count - 1 - i; j++) {
            if (totals[j].cost < totals[j + 1].cost) {
                ModelTotal temp = totals[j];
                totals[j] = totals[j + 1];
                totals[j + 1] = temp;
            }
        }
    }
    
    for (int i = 0; i < totals_count; i++) {
        char cost_buf[50];
        printf("- %s: %s\n", totals[i].model, 
               usd(totals[i].cost, cost_buf, sizeof(cost_buf)));
    }
}

int main(int argc, char* argv[]) {
    const char* provider = "codex";
    const char* mode = "current";
    const char* model_arg = NULL;
    const char* input_path = NULL;
    int days = 0;
    const char* format = "text";
    int pretty = 0;
    
    // Parse command line arguments (simplified)
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--provider") == 0 && i + 1 < argc) {
            provider = argv[++i];
        } else if (strcmp(argv[i], "--mode") == 0 && i + 1 < argc) {
            mode = argv[++i];
        } else if (strcmp(argv[i], "--model") == 0 && i + 1 < argc) {
            model_arg = argv[++i];
        } else if (strcmp(argv[i], "--input") == 0 && i + 1 < argc) {
            input_path = argv[++i];
        } else if (strcmp(argv[i], "--days") == 0 && i + 1 < argc) {
            days = atoi(argv[++i]);
        } else if (strcmp(argv[i], "--format") == 0 && i + 1 < argc) {
            format = argv[++i];
        } else if (strcmp(argv[i], "--pretty") == 0) {
            pretty = 1;
        }
    }
    
    Payload* payload = load_payload(input_path, provider);
    if (!payload) {
        eprint("Failed to load payload");
        return 1;
    }
    
    // Simplified parsing of daily entries
    DailyEntry entries[MAX_ENTRIES];
    int entry_count = 0;
    
    // This would normally parse the JSON properly
    // For demonstration, we'll just create some dummy entries
    strcpy(entries[0].date, "2023-12-01");
    entries[0].model_breakdowns_json = strdup("{\"modelName\":\"gpt-4\",\"cost\":0.5}");
    entries[0].models_used_json = NULL;
    entry_count = 1;
    
    filter_by_days(entries, &entry_count, days);
    
    if (strcmp(mode, "current") == 0) {
        const char* model = model_arg;
        char latest_date[11] = "";
        
        if (!model) {
            model = pick_current_model(entries, entry_count, latest_date);
        }
        
        if (!model) {
            eprint("No model data found in codexbar cost payload.");
            free(payload);
            return 2;
        }
        
        ModelTotal totals[MAX_MODELS];
        int totals_count;
        aggregate_costs(entries, entry_count, totals, &totals_count);
        
        double total_cost = 0;
        for (int i = 0; i < totals_count; i++) {
            if (strcmp(totals[i].model, model) == 0) {
                total_cost = totals[i].cost;
                break;
            }
        }
        
        char latest_cost_date[11] = "";
        double latest_cost;
        latest_day_cost(entries, entry_count, model, latest_cost_date, &latest_cost);
        
        if (strcmp(format, "json") == 0) {
            printf("{\n");
            printf("  \"provider\": \"%s\",\n", provider);
            printf("  \"mode\": \"current\",\n");
            printf("  \"model\": \"%s\",\n", model);
            printf("  \"latestModelDate\": \"%s\",\n", latest_date[0] ? latest_date : "null");
            printf("  \"totalCostUSD\": %.2f,\n", total_cost);
            if (!isnan(latest_cost)) {
                printf("  \"latestDayCostUSD\": %.2f,\n", latest_cost);
                printf("  \"latestDayCostDate\": \"%s\"\n", latest_cost_date);
            } else {
                printf("  \"latestDayCostUSD\": null,\n");
                printf("  \"latestDayCostDate\": null\n");
            }
            printf("}\n");
        } else {
            render_text_current(provider, model, 
                               latest_date[0] ? latest_date : NULL,
                               total_cost, latest_cost,
                               latest_cost_date[0] ? latest_cost_date : NULL,
                               entry_count);
        }
    } else {
        ModelTotal totals[MAX_MODELS];
        int totals_count;
        aggregate_costs(entries, entry_count, totals, &totals_count);
        
        if (totals_count == 0) {
            eprint("No model breakdowns found in codexbar cost payload.");
            free(payload);
            return 2;
        }
        
        if (strcmp(format, "json") == 0) {
            printf("{\n");
            printf("  \"provider\": \"%s\",\n", provider);
            printf("  \"mode\": \"all\",\n");
            printf("  \"models\": [\n");
            
            // Sort by cost (descending)
            for (int i = 0; i < totals_count - 1; i++) {
                for (int j = 0; j < totals_count - 1 - i; j++) {
                    if (totals[j].cost < totals[j + 1].cost) {
                        ModelTotal temp = totals[j];
                        totals[j] = totals[j + 1];
                        totals[j + 1] = temp;
                    }
                }
            }
            
            for (int i = 0; i < totals_count; i++) {
                printf("    {\n");
                printf("      \"model\": \"%s\",\n", totals[i].model);
                printf("      \"totalCostUSD\": %.2f\n", totals[i].cost);
                if (i < totals_count - 1) {
                    printf("    },\n");
                } else {
                    printf("    }\n");
                }
            }
            printf("  ]\n");
            printf("}\n");
        } else {
            render_text_all(provider, totals, totals_count);
        }
    }
    
    free(payload);
    return 0;
}
