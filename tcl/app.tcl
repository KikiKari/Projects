#!/usr/bin/env tclsh
# app.js — portiert nach tcl
# Quelle: javascript, Projects@Vision-Check:Vision-Check/app/js/app.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# ═══════════════════════════════════════════
# Vision-Check — Haupt-App (Analyse-Board)
# Orchestriert: Kamera · Filter · TF.js · Cloud APIs
# ═══════════════════════════════════════════

# ── DOM-Referenzen ───────────────────────────────────
proc $ {id} {
    return [document getElementById $id]
}

set video [document getElementById video]
set overlayCanvas [document getElementById canvas-overlay]
set snapCanvas [document getElementById snap-canvas]
set filteredCanvas [document getElementById filtered-canvas]
set loupeCanvas [document getElementById loupe-canvas]
set loupeInfo [document getElementById loupe-info]
set pixelLoupe [document getElementById pixel-loupe]

set btnStartCamera [document getElementById btn-start-camera]
set btnSnap [document getElementById btn-snap]
set btnAnalyze [document getElementById btn-analyze]
set btnSettings [document getElementById btn-settings]
set btnToggleLoupe [document getElementById btn-toggle-loupe]
set btnResetFilters [document getElementById btn-reset-filters]
set btnUpload [document getElementById btn-upload]
set fileInput [document getElementById file-input]

set cameraSelect [document getElementById camera-select]
set resolutionSelect [document getElementById resolution-select]

set statusDot [document getElementById status-dot]
set statusText [document getElementById status-text]
set camBadge [document getElementById cam-badge]
set resolutionInfo [document getElementById resolution-info]

set sliderBrightness [document getElementById slider-brightness]
set sliderSaturation [document getElementById slider-saturation]
set sliderClahe [document getElementById slider-clahe]
set sliderUnsharp [document getElementById slider-unsharp]
set valBrightness [document getElementById val-brightness]
set valSaturation [document getElementById val-saturation]
set valClahe [document getElementById val-clahe]
set valUnsharp [document getElementById val-unsharp]

set settingsModal [document getElementById settings-modal]
set snapshotArea [document getElementById snapshot-area]
set snapshotPreview [document getElementById snapshot-preview]

set resultsContainer [document getElementById results-container]
set layerIndicators [document querySelectorAll .layer-dot]
set analyzeTabBtns [document querySelectorAll .tab]
set analyzeTabContents [document querySelectorAll .tab-content]

# ── State ────────────────────────────────────────────
array set appState {
    cameraActive false
    snapshotDataURL ""
    loupeActive false
    isAnalyzing false
    tfModel ""
    tfBackend ""
    filterParams ""
    settings ""
    liveDetectionRunning false
    rafId ""
}

# ── Init ─────────────────────────────────────────────
proc init {} {
    setStatus "Initialisiere..." "loading"

    # Einstellungen laden
    set appState(settings) [Settings load]
    applyFilterParamsFromSettings

    # Service Worker
    if {"serviceWorker" in [navigator info]} {
        if {[catch {navigator serviceWorker register /sw.js} e]} {
            puts "SW: $e"
        }
    }

    # Dropdowns befüllen
    Camera populateDeviceDropdown $cameraSelect
    Camera populateResolutionDropdown $resolutionSelect

    # Slider-Werte aus Settings setzen
    syncSlidersFromParams

    # Settings-Modal binden
    Settings bindModal $settingsModal {newCfg -> 
        set appState(settings) $newCfg
    }

    # Event-Listener
    bindEvents

    # TensorFlow.js laden (non-blocking)
    loadTFModel

    setStatus "Bereit — Kamera starten" ""
}

