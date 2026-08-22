#!/usr/bin/env pwsh
# test_extension.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_extension.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_extension.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_extension.cjs
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

# Define paths
$scriptDir = $PSScriptRoot
$root = Join-Path $scriptDir ".."
$extension = Join-Path $root "browser-extension"
$manifestPath = Join-Path $extension "manifest.json"
$mobileBridgePath = Join-Path $root "mobile-shared" "webview-bridge.js"

# Load manifest
$manifest = Get-Content $manifestPath | ConvertFrom-Json
$corePath = Join-Path $extension "content-core.js"
$protoPath = Join-Path $extension "proto-main.js"

# Load core and proto modules
$core = & $corePath
$proto = & $protoPath

# Load mobile bridge
$mobileBridge = Get-Content $mobileBridgePath -Raw

function Concat {
    param([byte[][]]$Chunks)
    
    $size = ($Chunks | Measure-Object -Property Length -Sum).Sum
    $out = New-Object byte[] $size
    $offset = 0
    
    foreach ($chunk in $Chunks) {
        [Array]::Copy($chunk, 0, $out, $offset, $chunk.Length)
        $offset += $chunk.Length
    }
    
    return $out
}

function Varint {
    param([long]$Value)
    
    $bytes = @()
    $current = $Value
    
    do {
        $byte = $current -band 0x7f
        $current = $current -shr 7
        
        if ($current -gt 0) {
            $byte = $byte -bor 0x80
        }
        
        $bytes += $byte
    } while ($current -gt 0)
    
    return [byte[]]$bytes
}

function BytesField {
    param([int]$Number, [object]$Value)
    
    $body = $null
    if ($Value -is [string]) {
        $body = [System.Text.Encoding]::UTF8.GetBytes($Value)
    } else {
        $body = $Value
    }
    
    $fieldNumber = [bigint]$Number -shl 3 -bor 2
    return Concat @(Varint $fieldNumber.ToInt64($null)), @(Varint $body.Length), @($body)
}

function IntField {
    param([int]$Number, [long]$Value)
    
    $fieldNumber = [bigint]$Number -shl 3
    return Concat @(Varint $fieldNumber.ToInt64($null)), @(Varint $Value)
}

# Assertions
if ($manifest.manifest_version -ne 3) { throw "Manifest version assertion failed" }
if ($manifest.version -ne "0.8.0") { throw "Version assertion failed" }
if (-not $manifest.permissions.Contains("sidePanel")) { throw "sidePanel permission missing" }
if (-not $manifest.permissions.Contains("webRequest")) { throw "webRequest permission missing" }
if (-not $manifest.permissions.Contains("tabCapture")) { throw "tabCapture permission missing" }
if (-not $manifest.host_permissions.Contains("http://127.0.0.1/*")) { throw "host_permission http://127.0.0.1/* missing" }
if (-not $manifest.host_permissions.Contains("http://localhost/*")) { throw "host_permission http://localhost/* missing" }
if ($manifest.permissions.Contains("cookies")) { throw "cookies permission should not be present" }
if ($manifest.permissions.Contains("webRequestBlocking")) { throw "webRequestBlocking permission should not be present" }
if ($manifest.permissions.Contains("nativeMessaging")) { throw "nativeMessaging permission should not be present" }
if ($manifest.content_scripts[0].js[0] -ne "vendor-mpegts.js") { throw "vendor-mpegts.js not first content script" }

$mpegtsVendorPath = Join-Path $extension "vendor-mpegts.js"
$mpegtsLicensePath = Join-Path $extension "vendor-mpegts.LICENSE.txt"
$mpegtsNoticePath = Join-Path $extension "vendor-mpegts.NOTICE.md"

if (-not (Test-Path $mpegtsVendorPath)) { throw "vendor-mpegts.js missing" }
if (-not (Test-Path $mpegtsLicensePath)) { throw "vendor-mpegts.LICENSE.txt missing" }
if (-not (Test-Path $mpegtsNoticePath)) { throw "vendor-mpegts.NOTICE.md missing" }

$mpegtsContent = Get-Content $mpegtsVendorPath -Encoding Byte
$hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($mpegtsContent)
$hashHex = -join ($hash | ForEach-Object { "{0:X2}" -f $_ })
if ($hashHex -ne "0786F9AF6780822FF29240259A73B07ED7BC479BC44966E49418DD38213B8064") { throw "vendor-mpegts.js hash mismatch" }

