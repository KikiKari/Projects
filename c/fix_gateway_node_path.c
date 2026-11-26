// abstraction-provenance: {"artifact_sha256": "aa0cbf1d2ef34f4548a54f38fe2fbe6b54e0976f2dbeb3e7d0d2daea7588747a", "source_sha256": "04518825207cd6ef771c2d840daf0a025f3144f4e384f1d13b46e016570f59df", "target_language": "c"}
// fix_gateway_node_path.sh — portiert nach c
// Quelle: shell, OpenClaw@gateway1:scripts/fix_gateway_node_path.sh
// auch in: OpenClaw@gateway2:scripts/fix_gateway_node_path.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

int main() {
    // Backup der originalen Service-Datei
    char backup_cmd[512];
    time_t now = time(NULL);
    struct tm *tm_info = localtime(&now);
    char timestamp[32];
    strftime(timestamp, sizeof(timestamp), "%Y%m%d_%H%M%S", tm_info);
    
    snprintf(backup_cmd, sizeof(backup_cmd), 
             "cp /etc/systemd/system/openclaw-gateway.service "
             "/etc/systemd/system/openclaw-gateway.service.backup-%s", 
             timestamp);
    
    if (system(backup_cmd) != 0) {
        fprintf(stderr, "Fehler beim Erstellen des Backups\n");
        return 1;
    }

    // Korrektur des Node.js Pfads in der Service-Datei
    // Annahme: Node.js ist unter /usr/bin/node verfuegbar (wie von 'which node' gezeigt)
    const char* sed_cmd = "sed -i 's|/home/openclaw/.nvm/versions/node/v22.22.2/bin/node|/usr/bin/node|g' "
                          "/etc/systemd/system/openclaw-gateway.service";
    
    if (system(sed_cmd) != 0) {
        fprintf(stderr, "Fehler beim Anpassen des Node-Pfads\n");
        return 1;
    }

    // Service neu laden und neu starten
    if (system("systemctl daemon-reload") != 0) {
        fprintf(stderr, "Fehler beim Neuladen der Systemd-Konfiguration\n");
        return 1;
    }
    
    if (system("systemctl restart openclaw-gateway") != 0) {
        fprintf(stderr, "Fehler beim Neustarten des Services\n");
        return 1;
    }

    // Status pruefen
    system("systemctl status openclaw-gateway --no-pager");

    return 0;
}
