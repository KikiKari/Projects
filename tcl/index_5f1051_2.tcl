#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "6a941a3fd8cf6e10c03a76ad138d2dea7d0106def609e81219a32d0b5c559252", "source_sha256": "5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988", "target_language": "tcl"}
# index.html — portiert nach tcl
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

proc writeIndexHtml {filename} {
    set fd [open $filename w]
    
    puts $fd {<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">}
    puts $fd {<html>}
    puts $fd {<head>	<title>Tcl/Tk 8.6 Manual</title>}
    puts $fd {	<meta name="viewport" content="width=device-width, initial-scale=1">}
    puts $fd {	<link rel="stylesheet" href="/devsite.css" type="text/css" media="all">}
    puts $fd {</head>}
    puts $fd {<body bgcolor="white" text="black">}
    puts $fd {}
    puts $fd {	<table border="0" cellpadding="0" cellspacing="0" width="780">}
    puts $fd {	    <tr>}
    puts $fd {	    <td valign="top" align="left"><a href="/"><img src="/images/plume.png" width="60" height="55"}
    puts $fd {	border="0" alt="Tcl Home" /><img src="/images/Developer.gif" width="355" height="55"}
    puts $fd {	border="0" alt="Tcl Home" title="Tcl Developer Xchange" /></a></td>}
    puts $fd {	    <td valign="top" align="right"><a href="/siteinfo.html"><font size=1>Hosted by</font></a><br><a href="http://www.ActiveState.com/products/tcl"><img src="/images/aslogo.gif"}
    puts $fd {	border="0" alt="ActiveState"}
    puts $fd {	title="This site is hosted by ActiveState" /></a></td>}
    puts $fd {	    </tr>}
    puts $fd {	</table>}
    puts $fd {    <div id="globalnav"><ul>}
    puts $fd {<li><a href="/">HOME</a></li>}
    puts $fd {<li><a href="/about/">ABOUT TCL/TK</a></li>}
    puts $fd {<li><a href="/software/tcltk/">SOFTWARE</a></li>}
    puts $fd {<li><a href="/community/coreteam/">CORE DEVELOPMENT</a></li>}
    puts $fd {<li><a href="/community/">COMMUNITY</a></li>}
    puts $fd {<li><a href="/doc/" class="here">DOCUMENTATION</a></li>}
    puts $fd {</ul></div>}
    puts $fd {<br clear="all" />}
    puts $fd {<DIV style="border-top: 2px solid #3163CE; width: 780px"></DIV>}
    puts $fd {<table border="0" cellpadding="2" cellspacing="0" width="780">}
    puts $fd {	    <tr><td align="left" valign="middle">}
    puts $fd {<!-- SiteSearch Google -->}
    puts $fd {	<div style="display:table-cell; vertical-align:middle; margin:0px">}
    puts $fd {<FORM method="GET" action="https://www.google.com/search">}
    puts $fd {<A HREF="https://www.google.com/"><IMG src="/images/Search.gif" border="0"}
    puts $fd {ALT="Google SiteSearch" /></A>}
    puts $fd {<INPUT TYPE="text" name="q" size="20" maxlength="255" value="">}
    puts $fd {<INPUT type="image" value="submit" name="btnG" src="/images/Go.gif">}
    puts $fd {<input type="hidden" name="ie" value="UTF-8">}
    puts $fd {<input type="hidden" name="oe" value="UTF-8">}
    puts $fd {<input type="hidden" name="domains" value="tcl.tk">}
    puts $fd {<input type="hidden" name="sitesearch" value="tcl.tk">}
    puts $fd {</FORM></div>}
    puts $fd {<!-- SiteSearch Google -->}
    puts $fd {</td><td }
    puts $fd {	    align="right"><p class="banner">Tcl/Tk 8.6 Manual</p></td></tr></table>}
    puts $fd {	<DIV style="border-top: 1px solid #FFCE00; margin-bottom: 2px; width: 780px"></DIV><table border="0" cellpadding="0" cellspacing="0" width="780">}
    puts $fd {<tr><td>}
    puts $fd {<DL class="keylist">}
    puts $fd {<DT><A HREF="UserCmd/contents.htm">Tcl/Tk Applications</A></DT>}
    puts $fd {<DD>The interpreters which implement Tcl and Tk.</DD>}
    puts $fd {<DT><A HREF="TclCmd/contents.htm">Tcl Commands</A></DT>}
    puts $fd {<DD>The commands which the <B>tclsh</B> interpreter implements.</DD>}
    puts $fd {<DT><A HREF="TkCmd/contents.htm">Tk Commands</A></DT>}
    puts $fd {<DD>The additional commands which the <B>wish</B> interpreter implements.</DD>}
    puts $fd {<DT><A HREF="ItclCmd/contents.htm">[incr Tcl] Package Commands</A></DT>}
    puts $fd {<DD>The additional commands provided by the [incr Tcl] package.</DD>}
    puts $fd {<DT><A HREF="SqliteCmd/contents.htm">SQLite Package Commands</A></DT>}
    puts $fd {<DD>The additional commands provided by the SQLite package.</DD>}
    puts $fd {<DT><A HREF="TdbcCmd/contents.htm">TDBC Package Commands</A></DT>}
    puts $fd {<DD>The additional commands provided by the TDBC package.</DD>}
    puts $fd {<DT><A HREF="TdbcmysqlCmd/contents.htm">tdbc::mysql Package Commands</A></DT>}
    puts $fd {<DD>The additional commands provided by the tdbc::mysql package.</DD>}
    puts $fd {<DT><A HREF="TdbcodbcCmd/contents.htm">tdbc::odbc Package Commands</A></DT>}
    puts $fd {<DD>The additional commands provided by the tdbc::odbc package.</DD>}
    puts $fd {<DT><A HREF="TdbcpostgresCmd/contents.htm">tdbc::postgres Package Commands</A></DT>}
    puts $fd {<DD>The additional commands provided by the tdbc::postgres package.</DD>}
    puts $fd {<DT><A HREF="TdbcsqliteCmd/contents.htm">tdbc::sqlite3 Package Commands</A></DT>}
    puts $fd {<DD>The additional commands provided by the tdbc::sqlite3 package.</DD>}
    puts $fd {<DT><A HREF="ThreadCmd/contents.htm">Thread Package Commands</A></DT>}
    puts $fd {<DD>The additional commands provided by the Thread package.</DD>}
    puts $fd {<DT><A HREF="TclLib/contents.htm">Tcl Library</A></DT>}
    puts $fd {<DD>The C functions which a Tcl extended C program may use.</DD>}
    puts $fd {<DT><A HREF="TkLib/contents.htm">Tk Library</A></DT>}
    puts $fd {<DD>The additional C functions which a Tk extended C program may use.</DD>}
    puts $fd {<DT><A HREF="ItclLib/contents.htm">[incr Tcl] Package Library</A></DT>}
    puts $fd {<DD>The additional C functions provided by the [incr Tcl] package.</DD>}
    puts $fd {<DT><A HREF="TdbcLib/contents.htm">TDBC Package Library</A></DT>}
    puts $fd {<DD>The additional C functions provided by the TDBC package.</DD>}
    puts $fd {<DT><A HREF="Keywords/contents.htm">Keywords</A>}
    puts $fd {<DD>The keywords from the Tcl/Tk man pages.}
    puts $fd {<!--}
    puts $fd {<DT><A HREF="tutorial/tcltutorial.html">Tcl Tutorial</A></DT>}
    puts $fd {<DD>Tutorial for Tcl features.</DD>}
    puts $fd {-->}
    puts $fd {</DL>}
    puts $fd {}
    puts $fd {<br clear="all" />}
    puts $fd {<p align="center" class="footer">}
    puts $fd {		    <small><b>}
    puts $fd {		    This is the main Tcl Developer Xchange site,}
    puts $fd {		    www.tcl-lang.org .}
    puts $fd {		    </b></small>}
    puts $fd {		&nbsp;&nbsp;}
    puts $fd {<a href="/siteinfo.html">About this Site</a> |}
    puts $fd {<a href="/cdn-cgi/l/email-protection#7a0d1f18171b090e1f083a0e191657161b141d5415081d"><span class="__cf_email__" data-cfemail="95e2f0f7f8f4e6e1f0e7d5e1f6f9b8f9f4fbf2bbfae7f2">[email&#160;protected]</span></a>}
    puts $fd {<br>}
    puts $fd {<a href="/">Home</a> | }
    puts $fd {<a href="/about/">About Tcl/Tk</a> |}
    puts $fd {<a href="/software/tcltk/">Software</a> | }
    puts $fd {<a href="/community/coreteam/">Core Development</a> |}
    puts $fd {<a href="/community/">Community</a> |}
    puts $fd {<a href="/doc/">Documentation</a>}
    puts $fd {</p>}
    puts $fd {</td></tr></table><script data-cfasync="false" src="/cdn-cgi/scripts/5c5dd728/cloudflare-static/email-decode.min.js" defer></script></body></html>}
    
    close $fd
}

# Hauptprogramm
if {$argc != 1} {
    puts stderr "Usage: $argv0 <output-file>"
    exit 1
}

set outputFile [lindex $argv 0]
writeIndexHtml $outputFile
