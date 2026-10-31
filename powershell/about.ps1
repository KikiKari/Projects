#!/usr/bin/env pwsh
# about.html — portiert nach powershell
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/powershell/about.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/powershell/about.html
# Erzeugt: 2026-10-31 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
    Generates an HTML document similar to the provided about.html file.
.DESCRIPTION
    This script creates a structured HTML document with the same content and 
    metadata as the original about.html file. It outputs the result to a 
    specified file.
.PARAMETER OutputPath
    The path to the output HTML file.
.EXAMPLE
    .\Generate-AboutHtml.ps1 -OutputPath "about.html"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Create HTML document structure
$docType = "<!DOCTYPE html>"
$html = @"
<html
    class="layout layout-holy-grail   show-table-of-contents conceptual show-breadcrumb default-focus"
    lang="en-us"
    dir="ltr"
    data-authenticated="false"
    data-auth-status-determined="false"
    data-target="docs"
    x-ms-format-detection="none"
>
</html>
"@

# Parse HTML to allow manipulation
$htmlDoc = New-Object -ComObject "HTMLFile"
$htmlDoc.write($html)
$body = $htmlDoc.body
$head = $htmlDoc.head

# Set document title
$title = $htmlDoc.createElement("title")
$title.innerText = "About topics - PowerShell | Microsoft Learn"
$head.appendChild($title) | Out-Null

# Add meta tags
$metaTags = @(
    @{name="charset"; content="utf-8"},
    @{name="viewport"; content="width=device-width, initial-scale=1.0"},
    @{name="color-scheme"; content="light dark"},
    @{name="description"; content="About topics cover a range of concepts about PowerShell."},
    @{name="canonical"; content="https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about?view=powershell-7.6"},
    @{name="twitter:card"; content="summary"},
    @{name="twitter:site"; content="@MicrosoftLearn"},
    @{name="og:type"; content="website"},
    @{name="og:image:alt"; content="About topics - PowerShell | Microsoft Learn"},
    @{name="og:image"; content="https://learn.microsoft.com/media/logos/logo-powershell-social.png"},
    @{name="og:title"; content="About topics - PowerShell"},
    @{name="og:url"; content="https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about?view=powershell-7.6"},
    @{name="og:description"; content="About topics cover a range of concepts about PowerShell."},
    @{name="platform_id"; content="5035edbf-6e09-a6fa-a98d-bb2adc6ab1e0"},
    @{name="scope"; content="PowerShell"},
    @{name="locale"; content="en-us"},
    @{name="uhfHeaderId"; content="MSDocsHeader-Powershell"},
    @{name="page_type"; content="conceptual"},
    @{name="ROBOTS"; content="INDEX, FOLLOW"},
    @{name="apiPlatform"; content="powershell"},
    @{name="archive_url"; content="https://learn.microsoft.com/previous-versions/powershell/scripting/overview"},
    @{name="breadcrumb_path"; content="/powershell/scripting/bread/toc.json"},
    @{name="feedback_product_url"; content="https://github.com/PowerShell/PowerShell/issues/new/choose"},
    @{name="feedback_help_link_url"; content="https://learn.microsoft.com/powershell/scripting/community/community-support"},
    @{name="feedback_help_link_type"; content="ask-the-community"},
    @{name="feedback_system"; content="OpenSource"},
    @{name="hideScope"; content="false"},
    @{name="author"; content="sdwheeler"},
    @{name="ms.author"; content="sewhee"},
    @{name="manager"; content="jasongroce"},
    @{name="ms.devlang"; content="powershell"},
    @{name="ms.service"; content="powershell"},
    @{name="ms.tgt_pltfr"; content="windows, macos, linux"},
    @{name="ms.update-cycle"; content="365-days"},
    @{name="toc_preview"; content="true"},
    @{name="ms.topic"; content="reference"},
    @{name="products"; content="https://authoring-docs-microsoft.poolparty.biz/devrel/2bdae855-045f-4535-b365-7b2e23824328"},
    @{name="products"; content="https://authoring-docs-microsoft.poolparty.biz/devrel/8bce367e-2e90-4b56-9ed5-5e4e9f3a2dc3"},
    @{name="Locale"; content="en-US"},
    @{name="ms.date"; content="2026-01-18T00:00:00Z"},
    @{name="document_id"; content="6d07e1b4-9109-26f3-5a6a-20b41b4c66a5"},
    @{name="document_version_independent_id"; content="2bf88889-d533-2316-9add-a385ebbd4259"},
    @{name="updated_at"; content="2026-04-02T22:11:00Z"},
    @{name="original_content_git_url"; content="https://github.com/MicrosoftDocs/PowerShell-Docs/blob/live/reference/7.6/Microsoft.PowerShell.Core/About/About.md"},
    @{name="gitcommit"; content="https://github.com/MicrosoftDocs/PowerShell-Docs/blob/7baf66776aea350bef39470600f075e85f30d7ef/reference/7.6/Microsoft.PowerShell.Core/About/About.md"},
    @{name="git_commit_id"; content="7baf66776aea350bef39470600f075e85f30d7ef"},
    @{name="monikers"; content="powershell-7.6"},
    @{name="default_moniker"; content="powershell-7.6"},
    @{name="site_name"; content="Docs"},
    @{name="depot_name"; content="PowerShell.PowerShell_PowerShell-docs_reference"},
    @{name="schema"; content="Conceptual"},
    @{name="toc_rel"; content="../../psdocs/toc.json"},
    @{name="word_count"; content="1965"},
    @{name="config_moniker_range"; content="powershell-7.6"},
    @{name="asset_id"; content="module/microsoft.powershell.core/about/about"},
    @{name="moniker_range_name"; content="9b5469a01154ce5be5ffa44dbe12b832"},
    @{name="item_type"; content="Content"},
    @{name="source_path"; content="reference/7.6/Microsoft.PowerShell.Core/About/About.md"},
    @{name="previous_tlsh_hash"; content="A12B7262301D8F2E7BE20B1A341CEF4F17F0448C116A19D0012D2537977E1D634728A866C7361B692370488BB39F759D46E8CE22829C53AA1F9127FE495D6A4EE2CDB7B6FC"},
    @{name="github_feedback_content_git_url"; content="https://github.com/MicrosoftDocs/PowerShell-Docs/blob/main/reference/7.6/Microsoft.PowerShell.Core/About/About.md"},
    @{name="markdown_url"; content="https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about?view=powershell-7.6&amp;accept=text/markdown"}
)