if (-not $mobileBridge.Contains('location.hostname !== "www.tiktok.com"')) { throw "mobileBridge location check missing" }
if ($mobileBridge.Contains("document.cookie")) { throw "mobileBridge contains document.cookie" }
if (-not $mobileBridge.Contains("QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400")) { throw "QUICK_RECOVER_RELOAD_COOLDOWN_MS missing" }
if (-not $mobileBridge.Contains('"set-auto-reconnect"')) { throw "set-auto-reconnect missing" }
if (-not $mobileBridge.Contains('"set-limiter"')) { throw "set-limiter missing" }

foreach ($relative in @(
    $manifest.background.service_worker,
    $manifest.side_panel.default_path
) + ($manifest.content_scripts | ForEach-Object { $_.js })) {
    $fullPath = Join-Path $extension $relative
    if (-not (Test-Path $fullPath)) { throw "Missing manifest file: $relative" }
}

$scripts = Get-ChildItem $extension -Filter "*.js" | ForEach-Object { $_.Name }
foreach ($name in $scripts) {
    $source = Get-Content (Join-Path $extension $name) -Raw
    try {
        $null = [System.Management.Automation.Language.Parser]::ParseInput($source, [ref]$null, [ref]$null)
    } catch {
        throw "$name failed to parse: $_"
    }
    
    if ($source -match '\beval\s*\(') { throw "$name contains eval()" }
    if ($source -match 'new\s+Function\s*\(') { throw "$name contains new Function()" }
    if ($source -match '\.innerHTML\s*=') { throw "$name assigns innerHTML" }
}

# Test metadata inspection
$metadata = @{
    room = @{
        caption_info = @{ open = $true; support_lang = @("de", "en"); show_type = 1 }
        stream_data = '{"pull":"https:\/\/pull-flv-f77.example.tiktokcdn.com\/stage\/stream_hd.flv?expire=1\u0026sign=abc","hls":"https:\/\/pull-hls.example.tiktokcdn-eu.com\/stage\/stream_720p.m3u8?sign=xyz"}'
    }
}

$inspected = $core.inspectMetadata($metadata)
if ($inspected.captionInfo.present -ne $true) { throw "captionInfo.present should be true" }
if ($inspected.captionInfo.open -ne $true) { throw "captionInfo.open should be true" }
if (-not (Compare-Object $inspected.captionInfo.supportLang @("de", "en"))) { throw "captionInfo.supportLang mismatch" }
if ($inspected.media.Count -ne 2) { throw "media count should be 2" }
if (-not ($inspected.media | Where-Object { $_.protocol -eq "FLV" -and $_.quality -eq "HD" })) { throw "FLV HD media missing" }
if (-not ($inspected.media | Where-Object { $_.protocol -eq "HLS" -and $_.quality -eq "720p" })) { throw "HLS 720p media missing" }

