#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "89a4f2752cc847e34117f707f1dada86b4bcba7e7e5c5d22bd3518ac8b5b7f2e", "source_sha256": "502dcda47466a4ab74da59badbe4b12c4782ed031c43d5038f8bd8534373cd35", "target_language": "lua"}
-- model_usage.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:skills/model-usage/scripts/model_usage.py
-- auch in: OpenClaw@gateway2:skills/model-usage/scripts/model_usage.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[
Summarize CodexBar local cost usage by model.

Defaults to current model (most recent daily entry), or list all models.
]]

local argparse = require "argparse"
local json = require "cjson"

local function eprint(msg)
    io.stderr:write(msg .. "\n")
end

local function run_codexbar_cost(provider)
    local cmd = {"codexbar", "cost", "--format", "json", "--provider", provider}
    local success, result = pcall(function()
        local handle = io.popen(table.concat(cmd, " "))
        local output = handle:read("*a")
        handle:close()
        return output
    end)
    
    if not success then
        error("codexbar not found on PATH. Install CodexBar CLI first.")
    end
    
    if result == nil then
        error("codexbar cost failed.")
    end
    
    local success, payload = pcall(function()
        return json.decode(result)
    end)
    
    if not success then
        error("Failed to parse codexbar JSON output.")
    end
    
    if type(payload) ~= "table" then
        error("Expected codexbar cost JSON array.")
    end
    
    return payload
end

local function load_payload(input_path, provider)
    local data
    if input_path then
        local raw
        if input_path == "-" then
            raw = io.stdin:read("*a")
        else
            local handle = io.open(input_path, "r")
            if not handle then
                error("Could not open file: " .. input_path)
            end
            raw = handle:read("*a")
            handle:close()
        end
        data = json.decode(raw)
    else
        data = run_codexbar_cost(provider)
    end

    if type(data) == "table" and data.provider then
        return data
    end

    if type(data) == "table" then
        for _, entry in ipairs(data) do
            if type(entry) == "table" and entry.provider == provider then
                return entry
            end
        end
        error("Provider '" .. provider .. "' not found in codexbar payload.")
    end

    error("Unsupported JSON input format.")
end

local function parse_daily_entries(payload)
    local daily = payload.daily
    if not daily then
        return {}
    end
    if type(daily) ~= "table" then
        return {}
    end
    local result = {}
    for _, entry in ipairs(daily) do
        if type(entry) == "table" then
            table.insert(result, entry)
        end
    end
    return result
end

local function parse_date(value)
    local year, month, day = string.match(value, "(%d+)-(%d+)-(%d+)")
    if year and month and day then
        return {year = tonumber(year), month = tonumber(month), day = tonumber(day)}
    end
    return nil
end

local function date_to_days(date_obj)
    -- Simple conversion to days since epoch for comparison
    local days_in_month = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
    local days = 0
    for y = 1970, date_obj.year - 1 do
        days = days + 365
        if y % 4 == 0 and (y % 100 ~= 0 or y % 400 == 0) then
            days = days + 1
        end
    end
    for m = 1, date_obj.month - 1 do
        days = days + days_in_month[m]
        if m == 2 and date_obj.year % 4 == 0 and (date_obj.year % 100 ~= 0 or date_obj.year % 400 == 0) then
            days = days + 1
        end
    end
    return days + date_obj.day
end

local function filter_by_days(entries, days)
    if not days then
        return entries
    end
    local today = os.date("*t")
    local cutoff_days = date_to_days({year = today.year, month = today.month, day = today.day}) - (days - 1)
    local filtered = {}
    for _, entry in ipairs(entries) do
        local day = entry.date
        if type(day) == "string" then
            local parsed = parse_date(day)
            if parsed then
                local entry_days = date_to_days(parsed)
                if entry_days >= cutoff_days then
                    table.insert(filtered, entry)
                end
            end
        end
    end
    return filtered
end

local function aggregate_costs(entries)
    local totals = {}
    for _, entry in ipairs(entries) do
        local breakdowns = entry.modelBreakdowns
        if breakdowns then
            if type(breakdowns) == "table" then
                for _, item in ipairs(breakdowns) do
                    if type(item) == "table" then
                        local model = item.modelName
                        local cost = item.cost
                        if type(model) == "string" and (type(cost) == "number" or type(cost) == "integer") then
                            if not totals[model] then
                                totals[model] = 0.0
                            end
                            totals[model] = totals[model] + cost
                        end
                    end
                end
            end
        end
    end
    return totals
end

