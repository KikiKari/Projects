#!/usr/bin/env node
// firstscript.html — portiert nach javascript
// Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/eggdrop/firstscript.html
// auch in: OpenClaw@gateway2:skills/scripting-utils/references/eggdrop/firstscript.html
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import path from 'path';

function createDocument() {
  const doc = {
    doctype: '<!DOCTYPE html>',
    html: {
      attrs: { lang: 'en', 'data-content_root': '../' },
      head: createHead(),
      body: createBody()
    }
  };
  return doc;
}

function createHead() {
  return {
    meta: [
      { charset: 'utf-8' },
      { name: 'viewport', content: 'width=device-width, initial-scale=1.0' },
      { name: 'viewport', content: 'width=device-width, initial-scale=1' }
    ],
    title: 'Writing an Eggdrop Tcl Script — Eggdrop 1.10.1rc2 documentation',
    link: [
      { rel: 'stylesheet', type: 'text/css', href: '../_static/pygments.css?v=03e43079' },
      { rel: 'stylesheet', type: 'text/css', href: '../_static/eggdrop.css?v=ab48a1b6' },
      { rel: 'search', title: 'Search', href: '../search.html' },
      { rel: 'next', title: 'Writing a Basic Eggdrop Module', href: 'module.html' },
      { rel: 'prev', title: 'Sharing Userfiles', href: 'userfilesharing.html' }
    ],
    script: [
      { src: '../_static/documentation_options.js?v=290de6c6' },
      { src: '../_static/doctools.js?v=9bcbadda' },
      { src: '../_static/sphinx_highlight.js?v=dc90522c' }
    ]
  };
}

function createBody() {
  return {
    'div.header-wrapper': {
      attrs: { role: 'banner' },
      'div.header': {
        'div.headertitle': {
          a: { attrs: { href: '../index.html' }, text: 'Eggdrop 1.10.1rc2 documentation' }
        },
        'div.rel': {
          attrs: { role: 'navigation', 'aria-label': 'related navigation' },
          a: [
            { attrs: { href: 'userfilesharing.html', title: 'Sharing Userfiles', accesskey: 'P' }, text: 'previous' },
            { attrs: { href: 'module.html', title: 'Writing a Basic Eggdrop Module', accesskey: 'N' }, text: 'next' }
          ]
        }
      }
    },
    'div.content-wrapper': {
      'div.content': {
        'div.sidebar': createSidebar(),
        'div.document': {
          'div.documentwrapper': {
            'div.bodywrapper': {
              'div.body': {
                attrs: { role: 'main' },
                'section#writing-an-eggdrop-tcl-script': createMainContent()
              }
            }
          }
        }
      }
    },
    'div.footer-wrapper': createFooter()
  };
}