foreach ($meta in $metaTags) {
    $metaElement = $htmlDoc.createElement("meta")
    if ($meta.name -eq "charset") {
        $metaElement.setAttribute("charset", $meta.content)
    } elseif ($meta.name -eq "canonical") {
        $metaElement.setAttribute("rel", $meta.name)
        $metaElement.setAttribute("href", $meta.content)
    } else {
        $metaElement.setAttribute("name", $meta.name)
        $metaElement.setAttribute("content", $meta.content)
    }
    $head.appendChild($metaElement) | Out-Null
}

# Add stylesheet links
$cssLinks = @(
    "/static/assets/0.4.03391.7726-67491f8e/styles/site.css"
)

foreach ($css in $cssLinks) {
    $linkElement = $htmlDoc.createElement("link")
    $linkElement.setAttribute("rel", "stylesheet")
    $linkElement.setAttribute("href", $css)
    $head.appendChild($linkElement) | Out-Null
}

# Add script tags
$scripts = @(
    "https://wcpstatic.microsoft.com/mscc/lib/v2/wcp-consent.js",
    "https://js.monitor.azure.com/scripts/c/ms.jsll-4.min.js",
    "/_themes/docs.theme/master/en-us/_themes/global/deprecation.js"
)

foreach ($src in $scripts) {
    $scriptElement = $htmlDoc.createElement("script")
    $scriptElement.setAttribute("src", $src)
    $head.appendChild($scriptElement) | Out-Null
}

