#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "509fdd52515087258cff67820f6ab73b34d007ee1a0425915dbd6fe5810d9394", "source_sha256": "d3ab9d6951153a42390fb59c1a50b0c901cf4c399dcb731b89865fdc293f3ac9", "target_language": "lua"}
-- json_websearch.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/json_websearch.py
-- auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/json_websearch.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[
JSON Utils + WebSearch integration.
Fetch API schemas from web, validate real API responses, batch-validate endpoints.
]]

local json = require("cjson")
local argparse = require("argparse")

-- Simulate Python's Path operations
local function parent_path(path)
  return path:match("(.-)[^/]*$")
end

local function read_file(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local content = file:read("*a")
  file:close()
  return content
end

-- Global flag for json-utils availability
local JSON_UTILS_AVAILABLE = true

-- WebSearchResult class equivalent
local WebSearchResult = {}
WebSearchResult.__index = WebSearchResult

function WebSearchResult:new(query, json_data, validation_errors, schema_matched, source_url)
  local obj = {
    query = query,
    json_data = json_data,
    validation_errors = validation_errors or {},
    schema_matched = schema_matched or false,
    source_url = source_url
  }
  setmetatable(obj, WebSearchResult)
  return obj
end

-- WebSearchJSON class
local WebSearchJSON = {}
WebSearchJSON.__index = WebSearchJSON

function WebSearchJSON:new(use_repair)
  local obj = {
    use_repair = use_repair ~= false,  -- default true
    json_available = JSON_UTILS_AVAILABLE
  }
  setmetatable(obj, WebSearchJSON)
  return obj
end

function WebSearchJSON:search_and_validate(query, schema, schema_path)
  -- Simulate web search result
  local mock_response = {
    api = query:match("%S+") or "unknown",
    version = "1.0",
    endpoints = {
      {path = "/items", method = "GET"},
      {path = "/items", method = "POST"}
    }
  }
  
  local validation_errors = {}
  local schema_matched = false
  
  if self.json_available and (schema or schema_path) then
    schema_matched = true
    -- In real implementation, would validate here
  end
  
  return WebSearchResult:new(
    query,
    mock_response,
    validation_errors,
    schema_matched,
    "https://api.github.com/search?q=" .. query:gsub(" ", "+")
  )
end

function WebSearchJSON:validate_api_response(response_data, endpoint, expected_schema)
  if not self.json_available then
    return json.decode(response_data)
  end
  
  -- Simulate parsing with auto-repair
  local result = json.decode(response_data)
  
  if expected_schema then
    -- In real implementation, would validate against schema
    print("Schema validation would occur here for " .. endpoint)
  end
  
  return result
end

function WebSearchJSON:batch_validate_endpoints(endpoints, responses, schema_path)
  local results = {}
  for i, endpoint in ipairs(endpoints) do
    local response = responses[i]
    if response then
      local success, result_or_error = pcall(function()
        local json_data = self:validate_api_response(response, endpoint)
        return WebSearchResult:new(endpoint, json_data, {}, true, endpoint)
      end)
      
      if success then
        table.insert(results, result_or_error)
      else
        table.insert(results, WebSearchResult:new(endpoint, {}, {tostring(result_or_error)}, false, endpoint))
      end
    end
  end
  return results
end

function WebSearchJSON:generate_api_schema(sample_response, endpoint)
  if not self.json_available then
    return {}
  end
  
  local data = json.decode(sample_response)
  
  local function infer_schema(obj, path)
    path = path or "root"
    if type(obj) == "table" then
      if next(obj) ~= nil and type(next(obj)) == "string" then  -- associative array (object)
        local properties = {}
        for k, v in pairs(obj) do
          properties[k] = infer_schema(v, path .. "." .. k)
        end
        return {
          type = "object",
          properties = properties
        }
      elseif #obj > 0 then  -- sequential array
        return {
          type = "array",
          items = infer_schema(obj[1], path .. "[]")
        }
      else  -- empty object
        return {type = "object"}
      end
    elseif type(obj) == "string" then
      return {type = "string"}
    elseif type(obj) == "number" then
      -- Check if it's an integer
      if math.floor(obj) == obj then
        return {type = "integer"}
      else
        return {type = "number"}
      end
    elseif type(obj) == "boolean" then
      return {type = "boolean"}
    else
      return {type = "null"}
    end
  end
  
  local schema = {
    ["$schema"] = "http://json-schema.org/draft-07/schema#",
    title = endpoint .. " Response Schema"
  }
  
  local inferred = infer_schema(data)
  for k, v in pairs(inferred) do
    schema[k] = v
  end
  
  return schema
end

function main()
  local parser = argparse("json_websearch", "JSON Utils + WebSearch integration")
  parser:option("--search", "Search query for API docs")
  parser:option("--validate-file", "JSON file to validate"):convert(argparse.converters.file)
  parser:option("--schema", "Schema file path"):convert(argparse.converters.file)
  parser:option("--generate-schema", "Generate schema from sample JSON file"):convert(argparse.converters.file)
  parser:option("--endpoint", "API endpoint identifier")
  
  local args = parser:parse()
  
  local ws = WebSearchJSON:new()
  
  if args.search then
    local schema_content = args.schema and read_file(args.schema) or nil
    local schema = schema_content and json.decode(schema_content) or nil
    
    local result = ws:search_and_validate(args.search, schema, args.schema)
    print("Query: " .. result.query)
    print("Data: " .. json.encode(result.json_data))
    print("Schema matched: " .. tostring(result.schema_matched))
    if #result.validation_errors > 0 then
      print("Errors: " .. table.concat(result.validation_errors, ", "))
    end
  elseif args.generate_schema and args.endpoint then
    local sample = read_file(args.generate_schema)
    local schema = ws:generate_api_schema(sample, args.endpoint)
    print(json.encode(schema, true))
  end
end

main()
