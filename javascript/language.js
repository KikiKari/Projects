#!/usr/bin/env node
// language.html — portiert nach javascript
// Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/raku/language.html
// auch in: OpenClaw@gateway2:skills/scripting-utils/references/raku/language.html
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function generate404Page() {
    const doc = {
        type: 'tag',
        name: 'html',
        attribs: {
            lang: 'en',
            class: 'fontawesome-i2svg-active fontawesome-i2svg-complete',
            style: 'scroll-padding-top:60px'
        },
        children: [
            createHead(),
            createBody()
        ]
    };

    return '<!DOCTYPE html>\n' + renderElement(doc);
}

function createHead() {
    return {
        type: 'tag',
        name: 'head',
        children: [
            { type: 'tag', name: 'title', children: [{ type: 'text', data: '404 | Raku Documentation' }] },
            { type: 'tag', name: 'meta', attribs: { charset: 'UTF-8' } },
            createLink('/assets/images/Camelia.ico', 'icon', 'image/x-icon'),
            createLink('/assets/css/Website.css', 'stylesheet'),
            createLink('/assets/css/css/filtered-toc-dark.css', 'stylesheet', 'dark'),
            createLink('/assets/css/css/filtered-toc-light.css', 'stylesheet', 'light'),
            createLink('/assets/css/css/rainbow-dark.css', 'stylesheet', 'dark'),
            createLink('/assets/css/css/rainbow-light.css', 'stylesheet', 'light'),
            createLink('/assets/css/tm-styling.css', 'stylesheet'),
            createLink('/assets/css/tm-light.css', 'stylesheet', 'light'),
            createLink('/assets/css/tm-dark.css', 'stylesheet', 'dark'),
            createLink('/assets/css/all.min.css', 'stylesheet'),
            createLink('/assets/css/listf-styling-light.css', 'stylesheet', 'light'),
            createLink('/assets/css/listf-styling-dark.css', 'stylesheet', 'dark'),
            createLink('/assets/css/typegraph-styling.css', 'stylesheet'),
            createLink('/assets/css/typegraph-dark.css', 'stylesheet', 'dark'),
            createLink('/assets/css/typegraph-light.css', 'stylesheet', 'light'),
            createLink('/assets/css/css/page-styling-main.css', 'stylesheet'),
            createLink('/assets/css/css/page-styling-dark.css', 'stylesheet', 'dark'),
            createLink('/assets/css/css/page-styling-light.css', 'stylesheet', 'light'),
            createLink('/assets/css/css/chyronToggle-dark.css', 'stylesheet', 'dark'),
            createLink('/assets/css/css/chyronToggle-light.css', 'stylesheet', 'light'),
            createLink('/assets/css/css/centreToggle-dark.css', 'stylesheet', 'dark'),
            createLink('/assets/css/css/centreToggle-light.css', 'stylesheet', 'light'),
            createLink('/assets/css/css/options-search-light.css', 'stylesheet', 'light'),
            createLink('/assets/css/css/options-search-dark.css', 'stylesheet', 'dark'),
            createLink('https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-light.min.css', 'stylesheet', 'light'),
            createLink('https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css', 'stylesheet', 'dark'),
            createLink('https://cdn.jsdelivr.net/npm/@tarekraafat/autocomplete.js@10.2.7/dist/css/autoComplete.min.css', 'stylesheet'),
            createScript('https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js'),
            createScript('/assets/scripts/all.min.js'),
            createScript('/assets/scripts/tableManager.js'),
            createScript('/assets/scripts/filter-script.js'),
            createScript('https://cdn.jsdelivr.net/npm/fuzzysort@2.0.4/fuzzysort.min.js'),
            createScript('https://cdn.jsdelivr.net/npm/@tarekraafat/autocomplete.js@10.2.7/dist/autoComplete.min.js'),
            createScript('/assets/scripts/filtered-toc.js'),
            createScript('https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js'),
            createScript('https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/haskell.min.js'),
            createScript('/assets/scripts/options-search.js'),
            createScript('/assets/scripts/page-styling.js'),
            createScript('/assets/scripts/rainbow.js')
        ]
    };
}

