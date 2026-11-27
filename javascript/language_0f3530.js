#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "d22cb64358d3c2eac95bde1795f855a6e2a0a65b1f0f543ad5545afd7e4c1aeb", "source_sha256": "0f3530ed5a95fa71241e65119ede0362d09d6dbde8fbabfc84d844298613edb6", "target_language": "javascript"}
// language.html — portiert nach javascript
// Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/raku/language.html
// auch in: OpenClaw@gateway2:skills/scripting-utils/references/raku/language.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function generate404Page() {
    const docType = '<!DOCTYPE html>';
    
    // Create html element with attributes
    const htmlAttrs = {
        lang: "en",
        class: "fontawesome-i2svg-active fontawesome-i2svg-complete",
        style: "scroll-padding-top:60px"
    };
    
    // Head section
    const head = createHead();
    
    // Body section
    const body = createBody();
    
    // Assemble complete document
    let html = docType + '\n';
    html += createElement('html', htmlAttrs, '\n' + head + '\n' + body + '\n');
    
    return html;
}

function createHead() {
    let headContent = '';
    
    // Title
    headContent += createElement('title', {}, '404 | Raku Documentation') + '\n';
    
    // Meta charset
    headContent += createElement('meta', { charset: "UTF-8" }) + '\n';
    
    // Links
    const links = [
        { href: "/assets/images/Camelia.ico", rel: "icon", type: "image/x-icon" },
        { href: "/assets/css/Website.css", rel: "stylesheet" },
        { href: "/assets/css/css/filtered-toc-dark.css", rel: "stylesheet", title: "dark" },
        { href: "/assets/css/css/filtered-toc-light.css", rel: "stylesheet", title: "light" },
        { href: "/assets/css/css/rainbow-dark.css", rel: "stylesheet", title: "dark" },
        { href: "/assets/css/css/rainbow-light.css", rel: "stylesheet", title: "light" },
        { href: "/assets/css/tm-styling.css", rel: "stylesheet" },
        { href: "/assets/css/tm-light.css", rel: "stylesheet", title: "light" },
        { href: "/assets/css/tm-dark.css", rel: "stylesheet", title: "dark" },
        { href: "/assets/css/all.min.css", rel: "stylesheet" },
        { href: "/assets/css/listf-styling-light.css", rel: "stylesheet", title: "light" },
        { href: "/assets/css/listf-styling-dark.css", rel: "stylesheet", title: "dark" },
        { href: "/assets/css/typegraph-styling.css", rel: "stylesheet" },
        { href: "/assets/css/typegraph-dark.css", rel: "stylesheet", title: "dark" },
        { href: "/assets/css/typegraph-light.css", rel: "stylesheet", title: "light" },
        { href: "/assets/css/css/page-styling-main.css", rel: "stylesheet" },
        { href: "/assets/css/css/page-styling-dark.css", rel: "stylesheet", title: "dark" },
        { href: "/assets/css/css/page-styling-light.css", rel: "stylesheet", title: "light" },
        { href: "/assets/css/css/chyronToggle-dark.css", rel: "stylesheet", title: "dark" },
        { href: "/assets/css/css/chyronToggle-light.css", rel: "stylesheet", title: "light" },
        { href: "/assets/css/css/centreToggle-dark.css", rel: "stylesheet", title: "dark" },
        { href: "/assets/css/css/centreToggle-light.css", rel: "stylesheet", title: "light" },
        { href: "/assets/css/css/options-search-light.css", rel: "stylesheet", title: "light" },
        { href: "/assets/css/css/options-search-dark.css", rel: "stylesheet", title: "dark" },
        { href: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-light.min.css", rel: "stylesheet", title: "light" },
        { href: "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css", rel: "stylesheet", title: "dark" },
        { href: "https://cdn.jsdelivr.net/npm/@tarekraafat/autocomplete.js@10.2.7/dist/css/autoComplete.min.css", rel: "stylesheet" }
    ];
    
    links.forEach(link => {
        headContent += createElement('link', link) + '\n';
    });
    
    // Scripts
    const scripts = [
        'https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js',
        '/assets/scripts/all.min.js',
        '/assets/scripts/tableManager.js',
        '/assets/scripts/filter-script.js',
        'https://cdn.jsdelivr.net/npm/fuzzysort@2.0.4/fuzzysort.min.js',
        'https://cdn.jsdelivr.net/npm/@tarekraafat/autocomplete.js@10.2.7/dist/autoComplete.min.js',
        '/assets/scripts/filtered-toc.js',
        'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js',
        'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/haskell.min.js',
        '/assets/scripts/options-search.js',
        '/assets/scripts/page-styling.js',
        '/assets/scripts/rainbow.js'
    ];
    
    scripts.forEach(src => {
        headContent += createElement('script', { src: src }, '') + '\n';
    });
    
    return createElement('head', {}, headContent);
}

function createBody() {
    let bodyContent = '';
    
    // Add body classes
    const bodyAttrs = { class: "has-navbar-fixed-top" };
    
    // Top anchor
    bodyContent += createElement('div', { id: "404", class: "top-of-page" }) + '\n';
    
    // Navigation
    bodyContent += createNavigation() + '\n';
    
    // Main content
    bodyContent += createMainContent() + '\n';
    
    // Footer
    bodyContent += createFooter() + '\n';
    
    return createElement('body', bodyAttrs, '\n' + bodyContent);
}

function createNavigation() {
    let navContent = '';
    
    // Left bar toggle
    navContent += createElement('div', { class: "navbar-item", style: "margin-left: auto;" }, 
        '\n' + createElement('div', { class: "left-bar-toggle", title: "Toggle Table of Contents & Index" },
            '\n' + createElement('label', { class: "chyronToggle left" },
                '\n' + createElement('input', { id: "navbar-left-toggle", type: "checkbox" }) + '\n' +
                createElement('span', { class: "text" }, 'Contents') + '\n'
            ) + '\n'
        ) + '\n'
    ) + '\n';
    
    // Container
    navContent += createElement('div', { class: "container is-justify-content-space-around" },
        '\n' + createNavbarBrand() + '\n' + createNavbarMenu() + '\n'
    ) + '\n';
    
    return createElement('nav', { 
        class: "navbar is-fixed-top is-flex-touch", 
        role: "navigation", 
        ariaLabel: "main navigation" 
    }, '\n' + navContent + '\n');
}

function createNavbarBrand() {
    let brandContent = '';
    
    // Logo
    brandContent += createElement('div', { class: "navbar-logo" },
        '\n' + createElement('a', { class: "navbar-item", href: "/" },
            '\n' + createElement('img', { 
                src: "/assets/images/camelia-recoloured.png", 
                alt: "Raku", 
                width: "52.83", 
                height: "38" 
            }) + '\n'
        ) + '\n' +
        createElement('span', { class: "navbar-logo-tm" }, 'tm') + '\n'
    ) + '\n';
    
    // Burger menu
    brandContent += createElement('a', { 
        role: "button", 
        class: "navbar-burger burger", 
        ariaLabel: "menu", 
        ariaExpanded: "false", 
        'data-target': "navMenu" 
    },
        '\n' + createElement('span', { 'aria-hidden': "true" }) + '\n' +
        createElement('span', { 'aria-hidden': "true" }) + '\n' +
        createElement('span', { 'aria-hidden': "true" }) + '\n'
    ) + '\n';
    
    return createElement('div', { class: "navbar-brand" }, '\n' + brandContent);
}

function createNavbarMenu() {
    let menuContent = '';
    
    // Start section
    menuContent += createElement('div', { class: "navbar-start" },
        '\n' + createNavLinks() + '\n'
    ) + '\n';
    
    // End section (search)
    menuContent += createElement('div', { class: "navbar-end navbar-search-wrapper" },
        '\n' + createSearchBar() + '\n'
    ) + '\n';
    
    // Modals
    menuContent += createModals() + '\n';
    
    return createElement('div', { id: "navMenu", class: "navbar-menu" }, '\n' + menuContent);
}

function createNavLinks() {
    let links = '';
    
    const navItems = [
        { href: "/introduction", title: "Getting started, Tutorials, Migration guides", text: "Introduction" },
        { href: "/reference", title: "Fundamentals, General reference", text: "Reference" },
        { href: "/miscellaneous", title: "Programs, Experimental", text: "Miscellaneous" },
        { href: "/types", title: "The core types (classes) available", text: "Types" },
        { href: "/routines", title: "Searchable table of routines", text: "Routines" },
        { href: "https://raku.org", title: "Home page for community", text: "Raku<sup>®</sup>" },
        { href: "https://web.libera.chat/#raku", title: "IRC live chat", text: "Chat" }
    ];
    
    navItems.forEach(item => {
        links += createElement('a', { class: "navbar-item", href: item.href, title: item.title }, item.text) + '\n';
    });
    
    // More dropdown
    links += createElement('div', { class: "navbar-item has-dropdown is-hoverable" },
        '\n' + createElement('a', { class: "navbar-link" }, 'More') + '\n' +
        createElement('div', { class: "navbar-dropdown is-right is-rounded" },
            '\n' + createElement('hr', { class: "navbar-divider" }) + '\n' +
            createElement('a', { class: "navbar-item js-modal-trigger", 'data-target': "download-ebook" }, 'Download E-Book (epub)') + '\n' +
            createElement('hr', { class: "navbar-divider" }) + '\n' +
            createElement('a', { class: "navbar-item", href: "/about" }, 'About') + '\n' +
            createElement('hr', { class: "navbar-divider" }) + '\n' +
            createElement('a', { class: "navbar-item has-text-red", href: "https://github.com/raku/doc-website/issues" }, 'Report an issue with this site') + '\n' +
            createElement('hr', { class: "navbar-divider" }) + '\n' +
            createElement('a', { class: "navbar-item", href: "https://github.com/raku/doc/issues" }, 'Report an issue with the documentation content') + '\n'
        ) + '\n'
    ) + '\n';
    
    return links;
}

function createSearchBar() {
    return createElement('div', { class: "navbar-item" },
        '\n' + createElement('div', { class: "field has-addons" },
            '\n' + createElement('div', { class: "autoComplete_options" },
                '\n' + createElement('input', { 
                    class: "control input", 
                    id: "autoComplete", 
                    type: "search", 
                    dir: "ltr", 
                    spellcheck: "false", 
                    autocorrect: "off", 
                    autocomplete: "off", 
                    autocapitalize: "off", 
                    placeholder: "🔍 Type f to search for ..." 
                }) + '\n'
            ) + '\n' +
            createElement('div', { class: "control", title: "Search options" },
                '\n' + createElement('a', { 
                    class: "button is-primary js-modal-trigger", 
                    'data-target': "options-search-info" 
                },
                    '\n' + createElement('span', { class: "icon" },
                        '\n' + createElement('i', { class: "fas fa-cogs" }) + '\n'
                    ) + '\n'
                ) + '\n'
            ) + '\n'
        ) + '\n'
    );
}

function createModals() {
    let modals = '';
    
    // Options search modal
    modals += createElement('div', { id: "options-search-info", class: "modal" },
        '\n' + createElement('div', { class: "modal-background" }) + '\n' +
        createElement('div', { class: "modal-content" },
            '\n' + createElement('div', { class: "box" },
                '\n' + createElement('p', {}, 'The last search was: ' + 
                    createElement('span', { id: "selected-candidate", class: "ss-selected" }, '')
                ) + '\n' +
                createElement('div', { class: "control is-grouped is-grouped-centered options-search-controls" },
                    '\n' + createSearchOption('extra', 'Include extra information (Alt-E)', 'Extra info', 'yes', 'no') + '\n' +
                    createElement('p', {}, 'The search response can be shortened by excluding the extra information line (Alt-E)') + '\n' +
                    createSearchOption('loose', 'Search engine type Strict/Loose (Alt-L)', 'Search type', 'loose', 'strict') + '\n' +
                    createElement('p', {}, ' The search engine can perform a strict search (only the characters in the search box) or a loose search (Alt-L)') + '\n' +
                    createSearchOption('headings', 'Search in headings (Alt-H)', 'Headings', 'yes', 'no') + '\n' +
                    createElement('p', {}, 'Search through headings in all web-pages (Alt-H)') + '\n' +
                    createSearchOption('indexed', 'Search indexed items (Alt-I)', 'Indexed', 'yes', 'no') + '\n' +
                    createElement('p', {}, 'Search through all indexed items (Alt-I)') + '\n' +
                    createSearchOption('composite', 'Search composite pages (Alt-C)', 'Composite', 'yes', 'no') + '\n' +
                    createElement('p', {}, 'Search in the names of composite pages, which combine similar information from the main web pages (Alt-C)') + '\n' +
                    createSearchOption('primary', 'Search primary sources (Alt-P)', 'Primary', 'yes', 'no') + '\n' +
                    createElement('p', {}, 'Search through the names of the main web pages (Alt-P)') + '\n' +
                    createSearchOption('newtab', 'Open in new tab (Alt-Q)', 'New tab', 'yes', 'no') + '\n' +
                    createElement('p', {}, 'Once a search candidate has been chosen, it can be opened in a new tab or in the current tab (Alt-Q)') + '\n' +
                    createElement('p', {}, 'If all else fails, an item is added to use the Google search engine on the whole site') + '\n' +
                    createElement('button', { class: "button is-warning", id: "options-search-reset-defaults" }, 'Clear options, reset to defaults') + '\n' +
                    createElement('p', {}, 'Exit this page by pressing &lt;Escape&gt;, or clicking on X or on the background.') + '\n'
                ) + '\n'
            ) + '\n'
        ) + '\n' +
        createElement('button', { class: "modal-close is-large", 'aria-label': "close" }) + '\n'
    ) + '\n';
    
    // Download ebook modal
    modals += createElement('div', { id: "download-ebook", class: "modal" },
        '\n' + createElement('div', { class: "modal-background" }) + '\n' +
        createElement('div', { class: "modal-content" },
            '\n' + createElement('div', { class: "box" },
                '\n' + createElement('p', {},
                    createElement('a', { href: "/RakuDocumentation.epub", download: "RakuDocumentation.epub" }, 'RakuDocumentation.epub') + 
                    ' is a work in progress e-book. It targets the ' + 
                    createElement('a', { href: "https://www.w3.org/publishing/epub3/" }, 'EPUB v3 specification') + 
                    '. It needs testing on a variety of ereaders (some of which may still implicitly expect compliance with EPUB v2). The CSS definitely needs enhancing (especially for code snippets). The Ebook opens in a Calibre reader, which is available on all operating systems.'
                ) + '\n' +
                createElement('p', {}, 'Suggestions are welcome and should be addressed by opening an issue on the Raku/doc-website repository') + '\n' +
                createElement('p', {}, 'Exit this popup by pressing &lt;Escape&gt;, or clicking on X or on the background.') + '\n'
            ) + '\n'
        ) + '\n' +
        createElement('button', { class: "modal-close is-large", 'aria-label': "close" }) + '\n'
    ) + '\n';
    
    return modals;
}

function createSearchOption(id, title, labelText, onText, offText) {
    return createElement('label', { class: "centreToggle", title: title, style: "--switch-width: 10.5" },
        '\n' + createElement('input', { id: `options-search-${id}`, type: "checkbox" }) + '\n' +
        createElement('span', { class: "text" }, labelText) + '\n' +
        createElement('span', { class: "on" }, onText) + '\n' +
        createElement('span', { class: "off" }, offText) + '\n'
    );
}

function createMainContent() {
    let content = '';
    
    // Edit button
    content += createElement('div', { class: "page-edit" },
        '\n' + createElement('a', { 
            class: "button page-edit-button", 
            href: "https://github.com/Raku/doc-website/edit/main/Website/structure-sources/404.rakudoc", 
            title: "Edit this page.\nCommit: 0ead45c 2026-04-04" 
        },
            '\n' + createElement('span', { class: "icon is-right" },
                '\n' + createElement('i', { class: "fas fa-pen-alt is-medium" }) + '\n'
            ) + '\n'
        ) + '\n'
    ) + '\n';
    
    // Tile structure
    content += createElement('div', { class: "tile is-ancestor section" },
        '\n' + createLeftColumn() + '\n' + createMainColumn() + '\n'
    ) + '\n';
    
    return content;
}

function createLeftColumn() {
    return createElement('div', { id: "left-column", class: "tile is-parent is-2 is-hidden" },
        '\n' + createElement('div', { id: "left-col-inner" },
            '\n' + createElement('input', { 
                type: "checkbox", 
                id: "No-TOC", 
                checked: "checked", 
                style: "visibility: collapse;" 
            }) + '\n' +
            createElement('div', { class: "content" }, 'No Table of Contents or Index available') + '\n'
        ) + '\n'
    );
}

function createMainColumn() {
    return createElement('div', { id: "main-column", class: "tile is-parent", style: "overflow-x: hidden;" },
        '\n' + createElement('div', { id: "main-col-inner" },
            '\n' + createPageHeader() + '\n' + createPageContent() + '\n'
        ) + '\n'
    );
}

function createPageHeader() {
    return createElement('section', { class: "raku page-header" },
        '\n' + createElement('div', { class: "container px-4" },
            '\n' + createElement('div', { class: "raku page-title has-text-centered" }, '404') + '\n' +
            createElement('div', { class: "raku page-subtitle has-text-centered" }) + '\n'
        ) + '\n'
    );
}

function createPageContent() {
    return createElement('section', { class: "raku page-content" },
        '\n' + createElement('div', { class: "container px-4" },
            '\n' + createElement('div', { class: "columns one-col" },
                '\n' + createElement('img', { src: "/assets/images/Camelia-404.png", class: "camelia" }) + '\n' +
                createElement('h2', { id: "404:_Page_Not_Found", class: "raku-h2" },
                    createElement('a', { href: "#404", title: "go to top of document" }, 
                        '404: Page Not Found' + 
                        createElement('a', { class: "raku-anchor", title: "direct link", href: "#404:_Page_Not_Found" }, '§')
                    )
                ) + '\n' +
                createElement('p', {}, "We're sorry, but the content you tried to reach wasn't found.") + '\n' +
                createElement('p', {}, 
                    'While we do review server logs to catch these issues, we recently deployed a new version of the site, so please feel free to ' + 
                    createElement('a', { href: "https://github.com/Raku/doc-website/issues/" }, 'report any issues') + '.'
                ) + '\n' +
                createElement('p', {}, 'Thanks!') + '\n'
            ) + '\n'
        ) + '\n'
    );
}

function createFooter() {
    return createElement('footer', { class: "footer main-footer" },
        '\n' + createElement('div', { class: "container px-4" },
            '\n' + createElement('nav', { class: "level" },
                '\n' + createElement('div', { class: "level-left" },
                    '\n' + createElement('div', { class: "level-item" },
                        '\n' + createElement('a', { href: "/about" }, 'About') + '\n'
                    ) + '\n' +
                    createElement('div', { class: "level-item" },
                        '\n' + createElement('a', { id: "toggle-theme" }, 'Toggle theme') + '\n'
                    ) + '\n' +
                    createElement('div', { class: "level-item", title: "0ead45c 2026-04-04" },
                        '\n' + createElement('a', {}, 'Commit') + '\n'
                    ) + '\n'
                ) + '\n' +
                createElement('div', { class: "level-right" },
                    '\n' + createElement('div', { class: "level-item" },
                        '\n' + createElement('a', { href: "/license" }, 'License') + '\n'
                    ) + '\n'
                ) + '\n'
            ) + '\n'
        ) + '\n'
    );
}

function createElement(tag, attrs, content = '') {
    let attrString = '';
    
    for (const [key, value] of Object.entries(attrs)) {
        if (value !== undefined && value !== null) {
            // Handle special cases like aria-label
            const attrName = key.replace(/([A-Z])/g, '-$1').toLowerCase();
            attrString += ` ${attrName}="${value}"`;
        }
    }
    
    if (tag === 'img' || tag === 'meta' || tag === 'input' || tag === 'link' || tag === 'br' || tag === 'hr') {
        return `<${tag}${attrString}>`;
    } else if (content === '') {
        return `<${tag}${attrString}></${tag}>`;
    } else {
        return `<${tag}${attrString}>${content}</${tag}>`;
    }
}

// Main execution
if (require.main === module) {
    const outputFile = process.argv[2] || 'language.html';
    const htmlContent = generate404Page();
    
    fs.writeFileSync(outputFile, htmlContent, 'utf8');
    console.log(`404 page generated: ${outputFile}`);
}

module.exports = { generate404Page };
