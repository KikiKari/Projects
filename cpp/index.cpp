// abstraction-provenance: {"artifact_sha256": "675ef144bbb62183a0037d12362fc4ab50299671133451049ccf89e25c56b59d", "source_sha256": "daf22c296c801d3d533083361cc59fbdc22e5bfe528aa4bad1973b54cc5448a4", "target_language": "cpp"}
// index.css — portiert nach cpp
// Quelle: css, OpenClaw@main:src/index.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <output_file>" << std::endl;
        return 1;
    }

    std::ofstream file(argv[1]);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file " << argv[1] << std::endl;
        return 1;
    }

    file << "body {\n";
    file << "  margin: 0;\n";
    file << "  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',\n";
    file << "    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',\n";
    file << "    sans-serif;\n";
    file << "  -webkit-font-smoothing: antialiased;\n";
    file << "  -moz-osx-font-smoothing: grayscale;\n";
    file << "}\n\n";

    file << "code {\n";
    file << "  font-family: source-code-pro, Menlo, Monaco, Consolas, 'Courier New',\n";
    file << "    monospace;\n";
    file << "}\n";

    file.close();
    return 0;
}
