// abstraction-provenance: {"artifact_sha256": "1d06b2b7beb388cd846a66855ff7d58d8c922db610605002ba15aaab50335941", "source_sha256": "5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988", "target_language": "go"}
// index.html — portiert nach go
// Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html
// auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"fmt"
	"html"
	"os"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s <output-file>\n", os.Args[0])
		os.Exit(1)
	}

	filename := os.Args[1]
	file, err := os.Create(filename)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating file: %v\n", err)
		os.Exit(1)
	}
	defer file.Close()

	// Write DOCTYPE
	fmt.Fprint(file, "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n")
	
	// Begin HTML
	fmt.Fprint(file, "<html>\n<head>")
	fmt.Fprint(file, "\t<title>Tcl/Tk 8.6 Manual</title>\n")
	fmt.Fprint(file, "\t<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n")
	fmt.Fprint(file, "\t<link rel=\"stylesheet\" href=\"/devsite.css\" type=\"text/css\" media=\"all\">\n")
	fmt.Fprint(file, "</head>\n")
	fmt.Fprint(file, "<body bgcolor=\"white\" text=\"black\">\n\n")

	// Table with header images
	fmt.Fprint(file, "\t<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"780\">\n")
	fmt.Fprint(file, "\t\t<tr>\n")
	fmt.Fprint(file, "\t\t<td valign=\"top\" align=\"left\"><a href=\"/\"><img src=\"/images/plume.png\" width=\"60\" height=\"55\"\n")
	fmt.Fprint(file, "\tborder=\"0\" alt=\"Tcl Home\" /><img src=\"/images/Developer.gif\" width=\"355\" height=\"55\"\n")
	fmt.Fprint(file, "\tborder=\"0\" alt=\"Tcl Home\" title=\"Tcl Developer Xchange\" /></a></td>\n")
	fmt.Fprint(file, "\t\t<td valign=\"top\" align=\"right\"><a href=\"/siteinfo.html\"><font size=1>Hosted by</font></a><br><a href=\"http://www.ActiveState.com/products/tcl\"><img src=\"/images/aslogo.gif\"\n")
	fmt.Fprint(file, "\tborder=\"0\" alt=\"ActiveState\"\n")
	fmt.Fprint(file, "\ttitle=\"This site is hosted by ActiveState\" /></a></td>\n")
	fmt.Fprint(file, "\t\t</tr>\n")
	fmt.Fprint(file, "\t</table>\n")

	// Navigation bar
	fmt.Fprint(file, "    <div id=\"globalnav\"><ul>\n")
	fmt.Fprint(file, "<li><a href=\"/\">HOME</a></li>\n")
	fmt.Fprint(file, "<li><a href=\"/about/\">ABOUT TCL/TK</a></li>\n")
	fmt.Fprint(file, "<li><a href=\"/software/tcltk/\">SOFTWARE</a></li>\n")
	fmt.Fprint(file, "<li><a href=\"/community/coreteam/\">CORE DEVELOPMENT</a></li>\n")
	fmt.Fprint(file, "<li><a href=\"/community/\">COMMUNITY</a></li>\n")
	fmt.Fprint(file, "<li><a href=\"/doc/\" class=\"here\">DOCUMENTATION</a></li>\n")
	fmt.Fprint(file, "</ul></div>\n")
	fmt.Fprint(file, "<br clear=\"all\" />\n")

	// Blue divider
	fmt.Fprint(file, "<DIV style=\"border-top: 2px solid #3163CE; width: 780px\"></DIV>\n")

	// Search table
	fmt.Fprint(file, "<table border=\"0\" cellpadding=\"2\" cellspacing=\"0\" width=\"780\">\n")
	fmt.Fprint(file, "\t\t<tr><td align=\"left\" valign=\"middle\">\n")
	fmt.Fprint(file, "<!-- SiteSearch Google -->\n")
	fmt.Fprint(file, "\t<div style=\"display:table-cell; vertical-align:middle; margin:0px\">\n")
	fmt.Fprint(file, "<FORM method=\"GET\" action=\"https://www.google.com/search\">\n")
	fmt.Fprint(file, "<A HREF=\"https://www.google.com/\"><IMG src=\"/images/Search.gif\" border=\"0\"\n")
	fmt.Fprint(file, "ALT=\"Google SiteSearch\" /></A>\n")
	fmt.Fprint(file, "<INPUT TYPE=\"text\" name=\"q\" size=\"20\" maxlength=\"255\" value=\"\">\n")
	fmt.Fprint(file, "<INPUT type=\"image\" value=\"submit\" name=\"btnG\" src=\"/images/Go.gif\">\n")
	fmt.Fprint(file, "<input type=\"hidden\" name=\"ie\" value=\"UTF-8\">\n")
	fmt.Fprint(file, "<input type=\"hidden\" name=\"oe\" value=\"UTF-8\">\n")
	fmt.Fprint(file, "<input type=\"hidden\" name=\"domains\" value=\"tcl.tk\">\n")
	fmt.Fprint(file, "<input type=\"hidden\" name=\"sitesearch\" value=\"tcl.tk\">\n")
	fmt.Fprint(file, "</FORM></div>\n")
	fmt.Fprint(file, "<!-- SiteSearch Google -->\n")
	fmt.Fprint(file, "</td><td \n")
	fmt.Fprint(file, "\t\talign=\"right\"><p class=\"banner\">Tcl/Tk 8.6 Manual</p></td></tr></table>\n")

	// Yellow divider
	fmt.Fprint(file, "\t<DIV style=\"border-top: 1px solid #FFCE00; margin-bottom: 2px; width: 780px\"></DIV>")

	// Main content table
	fmt.Fprint(file, "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"780\">\n")
	fmt.Fprint(file, "<tr><td>\n")

	// Key list
	fmt.Fprint(file, "<DL class=\"keylist\">\n")
	fmt.Fprint(file, "<DT><A HREF=\"UserCmd/contents.htm\">Tcl/Tk Applications</A></DT>\n")
	fmt.Fprint(file, "<DD>The interpreters which implement Tcl and Tk.</DD>\n")
	fmt.Fprint(file, "<DT><A HREF=\"TclCmd/contents.htm\">Tcl Commands</A></DT>\n")
	fmt.Fprint(file, "<DD>The commands which the <B>tclsh</B> interpreter implements.</DD>\n")
	fmt.Fprint(file, "<DT><A HREF=\"TkCmd/contents.htm\">Tk Commands</A></DT>\n")
	fmt.Fprint(file, "<DD>The additional commands which the <B>wish</B> interpreter implements.</DD>\n")
	fmt.Fprint(file, "<DT><A HREF=\"ItclCmd/contents.htm\">[incr Tcl] Package Commands</A></DT>\n")
	fmt.Fprint(file, "<DD>The additional commands provided by the [incr Tcl] package.</DD>\n")
	fmt.Fprint(file, "<DT><A HREF=\"SqliteCmd/contents.htm\">SQLite Package Commands</A></DT>\n")
	fmt.Fprint(file, "<DD>The additional commands provided by the SQLite package.</DD>\n")
	fmt.Fprint(file, "<DT><A HREF=\"TdbcCmd/contents.htm\">TDBC Package Commands</A></DT>\n")
	fmt.Fprint(file, "<DD>The additional commands provided by the TDBC package.</DD>\n")
	fmt.Fprint(file, "<DT><A HREF=\"TdbcmysqlCmd/contents.htm\">tdbc::mysql Package Commands</A></DT>\n")
	fmt.Fprint(file, "<DD>The additional commands provided by the tdbc::mysql package.</DD>\n")
	fmt.Fprint(file, "<DT><A HREF=\"TdbcodbcCmd/contents.htm\">tdbc::odbc Package Commands</A></DT>\n")
	fmt.Fprint(file, "<DD>The additional commands provided by the tdbc::odbc package.</DD>\n")
	fmt.Fprint(file, "<DT><A HREF=\"TdbcpostgresCmd/contents.htm\">tdbc::postgres Package Commands</A></DT>\n")
	fmt.Fprint(file, "<DD>The additional commands provided by the tdbc::postgres package.</DD>\n")
	fmt.Fprint(file, "<DT><A HREF=\"TdbcsqliteCmd/contents.htm\">tdbc::sqlite3 Package Commands</A></DT>\n")
	fmt.Fprint(file, "<DD>The additional commands provided by the tdbc::sqlite3 package.</DD>\n")
	fmt.Fprint(file, "<DT><A HREF=\"ThreadCmd/contents.htm\">Thread Package Commands</A></DT>\n")
	fmt.Fprint(file, "<DD>The additional commands provided by the Thread package.</DD>\n")
	fmt.Fprint(file, "<DT><A HREF=\"TclLib/contents.htm\">Tcl Library</A></DT>\n")
	fmt.Fprint(file, "<DD>The C functions which a Tcl extended C program may use.</DD>\n")
	fmt.Fprint(file, "<DT><A HREF=\"TkLib/contents.htm\">Tk Library</A></DT>\n")
	fmt.Fprint(file, "<DD>The additional C functions which a Tk extended C program may use.</DD>\n")
	fmt.Fprint(file, "<DT><A HREF=\"ItclLib/contents.htm\">[incr Tcl] Package Library</A></DT>\n")
	fmt.Fprint(file, "<DD>The additional C functions provided by the [incr Tcl] package.</DD>\n")
	fmt.Fprint(file, "<DT><A HREF=\"TdbcLib/contents.htm\">TDBC Package Library</A></DT>\n")
	fmt.Fprint(file, "<DD>The additional C functions provided by the TDBC package.</DD>\n")
	fmt.Fprint(file, "<DT><A HREF=\"Keywords/contents.htm\">Keywords</A>\n")
	fmt.Fprint(file, "<DD>The keywords from the Tcl/Tk man pages.\n")
	fmt.Fprint(file, "<!--\n")
	fmt.Fprint(file, "<DT><A HREF=\"tutorial/tcltutorial.html\">Tcl Tutorial</A></DT>\n")
	fmt.Fprint(file, "<DD>Tutorial for Tcl features.</DD>\n")
	fmt.Fprint(file, "-->\n")
	fmt.Fprint(file, "</DL>\n\n")

	// Clear and footer
	fmt.Fprint(file, "<br clear=\"all\" />\n")
	fmt.Fprint(file, "<p align=\"center\" class=\"footer\">\n")
	fmt.Fprint(file, "\t\t\t<small><b>\n")
	fmt.Fprint(file, "\t\t\tThis is the main Tcl Developer Xchange site,\n")
	fmt.Fprint(file, "\t\t\twww.tcl-lang.org .\n")
	fmt.Fprint(file, "\t\t\t</b></small>\n")
	fmt.Fprint(file, "\t\t&nbsp;&nbsp;\n")
	fmt.Fprint(file, "<a href=\"/siteinfo.html\">About this Site</a> |\n")
	fmt.Fprint(file, "<a href=\"/cdn-cgi/l/email-protection#7a0d1f18171b090e1f083a0e191657161b141d5415081d\"><span class=\"__cf_email__\" data-cfemail=\"95e2f0f7f8f4e6e1f0e7d5e1f6f9b8f9f4fbf2bbfae7f2\">[email&#160;protected]</span></a>\n")
	fmt.Fprint(file, "<br>\n")
	fmt.Fprint(file, "<a href=\"/\">Home</a> | \n")
	fmt.Fprint(file, "<a href=\"/about/\">About Tcl/Tk</a> |\n")
	fmt.Fprint(file, "<a href=\"/software/tcltk/\">Software</a> | \n")
	fmt.Fprint(file, "<a href=\"/community/coreteam/\">Core Development</a> |\n")
	fmt.Fprint(file, "<a href=\"/community/\">Community</a> |\n")
	fmt.Fprint(file, "<a href=\"/doc/\">Documentation</a>\n")
	fmt.Fprint(file, "</p>\n")
	fmt.Fprint(file, "</td></tr></table>")

	// Script tag
	fmt.Fprint(file, "<script data-cfasync=\"false\" src=\"/cdn-cgi/scripts/5c5dd728/cloudflare-static/email-decode.min.js\" defer></script>")
	
	// Close body and html
	fmt.Fprint(file, "</body></html>\n")

	fmt.Printf("HTML file generated successfully: %s\n", filename)
}