if ($core.classifyMediaUrl("https://evil.example/stream.flv") -ne $null) { throw "classifyMediaUrl should return null for evil URL" }
if ($core.QUALITY_LABELS.auto -ne "Automatisch") { throw "QUALITY_LABELS.auto mismatch" }
if ($core.sanitizeChatText("Hallo 😊 Welt ❤️") -ne "Hallo Welt") { throw "sanitizeChatText mismatch" }
if ($core.sanitizeChatText("@Nutzer 👍🏽 bleibt hier") -ne "@Nutzer bleibt hier") { throw "sanitizeChatText with skin tone mismatch" }
if ($core.wordCount("Hallo 😊 schöne Welt") -ne 3) { throw "wordCount mismatch" }
if ($core.teamSuffixCandidate("Miimii tmm") -ne "tmm") { throw "teamSuffixCandidate mismatch 1" }
if ($core.teamSuffixCandidate("Ben") -ne "") { throw "teamSuffixCandidate mismatch 2" }
if ($core.teamSuffixCandidate("das ist gut") -ne "gut") { throw "teamSuffixCandidate mismatch 3" }
if ($core.contentHasToken("@Honey tmm wo is mein Tee?", "tmm") -ne $true) { throw "contentHasToken mismatch" }
if ($core.stripTeamTag("@Honey tmm wo is mein Tee?", "tmm") -ne "@Honey wo is mein Tee?") { throw "stripTeamTag mismatch 1" }
if ($core.stripTeamTag("das ist gut", "tmm") -ne "das ist gut") { throw "stripTeamTag mismatch 2" }
if ($core.shortenNickname("Anja Schaarschmidt89") -ne "Anja") { throw "shortenNickname mismatch 1" }
if ($core.shortenNickname("Team Kimm") -ne "Team Kimm") { throw "shortenNickname mismatch 2" }
if ($core.shortenNickname("Blitzerbiest") -ne "Blitzerbiest") { throw "shortenNickname mismatch 3" }
if ($core.shortenNickname("Traumtänzer.der.Nächte") -ne "Traumtänzer") { throw "shortenNickname mismatch 4" }
if ($core.shortenNickname("Vanny_GioPrimetv") -ne "Vanny") { throw "shortenNickname mismatch 5" }
if ($core.shortenNickname("Die Löwin") -ne "Löwin") { throw "shortenNickname mismatch 6" }
if ($core.shortenNickname("liane15") -ne "liane") { throw "shortenNickname mismatch 7" }
if ($core.shortenNickname("MKU Maskenaufsicht") -ne "Maskenaufsicht") { throw "shortenNickname mismatch 8" }
if ($core.shortenNickname("Butterfly 004") -ne "Butterfly") { throw "shortenNickname mismatch 9" }
if ($core.spokenNickname("user572838499281727393816181") -ne "user572") { throw "spokenNickname mismatch 1" }
if ($core.spokenNickname("Rebecca № 2 💕") -ne "Rebecca") { throw "spokenNickname mismatch 2" }
if ($core.collapseLaughter("hahahahahahhhhahhhaaaa Gott du Plemmi") -ne "haha Gott du Plemmi") { throw "collapseLaughter mismatch" }
if ($core.resolveSpeechLanguage("auto", "de") -ne "de-DE") { throw "resolveSpeechLanguage mismatch 1" }
if ($core.resolveSpeechLanguage("en-US", "de") -ne "en-US") { throw "resolveSpeechLanguage mismatch 2" }
if ($core.limiterStrengthToDbfs(0) -ne -4) { throw "limiterStrengthToDbfs mismatch 1" }
if ($core.limiterStrengthToDbfs(100) -ne -30) { throw "limiterStrengthToDbfs mismatch 2" }
if ($core.limiterDbfsToStrength(-30) -ne 100) { throw "limiterDbfsToStrength mismatch" }
if ($core.limiterMakeupCompensation(-30, 20) -ge $core.limiterMakeupCompensation(-10, 20)) { throw "limiterMakeupCompensation compensation mismatch" }

$text1 = $core.composeSpeechText(@{ author = "Miimii tmm"; content = "@Stivinho danke" }, @{ teamTag = "tmm" })
if ($text1 -ne "Miimii sagt zu Stivinho danke") { throw "composeSpeechText mismatch 1" }

$text2 = $core.composeSpeechText(@{ author = "Blitzerbiest"; content = "@Honey tmm wo is mein Tee ?" }, @{ teamTag = "tmm" })
if ($text2 -ne "Blitzerbiest fragt Honey wo is mein Tee") { throw "composeSpeechText mismatch 2" }

$text3 = $core.composeSpeechText(@{ author = "Miimii"; content = "@ Stivinho danke" }, @{ speakNames = $false })
if ($text3 -ne "Stivinho danke") { throw "composeSpeechText mismatch 3" }

$text4 = $core.composeSpeechText(@{ author = "Anja Schaarschmidt89"; content = "Guten Morgen" }, @{ shortenNames = $true })
if ($text4 -ne "Anja sagt Guten Morgen") { throw "composeSpeechText mismatch 4" }

$text5 = $core.composeSpeechText(@{ author = "Mia"; content = "Hallo @" })
if ($text5 -ne "Mia sagt Hallo @") { throw "composeSpeechText mismatch 5" }

$text6 = $core.gameEventSpeech(@{ rawText = "Jacky hat 1 Boosterhandschuh gesendet" })
if ($text6 -ne "Booster wurde gesetzt") { throw "gameEventSpeech mismatch 1" }

