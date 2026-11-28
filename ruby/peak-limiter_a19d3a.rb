#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "6558c1e336f452d7276511d1ff14d0b5120c3ad64c2270190439e0f98158783b", "source_sha256": "a19d3a3ec8b016d9d04f485dc499f8ad715431708b02863f2ac58f3208061edd", "target_language": "ruby"}
# peak-limiter.css — portiert nach ruby
# Quelle: css, Projects@abstractions:css/peak-limiter.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

# abstraction-provenance: {"artifact_sha256": "3f2b97b726a0a4643711dc1dc285df9b75511cc4f35fbe168e178bf60aeaa00d", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "css"}
# peak-limiter.html — portiert nach css
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

def generate_css
  css_rules = []
  
  # body rule
  css_rules << "body {"
  css_rules << "  font: 16px system-ui;"
  css_rules << "  max-width: 1000px;"
  css_rules << "  margin: 40px auto;"
  css_rules << "  padding: 20px;"
  css_rules << "}"
  css_rules << ""
  
  # pre rule
  css_rules << "pre {"
  css_rules << "  white-space: pre-wrap;"
  css_rules << "}"
  css_rules << ""
  
  # button rule
  css_rules << "button {"
  css_rules << "  padding: 12px;"
  css_rules << "}"
  css_rules << ""
  
  css_rules.join("\n")
end

def write_css_to_file(filename)
  File.open(filename, 'w') do |file|
    file.write(generate_css)
  end
end

if __FILE__ == $0
  if ARGV.length != 1
    puts "Verwendung: #{$0} <ausgabedatei>"
    exit 1
  end
  
  output_file = ARGV[0]
  write_css_to_file(output_file)
  puts "CSS erfolgreich in #{output_file} geschrieben"
end