# Add msdocs script
$msdocsScript = $htmlDoc.createElement("script")
$msdocsScript.id = "msdocs-script"
$msdocsScriptText = @"
var msDocs = {
  "environment": {
    "accessLevel": "online",
    "azurePortalHostname": "portal.azure.com",
    "reviewFeatures": false,
    "supportLevel": "production",
    "systemContent": true,
    "siteName": "learn",
    "legacyHosting": false
  },
  "data": {
    "contentLocale": "en-us",
    "contentDir": "ltr",
    "userLocale": "en-us",
    "userDir": "ltr",
    "pageTemplate": "Conceptual",
    "brand": "",
    "context": {},
    "standardFeedback": false,
    "showFeedbackReport": false,
    "feedbackHelpLinkType": "ask-the-community",
    "feedbackHelpLinkUrl": "https://learn.microsoft.com/powershell/scripting/community/community-support",
    "feedbackSystem": "OpenSource",
    "feedbackGitHubRepo": "",
    "feedbackProductUrl": "https://github.com/PowerShell/PowerShell/issues/new/choose",
    "extendBreadcrumb": false,
    "isEditDisplayable": true,
    "isPrivateUnauthorized": false,
    "hideViewSource": false,
    "isPermissioned": false,
    "hasRecommendations": false,
    "contributors": [
      {
        "name": "sdwheeler",
        "url": "https://github.com/sdwheeler"
      },
      {
        "name": "SufficientDaikon",
        "url": "https://github.com/SufficientDaikon"
      },
      {
        "name": "surfingoldelephant",
        "url": "https://github.com/surfingoldelephant"
      }
    ],
    "openSourceFeedbackIssueUrl": "https://github.com/MicrosoftDocs/PowerShell-Docs/issues/new?template=04-customer-feedback.yml",
    "openSourceFeedbackIssueTitle": "",
    "openSourceFeedbackIssueLabels": "needs-triage"
  },
  "functions": {}
};;
"@
$msdocsScript.innerText = $msdocsScriptText
$head.appendChild($msdocsScript) | Out-Null

# Add additional script
$additionalScript = $htmlDoc.createElement("script")
$additionalScript.setAttribute("src", "/static/assets/0.4.03391.7726-67491f8e/scripts/en-us/index-docs.js")
$head.appendChild($additionalScript) | Out-Null

# Create body structure
$header = $htmlDoc.createElement("header")
$header.className = "layout-body-header"
$body.appendChild($header) | Out-Null

# Add skip links
$skipMain = $htmlDoc.createElement("a")
$skipMain.href = "#main"
$skipMain.style = "z-index: 1070"
$skipMain.className = "outline-color-text visually-hidden-until-focused position-fixed inner-focus focus-visible top-0 left-0 right-0 padding-xs text-align-center background-color-body"
$skipMain.innerText = "Skip to main content"
$header.appendChild($skipMain) | Out-Null

$skipAsk = $htmlDoc.createElement("a")
$skipAsk.href = "#"
$skipAsk.setAttribute("data-skip-to-ask-learn", "")
$skipAsk.style = "z-index: 1070"
$skipAsk.className = "outline-color-text visually-hidden-until-focused position-fixed inner-focus focus-visible top-0 left-0 right-0 padding-xs text-align-center background-color-body"
$skipAsk.setAttribute("hidden", "")
$skipAsk.innerText = "Skip to Ask Learn chat experience"
$header.appendChild($skipAsk) | Out-Null

# Add cookie consent holder
$cookieConsent = $htmlDoc.createElement("div")
$cookieConsent.id = "cookie-consent-holder"
$cookieConsent.setAttribute("data-test-id", "cookie-consent-container")
$cookieConsent.setAttribute("hidden", "")
$header.appendChild($cookieConsent) | Out-Null

# Add unsupported browser warning
$unsupportedBrowser = $htmlDoc.createElement("div")
$unsupportedBrowser.id = "unsupported-browser"
$unsupportedBrowser.style = "background-color: white; color: black; padding: 16px; border-bottom: 1px solid grey;"
$unsupportedBrowser.setAttribute("hidden", "")
$browserContent = @"
<div style="max-width: 800px; margin: 0 auto;">
    <p style="font-size: 24px">This browser is no longer supported.</p>
    <p style="font-size: 16px; margin-top: 16px;">
        Upgrade to Microsoft Edge to take advantage of the latest features, security updates, and technical support.
    </p>
    <div style="margin-top: 12px;">
        <a
            href="https://go.microsoft.com/fwlink/p/?LinkID=2092881 "
            style="background-color: #0078d4; border: 1px solid #0078d4; color: white; padding: 6px 12px; border-radius: 2px; display: inline-block;"
        >
            Download Microsoft Edge
        </a>
        <a
            href="https://learn.microsoft.com/en-us/lifecycle/faq/internet-explorer-microsoft-edge"
            style="background-color: white; padding: 6px 12px; border: 1px solid #505050; color: #171717; border-radius: 2px; display: inline-block;"
        >
            More info about Internet Explorer and Microsoft Edge
        </a>
    </div>
</div>
"@
$unsupportedBrowser.innerHTML = $browserContent
$header.appendChild($unsupportedBrowser) | Out-Null

