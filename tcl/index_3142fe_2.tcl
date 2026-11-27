#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "f642bfd4914380d6f83499747e30bf03f164a9fea25c536c294d7827c0e700eb", "source_sha256": "3142feb6091cfe3d5bd13c9c754dfa402677f7a64e71a4cca7c3cba8af0bb43d", "target_language": "tcl"}
# index.html — portiert nach tcl
# Quelle: html, Projects@Weather-Check:Weather-Check/index.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 script to generate index.html
# This script creates an HTML file with the complete structure including
# all meta tags, scripts, and embedded JavaScript from the original HTML document.

proc generate_html {filename} {
    set fp [open $filename w]
    
    # Write DOCTYPE
    puts $fp {<!DOCTYPE html>}
    
    # Write html tag with language attribute
    puts $fp {<html lang="de">}
    
    # Write head section
    puts $fp {  <head>}
    puts $fp {    <meta charset="UTF-8" />}
    puts $fp {    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />}
    puts $fp {    <meta name="theme-color" content="#0d1b2a" />}
    puts $fp {    <meta name="description" content="Lokaler Regen-Check f&uuml;r die n&auml;chsten 30, 60 und 120 Minuten" />}
    puts $fp {    <meta name="apple-mobile-web-app-capable" content="yes" />}
    puts $fp {    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />}
    puts $fp {    <meta name="apple-mobile-web-app-title" content="Weather" />}
    puts $fp {    <link rel="manifest" href="./manifest.json" />}
    puts $fp {    <link rel="apple-touch-icon" href="./icon-512.png" />}
    puts $fp {    <title>Weather &ndash; Regen-Check</title>}
    puts $fp {    <script type="module" crossorigin src="./assets/index-DGdzG44S.js"></script>}
    puts $fp {    <link rel="stylesheet" crossorigin href="./assets/index-erFv57XC.css">}
    puts $fp {  </head>}
    
    # Write body section
    puts $fp {  <body>}
    puts $fp {    <div id="root"></div>}
    
    # Write the embedded JavaScript
    puts $fp {  <script data-pplx-inline-edit>}
    puts $fp {(function () \{}
    puts $fp {  if (window === window.top) return;}
    puts $fp {}
    puts $fp {  const allowedParentOrigins = \["https://www.perplexity.ai","https://perplexity.ai","https://testing.perplexity.ai","https://staging.perplexity.ai","https://*.preview.i.perplexity.ai","http://localhost:3000","http://127.0.0.1:3000","http://localhost:5173","http://127.0.0.1:5173"\];}
    puts $fp {  const MAX_FONT_BYTES = 500 * 1024;}
    puts $fp {  const MAX_TOTAL_FONT_BYTES = 2 * 1024 * 1024;}
    puts $fp {  let scrollForwarding = false;}
    puts $fp {  let scrollRaf = 0;}
    puts $fp {  let trustedTopOrigin = null;}
    puts $fp {}
    puts $fp {  // Allow entries like "https://*.preview.i.perplexity.ai" &mdash; the wildcard}
    puts $fp {  // matches a single DNS label (no dots), so "https://*.foo" cannot stretch}
    puts $fp {  // across multiple labels.}
    puts $fp {  function matchesAllowedOrigin(origin) \{}
    puts $fp {    if (!origin) return false;}
    puts $fp {    for (const entry of allowedParentOrigins) \{}
    puts $fp {      if (!entry.includes("*")) \{}
    puts $fp {        if (entry === origin) return true;}
    puts $fp {        continue;}
    puts $fp {      \}}
    puts $fp {      const pattern = new RegExp(}
    puts $fp {        "^" +}
    puts $fp {          entry.replace(/\[\.+?^$\{\}\(\)|\[\]\\\\\]/g, "\\\\$\&").replace(/\*/g, "\[^.\]+") +}
    puts $fp {          "$",}
    puts $fp {      );}
    puts $fp {      if (pattern.test(origin)) return true;}
    puts $fp {    \}}
    puts $fp {    return false;}
    puts $fp {  \}}
    puts $fp {}
    puts $fp {  // Trust decision: when the sender is same-origin-visible (event.origin is a}
    puts $fp {  // real origin like https://www.perplexity.ai) we trust event.origin directly.}
    puts $fp {  // When event.origin is "null" (opaque broker srcdoc) we fall back to the}
    puts $fp {  // broker's stamped `parentOrigin` to identify the top window. The fallback}
    puts $fp {  // is claim-only &mdash; we rely on the browser's native `targetOrigin` enforcement}
    puts $fp {  // on the response path (see postToTrustedTop) to ensure replies can't be}
    puts $fp {  // delivered to anyone but the actual top window of that claimed origin.}
    puts $fp {  function getTrustedParentOrigin(event) \{}
    puts $fp {    const forwardedParentOrigin =}
    puts $fp {      typeof event.data.parentOrigin === "string" ? event.data.parentOrigin : null;}
    puts $fp {    const parentOrigin = event.origin === "null" ? forwardedParentOrigin : event.origin;}
    puts $fp {    return matchesAllowedOrigin(parentOrigin) ? parentOrigin : null;}
    puts $fp {  \}}
    puts $fp {}
    puts $fp {  // All responses go to window.top with targetOrigin = the allowlisted origin.}
    puts $fp {  // An attacker that iframes us inside their own null-origin broker can claim}
    puts $fp {  // any parentOrigin they like, but the browser will drop the reply whenever}
    puts $fp {  // the real top's origin doesn't match &mdash; so the screenshot never leaves.}
    puts $fp {  function postToTrustedTop(message) \{}
    puts $fp {    if (!trustedTopOrigin) return;}
    puts $fp {    try \{}
    puts $fp {      window.top.postMessage(message, trustedTopOrigin);}
    puts $fp {    \} catch (_error) \{\}}
    puts $fp {  \}}
    puts $fp {}
    puts $fp {  function inlineAll(original, clone) \{}
    puts $fp {    if (original.nodeType !== 1 || clone.nodeType !== 1) return;}
    puts $fp {}
    puts $fp {    try \{}
    puts $fp {      const computedStyle = getComputedStyle(original);}
    puts $fp {      // cssText on a computed style is the serialized declaration in modern}
    puts $fp {      // Chromium/Safari &mdash; a single read beats enumerating ~400 longhand}
    puts $fp {      // properties. Firefox returns "" here, so we fall back on empty.}
    puts $fp {      const serialized = computedStyle.cssText;}
    puts $fp {      if (serialized) \{}
    puts $fp {        clone.style.cssText = serialized;}
    puts $fp {      \} else \{}
    puts $fp {        const parts = new Array(computedStyle.length);}
    puts $fp {        for (let index = 0; index < computedStyle.length; index += 1) \{}
    puts $fp {          const property = computedStyle\[index\];}
    puts $fp {          parts\[index\] = `${property}:${computedStyle.getPropertyValue(property)};`;}
    puts $fp {        \}}
    puts $fp {        clone.style.cssText = parts.join("");}
    puts $fp {      \}}
    puts $fp {    \} catch (_error) \{\}}
    puts $fp {}
    puts $fp {    const originalChildren = original.children;}
    puts $fp {    const clonedChildren = clone.children;}
    puts $fp {    for (}
    puts $fp {      let index = 0;}
    puts $fp {      index < originalChildren.length && index < clonedChildren.length;}
    puts $fp {      index += 1}
    puts $fp {    ) \{}
    puts $fp {      inlineAll(originalChildren\[index\], clonedChildren\[index\]);}
    puts $fp {    \}}
    puts $fp {  \}}
    puts $fp {}
    puts $fp {  function extractFontUrl(srcValue) \{}
    puts $fp {    const matches = \[}
    puts $fp {      ...srcValue.matchAll(}
    puts $fp {        /url\\(\["'\]?(\[^"'\)\]+"'\)?\\)(?:\\s*format\\(\["'\]?(\[^"'\)\]+"'\)?\\))?/gi,}
    puts $fp {      ),}
    puts $fp {    \];}
    puts $fp {    if (matches.length === 0) return null;}
    puts $fp {    const woff2 = matches.find((m) => m\[2\] && m\[2\].toLowerCase().includes("woff2"));}
    puts $fp {    if (woff2) return woff2\[1\];}
    puts $fp {    const woff = matches.find((m) => m\[2\] && m\[2\].toLowerCase().includes("woff"));}
    puts $fp {    if (woff) return woff\[1\];}
    puts $fp {    return matches\[0\]\[1\];}
    puts $fp {  \}}
    puts $fp {}
    puts $fp {  // Cache resolved font URL -> data URI across captures. Fonts on a page}
    puts $fp {  // essentially never change, and a batch run emits multiple captures back to}
    puts $fp {  // back &mdash; without this we'd refetch + re-base64 every time.}
    puts $fp {  const fontDataUriCache = new Map();}
    puts $fp {  const SRC_DECLARATION_RE = /src\\s*:\\s*\[^;\}\]+/i;}
    puts $fp {}
    puts $fp {  async function fetchAsDataUri(url) \{}
    puts $fp {    if (fontDataUriCache.has(url)) return fontDataUriCache.get(url);}
    puts $fp {    let dataUri = null;}
    puts $fp {    try \{}
    puts $fp {      const response = await fetch(url, \{ mode: "cors", credentials: "omit" \});}
    puts $fp {      if (response.ok) \{}
    puts $fp {        const blob = await response.blob();}
    puts $fp {        if (blob.size <= MAX_FONT_BYTES) \{}
    puts $fp {          dataUri = await new Promise((resolve) => \{}
    puts $fp {            const reader = new FileReader();}
    puts $fp {            reader.onloadend = () =>}
    puts $fp {              resolve(typeof reader.result === "string" ? reader.result : null);}
    puts $fp {            reader.onerror = () => resolve(null);}
    puts $fp {            reader.readAsDataURL(blob);}
    puts $fp {          \});}
    puts $fp {        \}}
    puts $fp {      \}}
    puts $fp {    \} catch (_error) \{}
    puts $fp {      dataUri = null;}
    puts $fp {    \}}
    puts $fp {    fontDataUriCache.set(url, dataUri);}
    puts $fp {    return dataUri;}
    puts $fp {  \}}
    puts $fp {}
    puts $fp {  function collectFontFaceRuleTexts() \{}
    puts $fp {    const rules = \[];}
    puts $fp {    for (const sheet of document.styleSheets) \{}
    puts $fp {      let cssRules;}
    puts $fp {      try \{}
    puts $fp {        cssRules = sheet.cssRules;}
    puts $fp {      \} catch (_error) \{}
    puts $fp {        continue;}
    puts $fp {      \}}
    puts $fp {      if (!cssRules) continue;}
    puts $fp {      for (const rule of cssRules) \{}
    puts $fp {        const cssText = rule.cssText || "";}
    puts $fp {        if (cssText.startsWith("@font-face")) rules.push(cssText);}
    puts $fp {      \}}
    puts $fp {    \}}
    puts $fp {    return rules;}
    puts $fp {  \}}
    puts $fp {}
    puts $fp {  async function buildInlinedFontCss() \{}
    puts $fp {    const ruleTexts = collectFontFaceRuleTexts();}
    puts $fp {    if (ruleTexts.length === 0) return null;}
    puts $fp {}
    puts $fp {    const resolved = ruleTexts.map((cssText) => \{}
    puts $fp {      if (!SRC_DECLARATION_RE.test(cssText)) return null;}
    puts $fp {      const srcMatch = cssText.match(/src\\s*:\\s*(\[^;\}]+\)[;\}]/i);}
    puts $fp {      if (!srcMatch) return null;}
    puts $fp {      const url = extractFontUrl(srcMatch\[1\]);}
    puts $fp {      if (!url) return null;}
    puts $fp {      try \{}
    puts $fp {        return \{ cssText, url: new URL(url, document.baseURI).href \};}
    puts $fp {      \} catch (_error) \{}
    puts $fp {        return null;}
    puts $fp {      \}}
    puts $fp {    \});}
    puts $fp {}
    puts $fp {    const dataUris = await Promise.all(}
    puts $fp {      resolved.map((entry) => (entry ? fetchAsDataUri(entry.url) : Promise.resolve(null))),}
    puts $fp {    );}
    puts $fp {}
    puts $fp {    const inlined = \[];}
    puts $fp {    let totalBytes = 0;}
    puts $fp {    for (let index = 0; index < resolved.length; index += 1) \{}
    puts $fp {      const entry = resolved\[index\];}
    puts $fp {      const dataUri = dataUris\[index\];}
    puts $fp {      if (!entry || !dataUri) continue;}
    puts $fp {      const approxBytes = dataUri.length * 0.75;}
    puts $fp {      if (totalBytes + approxBytes > MAX_TOTAL_FONT_BYTES) break;}
    puts $fp {      totalBytes += approxBytes;}
    puts $fp {      inlined.push(entry.cssText.replace(SRC_DECLARATION_RE, `src: url("${dataUri}")`));}
    puts $fp {    \}}
    puts $fp {    return inlined.length > 0 ? inlined.join("\\n") : null;}
    puts $fp {  \}}
    puts $fp {}
    puts $fp {  function stripExternal(clone) \{}
    puts $fp {    const images = clone.querySelectorAll("img");}}
    puts $fp {    for (let index = 0; index < images.length; index += 1) \{}
    puts $fp {      const src = images\[index\].getAttribute("src");}
    puts $fp {      if (src && !src.startsWith("data:")) images\[index\].removeAttribute("src");}
    puts $fp {    \}}
    puts $fp {}
    puts $fp {    const elements = clone.querySelectorAll("*");}
    puts $fp {    for (let index = 0; index < elements.length; index += 1) \{}
    puts $fp {      const style = elements\[index\].style.cssText;}
    puts $fp {      if (style && style.includes("url(")) \{}
    puts $fp {        elements\[index\].style.cssText = style.replace(}
    puts $fp {          /url\\(\["'\]?(?!data:)\[^)"'\]*["'\]?\)/gi,}
    puts $fp {          "none",}
    puts $fp {        );}
    puts $fp {      \}}
    puts $fp {    \}}
    puts $fp {  \}}
    puts $fp {}
    puts $fp {  function emitScroll() \{}
    puts $fp {    scrollRaf = 0;}
    puts $fp {    if (!scrollForwarding) return;}
    puts $fp {    postToTrustedTop(\{}
    puts $fp {      type: "INLINE_EDIT_SCROLL",}
    puts $fp {      scrollX: window.scrollX,}
    puts $fp {      scrollY: window.scrollY,}
    puts $fp {    \});}
    puts $fp {  \}}
    puts $fp {}
    puts $fp {  window.addEventListener(}
    puts $fp {    "scroll",}
    puts $fp {    function () \{}
    puts $fp {      if (!scrollForwarding || scrollRaf) return;}
    puts $fp {      scrollRaf = requestAnimationFrame(emitScroll);}
    puts $fp {    \},}
    puts $fp {    \{ passive: true, capture: true \},}
    puts $fp {  );}
    puts $fp {}
    puts $fp {  async function handleCaptureRequest(event) \{}
    puts $fp {    const requestId = event.data.requestId;}
    puts $fp {    const scrollX = window.scrollX;}
    puts $fp {    const scrollY = window.scrollY;}
    puts $fp {    const width = window.innerWidth;}
    puts $fp {    const height = window.innerHeight;}
    puts $fp {}
    puts $fp {    function postResult(dataUrl) \{}
    puts $fp {      postToTrustedTop(\{}
    puts $fp {        type: "INLINE_EDIT_SCREENSHOT_RESULT",}
    puts $fp {        requestId,}
    puts $fp {        dataUrl,}
    puts $fp {        scrollX,}
    puts $fp {        scrollY,}
    puts $fp {      \});}
    puts $fp {    \}}
    puts $fp {}
    puts $fp {    try \{}
    puts $fp {      // Wait for any pending web fonts to resolve so both inline metrics and}
    puts $fp {      // the @font-face inlining below see the same loaded faces.}
    puts $fp {      if (document.fonts && document.fonts.ready) \{}
    puts $fp {        try \{}
    puts $fp {          await document.fonts.ready;}
    puts $fp {        \} catch (_error) \{\}}
    puts $fp {      \}}
    puts $fp {}
    puts $fp {      const clone = document.documentElement.cloneNode(true);}
    puts $fp {      inlineAll(document.documentElement, clone);}
    puts $fp {}
    puts $fp {      const removedNodes = clone.querySelectorAll("script,link\[rel=\\"stylesheet\\"\],style");}
    puts $fp {      for (let index = 0; index < removedNodes.length; index += 1) \{}
    puts $fp {        removedNodes\[index\].remove();}
    puts $fp {      \}}
    puts $fp {}
    puts $fp {      stripExternal(clone);}
    puts $fp {}
    puts $fp {      // Re-embed web fonts as data-URI @font-face rules so the SVG rasterizer}
    puts $fp {      // can resolve them &mdash; external font URLs aren't fetched during}
    puts $fp {      // foreignObject rendering, which would otherwise force a fallback face}
    puts $fp {      // and change text metrics.}
    puts $fp {      const inlinedFontCss = await buildInlinedFontCss();}
    puts $fp {      if (inlinedFontCss) \{}
    puts $fp {        const styleEl = document.createElement("style");}
    puts $fp {        styleEl.textContent = inlinedFontCss;}
    puts $fp {        const head = clone.querySelector("head");}
    puts $fp {        if (head) head.appendChild(styleEl);}
    puts $fp {        else clone.insertBefore(styleEl, clone.firstChild);}
    puts $fp {      \}}
    puts $fp {}
    puts $fp {      const html = new XMLSerializer().serializeToString(clone);}
    puts $fp {      const svg =}
    puts $fp {        `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}">` +}
    puts $fp {        '<foreignObject width="100%" height="100%">' +}
    puts $fp {        `<div xmlns="http://www.w3.org/1999/xhtml" style="width:${width}px;height:${height}px;overflow:hidden">` +}
    puts $fp {        `<div style="position:relative;left:-${scrollX}px;top:-${scrollY}px">` +}
    puts $fp {        html +}
    puts $fp {        "</div></div></foreignObject></svg>";}
    puts $fp {      const svgUrl = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;}
    puts $fp {      const image = new Image();}
    puts $fp {      image.onload = function () \{}
    puts $fp {        const canvas = document.createElement("canvas");}
    puts $fp {        canvas.width = width;}
    puts $fp {        canvas.height = height;}
    puts $fp {        canvas.getContext("2d").drawImage(image, 0, 0);}
    puts $fp {        postResult(canvas.toDataURL("image/png"));}
    puts $fp {      \};}
    puts $fp {      image.onerror = function () \{}
    puts $fp {        postResult(null);}
    puts $fp {      \};}
    puts $fp {      image.src = svgUrl;}
    puts $fp {    \} catch (_error) \{}
    puts $fp {      postResult(null);}
    puts $fp {    \}}
    puts $fp {  \}}
    puts $fp {}
    puts $fp {  window.addEventListener("message", function (event) \{}
    puts $fp {    if (!event.data) return;}
    puts $fp {    // Only accept messages from the direct parent frame. Blocks sibling /}
    puts $fp {    // unrelated-window postMessage senders that could otherwise reach us.}
    puts $fp {    if (event.source !== window.parent) return;}
    puts $fp {}
    puts $fp {    const trustedParentOrigin = getTrustedParentOrigin(event);}
    puts $fp {    if (!trustedParentOrigin) return;}
    puts $fp {    trustedTopOrigin = trustedParentOrigin;}
    puts $fp {}
    puts $fp {    if (event.data.type === "INLINE_EDIT_SCROLL_START") \{}
    puts $fp {      scrollForwarding = true;}
    puts $fp {      emitScroll();}
    puts $fp {      return;}
    puts $fp {    \}}
    puts $fp {}
    puts $fp {    if (event.data.type === "INLINE_EDIT_SCROLL_STOP") \{}
    puts $fp {      scrollForwarding = false;}
    puts $fp {      if (scrollRaf) cancelAnimationFrame(scrollRaf);}
    puts $fp {      scrollRaf = 0;}
    puts $fp {      return;}
    puts $fp {    \}}
    puts $fp {}
    puts $fp {    if (event.data.type !== "INLINE_EDIT_CAPTURE_REQUEST") return;}
    puts $fp {}
    puts $fp {    handleCaptureRequest(event);}
    puts $fp {  \});}
    puts $fp {\})();}</script>}
    puts $fp {  </body>}
    puts $fp {</html>}
    
    close $fp
}

# Main execution - check if filename argument provided
if {$argc != 1} {
    puts stderr "Usage: $argv0 <output_filename>"
    exit 1
}

# Generate the HTML file
generate_html [lindex $argv 0]