function createSidebar() {
  return {
    h3: 'Table of Contents',
    'p.caption': { attrs: { role: 'heading' }, span: { attrs: { class: 'caption-text' }, text: 'Installing Eggdrop' } },
    'ul.toctree-l1': [
      { a: { attrs: { class: 'reference internal', href: '../install/readme.html' }, text: 'README' } },
      { a: { attrs: { class: 'reference internal', href: '../install/install.html' }, text: 'Installing Eggdrop' } },
      { a: { attrs: { class: 'reference internal', href: '../install/upgrading.html' }, text: 'Upgrading Eggdrop' } }
    ],
    'p.caption.2': { attrs: { role: 'heading' }, span: { attrs: { class: 'caption-text' }, text: 'Using Eggdrop' } },
    'ul.toctree-l1.2': [
      { a: { attrs: { class: 'reference internal', href: '../using/features.html' }, text: 'Eggdrop Features' } },
      { a: { attrs: { class: 'reference internal', href: '../using/core.html' }, text: 'Eggdrop Core Settings' } },
      { a: { attrs: { class: 'reference internal', href: '../using/partyline.html' }, text: 'The Party Line' } },
      { a: { attrs: { class: 'reference internal', href: '../using/autoscripts.html' }, text: 'Eggdrop Autoscripts' } },
      { a: { attrs: { class: 'reference internal', href: '../using/users.html' }, text: 'Users and Flags' } },
      { a: { attrs: { class: 'reference internal', href: '../using/bans.html' }, text: 'Bans, Invites, and Exempts' } },
      { a: { attrs: { class: 'reference internal', href: '../using/botnet.html' }, text: 'Botnet Sharing and Linking' } },
      { a: { attrs: { class: 'reference internal', href: '../using/ipv6.html' }, text: 'IPv6 support' } },
      { a: { attrs: { class: 'reference internal', href: '../using/tls.html' }, text: 'TLS support' } },
      { a: { attrs: { class: 'reference internal', href: '../using/ircv3.html' }, text: 'IRCv3 support' } },
      { a: { attrs: { class: 'reference internal', href: '../using/accounts.html' }, text: 'Account tracking in Eggdrop' } },
      { a: { attrs: { class: 'reference internal', href: '../using/pbkdf2info.html' }, text: 'Encryption/Hashing' } },
      { a: { attrs: { class: 'reference internal', href: '../using/python.html' }, text: 'Using the Python Module' } },
      { a: { attrs: { class: 'reference internal', href: '../using/twitchinfo.html' }, text: 'Twitch' } },
      { a: { attrs: { class: 'reference internal', href: '../using/tricks.html' }, text: 'Advanced Tips' } },
      { a: { attrs: { class: 'reference internal', href: '../using/text-sub.html' }, text: 'Textfile Substitutions' } },
      { a: { attrs: { class: 'reference internal', href: '../using/tcl-commands.html' }, text: 'Eggdrop Tcl Commands' } },
      { a: { attrs: { class: 'reference internal', href: '../using/twitch-tcl-commands.html' }, text: 'Eggdrop Twitch Tcl Commands' } },
      { a: { attrs: { class: 'reference internal', href: '../using/patch.html' }, text: 'Patching Eggdrop' } }
    ],
    'p.caption.3': { attrs: { role: 'heading' }, span: { attrs: { class: 'caption-text' }, text: 'Tutorials' } },
    'ul.current': [
      { a: { attrs: { class: 'reference internal', href: 'setup.html' }, text: 'Setting Up Eggdrop' } },
      { a: { attrs: { class: 'reference internal', href: 'firststeps.html' }, text: 'Common First Steps' } },
      { a: { attrs: { class: 'reference internal', href: 'tlssetup.html' }, text: 'Enabling TLS Security on Eggdrop' } },
      { a: { attrs: { class: 'reference internal', href: 'userfilesharing.html' }, text: 'Sharing Userfiles' } },
      { a: { attrs: { class: 'current reference internal', href: '#' }, text: 'Writing an Eggdrop Tcl Script' } },
      { a: { attrs: { class: 'reference internal', href: 'module.html' }, text: 'Writing a Basic Eggdrop Module' } }
    ],
    'p.caption.4': { attrs: { role: 'heading' }, span: { attrs: { class: 'caption-text' }, text: 'Eggdrop Modules' } },
    'ul.toctree-l1.3': [
      { a: { attrs: { class: 'reference internal', href: '../modules/index.html' }, text: 'Eggdrop Module Information' } },
      { a: { attrs: { class: 'reference internal', href: '../modules/included.html' }, text: 'Modules included with Eggdrop' } },
      { a: { attrs: { class: 'reference internal', href: '../modules/writing.html' }, text: 'How to Write an Eggdrop Module' } },
      { a: { attrs: { class: 'reference internal', href: '../modules/internals.html' }, text: 'Eggdrop Bind Internals' } }
    ],
    'p.caption.5': { attrs: { role: 'heading' }, span: { attrs: { class: 'caption-text' }, text: 'About Eggdrop' } },
    'ul.toctree-l1.4': [
      { a: { attrs: { class: 'reference internal', href: '../about/about.html' }, text: 'About Eggdrop' } },
      { a: { attrs: { class: 'reference internal', href: '../about/legal.html' }, text: 'Boring legal stuff' } }
    ],
    'div[role="search"]': {
      h3: { attrs: { style: 'margin-top: 1.5em;' }, text: 'Search' },
      form: {
        attrs: { class: 'search', action: '../search.html', method: 'get' },
        input: [
          { attrs: { type: 'text', name: 'q' } },
          { attrs: { type: 'submit', value: 'Go' } }
        ]
      }
    }
  };
}

