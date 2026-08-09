#!/usr/bin/env tclsh
# index.html — portiert nach tcl
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/eggdrop/index.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/eggdrop/index.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Tcl script to generate index.html for Eggdrop documentation

proc generate_html {filename} {
    set fp [open $filename w]
    
    # Write DOCTYPE and html start
    puts $fp {<!DOCTYPE html>}
    puts $fp {}
    puts $fp {<html lang="en" data-content_root="./">}
    
    # Head section
    puts $fp {  <head>}
    puts $fp {    <meta charset="utf-8" />}
    puts $fp {    <meta name="viewport" content="width=device-width, initial-scale=1.0" /><meta name="viewport" content="width=device-width, initial-scale=1" />}
    puts $fp {}
    puts $fp {    <title>Eggdrop, an open source IRC bot &#8212; Eggdrop 1.10.1 documentation</title>}
    puts $fp {    <link rel="stylesheet" type="text/css" href="_static/pygments.css?v=03e43079" />}
    puts $fp {    <link rel="stylesheet" type="text/css" href="_static/eggdrop.css?v=ab48a1b6" />}
    puts $fp {    <script src="_static/documentation_options.js?v=290de6c6"></script>}
    puts $fp {    <script src="_static/doctools.js?v=9bcbadda"></script>}
    puts $fp {    <script src="_static/sphinx_highlight.js?v=dc90522c"></script>}
    puts $fp {    <link rel="search" title="Search" href="search.html" />}
    puts $fp {    <link rel="next" title="README" href="install/readme.html" />} 
    puts $fp {  </head>}
    puts $fp {<body>}
    
    # Header wrapper
    puts $fp {    <div class="header-wrapper" role="banner">}
    puts $fp {      <div class="header">}
    puts $fp {        <div class="headertitle"><a}
    puts $fp {          href="#">Eggdrop 1.10.1 documentation</a></div>}
    puts $fp {        <div class="rel" role="navigation" aria-label="related navigation">}
    puts $fp {          <a href="install/readme.html" title="README"}
    puts $fp {             accesskey="N">next</a>}
    puts $fp {        </div>}
    puts $fp {       </div>}
    puts $fp {    </div>}
    puts $fp {}
    
    # Content wrapper
    puts $fp {    <div class="content-wrapper">}
    puts $fp {      <div class="content">}
    puts $fp {        <div class="sidebar">}
    puts $fp {}
    puts $fp {          <h3>Table of Contents</h3>}
    
    # Installing Eggdrop section
    puts $fp {          <p class="caption" role="heading"><span class="caption-text">Installing Eggdrop</span></p>}
    puts $fp {<ul>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="install/readme.html">README</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="install/install.html">Installing Eggdrop</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="install/upgrading.html">Upgrading Eggdrop</a></li>}
    puts $fp {</ul>}
    
    # Using Eggdrop section
    puts $fp {<p class="caption" role="heading"><span class="caption-text">Using Eggdrop</span></p>}
    puts $fp {<ul>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/features.html">Eggdrop Features</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/core.html">Eggdrop Core Settings</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/partyline.html">The Party Line</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/autoscripts.html">Eggdrop Autoscripts</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/users.html">Users and Flags</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/bans.html">Bans, Invites, and Exempts</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/botnet.html">Botnet Sharing and Linking</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/ipv6.html">IPv6 support</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/tls.html">TLS support</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/ircv3.html">IRCv3 support</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/accounts.html">Account tracking in Eggdrop</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/pbkdf2info.html">Encryption/Hashing</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/python.html">Using the Python Module</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/twitchinfo.html">Twitch</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/tricks.html">Advanced Tips</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/text-sub.html">Textfile Substitutions</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/tcl-commands.html">Eggdrop Tcl Commands</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/twitch-tcl-commands.html">Eggdrop Twitch Tcl Commands</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/patch.html">Patching Eggdrop</a></li>}
    puts $fp {</ul>}
    
    # Tutorials section
    puts $fp {<p class="caption" role="heading"><span class="caption-text">Tutorials</span></p>}
    puts $fp {<ul>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="tutorials/setup.html">Setting Up Eggdrop</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="tutorials/firststeps.html">Common First Steps</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="tutorials/tlssetup.html">Enabling TLS Security on Eggdrop</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="tutorials/userfilesharing.html">Sharing Userfiles</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="tutorials/firstscript.html">Writing an Eggdrop Tcl Script</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="tutorials/module.html">Writing a Basic Eggdrop Module</a></li>}
    puts $fp {</ul>}
    
    # Eggdrop Modules section
    puts $fp {<p class="caption" role="heading"><span class="caption-text">Eggdrop Modules</span></p>}
    puts $fp {<ul>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="modules/index.html">Eggdrop Module Information</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="modules/included.html">Modules included with Eggdrop</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="modules/writing.html">How to Write an Eggdrop Module</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="modules/internals.html">Eggdrop Bind Internals</a></li>}
    puts $fp {</ul>}
    
    # About Eggdrop section
    puts $fp {<p class="caption" role="heading"><span class="caption-text">About Eggdrop</span></p>}
    puts $fp {<ul>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="about/about.html">About Eggdrop</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="about/legal.html">Boring legal stuff</a></li>}
    puts $fp {</ul>}
    puts $fp {}
    
    # Search form
    puts $fp {          <div role="search">}
    puts $fp {            <h3 style="margin-top: 1.5em;">Search</h3>}
    puts $fp {            <form class="search" action="search.html" method="get">}
    puts $fp {                <input type="text" name="q" />}
    puts $fp {                <input type="submit" value="Go" />}
    puts $fp {            </form>}
    puts $fp {          </div>}
    puts $fp {}
    puts $fp {        </div>}
    
    # Document section
    puts $fp {        <div class="document">}
    puts $fp {}
    puts $fp {      <div class="documentwrapper">}
    puts $fp {        <div class="bodywrapper">}
    puts $fp {          <div class="body" role="main">}
    puts $fp {}
    puts $fp {  <section id="eggdrop-an-open-source-irc-bot">}
    puts $fp {<h1>Eggdrop, an open source IRC bot<a class="headerlink" href="#eggdrop-an-open-source-irc-bot" title="Link to this heading">¶</a></h1>}
    puts $fp {<p>Eggdrop is a free, open source software program built to assist in managing an IRC channel. It is the world’s oldest actively-maintained IRC bot and was designed to be easily used and expanded on via it’s ability to run Tcl scripts. Eggdrop can join IRC channels and perorm automated tasks such as protecting the channel from abuse, assisting users obtain their op/voice status, provide information and greetings, host games, etc.</p>}
    
    # Some things you can do with Eggdrop
    puts $fp {<section id="some-things-you-can-do-with-eggdrop">}
    puts $fp {<h2>Some things you can do with Eggdrop<a class="headerlink" href="#some-things-you-can-do-with-eggdrop" title="Link to this heading">¶</a></h2>}
    puts $fp {<p>Eggdrop has a large number of features, such as:</p>}
    puts $fp {<ul class="simple">}
    puts $fp {<li><p><a class="reference external" href="using/users.html">Channel Management</a></p></li>}
    puts $fp {<li><p>Running Tcl Scripts</p></li>}
    puts $fp {<li><p><a class="reference external" href="using/ircv3.html">Integration of the most current IRCv3 capabilities</a></p></li>}
    puts $fp {<li><p><a class="reference external" href="using/botnet.html">The ability to link multiple Eggdrops together and share userfiles</a></p></li>}
    puts $fp {<li><p><a class="reference external" href="using/tls.html">TLS Support</a></p></li>}
    puts $fp {<li><p><a class="reference external" href="using/ipv6.html">IPv6 Support</a></p></li>}
    puts $fp {<li><p><a class="reference external" href="using/twitchinfo.html">Twitch Support</a></p></li>}
    puts $fp {<li><p>… and much much more!</p></li>}
    puts $fp {</ul>}
    puts $fp {</section>}
    
    # How to get Eggdrop
    puts $fp {<section id="how-to-get-eggdrop">}
    puts $fp {<h2>How to get Eggdrop<a class="headerlink" href="#how-to-get-eggdrop" title="Link to this heading">¶</a></h2>}
    puts $fp {<p>The Eggdrop project source code is hosted at <a class="reference external" href="https://github.com/eggheads/eggdrop">https://github.com/eggheads/eggdrop</a>. You can clone it via git, or alternatively a copy of the current stable snapshot is located at <a class="reference external" href="https://geteggdrop.com">https://geteggdrop.com</a>. Additional information can be found on the official Eggdrop webpage at <a class="reference external" href="https://www.eggheads.org">https://www.eggheads.org</a>. For more information, see <a class="reference external" href="install/install.html">Installing Eggdrop</a></p>}
    puts $fp {</section>}
    
    # How to install Eggdrop
    puts $fp {<section id="how-to-install-eggdrop">}
    puts $fp {<h2>How to install Eggdrop<a class="headerlink" href="#how-to-install-eggdrop" title="Link to this heading">¶</a></h2>}
    
    # Installation Pre-requisites
    puts $fp {<section id="installation-pre-requisites">}
    puts $fp {<h3>Installation Pre-requisites<a class="headerlink" href="#installation-pre-requisites" title="Link to this heading">¶</a></h3>}
    puts $fp {<p>Eggdrop requires Tcl (and its development header files) to be present on the system it is compiled on. It is also strongly encouraged to install openssl (and its development header files) to enable TLS-protected network communication.</p>}
    puts $fp {</section>}
    
    # Installation
    puts $fp {<section id="installation">}
    puts $fp {<h3>Installation<a class="headerlink" href="#installation" title="Link to this heading">¶</a></h3>}
    puts $fp {<p>A guide to quickly installing Eggdrop can be found here.</p>}
    puts $fp {</section>}
    puts $fp {</section>}
    
    # Where to find more help
    puts $fp {<section id="where-to-find-more-help">}
    puts $fp {<h2>Where to find more help<a class="headerlink" href="#where-to-find-more-help" title="Link to this heading">¶</a></h2>}
    puts $fp {<p>The Eggheads development team can be found lurking on #eggdrop on the Libera network (irc.libera.chat).</p>}
    
    # Installing Eggdrop TOC
    puts $fp {<div class="toctree-wrapper compound">}
    puts $fp {<p class="caption" role="heading"><span class="caption-text">Installing Eggdrop</span></p>}
    puts $fp {<ul>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="install/readme.html">README</a><ul>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="install/readme.html#notice">Notice</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="install/readme.html#what-is-eggdrop">What is Eggdrop?</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="install/readme.html#how-to-get-eggdrop">How to Get Eggdrop</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="install/readme.html#system-pre-requisites">System Pre-Requisites</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="install/readme.html#minimum-requirements">Minimum Requirements</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="install/readme.html#quick-startup">Quick Startup</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="install/readme.html#upgrading">Upgrading</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="install/readme.html#command-line">Command Line</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="install/readme.html#auto-starting-eggdrop">Auto-starting Eggdrop</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="install/readme.html#documentation">Documentation</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="install/readme.html#obtaining-help">Obtaining Help</a></li>}
    puts $fp {</ul>}
    puts $fp {</li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="install/install.html">Installing Eggdrop</a><ul>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="install/install.html#quick-startup">Quick Startup</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="install/install.html#cygwin-requirements-windows">Cygwin Requirements (Windows)</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="install/install.html#modules">Modules</a></li>}
    puts $fp {</ul>}
    puts $fp {</li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="install/upgrading.html">Upgrading Eggdrop</a><ul>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="install/upgrading.html#how-to-upgrade">How to Upgrade</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="install/upgrading.html#must-read-changes-for-eggdrop-v1-10">Must-read changes for Eggdrop v1.10</a></li>}
    puts $fp {</ul>}
    puts $fp {</li>}
    puts $fp {</ul>}
    puts $fp {</div>}
    
    # Using Eggdrop TOC
    puts $fp {<div class="toctree-wrapper compound">}
    puts $fp {<p class="caption" role="heading"><span class="caption-text">Using Eggdrop</span></p>}
    puts $fp {<ul>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/features.html">Eggdrop Features</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/core.html">Eggdrop Core Settings</a><ul>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/core.html#executable-path">Executable Path</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/core.html#basic-settings">Basic Settings</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/core.html#log-files">Log Files</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/core.html#console-settings">Console Settings</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/core.html#file-and-directory-settings">File and Directory Settings</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/core.html#botnet-dcc-telnet-settings">Botnet/Dcc/Telnet Settings</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/core.html#advanced-settings">Advanced Settings</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/core.html#ssl-settings">SSL Settings</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/core.html#modules">Modules</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/core.html#scripts">Scripts</a></li>}
    puts $fp {</ul>}
    puts $fp {</li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/partyline.html">The Party Line</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/autoscripts.html">Eggdrop Autoscripts</a><ul>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/autoscripts.html#autoscripts-usage">Autoscripts usage</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/autoscripts.html#autoscripts-file-structure">Autoscripts File Structure</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/autoscripts.html#development-hints">Development hints</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/autoscripts.html#tcl-commands">Tcl Commands</a></li>}
    puts $fp {</ul>}
    puts $fp {</li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/users.html">Users and Flags</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/bans.html">Bans, Invites, and Exempts</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/botnet.html">Botnet Sharing and Linking</a><ul>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/botnet.html#what-is-a-botnet">What is a botnet?</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/botnet.html#terms">Terms</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/botnet.html#example-bottrees">Example bottrees</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/botnet.html#bot-flags">Bot Flags</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/botnet.html#adding-and-linking-bots">Adding and linking bots</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/botnet.html#using-botflags">Using botflags</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/botnet.html#making-bots-share-user-records">Making bots share user records</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/botnet.html#using-certificates-to-authenticate-eggdrops">Using certificates to authenticate Eggdrops</a></li>}
    puts $fp {</ul>}
    puts $fp {</li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/ipv6.html">IPv6 support</a><ul>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/ipv6.html#about">About</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/ipv6.html#installation">Installation</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/ipv6.html#usage">Usage</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/ipv6.html#ctcp-chat-chat4-chat6">CTCP CHAT/CHAT4/CHAT6</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/ipv6.html#settings">Settings</a></li>}
    puts $fp {</ul>}
    puts $fp {</li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/tls.html">TLS support</a><ul>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/tls.html#about">About</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/tls.html#installation">Installation</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/tls.html#usage">Usage</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/tls.html#keys-certificates-and-authentication">Keys, certificates and authentication</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/tls.html#ssl-tls-settings">SSL/TLS Settings</a></li>}
    puts $fp {</ul>}
    puts $fp {</li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/ircv3.html">IRCv3 support</a><ul>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/ircv3.html#about">About</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/ircv3.html#usage">Usage</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/ircv3.html#supported-cap-capabilities">Supported CAP capabilities</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/ircv3.html#errata">Errata</a></li>}
    puts $fp {</ul>}
    puts $fp {</li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/accounts.html">Account tracking in Eggdrop</a><ul>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/accounts.html#required-server-capabilities">Required Server Capabilities</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/accounts.html#enabling-eggdrop-account-tracking">Enabling Eggdrop Account Tracking</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/accounts.html#checking-account-tracking-status">Checking Account-tracking Status</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/accounts.html#determining-if-a-server-supports-account-capabilities">Determining if a Server Supports Account Capabilities</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/accounts.html#best-effort-account-tracking">Best-Effort Account Tracking</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/accounts.html#using-accounts-with-tcl-scripts">Using Accounts with Tcl Scripts</a></li>}
    puts $fp {</ul>}
    puts $fp {</li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/pbkdf2info.html">Encryption/Hashing</a><ul>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/pbkdf2info.html#background">Background</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/pbkdf2info.html#usage">Usage</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/pbkdf2info.html#tcl-interface">Tcl Interface</a></li>}
    puts $fp {</ul>}
    puts $fp {</li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/python.html">Using the Python Module</a><ul>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/python.html#system-requirements">System Requirements</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/python.html#loading-python">Loading Python</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/python.html#reloading-python-scripts">Reloading Python Scripts</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/python.html#multithreading-and-async">Multithreading and async</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/python.html#eggdrop-python-commands">Eggdrop Python Commands</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/python.html#writing-an-eggdrop-python-script">Writing an Eggdrop Python script</a></li>}
    puts $fp {</ul>}
    puts $fp {</li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/twitchinfo.html">Twitch</a><ul>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/twitchinfo.html#disclaimer">Disclaimer</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/twitchinfo.html#registering-with-twitch">Registering with Twitch</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/twitchinfo.html#editing-the-config-file">Editing the config file</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/twitchinfo.html#twitch-web-ui-functions">Twitch web UI functions</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/twitchinfo.html#twitch-irc-limitations">Twitch IRC limitations</a></li>}
    puts $fp {</ul>}
    puts $fp {</li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/tricks.html">Advanced Tips</a><ul>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/tricks.html#renaming-commands">Renaming commands</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/tricks.html#keeping-logs">Keeping Logs</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/tricks.html#self-logging">Self-logging</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/tricks.html#modifying-default-strings">Modifying Default Strings</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/tricks.html#modularizing-your-config-file">Modularizing Your Config File</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/tricks.html#variables-in-your-config">Variables in Your Config</a></li>}
    puts $fp {</ul>}
    puts $fp {</li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/text-sub.html">Textfile Substitutions</a></li>}
    puts $fp {<li class="toctree-l1"><a class="reference internal" href="using/tcl-commands.html">Eggdrop Tcl Commands</a><ul>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/tcl-commands.html#output-commands">Output Commands</a></li>}
    puts $fp {<li class="toctree-l2"><a class="reference internal" href="using/tcl-commands.html#user-record-manipulation-commands">User Record Manipulation Commands</a></li>}
    puts $fp {<li class="toctree-l2
