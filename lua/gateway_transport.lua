#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "d8dfcdc262a0b7f85c0f9731c00176b6f6736665ab24a7b4ec95d316f4bc3fee", "source_sha256": "12c3ea0e67b1e873ac253df6f3f06d5ed42b603005d56186c531d8a5b0d7f377", "target_language": "lua"}
-- gateway_transport.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/gateway_transport.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[Gateway-authenticated transport with manager-owned attempt records.

An attempt is saved before submission. If its outcome is uncertain, subsequent
calls only query the same node and attempt; they do not submit it again.
--]]

local json = require("cjson")
local uuid = require("uuid")

local function gateway_token()
  --[[Use the local Gateway credential without changing its configuration.]]
  local token = os.getenv("OPENCLAW_GATEWAY_TOKEN") or ""
  if token ~= "" then
    return token
  end
  local config_path = os.getenv("OPENCLAW_CONFIG_PATH")
  if not config_path then
    config_path = (os.getenv("HOME") or "/tmp") .. "/.openclaw/openclaw.json"
  end
  local file = io.open(config_path, "r")
  if not file then
    return ""
  end
  local content = file:read("*a")
  file:close()
  local success, config = pcall(json.decode, content)
  if not success then
    return ""
  end
  token = config.gateway and config.gateway.auth and config.gateway.auth.token
  if type(token) == "string" and not string.match(token, "^%${") then
    return string.match(token, "^%s*(.-)%s*$")
  end
  return ""
end

local TransportUnresolved = {
  message = "Transport unresolved"
}
TransportUnresolved.__index = TransportUnresolved

function TransportUnresolved:new(message)
  local obj = {
    message = message or "Transport unresolved"
  }
  setmetatable(obj, self)
  return obj
end

function TransportUnresolved:__tostring()
  return "TransportUnresolved: " .. self.message
end

local function http_request(url, method, headers, data, timeout)
  local curl = require("cURL")
  local buffer = {}
  local c = curl.easy{
    url = url,
    httpheader = headers,
    postfields = data,
    customrequest = method,
    timeout = timeout,
    writefunction = function(chunk)
      table.insert(buffer, chunk)
      return #chunk
    end
  }
  local success, err = pcall(function()
    c:perform()
  end)
  if not success then
    return nil, err
  end
  return table.concat(buffer)
end

local GatewayTransport = {}
GatewayTransport.__index = GatewayTransport

function GatewayTransport:new(state, save, url, token, options)
  options = options or {}
  local parsed_url = url
  local scheme = string.match(parsed_url, "^(https?)://")
  local hostname = string.match(parsed_url, "://([^/]+)")
  
  if not scheme or not hostname then
    error("invalid Gateway URL")
  end
  if scheme == "http" and hostname ~= "127.0.0.1" and hostname ~= "localhost" and hostname ~= "::1" then
    error("unencrypted Gateway must use loopback")
  end
  if not string.match(token, "%S") or (options.timeout or 3900) <= 0 or (options.interval or 3) <= 0 then
    error("Gateway token and positive timeouts required")
  end
  
  local obj = {
    state = state,
    save = save,
    url = url,
    token = string.match(token, "^%s*(.-)%s*$"),
    timeout = options.timeout or 3900,
    interval = options.interval or 3,
    opener = options.opener or http_request,
    clock = options.clock or os.clock,
    sleep = options.sleep or function(n) 
      local start = os.clock()
      while os.clock() - start < n do end
    end
  }
  setmetatable(obj, self)
  return obj
end

function GatewayTransport:_request(node, request, device_id)
  local payload_data = {
    node = node,
    device_id = device_id,
    request = request
  }
  local payload = json.encode(payload_data)
  local headers = {
    "Authorization: Bearer " .. self.token,
    "Content-Type: application/json"
  }
  
  local timeout = 40
  if node == "node4" then
    timeout = 150
  end
  
  local response, err = self.opener(self.url, "POST", headers, payload, timeout)
  if not response then
    return nil, TransportUnresolved:new("Gateway request failed: " .. tostring(err))
  end
  
  if #response > 4000000 then
    return nil, TransportUnresolved:new("response too large")
  end
  
  local success, data = pcall(json.decode, response)
  if not success or type(data) ~= "table" or data.result == nil then
    return nil, TransportUnresolved:new("invalid gateway response")
  end
  
  if device_id ~= nil and data.device_id ~= device_id then
    return nil, TransportUnresolved:new("gateway device identity mismatch")
  end
  
  return data.result
end

function GatewayTransport:available()
  local result, err = self:_request("node1", {operation = "availability"})
  if err then
    return nil, err
  end
  if type(result) ~= "table" then
    return nil, TransportUnresolved:new("invalid node availability")
  end
  return result
end

function GatewayTransport:_release(original, entry)
  if entry.released then
    return
  end
  local success, result = pcall(function()
    return self:_request(original.selected_node, {
      operation = "release",
      job_id = original.job_id,
      attempt_id = original.attempt_id
    }, original.selected_device_id)
  end)
  
  if not success then
    return -- Retry cleanup later; the result is durable in manager state.
  end
  
  if type(result) == "table" and result.status == "released" and
     result.job_id == original.job_id and
     result.attempt_id == original.attempt_id and
     result.selected_node == original.selected_node and
     result.target_language == original.target_language then
    entry.released = true
    self.save(self.state)
  end
end