function createBody() {
    return {
        type: 'tag',
        name: 'body',
        attribs: { class: 'has-navbar-fixed-top' },
        children: [
            { type: 'tag', name: 'div', attribs: { id: '404', class: 'top-of-page' } },
            createNavbar(),
            createMainContent(),
            createFooter()
        ]
    };
}

function createLink(href, rel, title) {
    const link = { type: 'tag', name: 'link', attribs: { href, rel } };
    if (title) link.attribs.title = title;
    return link;
}

function createScript(src) {
    return { type: 'tag', name: 'script', attribs: { src } };
}

function createNavbar() {
    return {
        type: 'tag',
        name: 'nav',
        attribs: { class: 'navbar is-fixed-top is-flex-touch', role: 'navigation', 'aria-label': 'main navigation' },
        children: [
            {
                type: 'tag',
                name: 'div',
                attribs: { class: 'navbar-item', style: 'margin-left: auto;' },
                children: [
                    {
                        type: 'tag',
                        name: 'div',
                        attribs: { class: 'left-bar-toggle', title: 'Toggle Table of Contents & Index' },
                        children: [
                            {
                                type: 'tag',
                                name: 'label',
                                attribs: { class: 'chyronToggle left' },
                                children: [
                                    { type: 'tag', name: 'input', attribs: { id: 'navbar-left-toggle', type: 'checkbox' } },
                                    { type: 'tag', name: 'span', attribs: { class: 'text' }, children: [{ type: 'text', data: 'Contents' }] }
                                ]
                            }
                        ]
                    }
                ]
            },
            {
                type: 'tag',
                name: 'div',
                attribs: { class: 'container is-justify-content-space-around' },
                children: [
                    {
                        type: 'tag',
                        name: 'div',
                        attribs: { class: 'navbar-brand' },
                        children: [
                            {
                                type: 'tag',
                                name: 'div',
                                attribs: { class: 'navbar-logo' },
                                children: [
                                    {
                                        type: 'tag',
                                        name: 'a',
                                        attribs: { class: 'navbar-item', href: '/' },
                                        children: [
                                            {
                                                type: 'tag',
                                                name: 'img',
                                                attribs: {
                                                    src: '/assets/images/camelia-recoloured.png',
                                                    alt: 'Raku',
                                                    width: '52.83',
                                                    height: '38'
                                                }
                                            }
                                        ]
                                    },
                                    { type: 'tag', name: 'span', attribs: { class: 'navbar-logo-tm' }, children: [{ type: 'text', data: 'tm' }] }
                                ]
                            },
                            {
                                type: 'tag',
                                name: 'a',
                                attribs: {
                                    role: 'button',
                                    class: 'navbar-burger burger',
                                    'aria-label': 'menu',
                                    'aria-expanded': 'false',
                                    'data-target': 'navMenu'
                                },
                                children: [
                                    { type: 'tag', name: 'span', attribs: { 'aria-hidden': 'true' } },
                                    { type: 'tag', name: 'span', attribs: { 'aria-hidden': 'true' } },
                                    { type: 'tag', name: 'span', attribs: { 'aria-hidden': 'true' } }
                                ]
                            }
                        ]
                    },
                    createNavMenu()
                ]
            }
        ]
    };
}

