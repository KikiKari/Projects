#!/usr/bin/env tclsh
# index.html — portiert nach tcl
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Tcl script to generate index.html file

proc write_index_html {filename} {
    set fp [open $filename w]
    
    puts $fp {<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">}
    puts $fp {<html>}
    puts $fp {<head>	<title>Tcl/Tk 8.6 Manual</title>}
    puts $fp {	<meta name="viewport" content="width=device-width, initial-scale=1">}
    puts $fp {	<link rel="stylesheet" href="/devsite.css" type="text/css" media="all">}
    puts $fp {</head>}
    puts $fp {<body bgcolor="white" text="black">}
    puts $fp {}
    puts $fp {	<table border="0" cellpadding="0" cellspacing="0" width="780">}
    puts $fp {	    <tr>}
    puts $fp {	    <td valign="top" align="left"><a href="/"><img src="/images/plume.png" width="60" height="55"}
    puts $fp {	border="0" alt="Tcl Home" /><img src="/images/Developer.gif" width="355" height="55"}
    puts $fp {	border="0" alt="Tcl Home" title="Tcl Developer Xchange" /></a></td>}
    puts $fp {	    <td valign="top" align="right"><a href="/siteinfo.html"><font size=1>Hosted by</font></a><br><a href="http://www.ActiveState.com/products/tcl"><img src="/images/aslogo.gif"}
    puts $fp {	border="0" alt="ActiveState"}
    puts $fp {	title="This site is hosted by ActiveState" /></a></td>}
    puts $fp {	    </tr>}
    puts $fp {	</table>}
    puts $fp {    <div id="globalnav"><ul>}
    puts $fp {<li><a href="/">HOME</a></li>}
    puts $fp {<li><a href="/about/">ABOUT TCL/TK</a></li>}
    puts $fp {<li><a href="/software/tcltk/">SOFTWARE</a></li>}
    puts $fp {<li><a href="/community/coreteam/">CORE DEVELOPMENT</a></li>}
    puts $fp {<li><a href="/community/">COMMUNITY</a></li>}
    puts $fp {<li><a href="/doc/" class="here">DOCUMENTATION</a></li>}
    puts $fp {</ul></div>}
    puts $fp {<br clear="all" />}
    puts $fp {<DIV style="border-top: 2px solid #3163CE; width: 780px"></DIV>}
    puts $fp {<table border="0" cellpadding="2" cellspacing="0" width="780">}
    puts $fp {	    <tr><td align="left" valign="middle">}
    puts $fp {<!-- SiteSearch Google -->}
    puts $fp {	<div style="display:table-cell; vertical-align:middle; margin:0px">}
    puts $fp {<FORM method="GET" action="https://www.google.com/search">}
    puts $fp {<A HREF="https://www.google.com/"><IMG src="/images/Search.gif" border="0"}
    puts $fp {ALT="Google SiteSearch" /></A>}
    puts $fp {<INPUT TYPE="text" name="q" size="20" maxlength="255" value="">}
    puts $fp {<INPUT type="image" value="submit" name="btnG" src="/images/Go.gif">}
    puts $fp {<input type="hidden" name="ie" value="UTF-8">}
    puts $fp {<input type="hidden" name="oe" value="UTF-8">}
    puts $fp {<input type="hidden" name="domains" value="tcl.tk">}
    puts $fp {<input type="hidden" name="sitesearch" value="tcl.tk">}
    puts $fp {</FORM></div>}
    puts $fp {<!-- SiteSearch Google -->}
    puts $fp {</td><td }
    puts $fp {	    align="right"><p class="banner">Tcl/Tk 8.6 Manual</p></td></tr></table>}
    puts $fp {	<DIV style="border-top: 1px solid #FFCE00; margin-bottom: 2px; width: 780px"></DIV><table border="0" cellpadding="0" cellspacing="0" width="780">}
    puts $fp {<tr><td>}
    puts $fp {<DL class="keylist">}
    puts $fp {<DT><A HREF="UserCmd/contents.htm">Tcl/Tk Applications</A></DT>}
    puts $fp {<DD>The interpreters which implement Tcl and Tk.</DD>}
    puts $fp {<DT><A HREF="TclCmd/contents.htm">Tcl Commands</A></DT>}
    puts $fp {<DD>The commands which the <B>tclsh</B> interpreter implements.</DD>}
    puts $fp {<DT><A HREF="TkCmd/contents.htm">Tk Commands</A></DT>}
    puts $fp {<DD>The additional commands which the <B>wish</B> interpreter implements.</DD>}
    puts $fp {<DT><A HREF="ItclCmd/contents.htm">[incr Tcl] Package Commands</A></DT>}
    puts $fp {<DD>The additional commands provided by the [incr Tcl] package.</DD>}
    puts $fp {<DT><A HREF="SqliteCmd/contents.htm">SQLite Package Commands</A></DT>}
    puts $fp {<DD>The additional commands provided by the SQLite package.</DD>}
    puts $fp {<DT><A HREF="TdbcCmd/contents.htm">TDBC Package Commands</A></DT>}
    puts $fp {<DD>The additional commands provided by the TDBC package.</DD>}
    puts $fp {<DT><A HREF="TdbcmysqlCmd/contents.htm">tdbc::mysql Package Commands</A></DT>}
    puts $fp {<DD>The additional commands provided by the tdbc::mysql package.</DD>}
    puts $fp {<DT><A HREF="TdbcodbcCmd/contents.htm">tdbc::odbc Package Commands</A></DT>}
    puts $fp {<DD>The additional commands provided by the tdbc::odbc package.</DD>}
    puts $fp {<DT><A HREF="TdbcpostgresCmd/contents.htm">tdbc::postgres Package Commands</A></DT>}
    puts $fp {<DD>The additional commands provided by the tdbc::postgres package.</DD>}
    puts $fp {<DT><A HREF="TdbcsqliteCmd/contents.htm">tdbc::sqlite3 Package Commands</A></DT>}
    puts $fp {<DD>The additional commands provided by the tdbc::sqlite3 package.</DD>}
    puts $fp {<DT><A HREF="ThreadCmd/contents.htm">Thread Package Commands</A></DT>}
    puts $fp {<DD>The additional commands provided by the Thread package.</DD>}
    puts $fp {<DT><A HREF="TclLib/contents.htm">Tcl Library</A></DT>}
    puts $fp {<DD>The C functions which a Tcl extended C program may use.</DD>}
    puts $fp {<DT><A HREF="TkLib/contents.htm">Tk Library</A></DT>}
    puts $fp {<DD>The additional C functions which a Tk extended C program may use.</DD>}
    puts $fp {<DT><A HREF="ItclLib/contents.htm">[incr Tcl] Package Library</A></DT>}
    puts $fp {<DD>The additional C functions provided by the [incr Tcl] package.</DD>}
    puts $fp {<DT><A HREF="TdbcLib/contents.htm">TDBC Package Library</A></DT>}
    puts $fp {<DD>The additional C functions provided by the TDBC package.</DD>}
    puts $fp {<DT><A HREF="Keywords/contents.htm">Keywords</A>}
    puts $fp {<DD>The keywords from the Tcl/Tk man pages.}
    puts $fp {<!--}
    puts $fp {<DT><A HREF="tutorial/tcltutorial.html">Tcl Tutorial</A></DT>}
    puts $fp {<DD>Tutorial for Tcl features.</DD>}
    puts $fp {-->}
    puts $fp {</DL>}
    puts $fp {}
    puts $fp {<br clear="all" />}
    puts $fp {<p align="center" class="footer">}
    puts $fp {		    <small><b>}
    puts $fp {		    This is the main Tcl Developer Xchange site,}
    puts $fp {		    www.tcl-lang.org .}
    puts $fp {		    </b></small>}
    puts $fp {		&nbsp;&nbsp;}
    puts $fp {<a href="/siteinfo.html">About this Site</a> |}
    puts $fp {<a href="/cdn-cgi/l/email-protection#7a0d1f18171b090e1f083a0e191657161b141d5415081d"><span class="__cf_email__" data-cfemail="95e2f0f7f8f4e6e1f0e7d5e1f6f9b8f9f4fbf2bbfae7f2">[email&#160;protected]</span></a>}
    puts $fp {<br>}
    puts $fp {<a href="/">Home</a> | }
    puts $fp {<a href="/about/">About Tcl/Tk</a> |}
    puts $fp {<a href="/software/tcltk/">Software</a> | }
    puts $fp {<a href="/community/coreteam/">Core Development</a> |}
    puts $fp {<a href="/community/">Community</a> |}
    puts $fp {<a href="/doc/">Documentation</a>}
    puts $fp {</p>}
    puts $fp {</td></tr></table><script data-cfasync="false" src="/cdn-cgi/scripts/5c5dd728/cloudflare-static/email-decode.min.js" defer></script></body></html>}
    
    close $fp
}

# Check if filename argument is provided
if {$argc != 1} {
    puts stderr "Usage: $argv0 <output_filename>"
    exit 1
}

set output_file [lindex $argv 0]
write_index_html $output_file
