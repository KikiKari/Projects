#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "b25f08bbd0fcad25f704545ef40290c09c695f74e0869defaf58a74ea9b664d6", "source_sha256": "e48c1623d8fdce193daf72caa7d76d4da5acf28c8842186c21c07f8cfddb5613", "target_language": "powershell"}
# index.html — portiert nach powershell
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/eggdrop/index.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/eggdrop/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
    Generates an HTML document similar to Eggdrop's index.html documentation page.
.DESCRIPTION
    This PowerShell script generates a structured HTML document that mirrors the structure and content of Eggdrop's main documentation index page.
    The output mimics the original HTML by dynamically constructing all elements using PowerShell's XML and HTML manipulation capabilities.
.PARAMETER OutputPath
    Specifies the path where the generated HTML file will be saved.
.EXAMPLE
    .\Generate-EggdropIndex.ps1 -OutputPath "index.html"
.NOTES
    Author: Assistant
    Date: 2025
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Create HTML document structure
$HTMLDocument = New-Object -ComObject "htmlfile"
$HTMLDocument.write("<!DOCTYPE html>")
$null = $HTMLDocument.close()

# Create root html element with attributes
$htmlElement = $HTMLDocument.documentElement
$htmlElement.setAttribute("lang", "en")
$htmlElement.setAttribute("data-content_root", "./")

# Create head section
$headElement = $HTMLDocument.createElement("head")

# Meta tags
$metaCharset = $HTMLDocument.createElement("meta")
$metaCharset.setAttribute("charset", "utf-8")
$headElement.appendChild($metaCharset)

$metaViewport1 = $HTMLDocument.createElement("meta")
$metaViewport1.setAttribute("name", "viewport")
$metaViewport1.setAttribute("content", "width=device-width, initial-scale=1.0")
$headElement.appendChild($metaViewport1)

$metaViewport2 = $HTMLDocument.createElement("meta")
$metaViewport2.setAttribute("name", "viewport")
$metaViewport2.setAttribute("content", "width=device-width, initial-scale=1")
$headElement.appendChild($metaViewport2)

# Title
$titleElement = $HTMLDocument.createElement("title")
$titleTextNode = $HTMLDocument.createTextNode("Eggdrop, an open source IRC bot -- Eggdrop 1.10.1 documentation")
$titleElement.appendChild($titleTextNode)
$headElement.appendChild($titleElement)

# Stylesheets
$linkPygments = $HTMLDocument.createElement("link")
$linkPygments.setAttribute("rel", "stylesheet")
$linkPygments.setAttribute("type", "text/css")
$linkPygments.setAttribute("href", "_static/pygments.css?v=03e43079")
$headElement.appendChild($linkPygments)

$linkEggdrop = $HTMLDocument.createElement("link")
$linkEggdrop.setAttribute("rel", "stylesheet")
$linkEggdrop.setAttribute("type", "text/css")
$linkEggdrop.setAttribute("href", "_static/eggdrop.css?v=ab48a1b6")
$headElement.appendChild($linkEggdrop)

# Scripts
$scriptDocOptions = $HTMLDocument.createElement("script")
$scriptDocOptions.setAttribute("src", "_static/documentation_options.js?v=290de6c6")
$headElement.appendChild($scriptDocOptions)

$scriptDoctools = $HTMLDocument.createElement("script")
$scriptDoctools.setAttribute("src", "_static/doctools.js?v=9bcbadda")
$headElement.appendChild($scriptDoctools)

$scriptHighlight = $HTMLDocument.createElement("script")
$scriptHighlight.setAttribute("src", "_static/sphinx_highlight.js?v=dc90522c")
$headElement.appendChild($scriptHighlight)

# Navigation links
$linkSearch = $HTMLDocument.createElement("link")
$linkSearch.setAttribute("rel", "search")
$linkSearch.setAttribute("title", "Search")
$linkSearch.setAttribute("href", "search.html")
$headElement.appendChild($linkSearch)