# Add site header
$siteHeader = $htmlDoc.createElement("div")
$siteHeader.id = "ms--site-header"
$siteHeader.setAttribute("data-test-id", "site-header-wrapper")
$siteHeader.setAttribute("itemscope", "")
$siteHeader.setAttribute("itemtype", "http://schema.org/Organization")
$header.appendChild($siteHeader) | Out-Null

# Add mobile nav
$mobileNav = $htmlDoc.createElement("div")
$mobileNav.id = "ms--mobile-nav"
$mobileNav.className = "site-header display-none-tablet padding-inline-none gap-none"
$mobileNav.setAttribute("data-bi-name", "mobile-header")
$mobileNav.setAttribute("data-test-id", "mobile-header")
$siteHeader.appendChild($mobileNav) | Out-Null

# Add primary nav
$primaryNav = $htmlDoc.createElement("div")
$primaryNav.id = "ms--primary-nav"
$primaryNav.className = "site-header display-none display-flex-tablet"
$primaryNav.setAttribute("data-bi-name", "L1-header")
$primaryNav.setAttribute("data-test-id", "primary-header")
$siteHeader.appendChild($primaryNav) | Out-Null

# Add secondary nav
$secondaryNav = $htmlDoc.createElement("div")
$secondaryNav.id = "ms--secondary-nav"
$secondaryNav.className = "site-header display-none display-flex-tablet"
$secondaryNav.setAttribute("data-bi-name", "L2-header")
$secondaryNav.setAttribute("data-test-id", "secondary-header")
$siteHeader.appendChild($secondaryNav) | Out-Null

# Add banner
$banner = $htmlDoc.createElement("div")
$banner.setAttribute("data-banner", "")
$header.appendChild($banner) | Out-Null

$disclaimerHolder = $htmlDoc.createElement("div")
$disclaimerHolder.id = "disclaimer-holder"
$banner.appendChild($disclaimerHolder) | Out-Null

# Add layout body menu
$menuSection = $htmlDoc.createElement("section")
$menuSection.id = "layout-body-menu"
$menuSection.className = "layout-body-menu display-flex"
$menuSection.setAttribute("data-bi-name", "menu")
$body.appendChild($menuSection) | Out-Null

$leftContainer = $htmlDoc.createElement("div")
$leftContainer.id = "left-container"
$leftContainer.className = "left-container display-none display-block-tablet padding-inline-sm padding-bottom-sm width-full"
$leftContainer.setAttribute("data-toc-container", "true")
$menuSection.appendChild($leftContainer) | Out-Null

$tocContent = $htmlDoc.createElement("div")
$tocContent.id = "ms--toc-content"
$tocContent.className = "height-full"
$leftContainer.appendChild($tocContent) | Out-Null

$nav = $htmlDoc.createElement("nav")
$nav.id = "affixed-left-container"
$nav.className = "margin-top-sm-tablet position-sticky display-flex flex-direction-column"
$nav.setAttribute("aria-label", "Primary")
$nav.setAttribute("data-bi-name", "left-toc")
$nav.setAttribute("role", "navigation")
$tocContent.appendChild($nav) | Out-Null

# Add collapsible TOC content
$tocCollapsible = $htmlDoc.createElement("div")
$tocCollapsible.id = "ms--toc-content-collapsible"
$tocCollapsible.className = "height-full"
$tocCollapsible.setAttribute("hidden", "")
$leftContainer.appendChild($tocCollapsible) | Out-Null

$collapsibleNav = $htmlDoc.createElement("nav")
$collapsibleNav.id = "affixed-left-container"
$collapsibleNav.className = "margin-top-sm-tablet position-sticky display-flex flex-direction-column"
$collapsibleNav.setAttribute("aria-label", "Primary")
$collapsibleNav.setAttribute("data-bi-name", "left-toc")
$collapsibleNav.setAttribute("role", "navigation")
$tocCollapsible.appendChild($collapsibleNav) | Out-Null

$tocHeader = $htmlDoc.createElement("div")
$tocHeader.id = "ms--collapsible-toc-header"
$tocHeader.className = "display-flex flex-direction-row-reverse justify-content-space-between align-items-center margin-bottom-xxs"
$collapsibleNav.appendChild($tocHeader) | Out-Null

$tocButton = $htmlDoc.createElement("button")
$tocButton.type = "button"
$tocButton.className = "button button-clear inner-focus"
$tocButton.setAttribute("data-collapsible-toc-toggle", "")
$tocButton.setAttribute("aria-expanded", "true")
$tocButton.setAttribute("aria-controls", "ms--collapsible-toc-content")
$tocButton.setAttribute("aria-label", "Table of contents")
$tocHeader.appendChild($tocButton) | Out-Null