$text7 = $core.gameEventSpeech(@{ rawText = "Jacky hat Rose gesendet x 1" })
if ($text7 -ne "") { throw "gameEventSpeech mismatch 2" }

$text8 = $core.composeSpeechText(@{ author = "System"; content = "Booster wurde gesetzt"; systemSpeechText = "Booster wurde gesetzt" })
if ($text8 -ne "Booster wurde gesetzt") { throw "composeSpeechText mismatch 6" }

$filter1 = $core.shouldFilterGameModeSpeech(
    @{ author = "A"; content = "Jacky"; receivedAtUtc = "2026-07-26T10:00:10.000Z" },
    @{ jacky = @{ name = "🫶Jacky🫶"; displayId = "jacky" } },
    @(
        @{ content = "Jacky"; receivedAtUtc = "2026-07-26T10:00:00.000Z" },
        @{ content = "🫶 Jacky 🫶"; receivedAtUtc = "2026-07-26T10:00:05.000Z" }
    )
)
if ($filter1 -ne $true) { throw "shouldFilterGameModeSpeech mismatch 1" }

$filter2 = $core.shouldFilterGameModeSpeech(
    @{ author = "A"; content = "@Jacky danke"; receivedAtUtc = "2026-07-26T10:00:10.000Z" },
    @{ jacky = @{ name = "Jacky"; displayId = "jacky" } },
    @(@{ content = "@Jacky danke"; receivedAtUtc = "2026-07-26T10:00:05.000Z" })
)
if ($filter2 -ne $false) { throw "shouldFilterGameModeSpeech mismatch 2" }

$text9 = $core.composeSpeechText(@{ author = "user572838499281727393816181"; content = "hahahahahahhhhahhhaaaa bald" })
if ($text9 -ne "user572 sagt haha bald") { throw "composeSpeechText mismatch 7" }

$text10 = $core.composeSpeechText(@{ author = "deroy"; content = "@user572838499281727393816181 bald bist du nur noch ein sohn" })
if ($text10 -ne "deroy sagt zu user572 bald bist du nur noch ein sohn") { throw "composeSpeechText mismatch 8" }

$text11 = $core.composeSpeechText(@{ author = "Rebecca № 2 💕"; content = "@Vanny_GioPrimetv hallo" }, @{ shortenNames = $true })
if ($text11 -ne "Rebecca sagt zu Vanny hallo") { throw "composeSpeechText mismatch 9" }

$team = $core.accumulateTeamEvidence(@{}, "Miimii tmm", "Teilt den Stream", @())
if ($team.teamTag -ne "") { throw "accumulateTeamEvidence mismatch 1" }

$team = $core.accumulateTeamEvidence($team.evidence, "Honey tmm", "wo ist mein Tee?", @("Teilt den Stream"))
if ($team.teamTag -ne "tmm") { throw "accumulateTeamEvidence mismatch 2" }

$team = $core.accumulateTeamEvidence(@{}, "Miimii tmm", "danke", @())
$team = $core.accumulateTeamEvidence($team.evidence, "Stivinho", "tmm hilft", @("danke"))
if ($team.teamTag -ne "tmm") { throw "accumulateTeamEvidence mismatch 3" }

if ($core.accumulateTeamEvidence(@{}, "Miimii tmm", "tmm danke", @()).teamTag -ne "tmm") { throw "accumulateTeamEvidence mismatch 4" }
if ($core.accumulateTeamEvidence(@{}, "Ben", "Ben ist da", @()).teamTag -ne "") { throw "accumulateTeamEvidence mismatch 5" }

if ($core.streamIdentityChanged(@{ handle = "demo"; roomId = "1" }, @{ handle = "demo"; roomId = "1" }) -ne $false) { throw "streamIdentityChanged mismatch 1" }
if ($core.streamIdentityChanged(@{ handle = "demo"; roomId = "1" }, @{ handle = "demo"; roomId = "2" }) -ne $true) { throw "streamIdentityChanged mismatch 2" }
if ($core.streamIdentityChanged(@{ handle = "demo"; roomId = "" }, @{ handle = "other"; roomId = "" }) -ne $true) { throw "streamIdentityChanged mismatch 3" }