$linkNext = $HTMLDocument.createElement("link")
$linkNext.setAttribute("rel", "next")
$linkNext.setAttribute("title", "README")
$linkNext.setAttribute("href", "install/readme.html")
$headElement.appendChild($linkNext)

$htmlElement.appendChild($headElement)

# Body section
$bodyElement = $HTMLDocument.createElement("body")

# Header wrapper
$headerWrapper = $HTMLDocument.createElement("div")
$headerWrapper.setAttribute("class", "header-wrapper")
$headerWrapper.setAttribute("role", "banner")

$headerDiv = $HTMLDocument.createElement("div")
$headerDiv.setAttribute("class", "header")

$headertitleDiv = $HTMLDocument.createElement("div")
$headertitleDiv.setAttribute("class", "headertitle")
$headertitleLink = $HTMLDocument.createElement("a")
$headertitleLink.setAttribute("href", "#")
$headertitleLinkTextNode = $HTMLDocument.createTextNode("Eggdrop 1.10.1 documentation")
$headertitleLink.appendChild($headertitleLinkTextNode)
$headertitleDiv.appendChild($headertitleLink)

$relDiv = $HTMLDocument.createElement("div")
$relDiv.setAttribute("class", "rel")
$relDiv.setAttribute("role", "navigation")
$relDiv.setAttribute("aria-label", "related navigation")
$relLink = $HTMLDocument.createElement("a")
$relLink.setAttribute("href", "install/readme.html")
$relLink.setAttribute("title", "README")
$relLink.setAttribute("accesskey", "N")
$relLinkTextNode = $HTMLDocument.createTextNode("next")
$relLink.appendChild($relLinkTextNode)
$relDiv.appendChild($relLink)

$headerDiv.appendChild($headertitleDiv)
$headerDiv.appendChild($relDiv)
$headerWrapper.appendChild($headerDiv)
$bodyElement.appendChild($headerWrapper)

# Content wrapper
$contentWrapper = $HTMLDocument.createElement("div")
$contentWrapper.setAttribute("class", "content-wrapper")

$contentDiv = $HTMLDocument.createElement("div")
$contentDiv.setAttribute("class", "content")

# Sidebar
$sidebarDiv = $HTMLDocument.createElement("div")
$sidebarDiv.setAttribute("class", "sidebar")

# Table of contents sections
function Add-CaptionSection {
    param([string]$text)
    
    $pCaption = $HTMLDocument.createElement("p")
    $pCaption.setAttribute("class", "caption")
    $pCaption.setAttribute("role", "heading")
    $spanCaption = $HTMLDocument.createElement("span")
    $spanCaption.setAttribute("class", "caption-text")
    $spanCaptionTextNode = $HTMLDocument.createTextNode($text)
    $spanCaption.appendChild($spanCaptionTextNode)
    $pCaption.appendChild($spanCaption)
    $sidebarDiv.appendChild($pCaption)
}

function Add-ToctreeList {
    param([array]$items)
    
    $ulList = $HTMLDocument.createElement("ul")
    foreach ($item in $items) {
        $liItem = $HTMLDocument.createElement("li")
        $liItem.setAttribute("class", "toctree-l1")
        $aRef = $HTMLDocument.createElement("a")
        $aRef.setAttribute("class", "reference internal")
        $aRef.setAttribute("href", $item.href)
        $aRefTextNode = $HTMLDocument.createTextNode($item.text)
        $aRef.appendChild($aRefTextNode)
        $liItem.appendChild($aRef)
        $ulList.appendChild($liItem)
    }
    $sidebarDiv.appendChild($ulList)
}

Add-CaptionSection -text "Installing Eggdrop"
Add-ToctreeList -items @(
    @{ text = "README"; href = "install/readme.html" },
    @{ text = "Installing Eggdrop"; href = "install/install.html" },
    @{ text = "Upgrading Eggdrop"; href = "install/upgrading.html" }
)

