#!/usr/bin/env tclsh
# index.html — portiert nach tcl
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/raku/index.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/raku/index.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Portierung von index.html nach Tcl 8.6
# Erzeugt das HTML-Dokument dynamisch und schreibt es in eine Datei

proc write_index_html {filename} {
    set fp [open $filename w]
    
    # DOCTYPE und HTML-Start
    puts $fp {<!DOCTYPE html>}
    puts $fp {<html lang="en" class="fontawesome-i2svg-active fontawesome-i2svg-complete" style="scroll-padding-top:60px">}
    
    # Head-Bereich
    puts $fp {<head>}
    puts $fp {    <title>Raku Documentation | Raku Documentation</title>}
    puts $fp {    <meta charset="UTF-8" />}
    puts $fp {}
    puts $fp {<link href="/assets/images/Camelia.ico" rel="icon" type="image/x-icon"/>}
    puts $fp {}
    puts $fp {    }
    puts $fp {<link rel="stylesheet" href="/assets/css/Website.css"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/css/filtered-toc-dark.css" title="dark"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/css/filtered-toc-light.css" title="light"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/css/rainbow-dark.css" title="dark"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/css/rainbow-light.css" title="light"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/tm-styling.css"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/tm-light.css" title="light"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/tm-dark.css" title="dark"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/all.min.css"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/listf-styling-light.css" title="light"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/listf-styling-dark.css" title="dark"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/typegraph-styling.css"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/typegraph-dark.css" title="dark"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/typegraph-light.css" title="light"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/css/page-styling-main.css"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/css/page-styling-dark.css" title="dark"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/css/page-styling-light.css" title="light"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/css/chyronToggle-dark.css" title="dark"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/css/chyronToggle-light.css" title="light"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/css/centreToggle-dark.css" title="dark"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/css/centreToggle-light.css" title="light"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/css/options-search-light.css" title="light"/>}
    puts $fp {<link rel="stylesheet" href="/assets/css/css/options-search-dark.css" title="dark"/>}
    puts $fp {<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-light.min.css" title="light" />}
    puts $fp {<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css" title="dark" />}
    puts $fp {<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@tarekraafat/autocomplete.js@10.2.7/dist/css/autoComplete.min.css" />}
    puts $fp {}
    puts $fp {    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>}
    puts $fp {    <script src="/assets/scripts/all.min.js"></script><script src="/assets/scripts/tableManager.js"></script><script src="/assets/scripts/filter-script.js"></script><script src="https://cdn.jsdelivr.net/npm/fuzzysort@2.0.4/fuzzysort.min.js"></script><script src="https://cdn.jsdelivr.net/npm/@tarekraafat/autocomplete.js@10.2.7/dist/autoComplete.min.js"></script><script src="/assets/scripts/filtered-toc.js"></script><script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script><script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/haskell.min.js"></script><script src="/assets/scripts/options-search.js"></script><script src="/assets/scripts/page-styling.js"></script><script src="/assets/scripts/rainbow.js"></script>}
    puts $fp {</head>}
    puts $fp {}
    
    # Body-Bereich
    puts $fp {<body class="has-navbar-fixed-top">}
    puts $fp {<div id="Raku_Documentation" class="top-of-page"></div>}
    puts $fp {<nav class="navbar is-fixed-top is-flex-touch" role="navigation" aria-label="main navigation">}
    puts $fp {    }
    puts $fp {    <div class="container is-justify-content-space-around">}
    puts $fp {        <div class="navbar-brand">}
    puts $fp {  <div class="navbar-logo">}
    puts $fp {    <a class="navbar-item" href="/">}
    puts $fp {      <img src="/assets/images/camelia-recoloured.png" alt="Raku" width="52.83" height="38">}
    puts $fp {    </a>}
    puts $fp {    <span class="navbar-logo-tm">tm</span>}
    puts $fp {  </div>}
    puts $fp {  <a role="button" class="navbar-burger burger" aria-label="menu" aria-expanded="false" data-target="navMenu">}
    puts $fp {    <span aria-hidden="true"></span>}
    puts $fp {    <span aria-hidden="true"></span>}
    puts $fp {    <span aria-hidden="true"></span>}
    puts $fp {  </a>}
    puts $fp {</div>}
    puts $fp {}
    puts $fp {          <div id="navMenu" class="navbar-menu">}
    puts $fp {    <div class="navbar-start">}
    puts $fp {        <a class="navbar-item" href="/introduction" title="Getting started, Tutorials, Migration guides">}
    puts $fp {            Introduction}
    puts $fp {        </a>}
    puts $fp {        <a class="navbar-item" href="/reference" title="Fundamentals, General reference">}
    puts $fp {            Reference}
    puts $fp {        </a>}
    puts $fp {        <a class="navbar-item" href="/miscellaneous" title="Programs, Experimental">}
    puts $fp {            Miscellaneous}
    puts $fp {        </a>}
    puts $fp {        <a class="navbar-item" href="/types" title="The core types (classes) available">}
    puts $fp {            Types}
    puts $fp {        </a>}
    puts $fp {        <a class="navbar-item" href="/routines" title="Searchable table of routines">}
    puts $fp {            Routines}
    puts $fp {        </a>}
    puts $fp {        <a class="navbar-item" href="https://raku.org" title="Home page for community">}
    puts $fp {            Raku<sup>®</sup>}
    puts $fp {        </a>}
    puts $fp {        <a class="navbar-item" href="https://web.libera.chat/#raku" title="IRC live chat">}
    puts $fp {            Chat}
    puts $fp {        </a>}
    puts $fp {        <div class="navbar-item has-dropdown is-hoverable">}
    puts $fp {          <a class="navbar-link">}
    puts $fp {            More}
    puts $fp {          </a>}
    puts $fp {          <div class="navbar-dropdown is-right is-rounded">}
    puts $fp {            }
    puts $fp {            <hr class="navbar-divider">}
    puts $fp {            <a class="navbar-item js-modal-trigger" data-target="download-ebook">}
    puts $fp {              Download E-Book (epub)}
    puts $fp {            </a>}
    puts $fp {        }
    puts $fp {            <hr class="navbar-divider">}
    puts $fp {            <a class="navbar-item" href="/about">}
    puts $fp {              About}
    puts $fp {            </a>}
    puts $fp {            <hr class="navbar-divider">}
    puts $fp {            <a class="navbar-item has-text-red" href="https://github.com/raku/doc-website/issues">}
    puts $fp {              Report an issue with this site}
    puts $fp {            </a>}
    puts $fp {            <hr class="navbar-divider">}
    puts $fp {            <a class="navbar-item" href="https://github.com/raku/doc/issues">}
    puts $fp {              Report an issue with the documentation content}
    puts $fp {            </a>}
    puts $fp {            }
    puts $fp {          </div>}
    puts $fp {        </div>}
    puts $fp {    </div>}
    puts $fp {        <div class="navbar-end navbar-search-wrapper">}
    puts $fp {        <div class="navbar-item">}
    puts $fp {            <div class="field has-addons">}
    puts $fp {                <div class="autoComplete_options">}
    puts $fp {                    <input class="control input" id="autoComplete" type="search" dir="ltr" spellcheck=false autocorrect="off" autocomplete="off" autocapitalize="off" placeholder="&#x1F50D; Type f to search for ...">}
    puts $fp {                </div>}
    puts $fp {                <div class="control" title="Search options">}
    puts $fp {                    <a class="button is-primary js-modal-trigger" data-target="options-search-info">}
    puts $fp {                        <span class="icon">}
    puts $fp {                            <i class="fas fa-cogs"></i>}
    puts $fp {                        </span>}
    puts $fp {                    </a>}
    puts $fp {                </div>}
    puts $fp {            </div>}
    puts $fp {        </div>}
    puts $fp {    </div>}
    puts $fp {    <div id="options-search-info" class="modal">}
    puts $fp {        <div class="modal-background"></div>}
    puts $fp {        <div class="modal-content">}
    puts $fp {            <div class="box">}
    puts $fp {                <p>The last search was: <span id="selected-candidate" class="ss-selected"></span></p>}
    puts $fp {                <div class="control is-grouped is-grouped-centered options-search-controls">}
    puts $fp {                    <label class="centreToggle" title="Include extra information (Alt-E)" style="--switch-width: 10.5">}
    puts $fp {                       <input id="options-search-extra" type="checkbox">}
    puts $fp {                       <span class="text">Extra info</span>}
    puts $fp {                       <span class="on">yes</span>}
    puts $fp {                       <span class="off">no</span>}
    puts $fp {                    </label>}
    puts $fp {                <p>The search response can be shortened by excluding the extra information line (Alt-E)</p>}
    puts $fp {                    <label class="centreToggle" title="Search engine type Strict/Loose (Alt-L)" style="--switch-width: 10.5">}
    puts $fp {                       <input id="options-search-loose" type="checkbox">}
    puts $fp {                       <span class="text">Search type</span>}
    puts $fp {                       <span class="on">loose</span>}
    puts $fp {                       <span class="off">strict</span>}
    puts $fp {                    </label>}
    puts $fp {                <p> The search engine can perform a strict search (only the characters in the search}
    puts $fp {                box) or a loose search (Alt-L)</p>}
    puts $fp {                    <label class="centreToggle" title="Search in headings (Alt-H)" style="--switch-width: 10.5">}
    puts $fp {                       <input id="options-search-headings" type="checkbox">}
    puts $fp {                       <span class="text">Headings</span>}
    puts $fp {                       <span class="on">yes</span>}
    puts $fp {                       <span class="off">no</span>}
    puts $fp {                    </label>}
    puts $fp {                    <p>Search through headings in all web-pages (Alt-H)</p>}
    puts $fp {                    <label class="centreToggle" title="Search indexed items (Alt-I)" style="--switch-width: 10.5">}
    puts $fp {                       <input id="options-search-indexed" type="checkbox">}
    puts $fp {                       <span class="text">Indexed</span>}
    puts $fp {                       <span class="on">yes</span>}
    puts $fp {                       <span class="off">no</span>}
    puts $fp {                    </label>}
    puts $fp {                    <p>Search through all indexed items (Alt-I)</p>}
    puts $fp {                    <label class="centreToggle" title="Search composite pages (Alt-C)" style="--switch-width: 10.5">}
    puts $fp {                       <input id="options-search-composite" type="checkbox">}
    puts $fp {                       <span class="text">Composite</span>}
    puts $fp {                       <span class="on">yes</span>}
    puts $fp {                       <span class="off">no</span>}
    puts $fp {                    </label>}
    puts $fp {                    <p>Search in the names of composite pages, which combine similar information from}
    puts $fp {                    the main web pages (Alt-C)</p>}
    puts $fp {                    <label class="centreToggle" title="Search primary sources (Alt-P)" style="--switch-width: 10.5">}
    puts $fp {                       <input id="options-search-primary" type="checkbox">}
    puts $fp {                       <span class="text">Primary</span>}
    puts $fp {                       <span class="on">yes</span>}
    puts $fp {                       <span class="off">no</span>}
    puts $fp {                    </label>}
    puts $fp {                    <p>Search through the names of the main web pages (Alt-P)</p>}
    puts $fp {                    <label class="centreToggle" title="Open in new tab (Alt-Q)" style="--switch-width: 10.5">}
    puts $fp {                       <input id="options-search-newtab" type="checkbox">}
    puts $fp {                       <span class="text">New tab</span>}
    puts $fp {                       <span class="on">yes</span>}
    puts $fp {                       <span class="off">no</span>}
    puts $fp {                    </label>}
    puts $fp {                    <p>Once a search candidate has been chosen, it can be opened in a new tab or in the current}
    puts $fp {                    tab (Alt-Q)</p>}
    puts $fp {                    <p>If all else fails, an item is added to use the Google search engine on the whole site</p>}
    puts $fp {                    <button class="button is-warning" id="options-search-reset-defaults">Clear options, reset to defaults</button>}
    puts $fp {                    <p>Exit this page by pressing &lt;Escape&gt;, or clicking on X or on the background.</p>}
    puts $fp {                </div>}
    puts $fp {            </div>}
    puts $fp {        </div>}
    puts $fp {        <button class="modal-close is-large" aria-label="close"></button>}
    puts $fp {    </div>}
    puts $fp {}
    puts $fp {  </div>}
    puts $fp {         <div id="download-ebook" class="modal">}
    puts $fp {                    <div class="modal-background"></div>}
    puts $fp {                    <div class="modal-content">}
    puts $fp {                        <div class="box">}
    puts $fp {                            <p><a href="/RakuDocumentation.epub" download>RakuDocumentation.epub</a> is a work in}
    puts $fp {                            progress e-book. It targets the <a href="https://www.w3.org/publishing/epub3/">EPUB v3 specification</a>.}
    puts $fp {                            It needs testing on a variety of ereaders (some of which may still implicitly expect}
    puts $fp {                            compliance with EPUB v2). The CSS definitely needs enhancing (especially for code snippets).}
    puts $fp {                            The Ebook opens in a Calibre reader, which is available on all operating systems.</p>}
    puts $fp {                            <p>Suggestions are welcome and should be addressed by opening an issue on}
    puts $fp {                            the Raku/doc-website repository</p>}
    puts $fp {                            <p>Exit this popup by pressing &lt;Escape&gt;, or clicking on X or on the background.</p>}
    puts $fp {                        </div>}
    puts $fp {                    </div>}
    puts $fp {                    <button class="modal-close is-large" aria-label="close"></button>}
    puts $fp {                </div>}
    puts $fp {        }
    puts $fp {  }
    puts $fp {}
    puts $fp {    </div>}
    puts $fp {</nav>}
    puts $fp {}
    puts $fp {<div id="wrapper"> <section class="hero is-medium is-primary"> <div class="hero-body"> <div class="container"> <h1 class="title is-1 is-size-2-mobile has-text-centered"> Raku documentation </h1> <h2 class="subtitle is-4 has-text-centered mt-3"> Welcome to the official documentation of the Raku<sup>®</sup> programming language! </h2> </div> </div> </section> <section class="section"> <div class="container px-4"> <div class="columns is-multiline"> <!-- Card --> <div class="column is-one-half"> <div class="card card-home"> <div class="card-content"> <div class="has-text-centered"> <a href="/introduction"> <span class="icon is-large has-text-primary"> <i class="fas fa-graduation-cap icon-large"></i> </span> </a> </div> <div class="content has-text-centered"> <p class="title is-5 has-text-primary"><a href="/introduction">Getting started, Migration guides from other languages, &amp; Tutorials</a></p> </div> <div class="content has-text-centered"> Documents introducing the language for various audiences. </div> <div class="has-text-centered"> <a class="button is-primary" href="/introduction"> <strong>Learn more</strong> </a> </div> </div> </div> </div> <div class="column is-one-half"> <div class="card card-home"> <div class="card-content"> <div class="has-text-centered"> <a href="/reference"> <span class="icon is-large has-text-primary"> <i class="fas fa-book icon-large"></i> </span> </a> </div> <div class="content has-text-centered"> <p class="title is-5 has-text-primary"><a href="/reference">Language References</a></p> </div> <div class="content has-text-centered"> Documents explaining the various conceptual parts of the language. </div> <div class="has-text-centered"> <a class="button is-primary" href="/reference"> <strong>Learn more</strong> </a> </div> </div> </div> </div> <div class="column is-one-third"> <div class="card card-home"> <div class="card-content"> <div class="has-text-centered"> <a href="/types"> <span class="icon is-large has-text-primary"> <i class="fas fa-layer-group icon-large"></i> </span> </a> </div> <div class="content has-text-centered"> <p class="title is-5 has-text-primary"><a href="/types">Type Reference</a></p> </div> <div class="content has-text-centered"> Index of built-in classes, roles and enums. </div> <div class="has-text-centered"> <a class="button is-primary" href="/types"> <strong>Learn more</strong> </a> </div> </div> </div> </div> <div class="column is-one-third"> <div class="card card-home"> <div class="card-content"> <div class="has-text-centered"> <a href="/routines"> <span class="icon is-large has-text-primary"> <i class="fas fa-paperclip icon-large"></i> </span> </a> </div> <div class="content has-text-centered"> <p class="title is-5 has-text-primary"><a href="/routines">Routine Reference</a></p> </div> <div class="content has-text-centered"> Index of built-in subroutines and methods. </div> <div class="has-text-centered"> <a class="button is-primary" href="/routines"> <strong>Learn more</strong> </a> </div> </div> </div> </div> <div class="column is-one-third"> <div class="card card-home"> <div class="card-content"> <div class="has-text-centered"> <a href="/miscellaneous"> <span class="icon is-large has-text-primary"> <i class="fas fa-code icon-large"></i> </span> </a> </div> <div class="content has-text-centered"> <p class="title is-5 has-text-primary"><a href="/miscellaneous">Miscellaneous</a></p> </div> <div class="content has-text-centered"> Documents explaining experimental topics and Raku programs rather than the language itself. </div> <div class="has-text-centered"> <a class="button is-primary" href="/miscellaneous"> <strong>Learn more</strong> </a> </div> </div> </div> </div> <div class="column is-one-half"> <div class="card card-home"> <div class="card-content"> <div class="has-text-centered"> <a href="/language/faq"> <span class="icon is-large has-text-primary"> <svg class="svg-inline--fa fa-question-circle fa-w-16 icon-large" aria-hidden="true" data-prefix="fas" data-icon="question-circle" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" data-fa-i2svg=""><path fill="currentColor" d="M504 256c0 136.997-111.043 248-248 248S8 392.997 8 256C8 119.083 119.043 8 256 8s248 111.083 248 248zM262.655 90c-54.497 0-89.255 22.957-116.549 63.758-3.536 5.286-2.353 12.415 2.715 16.258l34.699 26.31c5.205 3.947 12.621 3.008 16.665-2.122 17.864-22.658 30.113-35.797 57.303-35.797 20.429 0 45.698 13.148 45.698 32.958 0 14.976-12.363 22.667-32.534 33.976C247.128 238.528 216 254.941 216 296v4c0 6.627 5.373 12 12 12h56c6.627 0 12-5.373 12-12v-1.333c0-28.462 83.186-29.647 83.186-106.667 0-58.002-60.165-102-116.531-102zM256 338c-25.365 0-46 20.635-46 46 0 25.364 20.635 46 46 46s46-20.636 46-46c0-25.365-20.635-46-46-46z"></path></svg><!-- <i class="fas fa-question-circle icon-large"></i> --> </span> </a> </div> <div class="content has-text-centered"> <p class="title is-5 has-text-primary"><a href="/language/faq">FAQs (Frequently Asked Questions)</a></p> </div> <div class="content has-text-centered"> A collection of questions that have cropped up often, along with answers. </div> <div class="has-text-centered"> <a class="button is-primary" href="/language/faq"> <strong>Learn more</strong> </a> </div> </div> </div> </div> <div class="column is-one-half"> <div class="card card-home"> <div class="card-content"> <div class="has-text-centered"> <a href="/language/community"> <span class="icon is-large has-text-primary"> <svg class="svg-inline--fa fa-user-friends fa-w-20 icon-large" aria-hidden="true" data-prefix="fas" data-icon="user-friends" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 512" data-fa-i2svg=""><path fill="currentColor" d="M192 256c61.9 0 112-50.1 112-112S253.9 32 192 32 80 82.1 80 144s50.1 112 112 112zm76.8 32h-8.3c-20.8 10-43.9 16-68.5 16s-47.6-6-68.5-16h-8.3C51.6 288 0 339.6 0 403.2V432c0 26.5 21.5 48 48 48h288c26.5 0 48-21.5 48-48v-28.8c0-63.6-51.6-115.2-115.2-115.2zM480 256c53 0 96-43 96-96s-43-96-96-96-96 43-96 96 43 96 96 96zm48 32h-3.8c-13.9 4.8-28.6 8-44.2 8s-30.3-3.2-44.2-8H432c-20.4 0-39.2 5.9-55.7 15.4 24.4 26.3 39.7 61.2 39.7 99.8v38.4c0 2.2-.5 4.3-.6 6.4H592c26.5 0 48-21.5 48-48 0-61.9-50.1-112-112-112z"></path></svg><!-- <i class="fas fa-user-friends icon-large"></i> --> </span> </a> </div> <div class="content has-text-centered"> <p class="title is-5 has-text-primary"><a href="/language/community">Community</a></p> </div> <div class="content has-text-centered"> Information about the Raku development community, email lists, IRC and IRC bots, and blogs. </div> <div class="has-text-centered"> <a class="button is-primary" href="/language/community"> <strong>Learn more</strong> </a> </div> </div> </div> </div> <!-- Card ends --> <!-- Columns ends --> </div> </div> </section> <div class="raku links-block"> <div class="container px-4 py-5"> <div class="columns is-vcentered"> <div class="column is-one-third has-text-centered"> <div class="pt-5"> <span class="icon is-large"> <svg class="svg-inline--fa fa-hashtag fa-w-14 icon-large" aria-hidden="true" data-prefix="fas" data-icon="hashtag" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 448 512" data-fa-i2svg=""><path fill="currentColor" d="M440.667 182.109l7.143-40c1.313-7.355-4.342-14.109-11.813-14.109h-74.81l14.623-81.891C377.123 38.754 371.468 32 363.997 32h-40.632a12 12 0 0 0-11.813 9.891L296.175 128H197.54l14.623-81.891C213.477 38.754 207.822 32 200.35 32h-40.632a12 12 0 0 0-11.813 9.891L132.528 128H53.432a12 12 0 0 0-11.813 9.891l-7.143 40C33.163 185.246 38.818 192 46.289 192h74.81L98.242 320H19.146a12 12 0 0 0-11.813 9.891l-7.143 40C-1.123 377.246 4.532 384 12.003 384h74.81L72.19 465.891C70.877 473.246 76.532 480 84.003 480h40.632a12 12 0 0 0 11.813-9.891L151.826 384h98.634l-14.623 81.891C234.523 473.246 240.178 480 247.65 480h40.632a12 12 0 0 0 11.813-9.891L315.472 384h79.096a12 12 0 0 0 11.813-9.891l7.143-40c1.313-7.355-4.342-14.109-11.813-14.109h-74.81l22.857-128h79.096a12 12 0 0 0 11.813-9.891zM261.889 320h-98.634l22.857-128h98.634l-22.857 128z"></path></svg><!-- <i class="fas fa-hashtag icon-large"></i> --> </span> </div> </div> <div class="column is-two-thirds"> <div class="columns px-4"> <div class="column"> <p class="head">Community</p> <ul> <li><a href="https://www.reddit.com/r/rakulang/">Reddit</a></li> <li><a href="https://fosstodon.org/@rakulang">Mastodon</a></li> <li><a href="https://www.facebook.com/groups/1595443877388632/">Facebook</a></li> <li><a href="https://stackoverflow.com/questions/tagged/raku">Stack Overflow</a></li> </ul> </div> <div class="column"> <p class="head">Resources</p> <ul> <li><a href="https://raku.guide
