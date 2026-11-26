// abstraction-provenance: {"artifact_sha256": "731e3b94b78bde959b18a808196a5eb4f1c93222927a4a9ba0b151ce030be59a", "source_sha256": "4f983e18647beafe2b9b2b47b22a387ea65bb995eabb76e5206fc5b0ebb175d2", "target_language": "fsharp"}
// firstscript.html — portiert nach fsharp
// Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/eggdrop/firstscript.html
// auch in: OpenClaw@gateway2:skills/scripting-utils/references/eggdrop/firstscript.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO

type HtmlAttribute = string * string
type HtmlElement = {
    Tag: string
    Attributes: HtmlAttribute list
    Content: HtmlContent list
}
and HtmlContent = 
    | Element of HtmlElement
    | Text of string
    | Raw of string

let createElement tag attributes content = { Tag = tag; Attributes = attributes; Content = content }
let createText text = Text text
let createRaw raw = Raw raw

let attr name value = (name, value)

let rec renderElement (element: HtmlElement) =
    let attrs = 
        element.Attributes
        |> List.map (fun (name, value) -> sprintf "%s=\"%s\"" name value)
        |> String.concat " "
        |> fun s -> if s = "" then "" else " " + s
    
    match element.Content with
    | [] -> sprintf "<%s%s />" element.Tag attrs
    | content ->
        let inner = 
            content 
            |> List.map renderContent 
            |> String.concat ""
        sprintf "<%s%s>%s</%s>" element.Tag attrs inner element.Tag

and renderContent content =
    match content with
    | Element e -> renderElement e
    | Text t -> 
        t.Replace("&", "&amp;")
         .Replace("<", "&lt;")
         .Replace(">", "&gt;")
    | Raw r -> r

let doctype = "<!DOCTYPE html>"
let htmlRoot attrs content = createElement "html" attrs content
let head content = createElement "head" [] content
let meta attrs = createElement "meta" attrs []
let title content = createElement "title" [] [Text content]
let link attrs = createElement "link" attrs []
let script attrs = createElement "script" attrs []
let body attrs content = createElement "body" attrs content

let div attrs content = createElement "div" attrs content
let p attrs content = createElement "p" attrs content
let h1 attrs content = createElement "h1" attrs content
let h3 attrs content = createElement "h3" attrs content
let ul attrs content = createElement "ul" attrs content
let li attrs content = createElement "li" attrs content
let a attrs content = createElement "a" attrs content
let span attrs content = createElement "span" attrs content
let form attrs content = createElement "form" attrs content
let input attrs = createElement "input" attrs []
let section attrs content = createElement "section" attrs content
let pre attrs content = createElement "pre" attrs content
let table attrs content = createElement "table" attrs content
let thead attrs content = createElement "thead" attrs content
let tbody attrs content = createElement "tbody" attrs content
let tr attrs content = createElement "tr" attrs content
let th attrs content = createElement "th" attrs content
let td attrs content = createElement "td" attrs content
let code content = createElement "code" [] [Text content]

