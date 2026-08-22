#!/bin/bash
# about.html — portiert nach shell
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/powershell/about.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/powershell/about.html
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# This script generates the about.html file
# Usage: ./about.sh <output-file>

if [ $# -ne 1 ]; then
    echo "Usage: $0 <output-file>"
    exit 1
fi

OUTPUT_FILE="$1"

cat > "$OUTPUT_FILE" << 'EOF'
<!DOCTYPE html>
		<html
			class="layout layout-holy-grail   show-table-of-contents conceptual show-breadcrumb default-focus"
			lang="en-us"
			dir="ltr"
			data-authenticated="false"
			data-auth-status-determined="false"
			data-target="docs"
			x-ms-format-detection="none"
		>
			
		<head>
			<title>About topics - PowerShell | Microsoft Learn</title>
			<meta charset="utf-8" />
			<meta name="viewport" content="width=device-width, initial-scale=1.0" />
			<meta name="color-scheme" content="light dark" />

			<meta name="description" content="About topics cover a range of concepts about PowerShell." />
			<link rel="canonical" href="https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about?view=powershell-7.6" /> 

			<!-- Non-customizable open graph and sharing-related metadata -->
			<meta name="twitter:card" content="summary" />
			<meta name="twitter:site" content="@MicrosoftLearn" />
			<meta property="og:type" content="website" />
			<meta property="og:image:alt" content="About topics - PowerShell | Microsoft Learn" />
			<meta property="og:image" content="https://learn.microsoft.com/media/logos/logo-powershell-social.png" />
			<!-- Page specific open graph and sharing-related metadata -->
			<meta property="og:title" content="About topics - PowerShell" />
			<meta property="og:url" content="https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about?view=powershell-7.6" />
			<meta property="og:description" content="About topics cover a range of concepts about PowerShell." />
			<meta name="platform_id" content="5035edbf-6e09-a6fa-a98d-bb2adc6ab1e0" /> <meta name="scope" content="PowerShell" />
			<meta name="locale" content="en-us" />
			 
			<meta name="uhfHeaderId" content="MSDocsHeader-Powershell" />

			<meta name="page_type" content="conceptual" />

			<!--page specific meta tags-->
			

			<!-- custom meta tags -->
			
		<meta name="ROBOTS" content="INDEX, FOLLOW" />
	
		<meta name="apiPlatform" content="powershell" />
	
		<meta name="archive_url" content="https://learn.microsoft.com/previous-versions/powershell/scripting/overview" />
	
		<meta name="breadcrumb_path" content="/powershell/scripting/bread/toc.json" />
	
		<meta name="feedback_product_url" content="https://github.com/PowerShell/PowerShell/issues/new/choose" />
	
		<meta name="feedback_help_link_url" content="https://learn.microsoft.com/powershell/scripting/community/community-support" />
	
		<meta name="feedback_help_link_type" content="ask-the-community" />
	
		<meta name="feedback_system" content="OpenSource" />
	
		<meta name="hideScope" content="false" />
	
		<meta name="author" content="sdwheeler" />
	
		<meta name="ms.author" content="sewhee" />
	
		<meta name="manager" content="jasongroce" />
	
		<meta name="ms.devlang" content="powershell" />
	
		<meta name="ms.service" content="powershell" />
	
		<meta name="ms.tgt_pltfr" content="windows, macos, linux" />
	
		<meta name="ms.update-cycle" content="365-days" />
	
		<meta name="toc_preview" content="true" />
	
		<meta name="ms.topic" content="reference" />
	
		<meta name="products" content="https://authoring-docs-microsoft.poolparty.biz/devrel/2bdae855-045f-4535-b365-7b2e23824328" />
	
		<meta name="products" content="https://authoring-docs-microsoft.poolparty.biz/devrel/8bce367e-2e90-4b56-9ed5-5e4e9f3a2dc3" />
	
		<meta name="Locale" content="en-US" />
	
		<meta name="ms.date" content="2026-01-18T00:00:00Z" />
	
		<meta name="document_id" content="6d07e1b4-9109-26f3-5a6a-20b41b4c66a5" />
	
		<meta name="document_version_independent_id" content="2bf88889-d533-2316-9add-a385ebbd4259" />
	
		<meta name="updated_at" content="2026-04-02T22:11:00Z" />
	
		<meta name="original_content_git_url" content="https://github.com/MicrosoftDocs/PowerShell-Docs/blob/live/reference/7.6/Microsoft.PowerShell.Core/About/About.md" />
	
		<meta name="gitcommit" content="https://github.com/MicrosoftDocs/PowerShell-Docs/blob/7baf66776aea350bef39470600f075e85f30d7ef/reference/7.6/Microsoft.PowerShell.Core/About/About.md" />
	
		<meta name="git_commit_id" content="7baf66776aea350bef39470600f075e85f30d7ef" />
	
		<meta name="monikers" content="powershell-7.6" />
	
		<meta name="default_moniker" content="powershell-7.6" />
	
		<meta name="site_name" content="Docs" />
	
		<meta name="depot_name" content="PowerShell.PowerShell_PowerShell-docs_reference" />
	
		<meta name="schema" content="Conceptual" />
	
		<meta name="toc_rel" content="../../psdocs/toc.json" />
	
		<meta name="word_count" content="1965" />
	
		<meta name="config_moniker_range" content="powershell-7.6" />
	
		<meta name="asset_id" content="module/microsoft.powershell.core/about/about" />
	
		<meta name="moniker_range_name" content="9b5469a01154ce5be5ffa44dbe12b832" />
	
		<meta name="item_type" content="Content" />
	
		<meta name="source_path" content="reference/7.6/Microsoft.PowerShell.Core/About/About.md" />
	
		<meta name="previous_tlsh_hash" content="A12B7262301D8F2E7BE20B1A341CEF4F17F0448C116A19D0012D2537977E1D634728A866C7361B692370488BB39F759D46E8CE22829C53AA1F9127FE495D6A4EE2CDB7B6FC" />
	
		<meta name="github_feedback_content_git_url" content="https://github.com/MicrosoftDocs/PowerShell-Docs/blob/main/reference/7.6/Microsoft.PowerShell.Core/About/About.md" />
	
		<meta name="markdown_url" content="https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about?view=powershell-7.6&amp;accept=text/markdown" />
	 

			<!-- assets and js globals -->
			
			<link rel="stylesheet" href="/static/assets/0.4.03391.7726-67491f8e/styles/site.css" />
			
			<script src="https://wcpstatic.microsoft.com/mscc/lib/v2/wcp-consent.js"></script>
			<script src="https://js.monitor.azure.com/scripts/c/ms.jsll-4.min.js"></script>
			<script src="/_themes/docs.theme/master/en-us/_themes/global/deprecation.js"></script>

			<!-- msdocs global object -->
			<script id="msdocs-script">
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
	</script>

			<!-- base scripts, msdocs global should be before this -->
			<script src="/static/assets/0.4.03391.7726-67491f8e/scripts/en-us/index-docs.js"></script>
			

			<!-- json-ld -->
			
		</head>
	
			<body
				id="body"
				data-bi-name="body"
				class="layout-body "
				lang="en-us"
				dir="ltr"
			>
				<header class="layout-body-header">
		<div class="header-holder has-default-focus">
			
		<a
			href="#main"
			
			style="z-index: 1070"
			class="outline-color-text visually-hidden-until-focused position-fixed inner-focus focus-visible top-0 left-0 right-0 padding-xs text-align-center background-color-body"
			
		>
			Skip to main content
		</a>
	
		<a
			href="#"
			data-skip-to-ask-learn
			style="z-index: 1070"
			class="outline-color-text visually-hidden-until-focused position-fixed inner-focus focus-visible top-0 left-0 right-0 padding-xs text-align-center background-color-body"
			hidden
		>
			Skip to Ask Learn chat experience
		</a>
	

			<div hidden id="cookie-consent-holder" data-test-id="cookie-consent-container"></div>
			<!-- Unsupported browser warning -->
			<div
				id="unsupported-browser"
				style="background-color: white; color: black; padding: 16px; border-bottom: 1px solid grey;"
				hidden
			>
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
			</div>
			<!-- site header -->
			<div
				id="ms--site-header"
				data-test-id="site-header-wrapper"
				itemscope="itemscope"
				itemtype="http://schema.org/Organization"
			>
				<div
					id="ms--mobile-nav"
					class="site-header display-none-tablet padding-inline-none gap-none"
					data-bi-name="mobile-header"
					data-test-id="mobile-header"
				></div>
				<div
					id="ms--primary-nav"
					class="site-header display-none display-flex-tablet"
					data-bi-name="L1-header"
					data-test-id="primary-header"
				></div>
				<div
					id="ms--secondary-nav"
					class="site-header display-none display-flex-tablet"
					data-bi-name="L2-header"
					data-test-id="secondary-header"
					
				></div>
			</div>
			
		<!-- banner -->
		<div data-banner>
			<div id="disclaimer-holder"></div>
			
		</div>
		<!-- banner end -->
	
		</div>
	</header>
				 <section
					id="layout-body-menu"
					class="layout-body-menu display-flex"
					data-bi-name="menu"
			  >
					
		<div
			id="left-container"
			class="left-container display-none display-block-tablet padding-inline-sm padding-bottom-sm width-full"
			data-toc-container="true"
		>
			<!-- Regular TOC content (default) -->
			<div id="ms--toc-content" class="height-full">
				<nav
					id="affixed-left-container"
					class="margin-top-sm-tablet position-sticky display-flex flex-direction-column"
					aria-label="Primary"
					data-bi-name="left-toc"
					role="navigation"
				></nav>
			</div>
			<!-- Collapsible TOC content (hidden by default) -->
			<div id="ms--toc-content-collapsible" class="height-full" hidden>
				<nav
					id="affixed-left-container"
					class="margin-top-sm-tablet position-sticky display-flex flex-direction-column"
					aria-label="Primary"
					data-bi-name="left-toc"
					role="navigation"
				>
					<div
						id="ms--collapsible-toc-header"
						class="display-flex flex-direction-row-reverse justify-content-space-between align-items-center margin-bottom-xxs"
					>
						<button
							type="button"
							class="button button-clear inner-focus"
							data-collapsible-toc-toggle
							aria-expanded="true"
							aria-controls="ms--collapsible-toc-content"
							aria-label="Table of contents"
						>
							<span class="icon font-size-xxl" aria-hidden="true">
								<span class="docon docon-panel-left-contract"></span>
							</span>
						</button>
						<div id="ms--collapsible-toc-moniker-slot" class="flex-grow-1"></div>
					</div>
				</nav>
			</div>
		</div>
	
			  </section>

				<main
					id="main"
					role="main"
					class="layout-body-main "
					data-bi-name="content"
					lang="en-us"
					dir="ltr"
				>
					
			<div
		id="ms--content-header"
		class="content-header default-focus border-bottom-none"
		data-bi-name="content-header"
	>
		<div class="content-header-controls margin-xxs margin-inline-sm-tablet">
			<button
				type="button"
				class="contents-button button button-sm margin-right-xxs"
				data-bi-name="contents-expand"
				aria-haspopup="true"
				data-contents-button
			>
				<span class="icon" aria-hidden="true"><span class="docon docon-menu"></span></span>
				<span class="contents-expand-title"> Table of contents </span>
			</button>
			<button
				type="button"
				class="ap-collapse-behavior ap-expanded button button-sm"
				data-bi-name="ap-collapse"
				aria-controls="action-panel"
			>
				<span class="icon" aria-hidden="true"><span class="docon docon-exit-mode"></span></span>
				<span>Exit editor mode</span>
			</button>
		</div>
	</div>
			<div data-main-column class="padding-sm padding-top-none padding-top-sm-tablet">
				<div>
					
		<div id="article-header" class="background-color-body margin-bottom-xs display-none-print">
			<div class="display-flex align-items-center justify-content-space-between">
				
		<details
			id="article-header-breadcrumbs-overflow-popover"
			class="popover"
			data-for="article-header-breadcrumbs"
		>
			<summary
				class="button button-clear button-primary button-sm inner-focus"
				aria-label="All breadcrumbs"
			>
				<span class="icon" aria-hidden="true">
					<span class="docon docon-more"></span>
				</span>
			</summary>
			<div id="article-header-breadcrumbs-overflow" class="popover-content padding-none"></div>
		</details>

		<bread-crumbs
			id="article-header-breadcrumbs"
			role="group"
			aria-label="Breadcrumbs"
			data-test-id="article-header-breadcrumbs"
			class="overflow-hidden flex-grow-1 margin-right-sm margin-right-md-tablet margin-right-lg-desktop margin-left-negative-xxs padding-left-xxs"
		></bread-crumbs>
	 
		<div
			id="article-header-page-actions"
			class="opacity-none margin-left-auto display-flex flex-wrap-no-wrap align-items-stretch"
		>
			
		<button
			class="button button-sm border-none inner-focus display-none-tablet flex-shrink-0 "
			data-bi-name="ask-learn-assistant-entry"
			data-test-id="ask-learn-assistant-modal-entry-mobile"
			data-ask-learn-modal-entry
			
			type="button"
			style="min-width: max-content;"
			aria-expanded="false"
			aria-label="Ask Learn"
			hidden
		>
			<span class="icon font-size-lg" aria-hidden="true">
				<span class="docon docon-chat-sparkle-fill gradient-ask-learn-logo"></span>
			</span>
		</button>
		<button
			class="button button-sm display-none display-inline-flex-tablet display-none-desktop flex-shrink-0 margin-right-xxs border-color-ask-learn "
			data-bi-name="ask-learn-assistant-entry"
			
			data-test-id="ask-learn-assistant-modal-entry-tablet"
			data-ask-learn-modal-entry
			type="button"
			style="min-width: max-content;"
			aria-expanded="false"
			hidden
		>
			<span class="icon font-size-lg" aria-hidden="true">
				<span class="docon docon-chat-sparkle-fill gradient-ask-learn-logo"></span>
			</span>
			<span>Ask Learn</span>
		</button>
		<button
			class="button button-sm display-none flex-shrink-0 display-inline-flex-desktop margin-right-xxs border-color-ask-learn "
			data-bi-name="ask-learn-assistant-entry"
			
			data-test-id="ask-learn-assistant-flyout-entry"
			data-ask-learn-flyout-entry
			data-flyout-button="toggle"
			type="button"
			style="min-width: max-content;"
			aria-expanded="false"
			aria-controls="ask-learn-flyout"
			hidden
		>
			<span class="icon font-size-lg" aria-hidden="true">
				<span class="docon docon-chat-sparkle-fill gradient-ask-learn-logo"></span>
			</span>
			<span>Ask Learn</span>
		</button>
	 
		<button
			type="button"
			id="ms--focus-mode-button"
			data-focus-mode
			data-bi-name="focus-mode-entry"
			class="button button-sm flex-shrink-0 margin-right-xxs display-none display-inline-flex-desktop"
		>
			<span class="icon font-size-lg" aria-hidden="true">
				<span class="docon docon-glasses"></span>
			</span>
			<span>Focus mode</span>
		</button>
	 

			<details class="popover popover-right" id="article-header-page-actions-overflow">
				<summary
					class="justify-content-flex-start button button-clear button-sm button-primary inner-focus"
					aria-label="More actions"
					title="More actions"
				>
					<span class="icon" aria-hidden="true">
						<span class="docon docon-more-vertical"></span>
					</span>
				</summary>
				<div class="popover-content">
					
		<button
			data-page-action-item="overflow-mobile"
			type="button"
			class="button-block button-sm inner-focus button button-clear display-none-tablet justify-content-flex-start text-align-left"
			data-bi-name="contents-expand"
			data-contents-button
			data-popover-close
		>
			<span class="icon" aria-hidden="true"
				><span class="docon docon-editor-list-bullet"></span
			></span>
			<span class="contents-expand-title">Table of contents</span>
		</button>
	 
		<a
			id="lang-link-overflow"
			class="button-sm inner-focus button button-clear button-block justify-content-flex-start text-align-left"
			data-bi-name="language-toggle"
			data-page-action-item="overflow-all"
			data-check-hidden="true"
			data-read-in-link
			href="#"
			hidden
		>
			<span class="icon" aria-hidden="true" data-read-in-link-icon>
				<span class="docon docon-locale-globe"></span>
			</span>
			<span data-read-in-link-text>Read in English</span>
		</a>
	 
		<button
			type="button"
			class="collection button button-clear button-sm button-block justify-content-flex-start text-align-left inner-focus"
			data-list-type="collection"
			data-bi-name="collection"
			data-page-action-item="overflow-all"
			data-check-hidden="true"
			data-popover-close
		>
			<span class="icon" aria-hidden="true">
				<span class="docon docon-circle-addition"></span>
			</span>
			<span class="collection-status">Add</span>
		</button>
	
					
		<button
			type="button"
			class="collection button button-block button-clear button-sm justify-content-flex-start text-align-left inner-focus"
			data-list-type="plan"
			data-bi-name="plan"
			data-page-action-item="overflow-all"
			data-check-hidden="true"
			data-popover-close
			hidden
		>
			<span class="icon" aria-hidden="true">
				<span class="docon docon-circle-addition"></span>
			</span>
			<span class="plan-status">Add to plan</span>
		</button>
	  
		<a
			data-contenteditbtn
			class="button button-clear button-block button-sm inner-focus justify-content-flex-start text-align-left text-decoration-none"
			data-bi-name="edit"
			
			href="https://github.com/MicrosoftDocs/PowerShell-Docs/blob/main/reference/7.6/Microsoft.PowerShell.Core/About/About.md"
			data-original_content_git_url="https://github.com/MicrosoftDocs/PowerShell-Docs/blob/live/reference/7.6/Microsoft.PowerShell.Core/About/About.md"
			data-original_content_git_url_template="{repo}/blob/{branch}/reference/7.6/Microsoft.PowerShell.Core/About/About.md"
			data-pr_repo=""
			data-pr_branch=""
		>
			<span class="icon" aria-hidden="true">
				<span class="docon docon-edit-outline"></span>
			</span>
			<span>Edit</span>
		</a>
	
					
		<hr class="margin-block-xxs" />
		<h4 class="font-size-sm padding-left-xxs">Share via</h4>
		
					<a
						class="button button-clear button-sm inner-focus button-block justify-content-flex-start text-align-left text-decoration-none share-facebook"
						data-bi-name="facebook"
						data-page-action-item="overflow-all"
						href="#"
					>
						<span class="icon color-primary" aria-hidden="true">
							<span class="docon docon-facebook-share"></span>
						</span>
						<span>Facebook</span>
					</a>

					<a
						href="#"
						class="button button-clear button-sm inner-focus button-block justify-content-flex-start text-align-left text-decoration-none share-twitter"
						data-bi-name="twitter"
						data-page-action-item="overflow-all"
					>
						<span class="icon color-text" aria-hidden="true">
							<span class="docon docon-xlogo-share"></span>
						</span>
						<span>x.com</span>
					</a>

					<a
						href="#"
						class="button button-clear button-sm inner-focus button-block justify-content-flex-start text-align-left text-decoration-none share-linkedin"
						data-bi-name="linkedin"
						data-page-action-item="overflow-all"
					>
						<span class="icon color-primary" aria-hidden="true">
							<span class="docon docon-linked-in-logo"></span>
						</span>
						<span>LinkedIn</span>
					</a>
					<a
						href="#"
						class="button button-clear button-sm inner-focus button-block justify-content-flex-start text-align-left text-decoration-none share-email"
						data-bi-name="email"
						data-page-action-item="overflow-all"
					>
						<span class="icon color-primary" aria-hidden="true">
							<span class="docon docon-mail-message"></span>
						</span>
						<span>Email</span>
					</a>
			  
	 
		<hr class="margin-block-xxs" />
		
				<button
					class="button button-block button-clear button-sm justify-content-flex-start text-align-left inner-focus"
					type="button"
					data-bi-name="copy-markdown"
					data-page-action-item="overflow-all"
					data-copy-markdown
					data-copy-state="idle"
					data-check-hidden="true"
				>
					<span class="icon color-primary" aria-hidden="true">
						<span data-show-when="idle" class="docon docon-code-lang"></span>
						<span data-show-when="loading" class="loader" hidden></span>
						<span data-show-when="success" class="docon docon-check-mark" hidden></span>
					</span>
					<span>Copy Markdown</span>
				</button>
		   
				<button
					class="button button-block button-clear button-sm justify-content-flex-start text-align-left inner-focus"
					type="button"
					data-bi-name="print"
					data-page-action-item="overflow-all"
					data-popover-close
					data-print-page
					data-check-hidden="true"
				>
					<span class="icon color-primary" aria-hidden="true">
						<span class="docon docon-print"></span>
					</span>
					<span>Print</span>
				</button>
		  
	
				</div>
			</details>
		</div>
	
			</div>
		</div>
	  
		<!-- privateUnauthorizedTemplate is hidden by default -->
		<div unauthorized-private-section data-bi-name="permission-content-unauthorized-private" hidden>
			<hr class="hr margin-top-xs margin-bottom-sm" />
			<div class="notification notification-info">
				<div class="notification-content">
					<p class="margin-top-none notification-title">
						<span class="icon" aria-hidden="true"
							><span class="docon docon-exclamation-circle-solid"></span
						></span>
						<span>Note</span>
					</p>
					<p class="margin-top-none authentication-determined not-authenticated">
						Access to this page requires authorization. You can try <a class="docs-sign-in" href="#" data-bi-name="permission-content-sign-in">signing in</a> or <a  class="docs-change-directory" data-bi-name="permisson-content-change-directory">changing directories</a>.
					</p>
					<p class="margin-top-none authentication-determined authenticated">
						Access to this page requires authorization. You can try <a class="docs-change-directory" data-bi-name="permisson-content-change-directory">changing directories</a>.
					</p>
				</div>
			</div>
		</div>
	
					<div class="content"><h1 id="about-topics">About topics</h1></div>
					
		<div
			id="article-metadata"
			data-bi-name="article-metadata"
			data-test-id="article-metadata"
			class="page-metadata-container display-flex gap-xxs justify-content-space-between align-items-center flex-wrap-wrap"
		>
			 
				<div
					id="user-feedback"
					class="margin-block-xxs display-none display-none-print"
					hidden
					data-hide-on-archived
				>
					
		<button
			id="user-feedback-button"
			data-test-id="conceptual-feedback-button"
			class="button button-sm button-clear button-primary display-none"
			type="button"
			data-bi-name="user-feedback-button"
			data-user-feedback-button
			hidden
		>
			<span class="icon" aria-hidden="true">
				<span class="docon docon-like"></span>
			</span>
			<span>Feedback</span>
		</button>
	
				</div>
		  
		</div>
	 
		<div data-id="ai-summary" class="display-none-print">
			<div id="ms--ai-summary-cta" class="margin-top-xs display-flex align-items-center">
				<span class="icon" aria-hidden="true">
					<span class="docon docon-sparkle-fill gradient-text-vivid"></span>
				</span>
				<button
					id="ms--ai-summary"
					type="button"
					class="tag tag-sm tag-suggestion margin-left-xxs"
					data-test-id="ai-summary-cta"
					data-bi-name="ai-summary-cta"
					data-an="ai-summary"
				>
					<span class="ai-summary-cta-text">
						Summarize this article for me
					</span>
				</button>
			</div>
			<!-- Slot where the client will render the summary card after the user clicks the CTA -->
			<div id="ms--ai-summary-header" class="margin-top-xs"></div>
		</div>
	 
		<nav
			id="center-doc-outline"
			class="doc-outline display-none-desktop display-none-print margin-bottom-sm"
			data-bi-name="intopic toc"
			aria-label="In this article"
		>
			<h2 id="ms--in-this-article" class="title is-6 margin-block-xs">
				In this article
			</h2>
		</nav>
	
					<div class="content"><h2 id="description">Description</h2>
<p>About topics cover a range of concepts about PowerShell.</p>
<h2 id="about-topics-1">About Topics</h2>
<h3 id="about_alias_provider"><a href="about_alias_provider?view=powershell-7.6" data-linktype="relative-path">about_Alias_Provider</a></h3>
<p>Provides access to the PowerShell aliases and the values that they represent.</p>
<h3 id="about_aliases"><a href="about_aliases?view=powershell-7.6" data-linktype="relative-path">about_Aliases</a></h3>
<p>Describes how to use alternate names for cmdlets and commands in PowerShell.</p>
<h3 id="about_ansi_terminals"><a href="about_ansi_terminals?view=powershell-7.6" data-linktype="relative-path">about_ANSI_Terminals</a></h3>
<p>Describes the support available for ANSI escape sequences in Windows
PowerShell.</p>
<h3 id="about_arithmetic_operators"><a href="about_arithmetic_operators?view=powershell-7.6" data-linktype="relative-path">about_Arithmetic_Operators</a></h3>
<p>Describes the operators that perform arithmetic in PowerShell.</p>
<h3 id="about_arrays"><a href="about_arrays?view=powershell-7.6" data-linktype="relative-path">about_Arrays</a></h3>
<p>Describes arrays, which are data structures designed to store collections of
items.</p>
<h3 id="about_assignment_operators"><a href="about_assignment_operators?view=powershell-7.6" data-linktype="relative-path">about_Assignment_Operators</a></h3>
<p>Describes how to use operators to assign values to variables.</p>
<h3 id="about_automatic_variables"><a href="about_automatic_variables?view=powershell-7.6" data-linktype="relative-path">about_Automatic_Variables</a></h3>
<p>Describes variables that store state information for PowerShell. These
variables are created and maintained by PowerShell.</p>
<h3 id="about_booleans"><a href="about_booleans?view=powershell-7.6" data-linktype="relative-path">about_Booleans</a></h3>
<p>Describes how boolean expressions are evaluated.</p>
<h3 id="about_break"><a href="about_break?view=powershell-7.6" data-linktype="relative-path">about_Break</a></h3>
<p>Describes the <code>break</code> statement, which provides a way to exit the current
control block.</p>
<h3 id="about_built-in_functions"><a href="about_built-in_functions?view=powershell-7.6" data-linktype="relative-path">about_Built-in_Functions</a></h3>
<p>Describes the built-in functions in PowerShell.</p
