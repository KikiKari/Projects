#!/usr/bin/env node
// scrape_to_markdown.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/web-markdown-scraper/scripts/scrape_to_markdown.py
// auch in: OpenClaw@gateway2:skills/web-markdown-scraper/scripts/scrape_to_markdown.py
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');
const { URL } = require('url');
const { program } = require('commander');
const axios = require('axios');
const cheerio = require('cheerio');
const TurndownService = require('turndown');

function toStr(value) {
    if (value === null || value === undefined) {
        return "";
    }
    if (Buffer.isBuffer(value)) {
        return value.toString('utf-8');
    }
    return String(value);
}

function slugify(text, maxLen = 80) {
    let result = text.replace(/[^\w\s-]/g, '').trim().toLowerCase();
    result = result.replace(/[-\s]+/g, '-');
    result = result.substring(0, maxLen).replace(/-+$/, '');
    return result || "page";
}

function extractHtml(obj) {
    if (obj === null || obj === undefined) {
        return "";
    }
    
    const attrs = ["html", "rawHtml", "content", "markup", "body", "innerHtml"];
    for (const attr of attrs) {
        let value = obj[attr];
        if (typeof value === 'function') {
            try {
                value = value.call(obj);
            } catch (e) {
                value = null;
            }
        }
        const text = toStr(value);
        if (text && text.includes("<") && text.includes(">")) {
            return text;
        }
    }
    
    const text = toStr(obj);
    return (text.includes("<") && text.includes(">")) ? text : "";
}

function extractTitle(html) {
    const match = html.match(/<title[^>]*>(.*?)<\/title>/is);
    if (!match) {
        return "";
    }
    let title = match[1].replace(/<[^>]+>/g, " ");
    title = title.replace(/\s+/g, " ").trim();
    return title;
}

async function fetchPage(url, options = {}) {
    const { timeout = 30000 } = options;
    
    try {
        const response = await axios.get(url, {
            timeout: timeout,
            headers: {
                'User-Agent': 'Mozilla/5.0 (compatible; Scraper/1.0)'
            }
        });
        
        return {
            data: response.data,
            status: response.status,
            statusText: response.statusText,
            headers: response.headers
        };
    } catch (error) {
        throw new Error(`Failed to fetch ${url}: ${error.message}`);
    }
}

function pickMainHtml(pageData, preferredSelector = null) {
    const $ = cheerio.load(pageData);
    const selectors = [];
    
    if (preferredSelector) {
        selectors.push(preferredSelector);
    }
    
    selectors.push(
        "article",
        "main",
        "[role='main']",
        ".post-content",
        ".entry-content",
        ".article-content",
        "body"
    );
    
    for (const selector of selectors) {
        try {
            const element = $(selector).first();
            if (element.length > 0) {
                const html = element.html();
                if (html && html.length >= 120) {
                    return [html, selector];
                }
            }
        } catch (e) {
            // Continue to next selector
        }
    }
    
    return [pageData, null];
}

function htmlToMarkdown(html, preserveLinks = false, bodyWidth = 0) {
    const turndownService = new TurndownService({
        headingStyle: 'atx',
        hr: '---',
        bulletListMarker: '-',
        codeBlockStyle: 'fenced',
        emDelimiter: '*',
        strongDelimiter: '**',
        linkStyle: preserveLinks ? 'inlined' : 'referenced',
        linkReferenceStyle: 'full'
    });
    
    // Remove images
    turndownService.remove('img');
    
    // Handle tables
    turndownService.addRule('table', {
        filter: 'table',
        replacement: function(content) {
            return content;
        }
    });
    
    let markdown = turndownService.turndown(html);
    markdown = markdown.replace(/\n{3,}/g, '\n\n').trim();
    return markdown;
}