let generateHtml() =
    htmlRoot [("lang", "en"); ("data-content_root", "../")] [
        head [] [
            meta [("charset", "utf-8")]
            meta [("name", "viewport"); ("content", "width=device-width, initial-scale=1.0")]
            meta [("name", "viewport"); ("content", "width=device-width, initial-scale=1")]
            title "Writing an Eggdrop Tcl Script — Eggdrop 1.10.1rc2 documentation"
            link [("rel", "stylesheet"); ("type", "text/css"); ("href", "../_static/pygments.css?v=03e43079")]
            link [("rel", "stylesheet"); ("type", "text/css"); ("href", "../_static/eggdrop.css?v=ab48a1b6")]
            script [("src", "../_static/documentation_options.js?v=290de6c6")] []
            script [("src", "../_static/doctools.js?v=9bcbadda")] []
            script [("src", "../_static/sphinx_highlight.js?v=dc90522c")] []
            link [("rel", "search"); ("title", "Search"); ("href", "../search.html")]
            link [("rel", "next"); ("title", "Writing a Basic Eggdrop Module"); ("href", "module.html")]
            link [("rel", "prev"); ("title", "Sharing Userfiles"); ("href", "userfilesharing.html")]
        ]
        body [] [
            div [("class", "header-wrapper"); ("role", "banner")] [
                div [("class", "header")] [
                    div [("class", "headertitle")] [
                        a [("href", "../index.html")] [
                            createText "Eggdrop 1.10.1rc2 documentation"
                        ]
                    ]
                    div [("class", "rel"); ("role", "navigation"); ("aria-label", "related navigation")] [
                        a [("href", "userfilesharing.html"); ("title", "Sharing Userfiles"); ("accesskey", "P")] [
                            createText "previous"
                        ]
                        createText " | "
                        a [("href", "module.html"); ("title", "Writing a Basic Eggdrop Module"); ("accesskey", "N")] [
                            createText "next"
                        ]
                    ]
                ]
            ]
            div [("class", "content-wrapper")] [
                div [("class", "content")] [
                    div [("class", "sidebar")] [
                        createRaw @"
          <h3>Table of Contents</h3>
          <p class=""caption"" role=""heading""><span class=""caption-text"">Installing Eggdrop</span></p>
<ul>
<li class=""toctree-l1""><a class=""reference internal"" href=""../install/readme.html"">README</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../install/install.html"">Installing Eggdrop</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../install/upgrading.html"">Upgrading Eggdrop</a></li>
</ul>
<p class=""caption"" role=""heading""><span class=""caption-text"">Using Eggdrop</span></p>
<ul>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/features.html"">Eggdrop Features</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/core.html"">Eggdrop Core Settings</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/partyline.html"">The Party Line</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/autoscripts.html"">Eggdrop Autoscripts</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/users.html"">Users and Flags</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/bans.html"">Bans, Invites, and Exempts</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/botnet.html"">Botnet Sharing and Linking</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/ipv6.html"">IPv6 support</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/tls.html"">TLS support</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/ircv3.html"">IRCv3 support</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/accounts.html"">Account tracking in Eggdrop</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/pbkdf2info.html"">Encryption/Hashing</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/python.html"">Using the Python Module</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/twitchinfo.html"">Twitch</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/tricks.html"">Advanced Tips</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/text-sub.html"">Textfile Substitutions</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/tcl-commands.html"">Eggdrop Tcl Commands</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/twitch-tcl-commands.html"">Eggdrop Twitch Tcl Commands</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../using/patch.html"">Patching Eggdrop</a></li>
</ul>
<p class=""caption"" role=""heading""><span class=""caption-text"">Tutorials</span></p>
<ul class=""current"">
<li class=""toctree-l1""><a class=""reference internal"" href=""setup.html"">Setting Up Eggdrop</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""firststeps.html"">Common First Steps</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""tlssetup.html"">Enabling TLS Security on Eggdrop</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""userfilesharing.html"">Sharing Userfiles</a></li>
<li class=""toctree-l1 current""><a class=""current reference internal"" href=""#"">Writing an Eggdrop Tcl Script</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""module.html"">Writing a Basic Eggdrop Module</a></li>
</ul>
<p class=""caption"" role=""heading""><span class=""caption-text"">Eggdrop Modules</span></p>
<ul>
<li class=""toctree-l1""><a class=""reference internal"" href=""../modules/index.html"">Eggdrop Module Information</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../modules/included.html"">Modules included with Eggdrop</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../modules/writing.html"">How to Write an Eggdrop Module</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../modules/internals.html"">Eggdrop Bind Internals</a></li>
</ul>
<p class=""caption"" role=""heading""><span class=""caption-text"">About Eggdrop</span></p>
<ul>
<li class=""toctree-l1""><a class=""reference internal"" href=""../about/about.html"">About Eggdrop</a></li>
<li class=""toctree-l1""><a class=""reference internal"" href=""../about/legal.html"">Boring legal stuff</a></li>
</ul>"
                        div [("role", "search")] [
                            h3 [("style", "margin-top: 1.5em;")] [createText "Search"]
                            form [("class", "search"); ("action", "../search.html"); ("method", "get")] [
                                input [("type", "text"); ("name", "q")] []
                                input [("type", "submit"); ("value", "Go")] []
                            ]
                        ]
                    ]
                    div [("class", "document")] [
                        div [("class", "documentwrapper")] [
                            div [("class", "bodywrapper")] [
                                div [("class", "body"); ("role", "main")] [
                                    section [("id", "writing-an-eggdrop-tcl-script")] [
                                        h1 [("class", "headerlink"); ("href", "#writing-an-eggdrop-tcl-script"); ("title", "Link to this heading")] [
                                            createText "Writing an Eggdrop Tcl Script"
                                            createRaw "&#182;"
                                        ]
                                        p [] [createText @"So you want to write an Eggdrop Tcl script, but you don’t really know where
to begin. This file will give you a very basic idea about what Eggdrop
scripting is like, using a \emph{very} simple script that may help you get
started with your own scripts."]
                                        p [] [createText @"This guide assumes you know a bit about Eggdrops and IRC. You should have
already installed Eggdrop. The bot should not be on any important or busy
channels (development bots can be annoying if your script has bugs). If you
plan on doing a lot of development, enable the .tcl and .set commands, and
make sure nobody else has access to your bot. The .tcl and .set commands
are helpful in debugging and testing your code."]
                                        p [] [createText @"First, read through the script. Very few commands are listed here intentionally,
but as you want to develop more advanced scripts, you will definitely want to
get familiar with the \href{https://www.tcl.tk/man/tcl8.6/TclCmd/contents.htm}{core Tcl language commands}, especially the string- and list-related commands, as well as Eggdrop’s own library of custom Tcl commands, located in \href{https://docs.eggheads.org/using/tcl-commands.html}{tcl-commands.doc}"]
                                        p [] [createText @"If you have the .tcl command enabled, you can load a script by typing
‘.tcl source script/file.tcl’ to load it. Otherwise, add it to your config
file like normal (examples to do so are at the bottom of the config file) and
‘.rehash’ or ‘.restart’ your bot."]
                                        p [] [createText "Let’s look at a very basic example script that greets users as they join a channel:"]
                                        pre [("class", "highlight-default notranslate")] [
                                            div [("class", "highlight")] [
                                                createRaw @"<pre><span></span># GreetScript.tcl
# Version: 1.0
# Author: Geo &lt;geo@eggheads.org&gt;
#
# Description:
# A simple script that greets users as they join a channel
#
### Config Section ###
# How would you like the bot to gree users?
# 0 - via public message to channel
# 1 - via private message
set pmsg 0
# What message would you like to send to users when they join?
set greetmsg ""Hi! Welcome to the channel!""
### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING! ###

bind join - * greet

proc greet {nick uhost hand chan} {
  global pmsg
  global greetmsg
  if {$pmsg} {
    putserv ""PRIVMSG $nick :$greetmsg""
  } else {
    putserv ""PRIVMSG $chan :$greetmsg""
  }
}

putlog ""greetscript.tcl v1.0 by Geo""
</pre>"
                                            ]
                                        ]
                                        p [] [createText @"Whew! There’s a lot going on here. You’ll generally see scripts broken into a few key parts- the header, the config section, and the code section. Ok, let’s go over this piece by piece. First, the header of the script:"]
                                        pre [("class", "highlight-default notranslate")] [
                                            div [("class", "highlight")] [
                                                createRaw @"<pre><span></span><span class=""c1""># GreetScript.tcl</span>
<span class=""c1""># Version: 1.0</span>
<span class=""c1""># Author: Geo &lt;geo@eggheads.org&gt; or #eggdrop on Libera</span>
<span class=""c1"">#</span>
<span class=""c1""># Description:</span>
<span class=""c1""># A simple script that greets users as they join a channel</span>
</pre>"
                                            ]
                                        ]
                                        p [] [createText @"Any line prefixed by a # means it is comment, and thus ignored. You can type whatever you want, and it won’t matter. When writing scripts (especially if you want to give them to other people, it is good to use comments in the code to show what you’re doing. Here though, we use it to describe what the script is and, most importantly, who wrote it! Let’s give credit where credit is due, right? You may want to give users a way to contact you as well."]
                                        p [] [createText "Next, let’s look at the configuration section:"]
                                        pre [("class", "highlight-default notranslate")] [
                                            div [("class", "highlight")] [
                                                createRaw @"<pre><span></span><span class=""c1"">### Config Section ###</span>
<span class=""c1""># How would you like the bot to gree users?</span>
<span class=""c1""># 0 - via public message to channel</span>
<span class=""c1""># 1 - via private message</span>
<span class=""nb"">set</span> <span class=""n"">pmsg</span> <span class=""mi"">0</span>
<span class=""c1""># What message would you like to send to users when they join?</span>
<span class=""nb"">set</span> <span class=""n"">greetmsg</span> <span class=""s2"">""Hi! Welcome to the channel!""</span>
<span class=""c1"">### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING! ###</span>
</pre>"
                                            ]
                                        ]
                                        p [] [createText @"To make scripts easy to use, you’ll want to have a section that allows users to easily change the way the script operates, without having to edit the script itself. Here, we have two settings: one that controls which method the Eggdrop uses to greet a user, and a second with the message to greet the user with. Sure, we could hard-code that into the code section below, but in larger scripts that makes things harder to find, and also forces you to potentially have to make the same change multiple times in code. Why not make it simple and do it once, up top? Notice the settings do not have #s in front of them- they are variables that will be used by the script later on. And of course, the standard ominous warning not to change anything below!"]
                                        p [] [createText "Now, let’s look start to dissect the actual code!:"]
                                        pre [("class", "highlight-default notranslate")] [
                                            div [("class", "highlight")] [
                                                createRaw @"<pre><span></span><span class=""n"">bind</span> <span class=""n"">join</span> <span class=""o"">-</span> <span class=""o"">*</span> <span class=""n"">greet</span>
</pre>"
                                            ]
                                        ]
                                        p [] [createText @"This is a bind. This sets up an action that Eggdrop will react to. You can read \href{https://docs.eggheads.org/using/tcl-commands.html}{all the binds that Eggdrop uses here.} Generally, we like to place all binds towards the top of the script so that they are together and easy to find. Now, let’s look at documentation of the bind join together."]
                                        table [("class", "docutils align-default")] [
                                            thead [] [
                                                tr [("class", "row-odd")] [
                                                    th [("class", "head"); ("colspan", "2")] [
                                                        p [] [createText "bind JOIN"]
                                                    ]
                                                ]
                                            ]
                                            tbody [] [
                                                tr [("class", "row-even")] [
                                                    td [("colspan", "2")] [
                                                        p [] [createText "bind join <flags> <mask> <proc>"]
                                                    ]
                                                ]
                                                tr [("class", "row-odd")] [
                                                    td [("colspan", "2")] [
                                                        p [] [createText "procname <nick> <user@host> <handle> <channel>"]
                                                    ]
                                                ]
                                                tr [("class", "row-even")] [
                                                    td [("colspan", "2")] [
                                                        p [] [createText "Description: triggered by someone joining the channel. The mask in the bind is matched against “#channel nick!user@host” and can contain wildcards."]
                                                    ]
                                                ]
                                            ]
                                        ]
                                        p [] [createText @"So here, we can start to match the bind listed in the code to how it is described in the documentation. The first term after the bind command is ‘join’, showing that it is a join bind, which means the action we define here will take place each time a user joins a channel. The next term is ‘mask’, and it says it is in the form “#channel nick!user@host”. This is where we can start to refine exactly when this bind is triggered. If we want it to work for every person joining every channel Eggdrop is on, then a simple ‘*’ will suffice here- that will match everything. If we wanted this bind to only work in #foo, then the mask would be “#foo *”. If we wanted to greet users on every channel, but only those who are on AOL, the mask would be “* *@*.aol.com”. Finally the ‘proc’ argument is the name of the Tcl proc we want to call, where the code that actually \emph{does stuff} is located."]
                                        p [] [createText "So to sum up this line from the example script: When a user joins on any channel and with any hostmask, run the code located in proc ‘greet’."]
                                        p [] [createText "Now that we told the Eggdrop what action to look for, we need to tell it what to do when that action occurs!:"]
                                        pre [("class", "highlight-default notranslate")] [
                                            div [("class", "highlight")] [
                                                createRaw @"<pre><span></span><span class=""n"">proc</span> <span class=""n"">greet</span> <span class=""p"">{</span><span class=""n"">nick</span> <span class=""n"">uhost</span> <span class=""n"">hand</span> <span class=""n"">chan</span><span class=""p"">}</span> <span class=""p"">{</span>
</pre>"
                                            ]
                                        ]
                                        p [] [createText @"This is how we declare a Tcl proc. As we said above, this is where the magic happens. To set up the proc (this will look differently for different binds), lets refer back to the bind JOIN documentation. The second line shows \code{procname <nick> <user@host> <handle> <channel>}. Eggdrop does a lot of stuff in the background when a bind is triggered, and this is telling you how Eggdrop will present that information to you. Here, Eggdrop is telling you it is going to pass the proc you created four variables: One that contains the nickname of the person who triggered the bind (in this case, the user who joined), the user@host of that user, the handle of that user (if the user has one on the bot), and the channel that the bind was triggered on."]
                                        p [] [createText @"So let’s say someone with the nickname Geo with a hostmask of awesome@aol.com joined #sexystuff and that person is not added to the bot as a user. Eggdrop will pass 4 values to the variables you set up in that proc: The first variable will get the value “Geo”, the second “awesome@aol.com”, the third “*”, and the fourth “#sexystuff”. (That third value was a trick, we didn’t talk about that- if the user is not added to the bot, handle will get a “*” as a value). Now, let’s use those variables!:"]
                                        pre [("class", "highlight-default notranslate")] [
                                            div [("class", "highlight")] [
                                                createRaw @"<pre><span></span><span class=""k"">global</span> <span class=""n"">pmsg</span>
<span class=""k"">global</span> <span class=""n"">greetmsg</span>
</pre>"
                                            ]
                                        ]
                                        p [] [createText "This is a simple one- because we’re using variables declared in the main body of the script (remember way up top?), we have to tell this proc to use that variable, not not create a new local variable for this proc."]
                                        p [] [createText "And finally, let’s actually send a message to the user:"]
                                        pre [("class", "highlight-default notranslate")] [
                                            div [("class", "highlight")] [
                                                createRaw @"<pre><span></span><span class=""k"">if</span> <span class=""p"">{</span><span class=""n"">pmsg</span><span class=""p"">}</span>
  <span class=""n"">putserv</span> <span class=""s2"">""PRIVMSG $nick :$greetmsg""</span>
<span class=""p"">}</span> <span class=""k"">else</span> <span class=""p"">{</span>
  <span class=""n"">putserv</span> <span class=""s2"">""PRIVMSG $chan :$greetmsg""</span>
<span class=""p"">}</span>
</pre>"
                                            ]
                                        ]
                                        p [] [createText @"Here, we’re going to check if pmsg is true (any value that is not 0) and, if yes, send a private message to the user. If pmsg is not true (it is 0), then we will send the message to the channel. You can see that the first putserv message sends a PRIVMSG message to $nick - this is the nickname of the user that joined, and that Eggdrop stored for us in the first variable of the proc, which we called ‘nick’. The second putserv message will send a PRIVMSG message to the $chan - this is the channel the user joined, and that Eggdrop stored for us in the fourth variable of the proc, which we called ‘chan’."]
                                        p [] [createText "And finally: get the credit you deserve when the script loads!:"]
                                        pre [("class", "highlight-default notranslate")] [
                                            div [("class", "highlight")] [
                                                createRaw @"<pre><span></span><span class=""n"">putlog</span> <span class=""s2"">""greetscript.tcl v1.0 by Geo""</span>
</pre>"
                                            ]
                                        ]
                                        p [] [createText "Like your variables at the top of the script, this line is not inside a Tcl proc and will execute when the script is loaded. You can put this or any other initialization code you want to run."]
                                        p [] [createText "And there you have it- your first script! Take this, modify it and experiment. A few challenges for you:"]
                                        createRaw @"
<ul class=""simple"">
<li><p>How can you configure which channel it should run on, without hard-coding it into the bind? (Maybe with a variable…)</p></li>
<li><p>How can you configure it to only message a user with the nickname “FancyPants”? (Sounds like something a bind could handle)</p></li>
<li><p>How can you delay the message from sending by 5 seconds? (Hint: utimer)</p></li>
<li><p>How can you send different messages to different channels? (A new setting may be in order…)</p></li>
<li><p>How can you get the bot to not greet itself when it joins the channel? (Eggdrop stores its own nickname in a variable called $botnick)</p></li>
<li><p>How can you add the person joining the channel’s nickname to the greet message? (You can put variables inside variables…)</p></li>
</ul>"
                                        p [] [createText "If you want to try these out, join #eggdrop on Libera and check your answers (and remember, there are dozens of ways to do this, so a) don’t be defensive of your choices, and b) take others’ answers with a grain of salt!)"]
                                        p [] [createText "Copyright (C) 2003 - 2025 Eggheads Development Team"]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
                div [("class", "clearer")] []
            ]
            div [("class", "footer-wrapper")] [
                div [("class", "footer")] [
                    div [("class", "left")] [
                        div [("role", "navigation"); ("aria-label", "related navigaton")] [
                            a [("href", "userfilesharing.html"); ("title", "Sharing Userfiles")] [
                                createText "previous"
                            ]
                            createText " | "
                            a [("href", "module.html"); ("title", "Writing a Basic Eggdrop Module")] [
                                createText "next"
                            ]
                        ]
                        div [("role", "note"); ("aria-label", "source link")] []
                    ]
                    div [("class", "right")] [
                        div [("class", "footer"); ("role", "contentinfo")] [
                            createRaw "&#169; Copyright 2025, Eggheads."
                            createText "      Last updated on Aug 15, 2025."
                            createText "      Created using "
                            a [("href", "https://www.sphinx-doc.org/")] [createText "Sphinx"]
                            createText " 8.2.3."
                        ]
                    ]
                    div [("class", "clearer")] []
                ]
            ]
        ]
    ]

[<EntryPoint>]
let main args =
    let html = generateHtml()
    let content = doctype + "\n" + renderElement html
    match args with
    | [|filename|] -> 
        File.WriteAllText(filename, content)
        0
    | _ -> 
        printfn "Usage: firstscript <output-file>"
        1
