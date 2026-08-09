#!/usr/bin/env tclsh
# language.html — portiert nach tcl
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/raku/language.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/raku/language.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Tcl script to generate the HTML content from language.html
# Usage: tclsh this_script.tcl output_file.html

# Check command line arguments
if {$argc != 1} {
    puts stderr "Usage: $argv0 output_file.html"
    exit 1
}

set output_file [lindex $argv 0]

# Create the HTML document structure
set html [list]

# Add DOCTYPE and html start tag
lappend html {<!DOCTYPE html>}
lappend html {<html lang="en" class="fontawesome-i2svg-active fontawesome-i2svg-complete" style="scroll-padding-top:60px">}

# Head section
lappend html {<head>}
lappend html {    <title>404 | Raku Documentation</title>}
lappend html {    <meta charset="UTF-8" />}
lappend html {}
lappend html {<link href="/assets/images/Camelia.ico" rel="icon" type="image/x-icon"/>}
lappend html {}
lappend html {<link rel="stylesheet" href="/assets/css/Website.css"/>}
lappend html {<link rel="stylesheet" href="/assets/css/css/filtered-toc-dark.css" title="dark"/>}
lappend html {<link rel="stylesheet" href="/assets/css/css/filtered-toc-light.css" title="light"/>}
lappend html {<link rel="stylesheet" href="/assets/css/css/rainbow-dark.css" title="dark"/>}
lappend html {<link rel="stylesheet" href="/assets/css/css/rainbow-light.css" title="light"/>}
lappend html {<link rel="stylesheet" href="/assets/css/tm-styling.css"/>}
lappend html {<link rel="stylesheet" href="/assets/css/tm-light.css" title="light"/>}
lappend html {<link rel="stylesheet" href="/assets/css/tm-dark.css" title="dark"/>}
lappend html {<link rel="stylesheet" href="/assets/css/all.min.css"/>}
lappend html {<link rel="stylesheet" href="/assets/css/listf-styling-light.css" title="light"/>}
lappend html {<link rel="stylesheet" href="/assets/css/listf-styling-dark.css" title="dark"/>}
lappend html {<link rel="stylesheet" href="/assets/css/typegraph-styling.css"/>}
lappend html {<link rel="stylesheet" href="/assets/css/typegraph-dark.css" title="dark"/>}
lappend html {<link rel="stylesheet" href="/assets/css/typegraph-light.css" title="light"/>}
lappend html {<link rel="stylesheet" href="/assets/css/css/page-styling-main.css"/>}
lappend html {<link rel="stylesheet" href="/assets/css/css/page-styling-dark.css" title="dark"/>}
lappend html {<link rel="stylesheet" href="/assets/css/css/page-styling-light.css" title="light"/>}
lappend html {<link rel="stylesheet" href="/assets/css/css/chyronToggle-dark.css" title="dark"/>}
lappend html {<link rel="stylesheet" href="/assets/css/css/chyronToggle-light.css" title="light"/>}
lappend html {<link rel="stylesheet" href="/assets/css/css/centreToggle-dark.css" title="dark"/>}
lappend html {<link rel="stylesheet" href="/assets/css/css/centreToggle-light.css" title="light"/>}
lappend html {<link rel="stylesheet" href="/assets/css/css/options-search-light.css" title="light"/>}
lappend html {<link rel="stylesheet" href="/assets/css/css/options-search-dark.css" title="dark"/>}
lappend html {<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-light.min.css" title="light" />}
lappend html {<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css" title="dark" />}
lappend html {<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tarekraafat/autocomplete.js@10.2.7/dist/css/autoComplete.min.css" />}
lappend html {}
lappend html {    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>}
lappend html {    <script src="/assets/scripts/all.min.js"></script><script src="/assets/scripts/tableManager.js"></script><script src="/assets/scripts/filter-script.js"></script><script src="https://cdn.jsdelivr.net/npm/fuzzysort@2.0.4/fuzzysort.min.js"></script><script src="https://cdn.jsdelivr.net/npm/@tarekraafat/autocomplete.js@10.2.7/dist/autoComplete.min.js"></script><script src="/assets/scripts/filtered-toc.js"></script><script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script><script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/haskell.min.js"></script><script src="/assets/scripts/options-search.js"></script><script src="/assets/scripts/page-styling.js"></script><script src="/assets/scripts/rainbow.js"></script>}
lappend html {</head>}
lappend html {}
lappend html {<body class="has-navbar-fixed-top">}
lappend html {<div id="404" class="top-of-page"></div>}
lappend html {<nav class="navbar is-fixed-top is-flex-touch" role="navigation" aria-label="main navigation">}
lappend html {        <div class="navbar-item" style="margin-left: auto;">}
lappend html {          <div class="left-bar-toggle" title="Toggle Table of Contents & Index">}
lappend html {      <label class="chyronToggle left">}
lappend html {          <input id="navbar-left-toggle" type="checkbox">}
lappend html {          <span class="text">Contents</span>}
lappend html {      </label>}
lappend html {  </div>}
lappend html {}
lappend html {    </div>}
lappend html {}
lappend html {    <div class="container is-justify-content-space-around">}
lappend html {        <div class="navbar-brand">}
lappend html {  <div class="navbar-logo">}
lappend html {    <a class="navbar-item" href="/">}
lappend html {      <img src="/assets/images/camelia-recoloured.png" alt="Raku" width="52.83" height="38">}
lappend html {    </a>}
lappend html {    <span class="navbar-logo-tm">tm</span>}
lappend html {  </div>}
lappend html {  <a role="button" class="navbar-burger burger" aria-label="menu" aria-expanded="false" data-target="navMenu">}
lappend html {    <span aria-hidden="true"></span>}
lappend html {    <span aria-hidden="true"></span>}
lappend html {    <span aria-hidden="true"></span>}
lappend html {  </a>}
lappend html {</div>}
lappend html {}
lappend html {          <div id="navMenu" class="navbar-menu">}
lappend html {    <div class="navbar-start">}
lappend html {        <a class="navbar-item" href="/introduction" title="Getting started, Tutorials, Migration guides">}
lappend html {            Introduction}
lappend html {        </a>}
lappend html {        <a class="navbar-item" href="/reference" title="Fundamentals, General reference">}
lappend html {            Reference}
lappend html {        </a>}
lappend html {        <a class="navbar-item" href="/miscellaneous" title="Programs, Experimental">}
lappend html {            Miscellaneous}
lappend html {        </a>}
lappend html {        <a class="navbar-item" href="/types" title="The core types (classes) available">}
lappend html {            Types}
lappend html {        </a>}
lappend html {        <a class="navbar-item" href="/routines" title="Searchable table of routines">}
lappend html {            Routines}
lappend html {        </a>}
lappend html {        <a class="navbar-item" href="https://raku.org" title="Home page for community">}
lappend html {            Raku<sup>®</sup>}
lappend html {        </a>}
lappend html {        <a class="navbar-item" href="https://web.libera.chat/#raku" title="IRC live chat">}
lappend html {            Chat}
lappend html {        </a>}
lappend html {        <div class="navbar-item has-dropdown is-hoverable">}
lappend html {          <a class="navbar-link">}
lappend html {            More}
lappend html {          </a>}
lappend html {          <div class="navbar-dropdown is-right is-rounded">}
lappend html {}
lappend html {            <hr class="navbar-divider">}
lappend html {            <a class="navbar-item js-modal-trigger" data-target="download-ebook">}
lappend html {              Download E-Book (epub)}
lappend html {            </a>}
lappend html {}
lappend html {            <hr class="navbar-divider">}
lappend html {            <a class="navbar-item" href="/about">}
lappend html {              About}
lappend html {            </a>}
lappend html {            <hr class="navbar-divider">}
lappend html {            <a class="navbar-item has-text-red" href="https://github.com/raku/doc-website/issues">}
lappend html {              Report an issue with this site}
lappend html {            </a>}
lappend html {            <hr class="navbar-divider">}
lappend html {            <a class="navbar-item" href="https://github.com/raku/doc/issues">}
lappend html {              Report an issue with the documentation content}
lappend html {            </a>}
lappend html {}
lappend html {          </div>}
lappend html {        </div>}
lappend html {    </div>}
lappend html {        <div class="navbar-end navbar-search-wrapper">}
lappend html {        <div class="navbar-item">}
lappend html {            <div class="field has-addons">}
lappend html {                <div class="autoComplete_options">}
lappend html {                    <input class="control input" id="autoComplete" type="search" dir="ltr" spellcheck=false autocorrect="off" autocomplete="off" autocapitalize="off" placeholder="🔍 Type f to search for ...">}
lappend html {                </div>}
lappend html {                <div class="control" title="Search options">}
lappend html {                    <a class="button is-primary js-modal-trigger" data-target="options-search-info">}
lappend html {                        <span class="icon">}
lappend html {                            <i class="fas fa-cogs"></i>}
lappend html {                        </span>}
lappend html {                    </a>}
lappend html {                </div>}
lappend html {            </div>}
lappend html {        </div>}
lappend html {    </div>}
lappend html {    <div id="options-search-info" class="modal">}
lappend html {        <div class="modal-background"></div>}
lappend html {        <div class="modal-content">}
lappend html {            <div class="box">}
lappend html {                <p>The last search was: <span id="selected-candidate" class="ss-selected"></span></p>}
lappend html {                <div class="control is-grouped is-grouped-centered options-search-controls">}
lappend html {                    <label class="centreToggle" title="Include extra information (Alt-E)" style="--switch-width: 10.5">}
lappend html {                       <input id="options-search-extra" type="checkbox">}
lappend html {                       <span class="text">Extra info</span>}
lappend html {                       <span class="on">yes</span>}
lappend html {                       <span class="off">no</span>}
lappend html {                    </label>}
lappend html {                <p>The search response can be shortened by excluding the extra information line (Alt-E)</p>}
lappend html {                    <label class="centreToggle" title="Search engine type Strict/Loose (Alt-L)" style="--switch-width: 10.5">}
lappend html {                       <input id="options-search-loose" type="checkbox">}
lappend html {                       <span class="text">Search type</span>}
lappend html {                       <span class="on">loose</span>}
lappend html {                       <span class="off">strict</span>}
lappend html {                    </label>}
lappend html {                <p> The search engine can perform a strict search (only the characters in the search}
lappend html {                box) or a loose search (Alt-L)</p>}
lappend html {                    <label class="centreToggle" title="Search in headings (Alt-H)" style="--switch-width: 10.5">}
lappend html {                       <input id="options-search-headings" type="checkbox">}
lappend html {                       <span class="text">Headings</span>}
lappend html {                       <span class="on">yes</span>}
lappend html {                       <span class="off">no</span>}
lappend html {                    </label>}
lappend html {                    <p>Search through headings in all web-pages (Alt-H)</p>}
lappend html {                    <label class="centreToggle" title="Search indexed items (Alt-I)" style="--switch-width: 10.5">}
lappend html {                       <input id="options-search-indexed" type="checkbox">}
lappend html {                       <span class="text">Indexed</span>}
lappend html {                       <span class="on">yes</span>}
lappend html {                       <span class="off">no</span>}
lappend html {                    </label>}
lappend html {                    <p>Search through all indexed items (Alt-I)</p>}
lappend html {                    <label class="centreToggle" title="Search composite pages (Alt-C)" style="--switch-width: 10.5">}
lappend html {                       <input id="options-search-composite" type="checkbox">}
lappend html {                       <span class="text">Composite</span>}
lappend html {                       <span class="on">yes</span>}
lappend html {                       <span class="off">no</span>}
lappend html {                    </label>}
lappend html {                    <p>Search in the names of composite pages, which combine similar information from}
lappend html {                    the main web pages (Alt-C)</p>}
lappend html {                    <label class="centreToggle" title="Search primary sources (Alt-P)" style="--switch-width: 10.5">}
lappend html {                       <input id="options-search-primary" type="checkbox">}
lappend html {                       <span class="text">Primary</span>}
lappend html {                       <span class="on">yes</span>}
lappend html {                       <span class="off">no</span>}
lappend html {                    </label>}
lappend html {                    <p>Search through the names of the main web pages (Alt-P)</p>}
lappend html {                    <label class="centreToggle" title="Open in new tab (Alt-Q)" style="--switch-width: 10.5">}
lappend html {                       <input id="options-search-newtab" type="checkbox">}
lappend html {                       <span class="text">New tab</span>}
lappend html {                       <span class="on">yes</span>}
lappend html {                       <span class="off">no</span>}
lappend html {                    </label>}
lappend html {                    <p>Once a search candidate has been chosen, it can be opened in a new tab or in the current}
lappend html {                    tab (Alt-Q)</p>}
lappend html {                    <p>If all else fails, an item is added to use the Google search engine on the whole site</p>}
lappend html {                    <button class="button is-warning" id="options-search-reset-defaults">Clear options, reset to defaults</button>}
lappend html {                    <p>Exit this page by pressing &lt;Escape&gt;, or clicking on X or on the background.</p>}
lappend html {                </div>}
lappend html {            </div>}
lappend html {        </div>}
lappend html {        <button class="modal-close is-large" aria-label="close"></button>}
lappend html {    </div>}
lappend html {}
lappend html {  </div>}
lappend html {         <div id="download-ebook" class="modal">}
lappend html {                    <div class="modal-background"></div>}
lappend html {                    <div class="modal-content">}
lappend html {                        <div class="box">}
lappend html {                            <p><a href="/RakuDocumentation.epub" download>RakuDocumentation.epub</a> is a work in}
lappend html {                            progress e-book. It targets the <a href="https://www.w3.org/publishing/epub3/">EPUB v3 specification</a>.}
lappend html {                            It needs testing on a variety of ereaders (some of which may still implicitly expect}
lappend html {                            compliance with EPUB v2). The CSS definitely needs enhancing (especially for code snippets).}
lappend html {                            The Ebook opens in a Calibre reader, which is available on all operating systems.</p>}
lappend html {                            <p>Suggestions are welcome and should be addressed by opening an issue on}
lappend html {                            the Raku/doc-website repository</p>}
lappend html {                            <p>Exit this popup by pressing &lt;Escape&gt;, or clicking on X or on the background.</p>}
lappend html {                        </div>}
lappend html {                    </div>}
lappend html {                    <button class="modal-close is-large" aria-label="close"></button>}
lappend html {                </div>}
lappend html {}
lappend html {}
lappend html {    </div>}
lappend html {</nav>}
lappend html {}
lappend html {<div class="tile is-ancestor section">}
lappend html {    <div class="page-edit">}
lappend html {    <a class="button page-edit-button" href="https://github.com/Raku/doc-website/edit/main/Website/structure-sources/404.rakudoc" title="Edit this page.&#13;Commit: 0ead45c 2026-04-04">}
lappend html {      <span class="icon is-right">}
lappend html {        <i class="fas fa-pen-alt is-medium"></i>}
lappend html {      </span>}
lappend html {    </a>}
lappend html {  </div>}
lappend html {}
lappend html {    <div id="left-column" class="tile is-parent is-2 is-hidden">}
lappend html {        <div id="left-col-inner">}
lappend html {                <input type="checkbox" id="No-TOC" checked="checked" style="visibility: collapse;">}
lappend html {    </input>}
lappend html {    <div class="content">No Table of Contents or Index available</div>}
lappend html {}
lappend html {        </div>}
lappend html {    </div>}
lappend html {    <div id="main-column" class="tile is-parent" style="overflow-x: hidden;">}
lappend html {        <div id="main-col-inner">}
lappend html {            <section class="raku page-header">}
lappend html {    <div class="container px-4">}
lappend html {        <div class="raku page-title has-text-centered">}
lappend html {        404}
lappend html {        </div>}
lappend html {        <div class="raku page-subtitle has-text-centered">}
lappend html {}
lappend html {        </div>}
lappend html {    </div>}
lappend html {</section>}
lappend html {<section class="raku page-content"><div class="container px-4"><div class="columns one-col"><img src="/assets/images/Camelia-404.png" class="camelia">}
lappend html {}
lappend html {<h2 id="404:_Page_Not_Found" class="raku-h2"><a href="#404" title="go to top of document">404: Page Not Found<a class="raku-anchor" title="direct link" href="#404:_Page_Not_Found">§</a></a></h2>}
lappend html {<p>We're sorry, but the content you tried to reach wasn't found.</p><p>While we do review server logs to catch these issues, we recently deployed a new version of the site, so please feel free to <a href="https://github.com/Raku/doc-website/issues/">report any issues</a>.</p><p>Thanks!</p>}
lappend html {}
lappend html {</div></div></section>}
lappend html {}
lappend html {        </div>}
lappend html {    </div>}
lappend html {</div>}
lappend html {}
lappend html {<footer class="footer main-footer">}
lappend html {  <div class="container px-4">}
lappend html {    <nav class="level">}
lappend html {    <div class="level-left">}
lappend html {    <div class="level-item">}
lappend html {      <a href="/about">About</a>}
lappend html {    </div>}
lappend html {    <div class="level-item">}
lappend html {      <a id="toggle-theme">Toggle theme</a>}
lappend html {    </div>}
lappend html {        <div class="level-item" title="0ead45c 2026-04-04">}
lappend html {      <a>Commit</a>}
lappend html {    </div>}
lappend html {}
lappend html {</div>}
lappend html {}
lappend html {    <div class="level-right">}
lappend html {    <div class="level-item">}
lappend html {      <a href="/license">License</a>}
lappend html {    </div>}
lappend html {</div>}
lappend html {}
lappend html {    </nav>}
lappend html {  </div>}
lappend html {</footer>}
lappend html {}
lappend html {}
lappend html {</body>}
lappend html {</html>}

# Write the HTML content to the output file
set fh [open $output_file w]
puts $fh [join $html "\n"]
close $fh

# Output success message
puts "HTML file generated successfully: $output_file"
