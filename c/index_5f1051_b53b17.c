// abstraction-provenance: {"artifact_sha256": "fb7d9472fd190ed8d8acb391b09c3c30b67bbb6f4471ef73f63e3f65cc94e8fe", "source_sha256": "b53b17806f268da8dc7115668f5a04c5ff39edd9b2305ba40f1b04e598002f81", "target_language": "c"}
// index_5f1051.css — portiert nach c
// Quelle: css, Projects@abstractions:css/index_5f1051.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_css_file(const char* filename) {
    FILE* file = fopen(filename, "w");
    if (!file) {
        perror("Failed to open file");
        exit(EXIT_FAILURE);
    }

    // Write the CSS content
    fprintf(file, "/* abstraction-provenance: {\"artifact_sha256\": \"cdcc9e9ffa451d8c92fd763b0dfd0b1974003a826baaae753e2f347cfd3c9f57\", \"source_sha256\": \"5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988\", \"target_language\": \"css\"} */\n");
    fprintf(file, "/* index.html — portiert nach css */\n");
    fprintf(file, "/* Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html */\n");
    fprintf(file, "/* auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html */\n");
    fprintf(file, "/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */\n\n");

    fprintf(file, "body {\n");
    fprintf(file, "    background-color: white;\n");
    fprintf(file, "    color: black;\n");
    fprintf(file, "    margin: 0;\n");
    fprintf(file, "    padding: 0;\n");
    fprintf(file, "    font-family: Arial, sans-serif;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "table {\n");
    fprintf(file, "    border-collapse: collapse;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".globalnav-container {\n");
    fprintf(file, "    width: 780px;\n");
    fprintf(file, "    border: 0;\n");
    fprintf(file, "    cellpadding: 0;\n");
    fprintf(file, "    cellspacing: 0;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".header-left {\n");
    fprintf(file, "    vertical-align: top;\n");
    fprintf(file, "    text-align: left;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".header-right {\n");
    fprintf(file, "    vertical-align: top;\n");
    fprintf(file, "    text-align: right;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".logo-link {\n");
    fprintf(file, "    text-decoration: none;\n");
    fprintf(file, "    border: 0;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".logo-image {\n");
    fprintf(file, "    border: 0;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".hosted-by {\n");
    fprintf(file, "    font-size: 1px;\n");
    fprintf(file, "    text-decoration: none;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".active-state-logo {\n");
    fprintf(file, "    border: 0;\n");
    fprintf(file, "    title: \"This site is hosted by ActiveState\";\n");
    fprintf(file, "}\n\n");

    fprintf(file, "#globalnav {\n");
    fprintf(file, "    clear: both;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "#globalnav ul {\n");
    fprintf(file, "    list-style-type: none;\n");
    fprintf(file, "    margin: 0;\n");
    fprintf(file, "    padding: 0;\n");
    fprintf(file, "    overflow: hidden;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "#globalnav li {\n");
    fprintf(file, "    float: left;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "#globalnav a {\n");
    fprintf(file, "    display: block;\n");
    fprintf(file, "    padding: 8px 16px;\n");
    fprintf(file, "    text-decoration: none;\n");
    fprintf(file, "    color: #000;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "#globalnav a.here {\n");
    fprintf(file, "    background-color: #3163CE;\n");
    fprintf(file, "    color: white;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".divider-top {\n");
    fprintf(file, "    border-top: 2px solid #3163CE;\n");
    fprintf(file, "    width: 780px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".search-table {\n");
    fprintf(file, "    width: 780px;\n");
    fprintf(file, "    border: 0;\n");
    fprintf(file, "    cellpadding: 2;\n");
    fprintf(file, "    cellspacing: 0;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".search-container {\n");
    fprintf(file, "    display: table-cell;\n");
    fprintf(file, "    vertical-align: middle;\n");
    fprintf(file, "    margin: 0px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".search-form {\n");
    fprintf(file, "    display: inline;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".search-input {\n");
    fprintf(file, "    size: 20;\n");
    fprintf(file, "    maxlength: 255;\n");
    fprintf(file, "    value: \"\";\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".submit-button {\n");
    fprintf(file, "    border: 0;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".hidden-input {\n");
    fprintf(file, "    display: none;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".banner {\n");
    fprintf(file, "    text-align: right;\n");
    fprintf(file, "    font-weight: bold;\n");
    fprintf(file, "    margin: 0;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".divider-yellow {\n");
    fprintf(file, "    border-top: 1px solid #FFCE00;\n");
    fprintf(file, "    margin-bottom: 2px;\n");
    fprintf(file, "    width: 780px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".content-table {\n");
    fprintf(file, "    width: 780px;\n");
    fprintf(file, "    border: 0;\n");
    fprintf(file, "    cellpadding: 0;\n");
    fprintf(file, "    cellspacing: 0;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".keylist {\n");
    fprintf(file, "    margin: 0;\n");
    fprintf(file, "    padding: 0;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".keylist dt {\n");
    fprintf(file, "    font-weight: bold;\n");
    fprintf(file, "    margin-top: 10px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".keylist dd {\n");
    fprintf(file, "    margin-left: 20px;\n");
    fprintf(file, "    margin-bottom: 10px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".footer {\n");
    fprintf(file, "    text-align: center;\n");
    fprintf(file, "    clear: both;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".footer small {\n");
    fprintf(file, "    font-size: 12px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".footer a {\n");
    fprintf(file, "    text-decoration: none;\n");
    fprintf(file, "    color: #000;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".footer a:hover {\n");
    fprintf(file, "    text-decoration: underline;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".clear {\n");
    fprintf(file, "    clear: both;\n");
    fprintf(file, "}\n");

    fclose(file);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <filename>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    write_css_file(argv[1]);
    return 0;
}
