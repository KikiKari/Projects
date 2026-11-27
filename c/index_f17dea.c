// abstraction-provenance: {"artifact_sha256": "6bcbd98ea377d27cf4606df1e7639a19de8a0209ef2a81cf623e37783d555a49", "source_sha256": "b32c733987d23de98ace1b2a5119f7cb7989a0887c165c1db133ecb4ef278438", "target_language": "c"}
// index_f17dea.css — portiert nach c
// Quelle: css, Projects@abstractions:css/index_f17dea.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_css_rule(FILE *file, const char *selector, const char *properties) {
    fprintf(file, "%s {\n%s}\n\n", selector, properties);
}

void write_media_rule(FILE *file, const char *condition, const char *rules) {
    fprintf(file, "@media %s {\n%s}\n\n", condition, rules);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_file>\n", argv[0]);
        return 1;
    }

    FILE *file = fopen(argv[1], "w");
    if (!file) {
        perror("Error opening file");
        return 1;
    }

    // Write comments
    fprintf(file, "/* abstraction-provenance: {\"artifact_sha256\": \"9ebfdd610ffe88b7273a5ac8e215314a7bee0dffecf25fe9a995b6a39703e204\", \"source_sha256\": \"f17deae3e31b89fd76d250bd20903b36591af417c97b34d987e923632be9ac37\", \"target_language\": \"css\"} */\n");
    fprintf(file, "/* index.html — portiert nach css */\n");
    fprintf(file, "/* Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/raku/index.html */\n");
    fprintf(file, "/* auch in: OpenClaw@gateway2:skills/scripting-utils/references/raku/index.html */\n");
    fprintf(file, "/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */\n\n");

    // General Styles
    write_css_rule(file, "html", "    scroll-padding-top: 60px;\n");
    write_css_rule(file, "body.has-navbar-fixed-top", "    padding-top: 60px;\n");

    // Navbar Styles
    write_css_rule(file, ".navbar.is-fixed-top", 
        "    position: fixed;\n"
        "    top: 0;\n"
        "    left: 0;\n"
        "    right: 0;\n"
        "    z-index: 30;\n"
        "    min-height: 3.25rem;\n");
    write_css_rule(file, ".navbar.is-flex-touch", "    display: flex;\n");
    write_css_rule(file, ".container.is-justify-content-space-around", "    justify-content: space-around;\n");
    write_css_rule(file, ".navbar-brand", 
        "    display: flex;\n"
        "    align-items: center;\n");
    write_css_rule(file, ".navbar-logo", 
        "    display: flex;\n"
        "    align-items: center;\n");
    write_css_rule(file, ".navbar-logo-tm", 
        "    font-size: 0.75rem;\n"
        "    margin-left: 0.25rem;\n");
    write_css_rule(file, ".navbar-burger", 
        "    display: block;\n"
        "    position: relative;\n"
        "    cursor: pointer;\n");
    write_css_rule(file, ".navbar-burger span", 
        "    display: block;\n"
        "    height: 1px;\n"
        "    width: 20px;\n"
        "    background-color: currentColor;\n"
        "    margin: 5px 0;\n"
        "    transition: transform 0.3s ease;\n");
    write_css_rule(file, ".navbar-menu", "    display: none;\n");
    write_css_rule(file, ".navbar-start, .navbar-end", 
        "    display: flex;\n"
        "    align-items: center;\n");
    write_css_rule(file, ".navbar-item", 
        "    display: block;\n"
        "    padding: 0.5rem 0.75rem;\n");
    write_css_rule(file, ".navbar-link", 
        "    display: block;\n"
        "    padding: 0.5rem 0.75rem;\n");
    write_css_rule(file, ".navbar-dropdown", 
        "    display: none;\n"
        "    position: absolute;\n"
        "    top: 100%%;\n"
        "    left: 0;\n"
        "    background-color: white;\n"
        "    border-radius: 4px;\n"
        "    box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1);\n");
    write_css_rule(file, ".navbar-dropdown.is-right", 
        "    left: auto;\n"
        "    right: 0;\n");
    write_css_rule(file, ".navbar-dropdown.is-rounded", "    border-radius: 4px;\n");
    write_css_rule(file, ".navbar-divider", 
        "    display: block;\n"
        "    height: 1px;\n"
        "    background-color: #dbdbdb;\n"
        "    margin: 0.5rem 0;\n");
    write_css_rule(file, ".has-dropdown:hover .navbar-dropdown", "    display: block;\n");
    write_css_rule(file, ".navbar-search-wrapper", 
        "    display: flex;\n"
        "    align-items: center;\n");
    write_css_rule(file, ".field.has-addons", "    display: flex;\n");
    write_css_rule(file, ".control", "    position: relative;\n");
    write_css_rule(file, ".autoComplete_options", "    flex-grow: 1;\n");
    write_css_rule(file, ".input", 
        "    display: block;\n"
        "    width: 100%%;\n"
        "    padding: 0.375rem 0.75rem;\n"
        "    font-size: 1rem;\n"
        "    line-height: 1.5;\n"
        "    color: #495057;\n"
        "    background-color: #fff;\n"
        "    background-clip: padding-box;\n"
        "    border: 1px solid #ced4da;\n"
        "    border-radius: 0.25rem;\n"
        "    transition: border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;\n");
    write_css_rule(file, ".button.is-primary", 
        "    background-color: #00d1b2;\n"
        "    border-color: transparent;\n"
        "    color: #fff;\n");
    write_css_rule(file, ".icon", 
        "    display: inline-flex;\n"
        "    justify-content: center;\n"
        "    align-items: center;\n");
    write_css_rule(file, ".modal", 
        "    position: fixed;\n"
        "    top: 0;\n"
        "    left: 0;\n"
        "    right: 0;\n"
        "    bottom: 0;\n"
        "    z-index: 40;\n"
        "    display: none;\n"
        "    opacity: 0;\n"
        "    transition: opacity 0.15s linear;\n");
    write_css_rule(file, ".modal.is-active", 
        "    display: flex;\n"
        "    opacity: 1;\n");
    write_css_rule(file, ".modal-background", 
        "    position: absolute;\n"
        "    top: 0;\n"
        "    left: 0;\n"
        "    right: 0;\n"
        "    bottom: 0;\n"
        "    background-color: rgba(10, 10, 10, 0.86);\n");
    write_css_rule(file, ".modal-content", 
        "    position: relative;\n"
        "    width: 100%%;\n"
        "    max-height: calc(100vh - 160px);\n"
        "    overflow: auto;\n"
        "    margin: 0 auto;\n"
        "    padding: 20px;\n");
    write_css_rule(file, ".box", 
        "    background-color: white;\n"
        "    border-radius: 6px;\n"
        "    box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1), 0 0 0 1px rgba(10, 10, 10, 0.02);\n"
        "    padding: 1.25rem;\n");
    write_css_rule(file, ".modal-close", 
        "    position: absolute;\n"
        "    top: 20px;\n"
        "    right: 20px;\n"
        "    width: 40px;\n"
        "    height: 40px;\n"
        "    background: none;\n"
        "    border: none;\n"
        "    cursor: pointer;\n");
    write_css_rule(file, ".options-search-controls", 
        "    display: flex;\n"
        "    flex-direction: column;\n"
        "    gap: 1rem;\n");
    write_css_rule(file, ".centreToggle", 
        "    display: flex;\n"
        "    align-items: center;\n"
        "    gap: 0.5rem;\n");
    write_css_rule(file, ".centreToggle input[type=\"checkbox\"]", 
        "    width: var(--switch-width, 10.5em);\n"
        "    height: 2em;\n"
        "    appearance: none;\n"
        "    background: #ccc;\n"
        "    border-radius: 1em;\n"
        "    position: relative;\n"
        "    cursor: pointer;\n");
    write_css_rule(file, ".centreToggle input[type=\"checkbox\"]:checked", "    background: #00d1b2;\n");
    write_css_rule(file, ".centreToggle input[type=\"checkbox\"]::before", 
        "    content: '';\n"
        "    position: absolute;\n"
        "    width: 1.6em;\n"
        "    height: 1.6em;\n"
        "    background: white;\n"
        "    border-radius: 50%%;\n"
        "    top: 0.2em;\n"
        "    left: 0.2em;\n"
        "    transition: transform 0.3s;\n");
    write_css_rule(file, ".centreToggle input[type=\"checkbox\"]:checked::before", 
        "    transform: translateX(calc(var(--switch-width, 10.5em) - 2em));\n");
    write_css_rule(file, ".centreToggle .text,\n.centreToggle .on,\n.centreToggle .off", 
        "    font-weight: bold;\n");
    write_css_rule(file, ".centreToggle .on,\n.centreToggle .off", 
        "    position: absolute;\n"
        "    top: 50%%;\n"
        "    transform: translateY(-50%%);\n");
    write_css_rule(file, ".centreToggle .on", 
        "    left: 0.5em;\n"
        "    color: white;\n");
    write_css_rule(file, ".centreToggle .off", 
        "    right: 0.5em;\n"
        "    color: #333;\n");

    // Hero Section
    write_css_rule(file, ".hero.is-medium", "    min-height: 300px;\n");
    write_css_rule(file, ".hero.is-primary", 
        "    background-color: #00d1b2;\n"
        "    color: #fff;\n");
    write_css_rule(file, ".hero-body", "    padding: 3rem 1.5rem;\n");
    write_css_rule(file, ".title.is-1", "    font-size: 3rem;\n");
    write_css_rule(file, ".subtitle.is-4", "    font-size: 1.5rem;\n");
    write_css_rule(file, ".mt-3", "    margin-top: 0.75rem;\n");
    write_css_rule(file, ".has-text-centered", "    text-align: center;\n");

    // Cards
    write_css_rule(file, ".card-home", 
        "    border-radius: 6px;\n"
        "    box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1), 0 0 0 1px rgba(10, 10, 10, 0.02);\n"
        "    background-color: white;\n"
        "    margin-bottom: 1.5rem;\n");
    write_css_rule(file, ".card-content", "    padding: 1.5rem;\n");
    write_css_rule(file, ".content.has-text-centered", "    text-align: center;\n");
    write_css_rule(file, ".title.is-5", 
        "    font-size: 1.25rem;\n"
        "    margin-bottom: 0.5rem;\n");
    write_css_rule(file, ".has-text-primary", "    color: #00d1b2 !important;\n");
    write_css_rule(file, ".icon.is-large", "    font-size: 2rem;\n");

    // Links Block
    write_css_rule(file, ".raku.links-block", 
        "    background-color: #f5f5f5;\n"
        "    padding: 2rem 0;\n");
    write_css_rule(file, ".columns.is-vcentered", "    align-items: center;\n");
    write_css_rule(file, ".column.is-one-third", 
        "    flex: none;\n"
        "    width: 33.3333%%;\n");
    write_css_rule(file, ".column.is-two-thirds", 
        "    flex: none;\n"
        "    width: 66.6666%%;\n");
    write_css_rule(file, ".pt-5", "    padding-top: 1.5rem;\n");
    write_css_rule(file, ".head", 
        "    font-weight: bold;\n"
        "    margin-bottom: 0.5rem;\n");

    // Footer
    write_css_rule(file, ".footer.main-footer", 
        "    background-color: #fafafa;\n"
        "    padding: 3rem 1.5rem;\n");
    write_css_rule(file, ".level", 
        "    display: flex;\n"
        "    justify-content: space-between;\n"
        "    align-items: center;\n");
    write_css_rule(file, ".level-left, .level-right", 
        "    display: flex;\n"
        "    align-items: center;\n");
    write_css_rule(file, ".level-item", "    margin: 0 0.5rem;\n");

    // Responsive Adjustments
    write_media_rule(file, "screen and (max-width: 1023px)", 
        "    .navbar-menu {\n"
        "        background-color: white;\n"
        "        box-shadow: 0 8px 16px rgba(10, 10, 10, 0.1);\n"
        "        padding: 0.5rem 0;\n"
        "    }\n"
        "    \n"
        "    .navbar-menu.is-active {\n"
        "        display: block;\n"
        "    }\n"
        "    \n"
        "    .navbar-end {\n"
        "        margin-top: 1rem;\n"
        "    }\n");
        
    write_media_rule(file, "screen and (max-width: 768px)", 
        "    .title.is-1.is-size-2-mobile {\n"
        "        font-size: 2rem;\n"
        "    }\n"
        "    \n"
        "    .columns.is-multiline {\n"
        "        display: flex;\n"
        "        flex-wrap: wrap;\n"
        "    }\n"
        "    \n"
        "    .column.is-one-half, \n"
        "    .column.is-one-third {\n"
        "        width: 100%%;\n"
        "    }\n"
        "    \n"
        "    .raku.links-block .columns {\n"
        "        flex-direction: column;\n"
        "    }\n"
        "    \n"
        "    .column.is-one-third, \n"
        "    .column.is-two-thirds {\n"
        "        width: 100%%;\n"
        "    }\n");

    fclose(file);
    return 0;
}