$tocIcon = $htmlDoc.createElement("span")
$tocIcon.className = "icon font-size-xxl"
$tocIcon.setAttribute("aria-hidden", "true")
$tocButton.appendChild($tocIcon) | Out-Null

$panelIcon = $htmlDoc.createElement("span")
$panelIcon.className = "docon docon-panel-left-contract"
$tocIcon.appendChild($panelIcon) | Out-Null

$tocMonikerSlot = $htmlDoc.createElement("div")
$tocMonikerSlot.id = "ms--collapsible-toc-moniker-slot"
$tocMonikerSlot.className = "flex-grow-1"
$tocHeader.appendChild($tocMonikerSlot) | Out-Null

# Add main content area
$main = $htmlDoc.createElement("main")
$main.id = "main"
$main.setAttribute("role", "main")
$main.className = "layout-body-main "
$main.setAttribute("data-bi-name", "content")
$main.setAttribute("lang", "en-us")
$main.setAttribute("dir", "ltr")
$body.appendChild($main) | Out-Null

$contentHeader = $htmlDoc.createElement("div")
$contentHeader.id = "ms--content-header"
$contentHeader.className = "content-header default-focus border-bottom-none"
$contentHeader.setAttribute("data-bi-name", "content-header")
$main.appendChild($contentHeader) | Out-Null

$contentHeaderControls = $htmlDoc.createElement("div")
$contentHeaderControls.className = "content-header-controls margin-xxs margin-inline-sm-tablet"
$contentHeader.appendChild($contentHeaderControls) | Out-Null

$contentsButton = $htmlDoc.createElement("button")
$contentsButton.type = "button"
$contentsButton.className = "contents-button button button-sm margin-right-xxs"
$contentsButton.setAttribute("data-bi-name", "contents-expand")
$contentsButton.setAttribute("aria-haspopup", "true")
$contentsButton.setAttribute("data-contents-button", "")
$contentHeaderControls.appendChild($contentsButton) | Out-Null

$contentsIcon = $htmlDoc.createElement("span")
$contentsIcon.className = "icon"
$contentsIcon.setAttribute("aria-hidden", "true")
$contentsButton.appendChild($contentsIcon) | Out-Null

$menuIcon = $htmlDoc.createElement("span")
$menuIcon.className = "docon docon-menu"
$contentsIcon.appendChild($menuIcon) | Out-Null

$contentsTitle = $htmlDoc.createElement("span")
$contentsTitle.className = "contents-expand-title"
$contentsTitle.innerText = " Table of contents "
$contentsButton.appendChild($contentsTitle) | Out-Null

$collapseButton = $htmlDoc.createElement("button")
$collapseButton.type = "button"
$collapseButton.className = "ap-collapse-behavior ap-expanded button button-sm"
$collapseButton.setAttribute("data-bi-name", "ap-collapse")
$collapseButton.setAttribute("aria-controls", "action-panel")
$contentHeaderControls.appendChild($collapseButton) | Out-Null

$exitIcon = $htmlDoc.createElement("span")
$exitIcon.className = "icon"
$exitIcon.setAttribute("aria-hidden", "true")
$collapseButton.appendChild($exitIcon) | Out-Null

$exitModeIcon = $htmlDoc.createElement("span")
$exitModeIcon.className = "docon docon-exit-mode"
$exitIcon.appendChild($exitModeIcon) | Out-Null

$collapseText = $htmlDoc.createElement("span")
$collapseText.innerText = "Exit editor mode"
$collapseButton.appendChild($collapseText) | Out-Null

$mainPadding = $htmlDoc.createElement("div")
$mainPadding.setAttribute("data-main-column", "")
$mainPadding.className = "padding-sm padding-top-none padding-top-sm-tablet"
$main.appendChild($mainPadding) | Out-Null

$articleDiv = $htmlDoc.createElement("div")
$mainPadding.appendChild($articleDiv) | Out-Null

$articleHeader = $htmlDoc.createElement("div")
$articleHeader.id = "article-header"
$articleHeader.className = "background-color-body margin-bottom-xs display-none-print"
$articleDiv.appendChild($articleHeader) | Out-Null

$headerContent = $htmlDoc.createElement("div")
$headerContent.className = "display-flex align-items-center justify-content-space-between"
$articleHeader.appendChild($headerContent) | Out-Null