# ── TensorFlow.js + COCO-SSD ─────────────────────────
proc loadTFModel {} {
    setLayerIndicator 1 "loading"
    setStatus "Lade TensorFlow.js..." "loading"

    if {[catch {
        # Backend-Auswahl: WebGPU > WebGL > CPU
        proc backendFn {} {
            if {[info exists navigator(gpu)]} {
                if {[catch {tf setBackend webgpu}]} {
                    # ignore error
                } else {
                    return "webgpu"
                }
            }
            if {[tf setBackend webgl]} {
                return "webgl"
            }
            tf setBackend cpu
            return "cpu"
        }

        set appState(tfBackend) [backendFn]
        puts "TF Backend: $appState(tfBackend)"

        set appState(tfModel) [cocoSsd load {base mobilenet_v2}]
        setLayerIndicator 1 "active"
        setStatus "TF.js ($appState(tfBackend)) bereit" "ok"

        # Kamera automatisch starten nach Modell-Load
        if {$appState(cameraActive)} {
            startLiveDetection
        }
    } err]} {
        setLayerIndicator 1 "err"
        puts "TF.js Fehler: $err"
        setStatus "TF.js nicht verfügbar (Cloud-APIs weiter nutzbar)" "warn"
    }
}

# ── Kamera ───────────────────────────────────────────
proc startCamera {} {
    setStatus "Starte Kamera..." "loading"
    $camBadge textContent "Verbinde"
    $camBadge className "badge badge-loading"

    set result [Camera start $video [$cameraSelect value] [$resolutionSelect value]]

    if {[dict get $result ok]} {
        set appState(cameraActive) true
        $camBadge textContent "Live"
        $camBadge className "badge badge-live"
        $resolutionInfo textContent "[dict get $result actualWidth]×[dict get $result actualHeight]"
        setStatus "Kamera aktiv — [dict get $result deviceLabel || Gerät] ([dict get $result actualWidth]×[dict get $result actualHeight])" "ok"
        $btnSnap configure -state normal

        # Live-Detektion
        if {$appState(tfModel) != ""} {
            startLiveDetection
        }
    } else {
        setStatus "Kamera-Fehler: [dict get $result error]" "err"
        $camBadge textContent "Fehler"
        $camBadge className "badge badge-idle"
    }
}

# ── Live-Detektion (requestAnimationFrame) ────────────
proc startLiveDetection {} {
    if {$appState(liveDetectionRunning)} {
        return
    }
    set appState(liveDetectionRunning) true

    set frameCount 0
    set DETECT_EVERY 10 ;# Jedes 10. Frame (≈6fps Detektion bei 60fps rAF)

    proc loop {} {
        if {!$appState(cameraActive) || $appState(tfModel) == ""} {
            set appState(liveDetectionRunning) false
            return
        }

        incr frameCount
        if {($frameCount % $DETECT_EVERY) == 0 && [$video readyState] == 4} {
            if {[catch {
                set predictions [$appState(tfModel) detect $video]
                Camera drawDetections $overlayCanvas $video $predictions

                if {[llength $predictions] > 0} {
                    renderLocalDetections $predictions
                }
            }]} {
                # ignore error
            }
        }

        set appState(rafId) [requestAnimationFrame loop]
    }

    loop
}

proc stopLiveDetection {} {
    set appState(liveDetectionRunning) false
    if {$appState(rafId) != ""} {
        cancelAnimationFrame $appState(rafId)
    }
}

# ── Snapshot ─────────────────────────────────────────
proc takeSnapshot {} {
    if {!$appState(cameraActive)} {
        Settings showToast "Bitte zuerst Kamera starten"
        return
    }

    set frame [Camera captureFrame $video $snapCanvas 2048]
    if {$frame == ""} {
        Settings showToast "Kein Bild verfügbar"
        return
    }

    # Filter anwenden
    applyFiltersToSnapshot $snapCanvas

    set appState(snapshotDataURL) [$filteredCanvas toDataURL image/jpeg 0.92]

    # Vorschau
    $snapshotPreview configure -src $appState(snapshotDataURL)
    $snapshotArea configure -display block
    $snapshotArea className "fade-in"

    $btnAnalyze configure -state normal
    setStatus "Snapshot gespeichert — Filter angewendet" "ok"

    # Auto-Analyse?
    if {[dict exists $appState(settings) autoAnalyze] && [dict get $appState(settings) autoAnalyze]} {
        runCloudAnalysis
    }
}

