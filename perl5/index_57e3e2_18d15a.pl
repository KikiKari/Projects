#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "4f2c44cdfb060725e432d9913fad266e6b21f7f6594e8ff7945b632c16ae6082", "source_sha256": "18d15a289b831c9da96c808e0cc1de4dae7bf3dfc35a804a239a992cd82cde89", "target_language": "perl5"}
# index_57e3e2.css — portiert nach perl5
# Quelle: css, Projects@abstractions:css/index_57e3e2.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# abstraction-provenance: {"artifact_sha256": "a05439af4536c91ed01734c3151c3870ffe206fc2433d74fe3db29d4666579ca", "source_sha256": "57e3e28b7c96948ea289f7d9401b6d0bf990d118129de570394784d35e23cf4c", "target_language": "perl"}
# index.html — portiert nach css
# Quelle: html, Projects@tagesstatus-live-public:tagesstatus-live-public/index.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

sub generate_css {
    my $css = "";

    # Root styles
    $css .= ":root {\n";
    $css .= "  color-scheme: light;\n";
    $css .= "}\n\n";

    # Universal selector
    $css .= "* {\n";
    $css .= "  box-sizing: border-box;\n";
    $css .= "}\n\n";

    # Body styles
    $css .= "body {\n";
    $css .= "  margin: 0;\n";
    $css .= "  font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, Helvetica, Arial, sans-serif;\n";
    $css .= "  background: #f7f7f5;\n";
    $css .= "  color: #1d1c1a;\n";
    $css .= "}\n\n";

    # Wrap container
    $css .= ".wrap {\n";
    $css .= "  max-width: 880px;\n";
    $css .= "  margin: 0 auto;\n";
    $css .= "  padding: 20px 16px 60px;\n";
    $css .= "}\n\n";

    # Headings
    $css .= "h1 {\n";
    $css .= "  font-size: 22px;\n";
    $css .= "  margin: 0 0 2px;\n";
    $css .= "}\n\n";

    # Subtitle
    $css .= ".sub {\n";
    $css .= "  color: #6b6a66;\n";
    $css .= "  font-size: 13px;\n";
    $css .= "  margin-bottom: 16px;\n";
    $css .= "}\n\n";

    # Bar container
    $css .= ".bar {\n";
    $css .= "  display: flex;\n";
    $css .= "  gap: 10px;\n";
    $css .= "  align-items: center;\n";
    $css .= "  margin-bottom: 16px;\n";
    $css .= "  flex-wrap: wrap;\n";
    $css .= "}\n\n";

    # Buttons
    $css .= "button {\n";
    $css .= "  font-size: 13px;\n";
    $css .= "  font-weight: 600;\n";
    $css .= "  padding: 7px 13px;\n";
    $css .= "  border: 1px solid #d9d8d3;\n";
    $css .= "  border-radius: 8px;\n";
    $css .= "  background: #fff;\n";
    $css .= "  cursor: pointer;\n";
    $css .= "}\n\n";

    $css .= "button:hover {\n";
    $css .= "  background: #f2f1ec;\n";
    $css .= "}\n\n";

    $css .= "button.primary {\n";
    $css .= "  background: #1d1c1a;\n";
    $css .= "  color: #fff;\n";
    $css .= "  border-color: #1d1c1a;\n";
    $css .= "}\n\n";

    # Note box
    $css .= ".note {\n";
    $css .= "  background: #fffdf4;\n";
    $css .= "  border: 1px solid #f0e9c8;\n";
    $css .= "  border-radius: 10px;\n";
    $css .= "  padding: 12px 14px;\n";
    $css .= "  font-size: 13px;\n";
    $css .= "  color: #4a4734;\n";
    $css .= "  margin-bottom: 16px;\n";
    $css .= "  line-height: 1.5;\n";
    $css .= "}\n\n";

    # Section containers
    $css .= ".section {\n";
    $css .= "  background: #fff;\n";
    $css .= "  border: 1px solid #e8e7e3;\n";
    $css .= "  border-radius: 12px;\n";
    $css .= "  margin-bottom: 14px;\n";
    $css .= "  overflow: hidden;\n";
    $css .= "}\n\n";

    $css .= ".section > h2 {\n";
    $css .= "  font-size: 15px;\n";
    $css .= "  margin: 0;\n";
    $css .= "  padding: 13px 16px;\n";
    $css .= "  border-bottom: 1px solid #efeee9;\n";
    $css .= "  display: flex;\n";
    $css .= "  align-items: center;\n";
    $css .= "  gap: 9px;\n";
    $css .= "}\n\n";

    $css .= ".section > h2 .badge {\n";
    $css .= "  margin-left: auto;\n";
    $css .= "  font-size: 12px;\n";
    $css .= "  font-weight: 600;\n";
    $css .= "  background: #efeee9;\n";
    $css .= "  color: #5a5852;\n";
    $css .= "  padding: 2px 9px;\n";
    $css .= "  border-radius: 20px;\n";
    $css .= "}\n\n";

    # Body content
    $css .= ".body {\n";
    $css .= "  padding: 8px 16px 14px;\n";
    $css .= "  font-size: 14px;\n";
    $css .= "}\n\n";

    # Muted text
    $css .= ".muted {\n";
    $css .= "  color: #8a8884;\n";
    $css .= "}\n\n";

    # Error text
    $css .= ".err {\n";
    $css .= "  color: #c0392b;\n";
    $css .= "}\n\n";

    # Key-value pairs
    $css .= ".kv {\n";
    $css .= "  display: flex;\n";
    $css .= "  justify-content: space-between;\n";
    $css .= "  padding: 4px 0;\n";
    $css .= "  border-bottom: 1px solid #f4f3ee;\n";
    $css .= "}\n\n";

    $css .= ".kv:last-child {\n";
    $css .= "  border: none;\n";
    $css .= "}\n\n";

    $css .= ".kv .k {\n";
    $css .= "  color: #6b6a66;\n";
    $css .= "}\n\n";

    $css .= ".kv .v {\n";
    $css .= "  font-weight: 600;\n";
    $css .= "}\n\n";

    # Links
    $css .= "a {\n";
    $css .= "  color: #2b5cc4;\n";
    $css .= "  text-decoration: none;\n";
    $css .= "}\n\n";

    $css .= "a:hover {\n";
    $css .= "  text-decoration: underline;\n";
    $css .= "}\n\n";

    # Settings modal
    $css .= ".modal {\n";
    $css .= "  position: fixed;\n";
    $css .= "  inset: 0;\n";
    $css .= "  background: rgba(0, 0, 0, .35);\n";
    $css .= "  display: none;\n";
    $css .= "  align-items: flex-start;\n";
    $css .= "  justify-content: center;\n";
    $css .= "  padding: 40px 16px;\n";
    $css .= "  overflow: auto;\n";
    $css .= "}\n\n";

    $css .= ".modal.open {\n";
    $css .= "  display: flex;\n";
    $css .= "}\n\n";

    # Card component
    $css .= ".card {\n";
    $css .= "  background: #fff;\n";
    $css .= "  border-radius: 14px;\n";
    $css .= "  max-width: 560px;\n";
    $css .= "  width: 100%;\n";
    $css .= "  padding: 20px;\n";
    $css .= "}\n\n";

    $css .= ".card h3 {\n";
    $css .= "  margin: 0 0 4px;\n";
    $css .= "  font-size: 17px;\n";
    $css .= "}\n\n";

    $css .= ".card p.hint {\n";
    $css .= "  margin: 0 0 16px;\n";
    $css .= "  font-size: 12px;\n";
    $css .= "  color: #8a8884;\n";
    $css .= "}\n\n";

    # Form fields
    $css .= ".field {\n";
    $css .= "  margin-bottom: 12px;\n";
    $css .= "}\n\n";

    $css .= ".field label {\n";
    $css .= "  display: block;\n";
    $css .= "  font-size: 12px;\n";
    $css .= "  font-weight: 600;\n";
    $css .= "  color: #5a5852;\n";
    $css .= "  margin-bottom: 3px;\n";
    $css .= "}\n\n";

    $css .= ".field input {\n";
    $css .= "  width: 100%;\n";
    $css .= "  font-size: 13px;\n";
    $css .= "  padding: 7px 9px;\n";
    $css .= "  border: 1px solid #d9d8d3;\n";
    $css .= "  border-radius: 7px;\n";
    $css .= "  font-family: ui-monospace, Menlo, monospace;\n";
    $css .= "}\n\n";

    $css .= ".field .desc {\n";
    $css .= "  font-size: 11px;\n";
    $css .= "  color: #a8a6a1;\n";
    $css .= "  margin-top: 2px;\n";
    $css .= "}\n\n";

    # Action buttons
    $css .= ".actions {\n";
    $css .= "  display: flex;\n";
    $css .= "  gap: 10px;\n";
    $css .= "  justify-content: flex-end;\n";
    $css .= "  margin-top: 8px;\n";
    $css .= "}\n\n";

    # Warning box
    $css .= ".warn {\n";
    $css .= "  background: #fdf3f3;\n";
    $css .= "  border: 1px solid #f3d9d9;\n";
    $css .= "  color: #9a3b3b;\n";
    $css .= "  border-radius: 8px;\n";
    $css .= "  padding: 10px 12px;\n";
    $css .= "  font-size: 12px;\n";
    $css .= "  margin-bottom: 14px;\n";
    $css .= "}\n";

    return $css;
}

# Main execution
if (@ARGV != 1) {
    print STDERR "Usage: $0 <output_file>\n";
    exit 1;
}

my $output_file = $ARGV[0];

# Generate the CSS content
my $css_content = generate_css();

# Write to file
open(my $fh, '>', $output_file) or die "Could not open file '$output_file' for writing: $!";
print $fh $css_content;
close($fh);

print "CSS file generated successfully: $output_file\n";
