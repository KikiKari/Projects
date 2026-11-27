// abstraction-provenance: {"artifact_sha256": "5ddc8998309cccc68902458fcbfdb5dd740765dd7d2aebbc523836e6b4ea3ed7", "source_sha256": "0f3530ed5a95fa71241e65119ede0362d09d6dbde8fbabfc84d844298613edb6", "target_language": "fsharp"}
// language.html — portiert nach fsharp
// Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/raku/language.html
// auch in: OpenClaw@gateway2:skills/scripting-utils/references/raku/language.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO

type HtmlElement = {
    Tag: string
    Attributes: Map<string, string>
    Content: HtmlContent list
}

and HtmlContent =
    | Element of HtmlElement
    | Text of string
    | Raw of string

let createElement tag attrs content = { Tag = tag; Attributes = Map attrs; Content = content }
let text s = Text s
let raw s = Raw s

let (@=) key value = (key, value)

let htmlDocument =
    let docType = "<!DOCTYPE html>"
    
    let headSection = 
        createElement "head" [] [
            createElement "title" [] [text "404 | Raku Documentation"]
            createElement "meta" ["charset" @= "UTF-8"] []
            
            // Favicon
            createElement "link" [
                "href" @= "/assets/images/Camelia.ico"
                "rel" @= "icon"
                "type" @= "image/x-icon"
            ] []
            
            // Stylesheets
            createElement "link" ["href" @= "/assets/css/Website.css"; "rel" @= "stylesheet"] []
            createElement "link" ["href" @= "/assets/css/css/filtered-toc-dark.css"; "rel" @= "stylesheet"; "title" @= "dark"] []
            createElement "link" ["href" @= "/assets/css/css/filtered-toc-light.css"; "rel" @= "stylesheet"; "title" @= "light"] []
            createElement "link" ["href" @= "/assets/css/css/rainbow-dark.css"; "rel" @= "stylesheet"; "title" @= "dark"] []
            createElement "link" ["href" @= "/assets/css/css/rainbow-light.css"; "rel" @= "stylesheet"; "title" @= "light"] []
            createElement "link" ["href" @= "/assets/css/tm-styling.css"; "rel" @= "stylesheet"] []
            createElement "link" ["href" @= "/assets/css/tm-light.css"; "rel" @= "stylesheet"; "title" @= "light"] []
            createElement "link" ["href" @= "/assets/css/tm-dark.css"; "rel" @= "stylesheet"; "title" @= "dark"] []
            createElement "link" ["href" @= "/assets/css/all.min.css"; "rel" @= "stylesheet"] []
            createElement "link" ["href" @= "/assets/css/listf-styling-light.css"; "rel" @= "stylesheet"; "title" @= "light"] []
            createElement "link" ["href" @= "/assets/css/listf-styling-dark.css"; "rel" @= "stylesheet"; "title" @= "dark"] []
            createElement "link" ["href" @= "/assets/css/typegraph-styling.css"; "rel" @= "stylesheet"] []
            createElement "link" ["href" @= "/assets/css/typegraph-dark.css"; "rel" @= "stylesheet"; "title" @= "dark"] []
            createElement "link" ["href" @= "/assets/css/typegraph-light.css"; "rel" @= "stylesheet"; "title" @= "light"] []
            createElement "link" ["href" @= "/assets/css/css/page-styling-main.css"; "rel" @= "stylesheet"] []
            createElement "link" ["href" @= "/assets/css/css/page-styling-dark.css"; "rel" @= "stylesheet"; "title" @= "dark"] []
            createElement "link" ["href" @= "/assets/css/css/page-styling-light.css"; "rel" @= "stylesheet"; "title" @= "light"] []
            createElement "link" ["href" @= "/assets/css/css/chyronToggle-dark.css"; "rel" @= "stylesheet"; "title" @= "dark"] []
            createElement "link" ["href" @= "/assets/css/css/chyronToggle-light.css"; "rel" @= "stylesheet"; "title" @= "light"] []
            createElement "link" ["href" @= "/assets/css/css/centreToggle-dark.css"; "rel" @= "stylesheet"; "title" @= "dark"] []
            createElement "link" ["href" @= "/assets/css/css/centreToggle-light.css"; "rel" @= "stylesheet"; "title" @= "light"] []
            createElement "link" ["href" @= "/assets/css/css/options-search-light.css"; "rel" @= "stylesheet"; "title" @= "light"] []
            createElement "link" ["href" @= "/assets/css/css/options-search-dark.css"; "rel" @= "stylesheet"; "title" @= "dark"] []
            createElement "link" ["href" @= "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-light.min.css"; "rel" @= "stylesheet"; "title" @= "light"] []
            createElement "link" ["href" @= "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css"; "rel" @= "stylesheet"; "title" @= "dark"] []
            createElement "link" ["href" @= "https://cdn.jsdelivr.net/npm/@tarekraafat/autocomplete.js@10.2.7/dist/css/autoComplete.min.css"; "rel" @= "stylesheet"] []
            
            // Scripts
            createElement "script" ["src" @= "https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"] []
            createElement "script" ["src" @= "/assets/scripts/all.min.js"] []
            createElement "script" ["src" @= "/assets/scripts/tableManager.js"] []
            createElement "script" ["src" @= "/assets/scripts/filter-script.js"] []
            createElement "script" ["src" @= "https://cdn.jsdelivr.net/npm/fuzzysort@2.0.4/fuzzysort.min.js"] []
            createElement "script" ["src" @= "https://cdn.jsdelivr.net/npm/@tarekraafat/autocomplete.js@10.2.7/dist/autoComplete.min.js"] []
            createElement "script" ["src" @= "/assets/scripts/filtered-toc.js"] []
            createElement "script" ["src" @= "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"] []
            createElement "script" ["src" @= "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/haskell.min.js"] []
            createElement "script" ["src" @= "/assets/scripts/options-search.js"] []
            createElement "script" ["src" @= "/assets/scripts/page-styling.js"] []
            createElement "script" ["src" @= "/assets/scripts/rainbow.js"] []
        ]
    
    let bodySection =
        createElement "body" ["class" @= "has-navbar-fixed-top"] [
            // Top anchor
            createElement "div" ["id" @= "404"; "class" @= "top-of-page"] []
            
            // Navigation bar
            createElement "nav" ["class" @= "navbar is-fixed-top is-flex-touch"; "role" @= "navigation"; "aria-label" @= "main navigation"] [
                createElement "div" ["class" @= "navbar-item"; "style" @= "margin-left: auto;"] [
                    createElement "div" ["class" @= "left-bar-toggle"; "title" @= "Toggle Table of Contents & Index"] [
                        createElement "label" ["class" @= "chyronToggle left"] [
                            createElement "input" ["id" @= "navbar-left-toggle"; "type" @= "checkbox"] []
                            createElement "span" ["class" @= "text"] [text "Contents"]
                        ]
                    ]
                ]
                
                createElement "div" ["class" @= "container is-justify-content-space-around"] [
                    // Brand section
                    createElement "div" ["class" @= "navbar-brand"] [
                        createElement "div" ["class" @= "navbar-logo"] [
                            createElement "a" ["class" @= "navbar-item"; "href" @= "/"] [
                                createElement "img" [
                                    "src" @= "/assets/images/camelia-recoloured.png"
                                    "alt" @= "Raku"
                                    "width" @= "52.83"
                                    "height" @= "38"
                                ] []
                            ]
                            createElement "span" ["class" @= "navbar-logo-tm"] [text "tm"]
                        ]
                        createElement "a" [
                            "role" @= "button"
                            "class" @= "navbar-burger burger"
                            "aria-label" @= "menu"
                            "aria-expanded" @= "false"
                            "data-target" @= "navMenu"
                        ] [
                            createElement "span" ["aria-hidden" @= "true"] []
                            createElement "span" ["aria-hidden" @= "true"] []
                            createElement "span" ["aria-hidden" @= "true"] []
                        ]
                    ]
                    
                    // Menu section
                    createElement "div" ["id" @= "navMenu"; "class" @= "navbar-menu"] [
                        createElement "div" ["class" @= "navbar-start"] [
                            createElement "a" ["class" @= "navbar-item"; "href" @= "/introduction"; "title" @= "Getting started, Tutorials, Migration guides"] [text "Introduction"]
                            createElement "a" ["class" @= "navbar-item"; "href" @= "/reference"; "title" @= "Fundamentals, General reference"] [text "Reference"]
                            createElement "a" ["class" @= "navbar-item"; "href" @= "/miscellaneous"; "title" @= "Programs, Experimental"] [text "Miscellaneous"]
                            createElement "a" ["class" @= "navbar-item"; "href" @= "/types"; "title" @= "The core types (classes) available"] [text "Types"]
                            createElement "a" ["class" @= "navbar-item"; "href" @= "/routines"; "title" @= "Searchable table of routines"] [text "Routines"]
                            createElement "a" ["class" @= "navbar-item"; "href" @= "https://raku.org"; "title" @= "Home page for community"] [raw "Raku<sup>®</sup>"]
                            createElement "a" ["class" @= "navbar-item"; "href" @= "https://web.libera.chat/#raku"; "title" @= "IRC live chat"] [text "Chat"]
                            
                            // Dropdown menu
                            createElement "div" ["class" @= "navbar-item has-dropdown is-hoverable"] [
                                createElement "a" ["class" @= "navbar-link"] [text "More"]
                                createElement "div" ["class" @= "navbar-dropdown is-right is-rounded"] [
                                    createElement "hr" ["class" @= "navbar-divider"] []
                                    createElement "a" ["class" @= "navbar-item js-modal-trigger"; "data-target" @= "download-ebook"] [text "Download E-Book (epub)"]
                                    createElement "hr" ["class" @= "navbar-divider"] []
                                    createElement "a" ["class" @= "navbar-item"; "href" @= "/about"] [text "About"]
                                    createElement "hr" ["class" @= "navbar-divider"] []
                                    createElement "a" ["class" @= "navbar-item has-text-red"; "href" @= "https://github.com/raku/doc-website/issues"] [text "Report an issue with this site"]
                                    createElement "hr" ["class" @= "navbar-divider"] []
                                    createElement "a" ["class" @= "navbar-item"; "href" @= "https://github.com/raku/doc/issues"] [text "Report an issue with the documentation content"]
                                ]
                            ]
                        ]
                        
                        // Search section
                        createElement "div" ["class" @= "navbar-end navbar-search-wrapper"] [
                            createElement "div" ["class" @= "navbar-item"] [
                                createElement "div" ["class" @= "field has-addons"] [
                                    createElement "div" ["class" @= "autoComplete_options"] [
                                        createElement "input" [
                                            "class" @= "control input"
                                            "id" @= "autoComplete"
                                            "type" @= "search"
                                            "dir" @= "ltr"
                                            "spellcheck" @= "false"
                                            "autocorrect" @= "off"
                                            "autocomplete" @= "off"
                                            "autocapitalize" @= "off"
                                            "placeholder" @= "🔍 Type f to search for ..."
                                        ] []
                                    ]
                                    createElement "div" ["class" @= "control"; "title" @= "Search options"] [
                                        createElement "a" [
                                            "class" @= "button is-primary js-modal-trigger"
                                            "data-target" @= "options-search-info"
                                        ] [
                                            createElement "span" ["class" @= "icon"] [
                                                createElement "i" ["class" @= "fas fa-cogs"] []
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                    
                    // Options search modal
                    createElement "div" ["id" @= "options-search-info"; "class" @= "modal"] [
                        createElement "div" ["class" @= "modal-background"] []
                        createElement "div" ["class" @= "modal-content"] [
                            createElement "div" ["class" @= "box"] [
                                createElement "p" [] [text "The last search was: "; createElement "span" ["id" @= "selected-candidate"; "class" @= "ss-selected"] []]
                                createElement "div" ["class" @= "control is-grouped is-grouped-centered options-search-controls"] [
                                    createElement "label" ["class" @= "centreToggle"; "title" @= "Include extra information (Alt-E)"; "style" @= "--switch-width: 10.5"] [
                                        createElement "input" ["id" @= "options-search-extra"; "type" @= "checkbox"] []
                                        createElement "span" ["class" @= "text"] [text "Extra info"]
                                        createElement "span" ["class" @= "on"] [text "yes"]
                                        createElement "span" ["class" @= "off"] [text "no"]
                                    ]
                                    createElement "p" [] [text "The search response can be shortened by excluding the extra information line (Alt-E)"]
                                    
                                    createElement "label" ["class" @= "centreToggle"; "title" @= "Search engine type Strict/Loose (Alt-L)"; "style" @= "--switch-width: 10.5"] [
                                        createElement "input" ["id" @= "options-search-loose"; "type" @= "checkbox"] []
                                        createElement "span" ["class" @= "text"] [text "Search type"]
                                        createElement "span" ["class" @= "on"] [text "loose"]
                                        createElement "span" ["class" @= "off"] [text "strict"]
                                    ]
                                    createElement "p" [] [text " The search engine can perform a strict search (only the characters in the search box) or a loose search (Alt-L)"]
                                    
                                    createElement "label" ["class" @= "centreToggle"; "title" @= "Search in headings (Alt-H)"; "style" @= "--switch-width: 10.5"] [
                                        createElement "input" ["id" @= "options-search-headings"; "type" @= "checkbox"] []
                                        createElement "span" ["class" @= "text"] [text "Headings"]
                                        createElement "span" ["class" @= "on"] [text "yes"]
                                        createElement "span" ["class" @= "off"] [text "no"]
                                    ]
                                    createElement "p" [] [text "Search through headings in all web-pages (Alt-H)"]
                                    
                                    createElement "label" ["class" @= "centreToggle"; "title" @= "Search indexed items (Alt-I)"; "style" @= "--switch-width: 10.5"] [
                                        createElement "input" ["id" @= "options-search-indexed"; "type" @= "checkbox"] []
                                        createElement "span" ["class" @= "text"] [text "Indexed"]
                                        createElement "span" ["class" @= "on"] [text "yes"]
                                        createElement "span" ["class" @= "off"] [text "no"]
                                    ]
                                    createElement "p" [] [text "Search through all indexed items (Alt-I)"]
                                    
                                    createElement "label" ["class" @= "centreToggle"; "title" @= "Search composite pages (Alt-C)"; "style" @= "--switch-width: 10.5"] [
                                        createElement "input" ["id" @= "options-search-composite"; "type" @= "checkbox"] []
                                        createElement "span" ["class" @= "text"] [text "Composite"]
                                        createElement "span" ["class" @= "on"] [text "yes"]
                                        createElement "span" ["class" @= "off"] [text "no"]
                                    ]
                                    createElement "p" [] [text "Search in the names of composite pages, which combine similar information from the main web pages (Alt-C)"]
                                    
                                    createElement "label" ["class" @= "centreToggle"; "title" @= "Search primary sources (Alt-P)"; "style" @= "--switch-width: 10.5"] [
                                        createElement "input" ["id" @= "options-search-primary"; "type" @= "checkbox"] []
                                        createElement "span" ["class" @= "text"] [text "Primary"]
                                        createElement "span" ["class" @= "on"] [text "yes"]
                                        createElement "span" ["class" @= "off"] [text "no"]
                                    ]
                                    createElement "p" [] [text "Search through the names of the main web pages (Alt-P)"]
                                    
                                    createElement "label" ["class" @= "centreToggle"; "title" @= "Open in new tab (Alt-Q)"; "style" @= "--switch-width: 10.5"] [
                                        createElement "input" ["id" @= "options-search-newtab"; "type" @= "checkbox"] []
                                        createElement "span" ["class" @= "text"] [text "New tab"]
                                        createElement "span" ["class" @= "on"] [text "yes"]
                                        createElement "span" ["class" @= "off"] [text "no"]
                                    ]
                                    createElement "p" [] [text "Once a search candidate has been chosen, it can be opened in a new tab or in the current tab (Alt-Q)"]
                                    createElement "p" [] [text "If all else fails, an item is added to use the Google search engine on the whole site"]
                                    createElement "button" ["class" @= "button is-warning"; "id" @= "options-search-reset-defaults"] [text "Clear options, reset to defaults"]
                                    createElement "p" [] [text "Exit this page by pressing <Escape>, or clicking on X or on the background."]
                                ]
                            ]
                        ]
                        createElement "button" ["class" @= "modal-close is-large"; "aria-label" @= "close"] []
                    ]
                    
                    // Download ebook modal
                    createElement "div" ["id" @= "download-ebook"; "class" @= "modal"] [
                        createElement "div" ["class" @= "modal-background"] []
                        createElement "div" ["class" @= "modal-content"] [
                            createElement "div" ["class" @= "box"] [
                                createElement "p" [] [
                                    createElement "a" ["href" @= "/RakuDocumentation.epub"; "download" @= ""] [text "RakuDocumentation.epub"]
                                    text " is a work in progress e-book. It targets the "
                                    createElement "a" ["href" @= "https://www.w3.org/publishing/epub3/"] [text "EPUB v3 specification"]
                                    text ". It needs testing on a variety of ereaders (some of which may still implicitly expect compliance with EPUB v2). The CSS definitely needs enhancing (especially for code snippets). The Ebook opens in a Calibre reader, which is available on all operating systems."
                                ]
                                createElement "p" [] [text "Suggestions are welcome and should be addressed by opening an issue on the Raku/doc-website repository"]
                                createElement "p" [] [text "Exit this popup by pressing <Escape>, or clicking on X or on the background."]
                            ]
                        ]
                        createElement "button" ["class" @= "modal-close is-large"; "aria-label" @= "close"] []
                    ]
                ]
            ]
            
            // Main content
            createElement "div" ["class" @= "tile is-ancestor section"] [
                // Edit button
                createElement "div" ["class" @= "page-edit"] [
                    createElement "a" [
                        "class" @= "button page-edit-button"
                        "href" @= "https://github.com/Raku/doc-website/edit/main/Website/structure-sources/404.rakudoc"
                        "title" @= "Edit this page.\nCommit: 0ead45c 2026-04-04"
                    ] [
                        createElement "span" ["class" @= "icon is-right"] [
                            createElement "i" ["class" @= "fas fa-pen-alt is-medium"] []
                        ]
                    ]
                ]
                
                // Left column
                createElement "div" ["id" @= "left-column"; "class" @= "tile is-parent is-2 is-hidden"] [
                    createElement "div" ["id" @= "left-col-inner"] [
                        createElement "input" [
                            "type" @= "checkbox"
                            "id" @= "No-TOC"
                            "checked" @= "checked"
                            "style" @= "visibility: collapse;"
                        ] []
                        createElement "div" ["class" @= "content"] [text "No Table of Contents or Index available"]
                    ]
                ]
                
                // Main column
                createElement "div" ["id" @= "main-column"; "class" @= "tile is-parent"; "style" @= "overflow-x: hidden;"] [
                    createElement "div" ["id" @= "main-col-inner"] [
                        // Page header
                        createElement "section" ["class" @= "raku page-header"] [
                            createElement "div" ["class" @= "container px-4"] [
                                createElement "div" ["class" @= "raku page-title has-text-centered"] [text "404"]
                                createElement "div" ["class" @= "raku page-subtitle has-text-centered"] []
                            ]
                        ]
                        
                        // Page content
                        createElement "section" ["class" @= "raku page-content"] [
                            createElement "div" ["class" @= "container px-4"] [
                                createElement "div" ["class" @= "columns one-col"] [
                                    createElement "img" ["src" @= "/assets/images/Camelia-404.png"; "class" @= "camelia"] []
                                    createElement "h2" ["id" @= "404:_Page_Not_Found"; "class" @= "raku-h2"] [
                                        createElement "a" ["href" @= "#404"; "title" @= "go to top of document"] [
                                            text "404: Page Not Found"
                                            createElement "a" ["class" @= "raku-anchor"; "title" @= "direct link"; "href" @= "#404:_Page_Not_Found"] [text "§"]
                                        ]
                                    ]
                                    createElement "p" [] [text "We're sorry, but the content you tried to reach wasn't found."]
                                    createElement "p" [] [
                                        text "While we do review server logs to catch these issues, we recently deployed a new version of the site, so please feel free to "
                                        createElement "a" ["href" @= "https://github.com/Raku/doc-website/issues/"] [text "report any issues"]
                                        text "."
                                    ]
                                    createElement "p" [] [text "Thanks!"]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
            
            // Footer
            createElement "footer" ["class" @= "footer main-footer"] [
                createElement "div" ["class" @= "container px-4"] [
                    createElement "nav" ["class" @= "level"] [
                        createElement "div" ["class" @= "level-left"] [
                            createElement "div" ["class" @= "level-item"] [
                                createElement "a" ["href" @= "/about"] [text "About"]
                            ]
                            createElement "div" ["class" @= "level-item"] [
                                createElement "a" ["id" @= "toggle-theme"] [text "Toggle theme"]
                            ]
                            createElement "div" ["class" @= "level-item"; "title" @= "0ead45c 2026-04-04"] [
                                createElement "a" [] [text "Commit"]
                            ]
                        ]
                        createElement "div" ["class" @= "level-right"] [
                            createElement "div" ["class" @= "level-item"] [
                                createElement "a" ["href" @= "/license"] [text "License"]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    
    createElement "html" [
        "lang" @= "en"
        "class" @= "fontawesome-i2svg-active fontawesome-i2svg-complete"
        "style" @= "scroll-padding-top:60px"
    ] [headSection; bodySection]

let renderHtmlElement (element: HtmlElement): string =
    let attrString = 
        element.Attributes 
        |> Map.toList
        |> List.map (fun (key, value) -> sprintf "%s=\"%s\"" key value)
        |> String.concat " "
        |> fun s -> if s = "" then "" else " " + s
    
    let contentString = 
        element.Content
        |> List.map (function
            | Element e -> renderHtmlElement e
            | Text t -> t
            | Raw r -> r)
        |> String.concat ""
    
    if contentString = "" then
        sprintf "<%s%s/>" element.Tag attrString
    else
        sprintf "<%s%s>%s</%s>" element.Tag attrString contentString element.Tag

let renderDocument (docType: string) (html: HtmlElement): string =
    docType + "\n" + (renderHtmlElement html)

let generate404Page outputFile =
    let htmlContent = renderDocument "<!DOCTYPE html>" htmlDocument
    File.WriteAllText(outputFile, htmlContent)
    printfn "404 page generated successfully at %s" outputFile

// Main entry point
[<EntryPoint>]
let main args =
    let outputFile = 
        if args.Length > 0 then args.[0] 
        else "404.html"
    
    generate404Page outputFile
    0
