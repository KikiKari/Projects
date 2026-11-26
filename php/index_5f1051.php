<?php
// abstraction-provenance: {"artifact_sha256": "022eb911a4ccafbacd14a00d969e662965068acf39f981ac0d19ff3ad1fa7261", "source_sha256": "5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988", "target_language": "php"}
// index.html — portiert nach php
// Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html
// auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
function generateIndexHTML($filename) {
    $html = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">' . "\n";
    $html .= '<html>' . "\n";
    $html .= '<head>' . "\n";
    $html .= "\t" . '<title>Tcl/Tk 8.6 Manual</title>' . "\n";
    $html .= "\t" . '<meta name="viewport" content="width=device-width, initial-scale=1">' . "\n";
    $html .= "\t" . '<link rel="stylesheet" href="/devsite.css" type="text/css" media="all">' . "\n";
    $html .= '</head>' . "\n";
    $html .= '<body bgcolor="white" text="black">' . "\n\n";
    $html .= "\t" . '<table border="0" cellpadding="0" cellspacing="0" width="780">' . "\n";
    $html .= "\t" . '    <tr>' . "\n";
    $html .= "\t" . '    <td valign="top" align="left"><a href="/"><img src="/images/plume.png" width="60" height="55"' . "\n";
    $html .= "\t" . '	border="0" alt="Tcl Home" /><img src="/images/Developer.gif" width="355" height="55"' . "\n";
    $html .= "\t" . '	border="0" alt="Tcl Home" title="Tcl Developer Xchange" /></a></td>' . "\n";
    $html .= "\t" . '    <td valign="top" align="right"><a href="/siteinfo.html"><font size=1>Hosted by</font></a><br><a href="http://www.ActiveState.com/products/tcl"><img src="/images/aslogo.gif"' . "\n";
    $html .= "\t" . '	border="0" alt="ActiveState"' . "\n";
    $html .= "\t" . '	title="This site is hosted by ActiveState" /></a></td>' . "\n";
    $html .= "\t" . '    </tr>' . "\n";
    $html .= "\t" . '</table>' . "\n";
    $html .= '    <div id="globalnav"><ul>' . "\n";
    $html .= '<li><a href="/">HOME</a></li>' . "\n";
    $html .= '<li><a href="/about/">ABOUT TCL/TK</a></li>' . "\n";
    $html .= '<li><a href="/software/tcltk/">SOFTWARE</a></li>' . "\n";
    $html .= '<li><a href="/community/coreteam/">CORE DEVELOPMENT</a></li>' . "\n";
    $html .= '<li><a href="/community/">COMMUNITY</a></li>' . "\n";
    $html .= '<li><a href="/doc/" class="here">DOCUMENTATION</a></li>' . "\n";
    $html .= '</ul></div>' . "\n";
    $html .= '<br clear="all" />' . "\n";
    $html .= '<DIV style="border-top: 2px solid #3163CE; width: 780px"></DIV>' . "\n";
    $html .= '<table border="0" cellpadding="2" cellspacing="0" width="780">' . "\n";
    $html .= "\t" . '    <tr><td align="left" valign="middle">' . "\n";
    $html .= '<!-- SiteSearch Google -->' . "\n";
    $html .= "\t" . '<div style="display:table-cell; vertical-align:middle; margin:0px">' . "\n";
    $html .= '<FORM method="GET" action="https://www.google.com/search">' . "\n";
    $html .= '<A HREF="https://www.google.com/"><IMG src="/images/Search.gif" border="0"' . "\n";
    $html .= 'ALT="Google SiteSearch" /></A>' . "\n";
    $html .= '<INPUT TYPE="text" name="q" size="20" maxlength="255" value="">' . "\n";
    $html .= '<INPUT type="image" value="submit" name="btnG" src="/images/Go.gif">' . "\n";
    $html .= '<input type="hidden" name="ie" value="UTF-8">' . "\n";
    $html .= '<input type="hidden" name="oe" value="UTF-8">' . "\n";
    $html .= '<input type="hidden" name="domains" value="tcl.tk">' . "\n";
    $html .= '<input type="hidden" name="sitesearch" value="tcl.tk">' . "\n";
    $html .= '</FORM></div>' . "\n";
    $html .= '<!-- SiteSearch Google -->' . "\n";
    $html .= '</td><td ' . "\n";
    $html .= "\t" . '    align="right"><p class="banner">Tcl/Tk 8.6 Manual</p></td></tr></table>' . "\n";
    $html .= "\t" . '<DIV style="border-top: 1px solid #FFCE00; margin-bottom: 2px; width: 780px"></DIV>';
    $html .= '<table border="0" cellpadding="0" cellspacing="0" width="780">' . "\n";
    $html .= '<tr><td>' . "\n";
    $html .= '<DL class="keylist">' . "\n";
    $html .= '<DT><A HREF="UserCmd/contents.htm">Tcl/Tk Applications</A></DT>' . "\n";
    $html .= '<DD>The interpreters which implement Tcl and Tk.</DD>' . "\n";
    $html .= '<DT><A HREF="TclCmd/contents.htm">Tcl Commands</A></DT>' . "\n";
    $html .= '<DD>The commands which the <B>tclsh</B> interpreter implements.</DD>' . "\n";
    $html .= '<DT><A HREF="TkCmd/contents.htm">Tk Commands</A></DT>' . "\n";
    $html .= '<DD>The additional commands which the <B>wish</B> interpreter implements.</DD>' . "\n";
    $html .= '<DT><A HREF="ItclCmd/contents.htm">[incr Tcl] Package Commands</A></DT>' . "\n";
    $html .= '<DD>The additional commands provided by the [incr Tcl] package.</DD>' . "\n";
    $html .= '<DT><A HREF="SqliteCmd/contents.htm">SQLite Package Commands</A></DT>' . "\n";
    $html .= '<DD>The additional commands provided by the SQLite package.</DD>' . "\n";
    $html .= '<DT><A HREF="TdbcCmd/contents.htm">TDBC Package Commands</A></DT>' . "\n";
    $html .= '<DD>The additional commands provided by the TDBC package.</DD>' . "\n";
    $html .= '<DT><A HREF="TdbcmysqlCmd/contents.htm">tdbc::mysql Package Commands</A></DT>' . "\n";
    $html .= '<DD>The additional commands provided by the tdbc::mysql package.</DD>' . "\n";
    $html .= '<DT><A HREF="TdbcodbcCmd/contents.htm">tdbc::odbc Package Commands</A></DT>' . "\n";
    $html .= '<DD>The additional commands provided by the tdbc::odbc package.</DD>' . "\n";
    $html .= '<DT><A HREF="TdbcpostgresCmd/contents.htm">tdbc::postgres Package Commands</A></DT>' . "\n";
    $html .= '<DD>The additional commands provided by the tdbc::postgres package.</DD>' . "\n";
    $html .= '<DT><A HREF="TdbcsqliteCmd/contents.htm">tdbc::sqlite3 Package Commands</A></DT>' . "\n";
    $html .= '<DD>The additional commands provided by the tdbc::sqlite3 package.</DD>' . "\n";
    $html .= '<DT><A HREF="ThreadCmd/contents.htm">Thread Package Commands</A></DT>' . "\n";
    $html .= '<DD>The additional commands provided by the Thread package.</DD>' . "\n";
    $html .= '<DT><A HREF="TclLib/contents.htm">Tcl Library</A></DT>' . "\n";
    $html .= '<DD>The C functions which a Tcl extended C program may use.</DD>' . "\n";
    $html .= '<DT><A HREF="TkLib/contents.htm">Tk Library</A></DT>' . "\n";
    $html .= '<DD>The additional C functions which a Tk extended C program may use.</DD>' . "\n";
    $html .= '<DT><A HREF="ItclLib/contents.htm">[incr Tcl] Package Library</A></DT>' . "\n";
    $html .= '<DD>The additional C functions provided by the [incr Tcl] package.</DD>' . "\n";
    $html .= '<DT><A HREF="TdbcLib/contents.htm">TDBC Package Library</A></DT>' . "\n";
    $html .= '<DD>The additional C functions provided by the TDBC package.</DD>' . "\n";
    $html .= '<DT><A HREF="Keywords/contents.htm">Keywords</A>' . "\n";
    $html .= '<DD>The keywords from the Tcl/Tk man pages.' . "\n";
    $html .= '<!--' . "\n";
    $html .= '<DT><A HREF="tutorial/tcltutorial.html">Tcl Tutorial</A></DT>' . "\n";
    $html .= '<DD>Tutorial for Tcl features.</DD>' . "\n";
    $html .= '-->' . "\n";
    $html .= '</DL>' . "\n\n";
    $html .= '<br clear="all" />' . "\n";
    $html .= '<p align="center" class="footer">' . "\n";
    $html .= "\t" . '    <small><b>' . "\n";
    $html .= "\t" . '    This is the main Tcl Developer Xchange site,' . "\n";
    $html .= "\t" . '    www.tcl-lang.org .' . "\n";
    $html .= "\t" . '    </b></small>' . "\n";
    $html .= "\t" . '&nbsp;&nbsp;' . "\n";
    $html .= '<a href="/siteinfo.html">About this Site</a> |' . "\n";
    $html .= '<a href="/cdn-cgi/l/email-protection#7a0d1f18171b090e1f083a0e191657161b141d5415081d"><span class="__cf_email__" data-cfemail="95e2f0f7f8f4e6e1f0e7d5e1f6f9b8f9f4fbf2bbfae7f2">[email&#160;protected]</span></a>' . "\n";
    $html .= '<br>' . "\n";
    $html .= '<a href="/">Home</a> | ' . "\n";
    $html .= '<a href="/about/">About Tcl/Tk</a> |' . "\n";
    $html .= '<a href="/software/tcltk/">Software</a> | ' . "\n";
    $html .= '<a href="/community/coreteam/">Core Development</a> |' . "\n";
    $html .= '<a href="/community/">Community</a> |' . "\n";
    $html .= '<a href="/doc/">Documentation</a>' . "\n";
    $html .= '</p>' . "\n";
    $html .= '</td></tr></table>';
    $html .= '<script data-cfasync="false" src="/cdn-cgi/scripts/5c5dd728/cloudflare-static/email-decode.min.js" defer></script>';
    $html .= '</body></html>';

    file_put_contents($filename, $html);
    return true;
}

// Wenn das Skript direkt aufgerufen wird, generiere die Datei
if (basename(__FILE__) == basename($_SERVER['SCRIPT_NAME'])) {
    if (isset($argv[1])) {
        generateIndexHTML($argv[1]);
        echo "HTML file generated: " . $argv[1] . "\n";
    } else {
        echo "Usage: php " . $argv[0] . " <output_filename>\n";
    }
}
?>
