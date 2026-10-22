#!/usr/bin/env tclsh8.6
# test_mobile_projects.py — portiert nach tcl
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_mobile_projects.py
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

package require json
package require fileutil

# Define paths similar to Python's Path operations
set scriptDir [file normalize [file dirname [info script]]]
set rootDir [file dirname [file dirname $scriptDir]]
set iosDir [file join $rootDir mobile ios]
set androidDir [file join $rootDir mobile android]
set sharedFile [file join $rootDir plugin-source mobile-shared webview-bridge.js]

# Procedure equivalent to Python's require function
proc require {condition message} {
    if {![expr $condition]} {
        error $message
    }
}

# Check Android project if it exists
if {[file exists $androidDir]} {
    set manifestPath [file join $androidDir app src main AndroidManifest.xml]
    set gradlePath [file join $androidDir app build.gradle.kts]
    set webViewPath [file join $androidDir app src main java app tiktoklivecompanion CompanionWebView.kt]
    
    if {[file exists $manifestPath] && [file exists $gradlePath] && [file exists $webViewPath]} {
        set manifest [readFile $manifestPath]
        set gradle [readFile $gradlePath]
        set android_webview [readFile $webViewPath]
        
        require [expr {[string first {minSdk = 21} $gradle] != -1 && [string first {versionName = "0.8.2"} $gradle] != -1}] {Android version contract}
        require [expr {[string first {usesCleartextTraffic="false"} $manifest] != -1}] {Android cleartext must be disabled}
        require [expr {[string first addJavascriptInterface $android_webview] == -1}] {insecure Android JavaScript interface}
        require [expr {[string first addWebMessageListener $android_webview] != -1 && [string first ALLOWED_ORIGIN $android_webview] != -1}] {origin-restricted Android bridge}
        
        # Check for .aar files in libs directory
        set aarFiles [glob -nocomplain [file join $androidDir app libs *.aar]]
        require [expr {[llength $aarFiles] == 0}] {ShazamKit AAR must not be committed}
        
        # Compare shared file with Android resource
        set androidBridgePath [file join $androidDir app src main res raw webview_bridge.js]
        if {[file exists $sharedFile] && [file exists $androidBridgePath]} {
            set sharedBytes [readBinaryFile $sharedFile]
            set androidBytes [readBinaryFile $androidBridgePath]
            require [expr {$sharedBytes eq $androidBytes}] {Android bridge copy drift}
        }
    }
}

# Check iOS project if it exists
if {[file exists $iosDir]} {
    set iosWebViewPath [file join $iosDir TikTokLiveCompanion CompanionWebView.swift]
    set pbxPath [file join $iosDir TikTokLiveCompanion.xcodeproj project.pbxproj]
    set infoPlistPath [file join $iosDir TikTokLiveCompanion Info.plist]
    
    if {[file exists $iosWebViewPath] && [file exists $pbxPath]} {
        set ios_webview [readFile $iosWebViewPath]
        set pbx [readFile $pbxPath]
        
        require [expr {[string first {forMainFrameOnly: false} $ios_webview] != -1 && [string first {securityOrigin.host == "www.tiktok.com"} $ios_webview] != -1}] {origin-restricted iOS subframe bridge}
        require [expr {[string first {MARKETING_VERSION = 0.8.2} $pbx] != -1 && [string first {IPHONEOS_DEPLOYMENT_TARGET = 15.0} $pbx] != -1}] {iOS version contract}
        
        # Check source membership
        set sourcesExist 1
        foreach name {{StreamNameNormalizer.swift in Sources} {StreamNameNormalizerTests.swift in Sources} {MobileUIStructureTests.swift in Sources}} {
            if {[string first $name $pbx] == -1} {
                set sourcesExist 0
                break
            }
        }
        require $sourcesExist {iOS source and XCTest membership}
        
        # Compare shared file with iOS resource
        set iosBridgePath [file join $iosDir Resources webview-bridge.js]
        if {[file exists $sharedFile] && [file exists $iosBridgePath]} {
            set sharedBytes [readBinaryFile $sharedFile]
            set iosBytes [readBinaryFile $iosBridgePath]
            require [expr {$sharedBytes eq $iosBytes}] {iOS bridge copy drift}
        }
        
        # Check Info.plist version
        if {[file exists $infoPlistPath]} {
            # Note: Tcl doesn't have built-in plist support, so we'll check the content directly
            set infoContent [readFile $infoPlistPath]
            require [expr {[string first {<key>CFBundleShortVersionString</key>} $infoContent] != -1 && [string first {<string>0.8.2</string>} $infoContent] != -1}] {iOS plist version}
        }
    }
}

# Check for Apple private keys
set p8Files [glob -nocomplain [file join $rootDir *.p8]]
set recursiveP8Files [glob -nocomplain -dir $rootDir -types f *.p8]
foreach dir [glob -nocomplain -dir $rootDir -type d *] {
    lappend recursiveP8Files {*}[glob -nocomplain -dir $dir -types f *.p8]
    foreach subdir [glob -nocomplain -dir $dir -type d *] {
        lappend recursiveP8Files {*}[glob -nocomplain -dir $subdir -types f *.p8]
    }
}
set allP8Files [concat $p8Files $recursiveP8Files]
require [expr {[llength $allP8Files] == 0}] {Apple private key must not be committed}

# Check recognition schema
set schemaPath [file join $rootDir plugin-source mobile-shared recognition-result.schema.json]
if {[file exists $schemaPath]} {
    set schemaJson [readFile $schemaPath]
    set schema [::json::json2dict $schemaJson]
    
    # Extract properties.source.enum from nested dict structure
    if {[dict exists $schema properties] && [dict exists $schema properties source] && [dict exists $schema properties source enum]} {
        set enumValues [dict get $schema properties source enum]
        set expectedEnum {microphone webview}
        require [expr {$enumValues eq $expectedEnum}] {recognition source schema}
    } else {
        error {recognition source schema}
    }
}

puts {PASS: available mobile platform versions, bridge boundaries, policies, schema, source sync and secret exclusions}

# Helper procedures
proc readFile {filename} {
    set fh [open $filename r]
    set content [read $fh]
    close $fh
    return $content
}

proc readBinaryFile {filename} {
    set fh [open $filename rb]
    set content [read $fh]
    close $fh
    return $content
}