# ── Filter auf Snapshot anwenden ─────────────────────
proc applyFiltersToSnapshot {srcCanvas} {
    set params [getFilterParams]
    $filteredCanvas configure -width [$srcCanvas cget -width] -height [$srcCanvas cget -height]
    Filters applyPipeline $srcCanvas $filteredCanvas $params
}

proc getFilterParams {} {
    return [list \
        brightness [expr {double([$sliderBrightness value] || 0)}] \
        saturation [expr {double([$sliderSaturation value] || 1.2)}] \
        clahe [expr {double([$sliderClahe value] || 1.5)}] \
        unsharp [expr {int([$sliderUnsharp value] || 2)}] \
    ]
}

# ── Cloud-Analyse ─────────────────────────────────────
proc runCloudAnalysis {} {
    if {$appState(snapshotDataURL) == ""} {
        Settings showToast "Erst Snapshot aufnehmen"
        return
    }
    if {$appState(isAnalyzing)} {
        return
    }

    set appState(isAnalyzing) true
    $btnAnalyze configure -state disabled
    setStatus "Analysiere..." "loading"
    setLayerIndicator 3 "loading"

    clearResults
    showAnalysisSpinner true

    set settings $appState(settings)
    set hasAnyKey [expr {[dict exists $settings openaiKey] || [dict exists $settings geminiKey] || [dict exists $settings claudeKey]}]

    if {!$hasAnyKey && [dict exists $settings inat] && ![dict get $settings inat]} {
        showNoKeyHint
        set appState(isAnalyzing) false
        return
    }

    CloudAPI analyzeAll $appState(snapshotDataURL) $settings {source result -> 
        # Progress: Ergebnis sofort zeigen wenn es ankommt
        renderCloudResult $source $result
    }

    set appState(isAnalyzing) false
    $btnAnalyze configure -state normal
    showAnalysisSpinner false
    setLayerIndicator 3 "active"
    setStatus "Analyse abgeschlossen" "ok"
}

# ── Ergebnisse rendern ───────────────────────────────
proc clearResults {} {
    set container [$ results-layer0]
    set containerCloud [$ results-layer3]
    if {$container != ""} {
        $container innerHTML ""
    }
    if {$containerCloud != ""} {
        $containerCloud innerHTML ""
    }
}

proc renderLocalDetections {predictions} {
    set container [$ results-layer1]
    if {$container == ""} {
        return
    }

    $container innerHTML ""
    if {[llength $predictions] == 0} {
        $container innerHTML {<p style="color:var(--text-dim);font-size:12px;">Keine Objekte erkannt</p>}
        return
    }

    foreach pred [lrange $predictions 0 7] {
        set el [document createElement div]
        $el className "detection-item fade-in"
        set pct [expr {round([dict get $pred score] * 100)}]
        $el innerHTML "
      <span class=\"detection-class\">[dict get $pred class]</span>
      <div class=\"confidence-bar\">
        <div class=\"confidence-track\">
          <div class=\"confidence-fill\" style=\"width:${pct}%\"></div>
        </div>
        <span class=\"confidence-pct\">${pct}%</span>
      </div>
    "
        $container appendChild $el
    }
}

