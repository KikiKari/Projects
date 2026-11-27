#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "3056e3fb5f279c4431930176f375f63e8768f9384ac610c7a881c8e4af7e26b4", "source_sha256": "b32c733987d23de98ace1b2a5119f7cb7989a0887c165c1db133ecb4ef278438", "target_language": "perl5"}
# index_f17dea.css — portiert nach perl5
# Quelle: css, Projects@abstractions:css/index_f17dea.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# abstraction-provenance: {"artifact_sha256": "9ebfdd610ffe88b7273a5ac8e215314a7bee0dffecf25fe9a995b6a39703e204", "source_sha256": "f17deae3e31b89fd76d250bd20903b36591af417c97b34d987e923632be9ac37", "target_language": "perl5"}
# index.html — portiert nach css
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/raku/index.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/raku/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

sub generate_css {
    my $css = '';

    # General Styles
    $css .= "/* General Styles */\n";
    $css .= "html {\n";
    $css .= "    scroll-padding-top: 60px;\n";
    $css .= "}\n\n";
    
    $css .= "body.has-navbar-fixed-top {\n";
    $css .= "    padding-top: 60px;\n";
    $css .= "}\n\n";

    # Navbar Styles
    $css .= "/* Navbar Styles */\n";
    $css .= ".navbar.is-fixed-top {\n";
    $css .= "    position: fixed;\n";
    $css .= "    top: 0;\n";
    $css .= "    left: 0;\n";
    $css .= "    right: 0;\n";
    $css .= "    z-index: 30;\n";
    $css .= "    min-height: 3.25rem;\n";
    $css .= "}\n\n";
    
    $css .= ".navbar.is-flex-touch {\n";
    $css .= "    display: flex;\n";
    $css .= "}\n\n";
    
    $css .= ".container.is-justify-content-space-around {\n";
    $css .= "    justify-content: space-around;\n";
    $css .= "}\n\n";
    
    $css .= ".navbar-brand {\n";
    $css .= "    display: flex;\n";
    $css .= "    align-items: center;\n";
    $css .= "}\n\n";
    
    $css .= ".navbar-logo {\n";
    $css .= "    display: flex;\n";
    $css .= "    align-items: center;\n";
    $css .= "}\n\n";
    
    $css .= ".navbar-logo-tm {\n";
    $css .= "    font-size: 0.75rem;\n";
    $css .= "    margin-left: 0.25rem;\n";
    $css .= "}\n\n";
    
    $css .= ".navbar-burger {\n";
    $css .= "    display: block;\n";
    $css .= "    position: relative;\n";
    $css .= "    cursor: pointer;\n";
    $css .= "}\n\n";
    
    $css .= ".navbar-burger span {\n";
    $css .= "    display: block;\n";
    $css .= "    height: 1px;\n";
    $css .= "    width: 20px;\n";
    $css .= "    background-color: currentColor;\n";
    $css .= "    margin: 5px 0;\n";
    $css .= "    transition: transform 0.3s ease;\n";
    $css .= "}\n\n";
    
    $css .= ".navbar-menu {\n";
    $css .= "    display: none;\n";
    $css .= "}\n\n";
    
    $css .= ".navbar-start, .navbar-end {\n";
    $css .= "    display: flex;\n";
    $css .= "    align-items: center;\n";
    $css .= "}\n\n";
    
    $css .= ".navbar-item {\n";
    $css .= "    display: block;\n";
    $css .= "    padding: 0.5rem 0.75rem;\n";
    $css .= "}\n\n";
    
    $css .= ".navbar-link {\n";
    $css .= "    display: block;\n";
    $css .= "    padding: 0.5rem 0.75rem;\n";
    $css .= "}\n\n";
    
    $css .= ".navbar-dropdown {\n";
    $css .= "    display: none;\n";
    $css .= "    position: absolute;\n";
    $css .= "    top: 100%;\n";
    $css .= "    left: 0;\n";
    $css .= "    background-color: white;\n";
    $css .= "    border-radius: 4px;\n";
    $css .= "    box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1);\n";
    $css .= "}\n\n";
    
    $css .= ".navbar-dropdown.is-right {\n";
    $css .= "    left: auto;\n";
    $css .= "    right: 0;\n";
    $css .= "}\n\n";
    
    $css .= ".navbar-dropdown.is-rounded {\n";
    $css .= "    border-radius: 4px;\n";
    $css .= "}\n\n";
    
    $css .= ".navbar-divider {\n";
    $css .= "    display: block;\n";
    $css .= "    height: 1px;\n";
    $css .= "    background-color: #dbdbdb;\n";
    $css .= "    margin: 0.5rem 0;\n";
    $css .= "}\n\n";
    
    $css .= ".has-dropdown:hover .navbar-dropdown {\n";
    $css .= "    display: block;\n";
    $css .= "}\n\n";
    
    $css .= ".navbar-search-wrapper {\n";
    $css .= "    display: flex;\n";
    $css .= "    align-items: center;\n";
    $css .= "}\n\n";
    
    $css .= ".field.has-addons {\n";
    $css .= "    display: flex;\n";
    $css .= "}\n\n";
    
    $css .= ".control {\n";
    $css .= "    position: relative;\n";
    $css .= "}\n\n";
    
    $css .= ".autoComplete_options {\n";
    $css .= "    flex-grow: 1;\n";
    $css .= "}\n\n";
    
    $css .= ".input {\n";
    $css .= "    display: block;\n";
    $css .= "    width: 100%;\n";
    $css .= "    padding: 0.375rem 0.75rem;\n";
    $css .= "    font-size: 1rem;\n";
    $css .= "    line-height: 1.5;\n";
    $css .= "    color: #495057;\n";
    $css .= "    background-color: #fff;\n";
    $css .= "    background-clip: padding-box;\n";
    $css .= "    border: 1px solid #ced4da;\n";
    $css .= "    border-radius: 0.25rem;\n";
    $css .= "    transition: border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;\n";
    $css .= "}\n\n";
    
    $css .= ".button.is-primary {\n";
    $css .= "    background-color: #00d1b2;\n";
    $css .= "    border-color: transparent;\n";
    $css .= "    color: #fff;\n";
    $css .= "}\n\n";
    
    $css .= ".icon {\n";
    $css .= "    display: inline-flex;\n";
    $css .= "    justify-content: center;\n";
    $css .= "    align-items: center;\n";
    $css .= "}\n\n";
    
    $css .= ".modal {\n";
    $css .= "    position: fixed;\n";
    $css .= "    top: 0;\n";
    $css .= "    left: 0;\n";
    $css .= "    right: 0;\n";
    $css .= "    bottom: 0;\n";
    $css .= "    z-index: 40;\n";
    $css .= "    display: none;\n";
    $css .= "    opacity: 0;\n";
    $css .= "    transition: opacity 0.15s linear;\n";
    $css .= "}\n\n";
    
    $css .= ".modal.is-active {\n";
    $css .= "    display: flex;\n";
    $css .= "    opacity: 1;\n";
    $css .= "}\n\n";
    
    $css .= ".modal-background {\n";
    $css .= "    position: absolute;\n";
    $css .= "    top: 0;\n";
    $css .= "    left: 0;\n";
    $css .= "    right: 0;\n";
    $css .= "    bottom: 0;\n";
    $css .= "    background-color: rgba(10, 10, 10, 0.86);\n";
    $css .= "}\n\n";
    
    $css .= ".modal-content {\n";
    $css .= "    position: relative;\n";
    $css .= "    width: 100%;\n";
    $css .= "    max-height: calc(100vh - 160px);\n";
    $css .= "    overflow: auto;\n";
    $css .= "    margin: 0 auto;\n";
    $css .= "    padding: 20px;\n";
    $css .= "}\n\n";
    
    $css .= ".box {\n";
    $css .= "    background-color: white;\n";
    $css .= "    border-radius: 6px;\n";
    $css .= "    box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1), 0 0 0 1px rgba(10, 10, 10, 0.02);\n";
    $css .= "    padding: 1.25rem;\n";
    $css .= "}\n\n";
    
    $css .= ".modal-close {\n";
    $css .= "    position: absolute;\n";
    $css .= "    top: 20px;\n";
    $css .= "    right: 20px;\n";
    $css .= "    width: 40px;\n";
    $css .= "    height: 40px;\n";
    $css .= "    background: none;\n";
    $css .= "    border: none;\n";
    $css .= "    cursor: pointer;\n";
    $css .= "}\n\n";
    
    $css .= ".options-search-controls {\n";
    $css .= "    display: flex;\n";
    $css .= "    flex-direction: column;\n";
    $css .= "    gap: 1rem;\n";
    $css .= "}\n\n";
    
    $css .= ".centreToggle {\n";
    $css .= "    display: flex;\n";
    $css .= "    align-items: center;\n";
    $css .= "    gap: 0.5rem;\n";
    $css .= "}\n\n";
    
    $css .= ".centreToggle input[type=\"checkbox\"] {\n";
    $css .= "    width: var(--switch-width, 10.5em);\n";
    $css .= "    height: 2em;\n";
    $css .= "    appearance: none;\n";
    $css .= "    background: #ccc;\n";
    $css .= "    border-radius: 1em;\n";
    $css .= "    position: relative;\n";
    $css .= "    cursor: pointer;\n";
    $css .= "}\n\n";
    
    $css .= ".centreToggle input[type=\"checkbox\"]:checked {\n";
    $css .= "    background: #00d1b2;\n";
    $css .= "}\n\n";
    
    $css .= ".centreToggle input[type=\"checkbox\"]::before {\n";
    $css .= "    content: '';\n";
    $css .= "    position: absolute;\n";
    $css .= "    width: 1.6em;\n";
    $css .= "    height: 1.6em;\n";
    $css .= "    background: white;\n";
    $css .= "    border-radius: 50%;\n";
    $css .= "    top: 0.2em;\n";
    $css .= "    left: 0.2em;\n";
    $css .= "    transition: transform 0.3s;\n";
    $css .= "}\n\n";
    
    $css .= ".centreToggle input[type=\"checkbox\"]:checked::before {\n";
    $css .= "    transform: translateX(calc(var(--switch-width, 10.5em) - 2em));\n";
    $css .= "}\n\n";
    
    $css .= ".centreToggle .text,\n";
    $css .= ".centreToggle .on,\n";
    $css .= ".centreToggle .off {\n";
    $css .= "    font-weight: bold;\n";
    $css .= "}\n\n";
    
    $css .= ".centreToggle .on,\n";
    $css .= ".centreToggle .off {\n";
    $css .= "    position: absolute;\n";
    $css .= "    top: 50%;\n";
    $css .= "    transform: translateY(-50%);\n";
    $css .= "}\n\n";
    
    $css .= ".centreToggle .on {\n";
    $css .= "    left: 0.5em;\n";
    $css .= "    color: white;\n";
    $css .= "}\n\n";
    
    $css .= ".centreToggle .off {\n";
    $css .= "    right: 0.5em;\n";
    $css .= "    color: #333;\n";
    $css .= "}\n\n";

    # Hero Section
    $css .= "/* Hero Section */\n";
    $css .= ".hero.is-medium {\n";
    $css .= "    min-height: 300px;\n";
    $css .= "}\n\n";
    
    $css .= ".hero.is-primary {\n";
    $css .= "    background-color: #00d1b2;\n";
    $css .= "    color: #fff;\n";
    $css .= "}\n\n";
    
    $css .= ".hero-body {\n";
    $css .= "    padding: 3rem 1.5rem;\n";
    $css .= "}\n\n";
    
    $css .= ".title.is-1 {\n";
    $css .= "    font-size: 3rem;\n";
    $css .= "}\n\n";
    
    $css .= ".subtitle.is-4 {\n";
    $css .= "    font-size: 1.5rem;\n";
    $css .= "}\n\n";
    
    $css .= ".mt-3 {\n";
    $css .= "    margin-top: 0.75rem;\n";
    $css .= "}\n\n";
    
    $css .= ".has-text-centered {\n";
    $css .= "    text-align: center;\n";
    $css .= "}\n\n";

    # Cards
    $css .= "/* Cards */\n";
    $css .= ".card-home {\n";
    $css .= "    border-radius: 6px;\n";
    $css .= "    box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1), 0 0 0 1px rgba(10, 10, 10, 0.02);\n";
    $css .= "    background-color: white;\n";
    $css .= "    margin-bottom: 1.5rem;\n";
    $css .= "}\n\n";
    
    $css .= ".card-content {\n";
    $css .= "    padding: 1.5rem;\n";
    $css .= "}\n\n";
    
    $css .= ".content.has-text-centered {\n";
    $css .= "    text-align: center;\n";
    $css .= "}\n\n";
    
    $css .= ".title.is-5 {\n";
    $css .= "    font-size: 1.25rem;\n";
    $css .= "    margin-bottom: 0.5rem;\n";
    $css .= "}\n\n";
    
    $css .= ".has-text-primary {\n";
    $css .= "    color: #00d1b2 !important;\n";
    $css .= "}\n\n";
    
    $css .= ".icon.is-large {\n";
    $css .= "    font-size: 2rem;\n";
    $css .= "}\n\n";
    
    $css .= ".button.is-primary {\n";
    $css .= "    background-color: #00d1b2;\n";
    $css .= "    border-color: transparent;\n";
    $css .= "    color: #fff;\n";
    $css .= "}\n\n";

    # Links Block
    $css .= "/* Links Block */\n";
    $css .= ".raku.links-block {\n";
    $css .= "    background-color: #f5f5f5;\n";
    $css .= "    padding: 2rem 0;\n";
    $css .= "}\n\n";
    
    $css .= ".columns.is-vcentered {\n";
    $css .= "    align-items: center;\n";
    $css .= "}\n\n";
    
    $css .= ".column.is-one-third {\n";
    $css .= "    flex: none;\n";
    $css .= "    width: 33.3333%;\n";
    $css .= "}\n\n";
    
    $css .= ".column.is-two-thirds {\n";
    $css .= "    flex: none;\n";
    $css .= "    width: 66.6666%;\n";
    $css .= "}\n\n";
    
    $css .= ".pt-5 {\n";
    $css .= "    padding-top: 1.5rem;\n";
    $css .= "}\n\n";
    
    $css .= ".head {\n";
    $css .= "    font-weight: bold;\n";
    $css .= "    margin-bottom: 0.5rem;\n";
    $css .= "}\n\n";

    # Footer
    $css .= "/* Footer */\n";
    $css .= ".footer.main-footer {\n";
    $css .= "    background-color: #fafafa;\n";
    $css .= "    padding: 3rem 1.5rem;\n";
    $css .= "}\n\n";
    
    $css .= ".level {\n";
    $css .= "    display: flex;\n";
    $css .= "    justify-content: space-between;\n";
    $css .= "    align-items: center;\n";
    $css .= "}\n\n";
    
    $css .= ".level-left, .level-right {\n";
    $css .= "    display: flex;\n";
    $css .= "    align-items: center;\n";
    $css .= "}\n\n";
    
    $css .= ".level-item {\n";
    $css .= "    margin: 0 0.5rem;\n";
    $css .= "}\n\n";

    # Responsive Adjustments
    $css .= "/* Responsive Adjustments */\n";
    $css .= "\@media screen and (max-width: 1023px) {\n";
    $css .= "    .navbar-menu {\n";
    $css .= "        background-color: white;\n";
    $css .= "        box-shadow: 0 8px 16px rgba(10, 10, 10, 0.1);\n";
    $css .= "        padding: 0.5rem 0;\n";
    $css .= "    }\n";
    $css .= "    \n";
    $css .= "    .navbar-menu.is-active {\n";
    $css .= "        display: block;\n";
    $css .= "    }\n";
    $css .= "    \n";
    $css .= "    .navbar-end {\n";
    $css .= "        margin-top: 1rem;\n";
    $css .= "    }\n";
    $css .= "}\n\n";
    
    $css .= "\@media screen and (max-width: 768px) {\n";
    $css .= "    .title.is-1.is-size-2-mobile {\n";
    $css .= "        font-size: 2rem;\n";
    $css .= "    }\n";
    $css .= "    \n";
    $css .= "    .columns.is-multiline {\n";
    $css .= "        display: flex;\n";
    $css .= "        flex-wrap: wrap;\n";
    $css .= "    }\n";
    $css .= "    \n";
    $css .= "    .column.is-one-half, \n";
    $css .= "    .column.is-one-third {\n";
    $css .= "        width: 100%;\n";
    $css .= "    }\n";
    $css .= "    \n";
    $css .= "    .raku.links-block .columns {\n";
    $css .= "        flex-direction: column;\n";
    $css .= "    }\n";
    $css .= "    \n";
    $css .= "    .column.is-one-third, \n";
    $css .= "    .column.is-two-thirds {\n";
    $css .= "        width: 100%;\n";
    $css .= "    }\n";
    $css .= "}\n";

    return $css;
}

sub write_css_to_file {
    my ($filename) = @_;
    my $css_content = generate_css();
    
    open(my $fh, '>', $filename) or die "Konnte Datei '$filename' nicht öffnen: $!";
    print $fh $css_content;
    close($fh);
}

# Hauptprogramm
if (@ARGV != 1) {
    die "Verwendung: $0 <ausgabedatei>\n";
}

my $output_file = $ARGV[0];
write_css_to_file($output_file);
print "CSS wurde erfolgreich in '$output_file' geschrieben.\n";
