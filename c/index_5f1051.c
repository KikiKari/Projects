// abstraction-provenance: {"artifact_sha256": "0c34bb4e186c6d16bbfc0b36d6261c0490a43d0e466247f969ae67f25e1d3053", "source_sha256": "5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988", "target_language": "c"}
// index.html — portiert nach c
// Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html
// auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_html_header(FILE *file) {
    fprintf(file, "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">\n");
    fprintf(file, "<html>\n<head>\t<title>Tcl/Tk 8.6 Manual</title>\n");
    fprintf(file, "\t<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n");
    fprintf(file, "\t<link rel=\"stylesheet\" href=\"/devsite.css\" type=\"text/css\" media=\"all\">\n");
    fprintf(file, "</head>\n<body bgcolor=\"white\" text=\"black\">\n\n");
}

void write_top_table(FILE *file) {
    fprintf(file, "\t<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"780\">\n");
    fprintf(file, "\t    <tr>\n");
    fprintf(file, "\t    <td valign=\"top\" align=\"left\"><a href=\"/\"><img src=\"/images/plume.png\" width=\"60\" height=\"55\"\n");
    fprintf(file, "\tborder=\"0\" alt=\"Tcl Home\" /><img src=\"/images/Developer.gif\" width=\"355\" height=\"55\"\n");
    fprintf(file, "\tborder=\"0\" alt=\"Tcl Home\" title=\"Tcl Developer Xchange\" /></a></td>\n");
    fprintf(file, "\t    <td valign=\"top\" align=\"right\"><a href=\"/siteinfo.html\"><font size=1>Hosted by</font></a><br><a href=\"http://www.ActiveState.com/products/tcl\"><img src=\"/images/aslogo.gif\"\n");
    fprintf(file, "\tborder=\"0\" alt=\"ActiveState\"\n");
    fprintf(file, "\ttitle=\"This site is hosted by ActiveState\" /></a></td>\n");
    fprintf(file, "\t    </tr>\n\t</table>\n");
}

void write_navigation_bar(FILE *file) {
    fprintf(file, "    <div id=\"globalnav\"><ul>\n");
    fprintf(file, "<li><a href=\"/\">HOME</a></li>\n");
    fprintf(file, "<li><a href=\"/about/\">ABOUT TCL/TK</a></li>\n");
    fprintf(file, "<li><a href=\"/software/tcltk/\">SOFTWARE</a></li>\n");
    fprintf(file, "<li><a href=\"/community/coreteam/\">CORE DEVELOPMENT</a></li>\n");
    fprintf(file, "<li><a href=\"/community/\">COMMUNITY</a></li>\n");
    fprintf(file, "<li><a href=\"/doc/\" class=\"here\">DOCUMENTATION</a></li>\n");
    fprintf(file, "</ul></div>\n<br clear=\"all\" />\n");
    fprintf(file, "<DIV style=\"border-top: 2px solid #3163CE; width: 780px\"></DIV>\n");
}

void write_search_section(FILE *file) {
    fprintf(file, "<table border=\"0\" cellpadding=\"2\" cellspacing=\"0\" width=\"780\">\n");
    fprintf(file, "\t    <tr><td align=\"left\" valign=\"middle\">\n");
    fprintf(file, "<!-- SiteSearch Google -->\n");
    fprintf(file, "\t<div style=\"display:table-cell; vertical-align:middle; margin:0px\">\n");
    fprintf(file, "<FORM method=\"GET\" action=\"https://www.google.com/search\">\n");
    fprintf(file, "<A HREF=\"https://www.google.com/\"><IMG src=\"/images/Search.gif\" border=\"0\"\n");
    fprintf(file, "ALT=\"Google SiteSearch\" /></A>\n");
    fprintf(file, "<INPUT TYPE=\"text\" name=\"q\" size=\"20\" maxlength=\"255\" value=\"\">\n");
    fprintf(file, "<INPUT type=\"image\" value=\"submit\" name=\"btnG\" src=\"/images/Go.gif\">\n");
    fprintf(file, "<input type=\"hidden\" name=\"ie\" value=\"UTF-8\">\n");
    fprintf(file, "<input type=\"hidden\" name=\"oe\" value=\"UTF-8\">\n");
    fprintf(file, "<input type=\"hidden\" name=\"domains\" value=\"tcl.tk\">\n");
    fprintf(file, "<input type=\"hidden\" name=\"sitesearch\" value=\"tcl.tk\">\n");
    fprintf(file, "</FORM></div>\n");
    fprintf(file, "<!-- SiteSearch Google -->\n");
    fprintf(file, "</td><td \n");
    fprintf(file, "\t    align=\"right\"><p class=\"banner\">Tcl/Tk 8.6 Manual</p></td></tr></table>\n");
    fprintf(file, "\t<DIV style=\"border-top: 1px solid #FFCE00; margin-bottom: 2px; width: 780px\"></DIV>");
}

