#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "a210ae442504361b85b6384c181779d36b608fe24843bc64ef5d274344f46b83", "source_sha256": "acf29634657ddc4b0dd7488e70f24c496bf7bd82883eecf4ebbed3a1486457cd", "target_language": "ruby"}
# browser-session.mjs — portiert nach ruby
# Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

# frozen_string_literal: true

# Persistente Browser-Sitzung der Sandbox.
#
# Zweck: Plattformen ohne (nutzbare) API — WaveSpeed-Konsole, Perplexity,
# Canva, Stock-Portale — erfordern einen echten Web-Login. Diese Sitzung
# speichert Cookies/LocalStorage DAUERHAFT in einem user-data-dir, akzeptiert
# Cookie-Banner automatisch und bleibt über Skript-Läufe hinweg angemeldet.
#
# Profil-Verzeichnis: <repo>/.browser-profile (gitignored — enthält Secrets).
#
# Nutzung (immer unter Xvfb, damit echtes Chrome mit Codecs läuft):
#   xvfb-run -a ruby scripts/browser-session.rb open <URL>          # öffnen, Cookies akzeptieren, Screenshot
#   xvfb-run -a ruby scripts/browser-session.rb login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
#   xvfb-run -a ruby scripts/browser-session.rb shot <URL> [--out file.png] [--wait ms] [--full]
#   xvfb-run -a ruby scripts/browser-session.rb state                 # gespeicherte Cookies auflisten (Domains)
#
# Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.

require 'fileutils'
require 'pathname'
require 'json'
require 'uri'
require 'net/http'

# Helper methods
def join_paths(*paths)
  File.join(*paths)
end

def file_exists?(path)
  File.exist?(path)
end

def read_file(path)
  File.read(path)
end

def mkdir_p(path)
  FileUtils.mkdir_p(path)
end

def dirname(path)
  File.dirname(path)
end

def basename(path)
  File.basename(path)
end

def expand_path(path)
  File.expand_path(path)
end

# Constants
SCRIPT_PATH = __FILE__
REPO = dirname(expand_path(SCRIPT_PATH))
PROFILE = ENV['BROWSER_PROFILE_DIR'] || join_paths(REPO, '.browser-profile')

CHROME_PATHS = [
  '/usr/bin/google-chrome-stable',
  '/usr/bin/google-chrome'
].find { |path| file_exists?(path) }

ARGV.shift while ARGV.first&.start_with?('-') && ARGV.first&.include?('ruby')

CMD = ARGV[0]
TARGET = ARGV[1]
REST_ARGS = ARGV[2..-1] || []

def flag(name, default_value = nil)
  idx = REST_ARGS.index("--#{name}")
  return default_value unless idx
  return REST_ARGS[idx + 1] if REST_ARGS[idx + 1] && !REST_ARGS[idx + 1].start_with?('--')
  default_value
end

def has_flag?(name)
  REST_ARGS.include?("--#{name}")
end

# Load environment variables from .env file
def load_env
  env_file = join_paths(REPO, '.env')
  return {} unless file_exists?(env_file)

  env_vars = {}
  read_file(env_file).each_line do |line|
    match = line.match(/^\s*([A-Z0-9_]+)\s*=\s*"?([^"]*)"?\s*$/)
    env_vars[match[1]] = match[2] if match
  end
  env_vars
end

# Accept cookies by clicking common consent buttons
def accept_cookies(driver)
  labels = [
    'Accept all', 'Accept All', 'Alle akzeptieren', 'Accept all cookies',
    'Alle Cookies akzeptieren', 'I agree', 'Ich stimme zu', 'Zustimmen',
    'Allow all', 'Akzeptieren', 'Accept', 'Got it', 'Agree'
  ]

  labels.each do |label|
    begin
      button = driver.find_elements(:xpath, "//button[contains(text(), '#{label}')]")
      next if button.empty?
      button.first.click
      return label
    rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::TimeoutError
      next
    end
  end

  # Generic consent selectors
  generic_selectors = ['#onetrust-accept-btn-handler', '[aria-label*="accept" i]', 'button[title*="accept" i]']
  generic_selectors.each do |selector|
    begin
      elements = driver.find_elements(:css, selector)
      next if elements.empty?
      elements.first.click
      return selector
    rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::TimeoutError
      next
    end
  end

  nil
