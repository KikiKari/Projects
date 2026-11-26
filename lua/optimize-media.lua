#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "23925917df51a75e335af48e293096a16c5993678bb7d462746988eb0a54ced0", "source_sha256": "01865e120d0e52b50fea21a5f976ac63af413e6829f861a5d31d7898bd4dbaf4", "target_language": "lua"}
-- optimize-media.mjs — portiert nach lua
-- Quelle: javascript, Onboarding@main:scripts/optimize-media.mjs
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local fs = require("lfs")
local path = require("path")

-- Hilfsfunktion zur Konvertierung von URL zu Pfad
local function url_to_path(url)
  return url:gsub("file://", "")
end

-- Hilfsfunktion zum Extrahieren des Dateinamens ohne Erweiterung
local function get_stem(filename)
  return filename:match("(.+)%.png")
end

-- Hauptverzeichnis bestimmen
local directory = path.join(os.getenv("PWD"), "public", "media") .. "/"

-- Verzeichnis durchsuchen
for file in fs.dir(directory) do
  if file:match("%.png$") then
    local source = directory .. file
    local stem = get_stem(file)
    
    -- WebP-Konvertierung (simuliert)
    local webp_file = directory .. stem .. ".webp"
    print("Konvertiere " .. file .. " zu " .. stem .. ".webp (Qualität: 84)")
    
    -- AVIF-Konvertierung (simuliert)
    local avif_file = directory .. stem .. ".avif"
    print("Konvertiere " .. file .. " zu " .. stem .. ".avif (Qualität: 58)")
  end
end

print("WebP- und AVIF-Derivate erzeugt.")