proc renderCloudResult {source result} {
    # Tab auswählen basierend auf Quelle
    set containerId ""
    if {$source == "iNaturalist"} {
        set containerId "result-layer0"
    } else {
        set containerId "result-layer3"
    }

    set container [$ containerId]
    if {$container == ""} {
        return
    }

    if {![dict get $result ok]} {
        set el [document createElement div]
        $el className "result-block fade-in"
        $el innerHTML "
      <div class=\"result-header\">
        <span class=\"layer-tag\" style=\"color:var(--accent-err)\">$result(source || $source)</span>
        <span class=\"badge\" style=\"color:var(--accent-err);background:rgba(252,129,129,0.1)\">Fehler</span>
      </div>
      <p class=\"result-text\" style=\"color:var(--accent-err)\">$result(error)</p>
    "
        $container appendChild $el
        return
    }

    if {$source == "iNaturalist" && [dict exists $result results]} {
        # iNaturalist Cards
        set wrapper [document createElement div]
        $wrapper className "fade-in"
        foreach r [dict get $result results] {
            set card [document createElement div]
            $card className "species-card"
            $card innerHTML "
        [if {[dict exists $r photoUrl]} {set photoUrl [dict get $r photoUrl]} else {set photoUrl ""}]
        ${photoUrl ? "<img class=\"species-img\" src=\"${photoUrl}\" alt=\"[dict get $r name]\" loading=\"lazy\">" : "<div class=\"species-img\"></div>"}
        <div class=\"species-info\">
          <div class=\"species-name\">[dict get $r name]</div>
          <div class=\"species-latin\">[dict get $r scientificName || ""]</div>
          <div class=\"species-score\">Score: [if {[dict exists $r score]} {set score [dict get $r score]} else {set score ""}][expr {$score ? [format "%.1f" [expr {$score * 100}]]% : "–"}] · [dict get $r rank || ""]</div>
        </div>
      "
            $wrapper appendChild $card
        }
        $container appendChild $wrapper

        # Tab aktivieren
        switchTab tab-inat
        return
    }

    # Text-Ergebnis (OpenAI / Gemini / Claude)
    array set colorMap {
        "OpenAI GPT-4o" "var(--layer-3-gpt)"
        "Gemini 2.5 Pro" "var(--layer-3-gemini)"
        "Claude claude-opus-4-8" "var(--layer-3-claude)"
        "Claude claude-fable-5" "var(--layer-3-claude)"
    }
    set color [dict get $colorMap $result(source) || "var(--accent)"]

    set el [document createElement div]
    $el className "result-block fade-in"
    $el innerHTML "
    <div class=\"result-header\">
      <span class=\"layer-tag\" style=\"color:${color}\">
        <span style=\"width:8px;height:8px;border-radius:50%;background:${color};display:inline-block\"></span>
        [dict get $result source]
      </span>
      [if {[dict exists $result tokens]} {set tokens [dict get $result tokens]} else {set tokens ""}]${tokens ? "<span class=\"badge\" style=\"color:var(--text-dim);background:transparent;font-size:10px\">~[dict get $tokens output || "?"] Tokens</span>" : ""}
    </div>
    <div class=\"result-text\">[markdownToHTML [dict get $result text]]</div>
  "
    $container appendChild $el
    switchTab tab-cloud
}

proc showNoKeyHint {} {
    set container [$ results-layer3]
    if {$container == ""} {
        return
    }
    $container innerHTML "
    <div class=\"result-block fade-in\">
      <p class=\"result-text\" style=\"color:var(--accent-warn)\">
        Keine API-Keys konfiguriert.<br>
        Öffne die Einstellungen (⚙) und trage OpenAI, Gemini oder Claude-Key ein.
      </p>
    </div>
  "
    showAnalysisSpinner false
    $btnAnalyze configure -state normal
    set appState(isAnalyzing) false
}