function createMainContent() {
  return {
    h1: { text: 'Writing an Eggdrop Tcl Script', a: { attrs: { class: 'headerlink', href: '#writing-an-eggdrop-tcl-script', title: 'Link to this heading' }, text: '¶' } },
    p: [
      'So you want to write an Eggdrop Tcl script, but you don’t really know where to begin. This file will give you a very basic idea about what Eggdrop scripting is like, using a very simple script that may help you get started with your own scripts.',
      'This guide assumes you know a bit about Eggdrops and IRC. You should have already installed Eggdrop. The bot should not be on any important or busy channels (development bots can be annoying if your script has bugs). If you plan on doing a lot of development, enable the .tcl and .set commands, and make sure nobody else has access to your bot. The .tcl and .set commands are helpful in debugging and testing your code.',
      'First, read through the script. Very few commands are listed here intentionally, but as you want to develop more advanced scripts, you will definitely want to get familiar with the ',
      { a: { attrs: { class: 'reference external', href: 'https://www.tcl.tk/man/tcl8.6/TclCmd/contents.htm' }, text: 'core Tcl language commands' } },
      ', especially the string- and list-related commands, as well as Eggdrop’s own library of custom Tcl commands, located in ',
      { a: { attrs: { class: 'reference external', href: 'https://docs.eggheads.org/using/tcl-commands.html' }, text: 'tcl-commands.doc' } }
    ],
    p2: 'If you have the .tcl command enabled, you can load a script by typing \'.tcl source script/file.tcl\' to load it. Otherwise, add it to your config file like normal (examples to do so are at the bottom of the config file) and \'.rehash\' or \'.restart\' your bot.',
    p3: 'Let’s look at a very basic example script that greets users as they join a channel:',
    'div.highlight-default.notranslate': {
      'div.highlight': {
        pre: `# GreetScript.tcl
# Version: 1.0
# Author: Geo <geo@eggheads.org>
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
set greetmsg "Hi! Welcome to the channel!"
### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING! ###

bind join - * greet

proc greet {nick uhost hand chan} {
  global pmsg
  global greetmsg
  if {$pmsg} {
    putserv "PRIVMSG $nick :$greetmsg"
  } else {
    putserv "PRIVMSG $chan :$greetmsg"
  }
}

putlog "greetscript.tcl v1.0 by Geo"`
      }
    },
    p4: 'Whew! There’s a lot going on here. You’ll generally see scripts broken into a few key parts- the header, the config section, and the code section. Ok, let’s go over this piece by piece. First, the header of the script:',
    'div.highlight-default.notranslate.2': {
      'div.highlight': {
        pre: `# GreetScript.tcl
# Version: 1.0
# Author: Geo <geo@eggheads.org> or #eggdrop on Libera
#
# Description:
# A simple script that greets users as they join a channel`
      }
    },
    p5: 'Any line prefixed by a # means it is comment, and thus ignored. You can type whatever you want, and it won’t matter. When writing scripts (especially if you want to give them to other people, it is good to use comments in the code to show what you’re doing. Here though, we use it to describe what the script is and, most importantly, who wrote it! Let’s give credit where credit is due, right? You may want to give users a way to contact you as well.',
    p6: 'Next, let’s look at the configuration section:',
    'div.highlight-default.notranslate.3': {
      'div.highlight': {
        pre: `### Config Section ###
# How would you like the bot to gree users?
# 0 - via public message to channel
# 1 - via private message
set pmsg 0
# What message would you like to send to users when they join?
set greetmsg "Hi! Welcome to the channel!"
### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING! ###`
      }
    },
    p7: 'To make scripts easy to use, you’ll want to have a section that allows users to easily change the way the script operates, without having to edit the script itself. Here, we have two settings: one that controls which method the Eggdrop uses to greet a user, and a second with the message to greet the user with. Sure, we could hard-code that into the code section below, but in larger scripts that makes things harder to find, and also forces you to potentially have to make the same change multiple times in code. Why not make it simple and do it once, up top? Notice the settings do not have #s in front of them- they are variables that will be used by the script later on. And of course, the standard ominous warning not to change anything below!',
    p8: 'Now, let’s look start to dissect the actual code!:',
    'div.highlight-default.notranslate.4': {
      'div.highlight': {
        pre: 'bind join - * greet'
      }
    },
    p9: 'This is a bind. This sets up an action that Eggdrop will react to. You can read ',
    a: { attrs: { class: 'reference external', href: 'https://docs.eggheads.org/using/tcl-commands.html' }, text: 'all the binds that Eggdrop uses here.' },
    p10: 'Generally, we like to place all binds towards the top of the script so that they are together and easy to find. Now, let’s look at documentation of the bind join together.',
    'table.docutils.align-default': {
      thead: {
        tr: {
          th: { attrs: { class: 'head', colspan: '2' }, text: 'bind JOIN' }
        }
      },
      tbody: {
        tr: [
          { td: { attrs: { colspan: '2' }, text: 'bind join <flags> <mask> <proc>' } },
          { td: { attrs: { colspan: '2' }, text: 'procname <nick> <user@host> <handle> <channel>' } },
          { td: { attrs: { colspan: '2' }, text: 'Description: triggered by someone joining the channel. The mask in the bind is matched against "#channel nick!user@host" and can contain wildcards.' } }
        ]
      }
    },
    p11: 'So here, we can start to match the bind listed in the code to how it is described in the documentation. The first term after the bind command is ‘join’, showing that it is a join bind, which means the action we define here will take place each time a user joins a channel. The next term is ‘mask’, and it says it is in the form "#channel nick!user@host". This is where we can start to refine exactly when this bind is triggered. If we want it to work for every person joining every channel Eggdrop is on, then a simple ‘*’ will suffice here- that will match everything. If we wanted this bind to only work in #foo, then the mask would be "#foo *". If we wanted to greet users on every channel, but only those who are on AOL, the mask would be "* *@*.aol.com". Finally the ‘proc’ argument is the name of the Tcl proc we want to call, where the code that actually does stuff is located.',
    p12: 'So to sum up this line from the example script: When a user joins on any channel and with any hostmask, run the code located in proc ‘greet’.',
    p13: 'Now that we told the Eggdrop what action to look for, we need to tell it what to do when that action occurs!:',
    'div.highlight-default.notranslate.5': {
      'div.highlight': {
        pre: 'proc greet {nick uhost hand chan} {'
      }
    },
    p14: 'This is how we declare a Tcl proc. As we said above, this is where the magic happens. To set up the proc (this will look differently for different binds), lets refer back to the bind JOIN documentation. The second line shows procname <nick> <user@host> <handle> <channel>. Eggdrop does a lot of stuff in the background when a bind is triggered, and this is telling you how Eggdrop will present that information to you. Here, Eggdrop is telling you it is going to pass the proc you created four variables: One that contains the nickname of the person who triggered the bind (in this case, the user who joined), the user@host of that user, the handle of that user (if the user has one on the bot), and the channel that the bind was triggered on.',
    p15: 'So let’s say someone with the nickname Geo with a hostmask of awesome@aol.com joined #sexystuff and that person is not added to the bot as a user. Eggdrop will pass 4 values to the variables you set up in that proc: The first variable will get the value "Geo", the second "awesome@aol.com", the third "*", and the fourth "#sexystuff". (That third value was a trick, we didn’t talk about that- if the user is not added to the bot, handle will get a "*" as a value). Now, let’s use those variables!:',
    'div.highlight-default.notranslate.6': {
      'div.highlight': {
        pre: `global pmsg
global greetmsg`
      }
    },
    p16: 'This is a simple one- because we’re using variables declared in the main body of the script (remember way up top?), we have to tell this proc to use that variable, not not create a new local variable for this proc.',
    p17: 'And finally, let’s actually send a message to the user:',
    'div.highlight-default.notranslate.7': {
      'div.highlight': {
        pre: `if {\$pmsg}
  putserv "PRIVMSG \$nick :\$greetmsg"
} else {
  putserv "PRIVMSG \$chan :\$greetmsg"
}`
      }
    },
    p18: 'Here, we’re going to check if pmsg is true (any value that is not 0) and, if yes, send a private message to the user. If pmsg is not true (it is 0), then we will send the message to the channel. You can see that the first putserv message sends a PRIVMSG message to $nick - this is the nickname of the user that joined, and that Eggdrop stored for us in the first variable of the proc, which we called ‘nick’. The second putserv message will send a PRIVMSG message to the $chan - this is the channel the user joined, and that Eggdrop stored for us in the fourth variable of the proc, which we called ‘chan’.',
    p19: 'And finally: get the credit you deserve when the script loads!:',
    'div.highlight-default.notranslate.8': {
      'div.highlight': {
        pre: 'putlog "greetscript.tcl v1.0 by Geo"'
      }
    },
    p20: 'Like your variables at the top of the script, this line is not inside a Tcl proc and will execute when the script is loaded. You can put this or any other initialization code you want to run.',
    p21: 'And there you have it- your first script! Take this, modify it and experiment. A few challenges for you:',
    ul: {
      li: [
        'How can you configure which channel it should run on, without hard-coding it into the bind? (Maybe with a variable…)',
        'How can you configure it to only message a user with the nickname "FancyPants"? (Sounds like something a bind could handle)',
        'How can you delay the message from sending by 5 seconds? (Hint: utimer)',
        'How can you send different messages to different channels? (A new setting may be in order…)',
        'How can you get the bot to not greet itself when it joins the channel? (Eggdrop stores its own nickname in a variable called $botnick)',
        'How can you add the person joining the channel’s nickname to the greet message? (You can put variables inside variables…)'
      ]
    },
    p22: 'If you want to try these out, join #eggdrop on Libera and check your answers (and remember, there are dozens of ways to do this, so a) don’t be defensive of your choices, and b) take others’ answers with a grain of salt!)',
    p23: 'Copyright (C) 2003 - 2025 Eggheads Development Team'
  };
}