$breadcrumbsDetails = $htmlDoc.createElement("details")
$breadcrumbsDetails.id = "article-header-breadcrumbs-overflow-popover"
$breadcrumbsDetails.className = "popover"
$breadcrumbsDetails.setAttribute("data-for", "article-header-breadcrumbs")
$headerContent.appendChild($breadcrumbsDetails) | Out-Null

$breadcrumbsSummary = $htmlDoc.createElement("summary")
$breadcrumbsSummary.className = "button button-clear button-primary button-sm inner-focus"
$breadcrumbsSummary.setAttribute("aria-label", "All breadcrumbs")
$breadcrumbsDetails.appendChild($breadcrumbsSummary) | Out-Null

$moreIcon = $htmlDoc.createElement("span")
$moreIcon.className = "icon"
$moreIcon.setAttribute("aria-hidden", "true")
$breadcrumbsSummary.appendChild($moreIcon) | Out-Null

$moreDocon = $htmlDoc.createElement("span")
$moreDocon.className = "docon docon-more"
$moreIcon.appendChild($moreDocon) | Out-Null

$breadcrumbsOverflow = $htmlDoc.createElement("div")
$breadcrumbsOverflow.id = "article-header-breadcrumbs-overflow"
$breadcrumbsOverflow.className = "popover-content padding-none"
$breadcrumbsDetails.appendChild($breadcrumbsOverflow) | Out-Null

$breadcrumbs = $htmlDoc.createElement("bread-crumbs")
$breadcrumbs.id = "article-header-breadcrumbs"
$breadcrumbs.setAttribute("role", "group")
$breadcrumbs.setAttribute("aria-label", "Breadcrumbs")
$breadcrumbs.setAttribute("data-test-id", "article-header-breadcrumbs")
$breadcrumbs.className = "overflow-hidden flex-grow-1 margin-right-sm margin-right-md-tablet margin-right-lg-desktop margin-left-negative-xxs padding-left-xxs"
$headerContent.appendChild($breadcrumbs) | Out-Null

$pageActions = $htmlDoc.createElement("div")
$pageActions.id = "article-header-page-actions"
$pageActions.className = "opacity-none margin-left-auto display-flex flex-wrap-no-wrap align-items-stretch"
$headerContent.appendChild($pageActions) | Out-Null

# Add Ask Learn buttons
$askButtons = @(
    @{className="button button-sm border-none inner-focus display-none-tablet flex-shrink-0 "; data="ask-learn-modal-entry"; type="button"; ariaLabel="Ask Learn"; hidden=$true},
    @{className="button button-sm display-none display-inline-flex-tablet display-none-desktop flex-shrink-0 margin-right-xxs border-color-ask-learn "; data="ask-learn-modal-entry"; type="button"; hidden=$true},
    @{className="button button-sm display-none flex-shrink-0 display-inline-flex-desktop margin-right-xxs border-color-ask-learn "; data="ask-learn-flyout-entry"; type="button"; hidden=$true}
)

foreach ($btn in $askButtons) {
    $askButton = $htmlDoc.createElement("button")
    $askButton.className = $btn.className
    $askButton.setAttribute("data-bi-name", "ask-learn-assistant-entry")
    $askButton.setAttribute("data-test-id", "ask-learn-assistant-modal-entry-mobile")
    $askButton.setAttribute("data-$($btn.data)", "")
    $askButton.type = $btn.type
    $askButton.style = "min-width: max-content;"
    $askButton.setAttribute("aria-expanded", "false")
    $askButton.setAttribute("aria-label", $btn.ariaLabel)
    if ($btn.hidden) { $askButton.setAttribute("hidden", "") }
    $pageActions.appendChild($askButton) | Out-Null
    
    $sparkleIcon = $htmlDoc.createElement("span")
    $sparkleIcon.className = "icon font-size-lg"
    $sparkleIcon.setAttribute("aria-hidden", "true")
    $askButton.appendChild($sparkleIcon) | Out-Null
    
    $sparkleDocon = $htmlDoc.createElement("span")
    $sparkleDocon.className = "docon docon-chat-sparkle-fill gradient-ask-learn-logo"
    $sparkleIcon.appendChild($sparkleDocon) | Out-Null
    
    if ($btn.className -ne "button button-sm border-none inner-focus display-none-tablet flex-shrink-0 ") {
        $askText = $htmlDoc.createElement("span")
        $askText.innerText = "Ask Learn"
        $askButton.appendChild($askText) | Out-Null
    }
}

