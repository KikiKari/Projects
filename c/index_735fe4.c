// abstraction-provenance: {"artifact_sha256": "27f19a854515c79b91c7aa066581250efcdb2a218ec528a1d5005d15a5e494b5", "source_sha256": "735fe4b2c74b10f265f715cd4e85d574f46a7132d2e592703b5e712888470105", "target_language": "c"}
// index.html — portiert nach c
// Quelle: html, OpenClaw@main:index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>

void write_html_file(const char* filename) {
    FILE* file = fopen(filename, "w");
    if (!file) {
        perror("Fehler beim Öffnen der Datei");
        exit(1);
    }

    fprintf(file,
        "<!DOCTYPE html>\n"
        "<html lang=\"de\">\n"
        "  <head>\n"
        "    <meta charset=\"utf-8\" />\n"
        "    <link rel=\"icon\" href=\"/favicon.ico\" />\n"
        "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />\n"
        "    <meta name=\"theme-color\" content=\"#0b1020\" />\n"
        "    <meta\n"
        "      name=\"description\"\n"
        "      content=\"OpenClaw Startseite für Repository, Dokumentation und Frontend-Branch.\"\n"
        "    />\n"
        "    <link rel=\"apple-touch-icon\" href=\"/logo192.png\" />\n"
        "    <!--\n"
        "      manifest.json provides metadata used when your web app is installed on a\n"
        "      user's mobile device or desktop. See https://developers.google.com/web/fundamentals/web-app-manifest/\n"
        "    -->\n"
        "    <link rel=\"manifest\" href=\"/manifest.json\" />\n"
        "    <title>OpenClaw</title>\n"
        "  </head>\n"
        "  <body>\n"
        "    <noscript>You need to enable JavaScript to run this app.</noscript>\n"
        "    <div id=\"root\"></div>\n"
        "    <!--\n"
        "      This HTML file is a template.\n"
        "      If you open it directly in the browser, you will see an empty page.\n"
        "\n"
        "      You can add webfonts, meta tags, or analytics to this file.\n"
        "      The build step will place the bundled scripts into the <body> tag.\n"
        "\n"
        "      To begin the development, run `npm start` or `yarn start`.\n"
        "      To create a production bundle, use `npm run build` or `yarn build`.\n"
        "    -->\n"
        "  </body>\n"
        "  <script type=\"module\" src=\"/src/index.jsx\"></script>\n"
        "</html>\n"
    );

    fclose(file);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Verwendung: %s <dateiname>\n", argv[0]);
        return 1;
    }

    write_html_file(argv[1]);
    return 0;
}
