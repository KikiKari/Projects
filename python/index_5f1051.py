#!/usr/bin/env python3
# index.html — portiert nach python
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import sys
from html import escape

def generate_html():
    html_content = '''<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>\t<title>Tcl/Tk 8.6 Manual</title>
\t<meta name="viewport" content="width=device-width, initial-scale=1">
\t<link rel="stylesheet" href="/devsite.css" type="text/css" media="all">
</head>
<body bgcolor="white" text="black">

\t<table border="0" cellpadding="0" cellspacing="0" width="780">
\t    <tr>
\t    <td valign="top" align="left"><a href="/"><img src="/images/plume.png" width="60" height="55"
\tborder="0" alt="Tcl Home" /><img src="/images/Developer.gif" width="355" height="55"
\tborder="0" alt="Tcl Home" title="Tcl Developer Xchange" /></a></td>
\t    <td valign="top" align="right"><a href="/siteinfo.html"><font size=1>Hosted by</font></a><br><a href="http://www.ActiveState.com/products/tcl"><img src="/images/aslogo.gif"
\tborder="0" alt="ActiveState"
\ttitle="This site is hosted by ActiveState" /></a></td>
\t    </tr>
\t</table>
    <div id="globalnav"><ul>
<li><a href="/">HOME</a></li>
<li><a href="/about/">ABOUT TCL/TK</a></li>
<li><a href="/software/tcltk/">SOFTWARE</a></li>
<li><a href="/community/coreteam/">CORE DEVELOPMENT</a></li>
<li><a href="/community/">COMMUNITY</a></li>
<li><a href="/doc/" class="here">DOCUMENTATION</a></li>
</ul></div>
<br clear="all" />
<DIV style="border-top: 2px solid #3163CE; width: 780px"></DIV>
<table border="0" cellpadding="2" cellspacing="0" width="780">
\t    <tr><td align="left" valign="middle">
<!-- SiteSearch Google -->
\t<div style="display:table-cell; vertical-align:middle; margin:0px">
<FORM method="GET" action="https://www.google.com/search">
<A HREF="https://www.google.com/"><IMG src="/images/Search.gif" border="0"
ALT="Google SiteSearch" /></A>
<INPUT TYPE="text" name="q" size="20" maxlength="255" value="">
<INPUT type="image" value="submit" name="btnG" src="/images/Go.gif">
<input type="hidden" name="ie" value="UTF-8">
<input type="hidden" name="oe" value="UTF-8">
<input type="hidden" name="domains" value="tcl.tk">
<input type="hidden" name="sitesearch" value="tcl.tk">
</FORM></div>
<!-- SiteSearch Google -->
</td><td 
\t    align="right"><p class="banner">Tcl/Tk 8.6 Manual</p></td></tr></table>
\t<DIV style="border-top: 1px solid #FFCE00; margin-bottom: 2px; width: 780px"></DIV><table border="0" cellpadding="0" cellspacing="0" width="780">
<tr><td>
<DL class="keylist">
<DT><A HREF="UserCmd/contents.htm">Tcl/Tk Applications</A></DT>
<DD>The interpreters which implement Tcl and Tk.</DD>
<DT><A HREF="TclCmd/contents.htm">Tcl Commands</A></DT>
<DD>The commands which the <B>tclsh</B> interpreter implements.</DD>
<DT><A HREF="TkCmd/contents.htm">Tk Commands</A></DT>
<DD>The additional commands which the <B>wish</B> interpreter implements.</DD>
<DT><A HREF="ItclCmd/contents.htm">[incr Tcl] Package Commands</A></DT>
<DD>The additional commands provided by the [incr Tcl] package.</DD>
<DT><A HREF="SqliteCmd/contents.htm">SQLite Package Commands</A></DT>
<DD>The additional commands provided by the SQLite package.</DD>
<DT><A HREF="TdbcCmd/contents.htm">TDBC Package Commands</A></DT>
<DD>The additional commands provided by the TDBC package.</DD>
<DT><A HREF="TdbcmysqlCmd/contents.htm">tdbc::mysql Package Commands</A></DT>
<DD>The additional commands provided by the tdbc::mysql package.</DD>
<DT><A HREF="TdbcodbcCmd/contents.htm">tdbc::odbc Package Commands</A></DT>
<DD>The additional commands provided by the tdbc::odbc package.</DD>
<DT><A HREF="TdbcpostgresCmd/contents.htm">tdbc::postgres Package Commands</A></DT>
<DD>The additional commands provided by the tdbc::postgres package.</DD>
<DT><A HREF="TdbcsqliteCmd/contents.htm">tdbc::sqlite3 Package Commands</A></DT>
<DD>The additional commands provided by the tdbc::sqlite3 package.</DD>
<DT><A HREF="ThreadCmd/contents.htm">Thread Package Commands</A></DT>
<DD>The additional commands provided by the Thread package.</DD>
<DT><A HREF="TclLib/contents.htm">Tcl Library</A></DT>
<DD>The C functions which a Tcl extended C program may use.</DD>
<DT><A HREF="TkLib/contents.htm">Tk Library</A></DT>
<DD>The additional C functions which a Tk extended C program may use.</DD>
<DT><A HREF="ItclLib/contents.htm">[incr Tcl] Package Library</A></DT>
<DD>The additional C functions provided by the [incr Tcl] package.</DD>
<DT><A HREF="TdbcLib/contents.htm">TDBC Package Library</A></DT>
<DD>The additional C functions provided by the TDBC package.</DD>
<DT><A HREF="Keywords/contents.htm">Keywords</A>
<DD>The keywords from the Tcl/Tk man pages.
<!--
<DT><A HREF="tutorial/tcltutorial.html">Tcl Tutorial</A></DT>
<DD>Tutorial for Tcl features.</DD>
-->
</DL>

<br clear="all" />
<p align="center" class="footer">
\t\t    <small><b>
\t\t    This is the main Tcl Developer Xchange site,
\t\t    www.tcl-lang.org .
\t\t    </b></small>
\t\t&nbsp;&nbsp;
<a href="/siteinfo.html">About this Site</a> |
<a href="/cdn-cgi/l/email-protection#7a0d1f18171b090e1f083a0e191657161b141d5415081d"><span class="__cf_email__" data-cfemail="95e2f0f7f8f4e6e1f0e7d5e1f6f9b8f9f4fbf2bbfae7f2">[email&#160;protected]</span></a>
<br>
<a href="/">Home</a> | 
<a href="/about/">About Tcl/Tk</a> |
<a href="/software/tcltk/">Software</a> | 
<a href="/community/coreteam/">Core Development</a> |
<a href="/community/">Community</a> |
<a href="/doc/">Documentation</a>
</p>
</td></tr></table><script data-cfasync="false" src="/cdn-cgi/scripts/5c5dd728/cloudflare-static/email-decode.min.js" defer></script></body></html>
'''
    return html_content

def main():
    if len(sys.argv) != 2:
        print("Usage: {} <output_file>".format(sys.argv[0]))
        sys.exit(1)
    
    output_file = sys.argv[1]
    
    html_content = generate_html()
    
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(html_content)
        print(f"HTML file generated successfully: {output_file}")
    except IOError as e:
        print(f"Error writing to file {output_file}: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
