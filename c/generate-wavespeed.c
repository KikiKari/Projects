// abstraction-provenance: {"artifact_sha256": "313a4cbbcbe4fd7106489c7e447343de9efc296d2d5f3c339ef5ba1b8c0de69d", "source_sha256": "3fed8b6be2b9b8639b55bcaf18c09c0395ac005ab02c27f2dff26ca20b5d5825", "target_language": "c"}
// generate-wavespeed.mjs — portiert nach c
// Quelle: javascript, Onboarding@main:scripts/generate-wavespeed.mjs
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <curl/curl.h>
#include <json-c/json.h>
#include <dirent.h>
#include <errno.h>

#define API_KEY_ENV "WAVESPEED_API_KEY"
#define MAX_PATH 1024
#define MAX_URL 2048
#define MAX_BUFFER 65536

typedef struct {
    char *memory;
    size_t size;
} MemoryStruct;

static size_t WriteMemoryCallback(void *contents, size_t size, size_t nmemb, void *userp) {
    size_t realsize = size * nmemb;
    MemoryStruct *mem = (MemoryStruct *)userp;
    
    char *ptr = realloc(mem->memory, mem->size + realsize + 1);
    if (!ptr) {
        fprintf(stderr, "Nicht genügend Speicher (realloc gab NULL zurück)\n");
        return 0;
    }
    
    mem->memory = ptr;
    memcpy(&(mem->memory[mem->size]), contents, realsize);
    mem->size += realsize;
    mem->memory[mem->size] = 0;
    
    return realsize;
}

int file_exists(const char *path) {
    struct stat buffer;
    return (stat(path, &buffer) == 0);
}

int create_directory(const char *path) {
    struct stat st = {0};
    if (stat(path, &st) == -1) {
        return mkdir(path, 0700);
    }
    return 0;
}

char* read_file(const char *filename) {
    FILE *file = fopen(filename, "rb");
    if (!file) {
        perror("Fehler beim Öffnen der Datei");
        return NULL;
    }
    
    fseek(file, 0, SEEK_END);
    long length = ftell(file);
    fseek(file, 0, SEEK_SET);
    
    char *buffer = malloc(length + 1);
    if (!buffer) {
        fclose(file);
        return NULL;
    }
    
    fread(buffer, 1, length, file);
    buffer[length] = '\0';
    fclose(file);
    
    return buffer;
}

int write_file(const char *filename, const char *data, size_t size) {
    FILE *file = fopen(filename, "wb");
    if (!file) {
        perror("Fehler beim Schreiben der Datei");
        return -1;
    }
    
    fwrite(data, 1, size, file);
    fclose(file);
    return 0;
}

char* base64_encode(const unsigned char *data, size_t input_length) {
    static const char encoding_table[] = {
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
        'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
        'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
        'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
        'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
        'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
        'w', 'x', 'y', 'z', '0', '1', '2', '3',
        '4', '5', '6', '7', '8', '9', '+', '/'
    };
    
    size_t output_length = 4 * ((input_length + 2) / 3);
    char *encoded_data = malloc(output_length + 1);
    if (!encoded_data) return NULL;
    
    size_t i, j;
    for (i = 0, j = 0; i < input_length;) {
        uint32_t octet_a = i < input_length ? data[i++] : 0;
        uint32_t octet_b = i < input_length ? data[i++] : 0;
        uint32_t octet_c = i < input_length ? data[i++] : 0;
        
        uint32_t triple = (octet_a << 0x10) + (octet_b << 0x08) + octet_c;
        
        encoded_data[j++] = encoding_table[(triple >> 3 * 6) & 0x3F];
        encoded_data[j++] = encoding_table[(triple >> 2 * 6) & 0x3F];
        encoded_data[j++] = encoding_table[(triple >> 1 * 6) & 0x3F];
        encoded_data[j++] = encoding_table[(triple >> 0 * 6) & 0x3F];
    }
    
    for (i = 0; i < (3 - input_length % 3) % 3; i++)
        encoded_data[output_length - 1 - i] = '=';
    
    encoded_data[output_length] = '\0';
    return encoded_data;
}

void get_basename(const char *path, char *basename, size_t max_len) {
    const char *last_slash = strrchr(path, '/');
    if (last_slash) {
        strncpy(basename, last_slash + 1, max_len - 1);
        basename[max_len - 1] = '\0';
    } else {
        strncpy(basename, path, max_len - 1);
        basename[max_len - 1] = '\0';
    }
}