function loadUrls(urlArgs = [], urlFile = "") {
    let urls = [...urlArgs];
    
    if (urlFile) {
        const content = fs.readFileSync(urlFile, 'utf-8');
        const lines = content.split('\n');
        for (const line of lines) {
            const trimmed = line.trim();
            if (trimmed && !trimmed.startsWith('#')) {
                urls.push(trimmed);
            }
        }
    }
    
    // Deduplicate URLs
    const seen = new Set();
    const clean = [];
    for (const u of urls) {
        if (!seen.has(u)) {
            clean.push(u);
            seen.add(u);
        }
    }
    
    return clean;
}

function validateUrl(url) {
    try {
        const parsed = new URL(url);
        return ['http:', 'https:'].includes(parsed.protocol) && Boolean(parsed.hostname);
    } catch (e) {
        return false;
    }
}

async function main() {
    program
        .option('--url <urls...>', 'URLs to scrape')
        .option('--url-file <file>', 'File containing URLs to scrape')
        .option('--selector <selector>', 'Preferred CSS selector for content')
        .option('--js', 'Use JavaScript rendering (not supported in this version)')
        .option('--wait-selector <selector>', 'Wait for selector (not supported in this version)')
        .option('--preserve-links', 'Preserve links in markdown output')
        .option('--body-width <width>', 'Body width for markdown output', parseInt)
        .option('--timeout <timeout>', 'Request timeout in seconds', parseInt, 30)
        .option('--output-dir <dir>', 'Output directory', 'outputs')
        .option('--automatch-domain <domain>', 'Automatch domain (not supported in this version)');
    
    program.parse();
    const options = program.opts();
    
    const urls = loadUrls(options.url, options.urlFile);
    if (urls.length === 0) {
        console.log(JSON.stringify({ok: false, error: "No URLs provided"}));
        process.exit(1);
    }
    
    for (const u of urls) {
        if (!validateUrl(u)) {
            console.log(JSON.stringify({ok: false, error: `Invalid URL: ${u}`}));
            process.exit(1);
        }
    }
    
    const outputDir = path.resolve(options.outputDir);
    fs.mkdirSync(outputDir, { recursive: true });
    
    const results = [];
    
    for (const url of urls) {
        const item = {
            url: url,
            ok: false,
            title: "",
            status: null,
            selector_used: null,
            backend: null,
            markdown: "",
            preview: "",
            output_markdown_file: null,
            error: null,
        };
        
        try {
            const page = await fetchPage(url, { timeout: options.timeout * 1000 });
            const [html, selectorUsed] = pickMainHtml(page.data, options.selector || null);
            
            if (!html) {
                throw new Error("No HTML content extracted from page");
            }
            
            const title = extractTitle(html) || new URL(url).hostname;
            const markdown = htmlToMarkdown(
                html,
                options.preserveLinks,
                options.bodyWidth
            );
            
            const filename = slugify(`${new URL(url).hostname}-${title}`) + ".md";
            const mdPath = path.join(outputDir, filename);
            fs.writeFileSync(mdPath, markdown, 'utf-8');
            
            item.ok = true;
            item.title = title;
            item.status = page.status;
            item.selector_used = selectorUsed;
            item.backend = "axios";
            item.markdown = markdown;
            item.preview = markdown.substring(0, 1200);
            item.output_markdown_file = mdPath;
        } catch (e) {
            item.error = e.message;
        }
        
        results.push(item);
    }
    
    const ok = results.some(x => x.ok);
    const indexPath = path.join(outputDir, "index.json");
    const payload = {
        ok: ok,
        count: results.length,
        success_count: results.filter(x => x.ok).length,
        failure_count: results.filter(x => !x.ok).length,
        output_index_file: indexPath,
        results: results
    };
    
    fs.writeFileSync(indexPath, JSON.stringify(payload, null, 2), 'utf-8');
    console.log(JSON.stringify(payload));
}

if (require.main === module) {
    main().catch(err => {
        console.error(err);
        process.exit(1);
    });
}