function createNavMenu() {
    return {
        type: 'tag',
        name: 'div',
        attribs: { id: 'navMenu', class: 'navbar-menu' },
        children: [
            {
                type: 'tag',
                name: 'div',
                attribs: { class: 'navbar-start' },
                children: [
                    { type: 'tag', name: 'a', attribs: { class: 'navbar-item', href: '/introduction', title: 'Getting started, Tutorials, Migration guides' }, children: [{ type: 'text', data: 'Introduction' }] },
                    { type: 'tag', name: 'a', attribs: { class: 'navbar-item', href: '/reference', title: 'Fundamentals, General reference' }, children: [{ type: 'text', data: 'Reference' }] },
                    { type: 'tag', name: 'a', attribs: { class: 'navbar-item', href: '/miscellaneous', title: 'Programs, Experimental' }, children: [{ type: 'text', data: 'Miscellaneous' }] },
                    { type: 'tag', name: 'a', attribs: { class: 'navbar-item', href: '/types', title: 'The core types (classes) available' }, children: [{ type: 'text', data: 'Types' }] },
                    { type: 'tag', name: 'a', attribs: { class: 'navbar-item', href: '/routines', title: 'Searchable table of routines' }, children: [{ type: 'text', data: 'Routines' }] },
                    { type: 'tag', name: 'a', attribs: { class: 'navbar-item', href: 'https://raku.org', title: 'Home page for community' }, children: [{ type: 'text', data: 'Raku' }, { type: 'tag', name: 'sup', attribs: { class: 'raku' }, children: [{ type: 'text', data: '®' }] }] },
                    { type: 'tag', name: 'a', attribs: { class: 'navbar-item', href: 'https://web.libera.chat/#raku', title: 'IRC live chat' }, children: [{ type: 'text', data: 'Chat' }] },
                    createMoreDropdown()
                ]
            },
            createSearchBar()
        ]
    };
}

function createMoreDropdown() {
    return {
        type: 'tag',
        name: 'div',
        attribs: { class: 'navbar-item has-dropdown is-hoverable' },
        children: [
            { type: 'tag', name: 'a', attribs: { class: 'navbar-link' }, children: [{ type: 'text', data: 'More' }] },
            {
                type: 'tag',
                name: 'div',
                attribs: { class: 'navbar-dropdown is-right is-rounded' },
                children: [
                    { type: 'tag', name: 'hr', attribs: { class: 'navbar-divider' } },
                    { type: 'tag', name: 'a', attribs: { class: 'navbar-item js-modal-trigger', 'data-target': 'download-ebook' }, children: [{ type: 'text', data: 'Download E-Book (epub)' }] },
                    { type: 'tag', name: 'hr', attribs: { class: 'navbar-divider' } },
                    { type: 'tag', name: 'a', attribs: { class: 'navbar-item', href: '/about' }, children: [{ type: 'text', data: 'About' }] },
                    { type: 'tag', name: 'hr', attribs: { class: 'navbar-divider' } },
                    { type: 'tag', name: 'a', attribs: { class: 'navbar-item has-text-red', href: 'https://github.com/raku/doc-website/issues' }, children: [{ type: 'text', data: 'Report an issue with this site' }] },
                    { type: 'tag', name: 'hr', attribs: { class: 'navbar-divider' } },
                    { type: 'tag', name: 'a', attribs: { class: 'navbar-item', href: 'https://github.com/raku/doc/issues' }, children: [{ type: 'text', data: 'Report an issue with the documentation content' }] }
                ]
            }
        ]
    };
}

function createSearchBar() {
    return {
        type: 'tag',
        name: 'div',
        attribs: { class: 'navbar-end navbar-search-wrapper' },
        children: [
            {
                type: 'tag',
                name: 'div',
                attribs: { class: 'navbar-item' },
                children: [
                    {
                        type: 'tag',
                        name: 'div',
                        attribs: { class: 'field has-addons' },
                        children: [
                            {
                                type: 'tag',
                                name: 'div',
                                attribs: { class: 'autoComplete_options' },
                                children: [
                                    {
                                        type: 'tag',
                                        name: 'input',
                                        attribs: {
                                            class: 'control input',
                                            id: 'autoComplete',
                                            type: 'search',
                                            dir: 'ltr',
                                            spellcheck: 'false',
                                            autocorrect: 'off',
                                            autocomplete: 'off',
                                            autocapitalize: 'off',
                                            placeholder: '🔍 Type f to search for ...'
                                        }
                                    }
                                ]
                            },
                            {
                                type: 'tag',
                                name: 'div',
                                attribs: { class: 'control', title: 'Search options' },
                                children: [
                                    {
                                        type: 'tag',
                                        name: 'a',
                                        attribs: { class: 'button is-primary js-modal-trigger', 'data-target': 'options-search-info' },
                                        children: [
                                            {
                                                type: 'tag',
                                                name: 'span',
                                                attribs: { class: 'icon' },
                                                children: [
                                                    { type: 'tag', name: 'i', attribs: { class: 'fas fa-cogs' } }
                                                ]
                                            }
                                        ]
                                    }
                                ]
                            }
                        ]
                    }
                ]
            }
        ]
    };
}

