// abstraction-provenance: {"artifact_sha256": "7e2736d01d5f0254eeaa4baf8bb774dae6e10fd327d22540e02e76a12c6a0437", "source_sha256": "5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988", "target_language": "fsharp"}
// index.html — portiert nach fsharp
// Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html
// auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text

let generateHtml() =
    let sb = new StringBuilder()
    
    // DOCTYPE and html start
    sb.AppendLine("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">") |> ignore
    sb.AppendLine("<html>") |> ignore
    sb.AppendLine("<head>\t<title>Tcl/Tk 8.6 Manual</title>") |> ignore
    sb.AppendLine("\t<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">") |> ignore
    sb.AppendLine("\t<link rel=\"stylesheet\" href=\"/devsite.css\" type=\"text/css\" media=\"all\">") |> ignore
    sb.AppendLine("</head>") |> ignore
    sb.AppendLine("<body bgcolor=\"white\" text=\"black\">") |> ignore
    
    // Header table
    sb.AppendLine("\t<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"780\">") |> ignore
    sb.AppendLine("\t    <tr>") |> ignore
    sb.AppendLine("\t    <td valign=\"top\" align=\"left\"><a href=\"/\"><img src=\"/images/plume.png\" width=\"60\" height=\"55\"") |> ignore
    sb.AppendLine("\tborder=\"0\" alt=\"Tcl Home\" /><img src=\"/images/Developer.gif\" width=\"355\" height=\"55\"") |> ignore
    sb.AppendLine("\tborder=\"0\" alt=\"Tcl Home\" title=\"Tcl Developer Xchange\" /></a></td>") |> ignore
    sb.AppendLine("\t    <td valign=\"top\" align=\"right\"><a href=\"/siteinfo.html\"><font size=1>Hosted by</font></a><br><a href=\"http://www.ActiveState.com/products/tcl\"><img src=\"/images/aslogo.gif\"") |> ignore
    sb.AppendLine("\tborder=\"0\" alt=\"ActiveState\"") |> ignore
    sb.AppendLine("\ttitle=\"This site is hosted by ActiveState\" /></a></td>") |> ignore
    sb.AppendLine("\t    </tr>") |> ignore
    sb.AppendLine("\t</table>") |> ignore
    
    // Navigation
    sb.AppendLine("    <div id=\"globalnav\"><ul>") |> ignore
    sb.AppendLine("<li><a href=\"/\">HOME</a></li>") |> ignore
    sb.AppendLine("<li><a href=\"/about/\">ABOUT TCL/TK</a></li>") |> ignore
    sb.AppendLine("<li><a href=\"/software/tcltk/\">SOFTWARE</a></li>") |> ignore
    sb.AppendLine("<li><a href=\"/community/coreteam/\">CORE DEVELOPMENT</a></li>") |> ignore
    sb.AppendLine("<li><a href=\"/community/\">COMMUNITY</a></li>") |> ignore
    sb.AppendLine("<li><a href=\"/doc/\" class=\"here\">DOCUMENTATION</a></li>") |> ignore
    sb.AppendLine("</ul></div>") |> ignore
    sb.AppendLine("<br clear=\"all\" />") |> ignore
    
    // Blue divider
    sb.AppendLine("<DIV style=\"border-top: 2px solid #3163CE; width: 780px\"></DIV>") |> ignore
    
    // Search table
    sb.AppendLine("<table border=\"0\" cellpadding=\"2\" cellspacing=\"0\" width=\"780\">") |> ignore
    sb.AppendLine("\t    <tr><td align=\"left\" valign=\"middle\">") |> ignore
    sb.AppendLine("<!-- SiteSearch Google -->") |> ignore
    sb.AppendLine("\t<div style=\"display:table-cell; vertical-align:middle; margin:0px\">") |> ignore
    sb.AppendLine("<FORM method=\"GET\" action=\"https://www.google.com/search\">") |> ignore
    sb.AppendLine("<A HREF=\"https://www.google.com/\"><IMG src=\"/images/Search.gif\" border=\"0\"") |> ignore
    sb.AppendLine("ALT=\"Google SiteSearch\" /></A>") |> ignore
    sb.AppendLine("<INPUT TYPE=\"text\" name=\"q\" size=\"20\" maxlength=\"255\" value=\"\">") |> ignore
    sb.AppendLine("<INPUT type=\"image\" value=\"submit\" name=\"btnG\" src=\"/images/Go.gif\">") |> ignore
    sb.AppendLine("<input type=\"hidden\" name=\"ie\" value=\"UTF-8\">") |> ignore
    sb.AppendLine("<input type=\"hidden\" name=\"oe\" value=\"UTF-8\">") |> ignore
    sb.AppendLine("<input type=\"hidden\" name=\"domains\" value=\"tcl.tk\">") |> ignore
    sb.AppendLine("<input type=\"hidden\" name=\"sitesearch\" value=\"tcl.tk\">") |> ignore
    sb.AppendLine("</FORM></div>") |> ignore
    sb.AppendLine("<!-- SiteSearch Google -->") |> ignore
    sb.AppendLine("</td><td ") |> ignore
    sb.AppendLine("\t    align=\"right\"><p class=\"banner\">Tcl/Tk 8.6 Manual</p></td></tr></table>") |> ignore
    
    // Yellow divider
    sb.AppendLine("\t<DIV style=\"border-top: 1px solid #FFCE00; margin-bottom: 2px; width: 780px\"></DIV>") |> ignore
    
    // Main content table
    sb.AppendLine("<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"780\">") |> ignore
    sb.AppendLine("<tr><td>") |> ignore
    sb.AppendLine("<DL class=\"keylist\">") |> ignore
    
    // Content links
    sb.AppendLine("<DT><A HREF=\"UserCmd/contents.htm\">Tcl/Tk Applications</A></DT>") |> ignore
    sb.AppendLine("<DD>The interpreters which implement Tcl and Tk.</DD>") |> ignore
    sb.AppendLine("<DT><A HREF=\"TclCmd/contents.htm\">Tcl Commands</A></DT>") |> ignore
    sb.AppendLine("<DD>The commands which the <B>tclsh</B> interpreter implements.</DD>") |> ignore
    sb.AppendLine("<DT><A HREF=\"TkCmd/contents.htm\">Tk Commands</A></DT>") |> ignore
    sb.AppendLine("<DD>The additional commands which the <B>wish</B> interpreter implements.</DD>") |> ignore
    sb.AppendLine("<DT><A HREF=\"ItclCmd/contents.htm\">[incr Tcl] Package Commands</A></DT>") |> ignore
    sb.AppendLine("<DD>The additional commands provided by the [incr Tcl] package.</DD>") |> ignore
    sb.AppendLine("<DT><A HREF=\"SqliteCmd/contents.htm\">SQLite Package Commands</A></DT>") |> ignore
    sb.AppendLine("<DD>The additional commands provided by the SQLite package.</DD>") |> ignore
    sb.AppendLine("<DT><A HREF=\"TdbcCmd/contents.htm\">TDBC Package Commands</A></DT>") |> ignore
    sb.AppendLine("<DD>The additional commands provided by the TDBC package.</DD>") |> ignore
    sb.AppendLine("<DT><A HREF=\"TdbcmysqlCmd/contents.htm\">tdbc::mysql Package Commands</A></DT>") |> ignore
    sb.AppendLine("<DD>The additional commands provided by the tdbc::mysql package.</DD>") |> ignore
    sb.AppendLine("<DT><A HREF=\"TdbcodbcCmd/contents.htm\">tdbc::odbc Package Commands</A></DT>") |> ignore
    sb.AppendLine("<DD>The additional commands provided by the tdbc::odbc package.</DD>") |> ignore
    sb.AppendLine("<DT><A HREF=\"TdbcpostgresCmd/contents.htm\">tdbc::postgres Package Commands</A></DT>") |> ignore
    sb.AppendLine("<DD>The additional commands provided by the tdbc::postgres package.</DD>") |> ignore
    sb.AppendLine("<DT><A HREF=\"TdbcsqliteCmd/contents.htm\">tdbc::sqlite3 Package Commands</A></DT>") |> ignore
    sb.AppendLine("<DD>The additional commands provided by the tdbc::sqlite3 package.</DD>") |> ignore
    sb.AppendLine("<DT><A HREF=\"ThreadCmd/contents.htm\">Thread Package Commands</A></DT>") |> ignore
    sb.AppendLine("<DD>The additional commands provided by the Thread package.</DD>") |> ignore
    sb.AppendLine("<DT><A HREF=\"TclLib/contents.htm\">Tcl Library</A></DT>") |> ignore
    sb.AppendLine("<DD>The C functions which a Tcl extended C program may use.</DD>") |> ignore
    sb.AppendLine("<DT><A HREF=\"TkLib/contents.htm\">Tk Library</A></DT>") |> ignore
    sb.AppendLine("<DD>The additional C functions which a Tk extended C program may use.</DD>") |> ignore
    sb.AppendLine("<DT><A HREF=\"ItclLib/contents.htm\">[incr Tcl] Package Library</A></DT>") |> ignore
    sb.AppendLine("<DD>The additional C functions provided by the [incr Tcl] package.</DD>") |> ignore
    sb.AppendLine("<DT><A HREF=\"TdbcLib/contents.htm\">TDBC Package Library</A></DT>") |> ignore
    sb.AppendLine("<DD>The additional C functions provided by the TDBC package.</DD>") |> ignore
    sb.AppendLine("<DT><A HREF=\"Keywords/contents.htm\">Keywords</A>") |> ignore
    sb.AppendLine("<DD>The keywords from the Tcl/Tk man pages.") |> ignore
    sb.AppendLine("<!--") |> ignore
    sb.AppendLine("<DT><A HREF=\"tutorial/tcltutorial.html\">Tcl Tutorial</A></DT>") |> ignore
    sb.AppendLine("<DD>Tutorial for Tcl features.</DD>") |> ignore
    sb.AppendLine("-->") |> ignore
    sb.AppendLine("</DL>") |> ignore
    
    // Footer
    sb.AppendLine("<br clear=\"all\" />") |> ignore
    sb.AppendLine("<p align=\"center\" class=\"footer\">") |> ignore
    sb.AppendLine("\t\t    <small><b>") |> ignore
    sb.AppendLine("\t\t    This is the main Tcl Developer Xchange site,") |> ignore
    sb.AppendLine("\t\t    www.tcl-lang.org .") |> ignore
    sb.AppendLine("\t\t    </b></small>") |> ignore
    sb.AppendLine("\t\t&nbsp;&nbsp;") |> ignore
    sb.AppendLine("<a href=\"/siteinfo.html\">About this Site</a> |") |> ignore
    sb.AppendLine("<a href=\"/cdn-cgi/l/email-protection#7a0d1f18171b090e1f083a0e191657161b141d5415081d\"><span class=\"__cf_email__\" data-cfemail=\"95e2f0f7f8f4e6e1f0e7d5e1f6f9b8f9f4fbf2bbfae7f2\">[email&#160;protected]</span></a>") |> ignore
    sb.AppendLine("<br>") |> ignore
    sb.AppendLine("<a href=\"/\">Home</a> | ") |> ignore
    sb.AppendLine("<a href=\"/about/\">About Tcl/Tk</a> |") |> ignore
    sb.AppendLine("<a href=\"/software/tcltk/\">Software</a> | ") |> ignore
    sb.AppendLine("<a href=\"/community/coreteam/\">Core Development</a> |") |> ignore
    sb.AppendLine("<a href=\"/community/\">Community</a> |") |> ignore
    sb.AppendLine("<a href=\"/doc/\">Documentation</a>") |> ignore
    sb.AppendLine("</p>") |> ignore
    sb.AppendLine("</td></tr></table>") |> ignore
    
    // Scripts
    sb.AppendLine("<script data-cfasync=\"false\" src=\"/cdn-cgi/scripts/5c5dd728/cloudflare-static/email-decode.min.js\" defer></script>") |> ignore
    sb.AppendLine("</body></html>") |> ignore
    
    sb.ToString()

[<EntryPoint>]
let main argv =
    try
        let outputPath = 
            if argv.Length > 0 then argv.[0] 
            else "index.html"
        
        let htmlContent = generateHtml()
        File.WriteAllText(outputPath, htmlContent, Text.Encoding.UTF8)
        printfn "HTML file generated successfully: %s" outputPath
        0
    with
    | ex ->
        eprintfn "Error generating HTML file: %s" ex.Message
        1