Add-CaptionSection -text "Using Eggdrop"
Add-ToctreeList -items @(
    @{ text = "Eggdrop Features"; href = "using/features.html" },
    @{ text = "Eggdrop Core Settings"; href = "using/core.html" },
    @{ text = "The Party Line"; href = "using/partyline.html" },
    @{ text = "Eggdrop Autoscripts"; href = "using/autoscripts.html" },
    @{ text = "Users and Flags"; href = "using/users.html" },
    @{ text = "Bans, Invites, and Exempts"; href = "using/bans.html" },
    @{ text = "Botnet Sharing and Linking"; href = "using/botnet.html" },
    @{ text = "IPv6 support"; href = "using/ipv6.html" },
    @{ text = "TLS support"; href = "using/tls.html" },
    @{ text = "IRCv3 support"; href = "using/ircv3.html" },
    @{ text = "Account tracking in Eggdrop"; href = "using/accounts.html" },
    @{ text = "Encryption/Hashing"; href = "using/pbkdf2info.html" },
    @{ text = "Using the Python Module"; href = "using/python.html" },
    @{ text = "Twitch"; href = "using/twitchinfo.html" },
    @{ text = "Advanced Tips"; href = "using/tricks.html" },
    @{ text = "Textfile Substitutions"; href = "using/text-sub.html" },
    @{ text = "Eggdrop Tcl Commands"; href = "using/tcl-commands.html" },
    @{ text = "Eggdrop Twitch Tcl Commands"; href = "using/twitch-tcl-commands.html" },
    @{ text = "Patching Eggdrop"; href = "using/patch.html" }
)

Add-CaptionSection -text "Tutorials"
Add-ToctreeList -items @(
    @{ text = "Setting Up Eggdrop"; href = "tutorials/setup.html" },
    @{ text = "Common First Steps"; href = "tutorials/firststeps.html" },
    @{ text = "Enabling TLS Security on Eggdrop"; href = "tutorials/tlssetup.html" },
    @{ text = "Sharing Userfiles"; href = "tutorials/userfilesharing.html" },
    @{ text = "Writing an Eggdrop Tcl Script"; href = "tutorials/firstscript.html" },
    @{ text = "Writing a Basic Eggdrop Module"; href = "tutorials/module.html" }
)

Add-CaptionSection -text "Eggdrop Modules"
Add-ToctreeList -items @(
    @{ text = "Eggdrop Module Information"; href = "modules/index.html" },
    @{ text = "Modules included with Eggdrop"; href = "modules/included.html" },
    @{ text = "How to Write an Eggdrop Module"; href = "modules/writing.html" },
    @{ text = "Eggdrop Bind Internals"; href = "modules/internals.html" }
)

Add-CaptionSection -text "About Eggdrop"
Add-ToctreeList -items @(
    @{ text = "About Eggdrop"; href = "about/about.html" },
    @{ text = "Boring legal stuff"; href = "about/legal.html" }
)

# Search form
$searchDiv = $HTMLDocument.createElement("div")
$searchDiv.setAttribute("role", "search")
$h3Search = $HTMLDocument.createElement("h3")
$h3Search.setAttribute("style", "margin-top: 1.5em;")
$h3SearchTextNode = $HTMLDocument.createTextNode("Search")
$h3Search.appendChild($h3SearchTextNode)
$searchDiv.appendChild($h3Search)

$searchForm = $HTMLDocument.createElement("form")
$searchForm.setAttribute("class", "search")
$searchForm.setAttribute("action", "search.html")
$searchForm.setAttribute("method", "get")
$inputText = $HTMLDocument.createElement("input")
$inputText.setAttribute("type", "text")
$inputText.setAttribute("name", "q")
$searchForm.appendChild($inputText)
$inputSubmit = $HTMLDocument.createElement("input")
$inputSubmit.setAttribute("type", "submit")
$inputSubmit.setAttribute("value", "Go")
$searchForm.appendChild($inputSubmit)
$searchDiv.appendChild($searchForm)

