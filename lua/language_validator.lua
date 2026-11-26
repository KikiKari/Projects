#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "87cdf1607be4015827c447829b216f259c8fe1df6c412a269da333d8be039023", "source_sha256": "eb21431dabeaafc82a1e3ccf24278616e46ed082eca1de4d328c758ee82ee2c7", "target_language": "lua"}
-- language_validator.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/language_validator.py
-- auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/language_validator.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[
Multi-language script validator supporting 8+ languages.
WebSearch integration for documentation lookup.
]]

local function split(str, sep)
    local result = {}
    local pattern = string.format("([^%s]+)", sep)
    for part in string.gmatch(str, pattern) do
        table.insert(result, part)
    end
    return result
end

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local ValidationResult = {}
ValidationResult.__index = ValidationResult

function ValidationResult:new(language, valid, errors, warnings, doc_url)
    local instance = {
        language = language,
        valid = valid,
        errors = errors or {},
        warnings = warnings or {},
        doc_url = doc_url
    }
    setmetatable(instance, ValidationResult)
    return instance
end

local LanguageValidator = {}
LanguageValidator.__index = LanguageValidator

LanguageValidator.LANGUAGES = {
    bash = { cmd = "bash", args = { "-n" }, linter = "shellcheck" },
    sh = { cmd = "sh", args = { "-n" }, linter = "shellcheck" },
    python = { cmd = "python3", args = { "-m", "py_compile" }, linter = "pylint" },
    perl = { cmd = "perl", args = { "-c" }, linter = "perlcritic" },
    raku = { cmd = "raku", args = { "-c" }, linter = nil },
    powershell = { cmd = "pwsh", args = { "-Command", "Get-Command" }, linter = nil },
    javascript = { cmd = "node", args = { "--check" }, linter = "eslint" },
    tcl = { cmd = "tclsh", args = {}, linter = nil }
}

function LanguageValidator:new(language, use_websearch)
    use_websearch = use_websearch ~= false -- default true
    local lang_lower = language:lower()
    local config = LanguageValidator.LANGUAGES[lang_lower]
    
    if not config then
        error("Unsupported language: " .. language)
    end
    
    local instance = {
        language = lang_lower,
        use_websearch = use_websearch,
        config = config
    }
    setmetatable(instance, LanguageValidator)
    return instance
end

function LanguageValidator:validate(script_path)
    local errors = {}
    local warnings = {}
    
    -- Syntax check
    local cmd_args = { self.config.cmd }
    for _, arg in ipairs(self.config.args) do
        table.insert(cmd_args, arg)
    end
    table.insert(cmd_args, script_path)
    
    local success, result = pcall(function()
        local proc = io.popen(table.concat(cmd_args, " ") .. " 2>&1", "r")
        if not proc then
            return { returncode = 1, stderr = "Failed to execute command" }
        end
        local output = proc:read("*a")
        local exit_code = proc:close()
        return { 
            returncode = exit_code and 0 or 1,
            stderr = output
        }
    end)
    
    if success then
        if result.returncode ~= 0 then
            table.insert(errors, result.stderr)
        end
    else
        table.insert(errors, "Validation failed: " .. tostring(result))
    end
    
    -- Linter check if available
    if self.config.linter then
        local linter_warnings = self:_run_linter(script_path)
        for _, warning in ipairs(linter_warnings) do
            table.insert(warnings, warning)
        end
    end
    
    local doc_url = nil
    if #errors > 0 and self.use_websearch then
        doc_url = self:_fetch_docs()
    end
    
    return ValidationResult:new(
        self.language,
        #errors == 0,
        errors,
        warnings,
        doc_url
    )
end

function LanguageValidator:_run_linter(script_path)
    local linter = self.config.linter
    local warnings = {}
    
    local success, result = pcall(function()
        local cmd
        if linter == "shellcheck" then
            cmd = "shellcheck -f gcc " .. script_path
        elseif linter == "pylint" then
            cmd = "pylint --output-format=parseable " .. script_path
        else
            return {}
        end
        
        local proc = io.popen(cmd .. " 2>&1", "r")
        if not proc then
            return {}
        end
        local output = proc:read("*a")
        proc:close()
        return output
    end)
    
    if success and result then
        local lines = split(trim(result), "\n")
        for _, line in ipairs(lines) do
            if line ~= "" then
                table.insert(warnings, line)
            end
        end
    elseif not success then
        table.insert(warnings, "Linter execution failed: " .. tostring(result))
    end
    
    return warnings
end

function LanguageValidator:_fetch_docs()
    if not self.use_websearch then
        return nil
    end
    
    local docs = {
        powershell = "https://docs.microsoft.com/powershell/",
        raku = "https://docs.raku.org/",
        tcl = "https://www.tcl.tk/"
    }
    return docs[self.language]
end

local function main()
    local script_path = arg[1]
    local language = nil
    local no_websearch = false
    
    -- Simple argument parsing
    for i = 1, #arg do
        if arg[i] == "--lang" and arg[i+1] then
            language = arg[i+1]
            i = i + 1
        elseif arg[i] == "--no-websearch" then
            no_websearch = true
        elseif not script_path and arg[i]:sub(1,1) ~= "-" then
            script_path = arg[i]
        end
    end
    
    if not script_path or not language then
        print("Usage: " .. arg[0] .. " <script> --lang <language> [--no-websearch]")
        os.exit(1)
    end
    
    local validator
    local success, err = pcall(function()
        validator = LanguageValidator:new(language, not no_websearch)
    end)
    
    if not success then
        print("Error: " .. tostring(err))
        os.exit(1)
    end
    
    local result = validator:validate(script_path)
    
    print("Language: " .. result.language)
    print("Valid: " .. tostring(result.valid))
    
    if #result.errors > 0 then
        print("Errors: " .. #result.errors)
        for i = 1, math.min(5, #result.errors) do
            print("  - " .. result.errors[i])
        end
    end
    
    if #result.warnings > 0 then
        print("Warnings: " .. #result.warnings)
        for i = 1, math.min(5, #result.warnings) do
            print("  - " .. result.warnings[i])
        end
    end
    
    if result.doc_url then
        print("Docs: " .. result.doc_url)
    end
    
    os.exit(result.valid and 0 or 1)
end

main()
