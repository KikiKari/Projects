#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "8d64816d21290223e2378fe11505ae18dc4905ab47fdc23d2f950bd3379005e9", "source_sha256": "5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988", "target_language": "lua"}
-- index.html — portiert nach lua
-- Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html
-- auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local function write_html_to_file(filename)
    local file = io.open(filename, "w")
    if not file then
        print("Error: Could not open file " .. filename .. " for writing.")
        return
    end

    -- HTML header
    file:write([[
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>	<title>Tcl/Tk 8.6 Manual</title>
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="stylesheet" href="/devsite.css" type="text/css" media="all">
</head>
<body bgcolor="white" text="black">

]])

    -- Table with header images
    file:write([[
	<table border="0" cellpadding="0" cellspacing="0" width="780">
	    <tr>
	    <td valign="top" align="left"><a href="/"><img src="/images/plume.png" width="60" height="55"
	border="0" alt="Tcl Home" /><img src="/images/Developer.gif" width="355" height="55"
	border="0" alt="Tcl Home" title="Tcl Developer Xchange" /></a></td>
	    <td valign="top" align="right"><a href="/siteinfo.html"><font size=1>Hosted by</font></a><br><a href="http://www.ActiveState.com/products/tcl"><img src="/images/aslogo.gif"
	border="0" alt="ActiveState"
	title="This site is hosted by ActiveState" /></a></td>
	    </tr>
	</table>
]])

    -- Navigation bar
    file:write([[
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
]])

    -- Search form table
    file:write([[
<table border="0" cellpadding="2" cellspacing="0" width="780">
	    <tr><td align="left" valign="middle">
<!-- SiteSearch Google -->
	<div style="display:table-cell; vertical-align:middle; margin:0px">
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
	    align="right"><p class="banner">Tcl/Tk 8.6 Manual</p></td></tr></table>
]])

    -- Yellow divider line
    file:write([[	<DIV style="border-top: 1px solid #FFCE00; margin-bottom: 2px; width: 780px"></DIV>]])

    -- Main content table
    file:write([[
<table border="0" cellpadding="0" cellspacing="0" width="780">
<tr><td>
<DL class="keylist">
]])

    -- Key list items
    local keylist_items = {
        {"UserCmd/contents.htm", "Tcl/Tk Applications", "The interpreters which implement Tcl and Tk."},
        {"TclCmd/contents.htm", "Tcl Commands", "The commands which the <B>tclsh</B> interpreter implements."},
        {"TkCmd/contents.htm", "Tk Commands", "The additional commands which the <B>wish</B> interpreter implements."},
        {"ItclCmd/contents.htm", "[incr Tcl] Package Commands", "The additional commands provided by the [incr Tcl] package."},
        {"SqliteCmd/contents.htm", "SQLite Package Commands", "The additional commands provided by the SQLite package."},
        {"TdbcCmd/contents.htm", "TDBC Package Commands", "The additional commands provided by the TDBC package."},
        {"TdbcmysqlCmd/contents.htm", "tdbc::mysql Package Commands", "The additional commands provided by the tdbc::mysql package."},
        {"TdbcodbcCmd/contents.htm", "tdbc::odbc Package Commands", "The additional commands provided by the tdbc::odbc package."},
        {"TdbcpostgresCmd/contents.htm", "tdbc::postgres Package Commands", "The additional commands provided by the tdbc::postgres package."},
        {"TdbcsqliteCmd/contents.htm", "tdbc::sqlite3 Package Commands", "The additional commands provided by the tdbc::sqlite3 package."},
        {"ThreadCmd/contents.htm", "Thread Package Commands", "The additional commands provided by the Thread package."},
        {"TclLib/contents.htm", "Tcl Library", "The C functions which a Tcl extended C program may use."},
        {"TkLib/contents.htm", "Tk Library", "The additional C functions which a Tk extended C program may use."},
        {"ItclLib/contents.htm", "[incr Tcl] Package Library", "The additional C functions provided by the [incr Tcl] package."},
        {"TdbcLib/contents.htm", "TDBC Package Library", "The additional C functions provided by the TDBC package."},
        {"Keywords/contents.htm", "Keywords", "The keywords from the Tcl/Tk man pages.\n<!--\n<DT><A HREF=\"tutorial/tcltutorial.html\">Tcl Tutorial</A></DT>\n<DD>Tutorial for Tcl features.</DD>\n-->"}
    }

    for _, item in ipairs(keylist_items) do
        file:write("<DT><A HREF=\"" .. item[1] .. "\">" .. item[2] .. "</A></DT>\n")
        file:write("<DD>" .. item[3] .. "</DD>\n")
    end

    -- Footer content
    file:write([[
</DL>

<br clear="all" />
<p align="center" class="footer">
		    <small><b>
		    This is the main Tcl Developer Xchange site,
		    www.tcl-lang.org .
		    </b></small>
		&nbsp;&nbsp;
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
</td></tr></table>]])

    -- Script tag at the end of body
    file:write([[<script data-cfasync="false" src="/cdn-cgi/scripts/5c5dd728/cloudflare-static/email-decode.min.js" defer></script>]])

    -- Closing tags
    file:write([[
</body></html>
]])

    file:close()
    print("HTML content written to " .. filename)
end

-- Check command line argument
if #arg ~= 1 then
    print("Usage: " .. arg[0] .. " <output_filename>")
    os.exit(1)
end

write_html_to_file(arg[1])
