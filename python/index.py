#!/usr/bin/env python3
# index.html — portiert nach python
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/eggdrop/index.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/eggdrop/index.html
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

import sys
from xml.etree import ElementTree as ET


def create_index_html():
    # Create the root element
    html = ET.Element('html', lang='en', **{'data-content_root': './'})
    
    # Head section
    head = ET.SubElement(html, 'head')
    ET.SubElement(head, 'meta', charset='utf-8')
    ET.SubElement(head, 'meta', name='viewport', content='width=device-width, initial-scale=1.0')
    ET.SubElement(head, 'meta', name='viewport', content='width=device-width, initial-scale=1')
    
    title = ET.SubElement(head, 'title')
    title.text = 'Eggdrop, an open source IRC bot \u2014 Eggdrop 1.10.1 documentation'
    
    ET.SubElement(head, 'link', rel='stylesheet', type='text/css', href='_static/pygments.css?v=03e43079')
    ET.SubElement(head, 'link', rel='stylesheet', type='text/css', href='_static/eggdrop.css?v=ab48a1b6')
    ET.SubElement(head, 'script', src='_static/documentation_options.js?v=290de6c6')
    ET.SubElement(head, 'script', src='_static/doctools.js?v=9bcbadda')
    ET.SubElement(head, 'script', src='_static/sphinx_highlight.js?v=dc90522c')
    ET.SubElement(head, 'link', rel='search', title='Search', href='search.html')
    ET.SubElement(head, 'link', rel='next', title='README', href='install/readme.html')
    
    # Body section
    body = ET.SubElement(html, 'body')
    
    # Header wrapper
    header_wrapper = ET.SubElement(body, 'div', **{'class': 'header-wrapper', 'role': 'banner'})
    header = ET.SubElement(header_wrapper, 'div', **{'class': 'header'})
    headertitle = ET.SubElement(header, 'div', **{'class': 'headertitle'})
    headertitle_a = ET.SubElement(headertitle, 'a', href='#')
    headertitle_a.text = 'Eggdrop 1.10.1 documentation'
    
    rel = ET.SubElement(header, 'div', **{'class': 'rel', 'role': 'navigation', 'aria-label': 'related navigation'})
    rel_a = ET.SubElement(rel, 'a', href='install/readme.html', title='README', accesskey='N')
    rel_a.text = 'next'
    
    # Content wrapper
    content_wrapper = ET.SubElement(body, 'div', **{'class': 'content-wrapper'})
    content = ET.SubElement(content_wrapper, 'div', **{'class': 'content'})
    
    # Sidebar
    sidebar = ET.SubElement(content, 'div', **{'class': 'sidebar'})
    
    # Table of contents - Installing Eggdrop
    ET.SubElement(sidebar, 'h3').text = 'Table of Contents'
    caption1 = ET.SubElement(sidebar, 'p', **{'class': 'caption', 'role': 'heading'})
    span1 = ET.SubElement(caption1, 'span', **{'class': 'caption-text'})
    span1.text = 'Installing Eggdrop'
    ul1 = ET.SubElement(sidebar, 'ul')
    li1_1 = ET.SubElement(ul1, 'li', **{'class': 'toctree-l1'})
    a1_1 = ET.SubElement(li1_1, 'a', **{'class': 'reference internal', 'href': 'install/readme.html'})
    a1_1.text = 'README'
    li1_2 = ET.SubElement(ul1, 'li', **{'class': 'toctree-l1'})
    a1_2 = ET.SubElement(li1_2, 'a', **{'class': 'reference internal', 'href': 'install/install.html'})
    a1_2.text = 'Installing Eggdrop'
    li1_3 = ET.SubElement(ul1, 'li', **{'class': 'toctree-l1'})
    a1_3 = ET.SubElement(li1_3, 'a', **{'class': 'reference internal', 'href': 'install/upgrading.html'})
    a1_3.text = 'Upgrading Eggdrop'
    
    # Table of contents - Using Eggdrop
    caption2 = ET.SubElement(sidebar, 'p', **{'class': 'caption', 'role': 'heading'})
    span2 = ET.SubElement(caption2, 'span', **{'class': 'caption-text'})
    span2.text = 'Using Eggdrop'
    ul2 = ET.SubElement(sidebar, 'ul')
    links2 = [
        ('using/features.html', 'Eggdrop Features'),
        ('using/core.html', 'Eggdrop Core Settings'),
        ('using/partyline.html', 'The Party Line'),
        ('using/autoscripts.html', 'Eggdrop Autoscripts'),
        ('using/users.html', 'Users and Flags'),
        ('using/bans.html', 'Bans, Invites, and Exempts'),
        ('using/botnet.html', 'Botnet Sharing and Linking'),
        ('using/ipv6.html', 'IPv6 support'),
        ('using/tls.html', 'TLS support'),
        ('using/ircv3.html', 'IRCv3 support'),
        ('using/accounts.html', 'Account tracking in Eggdrop'),
        ('using/pbkdf2info.html', 'Encryption/Hashing'),
        ('using/python.html', 'Using the Python Module'),
        ('using/twitchinfo.html', 'Twitch'),
        ('using/tricks.html', 'Advanced Tips'),
        ('using/text-sub.html', 'Textfile Substitutions'),
        ('using/tcl-commands.html', 'Eggdrop Tcl Commands'),
        ('using/twitch-tcl-commands.html', 'Eggdrop Twitch Tcl Commands'),
        ('using/patch.html', 'Patching Eggdrop')
    ]
    for href, text in links2:
        li = ET.SubElement(ul2, 'li', **{'class': 'toctree-l1'})
        a = ET.SubElement(li, 'a', **{'class': 'reference internal', 'href': href})
        a.text = text
    
    # Table of contents - Tutorials
    caption3 = ET.SubElement(sidebar, 'p', **{'class': 'caption', 'role': 'heading'})
    span3 = ET.SubElement(caption3, 'span', **{'class': 'caption-text'})
    span3.text = 'Tutorials'
    ul3 = ET.SubElement(sidebar, 'ul')
    links3 = [
        ('tutorials/setup.html', 'Setting Up Eggdrop'),
        ('tutorials/firststeps.html', 'Common First Steps'),
        ('tutorials/tlssetup.html', 'Enabling TLS Security on Eggdrop'),
        ('tutorials/userfilesharing.html', 'Sharing Userfiles'),
        ('tutorials/firstscript.html', 'Writing an Eggdrop Tcl Script'),
        ('tutorials/module.html', 'Writing a Basic Eggdrop Module')
    ]
    for href, text in links3:
        li = ET.SubElement(ul3, 'li', **{'class': 'toctree-l1'})
        a = ET.SubElement(li, 'a', **{'class': 'reference internal', 'href': href})
        a.text = text
    
    # Table of contents - Eggdrop Modules
    caption4 = ET.SubElement(sidebar, 'p', **{'class': 'caption', 'role': 'heading'})
    span4 = ET.SubElement(caption4, 'span', **{'class': 'caption-text'})
    span4.text = 'Eggdrop Modules'
    ul4 = ET.SubElement(sidebar, 'ul')
    links4 = [
        ('modules/index.html', 'Eggdrop Module Information'),
        ('modules/included.html', 'Modules included with Eggdrop'),
        ('modules/writing.html', 'How to Write an Eggdrop Module'),
        ('modules/internals.html', 'Eggdrop Bind Internals')
    ]
    for href, text in links4:
        li = ET.SubElement(ul4, 'li', **{'class': 'toctree-l1'})
        a = ET.SubElement(li, 'a', **{'class': 'reference internal', 'href': href})
        a.text = text
    
    # Table of contents - About Eggdrop
    caption5 = ET.SubElement(sidebar, 'p', **{'class': 'caption', 'role': 'heading'})
    span5 = ET.SubElement(caption5, 'span', **{'class': 'caption-text'})
    span5.text = 'About Eggdrop'
    ul5 = ET.SubElement(sidebar, 'ul')
    li5_1 = ET.SubElement(ul5, 'li', **{'class': 'toctree-l1'})
    a5_1 = ET.SubElement(li5_1, 'a', **{'class': 'reference internal', 'href': 'about/about.html'})
    a5_1.text = 'About Eggdrop'
    li5_2 = ET.SubElement(ul5, 'li', **{'class': 'toctree-l1'})
    a5_2 = ET.SubElement(li5_2, 'a', **{'class': 'reference internal', 'href': 'about/legal.html'})
    a5_2.text = 'Boring legal stuff'
    
    # Search form
    search_div = ET.SubElement(sidebar, 'div', **{'role': 'search'})
    ET.SubElement(search_div, 'h3', style='margin-top: 1.5em;').text = 'Search'
    search_form = ET.SubElement(search_div, 'form', **{'class': 'search', 'action': 'search.html', 'method': 'get'})
    ET.SubElement(search_form, 'input', type='text', name='q')
    ET.SubElement(search_form, 'input', type='submit', value='Go')
    
    # Document section
    document = ET.SubElement(content, 'div', **{'class': 'document'})
    documentwrapper = ET.SubElement(document, 'div', **{'class': 'documentwrapper'})
    bodywrapper = ET.SubElement(documentwrapper, 'div', **{'class': 'bodywrapper'})
    body_content = ET.SubElement(bodywrapper, 'div', **{'class': 'body', 'role': 'main'})
    
    # Main content sections
    section1 = ET.SubElement(body_content, 'section', id='eggdrop-an-open-source-irc-bot')
    h1 = ET.SubElement(section1, 'h1')
    h1.text = 'Eggdrop, an open source IRC bot'
    a_headerlink1 = ET.SubElement(h1, 'a', **{
        'class': 'headerlink',
        'href': '#eggdrop-an-open-source-irc-bot',
        'title': 'Link to this heading'
    })
    a_headerlink1.text = '\xb6'  # ¶ symbol
    
    p1 = ET.SubElement(section1, 'p')
    p1.text = 'Eggdrop is a free, open source software program built to assist in managing an IRC channel. It is the world\u2019s oldest actively-maintained IRC bot and was designed to be easily used and expanded on via it\u2019s ability to run Tcl scripts. Eggdrop can join IRC channels and perorm automated tasks such as protecting the channel from abuse, assisting users obtain their op/voice status, provide information and greetings, host games, etc.'
    
    # Some things you can do with Eggdrop
    section2 = ET.SubElement(section1, 'section', id='some-things-you-can-do-with-eggdrop')
    h2_1 = ET.SubElement(section2, 'h2')
    h2_1.text = 'Some things you can do with Eggdrop'
    a_headerlink2 = ET.SubElement(h2_1, 'a', **{
        'class': 'headerlink',
        'href': '#some-things-you-can-do-with-eggdrop',
        'title': 'Link to this heading'
    })
    a_headerlink2.text = '\xb6'
    
    p2 = ET.SubElement(section2, 'p')
    p2.text = 'Eggdrop has a large number of features, such as:'
    
    ul_features = ET.SubElement(section2, 'ul', **{'class': 'simple'})
    feature_links = [
        ('using/users.html', 'Channel Management'),
        (None, 'Running Tcl Scripts'),
        ('using/ircv3.html', 'Integration of the most current IRCv3 capabilities'),
        ('using/botnet.html', 'The ability to link multiple Eggdrops together and share userfiles'),
        ('using/tls.html', 'TLS Support'),
        ('using/ipv6.html', 'IPv6 Support'),
        ('using/twitchinfo.html', 'Twitch Support')
    ]
    for href, text in feature_links:
        li = ET.SubElement(ul_features, 'li')
        if href:
            a = ET.SubElement(li, 'p')
            a_ext = ET.SubElement(a, 'a', **{'class': 'reference external', 'href': href})
            a_ext.text = text
        else:
            ET.SubElement(li, 'p').text = text
    
    li_last = ET.SubElement(ul_features, 'li')
    ET.SubElement(li_last, 'p').text = '\u2026 and much much more!'
    
    # How to get Eggdrop
    section3 = ET.SubElement(section1, 'section', id='how-to-get-eggdrop')
    h2_2 = ET.SubElement(section3, 'h2')
    h2_2.text = 'How to get Eggdrop'
    a_headerlink3 = ET.SubElement(h2_2, 'a', **{
        'class': 'headerlink',
        'href': '#how-to-get-eggdrop',
        'title': 'Link to this heading'
    })
    a_headerlink3.text = '\xb6'
    
    p3 = ET.SubElement(section3, 'p')
    p3.text = 'The Eggdrop project source code is hosted at '
    a_github = ET.SubElement(p3, 'a', **{'class': 'reference external', 'href': 'https://github.com/eggheads/eggdrop'})
    a_github.text = 'https://github.com/eggheads/eggdrop'
    p3.tail = '. You can clone it via git, or alternatively a copy of the current stable snapshot is located at '
    a_geteggdrop = ET.SubElement(p3, 'a', **{'class': 'reference external', 'href': 'https://geteggdrop.com'})
    a_geteggdrop.text = 'https://geteggdrop.com'
    p3.tail += '. Additional information can be found on the official Eggdrop webpage at '
    a_eggheads = ET.SubElement(p3, 'a', **{'class': 'reference external', 'href': 'https://www.eggheads.org'})
    a_eggheads.text = 'https://www.eggheads.org'
    p3.tail += '. For more information, see '
    a_install = ET.SubElement(p3, 'a', **{'class': 'reference external', 'href': 'install/install.html'})
    a_install.text = 'Installing Eggdrop'
    
    # How to install Eggdrop
    section4 = ET.SubElement(section1, 'section', id='how-to-install-eggdrop')
    h2_3 = ET.SubElement(section4, 'h2')
    h2_3.text = 'How to install Eggdrop'
    a_headerlink4 = ET.SubElement(h2_3, 'a', **{
        'class': 'headerlink',
        'href': '#how-to-install-eggdrop',
        'title': 'Link to this heading'
    })
    a_headerlink4.text = '\xb6'
    
    # Installation pre-requisites
    section5 = ET.SubElement(section4, 'section', id='installation-pre-requisites')
    h3_1 = ET.SubElement(section5, 'h3')
    h3_1.text = 'Installation Pre-requisites'
    a_headerlink5 = ET.SubElement(h3_1, 'a', **{
        'class': 'headerlink',
        'href': '#installation-pre-requisites',
        'title': 'Link to this heading'
    })
    a_headerlink5.text = '\xb6'
    
    p4 = ET.SubElement(section5, 'p')
    p4.text = 'Eggdrop requires Tcl (and its development header files) to be present on the system it is compiled on. It is also strongly encouraged to install openssl (and its development header files) to enable TLS-protected network communication.'
    
    # Installation
    section6 = ET.SubElement(section4, 'section', id='installation')
    h3_2 = ET.SubElement(section6, 'h3')
    h3_2.text = 'Installation'
    a_headerlink6 = ET.SubElement(h3_2, 'a', **{
        'class': 'headerlink',
        'href': '#installation',
        'title': 'Link to this heading'
    })
    a_headerlink6.text = '\xb6'
    
    p5 = ET.SubElement(section6, 'p')
    p5.text = 'A guide to quickly installing Eggdrop can be found here.'
    
    # Where to find more help
    section7 = ET.SubElement(section1, 'section', id='where-to-find-more-help')
    h2_4 = ET.SubElement(section7, 'h2')
    h2_4.text = 'Where to find more help'
    a_headerlink7 = ET.SubElement(h2_4, 'a', **{
        'class': 'headerlink',
        'href': '#where-to-find-more-help',
        'title': 'Link to this heading'
    })
    a_headerlink7.text = '\xb6'
    
    p6 = ET.SubElement(section7, 'p')
    p6.text = 'The Eggheads development team can be found lurking on #eggdrop on the Libera network (irc.libera.chat).'
    
    # Toctree wrappers
    # Installing Eggdrop
    toctree1 = ET.SubElement(section7, 'div', **{'class': 'toctree-wrapper compound'})
    caption_toctree1 = ET.SubElement(toctree1, 'p', **{'class': 'caption', 'role': 'heading'})
    span_toctree1 = ET.SubElement(caption_toctree1, 'span', **{'class': 'caption-text'})
    span_toctree1.text = 'Installing Eggdrop'
    ul_toctree1 = ET.SubElement(toctree1, 'ul')
    
    li_toctree1_1 = ET.SubElement(ul_toctree1, 'li', **{'class': 'toctree-l1'})
    a_toctree1_1 = ET.SubElement(li_toctree1_1, 'a', **{'class': 'reference internal', 'href': 'install/readme.html'})
    a_toctree1_1.text = 'README'
    ul_toctree1_1 = ET.SubElement(li_toctree1_1, 'ul')
    links_toctree1_1 = [
        ('install/readme.html#notice', 'Notice'),
        ('install/readme.html#what-is-eggdrop', 'What is Eggdrop?'),
        ('install/readme.html#how-to-get-eggdrop', 'How to Get Eggdrop'),
        ('install/readme.html#system-pre-requisites', 'System Pre-Requisites'),
        ('install/readme.html#minimum-requirements', 'Minimum Requirements'),
        ('install/readme.html#quick-startup', 'Quick Startup'),
        ('install/readme.html#upgrading', 'Upgrading'),
        ('install/readme.html#command-line', 'Command Line'),
        ('install/readme.html#auto-starting-eggdrop', 'Auto-starting Eggdrop'),
        ('install/readme.html#documentation', 'Documentation'),
        ('install/readme.html#obtaining-help', 'Obtaining Help')
    ]
    for href, text in links_toctree1_1:
        li = ET.SubElement(ul_toctree1_1, 'li', **{'class': 'toctree-l2'})
        a = ET.SubElement(li, 'a', **{'class': 'reference internal', 'href': href})
        a.text = text
    
    li_toctree1_2 = ET.SubElement(ul_toctree1, 'li', **{'class': 'toctree-l1'})
    a_toctree1_2 = ET.SubElement(li_toctree1_2, 'a', **{'class': 'reference internal', 'href': 'install/install.html'})
    a_toctree1_2.text = 'Installing Eggdrop'
    ul_toctree1_2 = ET.SubElement(li_toctree1_2, 'ul')
    links_toctree1_2 = [
        ('install/install.html#quick-startup', 'Quick Startup'),
        ('install/install.html#cygwin-requirements-windows', 'Cygwin Requirements (Windows)'),
        ('install/install.html#modules', 'Modules')
    ]
    for href, text in links_toctree1_2:
        li = ET.SubElement(ul_toctree1_2, 'li', **{'class': 'toctree-l2'})
        a = ET.SubElement(li, 'a', **{'class': 'reference internal', 'href': href})
        a.text = text
    
    li_toctree1_3 = ET.SubElement(ul_toctree1, 'li', **{'class': 'toctree-l1'})
    a_toctree1_3 = ET.SubElement(li_toctree1_3, 'a', **{'class': 'reference internal', 'href': 'install/upgrading.html'})
    a_toctree1_3.text = 'Upgrading Eggdrop'
    ul_toctree1_3 = ET.SubElement(li_toctree1_3, 'ul')
    links_toctree1_3 = [
        ('install/upgrading.html#how-to-upgrade', 'How to Upgrade'),
        ('install/upgrading.html#must-read-changes-for-eggdrop-v1-10', 'Must-read changes for Eggdrop v1.10')
    ]
    for href, text in links_toctree1_3:
        li = ET.SubElement(ul_toctree1_3, 'li', **{'class': 'toctree-l2'})
        a = ET.SubElement(li, 'a', **{'class': 'reference internal', 'href': href})
        a.text = text
    
    # Using Eggdrop
    toctree2 = ET.SubElement(section7, 'div', **{'class': 'toctree-wrapper compound'})
    caption_toctree2 = ET.SubElement(toctree2, 'p', **{'class': 'caption', 'role': 'heading'})
    span_toctree2 = ET.SubElement(caption_toctree2, 'span', **{'class': 'caption-text'})
    span_toctree2.text = 'Using Eggdrop'
    ul_toctree2 = ET.SubElement(toctree2, 'ul')
    
    li_toctree2_1 = ET.SubElement(ul_toctree2, 'li', **{'class': 'toctree-l1'})
    a_toctree2_1 = ET.SubElement(li_toctree2_1, 'a', **{'class': 'reference internal', 'href': 'using/features.html'})
    a_toctree2_1.text = 'Eggdrop Features'
    
    li_toctree2_2 = ET.SubElement(ul_toctree2, 'li', **{'class': 'toctree-l1'})
    a_toctree2_2 = ET.SubElement(li_toctree2_2, 'a', **{'class': 'reference internal', 'href': 'using/core.html'})
    a_toctree2_2.text = 'Eggdrop Core Settings'
    ul_toctree2_2 = ET.SubElement(li_toctree2_2, 'ul')
    links_toctree2_2 = [
        ('using/core.html#executable-path', 'Executable Path'),
        ('using/core.html#basic-settings', 'Basic Settings'),
        ('using/core.html#log-files', 'Log Files'),
        ('using/core.html#console-settings', 'Console Settings'),
        ('using/core.html#file-and-directory-settings', 'File and Directory Settings'),
        ('using/core.html#botnet-dcc-telnet-settings', 'Botnet/Dcc/Telnet Settings'),
        ('using/core.html#advanced-settings', 'Advanced Settings'),
        ('using/core.html#ssl-settings', 'SSL Settings'),
        ('using/core.html#modules', 'Modules'),
        ('using/core.html#scripts', 'Scripts')
    ]
    for href, text in links_toctree2_2:
        li = ET.SubElement(ul_toctree2_2, 'li', **{'class': 'toctree-l2'})
        a = ET.SubElement(li, 'a', **{'class': 'reference internal', 'href': href})
        a.text = text
    
    li_toctree2_3 = ET.SubElement(ul_toctree2, 'li', **{'class': 'toctree-l1'})
    a_toctree2_3 = ET.SubElement(li_toctree2_3, 'a', **{'class': 'reference internal', 'href': 'using/partyline.html'})
    a_toctree2_3.text = 'The Party Line'
    
    li_toctree2_4 = ET.SubElement(ul_toctree2, 'li', **{'class': 'toctree-l1'})
    a_toctree2_4 = ET.SubElement(li_toctree2_4, 'a', **{'class': 'reference internal', 'href': 'using/autoscripts.html'})
    a_toctree2_4.text = 'Eggdrop Autoscripts'
    ul_toctree2_4 = ET.SubElement(li_toctree2_4, 'ul')
    links_toctree2_4 = [
        ('using/autoscripts.html#autoscripts-usage', 'Autoscripts usage'),
        ('using/autoscripts.html#autoscripts-file-structure', 'Autoscripts File Structure'),
        ('using/autoscripts.html#development-hints', 'Development hints'),
        ('using/autoscripts.html#tcl-commands', 'Tcl Commands')
    ]
    for href, text in links_toctree2_4:
        li = ET.SubElement(ul_toctree2_4, 'li', **{'class': 'toctree-l2'})
        a = ET.SubElement(li, 'a', **{'class': 'reference internal', 'href': href})
        a.text = text
    
    li_toctree2_5 = ET.SubElement(ul_toctree2, 'li', **{'class': 'toctree-l1'})
    a_toctree2_5 = ET.SubElement(li_toctree2_5, 'a', **{'class': 'reference internal', 'href': 'using/users.html'})
    a_toctree2_5.text = 'Users and Flags'
    
    li_toctree2_6 = ET.SubElement(ul_toctree2, 'li', **{'class': 'toctree-l1'})
    a_toctree2_6 = ET.SubElement(li_toctree2_6, 'a', **{'class': 'reference internal', 'href': 'using/bans.html'})
    a_toctree2_6.text = 'Bans, Invites, and Exempts'
    
    li_toctree2_7 = ET.SubElement(ul_toctree2, 'li', **{'class': 'toctree-l1'})
    a_toctree2_7 = ET.SubElement(li_toctree2_7, 'a', **{'class': 'reference internal', 'href': 'using/botnet.html'})
    a_toctree2_7.text = 'Botnet Sharing and Linking'
    ul_toctree2_7 = ET.SubElement(li_toctree2_7, 'ul')
    links_toctree2_7 = [
        ('using/botnet.html#what-is-a-botnet', 'What is a botnet?'),
        ('using/botnet.html#terms', 'Terms'),
        ('using/botnet.html#example-bottrees', 'Example bottrees'),
        ('using/botnet.html#bot-flags', 'Bot Flags'),
        ('using/botnet.html#adding-and-linking-bots', 'Adding and linking bots'),
        ('using/botnet.html#using-botflags', 'Using botflags'),
        ('using/botnet.html#making-bots-share-user-records', 'Making bots share user records'),
        ('using/botnet.html#using-certificates-to-authenticate-eggdrops', 'Using certificates to authenticate Eggdrops')
    ]
    for href, text in links_toctree2_7:
        li = ET.SubElement(ul_toctree2_7, 'li', **{'class': 'toctree-l2'})
        a = ET.SubElement(li, 'a', **{'class': 'reference internal', 'href': href})
        a.text = text
    
    li_toctree2_8 = ET.SubElement(ul_toctree2, 'li', **{'class': 'toctree-l1'})
    a_toctree2_8 = ET.SubElement(li_toctree2_8, 'a', **{'class': 'reference internal', 'href': 'using/ipv6.html'})
    a_toctree2_8.text = 'IPv6 support'
    ul_toctree2_8 = ET.SubElement(li_toctree2_8, 'ul')
    links_toctree2_8 = [
        ('using/ipv6.html#about', 'About'),
        ('using/ipv6.html#installation', 'Installation'),
        ('using/ipv6.html#usage', 'Usage'),
        ('using/ipv6.html#ctcp-chat-chat4-chat6', 'CTCP CHAT/CHAT4/CHAT6'),
        ('using/ipv6.html#settings', 'Settings')
    ]
    for href, text in links_toctree2_8:
        li = ET.SubElement(ul_toctree2_8, 'li', **{'class': 'toctree-l2'})
        a = ET.SubElement(li, 'a', **{'class': 'reference internal', 'href': href})
        a.text = text
    
    li_toctree2_9 = ET.SubElement(ul_toctree2, 'li', **{'class': 'toctree-l1'})
    a_toctree2_9 = ET.SubElement(li_toctree2_9, 'a', **{'class': 'reference internal', 'href': 'using/tls.html'})
    a_toctree2_9.text = 'TLS support'
    ul_toctree2_9 = ET.SubElement(li_toctree2_9, 'ul')
    links_toctree2_9 = [
        ('using/tls.html#about', 'About'),
        ('using/tls.html#installation', 'Installation'),
        ('using/tls.html#usage', 'Usage'),
        ('using/tls.html#keys-certificates-and-authentication', 'Keys, certificates and authentication'),
        ('using/tls.html#ssl-tls-settings', 'SSL/TLS Settings')
    ]
    for href, text in links_toctree2_9:
        li = ET.SubElement(ul_toctree2_9, 'li', **{'class': 'toctree-l2'})
        a = ET.SubElement(li, 'a', **{'class': 'reference internal', 'href': href})
        a.text = text
    
    li_toctree2_10 = ET.SubElement(ul_toctree2, 'li', **{'class': 'toctree-l1'})
    a_toctree2_10 = ET.SubElement(li_toctree2_10, 'a', **{'class': 'reference internal', 'href': 'using/ircv3.html'})
    a_toctree2_10.text = 'IRCv3 support'
    ul_toctree2_10 = ET.SubElement(li_toctree2_10, 'ul')
    links_toctree2_10 = [
        ('using/ircv3.html#about', 'About'),
        ('using/ircv3.html#usage', 'Usage'),
        ('using/ircv3.html#supported-cap-capabilities', 'Supported CAP capabilities'),
        ('using/ircv3.html#errata', 'Errata')
    ]
    for href, text in links_toctree2_10:
        li = ET.SubElement(ul_toctree2_10, 'li', **{'class': 'toctree-l2'})
        a = ET.SubElement(li, 'a', **{'class': 'reference internal', 'href': href})
        a.text = text
    
    li_toctree2_11 = ET.SubElement(ul_toctree2, 'li', **{'class': 'toctree-l1'})
    a_toctree2_11 = ET.SubElement(li_toctree2_11, 'a', **{'class': 'reference internal', 'href': 'using/accounts.html'})
    a_toctree2_11.text = 'Account tracking in Eggdrop'
    ul_toctree2_11 = ET.SubElement(li_toctree2_11, 'ul')
    links_toctree2_11 = [
        ('using/accounts.html#required-server-capabilities', 'Required Server Capabilities'),
        ('using/accounts.html#enabling-eggdrop-account-tracking', 'Enabling Eggdrop Account Tracking'),
        ('using/accounts.html#checking-account-tracking-status', 'Checking Account-tracking Status'),
        ('using/accounts.html#determining-if-a-server-supports-account-capabilities', 'Determining if a Server Supports Account Capabilities'),
        ('using/accounts.html#best-effort-account-tracking', 'Best-Effort Account Tracking'),
        ('using/accounts.html#using-accounts-with-tcl-scripts', 'Using Accounts with Tcl Scripts')
    ]
    for href, text in links_toctree2_11:
        li = ET.SubElement(ul_toctree2_11, 'li', **{'class': 'toctree-l2'})
        a = ET.SubElement(li, 'a', **{'class': 'reference internal', 'href': href})
        a.text = text
    
    li_toctree2_12 = ET.SubElement(ul_toctree2, 'li', **{'class': 'toctree-l1'})
    a_toctree2_12 = ET.SubElement(li_toctree2_12, 'a', **{'class': 'reference internal', 'href': 'using/pbkdf2info.html'})
    a_toctree2_12.text = 'Encryption/Hashing'
    ul_toctree2_12 = ET.SubElement(li_toctree2_12, 'ul')
    links_toctree2_12 = [
        ('using/pbkdf2info.html#background', 'Background'),
        ('using/pbkdf2info.html#usage', 'Usage'),
        ('using/pbkdf2info.html#tcl-interface', 'Tcl Interface')
    ]
    for href, text in links_toctree2_12:
        li = ET.SubElement(ul_toctree2_12, 'li', **{'class': 'toctree-l2'})
        a = ET.SubElement(li, 'a', **{'class': 'reference internal', 'href': href})
        a.text = text
    
    li_toctree2_13 = ET.SubElement(ul_toctree2, 'li', **{'class': 'toctree-l1'})
    a_toctree2_13 = ET.SubElement(li_toctree2_13, 'a', **{'class': 'reference internal', 'href': 'using/python.html'})
    a_toctree2_13.text = 'Using the Python Module'
    ul_toctree2_13 = ET.SubElement(li_toctree2_13, 'ul')
    links_toctree2_13 = [
        ('using/python.html#system-requirements', 'System Requirements'),
        ('using/python.html#loading-python', 'Loading Python'),
        ('using/python.html#reloading-python-scripts', 'Reloading Python Scripts'),
        ('using/python.html#multithreading-and-async', 'Multithreading and async'),
        ('using/python.html#eggdrop-python-commands', 'Eggdrop Python Commands'),
        ('using/python.html#writing-an-eggdrop-python-script', 'Writing an Eggdrop Python script')
    ]
    for href, text in links_toctree2_13:
        li = ET.SubElement(ul_toctree2_13, 'li', **{'class': 'toctree-l2'})
        a = ET.SubElement(li, 'a', **{'class': 'reference internal', 'href': href})
        a.text = text
    
    li_toctree2_14 = ET.SubElement(ul_toctree2, 'li', **{'class': 'toctree-l1'})
    a_toctree2_14 = ET.SubElement(li_toctree2_14, 'a', **{'class': 'reference internal', 'href': 'using/twitchinfo.html'})
