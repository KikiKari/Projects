#!/usr/bin/env node
// language_validator.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/language_validator.py
// auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/language_validator.py
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

/**
 * Multi-language script validator supporting 8+ languages.
 * WebSearch integration for documentation lookup.
 */

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

class ValidationResult {
    constructor(language, valid, errors, warnings, docUrl = null) {
        this.language = language;
        this.valid = valid;
        this.errors = errors;
        this.warnings = warnings;
        this.docUrl = docUrl;
    }
}

class LanguageValidator {
    LANGUAGES = {
        "bash": { cmd: "bash", args: ["-n"], linter: "shellcheck" },
        "sh": { cmd: "sh", args: ["-n"], linter: "shellcheck" },
        "python": { cmd: "python3", args: ["-m", "py_compile"], linter: "pylint" },
        "perl": { cmd: "perl", args: ["-c"], linter: "perlcritic" },
        "raku": { cmd: "raku", args: ["-c"], linter: null },
        "powershell": { cmd: "pwsh", args: ["-Command", "Get-Command"], linter: null },
        "javascript": { cmd: "node", args: ["--check"], linter: "eslint" },
        "tcl": { cmd: "tclsh", args: [], linter: null },
    };

    constructor(language, useWebsearch = true) {
        this.language = language.toLowerCase();
        this.useWebsearch = useWebsearch;
        this.config = this.LANGUAGES[this.language];
        if (!this.config) {
            throw new Error(`Unsupported language: ${language}`);
        }
    }

    validate(scriptPath) {
        return new Promise((resolve) => {
            const errors = [];
            const warnings = [];

            // Syntax check
            const args = [...this.config.args, scriptPath];
            const child = spawn(this.config.cmd, args, { timeout: 30000 });

            let stderr = '';
            child.stderr.on('data', (data) => {
                stderr += data.toString();
            });

            child.on('close', (code) => {
                if (code !== 0) {
                    errors.push(stderr);
                }
                resolve({ errors, warnings });
            });

            child.on('error', (err) => {
                errors.push(`Command error: ${err.message}`);
                if (this.useWebsearch) {
                    const docUrl = this._fetchDocs();
                    resolve(new ValidationResult(this.language, false, errors, warnings, docUrl));
                } else {
                    resolve(new ValidationResult(this.language, false, errors, warnings));
                }
            });

            child.on('exit', (code, signal) => {
                if (signal === 'SIGTERM') {
                    errors.push("Validation timeout");
                    resolve(new ValidationResult(this.language, false, errors, warnings));
                }
            });
        }).then(({ errors, warnings }) => {
            // Linter check if available
            if (this.config.linter) {
                return this._runLinter(scriptPath).then(linterWarnings => {
                    warnings.push(...linterWarnings);
                    return new ValidationResult(
                        this.language,
                        errors.length === 0,
                        errors,
                        warnings
                    );
                });
            }
            return new ValidationResult(
                this.language,
                errors.length === 0,
                errors,
                warnings
            );
        });
    }

    _runLinter(scriptPath) {
        return new Promise((resolve) => {
            const linter = this.config.linter;
            const warnings = [];

            if (linter === "shellcheck") {
                const child = spawn("shellcheck", ["-f", "gcc", scriptPath]);
                let stdout = '';
                child.stdout.on('data', (data) => {
                    stdout += data.toString();
                });
                child.on('close', () => {
                    if (stdout.trim()) {
                        warnings.push(...stdout.trim().split("\n"));
                    }
                    resolve(warnings);
                });
                child.on('error', () => {
                    warnings.push(`Linter not installed: ${linter}`);
                    resolve(warnings);
                });
            } else if (linter === "pylint") {
                const child = spawn("pylint", ["--output-format=parseable", scriptPath]);
                let stdout = '';
                child.stdout.on('data', (data) => {
                    stdout += data.toString();
                });
                child.on('close', () => {
                    if (stdout.trim()) {
                        warnings.push(...stdout.trim().split("\n"));
                    }
                    resolve(warnings);
                });
                child.on('error', () => {
                    warnings.push(`Linter not installed: ${linter}`);
                    resolve(warnings);
                });
            } else {
                resolve(warnings);
            }
        });
    }

    _fetchDocs() {
        if (!this.useWebsearch) {
            return null;
        }

        const docs = {
            "powershell": "https://docs.microsoft.com/powershell/",
            "raku": "https://docs.raku.org/",
            "tcl": "https://www.tcl.tk/",
        };
        return docs[this.language] || null;
    }
}

function main() {
    const args = process.argv.slice(2);
    let scriptPath = null;
    let language = null;
    let useWebsearch = true;

    for (let i = 0; i < args.length; i++) {
        if (args[i] === "--lang" && i + 1 < args.length) {
            language = args[i + 1];
            i++;
        } else if (args[i] === "--no-websearch") {
            useWebsearch = false;
        } else if (!scriptPath && !args[i].startsWith("--")) {
            scriptPath = args[i];
        }
    }

    if (!scriptPath || !language) {
        console.error("Usage: node language_validator.js <script> --lang <language> [--no-websearch]");
        process.exit(1);
    }

    if (!fs.existsSync(scriptPath)) {
        console.error(`Script file not found: ${scriptPath}`);
        process.exit(1);
    }

    const validator = new LanguageValidator(language, useWebsearch);
    validator.validate(scriptPath).then(result => {
        console.log(`Language: ${result.language}`);
        console.log(`Valid: ${result.valid}`);
        if (result.errors.length > 0) {
            console.log(`Errors: ${result.errors.length}`);
            result.errors.slice(0, 5).forEach(err => {
                console.log(`  - ${err}`);
            });
        }
        if (result.warnings.length > 0) {
            console.log(`Warnings: ${result.warnings.length}`);
            result.warnings.slice(0, 5).forEach(warn => {
                console.log(`  - ${warn}`);
            });
        }
        if (result.docUrl) {
            console.log(`Docs: ${result.docUrl}`);
        }

        process.exit(result.valid ? 0 : 1);
    });
}

if (require.main === module) {
    main();
}

module.exports = { LanguageValidator, ValidationResult };