function createFooter() {
  return {
    'div.footer': {
      'div.left': {
        'div[role="navigation"]': {
          attrs: { 'aria-label': 'related navigaton' },
          a: [
            { attrs: { href: 'userfilesharing.html', title: 'Sharing Userfiles' }, text: 'previous' },
            { attrs: { href: 'module.html', title: 'Writing a Basic Eggdrop Module' }, text: 'next' }
          ]
        },
        'div[role="note"]': { attrs: { 'aria-label': 'source link' } }
      },
      'div.right': {
        'div.footer': {
          attrs: { role: 'contentinfo' },
          text: '© Copyright 2025, Eggheads. Last updated on Aug 15, 2025. Created using Sphinx 8.2.3.'
        }
      }
    }
  };
}

function renderElement(tag, element, indent = '') {
  if (element === undefined || element === null) return '';
  
  let result = '';
  const nextIndent = indent + '  ';
  
  // Handle special tag syntax with attributes
  let tagName = tag;
  let attrs = '';
  
  if (tag.includes('.')) {
    const parts = tag.split('.');
    tagName = parts[0];
    for (let i = 1; i < parts.length; i++) {
      if (parts[i].includes('#')) {
        const [cls, id] = parts[i].split('#');
        attrs += ` class="${cls}" id="${id}"`;
      } else if (parts[i].startsWith('#')) {
        attrs += ` id="${parts[i].substring(1)}"`;
      } else {
        attrs += ` class="${parts[i]}"`;
      }
    }
  } else if (tag.includes('#')) {
    const [tagPart, idPart] = tag.split('#');
    tagName = tagPart;
    attrs += ` id="${idPart}"`;
  }

  // Handle attributes in the element object
  if (element.attrs) {
    for (const [key, value] of Object.entries(element.attrs)) {
      attrs += ` ${key}="${value}"`;
    }
  }

  result += `${indent}<${tagName}${attrs ? ' ' + attrs.trim() : ''}`;
  
  // Handle text content and children
  const hasChildren = typeof element === 'object' && Object.keys(element).some(key => key !== 'attrs' && key !== 'text');
  const hasText = element.text || typeof element === 'string';
  
  if (!hasChildren && !hasText) {
    result += ' />\n';
    return result;
  }
  
  result += '>';
  
  if (hasText) {
    const text = element.text || element;
    result += text;
  }
  
  if (hasChildren) {
    result += '\n';
    for (const [childTag, childElement] of Object.entries(element)) {
      if (childTag === 'attrs' || childTag === 'text') continue;
      
      // Handle arrays of elements with same tag
      if (Array.isArray(childElement)) {
        for (const item of childElement) {
          result += renderElement(childTag, item, nextIndent);
        }
      } else {
        result += renderElement(childTag, childElement, nextIndent);
      }
    }
    result += `${indent}</${tagName}>\n`;
  } else {
    result += `</${tagName}>\n`;
  }
  
  return result;
}

