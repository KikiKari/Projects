#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "ae7dd0518ac1ea63e66f5c2c1271c204e475ff60acb14264bf12f37b9d7aacfb", "source_sha256": "5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988", "target_language": "perl5"}
# index.html — portiert nach perl5
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Get output filename from command line argument
my $output_file = shift @ARGV or die "Usage: $0 <output_filename>\n";

# Open file for writing
open(my $fh, '>', $output_file) or die "Cannot open file '$output_file' for writing: $!";

# Print DOCTYPE
print $fh qq(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">\n);

# Print HTML start tag
print $fh "<html>\n";

# Print head section
print $fh <<'EOF';
<head>	<title>Tcl/Tk 8.6 Manual</title>
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="stylesheet" href="/devsite.css" type="text/css" media="all">
</head>
EOF

# Print body start
print $fh qq(<body bgcolor="white" text="black">\n\n);

# Print first table
print $fh qq(\t<table border="0" cellpadding="0" cellspacing="0" width="780">\n);
print $fh qq(\t    <tr>\n);
print $fh qq(\t    <td valign="top" align="left"><a href="/"><img src="/images/plume.png" width="60" height="55"\n);
print $fh qq(\tborder="0" alt="Tcl Home" /><img src="/images/Developer.gif" width="355" height="55"\n);
print $fh qq(\tborder="0" alt="Tcl Home" title="Tcl Developer Xchange" /></a></td>\n);
print $fh qq(\t    <td valign="top" align="right"><a href="/siteinfo.html"><font size=1>Hosted by</font></a><br><a href="http://www.ActiveState.com/products/tcl"><img src="/images/aslogo.gif"\n);
print $fh qq(\tborder="0" alt="ActiveState"\n);
print $fh qq(\ttitle="This site is hosted by ActiveState" /></a></td>\n);
print $fh qq(\t    </tr>\n);
print $fh qq(\t</table>\n);

# Print navigation div
print $fh qq(    <div id="globalnav"><ul>\n);
print $fh qq(<li><a href="/">HOME</a></li>\n);
print $fh qq(<li><a href="/about/">ABOUT TCL/TK</a></li>\n);
print $fh qq(<li><a href="/software/tcltk/">SOFTWARE</a></li>\n);
print $fh qq(<li><a href="/community/coreteam/">CORE DEVELOPMENT</a></li>\n);
print $fh qq(<li><a href="/community/">COMMUNITY</a></li>\n);
print $fh qq(<li><a href="/doc/" class="here">DOCUMENTATION</a></li>\n);
print $fh qq(</ul></div>\n);

# Print clearing break and divider
print $fh qq(<br clear="all" />\n);
print $fh qq(<DIV style="border-top: 2px solid #3163CE; width: 780px"></DIV>\n);

# Print second table
print $fh qq(<table border="0" cellpadding="2" cellspacing="0" width="780">\n);
print $fh qq(\t\t    <tr><td align="left" valign="middle">\n);
print $fh qq(<!-- SiteSearch Google -->\n);
print $fh qq(\t<div style="display:table-cell; vertical-align:middle; margin:0px">\n);
print $fh qq(<FORM method="GET" action="https://www.google.com/search">\n);
print $fh qq(<A HREF="https://www.google.com/"><IMG src="/images/Search.gif" border="0"\n);
print $fh qq(ALT="Google SiteSearch" /></A>\n);
print $fh qq(<INPUT TYPE="text" name="q" size="20" maxlength="255" value="">\n);
print $fh qq(<INPUT type="image" value="submit" name="btnG" src="/images/Go.gif">\n);
print $fh qq(<input type="hidden" name="ie" value="UTF-8">\n);
print $fh qq(<input type="hidden" name="oe" value="UTF-8">\n);
print $fh qq(<input type="hidden" name="domains" value="tcl.tk">\n);
print $fh qq(<input type="hidden" name="sitesearch" value="tcl.tk">\n);
print $fh qq(</FORM></div>\n);
print $fh qq(<!-- SiteSearch Google -->\n);
print $fh qq(</td><td \n);
print $fh qq(\t    align="right"><p class="banner">Tcl/Tk 8.6 Manual</p></td></tr></table>\n);

# Print second divider
print $fh qq(\t<DIV style="border-top: 1px solid #FFCE00; margin-bottom: 2px; width: 780px"></DIV>);

# Print third table
print $fh qq(<table border="0" cellpadding="0" cellspacing="0" width="780">\n);
print $fh qq(<tr><td>\n);

# Print DL list
print $fh qq(<DL class="keylist">\n);
print $fh qq(<DT><A HREF="UserCmd/contents.htm">Tcl/Tk Applications</A></DT>\n);
print $fh qq(<DD>The interpreters which implement Tcl and Tk.</DD>\n);
print $fh qq(<DT><A HREF="TclCmd/contents.htm">Tcl Commands</A></DT>\n);
print $fh qq(<DD>The commands which the <B>tclsh</B> interpreter implements.</DD>\n);
print $fh qq(<DT><A HREF="TkCmd/contents.htm">Tk Commands</A></DT>\n);
print $fh qq(<DD>The additional commands which the <B>wish</B> interpreter implements.</DD>\n);
print $fh qq(<DT><A HREF="ItclCmd/contents.htm">[incr Tcl] Package Commands</A></DT>\n);
print $fh qq(<DD>The additional commands provided by the [incr Tcl] package.</DD>\n);
print $fh qq(<DT><A HREF="SqliteCmd/contents.htm">SQLite Package Commands</A></DT>\n);
print $fh qq(<DD>The additional commands provided by the SQLite package.</DD>\n);
print $fh qq(<DT><A HREF="TdbcCmd/contents.htm">TDBC Package Commands</A></DT>\n);
print $fh qq(<DD>The additional commands provided by the TDBC package.</DD>\n);
print $fh qq(<DT><A HREF="TdbcmysqlCmd/contents.htm">tdbc::mysql Package Commands</A></DT>\n);
print $fh qq(<DD>The additional commands provided by the tdbc::mysql package.</DD>\n);
print $fh qq(<DT><A HREF="TdbcodbcCmd/contents.htm">tdbc::odbc Package Commands</A></DT>\n);
print $fh qq(<DD>The additional commands provided by the tdbc::odbc package.</DD>\n);
print $fh qq(<DT><A HREF="TdbcpostgresCmd/contents.htm">tdbc::postgres Package Commands</A></DT>\n);
print $fh qq(<DD>The additional commands provided by the tdbc::postgres package.</DD>\n);
print $fh qq(<DT><A HREF="TdbcsqliteCmd/contents.htm">tdbc::sqlite3 Package Commands</A></DT>\n);
print $fh qq(<DD>The additional commands provided by the tdbc::sqlite3 package.</DD>\n);
print $fh qq(<DT><A HREF="ThreadCmd/contents.htm">Thread Package Commands</A></DT>\n);
print $fh qq(<DD>The additional commands provided by the Thread package.</DD>\n);
print $fh qq(<DT><A HREF="TclLib/contents.htm">Tcl Library</A></DT>\n);
print $fh qq(<DD>The C functions which a Tcl extended C program may use.</DD>\n);
print $fh qq(<DT><A HREF="TkLib/contents.htm">Tk Library</A></DT>\n);
print $fh qq(<DD>The additional C functions which a Tk extended C program may use.</DD>\n);
print $fh qq(<DT><A HREF="ItclLib/contents.htm">[incr Tcl] Package Library</A></DT>\n);
print $fh qq(<DD>The additional C functions provided by the [incr Tcl] package.</DD>\n);
print $fh qq(<DT><A HREF="TdbcLib/contents.htm">TDBC Package Library</A></DT>\n);
print $fh qq(<DD>The additional C functions provided by the TDBC package.</DD>\n);
print $fh qq(<DT><A HREF="Keywords/contents.htm">Keywords</A>\n);
print $fh qq(<DD>The keywords from the Tcl/Tk man pages.\n);
print $fh qq(<!--\n);
print $fh qq(<DT><A HREF="tutorial/tcltutorial.html">Tcl Tutorial</A></DT>\n);
print $fh qq(<DD>Tutorial for Tcl features.</DD>\n);
print $fh qq(-->\n);
print $fh qq(</DL>\n);

# Print closing tags and footer
print $fh qq(\n<br clear="all" />\n);
print $fh qq(<p align="center" class="footer">\n);
print $fh qq(\t\t    <small><b>\n);
print $fh qq(\t\t    This is the main Tcl Developer Xchange site,\n);
print $fh qq(\t\t    www.tcl-lang.org .\n);
print $fh qq(\t\t    </b></small>\n);
print $fh qq(\t\t&nbsp;&nbsp;\n);
print $fh qq(<a href="/siteinfo.html">About this Site</a> |\n);
print $fh qq(<a href="/cdn-cgi/l/email-protection#7a0d1f18171b090e1f083a0e191657161b141d5415081d"><span class="__cf_email__" data-cfemail="95e2f0f7f8f4e6e1f0e7d5e1f6f9b8f9f4fbf2bbfae7f2">[email&#160;protected]</span></a>\n);
print $fh qq(<br>\n);
print $fh qq(<a href="/">Home</a> | \n);
print $fh qq(<a href="/about/">About Tcl/Tk</a> |\n);
print $fh qq(<a href="/software/tcltk/">Software</a> | \n);
print $fh qq(<a href="/community/coreteam/">Core Development</a> |\n);
print $fh qq(<a href="/community/">Community</a> |\n);
print $fh qq(<a href="/doc/">Documentation</a>\n);
print $fh qq(</p>\n);
print $fh qq(</td></tr></table>);

# Print script tag and close body/html
print $fh qq(<script data-cfasync="false" src="/cdn-cgi/scripts/5c5dd728/cloudflare-static/email-decode.min.js" defer></script>);
print $fh qq(</body>);
print $fh qq(</html>\n);

# Close file
close($fh);

print "HTML file generated successfully: $output_file\n";
