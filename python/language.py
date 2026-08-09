#!/usr/bin/env python3
# language.html — portiert nach python
# Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/raku/language.html
# auch in: OpenClaw@gateway2:skills/scripting-utils/references/raku/language.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import sys
from bs4 import BeautifulSoup

def generate_html():
    # Create the HTML structure
    soup = BeautifulSoup('<!DOCTYPE html>', 'html.parser')
    
    # Create html element with attributes
    html = soup.new_tag('html', lang='en')
    html['class'] = 'fontawesome-i2svg-active fontawesome-i2svg-complete'
    html['style'] = 'scroll-padding-top:60px'
    soup.append(html)
    
    # Create head
    head = soup.new_tag('head')
    html.append(head)
    
    # Add title
    title = soup.new_tag('title')
    title.string = '404 | Raku Documentation'
    head.append(title)
    
    # Add meta charset
    meta_charset = soup.new_tag('meta', charset='UTF-8')
    head.append(meta_charset)
    
    # Add favicon link
    link_favicon = soup.new_tag('link', href='/assets/images/Camelia.ico', rel='icon', type='image/x-icon')
    head.append(link_favicon)
    
    # Add all stylesheet links
    stylesheets = [
        '/assets/css/Website.css',
        '/assets/css/css/filtered-toc-dark.css',
        '/assets/css/css/filtered-toc-light.css',
        '/assets/css/css/rainbow-dark.css',
        '/assets/css/css/rainbow-light.css',
        '/assets/css/tm-styling.css',
        '/assets/css/tm-light.css',
        '/assets/css/tm-dark.css',
        '/assets/css/all.min.css',
        '/assets/css/listf-styling-light.css',
        '/assets/css/listf-styling-dark.css',
        '/assets/css/typegraph-styling.css',
        '/assets/css/typegraph-dark.css',
        '/assets/css/typegraph-light.css',
        '/assets/css/css/page-styling-main.css',
        '/assets/css/css/page-styling-dark.css',
        '/assets/css/css/page-styling-light.css',
        '/assets/css/css/chyronToggle-dark.css',
        '/assets/css/css/chyronToggle-light.css',
        '/assets/css/css/centreToggle-dark.css',
        '/assets/css/css/centreToggle-light.css',
        '/assets/css/css/options-search-light.css',
        '/assets/css/css/options-search-dark.css',
        'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-light.min.css',
        'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css',
        'https://cdn.jsdelivr.net/npm/@tarekraafat/autocomplete.js@10.2.7/dist/css/autoComplete.min.css'
    ]
    
    for stylesheet in stylesheets:
        link = soup.new_tag('link', rel='stylesheet', href=stylesheet)
        if 'dark' in stylesheet:
            link['title'] = 'dark'
        elif 'light' in stylesheet:
            link['title'] = 'light'
        head.append(link)
    
    # Add script tags
    scripts = [
        'https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js',
        '/assets/scripts/all.min.js',
        '/assets/scripts/tableManager.js',
        '/assets/scripts/filter-script.js',
        'https://cdn.jsdelivr.net/npm/fuzzysort@2.0.4/fuzzysort.min.js',
        'https://cdn.jsdelivr.net/npm/@tarekraafat/autocomplete.js@10.2.7/dist/autoComplete.min.js',
        '/assets/scripts/filtered-toc.js',
        'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js',
        'https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/languages/haskell.min.js',
        '/assets/scripts/options-search.js',
        '/assets/scripts/page-styling.js',
        '/assets/scripts/rainbow.js'
    ]
    
    for script_src in scripts:
        script = soup.new_tag('script', src=script_src)
        head.append(script)
    
    # Create body
    body = soup.new_tag('body')
    body['class'] = 'has-navbar-fixed-top'
    html.append(body)
    
    # Add top div
    top_div = soup.new_tag('div', id='404', **{'class': 'top-of-page'})
    body.append(top_div)
    
    # Create navbar
    nav = soup.new_tag('nav', **{'class': 'navbar is-fixed-top is-flex-touch'}, role='navigation', **{'aria-label': 'main navigation'})
    body.append(nav)
    
    # Add navbar item with toggle
    navbar_item = soup.new_tag('div', **{'class': 'navbar-item'}, style='margin-left: auto;')
    nav.append(navbar_item)
    
    left_bar_toggle = soup.new_tag('div', **{'class': 'left-bar-toggle'}, title='Toggle Table of Contents & Index')
    navbar_item.append(left_bar_toggle)
    
    chyron_toggle = soup.new_tag('label', **{'class': 'chyronToggle left'})
    left_bar_toggle.append(chyron_toggle)
    
    input_toggle = soup.new_tag('input', id='navbar-left-toggle', type='checkbox')
    chyron_toggle.append(input_toggle)
    
    span_text = soup.new_tag('span', **{'class': 'text'})
    span_text.string = 'Contents'
    chyron_toggle.append(span_text)
    
    # Add container
    container = soup.new_tag('div', **{'class': 'container is-justify-content-space-around'})
    nav.append(container)
    
    # Add navbar brand
    navbar_brand = soup.new_tag('div', **{'class': 'navbar-brand'})
    container.append(navbar_brand)
    
    navbar_logo = soup.new_tag('div', **{'class': 'navbar-logo'})
    navbar_brand.append(navbar_logo)
    
    navbar_item_link = soup.new_tag('a', **{'class': 'navbar-item'}, href='/')
    navbar_logo.append(navbar_item_link)
    
    img = soup.new_tag('img', src='/assets/images/camelia-recoloured.png', alt='Raku', width='52.83', height='38')
    navbar_item_link.append(img)
    
    span_tm = soup.new_tag('span', **{'class': 'navbar-logo-tm'})
    span_tm.string = 'tm'
    navbar_logo.append(span_tm)
    
    navbar_burger = soup.new_tag('a', role='button', **{'class': 'navbar-burger burger'}, **{'aria-label': 'menu'}, **{'aria-expanded': 'false'}, **{'data-target': 'navMenu'})
    navbar_brand.append(navbar_burger)
    
    span1 = soup.new_tag('span', **{'aria-hidden': 'true'})
    navbar_burger.append(span1)
    
    span2 = soup.new_tag('span', **{'aria-hidden': 'true'})
    navbar_burger.append(span2)
    
    span3 = soup.new_tag('span', **{'aria-hidden': 'true'})
    navbar_burger.append(span3)
    
    # Add navbar menu
    navbar_menu = soup.new_tag('div', id='navMenu', **{'class': 'navbar-menu'})
    container.append(navbar_menu)
    
    # Add navbar start
    navbar_start = soup.new_tag('div', **{'class': 'navbar-start'})
    navbar_menu.append(navbar_start)
    
    # Add navbar items
    nav_items = [
        ('/introduction', 'Getting started, Tutorials, Migration guides', 'Introduction'),
        ('/reference', 'Fundamentals, General reference', 'Reference'),
        ('/miscellaneous', 'Programs, Experimental', 'Miscellaneous'),
        ('/types', 'The core types (classes) available', 'Types'),
        ('/routines', 'Searchable table of routines', 'Routines'),
        ('https://raku.org', 'Home page for community', 'Raku<sup>®</sup>'),
        ('https://web.libera.chat/#raku', 'IRC live chat', 'Chat')
    ]
    
    for href, title, text in nav_items:
        a = soup.new_tag('a', **{'class': 'navbar-item'}, href=href, title=title)
        a.string = text
        navbar_start.append(a)
    
    # Add dropdown
    dropdown_div = soup.new_tag('div', **{'class': 'navbar-item has-dropdown is-hoverable'})
    navbar_start.append(dropdown_div)
    
    dropdown_link = soup.new_tag('a', **{'class': 'navbar-link'})
    dropdown_link.string = 'More'
    dropdown_div.append(dropdown_link)
    
    dropdown_content = soup.new_tag('div', **{'class': 'navbar-dropdown is-right is-rounded'})
    dropdown_div.append(dropdown_content)
    
    hr1 = soup.new_tag('hr', **{'class': 'navbar-divider'})
    dropdown_content.append(hr1)
    
    dropdown_item1 = soup.new_tag('a', **{'class': 'navbar-item js-modal-trigger'}, **{'data-target': 'download-ebook'})
    dropdown_item1.string = 'Download E-Book (epub)'
    dropdown_content.append(dropdown_item1)
    
    hr2 = soup.new_tag('hr', **{'class': 'navbar-divider'})
    dropdown_content.append(hr2)
    
    dropdown_item2 = soup.new_tag('a', **{'class': 'navbar-item'}, href='/about')
    dropdown_item2.string = 'About'
    dropdown_content.append(dropdown_item2)
    
    hr3 = soup.new_tag('hr', **{'class': 'navbar-divider'})
    dropdown_content.append(hr3)
    
    dropdown_item3 = soup.new_tag('a', **{'class': 'navbar-item has-text-red'}, href='https://github.com/raku/doc-website/issues')
    dropdown_item3.string = 'Report an issue with this site'
    dropdown_content.append(dropdown_item3)
    
    hr4 = soup.new_tag('hr', **{'class': 'navbar-divider'})
    dropdown_content.append(hr4)
    
    dropdown_item4 = soup.new_tag('a', **{'class': 'navbar-item'}, href='https://github.com/raku/doc/issues')
    dropdown_item4.string = 'Report an issue with the documentation content'
    dropdown_content.append(dropdown_item4)
    
    # Add navbar end with search
    navbar_end = soup.new_tag('div', **{'class': 'navbar-end navbar-search-wrapper'})
    navbar_menu.append(navbar_end)
    
    navbar_item_search = soup.new_tag('div', **{'class': 'navbar-item'})
    navbar_end.append(navbar_item_search)
    
    field_div = soup.new_tag('div', **{'class': 'field has-addons'})
    navbar_item_search.append(field_div)
    
    autocomplete_div = soup.new_tag('div', **{'class': 'autoComplete_options'})
    field_div.append(autocomplete_div)
    
    input_search = soup.new_tag('input', **{'class': 'control input'}, id='autoComplete', type='search', dir='ltr', spellcheck='false', autocorrect='off', autocomplete='off', autocapitalize='off', placeholder='🔍 Type f to search for ...')
    autocomplete_div.append(input_search)
    
    control_div = soup.new_tag('div', **{'class': 'control'}, title='Search options')
    field_div.append(control_div)
    
    button_link = soup.new_tag('a', **{'class': 'button is-primary js-modal-trigger'}, **{'data-target': 'options-search-info'})
    control_div.append(button_link)
    
    span_icon = soup.new_tag('span', **{'class': 'icon'})
    button_link.append(span_icon)
    
    i_icon = soup.new_tag('i', **{'class': 'fas fa-cogs'})
    span_icon.append(i_icon)
    
    # Add options search info modal
    modal_div = soup.new_tag('div', id='options-search-info', **{'class': 'modal'})
    navbar_menu.append(modal_div)
    
    modal_bg = soup.new_tag('div', **{'class': 'modal-background'})
    modal_div.append(modal_bg)
    
    modal_content = soup.new_tag('div', **{'class': 'modal-content'})
    modal_div.append(modal_content)
    
    box_div = soup.new_tag('div', **{'class': 'box'})
    modal_content.append(box_div)
    
    p1 = soup.new_tag('p')
    p1.string = 'The last search was: '
    box_div.append(p1)
    
    span_selected = soup.new_tag('span', id='selected-candidate', **{'class': 'ss-selected'})
    p1.append(span_selected)
    
    control_grouped = soup.new_tag('div', **{'class': 'control is-grouped is-grouped-centered options-search-controls'})
    box_div.append(control_grouped)
    
    # Add toggle labels
    toggle_labels = [
        ('options-search-extra', 'Include extra information (Alt-E)', 'Extra info', 'yes', 'no', '10.5', 'The search response can be shortened by excluding the extra information line (Alt-E)'),
        ('options-search-loose', 'Search engine type Strict/Loose (Alt-L)', 'Search type', 'loose', 'strict', '10.5', ' The search engine can perform a strict search (only the characters in the search box) or a loose search (Alt-L)'),
        ('options-search-headings', 'Search through headings (Alt-H)', 'Headings', 'yes', 'no', '10.5', 'Search through headings in all web-pages (Alt-H)'),
        ('options-search-indexed', 'Search indexed items (Alt-I)', 'Indexed', 'yes', 'no', '10.5', 'Search through all indexed items (Alt-I)'),
        ('options-search-composite', 'Search composite pages (Alt-C)', 'Composite', 'yes', 'no', '10.5', 'Search in the names of composite pages, which combine similar information from the main web pages (Alt-C)'),
        ('options-search-primary', 'Search primary sources (Alt-P)', 'Primary', 'yes', 'no', '10.5', 'Search through the names of the main web pages (Alt-P)'),
        ('options-search-newtab', 'Open in new tab (Alt-Q)', 'New tab', 'yes', 'no', '10.5', 'Once a search candidate has been chosen, it can be opened in a new tab or in the current tab (Alt-Q)')
    ]
    
    for toggle_id, title, text, on_text, off_text, width, description in toggle_labels:
        label = soup.new_tag('label', **{'class': 'centreToggle'}, title=title, style=f'--switch-width: {width}')
        control_grouped.append(label)
        
        input_checkbox = soup.new_tag('input', id=toggle_id, type='checkbox')
        label.append(input_checkbox)
        
        span_text = soup.new_tag('span', **{'class': 'text'})
        span_text.string = text
        label.append(span_text)
        
        span_on = soup.new_tag('span', **{'class': 'on'})
        span_on.string = on_text
        label.append(span_on)
        
        span_off = soup.new_tag('span', **{'class': 'off'})
        span_off.string = off_text
        label.append(span_off)
        
        p_desc = soup.new_tag('p')
        p_desc.string = description
        control_grouped.append(p_desc)
    
    p_final = soup.new_tag('p')
    p_final.string = 'If all else fails, an item is added to use the Google search engine on the whole site'
    control_grouped.append(p_final)
    
    button_reset = soup.new_tag('button', **{'class': 'button is-warning'}, id='options-search-reset-defaults')
    button_reset.string = 'Clear options, reset to defaults'
    control_grouped.append(button_reset)
    
    p_exit = soup.new_tag('p')
    p_exit.string = 'Exit this page by pressing <Escape>, or clicking on X or on the background.'
    control_grouped.append(p_exit)
    
    modal_close = soup.new_tag('button', **{'class': 'modal-close is-large'}, **{'aria-label': 'close'})
    modal_div.append(modal_close)
    
    # Add download ebook modal
    ebook_modal = soup.new_tag('div', id='download-ebook', **{'class': 'modal'})
    navbar_menu.append(ebook_modal)
    
    ebook_modal_bg = soup.new_tag('div', **{'class': 'modal-background'})
    ebook_modal.append(ebook_modal_bg)
    
    ebook_modal_content = soup.new_tag('div', **{'class': 'modal-content'})
    ebook_modal.append(ebook_modal_content)
    
    ebook_box = soup.new_tag('div', **{'class': 'box'})
    ebook_modal_content.append(ebook_box)
    
    p_ebook1 = soup.new_tag('p')
    ebook_box.append(p_ebook1)
    
    a_ebook = soup.new_tag('a', href='/RakuDocumentation.epub', download='')
    a_ebook.string = 'RakuDocumentation.epub'
    p_ebook1.append(a_ebook)
    
    p_ebook1.string += ' is a work in progress e-book. It targets the '
    
    a_epub = soup.new_tag('a', href='https://www.w3.org/publishing/epub3/')
    a_epub.string = 'EPUB v3 specification'
    p_ebook1.append(a_epub)
    
    p_ebook1.string += '. It needs testing on a variety of ereaders (some of which may still implicitly expect compliance with EPUB v2). The CSS definitely needs enhancing (especially for code snippets). The Ebook opens in a Calibre reader, which is available on all operating systems.'
    
    p_ebook2 = soup.new_tag('p')
    p_ebook2.string = 'Suggestions are welcome and should be addressed by opening an issue on the Raku/doc-website repository'
    ebook_box.append(p_ebook2)
    
    p_ebook3 = soup.new_tag('p')
    p_ebook3.string = 'Exit this popup by pressing <Escape>, or clicking on X or on the background.'
    ebook_box.append(p_ebook3)
    
    ebook_modal_close = soup.new_tag('button', **{'class': 'modal-close is-large'}, **{'aria-label': 'close'})
    ebook_modal.append(ebook_modal_close)
    
    # Add main content area
    tile_ancestor = soup.new_tag('div', **{'class': 'tile is-ancestor section'})
    body.append(tile_ancestor)
    
    # Add page edit
    page_edit = soup.new_tag('div', **{'class': 'page-edit'})
    tile_ancestor.append(page_edit)
    
    edit_button = soup.new_tag('a', **{'class': 'button page-edit-button'}, href='https://github.com/Raku/doc-website/edit/main/Website/structure-sources/404.rakudoc', title='Edit this page.\nCommit: 0ead45c 2026-04-04')
    page_edit.append(edit_button)
    
    span_icon_right = soup.new_tag('span', **{'class': 'icon is-right'})
    edit_button.append(span_icon_right)
    
    i_pen = soup.new_tag('i', **{'class': 'fas fa-pen-alt is-medium'})
    span_icon_right.append(i_pen)
    
    # Add left column
    left_column = soup.new_tag('div', id='left-column', **{'class': 'tile is-parent is-2 is-hidden'})
    tile_ancestor.append(left_column)
    
    left_col_inner = soup.new_tag('div', id='left-col-inner')
    left_column.append(left_col_inner)
    
    input_toc = soup.new_tag('input', type='checkbox', id='No-TOC', checked='checked', style='visibility: collapse;')
    left_col_inner.append(input_toc)
    
    content_div = soup.new_tag('div', **{'class': 'content'})
    content_div.string = 'No Table of Contents or Index available'
    left_col_inner.append(content_div)
    
    # Add main column
    main_column = soup.new_tag('div', id='main-column', **{'class': 'tile is-parent'}, style='overflow-x: hidden;')
    tile_ancestor.append(main_column)
    
    main_col_inner = soup.new_tag('div', id='main-col-inner')
    main_column.append(main_col_inner)
    
    # Add page header section
    page_header = soup.new_tag('section', **{'class': 'raku page-header'})
    main_col_inner.append(page_header)
    
    container_header = soup.new_tag('div', **{'class': 'container px-4'})
    page_header.append(container_header)
    
    page_title = soup.new_tag('div', **{'class': 'raku page-title has-text-centered'})
    page_title.string = '404'
    container_header.append(page_title)
    
    page_subtitle = soup.new_tag('div', **{'class': 'raku page-subtitle has-text-centered'})
    container_header.append(page_subtitle)
    
    # Add page content section
    page_content = soup.new_tag('section', **{'class': 'raku page-content'})
    main_col_inner.append(page_content)
    
    container_content = soup.new_tag('div', **{'class': 'container px-4'})
    page_content.append(container_content)
    
    columns_div = soup.new_tag('div', **{'class': 'columns one-col'})
    container_content.append(columns_div)
    
    img_404 = soup.new_tag('img', src='/assets/images/Camelia-404.png', **{'class': 'camelia'})
    columns_div.append(img_404)
    
    h2 = soup.new_tag('h2', id='404:_Page_Not_Found', **{'class': 'raku-h2'})
    columns_div.append(h2)
    
    a_header = soup.new_tag('a', href='#404', title='go to top of document')
    a_header.string = '404: Page Not Found'
    h2.append(a_header)
    
    a_anchor = soup.new_tag('a', **{'class': 'raku-anchor'}, title='direct link', href='#404:_Page_Not_Found')
    a_anchor.string = '§'
    a_header.append(a_anchor)
    
    p1_content = soup.new_tag('p')
    p1_content.string = "We're sorry, but the content you tried to reach wasn't found."
    columns_div.append(p1_content)
    
    p2_content = soup.new_tag('p')
    p2_content.string = 'While we do review server logs to catch these issues, we recently deployed a new version of the site, so please feel free to '
    
    a_report = soup.new_tag('a', href='https://github.com/Raku/doc-website/issues/')
    a_report.string = 'report any issues'
    p2_content.append(a_report)
    
    p2_content.string += '.'
    columns_div.append(p2_content)
    
    p3_content = soup.new_tag('p')
    p3_content.string = 'Thanks!'
    columns_div.append(p3_content)
    
    # Add footer
    footer = soup.new_tag('footer', **{'class': 'footer main-footer'})
    body.append(footer)
    
    container_footer = soup.new_tag('div', **{'class': 'container px-4'})
    footer.append(container_footer)
    
    nav_footer = soup.new_tag('nav', **{'class': 'level'})
    container_footer.append(nav_footer)
    
    level_left = soup.new_tag('div', **{'class': 'level-left'})
    nav_footer.append(level_left)
    
    level_item1 = soup.new_tag('div', **{'class': 'level-item'})
    level_left.append(level_item1)
    
    a_about = soup.new_tag('a', href='/about')
    a_about.string = 'About'
    level_item1.append(a_about)
    
    level_item2 = soup.new_tag('div', **{'class': 'level-item'})
    level_left.append(level_item2)
    
    a_toggle = soup.new_tag('a', id='toggle-theme')
    a_toggle.string = 'Toggle theme'
    level_item2.append(a_toggle)
    
    level_item3 = soup.new_tag('div', **{'class': 'level-item'}, title='0ead45c 2026-04-04')
    level_left.append(level_item3)
    
    a_commit = soup.new_tag('a')
    a_commit.string = 'Commit'
    level_item3.append(a_commit)
    
    level_right = soup.new_tag('div', **{'class': 'level-right'})
    nav_footer.append(level_right)
    
    level_item4 = soup.new_tag('div', **{'class': 'level-item'})
    level_right.append(level_item4)
    
    a_license = soup.new_tag('a', href='/license')
    a_license.string = 'License'
    level_item4.append(a_license)
    
    return str(soup)

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 script.py <output_file>")
        sys.exit(1)
    
    output_file = sys.argv[1]
    
    html_content = generate_html()
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    print(f"HTML file generated: {output_file}")

if __name__ == '__main__':
    main()
