#!/usr/bin/env node
// about.html — portiert nach javascript
// Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/powershell/about.html
// auch in: OpenClaw@gateway2:skills/scripting-utils/references/powershell/about.html
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function createHtmlDocument() {
  const doc = {
    doctype: '<!DOCTYPE html>',
    html: {
      attributes: {
        class: 'layout layout-holy-grail   show-table-of-contents conceptual show-breadcrumb default-focus',
        lang: 'en-us',
        dir: 'ltr',
        'data-authenticated': 'false',
        'data-auth-status-determined': 'false',
        'data-target': 'docs',
        'x-ms-format-detection': 'none'
      },
      head: {
        title: 'About topics - PowerShell | Microsoft Learn',
        meta: [
          { charset: 'utf-8' },
          { name: 'viewport', content: 'width=device-width, initial-scale=1.0' },
          { name: 'color-scheme', content: 'light dark' },
          { name: 'description', content: 'About topics cover a range of concepts about PowerShell.' },
          { rel: 'canonical', href: 'https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about?view=powershell-7.6' },
          { name: 'twitter:card', content: 'summary' },
          { name: 'twitter:site', content: '@MicrosoftLearn' },
          { property: 'og:type', content: 'website' },
          { property: 'og:image:alt', content: 'About topics - PowerShell | Microsoft Learn' },
          { property: 'og:image', content: 'https://learn.microsoft.com/media/logos/logo-powershell-social.png' },
          { property: 'og:title', content: 'About topics - PowerShell' },
          { property: 'og:url', content: 'https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about?view=powershell-7.6' },
          { property: 'og:description', content: 'About topics cover a range of concepts about PowerShell.' },
          { name: 'platform_id', content: '5035edbf-6e09-a6fa-a98d-bb2adc6ab1e0' },
          { name: 'scope', content: 'PowerShell' },
          { name: 'locale', content: 'en-us' },
          { name: 'uhfHeaderId', content: 'MSDocsHeader-Powershell' },
          { name: 'page_type', content: 'conceptual' },
          { name: 'ROBOTS', content: 'INDEX, FOLLOW' },
          { name: 'apiPlatform', content: 'powershell' },
          { name: 'archive_url', content: 'https://learn.microsoft.com/previous-versions/powershell/scripting/overview' },
          { name: 'breadcrumb_path', content: '/powershell/scripting/bread/toc.json' },
          { name: 'feedback_product_url', content: 'https://github.com/PowerShell/PowerShell/issues/new/choose' },
          { name: 'feedback_help_link_url', content: 'https://learn.microsoft.com/powershell/scripting/community/community-support' },
          { name: 'feedback_help_link_type', content: 'ask-the-community' },
          { name: 'feedback_system', content: 'OpenSource' },
          { name: 'hideScope', content: 'false' },
          { name: 'author', content: 'sdwheeler' },
          { name: 'ms.author', content: 'sewhee' },
          { name: 'manager', content: 'jasongroce' },
          { name: 'ms.devlang', content: 'powershell' },
          { name: 'ms.service', content: 'powershell' },
          { name: 'ms.tgt_pltfr', content: 'windows, macos, linux' },
          { name: 'ms.update-cycle', content: '365-days' },
          { name: 'toc_preview', content: 'true' },
          { name: 'ms.topic', content: 'reference' },
          { name: 'products', content: 'https://authoring-docs-microsoft.poolparty.biz/devrel/2bdae855-045f-4535-b365-7b2e23824328' },
          { name: 'products', content: 'https://authoring-docs-microsoft.poolparty.biz/devrel/8bce367e-2e90-4b56-9ed5-5e4e9f3a2dc3' },
          { name: 'Locale', content: 'en-US' },
          { name: 'ms.date', content: '2026-01-18T00:00:00Z' },
          { name: 'document_id', content: '6d07e1b4-9109-26f3-5a6a-20b41b4c66a5' },
          { name: 'document_version_independent_id', content: '2bf88889-d533-2316-9add-a385ebbd4259' },
          { name: 'updated_at', content: '2026-04-02T22:11:00Z' },
          { name: 'original_content_git_url', content: 'https://github.com/MicrosoftDocs/PowerShell-Docs/blob/live/reference/7.6/Microsoft.PowerShell.Core/About/About.md' },
          { name: 'gitcommit', content: 'https://github.com/MicrosoftDocs/PowerShell-Docs/blob/7baf66776aea350bef39470600f075e85f30d7ef/reference/7.6/Microsoft.PowerShell.Core/About/About.md' },
          { name: 'git_commit_id', content: '7baf66776aea350bef39470600f075e85f30d7ef' },
          { name: 'monikers', content: 'powershell-7.6' },
          { name: 'default_moniker', content: 'powershell-7.6' },
          { name: 'site_name', content: 'Docs' },
          { name: 'depot_name', content: 'PowerShell.PowerShell_PowerShell-docs_reference' },
          { name: 'schema', content: 'Conceptual' },
          { name: 'toc_rel', content: '../../psdocs/toc.json' },
          { name: 'word_count', content: '1965' },
          { name: 'config_moniker_range', content: 'powershell-7.6' },
          { name: 'asset_id', content: 'module/microsoft.powershell.core/about/about' },
          { name: 'moniker_range_name', content: '9b5469a01154ce5be5ffa44dbe12b832' },
          { name: 'item_type', content: 'Content' },
          { name: 'source_path', content: 'reference/7.6/Microsoft.PowerShell.Core/About/About.md' },
          { name: 'previous_tlsh_hash', content: 'A12B7262301D8F2E7BE20B1A341CEF4F17F0448C116A19D0012D2537977E1D634728A866C7361B692370488BB39F759D46E8CE22829C53AA1F9127FE495D6A4EE2CDB7B6FC' },
          { name: 'github_feedback_content_git_url', content: 'https://github.com/MicrosoftDocs/PowerShell-Docs/blob/main/reference/7.6/Microsoft.PowerShell.Core/About/About.md' },
          { name: 'markdown_url', content: 'https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about?view=powershell-7.6&amp;accept=text/markdown' }
        ],
        links: [
          { rel: 'stylesheet', href: '/static/assets/0.4.03391.7726-67491f8e/styles/site.css' }
        ],
        scripts: [
          { src: 'https://wcpstatic.microsoft.com/mscc/lib/v2/wcp-consent.js' },
          { src: 'https://js.monitor.azure.com/scripts/c/ms.jsll-4.min.js' },
          { src: '/_themes/docs.theme/master/en-us/_themes/global/deprecation.js' }
        ]
      },
      body: {
        attributes: {
          id: 'body',
          'data-bi-name': 'body',
          class: 'layout-body ',
          lang: 'en-us',
          dir: 'ltr'
        },
        content: [
          {
            tag: 'header',
            attributes: { class: 'layout-body-header' },
            content: [
              {
                tag: 'div',
                attributes: { class: 'header-holder has-default-focus' },
                content: [
                  {
                    tag: 'a',
                    attributes: {
                      href: '#main',
                      style: 'z-index: 1070',
                      class: 'outline-color-text visually-hidden-until-focused position-fixed inner-focus focus-visible top-0 left-0 right-0 padding-xs text-align-center background-color-body'
                    },
                    content: 'Skip to main content'
                  },
                  {
                    tag: 'a',
                    attributes: {
                      href: '#',
                      'data-skip-to-ask-learn': '',
                      style: 'z-index: 1070',
                      class: 'outline-color-text visually-hidden-until-focused position-fixed inner-focus focus-visible top-0 left-0 right-0 padding-xs text-align-center background-color-body',
                      hidden: ''
                    },
                    content: 'Skip to Ask Learn chat experience'
                  },
                  {
                    tag: 'div',
                    attributes: { hidden: '', id: 'cookie-consent-holder', 'data-test-id': 'cookie-consent-container' }
                  },
                  {
                    tag: 'div',
                    attributes: {
                      id: 'unsupported-browser',
                      style: 'background-color: white; color: black; padding: 16px; border-bottom: 1px solid grey;',
                      hidden: ''
                    },
                    content: [
                      {
                        tag: 'div',
                        attributes: { style: 'max-width: 800px; margin: 0 auto;' },
                        content: [
                          {
                            tag: 'p',
                            attributes: { style: 'font-size: 24px' },
                            content: 'This browser is no longer supported.'
                          },
                          {
                            tag: 'p',
                            attributes: { style: 'font-size: 16px; margin-top: 16px;' },
                            content: 'Upgrade to Microsoft Edge to take advantage of the latest features, security updates, and technical support.'
                          },
                          {
                            tag: 'div',
                            attributes: { style: 'margin-top: 12px;' },
                            content: [
                              {
                                tag: 'a',
                                attributes: {
                                  href: 'https://go.microsoft.com/fwlink/p/?LinkID=2092881 ',
                                  style: 'background-color: #0078d4; border: 1px solid #0078d4; color: white; padding: 6px 12px; border-radius: 2px; display: inline-block;'
                                },
                                content: 'Download Microsoft Edge'
                              },
                              {
                                tag: 'a',
                                attributes: {
                                  href: 'https://learn.microsoft.com/en-us/lifecycle/faq/internet-explorer-microsoft-edge',
                                  style: 'background-color: white; padding: 6px 12px; border: 1px solid #505050; color: #171717; border-radius: 2px; display: inline-block;'
                                },
                                content: 'More info about Internet Explorer and Microsoft Edge'
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  },
                  {
                    tag: 'div',
                    attributes: {
                      id: 'ms--site-header',
                      'data-test-id': 'site-header-wrapper',
                      itemscope: 'itemscope',
                      itemtype: 'http://schema.org/Organization'
                    },
                    content: [
                      {
                        tag: 'div',
                        attributes: {
                          id: 'ms--mobile-nav',
                          class: 'site-header display-none-tablet padding-inline-none gap-none',
                          'data-bi-name': 'mobile-header',
                          'data-test-id': 'mobile-header'
                        }
                      },
                      {
                        tag: 'div',
                        attributes: {
                          id: 'ms--primary-nav',
                          class: 'site-header display-none display-flex-tablet',
                          'data-bi-name': 'L1-header',
                          'data-test-id': 'primary-header'
                        }
                      },
                      {
                        tag: 'div',
                        attributes: {
                          id: 'ms--secondary-nav',
                          class: 'site-header display-none display-flex-tablet',
                          'data-bi-name': 'L2-header',
                          'data-test-id': 'secondary-header'
                        }
                      }
                    ]
                  },
                  {
                    tag: 'div',
                    attributes: { 'data-banner': '' },
                    content: [
                      {
                        tag: 'div',
                        attributes: { id: 'disclaimer-holder' }
                      }
                    ]
                  }
                ]
              }
            ]
          },
          {
            tag: 'section',
            attributes: {
              id: 'layout-body-menu',
              class: 'layout-body-menu display-flex',
              'data-bi-name': 'menu'
            },
            content: [
              {
                tag: 'div',
                attributes: {
                  id: 'left-container',
                  class: 'left-container display-none display-block-tablet padding-inline-sm padding-bottom-sm width-full',
                  'data-toc-container': 'true'
                },
                content: [
                  {
                    tag: 'div',
                    attributes: { id: 'ms--toc-content', class: 'height-full' },
                    content: [
                      {
                        tag: 'nav',
                        attributes: {
                          id: 'affixed-left-container',
                          class: 'margin-top-sm-tablet position-sticky display-flex flex-direction-column',
                          'aria-label': 'Primary',
                          'data-bi-name': 'left-toc',
                          role: 'navigation'
                        }
                      }
                    ]
                  },
                  {
                    tag: 'div',
                    attributes: { id: 'ms--toc-content-collapsible', class: 'height-full', hidden: '' },
                    content: [
                      {
                        tag: 'nav',
                        attributes: {
                          id: 'affixed-left-container',
                          class: 'margin-top-sm-tablet position-sticky display-flex flex-direction-column',
                          'aria-label': 'Primary',
                          'data-bi-name': 'left-toc',
                          role: 'navigation'
                        },
                        content: [
                          {
                            tag: 'div',
                            attributes: {
                              id: 'ms--collapsible-toc-header',
                              class: 'display-flex flex-direction-row-reverse justify-content-space-between align-items-center margin-bottom-xxs'
                            },
                            content: [
                              {
                                tag: 'button',
                                attributes: {
                                  type: 'button',
                                  class: 'button button-clear inner-focus',
                                  'data-collapsible-toc-toggle': '',
                                  'aria-expanded': 'true',
                                  'aria-controls': 'ms--collapsible-toc-content',
                                  'aria-label': 'Table of contents'
                                },
                                content: [
                                  {
                                    tag: 'span',
                                    attributes: { class: 'icon font-size-xxl', 'aria-hidden': 'true' },
                                    content: [
                                      {
                                        tag: 'span',
                                        attributes: { class: 'docon docon-panel-left-contract' }
                                      }
                                    ]
                                  }
                                ]
                              },
                              {
                                tag: 'div',
                                attributes: { id: 'ms--collapsible-toc-moniker-slot', class: 'flex-grow-1' }
                              }
                            ]
                          }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          },
          {
            tag: 'main',
            attributes: {
              id: 'main',
              role: 'main',
              class: 'layout-body-main ',
              'data-bi-name': 'content',
              lang: 'en-us',
              dir: 'ltr'
            },
            content: [
              {
                tag: 'div',
                attributes: {
                  id: 'ms--content-header',
                  class: 'content-header default-focus border-bottom-none',
                  'data-bi-name': 'content-header'
                },
                content: [
                  {
                    tag: 'div',
                    attributes: { class: 'content-header-controls margin-xxs margin-inline-sm-tablet' },
                    content: [
                      {
                        tag: 'button',
                        attributes: {
                          type: 'button',
                          class: 'contents-button button button-sm margin-right-xxs',
                          'data-bi-name': 'contents-expand',
                          'aria-haspopup': 'true',
                          'data-contents-button': ''
                        },
                        content: [
                          {
                            tag: 'span',
                            attributes: { class: 'icon', 'aria-hidden': 'true' },
                            content: [
                              {
                                tag: 'span',
                                attributes: { class: 'docon docon-menu' }
                              }
                            ]
                          },
                          {
                            tag: 'span',
                            attributes: { class: 'contents-expand-title' },
                            content: ' Table of contents '
                          }
                        ]
                      },
                      {
                        tag: 'button',
                        attributes: {
                          type: 'button',
                          class: 'ap-collapse-behavior ap-expanded button button-sm',
                          'data-bi-name': 'ap-collapse',
                          'aria-controls': 'action-panel'
                        },
                        content: [
                          {
                            tag: 'span',
                            attributes: { class: 'icon', 'aria-hidden': 'true' },
                            content: [
                              {
                                tag: 'span',
                                attributes: { class: 'docon docon-exit-mode' }
                              }
                            ]
                          },
                          {
                            tag: 'span',
                            content: 'Exit editor mode'
                          }
                        ]
                      }
                    ]
                  }
                ]
              },
              {
                tag: 'div',
                attributes: { 'data-main-column': '', class: 'padding-sm padding-top-none padding-top-sm-tablet' },
                content: [
                  {
                    tag: 'div',
                    content: [
                      {
                        tag: 'div',
                        attributes: { id: 'article-header', class: 'background-color-body margin-bottom-xs display-none-print' },
                        content: [
                          {
                            tag: 'div',
                            attributes: { class: 'display-flex align-items-center justify-content-space-between' },
                            content: [
                              {
                                tag: 'details',
                                attributes: {
                                  id: 'article-header-breadcrumbs-overflow-popover',
                                  class: 'popover',
                                  'data-for': 'article-header-breadcrumbs'
                                },
                                content: [
                                  {
                                    tag: 'summary',
                                    attributes: {
                                      class: 'button button-clear button-primary button-sm inner-focus',
                                      'aria-label': 'All breadcrumbs'
                                    },
                                    content: [
                                      {
                                        tag: 'span',
                                        attributes: { class: 'icon', 'aria-hidden': 'true' },
                                        content: [
                                          {
                                            tag: 'span',
                                            attributes: { class: 'docon docon-more' }
                                          }
                                        ]
                                      }
                                    ]
                                  },
                                  {
                                    tag: 'div',
                                    attributes: { id: 'article-header-breadcrumbs-overflow', class: 'popover-content padding-none' }
                                  }
                                ]
                              },
                              {
                                tag: 'bread-crumbs',
                                attributes: {
                                  id: 'article-header-breadcrumbs',
                                  role: 'group',
                                  'aria-label': 'Breadcrumbs',
                                  'data-test-id': 'article-header-breadcrumbs',
                                  class: 'overflow-hidden flex-grow-1 margin-right-sm margin-right-md-tablet margin-right-lg-desktop margin-left-negative-xxs padding-left-xxs'
                                }
                              },
                              {
                                tag: 'div',
                                attributes: {
                                  id: 'article-header-page-actions',
                                  class: 'opacity-none margin-left-auto display-flex flex-wrap-no-wrap align-items-stretch'
                                },
                                content: [
                                  {
                                    tag: 'button',
                                    attributes: {
                                      class: 'button button-sm border-none inner-focus display-none-tablet flex-shrink-0 ',
                                      'data-bi-name': 'ask-learn-assistant-entry',
                                      'data-test-id': 'ask-learn-assistant-modal-entry-mobile',
                                      'data-ask-learn-modal-entry': '',
                                      type: 'button',
                                      style: 'min-width: max-content;',
                                      'aria-expanded': 'false',
                                      'aria-label': 'Ask Learn',
                                      hidden: ''
                                    },
                                    content: [
                                      {
                                        tag: 'span',
                                        attributes: { class: 'icon font-size-lg', 'aria-hidden': 'true' },
                                        content: [
                                          {
                                            tag: 'span',
                                            attributes: { class: 'docon docon-chat-sparkle-fill gradient-ask-learn-logo' }
                                          }
                                        ]
                                      }
                                    ]
                                  },
                                  {
                                    tag: 'button',
                                    attributes: {
                                      class: 'button button-sm display-none display-inline-flex-tablet display-none-desktop flex-shrink-0 margin-right-xxs border-color-ask-learn ',
                                      'data-bi-name': 'ask-learn-assistant-entry',
                                      'data-test-id': 'ask-learn-assistant-modal-entry-tablet',
                                      'data-ask-learn-modal-entry': '',
                                      type: 'button',
                                      style: 'min-width: max-content;',
                                      'aria-expanded': 'false',
                                      hidden: ''
                                    },
                                    content: [
                                      {
                                        tag: 'span',
                                        attributes: { class: 'icon font-size-lg', 'aria-hidden': 'true' },
                                        content: [
                                          {
                                            tag: 'span',
                                            attributes: { class: 'docon docon-chat-sparkle-fill gradient-ask-learn-logo' }
                                          }
                                        ]
                                      },
                                      {
                                        tag: 'span',
                                        content: 'Ask Learn'
                                      }
                                    ]
                                  },
                                  {
                                    tag: 'button',
                                    attributes: {
                                      class: 'button button-sm display-none flex-shrink-0 display-inline-flex-desktop margin-right-xxs border-color-ask-learn ',
                                      'data-bi-name': 'ask-learn-assistant-entry',
                                      'data-test-id': 'ask-learn-assistant-flyout-entry',
                                      'data-ask-learn-flyout-entry': '',
                                      'data-flyout-button': 'toggle',
                                      type: 'button',
                                      style: 'min-width: max-content;',
                                      'aria-expanded': 'false',
                                      'aria-controls': 'ask-learn-flyout',
                                      hidden: ''
                                    },
                                    content: [
                                      {
                                        tag: 'span',
                                        attributes: { class: 'icon font-size-lg', 'aria-hidden': 'true' },
                                        content: [
                                          {
                                            tag: 'span',
                                            attributes: { class: 'docon docon-chat-sparkle-fill gradient-ask-learn-logo' }
                                          }
                                        ]
                                      },
                                      {
                                        tag: 'span',
                                        content: 'Ask Learn'
                                      }
                                    ]
                                  },
                                  {
                                    tag: 'button',
                                    attributes: {
                                      type: 'button',
                                      id: 'ms--focus-mode-button',
                                      'data-focus-mode': '',
                                      'data-bi-name': 'focus-mode-entry',
                                      class: 'button button-sm flex-shrink-0 margin-right-xxs display-none display-inline-flex-desktop'
                                    },
                                    content: [
                                      {
                                        tag: 'span',
                                        attributes: { class: 'icon font-size-lg', 'aria-hidden': 'true' },
                                        content: [
                                          {
                                            tag: 'span',
                                            attributes: { class: 'docon docon-glasses' }
                                          }
                                        ]
                                      },
                                      {
                                        tag: 'span',
                                        content: 'Focus mode'
                                      }
                                    ]
                                  },
                                  {
                                    tag: 'details',
                                    attributes: { class: 'popover popover-right', id: 'article-header-page-actions-overflow' },
                                    content: [
                                      {
                                        tag: 'summary',
                                        attributes: {
                                          class: 'justify-content-flex-start button button-clear button-sm button-primary inner-focus',
                                          'aria-label': 'More actions',
                                          title: 'More actions'
                                        },
                                        content: [
                                          {
                                            tag: 'span',
                                            attributes: { class: 'icon', 'aria-hidden': 'true' },
                                            content: [
                                              {
                                                tag: 'span',
                                                attributes: { class: 'docon docon-more-vertical' }
                                              }
                                            ]
                                          }
                                        ]
                                      },
                                      {
                                        tag: 'div',
                                        attributes: { class: 'popover-content' },
                                        content: [
                                          {
                                            tag: 'button',
                                            attributes: {
                                              'data-page-action-item': 'overflow-mobile',
                                              type: 'button',
                                              class: 'button-block button-sm inner-focus button button-clear display-none-tablet justify-content-flex-start text-align-left',
                                              'data-bi-name': 'contents-expand',
                                              'data-contents-button': '',
                                              'data-popover-close': ''
                                            },
                                            content: [
                                              {
                                                tag: 'span',
                                                attributes: { class: 'icon', 'aria-hidden': 'true' },
                                                content: [
                                                  {
                                                    tag: 'span',
                                                    attributes: { class: 'docon docon-editor-list-bullet' }
                                                  }
                                                ]
                                              },
                                              {
                                                tag: 'span',
                                                attributes: { class: 'contents-expand-title' },
                                                content: 'Table of contents'
                                              }
                                            ]
                                          },
                                          {
                                            tag: 'a',
                                            attributes: {
                                              id: 'lang-link-overflow',
                                              class: 'button-sm inner-focus button button-clear button-block justify-content-flex-start text-align-left',
                                              'data-bi-name': 'language-toggle',
                                              'data-page-action-item': 'overflow-all',
                                              'data-check-hidden': 'true',
                                              'data-read-in-link': '',
                                              href: '#',
                                              hidden: ''
                                            },
                                            content: [
                                              {
                                                tag: 'span',
                                                attributes: { class: 'icon', 'aria-hidden': 'true', 'data-read-in-link-icon': '' },
                                                content: [
                                                  {
                                                    tag: 'span',
                                                    attributes: { class: 'docon docon-locale-globe' }
                                                  }
                                                ]
                                              },
                                              {
                                                tag: 'span',
                                                attributes: { 'data-read-in-link-text': '' },
                                                content: 'Read in English'
                                              }
                                            ]
                                          },
                                          {
                                            tag: 'button',
                                            attributes: {
                                              type: 'button',
                                              class: 'collection button button-clear button-sm button-block justify-content-flex-start text-align-left inner-focus',
                                              'data-list-type': 'collection',
                                              'data-bi-name': 'collection',
                                              'data-page-action-item': 'overflow-all',
                                              'data-check-hidden': 'true',
                                              'data-popover-close': ''
                                            },
                                            content: [
                                              {
                                                tag: 'span',
                                                attributes: { class: 'icon', 'aria-hidden': 'true' },
                                                content: [
                                                  {
                                                    tag: 'span',
                                                    attributes: { class: 'docon docon-circle-addition' }
                                                  }
                                                ]
                                              },
                                              {
                                                tag: 'span',
                                                attributes: { class: 'collection-status' },
                                                content: 'Add'
                                              }
                                            ]
                                          },
                                          {
                                            tag: 'button',
                                            attributes: {
                                              type: 'button',
                                              class: 'collection button button-block button-clear button-sm justify-content-flex-start text-align-left inner-focus',
                                              'data-list-type': 'plan',
                                              'data-bi-name': 'plan',
                                              'data-page-action-item': 'overflow-all',
                                              'data-check-hidden': 'true',
                                              'data-popover-close': '',
                                              hidden: ''
                                            },
                                            content: [
                                              {
                                                tag: 'span',
                                                attributes: { class: 'icon', 'aria-hidden': 'true' },
                                                content: [
                                                  {
                                                    tag: 'span',
                                                    attributes: { class: 'docon docon-circle-addition' }
                                                  }
                                                ]
                                              },
                                              {
                                                tag: 'span',
                                                attributes: { class: 'plan-status' },
                                                content: 'Add to plan'
                                              }
                                            ]
                                          },
                                          {
                                            tag: 'a',
                                            attributes: {
                                              'data-contenteditbtn': '',
                                              class: 'button button-clear button-block button-sm inner-focus justify-content-flex-start text-align-left text-decoration-none',
                                              'data-bi-name': 'edit',
                                              href: 'https://github.com/MicrosoftDocs/PowerShell-Docs/blob/main/reference/7.6/Microsoft.PowerShell.Core/About/About.md',
                                              'data-original_content_git_url': 'https://github.com/MicrosoftDocs/PowerShell-Docs/blob/live/reference/7.6/Microsoft.PowerShell.Core/About/About.md',
                                              'data-original_content_git_url_template': '{repo}/blob/{branch}/reference/7.6/Microsoft.PowerShell.Core/About/About.md',
                                              'data-pr_repo': '',
                                              'data-pr_branch': ''
                                            },
                                            content: [
                                              {
                                                tag: 'span',
                                                attributes: { class: 'icon', 'aria-hidden': 'true' },
                                                content: [
                                                  {
                                                    tag: 'span',
                                                    attributes: { class: 'docon docon-edit-outline' }
                                                  }
                                                ]
                                              },
                                              {
                                                tag: 'span',
                                                content: 'Edit'
                                              }
                                            ]
                                          },
                                          {
                                            tag: 'hr',
                                            attributes: { class: 'margin-block-xxs' }
                                          },
                                          {
                                            tag: 'h4',
                                            attributes: { class: 'font-size-sm padding-left-xxs' },
                                            content: 'Share via'
                                          },
                                          {
                                            tag: 'a',
                                            attributes: {
                                              class: 'button button-clear button-sm inner-focus button-block justify-content-flex-start text-align-left text-decoration-none share-facebook',
                                              'data-bi-name': 'facebook',
                                              'data-page-action-item': 'overflow-all',
                                              href: '#'
                                            },
                                            content: [
                                              {
                                                tag: 'span',
                                                attributes: { class: 'icon color-primary', 'aria-hidden': 'true' },
                                                content: [
                                                  {
                                                    tag: 'span',
                                                    attributes: { class: 'docon docon-facebook-share' }
                                                  }
                                                ]
                                              },
                                              {
                                                tag: 'span',
                                                content: 'Facebook'
                                              }
                                            ]
                                          },
                                          {
                                            tag: 'a',
                                            attributes: {
                                              href: '#',
                                              class: 'button button-clear button-sm inner-focus button-block justify-content-flex-start text-align-left text-decoration-none share-twitter',
                                              'data-bi-name': 'twitter',
                                              'data-page-action-item': 'overflow-all'
                                            },
                                            content: [
                                              {
                                                tag: 'span',
                                                attributes: { class: 'icon color-text', 'aria-hidden': 'true' },
                                                content: [
                                                  {
                                                    tag: 'span',
                                                    attributes: { class: 'docon docon-xlogo-share' }
                                                  }
                                                ]
                                              },
                                              {
                                                tag: 'span',
                                                content: 'x.com'
                                              }
                                            ]
                                          },
                                          {
                                            tag: 'a',
                                            attributes: {
                                              href: '#',
                                              class: 'button button-clear button-sm inner-focus button-block justify-content-flex-start text-align-left text-decoration-none share-linkedin',
                                              'data-bi-name': 'linkedin',
                                              'data-page-action-item': 'overflow-all'
                                            },
                                            content: [
                                              {
                                                tag: 'span',
                                                attributes: { class: 'icon color-primary', 'aria-hidden': 'true' },
                                                content: [
                                                  {
                                                    tag: 'span',
                                                    attributes: { class: 'docon docon-linked-in-logo' }
                                                  }
                                                ]
                                              },
                                              {
                                                tag: 'span',
                                                content: 'LinkedIn'
                                              }
                                            ]
                                          },
                                          {
                                            tag: 'a',
                                            attributes: {
                                              href: '#',
                                              class: 'button button-clear button-sm inner-focus button-block justify-content-flex-start text-align-left text-decoration-none share-email',
                                              'data-bi-name': 'email',
                                              'data-page-action-item': 'overflow-all'
                                            },
                                            content: [
                                              {
                                                tag: 'span',
                                                attributes: { class: 'icon color-primary', 'aria-hidden': 'true' },
                                                content: [
                                                  {
                                                    tag: 'span',
                                                    attributes: { class: 'docon docon-mail-message' }
                                                  }
                                                ]
                                              },
                                              {
                                                tag: 'span',
                                                content: 'Email'
                                              }
                                            ]
                                          },
                                          {
                                            tag: 'hr',
                                            attributes: { class: 'margin-block-xxs' }
                                          },
                                          {
                                            tag: 'button',
                                            attributes: {
                                              class: 'button button-block button-clear button-sm justify-content-flex-start text-align-left inner-focus',
                                              type: 'button',
                                              'data-bi-name': 'copy-markdown',
                                              'data-page-action-item': 'overflow-all',
                                              'data-copy-markdown': '',
                                              'data-copy-state': 'idle',
                                              'data-check-hidden': 'true'
                                            },
                                            content: [
                                              {
                                                tag: 'span',
                                                attributes: { class: 'icon color-primary', 'aria-hidden': 'true' },
                                                content: [
                                                  {
                                                    tag: 'span',
                                                    attributes: { 'data-show-when': 'idle', class: 'docon docon-code-lang' }
                                                  },
                                                  {
                                                    tag: 'span',
                                                    attributes: { 'data-show-when': 'loading', class: 'loader', hidden: '' }
                                                  },
                                                  {
                                                    tag: 'span',
                                                    attributes: { 'data-show-when': 'success', class: 'docon docon-check-mark', hidden: '' }
                                                  }
                                                ]
                                              },
                                              {
                                                tag: 'span',
                                                content: 'Copy Markdown'
                                              }
                                            ]
                                          },
                                          {
                                            tag: 'button',
                                            attributes: {
                                              class: 'button button-block button-clear button-sm justify-content-flex-start text-align-left inner-focus',
                                              type: 'button',
                                              'data-bi-name': 'print',
                                              'data-page-action-item': 'overflow-all',
                                              'data-popover-close': '',
                                              'data-print-page': '',
                                              'data-check-hidden': 'true'
                                            },
                                            content: [
                                              {
                                                tag: 'span',
                                                attributes: { class: 'icon color-primary', 'aria-hidden': 'true' },
                                                content: [
                                                  {
                                                    tag: 'span',
                                                    attributes: { class: 'docon docon-print' }
                                                  }
                                                ]
                                              },
                                              {
                                                tag: 'span',
                                                content: 'Print'
                                              }
                                            ]
                                          }
                                        ]
                                      }
                                    ]
                                  }
                                ]
                              }
                            ]
                          }
                        ]
                      },
                      {
                        tag: 'div',
                        attributes: { 'unauthorized-private-section': '', 'data-bi-name': 'permission-content-unauthorized-private', hidden: '' },
                        content: [
                          {
                            tag: 'hr',
                            attributes: { class: 'hr margin-top-xs margin-bottom-sm' }
                          },
                          {
                            tag: 'div',
                            attributes: { class: 'notification notification-info' },
                            content: [
                              {
                                tag: 'div',
                                attributes: { class: 'notification-content' },
                                content: [
                                  {
                                    tag: 'p',
                                    attributes: { class: 'margin-top-none notification-title' },
                                    content: [
                                      {
                                        tag: 'span',
                                        attributes: { class: 'icon', 'aria-hidden': 'true' },
                                        content: [
                                          {
                                            tag: 'span',
                                            attributes: { class: 'docon docon-exclamation-circle-solid' }
                                          }
                                        ]
                                      },
                                      {
                                        tag: 'span',
                                        content: 'Note'
                                      }
                                    ]
                                  },
                                  {
                                    tag: 'p',
                                    attributes: { class: 'margin-top-none authentication-determined not-authenticated' },
                                    content: 'Access to this page requires authorization. You can try <a class="docs-sign-in" href="#" data-bi-name="permission-content-sign-in">signing in</a> or <a  class="docs-change-directory" data-bi-name="permisson-content-change-directory">changing directories</a>.'
                                  },
                                  {
                                    tag: 'p',
                                    attributes: { class: 'margin-top-none authentication-determined authenticated' },
                                    content: 'Access to this page requires authorization. You can try <a class="docs-change-directory" data-bi-name="permisson-content-change-directory">changing directories</a>.'
                                  }
                                ]
                              }
                            ]
                          }
                        ]
                      },
                      {
                        tag: 'div',
                        attributes: { class: 'content' },
                        content: [
                          {
                            tag: 'h1
