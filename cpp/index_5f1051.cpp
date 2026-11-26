// abstraction-provenance: {"artifact_sha256": "518a406f674c88f9c7d2f46955c762a5920879e60a70ef6f614b279fcc43b381", "source_sha256": "5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988", "target_language": "cpp"}
// index.html — portiert nach cpp
// Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html
// auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

void generateHTML(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file " << filename << " for writing." << std::endl;
        return;
    }

    // DOCTYPE declaration
    file << "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n";
    
    // HTML start
    file << "<html>\n";
    file << "<head>\t<title>Tcl/Tk 8.6 Manual</title>\n";
    file << "\t<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n";
    file << "\t<link rel=\"stylesheet\" href=\"/devsite.css\" type=\"text/css\" media=\"all\">\n";
    file << "</head>\n";
    file << "<body bgcolor=\"white\" text=\"black\">\n\n";
    
    // Header table
    file << "\t<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"780\">\n";
    file << "\t    <tr>\n";
    file << "\t    <td valign=\"top\" align=\"left\"><a href=\"/\"><img src=\"/images/plume.png\" width=\"60\" height=\"55\"\n";
    file << "\tborder=\"0\" alt=\"Tcl Home\" /><img src=\"/images/Developer.gif\" width=\"355\" height=\"55\"\n";
    file << "\tborder=\"0\" alt=\"Tcl Home\" title=\"Tcl Developer Xchange\" /></a></td>\n";
    file << "\t    <td valign=\"top\" align=\"right\"><a href=\"/siteinfo.html\"><font size=1>Hosted by</font></a><br><a href=\"http://www.ActiveState.com/products/tcl\"><img src=\"/images/aslogo.gif\"\n";
    file << "\tborder=\"0\" alt=\"ActiveState\"\n";
    file << "\ttitle=\"This site is hosted by ActiveState\" /></a></td>\n";
    file << "\t    </tr>\n";
    file << "\t</table>\n";
    
    // Navigation menu
    file << "    <div id=\"globalnav\"><ul>\n";
    file << "<li><a href=\"/\">HOME</a></li>\n";
    file << "<li><a href=\"/about/\">ABOUT TCL/TK</a></li>\n";
    file << "<li><a href=\"/software/tcltk/\">SOFTWARE</a></li>\n";
    file << "<li><a href=\"/community/coreteam/\">CORE DEVELOPMENT</a></li>\n";
    file << "<li><a href=\"/community/\">COMMUNITY</a></li>\n";
    file << "<li><a href=\"/doc/\" class=\"here\">DOCUMENTATION</a></li>\n";
    file << "</ul></div>\n";
    file << "<br clear=\"all\" />\n";
    
    // Blue divider
    file << "<DIV style=\"border-top: 2px solid #3163CE; width: 780px\"></DIV>\n";
    
    // Search form table
    file << "<table border=\"0\" cellpadding=\"2\" cellspacing=\"0\" width=\"780\">\n";
    file << "\t\t    <tr><td align=\"left\" valign=\"middle\">\n";
    file << "<!-- SiteSearch Google -->\n";
    file << "\t<div style=\"display:table-cell; vertical-align:middle; margin:0px\">\n";
    file << "<FORM method=\"GET\" action=\"https://www.google.com/search\">\n";
    file << "<A HREF=\"https://www.google.com/\"><IMG src=\"/images/Search.gif\" border=\"0\"\n";
    file << "ALT=\"Google SiteSearch\" /></A>\n";
    file << "<INPUT TYPE=\"text\" name=\"q\" size=\"20\" maxlength=\"255\" value=\"\">\n";
    file << "<INPUT type=\"image\" value=\"submit\" name=\"btnG\" src=\"/images/Go.gif\">\n";
    file << "<input type=\"hidden\" name=\"ie\" value=\"UTF-8\">\n";
    file << "<input type=\"hidden\" name=\"oe\" value=\"UTF-8\">\n";
    file << "<input type=\"hidden\" name=\"domains\" value=\"tcl.tk\">\n";
    file << "<input type=\"hidden\" name=\"sitesearch\" value=\"tcl.tk\">\n";
    file << "</FORM></div>\n";
    file << "<!-- SiteSearch Google -->\n";
    file << "</td><td \n";
    file << "\t    align=\"right\"><p class=\"banner\">Tcl/Tk 8.6 Manual</p></td></tr></table>\n";
    
    // Yellow divider
    file << "\t<DIV style=\"border-top: 1px solid #FFCE00; margin-bottom: 2px; width: 780px\"></DIV>";
    
    // Content table
    file << "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"780\">\n";
    file << "<tr><td>\n";
    file << "<DL class=\"keylist\">\n";
    
    // Content links
    file << "<DT><A HREF=\"UserCmd/contents.htm\">Tcl/Tk Applications</A></DT>\n";
    file << "<DD>The interpreters which implement Tcl and Tk.</DD>\n";
    file << "<DT><A HREF=\"TclCmd/contents.htm\">Tcl Commands</A></DT>\n";
    file << "<DD>The commands which the <B>tclsh</B> interpreter implements.</DD>\n";
    file << "<DT><A HREF=\"TkCmd/contents.htm\">Tk Commands</A></DT>\n";
    file << "<DD>The additional commands which the <B>wish</B> interpreter implements.</DD>\n";
    file << "<DT><A HREF=\"ItclCmd/contents.htm\">[incr Tcl] Package Commands</A></DT>\n";
    file << "<DD>The additional commands provided by the [incr Tcl] package.</DD>\n";
    file << "<DT><A HREF=\"SqliteCmd/contents.htm\">SQLite Package Commands</A></DT>\n";
    file << "<DD>The additional commands provided by the SQLite package.</DD>\n";
    file << "<DT><A HREF=\"TdbcCmd/contents.htm\">TDBC Package Commands</A></DT>\n";
    file << "<DD>The additional commands provided by the TDBC package.</DD>\n";
    file << "<DT><A HREF=\"TdbcmysqlCmd/contents.htm\">tdbc::mysql Package Commands</A></DT>\n";
    file << "<DD>The additional commands provided by the tdbc::mysql package.</DD>\n";
    file << "<DT><A HREF=\"TdbcodbcCmd/contents.htm\">tdbc::odbc Package Commands</A></DT>\n";
    file << "<DD>The additional commands provided by the tdbc::odbc package.</DD>\n";
    file << "<DT><A HREF=\"TdbcpostgresCmd/contents.htm\">tdbc::postgres Package Commands</A></DT>\n";
    file << "<DD>The additional commands provided by the tdbc::postgres package.</DD>\n";
    file << "<DT><A HREF=\"TdbcsqliteCmd/contents.htm\">tdbc::sqlite3 Package Commands</A></DT>\n";
    file << "<DD>The additional commands provided by the tdbc::sqlite3 package.</DD>\n";
    file << "<DT><A HREF=\"ThreadCmd/contents.htm\">Thread Package Commands</A></DT>\n";
    file << "<DD>The additional commands provided by the Thread package.</DD>\n";
    file << "<DT><A HREF=\"TclLib/contents.htm\">Tcl Library</A></DT>\n";
    file << "<DD>The C functions which a Tcl extended C program may use.</DD>\n";
    file << "<DT><A HREF=\"TkLib/contents.htm\">Tk Library</A></DT>\n";
    file << "<DD>The additional C functions which a Tk extended C program may use.</DD>\n";
    file << "<DT><A HREF=\"ItclLib/contents.htm\">[incr Tcl] Package Library</A></DT>\n";
    file << "<DD>The additional C functions provided by the [incr Tcl] package.</DD>\n";
    file << "<DT><A HREF=\"TdbcLib/contents.htm\">TDBC Package Library</A></DT>\n";
    file << "<DD>The additional C functions provided by the TDBC package.</DD>\n";
    file << "<DT><A HREF=\"Keywords/contents.htm\">Keywords</A>\n";
    file << "<DD>The keywords from the Tcl/Tk man pages.\n";
    file << "<!--\n";
    file << "<DT><A HREF=\"tutorial/tcltutorial.html\">Tcl Tutorial</A></DT>\n";
    file << "<DD>Tutorial for Tcl features.</DD>\n";
    file << "-->\n";
    file << "</DL>\n\n";
    
    // Footer
    file << "<br clear=\"all\" />\n";
    file << "<p align=\"center\" class=\"footer\">\n";
    file << "\t\t    <small><b>\n";
    file << "\t\t    This is the main Tcl Developer Xchange site,\n";
    file << "\t\t    www.tcl-lang.org .\n";
    file << "\t\t    </b></small>\n";
    file << "\t\t&nbsp;&nbsp;\n";
    file << "<a href=\"/siteinfo.html\">About this Site</a> |\n";
    file << "<a href=\"/cdn-cgi/l/email-protection#7a0d1f18171b090e1f083a0e191657161b141d5415081d\"><span class=\"__cf_email__\" data-cfemail=\"95e2f0f7f8f4e6e1f0e7d5e1f6f9b8f9f4fbf2bbfae7f2\">[email&#160;protected]</span></a>\n";
    file << "<br>\n";
    file << "<a href=\"/\">Home</a> | \n";
    file << "<a href=\"/about/\">About Tcl/Tk</a> |\n";
    file << "<a href=\"/software/tcltk/\">Software</a> | \n";
    file << "<a href=\"/community/coreteam/\">Core Development</a> |\n";
    file << "<a href=\"/community/\">Community</a> |\n";
    file << "<a href=\"/doc/\">Documentation</a>\n";
    file << "</p>\n";
    file << "</td></tr></table>";
    
    // Script tags
    file << "<script data-cfasync=\"false\" src=\"/cdn-cgi/scripts/5c5dd728/cloudflare-static/email-decode.min.js\" defer></script>";
    
    // Close body and html
    file << "</body></html>\n";
    
    file.close();
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <output_filename>" << std::endl;
        return 1;
    }
    
    generateHTML(argv[1]);
    return 0;
}