# ── Einfacher Markdown-zu-HTML Konverter ─────────────
proc markdownToHTML {text} {
    if {$text == ""} {
        return ""
    }
    # Replace HTML special characters
    regsub -all {&} $text {\&amp;} text
    regsub -all {<} $text {\&lt;} text
    regsub -all {>} $text {\&gt;} text
    
    # Bold text
    regsub -all {\*\*(.+?)\*\*} $text {<strong>\1</strong>} text
    
    # Italic text
    regsub -all {\*(.+?)\*} $text {<em>\1</em>} text
    
    # Headings
    regsub -all {^### (.+)$} $text {<h4 style="color:var(--accent);margin:8px 0 4px">\1</h4>} text
    regsub -all {^## (.+)$} $text {<h3 style="color:var(--accent);margin:10px 0 4px">\1</h3>} text
    regsub -all {^# (.+)$} $text {<h3 style="color:var(--accent);margin:10px 0 4px">\1</h3>} text
    
    # Lists
    regsub -all {^\d+\. (.+)$} $text {<div style="margin:2px 0;padding-left:12px">\1</div>} text
    regsub -all {^[-•] (.+)$} $text {<div style="margin:2px 0;padding-left:12px">• \1</div>} text
    
    # Line breaks
    regsub -all {\n\n} $text {<br><br>} text
    regsub -all {\n} $text {<br>} text
    
    return $text
}

# ── Tab-Steuerung ─────────────────────────────────────
proc switchTab {tabId} {
    foreach btn $analyzeTabBtns {
        if {[$btn cget -data-tab] == $tabId} {
            $btn className "active"
        } else {
            $btn className ""
        }
    }
    foreach content $analyzeTabContents {
        if {[$content cget -id] == [string map {"tab-" "tab-content-"} $tabId]} {
            $content className "active"
        } else {
            $content className ""
        }
    }
}

# ── Pixel-Inspektor & Lupe ────────────────────────────
proc bindLoupeEvents {} {
    set viewport [$ camera-viewport]
    if {$viewport == ""} {
        return
    }

    $viewport addEventListener "mousemove" {e -> 
        if {!$appState(loupeActive)} {
            return
        }
        if {$appState(snapshotDataURL) == "" && !$appState(cameraActive)} {
            return
        }

        set rect [$viewport getBoundingClientRect]
        set mx [expr {[$e clientX] - [dict get $rect left]}]
        set my [expr {[$e clientY] - [dict get $rect top]}]

        # Koordinaten auf Original-Video skalieren
        set scaleX [expr {[$video cget -videoWidth] / [dict get $rect width]}]
        set scaleY [expr {[$video cget -videoHeight] / [dict get $rect height]}]
        set cx [expr {$mx * $scaleX}]
        set cy [expr {$my * $scaleY}]

        # Lupe rendern (aus Snapshot oder Video)
        set src [expr {[$filteredCanvas cget -width] > 0 ? $filteredCanvas : $snapCanvas}]
        if {[$src cget -width] > 0} {
            $loupeCanvas configure -width 160 -height 160
            Filters renderLoupe $src $loupeCanvas $cx $cy [dict get $appState(settings) loupeZoom || 8]

            # Pixel-Info
            set px [Filters getPixelAt $src $cx $cy]
            $loupeInfo textContent "$px(hex) · $px(brightness)L"

            # Pixel-Swatch
            set swatch [$ pixel-swatch]
            set values [$ pixel-values-text]
            if {$swatch != ""} {
                $swatch style.background $px(hex)
            }
            if {$values != ""} {
                $values innerHTML "
        <span>$px(hex)</span>
        <span>R:$px(r) G:$px(g) B:$px(b)</span>
        <span>Helligkeit: $px(brightness)</span>
      "
            }
        }

        # Lupe positionieren
        $pixelLoupe configure -display block
    }

    $viewport addEventListener "mouseleave" {
        if {!$appState(loupeActive)} {
            return
        }
        $pixelLoupe configure -display none
    }
}

# ── Status-Helfer ─────────────────────────────────────
proc setStatus {msg state} {
    if {$statusText != ""} {
        $statusText textContent $msg
    }
    if {$statusDot != ""} {
        $statusDot className "status-dot"
        switch $state {
            "ok" {
                $statusDot className "status-dot ok"
            }
            "warn" {
                $statusDot className "status-dot warn"
            }
            "err" - "error" {
                $statusDot className "status-dot err"
            }
        }
    }
}

proc setLayerIndicator {layer state} {
    set dot [document querySelector ".layer-dot\[data-layer=\"$layer\"\]"]
    if {$dot == ""} {
        return
    }
    if {$state == "active" || $state == "loading"} {
        $dot className "layer-dot active"
    } else {
        $dot className "layer-dot"
    }
}

proc showAnalysisSpinner {show} {
    set spinner [$ analyze-spinner]
    if {$spinner != ""} {
        if {$show} {
            $spinner configure -display block
        } else {
            $spinner configure -display none
        }
    }
}

# ── Filter-Slider-Sync ────────────────────────────────
proc syncSlidersFromParams {} {
    set cfg $appState(settings) || Settings::DEFAULTS
    if {$sliderBrightness != ""} {
        $sliderBrightness configure -value [dict get $cfg brightness]
        $valBrightness textContent [dict get $cfg brightness]
    }
    if {$sliderSaturation != ""} {
        $sliderSaturation configure -value [dict get $cfg saturation]
        $valSaturation textContent [dict get $cfg saturation]
    }
    if {$sliderClahe != ""} {
        $sliderClahe configure -value [dict get $cfg clahe]
        $valClahe textContent "[dict get $cfg clahe]x"
    }
    if {$sliderUnsharp != ""} {
        $sliderUnsharp configure -value [dict get $cfg unsharp]
        $valUnsharp textContent [dict get $cfg unsharp]
    }
}

proc applyFilterParamsFromSettings {} {
    # Nichts zu tun — Params werden direkt aus Slidern gelesen
}

proc bindSliderEvents {} {
    set pairs [list \
        [list $sliderBrightness $valBrightness {v -> return $v} ""] \
        [list $sliderSaturation $valSaturation {v -> return $v} ""] \
        [list $sliderClahe $valClahe {v -> return $v} "x"] \
        [list $sliderUnsharp $valUnsharp {v -> return $v} ""] \
    ]
    
    foreach pair $pairs {
        foreach {slider label fn suffix} $pair break
        if {$slider == ""} {
            continue
        }
        $slider addEventListener "input" {
            if {$label != ""} {
                $label textContent "[$fn [$slider value]]$suffix"
            }
            # Vorschau live aktualisieren wenn Snapshot vorhanden
            if {$appState(snapshotDataURL) != "" && [$snapCanvas cget -width] > 0} {
                applyFiltersToSnapshot $snapCanvas
                $snapshotPreview configure -src [$filteredCanvas toDataURL image/jpeg 0.88]
            }
        }
    }
}

# ── Upload-Handling ───────────────────────────────────
proc handleUpload {file} {
    if {$file == "" || ![string match "image/*" [$file type]]} {
        Settings showToast "Bitte ein Bild hochladen"
        return
    }
    set reader [FileReader new]
    $reader onload {e -> 
        set img [Image new]
        $img onload {
            $snapCanvas configure -width [$img width] -height [$img height]
            [$snapCanvas getContext 2d] drawImage $img 0 0
            applyFiltersToSnapshot $snapCanvas
            set appState(snapshotDataURL) [$filteredCanvas toDataURL image/jpeg 0.92]
            $snapshotPreview configure -src $appState(snapshotDataURL)
            $snapshotArea configure -display block
            $btnAnalyze configure -state normal
            setStatus "Bild geladen: [$img width]×[$img height]px" "ok"
            if {[dict exists $appState(settings) autoAnalyze] && [dict get $appState(settings) autoAnalyze]} {
                runCloudAnalysis
            }
        }
        $img src [$e target result]
    }
    $reader readAsDataURL $file
}

# ── Event-Listener binden ─────────────────────────────
proc bindEvents {} {
    # Kamera
    if {$btnStartCamera != ""} {
        $btnStartCamera addEventListener "click" startCamera
    }

    if {$cameraSelect != ""} {
        $cameraSelect addEventListener "change" {
            if {$appState(cameraActive)} {
                startCamera
            }
        }
    }

    if {$resolutionSelect != ""} {
        $resolutionSelect addEventListener "change" {
            if {$appState(cameraActive)} {
                startCamera
            }
        }
    }

    # Snapshot
    if {$btnSnap != ""} {
        $btnSnap addEventListener "click" takeSnapshot
    }

    # Analyse
    if {$btnAnalyze != ""} {
        $btnAnalyze addEventListener "click" runCloudAnalysis
    }

    # Einstellungen
    if {$btnSettings != ""} {
        $btnSettings addEventListener "click" {
            Settings openModal $settingsModal
        }
    }

    # Lupe Toggle
    if {$btnToggleLoupe != ""} {
        $btnToggleLoupe addEventListener "click" {
            set appState(loupeActive) [expr {!$appState(loupeActive)}]
            if {$appState(loupeActive)} {
                $btnToggleLoupe className "btn-primary"
            } else {
                $btnToggleLoupe className ""
            }
            if {!$appState(loupeActive)} {
                $pixelLoupe configure -display none
            }
        }
    }

    # Filter Reset
    if {$btnResetFilters != ""} {
        $btnResetFilters addEventListener "click" {
            set d Settings::DEFAULTS
            if {$sliderBrightness != ""} {
                $sliderBrightness configure -value [dict get $d brightness]
            }
            if {$sliderSaturation != ""} {
                $sliderSaturation configure -value [dict get $d saturation]
            }
            if {$sliderClahe != ""} {
                $sliderClahe configure -value [dict get $d clahe]
            }
            if {$sliderUnsharp != ""} {
                $sliderUnsharp configure -value [dict get $d unsharp]
            }
            syncSlidersFromParams
            if {$appState(snapshotDataURL) != "" && [$snapCanvas cget -width] > 0} {
                applyFiltersToSnapshot $snapCanvas
                $snapshotPreview configure -src [$filteredCanvas toDataURL image/jpeg 0.88]
            }
        }
    }

    # Upload
    if {$btnUpload != ""} {
        $btnUpload addEventListener "click" {
            if {$fileInput != ""} {
                $fileInput click
            }
        }
    }
    set btnUploadReplace [$ btn-upload-replace]
    if {$btnUploadReplace != ""} {
        $btnUploadReplace addEventListener "click" {
            if {$fileInput != ""} {
                $fileInput click
            }
        }
    }
    if {$fileInput != ""} {
        $fileInput addEventListener "change" {e -> 
            if {[$e target files length] > 0} {
                handleUpload [$e target files 0]
            }
        }
    }

    # Drag & Drop auf Upload-Zone
    set uploadZone [$ upload-zone]
    if {$uploadZone != ""} {
        $uploadZone addEventListener "dragover" {e -> 
            $e preventDefault
            $uploadZone className "drag-over"
        }
        $uploadZone addEventListener "dragleave" {
            $uploadZone className ""
        }
        $uploadZone addEventListener "drop" {e -> 
            $e preventDefault
            $uploadZone className ""
            if {[$e dataTransfer files length] > 0} {
                handleUpload [$e dataTransfer files 0]
            }
        }
        $uploadZone addEventListener "click" {
            if {$fileInput != ""} {
                $fileInput click
            }
        }
    }

    # Analyse-Tabs
    foreach btn $analyzeTabBtns {
        $btn addEventListener "click" {
            switchTab [$btn cget -data-tab]
        }
    }

    # Slider
    bindSliderEvents

    # Lupe
    bindLoupeEvents

    # Resize
    window addEventListener "resize" {
        if {$appState(cameraActive)} {
            Camera syncOverlayCanvas $video $overlayCanvas
        }
    }
}

# ── Start ─────────────────────────────────────────────
document addEventListener "DOMContentLoaded" init
