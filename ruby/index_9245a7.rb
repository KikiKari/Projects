#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "a243184f703a50475b4e7766629e573744d5c03d8a457d1bf371381b8b062c2b", "source_sha256": "9245a78489adb3949ae2a56f5e0987a465142b9a8ee97bddaca453f5011daef8", "target_language": "ruby"}
# index.html — portiert nach ruby
# Quelle: html, Projects@Program-Derivation:public/index.html
# auch in: Projects@Vision-Check:public/index.html
# auch in: Projects@Weather-Check:public/index.html
# auch in: Projects@abstractions:public/index.html
# auch in: 5 weiteren Fundstellen
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

require 'optparse'

# Erzeuge index.html mit Weiterleitung zur 3D-Ansicht
def generate_html
  <<~HTML
    <!DOCTYPE html>
    <html lang="de">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="refresh" content="0; url=3d.html">
    <title>Weiterleitung zur 3D-Ansicht</title>
    <link rel="canonical" href="3d.html">
    <script>location.replace('3d.html');</script>
    </head>
    <body>
    <p><a href="3d.html">3D-Ansicht öffnen</a></p>
    </body>
    </html>
  HTML
end

# Hauptprogramm
def main
  output_file = nil
  
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"
    opts.on("-o", "--output FILE", "Ausgabedatei") do |file|
      output_file = file
    end
  end.parse!
  
  html_content = generate_html
  
  if output_file
    File.write(output_file, html_content)
    puts "Datei '#{output_file}' wurde erstellt."
  else
    puts html_content
  end
end

main if __FILE__ == $0