function createMainContent() {
    return {
        type: 'tag',
        name: 'div',
        attribs: { class: 'tile is-ancestor section' },
        children: [
            createEditButton(),
            createLeftColumn(),
            createMainColumn()
        ]
    };
}

function createEditButton() {
    return {
        type: 'tag',
        name: 'div',
        attribs: { class: 'page-edit' },
        children: [
            {
                type: 'tag',
                name: 'a',
                attribs: {
                    class: 'button page-edit-button',
                    href: 'https://github.com/Raku/doc-website/edit/main/Website/structure-sources/404.rakudoc',
                    title: 'Edit this page.\nCommit: 0ead45c 2026-04-04'
                },
                children: [
                    {
                        type: 'tag',
                        name: 'span',
                        attribs: { class: 'icon is-right' },
                        children: [
                            { type: 'tag', name: 'i', attribs: { class: 'fas fa-pen-alt is-medium' } }
                        ]
                    }
                ]
            }
        ]
    };
}

function createLeftColumn() {
    return {
        type: 'tag',
        name: 'div',
        attribs: { id: 'left-column', class: 'tile is-parent is-2 is-hidden' },
        children: [
            {
                type: 'tag',
                name: 'div',
                attribs: { id: 'left-col-inner' },
                children: [
                    {
                        type: 'tag',
                        name: 'input',
                        attribs: {
                            type: 'checkbox',
                            id: 'No-TOC',
                            checked: 'checked',
                            style: 'visibility: collapse;'
                        }
                    },
                    { type: 'tag', name: 'div', attribs: { class: 'content' }, children: [{ type: 'text', data: 'No Table of Contents or Index available' }] }
                ]
            }
        ]
    };
}

function createMainColumn() {
    return {
        type: 'tag',
        name: 'div',
        attribs: { id: 'main-column', class: 'tile is-parent', style: 'overflow-x: hidden;' },
        children: [
            {
                type: 'tag',
                name: 'div',
                attribs: { id: 'main-col-inner' },
                children: [
                    createPageHeader(),
                    createPageContent()
                ]
            }
        ]
    };
}

function createPageHeader() {
    return {
        type: 'tag',
        name: 'section',
        attribs: { class: 'raku page-header' },
        children: [
            {
                type: 'tag',
                name: 'div',
                attribs: { class: 'container px-4' },
                children: [
                    { type: 'tag', name: 'div', attribs: { class: 'raku page-title has-text-centered' }, children: [{ type: 'text', data: '404' }] },
                    { type: 'tag', name: 'div', attribs: { class: 'raku page-subtitle has-text-centered' } }
                ]
            }
        ]
    };
}

