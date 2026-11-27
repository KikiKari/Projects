#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "5e3591294b78a393635111f75c9f95eaf3123dee135ea413eac4dbcabe1c2cce", "source_sha256": "a5de51b02b40bbdeafb7fb0f4da19091ec351b10a9160307085ebcef403cdd67", "target_language": "ruby"}
# offscreen.html — portiert nach ruby
# Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/offscreen.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# Script to generate offscreen.html file
# Usage: ruby offscreen_generator.rb [output_file]
# If no output file is specified, writes to 'offscreen.html'

require 'fileutils'

def generate_offscreen_html
  <<~HTML
  <!doctype html>
  <html lang="de">
  <head>
    <meta charset="utf-8">
    <title>TikTok LIVE Companion Sprachausgabe</title>
  </head>
  <body>
    <script src="offscreen.js"></script>
  </body>
  </html>
  HTML
end

# Get output filename from command line argument or use default
output_file = ARGV[0] || 'offscreen.html'

# Write the generated HTML to file
File.open(output_file, 'w') do |file|
  file.write(generate_offscreen_html)
end

puts "Generated #{output_file}"