function GatewayTransport:release_pending()
  local auftraege = self.state.auftraege or {}
  for _, entry in pairs(auftraege) do
    if type(entry) == "table" and 
       (entry.status == "completed" or entry.status == "rejected" or entry.status == "failed") and
       type(entry.job) == "table" then
      self:_release(entry.job, entry)
    end
  end
end

function GatewayTransport:reject(job, reason)
  --[[Record a completed response rejected by validation, before retrying it.]]
  if not job.source_sha256 or not job.target_language then
    return
  end
  local key = job.source_sha256 .. ":" .. job.target_language
  local auftraege = self.state.auftraege or {}
  self.state.auftraege = auftraege
  local entry = auftraege[key]
  
  if type(entry) ~= "table" or entry.status ~= "completed" then
    return
  end
  if (entry.job or {}).attempt_id ~= job.attempt_id then
    return nil, TransportUnresolved:new("rejected attempt identity mismatch")
  end
  
  entry.status = "rejected"
  entry.validation_error = string.sub(tostring(reason), 1, 500)
  self.save(self.state)
end

function GatewayTransport:__call(job)
  if not job.source_sha256 or not job.target_language or not job.selected_device_id then
    error("missing source identity")
  end
  
  local key = job.source_sha256 .. ":" .. job.target_language
  local auftraege = self.state.auftraege or {}
  self.state.auftraege = auftraege
  local entry = auftraege[key]
  
  local fresh = false
  local previous = nil
  
  if type(entry) == "table" and entry.status == "rejected" then
    self:_release(entry.job, entry)
    if not entry.released then
      return nil, TransportUnresolved:new("rejected attempt release is unresolved")
    end
    previous = entry
    local original = {
      source_sha256 = job.source_sha256,
      target_language = job.target_language,
      selected_device_id = job.selected_device_id,
      job_id = job.job_id,
      selected_node = job.selected_node,
      attempt_id = uuid()
    }
    for k, v in pairs(job) do
      if original[k] == nil then
        original[k] = v
      end
    end
    
    local previous_attempts = previous.previous_attempts or {}
    table.insert(previous_attempts, {
      job_id = previous.job.job_id,
      attempt_id = previous.job.attempt_id,
      selected_node = previous.job.selected_node,
      validation_error = previous.validation_error
    })
    
    entry = {
      job = original,
      status = "submitted",
      previous_attempts = previous_attempts
    }
    auftraege[key] = entry
    self.save(self.state)
    fresh = true
  else
    fresh = entry == nil
  end
  
  if entry == nil then
    local original = {
      source_sha256 = job.source_sha256,
      target_language = job.target_language,
      selected_device_id = job.selected_device_id,
      job_id = job.job_id,
      selected_node = job.selected_node,
      attempt_id = uuid()
    }
    for k, v in pairs(job) do
      if original[k] == nil then
        original[k] = v
      end
    end
    
    entry = {
      job = original,
      status = "submitted"
    }
    auftraege[key] = entry
    -- If this write fails there must be no remote submission.
    self.save(self.state)
  end
  
  local original = entry.job
  -- The dispatcher verifies the job object after transport returns.
  for k, v in pairs(original) do
    job[k] = v
  end
  
  if entry.response ~= nil then
    self:_release(original, entry)
    return entry.response
  end
  
  if entry.status == "failed" then
    return nil, TransportUnresolved:new("attempt requires reconciliation")
  end
  
  local status = nil
  if fresh then
    local success
    success, status = pcall(function()
      return self:_request(original.selected_node, {
        operation = "execute",
        job = original
      }, original.selected_device_id)
    end)
    if not success then
      status = nil -- The request may have been accepted. Query, never resend.
    end
  end
  
  local deadline = self.clock() + self.timeout
  while true do
    if status == nil then
      local success
      success, status = pcall(function()
        return self:_request(original.selected_node, {
          operation = "status",
          job_id = original.job_id,
          attempt_id = original.attempt_id
        }, original.selected_device_id)
      end)
      if not success then
        return nil, TransportUnresolved:new("attempt is not known by the node")
      end
    end
    
    if type(status) ~= "table" then
      return nil, TransportUnresolved:new("attempt is not known by the node")
    end
    
    if status.job_id ~= original.job_id or 
       status.attempt_id ~= original.attempt_id or
       status.selected_node ~= original.selected_node or
       status.target_language ~= original.target_language then
      return nil, TransportUnresolved:new("status identity mismatch")
    end
    
    local state = status.status
    if state == "completed" then
      local response = status.response
      if type(response) ~= "table" or response.status ~= "ok" or
         response.job_id ~= original.job_id or
         response.selected_node ~= original.selected_node or
         response.target_language ~= original.target_language or
         type(response.code) ~= "string" or string.match(response.code, "^%s*$") then
        return nil, TransportUnresolved:new("invalid translation result")
      end
      
      entry.response = response
      entry.status = "completed"
      self.save(self.state)
      self:_release(original, entry)
      return response
    end
    
    if state == "failed" or state == "unknown" then
      entry.status = state
      self.save(self.state)
      if state == "failed" then
        self:_release(original, entry)
      end
      return nil, TransportUnresolved:new("attempt requires reconciliation")
    end
    
    if state ~= "running" or self.clock() >= deadline then
      return nil, TransportUnresolved:new("attempt is unresolved")
    end
    
    self.sleep(self.interval)
    status = nil
  end
end

return {
  gateway_token = gateway_token,
  TransportUnresolved = TransportUnresolved,
  GatewayTransport = GatewayTransport
}
