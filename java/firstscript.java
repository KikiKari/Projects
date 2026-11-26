// abstraction-provenance: {"artifact_sha256": "1e841a1c333075da8b7eb1e725eb0dafe8c8f34dde938f6487005d331342a056", "source_sha256": "4f983e18647beafe2b9b2b47b22a387ea65bb995eabb76e5206fc5b0ebb175d2", "target_language": "java"}
// firstscript.html — portiert nach java
// Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/eggdrop/firstscript.html
// auch in: OpenClaw@gateway2:skills/scripting-utils/references/eggdrop/firstscript.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.util.*;

public class FirstScriptGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java FirstScriptGenerator <output-file>");
            System.exit(1);
        }

        String outputFile = args[0];
        try {
            generateHtml(outputFile);
            System.out.println("HTML file generated: " + outputFile);
        } catch (IOException e) {
            System.err.println("Error generating HTML file: " + e.getMessage());
            System.exit(1);
        }
    }

    private static void generateHtml(String outputFile) throws IOException {
        PrintWriter writer = new PrintWriter(new FileWriter(outputFile));
        
        // DOCTYPE
        writer.println("<!DOCTYPE html>");
        writer.println();
        
        // HTML opening tag
        writer.println("<html lang=\"en\" data-content_root=\"../\">");
        
        // HEAD section
        generateHead(writer);
        
        // BODY section
        generateBody(writer);
        
        // Closing tags
        writer.println("</html>");
        
        writer.close();
    }

    private static void generateHead(PrintWriter writer) {
        writer.println("  <head>");
        writer.println("    <meta charset=\"utf-8\" />");
        writer.println("    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" /><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />");
        writer.println();
        writer.println("    <title>Writing an Eggdrop Tcl Script &#8212; Eggdrop 1.10.1rc2 documentation</title>");
        writer.println("    <link rel=\"stylesheet\" type=\"text/css\" href=\"../_static/pygments.css?v=03e43079\" />");
        writer.println("    <link rel=\"stylesheet\" type=\"text/css\" href=\"../_static/eggdrop.css?v=ab48a1b6\" />");
        writer.println("    <script src=\"../_static/documentation_options.js?v=290de6c6\"></script>");
        writer.println("    <script src=\"../_static/doctools.js?v=9bcbadda\"></script>");
        writer.println("    <script src=\"../_static/sphinx_highlight.js?v=dc90522c\"></script>");
        writer.println("    <link rel=\"search\" title=\"Search\" href=\"../search.html\" />");
        writer.println("    <link rel=\"next\" title=\"Writing a Basic Eggdrop Module\" href=\"module.html\" />");
        writer.println("    <link rel=\"prev\" title=\"Sharing Userfiles\" href=\"userfilesharing.html\" />");
        writer.println("  </head>");
    }

    private static void generateBody(PrintWriter writer) {
        writer.println("<body>");
        
        // Header wrapper
        writer.println("    <div class=\"header-wrapper\" role=\"banner\">");
        writer.println("      <div class=\"header\">");
        writer.println("        <div class=\"headertitle\"><a");
        writer.println("          href=\"../index.html\">Eggdrop 1.10.1rc2 documentation</a></div>");
        writer.println("        <div class=\"rel\" role=\"navigation\" aria-label=\"related navigation\">");
        writer.println("          <a href=\"userfilesharing.html\" title=\"Sharing Userfiles\"");
        writer.println("             accesskey=\"P\">previous</a> |");
        writer.println("          <a href=\"module.html\" title=\"Writing a Basic Eggdrop Module\"");
        writer.println("             accesskey=\"N\">next</a>");
        writer.println("        </div>");
        writer.println("       </div>");
        writer.println("    </div>");
        writer.println();
        
        // Content wrapper
        writer.println("    <div class=\"content-wrapper\">");
        writer.println("      <div class=\"content\">");
        writer.println("        <div class=\"sidebar\">");
        writer.println();
        writer.println("          <h3>Table of Contents</h3>");
        
        // Table of contents - Installing Eggdrop
        writer.println("          <p class=\"caption\" role=\"heading\"><span class=\"caption-text\">Installing Eggdrop</span></p>");
        writer.println("<ul>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../install/readme.html\">README</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../install/install.html\">Installing Eggdrop</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../install/upgrading.html\">Upgrading Eggdrop</a></li>");
        writer.println("</ul>");
        
        // Table of contents - Using Eggdrop
        writer.println("<p class=\"caption\" role=\"heading\"><span class=\"caption-text\">Using Eggdrop</span></p>");
        writer.println("<ul>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/features.html\">Eggdrop Features</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/core.html\">Eggdrop Core Settings</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/partyline.html\">The Party Line</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/autoscripts.html\">Eggdrop Autoscripts</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/users.html\">Users and Flags</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/bans.html\">Bans, Invites, and Exempts</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/botnet.html\">Botnet Sharing and Linking</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/ipv6.html\">IPv6 support</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/tls.html\">TLS support</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/ircv3.html\">IRCv3 support</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/accounts.html\">Account tracking in Eggdrop</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/pbkdf2info.html\">Encryption/Hashing</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/python.html\">Using the Python Module</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/twitchinfo.html\">Twitch</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/tricks.html\">Advanced Tips</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/text-sub.html\">Textfile Substitutions</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/tcl-commands.html\">Eggdrop Tcl Commands</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/twitch-tcl-commands.html\">Eggdrop Twitch Tcl Commands</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../using/patch.html\">Patching Eggdrop</a></li>");
        writer.println("</ul>");
        
        // Table of contents - Tutorials
        writer.println("<p class=\"caption\" role=\"heading\"><span class=\"caption-text\">Tutorials</span></p>");
        writer.println("<ul class=\"current\">");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"setup.html\">Setting Up Eggdrop</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"firststeps.html\">Common First Steps</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"tlssetup.html\">Enabling TLS Security on Eggdrop</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"userfilesharing.html\">Sharing Userfiles</a></li>");
        writer.println("<li class=\"toctree-l1 current\"><a class=\"current reference internal\" href=\"#\">Writing an Eggdrop Tcl Script</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"module.html\">Writing a Basic Eggdrop Module</a></li>");
        writer.println("</ul>");
        
        // Table of contents - Eggdrop Modules
        writer.println("<p class=\"caption\" role=\"heading\"><span class=\"caption-text\">Eggdrop Modules</span></p>");
        writer.println("<ul>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../modules/index.html\">Eggdrop Module Information</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../modules/included.html\">Modules included with Eggdrop</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../modules/writing.html\">How to Write an Eggdrop Module</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../modules/internals.html\">Eggdrop Bind Internals</a></li>");
        writer.println("</ul>");
        
        // Table of contents - About Eggdrop
        writer.println("<p class=\"caption\" role=\"heading\"><span class=\"caption-text\">About Eggdrop</span></p>");
        writer.println("<ul>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../about/about.html\">About Eggdrop</a></li>");
        writer.println("<li class=\"toctree-l1\"><a class=\"reference internal\" href=\"../about/legal.html\">Boring legal stuff</a></li>");
        writer.println("</ul>");
        writer.println();
        
        // Search form
        writer.println("          <div role=\"search\">");
        writer.println("            <h3 style=\"margin-top: 1.5em;\">Search</h3>");
        writer.println("            <form class=\"search\" action=\"../search.html\" method=\"get\">");
        writer.println("                <input type=\"text\" name=\"q\" />");
        writer.println("                <input type=\"submit\" value=\"Go\" />");
        writer.println("            </form>");
        writer.println("          </div>");
        writer.println();
        writer.println("        </div>");
        
        // Document content
        generateDocumentContent(writer);
        
        writer.println("        </div>");
        writer.println("        <div class=\"clearer\"></div>");
        writer.println("      </div>");
        writer.println("    </div>");
        
        // Footer wrapper
        generateFooter(writer);
        
        writer.println("  </body>");
    }

    private static void generateDocumentContent(PrintWriter writer) {
        writer.println("        <div class=\"document\">");
        writer.println("            ");
        writer.println("      <div class=\"documentwrapper\">");
        writer.println("        <div class=\"bodywrapper\">");
        writer.println("          <div class=\"body\" role=\"main\">");
        writer.println("            ");
        writer.println("  <section id=\"writing-an-eggdrop-tcl-script\">");
        writer.println("<h1>Writing an Eggdrop Tcl Script<a class=\"headerlink\" href=\"#writing-an-eggdrop-tcl-script\" title=\"Link to this heading\">¶</a></h1>");
        writer.println("<p>So you want to write an Eggdrop Tcl script, but you don’t really know where");
        writer.println("to begin. This file will give you a very basic idea about what Eggdrop");
        writer.println("scripting is like, using a <em>very</em> simple script that may help you get");
        writer.println("started with your own scripts.</p>");
        writer.println("<p>This guide assumes you know a bit about Eggdrops and IRC. You should have");
        writer.println("already installed Eggdrop. The bot should not be on any important or busy");
        writer.println("channels (development bots can be annoying if your script has bugs). If you");
        writer.println("plan on doing a lot of development, enable the .tcl and .set commands, and");
        writer.println("make sure nobody else has access to your bot. The .tcl and .set commands");
        writer.println("are helpful in debugging and testing your code.</p>");
        writer.println("<p>First, read through the script. Very few commands are listed here intentionally,");
        writer.println("but as you want to develop more advanced scripts, you will definitely want to");
        writer.println("get familiar with the <a class=\"reference external\" href=\"https://www.tcl.tk/man/tcl8.6/TclCmd/contents.htm\">core Tcl language commands</a>, especially the string- and list-related commands, as well as Eggdrop’s own library of custom Tcl commands, located in <a class=\"reference external\" href=\"https://docs.eggheads.org/using/tcl-commands.html\">tcl-commands.doc</a></p>");
        writer.println("<p>If you have the .tcl command enabled, you can load a script by typing");
        writer.println("‘.tcl source script/file.tcl’ to load it. Otherwise, add it to your config");
        writer.println("file like normal (examples to do so are at the bottom of the config file) and");
        writer.println("‘.rehash’ or ‘.restart’ your bot.</p>");
        writer.println("<p>Let’s look at a very basic example script that greets users as they join a channel:</p>");
        writer.println("<div class=\"highlight-default notranslate\"><div class=\"highlight\"><pre><span></span># GreetScript.tcl");
        writer.println("# Version: 1.0");
        writer.println("# Author: Geo &lt;geo@eggheads.org&gt;");
        writer.println("#");
        writer.println("# Description:");
        writer.println("# A simple script that greets users as they join a channel");
        writer.println("#");
        writer.println("### Config Section ###");
        writer.println("# How would you like the bot to gree users?");
        writer.println("# 0 - via public message to channel");
        writer.println("# 1 - via private message");
        writer.println("set pmsg 0");
        writer.println("# What message would you like to send to users when they join?");
        writer.println("set greetmsg &quot;Hi! Welcome to the channel!&quot;");
        writer.println("### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING! ###");
        writer.println("");
        writer.println("bind join - * greet");
        writer.println("");
        writer.println("proc greet {nick uhost hand chan} {");
        writer.println("  global pmsg");
        writer.println("  global greetmsg");
        writer.println("  if {$pmsg} {");
        writer.println("    putserv &quot;PRIVMSG $nick :$greetmsg&quot;");
        writer.println("  } else {");
        writer.println("    putserv &quot;PRIVMSG $chan :$greetmsg&quot;");
        writer.println("  }");
        writer.println("}");
        writer.println("");
        writer.println("putlog &quot;greetscript.tcl v1.0 by Geo&quot;");
        writer.println("</pre></div>");
        writer.println("</div>");
        writer.println("<p>Whew! There’s a lot going on here. You’ll generally see scripts broken into a few key parts- the header, the config section, and the code section. Ok, let’s go over this piece by piece. First, the header of the script:</p>");
        writer.println("<div class=\"highlight-default notranslate\"><div class=\"highlight\"><pre><span></span><span class=\"c1\"># GreetScript.tcl</span>");
        writer.println("<span class=\"c1\"># Version: 1.0</span>");
        writer.println("<span class=\"c1\"># Author: Geo &lt;geo@eggheads.org&gt; or #eggdrop on Libera</span>");
        writer.println("<span class=\"c1\">#</span>");
        writer.println("<span class=\"c1\"># Description:</span>");
        writer.println("<span class=\"c1\"># A simple script that greets users as they join a channel</span>");
        writer.println("</pre></div>");
        writer.println("</div>");
        writer.println("<p>Any line prefixed by a # means it is comment, and thus ignored. You can type whatever you want, and it won’t matter. When writing scripts (especially if you want to give them to other people, it is good to use comments in the code to show what you’re doing. Here though, we use it to describe what the script is and, most importantly, who wrote it! Let’s give credit where credit is due, right? You may want to give users a way to contact you as well.</p>");
        writer.println("<p>Next, let’s look at the configuration section:</p>");
        writer.println("<div class=\"highlight-default notranslate\"><div class=\"highlight\"><pre><span></span><span class=\"c1\">### Config Section ###</span>");
        writer.println("<span class=\"c1\"># How would you like the bot to gree users?</span>");
        writer.println("<span class=\"c1\"># 0 - via public message to channel</span>");
        writer.println("<span class=\"c1\"># 1 - via private message</span>");
        writer.println("<span class=\"nb\">set</span> <span class=\"n\">pmsg</span> <span class=\"mi\">0</span>");
        writer.println("<span class=\"c1\"># What message would you like to send to users when they join?</span>");
        writer.println("<span class=\"nb\">set</span> <span class=\"n\">greetmsg</span> <span class=\"s2\">&quot;Hi! Welcome to the channel!&quot;</span>");
        writer.println("<span class=\"c1\">### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING! ###</span>");
        writer.println("</pre></div>");
        writer.println("</div>");
        writer.println("<p>To make scripts easy to use, you’ll want to have a section that allows users to easily change the way the script operates, without having to edit the script itself. Here, we have two settings: one that controls which method the Eggdrop uses to greet a user, and a second with the message to greet the user with. Sure, we could hard-code that into the code section below, but in larger scripts that makes things harder to find, and also forces you to potentially have to make the same change multiple times in code. Why not make it simple and do it once, up top? Notice the settings do not have #s in front of them- they are variables that will be used by the script later on. And of course, the standard ominous warning not to change anything below!</p>");
        writer.println("<p>Now, let’s look start to dissect the actual code!:</p>");
        writer.println("<div class=\"highlight-default notranslate\"><div class=\"highlight\"><pre><span></span><span class=\"n\">bind</span> <span class=\"n\">join</span> <span class=\"o\">-</span> <span class=\"o\">*</span> <span class=\"n\">greet</span>");
        writer.println("</pre></div>");
        writer.println("</div>");
        writer.println("<p>This is a bind. This sets up an action that Eggdrop will react to. You can read <a class=\"reference external\" href=\"https://docs.eggheads.org/using/tcl-commands.html\">all the binds that Eggdrop uses here.</a> Generally, we like to place all binds towards the top of the script so that they are together and easy to find. Now, let’s look at documentation of the bind join together.</p>");
        writer.println("<table class=\"docutils align-default\">");
        writer.println("<thead>");
        writer.println("<tr class=\"row-odd\"><th class=\"head\" colspan=\"2\"><p>bind JOIN</p></th>");
        writer.println("</tr>");
        writer.println("</thead>");
        writer.println("<tbody>");
        writer.println("<tr class=\"row-even\"><td colspan=\"2\"><p>bind join &lt;flags&gt; &lt;mask&gt; &lt;proc&gt;</p></td>");
        writer.println("</tr>");
        writer.println("<tr class=\"row-odd\"><td colspan=\"2\"><p>procname &lt;nick&gt; &lt;<a class=\"reference external\" href=\"mailto:user&#37;&#52;&#48;host\">user<span>&#64;</span>host</a>&gt; &lt;handle&gt; &lt;channel&gt;</p></td>");
        writer.println("</tr>");
        writer.println("<tr class=\"row-even\"><td colspan=\"2\"><p>Description: triggered by someone joining the channel. The mask in the bind is matched against “#channel <a class=\"reference external\" href=\"mailto:nick!user&#37;&#52;&#48;host\">nick!user<span>&#64;</span>host</a>” and can contain wildcards.</p></td>");
        writer.println("</tr>");
        writer.println("</tbody>");
        writer.println("</table>");
        writer.println("<p>So here, we can start to match the bind listed in the code to how it is described in the documentation. The first term after the bind command is ‘join’, showing that it is a join bind, which means the action we define here will take place each time a user joins a channel. The next term is ‘mask’, and it says it is in the form “#channel <a class=\"reference external\" href=\"mailto:nick!user&#37;&#52;&#48;host\">nick!user<span>&#64;</span>host</a>”. This is where we can start to refine exactly when this bind is triggered. If we want it to work for every person joining every channel Eggdrop is on, then a simple ‘*’ will suffice here- that will match everything. If we wanted this bind to only work in #foo, then the mask would be “#foo *”. If we wanted to greet users on every channel, but only those who are on AOL, the mask would be “* <a class=\"reference external\" href=\"mailto:*!*&#37;&#52;&#48;*&#46;aol&#46;com\">*!*<span>&#64;</span>*<span>&#46;</span>aol<span>&#46;</span>com</a>”. Finally the ‘proc’ argument is the name of the Tcl proc we want to call, where the code that actually <em>does stuff</em> is located.</p>");
        writer.println("<p>So to sum up this line from the example script: When a user joins on any channel and with any hostmask, run the code located in proc ‘greet’.</p>");
        writer.println("<p>Now that we told the Eggdrop what action to look for, we need to tell it what to do when that action occurs!:</p>");
        writer.println("<div class=\"highlight-default notranslate\"><div class=\"highlight\"><pre><span></span><span class=\"n\">proc</span> <span class=\"n\">greet</span> <span class=\"p\">{</span><span class=\"n\">nick</span> <span class=\"n\">uhost</span> <span class=\"n\">hand</span> <span class=\"n\">chan</span><span class=\"p\">}</span> <span class=\"p\">{</span>");
        writer.println("</pre></div>");
        writer.println("</div>");
        writer.println("<p>This is how we declare a Tcl proc. As we said above, this is where the magic happens. To set up the proc (this will look differently for different binds), lets refer back to the bind JOIN documentation. The second line shows <code class=\"docutils literal notranslate\"><span class=\"pre\">procname</span> <span class=\"pre\">&lt;nick&gt;</span> <span class=\"pre\">&lt;user&#64;host&gt;</span> <span class=\"pre\">&lt;handle&gt;</span> <span class=\"pre\">&lt;channel&gt;</span></code>. Eggdrop does a lot of stuff in the background when a bind is triggered, and this is telling you how Eggdrop will present that information to you. Here, Eggdrop is telling you it is going to pass the proc you created four variables: One that contains the nickname of the person who triggered the bind (in this case, the user who joined), the <a class=\"reference external\" href=\"mailto:user&#37;&#52;&#48;host\">user<span>&#64;</span>host</a> of that user, the handle of that user (if the user has one on the bot), and the channel that the bind was triggered on.</p>");
        writer.println("<p>So let’s say someone with the nickname Geo with a hostmask of <a class=\"reference external\" href=\"mailto:awesome&#37;&#52;&#48;aol&#46;com\">awesome<span>&#64;</span>aol<span>&#46;</span>com</a> joined #sexystuff and that person is not added to the bot as a user. Eggdrop will pass 4 values to the variables you set up in that proc: The first variable will get the value “Geo”, the second “<a class=\"reference external\" href=\"mailto:awesome&#37;&#52;&#48;aol&#46;com\">awesome<span>&#64;</span>aol<span>&#46;</span>com</a>”, the third “*”, and the fourth “#sexystuff”. (That third value was a trick, we didn’t talk about that- if the user is not added to the bot, handle will get a “*” as a value). Now, let’s use those variables!:</p>");
        writer.println("<div class=\"highlight-default notranslate\"><div class=\"highlight\"><pre><span></span><span class=\"k\">global</span> <span class=\"n\">pmsg</span>");
        writer.println("<span class=\"k\">global</span> <span class=\"n\">greetmsg</span>");
        writer.println("</pre></div>");
        writer.println("</div>");
        writer.println("<p>This is a simple one- because we’re using variables declared in the main body of the script (remember way up top?), we have to tell this proc to use that variable, not not create a new local variable for this proc.</p>");
        writer.println("<p>And finally, let’s actually send a message to the user:</p>");
        writer.println("<div class=\"highlight-default notranslate\"><div class=\"highlight\"><pre><span></span><span class=\"k\">if</span> <span class=\"p\">{</span><span class=\"n\">pmsg</span><span class=\"p\">}</span>");
        writer.println("  <span class=\"n\">putserv</span> <span class=\"s2\">&quot;PRIVMSG $nick :$greetmsg&quot;</span>");
        writer.println("<span class=\"p\">}</span> <span class=\"k\">else</span> <span class=\"p\">{</span>");
        writer.println("  <span class=\"n\">putserv</span> <span class=\"s2\">&quot;PRIVMSG $chan :$greetmsg&quot;</span>");
        writer.println("<span class=\"p\">}</span>");
        writer.println("</pre></div>");
        writer.println("</div>");
        writer.println("<p>Here, we’re going to check if pmsg is true (any value that is not 0) and, if yes, send a private message to the user. If pmsg is not true (it is 0), then we will send the message to the channel. You can see that the first putserv message sends a PRIVMSG message to $nick - this is the nickname of the user that joined, and that Eggdrop stored for us in the first variable of the proc, which we called ‘nick’. The second putserv message will send a PRIVMSG message to the $chan - this is the channel the user joined, and that Eggdrop stored for us in the fourth variable of the proc, which we called ‘chan’.</p>");
        writer.println("<p>And finally: get the credit you deserve when the script loads!:</p>");
        writer.println("<div class=\"highlight-default notranslate\"><div class=\"highlight\"><pre><span></span><span class=\"n\">putlog</span> <span class=\"s2\">&quot;greetscript.tcl v1.0 by Geo&quot;</span>");
        writer.println("</pre></div>");
        writer.println("</div>");
        writer.println("<p>Like your variables at the top of the script, this line is not inside a Tcl proc and will execute when the script is loaded. You can put this or any other initialization code you want to run.</p>");
        writer.println("<p>And there you have it- your first script! Take this, modify it and experiment. A few challenges for you:</p>");
        writer.println("<ul class=\"simple\">");
        writer.println("<li><p>How can you configure which channel it should run on, without hard-coding it into the bind? (Maybe with a variable…)</p></li>");
        writer.println("<li><p>How can you configure it to only message a user with the nickname “FancyPants”? (Sounds like something a bind could handle)</p></li>");
        writer.println("<li><p>How can you delay the message from sending by 5 seconds? (Hint: utimer)</p></li>");
        writer.println("<li><p>How can you send different messages to different channels? (A new setting may be in order…)</p></li>");
        writer.println("<li><p>How can you get the bot to not greet itself when it joins the channel? (Eggdrop stores its own nickname in a variable called $botnick)</p></li>");
        writer.println("<li><p>How can you add the person joining the channel’s nickname to the greet message? (You can put variables inside variables…)</p></li>");
        writer.println("</ul>");
        writer.println("<p>If you want to try these out, join #eggdrop on Libera and check your answers (and remember, there are dozens of ways to do this, so a) don’t be defensive of your choices, and b) take others’ answers with a grain of salt!)</p>");
        writer.println("<p>Copyright (C) 2003 - 2025 Eggheads Development Team</p>");
        writer.println("</section>");
        writer.println("");
        writer.println("");
        writer.println("            <div class=\"clearer\"></div>");
        writer.println("          </div>");
        writer.println("        </div>");
        writer.println("      </div>");
        writer.println("        </div>");
    }

    private static void generateFooter(PrintWriter writer) {
        writer.println("    <div class=\"footer-wrapper\">");
        writer.println("      <div class=\"footer\">");
        writer.println("        <div class=\"left\">");
        writer.println("          <div role=\"navigation\" aria-label=\"related navigaton\">");
        writer.println("            <a href=\"userfilesharing.html\" title=\"Sharing Userfiles\"");
        writer.println("              >previous</a> |");
        writer.println("            <a href=\"module.html\" title=\"Writing a Basic Eggdrop Module\"");
        writer.println("              >next</a>");
        writer.println("          </div>");
        writer.println("          <div role=\"note\" aria-label=\"source link\">");
        writer.println("          </div>");
        writer.println("        </div>");
        writer.println();
        writer.println("        <div class=\"right\">");
        writer.println("          ");
        writer.println("    <div class=\"footer\" role=\"contentinfo\">");
        writer.println("    &#169; Copyright 2025, Eggheads.");
        writer.println("      Last updated on Aug 15, 2025.");
        writer.println("      Created using <a href=\"https://www.sphinx-doc.org/\">Sphinx</a> 8.2.3.");
        writer.println("    </div>");
        writer.println("        </div>");
        writer.println("        <div class=\"clearer\"></div>");
        writer.println("      </div>");
        writer.println("    </div>");
    }
}
