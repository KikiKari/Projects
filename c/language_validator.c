// abstraction-provenance: {"artifact_sha256": "46a30298f6796e50498454642b07aa8199e80b4f884abbb3cacf3194ff55c2e2", "source_sha256": "eb21431dabeaafc82a1e3ccf24278616e46ed082eca1de4d328c758ee82ee2c7", "target_language": "c"}
// language_validator.py — portiert nach c
// Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/language_validator.py
// auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/language_validator.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>

#define MAX_LANGUAGES 8
#define MAX_ERRORS 100
#define MAX_WARNINGS 100
#define MAX_OUTPUT 4096

typedef struct {
    char* language;
    char* cmd;
    char** args;
    int arg_count;
    char* linter;
} LanguageConfig;

typedef struct {
    char* errors[MAX_ERRORS];
    char* warnings[MAX_WARNINGS];
    int error_count;
    int warning_count;
    char* doc_url;
} ValidationResult;

LanguageConfig languages[] = {
    {"bash", "bash", (char*[]){"-n"}, 1, "shellcheck"},
    {"sh", "sh", (char*[]){"-n"}, 1, "shellcheck"},
    {"python", "python3", (char*[]){"-m", "py_compile"}, 2, "pylint"},
    {"perl", "perl", (char*[]){"-c"}, 1, "perlcritic"},
    {"raku", "raku", (char*[]){"-c"}, 1, NULL},
    {"powershell", "pwsh", (char*[]){"-Command", "Get-Command"}, 2, NULL},
    {"javascript", "node", (char*[]){"--check"}, 1, "eslint"},
    {"tcl", "tclsh", (char*[]){}, 0, NULL}
};

const char* get_doc_url(const char* language) {
    if (strcmp(language, "powershell") == 0) {
        return "https://docs.microsoft.com/powershell/";
    } else if (strcmp(language, "raku") == 0) {
        return "https://docs.raku.org/";
    } else if (strcmp(language, "tcl") == 0) {
        return "https://www.tcl.tk/";
    }
    return NULL;
}

void add_error(ValidationResult* result, const char* error) {
    if (result->error_count < MAX_ERRORS - 1) {
        result->errors[result->error_count] = strdup(error);
        result->error_count++;
    }
}

void add_warning(ValidationResult* result, const char* warning) {
    if (result->warning_count < MAX_WARNINGS - 1) {
        result->warnings[result->warning_count] = strdup(warning);
        result->warning_count++;
    }
}

int run_command_with_timeout(char* cmd[], const char* script_path, char* output, size_t output_size, int timeout_seconds) {
    pid_t pid;
    int pipefd[2];
    pipe(pipefd);
    
    pid = fork();
    if (pid == 0) {
        close(pipefd[0]);
        dup2(pipefd[1], STDOUT_FILENO);
        dup2(pipefd[1], STDERR_FILENO);
        close(pipefd[1]);
        
        execvp(cmd[0], cmd);
        perror("execvp failed");
        exit(1);
    } else if (pid > 0) {
        close(pipefd[1]);
        
        // Set up timeout
        alarm(timeout_seconds);
        signal(SIGALRM, SIG_DFL);
        
        ssize_t bytes_read = read(pipefd[0], output, output_size - 1);
        if (bytes_read > 0) {
            output[bytes_read] = '\0';
        }
        close(pipefd[0]);
        
        int status;
        waitpid(pid, &status, 0);
        alarm(0); // Cancel alarm
        
        if (WIFEXITED(status)) {
            return WEXITSTATUS(status);
        } else {
            return -1; // Process was terminated by signal
        }
    } else {
        perror("fork failed");
        return -1;
    }
}

