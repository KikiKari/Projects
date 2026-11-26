// abstraction-provenance: {"artifact_sha256": "2c2158f7867ffaccdc0ebf0d9aeb3a2ea02c997bb550fdb7e846674aba23b456", "source_sha256": "daf22c296c801d3d533083361cc59fbdc22e5bfe528aa4bad1973b54cc5448a4", "target_language": "java"}
// index.css — portiert nach java
// Quelle: css, OpenClaw@main:src/index.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

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
            generateCssFile(outputFile);
            System.out.println("CSS file generated successfully: " + outputFile);
        } catch (IOException e) {
            System.err.println("Error generating CSS file: " + e.getMessage());
            System.exit(1);
        }
    }

    private static void generateCssFile(String outputPath) throws IOException {
        StringBuilder cssContent = new StringBuilder();
        
        // Generate body styles
        cssContent.append("body {\n");
        cssContent.append("  margin: 0;\n");
        cssContent.append("  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',\n");
        cssContent.append("    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',\n");
        cssContent.append("    sans-serif;\n");
        cssContent.append("  -webkit-font-smoothing: antialiased;\n");
        cssContent.append("  -moz-osx-font-smoothing: grayscale;\n");
        cssContent.append("}\n\n");
        
        // Generate code styles
        cssContent.append("code {\n");
        cssContent.append("  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',\n");
        cssContent.append("    monospace;\n");
        cssContent.append("}\n");
        
        // Write to file
        try (FileWriter writer = new FileWriter(outputPath)) {
            writer.write(cssContent.toString());
        }
    }
}
