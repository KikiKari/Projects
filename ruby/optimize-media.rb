#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "af238791a20fa48b666536f13be9296f2f32a71fe6acabf533b2508329deaf55", "source_sha256": "01865e120d0e52b50fea21a5f976ac63af413e6829f861a5d31d7898bd4dbaf4", "target_language": "ruby"}
# optimize-media.mjs — portiert nach ruby
# Quelle: javascript, Onboarding@main:scripts/optimize-media.mjs
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

require 'pathname'
require 'fileutils'

# Funktion zum Konvertieren von WebP und AVIF
def convert_image(source_path, output_path, format, quality)
  case format
  when :webp
    # WebP-Konvertierung mit ImageMagick
    system("convert", source_path, "-quality", quality.to_s, output_path)
  when :avif
    # AVIF-Konvertierung mit ImageMagick (falls unterstützt)
    system("convert", source_path, "-quality", quality.to_s, output_path)
  end
end

# Hauptverzeichnis bestimmen
directory = Pathname.new(File.join(__dir__, "../public/media/")).cleanpath

# Alle PNG-Dateien im Verzeichnis durchgehen
Dir.glob(File.join(directory, "*.png")).each do |source|
  next unless File.file?(source)
  
  filename = File.basename(source, ".png")
  
  # WebP erstellen
  webp_output = File.join(directory, "#{filename}.webp")
  convert_image(source, webp_output, :webp, 84)
  
  # AVIF erstellen
  avif_output = File.join(directory, "#{filename}.avif")
  convert_image(source, avif_output, :avif, 58)
end

puts "WebP- und AVIF-Derivate erzeugt."
