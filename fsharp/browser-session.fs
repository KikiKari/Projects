// abstraction-provenance: {"artifact_sha256": "3886e086213238bd5dacaf1b74e6fbb6dcc180ea5fbaf6039ae5e750e7fba33b", "source_sha256": "acf29634657ddc4b0dd7488e70f24c496bf7bd82883eecf4ebbed3a1486457cd", "target_language": "fsharp"}
// browser-session.mjs — portiert nach fsharp
// Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

// Persistente Browser-Sitzung der Sandbox.
//
// Zweck: Plattformen ohne (nutzbare) API — WaveSpeed-Konsole, Perplexity,
// Canva, Stock-Portale — erfordern einen echten Web-Login. Diese Sitzung
// speichert Cookies/LocalStorage DAUERHAFT in einem user-data-dir, akzeptiert
// Cookie-Banner automatisch und bleibt über Skript-Läufe hinweg angemeldet.
//
// Profil-Verzeichnis: <repo>/.browser-profile (gitignored — enthält Secrets).
//
// Nutzung (immer unter Xvfb, damit echtes Chrome mit Codecs läuft):
//   xvfb-run -a node scripts/browser-session.mjs open <URL>          # öffnen, Cookies akzeptieren, Screenshot
//   xvfb-run -a node scripts/browser-session.mjs login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
//   xvfb-run -a node scripts/browser-session.mjs shot <URL> [--out file.png] [--wait ms] [--full]
//   xvfb-run -a node scripts/browser-session.mjs state                 # gespeicherte Cookies auflisten (Domains)
//
// Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.

open System
open System.IO
open System.Text.RegularExpressions
open Microsoft.Playwright

let repo = Path.Combine(Path.GetDirectoryName(typeof<obj>.Assembly.Location), "..")
let profile = 
    match Environment.GetEnvironmentVariable("BROWSER_PROFILE_DIR") with
    | null | "" -> Path.Combine(repo, ".browser-profile")
    | dir -> dir

let chromePaths = [| "/usr/bin/google-chrome-stable"; "/usr/bin/google-chrome" |]
let chromePath = Array.tryFind File.Exists chromePaths

let args = Array.skip 2 Environment.GetCommandLineArgs()
let cmd = if args.Length > 0 then args.[0] else ""
let target = if args.Length > 1 then args.[1] else ""
let rest = if args.Length > 2 then Array.skip 2 args else [||]

let flag (name: string) (defaultVal: string) =
    let index = Array.IndexOf(rest, sprintf "--%s" name)
    if index >= 0 && index + 1 < rest.Length then rest.[index + 1] else defaultVal

let has (name: string) = Array.contains (sprintf "--%s" name) rest

// .env laden (nur für login-Credentials; nichts wird geloggt)
let loadEnv () =
    let envFile = Path.Combine(repo, ".env")
    if not (File.Exists(envFile)) then Map.empty
    else
        let lines = File.ReadAllLines(envFile)
        lines
        |> Array.choose (fun line ->
            let m = Regex.Match(line, @"^\s*([A-Z0-9_]+)\s*=\s*""?([^""]*)""?\s*$")
            if m.Success then Some(m.Groups.[1].Value, m.Groups.[2].Value) else None)
        |> Map.ofArray

/// Häufige Cookie-Consent-Buttons klicken (mehrsprachig, best effort).
let acceptCookies (page: IPage) =
    async {
        let labels = [|
            "Accept all"; "Accept All"; "Alle akzeptieren"; "Accept all cookies"
            "Alle Cookies akzeptieren"; "I agree"; "Ich stimme zu"; "Zustimmen"
            "Allow all"; "Akzeptieren"; "Accept"; "Got it"; "Agree"
        |]
        
        for name in labels do
            try
                let! btn = page.GetByRole(AriaRole.Button, new() { Name = name; Exact = Nullable(false) }).First.Async()
                let! visible = btn.IsVisibleAsync(new() { Timeout = 800.0 })
                if visible then
                    do! btn.ClickAsync(new() { Timeout = 1500.0 }) |> Async.AwaitTask
                    return Some(name)
                else
                    ()
            with _ -> ()
            
        // Generische Consent-IDs
        let selectors = [| "#onetrust-accept-btn-handler"; "[aria-label*='accept' i]"; "button[title*='accept' i]" |]
        for sel in selectors do
            try
                let! el = page.Locator(sel).First.Async()
                let! visible = el.IsVisibleAsync(new() { Timeout = 500.0 })
                if visible then
                    do! el.ClickAsync(new() { Timeout = 1500.0 }) |> Async.AwaitTask
                    return Some(sel)
                else
                    ()
            with _ -> ()
            
        return None
    }

Directory.CreateDirectory(profile) |> ignore

// Sandbox-Egress läuft über den Agent-Proxy (MITM mit CA in /root/.ccr).
// Chrome muss den Proxy nutzen; die CA ist zuvor via certutil in ~/.pki/nssdb
// importiert (siehe docs/VISUAL_QA.md), damit TLS ohne Fehler verifiziert.
// --socks <server>: leitet den Browser über einen SOCKS5-Proxy (z. B. den
// Tailscale-Userspace-Proxy localhost:1055) — sauberer Egress am Agent-MITM-
// Proxy vorbei, nötig für github.com/Codespaces. Sonst der Agent-HTTPS-Proxy.
let socks = flag "socks" ""
let proxy = 
    if not (String.IsNullOrEmpty(socks)) then
        sprintf "socks5://%s" socks
    else
        let httpsProxy = Environment.GetEnvironmentVariable("HTTPS_PROXY")
        let httpsProxyLower = Environment.GetEnvironmentVariable("https_proxy")
        match httpsProxy, httpsProxyLower with
        | null, null -> null
        | p, _ when not (String.IsNullOrEmpty(p)) -> p
        | _, p -> p