function renderDocument(doc) {
  let html = doc.doctype + '\n';
  html += '<html';
  for (const [key, value] of Object.entries(doc.html.attrs)) {
    html += ` ${key}="${value}"`;
  }
  html += '>\n';
  
  // Render head
  html += '  <head>\n';
  for (const meta of doc.html.head.meta) {
    html += '    <meta';
    for (const [key, value] of Object.entries(meta)) {
      html += ` ${key}="${value}"`;
    }
    html += ' />\n';
  }
  html += `    <title>${doc.html.head.title}</title>\n`;
  for (const link of doc.html.head.link) {
    html += '    <link';
    for (const [key, value] of Object.entries(link)) {
      html += ` ${key}="${value}"`;
    }
    html += ' />\n';
  }
  for (const script of doc.html.head.script) {
    html += '    <script';
    for (const [key, value] of Object.entries(script)) {
      html += ` ${key}="${value}"`;
    }
    html += '></script>\n';
  }
  html += '  </head>\n';
  
  // Render body
  html += renderElement('body', doc.html.body, '  ');
  
  html += '</html>\n';
  
  return html;
}

// Main execution
if (process.argv.length < 3) {
  console.error('Usage: node script.js <output-file>');
  process.exit(1);
}

const outputFile = process.argv[2];
const document = createDocument();
const htmlOutput = renderDocument(document);

fs.writeFileSync(outputFile, htmlOutput);
console.log(`HTML document written to ${outputFile}`);
