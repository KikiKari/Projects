// abstraction-provenance: {"artifact_sha256": "4654870fdcf131f16880de873d36c25933fb7140491926d6142c0c017d5adb19", "source_sha256": "9245a78489adb3949ae2a56f5e0987a465142b9a8ee97bddaca453f5011daef8", "target_language": "fsharp"}
// index.html — portiert nach fsharp
// Quelle: html, Projects@Program-Derivation:public/index.html
// auch in: Projects@Vision-Check:public/index.html
// auch in: Projects@Weather-Check:public/index.html
// auch in: Projects@abstractions:public/index.html
// auch in: 5 weiteren Fundstellen
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Xml.Linq

let createHtmlDocument () =
    let xhtmlNs = XNamespace.Get("http://www.w3.org/1999/xhtml")
    
    let docType = XDocumentType("html", null, null, null)
    
    let doc = 
        XDocument(
            docType,
            XElement(xhtmlNs + "html",
                XAttribute(XNamespace.Xmlns + "html", "http://www.w3.org/1999/xhtml"),
                XAttribute("lang", "de"),
                XElement(xhtmlNs + "head",
                    XElement(xhtmlNs + "meta",
                        XAttribute("charset", "utf-8")
                    ),
                    XElement(xhtmlNs + "meta",
                        XAttribute("name", "viewport"),
                        XAttribute("content", "width=device-width, initial-scale=1")
                    ),
                    XElement(xhtmlNs + "meta",
                        XAttribute("http-equiv", "refresh"),
                        XAttribute("content", "0; url=3d.html")
                    ),
                    XElement(xhtmlNs + "title",
                        "Weiterleitung zur 3D-Ansicht"
                    ),
                    XElement(xhtmlNs + "link",
                        XAttribute("rel", "canonical"),
                        XAttribute("href", "3d.html")
                    ),
                    XElement(xhtmlNs + "script",
                        "location.replace('3d.html');"
                    )
                ),
                XElement(xhtmlNs + "body",
                    XElement(xhtmlNs + "p",
                        XElement(xhtmlNs + "a",
                            XAttribute("href", "3d.html"),
                            "3D-Ansicht öffnen"
                        )
                    )
                )
            )
        )
    
    doc

let writeHtmlToFile (filePath: string) =
    let doc = createHtmlDocument()
    use writer = new StreamWriter(filePath, false, Text.Encoding.UTF8)
    doc.Save(writer, SaveOptions.None)

[<EntryPoint>]
let main argv =
    let filePath = 
        if argv.Length > 0 then argv.[0] 
        else "index.html"
    
    try
        writeHtmlToFile filePath
        printfn "HTML file successfully written to %s" filePath
        0
    with
    | ex ->
        eprintfn "Error writing HTML file: %s" ex.Message
        1