let playwright = Playwright.CreateAsync().Result
let browserType = playwright.Chromium

let launchOptions = BrowserTypeLaunchPersistentContextOptions(
    Headless = Nullable(false),
    Viewport = Nullable(ViewportSize(Width = 1440, Height = 900)),
    AcceptDownloads = Nullable(true),
    IgnoreHTTPSErrors = Nullable(has "insecure"),
    Proxy = if proxy <> null then Nullable(BrowserNewContextOptionsProxy( Server = proxy, Bypass = "localhost,127.0.0.1,::1" )) else Nullable(),
    Args = [
        "--no-sandbox"
        "--autoplay-policy=no-user-gesture-required"
        "--disable-blink-features=AutomationControlled"
        if proxy <> null then "--ssl-version-max=tls1.2"
    ] |> List.toArray
)

match chromePath with
| Some(path) -> launchOptions.ExecutablePath <- path
| None -> ()

let context = browserType.LaunchPersistentContextAsync(profile, launchOptions).Result
let page = 
    if context.Pages.Count > 0 then
        context.Pages.[0]
    else
        context.NewPageAsync().Result

try
    match cmd with
    | "state" ->
        let cookies = context.CookiesAsync().Result
        let domains = cookies |> Seq.map (fun c -> c.Domain) |> Set.ofSeq |> Set.toArray |> Array.sort
        printfn $"Profil: %s{profile}"
        printfn $"{cookies.Length} Cookies über {domains.Length} Domains:"
        domains |> Array.iter (fun d -> printfn $"  %s{d}")
        
    | "open" | "shot" ->
        if String.IsNullOrEmpty(target) then failwith "URL fehlt"
        page.GotoAsync(target, new() { WaitUntil = WaitForSelectorState.DOMContentLoaded; Timeout = 60000.0 }) |> Async.AwaitTask |> Async.RunSynchronously
        let waitTime = int (flag "wait" "2500")
        page.WaitForTimeoutAsync(waitTime) |> Async.AwaitTask |> Async.RunSynchronously
        let accepted = acceptCookies page |> Async.RunSynchronously
        match accepted with
        | Some(name) -> printfn $"Cookie-Consent bestätigt via: %s{name}"
        | None -> ()
        page.WaitForTimeoutAsync(1000) |> Async.AwaitTask |> Async.RunSynchronously
        let out = flag "out" (Path.Combine("/tmp", $"browser-{DateTimeOffset.Now.ToUnixTimeMilliseconds()}.png"))
        page.ScreenshotAsync(new() { Path = out; FullPage = has "full" }) |> Async.AwaitTask |> Async.RunSynchronously
        printfn $"Screenshot: %s{out}"
        printfn $"URL final: %s{page.Url}"
        
    | "login" ->
        if String.IsNullOrEmpty(target) then failwith "URL fehlt"
        let env = loadEnv()
        let user = 
            let envUserKey = flag "env-user" ""
            if Map.containsKey envUserKey env then env.[envUserKey] else flag "user" ""
        let pass = 
            let envPassKey = flag "env-pass" ""
            if Map.containsKey envPassKey env then env.[envPassKey] else flag "pass" ""
            
        page.GotoAsync(target, new() { WaitUntil = WaitForSelectorState.DOMContentLoaded; Timeout = 60000.0 }) |> Async.AwaitTask |> Async.RunSynchronously
        page.WaitForTimeoutAsync(2500) |> Async.AwaitTask |> Async.RunSynchronously
        acceptCookies page |> Async.RunSynchronously |> ignore
        
        if not (String.IsNullOrEmpty(user)) then
            let uf = flag "user-field" "input[type=email], input[name=email], input[name=username], input[id*=email i]"
            page.Locator(uf).First.FillAsync(user, new() { Timeout = 8000.0 }) |> Async.AwaitTask |> Async.RunSynchronously
            
        if not (String.IsNullOrEmpty(pass)) then
            let pf = flag "pass-field" "input[type=password]"
            page.Locator(pf).First.FillAsync(pass, new() { Timeout = 8000.0 }) |> Async.AwaitTask |> Async.RunSynchronously
            
        let out = flag "out" (Path.Combine("/tmp", $"login-{DateTimeOffset.Now.ToUnixTimeMilliseconds()}.png"))
        page.ScreenshotAsync(new() { Path = out }) |> Async.AwaitTask |> Async.RunSynchronously
        printfn $"Login-Formular ausgefüllt (user={(if String.IsNullOrEmpty(user) then "-" else "gesetzt")}, pass={(if String.IsNullOrEmpty(pass) then "-" else "gesetzt")}). Screenshot: %s{out}"
        printfn "Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung."
        
    | _ ->
        printfn "Befehle: open <URL> | shot <URL> | login <URL> | state"
        
finally
    context.CloseAsync() |> Async.AwaitTask |> Async.RunSynchronously // Profil (Cookies) bleibt auf Platte erhalten
