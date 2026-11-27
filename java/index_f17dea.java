// abstraction-provenance: {"artifact_sha256": "591e1b16f6779d39a4436313469b27d939e15f7e0decd7282e4dfad3bb92ba75", "source_sha256": "b32c733987d23de98ace1b2a5119f7cb7989a0887c165c1db133ecb4ef278438", "target_language": "java"}
// index_f17dea.css — portiert nach java
// Quelle: css, Projects@abstractions:css/index_f17dea.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.util.*;

public class CSSGenerator {
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java CSSGenerator <output-file>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        
        try {
            String cssContent = generateCSS();
            Files.write(Paths.get(outputFile), cssContent.getBytes());
            System.out.println("CSS file generated successfully: " + outputFile);
        } catch (IOException e) {
            System.err.println("Error writing CSS file: " + e.getMessage());
            System.exit(1);
        }
    }
    
    private static String generateCSS() {
        StringBuilder css = new StringBuilder();
        
        // Header comments
        css.append("/* abstraction-provenance: {\"artifact_sha256\": \"9ebfdd610ffe88b7273a5ac8e215314a7bee0dffecf25fe9a995b6a39703e204\", \"source_sha256\": \"f17deae3e31b89fd76d250bd20903b36591af417c97b34d987e923632be9ac37\", \"target_language\": \"css\"} */\n");
        css.append("/* index.html — portiert nach css */\n");
        css.append("/* Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/raku/index.html */\n");
        css.append("/* auch in: OpenClaw@gateway2:skills/scripting-utils/references/raku/index.html */\n");
        css.append("/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */\n\n");
        
        // General Styles
        css.append("/* General Styles */\n");
        css.append("html {\n");
        css.append("    scroll-padding-top: 60px;\n");
        css.append("}\n\n");
        
        css.append("body.has-navbar-fixed-top {\n");
        css.append("    padding-top: 60px;\n");
        css.append("}\n\n");
        
        // Navbar Styles
        css.append("/* Navbar Styles */\n");
        css.append(".navbar.is-fixed-top {\n");
        css.append("    position: fixed;\n");
        css.append("    top: 0;\n");
        css.append("    left: 0;\n");
        css.append("    right: 0;\n");
        css.append("    z-index: 30;\n");
        css.append("    min-height: 3.25rem;\n");
        css.append("}\n\n");
        
        css.append(".navbar.is-flex-touch {\n");
        css.append("    display: flex;\n");
        css.append("}\n\n");
        
        css.append(".container.is-justify-content-space-around {\n");
        css.append("    justify-content: space-around;\n");
        css.append("}\n\n");
        
        css.append(".navbar-brand {\n");
        css.append("    display: flex;\n");
        css.append("    align-items: center;\n");
        css.append("}\n\n");
        
        css.append(".navbar-logo {\n");
        css.append("    display: flex;\n");
        css.append("    align-items: center;\n");
        css.append("}\n\n");
        
        css.append(".navbar-logo-tm {\n");
        css.append("    font-size: 0.75rem;\n");
        css.append("    margin-left: 0.25rem;\n");
        css.append("}\n\n");
        
        css.append(".navbar-burger {\n");
        css.append("    display: block;\n");
        css.append("    position: relative;\n");
        css.append("    cursor: pointer;\n");
        css.append("}\n\n");
        
        css.append(".navbar-burger span {\n");
        css.append("    display: block;\n");
        css.append("    height: 1px;\n");
        css.append("    width: 20px;\n");
        css.append("    background-color: currentColor;\n");
        css.append("    margin: 5px 0;\n");
        css.append("    transition: transform 0.3s ease;\n");
        css.append("}\n\n");
        
        css.append(".navbar-menu {\n");
        css.append("    display: none;\n");
        css.append("}\n\n");
        
        css.append(".navbar-start, .navbar-end {\n");
        css.append("    display: flex;\n");
        css.append("    align-items: center;\n");
        css.append("}\n\n");
        
        css.append(".navbar-item {\n");
        css.append("    display: block;\n");
        css.append("    padding: 0.5rem 0.75rem;\n");
        css.append("}\n\n");
        
        css.append(".navbar-link {\n");
        css.append("    display: block;\n");
        css.append("    padding: 0.5rem 0.75rem;\n");
        css.append("}\n\n");
        
        css.append(".navbar-dropdown {\n");
        css.append("    display: none;\n");
        css.append("    position: absolute;\n");
        css.append("    top: 100%;\n");
        css.append("    left: 0;\n");
        css.append("    background-color: white;\n");
        css.append("    border-radius: 4px;\n");
        css.append("    box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1);\n");
        css.append("}\n\n");
        
        css.append(".navbar-dropdown.is-right {\n");
        css.append("    left: auto;\n");
        css.append("    right: 0;\n");
        css.append("}\n\n");
        
        css.append(".navbar-dropdown.is-rounded {\n");
        css.append("    border-radius: 4px;\n");
        css.append("}\n\n");
        
        css.append(".navbar-divider {\n");
        css.append("    display: block;\n");
        css.append("    height: 1px;\n");
        css.append("    background-color: #dbdbdb;\n");
        css.append("    margin: 0.5rem 0;\n");
        css.append("}\n\n");
        
        css.append(".has-dropdown:hover .navbar-dropdown {\n");
        css.append("    display: block;\n");
        css.append("}\n\n");
        
        css.append(".navbar-search-wrapper {\n");
        css.append("    display: flex;\n");
        css.append("    align-items: center;\n");
        css.append("}\n\n");
        
        css.append(".field.has-addons {\n");
        css.append("    display: flex;\n");
        css.append("}\n\n");
        
        css.append(".control {\n");
        css.append("    position: relative;\n");
        css.append("}\n\n");
        
        css.append(".autoComplete_options {\n");
        css.append("    flex-grow: 1;\n");
        css.append("}\n\n");
        
        css.append(".input {\n");
        css.append("    display: block;\n");
        css.append("    width: 100%;\n");
        css.append("    padding: 0.375rem 0.75rem;\n");
        css.append("    font-size: 1rem;\n");
        css.append("    line-height: 1.5;\n");
        css.append("    color: #495057;\n");
        css.append("    background-color: #fff;\n");
        css.append("    background-clip: padding-box;\n");
        css.append("    border: 1px solid #ced4da;\n");
        css.append("    border-radius: 0.25rem;\n");
        css.append("    transition: border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;\n");
        css.append("}\n\n");
        
        css.append(".button.is-primary {\n");
        css.append("    background-color: #00d1b2;\n");
        css.append("    border-color: transparent;\n");
        css.append("    color: #fff;\n");
        css.append("}\n\n");
        
        css.append(".icon {\n");
        css.append("    display: inline-flex;\n");
        css.append("    justify-content: center;\n");
        css.append("    align-items: center;\n");
        css.append("}\n\n");
        
        css.append(".modal {\n");
        css.append("    position: fixed;\n");
        css.append("    top: 0;\n");
        css.append("    left: 0;\n");
        css.append("    right: 0;\n");
        css.append("    bottom: 0;\n");
        css.append("    z-index: 40;\n");
        css.append("    display: none;\n");
        css.append("    opacity: 0;\n");
        css.append("    transition: opacity 0.15s linear;\n");
        css.append("}\n\n");
        
        css.append(".modal.is-active {\n");
        css.append("    display: flex;\n");
        css.append("    opacity: 1;\n");
        css.append("}\n\n");
        
        css.append(".modal-background {\n");
        css.append("    position: absolute;\n");
        css.append("    top: 0;\n");
        css.append("    left: 0;\n");
        css.append("    right: 0;\n");
        css.append("    bottom: 0;\n");
        css.append("    background-color: rgba(10, 10, 10, 0.86);\n");
        css.append("}\n\n");
        
        css.append(".modal-content {\n");
        css.append("    position: relative;\n");
        css.append("    width: 100%;\n");
        css.append("    max-height: calc(100vh - 160px);\n");
        css.append("    overflow: auto;\n");
        css.append("    margin: 0 auto;\n");
        css.append("    padding: 20px;\n");
        css.append("}\n\n");
        
        css.append(".box {\n");
        css.append("    background-color: white;\n");
        css.append("    border-radius: 6px;\n");
        css.append("    box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1), 0 0 0 1px rgba(10, 10, 10, 0.02);\n");
        css.append("    padding: 1.25rem;\n");
        css.append("}\n\n");
        
        css.append(".modal-close {\n");
        css.append("    position: absolute;\n");
        css.append("    top: 20px;\n");
        css.append("    right: 20px;\n");
        css.append("    width: 40px;\n");
        css.append("    height: 40px;\n");
        css.append("    background: none;\n");
        css.append("    border: none;\n");
        css.append("    cursor: pointer;\n");
        css.append("}\n\n");
        
        css.append(".options-search-controls {\n");
        css.append("    display: flex;\n");
        css.append("    flex-direction: column;\n");
        css.append("    gap: 1rem;\n");
        css.append("}\n\n");
        
        css.append(".centreToggle {\n");
        css.append("    display: flex;\n");
        css.append("    align-items: center;\n");
        css.append("    gap: 0.5rem;\n");
        css.append("}\n\n");
        
        css.append(".centreToggle input[type=\"checkbox\"] {\n");
        css.append("    width: var(--switch-width, 10.5em);\n");
        css.append("    height: 2em;\n");
        css.append("    appearance: none;\n");
        css.append("    background: #ccc;\n");
        css.append("    border-radius: 1em;\n");
        css.append("    position: relative;\n");
        css.append("    cursor: pointer;\n");
        css.append("}\n\n");
        
        css.append(".centreToggle input[type=\"checkbox\"]:checked {\n");
        css.append("    background: #00d1b2;\n");
        css.append("}\n\n");
        
        css.append(".centreToggle input[type=\"checkbox\"]::before {\n");
        css.append("    content: '';\n");
        css.append("    position: absolute;\n");
        css.append("    width: 1.6em;\n");
        css.append("    height: 1.6em;\n");
        css.append("    background: white;\n");
        css.append("    border-radius: 50%;\n");
        css.append("    top: 0.2em;\n");
        css.append("    left: 0.2em;\n");
        css.append("    transition: transform 0.3s;\n");
        css.append("}\n\n");
        
        css.append(".centreToggle input[type=\"checkbox\"]:checked::before {\n");
        css.append("    transform: translateX(calc(var(--switch-width, 10.5em) - 2em));\n");
        css.append("}\n\n");
        
        css.append(".centreToggle .text,\n");
        css.append(".centreToggle .on,\n");
        css.append(".centreToggle .off {\n");
        css.append("    font-weight: bold;\n");
        css.append("}\n\n");
        
        css.append(".centreToggle .on,\n");
        css.append(".centreToggle .off {\n");
        css.append("    position: absolute;\n");
        css.append("    top: 50%;\n");
        css.append("    transform: translateY(-50%);\n");
        css.append("}\n\n");
        
        css.append(".centreToggle .on {\n");
        css.append("    left: 0.5em;\n");
        css.append("    color: white;\n");
        css.append("}\n\n");
        
        css.append(".centreToggle .off {\n");
        css.append("    right: 0.5em;\n");
        css.append("    color: #333;\n");
        css.append("}\n\n");
        
        // Hero Section
        css.append("/* Hero Section */\n");
        css.append(".hero.is-medium {\n");
        css.append("    min-height: 300px;\n");
        css.append("}\n\n");
        
        css.append(".hero.is-primary {\n");
        css.append("    background-color: #00d1b2;\n");
        css.append("    color: #fff;\n");
        css.append("}\n\n");
        
        css.append(".hero-body {\n");
        css.append("    padding: 3rem 1.5rem;\n");
        css.append("}\n\n");
        
        css.append(".title.is-1 {\n");
        css.append("    font-size: 3rem;\n");
        css.append("}\n\n");
        
        css.append(".subtitle.is-4 {\n");
        css.append("    font-size: 1.5rem;\n");
        css.append("}\n\n");
        
        css.append(".mt-3 {\n");
        css.append("    margin-top: 0.75rem;\n");
        css.append("}\n\n");
        
        css.append(".has-text-centered {\n");
        css.append("    text-align: center;\n");
        css.append("}\n\n");
        
        // Cards
        css.append("/* Cards */\n");
        css.append(".card-home {\n");
        css.append("    border-radius: 6px;\n");
        css.append("    box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1), 0 0 0 1px rgba(10, 10, 10, 0.02);\n");
        css.append("    background-color: white;\n");
        css.append("    margin-bottom: 1.5rem;\n");
        css.append("}\n\n");
        
        css.append(".card-content {\n");
        css.append("    padding: 1.5rem;\n");
        css.append("}\n\n");
        
        css.append(".content.has-text-centered {\n");
        css.append("    text-align: center;\n");
        css.append("}\n\n");
        
        css.append(".title.is-5 {\n");
        css.append("    font-size: 1.25rem;\n");
        css.append("    margin-bottom: 0.5rem;\n");
        css.append("}\n\n");
        
        css.append(".has-text-primary {\n");
        css.append("    color: #00d1b2 !important;\n");
        css.append("}\n\n");
        
        css.append(".icon.is-large {\n");
        css.append("    font-size: 2rem;\n");
        css.append("}\n\n");
        
        css.append(".button.is-primary {\n");
        css.append("    background-color: #00d1b2;\n");
        css.append("    border-color: transparent;\n");
        css.append("    color: #fff;\n");
        css.append("}\n\n");
        
        // Links Block
        css.append("/* Links Block */\n");
        css.append(".raku.links-block {\n");
        css.append("    background-color: #f5f5f5;\n");
        css.append("    padding: 2rem 0;\n");
        css.append("}\n\n");
        
        css.append(".columns.is-vcentered {\n");
        css.append("    align-items: center;\n");
        css.append("}\n\n");
        
        css.append(".column.is-one-third {\n");
        css.append("    flex: none;\n");
        css.append("    width: 33.3333%;\n");
        css.append("}\n\n");
        
        css.append(".column.is-two-thirds {\n");
        css.append("    flex: none;\n");
        css.append("    width: 66.6666%;\n");
        css.append("}\n\n");
        
        css.append(".pt-5 {\n");
        css.append("    padding-top: 1.5rem;\n");
        css.append("}\n\n");
        
        css.append(".head {\n");
        css.append("    font-weight: bold;\n");
        css.append("    margin-bottom: 0.5rem;\n");
        css.append("}\n\n");
        
        // Footer
        css.append("/* Footer */\n");
        css.append(".footer.main-footer {\n");
        css.append("    background-color: #fafafa;\n");
        css.append("    padding: 3rem 1.5rem;\n");
        css.append("}\n\n");
        
        css.append(".level {\n");
        css.append("    display: flex;\n");
        css.append("    justify-content: space-between;\n");
        css.append("    align-items: center;\n");
        css.append("}\n\n");
        
        css.append(".level-left, .level-right {\n");
        css.append("    display: flex;\n");
        css.append("    align-items: center;\n");
        css.append("}\n\n");
        
        css.append(".level-item {\n");
        css.append("    margin: 0 0.5rem;\n");
        css.append("}\n\n");
        
        // Responsive Adjustments
        css.append("/* Responsive Adjustments */\n");
        css.append("@media screen and (max-width: 1023px) {\n");
        css.append("    .navbar-menu {\n");
        css.append("        background-color: white;\n");
        css.append("        box-shadow: 0 8px 16px rgba(10, 10, 10, 0.1);\n");
        css.append("        padding: 0.5rem 0;\n");
        css.append("    }\n\n");
        
        css.append("    .navbar-menu.is-active {\n");
        css.append("        display: block;\n");
        css.append("    }\n\n");
        
        css.append("    .navbar-end {\n");
        css.append("        margin-top: 1rem;\n");
        css.append("    }\n");
        css.append("}\n\n");
        
        css.append("@media screen and (max-width: 768px) {\n");
        css.append("    .title.is-1.is-size-2-mobile {\n");
        css.append("        font-size: 2rem;\n");
        css.append("    }\n\n");
        
        css.append("    .columns.is-multiline {\n");
        css.append("        display: flex;\n");
        css.append("        flex-wrap: wrap;\n");
        css.append("    }\n\n");
        
        css.append("    .column.is-one-half, \n");
        css.append("    .column.is-one-third {\n");
        css.append("        width: 100%;\n");
        css.append("    }\n\n");
        
        css.append("    .raku.links-block .columns {\n");
        css.append("        flex-direction: column;\n");
        css.append("    }\n\n");
        
        css.append("    .column.is-one-third, \n");
        css.append("    .column.is-two-thirds {\n");
        css.append("        width: 100%;\n");
        css.append("    }\n");
        css.append("}\n");
        
        return css.toString();
    }
}
