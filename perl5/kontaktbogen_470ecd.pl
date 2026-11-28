#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "2cfbb0d1fdad1e08a5148630f5199fd6fa447e6b25245a1bccb48cd802b0c606", "source_sha256": "470ecd5aad55c517d9e61935d3422a32740607ef531514fee63990c26ee64839", "target_language": "perl5"}
# kontaktbogen.css — portiert nach perl5
# Quelle: css, Projects@abstractions:css/kontaktbogen.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# abstraction-provenance: {"artifact_sha256": "450641e159859fa2b6c4bef0c3cf3d2fc42700f880b018b48996ee2e02d23ab2", "source_sha256": "ca574d779b67b58a38559123215e116d8c6e2ef4c122350bb69958e8a6423187", "target_language": "perl"}
# kontaktbogen.html — portiert nach perl
# Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

sub generate_css {
    my $css = '';
    
    # Root variables
    $css .= ":root {\n";
    $css .= "  --bg: #FAF8F4;\n";
    $css .= "  --ink: #1B1A17;\n";
    $css .= "  --muted: #6E6A61;\n";
    $css .= "  --line: #E5E1D8;\n";
    $css .= "  --accent: #A8542F;\n";
    $css .= "  --accent-2: #2E7D7B;\n";
    $css .= "  --surface: #fff;\n";
    $css .= "}\n\n";
    
    # Universal selector
    $css .= "* {\n";
    $css .= "  box-sizing: border-box;\n";
    $css .= "}\n\n";
    
    # Body styles
    $css .= "body {\n";
    $css .= "  margin: 0;\n";
    $css .= "  font-family: 'Hanken Grotesk', system-ui, sans-serif;\n";
    $css .= "  background: var(--bg);\n";
    $css .= "  color: var(--ink);\n";
    $css .= "  line-height: 1.5;\n";
    $css .= "}\n\n";
    
    # Header styles
    $css .= "header {\n";
    $css .= "  padding: 2.5rem 2rem 1rem;\n";
    $css .= "  border-bottom: 1px solid var(--line);\n";
    $css .= "  background: var(--surface);\n";
    $css .= "  position: sticky;\n";
    $css .= "  top: 0;\n";
    $css .= "  z-index: 10;\n";
    $css .= "}\n\n";
    
    $css .= "header h1 {\n";
    $css .= "  margin: 0 0 .5rem;\n";
    $css .= "  font-family: 'Newsreader', Georgia, serif;\n";
    $css .= "  font-weight: 400;\n";
    $css .= "  font-size: 2.25rem;\n";
    $css .= "}\n\n";
    
    $css .= "header p {\n";
    $css .= "  margin: .25rem 0;\n";
    $css .= "  color: var(--muted);\n";
    $css .= "  max-width: 80ch;\n";
    $css .= "}\n\n";
    
    # Legend styles
    $css .= ".legend {\n";
    $css .= "  display: flex;\n";
    $css .= "  gap: 1rem;\n";
    $css .= "  flex-wrap: wrap;\n";
    $css .= "  margin-top: .75rem;\n";
    $css .= "  font-size: .8125rem;\n";
    $css .= "}\n\n";
    
    # Pill styles
    $css .= ".pill {\n";
    $css .= "  padding: .15rem .6rem;\n";
    $css .= "  border-radius: 999px;\n";
    $css .= "  border: 1px solid var(--line);\n";
    $css .= "  background: #fff;\n";
    $css .= "}\n\n";
    
    $css .= ".pill.pflicht {\n";
    $css .= "  border-color: var(--accent);\n";
    $css .= "  color: var(--accent);\n";
    $css .= "  font-weight: 600;\n";
    $css .= "}\n\n";
    
    $css .= ".pill.auswahl {\n";
    $css .= "  border-color: var(--accent-2);\n";
    $css .= "  color: var(--accent-2);\n";
    $css .= "  font-weight: 600;\n";
    $css .= "}\n\n";
    
    # Main styles
    $css .= "main {\n";
    $css .= "  padding: 2rem;\n";
    $css .= "  max-width: 1400px;\n";
    $css .= "  margin: 0 auto;\n";
    $css .= "}\n\n";
    
    # Section styles
    $css .= "section {\n";
    $css .= "  margin: 2.5rem 0;\n";
    $css .= "}\n\n";
    
    $css .= "section h2 {\n";
    $css .= "  font-family: 'Newsreader', serif;\n";
    $css .= "  font-weight: 400;\n";
    $css .= "  font-size: 1.5rem;\n";
    $css .= "  margin: 0 0 .25rem;\n";
    $css .= "  display: flex;\n";
    $css .= "  align-items: center;\n";
    $css .= "  gap: .75rem;\n";
    $css .= "}\n\n";
    
    $css .= "section .sub {\n";
    $css .= "  color: var(--muted);\n";
    $css .= "  font-size: .875rem;\n";
    $css .= "  margin: 0 0 1.25rem;\n";
    $css .= "}\n\n";
    
    # Grid styles
    $css .= ".grid {\n";
    $css .= "  display: grid;\n";
    $css .= "  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));\n";
    $css .= "  gap: 1rem;\n";
    $css .= "}\n\n";
    
    # Card styles
    $css .= ".card {\n";
    $css .= "  background: var(--surface);\n";
    $css .= "  border: 1px solid var(--line);\n";
    $css .= "  border-radius: 10px;\n";
    $css .= "  overflow: hidden;\n";
    $css .= "  display: flex;\n";
    $css .= "  flex-direction: column;\n";
    $css .= "}\n\n";
    
    $css .= ".card .imgwrap {\n";
    $css .= "  aspect-ratio: 1;\n";
    $css .= "  background: #f1eee7;\n";
    $css .= "  display: flex;\n";
    $css .= "  align-items: center;\n";
    $css .= "  justify-content: center;\n";
    $css .= "  overflow: hidden;\n";
    $css .= "}\n\n";
    
    $css .= ".card img {\n";
    $css .= "  width: 100%;\n";
    $css .= "  height: 100%;\n";
    $css .= "  object-fit: contain;\n";
    $css .= "  background: #fff;\n";
    $css .= "}\n\n";
    
    $css .= ".card .meta {\n";
    $css .= "  padding: .6rem .75rem .75rem;\n";
    $css .= "  font-size: .78125rem;\n";
    $css .= "}\n\n";
    
    $css .= ".card .name {\n";
    $css .= "  font-family: 'JetBrains Mono', monospace;\n";
    $css .= "  font-size: .6875rem;\n";
    $css .= "  color: var(--muted);\n";
    $css .= "  word-break: break-all;\n";
    $css .= "  line-height: 1.3;\n";
    $css .= "  margin-bottom: .35rem;\n";
    $css .= "}\n\n";
    
    $css .= ".card .dims {\n";
    $css .= "  color: var(--muted);\n";
    $css .= "  font-size: .6875rem;\n";
    $css .= "  margin-bottom: .35rem;\n";
    $css .= "}\n\n";
    
    $css .= ".card .prompt {\n";
    $css .= "  color: var(--ink);\n";
    $css .= "  font-size: .75rem;\n";
    $css .= "  line-height: 1.35;\n";
    $css .= "  font-style: italic;\n";
    $css .= "  border-top: 1px solid var(--line);\n";
    $css .= "  padding-top: .4rem;\n";
    $css .= "  margin-top: .35rem;\n";
    $css .= "  max-height: 5.5em;\n";
    $css .= "  overflow: hidden;\n";
    $css .= "}\n\n";
    
    # Tag styles
    $css .= ".tag {\n";
    $css .= "  display: inline-block;\n";
    $css .= "  padding: .1rem .45rem;\n";
    $css .= "  border-radius: 999px;\n";
    $css .= "  font-size: .6875rem;\n";
    $css .= "  background: #F1EEE7;\n";
    $css .= "  color: var(--muted);\n";
    $css .= "  margin-right: .25rem;\n";
    $css .= "}\n\n";
    
    $css .= ".tag.p {\n";
    $css .= "  background: #F1E5DD;\n";
    $css .= "  color: var(--accent);\n";
    $css .= "}\n\n";
    
    $css .= ".tag.a {\n";
    $css .= "  background: #DEEDEC;\n";
    $css .= "  color: var(--accent-2);\n";
    $css .= "}\n";
    
    return $css;
}

# Main execution
if (@ARGV != 1) {
    print STDERR "Usage: $0 <output_file>\n";
    exit 1;
}

my $output_file = $ARGV[0];
my $css_content = generate_css();

open(my $fh, '>', $output_file) or die "Could not open file '$output_file' for writing: $!";
print $fh $css_content;
close($fh);

print "CSS file generated successfully: $output_file\n";
