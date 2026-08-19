#!/usr/bin/env tclsh8.6
# scrape_to_markdown.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/web-markdown-scraper/scripts/scrape_to_markdown.py
# auch in: OpenClaw@gateway2:skills/web-markdown-scraper/scripts/scrape_to_markdown.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

package require http
package require json
package require fileutil
package require uri

proc to_str {value} {
    if {$value eq "" || $value eq "null"} {
        return ""
    }
    return [string trim $value]
}

proc slugify {text {max_len 80}} {
    regsub -all {[^[:alnum:] _-]} [string tolower [string trim $text]] "" cleaned
    regsub -all {[ _-]+} $cleaned "-" slug
    set slug [string range $slug 0 [expr {$max_len - 1}]]
    while {[string match "*-" $slug]} {
        set slug [string range $slug 0 end-1]
    }
    while {[string match "-*" $slug]} {
        set slug [string range $slug 1 end]
    }
    if {$slug eq ""} {
        set slug "page"
    }
    return $slug
}

proc extract_html {obj} {
    if {$obj eq ""} {
        return ""
    }
    
    foreach attr {html raw_html content markup body inner_html} {
        if {[info exists obj($attr)]} {
            set value $obj($attr)
            if {[string match "*<*>" $value] && [string match "*>*<" $value]} {
                return $value
            }
        }
    }
    
    if {[string match "*<*>" $obj] && [string match "*>*<" $obj]} {
        return $obj
    }
    return ""
}

proc extract_title {html} {
    if {[regexp -nocase {<title[^>]*>(.*?)</title>} $html match title_content]} {
        regsub -all {<[^>]+>} $title_content " " title_clean
        regsub -all {\s+} [string trim $title_clean] " " title_final
        return [string trim $title_final]
    }
    return ""
}

proc fetch_page {url {js false} {wait_selector ""} {timeout 30} {automatch_domain ""}} {
    set token [http::geturl $url -timeout [expr {$timeout * 1000}]]
    set status [http::status $token]
    set code [http::ncode $token]
    set data [http::data $token]
    http::cleanup $token
    
    if {$status ne "ok"} {
        error "Failed to fetch $url: $status"
    }
    
    array set page {}
    set page(content) $data
    set page(status) $code
    set page(raw_html) $data
    
    return [list [array get page] "http.geturl"]
}

proc pick_main_html {page_array {preferred_selector ""}} {
    upvar $page_array page
    
    set selectors {}
    if {$preferred_selector ne ""} {
        lappend selectors $preferred_selector
    }
    foreach sel {article main "[role='main']" .post-content .entry-content .article-content body} {
        lappend selectors $sel
    }
    
    set html [extract_html [array get page]]
    if {$html eq ""} {
        return [list "" ""]
    }
    
    # For simplicity, we just return the full HTML since TCL doesn't have CSS selection capabilities built-in
    return [list $html "body"]
}

proc html_to_markdown {html {preserve_links false} {body_width 0}} {
    # Simple HTML to Markdown conversion
    set md $html
    
    # Remove script and style tags
    regsub -all {(?i)<(script|style)[^>]*>.*?</\1>} $md "" md
    
    # Convert headers
    regsub -all -nocase {<h1[^>]*>(.*?)</h1>} $md {"# " . [regsub -all {<[^>]+>} {\1} ""]} md
    regsub -all -nocase {<h2[^>]*>(.*?)</h2>} $md {"## " . [regsub -all {<[^>]+>} {\1} ""]} md
    regsub -all -nocase {<h3[^>]*>(.*?)</h3>} $md {"### " . [regsub -all {<[^>]+>} {\1} ""]} md
    regsub -all -nocase {<h4[^>]*>(.*?)</h4>} $md {"#### " . [regsub -all {<[^>]+>} {\1} ""]} md
    regsub -all -nocase {<h5[^>]*>(.*?)</h5>} $md {"##### " . [regsub -all {<[^>]+>} {\1} ""]} md
    regsub -all -nocase {<h6[^>]*>(.*?)</h6>} $md {"###### " . [regsub -all {<[^>]+>} {\1} ""]} md
    
    # Convert paragraphs
    regsub -all -nocase {<p[^>]*>(.*?)</p>} $md {"\n" . [regsub -all {<[^>]+>} {\1} ""] . "\n"} md
    
    # Convert links
    if {$preserve_links} {
        regsub -all -nocase {<a[^>]+href=["']([^"']+)["'][^>]*>(.*?)</a>} $md {"[" . [regsub -all {<[^>]+>} {\2} ""] . "](" . \1 . ")"} md
    } else {
        regsub -all -nocase {<a[^>]+href=["']([^"']+)["'][^>]*>(.*?)</a>} $md {[regsub -all {<[^>]+>} {\2} ""]} md
    }
    
    # Convert bold/strong
    regsub -all -nocase {<(b|strong)[^>]*>(.*?)</\1>} $md {"**" . [regsub -all {<[^>]+>} {\2} ""] . "**"} md
    
    # Convert italic/em
    regsub -all -nocase {<(i|em)[^>]*>(.*?)</\1>} $md {"*" . [regsub -all {<[^>]+>} {\2} ""] . "*"} md
    
    # Convert lists
    regsub -all -nocase {<ul[^>]*>(.*?)</ul>} $md {"\n" . [regsub -all {<li[^>]*>(.*?)</li>} {\1\n} \1]} md
    regsub -all -nocase {<ol[^>]*>(.*?)</ol>} $md {"\n" . [regsub -all {<li[^>]*>(.*?)</li>} {\1\n} \1]} md
    
    # Remove remaining HTML tags
    regsub -all {<[^>]+>} $md "" md
    
    # Clean up extra whitespace
    regsub -all {\n{3,}} $md "\n\n" md
    return [string trim $md]
}

