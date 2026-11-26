// abstraction-provenance: {"artifact_sha256": "f158626f853e6dc58145a8e8a49ce376398a44d1fe252c6e752694b902bc5510", "source_sha256": "eb21431dabeaafc82a1e3ccf24278616e46ed082eca1de4d328c758ee82ee2c7", "target_language": "java"}
// language_validator.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/language_validator.py
// auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/language_validator.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * Multi-language script validator supporting 8+ languages.
 * WebSearch integration for documentation lookup.
 */
public class LanguageValidator {

    private static final Map<String, LanguageConfig> LANGUAGES = new HashMap<>();

    static {
        LANGUAGES.put("bash", new LanguageConfig("bash", new String[]{"-n"}, "shellcheck"));
        LANGUAGES.put("sh", new LanguageConfig("sh", new String[]{"-n"}, "shellcheck"));
        LANGUAGES.put("python", new LanguageConfig("python3", new String[]{"-m", "py_compile"}, "pylint"));
        LANGUAGES.put("perl", new LanguageConfig("perl", new String[]{"-c"}, "perlcritic"));
        LANGUAGES.put("raku", new LanguageConfig("raku", new String[]{"-c"}, null));
        LANGUAGES.put("powershell", new LanguageConfig("pwsh", new String[]{"-Command", "Get-Command"}, null));
        LANGUAGES.put("javascript", new LanguageConfig("node", new String[]{"--check"}, "eslint"));
        LANGUAGES.put("tcl", new LanguageConfig("tclsh", new String[]{}, null));
    }

    private final String language;
    private final boolean useWebsearch;
    private final LanguageConfig config;

    public LanguageValidator(String language, boolean useWebsearch) {
        this.language = language.toLowerCase();
        this.useWebsearch = useWebsearch;
        this.config = LANGUAGES.get(this.language);
        if (this.config == null) {
            throw new IllegalArgumentException("Unsupported language: " + language);
        }
    }

    /**
     * Validate a script file.
     */
    public ValidationResult validate(Path scriptPath) {
        List<String> errors = new ArrayList<>();
        List<String> warnings = new ArrayList<>();

        // Syntax check
        try {
            ProcessBuilder pb = new ProcessBuilder();
            List<String> command = new ArrayList<>();
            command.add(config.cmd);
            for (String arg : config.args) {
                command.add(arg);
            }
            command.add(scriptPath.toString());
            pb.command(command);
            Process process = pb.start();
            
            boolean finished = process.waitFor(30, TimeUnit.SECONDS);
            if (!finished) {
                process.destroyForcibly();
                errors.add("Validation timeout");
            } else if (process.exitValue() != 0) {
                BufferedReader reader = new BufferedReader(new InputStreamReader(process.getErrorStream()));
                StringBuilder errorOutput = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null) {
                    errorOutput.append(line).append("\n");
                }
                errors.add(errorOutput.toString());
            }
        } catch (IOException e) {
            errors.add("Command not found: " + config.cmd);
            if (useWebsearch) {
                String docUrl = fetchDocs();
                return new ValidationResult(language, false, errors, warnings, docUrl);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            errors.add("Validation interrupted");
        }

        // Linter check if available
        if (config.linter != null) {
            List<String> linterWarnings = runLinter(scriptPath);
            warnings.addAll(linterWarnings);
        }

        return new ValidationResult(
                language,
                errors.isEmpty(),
                errors,
                warnings
        );
    }

    /**
     * Run language-specific linter.
     */
    private List<String> runLinter(Path scriptPath) {
        List<String> warnings = new ArrayList<>();
        String linter = config.linter;

        try {
            ProcessBuilder pb;
            if ("shellcheck".equals(linter)) {
                pb = new ProcessBuilder("shellcheck", "-f", "gcc", scriptPath.toString());
            } else if ("pylint".equals(linter)) {
                pb = new ProcessBuilder("pylint", "--output-format=parseable", scriptPath.toString());
            } else {
                warnings.add("Unknown linter: " + linter);
                return warnings;
            }

            Process process = pb.start();
            process.waitFor();

            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String line;
            while ((line = reader.readLine()) != null) {
                warnings.add(line);
            }
        } catch (IOException e) {
            warnings.add("Linter not installed: " + linter);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            warnings.add("Linter execution interrupted");
        }

        return warnings;
    }

    /**
     * Fetch documentation URL via WebSearch if enabled.
     */
    private String fetchDocs() {
        if (!useWebsearch) {
            return null;
        }

        // Return known good documentation URLs
        Map<String, String> docs = new HashMap<>();
        docs.put("powershell", "https://docs.microsoft.com/powershell/");
        docs.put("raku", "https://docs.raku.org/");
        docs.put("tcl", "https://www.tcl.tk/");

        return docs.get(language);
    }

    public static void main(String[] args) {
        if (args.length < 2) {
            System.err.println("Usage: java LanguageValidator <script> --lang <language>");
            System.exit(1);
        }

        Path scriptPath = Paths.get(args[0]);
        String language = null;
        boolean useWebsearch = true;

        for (int i = 1; i < args.length; i++) {
            if ("--lang".equals(args[i]) && i + 1 < args.length) {
                language = args[i + 1];
                i++;
            } else if ("--no-websearch".equals(args[i])) {
                useWebsearch = false;
            }
        }

        if (language == null) {
            System.err.println("Language argument is required");
            System.exit(1);
        }

        LanguageValidator validator = new LanguageValidator(language, useWebsearch);
        ValidationResult result = validator.validate(scriptPath);

        System.out.println("Language: " + result.language);
        System.out.println("Valid: " + result.valid);
        if (!result.errors.isEmpty()) {
            System.out.println("Errors: " + result.errors.size());
            int count = 0;
            for (String err : result.errors) {
                if (count >= 5) break;
                System.out.println("  - " + err);
                count++;
            }
        }
        if (!result.warnings.isEmpty()) {
            System.out.println("Warnings: " + result.warnings.size());
            int count = 0;
            for (String warn : result.warnings) {
                if (count >= 5) break;
                System.out.println("  - " + warn);
                count++;
            }
        }
        if (result.docUrl != null) {
            System.out.println("Docs: " + result.docUrl);
        }

        System.exit(result.valid ? 0 : 1);
    }

    static class LanguageConfig {
        final String cmd;
        final String[] args;
        final String linter;

        LanguageConfig(String cmd, String[] args, String linter) {
            this.cmd = cmd;
            this.args = args;
            this.linter = linter;
        }
    }

    static class ValidationResult {
        final String language;
        final boolean valid;
        final List<String> errors;
        final List<String> warnings;
        final String docUrl;

        ValidationResult(String language, boolean valid, List<String> errors, List<String> warnings) {
            this(language, valid, errors, warnings, null);
        }

        ValidationResult(String language, boolean valid, List<String> errors, List<String> warnings, String docUrl) {
            this.language = language;
            this.valid = valid;
            this.errors = errors;
            this.warnings = warnings;
            this.docUrl = docUrl;
        }
    }
}
