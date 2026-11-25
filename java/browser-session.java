// abstraction-provenance: {"artifact_sha256": "381c3417c93a1dcad206f1b68c0614b94f4fda38f39b98fb36bb3680fe67d1c3", "source_sha256": "acf29634657ddc4b0dd7488e70f24c496bf7bd82883eecf4ebbed3a1486457cd", "target_language": "java"}
// browser-session.mjs — portiert nach java
// Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.regex.*;
import org.openqa.selenium.*;
import org.openqa.selenium.chrome.*;
import org.openqa.selenium.support.ui.*;
import io.github.bonigarcia.wdm.WebDriverManager;

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
 *   xvfb-run -a java BrowserSession open <URL>          # öffnen, Cookies akzeptieren, Screenshot
 *   xvfb-run -a java BrowserSession login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
 *   xvfb-run -a java BrowserSession shot <URL> [--out file.png] [--wait ms] [--full]
 *   xvfb-run -a java BrowserSession state                 # gespeicherte Cookies auflisten (Domains)
 *
 * Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.
 */
public class BrowserSession {

    private static final String REPO = Paths.get("").toAbsolutePath().toString();
    private static final String PROFILE = System.getenv().getOrDefault("BROWSER_PROFILE_DIR", 
        Paths.get(REPO, ".browser-profile").toString());
    
    private static WebDriver driver;
    private static String[] args;
    private static Map<String, String> envVars = new HashMap<>();

    public static void main(String[] argv) throws Exception {
        args = argv;
        
        // Profil-Verzeichnis erstellen
        Files.createDirectories(Paths.get(PROFILE));
        
        // .env laden
        loadEnv();
        
        // Chrome-Optionen konfigurieren
        ChromeOptions options = new ChromeOptions();
        options.setExperimentalOption("useAutomationExtension", false);
        options.setExperimentalOption("excludeSwitches", Arrays.asList("enable-automation"));
        
        // Profil-Verzeichnis setzen
        options.addArguments("--user-data-dir=" + PROFILE);
        options.addArguments("--no-sandbox");
        options.addArguments("--autoplay-policy=no-user-gesture-required");
        options.addArguments("--disable-blink-features=AutomationControlled");
        options.addArguments("--window-size=1440,900");
        
        // Proxy konfigurieren
        String socks = flag("socks", null);
        String proxy = socks != null ? "socks5://" + socks : 
            System.getenv().getOrDefault("HTTPS_PROXY", 
                System.getenv().getOrDefault("https_proxy", null));
                
        if (proxy != null) {
            options.addArguments("--proxy-server=" + proxy);
            options.addArguments("--proxy-bypass-list=localhost,127.0.0.1,::1");
        }
        
        // TLS-Einstellungen für MITM-Proxy
        if (has("insecure")) {
            options.addArguments("--ignore-certificate-errors");
            options.addArguments("--ignore-ssl-errors");
        }
        
        if (proxy != null) {
            options.addArguments("--ssl-version-max=tls1.2");
        }
        
        // WebDriver initialisieren
        WebDriverManager.chromedriver().setup();
        driver = new ChromeDriver(options);
        
        try {
            executeCommand();
        } finally {
            if (driver != null) {
                driver.quit();
            }
        }
    }
    
    private static void executeCommand() throws Exception {
        String cmd = argAt(0, "");
        String target = argAt(1, "");
        
        if ("state".equals(cmd)) {
            state();
        } else if ("open".equals(cmd) || "shot".equals(cmd)) {
            if (target.isEmpty()) throw new Exception("URL fehlt");
            shot(target);
        } else if ("login".equals(cmd)) {
            if (target.isEmpty()) throw new Exception("URL fehlt");
            login(target);
        } else {
            System.out.println("Befehle: open <URL> | shot <URL> | login <URL> | state");
        }
    }
    
    private static void state() {
        // In Selenium können wir nicht direkt auf die Cookies des Profils zugreifen
        // Dies ist eine vereinfachte Version
        System.out.println("Profil: " + PROFILE);
        System.out.println("Cookies können nur während aktiver Sitzung abgerufen werden");
    }
    
    private static void shot(String url) throws Exception {
        driver.get(url);
        
        String waitStr = flag("wait", "2500");
        Thread.sleep(Integer.parseInt(waitStr));
        
        String accepted = acceptCookies();
        if (accepted != null) {
            System.out.println("Cookie-Consent bestätigt via: " + accepted);
        }
        
        Thread.sleep(1000);
        
        String outFile = flag("out", "/tmp/browser-" + System.currentTimeMillis() + ".png");
        takeScreenshot(outFile, has("full"));
        System.out.println("Screenshot: " + outFile);
        System.out.println("URL final: " + driver.getCurrentUrl());
    }
    
