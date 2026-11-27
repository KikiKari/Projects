#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "f7ef5a0c839ca684f76711e8985c099b0031cc695495d4975ff220451532e245", "source_sha256": "0f3530ed5a95fa71241e65119ede0362d09d6dbde8fbabfc84d844298613edb6", "target_language": "lua"}
-- language.html — portiert nach lua
-- Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/raku/language.html
-- auch in: OpenClaw@gateway2:skills/scripting-utils/references/raku/language.html
-- Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

local function generate_404_page(output_file)
    local file = io.open(output_file, "w")
    if not file then
        print("Error: Could not open file " .. output_file .. " for writing")
        return false
    end

    -- Write DOCTYPE and html tag
    file:write('<!DOCTYPE html>\n')
    file:write('<html lang="en" class="fontawesome-i2svg-active fontawesome-i2svg-complete" style="scroll-padding-top:60px">\n')
    
    -- Head section
    file:write('<head>\n')
    file:write('    <title>404 | Raku Documentation</title>\n')
    file:write('    <meta charset="UTF-8" />\n')
    file:write('    \n')
    file:write('<link href="/assets/images/Camelia.ico" rel="icon" type="image/x-icon"/>\n')
    file:write('\n')
    file:write('    \n')
    file:write('    \n')
    
    -- Stylesheets
    local stylesheets = {
        "/assets/css/Website.css",
        {href="/assets/css/css/filtered-toc-dark.css", title="dark"},
        {href="/assets/css/css/filtered-toc-light.css", title="light"},
        {href="/assets/css/css/rainbow-dark.css", title="dark"},
        {href="/assets/css/css/rainbow-light.css", title="light"},
        "/assets/css/tm-styling.css",
        {href="/assets/css/tm-light.css", title="light"},
        {href="/assets/css/tm-dark.css", title="dark"},
        "/assets/css/all.min.css",
        {href="/assets/css/listf-styling-light.css", title="light"},
        {href="/assets/css/listf-styling-dark.css", title="dark"},
        "/assets/css/typegraph-styling.css",
        {href="/assets/css/typegraph-dark.css", title="dark"},
        {href="/assets/css/typegraph-light.css", title="light"},
        "/assets/css/css/page-styling-main.css",
        {href="/assets/css/css/page-styling-dark.css", title="dark"},
        {href="/assets/css/css/page-styling-light.css", title="light"},
        {href="/assets/css/css/chyronToggle-dark.css", title="dark"},
        {href="/assets/css/css/chyronToggle-light.css", title="light"},
        {href="/assets/css/css/centreToggle-dark.css", title="dark"},
        {href="/assets/css/css/centreToggle-light.css", title="light"},
        {href="/assets/css/css/options-search-light.css", title="light"},
        {href="/assets/css/css/options-search-dark.css", title="dark"},
        {href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-light.min.css", title="light"},
        {href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css", title="dark"},
        "https://cdn.jsdelivr.net/npm/@tarekraafat/autocomplete.js@10.2.7/dist/css/autoComplete.min.css"
    }
    
    for _, stylesheet in ipairs(stylesheets) do
        if type(stylesheet) == "string" then
            file:write('<link rel="stylesheet" href="' .. stylesheet .. '"/>\n')
        else
            file:write('<link rel="stylesheet" href="' .. stylesheet.href .. '" title="' .. stylesheet.title .. '"/>\n')
        end
    end
    
    -- Scripts
    file:write('    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>\n')
    local scripts = {
        "/assets/scripts/all.min.js",
        "/assets/scripts/tableManager.js",
        "/assets/scripts/filter-script.js",
        "https://cdn.jsdelivr.net/npm/fuzzysort@2.0.4/fuzzysort.min.js",
        "https://cdn.jsdelivr.net/npm/@tarekraafat/autocomplete.js@10.2.7/dist/autoComplete.min.js",
        "/assets/scripts/filtered-toc.js",
        "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js",
        "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/haskell.min.js",
        "/assets/scripts/options-search.js",
        "/assets/scripts/page-styling.js",
        "/assets/scripts/rainbow.js"
    }
    
    for _, script in ipairs(scripts) do
        file:write('<script src="' .. script .. '"></script>')
    end
    file:write('\n')
    file:write('</head>\n')
    
    -- Body start
    file:write('\n<body class="has-navbar-fixed-top">\n')
    file:write('<div id="404" class="top-of-page"></div>\n')
    
    -- Navigation bar
    file:write('<nav class="navbar is-fixed-top is-flex-touch" role="navigation" aria-label="main navigation">\n')
    file:write('        <div class="navbar-item" style="margin-left: auto;">\n')
    file:write('          <div class="left-bar-toggle" title="Toggle Table of Contents & Index">\n')
    file:write('      <label class="chyronToggle left">\n')
    file:write('          <input id="navbar-left-toggle" type="checkbox">\n')
    file:write('          <span class="text">Contents</span>\n')
    file:write('      </label>\n')
    file:write('  </div>\n')
    file:write('\n')
    file:write('    </div>\n')
    file:write('\n')
    file:write('    <div class="container is-justify-content-space-around">\n')
    file:write('        <div class="navbar-brand">\n')
    file:write('  <div class="navbar-logo">\n')
    file:write('    <a class="navbar-item" href="/">\n')
    file:write('      <img src="/assets/images/camelia-recoloured.png" alt="Raku" width="52.83" height="38">\n')
    file:write('    </a>\n')
    file:write('    <span class="navbar-logo-tm">tm</span>\n')
    file:write('  </div>\n')
    file:write('  <a role="button" class="navbar-burger burger" aria-label="menu" aria-expanded="false" data-target="navMenu">\n')
    file:write('    <span aria-hidden="true"></span>\n')
    file:write('    <span aria-hidden="true"></span>\n')
    file:write('    <span aria-hidden="true"></span>\n')
    file:write('  </a>\n')
    file:write('</div>\n')
    file:write('\n')
    file:write('          <div id="navMenu" class="navbar-menu">\n')
    file:write('    <div class="navbar-start">\n')
    file:write('        <a class="navbar-item" href="/introduction" title="Getting started, Tutorials, Migration guides">\n')
    file:write('            Introduction\n')
    file:write('        </a>\n')
    file:write('        <a class="navbar-item" href="/reference" title="Fundamentals, General reference">\n')
    file:write('            Reference\n')
    file:write('        </a>\n')
    file:write('        <a class="navbar-item" href="/miscellaneous" title="Programs, Experimental">\n')
    file:write('            Miscellaneous\n')
    file:write('        </a>\n')
    file:write('        <a class="navbar-item" href="/types" title="The core types (classes) available">\n')
    file:write('            Types\n')
    file:write('        </a>\n')
    file:write('        <a class="navbar-item" href="/routines" title="Searchable table of routines">\n')
    file:write('            Routines\n')
    file:write('        </a>\n')
    file:write('        <a class="navbar-item" href="https://raku.org" title="Home page for community">\n')
    file:write('            Raku<sup>®</sup>\n')
    file:write('        </a>\n')
    file:write('        <a class="navbar-item" href="https://web.libera.chat/#raku" title="IRC live chat">\n')
    file:write('            Chat\n')
    file:write('        </a>\n')
    file:write('        <div class="navbar-item has-dropdown is-hoverable">\n')
    file:write('          <a class="navbar-link">\n')
    file:write('            More\n')
    file:write('          </a>\n')
    file:write('          <div class="navbar-dropdown is-right is-rounded">\n')
    file:write('            \n')
    file:write('            <hr class="navbar-divider">\n')
    file:write('            <a class="navbar-item js-modal-trigger" data-target="download-ebook">\n')
    file:write('              Download E-Book (epub)\n')
    file:write('            </a>\n')
    file:write('        \n')
    file:write('            <hr class="navbar-divider">\n')
    file:write('            <a class="navbar-item" href="/about">\n')
    file:write('              About\n')
    file:write('            </a>\n')
    file:write('            <hr class="navbar-divider">\n')
    file:write('            <a class="navbar-item has-text-red" href="https://github.com/raku/doc-website/issues">\n')
    file:write('              Report an issue with this site\n')
    file:write('            </a>\n')
    file:write('            <hr class="navbar-divider">\n')
    file:write('            <a class="navbar-item" href="https://github.com/raku/doc/issues">\n')
    file:write('              Report an issue with the documentation content\n')
    file:write('            </a>\n')
    file:write('            \n')
    file:write('          </div>\n')
    file:write('        </div>\n')
    file:write('    </div>\n')
    file:write('        <div class="navbar-end navbar-search-wrapper">\n')
    file:write('        <div class="navbar-item">\n')
    file:write('            <div class="field has-addons">\n')
    file:write('                <div class="autoComplete_options">\n')
    file:write('                    <input class="control input" id="autoComplete" type="search" dir="ltr" spellcheck=false autocorrect="off" autocomplete="off" autocapitalize="off" placeholder="🔍 Type f to search for ...">\n')
    file:write('                </div>\n')
    file:write('                <div class="control" title="Search options">\n')
    file:write('                    <a class="button is-primary js-modal-trigger"\n')
    file:write('                        data-target="options-search-info">\n')
    file:write('                        <span class="icon">\n')
    file:write('                            <i class="fas fa-cogs"></i>\n')
    file:write('                        </span>\n')
    file:write('                    </a>\n')
    file:write('                </div>\n')
    file:write('            </div>\n')
    file:write('        </div>\n')
    file:write('    </div>\n')
    file:write('    <div id="options-search-info" class="modal">\n')
    file:write('        <div class="modal-background"></div>\n')
    file:write('        <div class="modal-content">\n')
    file:write('            <div class="box">\n')
    file:write('                <p>The last search was: <span id="selected-candidate" class="ss-selected"></span></p>\n')
    file:write('                <div class="control is-grouped is-grouped-centered options-search-controls">\n')
    file:write('                    <label class="centreToggle" title="Include extra information (Alt-E)" style="--switch-width: 10.5">\n')
    file:write('                       <input id="options-search-extra" type="checkbox">\n')
    file:write('                       <span class="text">Extra info</span>\n')
    file:write('                       <span class="on">yes</span>\n')
    file:write('                       <span class="off">no</span>\n')
    file:write('                    </label>\n')
    file:write('                <p>The search response can be shortened by excluding the extra information line (Alt-E)</p>\n')
    file:write('                    <label class="centreToggle" title="Search engine type Strict/Loose (Alt-L)" style="--switch-width: 10.5">\n')
    file:write('                       <input id="options-search-loose" type="checkbox">\n')
    file:write('                       <span class="text">Search type</span>\n')
    file:write('                       <span class="on">loose</span>\n')
    file:write('                       <span class="off">strict</span>\n')
    file:write('                    </label>\n')
    file:write('                <p> The search engine can perform a strict search (only the characters in the search\n')
    file:write('                box) or a loose search (Alt-L)</p>\n')
    file:write('                    <label class="centreToggle" title="Search in headings (Alt-H)" style="--switch-width: 10.5">\n')
    file:write('                       <input id="options-search-headings" type="checkbox">\n')
    file:write('                       <span class="text">Headings</span>\n')
    file:write('                       <span class="on">yes</span>\n')
    file:write('                       <span class="off">no</span>\n')
    file:write('                    </label>\n')
    file:write('                    <p>Search through headings in all web-pages (Alt-H)</p>\n')
    file:write('                    <label class="centreToggle" title="Search indexed items (Alt-I)" style="--switch-width: 10.5">\n')
    file:write('                       <input id="options-search-indexed" type="checkbox">\n')
    file:write('                       <span class="text">Indexed</span>\n')
    file:write('                       <span class="on">yes</span>\n')
    file:write('                       <span class="off">no</span>\n')
    file:write('                    </label>\n')
    file:write('                    <p>Search through all indexed items (Alt-I)</p>\n')
    file:write('                    <label class="centreToggle" title="Search composite pages (Alt-C)" style="--switch-width: 10.5">\n')
    file:write('                       <input id="options-search-composite" type="checkbox">\n')
    file:write('                       <span class="text">Composite</span>\n')
    file:write('                       <span class="on">yes</span>\n')
    file:write('                       <span class="off">no</span>\n')
    file:write('                    </label>\n')
    file:write('                    <p>Search in the names of composite pages, which combine similar information from\n')
    file:write('                    the main web pages (Alt-C)</p>\n')
    file:write('                    <label class="centreToggle" title="Search primary sources (Alt-P)" style="--switch-width: 10.5">\n')
    file:write('                       <input id="options-search-primary" type="checkbox">\n')
    file:write('                       <span class="text">Primary</span>\n')
    file:write('                       <span class="on">yes</span>\n')
    file:write('                       <span class="off">no</span>\n')
    file:write('                    </label>\n')
    file:write('                    <p>Search through the names of the main web pages (Alt-P)</p>\n')
    file:write('                    <label class="centreToggle" title="Open in new tab (Alt-Q)" style="--switch-width: 10.5">\n')
    file:write('                       <input id="options-search-newtab" type="checkbox">\n')
    file:write('                       <span class="text">New tab</span>\n')
    file:write('                       <span class="on">yes</span>\n')
    file:write('                       <span class="off">no</span>\n')
    file:write('                    </label>\n')
    file:write('                    <p>Once a search candidate has been chosen, it can be opened in a new tab or in the current\n')
    file:write('                    tab (Alt-Q)</p>\n')
    file:write('                    <p>If all else fails, an item is added to use the Google search engine on the whole site</p>\n')
    file:write('                    <button class="button is-warning" id="options-search-reset-defaults">Clear options, reset to defaults</button>\n')
    file:write('                    <p>Exit this page by pressing &lt;Escape&gt;, or clicking on X or on the background.</p>\n')
    file:write('                </div>\n')
    file:write('            </div>\n')
    file:write('        </div>\n')
    file:write('        <button class="modal-close is-large" aria-label="close"></button>\n')
    file:write('    </div>\n')
    file:write('\n')
    file:write('  </div>\n')
    file:write('         <div id="download-ebook" class="modal">\n')
    file:write('                    <div class="modal-background"></div>\n')
    file:write('                    <div class="modal-content">\n')
    file:write('                        <div class="box">\n')
    file:write('                            <p><a href="/RakuDocumentation.epub" download>RakuDocumentation.epub</a> is a work in\n')
    file:write('                            progress e-book. It targets the <a href="https://www.w3.org/publishing/epub3/">EPUB v3 specification</a>.\n')
    file:write('                            It needs testing on a variety of ereaders (some of which may still implicitly expect\n')
    file:write('                            compliance with EPUB v2). The CSS definitely needs enhancing (especially for code snippets).\n')
    file:write('                            The Ebook opens in a Calibre reader, which is available on all operating systems.</p>\n')
    file:write('                            <p>Suggestions are welcome and should be addressed by opening an issue on\n')
    file:write('                            the Raku/doc-website repository</p>\n')
    file:write('                            <p>Exit this popup by pressing &lt;Escape&gt;, or clicking on X or on the background.</p>\n')
    file:write('                        </div>\n')
    file:write('                    </div>\n')
    file:write('                    <button class="modal-close is-large" aria-label="close"></button>\n')
    file:write('                </div>\n')
    file:write('        \n')
    file:write('  \n')
    file:write('\n')
    file:write('    </div>\n')
    file:write('</nav>\n')
    file:write('\n')
    file:write('<div class="tile is-ancestor section">\n')
    file:write('    <div class="page-edit">\n')
    file:write('    <a class="button page-edit-button"\n')
    file:write('       href="https://github.com/Raku/doc-website/edit/main/Website/structure-sources/404.rakudoc"\n')
    file:write('       title="Edit this page.&#13;Commit: 0ead45c 2026-04-04">\n')
    file:write('      <span class="icon is-right">\n')
    file:write('        <i class="fas fa-pen-alt is-medium"></i>\n')
    file:write('      </span>\n')
    file:write('    </a>\n')
    file:write('  </div>\n')
    file:write('\n')
    file:write('    <div id="left-column" class="tile is-parent is-2 is-hidden">\n')
    file:write('        <div id="left-col-inner">\n')
    file:write('                <input type="checkbox" id="No-TOC"\n')
    file:write('        checked="checked"\n')
    file:write('        style="visibility: collapse;">\n')
    file:write('    </input>\n')
    file:write('    <div class="content">No Table of Contents or Index available</div>\n')
    file:write('\n')
    file:write('        </div>\n')
    file:write('    </div>\n')
    file:write('    <div id="main-column" class="tile is-parent" style="overflow-x: hidden;">\n')
    file:write('        <div id="main-col-inner">\n')
    file:write('            <section class="raku page-header">\n')
    file:write('    <div class="container px-4">\n')
    file:write('        <div class="raku page-title has-text-centered">\n')
    file:write('        404\n')
    file:write('        </div>\n')
    file:write('        <div class="raku page-subtitle has-text-centered">\n')
    file:write('        \n')
    file:write('        </div>\n')
    file:write('    </div>\n')
    file:write('</section>\n')
    file:write('<section class="raku page-content"><div class="container px-4"><div class="columns one-col"><img src="/assets/images/Camelia-404.png" class="camelia">\n')
    file:write('\n')
    file:write('<h2 id="404:_Page_Not_Found" class="raku-h2"><a href="#404" title="go to top of document">404: Page Not Found<a class="raku-anchor" title="direct link" href="#404:_Page_Not_Found">§</a></a></h2>\n')
    file:write('<p>We\'re sorry, but the content you tried to reach wasn\'t found.</p><p>While we do review server logs to catch these issues, we recently deployed a new version of the site, so please feel free to <a href="https://github.com/Raku/doc-website/issues/">report any issues</a>.</p><p>Thanks!</p>\n')
    file:write('\n')
    file:write('</div></div></section>\n')
    file:write('\n')
    file:write('        </div>\n')
    file:write('    </div>\n')
    file:write('</div>\n')
    file:write('\n')
    file:write('<footer class="footer main-footer">\n')
    file:write('  <div class="container px-4">\n')
    file:write('    <nav class="level">\n')
    file:write('    <div class="level-left">\n')
    file:write('    <div class="level-item">\n')
    file:write('      <a href="/about">About</a>\n')
    file:write('    </div>\n')
    file:write('    <div class="level-item">\n')
    file:write('      <a id="toggle-theme">Toggle theme</a>\n')
    file:write('    </div>\n')
    file:write('        <div class="level-item" title="0ead45c 2026-04-04">\n')
    file:write('      <a>Commit</a>\n')
    file:write('    </div>\n')
    file:write('\n')
    file:write('</div>\n')
    file:write('\n')
    file:write('    <div class="level-right">\n')
    file:write('    <div class="level-item">\n')
    file:write('      <a href="/license">License</a>\n')
    file:write('    </div>\n')
    file:write('</div>\n')
    file:write('\n')
    file:write('    </nav>\n')
    file:write('  </div>\n')
    file:write('</footer>\n')
    file:write('\n')
    file:write('\n')
    file:write('</body>\n')
    file:write('</html>\n')
    
    file:close()
    return true
end

-- Main execution
if #arg ~= 1 then
    print("Usage: " .. arg[0] .. " <output_file>")
    os.exit(1)
end

local output_file = arg[1]
if generate_404_page(output_file) then
    print("Successfully generated " .. output_file)
else
    os.exit(1)
end