$sidebarDiv.appendChild($searchDiv)
$contentDiv.appendChild($sidebarDiv)

# Document section
$documentDiv = $HTMLDocument.createElement("div")
$documentDiv.setAttribute("class", "document")

$documentwrapperDiv = $HTMLDocument.createElement("div")
$documentwrapperDiv.setAttribute("class", "documentwrapper")

$bodywrapperDiv = $HTMLDocument.createElement("div")
$bodywrapperDiv.setAttribute("class", "bodywrapper")

$bodyDiv = $HTMLDocument.createElement("div")
$bodyDiv.setAttribute("class", "body")
$bodyDiv.setAttribute("role", "main")

# Main content sections
$sectionMain = $HTMLDocument.createElement("section")
$sectionMain.setAttribute("id", "eggdrop-an-open-source-irc-bot")

$h1Title = $HTMLDocument.createElement("h1")
$aHeaderLink = $HTMLDocument.createElement("a")
$aHeaderLink.setAttribute("class", "headerlink")
$aHeaderLink.setAttribute("href", "#eggdrop-an-open-source-irc-bot")
$aHeaderLink.setAttribute("title", "Link to this heading")
$aHeaderLinkTextNode = $HTMLDocument.createTextNode("¶")
$aHeaderLink.appendChild($aHeaderLinkTextNode)
$h1TitleTextNode = $HTMLDocument.createTextNode("Eggdrop, an open source IRC bot")
$h1Title.appendChild($h1TitleTextNode)
$h1Title.appendChild($aHeaderLink)
$sectionMain.appendChild($h1Title)

$pDescription = $HTMLDocument.createElement("p")
$pDescriptionTextNode = $HTMLDocument.createTextNode("Eggdrop is a free, open source software program built to assist in managing an IRC channel. It is the world’s oldest actively-maintained IRC bot and was designed to be easily used and expanded on via it’s ability to run Tcl scripts. Eggdrop can join IRC channels and perorm automated tasks such as protecting the channel from abuse, assisting users obtain their op/voice status, provide information and greetings, host games, etc.")
$pDescription.appendChild($pDescriptionTextNode)
$sectionMain.appendChild($pDescription)

# Sub-sections
$sectionThings = $HTMLDocument.createElement("section")
$sectionThings.setAttribute("id", "some-things-you-can-do-with-eggdrop")

$h2Things = $HTMLDocument.createElement("h2")
$aThingsLink = $HTMLDocument.createElement("a")
$aThingsLink.setAttribute("class", "headerlink")
$aThingsLink.setAttribute("href", "#some-things-you-can-do-with-eggdrop")
$aThingsLink.setAttribute("title", "Link to this heading")
$aThingsLinkTextNode = $HTMLDocument.createTextNode("¶")
$aThingsLink.appendChild($aThingsLinkTextNode)
$h2ThingsTextNode = $HTMLDocument.createTextNode("Some things you can do with Eggdrop")
$h2Things.appendChild($h2ThingsTextNode)
$h2Things.appendChild($aThingsLink)
$sectionThings.appendChild($h2Things)

$pFeaturesIntro = $HTMLDocument.createElement("p")
$pFeaturesIntroTextNode = $HTMLDocument.createTextNode("Eggdrop has a large number of features, such as:")
$pFeaturesIntro.appendChild($pFeaturesIntroTextNode)
$sectionThings.appendChild($pFeaturesIntro)

$ulFeatures = $HTMLDocument.createElement("ul")
$ulFeatures.setAttribute("class", "simple")

