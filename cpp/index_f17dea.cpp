// abstraction-provenance: {"artifact_sha256": "9f2e36a4bedc5d538586242b20a7811ef4af3fcd83b5b9d6ea3e94a13f1b0809", "source_sha256": "b32c733987d23de98ace1b2a5119f7cb7989a0887c165c1db133ecb4ef278438", "target_language": "cpp"}
// index_f17dea.css — portiert nach cpp
// Quelle: css, Projects@abstractions:css/index_f17dea.css
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

    // Ausgabe des CSS-Inhalts
    file << "/* abstraction-provenance: {\"artifact_sha256\": \"9ebfdd610ffe88b7273a5ac8e215314a7bee0dffecf25fe9a995b6a39703e204\", \"source_sha256\": \"f17deae3e31b89fd76d250bd20903b36591af417c97b34d987e923632be9ac37\", \"target_language\": \"css\"} */\n";
    file << "/* index.html — portiert nach css */\n";
    file << "/* Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/raku/index.html */\n";
    file << "/* auch in: OpenClaw@gateway2:skills/scripting-utils/references/raku/index.html */\n";
    file << "/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */\n\n";

    file << "/* General Styles */\n";
    file << "html {\n";
    file << "    scroll-padding-top: 60px;\n";
    file << "}\n\n";

    file << "body.has-navbar-fixed-top {\n";
    file << "    padding-top: 60px;\n";
    file << "}\n\n";

    file << "/* Navbar Styles */\n";
    file << ".navbar.is-fixed-top {\n";
    file << "    position: fixed;\n";
    file << "    top: 0;\n";
    file << "    left: 0;\n";
    file << "    right: 0;\n";
    file << "    z-index: 30;\n";
    file << "    min-height: 3.25rem;\n";
    file << "}\n\n";

    file << ".navbar.is-flex-touch {\n";
    file << "    display: flex;\n";
    file << "}\n\n";

    file << ".container.is-justify-content-space-around {\n";
    file << "    justify-content: space-around;\n";
    file << "}\n\n";

    file << ".navbar-brand {\n";
    file << "    display: flex;\n";
    file << "    align-items: center;\n";
    file << "}\n\n";

    file << ".navbar-logo {\n";
    file << "    display: flex;\n";
    file << "    align-items: center;\n";
    file << "}\n\n";

    file << ".navbar-logo-tm {\n";
    file << "    font-size: 0.75rem;\n";
    file << "    margin-left: 0.25rem;\n";
    file << "}\n\n";

    file << ".navbar-burger {\n";
    file << "    display: block;\n";
    file << "    position: relative;\n";
    file << "    cursor: pointer;\n";
    file << "}\n\n";

    file << ".navbar-burger span {\n";
    file << "    display: block;\n";
    file << "    height: 1px;\n";
    file << "    width: 20px;\n";
    file << "    background-color: currentColor;\n";
    file << "    margin: 5px 0;\n";
    file << "    transition: transform 0.3s ease;\n";
    file << "}\n\n";

    file << ".navbar-menu {\n";
    file << "    display: none;\n";
    file << "}\n\n";

    file << ".navbar-start, .navbar-end {\n";
    file << "    display: flex;\n";
    file << "    align-items: center;\n";
    file << "}\n\n";

    file << ".navbar-item {\n";
    file << "    display: block;\n";
    file << "    padding: 0.5rem 0.75rem;\n";
    file << "}\n\n";

    file << ".navbar-link {\n";
    file << "    display: block;\n";
    file << "    padding: 0.5rem 0.75rem;\n";
    file << "}\n\n";

    file << ".navbar-dropdown {\n";
    file << "    display: none;\n";
    file << "    position: absolute;\n";
    file << "    top: 100%;\n";
    file << "    left: 0;\n";
    file << "    background-color: white;\n";
    file << "    border-radius: 4px;\n";
    file << "    box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1);\n";
    file << "}\n\n";

    file << ".navbar-dropdown.is-right {\n";
    file << "    left: auto;\n";
    file << "    right: 0;\n";
    file << "}\n\n";

    file << ".navbar-dropdown.is-rounded {\n";
    file << "    border-radius: 4px;\n";
    file << "}\n\n";

    file << ".navbar-divider {\n";
    file << "    display: block;\n";
    file << "    height: 1px;\n";
    file << "    background-color: #dbdbdb;\n";
    file << "    margin: 0.5rem 0;\n";
    file << "}\n\n";

    file << ".has-dropdown:hover .navbar-dropdown {\n";
    file << "    display: block;\n";
    file << "}\n\n";

    file << ".navbar-search-wrapper {\n";
    file << "    display: flex;\n";
    file << "    align-items: center;\n";
    file << "}\n\n";

    file << ".field.has-addons {\n";
    file << "    display: flex;\n";
    file << "}\n\n";

    file << ".control {\n";
    file << "    position: relative;\n";
    file << "}\n\n";

    file << ".autoComplete_options {\n";
    file << "    flex-grow: 1;\n";
    file << "}\n\n";

    file << ".input {\n";
    file << "    display: block;\n";
    file << "    width: 100%;\n";
    file << "    padding: 0.375rem 0.75rem;\n";
    file << "    font-size: 1rem;\n";
    file << "    line-height: 1.5;\n";
    file << "    color: #495057;\n";
    file << "    background-color: #fff;\n";
    file << "    background-clip: padding-box;\n";
    file << "    border: 1px solid #ced4da;\n";
    file << "    border-radius: 0.25rem;\n";
    file << "    transition: border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;\n";
    file << "}\n\n";

    file << ".button.is-primary {\n";
    file << "    background-color: #00d1b2;\n";
    file << "    border-color: transparent;\n";
    file << "    color: #fff;\n";
    file << "}\n\n";

    file << ".icon {\n";
    file << "    display: inline-flex;\n";
    file << "    justify-content: center;\n";
    file << "    align-items: center;\n";
    file << "}\n\n";

    file << ".modal {\n";
    file << "    position: fixed;\n";
    file << "    top: 0;\n";
    file << "    left: 0;\n";
    file << "    right: 0;\n";
    file << "    bottom: 0;\n";
    file << "    z-index: 40;\n";
    file << "    display: none;\n";
    file << "    opacity: 0;\n";
    file << "    transition: opacity 0.15s linear;\n";
    file << "}\n\n";

    file << ".modal.is-active {\n";
    file << "    display: flex;\n";
    file << "    opacity: 1;\n";
    file << "}\n\n";

    file << ".modal-background {\n";
    file << "    position: absolute;\n";
    file << "    top: 0;\n";
    file << "    left: 0;\n";
    file << "    right: 0;\n";
    file << "    bottom: 0;\n";
    file << "    background-color: rgba(10, 10, 10, 0.86);\n";
    file << "}\n\n";

    file << ".modal-content {\n";
    file << "    position: relative;\n";
    file << "    width: 100%;\n";
    file << "    max-height: calc(100vh - 160px);\n";
    file << "    overflow: auto;\n";
    file << "    margin: 0 auto;\n";
    file << "    padding: 20px;\n";
    file << "}\n\n";

    file << ".box {\n";
    file << "    background-color: white;\n";
    file << "    border-radius: 6px;\n";
    file << "    box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1), 0 0 0 1px rgba(10, 10, 10, 0.02);\n";
    file << "    padding: 1.25rem;\n";
    file << "}\n\n";

    file << ".modal-close {\n";
    file << "    position: absolute;\n";
    file << "    top: 20px;\n";
    file << "    right: 20px;\n";
    file << "    width: 40px;\n";
    file << "    height: 40px;\n";
    file << "    background: none;\n";
    file << "    border: none;\n";
    file << "    cursor: pointer;\n";
    file << "}\n\n";

    file << ".options-search-controls {\n";
    file << "    display: flex;\n";
    file << "    flex-direction: column;\n";
    file << "    gap: 1rem;\n";
    file << "}\n\n";

    file << ".centreToggle {\n";
    file << "    display: flex;\n";
    file << "    align-items: center;\n";
    file << "    gap: 0.5rem;\n";
    file << "}\n\n";

    file << ".centreToggle input[type=\"checkbox\"] {\n";
    file << "    width: var(--switch-width, 10.5em);\n";
    file << "    height: 2em;\n";
    file << "    appearance: none;\n";
    file << "    background: #ccc;\n";
    file << "    border-radius: 1em;\n";
    file << "    position: relative;\n";
    file << "    cursor: pointer;\n";
    file << "}\n\n";

    file << ".centreToggle input[type=\"checkbox\"]:checked {\n";
    file << "    background: #00d1b2;\n";
    file << "}\n\n";

    file << ".centreToggle input[type=\"checkbox\"]::before {\n";
    file << "    content: '';\n";
    file << "    position: absolute;\n";
    file << "    width: 1.6em;\n";
    file << "    height: 1.6em;\n";
    file << "    background: white;\n";
    file << "    border-radius: 50%;\n";
    file << "    top: 0.2em;\n";
    file << "    left: 0.2em;\n";
    file << "    transition: transform 0.3s;\n";
    file << "}\n\n";

    file << ".centreToggle input[type=\"checkbox\"]:checked::before {\n";
    file << "    transform: translateX(calc(var(--switch-width, 10.5em) - 2em));\n";
    file << "}\n\n";

    file << ".centreToggle .text,\n";
    file << ".centreToggle .on,\n";
    file << ".centreToggle .off {\n";
    file << "    font-weight: bold;\n";
    file << "}\n\n";

    file << ".centreToggle .on,\n";
    file << ".centreToggle .off {\n";
    file << "    position: absolute;\n";
    file << "    top: 50%;\n";
    file << "    transform: translateY(-50%);\n";
    file << "}\n\n";

    file << ".centreToggle .on {\n";
    file << "    left: 0.5em;\n";
    file << "    color: white;\n";
    file << "}\n\n";

    file << ".centreToggle .off {\n";
    file << "    right: 0.5em;\n";
    file << "    color: #333;\n";
    file << "}\n\n";

    file << "/* Hero Section */\n";
    file << ".hero.is-medium {\n";
    file << "    min-height: 300px;\n";
    file << "}\n\n";

    file << ".hero.is-primary {\n";
    file << "    background-color: #00d1b2;\n";
    file << "    color: #fff;\n";
    file << "}\n\n";

    file << ".hero-body {\n";
    file << "    padding: 3rem 1.5rem;\n";
    file << "}\n\n";

    file << ".title.is-1 {\n";
    file << "    font-size: 3rem;\n";
    file << "}\n\n";

    file << ".subtitle.is-4 {\n";
    file << "    font-size: 1.5rem;\n";
    file << "}\n\n";

    file << ".mt-3 {\n";
    file << "    margin-top: 0.75rem;\n";
    file << "}\n\n";

    file << ".has-text-centered {\n";
    file << "    text-align: center;\n";
    file << "}\n\n";

    file << "/* Cards */\n";
    file << ".card-home {\n";
    file << "    border-radius: 6px;\n";
    file << "    box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1), 0 0 0 1px rgba(10, 10, 10, 0.02);\n";
    file << "    background-color: white;\n";
    file << "    margin-bottom: 1.5rem;\n";
    file << "}\n\n";

    file << ".card-content {\n";
    file << "    padding: 1.5rem;\n";
    file << "}\n\n";

    file << ".content.has-text-centered {\n";
    file << "    text-align: center;\n";
    file << "}\n\n";

    file << ".title.is-5 {\n";
    file << "    font-size: 1.25rem;\n";
    file << "    margin-bottom: 0.5rem;\n";
    file << "}\n\n";

    file << ".has-text-primary {\n";
    file << "    color: #00d1b2 !important;\n";
    file << "}\n\n";

    file << ".icon.is-large {\n";
    file << "    font-size: 2rem;\n";
    file << "}\n\n";

    file << ".button.is-primary {\n";
    file << "    background-color: #00d1b2;\n";
    file << "    border-color: transparent;\n";
    file << "    color: #fff;\n";
    file << "}\n\n";

    file << "/* Links Block */\n";
    file << ".raku.links-block {\n";
    file << "    background-color: #f5f5f5;\n";
    file << "    padding: 2rem 0;\n";
    file << "}\n\n";

    file << ".columns.is-vcentered {\n";
    file << "    align-items: center;\n";
    file << "}\n\n";

    file << ".column.is-one-third {\n";
    file << "    flex: none;\n";
    file << "    width: 33.3333%;\n";
    file << "}\n\n";

    file << ".column.is-two-thirds {\n";
    file << "    flex: none;\n";
    file << "    width: 66.6666%;\n";
    file << "}\n\n";

    file << ".pt-5 {\n";
    file << "    padding-top: 1.5rem;\n";
    file << "}\n\n";

    file << ".head {\n";
    file << "    font-weight: bold;\n";
    file << "    margin-bottom: 0.5rem;\n";
    file << "}\n\n";

    file << "/* Footer */\n";
    file << ".footer.main-footer {\n";
    file << "    background-color: #fafafa;\n";
    file << "    padding: 3rem 1.5rem;\n";
    file << "}\n\n";

    file << ".level {\n";
    file << "    display: flex;\n";
    file << "    justify-content: space-between;\n";
    file << "    align-items: center;\n";
    file << "}\n\n";

    file << ".level-left, .level-right {\n";
    file << "    display: flex;\n";
    file << "    align-items: center;\n";
    file << "}\n\n";

    file << ".level-item {\n";
    file << "    margin: 0 0.5rem;\n";
    file << "}\n\n";

    file << "/* Responsive Adjustments */\n";
    file << "@media screen and (max-width: 1023px) {\n";
    file << "    .navbar-menu {\n";
    file << "        background-color: white;\n";
    file << "        box-shadow: 0 8px 16px rgba(10, 10, 10, 0.1);\n";
    file << "        padding: 0.5rem 0;\n";
    file << "    }\n";
    file << "    \n";
    file << "    .navbar-menu.is-active {\n";
    file << "        display: block;\n";
    file << "    }\n";
    file << "    \n";
    file << "    .navbar-end {\n";
    file << "        margin-top: 1rem;\n";
    file << "    }\n";
    file << "}\n\n";

    file << "@media screen and (max-width: 768px) {\n";
    file << "    .title.is-1.is-size-2-mobile {\n";
    file << "        font-size: 2rem;\n";
    file << "    }\n";
    file << "    \n";
    file << "    .columns.is-multiline {\n";
    file << "        display: flex;\n";
    file << "        flex-wrap: wrap;\n";
    file << "    }\n";
    file << "    \n";
    file << "    .column.is-one-half, \n";
    file << "    .column.is-one-third {\n";
    file << "        width: 100%;\n";
    file << "    }\n";
    file << "    \n";
    file << "    .raku.links-block .columns {\n";
    file << "        flex-direction: column;\n";
    file << "    }\n";
    file << "    \n";
    file << "    .column.is-one-third, \n";
    file << "    .column.is-two-thirds {\n";
    file << "        width: 100%;\n";
    file << "    }\n";
    file << "}\n";

    file.close();
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Verwendung: " << argv[0] << " <Ausgabedatei>" << std::endl;
        return 1;
    }

    std::string outputFile = argv[1];
    writeCSS(outputFile);

    std::cout << "CSS-Datei erfolgreich erstellt: " << outputFile << std::endl;
    return 0;
}
