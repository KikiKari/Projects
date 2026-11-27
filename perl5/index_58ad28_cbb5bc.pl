#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "e58eb17f9fb38f1e7280d0852cb5b2ba9a2e2ca343d11c0ac66c82e5538d0b13", "source_sha256": "cbb5bc6a6daaf8b0fa22ba63f44d741131d32c58a9faab7d6cda9954587b0052", "target_language": "perl5"}
# index_58ad28.css — portiert nach perl5
# Quelle: css, Projects@abstractions:css/index_58ad28.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# abstraction-provenance: {"artifact_sha256": "537643848792cfff80c1482b508d158466cc91ff9b4bb017d27cc984f4a6b58f", "source_sha256": "58ad2830d3e11b79c54044cfe5a82e7e3fd2a9b1ca1f65c546ff6e92e821c6f3", "target_language": "perl"}
# index.html — portiert nach css
# Quelle: html, Projects@Telegram-Monitor:public/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

sub generate_css {
    my $css = "";

    # Root variables for light mode
    $css .= ":root {\n";
    $css .= "  --bg: #ffffff;\n";
    $css .= "  --soft: #f6f7f9;\n";
    $css .= "  --line: #e3e6ea;\n";
    $css .= "  --text: #16191d;\n";
    $css .= "  --muted: #5f6773;\n";
    $css .= "  --tg: #2481cc;\n";
    $css .= "  --tg-soft: #e8f2fb;\n";
    $css .= "  --tt: #fe2c55;\n";
    $css .= "  --ok: #15803d;\n";
    $css .= "  --ok-soft: #e7f6ec;\n";
    $css .= "  --warn: #b45309;\n";
    $css .= "  --warn-soft: #fdf3e3;\n";
    $css .= "  color-scheme: light;\n";
    $css .= "}\n\n";

    # Dark mode media query
    $css .= "\@media (prefers-color-scheme: dark) {\n";
    $css .= "  :root {\n";
    $css .= "    --bg: #0f1115;\n";
    $css .= "    --soft: #171a21;\n";
    $css .= "    --line: #262b36;\n";
    $css .= "    --text: #f2f4f8;\n";
    $css .= "    --muted: #9aa3b2;\n";
    $css .= "    --tg-soft: #132a3d;\n";
    $css .= "    --ok-soft: #12261a;\n";
    $css .= "    --warn-soft: #2c2110;\n";
    $css .= "    color-scheme: dark;\n";
    $css .= "  }\n";
    $css .= "}\n\n";

    # Universal selector
    $css .= "* {\n";
    $css .= "  box-sizing: border-box;\n";
    $css .= "}\n\n";

    # Body styles
    $css .= "body {\n";
    $css .= "  margin: 0;\n";
    $css .= "  background: var(--bg);\n";
    $css .= "  color: var(--text);\n";
    $css .= "  font: 16px/1.6 -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif;\n";
    $css .= "}\n\n";

    # Wrap container
    $css .= ".wrap {\n";
    $css .= "  max-width: 820px;\n";
    $css .= "  margin: 0 auto;\n";
    $css .= "  padding: 0 20px 72px;\n";
    $css .= "}\n\n";

    # Header section
    $css .= "header {\n";
    $css .= "  padding: 64px 0 40px;\n";
    $css .= "  border-bottom: 1px solid var(--line);\n";
    $css .= "  margin-bottom: 8px;\n";
    $css .= "}\n\n";

    # Headings
    $css .= "h1 {\n";
    $css .= "  font-size: 34px;\n";
    $css .= "  line-height: 1.2;\n";
    $css .= "  margin: 0 0 12px;\n";
    $css .= "  letter-spacing: -0.02em;\n";
    $css .= "}\n\n";

    $css .= ".lede {\n";
    $css .= "  font-size: 18px;\n";
    $css .= "  color: var(--muted);\n";
    $css .= "  margin: 0 0 22px;\n";
    $css .= "  max-width: 60ch;\n";
    $css .= "}\n\n";

    $css .= "h2 {\n";
    $css .= "  font-size: 13px;\n";
    $css .= "  margin: 44px 0 14px;\n";
    $css .= "  text-transform: uppercase;\n";
    $css .= "  letter-spacing: 0.06em;\n";
    $css .= "  color: var(--muted);\n";
    $css .= "  font-weight: 650;\n";
    $css .= "}\n\n";

    $css .= "h3 {\n";
    $css .= "  font-size: 17px;\n";
    $css .= "  margin: 26px 0 6px;\n";
    $css .= "}\n\n";

    # Paragraphs
    $css .= "p {\n";
    $css .= "  margin: 0 0 14px;\n";
    $css .= "  max-width: 68ch;\n";
    $css .= "}\n\n";

    # Badges
    $css .= ".badges {\n";
    $css .= "  display: flex;\n";
    $css .= "  gap: 7px;\n";
    $css .= "  flex-wrap: wrap;\n";
    $css .= "  margin-bottom: 22px;\n";
    $css .= "}\n\n";

    $css .= ".badge {\n";
    $css .= "  font-size: 12px;\n";
    $css .= "  font-weight: 650;\n";
    $css .= "  padding: 4px 11px;\n";
    $css .= "  border-radius: 99px;\n";
    $css .= "  background: var(--soft);\n";
    $css .= "  color: var(--muted);\n";
    $css .= "  border: 1px solid var(--line);\n";
    $css .= "}\n\n";

    $css .= ".badge.on {\n";
    $css .= "  background: var(--ok-soft);\n";
    $css .= "  color: var(--ok);\n";
    $css .= "  border-color: transparent;\n";
    $css .= "}\n\n";

    # Call to action buttons
    $css .= ".cta {\n";
    $css .= "  display: flex;\n";
    $css .= "  gap: 10px;\n";
    $css .= "  flex-wrap: wrap;\n";
    $css .= "}\n\n";

    $css .= ".btn {\n";
    $css .= "  display: inline-block;\n";
    $css .= "  font-weight: 650;\n";
    $css .= "  font-size: 15px;\n";
    $css .= "  padding: 11px 20px;\n";
    $css .= "  border-radius: 9px;\n";
    $css .= "  text-decoration: none;\n";
    $css .= "  border: 1px solid var(--line);\n";
    $css .= "  background: var(--bg);\n";
    $css .= "  color: var(--text);\n";
    $css .= "}\n\n";

    $css .= ".btn.primary {\n";
    $css .= "  background: var(--tg);\n";
    $css .= "  border-color: var(--tg);\n";
    $css .= "  color: #fff;\n";
    $css .= "}\n\n";

    $css .= ".btn:hover {\n";
    $css .= "  border-color: var(--tg);\n";
    $css .= "}\n\n";

    # Grid layout
    $css .= ".grid {\n";
    $css .= "  display: grid;\n";
    $css .= "  grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));\n";
    $css .= "  gap: 14px;\n";
    $css .= "}\n\n";

    # Cards
    $css .= ".card {\n";
    $css .= "  border: 1px solid var(--line);\n";
    $css .= "  border-radius: 12px;\n";
    $css .= "  padding: 16px 18px;\n";
    $css .= "  background: var(--bg);\n";
    $css .= "}\n\n";

    $css .= ".card h3 {\n";
    $css .= "  margin-top: 0;\n";
    $css .= "  font-size: 15.5px;\n";
    $css .= "}\n\n";

    $css .= ".card p {\n";
    $css .= "  font-size: 14px;\n";
    $css .= "  color: var(--muted);\n";
    $css .= "  margin: 0;\n";
    $css .= "}\n\n";

    # Ordered steps
    $css .= "ol.steps {\n";
    $css .= "  list-style: none;\n";
    $css .= "  counter-reset: s;\n";
    $css .= "  padding: 0;\n";
    $css .= "  margin: 0;\n";
    $css .= "}\n\n";

    $css .= "ol.steps li {\n";
    $css .= "  counter-increment: s;\n";
    $css .= "  position: relative;\n";
    $css .= "  padding: 0 0 20px 40px;\n";
    $css .= "  border-left: 2px solid var(--line);\n";
    $css .= "  margin-left: 11px;\n";
    $css .= "}\n\n";

    $css .= "ol.steps li:last-child {\n";
    $css .= "  border-left-color: transparent;\n";
    $css .= "  padding-bottom: 0;\n";
    $css .= "}\n\n";

    $css .= "ol.steps li::before {\n";
    $css .= "  content: counter(s);\n";
    $css .= "  position: absolute;\n";
    $css .= "  left: -13px;\n";
    $css .= "  top: 0;\n";
    $css .= "  width: 24px;\n";
    $css .= "  height: 24px;\n";
    $css .= "  border-radius: 50%;\n";
    $css .= "  background: var(--tg);\n";
    $css .= "  color: #fff;\n";
    $css .= "  display: flex;\n";
    $css .= "  align-items: center;\n";
    $css .= "  justify-content: center;\n";
    $css .= "  font-size: 12px;\n";
    $css .= "  font-weight: 700;\n";
    $css .= "}\n\n";

    $css .= "ol.steps b {\n";
    $css .= "  display: block;\n";
    $css .= "  margin-bottom: 3px;\n";
    $css .= "}\n\n";

    $css .= "ol.steps p {\n";
    $css .= "  font-size: 14.5px;\n";
    $css .= "  color: var(--muted);\n";
    $css .= "  margin: 0 0 8px;\n";
    $css .= "}\n\n";

    # Code blocks
    $css .= "code {\n";
    $css .= "  background: var(--soft);\n";
    $css .= "  padding: 2px 7px;\n";
    $css .= "  border-radius: 5px;\n";
    $css .= "  font-size: 13.5px;\n";
    $css .= "  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;\n";
    $css .= "  word-break: break-word;\n";
    $css .= "}\n\n";

    $css .= "pre {\n";
    $css .= "  background: var(--soft);\n";
    $css .= "  border: 1px solid var(--line);\n";
    $css .= "  border-radius: 10px;\n";
    $css .= "  padding: 13px 15px;\n";
    $css .= "  overflow-x: auto;\n";
    $css .= "  margin: 0 0 14px;\n";
    $css .= "}\n\n";

    $css .= "pre code {\n";
    $css .= "  background: none;\n";
    $css .= "  padding: 0;\n";
    $css .= "  font-size: 13.5px;\n";
    $css .= "  line-height: 1.7;\n";
    $css .= "}\n\n";

    # Tables
    $css .= "table {\n";
    $css .= "  width: 100%;\n";
    $css .= "  border-collapse: collapse;\n";
    $css .= "  font-size: 14.5px;\n";
    $css .= "  margin: 0 0 16px;\n";
    $css .= "}\n\n";

    $css .= "th,\n";
    $css .= "td {\n";
    $css .= "  text-align: left;\n";
    $css .= "  padding: 9px 11px;\n";
    $css .= "  border-bottom: 1px solid var(--line);\n";
    $css .= "  vertical-align: top;\n";
    $css .= "}\n\n";

    $css .= "th {\n";
    $css .= "  color: var(--muted);\n";
    $css .= "  font-size: 12px;\n";
    $css .= "  text-transform: uppercase;\n";
    $css .= "  letter-spacing: 0.04em;\n";
    $css .= "  font-weight: 650;\n";
    $css .= "}\n\n";

    # Notes/warnings
    $css .= ".note {\n";
    $css .= "  border-left: 3px solid var(--warn);\n";
    $css .= "  background: var(--warn-soft);\n";
    $css .= "  border-radius: 0 9px 9px 0;\n";
    $css .= "  padding: 13px 16px;\n";
    $css .= "  margin: 0 0 16px;\n";
    $css .= "  font-size: 14.5px;\n";
    $css .= "}\n\n";

    $css .= ".note b {\n";
    $css .= "  display: block;\n";
    $css .= "  margin-bottom: 3px;\n";
    $css .= "}\n\n";

    # Links
    $css .= "a {\n";
    $css .= "  color: var(--tg);\n";
    $css .= "}\n\n";

    # Footer
    $css .= "footer {\n";
    $css .= "  margin-top: 52px;\n";
    $css .= "  padding-top: 22px;\n";
    $css .= "  border-top: 1px solid var(--line);\n";
    $css .= "  font-size: 13.5px;\n";
    $css .= "  color: var(--muted);\n";
    $css .= "}\n";

    return $css;
}

# Main execution
my $output_file = $ARGV[0] || 'index_58ad28.css';
my $css_content = generate_css();

open(my $fh, '>', $output_file) or die "Could not open file '$output_file' $!";
print $fh $css_content;
close $fh;

print "CSS file generated: $output_file\n";
