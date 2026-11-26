#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "35dcb8bf5ca2b2d1e28c07ae666809473a1f94808d49cb032d79b71561e2a636", "source_sha256": "f68a161573356fe83ce98ebe454cffaef6896f81d310cd932a9847500e671f9b", "target_language": "lua"}
-- json_processor.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_processor.py
-- auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_processor.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[
JSON Processor mit Validierung und Reparatur.
Für robuste Verarbeitung von LLM-Outputs.
]]

local json = require("cjson")
local inspect = require("inspect")

-- Hilfsfunktionen für Fehlerbehandlung
local function error_handler(err)
    return tostring(err)
end

local function pcall_or_error(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        error(result, 2)
    end
    return result
end

-- Globale Konfiguration
local HAS_JSON_REPAIR = false -- In Lua nicht direkt verfügbar, muss manuell implementiert werden

-- Exception-Klassen (simuliert durch Tabellen)
local JSONProcessingError = {}
JSONProcessingError.__index = JSONProcessingError

function JSONProcessingError:new(message)
    local obj = {
        message = message or "JSON processing error"
    }
    setmetatable(obj, JSONProcessingError)
    return obj
end

function JSONProcessingError:__tostring()
    return self.message
end

local JSONValidationError = {}
JSONValidationError.__index = JSONValidationError
setmetatable(JSONValidationError, JSONProcessingError)

function JSONValidationError:new(message)
    local obj = JSONProcessingError:new(message or "JSON validation error")
    setmetatable(obj, JSONValidationError)
    return obj
end

local JSONRepairError = {}
JSONRepairError.__index = JSONRepairError
setmetatable(JSONRepairError, JSONProcessingError)

function JSONRepairError:new(message)
    local obj = JSONProcessingError:new(message or "JSON repair error")
    setmetatable(obj, JSONRepairError)
    return obj
end

-- Hauptfunktionen

function repair_json_string(raw_json)
    --[[
    Repariert häufige JSON-Fehler aus LLM-Outputs.
    
    Behebt:
    - Trailing commas
    - Einzelne statt doppelte Quotes
    - JavaScript-Style Kommentare
    - Unescaped Zeilenumbrüche in Strings
    ]]
    if HAS_JSON_REPAIR then
        -- Placeholder für tatsächliche Reparaturlogik
        -- Da json_repair in Lua nicht verfügbar ist, wird dies simuliert
        print("Warning: json_repair not available in Lua")
    end

    -- Fallback: Manuelle Reparaturen
    local cleaned = raw_json:gsub("^%s+", ""):gsub("%s+$", "")
    
    -- Entferne JavaScript-Kommentare
    cleaned = cleaned:gsub("//.-\n", "\n")
    cleaned = cleaned:gsub("/%*.-%*/", "", 1)
    
    -- Entferne trailing commas vor ] oder }
    cleaned = cleaned:gsub(",(%s*[}%]])", "%1")
    
    return cleaned
end

function parse_json(raw_input, repair)
    repair = repair ~= false -- Standardmäßig true
    
    --[[
    Parst JSON-String mit optionaler automatischer Reparatur.
    
    Args:
        raw_input: Der zu parsende JSON-String
        repair: Ob JSON-Reparatur versucht werden soll (default: True)
    
    Returns:
        Geparstes Lua-Objekt
    
    Throws:
        JSONProcessingError: Wenn Parsing fehlschlägt
    ]]
    raw_input = raw_input:gsub("^%s+", ""):gsub("%s+$", "")
    
    -- Versuche zuerst direktes Parsing
    local success, result = pcall(json.decode, raw_input)
    if success then
        return result
    end
    
    -- Extrahiere JSON aus Markdown-Code-Blöcken
    if raw_input:find("```") then
        -- Suche nach JSON in ```json ... ``` oder ``` ... ```
        local patterns = {
            "```json%s*(.-)%s*```",
            "````%s*({.-})%s*```",
            "````%s*(%[.-%])%s*```"
        }
        
        for _, pattern in ipairs(patterns) do
            local matches = {raw_input:match(pattern)}
            for _, match in ipairs(matches) do
                local success_inner, result_inner = pcall(json.decode, match)
                if success_inner then
                    return result_inner
                end
            end
        end
    end
    
    -- Versuche Reparatur
    if repair then
        local success_repair, repaired = pcall(repair_json_string, raw_input)
        if success_repair then
            local success_parse, result_parse = pcall(json.decode, repaired)
            if success_parse then
                return result_parse
            else
                error(JSONProcessingError:new("Could not parse JSON even after repair: " .. result_parse))
            end
        else
            error(JSONRepairError:new("JSON repair failed: " .. repaired))
        end
    end
    
    error(JSONProcessingError:new("Could not parse JSON"))
end

function safe_json_loads(raw_input, default, repair)
    --[[
    Sicheres JSON-Parsing mit Fallback auf Default-Wert.
    
    Args:
        raw_input: Der zu parsende JSON-String
        default: Rückgabewert bei Fehlschlag (default: nil)
        repair: Ob Reparatur versucht werden soll
    
    Returns:
        Geparstes Objekt oder Default-Wert
    ]]
    repair = repair ~= false
    
    local success, result = pcall(parse_json, raw_input, repair)
    if success then
        return result
    else
        return default
    end
end

function extract_json_from_text(text)
    --[[
    Extrahiert alle JSON-Objekte aus einem Text.
    
    Args:
        text: Text, der JSON-Objekte enthalten könnte
    
    Returns:
        Liste aller gefundenen und geparsten JSON-Objekte
    ]]
    local results = {}
    
    -- Einfache Muster für JSON-Objekte und Arrays
    local object_pattern = "{[^{}]*(?:{[^{}]*}[^{}]*)*}"
    local array_pattern = "%[[^%[%]]*(?:%[[^%[%]]*%][^%[%]]*)*%]"
    
    -- Suche nach Objekten
    for match in text:gmatch(object_pattern) do
        local success, parsed = pcall(parse_json, match, true)
        if success then
            table.insert(results, parsed)
        end
    end
    
    -- Suche nach Arrays
    for match in text:gmatch(array_pattern) do
        local success, parsed = pcall(parse_json, match, true)
        if success then
            table.insert(results, parsed)
        end
    end
    
    return results
end

-- CLI Interface
if arg and #arg > 0 then
    local input_file = arg[1]
    local options = {}
    
    -- Parse Kommandozeilenargumente
    for i = 2, #arg do
        if arg[i] == "--file" or arg[i] == "-f" then
            options.file = true
        elseif arg[i] == "--no-repair" then
            options.repair = false
        elseif arg[i] == "--pretty" or arg[i] == "-p" then
            options.pretty = true
        end
    end
    
    local content
    
    if options.file then
        local file = io.open(input_file, "r")
        if not file then
            io.stderr:write("Error: Could not open file " .. input_file .. "\n")
            os.exit(1)
        end
        content = file:read("*all")
        file:close()
    else
        content = input_file
    end
    
    local success, result = pcall(parse_json, content, options.repair ~= false)
    if success then
        local output
        if options.pretty then
            output = inspect(result)
        else
            output = json.encode(result)
        end
        print(output)
    else
        io.stderr:write("Error: " .. tostring(result) .. "\n")
        os.exit(1)
    end
end

return {
    JSONProcessingError = JSONProcessingError,
    JSONValidationError = JSONValidationError,
    JSONRepairError = JSONRepairError,
    repair_json_string = repair_json_string,
    parse_json = parse_json,
    safe_json_loads = safe_json_loads,
    extract_json_from_text = extract_json_from_text
}
