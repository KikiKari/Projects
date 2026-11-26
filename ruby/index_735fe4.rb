#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "997090d92443923d0be3e65e83ae968066372156e26e469ea5c2d6ddfe4ef7d8", "source_sha256": "735fe4b2c74b10f265f715cd4e85d574f46a7132d2e592703b5e712888470105", "target_language": "ruby"}
# index.html — portiert nach ruby
# Quelle: html, OpenClaw@main:index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

require 'optparse'

# Parse command line options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] OUTPUT_FILE"
  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!(into: options)

if ARGV.empty?
  puts "Error: Output file argument missing."
  puts "Use --help for usage information."
  exit 1
end

output_file = ARGV[0]

# Generate HTML structure
html_content = <<~HTML
  <!DOCTYPE html>
  <html lang="de">
    <head>
      <meta charset="utf-8" />
      <link rel="icon" href="/favicon.ico" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <meta name="theme-color" content="#0b1020" />
      <meta
        name="description"
        content="OpenClaw Startseite für Repository, Dokumentation und Frontend-Branch."
      />
      <link rel="apple-touch-icon" href="/logo192.png" />
      <!--
        manifest.json provides metadata used when your web app is installed on a
        user's mobile device or desktop. See https://developers.google.com/web/fundamentals/web-app-manifest/
      -->
      <link rel="manifest" href="/manifest.json" />
      <title>OpenClaw</title>
    </head>
    <body>
      <noscript>You need to enable JavaScript to run this app.</noscript>
      <div id="root"></div>
      <!--
        This HTML file is a template.
        If you open it directly in the browser, you will see an empty page.

        You can add webfonts, meta tags, or analytics to this file.
        The build step will place the bundled scripts into the <body> tag.

        To begin the development, run `npm start` or `yarn start`.
        To create a production bundle, use `npm run build` or `yarn build`.
      -->
    </body>
    <script type="module" src="/src/index.jsx"></script>
  </html>
HTML

# Write to output file
File.open(output_file, 'w') do |file|
  file.write(html_content)
end

puts "HTML file generated successfully: #{output_file}"
