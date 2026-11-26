<?php
// abstraction-provenance: {"artifact_sha256": "1cba4b6d89d7f11396db9c554c9233d6096f930c387f0bcafdeb23bb7f811551", "source_sha256": "eb21431dabeaafc82a1e3ccf24278616e46ed082eca1de4d328c758ee82ee2c7", "target_language": "php"}
// language_validator.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/language_validator.py
// auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/language_validator.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * Multi-language script validator supporting 8+ languages.
 * WebSearch integration for documentation lookup.
 */

class ValidationResult {
    public string $language;
    public bool $valid;
    public array $errors;
    public array $warnings;
    public ?string $docUrl;

    public function __construct(string $language, bool $valid, array $errors, array $warnings, ?string $docUrl = null) {
        $this->language = $language;
        $this->valid = $valid;
        $this->errors = $errors;
        $this->warnings = $warnings;
        $this->docUrl = $docUrl;
    }
}

class LanguageValidator {
    private const LANGUAGES = [
        "bash" => ["cmd" => "bash", "args" => ["-n"], "linter" => "shellcheck"],
        "sh" => ["cmd" => "sh", "args" => ["-n"], "linter" => "shellcheck"],
        "python" => ["cmd" => "python3", "args" => ["-m", "py_compile"], "linter" => "pylint"],
        "perl" => ["cmd" => "perl", "args" => ["-c"], "linter" => "perlcritic"],
        "raku" => ["cmd" => "raku", "args" => ["-c"], "linter" => null],
        "powershell" => ["cmd" => "pwsh", "args" => ["-Command", "Get-Command"], "linter" => null],
        "javascript" => ["cmd" => "node", "args" => ["--check"], "linter" => "eslint"],
        "tcl" => ["cmd" => "tclsh", "args" => [], "linter" => null],
    ];

    private string $language;
    private bool $useWebsearch;
    private array $config;

    public function __construct(string $language, bool $useWebsearch = true) {
        $this->language = strtolower($language);
        $this->useWebsearch = $useWebsearch;
        $this->config = self::LANGUAGES[$this->language] ?? [];
        
        if (empty($this->config)) {
            throw new InvalidArgumentException("Unsupported language: $language");
        }
    }

    /**
     * Validate a script file.
     */
    public function validate(string $scriptPath): ValidationResult {
        $errors = [];
        $warnings = [];

        // Syntax check
        try {
            $command = array_merge([$this->config["cmd"]], $this->config["args"], [$scriptPath]);
            $process = proc_open(
                implode(' ', array_map('escapeshellarg', $command)),
                [
                    0 => ['pipe', 'r'],
                    1 => ['pipe', 'w'],
                    2 => ['pipe', 'w']
                ],
                $pipes
            );

            if (is_resource($process)) {
                fclose($pipes[0]);
                $stdout = stream_get_contents($pipes[1]);
                $stderr = stream_get_contents($pipes[2]);
                fclose($pipes[1]);
                fclose($pipes[2]);
                
                $returnCode = proc_close($process);
                
                if ($returnCode !== 0) {
                    $errors[] = $stderr ?: 'Syntax error';
                }
            } else {
                $errors[] = "Failed to start process";
            }
        } catch (Exception $e) {
            $errors[] = "Validation error: " . $e->getMessage();
        }

        // Linter check if available
        if (!empty($this->config["linter"])) {
            $linterWarnings = $this->_runLinter($scriptPath);
            $warnings = array_merge($warnings, $linterWarnings);
        }

        return new ValidationResult(
            $this->language,
            count($errors) === 0,
            $errors,
            $warnings,
            $this->useWebsearch ? $this->_fetchDocs() : null
        );
    }

    /**
     * Run language-specific linter.
     */
    private function _runLinter(string $scriptPath): array {
        $linter = $this->config["linter"];
        $warnings = [];

        try {
            if ($linter === "shellcheck") {
                $command = ['shellcheck', '-f', 'gcc', $scriptPath];
                $process = proc_open(
                    implode(' ', array_map('escapeshellarg', $command)),
                    [
                        0 => ['pipe', 'r'],
                        1 => ['pipe', 'w'],
                        2 => ['pipe', 'w']
                    ],
                    $pipes
                );

                if (is_resource($process)) {
                    fclose($pipes[0]);
                    $stdout = stream_get_contents($pipes[1]);
                    fclose($pipes[1]);
                    fclose($pipes[2]);
                    
                    proc_close($process);
                    
                    if (!empty($stdout)) {
                        $warnings = explode("\n", trim($stdout));
                    }
                }
            } elseif ($linter === "pylint") {
                $command = ['pylint', '--output-format=parseable', $scriptPath];
                $process = proc_open(
                    implode(' ', array_map('escapeshellarg', $command)),
                    [
                        0 => ['pipe', 'r'],
                        1 => ['pipe', 'w'],
                        2 => ['pipe', 'w']
                    ],
                    $pipes
                );

                if (is_resource($process)) {
                    fclose($pipes[0]);
                    $stdout = stream_get_contents($pipes[1]);
                    fclose($pipes[1]);
                    fclose($pipes[2]);
                    
                    proc_close($process);
                    
                    if (!empty($stdout)) {
                        $warnings = explode("\n", trim($stdout));
                    }
                }
            }
        } catch (Exception $e) {
            $warnings[] = "Linter error: " . $e->getMessage();
        }

        return $warnings;
    }

    /**
     * Fetch documentation URL via WebSearch if enabled.
     */
    private function _fetchDocs(): ?string {
        if (!$this->useWebsearch) {
            return null;
        }

        // Return known good documentation URLs
        $docs = [
            "powershell" => "https://docs.microsoft.com/powershell/",
            "raku" => "https://docs.raku.org/",
            "tcl" => "https://www.tcl.tk/",
        ];
        
        return $docs[$this->language] ?? null;
    }
}

function main() {
    global $argv, $argc;
    
    if ($argc < 3) {
        echo "Usage: php language_validator.php <script> --lang=<language>\n";
        exit(1);
    }
    
    $scriptPath = '';
    $language = '';
    $useWebsearch = true;
    
    foreach (array_slice($argv, 1) as $arg) {
        if (strpos($arg, '--lang=') === 0) {
            $language = substr($arg, 7);
        } elseif ($arg === '--no-websearch') {
            $useWebsearch = false;
        } elseif (file_exists($arg)) {
            $scriptPath = $arg;
        }
    }
    
    if (empty($scriptPath) || empty($language)) {
        echo "Error: Script path and language are required\n";
        exit(1);
    }
    
    try {
        $validator = new LanguageValidator($language, $useWebsearch);
        $result = $validator->validate($scriptPath);
        
        echo "Language: {$result->language}\n";
        echo "Valid: " . ($result->valid ? 'true' : 'false') . "\n";
        
        if (!empty($result->errors)) {
            echo "Errors: " . count($result->errors) . "\n";
            foreach (array_slice($result->errors, 0, 5) as $err) {
                echo "  - $err\n";
            }
        }
        
        if (!empty($result->warnings)) {
            echo "Warnings: " . count($result->warnings) . "\n";
            foreach (array_slice($result->warnings, 0, 5) as $warn) {
                echo "  - $warn\n";
            }
        }
        
        if ($result->docUrl) {
            echo "Docs: {$result->docUrl}\n";
        }
        
        exit($result->valid ? 0 : 1);
    } catch (Exception $e) {
        echo "Error: " . $e->getMessage() . "\n";
        exit(1);
    }
}

if (isset($argv) && basename(__FILE__) === basename($_SERVER['SCRIPT_NAME'])) {
    main();
}
?>