proc load_urls {url_args url_file} {
    set urls $url_args
    if {$url_file ne ""} {
        set fh [open $url_file r]
        while {[gets $fh line] >= 0} {
            set line [string trim $line]
            if {$line ne "" && ![string match "#*" $line]} {
                lappend urls $line
            }
        }
        close $fh
    }
    
    set clean {}
    array set seen {}
    foreach u $urls {
        if {![info exists seen($u)]} {
            lappend clean $u
            set seen($u) 1
        }
    }
    return $clean
}

proc validate_url {url} {
    if {[catch {set parsed [uri::split $url]}]} {
        return false
    }
    array set parts $parsed
    if {![info exists parts(scheme)] || ![info exists parts(host)]} {
        return false
    }
    set scheme [string tolower $parts(scheme)]
    return [expr {$scheme eq "http" || $scheme eq "https"}]
}

proc main {} {
    global argv
    
    set urls {}
    set url_file ""
    set selector ""
    set js false
    set wait_selector ""
    set preserve_links false
    set body_width 0
    set timeout 30
    set output_dir "outputs"
    set automatch_domain ""
    
    # Parse arguments manually
    set i 0
    while {$i < [llength $argv]} {
        set arg [lindex $argv $i]
        incr i
        
        switch -exact -- $arg {
            "--url" {
                if {$i < [llength $argv]} {
                    lappend urls [lindex $argv $i]
                    incr i
                }
            }
            "--url-file" {
                if {$i < [llength $argv]} {
                    set url_file [lindex $argv $i]
                    incr i
                }
            }
            "--selector" {
                if {$i < [llength $argv]} {
                    set selector [lindex $argv $i]
                    incr i
                }
            }
            "--js" {
                set js true
            }
            "--wait-selector" {
                if {$i < [llength $argv]} {
                    set wait_selector [lindex $argv $i]
                    incr i
                }
            }
            "--preserve-links" {
                set preserve_links true
            }
            "--body-width" {
                if {$i < [llength $argv]} {
                    set body_width [lindex $argv $i]
                    incr i
                }
            }
            "--timeout" {
                if {$i < [llength $argv]} {
                    set timeout [lindex $argv $i]
                    incr i
                }
            }
            "--output-dir" {
                if {$i < [llength $argv]} {
                    set output_dir [lindex $argv $i]
                    incr i
                }
            }
            "--automatch-domain" {
                if {$i < [llength $argv]} {
                    set automatch_domain [lindex $argv $i]
                    incr i
                }
            }
        }
    }
    
    set urls [load_urls $urls $url_file]
    if {[llength $urls] == 0} {
        puts [json::write object ok false error "No URLs provided"]
        exit 1
    }
    
    foreach u $urls {
        if {![validate_url $u]} {
            puts [json::write object ok false error "Invalid URL: $u"]
            exit 1
        }
    }
    
    file mkdir $output_dir
    
    set results {}
    
    foreach url $urls {
        array set item {}
        set item(url) $url
        set item(ok) false
        set item(title) ""
        set item(status) ""
        set item(selector_used) ""
        set item(backend) ""
        set item(markdown) ""
        set item(preview) ""
        set item(output_markdown_file) ""
        set item(error) ""
        
        if {[catch {
            foreach {page_data backend} [fetch_page $url $js $wait_selector $timeout $automatch_domain] break
            array set page $page_data
            
            foreach {html selector_used} [pick_main_html page $selector] break
            if {$html eq ""} {
                error "No HTML content extracted from page"
            }
            
            set title [extract_title $html]
            if {$title eq ""} {
                set parsed [uri::split $url]
                array set parts $parsed
                set title $parts(host)
            }
            
            set markdown [html_to_markdown $html $preserve_links $body_width]
            
            set filename [slugify "${parts(host)}-${title}"].md
            set md_path [file join $output_dir $filename]
            set fh [open $md_path w]
            puts $fh $markdown
            close $fh
            
            set item(ok) true
            set item(title) $title
            set item(status) $page(status)
            set item(selector_used) $selector_used
            set item(backend) $backend
            set item(markdown) $markdown
            set item(preview) [string range $markdown 0 1199]
            set item(output_markdown_file) $md_path
        } errmsg]} {
            set item(error) $errmsg
        }
        
        lappend results [array get item]
    }
    
    set ok false
    set success_count 0
    set failure_count 0
    
    set processed_results {}
    foreach result $results {
        array set item $result
        if {$item(ok)} {
            set ok true
            incr success_count
        } else {
            incr failure_count
        }
        lappend processed_results [array get item]
    }
    
    set index_path [file join $output_dir "index.json"]
    set payload [json::write object \
        ok $ok \
        count [llength $results] \
        success_count $success_count \
        failure_count $failure_count \
        output_index_file $index_path \
        results $processed_results]
    
    set fh [open $index_path w]
    puts $fh $payload
    close $fh
    
    puts $payload
}

if {[info script] eq $argv0} {
    main
}