$liFeature1 = $HTMLDocument.createElement("li")
$aFeature1 = $HTMLDocument.createElement("a")
$aFeature1.setAttribute("class", "reference external")
$aFeature1.setAttribute("href", "using/users.html")
$aFeature1TextNode = $HTMLDocument.createTextNode("Channel Management")
$aFeature1.appendChild($aFeature1TextNode)
$liFeature1.appendChild($aFeature1)
$ulFeatures.appendChild($liFeature1)

$liFeature2 = $HTMLDocument.createElement("li")
$pFeature2 = $HTMLDocument.createElement("p")
$aFeature2 = $HTMLDocument.createElement("a")
$aFeature2TextNode = $HTMLDocument.createTextNode("Running Tcl Scripts")
$aFeature2.appendChild($aFeature2TextNode)
$pFeature2.appendChild($aFeature2)
$liFeature2.appendChild($pFeature2)
$ulFeatures.appendChild($liFeature2)

$liFeature3 = $HTMLDocument.createElement("li")
$aFeature3 = $HTMLDocument.createElement("a")
$aFeature3.setAttribute("class", "reference external")
$aFeature3.setAttribute("href", "using/ircv3.html")
$aFeature3TextNode = $HTMLDocument.createTextNode("Integration of the most current IRCv3 capabilities")
$aFeature3.appendChild($aFeature3TextNode)
$liFeature3.appendChild($aFeature3)
$ulFeatures.appendChild($liFeature3)

$liFeature4 = $HTMLDocument.createElement("li")
$aFeature4 = $HTMLDocument.createElement("a")
$aFeature4.setAttribute("class", "reference external")
$aFeature4.setAttribute("href", "using/botnet.html")
$aFeature4TextNode = $HTMLDocument.createTextNode("The ability to link multiple Eggdrops together and share userfiles")
$aFeature4.appendChild($aFeature4TextNode)
$liFeature4.appendChild($aFeature4)
$ulFeatures.appendChild($liFeature4)

$liFeature5 = $HTMLDocument.createElement("li")
$aFeature5 = $HTMLDocument.createElement("a")
$aFeature5.setAttribute("class", "reference external")
$aFeature5.setAttribute("href", "using/tls.html")
$aFeature5TextNode = $HTMLDocument.createTextNode("TLS Support")
$aFeature5.appendChild($aFeature5TextNode)
$liFeature5.appendChild($aFeature5)
$ulFeatures.appendChild($liFeature5)

$liFeature6 = $HTMLDocument.createElement("li")
$aFeature6 = $HTMLDocument.createElement("a")
$aFeature6.setAttribute("class", "reference external")
$aFeature6.setAttribute("href", "using/ipv6.html")
$aFeature6TextNode = $HTMLDocument.createTextNode("IPv6 Support")
$aFeature6.appendChild($aFeature6TextNode)
$liFeature6.appendChild($aFeature6)
$ulFeatures.appendChild($liFeature6)

$liFeature7 = $HTMLDocument.createElement("li")
$aFeature7 = $HTMLDocument.createElement("a")
$aFeature7.setAttribute("class", "reference external")
$aFeature7.setAttribute("href", "using/twitchinfo.html")
$aFeature7TextNode = $HTMLDocument.createTextNode("Twitch Support")
$aFeature7.appendChild($aFeature7TextNode)
$liFeature7.appendChild($aFeature7)
$ulFeatures.appendChild($liFeature7)

$liFeature8 = $HTMLDocument.createElement("li")
$pFeature8 = $HTMLDocument.createElement("p")
$pFeature8TextNode = $HTMLDocument.createTextNode("… and much much more!")
$pFeature8.appendChild($pFeature8TextNode)
$liFeature8.appendChild($pFeature8)
$ulFeatures.appendChild($liFeature8)

$sectionThings.appendChild($ulFeatures)
$sectionMain.appendChild($sectionThings)

# How to get Eggdrop section
$sectionGet = $HTMLDocument.createElement("section")
$sectionGet.setAttribute("id", "how-to-get-eggdrop")