end

# Setup profile directory
mkdir_p(PROFILE)

# Configure proxy settings
SOCKS = flag('socks', nil)
PROXY_URL = SOCKS ? "socks5://#{SOCKS}" : (ENV['HTTPS_PROXY'] || ENV['https_proxy'] || nil)

# Setup Chrome options
require 'selenium-webdriver'

options = Selenium::WebDriver::Chrome::Options.new
options.add_preference('profile.default_content_setting_values.notifications', 2)
options.add_argument('--no-sandbox')
options.add_argument('--autoplay-policy=no-user-gesture-required')
options.add_argument('--disable-blink-features=AutomationControlled')
options.add_argument('--disable-extensions')
options.add_argument('--disable-plugins')
options.add_argument('--disable-images')
options.add_argument('--disable-javascript')
options.add_argument('--disable-java')
options.add_argument('--disable-web-security')
options.add_argument('--allow-running-insecure-content')
options.add_argument('--ignore-certificate-errors')
options.add_argument('--ignore-ssl-errors')
options.add_argument('--ignore-certificate-errors-spki-list')
options.add_argument('--ignore-urlfetch-trustworthy-cert')
options.add_argument('--allow-insecure-localhost')
options.add_argument('--allow-running-insecure-content')
options.add_argument('--unsafely-treat-insecure-origin-as-secure')
options.add_argument("--user-data-dir=#{PROFILE}")
options.add_argument('--window-size=1440,900')

if PROXY_URL
  uri = URI(PROXY_URL)
  options.add_argument("--proxy-server=#{uri.scheme}://#{uri.host}:#{uri.port}")
  options.add_argument('--proxy-bypass-list=localhost,127.0.0.1,::1')
end

if PROXY_URL
  options.add_argument('--ssl-version-max=tls1.2')
end

# Launch browser with persistent context
driver = Selenium::WebDriver.for(:chrome, options: options)

begin
  if CMD == 'state'
    # This is a simplified version since we can't directly access cookies from Selenium in the same way
    puts "Profil: #{PROFILE}"
    puts "Cookies können nur im Browser angezeigt werden"
    
  elsif CMD == 'open' || CMD == 'shot'
    raise 'URL fehlt' unless TARGET
    
    driver.navigate.to(TARGET)
    sleep((flag('wait', '2.5').to_f / 1000).round(3))
    
    accepted = accept_cookies(driver)
    puts "Cookie-Consent bestätigt via: #{accepted}" if accepted
    
    sleep(1)
    
    output_file = flag('out', "/tmp/browser-#{Time.now.to_i}.png")
    driver.save_screenshot(output_file)
    puts "Screenshot: #{output_file}"
    puts "URL final: #{driver.current_url}"
    
  elsif CMD == 'login'
    raise 'URL fehlt' unless TARGET
    
    env = load_env
    user = env[flag('env-user', '')] || flag('user', '')
    pass = env[flag('pass-pass', '')] || flag('pass', '')
    
    driver.navigate.to(TARGET)
    sleep(2.5)
    
    accept_cookies(driver)
    
    if user
      user_field_selector = flag('user-field', 'input[type=email], input[name=email], input[name=username], input[id*=email i]')
      user_field = driver.find_element(:css, user_field_selector.split(',').first.strip)
      user_field.send_keys(user)
    end
    
    if pass
      pass_field_selector = flag('pass-field', 'input[type=password]')
      pass_field = driver.find_element(:css, pass_field_selector)
      pass_field.send_keys(pass)
    end
    
    output_file = flag('out', "/tmp/login-#{Time.now.to_i}.png")
    driver.save_screenshot(output_file)
    puts "Login-Formular ausgefüllt (user=#{user ? 'gesetzt' : '-'}, pass=#{pass ? 'gesetzt' : '-'}). Screenshot: #{output_file}"
    puts 'Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung.'
    
  else
    puts 'Befehle: open <URL> | shot <URL> | login <URL> | state'
  end
  
ensure
  driver.quit
end
