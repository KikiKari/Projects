// abstraction-provenance: {"artifact_sha256": "59a44e159a62905689e9592e7a9b5f80f0245ba86ffa6eb073802c4d0fdaf1ee", "source_sha256": "5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988", "target_language": "java"}
// index.html — portiert nach java
// Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html
// auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.util.*;

public class IndexGenerator {
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java IndexGenerator <output-file>");
            System.exit(1);
        }
        
        try {
            generateIndexFile(args[0]);
        } catch (IOException e) {
            System.err.println("Error writing file: " + e.getMessage());
            System.exit(1);
        }
    }
    
    private static void generateIndexFile(String filename) throws IOException {
        PrintWriter writer = new PrintWriter(new FileWriter(filename));
        
        // DOCTYPE declaration
        writer.println("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">");
        
        // HTML start
        writer.println("<html>");
        
        // Head section
        writeHead(writer);
        
        // Body start
        writer.println("<body bgcolor=\"white\" text=\"black\">");
        
        // Header table
        writeHeaderTable(writer);
        
        // Navigation
        writeNavigation(writer);
        
        // Divider
        writer.println("<br clear=\"all\" />");
        writer.println("<DIV style=\"border-top: 2px solid #3163CE; width: 780px\"></DIV>");
        
        // Search table
        writeSearchTable(writer);
        
        // Yellow divider
        writer.println("<DIV style=\"border-top: 1px solid #FFCE00; margin-bottom: 2px; width: 780px\"></DIV>");
        
        // Main content table
        writeMainContent(writer);
        
        // Scripts
        writer.println("<script data-cfasync=\"false\" src=\"/cdn-cgi/scripts/5c5dd728/cloudflare-static/email-decode.min.js\" defer></script>");
        
        // Close tags
        writer.println("</body>");
        writer.println("</html>");
        
        writer.close();
    }
    
    private static void writeHead(PrintWriter writer) {
        writer.println("<head>\t<title>Tcl/Tk 8.6 Manual</title>");
        writer.println("\t<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">");
        writer.println("\t<link rel=\"stylesheet\" href=\"/devsite.css\" type=\"text/css\" media=\"all\">");
        writer.println("</head>");
    }
    
    private static void writeHeaderTable(PrintWriter writer) {
        writer.println("\t<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"780\">");
        writer.println("	    <tr>");
        writer.println("	    <td valign=\"top\" align=\"left\"><a href=\"/\"><img src=\"/images/plume.png\" width=\"60\" height=\"55\"");
        writer.println("	border=\"0\" alt=\"Tcl Home\" /><img src=\"/images/Developer.gif\" width=\"355\" height=\"55\"");
        writer.println("	border=\"0\" alt=\"Tcl Home\" title=\"Tcl Developer Xchange\" /></a></td>");
        writer.println("	    <td valign=\"top\" align=\"right\"><a href=\"/siteinfo.html\"><font size=1>Hosted by</font></a><br><a href=\"http://www.ActiveState.com/products/tcl\"><img src=\"/images/aslogo.gif\"");
        writer.println("	border=\"0\" alt=\"ActiveState\"");
        writer.println("	title=\"This site is hosted by ActiveState\" /></a></td>");
        writer.println("	    </tr>");
        writer.println("	</table>");
    }
    
    private static void writeNavigation(PrintWriter writer) {
        writer.println("    <div id=\"globalnav\"><ul>");
        writer.println("<li><a href=\"/\">HOME</a></li>");
        writer.println("<li><a href=\"/about/\">ABOUT TCL/TK</a></li>");
        writer.println("<li><a href=\"/software/tcltk/\">SOFTWARE</a></li>");
        writer.println("<li><a href=\"/community/coreteam/\">CORE DEVELOPMENT</a></li>");
        writer.println("<li><a href=\"/community/\">COMMUNITY</a></li>");
        writer.println("<li><a href=\"/doc/\" class=\"here\">DOCUMENTATION</a></li>");
        writer.println("</ul></div>");
    }
    
    private static void writeSearchTable(PrintWriter writer) {
        writer.println("<table border=\"0\" cellpadding=\"2\" cellspacing=\"0\" width=\"780\">");
        writer.println("	    <tr><td align=\"left\" valign=\"middle\">");
        writer.println("<!-- SiteSearch Google -->");
        writer.println("	<div style=\"display:table-cell; vertical-align:middle; margin:0px\">");
        writer.println("<FORM method=\"GET\" action=\"https://www.google.com/search\">");
        writer.println("<A HREF=\"https://www.google.com/\"><IMG src=\"/images/Search.gif\" border=\"0\"");
        writer.println("ALT=\"Google SiteSearch\" /></A>");
        writer.println("<INPUT TYPE=\"text\" name=\"q\" size=\"20\" maxlength=\"255\" value=\"\">");
        writer.println("<INPUT type=\"image\" value=\"submit\" name=\"btnG\" src=\"/images/Go.gif\">");
        writer.println("<input type=\"hidden\" name=\"ie\" value=\"UTF-8\">");
        writer.println("<input type=\"hidden\" name=\"oe\" value=\"UTF-8\">");
        writer.println("<input type=\"hidden\" name=\"domains\" value=\"tcl.tk\">");
        writer.println("<input type=\"hidden\" name=\"sitesearch\" value=\"tcl.tk\">");
        writer.println("</FORM></div>");
        writer.println("<!-- SiteSearch Google -->");
        writer.println("</td><td ");
        writer.println("	    align=\"right\"><p class=\"banner\">Tcl/Tk 8.6 Manual</p></td></tr></table>");
    }
    
    private static void writeMainContent(PrintWriter writer) {
        writer.println("<table border=\"0\" cellpadding=\"0\" cellspacing=\"0\" width=\"780\">");
        writer.println("<tr><td>");
        writer.println("<DL class=\"keylist\">");
        
        writeLinkItem(writer, "UserCmd/contents.htm", "Tcl/Tk Applications", 
            "The interpreters which implement Tcl and Tk.");
        writeLinkItem(writer, "TclCmd/contents.htm", "Tcl Commands", 
            "The commands which the <B>tclsh</B> interpreter implements.");
        writeLinkItem(writer, "TkCmd/contents.htm", "Tk Commands", 
            "The additional commands which the <B>wish</B> interpreter implements.");
        writeLinkItem(writer, "ItclCmd/contents.htm", "[incr Tcl] Package Commands", 
            "The additional commands provided by the [incr Tcl] package.");
        writeLinkItem(writer, "SqliteCmd/contents.htm", "SQLite Package Commands", 
            "The additional commands provided by the SQLite package.");
        writeLinkItem(writer, "TdbcCmd/contents.htm", "TDBC Package Commands", 
            "The additional commands provided by the TDBC package.");
        writeLinkItem(writer, "TdbcmysqlCmd/contents.htm", "tdbc::mysql Package Commands", 
            "The additional commands provided by the tdbc::mysql package.");
        writeLinkItem(writer, "TdbcodbcCmd/contents.htm", "tdbc::odbc Package Commands", 
            "The additional commands provided by the tdbc::odbc package.");
        writeLinkItem(writer, "TdbcpostgresCmd/contents.htm", "tdbc::postgres Package Commands", 
            "The additional commands provided by the tdbc::postgres package.");
        writeLinkItem(writer, "TdbcsqliteCmd/contents.htm", "tdbc::sqlite3 Package Commands", 
            "The additional commands provided by the tdbc::sqlite3 package.");
        writeLinkItem(writer, "ThreadCmd/contents.htm", "Thread Package Commands", 
            "The additional commands provided by the Thread package.");
        writeLinkItem(writer, "TclLib/contents.htm", "Tcl Library", 
            "The C functions which a Tcl extended C program may use.");
        writeLinkItem(writer, "TkLib/contents.htm", "Tk Library", 
            "The additional C functions which a Tk extended C program may use.");
        writeLinkItem(writer, "ItclLib/contents.htm", "[incr Tcl] Package Library", 
            "The additional C functions provided by the [incr Tcl] package.");
        writeLinkItem(writer, "TdbcLib/contents.htm", "TDBC Package Library", 
            "The additional C functions provided by the TDBC package.");
        writeLinkItem(writer, "Keywords/contents.htm", "Keywords", 
            "The keywords from the Tcl/Tk man pages.");
        
        writer.println("<!--");
        writer.println("<DT><A HREF=\"tutorial/tcltutorial.html\">Tcl Tutorial</A></DT>");
        writer.println("<DD>Tutorial for Tcl features.</DD>");
        writer.println("-->");
        writer.println("</DL>");
        
        writer.println("<br clear=\"all\" />");
        writer.println("<p align=\"center\" class=\"footer\">");
        writer.println("		    <small><b>");
        writer.println("		    This is the main Tcl Developer Xchange site,");
        writer.println("		    www.tcl-lang.org .");
        writer.println("		    </b></small>");
        writer.println("		&nbsp;&nbsp;");
        writer.println("<a href=\"/siteinfo.html\">About this Site</a> |");
        writer.println("<a href=\"/cdn-cgi/l/email-protection#7a0d1f18171b090e1f083a0e191657161b141d\"><span class=\"__cf_email__\" data-cfemail=\"95e2f0f7f8f4e6e1f0e7d5e1f6f9b8f9f4fbf2bbfae7f2\">[email&#160;protected]</span></a>");
        writer.println("<br>");
        writer.println("<a href=\"/\">Home</a> | ");
        writer.println("<a href=\"/about/\">About Tcl/Tk</a> |");
        writer.println("<a href=\"/software/tcltk/\">Software</a> | ");
        writer.println("<a href=\"/community/coreteam/\">Core Development</a> |");
        writer.println("<a href=\"/community/\">Community</a> |");
        writer.println("<a href=\"/doc/\">Documentation</a>");
        writer.println("</p>");
        writer.println("</td></tr></table>");
    }
    
    private static void writeLinkItem(PrintWriter writer, String href, String title, String description) {
        writer.println("<DT><A HREF=\"" + href + "\">" + title + "</A></DT>");
        writer.println("<DD>" + description + "</DD>");
    }
}
