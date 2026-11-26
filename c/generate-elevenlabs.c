// abstraction-provenance: {"artifact_sha256": "7644035d9602d60e7e414c5ccc2b1786a949f887a91e150cec00ff8b174e05d4", "source_sha256": "4112b3dbe78c8a495b73f6feaebe05ada553911d2e25f6bd1e2e4d704a6ac1b6", "target_language": "c"}
// generate-elevenlabs.mjs — portiert nach c
// Quelle: javascript, Onboarding@main:scripts/generate-elevenlabs.mjs
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>
#include <sys/stat.h>

// Struktur für HTTP-Antwortdaten
struct MemoryStruct {
    char *memory;
    size_t size;
};

// Callback-Funktion zum Schreiben der HTTP-Antwort
static size_t WriteMemoryCallback(void *contents, size_t size, size_t nmemb, struct MemoryStruct *chunk) {
    size_t realsize = size * nmemb;
    char *ptr = realloc(chunk->memory, chunk->size + realsize + 1);
    
    if (ptr == NULL) {
        fprintf(stderr, "Nicht genügend Speicher\n");
        return 0;
    }
    
    chunk->memory = ptr;
    memcpy(&(chunk->memory[chunk->size]), contents, realsize);
    chunk->size += realsize;
    chunk->memory[chunk->size] = 0;
    
    return realsize;
}

// Funktion zum Erstellen von Verzeichnissen rekursiv
int create_directories(const char *path) {
    char tmp[1024];
    char *p = NULL;
    size_t len;
    
    snprintf(tmp, sizeof(tmp), "%s", path);
    len = strlen(tmp);
    if (tmp[len - 1] == '/') tmp[len - 1] = 0;
    
    for (p = tmp + 1; *p; p++) {
        if (*p == '/') {
            *p = 0;
            mkdir(tmp, 0755);
            *p = '/';
        }
    }
    return mkdir(tmp, 0755);
}

// Funktion zum Schreiben von Binärdaten in eine Datei
int write_binary_file(const char *filename, const char *data, size_t size) {
    FILE *file = fopen(filename, "wb");
    if (!file) {
        perror("Fehler beim Öffnen der Datei");
        return -1;
    }
    
    size_t written = fwrite(data, 1, size, file);
    fclose(file);
    
    if (written != size) {
        fprintf(stderr, "Fehler beim Schreiben der Datei\n");
        return -1;
    }
    
    return 0;
}

// Funktion zum Schreiben von Textdaten in eine Datei
int write_text_file(const char *filename, const char *text) {
    FILE *file = fopen(filename, "w");
    if (!file) {
        perror("Fehler beim Öffnen der Datei");
        return -1;
    }
    
    fprintf(file, "%s", text);
    fclose(file);
    return 0;
}

int main() {
    CURL *curl;
    CURLcode res;
    struct MemoryStruct chunk;
    struct curl_slist *headers = NULL;
    
    // Initialisiere Speicher für Antwortdaten
    chunk.memory = malloc(1);
    chunk.size = 0;
    
    // Initialisiere cURL
    curl_global_init(CURL_GLOBAL_ALL);
    curl = curl_easy_init();
    
    if (!curl) {
        fprintf(stderr, "cURL konnte nicht initialisiert werden\n");
        return 1;
    }
    
    // Hole Umgebungsvariablen
    const char *key = getenv("ELEVENLABS_API_KEY");
    const char *voiceId = getenv("ELEVENLABS_VOICE_ID");
    
    // Setze Standardwert für voiceId falls nicht gesetzt
    if (!voiceId) {
        voiceId = "JBFqnCBsd6RMkjVDRZzb";
    }
    
    // Prüfe ob API-Key vorhanden ist
    if (!key) {
        fprintf(stderr, "ELEVENLABS_API_KEY fehlt.\n");
        return 1;
    }
    
    // Definiere Textinhalt
    const char *text = "Neun Projekte. Zwei Plattformen. Ein Ort, an dem Ideen verbunden und weiterentwickelt werden.";
    
    // Erstelle URL
    char url[512];
    snprintf(url, sizeof(url), "https://api.elevenlabs.io/v1/text-to-speech/%s?output_format=mp3_44100_128", voiceId);
    
    // Setze HTTP-Header
    char api_key_header[256];
    snprintf(api_key_header, sizeof(api_key_header), "xi-api-key: %s", key);
    headers = curl_slist_append(headers, api_key_header);
    headers = curl_slist_append(headers, "Content-Type: application/json");
    
    // Erstelle JSON-Payload
    char payload[1024];
    snprintf(payload, sizeof(payload), 
             "{\"text\":\"%s\",\"model_id\":\"eleven_multilingual_v2\",\"voice_settings\":{\"stability\":0.58,\"similarity_boost\":0.72,\"style\":0.18,\"use_speaker_boost\":true}}", 
             text);
    
    // Konfiguriere cURL
    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, payload);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &chunk);
    
    // Führe HTTP-Anfrage aus
    res = curl_easy_perform(curl);
    
    if (res != CURLE_OK) {
        fprintf(stderr, "cURL-Anfrage fehlgeschlagen: %s\n", curl_easy_strerror(res));
        curl_slist_free_all(headers);
        curl_easy_cleanup(curl);
        free(chunk.memory);
        return 1;
    }
    
    // Prüfe HTTP-Statuscode
    long response_code;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response_code);
    
    if (response_code >= 400) {
        fprintf(stderr, "ElevenLabs fehlgeschlagen: %ld\n", response_code);
        curl_slist_free_all(headers);
        curl_easy_cleanup(curl);
        free(chunk.memory);
        return 1;
    }
    
    // Erstelle Verzeichnisse
    create_directories("public/audio/");
    create_directories("media-production/");
    
    // Schreibe Audio-Datei
    if (write_binary_file("public/audio/project-narration.mp3", chunk.memory, chunk.size) != 0) {
        fprintf(stderr, "Fehler beim Schreiben der Audio-Datei\n");
        curl_slist_free_all(headers);
        curl_easy_cleanup(curl);
        free(chunk.memory);
        return 1;
    }
    
    // Erstelle JSON-Inhalt für Protokolldatei
    char json_content[1024];
    snprintf(json_content, sizeof(json_content), 
             "{\n"
             "  \"model\": \"eleven_multilingual_v2\",\n"
             "  \"voiceId\": \"%s\",\n"
             "  \"characters\": %zu,\n"
             "  \"text\": \"%s\",\n"
             "  \"output\": \"public/audio/project-narration.mp3\"\n"
             "}",
             voiceId, strlen(text), text);
    
    // Schreibe Protokolldatei
    if (write_text_file("media-production/elevenlabs-result.json", json_content) != 0) {
        fprintf(stderr, "Fehler beim Schreiben der Protokolldatei\n");
        curl_slist_free_all(headers);
        curl_easy_cleanup(curl);
        free(chunk.memory);
        return 1;
    }
    
    // Gebe Erfolgsmeldung aus
    printf("ElevenLabs abgeschlossen: %zu Zeichen.\n", strlen(text));
    
    // Räume auf
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    free(chunk.memory);
    curl_global_cleanup();
    
    return 0;
}
