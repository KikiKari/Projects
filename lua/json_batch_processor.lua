#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "a485d37dab7e8f2d3b623682cfc7e174536321ce009b3f4f0b0f43ba34e099e8", "source_sha256": "40b902ee3739509c4b2ef72ed57b4d983e5b509f6e446d20ab14d630d9773322", "target_language": "lua"}
-- json_batch_processor.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_batch_processor.py
-- auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_batch_processor.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[
Batch JSON Processor - Verarbeitet mehrere JSON-Dateien oder JSON-Lines (NDJSON).
]]

local json = require("cjson")
local argparse = require("argparse")

-- Hilfsfunktionen für Dateioperationen
local function read_file(path)
    local file = io.open(path, "r")
    if not file then
        error("Could not open file: " .. path)
    end
    local content = file:read("*a")
    file:close()
    return content
end

local function write_file(path, content)
    local file = io.open(path, "w")
    if not file then
        error("Could not write to file: " .. path)
    end
    file:write(content)
    file:close()
end

-- BatchResult Klasse
local BatchResult = {}
BatchResult.__index = BatchResult

function BatchResult:new(index, source, success, data, error_msg)
    local obj = {
        index = index,
        source = source,
        success = success,
        data = data,
        error = error_msg
    }
    setmetatable(obj, BatchResult)
    return obj
end

function BatchResult:to_table()
    return {
        index = self.index,
        source = self.source,
        success = self.success,
        data = self.data,
        error = self.error
    }
end

-- JSON Processing Funktionen (vereinfacht)
local function parse_json(content, repair)
    -- In echter Implementierung würde hier die Reparatur stattfinden
    local status, result = pcall(json.decode, content)
    if not status then
        if repair then
            -- Versuche einfache Reparaturen
            local repaired = content:gsub(':([%s\n\r]*)([^%s{[]+)', ': "%2"')
            status, result = pcall(json.decode, repaired)
        end
        
        if not status then
            error("JSON parsing failed: " .. result)
        end
    end
    return result
end

-- Liest JSON-Lines Datei
local function read_jsonl(file_path)
    local results = {}
    local file = io.open(file_path, "r")
    if not file then
        table.insert(results, BatchResult:new(0, file_path, false, nil, "Could not open file"))
        return results
    end
    
    local line_num = 0
    for line in file:lines() do
        line_num = line_num + 1
        line = line:match("^%s*(.-)%s*$")  -- trim
        if line ~= "" then
            local status, result = pcall(json.decode, line)
            if status then
                table.insert(results, result)
            else
                table.insert(results, BatchResult:new(
                    line_num,
                    file_path .. ":" .. line_num,
                    false,
                    nil,
                    "JSON decode error: " .. result
                ))
            end
        end
    end
    file:close()
    return results
end

-- Verarbeitet eine Liste von Inputs sequentiell (Lua hat keinen eingebauten Threadpool)
local function process_batch(inputs, processor)
    local results = {}
    for idx, inp in ipairs(inputs) do
        local status, result = pcall(processor, inp, idx)
        if status then
            table.insert(results, result)
        else
            table.insert(results, BatchResult:new(
                idx,
                tostring(inp),
                false,
                nil,
                "Unexpected error: " .. result
            ))
        end
    end
    return results
end

-- Verarbeitet mehrere JSON-Dateien
local function process_file_batch(file_paths, repair)
    local function processor(path, idx)
        local content = read_file(path)
        local status, data = pcall(parse_json, content, repair)
        if status then
            return BatchResult:new(idx, path, true, data, nil)
        else
            return BatchResult:new(idx, path, false, nil, data)
        end
    end
    
    return process_batch(file_paths, processor)
end

-- Verarbeitet eine JSON-Lines Datei
local function process_jsonl_file(file_path, repair)
    local results = {}
    local file = io.open(file_path, "r")
    if not file then
        table.insert(results, BatchResult:new(0, file_path, false, nil, "Could not open file"))
        return results
    end
    
    local line_num = 0
    for line in file:lines() do
        line_num = line_num + 1
        line = line:match("^%s*(.-)%s*$")  -- trim
        if line ~= "" then
            local status, data = pcall(parse_json, line, repair)
            if status then
                table.insert(results, BatchResult:new(
                    line_num,
                    file_path .. ":" .. line_num,
                    true,
                    data,
                    nil
                ))
            else
                table.insert(results, BatchResult:new(
                    line_num,
                    file_path .. ":" .. line_num,
                    false,
                    nil,
                    data
                ))
            end
        end
    end
    file:close()
    return results
end

-- Schreibt Ergebnisse als JSON-Lines
local function write_jsonl(results, output_path, only_successful)
    local file = io.open(output_path, "w")
    if not file then
        error("Could not write to file: " .. output_path)
    end
    
    for _, result in ipairs(results) do
        if not only_successful or result.success then
            file:write(json.encode(result:to_table()) .. "\n")
        end
    end
    file:close()
end

-- Hauptfunktion
local function main()
    local parser = argparse.ArgumentParser()
    parser:option("-i --inputs"):args("+"):help("JSON files to process")
    parser:flag("-l --jsonl"):help("Treat inputs as JSON-Lines files")
    parser:flag("-r --repair"):help("Enable JSON repair"):default(true)
    parser:option("-w --workers"):convert(tonumber):default(4):help("Parallel workers")
    parser:option("-o --output"):help("Output JSON-Lines file")
    parser:flag("-s --summary"):help("Show summary only")
    
    local args = parser:parse()
    
    local all_results = {}
    
    if args.jsonl then
        -- JSON-Lines Modus
        for _, input_path in ipairs(args.inputs) do
            local results = process_jsonl_file(input_path, args.repair)
            for _, result in ipairs(results) do
                table.insert(all_results, result)
            end
        end
    else
        -- Standard JSON Batch
        all_results = process_file_batch(args.inputs, args.repair)
    end
    
    -- Statistiken sammeln
    local successful = 0
    local failed = 0
    for _, result in ipairs(all_results) do
        if result.success then
            successful = successful + 1
        else
            failed = failed + 1
        end
    end
    
    -- Ausgabe
    if args.summary then
        print("Processed: " .. #all_results)
        print("Successful: " .. successful)
        print("Failed: " .. failed)
    else
        for _, result in ipairs(all_results) do
            if result.success then
                print(json.encode(result.data))
            else
                io.stderr:write("ERROR [" .. result.source .. "]: " .. result.error .. "\n")
            end
        end
    end
    
    -- Optional: JSONL Output
    if args.output then
        write_jsonl(all_results, args.output, false)
        io.stderr:write("\nResults written to: " .. args.output .. "\n")
    end
    
    -- Exit code Simulation
    if failed > 0 then
        os.exit(1)
    else
        os.exit(0)
    end
end

main()
