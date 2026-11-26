// abstraction-provenance: {"artifact_sha256": "4a25062515133620434292263a00a14ca07fed47892ecd385d69de2059311c67", "source_sha256": "ea0eb33b2baa2fe609d171d70b4b6f712df52229f647c3ac02833fc01d629d35", "target_language": "fsharp"}
// gateway-dashboard.html — portiert nach fsharp
// Quelle: html, OpenClaw@main:examples/gateway-dashboard.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

module GatewayDashboard

open System
open System.IO
open System.Text

let generateDashboard (outputPath: string) =
    let html = StringBuilder()

    // DOCTYPE and html start
    html.AppendLine("<!DOCTYPE html>") |> ignore
    html.AppendLine("<html lang=\"en\">") |> ignore
    
    // Head section
    html.AppendLine("<head>") |> ignore
    html.AppendLine("  <meta charset=\"UTF-8\">") |> ignore
    html.AppendLine("  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">") |> ignore
    html.AppendLine("  <title>OpenClaw — Gateway Dashboard</title>") |> ignore
    html.AppendLine("  <link rel=\"stylesheet\" href=\"gateway-styles.css\">") |> ignore
    html.AppendLine("</head>") |> ignore
    
    // Body start
    html.AppendLine("<body>") |> ignore
    
    // Header
    html.AppendLine("  <header>") |> ignore
    html.AppendLine("    <h1>OpenClaw Cluster</h1>") |> ignore
    html.AppendLine("    <span id=\"cluster-status\" class=\"badge\">Checking...</span>") |> ignore
    html.AppendLine("  </header>") |> ignore
    
    // Main content
    html.AppendLine("  <main>") |> ignore
    
    // Grid section
    html.AppendLine("    <section class=\"grid\">") |> ignore
    html.AppendLine("      <div class=\"card\" id=\"gw1\">") |> ignore
    html.AppendLine("        <h2>Gateway 1</h2>") |> ignore
    html.AppendLine("        <p class=\"endpoint\">gateway1.openclaw.internal</p>") |> ignore
    html.AppendLine("        <div class=\"status-dot\"></div>") |> ignore
    html.AppendLine("      </div>") |> ignore
    html.AppendLine("      <div class=\"card\" id=\"gw2\">") |> ignore
    html.AppendLine("        <h2>Gateway 2</h2>") |> ignore
    html.AppendLine("        <p class=\"endpoint\">gateway2.openclaw.internal</p>") |> ignore
    html.AppendLine("        <div class=\"status-dot\"></div>") |> ignore
    html.AppendLine("      </div>") |> ignore
    html.AppendLine("    </section>") |> ignore
    
    // Metrics section
    html.AppendLine("    <section class=\"metrics\">") |> ignore
    html.AppendLine("      <h2>Node Metrics</h2>") |> ignore
    html.AppendLine("      <table>") |> ignore
    html.AppendLine("        <thead>") |> ignore
    html.AppendLine("          <tr><th>Node</th><th>Latency</th><th>Requests</th><th>Status</th></tr>") |> ignore
    html.AppendLine("        </thead>") |> ignore
    html.AppendLine("        <tbody id=\"metrics-body\">") |> ignore
    html.AppendLine("          <tr><td colspan=\"4\">Loading...</td></tr>") |> ignore
    html.AppendLine("        </tbody>") |> ignore
    html.AppendLine("      </table>") |> ignore
    html.AppendLine("    </section>") |> ignore
    
    html.AppendLine("  </main>") |> ignore
    
    // Script section
    html.AppendLine("  <script>") |> ignore
    html.AppendLine("    const GATEWAY_URL = window.OPENCLAW_URL || \"http://localhost:8080\";") |> ignore
    html.AppendLine("") |> ignore
    html.AppendLine("    async function pollStatus() {") |> ignore
    html.AppendLine("      try {") |> ignore
    html.AppendLine("        const res = await fetch(`${GATEWAY_URL}/health`);") |> ignore
    html.AppendLine("        const ok = res.ok;") |> ignore
    html.AppendLine("        document.getElementById(\"cluster-status\").textContent = ok ? \"Online\" : \"Degraded\";") |> ignore
    html.AppendLine("        document.getElementById(\"cluster-status\").className = `badge ${ok ? \"ok\" : \"warn\"}`;") |> ignore
    html.AppendLine("        document.querySelectorAll(\".status-dot\").forEach(d => d.className = `status-dot ${ok ? \"green\" : \"red\"}`);") |> ignore
    html.AppendLine("      } catch {") |> ignore
    html.AppendLine("        document.getElementById(\"cluster-status\").textContent = \"Offline\";") |> ignore
    html.AppendLine("        document.getElementById(\"cluster-status\").className = \"badge error\";") |> ignore
    html.AppendLine("      }") |> ignore
    html.AppendLine("    }") |> ignore
    html.AppendLine("") |> ignore
    html.AppendLine("    pollStatus();") |> ignore
    html.AppendLine("    setInterval(pollStatus, 5000);") |> ignore
    html.AppendLine("  </script>") |> ignore
    
    // Close body and html
    html.AppendLine("</body>") |> ignore
    html.AppendLine("</html>") |> ignore
    
    // Write to file
    File.WriteAllText(outputPath, html.ToString())

[<EntryPoint>]
let main argv =
    let outputPath = 
        if argv.Length > 0 then argv.[0] 
        else "gateway-dashboard.html"
    
    generateDashboard outputPath
    printfn "Dashboard generated at %s" outputPath
    0