    private static void login(String url) throws Exception {
        driver.get(url);
        Thread.sleep(2500);
        
        acceptCookies();
        
        String user = envVars.getOrDefault(flag("env-user", ""), flag("user", ""));
        String pass = envVars.getOrDefault(flag("env-pass", ""), flag("pass", ""));
        
        if (!user.isEmpty()) {
            String userField = flag("user-field", "input[type=email], input[name=email], input[name=username], input[id*=email i]");
            WebElement userEl = findElement(By.cssSelector(userField));
            if (userEl != null) {
                userEl.sendKeys(user);
            }
        }
        
        if (!pass.isEmpty()) {
            String passField = flag("pass-field", "input[type=password]");
            WebElement passEl = findElement(By.cssSelector(passField));
            if (passEl != null) {
                passEl.sendKeys(pass);
            }
        }
        
        String outFile = flag("out", "/tmp/login-" + System.currentTimeMillis() + ".png");
        takeScreenshot(outFile);
        System.out.println("Login-Formular ausgefüllt (user=" + (user.isEmpty() ? "-" : "gesetzt") + 
                          ", pass=" + (pass.isEmpty() ? "-" : "gesetzt") + "). Screenshot: " + outFile);
        System.out.println("Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung.");
    }
    
    /** Häufige Cookie-Consent-Buttons klicken (mehrsprachig, best effort). */
    private static String acceptCookies() {
        String[] labels = {
            "Accept all", "Accept All", "Alle akzeptieren", "Accept all cookies",
            "Alle Cookies akzeptieren", "I agree", "Ich stimme zu", "Zustimmen",
            "Allow all", "Akzeptieren", "Accept", "Got it", "Agree"
        };
        
        for (String label : labels) {
            try {
                WebElement btn = driver.findElement(By.xpath("//button[contains(text(),'" + label + "')]"));
                if (btn.isDisplayed()) {
                    btn.click();
                    return label;
                }
            } catch (Exception e) {
                // weiter
            }
            
            try {
                List<WebElement> buttons = driver.findElements(By.tagName("button"));
                for (WebElement button : buttons) {
                    if (button.getText().contains(label)) {
                        if (button.isDisplayed()) {
                            button.click();
                            return label;
                        }
                    }
                }
            } catch (Exception e) {
                // weiter
            }
        }
        
        // Generische Consent-IDs
        String[] selectors = {"#onetrust-accept-btn-handler", "[aria-label*='accept' i]", "button[title*='accept' i]"};
        for (String selector : selectors) {
            try {
                WebElement el = driver.findElement(By.cssSelector(selector));
                if (el.isDisplayed()) {
                    el.click();
                    return selector;
                }
            } catch (Exception e) {
                // weiter
            }
        }
        
        return null;
    }
    
    private static WebElement findElement(By by) {
        try {
            WebDriverWait wait = new WebDriverWait(driver, 8);
            return wait.until(ExpectedConditions.visibilityOfElementLocated(by));
        } catch (Exception e) {
            return null;
        }
    }
    
    private static void takeScreenshot(String filename) throws Exception {
        takeScreenshot(filename, false);
    }
    
    private static void takeScreenshot(String filename, boolean fullPage) throws Exception {
        File screenshot = ((TakesScreenshot) driver).getScreenshotAs(OutputType.FILE);
        Files.copy(screenshot.toPath(), Paths.get(filename), StandardCopyOption.REPLACE_EXISTING);
    }
    
    private static void loadEnv() {
        Path envFile = Paths.get(REPO, ".env");
        if (!Files.exists(envFile)) return;
        
        try {
            List<String> lines = Files.readAllLines(envFile);
            for (String line : lines) {
                Matcher m = Pattern.compile("^\\s*([A-Z0-9_]+)\\s*=\\s*\"?([^\"]*)\"?\\s*$").matcher(line);
                if (m.matches()) {
                    envVars.put(m.group(1), m.group(2));
                }
            }
        } catch (IOException e) {
            // ignorieren
        }
    }
    
    private static String flag(String name, String defaultValue) {
        for (int i = 0; i < args.length - 1; i++) {
            if (("--" + name).equals(args[i])) {
                return args[i + 1];
            }
        }
        return defaultValue;
    }
    
    private static boolean has(String name) {
        return Arrays.asList(args).contains("--" + name);
    }
    
    private static String argAt(int index, String defaultValue) {
        int actualIndex = index + 2; // Skip "java BrowserSession"
        if (actualIndex < args.length) {
            return args[actualIndex];
        }
        return defaultValue;
    }
}