if ($core.liveHandleFromUrl("https://www.tiktok.com/@Demo/live") -ne "demo") { throw "liveHandleFromUrl mismatch 1" }
if ($core.liveHandleFromUrl("https://www.tiktok.com/embed/live/@Other") -ne "other") { throw "liveHandleFromUrl mismatch 2" }
if ($core.liveHandleFromUrl("https://www.tiktok.com/@demo") -ne "") { throw "liveHandleFromUrl mismatch 3" }
if ($core.liveHandleFromUrl("not a url") -ne "") { throw "liveHandleFromUrl mismatch 4" }

if ($core.parseCompactCount("3,231") -ne 3231) { throw "parseCompactCount mismatch 1" }
if ($core.parseCompactCount("3.231") -ne 3231) { throw "parseCompactCount mismatch 2" }
if ($core.parseCompactCount("3.2K") -ne 3200) { throw "parseCompactCount mismatch 3" }
if ($core.parseCompactCount("1,1M") -ne 1100000) { throw "parseCompactCount mismatch 4" }
if ($core.parseCompactCount("nicht verfügbar") -ne $null) { throw "parseCompactCount mismatch 5" }

$recommendationItems = $core.dedupeRecommendations(@(
    @{ handle = "@Alpha"; displayName = ""; title = "Erster Stream"; viewerCount = $null; url = "https://www.tiktok.com/@alpha/live"; position = 1 }
    @{ handle = "alpha"; displayName = "Alpha Live"; viewerCount = 123; viewerLabel = "123"; position = 2 }
    @{ handle = "Beta"; displayName = "Beta"; viewerCount = 500; url = "https://www.tiktok.com/@beta/live"; position = 3 }
    @{ handle = "gamma"; displayName = "Gamma"; viewerCount = $null; url = "https://www.tiktok.com/@gamma/live"; position = 2 }
))

if ($recommendationItems.Count -ne 3) { throw "dedupeRecommendations count mismatch" }
if ($recommendationItems[0].handle -ne "alpha") { throw "dedupeRecommendations order mismatch 1" }
if ($recommendationItems[0].displayName -ne "Alpha Live") { throw "dedupeRecommendations displayName mismatch" }
if ($recommendationItems[0].viewerCount -ne 123) { throw "dedupeRecommendations viewerCount mismatch" }

$sortedHandles = $core.sortRecommendations($recommendationItems) | ForEach-Object { $_.handle }
if (($sortedHandles -join ",") -ne "alpha,gamma,beta") { throw "sortRecommendations default sort mismatch" }

$sortedByViewers = $core.sortRecommendations($recommendationItems, "viewers") | ForEach-Object { $_.handle }
if (($sortedByViewers -join ",") -ne "beta,alpha,gamma") { throw "sortRecommendations viewers sort mismatch" }

if ($core.sameParticipant(@{ name = "Anja Schaarschmidt89" }, @{ nickname = "Anja Schaarschmidt89" }) -ne $true) { throw "sameParticipant mismatch 1" }
if ($core.sameParticipant(@{ userId = "42"; name = "Anja" }, @{ userId = "42"; name = "A. Schaarschmidt" }) -ne $true) { throw "sameParticipant mismatch 2" }

$sortedParticipants = $core.sortParticipants(@(
    @{ name = "Zed"; messageCount = 2; wordCount = 7 }
    @{ name = "Ada"; messageCount = 3; wordCount = 2 }
    @{ name = "Ben"; messageCount = 2; wordCount = 9 }
)) | ForEach-Object { $_.name }

if (($sortedParticipants -join ",") -ne "Ada,Ben,Zed") { throw "sortParticipants mismatch" }

$merged = $core.mergeParticipantRecord(
    @{ userId = $null; displayId = ""; name = "Anna"; messageCount = 2 },
    @{ userId = "42"; displayId = "anna_live"; receivedAtUtc = "2026-07-18T10:00:00.000Z" },
    "Anna",
    @{ wordCount = 7 }
)

$expectedMerged = @{
    userId = "42"
    displayId = "anna_live"
    name = "Anna"
    messageCount = 2
    wordCount = 7
    giftEventCount = 0
    giftItemCount = 0
    lastSeenAtUtc = "2026-07-18T10:00:00.000Z"
}

if (($merged.Keys | Sort-Object) -ne ($expectedMerged.Keys | Sort-Object)) { throw "mergeParticipantRecord keys mismatch" }
foreach ($key in $merged.Keys) {
    if ($merged[$key] -ne $expectedMerged[$key]) { throw "mergeParticipantRecord value mismatch for key $key" }
}