$h2Get = $HTMLDocument.createElement("h2")
$aGetLink = $HTMLDocument.createElement("a")
$aGetLink.setAttribute("class", "headerlink")
$aGetLink.setAttribute("href", "#how-to-get-eggdrop")
$aGetLink.setAttribute("title", "Link to this heading")
$aGetLinkTextNode = $HTMLDocument.createTextNode("¶")
$aGetLink.appendChild($aGetLinkTextNode)
$h2GetTextNode = $HTMLDocument.createTextNode("How to get Eggdrop")
$h2Get.appendChild($h2GetTextNode)
$h2Get.appendChild($aGetLink)
$sectionGet.appendChild($h2Get)

$pGetInfo = $HTMLDocument.createElement("p")
$aGitHub = $HTMLDocument.createElement("a")
$aGitHub.setAttribute("class", "reference external")
$aGitHub.setAttribute("href", "https://github.com/eggheads/eggdrop")
$aGitHubTextNode = $HTMLDocument.createTextNode("https://github.com/eggheads/eggdrop")
$aGitHub.appendChild($aGitHubTextNode)
$pGetInfoTextNode1 = $HTMLDocument.createTextNode("The Eggdrop project source code is hosted at ")
$pGetInfoTextNode2 = $HTMLDocument.createTextNode(". You can clone it via git, or alternatively a copy of the current stable snapshot is located at ")
$aStable = $HTMLDocument.createElement("a")
$aStable.setAttribute("class", "reference external")
$aStable.setAttribute("href", "https://geteggdrop.com")
$aStableTextNode = $HTMLDocument.createTextNode("https://geteggdrop.com")
$aStable.appendChild($aStableTextNode)
$pGetInfoTextNode3 = $HTMLDocument.createTextNode(". Additional information can be found on the official Eggdrop webpage at ")
$aWebpage = $HTMLDocument.createElement("a")
$aWebpage.setAttribute("class", "reference external")
$aWebpage.setAttribute("href", "https://www.eggheads.org")
$aWebpageTextNode = $HTMLDocument.createTextNode("https://www.eggheads.org")
$aWebpage.appendChild($aWebpageTextNode)
$pGetInfoTextNode4 = $HTMLDocument.createTextNode(". For more information, see ")
$aInstall = $HTMLDocument.createElement("a")
$aInstall.setAttribute("class", "reference external")
$aInstall.setAttribute("href", "install/install.html")
$aInstallTextNode = $HTMLDocument.createTextNode("Installing Eggdrop")
$aInstall.appendChild($aInstallTextNode)
$pGetInfoTextNode5 = $HTMLDocument.createTextNode("")
$pGetInfo.appendChild($pGetInfoTextNode1)
$pGetInfo.appendChild($aGitHub)
$pGetInfo.appendChild($pGetInfoTextNode2)
$pGetInfo.appendChild($aStable)
$pGetInfo.appendChild($pGetInfoTextNode3)
$pGetInfo.appendChild($aWebpage)
$pGetInfo.appendChild($pGetInfoTextNode4)
$pGetInfo.appendChild($aInstall)
$pGetInfo.appendChild($pGetInfoTextNode5)
$sectionGet.appendChild($pGetInfo)
$sectionMain.appendChild($sectionGet)

# Installation sections
$sectionInstall = $HTMLDocument.createElement("section")
$sectionInstall.setAttribute("id", "how-to-install-eggdrop")

$h2Install = $HTMLDocument.createElement("h2")
$aInstallLink = $HTMLDocument.createElement("a")
$aInstallLink.setAttribute("class", "headerlink")
$aInstallLink.setAttribute("href", "#how-to-install-eggdrop")
$aInstallLink.setAttribute("title", "Link to this heading")
$aInstallLinkTextNode = $HTMLDocument.createTextNode("¶")
$aInstallLink.appendChild($aInstallLinkTextNode)
$h2InstallTextNode = $HTMLDocument.createTextNode("How to install Eggdrop")
$h2Install.appendChild($h2InstallTextNode)
$h2Install.appendChild($aInstallLink)
$sectionInstall.appendChild($h2Install)

