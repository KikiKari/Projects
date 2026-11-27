#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "018a82b18eb09d736f5fc546f0080b66c61ddcad9e0ff7db2914b759226bda86", "source_sha256": "b32c733987d23de98ace1b2a5119f7cb7989a0887c165c1db133ecb4ef278438", "target_language": "tcl"}
# index_f17dea.css — portiert nach tcl
# Quelle: css, Projects@abstractions:css/index_f17dea.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# Abstraction provenance: {"artifact_sha256": "9ebfdd610ffe88b7273a5ac8e215314a7bee0dffecf25fe9a995b6a39703e204", "source_sha256": "f17deae3e31b89fd76d250bd20903b36591af417c97b34d987e923632be9ac37", "target_language": "tcl"}
# index.html — portiert nach css
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/raku/index.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/raku/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

proc generate_css {} {
    set css ""

    # General Styles
    append css "/* General Styles */\n"
    append css "html {\n"
    append css "    scroll-padding-top: 60px;\n"
    append css "}\n\n"
    
    append css "body.has-navbar-fixed-top {\n"
    append css "    padding-top: 60px;\n"
    append css "}\n\n"

    # Navbar Styles
    append css "/* Navbar Styles */\n"
    append css ".navbar.is-fixed-top {\n"
    append css "    position: fixed;\n"
    append css "    top: 0;\n"
    append css "    left: 0;\n"
    append css "    right: 0;\n"
    append css "    z-index: 30;\n"
    append css "    min-height: 3.25rem;\n"
    append css "}\n\n"
    
    append css ".navbar.is-flex-touch {\n"
    append css "    display: flex;\n"
    append css "}\n\n"
    
    append css ".container.is-justify-content-space-around {\n"
    append css "    justify-content: space-around;\n"
    append css "}\n\n"
    
    append css ".navbar-brand {\n"
    append css "    display: flex;\n"
    append css "    align-items: center;\n"
    append css "}\n\n"
    
    append css ".navbar-logo {\n"
    append css "    display: flex;\n"
    append css "    align-items: center;\n"
    append css "}\n\n"
    
    append css ".navbar-logo-tm {\n"
    append css "    font-size: 0.75rem;\n"
    append css "    margin-left: 0.25rem;\n"
    append css "}\n\n"
    
    append css ".navbar-burger {\n"
    append css "    display: block;\n"
    append css "    position: relative;\n"
    append css "    cursor: pointer;\n"
    append css "}\n\n"
    
    append css ".navbar-burger span {\n"
    append css "    display: block;\n"
    append css "    height: 1px;\n"
    append css "    width: 20px;\n"
    append css "    background-color: currentColor;\n"
    append css "    margin: 5px 0;\n"
    append css "    transition: transform 0.3s ease;\n"
    append css "}\n\n"
    
    append css ".navbar-menu {\n"
    append css "    display: none;\n"
    append css "}\n\n"
    
    append css ".navbar-start, .navbar-end {\n"
    append css "    display: flex;\n"
    append css "    align-items: center;\n"
    append css "}\n\n"
    
    append css ".navbar-item {\n"
    append css "    display: block;\n"
    append css "    padding: 0.5rem 0.75rem;\n"
    append css "}\n\n"
    
    append css ".navbar-link {\n"
    append css "    display: block;\n"
    append css "    padding: 0.5rem 0.75rem;\n"
    append css "}\n\n"
    
    append css ".navbar-dropdown {\n"
    append css "    display: none;\n"
    append css "    position: absolute;\n"
    append css "    top: 100%;\n"
    append css "    left: 0;\n"
    append css "    background-color: white;\n"
    append css "    border-radius: 4px;\n"
    append css "    box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1);\n"
    append css "}\n\n"
    
    append css ".navbar-dropdown.is-right {\n"
    append css "    left: auto;\n"
    append css "    right: 0;\n"
    append css "}\n\n"
    
    append css ".navbar-dropdown.is-rounded {\n"
    append css "    border-radius: 4px;\n"
    append css "}\n\n"
    
    append css ".navbar-divider {\n"
    append css "    display: block;\n"
    append css "    height: 1px;\n"
    append css "    background-color: #dbdbdb;\n"
    append css "    margin: 0.5rem 0;\n"
    append css "}\n\n"
    
    append css ".has-dropdown:hover .navbar-dropdown {\n"
    append css "    display: block;\n"
    append css "}\n\n"
    
    append css ".navbar-search-wrapper {\n"
    append css "    display: flex;\n"
    append css "    align-items: center;\n"
    append css "}\n\n"
    
    append css ".field.has-addons {\n"
    append css "    display: flex;\n"
    append css "}\n\n"
    
    append css ".control {\n"
    append css "    position: relative;\n"
    append css "}\n\n"
    
    append css ".autoComplete_options {\n"
    append css "    flex-grow: 1;\n"
    append css "}\n\n"
    
    append css ".input {\n"
    append css "    display: block;\n"
    append css "    width: 100%;\n"
    append css "    padding: 0.375rem 0.75rem;\n"
    append css "    font-size: 1rem;\n"
    append css "    line-height: 1.5;\n"
    append css "    color: #495057;\n"
    append css "    background-color: #fff;\n"
    append css "    background-clip: padding-box;\n"
    append css "    border: 1px solid #ced4da;\n"
    append css "    border-radius: 0.25rem;\n"
    append css "    transition: border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;\n"
    append css "}\n\n"
    
    append css ".button.is-primary {\n"
    append css "    background-color: #00d1b2;\n"
    append css "    border-color: transparent;\n"
    append css "    color: #fff;\n"
    append css "}\n\n"
    
    append css ".icon {\n"
    append css "    display: inline-flex;\n"
    append css "    justify-content: center;\n"
    append css "    align-items: center;\n"
    append css "}\n\n"
    
    append css ".modal {\n"
    append css "    position: fixed;\n"
    append css "    top: 0;\n"
    append css "    left: 0;\n"
    append css "    right: 0;\n"
    append css "    bottom: 0;\n"
    append css "    z-index: 40;\n"
    append css "    display: none;\n"
    append css "    opacity: 0;\n"
    append css "    transition: opacity 0.15s linear;\n"
    append css "}\n\n"
    
    append css ".modal.is-active {\n"
    append css "    display: flex;\n"
    append css "    opacity: 1;\n"
    append css "}\n\n"
    
    append css ".modal-background {\n"
    append css "    position: absolute;\n"
    append css "    top: 0;\n"
    append css "    left: 0;\n"
    append css "    right: 0;\n"
    append css "    bottom: 0;\n"
    append css "    background-color: rgba(10, 10, 10, 0.86);\n"
    append css "}\n\n"
    
    append css ".modal-content {\n"
    append css "    position: relative;\n"
    append css "    width: 100%;\n"
    append css "    max-height: calc(100vh - 160px);\n"
    append css "    overflow: auto;\n"
    append css "    margin: 0 auto;\n"
    append css "    padding: 20px;\n"
    append css "}\n\n"
    
    append css ".box {\n"
    append css "    background-color: white;\n"
    append css "    border-radius: 6px;\n"
    append css "    box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1), 0 0 0 1px rgba(10, 10, 10, 0.02);\n"
    append css "    padding: 1.25rem;\n"
    append css "}\n\n"
    
    append css ".modal-close {\n"
    append css "    position: absolute;\n"
    append css "    top: 20px;\n"
    append css "    right: 20px;\n"
    append css "    width: 40px;\n"
    append css "    height: 40px;\n"
    append css "    background: none;\n"
    append css "    border: none;\n"
    append css "    cursor: pointer;\n"
    append css "}\n\n"
    
    append css ".options-search-controls {\n"
    append css "    display: flex;\n"
    append css "    flex-direction: column;\n"
    append css "    gap: 1rem;\n"
    append css "}\n\n"
    
    append css ".centreToggle {\n"
    append css "    display: flex;\n"
    append css "    align-items: center;\n"
    append css "    gap: 0.5rem;\n"
    append css "}\n\n"
    
    append css ".centreToggle input[type=\"checkbox\"] {\n"
    append css "    width: var(--switch-width, 10.5em);\n"
    append css "    height: 2em;\n"
    append css "    appearance: none;\n"
    append css "    background: #ccc;\n"
    append css "    border-radius: 1em;\n"
    append css "    position: relative;\n"
    append css "    cursor: pointer;\n"
    append css "}\n\n"
    
    append css ".centreToggle input[type=\"checkbox\"]:checked {\n"
    append css "    background: #00d1b2;\n"
    append css "}\n\n"
    
    append css ".centreToggle input[type=\"checkbox\"]::before {\n"
    append css "    content: '';\n"
    append css "    position: absolute;\n"
    append css "    width: 1.6em;\n"
    append css "    height: 1.6em;\n"
    append css "    background: white;\n"
    append css "    border-radius: 50%;\n"
    append css "    top: 0.2em;\n"
    append css "    left: 0.2em;\n"
    append css "    transition: transform 0.3s;\n"
    append css "}\n\n"
    
    append css ".centreToggle input[type=\"checkbox\"]:checked::before {\n"
    append css "    transform: translateX(calc(var(--switch-width, 10.5em) - 2em));\n"
    append css "}\n\n"
    
    append css ".centreToggle .text,\n"
    append css ".centreToggle .on,\n"
    append css ".centreToggle .off {\n"
    append css "    font-weight: bold;\n"
    append css "}\n\n"
    
    append css ".centreToggle .on,\n"
    append css ".centreToggle .off {\n"
    append css "    position: absolute;\n"
    append css "    top: 50%;\n"
    append css "    transform: translateY(-50%);\n"
    append css "}\n\n"
    
    append css ".centreToggle .on {\n"
    append css "    left: 0.5em;\n"
    append css "    color: white;\n"
    append css "}\n\n"
    
    append css ".centreToggle .off {\n"
    append css "    right: 0.5em;\n"
    append css "    color: #333;\n"
    append css "}\n\n"

    # Hero Section
    append css "/* Hero Section */\n"
    append css ".hero.is-medium {\n"
    append css "    min-height: 300px;\n"
    append css "}\n\n"
    
    append css ".hero.is-primary {\n"
    append css "    background-color: #00d1b2;\n"
    append css "    color: #fff;\n"
    append css "}\n\n"
    
    append css ".hero-body {\n"
    append css "    padding: 3rem 1.5rem;\n"
    append css "}\n\n"
    
    append css ".title.is-1 {\n"
    append css "    font-size: 3rem;\n"
    append css "}\n\n"
    
    append css ".subtitle.is-4 {\n"
    append css "    font-size: 1.5rem;\n"
    append css "}\n\n"
    
    append css ".mt-3 {\n"
    append css "    margin-top: 0.75rem;\n"
    append css "}\n\n"
    
    append css ".has-text-centered {\n"
    append css "    text-align: center;\n"
    append css "}\n\n"

    # Cards
    append css "/* Cards */\n"
    append css ".card-home {\n"
    append css "    border-radius: 6px;\n"
    append css "    box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1), 0 0 0 1px rgba(10, 10, 10, 0.02);\n"
    append css "    background-color: white;\n"
    append css "    margin-bottom: 1.5rem;\n"
    append css "}\n\n"
    
    append css ".card-content {\n"
    append css "    padding: 1.5rem;\n"
    append css "}\n\n"
    
    append css ".content.has-text-centered {\n"
    append css "    text-align: center;\n"
    append css "}\n\n"
    
    append css ".title.is-5 {\n"
    append css "    font-size: 1.25rem;\n"
    append css "    margin-bottom: 0.5rem;\n"
    append css "}\n\n"
    
    append css ".has-text-primary {\n"
    append css "    color: #00d1b2 !important;\n"
    append css "}\n\n"
    
    append css ".icon.is-large {\n"
    append css "    font-size: 2rem;\n"
    append css "}\n\n"
    
    append css ".button.is-primary {\n"
    append css "    background-color: #00d1b2;\n"
    append css "    border-color: transparent;\n"
    append css "    color: #fff;\n"
    append css "}\n\n"

    # Links Block
    append css "/* Links Block */\n"
    append css ".raku.links-block {\n"
    append css "    background-color: #f5f5f5;\n"
    append css "    padding: 2rem 0;\n"
    append css "}\n\n"
    
    append css ".columns.is-vcentered {\n"
    append css "    align-items: center;\n"
    append css "}\n\n"
    
    append css ".column.is-one-third {\n"
    append css "    flex: none;\n"
    append css "    width: 33.3333%;\n"
    append css "}\n\n"
    
    append css ".column.is-two-thirds {\n"
    append css "    flex: none;\n"
    append css "    width: 66.6666%;\n"
    append css "}\n\n"
    
    append css ".pt-5 {\n"
    append css "    padding-top: 1.5rem;\n"
    append css "}\n\n"
    
    append css ".head {\n"
    append css "    font-weight: bold;\n"
    append css "    margin-bottom: 0.5rem;\n"
    append css "}\n\n"

    # Footer
    append css "/* Footer */\n"
    append css ".footer.main-footer {\n"
    append css "    background-color: #fafafa;\n"
    append css "    padding: 3rem 1.5rem;\n"
    append css "}\n\n"
    
    append css ".level {\n"
    append css "    display: flex;\n"
    append css "    justify-content: space-between;\n"
    append css "    align-items: center;\n"
    append css "}\n\n"
    
    append css ".level-left, .level-right {\n"
    append css "    display: flex;\n"
    append css "    align-items: center;\n"
    append css "}\n\n"
    
    append css ".level-item {\n"
    append css "    margin: 0 0.5rem;\n"
    append css "}\n\n"

    # Responsive Adjustments
    append css "/* Responsive Adjustments */\n"
    append css "@media screen and (max-width: 1023px) {\n"
    append css "    .navbar-menu {\n"
    append css "        background-color: white;\n"
    append css "        box-shadow: 0 8px 16px rgba(10, 10, 10, 0.1);\n"
    append css "        padding: 0.5rem 0;\n"
    append css "    }\n"
    append css "    \n"
    append css "    .navbar-menu.is-active {\n"
    append css "        display: block;\n"
    append css "    }\n"
    append css "    \n"
    append css "    .navbar-end {\n"
    append css "        margin-top: 1rem;\n"
    append css "    }\n"
    append css "}\n\n"
    
    append css "@media screen and (max-width: 768px) {\n"
    append css "    .title.is-1.is-size-2-mobile {\n"
    append css "        font-size: 2rem;\n"
    append css "    }\n"
    append css "    \n"
    append css "    .columns.is-multiline {\n"
    append css "        display: flex;\n"
    append css "        flex-wrap: wrap;\n"
    append css "    }\n"
    append css "    \n"
    append css "    .column.is-one-half, \n"
    append css "    .column.is-one-third {\n"
    append css "        width: 100%;\n"
    append css "    }\n"
    append css "    \n"
    append css "    .raku.links-block .columns {\n"
    append css "        flex-direction: column;\n"
    append css "    }\n"
    append css "    \n"
    append css "    .column.is-one-third, \n"
    append css "    .column.is-two-thirds {\n"
    append css "        width: 100%;\n"
    append css "    }\n"
    append css "}\n"

    return $css
}

# Main execution
if {$argc != 1} {
    puts stderr "Usage: $argv0 <output-file>"
    exit 1
}

set output_file [lindex $argv 0]
set css_content [generate_css]

if {[catch {open $output_file w} file_handle]} {
    puts stderr "Error: Could not open file '$output_file' for writing."
    exit 1
}

puts $file_handle $css_content
close $file_handle

puts "CSS file generated successfully: $output_file"
