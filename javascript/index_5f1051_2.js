#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "61bce82a4d9acbdbd17551b1d7737f7296c24b98621de56585a01702055f7bdc", "source_sha256": "5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988", "target_language": "javascript"}
// index.html — portiert nach javascript
// Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html
// auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function createHTMLDocument() {
    // Create the document
    const doc = {
        doctype: '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">',
        html: {
            attrs: {},
            head: {
                children: [
                    { tag: 'title', children: ['Tcl/Tk 8.6 Manual'] },
                    { tag: 'meta', attrs: { name: 'viewport', content: 'width=device-width, initial-scale=1' } },
                    { tag: 'link', attrs: { rel: 'stylesheet', href: '/devsite.css', type: 'text/css', media: 'all' } }
                ]
            },
            body: {
                attrs: { bgcolor: 'white', text: 'black' },
                children: []
            }
        }
    };

    // Add table with header images
    const headerTable = {
        tag: 'table',
        attrs: { border: '0', cellpadding: '0', cellspacing: '0', width: '780' },
        children: [{
            tag: 'tr',
            children: [
                {
                    tag: 'td',
                    attrs: { valign: 'top', align: 'left' },
                    children: [{
                        tag: 'a',
                        attrs: { href: '/' },
                        children: [
                            {
                                tag: 'img',
                                attrs: { src: '/images/plume.png', width: '60', height: '55', border: '0', alt: 'Tcl Home' }
                            },
                            {
                                tag: 'img',
                                attrs: { src: '/images/Developer.gif', width: '355', height: '55', border: '0', alt: 'Tcl Home', title: 'Tcl Developer Xchange' }
                            }
                        ]
                    }]
                },
                {
                    tag: 'td',
                    attrs: { valign: 'top', align: 'right' },
                    children: [
                        {
                            tag: 'a',
                            attrs: { href: '/siteinfo.html' },
                            children: [{ tag: 'font', attrs: { size: '1' }, children: ['Hosted by'] }]
                        },
                        { tag: 'br' },
                        {
                            tag: 'a',
                            attrs: { href: 'http://www.ActiveState.com/products/tcl' },
                            children: [{
                                tag: 'img',
                                attrs: { src: '/images/aslogo.gif', border: '0', alt: 'ActiveState', title: 'This site is hosted by ActiveState' }
                            }]
                        }
                    ]
                }
            ]
        }]
    };

    doc.html.body.children.push(headerTable);

    // Add navigation div
    const navDiv = {
        tag: 'div',
        attrs: { id: 'globalnav' },
        children: [{
            tag: 'ul',
            children: [
                { tag: 'li', children: [{ tag: 'a', attrs: { href: '/' }, children: ['HOME'] }] },
                { tag: 'li', children: [{ tag: 'a', attrs: { href: '/about/' }, children: ['ABOUT TCL/TK'] }] },
                { tag: 'li', children: [{ tag: 'a', attrs: { href: '/software/tcltk/' }, children: ['SOFTWARE'] }] },
                { tag: 'li', children: [{ tag: 'a', attrs: { href: '/community/coreteam/' }, children: ['CORE DEVELOPMENT'] }] },
                { tag: 'li', children: [{ tag: 'a', attrs: { href: '/community/' }, children: ['COMMUNITY'] }] },
                { tag: 'li', children: [{ tag: 'a', attrs: { href: '/doc/', class: 'here' }, children: ['DOCUMENTATION'] }] }
            ]
        }]
    };

    doc.html.body.children.push(navDiv);
    doc.html.body.children.push({ tag: 'br', attrs: { clear: 'all' } });

    // Add blue divider
    doc.html.body.children.push({
        tag: 'DIV',
        attrs: { style: 'border-top: 2px solid #3163CE; width: 780px' }
    });

    // Add search table
    const searchTable = {
        tag: 'table',
        attrs: { border: '0', cellpadding: '2', cellspacing: '0', width: '780' },
        children: [{
            tag: 'tr',
            children: [
                {
                    tag: 'td',
                    attrs: { align: 'left', valign: 'middle' },
                    children: [{
                        tag: 'div',
                        attrs: { style: 'display:table-cell; vertical-align:middle; margin:0px' },
                        children: [
                            {
                                tag: 'FORM',
                                attrs: { method: 'GET', action: 'https://www.google.com/search' },
                                children: [
                                    {
                                        tag: 'A',
                                        attrs: { HREF: 'https://www.google.com/' },
                                        children: [{
                                            tag: 'IMG',
                                            attrs: { src: '/images/Search.gif', border: '0', ALT: 'Google SiteSearch' }
                                        }]
                                    },
                                    { tag: 'INPUT', attrs: { TYPE: 'text', name: 'q', size: '20', maxlength: '255', value: '' } },
                                    { tag: 'INPUT', attrs: { type: 'image', value: 'submit', name: 'btnG', src: '/images/Go.gif' } },
                                    { tag: 'input', attrs: { type: 'hidden', name: 'ie', value: 'UTF-8' } },
                                    { tag: 'input', attrs: { type: 'hidden', name: 'oe', value: 'UTF-8' } },
                                    { tag: 'input', attrs: { type: 'hidden', name: 'domains', value: 'tcl.tk' } },
                                    { tag: 'input', attrs: { type: 'hidden', name: 'sitesearch', value: 'tcl.tk' } }
                                ]
                            }
                        ]
                    }]
                },
                {
                    tag: 'td',
                    attrs: { align: 'right' },
                    children: [{
                        tag: 'p',
                        attrs: { class: 'banner' },
                        children: ['Tcl/Tk 8.6 Manual']
                    }]
                }
            ]
        }]
    };

    doc.html.body.children.push(searchTable);

    // Add yellow divider
    doc.html.body.children.push({
        tag: 'DIV',
        attrs: { style: 'border-top: 1px solid #FFCE00; margin-bottom: 2px; width: 780px' }
    });

    // Add main content table
    const contentTable = {
        tag: 'table',
        attrs: { border: '0', cellpadding: '0', cellspacing: '0', width: '780' },
        children: [{
            tag: 'tr',
            children: [{
                tag: 'td',
                children: [{
                    tag: 'DL',
                    attrs: { class: 'keylist' },
                    children: [
                        {
                            tag: 'DT',
                            children: [{ tag: 'A', attrs: { HREF: 'UserCmd/contents.htm' }, children: ['Tcl/Tk Applications'] }]
                        },
                        { tag: 'DD', children: ['The interpreters which implement Tcl and Tk.'] },
                        {
                            tag: 'DT',
                            children: [{ tag: 'A', attrs: { HREF: 'TclCmd/contents.htm' }, children: ['Tcl Commands'] }]
                        },
                        { tag: 'DD', children: ['The commands which the ', { tag: 'B', children: ['tclsh'] }, ' interpreter implements.'] },
                        {
                            tag: 'DT',
                            children: [{ tag: 'A', attrs: { HREF: 'TkCmd/contents.htm' }, children: ['Tk Commands'] }]
                        },
                        { tag: 'DD', children: ['The additional commands which the ', { tag: 'B', children: ['wish'] }, ' interpreter implements.'] },
                        {
                            tag: 'DT',
                            children: [{ tag: 'A', attrs: { HREF: 'ItclCmd/contents.htm' }, children: ['[incr Tcl] Package Commands'] }]
                        },
                        { tag: 'DD', children: ['The additional commands provided by the [incr Tcl] package.'] },
                        {
                            tag: 'DT',
                            children: [{ tag: 'A', attrs: { HREF: 'SqliteCmd/contents.htm' }, children: ['SQLite Package Commands'] }]
                        },
                        { tag: 'DD', children: ['The additional commands provided by the SQLite package.'] },
                        {
                            tag: 'DT',
                            children: [{ tag: 'A', attrs: { HREF: 'TdbcCmd/contents.htm' }, children: ['TDBC Package Commands'] }]
                        },
                        { tag: 'DD', children: ['The additional commands provided by the TDBC package.'] },
                        {
                            tag: 'DT',
                            children: [{ tag: 'A', attrs: { HREF: 'TdbcmysqlCmd/contents.htm' }, children: ['tdbc::mysql Package Commands'] }]
                        },
                        { tag: 'DD', children: ['The additional commands provided by the tdbc::mysql package.'] },
                        {
                            tag: 'DT',
                            children: [{ tag: 'A', attrs: { HREF: 'TdbcodbcCmd/contents.htm' }, children: ['tdbc::odbc Package Commands'] }]
                        },
                        { tag: 'DD', children: ['The additional commands provided by the tdbc::odbc package.'] },
                        {
                            tag: 'DT',
                            children: [{ tag: 'A', attrs: { HREF: 'TdbcpostgresCmd/contents.htm' }, children: ['tdbc::postgres Package Commands'] }]
                        },
                        { tag: 'DD', children: ['The additional commands provided by the tdbc::postgres package.'] },
                        {
                            tag: 'DT',
                            children: [{ tag: 'A', attrs: { HREF: 'TdbcsqliteCmd/contents.htm' }, children: ['tdbc::sqlite3 Package Commands'] }]
                        },
                        { tag: 'DD', children: ['The additional commands provided by the tdbc::sqlite3 package.'] },
                        {
                            tag: 'DT',
                            children: [{ tag: 'A', attrs: { HREF: 'ThreadCmd/contents.htm' }, children: ['Thread Package Commands'] }]
                        },
                        { tag: 'DD', children: ['The additional commands provided by the Thread package.'] },
                        {
                            tag: 'DT',
                            children: [{ tag: 'A', attrs: { HREF: 'TclLib/contents.htm' }, children: ['Tcl Library'] }]
                        },
                        { tag: 'DD', children: ['The C functions which a Tcl extended C program may use.'] },
                        {
                            tag: 'DT',
                            children: [{ tag: 'A', attrs: { HREF: 'TkLib/contents.htm' }, children: ['Tk Library'] }]
                        },
                        { tag: 'DD', children: ['The additional C functions which a Tk extended C program may use.'] },
                        {
                            tag: 'DT',
                            children: [{ tag: 'A', attrs: { HREF: 'ItclLib/contents.htm' }, children: ['[incr Tcl] Package Library'] }]
                        },
                        { tag: 'DD', children: ['The additional C functions provided by the [incr Tcl] package.'] },
                        {
                            tag: 'DT',
                            children: [{ tag: 'A', attrs: { HREF: 'TdbcLib/contents.htm' }, children: ['TDBC Package Library'] }]
                        },
                        { tag: 'DD', children: ['The additional C functions provided by the TDBC package.'] },
                        {
                            tag: 'DT',
                            children: [{ tag: 'A', attrs: { HREF: 'Keywords/contents.htm' }, children: ['Keywords'] }]
                        },
                        { tag: 'DD', children: ['The keywords from the Tcl/Tk man pages.'] }
                    ]
                }]
            }]
        }]
    };

    doc.html.body.children.push(contentTable);

    // Add footer
    doc.html.body.children.push({ tag: 'br', attrs: { clear: 'all' } });

    const footer = {
        tag: 'p',
        attrs: { align: 'center', class: 'footer' },
        children: [
            { tag: 'small', children: [{ tag: 'b', children: ['This is the main Tcl Developer Xchange site, www.tcl-lang.org .'] }] },
            '&nbsp;&nbsp;',
            { tag: 'a', attrs: { href: '/siteinfo.html' }, children: ['About this Site'] },
            ' | ',
            {
                tag: 'a',
                attrs: { href: '/cdn-cgi/l/email-protection#7a0d1f18171b090e1f083a0e191657161b141d5415081d' },
                children: [{ tag: 'span', attrs: { class: '__cf_email__', 'data-cfemail': '95e2f0f7f8f4e6e1f0e7d5e1f6f9b8f9f4fbf2bbfae7f2' }, children: ['[email\u00A0protected]'] }]
            },
            { tag: 'br' },
            { tag: 'a', attrs: { href: '/' }, children: ['Home'] },
            ' | ',
            { tag: 'a', attrs: { href: '/about/' }, children: ['About Tcl/Tk'] },
            ' | ',
            { tag: 'a', attrs: { href: '/software/tcltk/' }, children: ['Software'] },
            ' | ',
            { tag: 'a', attrs: { href: '/community/coreteam/' }, children: ['Core Development'] },
            ' | ',
            { tag: 'a', attrs: { href: '/community/' }, children: ['Community'] },
            ' | ',
            { tag: 'a', attrs: { href: '/doc/' }, children: ['Documentation'] }
        ]
    };

    contentTable.children[0].children[0].children.push(footer);

    // Add script
    doc.html.body.children.push({
        tag: 'script',
        attrs: { 'data-cfasync': 'false', src: '/cdn-cgi/scripts/5c5dd728/cloudflare-static/email-decode.min.js', defer: '' }
    });

    return doc;
}

