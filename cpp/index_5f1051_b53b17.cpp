// abstraction-provenance: {"artifact_sha256": "837706a348f854afbd8acfdf045914c86108eaf4034fa0b5cc840bdcdb7896ef", "source_sha256": "b53b17806f268da8dc7115668f5a04c5ff39edd9b2305ba40f1b04e598002f81", "target_language": "cpp"}
// index_5f1051.css — portiert nach cpp
// Quelle: css, Projects@abstractions:css/index_5f1051.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

void writeCSS(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Fehler beim Öffnen der Datei: " << filename << std::endl;
        return;
    }

    // Kopfkommentare
    file << "/* abstraction-provenance: {\"artifact_sha256\": \"cdcc9e9ffa451d8c92fd763b0dfd0b1974003a826baaae753e2f347cfd3c9f57\", \"source_sha256\": \"5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988\", \"target_language\": \"css\"} */\n";
    file << "/* index.html — portiert nach css */\n";
    file << "/* Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html */\n";
    file << "/* auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html */\n";
    file << "/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */\n\n";

    // body
    file << "body {\n";
    file << "    background-color: white;\n";
    file << "    color: black;\n";
    file << "    margin: 0;\n";
    file << "    padding: 0;\n";
    file << "    font-family: Arial, sans-serif;\n";
    file << "}\n\n";

    // table
    file << "table {\n";
    file << "    border-collapse: collapse;\n";
    file << "}\n\n";

    // .globalnav-container
    file << ".globalnav-container {\n";
    file << "    width: 780px;\n";
    file << "    border: 0;\n";
    file << "    cellpadding: 0;\n";
    file << "    cellspacing: 0;\n";
    file << "}\n\n";

    // .header-left
    file << ".header-left {\n";
    file << "    vertical-align: top;\n";
    file << "    text-align: left;\n";
    file << "}\n\n";

    // .header-right
    file << ".header-right {\n";
    file << "    vertical-align: top;\n";
    file << "    text-align: right;\n";
    file << "}\n\n";

    // .logo-link
    file << ".logo-link {\n";
    file << "    text-decoration: none;\n";
    file << "    border: 0;\n";
    file << "}\n\n";

    // .logo-image
    file << ".logo-image {\n";
    file << "    border: 0;\n";
    file << "}\n\n";

    // .hosted-by
    file << ".hosted-by {\n";
    file << "    font-size: 1px;\n";
    file << "    text-decoration: none;\n";
    file << "}\n\n";

    // .active-state-logo
    file << ".active-state-logo {\n";
    file << "    border: 0;\n";
    file << "    title: \"This site is hosted by ActiveState\";\n";
    file << "}\n\n";

    // #globalnav
    file << "#globalnav {\n";
    file << "    clear: both;\n";
    file << "}\n\n";

    // #globalnav ul
    file << "#globalnav ul {\n";
    file << "    list-style-type: none;\n";
    file << "    margin: 0;\n";
    file << "    padding: 0;\n";
    file << "    overflow: hidden;\n";
    file << "}\n\n";

    // #globalnav li
    file << "#globalnav li {\n";
    file << "    float: left;\n";
    file << "}\n\n";

    // #globalnav a
    file << "#globalnav a {\n";
    file << "    display: block;\n";
    file << "    padding: 8px 16px;\n";
    file << "    text-decoration: none;\n";
    file << "    color: #000;\n";
    file << "}\n\n";

    // #globalnav a.here
    file << "#globalnav a.here {\n";
    file << "    background-color: #3163CE;\n";
    file << "    color: white;\n";
    file << "}\n\n";

    // .divider-top
    file << ".divider-top {\n";
    file << "    border-top: 2px solid #3163CE;\n";
    file << "    width: 780px;\n";
    file << "}\n\n";

    // .search-table
    file << ".search-table {\n";
    file << "    width: 780px;\n";
    file << "    border: 0;\n";
    file << "    cellpadding: 2;\n";
    file << "    cellspacing: 0;\n";
    file << "}\n\n";

    // .search-container
    file << ".search-container {\n";
    file << "    display: table-cell;\n";
    file << "    vertical-align: middle;\n";
    file << "    margin: 0px;\n";
    file << "}\n\n";

    // .search-form
    file << ".search-form {\n";
    file << "    display: inline;\n";
    file << "}\n\n";

    // .search-input
    file << ".search-input {\n";
    file << "    size: 20;\n";
    file << "    maxlength: 255;\n";
    file << "    value: \"\";\n";
    file << "}\n\n";

    // .submit-button
    file << ".submit-button {\n";
    file << "    border: 0;\n";
    file << "}\n\n";

    // .hidden-input
    file << ".hidden-input {\n";
    file << "    display: none;\n";
    file << "}\n\n";

    // .banner
    file << ".banner {\n";
    file << "    text-align: right;\n";
    file << "    font-weight: bold;\n";
    file << "    margin: 0;\n";
    file << "}\n\n";

    // .divider-yellow
    file << ".divider-yellow {\n";
    file << "    border-top: 1px solid #FFCE00;\n";
    file << "    margin-bottom: 2px;\n";
    file << "    width: 780px;\n";
    file << "}\n\n";

    // .content-table
    file << ".content-table {\n";
    file << "    width: 780px;\n";
    file << "    border: 0;\n";
    file << "    cellpadding: 0;\n";
    file << "    cellspacing: 0;\n";
    file << "}\n\n";

    // .keylist
    file << ".keylist {\n";
    file << "    margin: 0;\n";
    file << "    padding: 0;\n";
    file << "}\n\n";

    // .keylist dt
    file << ".keylist dt {\n";
    file << "    font-weight: bold;\n";
    file << "    margin-top: 10px;\n";
    file << "}\n\n";

    // .keylist dd
    file << ".keylist dd {\n";
    file << "    margin-left: 20px;\n";
    file << "    margin-bottom: 10px;\n";
    file << "}\n\n";

    // .footer
    file << ".footer {\n";
    file << "    text-align: center;\n";
    file << "    clear: both;\n";
    file << "}\n\n";

    // .footer small
    file << ".footer small {\n";
    file << "    font-size: 12px;\n";
    file << "}\n\n";

    // .footer a
    file << ".footer a {\n";
    file << "    text-decoration: none;\n";
    file << "    color: #000;\n";
    file << "}\n\n";

    // .footer a:hover
    file << ".footer a:hover {\n";
    file << "    text-decoration: underline;\n";
    file << "}\n\n";

    // .clear
    file << ".clear {\n";
    file << "    clear: both;\n";
    file << "}\n";

    file.close();
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Verwendung: " << argv[0] << " <ausgabedatei>" << std::endl;
        return 1;
    }

    writeCSS(argv[1]);
    return 0;
}
