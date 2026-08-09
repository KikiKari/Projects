#!/usr/bin/env node
// index.html — portiert nach javascript
// Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html
// auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');

function createHTMLDocument() {
    const doc = {
        doctype: '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">',
        html: {
            head: {
                title: 'Tcl/Tk 8.6 Manual',
                meta: [
                    { name: 'viewport', content: 'width=device-width, initial-scale=1' }
                ],
                link: [
                    { rel: 'stylesheet', href: '/devsite.css', type: 'text/css', media: 'all' }
                ]
            },
            body: {
                attributes: { bgcolor: 'white', text: 'black' },
                children: []
            }
        }
    };

    // Create table with header images
    const headerTable = {
        tag: 'table',
        attributes: { border: '0', cellpadding: '0', cellspacing: '0', width: '780' },
        children: [{
            tag: 'tr',
            children: [{
                tag: 'td',
                attributes: { valign: 'top', align: 'left' },
                children: [{
                    tag: 'a',
                    attributes: { href: '/' },
                    children: [
                        { tag: 'img', attributes: { src: '/images/plume.png', width: '60', height: '55', border: '0', alt: 'Tcl Home' } },
                        { tag: 'img', attributes: { src: '/images/Developer.gif', width: '355', height: '55', border: '0', alt: 'Tcl Home', title: 'Tcl Developer Xchange' } }
                    ]
                }]
            }, {
                tag: 'td',
                attributes: { valign: 'top', align: 'right' },
                children: [
                    { tag: 'a', attributes: { href: '/siteinfo.html' }, children: [{ tag: 'font', attributes: { size: '1' }, text: 'Hosted by' }] },
                    { tag: 'br' },
                    { tag: 'a', attributes: { href: 'http://www.ActiveState.com/products/tcl' }, children: [
                        { tag: 'img', attributes: { src: '/images/aslogo.gif', border: '0', alt: 'ActiveState', title: 'This site is hosted by ActiveState' } }
                    ]}
                ]
            }]
        }]
    };

    // Add header table to body
    doc.html.body.children.push(headerTable);

    // Create navigation div
    const navDiv = {
        tag: 'div',
        attributes: { id: 'globalnav' },
        children: [{
            tag: 'ul',
            children: [
                { tag: 'li', children: [{ tag: 'a', attributes: { href: '/' }, text: 'HOME' }] },
                { tag: 'li', children: [{ tag: 'a', attributes: { href: '/about/' }, text: 'ABOUT TCL/TK' }] },
                { tag: 'li', children: [{ tag: 'a', attributes: { href: '/software/tcltk/' }, text: 'SOFTWARE' }] },
                { tag: 'li', children: [{ tag: 'a', attributes: { href: '/community/coreteam/' }, text: 'CORE DEVELOPMENT' }] },
                { tag: 'li', children: [{ tag: 'a', attributes: { href: '/community/' }, text: 'COMMUNITY' }] },
                { tag: 'li', children: [{ tag: 'a', attributes: { href: '/doc/', class: 'here' }, text: 'DOCUMENTATION' }] }
            ]
        }]
    };

    // Add navigation and break to body
    doc.html.body.children.push(navDiv);
    doc.html.body.children.push({ tag: 'br', attributes: { clear: 'all' } });

    // Create divider
    doc.html.body.children.push({
        tag: 'div',
        attributes: { style: 'border-top: 2px solid #3163CE; width: 780px' }
    });

    // Create search table
    const searchTable = {
        tag: 'table',
        attributes: { border: '0', cellpadding: '2', cellspacing: '0', width: '780' },
        children: [{
            tag: 'tr',
            children: [{
                tag: 'td',
                attributes: { align: 'left', valign: 'middle' },
                children: [{
                    tag: 'div',
                    attributes: { style: 'display:table-cell; vertical-align:middle; margin:0px' },
                    children: [{
                        tag: 'form',
                        attributes: { method: 'GET', action: 'https://www.google.com/search' },
                        children: [
                            { tag: 'a', attributes: { href: 'https://www.google.com/' }, children: [
                                { tag: 'img', attributes: { src: '/images/Search.gif', border: '0', alt: 'Google SiteSearch' } }
                            ]},
                            { tag: 'input', attributes: { type: 'text', name: 'q', size: '20', maxlength: '255', value: '' } },
                            { tag: 'input', attributes: { type: 'image', value: 'submit', name: 'btnG', src: '/images/Go.gif' } },
                            { tag: 'input', attributes: { type: 'hidden', name: 'ie', value: 'UTF-8' } },
                            { tag: 'input', attributes: { type: 'hidden', name: 'oe', value: 'UTF-8' } },
                            { tag: 'input', attributes: { type: 'hidden', name: 'domains', value: 'tcl.tk' } },
                            { tag: 'input', attributes: { type: 'hidden', name: 'sitesearch', value: 'tcl.tk' } }
                        ]
                    }]
                }]
            }, {
                tag: 'td',
                attributes: { align: 'right' },
                children: [{
                    tag: 'p',
                    attributes: { class: 'banner' },
                    text: 'Tcl/Tk 8.6 Manual'
                }]
            }]
        }]
    };

    // Add search table to body
    doc.html.body.children.push(searchTable);

    // Create yellow divider
    doc.html.body.children.push({
        tag: 'div',
        attributes: { style: 'border-top: 1px solid #FFCE00; margin-bottom: 2px; width: 780px' }
    });

    // Create main content table
    const contentTable = {
        tag: 'table',
        attributes: { border: '0', cellpadding: '0', cellspacing: '0', width: '780' },
        children: [{
            tag: 'tr',
            children: [{
                tag: 'td',
                children: [{
                    tag: 'dl',
                    attributes: { class: 'keylist' },
                    children: [
                        { tag: 'dt', children: [{ tag: 'a', attributes: { href: 'UserCmd/contents.htm' }, text: 'Tcl/Tk Applications' }] },
                        { tag: 'dd', text: 'The interpreters which implement Tcl and Tk.' },
                        { tag: 'dt', children: [{ tag: 'a', attributes: { href: 'TclCmd/contents.htm' }, text: 'Tcl Commands' }] },
                        { tag: 'dd', text: 'The commands which the tclsh interpreter implements.' },
                        { tag: 'dt', children: [{ tag: 'a', attributes: { href: 'TkCmd/contents.htm' }, text: 'Tk Commands' }] },
                        { tag: 'dd', text: 'The additional commands which the wish interpreter implements.' },
                        { tag: 'dt', children: [{ tag: 'a', attributes: { href: 'ItclCmd/contents.htm' }, text: '[incr Tcl] Package Commands' }] },
                        { tag: 'dd', text: 'The additional commands provided by the [incr Tcl] package.' },
                        { tag: 'dt', children: [{ tag: 'a', attributes: { href: 'SqliteCmd/contents.htm' }, text: 'SQLite Package Commands' }] },
                        { tag: 'dd', text: 'The additional commands provided by the SQLite package.' },
                        { tag: 'dt', children: [{ tag: 'a', attributes: { href: 'TdbcCmd/contents.htm' }, text: 'TDBC Package Commands' }] },
                        { tag: 'dd', text: 'The additional commands provided by the TDBC package.' },
                        { tag: 'dt', children: [{ tag: 'a', attributes: { href: 'TdbcmysqlCmd/contents.htm' }, text: 'tdbc::mysql Package Commands' }] },
                        { tag: 'dd', text: 'The additional commands provided by the tdbc::mysql package.' },
                        { tag: 'dt', children: [{ tag: 'a', attributes: { href: 'TdbcodbcCmd/contents.htm' }, text: 'tdbc::odbc Package Commands' }] },
                        { tag: 'dd', text: 'The additional commands provided by the tdbc::odbc package.' },
                        { tag: 'dt', children: [{ tag: 'a', attributes: { href: 'TdbcpostgresCmd/contents.htm' }, text: 'tdbc::postgres Package Commands' }] },
                        { tag: 'dd', text: 'The additional commands provided by the tdbc::postgres package.' },
                        { tag: 'dt', children: [{ tag: 'a', attributes: { href: 'TdbcsqliteCmd/contents.htm' }, text: 'tdbc::sqlite3 Package Commands' }] },
                        { tag: 'dd', text: 'The additional commands provided by the tdbc::sqlite3 package.' },
                        { tag: 'dt', children: [{ tag: 'a', attributes: { href: 'ThreadCmd/contents.htm' }, text: 'Thread Package Commands' }] },
                        { tag: 'dd', text: 'The additional commands provided by the Thread package.' },
                        { tag: 'dt', children: [{ tag: 'a', attributes: { href: 'TclLib/contents.htm' }, text: 'Tcl Library' }] },
                        { tag: 'dd', text: 'The C functions which a Tcl extended C program may use.' },
                        { tag: 'dt', children: [{ tag: 'a', attributes: { href: 'TkLib/contents.htm' }, text: 'Tk Library' }] },
                        { tag: 'dd', text: 'The additional C functions which a Tk extended C program may use.' },
                        { tag: 'dt', children: [{ tag: 'a', attributes: { href: 'ItclLib/contents.htm' }, text: '[incr Tcl] Package Library' }] },
                        { tag: 'dd', text: 'The additional C functions provided by the [incr Tcl] package.' },
                        { tag: 'dt', children: [{ tag: 'a', attributes: { href: 'TdbcLib/contents.htm' }, text: 'TDBC Package Library' }] },
                        { tag: 'dd', text: 'The additional C functions provided by the TDBC package.' },
                        { tag: 'dt', children: [{ tag: 'a', attributes: { href: 'Keywords/contents.htm' }, text: 'Keywords' }] },
                        { tag: 'dd', text: 'The keywords from the Tcl/Tk man pages.' }
                    ]
                }, {
                    tag: 'br',
                    attributes: { clear: 'all' }
                }, {
                    tag: 'p',
                    attributes: { align: 'center', class: 'footer' },
                    children: [
                        { tag: 'small', children: [{ tag: 'b', text: 'This is the main Tcl Developer Xchange site, www.tcl-lang.org .' }] },
                        { tag: 'nbsp' },
                        { tag: 'nbsp' },
                        { tag: 'a', attributes: { href: '/siteinfo.html' }, text: 'About this Site' },
                        { tag: 'nbsp' },
                        { tag: '|' },
                        { tag: 'nbsp' },
                        { tag: 'a', attributes: { href: '/cdn-cgi/l/email-protection#7a0d1f18171b090e1f083a0e191657161b141d5415081d' }, children: [
                            { tag: 'span', attributes: { class: '__cf_email__', 'data-cfemail': '95e2f0f7f8f4e6e1f0e7d5e1f6f9b8f9f4fbf2bbfae7f2' }, text: '[email\u00A0protected]' }
                        ]},
                        { tag: 'br' },
                        { tag: 'a', attributes: { href: '/' }, text: 'Home' },
                        { tag: 'nbsp' },
                        { tag: '|' },
                        { tag: 'nbsp' },
                        { tag: 'a', attributes: { href: '/about/' }, text: 'About Tcl/Tk' },
                        { tag: 'nbsp' },
                        { tag: '|' },
                        { tag: 'nbsp' },
                        { tag: 'a', attributes: { href: '/software/tcltk/' }, text: 'Software' },
                        { tag: 'nbsp' },
                        { tag: '|' },
                        { tag: 'nbsp' },
                        { tag: 'a', attributes: { href: '/community/coreteam/' }, text: 'Core Development' },
                        { tag: 'nbsp' },
                        { tag: '|' },
                        { tag: 'nbsp' },
                        { tag: 'a', attributes: { href: '/community/' }, text: 'Community' },
                        { tag: 'nbsp' },
                        { tag: '|' },
                        { tag: 'nbsp' },
                        { tag: 'a', attributes: { href: '/doc/' }, text: 'Documentation' }
                    ]
                }]
            }]
        }]
    };

    // Add content table to body
    doc.html.body.children.push(contentTable);

    // Add script at the end
    doc.html.body.children.push({
        tag: 'script',
        attributes: { 'data-cfasync': 'false', src: '/cdn-cgi/scripts/5c5dd728/cloudflare-static/email-decode.min.js', defer: true }
    });

    return doc;
}

