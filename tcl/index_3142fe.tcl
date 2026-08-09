#!/usr/bin/env tclsh
# index.html — portiert nach tcl
# Quelle: html, Projects@Weather-Check:Weather-Check/index.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

proc writeIndexHtml {filename} {
    set fd [open $filename w]
    
    puts $fd {<!DOCTYPE html>}
    puts $fd {<html lang="de">}
    puts $fd {  <head>}
    puts $fd {    <meta charset="UTF-8" />}
    puts $fd {    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />}
    puts $fd {    <meta name="theme-color" content="#0d1b2a" />}
    puts $fd {    <meta name="description" content="Lokaler Regen-Check für die nächsten 30, 60 und 120 Minuten" />}
    puts $fd {    <meta name="apple-mobile-web-app-capable" content="yes" />}
    puts $fd {    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />}
    puts $fd {    <meta name="apple-mobile-web-app-title" content="Weather" />}
    puts $fd {    <link rel="manifest" href="./manifest.json" />}
    puts $fd {    <link rel="apple-touch-icon" href="./icon-512.png" />}
    puts $fd {    <title>Weather – Regen-Check</title>}
    puts $fd {    <script type="module" crossorigin src="./assets/index-DGdzG44S.js"></script>}
    puts $fd {    <link rel="stylesheet" crossorigin href="./assets/index-erFv57XC.css">}
    puts $fd {  </head>}
    puts $fd {  <body>}
    puts $fd {    <div id="root"></div>}
    puts $fd {  <script data-pplx-inline-edit>}
    puts $fd {(function () \{}
    puts $fd {  if (window === window.top) return;}
    puts $fd {}
    puts $fd {  const allowedParentOrigins = \["https://www.perplexity.ai","https://perplexity.ai","https://testing.perplexity.ai","https://staging.perplexity.ai","https://*.preview.i.perplexity.ai","http://localhost:3000","http://127.0.0.1:3000","http://localhost:5173","http://127.0.0.1:5173"\];}
    puts $fd {  const MAX_FONT_BYTES = 500 * 1024;}
    puts $fd {  const MAX_TOTAL_FONT_BYTES = 2 * 1024 * 1024;}
    puts $fd {  let scrollForwarding = false;}
    puts $fd {  let scrollRaf = 0;}
    puts $fd {  let trustedTopOrigin = null;}
    puts $fd {}
    puts $fd {  // Allow entries like "https://*.preview.i.perplexity.ai" — the wildcard}
    puts $fd {  // matches a single DNS label (no dots), so "https://*.foo" cannot stretch}
    puts $fd {  // across multiple labels.}
    puts $fd {  function matchesAllowedOrigin(origin) \{}
    puts $fd {    if (!origin) return false;}
    puts $fd {    for (const entry of allowedParentOrigins) \{}
    puts $fd {      if (!entry.includes("*")) \{}
    puts $fd {        if (entry === origin) return true;}
    puts $fd {        continue;}
    puts $fd {      \}}
    puts $fd {      const pattern = new RegExp(}
    puts $fd {        "^" +}
    puts $fd {          entry.replace(/\[.+?^$\{\}\(\)|\[\]\\\]/g, "\\$&").replace(/\*/g, "\[^.\]+") +}
    puts $fd {          "$",}
    puts $fd {      );}
    puts $fd {      if (pattern.test(origin)) return true;}
    puts $fd {    \}}
    puts $fd {    return false;}
    puts $fd {  \}}
    puts $fd {}
    puts $fd {  // Trust decision: when the sender is same-origin-visible (event.origin is a}
    puts $fd {  // real origin like https://www.perplexity.ai) we trust event.origin directly.}
    puts $fd {  // When event.origin is "null" (opaque broker srcdoc), we fall back to the}
    puts $fd {  // broker's stamped `parentOrigin` to identify the top window. The fallback}
    puts $fd {  // is claim-only — we rely on the browser's native `targetOrigin` enforcement}
    puts $fd {  // on the response path (see postToTrustedTop) to ensure replies can't be}
    puts $fd {  // delivered to anyone but the actual top window of that claimed origin.}
    puts $fd {  function getTrustedParentOrigin(event) \{}
    puts $fd {    const forwardedParentOrigin =}
    puts $fd {      typeof event.data.parentOrigin === "string" ? event.data.parentOrigin : null;}
    puts $fd {    const parentOrigin = event.origin === "null" ? forwardedParentOrigin : event.origin;}
    puts $fd {    return matchesAllowedOrigin(parentOrigin) ? parentOrigin : null;}
    puts $fd {  \}}
    puts $fd {}
    puts $fd {  // All responses go to window.top with targetOrigin = the allowlisted origin.}
    puts $fd {  // An attacker that iframes us inside their own null-origin broker can claim}
    puts $fd {  // any parentOrigin they like, but the browser will drop the reply whenever}
    puts $fd {  // the real top's origin doesn't match — so the screenshot never leaves.}
    puts $fd {  function postToTrustedTop(message) \{}
    puts $fd {    if (!trustedTopOrigin) return;}
    puts $fd {    try \{}
    puts $fd {      window.top.postMessage(message, trustedTopOrigin);}
    puts $fd {    \} catch (_error) \{\}}
    puts $fd {  \}}
    puts $fd {}
    puts $fd {  function inlineAll(original, clone) \{}
    puts $fd {    if (original.nodeType !== 1 || clone.nodeType !== 1) return;}
    puts $fd {}
    puts $fd {    try \{}
    puts $fd {      const computedStyle = getComputedStyle(original);}
    puts $fd {      // cssText on a computed style is the serialized declaration in modern}
    puts $fd {      // Chromium/Safari — a single read beats enumerating ~400 longhand}
    puts $fd {      // properties. Firefox returns "" here, so we fall back on empty.}
    puts $fd {      const serialized = computedStyle.cssText;}
    puts $fd {      if (serialized) \{}
    puts $fd {        clone.style.cssText = serialized;}
    puts $fd {      \} else \{}
    puts $fd {        const parts = new Array(computedStyle.length);}
    puts $fd {        for (let index = 0; index < computedStyle.length; index += 1) \{}
    puts $fd {          const property = computedStyle\[index\];}
    puts $fd {          parts\[index\] = `${property}:${computedStyle.getPropertyValue(property)};`;}
    puts $fd {        \}}
    puts $fd {        clone.style.cssText = parts.join("");}}
    puts $fd {      \}}
    puts $fd {    \} catch (_error) \{\}}
    puts $fd {}
    puts $fd {    const originalChildren = original.children;}
    puts $fd {    const clonedChildren = clone.children;}
    puts $fd {    for (}
    puts $fd {      let index = 0;}
    puts $fd {      index < originalChildren.length && index < clonedChildren.length;}
    puts $fd {      index += 1}
    puts $fd {    ) \{}
    puts $fd {      inlineAll(originalChildren\[index\], clonedChildren\[index\]);}
    puts $fd {    \}}
    puts $fd {  \}}
    puts $fd {}
    puts $fd {  function extractFontUrl(srcValue) \{}
    puts $fd {    const matches = \[}
    puts $fd {      ...srcValue.matchAll(}
    puts $fd {        /url\(\["'\]?\([^"')\]+\)\["'\]?\)\(?:\\s*format\(\["'\]?\([^"')\]+\)\["'\]?\)\)?/gi,}
    puts $fd {      ),}
    puts $fd {    \];}
    puts $fd {    if (matches.length === 0) return null;}
    puts $fd {    const woff2 = matches.find((m) => m\[2\] && m\[2\].toLowerCase().includes("woff2"));}
    puts $fd {    if (woff2) return woff2\[1\];}
    puts $fd {    const woff = matches.find((m) => m\[2\] && m\[2\].toLowerCase().includes("woff"));}
    puts $fd {    if (woff) return woff\[1\];}
    puts $fd {    return matches\[0\]\[1\];}
    puts $fd {  \}}
    puts $fd {}
    puts $fd {  // Cache resolved font URL -> data URI across captures. Fonts on a page}
    puts $fd {  // essentially never change, and a batch run emits multiple captures back to}
    puts $fd {  // back — without this we'd refetch + re-base64 every time.}
    puts $fd {  const fontDataUriCache = new Map();}
    puts $fd {  const SRC_DECLARATION_RE = /src\\s*:\\s*\[^;}\]+/i;}
    puts $fd {}
    puts $fd {  async function fetchAsDataUri(url) \{}
    puts $fd {    if (fontDataUriCache.has(url)) return fontDataUriCache.get(url);}
    puts $fd {    let dataUri = null;}
    puts $fd {    try \{}
    puts $fd {      const response = await fetch(url, \{ mode: "cors", credentials: "omit" \});}
    puts $fd {      if (response.ok) \{}
    puts $fd {        const blob = await response.blob();}
    puts $fd {        if (blob.size <= MAX_FONT_BYTES) \{}
    puts $fd {          dataUri = await new Promise((resolve) => \{}
    puts $fd {            const reader = new FileReader();}
    puts $fd {            reader.onloadend = () =>}
    puts $fd {              resolve(typeof reader.result === "string" ? reader.result : null);}
    puts $fd {            reader.onerror = () => resolve(null);}
    puts $fd {            reader.readAsDataURL(blob);}
    puts $fd {          \});}
    puts $fd {        \}}
    puts $fd {      \}}
    puts $fd {    \} catch (_error) \{}
    puts $fd {      dataUri = null;}
    puts $fd {    \}}
    puts $fd {    fontDataUriCache.set(url, dataUri);}
    puts $fd {    return dataUri;}
    puts $fd {  \}}
    puts $fd {}
    puts $fd {  function collectFontFaceRuleTexts() \{}
    puts $fd {    const rules = \[];}
    puts $fd {    for (const sheet of document.styleSheets) \{}
    puts $fd {      let cssRules;}
    puts $fd {      try \{}
    puts $fd {        cssRules = sheet.cssRules;}
    puts $fd {      \} catch (_error) \{}
    puts $fd {        continue;}
    puts $fd {      \}}
    puts $fd {      if (!cssRules) continue;}
    puts $fd {      for (const rule of cssRules) \{}
    puts $fd {        const cssText = rule.cssText || "";}
    puts $fd {        if (cssText.startsWith("@font-face")) rules.push(cssText);}
    puts $fd {      \}}
    puts $fd {    \}}
    puts $fd {    return rules;}
    puts $fd {  \}}
    puts $fd {}
    puts $fd {  async function buildInlinedFontCss() \{}
    puts $fd {    const ruleTexts = collectFontFaceRuleTexts();}
    puts $fd {    if (ruleTexts.length === 0) return null;}
    puts $fd {}
    puts $fd {    const resolved = ruleTexts.map((cssText) => \{}
    puts $fd {      if (!SRC_DECLARATION_RE.test(cssText)) return null;}
    puts $fd {      const srcMatch = cssText.match(/src\\s*:\\s*\([^;}]+\)\[;}\]/i);}
    puts $fd {      if (!srcMatch) return null;}
    puts $fd {      const url = extractFontUrl(srcMatch\[1\]);}
    puts $fd {      if (!url) return null;}
    puts $fd {      try \{}
    puts $fd {        return \{ cssText, url: new URL(url, document.baseURI).href \};}
    puts $fd {      \} catch (_error) \{}
    puts $fd {        return null;}
    puts $fd {      \}}
    puts $fd {    \});}
    puts $fd {}
    puts $fd {    const dataUris = await Promise.all(}
    puts $fd {      resolved.map((entry) => (entry ? fetchAsDataUri(entry.url) : Promise.resolve(null))),}
    puts $fd {    );}
    puts $fd {}
    puts $fd {    const inlined = \[];}
    puts $fd {    let totalBytes = 0;}
    puts $fd {    for (let index = 0; index < resolved.length; index += 1) \{}
    puts $fd {      const entry = resolved\[index\];}
    puts $fd {      const dataUri = dataUris\[index\];}
    puts $fd {      if (!entry || !dataUri) continue;}
    puts $fd {      const approxBytes = dataUri.length * 0.75;}
    puts $fd {      if (totalBytes + approxBytes > MAX_TOTAL_FONT_BYTES) break;}
    puts $fd {      totalBytes += approxBytes;}
    puts $fd {      inlined.push(entry.cssText.replace(SRC_DECLARATION_RE, `src: url("${dataUri}")`));}
    puts $fd {    \}}
    puts $fd {    return inlined.length > 0 ? inlined.join("\\n") : null;}
    puts $fd {  \}}
    puts $fd {}
    puts $fd {  function stripExternal(clone) \{}
    puts $fd {    const images = clone.querySelectorAll("img");}
    puts $fd {    for (let index = 0; index < images.length; index += 1) \{}
    puts $fd {      const src = images\[index\].getAttribute("src");}
    puts $fd {      if (src && !src.startsWith("data:")) images\[index\].removeAttribute("src");}
    puts $fd {    \}}
    puts $fd {}
    puts $fd {    const elements = clone.querySelectorAll("*");}
    puts $fd {    for (let index = 0; index < elements.length; index += 1) \{}
    puts $fd {      const style = elements\[index\].style.cssText;}
    puts $fd {      if (style && style.includes("url(")) \{}
    puts $fd {        elements\[index\].style.cssText = style.replace(}
    puts $fd {          /url\(\["'\]?\(?!data:\)\[^)"'\]*\["'\]?\)/gi,}
    puts $fd {          "none",}
    puts $fd {        );}
    puts $fd {      \}}
    puts $fd {    \}}
    puts $fd {  \}}
    puts $fd {}
    puts $fd {  function emitScroll() \{}
    puts $fd {    scrollRaf = 0;}
    puts $fd {    if (!scrollForwarding) return;}
    puts $fd {    postToTrustedTop(\{}
    puts $fd {      type: "INLINE_EDIT_SCROLL",}
    puts $fd {      scrollX: window.scrollX,}
    puts $fd {      scrollY: window.scrollY,}
    puts $fd {    \});}
    puts $fd {  \}}
    puts $fd {}
    puts $fd {  window.addEventListener(}
    puts $fd {    "scroll",}
    puts $fd {    function () \{}
    puts $fd {      if (!scrollForwarding || scrollRaf) return;}
    puts $fd {      scrollRaf = requestAnimationFrame(emitScroll);}
    puts $fd {    \},}
    puts $fd {    \{ passive: true, capture: true \},}
    puts $fd {  );}
    puts $fd {}
    puts $fd {  async function handleCaptureRequest(event) \{}
    puts $fd {    const requestId = event.data.requestId;}
    puts $fd {    const scrollX = window.scrollX;}
    puts $fd {    const scrollY = window.scrollY;}
    puts $fd {    const width = window.innerWidth;}
    puts $fd {    const height = window.innerHeight;}
    puts $fd {}
    puts $fd {    function postResult(dataUrl) \{}
    puts $fd {      postToTrustedTop(\{}
    puts $fd {        type: "INLINE_EDIT_SCREENSHOT_RESULT",}
    puts $fd {        requestId,}
    puts $fd {        dataUrl,}
    puts $fd {        scrollX,}
    puts $fd {        scrollY,}
    puts $fd {      \});}
    puts $fd {    \}}
    puts $fd {}
    puts $fd {    try \{}
    puts $fd {      // Wait for any pending web fonts to resolve so both inline metrics and}
    puts $fd {      // the @font-face inlining below see the same loaded faces.}
    puts $fd {      if (document.fonts && document.fonts.ready) \{}
    puts $fd {        try \{}
    puts $fd {          await document.fonts.ready;}
    puts $fd {        \} catch (_error) \{\}}
    puts $fd {      \}}
    puts $fd {}
    puts $fd {      const clone = document.documentElement.cloneNode(true);}
    puts $fd {      inlineAll(document.documentElement, clone);}
    puts $fd {}
    puts $fd {      const removedNodes = clone.querySelectorAll("script,link\[rel=\\"stylesheet\\"\],style");}
    puts $fd {      for (let index = 0; index < removedNodes.length; index += 1) \{}
    puts $fd {        removedNodes\[index\].remove();}
    puts $fd {      \}}
    puts $fd {}
    puts $fd {      stripExternal(clone);}
    puts $fd {}
    puts $fd {      // Re-embed web fonts as data-URI @font-face rules so the SVG rasterizer}
    puts $fd {      // can resolve them — external font URLs aren't fetched during}
    puts $fd {      // foreignObject rendering, which would otherwise force a fallback face}
    puts $fd {      // and change text metrics.}
    puts $fd {      const inlinedFontCss = await buildInlinedFontCss();}
    puts $fd {      if (inlinedFontCss) \{}
    puts $fd {        const styleEl = document.createElement("style");}
    puts $fd {        styleEl.textContent = inlinedFontCss;}
    puts $fd {        const head = clone.querySelector("head");}
    puts $fd {        if (head) head.appendChild(styleEl);}
    puts $fd {        else clone.insertBefore(styleEl, clone.firstChild);}
    puts $fd {      \}}
    puts $fd {}
    puts $fd {      const html = new XMLSerializer().serializeToString(clone);}
    puts $fd {      const svg =}
    puts $fd {        `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}">` +}
    puts $fd {        '<foreignObject width="100%" height="100%">' +}
    puts $fd {        `<div xmlns="http://www.w3.org/1999/xhtml" style="width:${width}px;height:${height}px;overflow:hidden">` +}
    puts $fd {        `<div style="position:relative;left:-${scrollX}px;top:-${scrollY}px">` +}
    puts $fd {        html +}
    puts $fd {        "</div></div></foreignObject></svg>";}
    puts $fd {      const svgUrl = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;}
    puts $fd {      const image = new Image();}
    puts $fd {      image.onload = function () \{}
    puts $fd {        const canvas = document.createElement("canvas");}
    puts $fd {        canvas.width = width;}
    puts $fd {        canvas.height = height;}
    puts $fd {        canvas.getContext("2d").drawImage(image, 0, 0);}
    puts $fd {        postResult(canvas.toDataURL("image/png"));}
    puts $fd {      \};}
    puts $fd {      image.onerror = function () \{}
    puts $fd {        postResult(null);}
    puts $fd {      \};}
    puts $fd {      image.src = svgUrl;}
    puts $fd {    \} catch (_error) \{}
    puts $fd {      postResult(null);}
    puts $fd {    \}}
    puts $fd {  \}}
    puts $fd {}
    puts $fd {  window.addEventListener("message", function (event) \{}
    puts $fd {    if (!event.data) return;}
    puts $fd {    // Only accept messages from the direct parent frame. Blocks sibling /}
    puts $fd {    // unrelated-window postMessage senders that could otherwise reach us.}
    puts $fd {    if (event.source !== window.parent) return;}
    puts $fd {}
    puts $fd {    const trustedParentOrigin = getTrustedParentOrigin(event);}
    puts $fd {    if (!trustedParentOrigin) return;}
    puts $fd {    trustedTopOrigin = trustedParentOrigin;}
    puts $fd {}
    puts $fd {    if (event.data.type === "INLINE_EDIT_SCROLL_START") \{}
    puts $fd {      scrollForwarding = true;}
    puts $fd {      emitScroll();}
    puts $fd {      return;}
    puts $fd {    \}}
    puts $fd {}
    puts $fd {    if (event.data.type === "INLINE_EDIT_SCROLL_STOP") \{}
    puts $fd {      scrollForwarding = false;}
    puts $fd {      if (scrollRaf) cancelAnimationFrame(scrollRaf);}
    puts $fd {      scrollRaf = 0;}
    puts $fd {      return;}
    puts $fd {    \}}
    puts $fd {}
    puts $fd {    if (event.data.type !== "INLINE_EDIT_CAPTURE_REQUEST") return;}
    puts $fd {}
    puts $fd {    handleCaptureRequest(event);}
    puts $fd {  \});}
    puts $fd {\})();}
    puts $fd {}
    puts $fd {</script></body>}
    puts $fd {</html>}
    
    close $fd
}

# Hauptprogramm
if {$argc != 1} {
    puts stderr "Verwendung: $argv0 <ausgabedatei>"
    exit 1
}

set outputFile [lindex $argv 0]
writeIndexHtml $outputFile
