// abstraction-provenance: {"artifact_sha256": "309a49ae89d0c2fce6ae2c72db8945d715406efceb074b7e456cfc106293a1fc", "source_sha256": "acf29634657ddc4b0dd7488e70f24c496bf7bd82883eecf4ebbed3a1486457cd", "target_language": "go"}
// browser-session.mjs — portiert nach go
// Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"bufio"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/go-rod/rod"
	"github.com/go-rod/rod/lib/launcher"
	"github.com/go-rod/rod/lib/proto"
)

var (
	REPO    string
	PROFILE string
	CHROME  string
)

func init() {
	ex, err := os.Executable()
	if err != nil {
		log.Fatal(err)
	}
	REPO = filepath.Join(filepath.Dir(ex), "..")
	PROFILE = os.Getenv("BROWSER_PROFILE_DIR")
	if PROFILE == "" {
		PROFILE = filepath.Join(REPO, ".browser-profile")
	}

	chromePaths := []string{"/usr/bin/google-chrome-stable", "/usr/bin/google-chrome"}
	for _, path := range chromePaths {
		if _, err := os.Stat(path); err == nil {
			CHROME = path
			break
		}
	}
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Befehle: open <URL> | shot <URL> | login <URL> | state")
		return
	}

	cmd := os.Args[1]
	var target string
	var rest []string
	if len(os.Args) > 2 {
		target = os.Args[2]
		rest = os.Args[3:]
	}

	flag := func(name, def string) string {
		for i, arg := range rest {
			if arg == "--"+name && i+1 < len(rest) {
				return rest[i+1]
			}
		}
		return def
	}

	has := func(name string) bool {
		for _, arg := range rest {
			if arg == "--"+name {
				return true
			}
		}
		return false
	}

	os.MkdirAll(PROFILE, 0755)

	SOCKS := flag("socks", "")
	var PROXY string
	if SOCKS != "" {
		PROXY = "socks5://" + SOCKS
	} else {
		proxyEnv := os.Getenv("HTTPS_PROXY")
		if proxyEnv == "" {
			proxyEnv = os.Getenv("https_proxy")
		}
		PROXY = proxyEnv
	}

	l := launcher.New().
		Set("user-data-dir", PROFILE).
		Set("no-sandbox").
		Set("autoplay-policy", "no-user-gesture-required").
		Set("disable-blink-features", "AutomationControlled")

	if CHROME != "" {
		l.Bin(CHROME)
	}

	if PROXY != "" {
		l.Set("proxy-server", PROXY)
	}

	if PROXY != "" && !has("insecure") {
		l.Set("ssl-version-max", "tls1.2")
	}

	browser := rod.New().ControlURL(l.MustLaunch()).MustConnect()
	defer browser.MustClose()

	page := browser.MustPages().First()
	if page == nil {
		page = browser.MustPage("")
	}

	page.MustSetViewport(1440, 900, 1, false)

	switch cmd {
	case "state":
		cookies, err := page.Cookies()
		if err != nil {
			log.Fatal(err)
		}
		domainMap := make(map[string]bool)
		for _, cookie := range cookies {
			domainMap[cookie.Domain] = true
		}
		domains := make([]string, 0, len(domainMap))
		for domain := range domainMap {
			domains = append(domains, domain)
		}
		fmt.Printf("Profil: %s\n", PROFILE)
		fmt.Printf("%d Cookies über %d Domains:\n", len(cookies), len(domains))
		for _, domain := range domains {
			fmt.Printf("  %s\n", domain)
		}
	case "open", "shot":
		if target == "" {
			log.Fatal("URL fehlt")
		}
		page.MustNavigate(target).MustWaitLoad()
		waitTime := parseInt(flag("wait", "2500"))
		time.Sleep(time.Duration(waitTime) * time.Millisecond)
		accepted := acceptCookies(page)
		if accepted != "" {
			fmt.Printf("Cookie-Consent bestätigt via: %s\n", accepted)
		}
		time.Sleep(1 * time.Second)
		out := flag("out", filepath.Join("/tmp", fmt.Sprintf("browser-%d.png", time.Now().Unix())))
		page.MustScreenshot(out)
		if has("full") {
			page.MustScreenshotFullPage(out)
		}
		fmt.Printf("Screenshot: %s\n", out)
		fmt.Printf("URL final: %s\n", page.MustInfo().URL)
	case "login":
		if target == "" {
			log.Fatal("URL fehlt")
		}
		env := loadEnv()
		user := env[flag("env-user", "")] 
		if user == "" {
			user = flag("user", "")
		}
		pass := env[flag("env-pass", "")]
		if pass == "" {
			pass = flag("pass", "")
		}
		page.MustNavigate(target).MustWaitLoad()
		time.Sleep(2500 * time.Millisecond)
		acceptCookies(page)
		if user != "" {
			uf := flag("user-field", "input[type=email], input[name=email], input[name=username], input[id*=email i]")
			page.MustElement(uf).MustInput(user)
		}
		if pass != "" {
			pf := flag("pass-field", "input[type=password]")
			page.MustElement(pf).MustInput(pass)
		}
		out := flag("out", filepath.Join("/tmp", fmt.Sprintf("login-%d.png", time.Now().Unix())))
		page.MustScreenshot(out)
		userStatus := "-"
		if user != "" {
			userStatus = "gesetzt"
		}
		passStatus := "-"
		if pass != "" {
			passStatus = "gesetzt"
		}
		fmt.Printf("Login-Formular ausgefüllt (user=%s, pass=%s). Screenshot: %s\n", userStatus, passStatus, out)
		fmt.Println("Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung.")
	default:
		fmt.Println("Befehle: open <URL> | shot <URL> | login <URL> | state")
	}
}

func acceptCookies(page *rod.Page) string {
	labels := []string{
		"Accept all", "Accept All", "Alle akzeptieren", "Accept all cookies",
		"Alle Cookies akzeptieren", "I agree", "Ich stimme zu", "Zustimmen",
		"Allow all", "Akzeptieren", "Accept", "Got it", "Agree",
	}
	for _, name := range labels {
		btn := page.RodPage().ElementByJS(page.Sleeper(), fmt.Sprintf(`document.querySelector('[role="button"][aria-label*="%s" i]') || document.querySelector('button:contains("%s")')`, name, name))
		if btn != nil {
			err := btn.Click(proto.InputDispatchMouseEventButtonTypeLeft, 1)
			if err == nil {
				return name
			}
		}
	}
	selectors := []string{"#onetrust-accept-btn-handler", "[aria-label*='accept' i]", "button[title*='accept' i]"}
	for _, sel := range selectors {
		el := page.MustElement(sel)
		if el != nil {
			err := el.Click(proto.InputDispatchMouseEventButtonTypeLeft, 1)
			if err == nil {
				return sel
			}
		}
	}
	return ""
}

func loadEnv() map[string]string {
	envFile := filepath.Join(REPO, ".env")
	if _, err := os.Stat(envFile); os.IsNotExist(err) {
		return make(map[string]string)
	}
	content, err := ioutil.ReadFile(envFile)
	if err != nil {
		log.Fatal(err)
	}
	lines := strings.Split(string(content), "\n")
	env := make(map[string]string)
	re := regexp.MustCompile(`^\s*([A-Z0-9_]+)\s*=\s*"?([^"]*)"?\s*$`)
	for _, line := range lines {
		matches := re.FindStringSubmatch(line)
		if len(matches) > 2 {
			env[matches[1]] = matches[2]
		}
	}
	return env
}

func parseInt(s string, def int) int {
	i, err := strconv.Atoi(s)
	if err != nil {
		return def
	}
	return i
}
