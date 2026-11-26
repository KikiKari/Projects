#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "56fe73ad1246c1bcb4d0b74fdaa95c66d07366e4d39bbfd44fca3e9b5e58e81f", "source_sha256": "c10479f79ca5554fe399cf2f5d70fb5b32e837c1c7a846eb7dd7c9e9e5319c66", "target_language": "ruby"}
# index.html — portiert nach ruby
# Quelle: html, Projects@TikTok-Live-Companion:site/index.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/index.html
# auch in: Projects@vercel/install-and-configure-vercel-w-98sxlo:site/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

require 'optparse'

# Parse command line options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"
  opts.on("-o", "--output FILE", "Output file") do |file|
    options[:output] = file
  end
end.parse!

# Generate HTML document
html_content = <<~HTML
  <!doctype html>
  <html lang="de">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <meta name="description" content="Dokumentation für TikTok LIVE Companion 0.8.2 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />
      <meta name="theme-color" content="#ffffff" />
      <link rel="icon" type="image/png" href="/branding/staenderglobus-ios.png" />
      <link rel="apple-touch-icon" href="/branding/staenderglobus-ios.png" />
      <title>TikTok LIVE Companion – Dokumentation</title>
    </head>
    <body>
      <div id="root"></div>
      <script type="module" src="/src/main.tsx"></script>
    </body>
  </html>
HTML

# Write to file or stdout
if options[:output]
  File.write(options[:output], html_content)
  puts "HTML document written to #{options[:output]}"
else
  puts html_content
end
