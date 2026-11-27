#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "b979e31128cb60c03dcb38cd3ccf3f240a69586156f34be5a3280502a18b592d", "source_sha256": "2cfa301efe20d60c29e0e9f0746e5a99d405ea44a5d03839c72e6b525451fe07", "target_language": "ruby"}
# index.html — portiert nach ruby
# Quelle: html, Projects@TikTok-Live-Companion-Android:site/index.html
# auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

require 'optparse'

# Erzeugt die index.html basierend auf dem Template
def generate_html
  <<~HTML
    <!doctype html>
    <html lang="de">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <meta name="description" content="Dokumentation für TikTok LIVE Companion 0.8.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />
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
end

# Optionen parsen
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"
  
  opts.on("-o", "--output FILE", "Ausgabedatei") do |file|
    options[:output] = file
  end
  
  opts.on("-h", "--help", "Hilfe anzeigen") do
    puts opts
    exit
  end
end.parse!

# In Datei schreiben oder auf stdout ausgeben
if options[:output]
  File.write(options[:output], generate_html)
else
  puts generate_html
end
