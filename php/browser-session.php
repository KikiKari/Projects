<?php
// abstraction-provenance: {"artifact_sha256": "2656a21df0cbdfbeb640a9b2b95e8ed4b5c9df58b6e30c9b5c511313d773d6d5", "source_sha256": "acf29634657ddc4b0dd7488e70f24c496bf7bd82883eecf4ebbed3a1486457cd", "target_language": "php"}
// browser-session.mjs — portiert nach php
// Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py
/**
 * Persistente Browser-Sitzung der Sandbox.
 *
 * Zweck: Plattformen ohne (nutzbare) API — WaveSpeed-Konsole, Perplexity,
 * Canva, Stock-Portale — erfordern einen echten Web-Login. Diese Sitzung
 * speichert Cookies/LocalStorage DAUERHAFT in einem user-data-dir, akzeptiert
 * Cookie-Banner automatisch und bleibt über Skript-Läufe hinweg angemeldet.
 *
 * Profil-Verzeichnis: <repo>/.browser-profile (gitignored — enthält Secrets).
 *
 * Nutzung (immer unter Xvfb, damit echtes Chrome mit Codecs läuft):
 *   xvfb-run -a php scripts/browser-session.php open <URL>          # öffnen, Cookies akzeptieren, Screenshot
 *   xvfb-run -a php scripts/browser-session.php login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
 *   xvfb-run -a php scripts/browser-session.php shot <URL> [--out file.png] [--wait ms] [--full]
 *   xvfb-run -a php scripts/browser-session.php state                 # gespeicherte Cookies auflisten (Domains)
 *
 * Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.
 */

// Konfiguration
$REPO = dirname(__DIR__);
$PROFILE = getenv('BROWSER_PROFILE_DIR') ?: "$REPO/.browser-profile";
$CHROME = array_filter([
    "/usr/bin/google-chrome-stable",
    "/usr/bin/google-chrome"
], 'file_exists')[0] ?? null;

// Argumente parsen
$args = array_slice($argv, 1);
$cmd = $args[0] ?? '';
$target = $args[1] ?? null;
$rest = array_slice($args, 2);

// Hilfsfunktionen
function flag($n, $d) {
    global $rest;
    $key = array_search("--$n", $rest);
    return ($key !== false && isset($rest[$key + 1])) ? $rest[$key + 1] : $d;
}

function has($n) {
    global $rest;
    return in_array("--$n", $rest);
}

// .env laden (nur für login-Credentials; nichts wird geloggt)
function loadEnv() {
    global $REPO;
    $f = "$REPO/.env";
    if (!file_exists($f)) return [];
    $lines = file($f, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $out = [];
    foreach ($lines as $line) {
        if (preg_match('/^\s*([A-Z0-9_]+)\s*=\s*"?(.*?)"?\s*$/', $line, $matches)) {
            $out[$matches[1]] = $matches[2];
        }
    }
    return $out;
}

/** Häufige Cookie-Consent-Buttons klicken (mehrsprachig, best effort). */
function acceptCookies($page) {
    $labels = [
        "Accept all", "Accept All", "Alle akzeptieren", "Accept all cookies",
        "Alle Cookies akzeptieren", "I agree", "Ich stimme zu", "Zustimmen",
        "Allow all", "Akzeptieren", "Accept", "Got it", "Agree",
    ];
    foreach ($labels as $name) {
        try {
            $btn = $page->querySelector("button[aria-label*='$name'], button:contains('$name')");
            if ($btn && $btn->isDisplayed()) {
                $btn->click();
                return $name;
            }
        } catch (Exception $e) { /* weiter */ }
    }
    // Generische Consent-IDs
    $selectors = ["#onetrust-accept-btn-handler", "[aria-label*='accept' i]", "button[title*='accept' i]"];
    foreach ($selectors as $sel) {
        try {
            $el = $page->querySelector($sel);
            if ($el && $el->isDisplayed()) {
                $el->click();
                return $sel;
            }
        } catch (Exception $e) { /* weiter */ }
    }
    return null;
}

// Verzeichnis erstellen
if (!is_dir($PROFILE)) {
    mkdir($PROFILE, 0755, true);
}

// Proxy-Einstellungen
$SOCKS = flag("socks", null);
$PROXY = $SOCKS 
    ? "socks5://$SOCKS"
    : (getenv('HTTPS_PROXY') ?: getenv('https_proxy') ?: null);

// Chrome-Optionen konstruieren
$options = [
    '--no-sandbox',
    '--autoplay-policy=no-user-gesture-required',
    '--disable-blink-features=AutomationControlled',
];

if ($PROXY) {
    $options[] = '--proxy-server=' . $PROXY;
    $options[] = '--proxy-bypass-list=localhost,127.0.0.1,::1';
    $options[] = '--ssl-version-max=tls1.2';
}

// Starte Chrome mit Playwright (via Puppeteer)
require_once 'vendor/autoload.php';

use HeadlessChromium\BrowserFactory;
use HeadlessChromium\Exception\OperationTimedOut;

$browserFactory = new BrowserFactory($CHROME);

$browser = $browserFactory->createBrowser([
    'headless' => false,
    'userDataDir' => $PROFILE,
    'windowSize' => [1440, 900],
    'customFlags' => $options
]);

$page = $browser->createPage();

try {
    if ($cmd === "state") {
        // In PHP können wir keine direkte Abfrage der Cookies machen, daher simulieren wir dies
        echo "Profil: $PROFILE\n";
        echo "Cookies können nur im Browser-Profil manuell eingesehen werden.\n";
    } elseif ($cmd === "open" || $cmd === "shot") {
        if (!$target) throw new Exception("URL fehlt");
        $page->navigate($target)->waitForNavigation('domcontentloaded', 60000);
        usleep((int)(flag("wait", "2500")) * 1000);
        $accepted = acceptCookies($page);
        if ($accepted) echo "Cookie-Consent bestätigt via: $accepted\n";
        sleep(1);
        $out = flag("out", "/tmp/browser-" . time() . ".png");
        $page->screenshot(['path' => $out, 'fullPage' => has("full")]);
        echo "Screenshot: $out\n";
        echo "URL final: " . $page->getCurrentUrl() . "\n";
    } elseif ($cmd === "login") {
        if (!$target) throw new Exception("URL fehlt");
        $env = loadEnv();
        $user = $env[flag("env-user", "")] ?? flag("user", "");
        $pass = $env[flag("env-pass", "")] ?? flag("pass", "");
        $page->navigate($target)->waitForNavigation('domcontentloaded', 60000);
        sleep(2);
        acceptCookies($page);
        if ($user) {
            $uf = flag("user-field", "input[type=email], input[name=email], input[name=username], input[id*=email i]");
            $page->querySelector($uf)->type($user);
        }
        if ($pass) {
            $pf = flag("pass-field", "input[type=password]");
            $page->querySelector($pf)->type($pass);
        }
        $out = flag("out", "/tmp/login-" . time() . ".png");
        $page->screenshot(['path' => $out]);
        echo "Login-Formular ausgefüllt (user=" . ($user ? "gesetzt" : "-") . ", pass=" . ($pass ? "gesetzt" : "-") . "). Screenshot: $out\n";
        echo "Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung.\n";
    } else {
        echo "Befehle: open <URL> | shot <URL> | login <URL> | state\n";
    }
} finally {
    $browser->close(); // Profil (Cookies) bleibt auf Platte erhalten
}
?>
