#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "02e71abe94ca8fd28ef308e160ef05320589c682d2b11b39fe97af4439bfcc35", "source_sha256": "b53b17806f268da8dc7115668f5a04c5ff39edd9b2305ba40f1b04e598002f81", "target_language": "tcl"}
# index_5f1051.css — portiert nach tcl
# Quelle: css, Projects@abstractions:css/index_5f1051.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# Abstraction provenance: {"artifact_sha256": "cdcc9e9ffa451d8c92fd763b0dfd0b1974003a826baaae753e2f347cfd3c9f57", "source_sha256": "5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988", "target_language": "tcl"}
# index.html — portiert nach tcl
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

proc generate_css {} {
    set css ""

    # body styles
    append css "body {\n"
    append css "    background-color: white;\n"
    append css "    color: black;\n"
    append css "    margin: 0;\n"
    append css "    padding: 0;\n"
    append css "    font-family: Arial, sans-serif;\n"
    append css "}\n\n"

    # table styles
    append css "table {\n"
    append css "    border-collapse: collapse;\n"
    append css "}\n\n"

    # globalnav-container styles
    append css ".globalnav-container {\n"
    append css "    width: 780px;\n"
    append css "    border: 0;\n"
    append css "    cellpadding: 0;\n"
    append css "    cellspacing: 0;\n"
    append css "}\n\n"

    # header-left styles
    append css ".header-left {\n"
    append css "    vertical-align: top;\n"
    append css "    text-align: left;\n"
    append css "}\n\n"

    # header-right styles
    append css ".header-right {\n"
    append css "    vertical-align: top;\n"
    append css "    text-align: right;\n"
    append css "}\n\n"

    # logo-link styles
    append css ".logo-link {\n"
    append css "    text-decoration: none;\n"
    append css "    border: 0;\n"
    append css "}\n\n"

    # logo-image styles
    append css ".logo-image {\n"
    append css "    border: 0;\n"
    append css "}\n\n"

    # hosted-by styles
    append css ".hosted-by {\n"
    append css "    font-size: 1px;\n"
    append css "    text-decoration: none;\n"
    append css "}\n\n"

    # active-state-logo styles
    append css ".active-state-logo {\n"
    append css "    border: 0;\n"
    append css "    title: \"This site is hosted by ActiveState\";\n"
    append css "}\n\n"

    # globalnav styles
    append css "#globalnav {\n"
    append css "    clear: both;\n"
    append css "}\n\n"

    # globalnav ul styles
    append css "#globalnav ul {\n"
    append css "    list-style-type: none;\n"
    append css "    margin: 0;\n"
    append css "    padding: 0;\n"
    append css "    overflow: hidden;\n"
    append css "}\n\n"

    # globalnav li styles
    append css "#globalnav li {\n"
    append css "    float: left;\n"
    append css "}\n\n"

    # globalnav a styles
    append css "#globalnav a {\n"
    append css "    display: block;\n"
    append css "    padding: 8px 16px;\n"
    append css "    text-decoration: none;\n"
    append css "    color: #000;\n"
    append css "}\n\n"

    # globalnav a.here styles
    append css "#globalnav a.here {\n"
    append css "    background-color: #3163CE;\n"
    append css "    color: white;\n"
    append css "}\n\n"

    # divider-top styles
    append css ".divider-top {\n"
    append css "    border-top: 2px solid #3163CE;\n"
    append css "    width: 780px;\n"
    append css "}\n\n"

    # search-table styles
    append css ".search-table {\n"
    append css "    width: 780px;\n"
    append css "    border: 0;\n"
    append css "    cellpadding: 2;\n"
    append css "    cellspacing: 0;\n"
    append css "}\n\n"

    # search-container styles
    append css ".search-container {\n"
    append css "    display: table-cell;\n"
    append css "    vertical-align: middle;\n"
    append css "    margin: 0px;\n"
    append css "}\n\n"

    # search-form styles
    append css ".search-form {\n"
    append css "    display: inline;\n"
    append css "}\n\n"

    # search-input styles
    append css ".search-input {\n"
    append css "    size: 20;\n"
    append css "    maxlength: 255;\n"
    append css "    value: \"\";\n"
    append css "}\n\n"

    # submit-button styles
    append css ".submit-button {\n"
    append css "    border: 0;\n"
    append css "}\n\n"

    # hidden-input styles
    append css ".hidden-input {\n"
    append css "    display: none;\n"
    append css "}\n\n"

    # banner styles
    append css ".banner {\n"
    append css "    text-align: right;\n"
    append css "    font-weight: bold;\n"
    append css "    margin: 0;\n"
    append css "}\n\n"

    # divider-yellow styles
    append css ".divider-yellow {\n"
    append css "    border-top: 1px solid #FFCE00;\n"
    append css "    margin-bottom: 2px;\n"
    append css "    width: 780px;\n"
    append css "}\n\n"

    # content-table styles
    append css ".content-table {\n"
    append css "    width: 780px;\n"
    append css "    border: 0;\n"
    append css "    cellpadding: 0;\n"
    append css "    cellspacing: 0;\n"
    append css "}\n\n"

    # keylist styles
    append css ".keylist {\n"
    append css "    margin: 0;\n"
    append css "    padding: 0;\n"
    append css "}\n\n"

    # keylist dt styles
    append css ".keylist dt {\n"
    append css "    font-weight: bold;\n"
    append css "    margin-top: 10px;\n"
    append css "}\n\n"

    # keylist dd styles
    append css ".keylist dd {\n"
    append css "    margin-left: 20px;\n"
    append css "    margin-bottom: 10px;\n"
    append css "}\n\n"

    # footer styles
    append css ".footer {\n"
    append css "    text-align: center;\n"
    append css "    clear: both;\n"
    append css "}\n\n"

    # footer small styles
    append css ".footer small {\n"
    append css "    font-size: 12px;\n"
    append css "}\n\n"

    # footer a styles
    append css ".footer a {\n"
    append css "    text-decoration: none;\n"
    append css "    color: #000;\n"
    append css "}\n\n"

    # footer a:hover styles
    append css ".footer a:hover {\n"
    append css "    text-decoration: underline;\n"
    append css "}\n\n"

    # clear styles
    append css ".clear {\n"
    append css "    clear: both;\n"
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
    puts stderr "Error: Could not open file '$output_file' for writing"
    exit 1
}

puts $file_handle $css_content
close $file_handle

puts "CSS file generated successfully: $output_file"