function renderElement(element) {
    if (typeof element === 'string') {
        return element;
    }

    if (element.text) {
        return element.text;
    }

    if (!element.tag) {
        return '';
    }

    let html = `<${element.tag}`;

    if (element.attributes) {
        for (const [key, value] of Object.entries(element.attributes)) {
            html += ` ${key}="${value}"`;
        }
    }

    if (element.children && element.children.length > 0) {
        html += '>';
        for (const child of element.children) {
            html += renderElement(child);
        }
        html += `</${element.tag}>`;
    } else if (element.text) {
        html += `>${element.text}</${element.tag}>`;
    } else {
        html += '>';
    }

    return html;
}

function renderDocument(doc) {
    let html = doc.doctype + '\n';
    html += '<html>\n';
    html += '<head>';
    
    // Render title
    html += `<title>${doc.html.head.title}</title>\n`;
    
    // Render meta tags
    for (const meta of doc.html.head.meta) {
        html += '<meta';
        for (const [key, value] of Object.entries(meta)) {
            html += ` ${key}="${value}"`;
        }
        html += '>\n';
    }
    
    // Render link tags
    for (const link of doc.html.head.link) {
        html += '<link';
        for (const [key, value] of Object.entries(link)) {
            html += ` ${key}="${value}"`;
        }
        html += '>\n';
    }
    
    html += '</head>\n';
    
    // Render body
    html += '<body';
    if (doc.html.body.attributes) {
        for (const [key, value] of Object.entries(doc.html.body.attributes)) {
            html += ` ${key}="${value}"`;
        }
    }
    html += '>\n';
    
    // Render body children
    for (const child of doc.html.body.children) {
        html += renderElement(child) + '\n';
    }
    
    html += '</body></html>';
    
    return html;
}

function main() {
    const outputFile = process.argv[2];
    
    if (!outputFile) {
        console.error('Usage: node script.js <output-file>');
        process.exit(1);
    }
    
    const doc = createHTMLDocument();
    const htmlContent = renderDocument(doc);
    
    fs.writeFileSync(outputFile, htmlContent);
}

main();