function renderElement(element) {
    if (typeof element === 'string') {
        return element;
    }

    if (typeof element === 'object' && !element.tag) {
        return element.children.map(renderElement).join('');
    }

    let result = '';

    if (element.tag) {
        result += '<' + element.tag;

        if (element.attrs) {
            for (const [key, value] of Object.entries(element.attrs)) {
                result += ' ' + key + '="' + value + '"';
            }
        }

        result += '>';

        if (element.children) {
            result += element.children.map(renderElement).join('');
        }

        result += '</' + element.tag + '>';
    }

    return result;
}

function generateHTML(doc) {
    let html = doc.doctype + '\n';
    html += '<html>\n';
    html += '<head>' + doc.html.head.children.map(renderElement).join('') + '</head>\n';
    html += '<body';
    
    if (doc.html.body.attrs) {
        for (const [key, value] of Object.entries(doc.html.body.attrs)) {
            html += ' ' + key + '="' + value + '"';
        }
    }
    
    html += '>' + doc.html.body.children.map(renderElement).join('') + '</body>\n';
    html += '</html>\n';

    return html;
}

function main() {
    const outputFile = process.argv[2];
    
    if (!outputFile) {
        console.error('Usage: node ' + path.basename(process.argv[1]) + ' <output-file>');
        process.exit(1);
    }

    try {
        const doc = createHTMLDocument();
        const htmlContent = generateHTML(doc);
        
        fs.writeFileSync(outputFile, htmlContent, 'utf8');
        console.log('HTML file generated successfully: ' + outputFile);
    } catch (error) {
        console.error('Error generating HTML file:', error.message);
        process.exit(1);
    }
}

main();
