#!/usr/bin/env tclsh
# test_mobile_projects.py — portiert nach tcl
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_projects.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

package require json
package require plist

# Define paths similar to Python's Path operations
set scriptDir [file normalize [file dirname [info script]]]
set rootDir [file normalize "$scriptDir/../../"]
set iosDir [file join $rootDir "mobile" "ios"]
set androidDir [file join $rootDir "mobile" "android"]
set sharedFile [file join $rootDir "plugin-source" "mobile-shared" "webview-bridge.js"]

# Function to mimic Python's require behavior
proc require {condition message} {
    if {!$condition} {
        error $message
    }
}

# Helper function to check if substring exists in file content
proc file_contains {filepath substring} {
    set fh [open $filepath r]
    set content [read $fh]
    close $fh
    return [string first $substring $content] != -1
}

# Helper function to compare two files byte by byte
proc files_equal {file1 file2} {
    set fh1 [open $file1 rb]
    set data1 [read $fh1]
    close $fh1
    
    set fh2 [open $file2 rb]
    set data2 [read $fh2]
    close $fh2
    
    return [expr {$data1 eq $data2}]
}

# Check Android project if it exists
if {[file exists $androidDir]} {
    set manifestFile [file join $androidDir "app" "src" "main" "AndroidManifest.xml"]
    set gradleFile [file join $androidDir "app" "build.gradle.kts"]
    set webViewFile [file join $androidDir "app" "src" "main" "java" "app" "tiktoklivecompanion" "CompanionWebView.kt"]
    set libsDir [file join $androidDir "app" "libs"]
    set bridgeDest [file join $androidDir "app" "src" "main" "res" "raw" "webview_bridge.js"]
    
    # Read files for checking contents
    set manifestContent [read_file $manifestFile]
    set gradleContent [read_file $gradleFile]
    set webViewContent [read_file $webViewFile]
    
    # Perform checks
    require [expr {[string first "minSdk = 21" $gradleContent] != -1 && [string first {versionName = "0.8.0"} $gradleContent] != -1}] "Android version contract"
    require [string first {usesCleartextTraffic="false"} $manifestContent] != -1 "Android cleartext must be disabled"
    require [string first "addJavascriptInterface" $webViewContent] == -1 "insecure Android JavaScript interface"
    require [expr {[string first "addWebMessageListener" $webViewContent] != -1 && [string first "ALLOWED_ORIGIN" $webViewContent] != -1}] "origin-restricted Android bridge"
    
    # Check no .aar files exist in libs directory
    set aarFiles [glob -nocomplain [file join $libsDir "*.aar"]]
    require [llength $aarFiles] == 0 "ShazamKit AAR must not be committed"
    
    # Compare shared JS file with Android copy
    require [files_equal $sharedFile $bridgeDest] "Android bridge copy drift"
}

# Check iOS project if it exists
if {[file exists $iosDir]} {
    set webViewSwift [file join $iosDir "TikTokLiveCompanion" "CompanionWebView.swift"]
    set pbxproj [file join $iosDir "TikTokLiveCompanion.xcodeproj" "project.pbxproj"]
    set infoPlist [file join $iosDir "TikTokLiveCompanion" "Info.plist"]
    set iosBridge [file join $iosDir "Resources" "webview-bridge.js"]
    
    # Read files for checking contents
    set webViewContent [read_file $webViewSwift]
    set pbxContent [read_file $pbxproj]
    
    # Perform checks
    require [expr {[string first "forMainFrameOnly: false" $webViewContent] != -1 && [string first {securityOrigin.host == "www.tiktok.com"} $webViewContent] != -1}] "origin-restricted iOS subframe bridge"
    require [expr {[string first "MARKETING_VERSION = 0.8.0" $pbxContent] != -1 && [string first "IPHONEOS_DEPLOYMENT_TARGET = 15.0" $pbxContent] != -1}] "iOS version contract"
    
    # Check source memberships
    set requiredMembers {"StreamNameNormalizer.swift in Sources" "StreamNameNormalizerTests.swift in Sources" "MobileUIStructureTests.swift in Sources"}
    set allFound true
    foreach member $requiredMembers {
        if {[string first $member $pbxContent] == -1} {
            set allFound false
            break
        }
    }
    require $allFound "iOS source and XCTest membership"
    
    # Compare shared JS file with iOS copy
    require [files_equal $sharedFile $iosBridge] "iOS bridge copy drift"
    
    # Load and check Info.plist
    set plistData [plist::parse [read_file $infoPlist]]
    require [dict get $plistData CFBundleShortVersionString] eq "0.8.0" "iOS plist version"
}

# Check that no .p8 files are committed anywhere in the repo
set p8Files [glob -nocomplain -dir $rootDir -types f "*.p8"]
require [llength $p8Files] == 0 "Apple private key must not be committed"

# Check recognition result schema
set schemaFile [file join $rootDir "plugin-source" "mobile-shared" "recognition-result.schema.json"]
set schemaJson [json::json2dict [read_file $schemaFile]]
set enumValues [dict get [dict get [dict get $schemaJson properties] source] enum]
require [expr {$enumValues eq {"microphone" "webview"}}] "recognition source schema"

puts "PASS: available mobile platform versions, bridge boundaries, policies, schema, source sync and secret exclusions"

# Helper procedure to read entire file content
proc read_file {filename} {
    set fh [open $filename r]
    set content [read $fh]
    close $fh
    return $content
}
