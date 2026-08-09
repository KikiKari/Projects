#!/usr/bin/env node
// index.html — portiert nach javascript
// Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/raku/index.html
// auch in: OpenClaw@gateway2:skills/scripting-utils/references/raku/index.html
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import path from 'path';

function createHTMLDocument() {
    const doc = {
        doctype: '<!DOCTYPE html>',
        html: {
            attributes: {
                lang: 'en',
                class: 'fontawesome-i2svg-active fontawesome-i2svg-complete',
                style: 'scroll-padding-top:60px'
            },
            head: {
                title: 'Raku Documentation | Raku Documentation',
                meta: [
                    { charset: 'UTF-8' }
                ],
                links: [
                    { href: '/assets/images/Camelia.ico', rel: 'icon', type: 'image/x-icon' },
                    { rel: 'stylesheet', href: '/assets/css/Website.css' },
                    { rel: 'stylesheet', href: '/assets/css/css/filtered-toc-dark.css', title: 'dark' },
                    { rel: 'stylesheet', href: '/assets/css/css/filtered-toc-light.css', title: 'light' },
                    { rel: 'stylesheet', href: '/assets/css/css/rainbow-dark.css', title: 'dark' },
                    { rel: 'stylesheet', href: '/assets/css/css/rainbow-light.css', title: 'light' },
                    { rel: 'stylesheet', href: '/assets/css/tm-styling.css' },
                    { rel: 'stylesheet', href: '/assets/css/tm-light.css', title: 'light' },
                    { rel: 'stylesheet', href: '/assets/css/tm-dark.css', title: 'dark' },
                    { rel: 'stylesheet', href: '/assets/css/all.min.css' },
                    { rel: 'stylesheet', href: '/assets/css/listf-styling-light.css', title: 'light' },
                    { rel: 'stylesheet', href: '/assets/css/listf-styling-dark.css', title: 'dark' },
                    { rel: 'stylesheet', href: '/assets/css/typegraph-styling.css' },
                    { rel: 'stylesheet', href: '/assets/css/typegraph-dark.css', title: 'dark' },
                    { rel: 'stylesheet', href: '/assets/css/typegraph-light.css', title: 'light' },
                    { rel: 'stylesheet', href: '/assets/css/css/page-styling-main.css' },
                    { rel: 'stylesheet', href: '/assets/css/css/page-styling-dark.css', title: 'dark' },
                    { rel: 'stylesheet', href: '/assets/css/css/page-styling-light.css', title: 'light' },
                    { rel: 'stylesheet', href: '/assets/css/css/chyronToggle-dark.css', title: 'dark' },
                    { rel: 'stylesheet', href: '/assets/css/css/chyronToggle-light.css', title: 'light' },
                    { rel: 'stylesheet', href: '/assets/css/css/centreToggle-dark.css', title: 'dark' },
                    { rel: 'stylesheet', href: '/assets/css/css/centreToggle-light.css', title: 'light' },
                    { rel: 'stylesheet', href: '/assets/css/css/options-search-light.css', title: 'light' },
                    { rel: 'stylesheet', href: '/assets/css/css/options-search-dark.css', title: 'dark' },
                    { rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-light.min.css', title: 'light' },
                    { rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css', title: 'dark' },
                    { rel: 'stylesheet', href: 'https://cdn.jsdelivr.net/npm/@tarekraafat/autocomplete.js@10.2.7/dist/css/autoComplete.min.css' }
                ],
                scripts: [
                    { src: 'https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js' },
                    { src: '/assets/scripts/all.min.js' },
                    { src: '/assets/scripts/tableManager.js' },
                    { src: '/assets/scripts/filter-script.js' },
                    { src: 'https://cdn.jsdelivr.net/npm/fuzzysort@2.0.4/fuzzysort.min.js' },
                    { src: 'https://cdn.jsdelivr.net/npm/@tarekraafat/autocomplete.js@10.2.7/dist/autoComplete.min.js' },
                    { src: '/assets/scripts/filtered-toc.js' },
                    { src: 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js' },
                    { src: 'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/haskell.min.js' },
                    { src: '/assets/scripts/options-search.js' },
                    { src: '/assets/scripts/page-styling.js' },
                    { src: '/assets/scripts/rainbow.js' }
                ]
            },
            body: {
                attributes: { class: 'has-navbar-fixed-top' },
                content: []
            }
        }
    };

    // Create body content
    doc.html.body.content.push(
        { tag: 'div', attributes: { id: 'Raku_Documentation', class: 'top-of-page' } },
        createNavbar(),
        { tag: 'div', attributes: { id: 'wrapper' }, content: [
            createHeroSection(),
            createMainContentSection(),
            createLinksBlock(),
            createFooter()
        ]}
    );

    return doc;
}

function createNavbar() {
    return {
        tag: 'nav',
        attributes: {
            class: 'navbar is-fixed-top is-flex-touch',
            role: 'navigation',
            'aria-label': 'main navigation'
        },
        content: [
            {
                tag: 'div',
                attributes: { class: 'container is-justify-content-space-around' },
                content: [
                    {
                        tag: 'div',
                        attributes: { class: 'navbar-brand' },
                        content: [
                            {
                                tag: 'div',
                                attributes: { class: 'navbar-logo' },
                                content: [
                                    {
                                        tag: 'a',
                                        attributes: { class: 'navbar-item', href: '/' },
                                        content: [
                                            {
                                                tag: 'img',
                                                attributes: {
                                                    src: '/assets/images/camelia-recoloured.png',
                                                    alt: 'Raku',
                                                    width: '52.83',
                                                    height: '38'
                                                }
                                            }
                                        ]
                                    },
                                    {
                                        tag: 'span',
                                        attributes: { class: 'navbar-logo-tm' },
                                        content: 'tm'
                                    }
                                ]
                            },
                            {
                                tag: 'a',
                                attributes: {
                                    role: 'button',
                                    class: 'navbar-burger burger',
                                    'aria-label': 'menu',
                                    'aria-expanded': 'false',
                                    'data-target': 'navMenu'
                                },
                                content: [
                                    { tag: 'span', attributes: { 'aria-hidden': 'true' } },
                                    { tag: 'span', attributes: { 'aria-hidden': 'true' } },
                                    { tag: 'span', attributes: { 'aria-hidden': 'true' } }
                                ]
                            }
                        ]
                    },
                    {
                        tag: 'div',
                        attributes: { id: 'navMenu', class: 'navbar-menu' },
                        content: [
                            createNavbarStart(),
                            createNavbarEnd()
                        ]
                    },
                    createSearchOptionsModal(),
                    createDownloadEbookModal()
                ]
            }
        ]
    };
}

function createNavbarStart() {
    return {
        tag: 'div',
        attributes: { class: 'navbar-start' },
        content: [
            { tag: 'a', attributes: { class: 'navbar-item', href: '/introduction', title: 'Getting started, Tutorials, Migration guides' }, content: 'Introduction' },
            { tag: 'a', attributes: { class: 'navbar-item', href: '/reference', title: 'Fundamentals, General reference' }, content: 'Reference' },
            { tag: 'a', attributes: { class: 'navbar-item', href: '/miscellaneous', title: 'Programs, Experimental' }, content: 'Miscellaneous' },
            { tag: 'a', attributes: { class: 'navbar-item', href: '/types', title: 'The core types (classes) available' }, content: 'Types' },
            { tag: 'a', attributes: { class: 'navbar-item', href: '/routines', title: 'Searchable table of routines' }, content: 'Routines' },
            { tag: 'a', attributes: { class: 'navbar-item', href: 'https://raku.org', title: 'Home page for community' }, content: ['Raku', { tag: 'sup', content: '®' }] },
            { tag: 'a', attributes: { class: 'navbar-item', href: 'https://web.libera.chat/#raku', title: 'IRC live chat' }, content: 'Chat' },
            {
                tag: 'div',
                attributes: { class: 'navbar-item has-dropdown is-hoverable' },
                content: [
                    { tag: 'a', attributes: { class: 'navbar-link' }, content: 'More' },
                    {
                        tag: 'div',
                        attributes: { class: 'navbar-dropdown is-right is-rounded' },
                        content: [
                            { tag: 'hr', attributes: { class: 'navbar-divider' } },
                            { tag: 'a', attributes: { class: 'navbar-item js-modal-trigger', 'data-target': 'download-ebook' }, content: 'Download E-Book (epub)' },
                            { tag: 'hr', attributes: { class: 'navbar-divider' } },
                            { tag: 'a', attributes: { class: 'navbar-item', href: '/about' }, content: 'About' },
                            { tag: 'hr', attributes: { class: 'navbar-divider' } },
                            { tag: 'a', attributes: { class: 'navbar-item has-text-red', href: 'https://github.com/raku/doc-website/issues' }, content: 'Report an issue with this site' },
                            { tag: 'hr', attributes: { class: 'navbar-divider' } },
                            { tag: 'a', attributes: { class: 'navbar-item', href: 'https://github.com/raku/doc/issues' }, content: 'Report an issue with the documentation content' }
                        ]
                    }
                ]
            }
        ]
    };
}

function createNavbarEnd() {
    return {
        tag: 'div',
        attributes: { class: 'navbar-end navbar-search-wrapper' },
        content: [
            {
                tag: 'div',
                attributes: { class: 'navbar-item' },
                content: [
                    {
                        tag: 'div',
                        attributes: { class: 'field has-addons' },
                        content: [
                            {
                                tag: 'div',
                                attributes: { class: 'autoComplete_options' },
                                content: [
                                    {
                                        tag: 'input',
                                        attributes: {
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
                                tag: 'div',
                                attributes: { class: 'control', title: 'Search options' },
                                content: [
                                    {
                                        tag: 'a',
                                        attributes: {
                                            class: 'button is-primary js-modal-trigger',
                                            'data-target': 'options-search-info'
                                        },
                                        content: [
                                            {
                                                tag: 'span',
                                                attributes: { class: 'icon' },
                                                content: [
                                                    {
                                                        tag: 'i',
                                                        attributes: { class: 'fas fa-cogs' }
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
            }
        ]
    };
}

function createSearchOptionsModal() {
    return {
        tag: 'div',
        attributes: { id: 'options-search-info', class: 'modal' },
        content: [
            { tag: 'div', attributes: { class: 'modal-background' } },
            {
                tag: 'div',
                attributes: { class: 'modal-content' },
                content: [
                    {
                        tag: 'div',
                        attributes: { class: 'box' },
                        content: [
                            {
                                tag: 'p',
                                content: ['The last search was: ', { tag: 'span', attributes: { id: 'selected-candidate', class: 'ss-selected' } }]
                            },
                            {
                                tag: 'div',
                                attributes: { class: 'control is-grouped is-grouped-centered options-search-controls' },
                                content: [
                                    {
                                        tag: 'label',
                                        attributes: { class: 'centreToggle', title: 'Include extra information (Alt-E)', style: '--switch-width: 10.5' },
                                        content: [
                                            { tag: 'input', attributes: { id: 'options-search-extra', type: 'checkbox' } },
                                            { tag: 'span', attributes: { class: 'text' }, content: 'Extra info' },
                                            { tag: 'span', attributes: { class: 'on' }, content: 'yes' },
                                            { tag: 'span', attributes: { class: 'off' }, content: 'no' }
                                        ]
                                    },
                                    {
                                        tag: 'p',
                                        content: 'The search response can be shortened by excluding the extra information line (Alt-E)'
                                    },
                                    {
                                        tag: 'label',
                                        attributes: { class: 'centreToggle', title: 'Search engine type Strict/Loose (Alt-L)', style: '--switch-width: 10.5' },
                                        content: [
                                            { tag: 'input', attributes: { id: 'options-search-loose', type: 'checkbox' } },
                                            { tag: 'span', attributes: { class: 'text' }, content: 'Search type' },
                                            { tag: 'span', attributes: { class: 'on' }, content: 'loose' },
                                            { tag: 'span', attributes: { class: 'off' }, content: 'strict' }
                                        ]
                                    },
                                    {
                                        tag: 'p',
                                        content: ' The search engine can perform a strict search (only the characters in the search box) or a loose search (Alt-L)'
                                    },
                                    {
                                        tag: 'label',
                                        attributes: { class: 'centreToggle', title: 'Search in headings (Alt-H)', style: '--switch-width: 10.5' },
                                        content: [
                                            { tag: 'input', attributes: { id: 'options-search-headings', type: 'checkbox' } },
                                            { tag: 'span', attributes: { class: 'text' }, content: 'Headings' },
                                            { tag: 'span', attributes: { class: 'on' }, content: 'yes' },
                                            { tag: 'span', attributes: { class: 'off' }, content: 'no' }
                                        ]
                                    },
                                    {
                                        tag: 'p',
                                        content: 'Search through headings in all web-pages (Alt-H)'
                                    },
                                    {
                                        tag: 'label',
                                        attributes: { class: 'centreToggle', title: 'Search indexed items (Alt-I)', style: '--switch-width: 10.5' },
                                        content: [
                                            { tag: 'input', attributes: { id: 'options-search-indexed', type: 'checkbox' } },
                                            { tag: 'span', attributes: { class: 'text' }, content: 'Indexed' },
                                            { tag: 'span', attributes: { class: 'on' }, content: 'yes' },
                                            { tag: 'span', attributes: { class: 'off' }, content: 'no' }
                                        ]
                                    },
                                    {
                                        tag: 'p',
                                        content: 'Search through all indexed items (Alt-I)'
                                    },
                                    {
                                        tag: 'label',
                                        attributes: { class: 'centreToggle', title: 'Search composite pages (Alt-C)', style: '--switch-width: 10.5' },
                                        content: [
                                            { tag: 'input', attributes: { id: 'options-search-composite', type: 'checkbox' } },
                                            { tag: 'span', attributes: { class: 'text' }, content: 'Composite' },
                                            { tag: 'span', attributes: { class: 'on' }, content: 'yes' },
                                            { tag: 'span', attributes: { class: 'off' }, content: 'no' }
                                        ]
                                    },
                                    {
                                        tag: 'p',
                                        content: 'Search in the names of composite pages, which combine similar information from the main web pages (Alt-C)'
                                    },
                                    {
                                        tag: 'label',
                                        attributes: { class: 'centreToggle', title: 'Search primary sources (Alt-P)', style: '--switch-width: 10.5' },
                                        content: [
                                            { tag: 'input', attributes: { id: 'options-search-primary', type: 'checkbox' } },
                                            { tag: 'span', attributes: { class: 'text' }, content: 'Primary' },
                                            { tag: 'span', attributes: { class: 'on' }, content: 'yes' },
                                            { tag: 'span', attributes: { class: 'off' }, content: 'no' }
                                        ]
                                    },
                                    {
                                        tag: 'p',
                                        content: 'Search through the names of the main web pages (Alt-P)'
                                    },
                                    {
                                        tag: 'label',
                                        attributes: { class: 'centreToggle', title: 'Open in new tab (Alt-Q)', style: '--switch-width: 10.5' },
                                        content: [
                                            { tag: 'input', attributes: { id: 'options-search-newtab', type: 'checkbox' } },
                                            { tag: 'span', attributes: { class: 'text' }, content: 'New tab' },
                                            { tag: 'span', attributes: { class: 'on' }, content: 'yes' },
                                            { tag: 'span', attributes: { class: 'off' }, content: 'no' }
                                        ]
                                    },
                                    {
                                        tag: 'p',
                                        content: 'Once a search candidate has been chosen, it can be opened in a new tab or in the current tab (Alt-Q)'
                                    },
                                    {
                                        tag: 'p',
                                        content: 'If all else fails, an item is added to use the Google search engine on the whole site'
                                    },
                                    {
                                        tag: 'button',
                                        attributes: { class: 'button is-warning', id: 'options-search-reset-defaults' },
                                        content: 'Clear options, reset to defaults'
                                    },
                                    {
                                        tag: 'p',
                                        content: 'Exit this page by pressing <Escape>, or clicking on X or on the background.'
                                    }
                                ]
                            }
                        ]
                    }
                ]
            },
            { tag: 'button', attributes: { class: 'modal-close is-large', 'aria-label': 'close' } }
        ]
    };
}

function createDownloadEbookModal() {
    return {
        tag: 'div',
        attributes: { id: 'download-ebook', class: 'modal' },
        content: [
            { tag: 'div', attributes: { class: 'modal-background' } },
            {
                tag: 'div',
                attributes: { class: 'modal-content' },
                content: [
                    {
                        tag: 'div',
                        attributes: { class: 'box' },
                        content: [
                            {
                                tag: 'p',
                                content: [
                                    { tag: 'a', attributes: { href: '/RakuDocumentation.epub', download: 'RakuDocumentation.epub' }, content: 'RakuDocumentation.epub' },
                                    ' is a work in progress e-book. It targets the ',
                                    { tag: 'a', attributes: { href: 'https://www.w3.org/publishing/epub3/' }, content: 'EPUB v3 specification' },
                                    '. It needs testing on a variety of ereaders (some of which may still implicitly expect compliance with EPUB v2). The CSS definitely needs enhancing (especially for code snippets). The Ebook opens in a Calibre reader, which is available on all operating systems.'
                                ]
                            },
                            {
                                tag: 'p',
                                content: 'Suggestions are welcome and should be addressed by opening an issue on the Raku/doc-website repository'
                            },
                            {
                                tag: 'p',
                                content: 'Exit this popup by pressing <Escape>, or clicking on X or on the background.'
                            }
                        ]
                    }
                ]
            },
            { tag: 'button', attributes: { class: 'modal-close is-large', 'aria-label': 'close' } }
        ]
    };
}

function createHeroSection() {
    return {
        tag: 'section',
        attributes: { class: 'hero is-medium is-primary' },
        content: [
            {
                tag: 'div',
                attributes: { class: 'hero-body' },
                content: [
                    {
                        tag: 'div',
                        attributes: { class: 'container' },
                        content: [
                            {
                                tag: 'h1',
                                attributes: { class: 'title is-1 is-size-2-mobile has-text-centered' },
                                content: 'Raku documentation'
                            },
                            {
                                tag: 'h2',
                                attributes: { class: 'subtitle is-4 has-text-centered mt-3' },
                                content: ['Welcome to the official documentation of the Raku', { tag: 'sup', content: '®' }, ' programming language!']
                            }
                        ]
                    }
                ]
            }
        ]
    };
}

function createMainContentSection() {
    return {
        tag: 'section',
        attributes: { class: 'section' },
        content: [
            {
                tag: 'div',
                attributes: { class: 'container px-4' },
                content: [
                    {
                        tag: 'div',
                        attributes: { class: 'columns is-multiline' },
                        content: [
                            createCard('/introduction', 'fas fa-graduation-cap icon-large', 'Getting started, Migration guides from other languages, & Tutorials', 'Documents introducing the language for various audiences.'),
                            createCard('/reference', 'fas fa-book icon-large', 'Language References', 'Documents explaining the conceptual parts of the language.'),
                            createCard('/types', 'fas fa-layer-group icon-large', 'Type Reference', 'Index of built-in classes, roles and enums.'),
                            createCard('/routines', 'fas fa-paperclip icon-large', 'Routine Reference', 'Index of built-in subroutines and methods.'),
                            createCard('/miscellaneous', 'fas fa-code icon-large', 'Miscellaneous', 'Documents explaining experimental topics and Raku programs rather than the language itself.'),
                            createFAQCard(),
                            createCommunityCard()
                        ]
                    }
                ]
            }
        ]
    };
}

function createCard(href, iconClass, title, description) {
    return {
        tag: 'div',
        attributes: { class: 'column is-one-half' },
        content: [
            {
                tag: 'div',
                attributes: { class: 'card card-home' },
                content: [
                    {
                        tag: 'div',
                        attributes: { class: 'card-content' },
                        content: [
                            {
                                tag: 'div',
                                attributes: { class: 'has-text-centered' },
                                content: [
                                    {
                                        tag: 'a',
                                        attributes: { href: href },
                                        content: [
                                            {
                                                tag: 'span',
                                                attributes: { class: 'icon is-large has-text-primary' },
                                                content: [
                                                    { tag: 'i', attributes: { class: iconClass } }
                                                ]
                                            }
                                        ]
                                    }
                                ]
                            },
                            {
                                tag: 'div',
                                attributes: { class: 'content has-text-centered' },
                                content: [
                                    {
                                        tag: 'p',
                                        attributes: { class: 'title is-5 has-text-primary' },
                                        content: [
                                            { tag: 'a', attributes: { href: href }, content: title }
                                        ]
                                    }
                                ]
                            },
                            {
                                tag: 'div',
                                attributes: { class: 'content has-text-centered' },
                                content: description
                            },
                            {
                                tag: 'div',
                                attributes: { class: 'has-text-centered' },
                                content: [
                                    {
                                        tag: 'a',
                                        attributes: { class: 'button is-primary', href: href },
                                        content: [{ tag: 'strong', content: 'Learn more' }]
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

function createFAQCard() {
    return {
        tag: 'div',
        attributes: { class: 'column is-one-half' },
        content: [
            {
                tag: 'div',
                attributes: { class: 'card card-home' },
                content: [
                    {
                        tag: 'div',
                        attributes: { class: 'card-content' },
                        content: [
                            {
                                tag: 'div',
                                attributes: { class: 'has-text-centered' },
                                content: [
                                    {
                                        tag: 'a',
                                        attributes: { href: '/language/faq' },
                                        content: [
                                            {
                                                tag: 'span',
                                                attributes: { class: 'icon is-large has-text-primary' },
                                                content: [
                                                    {
                                                        tag: 'svg',
                                                        attributes: {
                                                            class: 'svg-inline--fa fa-question-circle fa-w-16 icon-large',
                                                            'aria-hidden': 'true',
                                                            'data-prefix': 'fas',
                                                            'data-icon': 'question-circle',
                                                            role: 'img',
                                                            xmlns: 'http://www.w3.org/2000/svg',
                                                            viewBox: '0 0 512 512'
                                                        },
                                                        content: [
                                                            {
                                                                tag: 'path',
                                                                attributes: {
                                                                    fill: 'currentColor',
                                                                    d: 'M504 256c0 136.997-111.043 248-248 248S8 392.997 8 256C8 119.083 119.043 8 256 8s248 111.083 248 248zM262.655 90c-54.497 0-89.255 22.957-116.549 63.758-3.536 5.286-2.353 12.415 2.715 16.258l34.699 26.31c5.205 3.947 12.621 3.008 16.665-2.122 17.864-22.658 30.113-35.797 57.303-35.797 20.429 0 45.698 13.148 45.698 32.958 0 14.976-12.363 22.667-32.534 33.976C247.128 238.528 216 254.941 216 296v4c0 6.627 5.373 12 12 12h56c6.627 0 12-5.373 12-12v-1.333c0-28.462 83.186-29.647 83.186-106.667 0-58.002-60.165-102-116.531-102zM256 338c-25.365 0-46 20.635-46 46 0 25.364 20.635 46 46 46s46-20.636 46-46c0-25.365-20.635-46-46-46z'
                                                                }
                                                            }
                                                        ]
                                                    }
                                                ]
                                            }
                                        ]
                                    }
                                ]
                            },
                            {
                                tag: 'div',
                                attributes: { class: 'content has-text-centered' },
                                content: [
                                    {
                                        tag: 'p',
                                        attributes: { class: 'title is-5 has-text-primary' },
                                        content: [
                                            { tag: 'a', attributes: { href: '/language/faq' }, content: 'FAQs (Frequently Asked Questions)' }
                                        ]
                                    }
                                ]
                            },
                            {
                                tag: 'div',
                                attributes: { class: 'content has-text-centered' },
                                content: 'A collection of questions that have cropped up often, along with answers.'
                            },
                            {
                                tag: 'div',
                                attributes: { class: 'has-text-centered' },
                                content: [
                                    {
                                        tag: 'a',
                                        attributes: { class: 'button is-primary', href: '/language/faq' },
                                        content: [{ tag: 'strong', content: 'Learn more' }]
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

function createCommunityCard() {
    return {
        tag: 'div',
        attributes: { class: 'column is-one-half' },
        content: [
            {
                tag: 'div',
                attributes: { class: 'card card-home' },
                content: [
                    {
                        tag: 'div',
                        attributes: { class: 'card-content' },
                        content: [
                            {
                                tag: 'div',
                                attributes: { class: 'has-text-centered' },
                                content: [
                                    {
                                        tag: 'a',
                                        attributes: { href: '/language/community' },
                                        content: [
                                            {
                                                tag: 'span',
                                                attributes: { class: 'icon is-large has-text-primary' },
                                                content: [
                                                    {
                                                        tag: 'svg',
                                                        attributes: {
                                                            class: 'svg-inline--fa fa-user-friends fa-w-20 icon-large',
                                                            'aria-hidden': 'true',
                                                            'data-prefix': 'fas',
                                                            'data-icon': 'user-friends',
                                                            role: 'img',
                                                            xmlns: 'http://www.w3.org/2000/svg',
                                                            viewBox: '0 0 640 512'
                                                        },
                                                        content: [
                                                            {
                                                                tag: 'path',
                                                                attributes: {
                                                                    fill: 'currentColor',
                                                                    d: 'M192 256c61.9 0 112-50.1 112-112S253.9 32 192 32 80 82.1 80 144s50.1 112 112 112zm76.8 32h-8.3c-20.8 10-43.9 16-68.5 16s-47.6-6-68.5-16h-8.3C51.6 288 0 339.6 0 403.2V432c0 26.5 21.5 48 48 48h288c26.5 0 48-21.5 48-48v-28.8c0-63.6-51.6-115.2-115.2-115.2zM480 256c53 0 96-43 96-96s-43-96-96-96-96 43-96 96 43 96 96 96zm48 32h-3.8c-13.9 4.8-28.6 8-44.2 8s-30.3-3.2-44.2-8H432c-20.4 0-39.2 5.9-55.7 15.4 24.4 26.3 39.7 61.2 39.7 99.8v38.4c0 2.2-.5 4.3-.6 6.4H592c26.5 0 48-21.5 48-48 0-61.9-50.1-112-112-112z'
                                                                }
                                                            }
                                                        ]
                                                    }
                                                ]
                                            }
                                        ]
                                    }
                                ]
                            },
                            {
                                tag: 'div',
                                attributes: { class: 'content has-text-centered' },
                                content: [
                                    {
                                        tag: 'p',
                                        attributes: { class: 'title is-5 has-text-primary' },
                                        content: [
                                            { tag: 'a', attributes: { href: '/language/community' }, content: 'Community' }
                                        ]
                                    }
                                ]
                            },
                            {
                                tag: 'div',
                                attributes: { class: 'content has-text-centered' },
                                content: 'Information about the Raku development community, email lists, IRC and IRC bots, and blogs.'
                            },
                            {
                                tag: 'div',
                                attributes: { class: 'has-text-centered' },
                                content: [
                                    {
                                        tag: 'a',
                                        attributes: { class: 'button is-primary', href: '/language/community' },
                                        content: [{ tag: 'strong', content: 'Learn more' }]
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

function createLinksBlock() {
    return {
        tag: 'div',
        attributes: { class: 'raku links-block' },
        content: [
            {
                tag: 'div',
                attributes: { class: 'container px-4 py-5' },
                content: [
                    {
                        tag: 'div',
                        attributes: { class: 'columns is-vcentered' },
                        content: [
                            {
                                tag: 'div',
                                attributes: { class: 'column is-one-third has-text-centered' },
                                content: [
                                    {
                                        tag: 'div',
                                        attributes: { class: 'pt-5' },
                                        content: [
                                            {
                                                tag: 'span',
                                                attributes: { class: 'icon is-large' },
                                                content: [
                                                    {
                                                        tag: 'svg',
                                                        attributes: {
                                                            class: 'svg-inline--fa fa-hashtag fa-w-14 icon-large',
                                                            'aria-hidden': 'true',
                                                            'data-prefix': 'fas',
                                                            'data-icon': 'hashtag',
                                                            role: 'img',
                                                            xmlns: 'http://www.w3.org/2000/svg',
                                                            viewBox: '0 0 448 512'
                                                        },
                                                        content: [
                                                            {
                                                                tag: 'path',
                                                                attributes: {
                                                                    fill: 'currentColor',
                                                                    d: 'M440.667 182.109l7.143-40c1.313-7.355-4.342-14.109-11.813-14.109h-74.81l14.623-81.891C377.123 38.754 371.468 32 363.997 32h-40.632a12 12 0 0 0-11.813 9.891L296.175 128H197.54l14.623-81.891C213.477 38.754 207.822 32 200.35 32h-40.632a12 12 0 0 0-11.813 9.891L132.528 128H53.432a1