int main() {
    const char *key = getenv(API_KEY_ENV);
    if (!key) {
        fprintf(stderr, "WAVESPEED_API_KEY fehlt.\n");
        return 1;
    }
    
    curl_global_init(CURL_GLOBAL_DEFAULT);
    
    // Pfade erstellen
    char raw_dir[MAX_PATH] = "../media-production/raw/";
    char public_dir[MAX_PATH] = "../public/media/";
    char jobs_file[MAX_PATH] = "../media-production/wavespeed-jobs.json";
    char results_file[MAX_PATH] = "../media-production/wavespeed-results.json";
    
    create_directory(raw_dir);
    create_directory(public_dir);
    
    // Jobs laden
    char *jobs_content = read_file(jobs_file);
    if (!jobs_content) {
        fprintf(stderr, "Konnte jobs Datei nicht lesen\n");
        return 1;
    }
    
    json_object *jobs_array = json_tokener_parse(jobs_content);
    if (!jobs_array || !json_object_is_type(jobs_array, json_type_array)) {
        fprintf(stderr, "Ungültiges JSON Format in jobs Datei\n");
        free(jobs_content);
        return 1;
    }
    
    // Log laden oder leeres Array erstellen
    json_object *log_array = NULL;
    char *log_content = read_file(results_file);
    if (log_content) {
        log_array = json_tokener_parse(log_content);
        if (!log_array || !json_object_is_type(log_array, json_type_array)) {
            log_array = json_object_new_array();
        }
        free(log_content);
    } else {
        log_array = json_object_new_array();
    }
    
    int jobs_count = json_object_array_length(jobs_array);
    int completed_jobs = 0;
    
    for (int i = 0; i < jobs_count; i++) {
        json_object *job = json_object_array_get_idx(jobs_array, i);
        
        json_object *id_obj, *output_obj, *prompt_obj, *images_obj, *aspect_ratio_obj;
        if (!json_object_object_get_ex(job, "id", &id_obj) ||
            !json_object_object_get_ex(job, "output", &output_obj) ||
            !json_object_object_get_ex(job, "prompt", &prompt_obj) ||
            !json_object_object_get_ex(job, "images", &images_obj) ||
            !json_object_object_get_ex(job, "aspectRatio", &aspect_ratio_obj)) {
            fprintf(stderr, "Ungültige Job Struktur\n");
            continue;
        }
        
        const char *id = json_object_get_string(id_obj);
        const char *output = json_object_get_string(output_obj);
        const char *prompt = json_object_get_string(prompt_obj);
        const char *aspect_ratio = json_object_get_string(aspect_ratio_obj);
        
        char raw_path[MAX_PATH];
        snprintf(raw_path, sizeof(raw_path), "%s%s.png", raw_dir, id);
        
        char target_path[MAX_PATH];
        snprintf(target_path, sizeof(target_path), "%s%s.png", public_dir, output);
        
        if (file_exists(raw_path)) {
            // Prüfen ob bereits geloggt
            int found = 0;
            int log_count = json_object_array_length(log_array);
            for (int j = 0; j < log_count; j++) {
                json_object *entry = json_object_array_get_idx(log_array, j);
                json_object *entry_id_obj;
                if (json_object_object_get_ex(entry, "id", &entry_id_obj)) {
                    if (strcmp(json_object_get_string(entry_id_obj), id) == 0) {
                        found = 1;
                        break;
                    }
                }
            }
            
            if (!found) {
                json_object *new_entry = json_object_new_object();
                json_object_object_add(new_entry, "id", json_object_new_string(id));
                json_object_object_add(new_entry, "requestId", json_object_new_string("completed-before-resume"));
                json_object_object_add(new_entry, "model", json_object_new_string("google/nano-banana-2/edit"));
                json_object_object_add(new_entry, "resolution", json_object_new_string("4k"));
                json_object_object_add(new_entry, "plannedCostUsd", json_object_new_double(0.14));
                
                char basename[MAX_PATH];
                get_basename(target_path, basename, sizeof(basename));
                json_object_object_add(new_entry, "output", json_object_new_string(basename));
                
                json_object_array_add(log_array, new_entry);
                
                // Log speichern
                const char *log_str = json_object_to_json_string_ext(log_array, JSON_C_TO_STRING_PRETTY);
                write_file(results_file, log_str, strlen(log_str));
            }
            
            printf("Übersprungen: %s ist bereits vorhanden.\n", id);
            completed_jobs++;
            continue;
        }
        
        // Bilder laden und Base64 kodieren
        json_object *images_array = json_object_new_array();
        int images_count = json_object_array_length(images_obj);
        
        for (int j = 0; j < images_count; j++) {
            json_object *image_obj = json_object_array_get_idx(images_obj, j);
            const char *image_url = json_object_get_string(image_obj);
            
            if (strncmp(image_url, "http", 4) == 0 || strncmp(image_url, "data:", 5) == 0) {
                json_object_array_add(images_array, json_object_new_string(image_url));
            } else {
                // Lokale Datei laden und Base64 kodieren
                char image_path[MAX_PATH];
                snprintf(image_path, sizeof(image_path), "../%s", image_url);
                
                FILE *file = fopen(image_path, "rb");
                if (file) {
                    fseek(file, 0, SEEK_END);
                    long file_size = ftell(file);
                    fseek(file, 0, SEEK_SET);
                    
                    unsigned char *file_data = malloc(file_size);
                    fread(file_data, 1, file_size, file);
                    fclose(file);
                    
                    char *base64_data = base64_encode(file_data, file_size);
                    if (base64_data) {
                        char *full_data_url = malloc(strlen(base64_data) + 30);
                        sprintf(full_data_url, "data:image/png;base64,%s", base64_data);
                        json_object_array_add(images_array, json_object_new_string(full_data_url));
                        free(full_data_url);
                        free(base64_data);
                    }
                    free(file_data);
                }
            }
        }
        
        // Request an WaveSpeed API senden
        CURL *curl = curl_easy_init();
        if (!curl) {
            fprintf(stderr, "Konnte cURL nicht initialisieren\n");
            continue;
        }
        
        MemoryStruct chunk = {0};
        chunk.memory = malloc(1);
        chunk.size = 0;
        
        json_object *post_data = json_object_new_object();
        json_object_object_add(post_data, "prompt", json_object_new_string(prompt));
        json_object_object_add(post_data, "images", images_array);
        json_object_object_add(post_data, "aspect_ratio", json_object_new_string(aspect_ratio));
        json_object_object_add(post_data, "resolution", json_object_new_string("4k"));
        json_object_object_add(post_data, "output_format", json_object_new_string("png"));
        json_object_object_add(post_data, "enable_web_search", json_object_new_boolean(0));
        json_object_object_add(post_data, "enable_image_search", json_object_new_boolean(0));
        json_object_object_add(post_data, "enable_sync_mode", json_object_new_boolean(0));
        json_object_object_add(post_data, "enable_base64_output", json_object_new_boolean(0));
        
        const char *post_body = json_object_to_json_string(post_data);
        
        struct curl_slist *headers = NULL;
        char auth_header[256];
        snprintf(auth_header, sizeof(auth_header), "Authorization: Bearer %s", key);
        headers = curl_slist_append(headers, auth_header);
        headers = curl_slist_append(headers, "Content-Type: application/json");
        
        curl_easy_setopt(curl, CURLOPT_URL, "https://api.wavespeed.ai/api/v3/google/nano-banana-2/edit");
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, post_body);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&chunk);
        
        CURLcode res = curl_easy_perform(curl);
        if (res != CURLE_OK) {
            fprintf(stderr, "WaveSpeed submit fehlgeschlagen: %s\n", curl_easy_strerror(res));
            curl_easy_cleanup(curl);
            curl_slist_free_all(headers);
            free(chunk.memory);
            continue;
        }
        
        long response_code;
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response_code);
        
        if (response_code != 200) {
            fprintf(stderr, "WaveSpeed submit fehlgeschlagen: HTTP %ld %s\n", response_code, chunk.memory);
            curl_easy_cleanup(curl);
            curl_slist_free_all(headers);
            free(chunk.memory);
            continue;
        }
        
        json_object *submitted_response = json_tokener_parse(chunk.memory);
        json_object *request_id_obj = NULL;
        const char *request_id = NULL;
        
        json_object *data_obj;
        if (json_object_object_get_ex(submitted_response, "data", &data_obj)) {
            json_object_object_get_ex(data_obj, "id", &request_id_obj);
        } else {
            json_object_object_get_ex(submitted_response, "id", &request_id_obj);
        }
        
        if (request_id_obj) {
            request_id = json_object_get_string(request_id_obj);
        } else {
            fprintf(stderr, "Konnte Request ID nicht extrahieren\n");
            curl_easy_cleanup(curl);
            curl_slist_free_all(headers);
            free(chunk.memory);
            continue;
        }
        
        curl_easy_cleanup(curl);
        curl_slist_free_all(headers);
        free(chunk.memory);
        
        // Polling für Ergebnis
        char result_url[MAX_URL];
        snprintf(result_url, sizeof(result_url), "https://api.wavespeed.ai/api/v3/predictions/%s/result", request_id);
        
        json_object *result = NULL;
        int success = 0;
        
        for (int attempt = 0; attempt < 90; attempt++) {
            sleep(4);
            
            CURL *poll_curl = curl_easy_init();
            if (!poll_curl) {
                fprintf(stderr, "Konnte cURL für Polling nicht initialisieren\n");
                break;
            }
            
            MemoryStruct poll_chunk = {0};
            poll_chunk.memory = malloc(1);
            poll_chunk.size = 0;
            
            struct curl_slist *poll_headers = NULL;
            char poll_auth_header[256];
            snprintf(poll_auth_header, sizeof(poll_auth_header), "Authorization: Bearer %s", key);
            poll_headers = curl_slist_append(poll_headers, poll_auth_header);
            
            curl_easy_setopt(poll_curl, CURLOPT_URL, result_url);
            curl_easy_setopt(poll_curl, CURLOPT_HTTPHEADER, poll_headers);
            curl_easy_setopt(poll_curl, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
            curl_easy_setopt(poll_curl, CURLOPT_WRITEDATA, (void *)&poll_chunk);
            
            CURLcode poll_res = curl_easy_perform(poll_curl);
            if (poll_res == CURLE_OK) {
                long poll_response_code;
                curl_easy_getinfo(poll_curl, CURLINFO_RESPONSE_CODE, &poll_response_code);
                
                if (poll_response_code == 200) {
                    result = json_tokener_parse(poll_chunk.memory);
                    json_object *result_data_obj, *status_obj;
                    
                    if (json_object_object_get_ex(result, "data", &result_data_obj)) {
                        if (json_object_object_get_ex(result_data_obj, "status", &status_obj)) {
                            const char *status = json_object_get_string(status_obj);
                            if (strcmp(status, "completed") == 0) {
                                success = 1;
                                break;
                            } else if (strcmp(status, "failed") == 0) {
                                fprintf(stderr, "WaveSpeed job fehlgeschlagen: %s\n", id);
                                break;
                            }
                        }
                    }
                }
            }
            
            curl_easy_cleanup(poll_curl);
            curl_slist_free_all(poll_headers);
            free(poll_chunk.memory);
        }
        
        if (!success) {
            fprintf(stderr, "Timeout beim Warten auf Ergebnis für Job %s\n", id);
            continue;
        }
        
        // Bild URL extrahieren und herunterladen
        json_object *outputs_obj, *first_output_obj;
        const char *image_url = NULL;
        
        json_object *result_data_obj;
        if (json_object_object_get_ex(result, "data", &result_data_obj)) {
            if (json_object_object_get_ex(result_data_obj, "outputs", &outputs_obj)) {
                if (json_object_array_length(outputs_obj) > 0) {
                    first_output_obj = json_object_array_get_idx(outputs_obj, 0);
                    image_url = json_object_get_string(first_output_obj);
                }
            }
        }
        
        if (!image_url) {
            fprintf(stderr, "Kein Output für %s\n", id);
            continue;
        }
        
        // Bild herunterladen
        CURL *download_curl = curl_easy_init();
        if (!download_curl) {
            fprintf(stderr, "Konnte cURL für Download nicht initialisieren\n");
            continue;
        }
        
        MemoryStruct download_chunk = {0};
        download_chunk.memory = malloc(1);
        download_chunk.size = 0;
        
        curl_easy_setopt(download_curl, CURLOPT_URL, image_url);
        curl_easy_setopt(download_curl, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
        curl_easy_setopt(download_curl, CURLOPT_WRITEDATA, (void *)&download_chunk);
        
        CURLcode download_res = curl_easy_perform(download_curl);
        if (download_res != CURLE_OK) {
            fprintf(stderr, "Download des Bildes fehlgeschlagen: %s\n", curl_easy_strerror(download_res));
            curl_easy_cleanup(download_curl);
            free(download_chunk.memory);
            continue;
        }
        
        // Bild speichern
        write_file(raw_path, download_chunk.memory, download_chunk.size);
        write_file(target_path, download_chunk.memory, download_chunk.size);
        
        curl_easy_cleanup(download_curl);
        free(download_chunk.memory);
        
        // Log aktualisieren
        json_object *new_entry = json_object_new_object();
        json_object_object_add(new_entry, "id", json_object_new_string(id));
        json_object_object_add(new_entry, "requestId", json_object_new_string(request_id));
        json_object_object_add(new_entry, "model", json_object_new_string("google/nano-banana-2/edit"));
        json_object_object_add(new_entry, "resolution", json_object_new_string("4k"));
        json_object_object_add(new_entry, "plannedCostUsd", json_object_new_double(0.14));
        
        char basename[MAX_PATH];
        get_basename(target_path, basename, sizeof(basename));
        json_object_object_add(new_entry, "output", json_object_new_string(basename));
        
        json_object_array_add(log_array, new_entry);
        
        // Log speichern
        const char *log_str = json_object_to_json_string_ext(log_array, JSON_C_TO_STRING_PRETTY);
        write_file(results_file, log_str, strlen(log_str));
        
        printf("Abgeschlossen: %s\n", id);
        completed_jobs++;
    }
    
    // Finale Zusammenfassung
    double total_cost = completed_jobs * 0.14;
    printf("WaveSpeed abgeschlossen: %d Assets, geplante Basiskosten $%.2f.\n", completed_jobs, total_cost);
    
    // Aufräumen
    json_object_put(jobs_array);
    json_object_put(log_array);
    free(jobs_content);
    
    curl_global_cleanup();
    return 0;
}