$sectionPreReq = $HTMLDocument.createElement("section")
$sectionPreReq.setAttribute("id", "installation-pre-requisites")

$h3PreReq = $HTMLDocument.createElement("h3")
$aPreReqLink = $HTMLDocument.createElement("a")
$aPreReqLink.setAttribute("class", "headerlink")
$aPreReqLink.setAttribute("href", "#installation-pre-requisites")
$aPreReqLink.setAttribute("title", "Link to this heading")
$aPreReqLinkTextNode = $HTMLDocument.createTextNode("¶")
$aPreReqLink.appendChild($aPreReqLinkTextNode)
$h3PreReqTextNode = $HTMLDocument.createTextNode("Installation Pre-requisites")
$h3PreReq.appendChild($h3PreReqTextNode)
$h3PreReq.appendChild($aPreReqLink)
$sectionPreReq.appendChild($h3PreReq)

$pPreReq = $HTMLDocument.createElement("p")
$pPreReqTextNode = $HTMLDocument.createTextNode("Eggdrop requires Tcl (and its development header files) to be present on the system it is compiled on. It is also strongly encouraged to install openssl (and its development header files) to enable TLS-protected network communication.")
$pPreReq.appendChild($pPreReqTextNode)
$sectionPreReq.appendChild($pPreReq)
$sectionInstall.appendChild($sectionPreReq)

$sectionInstallGuide = $HTMLDocument.createElement("section")
$sectionInstallGuide.setAttribute("id", "installation")

$h3Install = $HTMLDocument.createElement("h3")
$aInstallGuideLink = $HTMLDocument.createElement("a")
$aInstallGuideLink.setAttribute("class", "headerlink")
$aInstallGuideLink.setAttribute("href", "#installation")
$aInstallGuideLink.setAttribute("title", "Link to this heading")
$aInstallGuideLinkTextNode = $HTMLDocument.createTextNode("¶")
$aInstallGuideLink.appendChild($aInstallGuideLinkTextNode)
$h3InstallTextNode = $HTMLDocument.createTextNode("Installation")
$h3Install.appendChild($h3InstallTextNode)
$h3Install.appendChild($aInstallGuideLink)
$sectionInstallGuide.appendChild($h3Install)

$pInstallGuide = $HTMLDocument.createElement("p")
$aInstallReadme = $HTMLDocument.createElement("a")
$aInstallReadme.setAttribute("class", "reference external")
$aInstallReadme.setAttribute("href", "install/readme.html")
$aInstallReadmeTextNode = $HTMLDocument.createTextNode("here")
$aInstallReadme.appendChild($aInstallReadmeTextNode)
$pInstallGuideTextNode = $HTMLDocument.createTextNode("A guide to quickly installing Eggdrop can be found ")
$pInstallGuide.appendChild($pInstallGuideTextNode)
$pInstallGuide.appendChild($aInstallReadme)
$pInstallGuide.appendChild($HTMLDocument.createTextNode("."))
$sectionInstallGuide.appendChild($pInstallGuide)
$sectionInstall.appendChild($sectionInstallGuide)
$sectionMain.appendChild($sectionInstall)

# Where to find more help section
$sectionHelp = $HTMLDocument.createElement("section")
$sectionHelp.setAttribute("id", "where-to-find-more-help")

$h2Help = $HTMLDocument.createElement("h2")
$aHelpLink = $HTMLDocument.createElement("a")
$aHelpLink.setAttribute("class", "headerlink")
$aHelpLink.setAttribute("href", "#where-to-find-more-help")
$aHelpLink.setAttribute("title", "Link to this heading")
$aHelpLinkTextNode = $HTMLDocument.createTextNode("¶")
$aHelpLink.appendChild($aHelpLinkTextNode)
$h2HelpTextNode = $HTMLDocument.createTextNode("Where to find more help")
$h2Help.appendChild($h2HelpTextNode)
$h2Help.appendChild($aHelpLink)
$sectionHelp.appendChild($h2Help)

