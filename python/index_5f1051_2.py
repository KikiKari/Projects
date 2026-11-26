#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "0b9cb95c4bc1a93e8056a8f9637b8325de0fb0eaa9841b7f21a478d19d7e736c", "source_sha256": "5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988", "target_language": "python"}
# index.html — portiert nach python
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import sys
from xml.etree.ElementTree import Element, SubElement, tostring
from xml.dom import minidom

def create_html():
    # Create the root element with DOCTYPE
    html = Element('html')
    
    # Head section
    head = SubElement(html, 'head')
    title = SubElement(head, 'title')
    title.text = 'Tcl/Tk 8.6 Manual'
    
    meta = SubElement(head, 'meta')
    meta.set('name', 'viewport')
    meta.set('content', 'width=device-width, initial-scale=1')
    
    link = SubElement(head, 'link')
    link.set('rel', 'stylesheet')
    link.set('href', '/devsite.css')
    link.set('type', 'text/css')
    link.set('media', 'all')
    
    # Body section
    body = SubElement(html, 'body')
    body.set('bgcolor', 'white')
    body.set('text', 'black')
    
    # First table
    table1 = SubElement(body, 'table')
    table1.set('border', '0')
    table1.set('cellpadding', '0')
    table1.set('cellspacing', '0')
    table1.set('width', '780')
    
    tr1 = SubElement(table1, 'tr')
    
    td1 = SubElement(tr1, 'td')
    td1.set('valign', 'top')
    td1.set('align', 'left')
    
    a1 = SubElement(td1, 'a')
    a1.set('href', '/')
    
    img1 = SubElement(a1, 'img')
    img1.set('src', '/images/plume.png')
    img1.set('width', '60')
    img1.set('height', '55')
    img1.set('border', '0')
    img1.set('alt', 'Tcl Home')
    
    img2 = SubElement(a1, 'img')
    img2.set('src', '/images/Developer.gif')
    img2.set('width', '355')
    img2.set('height', '55')
    img2.set('border', '0')
    img2.set('alt', 'Tcl Home')
    img2.set('title', 'Tcl Developer Xchange')
    
    td2 = SubElement(tr1, 'td')
    td2.set('valign', 'top')
    td2.set('align', 'right')
    
    a2 = SubElement(td2, 'a')
    a2.set('href', '/siteinfo.html')
    
    font1 = SubElement(a2, 'font')
    font1.set('size', '1')
    font1.text = 'Hosted by'
    
    br1 = SubElement(td2, 'br')
    
    a3 = SubElement(td2, 'a')
    a3.set('href', 'http://www.ActiveState.com/products/tcl')
    
    img3 = SubElement(a3, 'img')
    img3.set('src', '/images/aslogo.gif')
    img3.set('border', '0')
    img3.set('alt', 'ActiveState')
    img3.set('title', 'This site is hosted by ActiveState')
    
    # Global navigation
    div1 = SubElement(body, 'div')
    div1.set('id', 'globalnav')
    
    ul1 = SubElement(div1, 'ul')
    
    li_list = [
        ('/', 'HOME'),
        ('/about/', 'ABOUT TCL/TK'),
        ('/software/tcltk/', 'SOFTWARE'),
        ('/community/coreteam/', 'CORE DEVELOPMENT'),
        ('/community/', 'COMMUNITY'),
        ('/doc/', 'DOCUMENTATION')
    ]
    
    for href, text in li_list:
        li = SubElement(ul1, 'li')
        a = SubElement(li, 'a')
        a.set('href', href)
        if text == 'DOCUMENTATION':
            a.set('class', 'here')
        a.text = text
    
    # Clear break
    br2 = SubElement(body, 'br')
    br2.set('clear', 'all')
    
    # Divider
    div2 = SubElement(body, 'DIV')
    div2.set('style', 'border-top: 2px solid #3163CE; width: 780px')
    
    # Second table
    table2 = SubElement(body, 'table')
    table2.set('border', '0')
    table2.set('cellpadding', '2')
    table2.set('cellspacing', '0')
    table2.set('width', '780')
    
    tr2 = SubElement(table2, 'tr')
    
    td3 = SubElement(tr2, 'td')
    td3.set('align', 'left')
    td3.set('valign', 'middle')
    
    # Search form
    div3 = SubElement(td3, 'div')
    div3.set('style', 'display:table-cell; vertical-align:middle; margin:0px')
    
    form1 = SubElement(div3, 'FORM')
    form1.set('method', 'GET')
    form1.set('action', 'https://www.google.com/search')
    
    a4 = SubElement(form1, 'A')
    a4.set('HREF', 'https://www.google.com/')
    
    img4 = SubElement(a4, 'IMG')
    img4.set('src', '/images/Search.gif')
    img4.set('border', '0')
    img4.set('ALT', 'Google SiteSearch')
    
    input1 = SubElement(form1, 'INPUT')
    input1.set('TYPE', 'text')
    input1.set('name', 'q')
    input1.set('size', '20')
    input1.set('maxlength', '255')
    input1.set('value', '')
    
    input2 = SubElement(form1, 'INPUT')
    input2.set('type', 'image')
    input2.set('value', 'submit')
    input2.set('name', 'btnG')
    input2.set('src', '/images/Go.gif')
    
    input3 = SubElement(form1, 'input')
    input3.set('type', 'hidden')
    input3.set('name', 'ie')
    input3.set('value', 'UTF-8')
    
    input4 = SubElement(form1, 'input')
    input4.set('type', 'hidden')
    input4.set('name', 'oe')
    input4.set('value', 'UTF-8')
    
    input5 = SubElement(form1, 'input')
    input5.set('type', 'hidden')
    input5.set('name', 'domains')
    input5.set('value', 'tcl.tk')
    
    input6 = SubElement(form1, 'input')
    input6.set('type', 'hidden')
    input6.set('name', 'sitesearch')
    input6.set('value', 'tcl.tk')
    
    # Banner cell
    td4 = SubElement(tr2, 'td')
    td4.set('align', 'right')
    
    p1 = SubElement(td4, 'p')
    p1.set('class', 'banner')
    p1.text = 'Tcl/Tk 8.6 Manual'
    
    # Another divider
    div4 = SubElement(body, 'DIV')
    div4.set('style', 'border-top: 1px solid #FFCE00; margin-bottom: 2px; width: 780px')
    
    # Third table
    table3 = SubElement(body, 'table')
    table3.set('border', '0')
    table3.set('cellpadding', '0')
    table3.set('cellspacing', '0')
    table3.set('width', '780')
    
    tr3 = SubElement(table3, 'tr')
    
    td5 = SubElement(tr3, 'td')
    
    # DL list
    dl1 = SubElement(td5, 'DL')
    dl1.set('class', 'keylist')
    
    dt_links = [
        ('UserCmd/contents.htm', 'Tcl/Tk Applications', 'The interpreters which implement Tcl and Tk.'),
        ('TclCmd/contents.htm', 'Tcl Commands', 'The commands which the <B>tclsh</B> interpreter implements.'),
        ('TkCmd/contents.htm', 'Tk Commands', 'The additional commands which the <B>wish</B> interpreter implements.'),
        ('ItclCmd/contents.htm', '[incr Tcl] Package Commands', 'The additional commands provided by the [incr Tcl] package.'),
        ('SqliteCmd/contents.htm', 'SQLite Package Commands', 'The additional commands provided by the SQLite package.'),
        ('TdbcCmd/contents.htm', 'TDBC Package Commands', 'The additional commands provided by the TDBC package.'),
        ('TdbcmysqlCmd/contents.htm', 'tdbc::mysql Package Commands', 'The additional commands provided by the tdbc::mysql package.'),
        ('TdbcodbcCmd/contents.htm', 'tdbc::odbc Package Commands', 'The additional commands provided by the tdbc::odbc package.'),
        ('TdbcpostgresCmd/contents.htm', 'tdbc::postgres Package Commands', 'The additional commands provided by the tdbc::postgres package.'),
        ('TdbcsqliteCmd/contents.htm', 'tdbc::sqlite3 Package Commands', 'The additional commands provided by the tdbc::sqlite3 package.'),
        ('ThreadCmd/contents.htm', 'Thread Package Commands', 'The additional commands provided by the Thread package.'),
        ('TclLib/contents.htm', 'Tcl Library', 'The C functions which a Tcl extended C program may use.'),
        ('TkLib/contents.htm', 'Tk Library', 'The additional C functions which a Tk extended C program may use.'),
        ('ItclLib/contents.htm', '[incr Tcl] Package Library', 'The additional C functions provided by the [incr Tcl] package.'),
        ('TdbcLib/contents.htm', 'TDBC Package Library', 'The additional C functions provided by the TDBC package.'),
        ('Keywords/contents.htm', 'Keywords', 'The keywords from the Tcl/Tk man pages.')
    ]
    
    for href, text, dd_text in dt_links:
        dt = SubElement(dl1, 'DT')
        a = SubElement(dt, 'A')
        a.set('HREF', href)
        a.text = text
        dd = SubElement(dl1, 'DD')
        dd.text = dd_text
    
    # Comment in HTML
    comment_text = '\n<DT><A HREF="tutorial/tcltutorial.html">Tcl Tutorial</A></DT>\n<DD>Tutorial for Tcl features.</DD>\n'
    # We'll add this as a text element
    comment_element = SubElement(dl1, 'DD')
    comment_element.text = comment_text.strip()
    comment_element.tail = '\n-->'
    
    # Clear break
    br3 = SubElement(body, 'br')
    br3.set('clear', 'all')
    
    # Footer paragraph
    p2 = SubElement(body, 'p')
    p2.set('align', 'center')
    p2.set('class', 'footer')
    
    small1 = SubElement(p2, 'small')
    b1 = SubElement(small1, 'b')
    b1.text = 'This is the main Tcl Developer Xchange site, www.tcl-lang.org .'
    
    # Non-breaking space entities
    nbsp1 = SubElement(p2, 'span')
    nbsp1.text = ' '
    nbsp1.tail = '&nbsp;&nbsp;'
    
    a5 = SubElement(p2, 'a')
    a5.set('href', '/siteinfo.html')
    a5.text = 'About this Site'
    
    span1 = SubElement(p2, 'span')
    span1.text = ' | '
    
    a6 = SubElement(p2, 'a')
    a6.set('href', '/cdn-cgi/l/email-protection#7a0d1f18171b090e1f083a0e191657161b141d')
    
    span2 = SubElement(a6, 'span')
    span2.set('__cf_email__', '')
    span2.set('data-cfemail', '95e2f0f7f8f4e6e1f0e7d5e1f6f9b8f9f4fbf2bbfae7f2')
    span2.text = '[email&#160;protected]'
    
    br4 = SubElement(p2, 'br')
    
    footer_links = [
        ('/', 'Home'),
        ('/about/', 'About Tcl/Tk'),
        ('/software/tcltk/', 'Software'),
        ('/community/coreteam/', 'Core Development'),
        ('/community/', 'Community'),
        ('/doc/', 'Documentation')
    ]
    
    for i, (href, text) in enumerate(footer_links):
        if i > 0:
            span = SubElement(p2, 'span')
            span.text = ' | '
        
        a = SubElement(p2, 'a')
        a.set('href', href)
        a.text = text
    
    # Script tag
    script1 = SubElement(body, 'script')
    script1.set('data-cfasync', 'false')
    script1.set('src', '/cdn-cgi/scripts/5c5dd728/cloudflare-static/email-decode.min.js')
    script1.set('defer', '')
    
    return html

def prettify(elem):
    """Return a pretty-printed XML string for the Element."""
    rough_string = tostring(elem, encoding='unicode')
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="  ").replace('<?xml version="1.0" ?>\n', '')

def main():
    if len(sys.argv) != 2:
        print("Usage: {} <output_file>".format(sys.argv[0]))
        sys.exit(1)
    
    output_file = sys.argv[1]
    
    # Create HTML structure
    html_root = create_html()
    
    # Add DOCTYPE declaration manually
    doctype = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">\n'
    
    # Convert to string with pretty formatting
    html_string = prettify(html_root)
    
    # Write to file with DOCTYPE
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(doctype + html_string)

if __name__ == '__main__':
    main()
