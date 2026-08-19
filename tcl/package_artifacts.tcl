#!/usr/bin/env tclsh
# package_artifacts.py — portiert nach tcl
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6
package require zipfile::encode
package require fileutil
package require json
package require sha256

# Globale Variablen
set ROOT [file normalize [file dirname [info script]]]
set PROJECT_ROOT [file dirname $ROOT]
array set EXCLUDED_PARTS [list __pycache__ 1 .gradle 1 .kotlin 1 build 1 DerivedData 1 xcuserdata 1]

proc add_tree {archive source {prefix ""}} {
    global EXCLUDED_PARTS
    
    # Rekursiv alle Dateien finden
    set files [lsort [glob -nocomplain -dir $source -types f -recursive *]]
    
    foreach filepath $files {
        # Prüfe ob Datei ausgeschlossen ist
        set relpath [fileutil::stripPath $source $filepath]
        set parts [split $relpath "/"]
        
        set excluded 0
        foreach part $parts {
            if {[info exists EXCLUDED_PARTS($part)]} {
                set excluded 1
                break
            }
        }
        
        # Prüfe Dateiendung
        set ext [string tolower [file extension $filepath]]
        if {$excluded || $ext eq ".pyc" || $ext eq ".aar"} {
            continue
        }
        
        # Archivpfad erstellen
        set archive_path [file join $prefix $relpath]
        set archive_path [string map {"/" "\\"} $archive_path]  ;# Windows-Pfade
        
        # Datei zum Archiv hinzufügen
        $archive add $filepath -name $archive_path
    }
}

# Argumente parsen
proc parse_args {} {
    global argv PROJECT_ROOT
    
    array set args [list \
        output_dir "" \
        android_apk "" \
        android_source [file join $PROJECT_ROOT mobile android] \
        ios_source [file join $PROJECT_ROOT mobile ios] \
    ]
    
    for {set i 0} {$i < [llength $argv]} {incr i} {
        set arg [lindex $argv $i]
        switch -exact -- $arg {
            --output-dir {
                incr i
                set args(output_dir) [lindex $argv $i]
            }
            --android-apk {
                incr i
                set args(android_apk) [lindex $argv $i]
            }
            --android-source {
                incr i
                set args(android_source) [lindex $argv $i]
            }
            --ios-source {
                incr i
                set args(ios_source) [lindex $argv $i]
            }
            default {
                error "Unbekanntes Argument: $arg"
            }
        }
    }
    
    if {$args(output_dir) eq ""} {
        error "--output-dir ist erforderlich"
    }
    
    return [array get args]
}

