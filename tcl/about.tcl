#!/usr/bin/env tclsh
# about.html — portiert nach tcl
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/powershell/about.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/powershell/about.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

proc generateHTML {outputFile} {
    set html [list]
    
    lappend html {<!DOCTYPE html>}
    lappend html {<html class="layout layout-holy-grail   show-table-of-contents conceptual show-breadcrumb default-focus" lang="en-us" dir="ltr" data-authenticated="false" data-auth-status-determined="false" data-target="docs" x-ms-format-detection="none">}
    lappend html {<head>}
    lappend html {<title>About topics - PowerShell | Microsoft Learn</title>}
    lappend html {<meta charset="utf-8" />}
    lappend html {<meta name="viewport" content="width=device-width, initial-scale=1.0" />}
    lappend html {<meta name="color-scheme" content="light dark" />}
    lappend html {<meta name="description" content="About topics cover a range of concepts about PowerShell." />}
    lappend html {<link rel="canonical" href="https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about?view=powershell-7.6" />}
    lappend html {<meta name="twitter:card" content="summary" />}
    lappend html {<meta name="twitter:site" content="@MicrosoftLearn" />}
    lappend html {<meta property="og:type" content="website" />}
    lappend html {<meta property="og:image:alt" content="About topics - PowerShell | Microsoft Learn" />}
    lappend html {<meta property="og:image" content="https://learn.microsoft.com/media/logos/logo-powershell-social.png" />}
    lappend html {<meta property="og:title" content="About topics - PowerShell" />}
    lappend html {<meta property="og:url" content="https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about?view=powershell-7.6" />}
    lappend html {<meta property="og:description" content="About topics cover a range of concepts about PowerShell." />}
    lappend html {<meta name="platform_id" content="5035edbf-6e09-a6fa-a98d-bb2adc6ab1e0" />}
    lappend html {<meta name="scope" content="PowerShell" />}
    lappend html {<meta name="locale" content="en-us" />}
    lappend html {<meta name="uhfHeaderId" content="MSDocsHeader-Powershell" />}
    lappend html {<meta name="page_type" content="conceptual" />}
    lappend html {<meta name="ROBOTS" content="INDEX, FOLLOW" />}
    lappend html {<meta name="apiPlatform" content="powershell" />}
    lappend html {<meta name="archive_url" content="https://learn.microsoft.com/previous-versions/powershell/scripting/overview" />}
    lappend html {<meta name="breadcrumb_path" content="/powershell/scripting/bread/toc.json" />}
    lappend html {<meta name="feedback_product_url" content="https://github.com/PowerShell/PowerShell/issues/new/choose" />}
    lappend html {<meta name="feedback_help_link_url" content="https://learn.microsoft.com/powershell/scripting/community/community-support" />}
    lappend html {<meta name="feedback_help_link_type" content="ask-the-community" />}
    lappend html {<meta name="feedback_system" content="OpenSource" />}
    lappend html {<meta name="hideScope" content="false" />}
    lappend html {<meta name="author" content="sdwheeler" />}
    lappend html {<meta name="ms.author" content="sewhee" />}
    lappend html {<meta name="manager" content="jasongroce" />}
    lappend html {<meta name="ms.devlang" content="powershell" />}
    lappend html {<meta name="ms.service" content="powershell" />}
    lappend html {<meta name="ms.tgt_pltfr" content="windows, macos, linux" />}
    lappend html {<meta name="ms.update-cycle" content="365-days" />}
    lappend html {<meta name="toc_preview" content="true" />}
    lappend html {<meta name="ms.topic" content="reference" />}
    lappend html {<meta name="products" content="https://authoring-docs-microsoft.poolparty.biz/devrel/2bdae855-045f-4535-b365-7b2e23824328" />}
    lappend html {<meta name="products" content="https://authoring-docs-microsoft.poolparty.biz/devrel/8bce367e-2e90-4b56-9ed5-5e4e9f3a2dc3" />}
    lappend html {<meta name="Locale" content="en-US" />}
    lappend html {<meta name="ms.date" content="2026-01-18T00:00:00Z" />}
    lappend html {<meta name="document_id" content="6d07e1b4-9109-26f3-5a6a-20b41b4c66a5" />}
    lappend html {<meta name="document_version_independent_id" content="2bf88889-d533-2316-9add-a385ebbd4259" />}
    lappend html {<meta name="updated_at" content="2026-04-02T22:11:00Z" />}
    lappend html {<meta name="original_content_git_url" content="https://github.com/MicrosoftDocs/PowerShell-Docs/blob/live/reference/7.6/Microsoft.PowerShell.Core/About/About.md" />}
    lappend html {<meta name="gitcommit" content="https://github.com/MicrosoftDocs/PowerShell-Docs/blob/7baf66776aea350bef39470600f075e85f30d7ef/reference/7.6/Microsoft.PowerShell.Core/About/About.md" />}
    lappend html {<meta name="git_commit_id" content="7baf66776aea350bef39470600f075e85f30d7ef" />}
    lappend html {<meta name="monikers" content="powershell-7.6" />}
    lappend html {<meta name="default_moniker" content="powershell-7.6" />}
    lappend html {<meta name="site_name" content="Docs" />}
    lappend html {<meta name="depot_name" content="PowerShell.PowerShell_PowerShell-docs_reference" />}
    lappend html {<meta name="schema" content="Conceptual" />}
    lappend html {<meta name="toc_rel" content="../../psdocs/toc.json" />}
    lappend html {<meta name="word_count" content="1965" />}
    lappend html {<meta name="config_moniker_range" content="powershell-7.6" />}
    lappend html {<meta name="asset_id" content="module/microsoft.powershell.core/about/about" />}
    lappend html {<meta name="moniker_range_name" content="9b5469a01154ce5be5ffa44dbe12b832" />}
    lappend html {<meta name="item_type" content="Content" />}
    lappend html {<meta name="source_path" content="reference/7.6/Microsoft.PowerShell.Core/About/About.md" />}
    lappend html {<meta name="previous_tlsh_hash" content="A12B7262301D8F2E7BE20B1A341CEF4F17F0448C116A19D0012D2537977E1D634728A866C7361B692370488BB39F759D46E8CE22829C53AA1F9127FE495D6A4EE2CDB7B6FC" />}
    lappend html {<meta name="github_feedback_content_git_url" content="https://github.com/MicrosoftDocs/PowerShell-Docs/blob/main/reference/7.6/Microsoft.PowerShell.Core/About/About.md" />}
    lappend html {<meta name="markdown_url" content="https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about?view=powershell-7.6&amp;accept=text/markdown" />}
    lappend html {<link rel="stylesheet" href="/static/assets/0.4.03391.7726-67491f8e/styles/site.css" />}
    lappend html {<script src="https://wcpstatic.microsoft.com/mscc/lib/v2/wcp-consent.js"></script>}
    lappend html {<script src="https://js.monitor.azure.com/scripts/c/ms.jsll-4.min.js"></script>}
    lappend html {<script src="/_themes/docs.theme/master/en-us/_themes/global/deprecation.js"></script>}
    lappend html {<script id="msdocs-script">}
    lappend html {var msDocs = \{}
    lappend html {  "environment": \{}
    lappend html {    "accessLevel": "online",}
    lappend html {    "azurePortalHostname": "portal.azure.com",}
    lappend html {    "reviewFeatures": false,}
    lappend html {    "supportLevel": "production",}
    lappend html {    "systemContent": true,}
    lappend html {    "siteName": "learn",}
    lappend html {    "legacyHosting": false}
    lappend html {  \},}
    lappend html {  "data": \{}
    lappend html {    "contentLocale": "en-us",}
    lappend html {    "contentDir": "ltr",}
    lappend html {    "userLocale": "en-us",}
    lappend html {    "userDir": "ltr",}
    lappend html {    "pageTemplate": "Conceptual",}
    lappend html {    "brand": "",}
    lappend html {    "context": \{\},}
    lappend html {    "standardFeedback": false,}
    lappend html {    "showFeedbackReport": false,}
    lappend html {    "feedbackHelpLinkType": "ask-the-community",}
    lappend html {    "feedbackHelpLinkUrl": "https://learn.microsoft.com/powershell/scripting/community/community-support",}
    lappend html {    "feedbackSystem": "OpenSource",}
    lappend html {    "feedbackGitHubRepo": "",}
    lappend html {    "feedbackProductUrl": "https://github.com/PowerShell/PowerShell/issues/new/choose",}
    lappend html {    "extendBreadcrumb": false,}
    lappend html {    "isEditDisplayable": true,}
    lappend html {    "isPrivateUnauthorized": false,}
    lappend html {    "hideViewSource": false,}
    lappend html {    "isPermissioned": false,}
    lappend html {    "hasRecommendations": false,}
    lappend html {    "contributors": [}
    lappend html {      \{}
    lappend html {        "name": "sdwheeler",}
    lappend html {        "url": "https://github.com/sdwheeler"}
    lappend html {      \},}
    lappend html {      \{}
    lappend html {        "name": "SufficientDaikon",}
    lappend html {        "url": "https://github.com/SufficientDaikon"}
    lappend html {      \},}
    lappend html {      \{}
    lappend html {        "name": "surfingoldelephant",}
    lappend html {        "url": "https://github.com/surfingoldelephant"}
    lappend html {      \}}
    lappend html {    ],}
    lappend html {    "openSourceFeedbackIssueUrl": "https://github.com/MicrosoftDocs/PowerShell-Docs/issues/new?template=04-customer-feedback.yml",}
    lappend html {    "openSourceFeedbackIssueTitle": "",}
    lappend html {    "openSourceFeedbackIssueLabels": "needs-triage"}
    lappend html {  \},}
    lappend html {  "functions": \{\}}
    lappend html {;;}
    lappend html {</script>}
    lappend html {<script src="/static/assets/0.4.03391.7726-67491f8e/scripts/en-us/index-docs.js"></script>}
    lappend html {</head>}
    lappend html {<body id="body" data-bi-name="body" class="layout-body " lang="en-us" dir="ltr">}
    lappend html {<header class="layout-body-header">}
    lappend html {<div class="header-holder has-default-focus">}
    lappend html {<a href="#main" style="z-index: 1070" class="outline-color-text visually-hidden-until-focused position-fixed inner-focus focus-visible top-0 left-0 right-0 padding-xs text-align-center background-color-body">}
    lappend html {Skip to main content}
    lappend html {</a>}
    lappend html {<a href="#" data-skip-to-ask-learn style="z-index: 1070" class="outline-color-text visually-hidden-until-focused position-fixed inner-focus focus-visible top-0 left-0 right-0 padding-xs text-align-center background-color-body" hidden>}
    lappend html {Skip to Ask Learn chat experience}
    lappend html {</a>}
    lappend html {<div hidden id="cookie-consent-holder" data-test-id="cookie-consent-container"></div>}
    lappend html {<div id="unsupported-browser" style="background-color: white; color: black; padding: 16px; border-bottom: 1px solid grey;" hidden>}
    lappend html {<div style="max-width: 800px; margin: 0 auto;">}
    lappend html {<p style="font-size: 24px">This browser is no longer supported.</p>}
    lappend html {<p style="font-size: 16px; margin-top: 16px;">}
    lappend html {Upgrade to Microsoft Edge to take advantage of the latest features, security updates, and technical support.}
    lappend html {</p>}
    lappend html {<div style="margin-top: 12px;">}
    lappend html {<a href="https://go.microsoft.com/fwlink/p/?LinkID=2092881 " style="background-color: #0078d4; border: 1px solid #0078d4; color: white; padding: 6px 12px; border-radius: 2px; display: inline-block;">}
    lappend html {Download Microsoft Edge}
    lappend html {</a>}
    lappend html {<a href="https://learn.microsoft.com/en-us/lifecycle/faq/internet-explorer-microsoft-edge" style="background-color: white; padding: 6px 12px; border: 1px solid #505050; color: #171717; border-radius: 2px; display: inline-block;">}
    lappend html {More info about Internet Explorer and Microsoft Edge}
    lappend html {</a>}
    lappend html {</div>}
    lappend html {</div>}
    lappend html {</div>}
    lappend html {<div id="ms--site-header" data-test-id="site-header-wrapper" itemscope="itemscope" itemtype="http://schema.org/Organization">}
    lappend html {<div id="ms--mobile-nav" class="site-header display-none-tablet padding-inline-none gap-none" data-bi-name="mobile-header" data-test-id="mobile-header"></div>}
    lappend html {<div id="ms--primary-nav" class="site-header display-none display-flex-tablet" data-bi-name="L1-header" data-test-id="primary-header"></div>}
    lappend html {<div id="ms--secondary-nav" class="site-header display-none display-flex-tablet" data-bi-name="L2-header" data-test-id="secondary-header"></div>}
    lappend html {</div>}
    lappend html {<div data-banner>}
    lappend html {<div id="disclaimer-holder"></div>}
    lappend html {</div>}
    lappend html {</div>}
    lappend html {</header>}
    lappend html {<section id="layout-body-menu" class="layout-body-menu display-flex" data-bi-name="menu">}
    lappend html {<div id="left-container" class="left-container display-none display-block-tablet padding-inline-sm padding-bottom-sm width-full" data-toc-container="true">}
    lappend html {<div id="ms--toc-content" class="height-full">}
    lappend html {<nav id="affixed-left-container" class="margin-top-sm-tablet position-sticky display-flex flex-direction-column" aria-label="Primary" data-bi-name="left-toc" role="navigation"></nav>}
    lappend html {</div>}
    lappend html {<div id="ms--toc-content-collapsible" class="height-full" hidden>}
    lappend html {<nav id="affixed-left-container" class="margin-top-sm-tablet position-sticky display-flex flex-direction-column" aria-label="Primary" data-bi-name="left-toc" role="navigation">}
    lappend html {<div id="ms--collapsible-toc-header" class="display-flex flex-direction-row-reverse justify-content-space-between align-items-center margin-bottom-xxs">}
    lappend html {<button type="button" class="button button-clear inner-focus" data-collapsible-toc-toggle aria-expanded="true" aria-controls="ms--collapsible-toc-content" aria-label="Table of contents">}
    lappend html {<span class="icon font-size-xxl" aria-hidden="true">}
    lappend html {<span class="docon docon-panel-left-contract"></span>}
    lappend html {</span>}
    lappend html {</button>}
    lappend html {<div id="ms--collapsible-toc-moniker-slot" class="flex-grow-1"></div>}
    lappend html {</div>}
    lappend html {</nav>}
    lappend html {</div>}
    lappend html {</div>}
    lappend html {</section>}
    lappend html {<main id="main" role="main" class="layout-body-main " data-bi-name="content" lang="en-us" dir="ltr">}
    lappend html {<div id="ms--content-header" class="content-header default-focus border-bottom-none" data-bi-name="content-header">}
    lappend html {<div class="content-header-controls margin-xxs margin-inline-sm-tablet">}
    lappend html {<button type="button" class="contents-button button button-sm margin-right-xxs" data-bi-name="contents-expand" aria-haspopup="true" data-contents-button>}
    lappend html {<span class="icon" aria-hidden="true"><span class="docon docon-menu"></span></span>}
    lappend html {<span class="contents-expand-title"> Table of contents </span>}
    lappend html {</button>}
    lappend html {<button type="button" class="ap-collapse-behavior ap-expanded button button-sm" data-bi-name="ap-collapse" aria-controls="action-panel">}
    lappend html {<span class="icon" aria-hidden="true"><span class="docon docon-exit-mode"></span></span>}
    lappend html {<span>Exit editor mode</span>}
    lappend html {</button>}
    lappend html {</div>}
    lappend html {</div>}
    lappend html {<div data-main-column class="padding-sm padding-top-none padding-top-sm-tablet">}
    lappend html {<div>}
    lappend html {<div id="article-header" class="background-color-body margin-bottom-xs display-none-print">}
    lappend html {<div class="display-flex align-items-center justify-content-space-between">}
    lappend html {<details id="article-header-breadcrumbs-overflow-popover" class="popover" data-for="article-header-breadcrumbs">}
    lappend html {<summary class="button button-clear button-primary button-sm inner-focus" aria-label="All breadcrumbs">}
    lappend html {<span class="icon" aria-hidden="true">}
    lappend html {<span class="docon docon-more"></span>}
    lappend html {</span>}
    lappend html {</summary>}
    lappend html {<div id="article-header-breadcrumbs-overflow" class="popover-content padding-none"></div>}
    lappend html {</details>}
    lappend html {<bread-crumbs id="article-header-breadcrumbs" role="group" aria-label="Breadcrumbs" data-test-id="article-header-breadcrumbs" class="overflow-hidden flex-grow-1 margin-right-sm margin-right-md-tablet margin-right-lg-desktop margin-left-negative-xxs padding-left-xxs"></bread-crumbs>}
    lappend html {<div id="article-header-page-actions" class="opacity-none margin-left-auto display-flex flex-wrap-no-wrap align-items-stretch">}
    lappend html {<button class="button button-sm border-none inner-focus display-none-tablet flex-shrink-0 " data-bi-name="ask-learn-assistant-entry" data-test-id="ask-learn-assistant-modal-entry-mobile" data-ask-learn-modal-entry type="button" style="min-width: max-content;" aria-expanded="false" aria-label="Ask Learn" hidden>}
    lappend html {<span class="icon font-size-lg" aria-hidden="true">}
    lappend html {<span class="docon docon-chat-sparkle-fill gradient-ask-learn-logo"></span>}
    lappend html {</span>}
    lappend html {</button>}
    lappend html {<button class="button button-sm display-none display-inline-flex-tablet display-none-desktop flex-shrink-0 margin-right-xxs border-color-ask-learn " data-bi-name="ask-learn-assistant-entry" data-test-id="ask-learn-assistant-modal-entry-tablet" data-ask-learn-modal-entry type="button" style="min-width: max-content;" aria-expanded="false" hidden>}
    lappend html {<span class="icon font-size-lg" aria-hidden="true">}
    lappend html {<span class="docon docon-chat-sparkle-fill gradient-ask-learn-logo"></span>}
    lappend html {</span>}
    lappend html {<span>Ask Learn</span>}
    lappend html {</button>}
    lappend html {<button class="button button-sm display-none flex-shrink-0 display-inline-flex-desktop margin-right-xxs border-color-ask-learn " data-bi-name="ask-learn-assistant-entry" data-test-id="ask-learn-assistant-flyout-entry" data-ask-learn-flyout-entry data-flyout-button="toggle" type="button" style="min-width: max-content;" aria-expanded="false" aria-controls="ask-learn-flyout" hidden>}
    lappend html {<span class="icon font-size-lg" aria-hidden="true">}
    lappend html {<span class="docon docon-chat-sparkle-fill gradient-ask-learn-logo"></span>}
    lappend html {</span>}
    lappend html {<span>Ask Learn</span>}
    lappend html {</button>}
    lappend html {<button type="button" id="ms--focus-mode-button" data-focus-mode data-bi-name="focus-mode-entry" class="button button-sm flex-shrink-0 margin-right-xxs display-none display-inline-flex-desktop">}
    lappend html {<span class="icon font-size-lg" aria-hidden="true">}
    lappend html {<span class="docon docon-glasses"></span>}
    lappend html {</span>}
    lappend html {<span>Focus mode</span>}
    lappend html {</button>}
    lappend html {<details class="popover popover-right" id="article-header-page-actions-overflow">}
    lappend html {<summary class="justify-content-flex-start button button-clear button-sm button-primary inner-focus" aria-label="More actions" title="More actions">}
    lappend html {<span class="icon" aria-hidden="true">}
    lappend html {<span class="docon docon-more-vertical"></span>}
    lappend html {</span>}
    lappend html {</summary>}
    lappend html {<div class="popover-content">}
    lappend html {<button data-page-action-item="overflow-mobile" type="button" class="button-block button-sm inner-focus button button-clear display-none-tablet justify-content-flex-start text-align-left" data-bi-name="contents-expand" data-contents-button data-popover-close>}
    lappend html {<span class="icon" aria-hidden="true"><span class="docon docon-editor-list-bullet"></span></span>}
    lappend html {<span class="contents-expand-title">Table of contents</span>}
    lappend html {</button>}
    lappend html {<a id="lang-link-overflow" class="button-sm inner-focus button button-clear button-block justify-content-flex-start text-align-left" data-bi-name="language-toggle" data-page-action-item="overflow-all" data-check-hidden="true" data-read-in-link href="#" hidden>}
    lappend html {<span class="icon" aria-hidden="true" data-read-in-link-icon>}
    lappend html {<span class="docon docon-locale-globe"></span>}
    lappend html {</span>}
    lappend html {<span data-read-in-link-text>Read in English</span>}
    lappend html {</a>}
    lappend html {<button type="button" class="collection button button-clear button-sm button-block justify-content-flex-start text-align-left inner-focus" data-list-type="collection" data-bi-name="collection" data-page-action-item="overflow-all" data-check-hidden="true" data-popover-close>}
    lappend html {<span class="icon" aria-hidden="true">}
    lappend html {<span class="docon docon-circle-addition"></span>}
    lappend html {</span>}
    lappend html {<span class="collection-status">Add</span>}
    lappend html {</button>}
    lappend html {<button type="button" class="collection button button-block button-clear button-sm justify-content-flex-start text-align-left inner-focus" data-list-type="plan" data-bi-name="plan" data-page-action-item="overflow-all" data-check-hidden="true" data-popover-close hidden>}
    lappend html {<span class="icon" aria-hidden="true">}
    lappend html {<span class="docon docon-circle-addition"></span>}
    lappend html {</span>}
    lappend html {<span class="plan-status">Add to plan</span>}
    lappend html {</button>}
    lappend html {<a data-contenteditbtn class="button button-clear button-block button-sm inner-focus justify-content-flex-start text-align-left text-decoration-none" data-bi-name="edit" href="https://github.com/MicrosoftDocs/PowerShell-Docs/blob/main/reference/7.6/Microsoft.PowerShell.Core/About/About.md" data-original_content_git_url="https://github.com/MicrosoftDocs/PowerShell-Docs/blob/live/reference/7.6/Microsoft.PowerShell.Core/About/About.md" data-original_content_git_url_template="\{repo\}/blob/\{branch\}/reference/7.6/Microsoft.PowerShell.Core/About/About.md" data-pr_repo="" data-pr_branch="">}
    lappend html {<span class="icon" aria-hidden="true">}
    lappend html {<span class="docon docon-edit-outline"></span>}
    lappend html {</span>}
    lappend html {<span>Edit</span>}
    lappend html {</a>}
    lappend html {<hr class="margin-block-xxs" />}
    lappend html {<h4 class="font-size-sm padding-left-xxs">Share via</h4>}
    lappend html {<a class="button button-clear button-sm inner-focus button-block justify-content-flex-start text-align-left text-decoration-none share-facebook" data-bi-name="facebook" data-page-action-item="overflow-all" href="#">}
    lappend html {<span class="icon color-primary" aria-hidden="true">}
    lappend html {<span class="docon docon-facebook-share"></span>}
    lappend html {</span>}
    lappend html {<span>Facebook</span>}
    lappend html {</a>}
    lappend html {<a href="#" class="button button-clear button-sm inner-focus button-block justify-content-flex-start text-align-left text-decoration-none share-twitter" data-bi-name="twitter" data-page-action-item="overflow-all">}
    lappend html {<span class="icon color-text" aria-hidden="true">}
    lappend html {<span class="docon docon-xlogo-share"></span>}
    lappend html {</span>}
    lappend html {<span>x.com</span>}
    lappend html {</a>}
    lappend html {<a href="#" class="button button-clear button-sm inner-focus button-block justify-content-flex-start text-align-left text-decoration-none share-linkedin" data-bi-name="linkedin" data-page-action-item="overflow-all">}
    lappend html {<span class="icon color-primary" aria-hidden="true">}
    lappend html {<span class="docon docon-linked-in-logo"></span>}
    lappend html {</span>}
    lappend html {<span>LinkedIn</span>}
    lappend html {</a>}
    lappend html {<a href="#" class="button button-clear button-sm inner-focus button-block justify-content-flex-start text-align-left text-decoration-none share-email" data-bi-name="email" data-page-action-item="overflow-all">}
    lappend html {<span class="icon color-primary" aria-hidden="true">}
    lappend html {<span class="docon docon-mail-message"></span>}
    lappend html {</span>}
    lappend html {<span>Email</span>}
    lappend html {</a>}
    lappend html {<hr class="margin-block-xxs" />}
    lappend html {<button class="button button-block button-clear button-sm justify-content-flex-start text-align-left inner-focus" type="button" data-bi-name="copy-markdown" data-page-action-item="overflow-all" data-copy-markdown data-copy-state="idle" data-check-hidden="true">}
    lappend html {<span class="icon color-primary" aria-hidden="true">}
    lappend html {<span data-show-when="idle" class="docon docon-code-lang"></span>}
    lappend html {<span data-show-when="loading" class="loader" hidden></span>}
    lappend html {<span data-show-when="success" class="docon docon-check-mark" hidden></span>}
    lappend html {</span>}
    lappend html {<span>Copy Markdown</span>}
    lappend html {</button>}
    lappend html {<button class="button button-block button-clear button-sm justify-content-flex-start text-align-left inner-focus" type="button" data-bi-name="print" data-page-action-item="overflow-all" data-popover-close data-print-page data-check-hidden="true">}
    lappend html {<span class="icon color-primary" aria-hidden="true">}
    lappend html {<span class="docon docon-print"></span>}
    lappend html {</span>}
    lappend html {<span>Print</span>}
    lappend html {</button>}
    lappend html {</div>}
    lappend html {</details>}
    lappend html {</div>}
    lappend html {</div>}
    lappend html {</div>}
    lappend html {<div unauthorized-private-section data-bi-name="permission-content-unauthorized-private" hidden>}
    lappend html {<hr class="hr margin-top-xs margin-bottom-sm" />}
    lappend html {<div class="notification notification-info">}
    lappend html {<div class="notification-content">}
    lappend html {<p class="margin-top-none notification-title">}
    lappend html {<span class="icon" aria-hidden="true"><span class="docon docon-exclamation-circle-solid"></span></span>}
    lappend html {<span>Note</span>}
    lappend html {</p>}
    lappend html {<p class="margin-top-none authentication-determined not-authenticated">}
    lappend html {Access to this page requires authorization. You can try <a class="docs-sign-in" href="#" data-bi-name="permission-content-sign-in">signing in</a> or <a  class="docs-change-directory" data-bi-name="permisson-content-change-directory">changing directories</a>.}
    lappend html {</p>}
    lappend html {<p class="margin-top-none authentication-determined authenticated">}
    lappend html {Access to this page requires authorization. You can try <a class="docs-change-directory" data-bi-name="permisson-content-change-directory">changing directories</a>.}
    lappend html {</p>}
    lappend html {</div>}
    lappend html {</div>}
    lappend html {</div>}
    lappend html {<div class="content"><h1 id="about-topics">About topics</h1></div>}
    lappend html {<div id="article-metadata" data-bi-name="article-metadata" data-test-id="article-metadata" class="page-metadata-container display-flex gap-xxs justify-content-space-between align-items-center flex-wrap-wrap">}
    lappend html {<div id="user-feedback" class="margin-block-xxs display-none display-none-print" hidden data-hide-on-archived>}
    lappend html {<button id="user-feedback-button" data-test-id="conceptual-feedback-button" class="button button-sm button-clear button-primary display-none" type="button" data-bi-name="user-feedback-button" data-user-feedback-button hidden>}
    lappend html {<span class="icon" aria-hidden="true">}
    lappend html {<span class="docon docon-like"></span>}
    lappend html {</span>}
    lappend html {<span>Feedback</span>}
    lappend html {</button>}
    lappend html {</div>}
    lappend html {</div>}
    lappend html {<div data-id="ai-summary" class="display-none-print">}
    lappend html {<div id="ms--ai-summary-cta" class="margin-top-xs display-flex align-items-center">}
    lappend html {<span class="icon" aria-hidden="true">}
    lappend html {<span class="docon docon-sparkle-fill gradient-text-vivid"></span>}
    lappend html {</span>}
    lappend html {<button id="ms--ai-summary" type="button" class="tag tag-sm tag-suggestion margin-left-xxs" data-test-id="ai-summary-cta" data-bi-name="ai-summary-cta" data-an="ai-summary">}
    lappend html {<span class="ai-summary-cta-text">}
    lappend html {Summarize this article for me}
    lappend html {</span>}
    lappend html {</button>}
    lappend html {</div>}
    lappend html {<div id="ms--ai-summary-header" class="margin-top-xs"></div>}
    lappend html {</div>}
    lappend html {<nav id="center-doc-outline" class="doc-outline display-none-desktop display-none-print margin-bottom-sm" data-bi-name="intopic
