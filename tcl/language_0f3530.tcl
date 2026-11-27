#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "410720b71512495bb2317280b9e1bf6993bd9562a18bbe1f8c259199a0725b13", "source_sha256": "0f3530ed5a95fa71241e65119ede0362d09d6dbde8fbabfc84d844298613edb6", "target_language": "tcl"}
# language.html — portiert nach tcl
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/raku/language.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/raku/language.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# Tcl script to generate the 404 error page HTML
# Usage: tclsh this_script.tcl output_file.html

if {$argc != 1} {
    puts stderr "Usage: $argv0 output_file.html"
    exit 1
}

set output_file [lindex $argv 0]

# Open file for writing
set fh [open $output_file w]

# Write DOCTYPE and html tag
puts $fh {<!DOCTYPE html>}
puts $fh {<html lang="en" class="fontawesome-i2svg-active fontawesome-i2svg-complete" style="scroll-padding-top:60px">}

# Head section
puts $fh {<head>}
puts $fh {    <title>404 | Raku Documentation</title>}
puts $fh {    <meta charset="UTF-8" />}
puts $fh {}
puts $fh {<link href="/assets/images/Camelia.ico" rel="icon" type="image/x-icon"/>}
puts $fh {}
puts $fh {<link rel="stylesheet" href="/assets/css/Website.css"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/css/filtered-toc-dark.css" title="dark"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/css/filtered-toc-light.css" title="light"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/css/rainbow-dark.css" title="dark"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/css/rainbow-light.css" title="light"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/tm-styling.css"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/tm-light.css" title="light"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/tm-dark.css" title="dark"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/all.min.css"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/listf-styling-light.css" title="light"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/listf-styling-dark.css" title="dark"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/typegraph-styling.css"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/typegraph-dark.css" title="dark"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/typegraph-light.css" title="light"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/css/page-styling-main.css"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/css/page-styling-dark.css" title="dark"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/css/page-styling-light.css" title="light"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/css/chyronToggle-dark.css" title="dark"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/css/chyronToggle-light.css" title="light"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/css/centreToggle-dark.css" title="dark"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/css/centreToggle-light.css" title="light"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/css/options-search-light.css" title="light"/>}
puts $fh {<link rel="stylesheet" href="/assets/css/css/options-search-dark.css" title="dark"/>}
puts $fh {<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-light.min.css" title="light" />}
puts $fh {<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css" title="dark" />}
puts $fh {<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tarekraafat/autocomplete.js@10.2.7/dist/css/autoComplete.min.css" />}
puts $fh {}
puts $fh {    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>}
puts $fh {    <script src="/assets/scripts/all.min.js"></script><script src="/assets/scripts/tableManager.js"></script><script src="/assets/scripts/filter-script.js"></script><script src="https://cdn.jsdelivr.net/npm/fuzzysort@2.0.4/fuzzysort.min.js"></script><script src="https://cdn.jsdelivr.net/npm/@tarekraafat/autocomplete.js@10.2.7/dist/autoComplete.min.js"></script><script src="/assets/scripts/filtered-toc.js"></script><script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script><script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/haskell.min.js"></script><script src="/assets/scripts/options-search.js"></script><script src="/assets/scripts/page-styling.js"></script><script src="/assets/scripts/rainbow.js"></script>}
puts $fh {</head>}
puts $fh {}

# Body start
puts $fh {<body class="has-navbar-fixed-top">}
puts $fh {<div id="404" class="top-of-page"></div>}

# Navigation bar
puts $fh {<nav class="navbar is-fixed-top is-flex-touch" role="navigation" aria-label="main navigation">}
puts $fh {        <div class="navbar-item" style="margin-left: auto;">}
puts $fh {          <div class="left-bar-toggle" title="Toggle Table of Contents & Index">}
puts $fh {      <label class="chyronToggle left">}
puts $fh {          <input id="navbar-left-toggle" type="checkbox">}
puts $fh {          <span class="text">Contents</span>}
puts $fh {      </label>}
puts $fh {  </div>}
puts $fh {}
puts $fh {    </div>}
puts $fh {}
puts $fh {    <div class="container is-justify-content-space-around">}
puts $fh {        <div class="navbar-brand">}
puts $fh {  <div class="navbar-logo">}
puts $fh {    <a class="navbar-item" href="/">}
puts $fh {      <img src="/assets/images/camelia-recoloured.png" alt="Raku" width="52.83" height="38">}
puts $fh {    </a>}
puts $fh {    <span class="navbar-logo-tm">tm</span>}
puts $fh {  </div>}
puts $fh {  <a role="button" class="navbar-burger burger" aria-label="menu" aria-expanded="false" data-target="navMenu">}
puts $fh {    <span aria-hidden="true"></span>}
puts $fh {    <span aria-hidden="true"></span>}
puts $fh {    <span aria-hidden="true"></span>}
puts $fh {  </a>}
puts $fh {</div>}
puts $fh {}
puts $fh {          <div id="navMenu" class="navbar-menu">}
puts $fh {    <div class="navbar-start">}
puts $fh {        <a class="navbar-item" href="/introduction" title="Getting started, Tutorials, Migration guides">}
puts $fh {            Introduction}
puts $fh {        </a>}
puts $fh {        <a class="navbar-item" href="/reference" title="Fundamentals, General reference">}
puts $fh {            Reference}
puts $fh {        </a>}
puts $fh {        <a class="navbar-item" href="/miscellaneous" title="Programs, Experimental">}
puts $fh {            Miscellaneous}
puts $fh {        </a>}
puts $fh {        <a class="navbar-item" href="/types" title="The core types (classes) available">}
puts $fh {            Types}
puts $fh {        </a>}
puts $fh {        <a class="navbar-item" href="/routines" title="Searchable table of routines">}
puts $fh {            Routines}
puts $fh {        </a>}
puts $fh {        <a class="navbar-item" href="https://raku.org" title="Home page for community">}
puts $fh {            Raku<sup>®</sup>}
puts $fh {        </a>}
puts $fh {        <a class="navbar-item" href="https://web.libera.chat/#raku" title="IRC live chat">}
puts $fh {            Chat}
puts $fh {        </a>}
puts $fh {        <div class="navbar-item has-dropdown is-hoverable">}
puts $fh {          <a class="navbar-link">}
puts $fh {            More}
puts $fh {          </a>}
puts $fh {          <div class="navbar-dropdown is-right is-rounded">}
puts $fh {}
puts $fh {            <hr class="navbar-divider">}
puts $fh {            <a class="navbar-item js-modal-trigger" data-target="download-ebook">}
puts $fh {              Download E-Book (epub)}
puts $fh {            </a>}
puts $fh {}
puts $fh {            <hr class="navbar-divider">}
puts $fh {            <a class="navbar-item" href="/about">}
puts $fh {              About}
puts $fh {            </a>}
puts $fh {            <hr class="navbar-divider">}
puts $fh {            <a class="navbar-item has-text-red" href="https://github.com/raku/doc-website/issues">}
puts $fh {              Report an issue with this site}
puts $fh {            </a>}
puts $fh {            <hr class="navbar-divider">}
puts $fh {            <a class="navbar-item" href="https://github.com/raku/doc/issues">}
puts $fh {              Report an issue with the documentation content}
puts $fh {            </a>}
puts $fh {}
puts $fh {          </div>}
puts $fh {        </div>}
puts $fh {    </div>}
puts $fh {        <div class="navbar-end navbar-search-wrapper">}
puts $fh {        <div class="navbar-item">}
puts $fh {            <div class="field has-addons">}
puts $fh {                <div class="autoComplete_options">}
puts $fh {                    <input class="control input" id="autoComplete" type="search" dir="ltr" spellcheck=false autocorrect="off" autocomplete="off" autocapitalize="off" placeholder="🔍 Type f to search for ...">}
puts $fh {                </div>}
puts $fh {                <div class="control" title="Search options">}
puts $fh {                    <a class="button is-primary js-modal-trigger" data-target="options-search-info">}
puts $fh {                        <span class="icon">}
puts $fh {                            <i class="fas fa-cogs"></i>}
puts $fh {                        </span>}
puts $fh {                    </a>}
puts $fh {                </div>}
puts $fh {            </div>}
puts $fh {        </div>}
puts $fh {    </div>}
puts $fh {    <div id="options-search-info" class="modal">}
puts $fh {        <div class="modal-background"></div>}
puts $fh {        <div class="modal-content">}
puts $fh {            <div class="box">}
puts $fh {                <p>The last search was: <span id="selected-candidate" class="ss-selected"></span></p>}
puts $fh {                <div class="control is-grouped is-grouped-centered options-search-controls">}
puts $fh {                    <label class="centreToggle" title="Include extra information (Alt-E)" style="--switch-width: 10.5">}
puts $fh {                       <input id="options-search-extra" type="checkbox">}
puts $fh {                       <span class="text">Extra info</span>}
puts $fh {                       <span class="on">yes</span>}
puts $fh {                       <span class="off">no</span>}
puts $fh {                    </label>}
puts $fh {                <p>The search response can be shortened by excluding the extra information line (Alt-E)</p>}
puts $fh {                    <label class="centreToggle" title="Search engine type Strict/Loose (Alt-L)" style="--switch-width: 10.5">}
puts $fh {                       <input id="options-search-loose" type="checkbox">}
puts $fh {                       <span class="text">Search type</span>}
puts $fh {                       <span class="on">loose</span>}
puts $fh {                       <span class="off">strict</span>}
puts $fh {                    </label>}
puts $fh {                <p> The search engine can perform a strict search (only the characters in the search}
puts $fh {                box) or a loose search (Alt-L)</p>}
puts $fh {                    <label class="centreToggle" title="Search in headings (Alt-H)" style="--switch-width: 10.5">}
puts $fh {                       <input id="options-search-headings" type="checkbox">}
puts $fh {                       <span class="text">Headings</span>}
puts $fh {                       <span class="on">yes</span>}
puts $fh {                       <span class="off">no</span>}
puts $fh {                    </label>}
puts $fh {                    <p>Search through headings in all web-pages (Alt-H)</p>}
puts $fh {                    <label class="centreToggle" title="Search indexed items (Alt-I)" style="--switch-width: 10.5">}
puts $fh {                       <input id="options-search-indexed" type="checkbox">}
puts $fh {                       <span class="text">Indexed</span>}
puts $fh {                       <span class="on">yes</span>}
puts $fh {                       <span class="off">no</span>}
puts $fh {                    </label>}
puts $fh {                    <p>Search through all indexed items (Alt-I)</p>}
puts $fh {                    <label class="centreToggle" title="Search composite pages (Alt-C)" style="--switch-width: 10.5">}
puts $fh {                       <input id="options-search-composite" type="checkbox">}
puts $fh {                       <span class="text">Composite</span>}
puts $fh {                       <span class="on">yes</span>}
puts $fh {                       <span class="off">no</span>}
puts $fh {                    </label>}
puts $fh {                    <p>Search in the names of composite pages, which combine similar information from}
puts $fh {                    the main web pages (Alt-C)</p>}
puts $fh {                    <label class="centreToggle" title="Search primary sources (Alt-P)" style="--switch-width: 10.5">}
puts $fh {                       <input id="options-search-primary" type="checkbox">}
puts $fh {                       <span class="text">Primary</span>}
puts $fh {                       <span class="on">yes</span>}
puts $fh {                       <span class="off">no</span>}
puts $fh {                    </label>}
puts $fh {                    <p>Search through the names of the main web pages (Alt-P)</p>}
puts $fh {                    <label class="centreToggle" title="Open in new tab (Alt-Q)" style="--switch-width: 10.5">}
puts $fh {                       <input id="options-search-newtab" type="checkbox">}
puts $fh {                       <span class="text">New tab</span>}
puts $fh {                       <span class="on">yes</span>}
puts $fh {                       <span class="off">no</span>}
puts $fh {                    </label>}
puts $fh {                    <p>Once a search candidate has been chosen, it can be opened in a new tab or in the current}
puts $fh {                    tab (Alt-Q)</p>}
puts $fh {                    <p>If all else fails, an item is added to use the Google search engine on the whole site</p>}
puts $fh {                    <button class="button is-warning" id="options-search-reset-defaults">Clear options, reset to defaults</button>}
puts $fh {                    <p>Exit this page by pressing &lt;Escape&gt;, or clicking on X or on the background.</p>}
puts $fh {                </div>}
puts $fh {            </div>}
puts $fh {        </div>}
puts $fh {        <button class="modal-close is-large" aria-label="close"></button>}
puts $fh {    </div>}
puts $fh {}
puts $fh {  </div>}
puts $fh {         <div id="download-ebook" class="modal">}
puts $fh {                    <div class="modal-background"></div>}
puts $fh {                    <div class="modal-content">}
puts $fh {                        <div class="box">}
puts $fh {                            <p><a href="/RakuDocumentation.epub" download>RakuDocumentation.epub</a> is a work in}
puts $fh {                            progress e-book. It targets the <a href="https://www.w3.org/publishing/epub3/">EPUB v3 specification</a>.}
puts $fh {                            It needs testing on a variety of ereaders (some of which may still implicitly expect}
puts $fh {                            compliance with EPUB v2). The CSS definitely needs enhancing (especially for code snippets).}
puts $fh {                            The Ebook opens in a Calibre reader, which is available on all operating systems.</p>}
puts $fh {                            <p>Suggestions are welcome and should be addressed by opening an issue on}
puts $fh {                            the Raku/doc-website repository</p>}
puts $fh {                            <p>Exit this popup by pressing &lt;Escape&gt;, or clicking on X or on the background.</p>}
puts $fh {                        </div>}
puts $fh {                    </div>}
puts $fh {                    <button class="modal-close is-large" aria-label="close"></button>}
puts $fh {                </div>}
puts $fh {}
puts $fh {}
puts $fh {    </div>}
puts $fh {</nav>}
puts $fh {}

# Main content area
puts $fh {<div class="tile is-ancestor section">}
puts $fh {    <div class="page-edit">}
puts $fh {    <a class="button page-edit-button" href="https://github.com/Raku/doc-website/edit/main/Website/structure-sources/404.rakudoc" title="Edit this page.&#13;Commit: 0ead45c 2026-04-04">}
puts $fh {      <span class="icon is-right">}
puts $fh {        <i class="fas fa-pen-alt is-medium"></i>}
puts $fh {      </span>}
puts $fh {    </a>}
puts $fh {  </div>}
puts $fh {}
puts $fh {    <div id="left-column" class="tile is-parent is-2 is-hidden">}
puts $fh {        <div id="left-col-inner">}
puts $fh {                <input type="checkbox" id="No-TOC" checked="checked" style="visibility: collapse;">}
puts $fh {    </input>}
puts $fh {    <div class="content">No Table of Contents or Index available</div>}
puts $fh {}
puts $fh {        </div>}
puts $fh {    </div>}
puts $fh {    <div id="main-column" class="tile is-parent" style="overflow-x: hidden;">}
puts $fh {        <div id="main-col-inner">}
puts $fh {            <section class="raku page-header">}
puts $fh {    <div class="container px-4">}
puts $fh {        <div class="raku page-title has-text-centered">}
puts $fh {        404}
puts $fh {        </div>}
puts $fh {        <div class="raku page-subtitle has-text-centered">}
puts $fh {}
puts $fh {        </div>}
puts $fh {    </div>}
puts $fh {</section>}
puts $fh {<section class="raku page-content"><div class="container px-4"><div class="columns one-col"><img src="/assets/images/Camelia-404.png" class="camelia">}
puts $fh {}
puts $fh {<h2 id="404:_Page_Not_Found" class="raku-h2"><a href="#404" title="go to top of document">404: Page Not Found<a class="raku-anchor" title="direct link" href="#404:_Page_Not_Found">§</a></a></h2>}
puts $fh {<p>We're sorry, but the content you tried to reach wasn't found.</p><p>While we do review server logs to catch these issues, we recently deployed a new version of the site, so please feel free to <a href="https://github.com/Raku/doc-website/issues/">report any issues</a>.</p><p>Thanks!</p>}
puts $fh {}
puts $fh {</div></div></section>}
puts $fh {}
puts $fh {        </div>}
puts $fh {    </div>}
puts $fh {</div>}
puts $fh {}

# Footer
puts $fh {<footer class="footer main-footer">}
puts $fh {  <div class="container px-4">}
puts $fh {    <nav class="level">}
puts $fh {    <div class="level-left">}
puts $fh {    <div class="level-item">}
puts $fh {      <a href="/about">About</a>}
puts $fh {    </div>}
puts $fh {    <div class="level-item">}
puts $fh {      <a id="toggle-theme">Toggle theme</a>}
puts $fh {    </div>}
puts $fh {        <div class="level-item" title="0ead45c 2026-04-04">}
puts $fh {      <a>Commit</a>}
puts $fh {    </div>}
puts $fh {}
puts $fh {</div>}
puts $fh {}
puts $fh {    <div class="level-right">}
puts $fh {    <div class="level-item">}
puts $fh {      <a href="/license">License</a>}
puts $fh {    </div>}
puts $fh {</div>}
puts $fh {}
puts $fh {    </nav>}
puts $fh {  </div>}
puts $fh {</footer>}
puts $fh {}

# Close body and html tags
puts $fh {}
puts $fh {</body>}
puts $fh {</html>}

# Close file handle
close $fh

# Output success message to stdout
puts "HTML file generated successfully: $output_file"
