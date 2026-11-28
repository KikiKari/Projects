#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "a6dd86d932b2075e1109118bd1e1d7a335418757c8942f08e6d1e5fa7924e237", "source_sha256": "470ecd5aad55c517d9e61935d3422a32740607ef531514fee63990c26ee64839", "target_language": "ruby"}
# kontaktbogen.css — portiert nach ruby
# Quelle: css, Projects@abstractions:css/kontaktbogen.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

# abstraction-provenance: {"artifact_sha256": "450641e159859fa2b6c4bef0c3cf3d2fc42700f880b018b48996ee2e02d23ab2", "source_sha256": "ca574d779b67b58a38559123215e116d8c6e2ef4c122350bb69958e8a6423187", "target_language": "ruby"}
# kontaktbogen.html — portiert nach css
# Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

require 'fileutils'

class KontaktbogenCSSGenerator
  def initialize
    @variables = {
      '--bg' => '#FAF8F4',
      '--ink' => '#1B1A17',
      '--muted' => '#6E6A61',
      '--line' => '#E5E1D8',
      '--accent' => '#A8542F',
      '--accent-2' => '#2E7D7B',
      '--surface' => '#fff'
    }
  end

  def generate_css
    css_content = []
    
    # Root variables
    css_content << ":root {"
    @variables.each do |key, value|
      css_content << "  #{key}: #{value};"
    end
    css_content << "}"
    css_content << ""
    
    # Universal selector
    css_content << "* {"
    css_content << "  box-sizing: border-box;"
    css_content << "}"
    css_content << ""
    
    # Body styles
    css_content << "body {"
    css_content << "  margin: 0;"
    css_content << "  font-family: 'Hanken Grotesk', system-ui, sans-serif;"
    css_content << "  background: var(--bg);"
    css_content << "  color: var(--ink);"
    css_content << "  line-height: 1.5;"
    css_content << "}"
    css_content << ""
    
    # Header styles
    css_content << "header {"
    css_content << "  padding: 2.5rem 2rem 1rem;"
    css_content << "  border-bottom: 1px solid var(--line);"
    css_content << "  background: var(--surface);"
    css_content << "  position: sticky;"
    css_content << "  top: 0;"
    css_content << "  z-index: 10;"
    css_content << "}"
    css_content << ""
    
    css_content << "header h1 {"
    css_content << "  margin: 0 0 .5rem;"
    css_content << "  font-family: 'Newsreader', Georgia, serif;"
    css_content << "  font-weight: 400;"
    css_content << "  font-size: 2.25rem;"
    css_content << "}"
    css_content << ""
    
    css_content << "header p {"
    css_content << "  margin: .25rem 0;"
    css_content << "  color: var(--muted);"
    css_content << "  max-width: 80ch;"
    css_content << "}"
    css_content << ""
    
    # Legend styles
    css_content << ".legend {"
    css_content << "  display: flex;"
    css_content << "  gap: 1rem;"
    css_content << "  flex-wrap: wrap;"
    css_content << "  margin-top: .75rem;"
    css_content << "  font-size: .8125rem;"
    css_content << "}"
    css_content << ""
    
    # Pill styles
    css_content << ".pill {"
    css_content << "  padding: .15rem .6rem;"
    css_content << "  border-radius: 999px;"
    css_content << "  border: 1px solid var(--line);"
    css_content << "  background: #fff;"
    css_content << "}"
    css_content << ""
    
    css_content << ".pill.pflicht {"
    css_content << "  border-color: var(--accent);"
    css_content << "  color: var(--accent);"
    css_content << "  font-weight: 600;"
    css_content << "}"
    css_content << ""
    
    css_content << ".pill.auswahl {"
    css_content << "  border-color: var(--accent-2);"
    css_content << "  color: var(--accent-2);"
    css_content << "  font-weight: 600;"
    css_content << "}"
    css_content << ""
    
    # Main styles
    css_content << "main {"
    css_content << "  padding: 2rem;"
    css_content << "  max-width: 1400px;"
    css_content << "  margin: 0 auto;"
    css_content << "}"
    css_content << ""
    
    # Section styles
    css_content << "section {"
    css_content << "  margin: 2.5rem 0;"
    css_content << "}"
    css_content << ""
    
    css_content << "section h2 {"
    css_content << "  font-family: 'Newsreader', serif;"
    css_content << "  font-weight: 400;"
    css_content << "  font-size: 1.5rem;"
    css_content << "  margin: 0 0 .25rem;"
    css_content << "  display: flex;"
    css_content << "  align-items: center;"
    css_content << "  gap: .75rem;"
    css_content << "}"
    css_content << ""
    
    css_content << "section .sub {"
    css_content << "  color: var(--muted);"
    css_content << "  font-size: .875rem;"
    css_content << "  margin: 0 0 1.25rem;"
    css_content << "}"
    css_content << ""
    
    # Grid styles
    css_content << ".grid {"
    css_content << "  display: grid;"
    css_content << "  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));"
    css_content << "  gap: 1rem;"
    css_content << "}"
    css_content << ""
    
    # Card styles
    css_content << ".card {"
    css_content << "  background: var(--surface);"
    css_content << "  border: 1px solid var(--line);"
    css_content << "  border-radius: 10px;"
    css_content << "  overflow: hidden;"
    css_content << "  display: flex;"
    css_content << "  flex-direction: column;"
    css_content << "}"
    css_content << ""
    
    css_content << ".card .imgwrap {"
    css_content << "  aspect-ratio: 1;"
    css_content << "  background: #f1eee7;"
    css_content << "  display: flex;"
    css_content << "  align-items: center;"
    css_content << "  justify-content: center;"
    css_content << "  overflow: hidden;"
    css_content << "}"
    css_content << ""
    
    css_content << ".card img {"
    css_content << "  width: 100%;"
    css_content << "  height: 100%;"
    css_content << "  object-fit: contain;"
    css_content << "  background: #fff;"
    css_content << "}"
    css_content << ""
    
    css_content << ".card .meta {"
    css_content << "  padding: .6rem .75rem .75rem;"
    css_content << "  font-size: .78125rem;"
    css_content << "}"
    css_content << ""
    
    css_content << ".card .name {"
    css_content << "  font-family: 'JetBrains Mono', monospace;"
    css_content << "  font-size: .6875rem;"
    css_content << "  color: var(--muted);"
    css_content << "  word-break: break-all;"
    css_content << "  line-height: 1.3;"
    css_content << "  margin-bottom: .35rem;"
    css_content << "}"
    css_content << ""
    
    css_content << ".card .dims {"
    css_content << "  color: var(--muted);"
    css_content << "  font-size: .6875rem;"
    css_content << "  margin-bottom: .35rem;"
    css_content << "}"
    css_content << ""
    
    css_content << ".card .prompt {"
    css_content << "  color: var(--ink);"
    css_content << "  font-size: .75rem;"
    css_content << "  line-height: 1.35;"
    css_content << "  font-style: italic;"
    css_content << "  border-top: 1px solid var(--line);"
    css_content << "  padding-top: .4rem;"
    css_content << "  margin-top: .35rem;"
    css_content << "  max-height: 5.5em;"
    css_content << "  overflow: hidden;"
    css_content << "}"
    css_content << ""
    
    # Tag styles
    css_content << ".tag {"
    css_content << "  display: inline-block;"
    css_content << "  padding: .1rem .45rem;"
    css_content << "  border-radius: 999px;"
    css_content << "  font-size: .6875rem;"
    css_content << "  background: #F1EEE7;"
    css_content << "  color: var(--muted);"
    css_content << "  margin-right: .25rem;"
    css_content << "}"
    css_content << ""
    
    css_content << ".tag.p {"
    css_content << "  background: #F1E5DD;"
    css_content << "  color: var(--accent);"
    css_content << "}"
    css_content << ""
    
    css_content << ".tag.a {"
    css_content << "  background: #DEEDEC;"
    css_content << "  color: var(--accent-2);"
    css_content << "}"
    
    css_content.join("\n")
  end
  
  def write_to_file(filename)
    File.open(filename, 'w') do |file|
      file.write(generate_css)
    end
  end
end

if __FILE__ == $0
  if ARGV.length != 1
    puts "Verwendung: #{$0} <ausgabedatei>"
    exit 1
  end
  
  generator = KontaktbogenCSSGenerator.new
  output_file = ARGV[0]
  
  generator.write_to_file(output_file)
  puts "CSS-Datei wurde erfolgreich erstellt: #{output_file}"
end