local function pick_current_model(entries)
    if #entries == 0 then
        return nil, nil
    end
    local sorted_entries = {}
    for i, entry in ipairs(entries) do
        sorted_entries[i] = entry
    end
    table.sort(sorted_entries, function(a, b)
        local date_a = a.date or ""
        local date_b = b.date or ""
        return date_a < date_b
    end)
    
    for i = #sorted_entries, 1, -1 do
        local entry = sorted_entries[i]
        local breakdowns = entry.modelBreakdowns
        if type(breakdowns) == "table" and #breakdowns > 0 then
            local scored = {}
            for _, item in ipairs(breakdowns) do
                if type(item) == "table" then
                    local model = item.modelName
                    local cost = item.cost
                    if type(model) == "string" and (type(cost) == "number" or type(cost) == "integer") then
                        table.insert(scored, {model = model, cost = cost})
                    end
                end
            end
            if #scored > 0 then
                table.sort(scored, function(a, b) return a.cost > b.cost end)
                return scored[1].model, entry.date
            end
        end
        local models_used = entry.modelsUsed
        if type(models_used) == "table" and #models_used > 0 then
            local last = models_used[#models_used]
            if type(last) == "string" then
                return last, entry.date
            end
        end
    end
    return nil, nil
end

local function usd(value)
    if value == nil then
        return "—"
    end
    return string.format("$%,.2f", value)
end

local function latest_day_cost(entries, model)
    if #entries == 0 then
        return nil, nil
    end
    local sorted_entries = {}
    for i, entry in ipairs(entries) do
        sorted_entries[i] = entry
    end
    table.sort(sorted_entries, function(a, b)
        local date_a = a.date or ""
        local date_b = b.date or ""
        return date_a < date_b
    end)
    
    for i = #sorted_entries, 1, -1 do
        local entry = sorted_entries[i]
        local breakdowns = entry.modelBreakdowns
        if type(breakdowns) == "table" then
            for _, item in ipairs(breakdowns) do
                if type(item) == "table" and item.modelName == model then
                    local cost = item.cost
                    local day = entry.date
                    if type(cost) == "number" or type(cost) == "integer" then
                        return day, cost
                    else
                        return day, nil
                    end
                end
            end
        end
    end
    return nil, nil
end

local function render_text_current(provider, model, latest_date, total_cost, latest_cost, latest_cost_date, entry_count)
    local lines = {
        "Provider: " .. provider,
        "Current model: " .. model
    }
    if latest_date then
        table.insert(lines, "Latest model date: " .. latest_date)
    end
    table.insert(lines, "Total cost (rows): " .. usd(total_cost))
    if latest_cost_date then
        table.insert(lines, "Latest day cost: " .. usd(latest_cost) .. " (" .. latest_cost_date .. ")")
    end
    table.insert(lines, "Daily rows: " .. entry_count)
    return table.concat(lines, "\n")
end

local function render_text_all(provider, totals)
    local lines = {
        "Provider: " .. provider,
        "Models:"
    }
    local sorted_totals = {}
    for model, cost in pairs(totals) do
        table.insert(sorted_totals, {model = model, cost = cost})
    end
    table.sort(sorted_totals, function(a, b) return a.cost > b.cost end)
    
    for _, item in ipairs(sorted_totals) do
        table.insert(lines, "- " .. item.model .. ": " .. usd(item.cost))
    end
    return table.concat(lines, "\n")
end

local function build_json_current(provider, model, latest_date, total_cost, latest_cost, latest_cost_date, entry_count)
    return {
        provider = provider,
        mode = "current",
        model = model,
        latestModelDate = latest_date,
        totalCostUSD = total_cost,
        latestDayCostUSD = latest_cost,
        latestDayCostDate = latest_cost_date,
        dailyRowCount = entry_count
    }
end

local function build_json_all(provider, totals)
    local models = {}
    local sorted_totals = {}
    for model, cost in pairs(totals) do
        table.insert(sorted_totals, {model = model, cost = cost})
    end
    table.sort(sorted_totals, function(a, b) return a.cost > b.cost end)
    
    for _, item in ipairs(sorted_totals) do
        table.insert(models, {model = item.model, totalCostUSD = item.cost})
    end
    return {
        provider = provider,
        mode = "all",
        models = models
    }
end

local function main()
    local parser = argparse.ArgumentParser("Summarize CodexBar model usage from local cost logs.")
    parser:add_argument("--provider"):choices({"codex", "claude"}):default("codex")
    parser:add_argument("--mode"):choices({"current", "all"}):default("current")
    parser:add_argument("--model"):help("Explicit model name to report instead of auto-current.")
    parser:add_argument("--input"):help("Path to codexbar cost JSON (or '-' for stdin).")
    parser:add_argument("--days"):type("integer"):help("Limit to last N days (based on daily rows).")
    parser:add_argument("--format"):choices({"text", "json"}):default("text")
    parser:add_argument("--pretty"):action("store_true"):help("Pretty-print JSON output.")
    
    local args = parser:parse()
    
    local success, payload = pcall(function()
        return load_payload(args.input, args.provider)
    end)
    
    if not success then
        eprint(payload)
        return 1
    end
    
    local entries = parse_daily_entries(payload)
    entries = filter_by_days(entries, args.days)
    
    if args.mode == "current" then
        local model = args.model
        local latest_date = nil
        if not model then
            model, latest_date = pick_current_model(entries)
        end
        if not model then
            eprint("No model data found in codexbar cost payload.")
            return 2
        end
        local totals = aggregate_costs(entries)
        local total_cost = totals[model]
        local latest_cost_date, latest_cost = latest_day_cost(entries, model)
        
        if args.format == "json" then
            local payload_out = build_json_current(
                args.provider,
                model,
                latest_date,
                total_cost,
                latest_cost,
                latest_cost_date,
                #entries
            )
            if args.pretty then
                print(json.encode(payload_out))
            else
                print(json.encode(payload_out))
            end
        else
            print(render_text_current(
                args.provider,
                model,
                latest_date,
                total_cost,
                latest_cost,
                latest_cost_date,
                #entries
            ))
        end
        return 0
    end
    
    local totals = aggregate_costs(entries)
    if not next(totals) then
        eprint("No model breakdowns found in codexbar cost payload.")
        return 2
    end
    
    if args.format == "json" then
        local payload_out = build_json_all(args.provider, totals)
        if args.pretty then
            print(json.encode(payload_out))
        else
            print(json.encode(payload_out))
        end
    else
        print(render_text_all(args.provider, totals))
    end
    return 0
end

os.exit(main())
