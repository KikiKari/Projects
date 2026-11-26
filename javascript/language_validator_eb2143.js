#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "f574a9fa2bee886d984db4e27b09a9fbfd0ac2231d58de49d2b5eccc9284e079", "source_sha256": "eb21431dabeaafc82a1e3ccf24278616e46ed082eca1de4d328c758ee82ee2c7", "target_language": "javascript"}
// language_validator.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/language_validator.py
// auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/language_validator.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/**
 * Multi-language script validator supporting 8+ languages.
 * WebSearch integration for documentation lookup.
 */

const { spawnSync } = require('child_process');
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
    static LANGUAGES = {
        bash: { cmd: "bash", args: ["-n"], linter: "shellcheck" },
        sh: { cmd: "sh", args: ["-n"], linter: "shellcheck" },
        python: { cmd: "python3", args: ["-m", "py_compile"], linter: "pylint" },
        perl: { cmd: "perl", args: ["-c"], linter: "perlcritic" },
        raku: { cmd: "raku", args: ["-c"], linter: null },
        powershell: { cmd: "pwsh", args: ["-Command", "Get-Command"], linter: null },
        javascript: { cmd: "node", args: ["--check"], linter: "eslint" },
        tcl: { cmd: "tclsh", args: [], linter: null },
    };

    constructor(language, useWebsearch = true) {
        this.language = language.toLowerCase();
        this.useWebsearch = useWebsearch;
        this.config = LanguageValidator.LANGUAGES[this.language];
        if (!this.config) {
            throw new Error(`Unsupported language: ${language}`);
        }
    }

    validate(scriptPath) {
        const errors = [];
        const warnings = [];

        // Syntax check
        try {
            const result = spawnSync(
                this.config.cmd,
                [...this.config.args, scriptPath],
                { encoding: 'utf8', timeout: 30000 }
            );
            
            if (result.status !== 0) {
                errors.push(result.stderr);
            }
        } catch (error) {
            if (error.code === 'ETIMEDOUT') {
                errors.push("Validation timeout");
            } else if (error.code === 'ENOENT') {
                errors.push(`Command not found: ${this.config.cmd}`);
                if (this.useWebsearch) {
                    const docUrl = this._fetchDocs();
                    return new ValidationResult(this.language, false, errors, warnings, docUrl);
                }
            } else {
                errors.push(error.message);
            }
        }

        // Linter check if available
        if (this.config.linter) {
            const linterWarnings = this._runLinter(scriptPath);
            warnings.push(...linterWarnings);
        }

        return new ValidationResult(
            this.language,
            errors.length === 0,
            errors,
            warnings
        );
    }

    _runLinter(scriptPath) {
        const linter = this.config.linter;
        const warnings = [];

        try {
            let result;
            if (linter === "shellcheck") {
                result = spawnSync(
                    "shellcheck",
                    ["-f", "gcc", scriptPath],
                    { encoding: 'utf8' }
                );
                if (result.stdout) {
                    warnings.push(...result.stdout.trim().split("\n").filter(line => line));
                }
            } else if (linter === "pylint") {
                result = spawnSync(
                    "pylint",
                    ["--output-format=parseable", scriptPath],
                    { encoding: 'utf8' }
                );
                if (result.stdout) {
                    warnings.push(...result.stdout.trim().split("\n").filter(line => line));
                }
            }
        } catch (error) {
            warnings.push(`Linter error: ${error.message}`);
        }

        return warnings;
    }

    _fetchDocs() {
        if (!this.useWebsearch) {
            return null;
        }

        // Return known good documentation URLs
        const docs = {
            powershell: "https://docs.microsoft.com/powershell/",
            raku: "https://docs.raku.org/",
            tcl: "https://www.tcl.tk/",
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
            language = args[++i];
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
    const result = validator.validate(scriptPath);

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
}

if (require.main === module) {
    main();
}

module.exports = { LanguageValidator, ValidationResult };
