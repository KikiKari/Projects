#!/usr/bin/env node
// TEST_A~1.PY — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:abstraction-manager/TEST_A~1.PY
// auch in: Projects@abstractions:abstractions/test_abstractions_manager.py
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

/**
 * test_abstractions_manager.js — Unit-Tests für den Abstractions Manager.
 *
 * Testet alle kritischen Sicherheits- und Kernfunktionen:
 *     - Path-Traversal-Schutz (validate_source_file_path)
 *     - Shell-Injection-Prävention (validate_task_description)
 *     - Modell-Allowlist (validate_ai_model_name)
 *     - Zielsprachen-Validierung (validate_target_language)
 *     - Timeout-Validierung (validate_timeout_seconds)
 *     - JSON-Serialisierung (create_abstraction.js Hilfsfunktionen)
 *     - File-Change-Detection (Hash-basiert)
 *     - Atomisches State-File-Schreiben
 *
 * Ausführen:
 *     npm test
 *
 * Author: OpenClaw Team
 * Version: 1.0.0
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const os = require('os');

// Mock für pytest-ähnliche Tests
const assert = require('assert');

// Importiere lokale Module
const {
    ValidationError,
    PortationError,
    ApiKeyError,
    StateFileError,
} = require('./exceptions');

const {
    validate_source_file_path,
    validate_task_description,
    validate_ai_model_name,
    validate_target_language,
    validate_timeout_seconds,
    load_and_validate_api_key,
    ALLOWED_TARGET_LANGUAGES,
    ALLOWED_AI_MODELS,
} = require('./validators');

const {
    compute_file_sha256,
    has_source_file_changed,
    load_abstraction_state,
    save_abstraction_state_atomically,
    LANGUAGE_FILE_EXTENSIONS,
} = require('./create_abstraction');

// ===========================================================================
// Test-Hilfsfunktionen
// ===========================================================================

function createTempDir() {
    return fs.mkdtempSync(path.join(os.tmpdir(), 'test-'));
}

function createTempFile(dir, filename, content) {
    const filepath = path.join(dir, filename);
    fs.writeFileSync(filepath, content, 'utf8');
    return filepath;
}

function removeTempDir(dir) {
    fs.rmSync(dir, { recursive: true, force: true });
}

// ===========================================================================
// Tests: Path-Traversal-Schutz
// ===========================================================================

class TestSourceFilePathValidation {
    static test_valid_path_within_allowed_directory_is_accepted() {
        const tempDir = createTempDir();
        const scriptsDir = path.join(tempDir, 'skills', 'scripts');
        fs.mkdirSync(scriptsDir, { recursive: true });
        const scriptPath = createTempFile(scriptsDir, 'db_maintainer.py', "# Test-Script\nprint('hello world')\n");
        
        process.env.OPENCLAW_WORKSPACE = tempDir;
        
        try {
            const result = validate_source_file_path(scriptPath);
            assert.strictEqual(result, path.resolve(scriptPath));
        } finally {
            removeTempDir(tempDir);
        }
    }

    static test_nonexistent_file_raises_file_not_found_error() {
        assert.throws(() => {
            validate_source_file_path('/absolutely/nonexistent/path/script.py');
        }, { code: 'ENOENT' });
    }

    static test_directory_instead_of_file_raises_validation_error() {
        const tempDir = createTempDir();
        try {
            assert.throws(() => {
                validate_source_file_path(tempDir);
            }, ValidationError);
        } finally {
            removeTempDir(tempDir);
        }
    }

    static test_path_outside_workspace_raises_validation_error() {
        process.env.OPENCLAW_WORKSPACE = '/home/openclaw/.openclaw/workspace';
        
        const traversalAttempts = [
            '/etc/passwd',
            '/etc/shadow',
            '/root/.ssh/id_rsa',
            '/proc/1/cmdline',
        ];
        
        for (const attempt of traversalAttempts) {
            assert.throws(() => {
                validate_source_file_path(attempt);
            }, (err) => {
                return err instanceof ValidationError || err.code === 'ENOENT';
            });
        }
    }
}

// ===========================================================================
// Tests: Shell-Injection-Prävention
// ===========================================================================

class TestTaskDescriptionValidation {
    static test_valid_task_descriptions_are_accepted() {
        const validTasks = [
            'Port db_maintainer.py to Go',
            'Add error handling to json_processor',
            'Refactor websearch-crawl.sh for Perl 5',
            'Port check-live.js with full JSDoc',
            'Migrate log_collector.py to Ruby',
        ];
        
        for (const task of validTasks) {
            const result = validate_task_description(task);
            assert.strictEqual(result, task.trim());
        }
    }

    static test_shell_metacharacters_are_rejected() {
        const maliciousInputs = [
            ['; rm -rf /', 'Semikolon + Befehl'],
            ['$(cat /etc/passwd)', 'Befehlssubstitution $(...)'],
            ['`whoami`', 'Backtick-Substitution'],
            ['task && evil_cmd', '&&-Verkettung'],
            ['task | cat /etc/shadow', 'Pipe-Redirect'],
            ['task\ncommand', 'Newline-Injection'],
            ['task; exit 0', 'Semikolon-Injection'],
            ['task > /tmp/evil', 'Ausgabe-Redirect'],
        ];
        
        for (const [input, description] of maliciousInputs) {
            assert.throws(() => {
                validate_task_description(input);
            }, ValidationError);
        }
    }

    static test_empty_task_raises_validation_error() {
        assert.throws(() => {
            validate_task_description('');
        }, ValidationError);
    }

    static test_whitespace_only_task_raises_validation_error() {
        assert.throws(() => {
            validate_task_description('   ');
        }, ValidationError);
    }

    static test_task_at_maximum_length_is_accepted() {
        const maxLengthTask = 'a'.repeat(500);
        const result = validate_task_description(maxLengthTask);
        assert.strictEqual(result.length, 500);
    }

    static test_task_exceeding_maximum_length_raises_validation_error() {
        const tooLongTask = 'a'.repeat(501);
        assert.throws(() => {
            validate_task_description(tooLongTask);
        }, ValidationError);
    }
}

// ===========================================================================
// Tests: Modell-Allowlist
// ===========================================================================

class TestAiModelValidation {
    static test_all_allowed_models_are_accepted() {
        for (const model of ALLOWED_AI_MODELS) {
            const result = validate_ai_model_name(model);
            assert.strictEqual(result, model);
        }
    }

    static test_unknown_models_are_rejected() {
        const invalidModels = [
            'gpt-4',                          // Ohne Provider-Prefix
            'unknown-model',                  // Unbekanntes Modell
            'openrouter/evil; rm -rf /',      // Injection-Versuch
            '',                               // Leer
            'claude-3-5-sonnet-20241022',     // Ohne openrouter/-Prefix
        ];
        
        for (const model of invalidModels) {
            assert.throws(() => {
                validate_ai_model_name(model);
            }, ValidationError);
        }
    }
}

// ===========================================================================
// Tests: Zielsprachen-Validierung
// ===========================================================================

class TestTargetLanguageValidation {
    static test_all_supported_languages_are_accepted() {
        for (const language of ALLOWED_TARGET_LANGUAGES) {
            const result = validate_target_language(language);
            assert.strictEqual(result, language.toLowerCase());
        }
    }

    static test_language_is_normalized_to_lowercase() {
        const result = validate_target_language('JavaScript');
        assert.strictEqual(result, 'javascript');
    }

    static test_unsupported_language_raises_validation_error() {
        assert.throws(() => {
            validate_target_language('cobol');
        }, ValidationError);
    }

    static test_language_with_injection_attempt_raises_validation_error() {
        assert.throws(() => {
            validate_target_language('perl5; rm -rf /');
        }, ValidationError);
    }
}

// ===========================================================================
// Tests: Timeout-Validierung
// ===========================================================================

class TestTimeoutValidation {
    static test_valid_timeouts_are_accepted() {
        const validTimeouts = [1, 60, 1800, 3600, 7200];
        for (const timeout of validTimeouts) {
            const result = validate_timeout_seconds(timeout);
            assert.strictEqual(result, timeout);
        }
    }

    static test_out_of_range_timeouts_raise_validation_error() {
        const invalidTimeouts = [0, -1, 7201, 99999];
        for (const timeout of invalidTimeouts) {
            assert.throws(() => {
                validate_timeout_seconds(timeout);
            }, ValidationError);
        }
    }

    static test_float_timeout_raises_validation_error() {
        assert.throws(() => {
            validate_timeout_seconds(1800.5);
        }, ValidationError);
    }
}

// ===========================================================================
// Tests: API-Schlüssel-Validierung
// ===========================================================================

class TestApiKeyValidation {
    static test_valid_api_key_is_returned() {
        const fakeKey = 'sk-ant-api03-' + 'x'.repeat(30);
        process.env.ANTHROPIC_API_KEY = fakeKey;
        const result = load_and_validate_api_key('ANTHROPIC');
        assert.strictEqual(result, fakeKey);
    }

    static test_missing_api_key_raises_api_key_error() {
        delete process.env.ANTHROPIC_API_KEY;
        assert.throws(() => {
            load_and_validate_api_key('ANTHROPIC');
        }, ApiKeyError);
    }

    static test_too_short_api_key_raises_api_key_error() {
        process.env.ANTHROPIC_API_KEY = 'short';
        assert.throws(() => {
            load_and_validate_api_key('ANTHROPIC');
        }, ApiKeyError);
    }
}

// ===========================================================================
// Tests: File-Change-Detection
// ===========================================================================

class TestFileChangeDetection {
    static test_unchanged_file_is_not_detected_as_changed() {
        const tempDir = createTempDir();
        const testFile = path.join(tempDir, 'script.py');
        fs.writeFileSync(testFile, "print('hello')", 'utf8');
        
        try {
            const currentHash = compute_file_sha256(testFile);
            const hashCache = { [testFile]: currentHash };
            
            assert.strictEqual(has_source_file_changed(testFile, hashCache), false);
        } finally {
            removeTempDir(tempDir);
        }
    }

    static test_modified_file_is_detected_as_changed() {
        const tempDir = createTempDir();
        const testFile = path.join(tempDir, 'script.py');
        fs.writeFileSync(testFile, "print('hello')", 'utf8');
        const oldHash = compute_file_sha256(testFile);
        
        try {
            const hashCache = { [testFile]: oldHash };
            fs.writeFileSync(testFile, "print('changed!')", 'utf8');
            
            assert.strictEqual(has_source_file_changed(testFile, hashCache), true);
        } finally {
            removeTempDir(tempDir);
        }
    }

    static test_new_file_without_cached_hash_is_detected_as_changed() {
        const tempDir = createTempDir();
        const testFile = path.join(tempDir, 'new_script.py');
        fs.writeFileSync(testFile, "print('new')", 'utf8');
        const emptyCache = {};
        
        try {
            assert.strictEqual(has_source_file_changed(testFile, emptyCache), true);
        } finally {
            removeTempDir(tempDir);
        }
    }

    static test_different_files_produce_different_hashes() {
        const tempDir = createTempDir();
        const fileA = path.join(tempDir, 'a.py');
        const fileB = path.join(tempDir, 'b.py');
        fs.writeFileSync(fileA, 'content A', 'utf8');
        fs.writeFileSync(fileB, 'content B', 'utf8');
        
        try {
            assert.notStrictEqual(compute_file_sha256(fileA), compute_file_sha256(fileB));
        } finally {
            removeTempDir(tempDir);
        }
    }

    static test_identical_content_produces_identical_hash() {
        const tempDir = createTempDir();
        const fileA = path.join(tempDir, 'a.py');
        const fileB = path.join(tempDir, 'b.py');
        const identicalContent = 'identical content';
        fs.writeFileSync(fileA, identicalContent, 'utf8');
        fs.writeFileSync(fileB, identicalContent, 'utf8');
        
        try {
            assert.strictEqual(compute_file_sha256(fileA), compute_file_sha256(fileB));
        } finally {
            removeTempDir(tempDir);
        }
    }
}

// ===========================================================================
// Tests: Atomisches State-File
// ===========================================================================

class TestAtomicStateFile {
    static test_state_is_saved_and_loaded_correctly() {
        const tempDir = createTempDir();
        const stateFile = path.join(tempDir, 'state.json');
        const testState = {
            file_hashes: { 'script.py': 'abc123' },
            last_run: '2026-05-26T10:00:00',
        };
        
        try {
            save_abstraction_state_atomically(stateFile, testState);
            const loadedState = load_abstraction_state(stateFile);
            assert.deepStrictEqual(loadedState, testState);
        } finally {
            removeTempDir(tempDir);
        }
    }

    static test_nonexistent_state_file_returns_empty_dict() {
        const tempDir = createTempDir();
        const nonexistentPath = path.join(tempDir, 'nonexistent', 'state.json');
        
        try {
            const result = load_abstraction_state(nonexistentPath);
            assert.deepStrictEqual(result, {});
        } finally {
            removeTempDir(tempDir);
        }
    }

    static test_atomic_write_creates_parent_directories() {
        const tempDir = createTempDir();
        const deepPath = path.join(tempDir, 'a', 'b', 'c', 'state.json');
        
        try {
            save_abstraction_state_atomically(deepPath, { key: 'value' });
            assert.strictEqual(fs.existsSync(deepPath), true);
        } finally {
            removeTempDir(tempDir);
        }
    }

    static test_atomic_write_leaves_no_temp_file_on_success() {
        const tempDir = createTempDir();
        const statePath = path.join(tempDir, 'state.json');
        
        try {
            save_abstraction_state_atomically(statePath, { data: 1 });
            const tempFiles = fs.readdirSync(tempDir).filter(f => f.endsWith('.tmp'));
            assert.strictEqual(tempFiles.length, 0);
        } finally {
            removeTempDir(tempDir);
        }
    }

    static test_invalid_json_in_state_file_raises_state_file_error() {
        const tempDir = createTempDir();
        const corruptedState = path.join(tempDir, 'state.json');
        fs.writeFileSync(corruptedState, '{ invalid json !!!', 'utf8');
        
        try {
            assert.throws(() => {
                load_abstraction_state(corruptedState);
            }, StateFileError);
        } finally {
            removeTempDir(tempDir);
        }
    }
}

// ===========================================================================
// Tests: Sprachzuordnung
// ===========================================================================

class TestLanguageFileExtensions {
    static test_all_supported_languages_have_file_extensions() {
        for (const language of ALLOWED_TARGET_LANGUAGES) {
            assert.ok(LANGUAGE_FILE_EXTENSIONS.hasOwnProperty(language), 
                `Fehlende Extension für Sprache: ${language}`);
        }
    }

    static test_correct_file_extension_per_language() {
        const languageExtensions = [
            ['perl5', '.pl'],
            ['perl6', '.raku'],
            ['javascript', '.js'],
            ['python', '.py'],
            ['bash', '.sh'],
            ['powershell', '.ps1'],
            ['go', '.go'],
        ];
        
        for (const [language, expectedExt] of languageExtensions) {
            assert.strictEqual(LANGUAGE_FILE_EXTENSIONS[language], expectedExt);
        }
    }
}

// ===========================================================================
// Testausführung
// ===========================================================================

function runTests() {
    const testClasses = [
        TestSourceFilePathValidation,
        TestTaskDescriptionValidation,
        TestAiModelValidation,
        TestTargetLanguageValidation,
        TestTimeoutValidation,
        TestApiKeyValidation,
        TestFileChangeDetection,
        TestAtomicStateFile,
        TestLanguageFileExtensions,
    ];

    let passed = 0;
    let failed = 0;

    for (const testClass of testClasses) {
        const className = testClass.name;
        console.log(`\nRunning tests for ${className}...`);
        
        const methods = Object.getOwnPropertyNames(testClass)
            .filter(prop => prop.startsWith('test_'));
            
        for (const method of methods) {
            try {
                testClass[method]();
                console.log(`  ✓ ${method}`);
                passed++;
            } catch (error) {
                console.log(`  ✗ ${method}: ${error.message}`);
                failed++;
            }
        }
    }

    console.log(`\nTests completed: ${passed} passed, ${failed} failed`);
    process.exit(failed > 0 ? 1 : 0);
}

// Tests ausführen, wenn das Skript direkt aufgerufen wird
if (require.main === module) {
    runTests();
}

module.exports = {
    TestSourceFilePathValidation,
    TestTaskDescriptionValidation,
    TestAiModelValidation,
    TestTargetLanguageValidation,
    TestTimeoutValidation,
    TestApiKeyValidation,
    TestFileChangeDetection,
    TestAtomicStateFile,
    TestLanguageFileExtensions,
};