void run_linter(const char* linter, const char* script_path, ValidationResult* result) {
    char output[MAX_OUTPUT];
    char* cmd[10];
    int status;
    
    if (strcmp(linter, "shellcheck") == 0) {
        cmd[0] = "shellcheck";
        cmd[1] = "-f";
        cmd[2] = "gcc";
        cmd[3] = (char*)script_path;
        cmd[4] = NULL;
        
        status = run_command_with_timeout(cmd, script_path, output, sizeof(output), 30);
        if (status != 0 && strlen(output) > 0) {
            add_warning(result, output);
        }
    } else if (strcmp(linter, "pylint") == 0) {
        cmd[0] = "pylint";
        cmd[1] = "--output-format=parseable";
        cmd[2] = (char*)script_path;
        cmd[3] = NULL;
        
        status = run_command_with_timeout(cmd, script_path, output, sizeof(output), 30);
        if (status != 0 && strlen(output) > 0) {
            add_warning(result, output);
        }
    } else {
        char warning[256];
        snprintf(warning, sizeof(warning), "Linter not installed: %s", linter);
        add_warning(result, warning);
    }
}

ValidationResult validate_script(const char* language, const char* script_path, int use_websearch) {
    ValidationResult result = {0};
    LanguageConfig* config = NULL;
    
    for (int i = 0; i < MAX_LANGUAGES; i++) {
        if (strcmp(languages[i].language, language) == 0) {
            config = &languages[i];
            break;
        }
    }
    
    if (!config) {
        char error[256];
        snprintf(error, sizeof(error), "Unsupported language: %s", language);
        add_error(&result, error);
        return result;
    }
    
    // Build command array
    char* cmd[20];
    cmd[0] = config->cmd;
    for (int i = 0; i < config->arg_count; i++) {
        cmd[i + 1] = config->args[i];
    }
    cmd[config->arg_count + 1] = (char*)script_path;
    cmd[config->arg_count + 2] = NULL;
    
    char output[MAX_OUTPUT];
    int status = run_command_with_timeout(cmd, script_path, output, sizeof(output), 30);
    
    if (status == -1) {
        add_error(&result, "Validation timeout");
    } else if (status != 0) {
        if (strlen(output) > 0) {
            add_error(&result, output);
        } else {
            char error[256];
            snprintf(error, sizeof(error), "Command failed with exit code %d", status);
            add_error(&result, error);
        }
    }
    
    // Check if command not found
    if (access(config->cmd, X_OK) != 0 && errno == ENOENT) {
        char error[256];
        snprintf(error, sizeof(error), "Command not found: %s", config->cmd);
        add_error(&result, error);
        
        if (use_websearch) {
            result.doc_url = (char*)get_doc_url(language);
        }
        return result;
    }
    
    // Run linter if available
    if (config->linter) {
        run_linter(config->linter, script_path, &result);
    }
    
    return result;
}

void print_result(const char* language, ValidationResult* result) {
    printf("Language: %s\n", language);
    printf("Valid: %s\n", result->error_count == 0 ? "True" : "False");
    
    if (result->error_count > 0) {
        printf("Errors: %d\n", result->error_count);
        int print_count = result->error_count < 5 ? result->error_count : 5;
        for (int i = 0; i < print_count; i++) {
            printf("  - %s\n", result->errors[i]);
        }
    }
    
    if (result->warning_count > 0) {
        printf("Warnings: %d\n", result->warning_count);
        int print_count = result->warning_count < 5 ? result->warning_count : 5;
        for (int i = 0; i < print_count; i++) {
            printf("  - %s\n", result->warnings[i]);
        }
    }
    
    if (result->doc_url) {
        printf("Docs: %s\n", result->doc_url);
    }
}

void free_result(ValidationResult* result) {
    for (int i = 0; i < result->error_count; i++) {
        free(result->errors[i]);
    }
    for (int i = 0; i < result->warning_count; i++) {
        free(result->warnings[i]);
    }
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s --lang <language> <script_file> [--no-websearch]\n", argv[0]);
        return 1;
    }
    
    char* language = NULL;
    char* script_path = NULL;
    int use_websearch = 1;
    
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--lang") == 0 && i + 1 < argc) {
            language = argv[++i];
        } else if (strcmp(argv[i], "--no-websearch") == 0) {
            use_websearch = 0;
        } else if (argv[i][0] != '-') {
            script_path = argv[i];
        }
    }
    
    if (!language || !script_path) {
        fprintf(stderr, "Both --lang and script file must be specified\n");
        return 1;
    }
    
    ValidationResult result = validate_script(language, script_path, use_websearch);
    print_result(language, &result);
    
    int exit_code = result.error_count == 0 ? 0 : 1;
    free_result(&result);
    
    return exit_code;
}
