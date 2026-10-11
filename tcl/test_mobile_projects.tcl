#!/usr/bin/env tclsh
# test_mobile_projects.py — portiert nach tcl
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_mobile_projects.py
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6
package require json

# Define paths similar to Python's Path operations
set scriptDir [file normalize [file dirname [info script]]]
set ROOT [file normalize [file join $scriptDir ".." ".."]]
set IOS [file join $ROOT "mobile" "ios"]
set ANDROID [file join $ROOT "mobile" "android"]
set SHARED [file join $ROOT "plugin-source" "mobile-shared" "webview-bridge.js"]

# Helper function to mimic Python's assert behavior
proc require {condition message} {
    if {![uplevel #0 expr $condition]} {
        error $message
    }
}

# Read file content with encoding
proc read_file {filepath} {
    set fh [open $filepath r]
    fconfigure $fh -encoding utf-8
    set content [read $fh]
    close $fh
    return $content
}

# Read binary file content
proc read_binary {filepath} {
    set fh [open $filepath rb]
    set content [read $fh]
    close $fh
    return $content
}

# Check Android project if it exists
if {[file exists $ANDROID]} {
    set manifest [read_file [file join $ANDROID "app" "src" "main" "AndroidManifest.xml"]]
    set gradle [read_file [file join $ANDROID "app" "build.gradle.kts"]]
    set android_webview [read_file [file join $ANDROID "app" "src" "main" "java" "app" "tiktoklivecompanion" "CompanionWebView.kt"]]
    
    require {[string first {minSdk = 21} $gradle] != -1 && [string first {versionName = "0.8.2"} $gradle] != -1} "Android version contract"
    require {[string first {usesCleartextTraffic="false"} $manifest] != -1} "Android cleartext must be disabled"
    require {[string first addJavascriptInterface $android_webview] == -1} "insecure Android JavaScript interface"
    require {[string first addWebMessageListener $android_webview] != -1 && [string first ALLOWED_ORIGIN $android_webview] != -1} "origin-restricted Android bridge"
    
    # Check for .aar files in libs directory
    set aar_files [glob -nocomplain [file join $ANDROID "app" "libs" "*.aar"]]
    require {[llength $aar_files] == 0} "ShazamKit AAR must not be committed"
    
    set shared_content [read_binary $SHARED]
    set android_bridge_content [read_binary [file join $ANDROID "app" "src" "main" "res" "raw" "webview_bridge.js"]]
    require {$shared_content eq $android_bridge_content} "Android bridge copy drift"
}

# Check iOS project if it exists
if {[file exists $IOS]} {
    set ios_webview [read_file [file join $IOS "TikTokLiveCompanion" "CompanionWebView.swift"]]
    set pbx [read_file [file join $IOS "TikTokLiveCompanion.xcodeproj" "project.pbxproj"]]
    
    require {[string first {forMainFrameOnly: false} $ios_webview] != -1 && [string first {securityOrigin.host == "www.tiktok.com"} $ios_webview] != -1} "origin-restricted iOS subframe bridge"
    require {[string first {MARKETING_VERSION = 0.8.2} $pbx] != -1 && [string first {IPHONEOS_DEPLOYMENT_TARGET = 15.0} $pbx] != -1} "iOS version contract"
    
    # Check source and test membership
    set required_names {"StreamNameNormalizer.swift in Sources" "StreamNameNormalizerTests.swift in Sources" "MobileUIStructureTests.swift in Sources"}
    foreach name $required_names {
        require {[string first $name $pbx] != -1} "iOS source and XCTest membership"
    }
    
    set shared_content [read_binary $SHARED]
    set ios_bridge_content [read_binary [file join $IOS "Resources" "webview-bridge.js"]]
    require {$shared_content eq $ios_bridge_content} "iOS bridge copy drift"
    
    # Parse Info.plist using system plutil command
    set plist_file [file join $IOS "TikTokLiveCompanion" "Info.plist"]
    set temp_json "/tmp/info_plist.json"
    exec plutil -convert json -o $temp_json $plist_file
    set plist_fh [open $temp_json r]
    set plist_data [read $plist_fh]
    close $plist_fh
    file delete $temp_json
    
    set info_dict [::json::json2dict $plist_data]
    array set info_array $info_dict
    require {$info_array(CFBundleShortVersionString) eq "0.8.2"} "iOS plist version"
}

# Check for Apple private keys
set p8_files {}
foreach item [glob -directory $ROOT -types f -nocomplain "**/*.p8"] {
    lappend p8_files $item
}
require {[llength $p8_files] == 0} "Apple private key must not be committed"

# Validate JSON schema
set schema_file [file join $ROOT "plugin-source" "mobile-shared" "recognition-result.schema.json"]
set schema_content [read_file $schema_file]
set schema_dict [::json::json2dict $schema_content]
array set schema_array $schema_dict

# Navigate to properties.source.enum
array set properties_array $schema_array(properties)
array set source_array $properties_array(source)
set enum_values $source_array(enum)

set expected_enum [list microphone webview]
require {$enum_values eq $expected_enum} "recognition source schema"

puts "PASS: available mobile platform versions, bridge boundaries, policies, schema, source sync and secret exclusions"