# Hauptprogramm
proc main {} {
    global ROOT PROJECT_ROOT
    
    # Argumente parsen
    array set args [parse_args]
    
    # Ausgabeverzeichnis erstellen
    file mkdir $args(output_dir)
    set output_dir [file normalize $args(output_dir)]
    
    # Version aus manifest.json lesen
    set manifest_file [file join $ROOT browser-extension manifest.json]
    set manifest_content [readFile $manifest_file]
    set manifest [json::json2dict $manifest_content]
    set version [dict get $manifest version]
    
    # Dateinamen definieren
    set extension_zip [file join $args(output_dir) "tiktok-live-companion-extension-$version.zip"]
    set plugin_zip [file join $args(output_dir) "tiktok-live-companion-plugin-$version.zip"]
    set service_zip [file join $args(output_dir) "tiktok-live-companion-service-$version.zip"]
    set ios_source_zip [file join $args(output_dir) "tiktok-live-companion-ios-$version-source.zip"]
    set android_source_zip [file join $args(output_dir) "tiktok-live-companion-android-$version-source.zip"]
    set android_apk [file join $args(output_dir) "tiktok-live-companion-android-$version.apk"]
    set extension_dir [file join $args(output_dir) "tiktok-live-companion-extension-$version"]
    set checksum_file [file join $args(output_dir) "tiktok-live-companion-$version-SHA256.txt"]
    
    # Extension-Verzeichnis vorbereiten
    set resolved_extension_dir [file normalize $extension_dir]
    if {[file dirname $resolved_extension_dir] ne $output_dir} {
        error "Refusing to package outside the requested output directory"
    }
    
    if {[file exists $extension_dir]} {
        file delete -force $extension_dir
    }
    
    file copy [file join $ROOT browser-extension] $extension_dir
    file copy [file join $ROOT companion-service] [file join $extension_dir companion-service]
    
    # Batch-Datei schreiben
    set batch_content "@echo off\r\ncall \"%~dp0companion-service\\\\Sprachdienst-reparieren.cmd\"\r\n"
    writeFile [file join $extension_dir "Sprachdienst-reparieren.cmd"] $batch_content
    
    # package.json schreiben
    set package_json [dict create \
        name "tiktok-live-companion-extension-package" \
        private true \
        version $version \
        scripts [dict create \
            setup "npm --prefix companion-service run setup --" \
            start "npm --prefix companion-service start" \
            test "npm --prefix companion-service test" \
        ] \
    ]
    
    set package_json_str [json::dict2json $package_json]
    writeFile [file join $extension_dir package.json] "$package_json_str\n"
    
    # ZIP-Archive erstellen
    set archive [zipfile::encode::openArchive $extension_zip]
    add_tree $archive $extension_dir
    zipfile::encode::closeArchive $archive
    
    set archive [zipfile::encode::openArchive $plugin_zip]
    add_tree $archive $ROOT "tiktok-live-companion"
    zipfile::encode::closeArchive $archive
    
    set archive [zipfile::encode::openArchive $service_zip]
    add_tree $archive [file join $ROOT companion-service]
    zipfile::encode::closeArchive $archive
    
    # Quellverzeichnisse prüfen
    set ios_source [file normalize $args(ios_source)]
    set android_source [file normalize $args(android_source)]
    
    if {![file isdirectory $ios_source] || ![file isdirectory $android_source]} {
        error "--ios-source and --android-source must point to existing source directories"
    }
    
    # iOS Source Archive
    set archive [zipfile::encode::openArchive $ios_source_zip]
    add_tree $archive $ios_source "TikTokLiveCompanion-iOS"
    zipfile::encode::closeArchive $archive
    
    # Android Source Archive
    set archive [zipfile::encode::openArchive $android_source_zip]
    add_tree $archive $android_source "TikTokLiveCompanion-Android"
    zipfile::encode::closeArchive $archive
    
    # APK kopieren falls angegeben
    if {$args(android_apk) ne ""} {
        set source_apk [file normalize $args(android_apk)]
        if {![file isfile $source_apk] || [string tolower [file extension $source_apk]] ne ".apk"} {
            error "--android-apk must point to an existing APK"
        }
        if {$source_apk ne [file normalize $android_apk]} {
            file copy -force $source_apk $android_apk
        }
    }
    
    # Checksummen berechnen
    set artifacts [list $extension_zip $plugin_zip $service_zip $ios_source_zip $android_source_zip]
    if {[file exists $android_apk]} {
        lappend artifacts $android_apk
    }
    
    set checksums {}
    foreach artifact $artifacts {
        set digest [sha256::sha256 -file $artifact]
        lappend checksums "$digest  [file tail $artifact]"
    }
    
    writeFile $checksum_file "[join $checksums \n]\n"
    
    # Ergebnis ausgeben
    set result [dict create \
        extension_dir [file normalize $extension_dir] \
        extension_zip [file normalize $extension_zip] \
        plugin_zip [file normalize $plugin_zip] \
        service_zip [file normalize $service_zip] \
        ios_source_zip [file normalize $ios_source_zip] \
        android_source_zip [file normalize $android_source_zip] \
        android_apk [expr {[file exists $android_apk] ? [file normalize $android_apk] : ""}] \
        checksum_file [file normalize $checksum_file] \
        version $version \
    ]
    
    puts [json::dict2json $result]
}

# Hilfsfunktionen
proc readFile {filename} {
    set fh [open $filename r]
    set content [read $fh]
    close $fh
    return $content
}

proc writeFile {filename content} {
    set fh [open $filename w]
    puts -nonewline $fh $content
    close $fh
}

# Programm starten
main