void write_content_links(FILE *file) {
    fprintf(file, "<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"780\">\n");
    fprintf(file, "<tr><td>\n");
    fprintf(file, "<DL class=\"keylist\">\n");
    
    fprintf(file, "<DT><A HREF=\"UserCmd/contents.htm\">Tcl/Tk Applications</A></DT>\n");
    fprintf(file, "<DD>The interpreters which implement Tcl and Tk.</DD>\n");
    
    fprintf(file, "<DT><A HREF=\"TclCmd/contents.htm\">Tcl Commands</A></DT>\n");
    fprintf(file, "<DD>The commands which the <B>tclsh</B> interpreter implements.</DD>\n");
    
    fprintf(file, "<DT><A HREF=\"TkCmd/contents.htm\">Tk Commands</A></DT>\n");
    fprintf(file, "<DD>The additional commands which the <B>wish</B> interpreter implements.</DD>\n");
    
    fprintf(file, "<DT><A HREF=\"ItclCmd/contents.htm\">[incr Tcl] Package Commands</A></DT>\n");
    fprintf(file, "<DD>The additional commands provided by the [incr Tcl] package.</DD>\n");
    
    fprintf(file, "<DT><A HREF=\"SqliteCmd/contents.htm\">SQLite Package Commands</A></DT>\n");
    fprintf(file, "<DD>The additional commands provided by the SQLite package.</DD>\n");
    
    fprintf(file, "<DT><A HREF=\"TdbcCmd/contents.htm\">TDBC Package Commands</A></DT>\n");
    fprintf(file, "<DD>The additional commands provided by the TDBC package.</DD>\n");
    
    fprintf(file, "<DT><A HREF=\"TdbcmysqlCmd/contents.htm\">tdbc::mysql Package Commands</A></DT>\n");
    fprintf(file, "<DD>The additional commands provided by the tdbc::mysql package.</DD>\n");
    
    fprintf(file, "<DT><A HREF=\"TdbcodbcCmd/contents.htm\">tdbc::odbc Package Commands</A></DT>\n");
    fprintf(file, "<DD>The additional commands provided by the tdbc::odbc package.</DD>\n");
    
    fprintf(file, "<DT><A HREF=\"TdbcpostgresCmd/contents.htm\">tdbc::postgres Package Commands</A></DT>\n");
    fprintf(file, "<DD>The additional commands provided by the tdbc::postgres package.</DD>\n");
    
    fprintf(file, "<DT><A HREF=\"TdbcsqliteCmd/contents.htm\">tdbc::sqlite3 Package Commands</A></DT>\n");
    fprintf(file, "<DD>The additional commands provided by the tdbc::sqlite3 package.</DD>\n");
    
    fprintf(file, "<DT><A HREF=\"ThreadCmd/contents.htm\">Thread Package Commands</A></DT>\n");
    fprintf(file, "<DD>The additional commands provided by the Thread package.</DD>\n");
    
    fprintf(file, "<DT><A HREF=\"TclLib/contents.htm\">Tcl Library</A></DT>\n");
    fprintf(file, "<DD>The C functions which a Tcl extended C program may use.</DD>\n");
    
    fprintf(file, "<DT><A HREF=\"TkLib/contents.htm\">Tk Library</A></DT>\n");
    fprintf(file, "<DD>The additional C functions which a Tk extended C program may use.</DD>\n");
    
    fprintf(file, "<DT><A HREF=\"ItclLib/contents.htm\">[incr Tcl] Package Library</A></DT>\n");
    fprintf(file, "<DD>The additional C functions provided by the [incr Tcl] package.</DD>\n");
    
    fprintf(file, "<DT><A HREF=\"TdbcLib/contents.htm\">TDBC Package Library</A></DT>\n");
    fprintf(file, "<DD>The additional C functions provided by the TDBC package.</DD>\n");
    
    fprintf(file, "<DT><A HREF=\"Keywords/contents.htm\">Keywords</A>\n");
    fprintf(file, "<DD>The keywords from the Tcl/Tk man pages.\n");
    fprintf(file, "<!--\n<DT><A HREF=\"tutorial/tcltutorial.html\">Tcl Tutorial</A></DT>\n");
    fprintf(file, "<DD>Tutorial for Tcl features.</DD>\n-->\n</DL>\n\n");
}

void write_footer(FILE *file) {
    fprintf(file, "<br clear=\"all\" />\n");
    fprintf(file, "<p align=\"center\" class=\"footer\">\n");
    fprintf(file, "\t\t    <small><b>\n");
    fprintf(file, "\t\t    This is the main Tcl Developer Xchange site,\n");
    fprintf(file, "\t\t    www.tcl-lang.org .\n");
    fprintf(file, "\t\t    </b></small>\n");
    fprintf(file, "\t\t&nbsp;&nbsp;\n");
    fprintf(file, "<a href=\"/siteinfo.html\">About this Site</a> |\n");
    fprintf(file, "<a href=\"/cdn-cgi/l/email-protection#7a0d1f18171b090e1f083a0e191657161b141d\"><span class=\"__cf_email__\" data-cfemail=\"95e2f0f7f8f4e6e1f0e7d5e1f6f9b8f9f4fbf2bbfae7f2\">[email&#160;protected]</span></a>\n");
    fprintf(file, "<br>\n");
    fprintf(file, "<a href=\"/\">Home</a> | \n");
    fprintf(file, "<a href=\"/about/\">About Tcl/Tk</a> |\n");
    fprintf(file, "<a href=\"/software/tcltk/\">Software</a> | \n");
    fprintf(file, "<a href=\"/community/coreteam/\">Core Development</a> |\n");
    fprintf(file, "<a href=\"/community/\">Community</a> |\n");
    fprintf(file, "<a href=\"/doc/\">Documentation</a>\n");
    fprintf(file, "</p>\n");
    fprintf(file, "</td></tr></table>");
    fprintf(file, "<script data-cfasync=\"false\" src=\"/cdn-cgi/scripts/5c5dd728/cloudflare-static/email-decode.min.js\" defer></script>");
    fprintf(file, "</body></html>\n");
}

int main(int argc, char *argv[]) {
    FILE *output_file;
    
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_filename>\n", argv[0]);
        return 1;
    }
    
    output_file = fopen(argv[1], "w");
    if (!output_file) {
        perror("Error opening file");
        return 1;
    }
    
    write_html_header(output_file);
    write_top_table(output_file);
    write_navigation_bar(output_file);
    write_search_section(output_file);
    write_content_links(output_file);
    write_footer(output_file);
    
    fclose(output_file);
    return 0;
}
