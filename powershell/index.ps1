#!/usr/bin/env pwsh
# index.html — portiert nach powershell
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/eggdrop/index.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/eggdrop/index.html
# Erzeugt: 2026-10-31 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
    Generates an HTML document similar to Eggdrop documentation index page.
.DESCRIPTION
    This script generates an HTML file that mimics the structure and content of the provided index.html,
    including all necessary elements like headers, body content, navigation links, and footer.
.PARAMETER OutputPath
    The path where the generated HTML file will be saved.
.EXAMPLE
    .\Generate-EggdropIndex.ps1 -OutputPath "index.html"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Create HTML content using PowerShell's Here-String feature
$htmlContent = @"
<!DOCTYPE html>
<html lang="en" data-content_root="./">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Eggdrop, an open source IRC bot &#8212; Eggdrop 1.10.1 documentation</title>
    <link rel="stylesheet" type="text/css" href="_static/pygments.css?v=03e43079" />
    <link rel="stylesheet" type="text/css" href="_static/eggdrop.css?v=ab48a1b6" />
    <script src="_static/documentation_options.js?v=290de6c6"></script>
    <script src="_static/doctools.js?v=9bcbadda"></script>
    <script src="_static/sphinx_highlight.js?v=dc90522c"></script>
    <link rel="search" title="Search" href="search.html" />
    <link rel="next" title="README" href="install/readme.html" /> 
  </head>
  <body>
    <div class="header-wrapper" role="banner">
      <div class="header">
        <div class="headertitle"><a href="#">Eggdrop 1.10.1 documentation</a></div>
        <div class="rel" role="navigation" aria-label="related navigation">
          <a href="install/readme.html" title="README" accesskey="N">next</a>
        </div>
      </div>
    </div>

    <div class="content-wrapper">
      <div class="content">
        <div class="sidebar">
          <h3>Table of Contents</h3>
          <p class="caption" role="heading"><span class="caption-text">Installing Eggdrop</span></p>
          <ul>
            <li class="toctree-l1"><a class="reference internal" href="install/readme.html">README</a></li>
            <li class="toctree-l1"><a class="reference internal" href="install/install.html">Installing Eggdrop</a></li>
            <li class="toctree-l1"><a class="reference internal" href="install/upgrading.html">Upgrading Eggdrop</a></li>
          </ul>
          <p class="caption" role="heading"><span class="caption-text">Using Eggdrop</span></p>
          <ul>
            <li class="toctree-l1"><a class="reference internal" href="using/features.html">Eggdrop Features</a></li>
            <li class="toctree-l1"><a class="reference internal" href="using/core.html">Eggdrop Core Settings</a></li>
            <li class="toctree-l1"><a class="reference internal" href="using/partyline.html">The Party Line</a></li>
            <li class="toctree-l1"><a class="reference internal" href="using/autoscripts.html">Eggdrop Autoscripts</a></li>
            <li class="toctree-l1"><a class="reference internal" href="using/users.html">Users and Flags</a></li>
            <li class="toctree-l1"><a class="reference internal" href="using/bans.html">Bans, Invites, and Exempts</a></li>
            <li class="toctree-l1"><a class="reference internal" href="using/botnet.html">Botnet Sharing and Linking</a></li>
            <li class="toctree-l1"><a class="reference internal" href="using/ipv6.html">IPv6 support</a></li>
            <li class="toctree-l1"><a class="reference internal" href="using/tls.html">TLS support</a></li>
            <li class="toctree-l1"><a class="reference internal" href="using/ircv3.html">IRCv3 support</a></li>
            <li class="toctree-l1"><a class="reference internal" href="using/accounts.html">Account tracking in Eggdrop</a></li>
            <li class="toctree-l1"><a class="reference internal" href="using/pbkdf2info.html">Encryption/Hashing</a></li>
            <li class="toctree-l1"><a class="reference internal" href="using/python.html">Using the Python Module</a></li>
            <li class="toctree-l1"><a class="reference internal" href="using/twitchinfo.html">Twitch</a></li>
            <li class="toctree-l1"><a class="reference internal" href="using/tricks.html">Advanced Tips</a></li>
            <li class="toctree-l1"><a class="reference internal" href="using/text-sub.html">Textfile Substitutions</a></li>
            <li class="toctree-l1"><a class="reference internal" href="using/tcl-commands.html">Eggdrop Tcl Commands</a></li>
            <li class="toctree-l1"><a class="reference internal" href="using/twitch-tcl-commands.html">Eggdrop Twitch Tcl Commands</a></li>
            <li class="toctree-l1"><a class="reference internal" href="using/patch.html">Patching Eggdrop</a></li>
          </ul>
          <p class="caption" role="heading"><span class="caption-text">Tutorials</span></p>
          <ul>
            <li class="toctree-l1"><a class="reference internal" href="tutorials/setup.html">Setting Up Eggdrop</a></li>
            <li class="toctree-l1"><a class="reference internal" href="tutorials/firststeps.html">Common First Steps</a></li>
            <li class="toctree-l1"><a class="reference internal" href="tutorials/tlssetup.html">Enabling TLS Security on Eggdrop</a></li>
            <li class="toctree-l1"><a class="reference internal" href="tutorials/userfilesharing.html">Sharing Userfiles</a></li>
            <li class="toctree-l1"><a class="reference internal" href="tutorials/firstscript.html">Writing an Eggdrop Tcl Script</a></li>
            <li class="toctree-l1"><a class="reference internal" href="tutorials/module.html">Writing a Basic Eggdrop Module</a></li>
          </ul>
          <p class="caption" role="heading"><span class="caption-text">Eggdrop Modules</span></p>
          <ul>
            <li class="toctree-l1"><a class="reference internal" href="modules/index.html">Eggdrop Module Information</a></li>
            <li class="toctree-l1"><a class="reference internal" href="modules/included.html">Modules included with Eggdrop</a></li>
            <li class="toctree-l1"><a class="reference internal" href="modules/writing.html">How to Write an Eggdrop Module</a></li>
            <li class="toctree-l1"><a class="reference internal" href="modules/internals.html">Eggdrop Bind Internals</a></li>
          </ul>
          <p class="caption" role="heading"><span class="caption-text">About Eggdrop</span></p>
          <ul>
            <li class="toctree-l1"><a class="reference internal" href="about/about.html">About Eggdrop</a></li>
            <li class="toctree-l1"><a class="reference internal" href="about/legal.html">Boring legal stuff</a></li>
          </ul>

          <div role="search">
            <h3 style="margin-top: 1.5em;">Search</h3>
            <form class="search" action="search.html" method="get">
              <input type="text" name="q" />
              <input type="submit" value="Go" />
            </form>
          </div>
        </div>
        
        <div class="document">
          <div class="documentwrapper">
            <div class="bodywrapper">
              <div class="body" role="main">
                <section id="eggdrop-an-open-source-irc-bot">
                  <h1>Eggdrop, an open source IRC bot<a class="headerlink" href="#eggdrop-an-open-source-irc-bot" title="Link to this heading">¶</a></h1>
                  <p>Eggdrop is a free, open source software program built to assist in managing an IRC channel. It is the world’s oldest actively-maintained IRC bot and was designed to be easily used and expanded on via it’s ability to run Tcl scripts. Eggdrop can join IRC channels and perorm automated tasks such as protecting the channel from abuse, assisting users obtain their op/voice status, provide information and greetings, host games, etc.</p>
                  
                  <section id="some-things-you-can-do-with-eggdrop">
                    <h2>Some things you can do with Eggdrop<a class="headerlink" href="#some-things-you-can-do-with-eggdrop" title="Link to this heading">¶</a></h2>
                    <ul class="simple">
                      <li><p><a class="reference external" href="using/users.html">Channel Management</a></p></li>
                      <li><p>Running Tcl Scripts</p></li>
                      <li><p><a class="reference external" href="using/ircv3.html">Integration of the most current IRCv3 capabilities</a></p></li>
                      <li><p><a class="reference external" href="using/botnet.html">The ability to link multiple Eggdrops together and share userfiles</a></p></li>
                      <li><p><a class="reference external" href="using/tls.html">TLS Support</a></p></li>
                      <li><p><a class="reference external" href="using/ipv6.html">IPv6 Support</a></p></li>
                      <li><p><a class="reference external" href="using/twitchinfo.html">Twitch Support</a></p></li>
                      <li><p>... and much much more!</p></li>
                    </ul>
                  </section>
                  
                  <section id="how-to-get-eggdrop">
                    <h2>How to get Eggdrop<a class="headerlink" href="#how-to-get-eggdrop" title="Link to this heading">¶</a></h2>
                    <p>The Eggdrop project source code is hosted at <a class="reference external" href="https://github.com/eggheads/eggdrop">https://github.com/eggheads/eggdrop</a>. You can clone it via git, or alternatively a copy of the current stable snapshot is located at <a class="reference external" href="https://geteggdrop.com">https://geteggdrop.com</a>. Additional information can be found on the official Eggdrop webpage at <a class="reference external" href="https://www.eggheads.org">https://www.eggheads.org</a>. For more information, see <a class="reference external" href="install/install.html">Installing Eggdrop</a></p>
                  </section>
                  
                  <section id="how-to-install-eggdrop">
                    <h2>How to install Eggdrop<a class="headerlink" href="#how-to-install-eggdrop" title="Link to this heading">¶</a></h2>
                    <section id="installation-pre-requisites">
                      <h3>Installation Pre-requisites<a class="headerlink" href="#installation-pre-requisites" title="Link to this heading">¶</a></h3>
                      <p>Eggdrop requires Tcl (and its development header files) to be present on the system it is compiled on. It is also strongly encouraged to install openssl (and its development header files) to enable TLS-protected network communication.</p>
                    </section>
                    <section id="installation">
                      <h3>Installation<a class="headerlink" href="#installation" title="Link to this heading">¶</a></h3>
                      <p>A guide to quickly installing Eggdrop can be found here.</p>
                    </section>
                  </section>
                  
                  <section id="where-to-find-more-help">
                    <h2>Where to find more help<a class="headerlink" href="#where-to-find-more-help" title="Link to this heading">¶</a></h2>
                    <p>The Eggheads development team can be found lurking on #eggdrop on the Libera network (irc.libera.chat).</p>
                    
                    <!-- TOC sections omitted for brevity -->
                  </section>
                </section>
              </div>
            </div>
          </div>
        </div>
        <div class="clearer"></div>
      </div>
    </div>

    <div class="footer-wrapper">
      <div class="footer">
        <div class="left">
          <div role="navigation" aria-label="related navigaton">
            <a href="install/readme.html" title="README">next</a>
          </div>
          <div role="note" aria-label="source link"></div>
        </div>
        <div class="right">
          <div class="footer" role="contentinfo">
            &#169; Copyright 2025, Eggheads.
            Last updated on Aug 15, 2025.
            Created using <a href="https://www.sphinx-doc.org/">Sphinx</a> 8.2.3.
          </div>
        </div>
        <div class="clearer"></div>
      </div>
    </div>
  </body>
</html>
"@

# Write the HTML content to the specified output file
$htmlContent | Out-File -FilePath $OutputPath -Encoding Utf8

Write-Host "HTML file generated successfully at $OutputPath"