$pHelp = $HTMLDocument.createElement("p")
$pHelpTextNode = $HTMLDocument.createTextNode("The Eggheads development team can be found lurking on #eggdrop on the Libera network (irc.libera.chat).")
$pHelp.appendChild($pHelpTextNode)
$sectionHelp.appendChild($pHelp)

$bodyDiv.appendChild($sectionMain)
$bodyDiv.appendChild($sectionHelp)
$bodywrapperDiv.appendChild($bodyDiv)
$documentwrapperDiv.appendChild($bodywrapperDiv)
$documentDiv.appendChild($documentwrapperDiv)
$contentDiv.appendChild($documentDiv)
$contentWrapper.appendChild($contentDiv)
$bodyElement.appendChild($contentWrapper)

# Footer wrapper
$footerWrapper = $HTMLDocument.createElement("div")
$footerWrapper.setAttribute("class", "footer-wrapper")

$footerDiv = $HTMLDocument.createElement("div")
$footerDiv.setAttribute("class", "footer")

$leftDiv = $HTMLDocument.createElement("div")
$leftDiv.setAttribute("class", "left")

$navDiv = $HTMLDocument.createElement("div")
$navDiv.setAttribute("role", "navigation")
$navDiv.setAttribute("aria-label", "related navigaton")
$navLink = $HTMLDocument.createElement("a")
$navLink.setAttribute("href", "install/readme.html")
$navLink.setAttribute("title", "README")
$navLinkTextNode = $HTMLDocument.createTextNode("next")
$navLink.appendChild($navLinkTextNode)
$navDiv.appendChild($navLink)

$noteDiv = $HTMLDocument.createElement("div")
$noteDiv.setAttribute("role", "note")
$noteDiv.setAttribute("aria-label", "source link")
$leftDiv.appendChild($navDiv)
$leftDiv.appendChild($noteDiv)

$rightDiv = $HTMLDocument.createElement("div")
$rightDiv.setAttribute("class", "right")

$footerContentDiv = $HTMLDocument.createElement("div")
$footerContentDiv.setAttribute("class", "footer")
$footerContentDiv.setAttribute("role", "contentinfo")
$copyTextNode = $HTMLDocument.createTextNode("© Copyright 2025, Eggheads. Last updated on Aug 15, 2025. Created using ")
$sphinxLink = $HTMLDocument.createElement("a")
$sphinxLink.setAttribute("href", "https://www.sphinx-doc.org/")
$sphinxLinkTextNode = $HTMLDocument.createTextNode("Sphinx")
$sphinxLink.appendChild($sphinxLinkTextNode)
$copyTextNode2 = $HTMLDocument.createTextNode(" 8.2.3.")
$footerContentDiv.appendChild($copyTextNode)
$footerContentDiv.appendChild($sphinxLink)
$footerContentDiv.appendChild($copyTextNode2)
$rightDiv.appendChild($footerContentDiv)

$clearerDiv1 = $HTMLDocument.createElement("div")
$clearerDiv1.setAttribute("class", "clearer")
$rightDiv.appendChild($clearerDiv1)

$footerDiv.appendChild($leftDiv)
$footerDiv.appendChild($rightDiv)

$clearerDiv2 = $HTMLDocument.createElement("div")
$clearerDiv2.setAttribute("class", "clearer")
$footerDiv.appendChild($clearerDiv2)

$footerWrapper.appendChild($footerDiv)
$bodyElement.appendChild($footerWrapper)

$htmlElement.appendChild($bodyElement)

# Save to file
$HTMLDocument.documentElement.innerHTML | Out-File -FilePath $OutputPath -Encoding Utf8
Write-Host "Generated HTML file saved to: $OutputPath"