function createPageContent() {
    return {
        type: 'tag',
        name: 'section',
        attribs: { class: 'raku page-content' },
        children: [
            {
                type: 'tag',
                name: 'div',
                attribs: { class: 'container px-4' },
                children: [
                    {
                        type: 'tag',
                        name: 'div',
                        attribs: { class: 'columns one-col' },
                        children: [
                            { type: 'tag', name: 'img', attribs: { src: '/assets/images/Camelia-404.png', class: 'camelia' } },
                            {
                                type: 'tag',
                                name: 'h2',
                                attribs: { id: '404:_Page_Not_Found', class: 'raku-h2' },
                                children: [
                                    {
                                        type: 'tag',
                                        name: 'a',
                                        attribs: { href: '#404', title: 'go to top of document' },
                                        children: [
                                            { type: 'text', data: '404: Page Not Found' },
                                            {
                                                type: 'tag',
                                                name: 'a',
                                                attribs: { class: 'raku-anchor', title: 'direct link', href: '#404:_Page_Not_Found' },
                                                children: [{ type: 'text', data: '§' }]
                                            }
                                        ]
                                    }
                                ]
                            },
                            { type: 'tag', name: 'p', children: [{ type: 'text', data: "We're sorry, but the content you tried to reach wasn't found." }] },
                            { type: 'tag', name: 'p', children: [{ type: 'text', data: 'While we do review server logs to catch these issues, we recently deployed a new version of the site, so please feel free to ' }, { type: 'tag', name: 'a', attribs: { href: 'https://github.com/Raku/doc-website/issues/' }, children: [{ type: 'text', data: 'report any issues' }] }, { type: 'text', data: '.' }] },
                            { type: 'tag', name: 'p', children: [{ type: 'text', data: 'Thanks!' }] }
                        ]
                    }
                ]
            }
        ]
    };
}

function createFooter() {
    return {
        type: 'tag',
        name: 'footer',
        attribs: { class: 'footer main-footer' },
        children: [
            {
                type: 'tag',
                name: 'div',
                attribs: { class: 'container px-4' },
                children: [
                    {
                        type: 'tag',
                        name: 'nav',
                        attribs: { class: 'level' },
                        children: [
                            {
                                type: 'tag',
                                name: 'div',
                                attribs: { class: 'level-left' },
                                children: [
                                    { type: 'tag', name: 'div', attribs: { class: 'level-item' }, children: [{ type: 'tag', name: 'a', attribs: { href: '/about' }, children: [{ type: 'text', data: 'About' }] }] },
                                    { type: 'tag', name: 'div', attribs: { class: 'level-item' }, children: [{ type: 'tag', name: 'a', attribs: { id: 'toggle-theme' }, children: [{ type: 'text', data: 'Toggle theme' }] }] },
                                    { type: 'tag', name: 'div', attribs: { class: 'level-item', title: '0ead45c 2026-04-04' }, children: [{ type: 'tag', name: 'a', children: [{ type: 'text', data: 'Commit' }] }] }
                                ]
                            },
                            {
                                type: 'tag',
                                name: 'div',
                                attribs: { class: 'level-right' },
                                children: [
                                    { type: 'tag', name: 'div', attribs: { class: 'level-item' }, children: [{ type: 'tag', name: 'a', attribs: { href: '/license' }, children: [{ type: 'text', data: 'License' }] }] }
                                ]
                            }
                        ]
                    }
                ]
            }
        ]
    };
}

function renderElement(element) {
    if (element.type === 'text') {
        return element.data;
    }

    if (element.type === 'tag') {
        let html = `<${element.name}`;
        
        if (element.attribs) {
            for (const [key, value] of Object.entries(element.attribs)) {
                html += ` ${key}="${value}"`;
            }
        }
        
        if (!element.children || element.children.length === 0) {
            html += '>';
        } else {
            html += '>';
            for (const child of element.children) {
                html += renderElement(child);
            }
            html += `</${element.name}>`;
        }
        
        return html;
    }
    
    return '';
}

// Main execution
if (require.main === module) {
    const outputFile = process.argv[2];
    
    if (!outputFile) {
        console.error('Usage: node script.js <output-file>');
        process.exit(1);
    }
    
    const htmlContent = generate404Page();
    
    fs.writeFileSync(outputFile, htmlContent, 'utf8');
    console.log(`404 page generated successfully: ${outputFile}`);
}