# Add Focus Mode button
$focusButton = $htmlDoc.createElement("button")
$focusButton.type = "button"
$focusButton.id = "ms--focus-mode-button"
$focusButton.setAttribute("data-focus-mode", "")
$focusButton.setAttribute("data-bi-name", "focus-mode-entry")
$focusButton.className = "button button-sm flex-shrink-0 margin-right-xxs display-none display-inline-flex-desktop"
$pageActions.appendChild($focusButton) | Out-Null

$glassesIcon = $htmlDoc.createElement("span")
$glassesIcon.className = "icon font-size-lg"
$glassesIcon.setAttribute("aria-hidden", "true")
$focusButton.appendChild($glassesIcon) | Out-Null

$glassesDocon = $htmlDoc.createElement("span")
$glassesDocon.className = "docon docon-glasses"
$glassesIcon.appendChild($glassesDocon) | Out-Null

$focusText = $htmlDoc.createElement("span")
$focusText.innerText = "Focus mode"
$focusButton.appendChild($focusText) | Out-Null

# Add overflow actions
$overflowDetails = $htmlDoc.createElement("details")
$overflowDetails.className = "popover popover-right"
$overflowDetails.id = "article-header-page-actions-overflow"
$pageActions.appendChild($overflowDetails) | Out-Null

$overflowSummary = $htmlDoc.createElement("summary")
$overflowSummary.className = "justify-content-flex-start button button-clear button-sm button-primary inner-focus"
$overflowSummary.setAttribute("aria-label", "More actions")
$overflowSummary.title = "More actions"
$overflowDetails.appendChild($overflowSummary) | Out-Null

$moreVerticalIcon = $htmlDoc.createElement("span")
$moreVerticalIcon.className = "icon"
$moreVerticalIcon.setAttribute("aria-hidden", "true")
$overflowSummary.appendChild($moreVerticalIcon) | Out-Null

$moreVerticalDocon = $htmlDoc.createElement("span")
$moreVerticalDocon.className = "docon docon-more-vertical"
$moreVerticalIcon.appendChild($moreVerticalDocon) | Out-Null

$overflowContent = $htmlDoc.createElement("div")
$overflowContent.className = "popover-content"
$overflowDetails.appendChild($overflowContent) | Out-Null

# Add table of contents button for mobile
$tocMobileButton = $htmlDoc.createElement("button")
$tocMobileButton.setAttribute("data-page-action-item", "overflow-mobile")
$tocMobileButton.type = "button"
$tocMobileButton.className = "button-block button-sm inner-focus button button-clear display-none-tablet justify-content-flex-start text-align-left"
$tocMobileButton.setAttribute("data-bi-name", "contents-expand")
$tocMobileButton.setAttribute("data-contents-button", "")
$tocMobileButton.setAttribute("data-popover-close", "")
$overflowContent.appendChild($tocMobileButton) | Out-Null

$tocMobileIcon = $htmlDoc.createElement("span")
$tocMobileIcon.className = "icon"
$tocMobileIcon.setAttribute("aria-hidden", "true")
$tocMobileButton.appendChild($tocMobileIcon) | Out-Null

$tocMobileListIcon = $htmlDoc.createElement("span")
$tocMobileListIcon.className = "docon docon-editor-list-bullet"
$tocMobileIcon.appendChild($tocMobileListIcon) | Out-Null

$tocMobileTitle = $htmlDoc.createElement("span")
$tocMobileTitle.className = "contents-expand-title"
$tocMobileTitle.innerText = "Table of contents"
$tocMobileButton.appendChild($tocMobileTitle) | Out-Null

# Add language toggle
$langLink = $htmlDoc.createElement("a")
$langLink.id = "lang-link-overflow"
$langLink.className = "button-sm inner-focus button button-clear button-block justify-content-flex-start text-align-left"
$langLink.setAttribute("data-bi-name", "language-toggle")
$langLink.setAttribute("data-page-action-item", "overflow-all")
$langLink.setAttribute("data-check-hidden", "true")
$langLink.setAttribute("data-read-in-link", "")
$langLink.href = "#"
$langLink.setAttribute("hidden", "")
$overflowContent.appendChild($langLink) | Out-Null

$langIcon = $htmlDoc.createElement("span")
$langIcon.className = "icon"
$langIcon.setAttribute("aria-hidden", "true")
$langIcon.setAttribute("data-read-in-link-icon", "")
$langLink.appendChild($langIcon) | Out-Null

