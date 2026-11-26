// abstraction-provenance: {"artifact_sha256": "ae58454334c85dbcfda57278e69ded5ecbcc0e7610bd2fd8758871bec0b7ba07", "source_sha256": "c10479f79ca5554fe399cf2f5d70fb5b32e837c1c7a846eb7dd7c9e9e5319c66", "target_language": "fsharp"}
// index.html — portiert nach fsharp
// Quelle: html, Projects@TikTok-Live-Companion:site/index.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/index.html
// auch in: Projects@vercel/install-and-configure-vercel-w-98sxlo:site/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Xml.Linq

let createHtmlDocument () =
    let htmlNs = XNamespace.Get("http://www.w3.org/1999/xhtml")
    
    let docType = XDocumentType("html", null, null, null)
    
    let root = 
        XElement(htmlNs + "html",
            XAttribute(XNamespace.Xmlns + "html", "http://www.w3.org/1999/xhtml"),
            XAttribute("lang", "de"),
            XElement(htmlNs + "head",
                XElement(htmlNs + "meta",
                    XAttribute("charset", "UTF-8")),
                XElement(htmlNs + "meta",
                    XAttribute("name", "viewport"),
                    XAttribute("content", "width=device-width, initial-scale=1.0")),
                XElement(htmlNs + "meta",
                    XAttribute("name", "description"),
                    XAttribute("content", "Dokumentation für TikTok LIVE Companion 0.8.2 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.")),
                XElement(htmlNs + "meta",
                    XAttribute("name", "theme-color"),
                    XAttribute("content", "#ffffff")),
                XElement(htmlNs + "link",
                    XAttribute("rel", "icon"),
                    XAttribute("type", "image/png"),
                    XAttribute("href", "/branding/staenderglobus-ios.png")),
                XElement(htmlNs + "link",
                    XAttribute("rel", "apple-touch-icon"),
                    XAttribute("href", "/branding/staenderglobus-ios.png")),
                XElement(htmlNs + "title",
                    "TikTok LIVE Companion – Dokumentation")
            ),
            XElement(htmlNs + "body",
                XElement(htmlNs + "div",
                    XAttribute("id", "root")),
                XElement(htmlNs + "script",
                    XAttribute("type", "module"),
                    XAttribute("src", "/src/main.tsx"))
            )
        )
    
    XDocument(docType, root)

let writeHtmlToFile (filePath: string) =
    let doc = createHtmlDocument()
    use writer = new StreamWriter(filePath, false, Text.Encoding.UTF8)
    doc.Save(writer, SaveOptions.None)

[<EntryPoint>]
let main argv =
    let filePath = 
        if argv.Length > 0 then argv.[0]
        else "index.html"
    
    writeHtmlToFile filePath
    0
