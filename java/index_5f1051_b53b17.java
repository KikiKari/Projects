// abstraction-provenance: {"artifact_sha256": "e4c9d8dce77350f691ba1c97ab3f31a20457b5c287d36df5be88fc31fe0fd3b9", "source_sha256": "b53b17806f268da8dc7115668f5a04c5ff39edd9b2305ba40f1b04e598002f81", "target_language": "java"}
// index_5f1051.css — portiert nach java
// Quelle: css, Projects@abstractions:css/index_5f1051.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Path;

public class CssGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java CssGenerator <output-file>");
            System.exit(1);
        }

        String outputFile = args[0];
        
        try {
            generateCss(outputFile);
            System.out.println("CSS file generated successfully: " + outputFile);
        } catch (IOException e) {
            System.err.println("Error writing CSS file: " + e.getMessage());
            System.exit(1);
        }
    }

    private static void generateCss(String outputFile) throws IOException {
        try (FileWriter writer = new FileWriter(outputFile)) {
            // Write comments
            writer.write("/* abstraction-provenance: {\"artifact_sha256\": \"cdcc9e9ffa451d8c92fd763b0dfd0b1974003a826baaae753e2f347cfd3c9f57\", \"source_sha256\": \"5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988\", \"target_language\": \"css\"} */\n");
            writer.write("/* index.html — portiert nach css */\n");
            writer.write("/* Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html */\n");
            writer.write("/* auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html */\n");
            writer.write("/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */\n\n");

            // body styles
            writer.write("body {\n");
            writer.write("    background-color: white;\n");
            writer.write("    color: black;\n");
            writer.write("    margin: 0;\n");
            writer.write("    padding: 0;\n");
            writer.write("    font-family: Arial, sans-serif;\n");
            writer.write("}\n\n");

            // table styles
            writer.write("table {\n");
            writer.write("    border-collapse: collapse;\n");
            writer.write("}\n\n");

            // globalnav-container styles
            writer.write(".globalnav-container {\n");
            writer.write("    width: 780px;\n");
            writer.write("    border: 0;\n");
            writer.write("    cellpadding: 0;\n");
            writer.write("    cellspacing: 0;\n");
            writer.write("}\n\n");

            // header-left styles
            writer.write(".header-left {\n");
            writer.write("    vertical-align: top;\n");
            writer.write("    text-align: left;\n");
            writer.write("}\n\n");

            // header-right styles
            writer.write(".header-right {\n");
            writer.write("    vertical-align: top;\n");
            writer.write("    text-align: right;\n");
            writer.write("}\n\n");

            // logo-link styles
            writer.write(".logo-link {\n");
            writer.write("    text-decoration: none;\n");
            writer.write("    border: 0;\n");
            writer.write("}\n\n");

            // logo-image styles
            writer.write(".logo-image {\n");
            writer.write("    border: 0;\n");
            writer.write("}\n\n");

            // hosted-by styles
            writer.write(".hosted-by {\n");
            writer.write("    font-size: 1px;\n");
            writer.write("    text-decoration: none;\n");
            writer.write("}\n\n");

            // active-state-logo styles
            writer.write(".active-state-logo {\n");
            writer.write("    border: 0;\n");
            writer.write("    title: \"This site is hosted by ActiveState\";\n");
            writer.write("}\n\n");

            // globalnav styles
            writer.write("#globalnav {\n");
            writer.write("    clear: both;\n");
            writer.write("}\n\n");

            // globalnav ul styles
            writer.write("#globalnav ul {\n");
            writer.write("    list-style-type: none;\n");
            writer.write("    margin: 0;\n");
            writer.write("    padding: 0;\n");
            writer.write("    overflow: hidden;\n");
            writer.write("}\n\n");

            // globalnav li styles
            writer.write("#globalnav li {\n");
            writer.write("    float: left;\n");
            writer.write("}\n\n");

            // globalnav a styles
            writer.write("#globalnav a {\n");
            writer.write("    display: block;\n");
            writer.write("    padding: 8px 16px;\n");
            writer.write("    text-decoration: none;\n");
            writer.write("    color: #000;\n");
            writer.write("}\n\n");

            // globalnav a.here styles
            writer.write("#globalnav a.here {\n");
            writer.write("    background-color: #3163CE;\n");
            writer.write("    color: white;\n");
            writer.write("}\n\n");

            // divider-top styles
            writer.write(".divider-top {\n");
            writer.write("    border-top: 2px solid #3163CE;\n");
            writer.write("    width: 780px;\n");
            writer.write("}\n\n");

            // search-table styles
            writer.write(".search-table {\n");
            writer.write("    width: 780px;\n");
            writer.write("    border: 0;\n");
            writer.write("    cellpadding: 2;\n");
            writer.write("    cellspacing: 0;\n");
            writer.write("}\n\n");

            // search-container styles
            writer.write(".search-container {\n");
            writer.write("    display: table-cell;\n");
            writer.write("    vertical-align: middle;\n");
            writer.write("    margin: 0px;\n");
            writer.write("}\n\n");

            // search-form styles
            writer.write(".search-form {\n");
            writer.write("    display: inline;\n");
            writer.write("}\n\n");

            // search-input styles
            writer.write(".search-input {\n");
            writer.write("    size: 20;\n");
            writer.write("    maxlength: 255;\n");
            writer.write("    value: \"\";\n");
            writer.write("}\n\n");

            // submit-button styles
            writer.write(".submit-button {\n");
            writer.write("    border: 0;\n");
            writer.write("}\n\n");

            // hidden-input styles
            writer.write(".hidden-input {\n");
            writer.write("    display: none;\n");
            writer.write("}\n\n");

            // banner styles
            writer.write(".banner {\n");
            writer.write("    text-align: right;\n");
            writer.write("    font-weight: bold;\n");
            writer.write("    margin: 0;\n");
            writer.write("}\n\n");

            // divider-yellow styles
            writer.write(".divider-yellow {\n");
            writer.write("    border-top: 1px solid #FFCE00;\n");
            writer.write("    margin-bottom: 2px;\n");
            writer.write("    width: 780px;\n");
            writer.write("}\n\n");

            // content-table styles
            writer.write(".content-table {\n");
            writer.write("    width: 780px;\n");
            writer.write("    border: 0;\n");
            writer.write("    cellpadding: 0;\n");
            writer.write("    cellspacing: 0;\n");
            writer.write("}\n\n");

            // keylist styles
            writer.write(".keylist {\n");
            writer.write("    margin: 0;\n");
            writer.write("    padding: 0;\n");
            writer.write("}\n\n");

            // keylist dt styles
            writer.write(".keylist dt {\n");
            writer.write("    font-weight: bold;\n");
            writer.write("    margin-top: 10px;\n");
            writer.write("}\n\n");

            // keylist dd styles
            writer.write(".keylist dd {\n");
            writer.write("    margin-left: 20px;\n");
            writer.write("    margin-bottom: 10px;\n");
            writer.write("}\n\n");

            // footer styles
            writer.write(".footer {\n");
            writer.write("    text-align: center;\n");
            writer.write("    clear: both;\n");
            writer.write("}\n\n");

            // footer small styles
            writer.write(".footer small {\n");
            writer.write("    font-size: 12px;\n");
            writer.write("}\n\n");

            // footer a styles
            writer.write(".footer a {\n");
            writer.write("    text-decoration: none;\n");
            writer.write("    color: #000;\n");
            writer.write("}\n\n");

            // footer a:hover styles
            writer.write(".footer a:hover {\n");
            writer.write("    text-decoration: underline;\n");
            writer.write("}\n\n");

            // clear styles
            writer.write(".clear {\n");
            writer.write("    clear: both;\n");
            writer.write("}\n");
        }
    }
}