$profileAndSummary = $core.inspectMetadata(@{
    live_ai_summary_ui = @{ vid = "v2" }
    userInfo = @{
        uniqueId = "demo"
        nickname = "Demo"
        signature = "Eine Bio"
        stats = @{ followingCount = 12; followerCount = 345; heartCount = 678 }
    }
})

if ($profileAndSummary.profileInfo.present -ne $true) { throw "profileInfo.present should be true" }
if ($profileAndSummary.profileInfo.uniqueId -ne "demo") { throw "profileInfo.uniqueId mismatch" }
if ($profileAndSummary.profileInfo.followerCount -ne "345") { throw "profileInfo.followerCount mismatch" }
if ($profileAndSummary.aiSummaryInfo.featureFlagPresent -ne $true) { throw "aiSummaryInfo.featureFlagPresent should be true" }
if ($profileAndSummary.aiSummaryInfo.text -ne "") { throw "aiSummaryInfo.text should be empty" }

$actualSummary = $core.inspectMetadata(@{ live_summary_text = "Eine tatsächlich gelieferte Zusammenfassung." })
if ($actualSummary.aiSummaryInfo.text -ne "Eine tatsächlich gelieferte Zusammenfassung.") { throw "actualSummary text mismatch" }

$pulldata = @{
    options = @{ qualities = @(
        @{ sdk_key = "origin"; name = "Original" }
        @{ sdk_key = "hd"; name = "720p" }
        @{ sdk_key = "sd"; name = "540p" }
        @{ sdk_key = "ld"; name = "360p" }
    ) }
    stream_data = '{"data":{"origin":{"main":{"flv":"https://pull.example.tiktokcdn.com/live/stream_origin.flv","sdk_params":"{\"VCodec\":\"h265\",\"vbitrate\":2600000,\"width\":1920,\"height\":1080,\"fps\":60}"}},"hd":{"main":{"flv":"https://pull.example.tiktokcdn.com/live/stream_hd.flv","hls":"https://pull.example.tiktokcdn.com/live/stream_hd.m3u8","sdk_params":"{\"VCodec\":\"h264\",\"vbitrate\":1800000,\"width\":1280,\"height\":720,\"fps\":30}"}},"sd":{"main":{"flv":"https://pull.example.tiktokcdn.com/live/stream_sd.flv","sdk_params":"{\"VCodec\":\"h264\",\"vbitrate\":900000,\"width\":960,\"height\":540,\"fps\":30}"}},"ld":{"main":{"flv":"https://pull.example.tiktokcdn.com/live/stream_ld.flv","sdk_params":"{\"VCodec\":\"h264\",\"vbitrate\":600000,\"width\":640,\"height\":360,\"fps\":30}"}}}}'
}

$variants = $core.extractStreamVariants($pulldata)
if ($variants.Count -ne 5) { throw "extractStreamVariants count mismatch" }

$origin = $variants | Where-Object { $_.sdkKey -eq "origin" -and $_.quality -eq "Original" -and $_.height -eq 1080 }
if (-not $origin) { throw "origin variant missing" }

$hd = $variants | Where-Object { $_.sdkKey -eq "hd" -and $_.quality -eq "720p" -and $_.bitrate -eq 1800000 }
if (-not $hd) { throw "hd variant missing" }

$sd = $variants | Where-Object { $_.sdkKey -eq "sd" -and $_.width -eq 960 -and $_.height -eq 540 }
if (-not $sd) { throw "sd variant missing" }

$ld = $variants | Where-Object { $_.sdkKey -eq "ld" -and $_.quality -eq "360p" -and $_.height -eq 360 }
if (-not $ld) { throw "ld variant missing" }

# Test protobuf decoding
$captionContent = Concat @(BytesField 1 "de"), @(BytesField 2 "Guten Abend")
$captionPayload = Concat @(
    IntField 2 123456
    IntField 3 1500
    BytesField 4 $captionContent
    IntField 5 77
    IntField 6 3
    IntField 7 1
)
$baseMessage = Concat @(BytesField 1 "WebcastCaptionMessage"), @(BytesField 2 $captionPayload)
$fetchResult = BytesField 1 $baseMessage
$decoded = $proto.decodeFetchResult($fetchResult)