$langGlobeIcon = $htmlDoc.createElement("span")
$langGlobeIcon.className = "docon docon-locale-globe"
$langIcon.appendChild($langGlobeIcon) | Out-Null

$langText = $htmlDoc.createElement("span")
$langText.setAttribute("data-read-in-link-text", "")
$langText.innerText = "Read in English"
$langLink.appendChild($langText) | Out-Null

# Add collection button
$collectionButton = $htmlDoc.createElement("button")
$collectionButton.type = "button"
$collectionButton.className = "collection button button-clear button-sm button-block justify-content-flex-start text-align-left inner-focus"
$collectionButton.setAttribute("data-list-type", "collection")
$collectionButton.setAttribute("data-bi-name", "collection")
$collectionButton.setAttribute("data-page-action-item", "overflow-all")
$collectionButton.setAttribute("data-check-hidden", "true")
$collectionButton.setAttribute("data-popover-close", "")
$overflowContent.appendChild($collectionButton) | Out-Null

$collectionIcon = $htmlDoc.createElement("span")
$collectionIcon.className = "icon"
$collectionIcon.setAttribute("aria-hidden", "true")
$collectionButton.appendChild($collectionIcon) | Out-Null

$collectionAddIcon = $htmlDoc.createElement("span")
$collectionAddIcon.className = "docon docon-circle-addition"
$collectionIcon.appendChild($collectionAddIcon) | Out-Null

$collectionStatus = $htmlDoc.createElement("span")
$collectionStatus.className = "collection-status"
$collectionStatus.innerText = "Add"
$collectionButton.appendChild($collectionStatus) | Out-Null

# Add plan button
$planButton = $htmlDoc.createElement("button")
$planButton.type = "button"
$planButton.className = "collection button button-block button-clear button-sm justify-content-flex-start text-align-left inner-focus"
$planButton.setAttribute("data-list-type", "plan")
$planButton.setAttribute("data-bi-name", "plan")
$planButton.setAttribute("data-page-action-item", "overflow-all")
$planButton.setAttribute("data-check-hidden", "true")
$planButton.setAttribute("data-popover-close", "")
$planButton.setAttribute("hidden", "")
$overflowContent.appendChild($planButton) | Out-Null

$planIcon = $htmlDoc.createElement("span")
$planIcon.className = "icon"
$planIcon.setAttribute("aria-hidden", "true")
$planButton.appendChild($planIcon) | Out-Null

$planAddIcon = $htmlDoc.createElement("span")
$planAddIcon.className = "docon docon-circle-addition"
$planIcon.appendChild($planAddIcon) | Out-Null

$planStatus = $htmlDoc.createElement("span")
$planStatus.className = "plan-status"
$planStatus.innerText = "Add to plan"
$planButton.appendChild($planStatus) | Out-Null

# Add edit button
$editLink = $htmlDoc.createElement("a")
$editLink.setAttribute("data-contenteditbtn", "")
$editLink.className = "button button-clear button-block button-sm inner-focus justify-content-flex-start text-align-left text-decoration-none"
$editLink.setAttribute("data-bi-name", "edit")
$editLink.href = "https://github.com/MicrosoftDocs/PowerShell-Docs/blob/main/reference/7.6/Microsoft.PowerShell.Core/About/About.md"
$editLink.setAttribute("data-original_content_git_url", "https://github.com/MicrosoftDocs/PowerShell-Docs/blob/live/reference/7.6/Microsoft.PowerShell.Core/About/About.md")
$editLink.setAttribute("data-original_content_git_url_template", "{repo}/blob/{branch}/reference/7.6/Microsoft.PowerShell.Core/About/About.md")
$editLink.setAttribute("data-pr_repo", "")
$editLink.setAttribute("data-pr_branch", "")
$overflowContent.appendChild($editLink) | Out-Null

$editIcon = $htmlDoc.createElement("span")
$editIcon.className = "icon"
$editIcon.setAttribute("aria-hidden", "true")
$editLink.appendChild($editIcon) | Out-Null

$editOutlineIcon = $htmlDoc.createElement("span")
$editOutlineIcon.className = "docon docon-edit-outline"
$editIcon.appendChild($editOutlineIcon) | Out-Null

$editText = $htmlDoc.createElement("span")
$editText.innerText = "Edit"
$editLink.appendChild($editText) | Out-Null

# Add separator
$hr = $htmlDoc.createElement("hr")
$hr.className = "margin-block-xxs"
$overflowContent.appendChild($hr) | Out-Null

$h