if ($decoded.captions.Count -ne 1) { throw "decoded captions count mismatch" }
if ($decoded.captions[0].contents[0].lang -ne "de") { throw "caption language mismatch" }
if ($decoded.captions[0].contents[0].text -ne "Guten Abend") { throw "caption text mismatch" }
if ($decoded.captions[0].sentenceId -ne "77") { throw "caption sentenceId mismatch" }
if ($decoded.captions[0].definite -ne $true) { throw "caption definite mismatch" }

$chatUser = Concat @(IntField 1 123), @(BytesField 3 "Demo 😊"), @(BytesField 38 "demo_user")
$chatPayload = Concat @(
    BytesField 1 (Concat @(IntField 2 9010))
    BytesField 2 $chatUser
    BytesField 3 "Guten Abend ❤️"
    BytesField 14 "de"
)
$chatFetch = BytesField 1 (Concat @(BytesField 1 "WebcastChatMessage"), @(BytesField 2 $chatPayload))
$chatDecoded = $proto.decodeFetchResult($chatFetch).chatMessages

if ($chatDecoded.Count -ne 1) { throw "chatDecoded count mismatch" }
if ($chatDecoded[0].messageId -ne "9010") { throw "chat messageId mismatch" }
if ($chatDecoded[0].nickname -ne "Demo 😊") { throw "chat nickname mismatch" }
if ($chatDecoded[0].displayId -ne "demo_user") { throw "chat displayId mismatch" }
if ($chatDecoded[0].content -ne "Guten Abend ❤️") { throw "chat content mismatch" }
if ($chatDecoded[0].contentLanguage -ne "de") { throw "chat contentLanguage mismatch" }

$giftPayload = Concat @(
    BytesField 1 (Concat @(IntField 2 9020))
    IntField 2 777
    IntField 5 23
    BytesField 7 $chatUser
    IntField 9 1
)
$giftFetch = BytesField 1 (Concat @(BytesField 1 "WebcastGiftMessage"), @(BytesField 2 $giftPayload))
$giftDecoded = $proto.decodeFetchResult($giftFetch).giftMessages

if ($giftDecoded.Count -ne 1) { throw "giftDecoded count mismatch" }
if ($giftDecoded[0].nickname -ne "Demo 😊") { throw "gift nickname mismatch" }
if ($giftDecoded[0].repeatCount -ne "23") { throw "gift repeatCount mismatch" }

$common = Concat @(IntField 2 9001), @(BytesField 8 (BytesField 1 "pm_mt_msg_viewer"))
$roomUsers = Concat @(BytesField 1 $common), @(IntField 3 143), @(IntField 7 15842)
$likes = Concat @(BytesField 1 $common), @(IntField 2 10), @(IntField 3 430200)
$socialCommon = Concat @(IntField 2 9002), @(BytesField 8 (BytesField 1 "pm_main_follow_message_viewer_2"))
$social = Concat @(BytesField 1 $socialCommon), @(IntField 6 238800)
$liveFetch = Concat @(
    BytesField 1 (Concat @(BytesField 1 "WebcastRoomUserSeqMessage"), @(BytesField 2 $roomUsers))
    BytesField 1 (Concat @(BytesField 1 "WebcastLikeMessage"), @(BytesField 2 $likes))
    BytesField 1 (Concat @(BytesField 1 "WebcastSocialMessage"), @(BytesField 2 $social))
)
$liveDecoded = $proto.decodeFetchResult($liveFetch).liveEvents

if ($liveDecoded.Count -ne 3) { throw "liveDecoded count mismatch" }
if ($liveDecoded[0].viewerCount -ne "143") { throw "live viewerCount mismatch" }
if ($liveDecoded[0].totalViewers -ne "15842") { throw "live totalViewers mismatch" }
if ($liveDecoded[1].likeCount -ne "430200") { throw "live likeCount mismatch" }
if ($liveDecoded[2].kind -ne "follow") { throw "live kind mismatch" }
if ($liveDecoded[2].followerCount -ne "238800") { throw "live followerCount mismatch" }

Write-Host "PASS: manifest $($manifest.version), $($scripts.Count) scripts, chat speech composition, gifts, audience statistics, service controls and security guards"
