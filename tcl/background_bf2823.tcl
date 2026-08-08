#!/usr/bin/env tclsh
# background.js — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/browser-extension/background.js
# auch in: Projects@TikTok-Live-Companion:release/0.7.1/tiktok-live-companion-extension-0.7.1/background.js
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/background.js
# auch in: Projects@TikTok-Live-Companion-Android:release/0.7.1/tiktok-live-companion-extension-0.7.1/background.js
# auch in: 2 weiteren Fundstellen
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

package require http
package require json
package require tls

# Global variables to simulate JavaScript constants and state
set STATE_PREFIX "tlc-tab-"
set LEGACY_HOOK_SCRIPT_ID "tiktok-live-companion-ws-hook"
set SETTINGS_KEY "tlc-settings"
set SERVICE_INSTALL_KEY "tlc-service-install"
set PROFILE_PREFIX "tlc-profile-"
set STREAM_CACHE_PREFIX "tlc-stream-"
set MAX_MEDIA 60
set MAX_CAPTIONS 2000
set MAX_CHAT 500
set MAX_EVENT_IDS 500
set MAX_DEBUG 500
set MAX_PARTICIPANTS 5000

# Simulate core object with required functions
namespace eval core {
    variable EMPTY_PROFILE_INFO [dict create present false uniqueId "" nickname "" signature "" followingCount "" followerCount "" likeCount "" verified false verifiedLabel "" livePro false liveProLabel "" sponsoredContent false sponsoredContentLabel "" paidPartnership false paidPartnershipLabel ""]
    variable EMPTY_AI_SUMMARY_INFO [dict create present false summary "" generatedAtUtc ""]
    
    proc classifyMediaUrl {url} {
        # Simplified implementation
        return [dict create url $url protocol "unknown" audioOnly false]
    }
    
    proc captionsOverlap {caption1 caption2} {
        # Simplified implementation
        return false
    }
    
    proc captionText {caption} {
        # Simplified implementation
        return [dict get $caption text]
    }
    
    proc mergeObservedCaptionInfo {current entry} {
        # Simplified implementation
        return $current
    }
    
    proc normalizedIdentity {value} {
        return [string tolower [regsub {^@} $value ""]]
    }
    
    proc sanitizeChatText {text} {
        return [string trim $text]
    }
    
    proc wordCount {text} {
        return [llength [split $text]]
    }
    
    proc stripTeamTag {text tag} {
        return $text
    }
    
    proc accumulateTeamEvidence {evidence author content messages} {
        return [dict create evidence $evidence teamTag ""]
    }
    
    proc streamIdentityChanged {current incoming} {
        return [expr {[dict get $current handle] ne [dict get $incoming handle] || [dict get $current roomId] ne [dict get $incoming roomId]}]
    }
    
    proc sameParticipant {p1 p2} {
        return [expr {[dict get $p1 key] eq [dict get $p2 key]}]
    }
    
    proc mergeParticipantRecord {existing raw author patch} {
        set result [dict create]
        if {$existing ne ""} {
            set result $existing
        }
        dict set result key [dict get $raw key]
        dict set result name $author
        dict set result messageCount 0
        dict set result wordCount 0
        dict set result giftEventCount 0
        dict set result giftItemCount 0
        return $result
    }
    
    proc spokenNickname {author} {
        return $author
    }
    
    proc resolveSpeechLanguage {setting contentLang} {
        if {$setting eq "auto"} {
            return "de-DE"
        }
        return $setting
    }
    
    proc shouldFilterGameModeSpeech {item participants messages} {
        return false
    }
    
    proc composeSpeechText {item options} {
        return [dict get $item content]
    }
    
    proc gameEventSpeech {message} {
        return ""
    }
    
    proc limiterStrengthToDbfs {strength} {
        return [expr {-1.0 * $strength}]
    }
    
    proc limiterDbfsToStrength {dbfs} {
        return [expr {int(abs($dbfs))}]
    }
}

proc stateKey {tabId} {
    return "${::STATE_PREFIX}${tabId}"
}

proc newBrowserSessionId {} {
    # Generate a simple UUID-like string
    set chars "0123456789abcdef"
    set result ""
    for {set i 0} {$i < 32} {incr i} {
        append result [string index $chars [expr {int(rand() * 16)}]]
        if {$i == 7 || $i == 11 || $i == 15 || $i == 19} {
            append result "-"
        }
    }
    return $result
}

proc emptyState {} {
    return [dict create \
        enabled false \
        browserSessionId "" \
        page [dict create url "" title "" scannedAtUtc ""] \
        captionInfo [dict create present false open "" supportLang {} location "" showType "" observed false source ""] \
        profileInfo $::core::EMPTY_PROFILE_INFO \
        aiSummaryInfo $::core::EMPTY_AI_SUMMARY_INFO \
        menuCaptionAvailable false \
        menuCaptionActive false \
        hook [dict create armed false installed false connected false lastError ""] \
        stream [dict create key "" handle "" roomId "" teamTag "" teamEvidence [dict create]] \
        liveStats [dict create \
            viewerCount "" \
            totalViewers "" \
            likeCount "" \
            followEvents 0 \
            shareEvents 0 \
            shareCount "" \
            followerCount "" \
            lastUpdatedUtc "" \
            recentEventIds {}] \
        selectedQuality "" \
        playerState [dict create \
            available false playing false muted false elapsedText "" pipActive false fullscreenActive false \
            volume 1 volumePercent 100 volumeGainDb 0 peakDbfs "" \
            limiterEnabled false limiterStrength 30 limiterThresholdDbfs [$::core::limiterStrengthToDbfs 30] limiterReductionDb 0 \
            connectedStreams 0 multiGuest false] \
        media {} \
        captions {} \
        chatMessages {} \
        chatSourceTabId "" \
        chatTargetTabId "" \
        chatSourceOnly false \
        participants [dict create] \
        participantsTruncated false \
        streamMutes {} \
        recentGiftIds {} \
        quickRecoverEnabled false \
        speech [dict create enabled false status "Vorlesen ist ausgeschaltet." lastSpokenKey "" lastSpokenAtUtc "" queueDepth 0] \
        recovery [dict create lastQuickRecoverAtUtc "" lastReason ""] \
        debug [dict create enabled false entries {}]]
}

proc getState {tabId} {
    # Simplified implementation using global array for storage
    global states
    if {[info exists states($tabId)]} {
        return $states($tabId)
    }
    return [emptyState]
}

proc pageHandle {page} {
    if {[catch {
        set url [dict get $page url]
        set path [::http::geturl $url]
        set handle ""
        if {[regexp {^/@([^/]+)/live/?$} $path match result]} {
            set handle [string tolower $result]
        } elseif {[regexp {^/embed/live/@?([^/?#]+)/?$} $path match result]} {
            set handle [string tolower $result]
        }
        return $handle
    } err]} {
        return ""
    }
}

proc normalizeHandle {value} {
    return [string tolower [regsub {^@} $value ""]]
}

proc profileHandle {profile} {
    set uniqueId [dict get $profile uniqueId]
    set handle [dict get $profile handle]
    return [normalizeHandle [expr {$uniqueId ne "" ? $uniqueId : $handle}]]
}

proc stateIdentityHandle {state} {
    set streamHandle [dict get $state stream handle]
    set profileUniqueId [dict get $state profileInfo uniqueId]
    set page [dict get $state page]
    set pageHandleVal [pageHandle $page]
    return [normalizeHandle [expr {$streamHandle ne "" ? $streamHandle : ($profileUniqueId ne "" ? $profileUniqueId : $pageHandleVal)}]]
}

proc pageStateHandle {state {message {}}} {
    set page [dict get $state page]
    if {$message ne "" && [dict exists $message page]} {
        set page [dict get $message page]
    }
    set pageHandleVal [pageHandle $page]
    
    set profileInfo ""
    if {$message ne "" && [dict exists $message profileInfo]} {
        set profileInfo [dict get $message profileInfo]
    }
    
    set streamHandle [dict get $state stream handle]
    
    set handle [expr {$pageHandleVal ne "" ? $pageHandleVal : 
                     ($profileInfo ne "" ? [profileHandle $profileInfo] : 
                      ($streamHandle ne "" ? $streamHandle : ""))}]
    return [normalizeHandle $handle]
}

proc profileMatchesHandle {profile handle} {
    set candidate [profileHandle $profile]
    return [expr {$handle eq "" || $candidate eq "" || $candidate eq $handle}]
}

proc resetPageIdentityState {state handle} {
    dict set state profileInfo $::core::EMPTY_PROFILE_INFO
    dict set state aiSummaryInfo $::core::EMPTY_AI_SUMMARY_INFO
    dict set state liveStats followerCount ""
    return $state
}

proc resetPageIdentityIfChanged {state nextHandle} {
    set currentHandle [stateIdentityHandle $state]
    if {$nextHandle eq "" || $currentHandle eq "" || $nextHandle eq $currentHandle} {
        return [list $state false]
    }
    set state [resetPageIdentityState $state $nextHandle]
    return [list $state true]
}

proc profileKey {handle} {
    return "${::PROFILE_PREFIX}[string tolower $handle]"
}

proc cacheProfile {profile} {
    # Simplified implementation
    return
}

proc cachedProfile {handle} {
    # Simplified implementation
    return ""
}

proc addDebug {tabId event {detail {}}} {
    # Simplified implementation
    return
}

proc redactUrl {raw} {
    if {[catch {
        set urlParts [split $raw "?"]
        set baseUrl [lindex $urlParts 0]
        if {[llength $urlParts] > 1} {
            append baseUrl "?REDACTED"
        }
        return $baseUrl
    } err]} {
        return "ungültig"
    }
}

proc setState {tabId state} {
    global states
    set states($tabId) $state
    # Simulate caching and messaging
    return $state
}

proc getSettings {} {
    # Simplified implementation returning default settings
    return [dict create \
        keepSpeechActive false \
        speechVolume 0.5 \
        speechLanguage "auto" \
        speechVoiceName "" \
        gameModeEnabled false \
        speakNames true \
        shortenNames false \
        autoChatRefreshEnabled false \
        autoChatRefreshMinutes 5 \
        serviceUrl "http://127.0.0.1:43117" \
        pairingCode "" \
        auddApiToken "" \
        playerVolume 100 \
        limiterStrength 30 \
        limiterEnabled false \
        songRecognitionEnabled false \
        hookEnabled false \
        autoHook false \
        quickRecoverEnabled false \
        speechEnabled false \
        waitingForTikTok true \
        debugEnabled false \
        permanentMutes {}]
}

proc setSettings {patch} {
    # Simplified implementation
    set settings [getSettings]
    dict for {key value} $patch {
        dict set settings $key $value
    }
    return $settings
}

proc booleanValue {value} {
    if {[string is boolean $value]} {
        return $value
    }
    if {[string is integer $value]} {
        return [expr {$value != 0}]
    }
    if {[string is string $value]} {
        return [regexp {^(?:1|true|yes|ja|on)$} [string trim $value] ignore]
    }
    return [expr {!!$value}]
}

proc normalizePlayerState {{playerState {}}} {
    if {$playerState eq ""} {
        set playerState [dict create]
    }
    return [dict create \
        available [booleanValue [dict get $playerState available]] \
        videoAvailable [booleanValue [expr {[dict exists $playerState videoAvailable] ? [dict get $playerState videoAvailable] : [dict get $playerState available]}]] \
        controlAvailable [booleanValue [dict get $playerState controlAvailable]] \
        playing [booleanValue [dict get $playerState playing]] \
        muted [booleanValue [dict get $playerState muted]] \
        limiterEnabled [booleanValue [dict get $playerState limiterEnabled]] \
        pipActive [booleanValue [dict get $playerState pipActive]] \
        fullscreenActive [booleanValue [dict get $playerState fullscreenActive]] \
        multiGuest [booleanValue [dict get $playerState multiGuest]]]
}

proc loopbackServiceUrl {value} {
    if {[catch {
        if {![regexp {^http://(127\.0\.0\.1|localhost)(:\d+)?} $value]} {
            return ""
        }
        return [regsub {/.*} $value ""]
    } err]} {
        return ""
    }
}

proc profileCompleteness {profile} {
    set fields [list uniqueId nickname signature followingCount followerCount likeCount]
    set count 0
    foreach field $fields {
        if {[dict exists $profile $field] && [dict get $profile $field] ne ""} {
            incr count
        }
    }
    if {[dict get $profile verified]} { incr count }
    if {[dict get $profile livePro]} { incr count }
    if {[dict get $profile sponsoredContent]} { incr count }
    if {[dict get $profile paidPartnership]} { incr count }
    return $count
}

proc mergeProfile {current incoming} {
    if {![dict get $incoming present]} {
        return $current
    }
    set merged ""
    if {![dict get $current present] || [profileCompleteness $incoming] >= [profileCompleteness $current]} {
        set merged [dict merge $current $incoming]
    } else {
        set merged [dict merge $incoming $current]
    }
    return [dict create \
        present [dict get $merged present] \
        uniqueId [dict get $merged uniqueId] \
        nickname [dict get $merged nickname] \
        signature [dict get $merged signature] \
        followingCount [dict get $merged followingCount] \
        followerCount [dict get $merged followerCount] \
        likeCount [dict get $merged likeCount] \
        verified [expr {[dict get $current verified] || [dict get $incoming verified]}] \
        verifiedLabel [expr {[dict get $current verifiedLabel] ne "" ? [dict get $current verifiedLabel] : [dict get $incoming verifiedLabel]}] \
        livePro [expr {[dict get $current livePro] || [dict get $incoming livePro]}] \
        liveProLabel [expr {[dict get $current liveProLabel] ne "" ? [dict get $current liveProLabel] : [dict get $incoming liveProLabel]}] \
        sponsoredContent [expr {[dict get $current sponsoredContent] || [dict get $incoming sponsoredContent]}] \
        sponsoredContentLabel [expr {[dict get $current sponsoredContentLabel] ne "" ? [dict get $current sponsoredContentLabel] : [dict get $incoming sponsoredContentLabel]}] \
        paidPartnership [expr {[dict get $current paidPartnership] || [dict get $incoming paidPartnership]}] \
        paidPartnershipLabel [expr {[dict get $current paidPartnershipLabel] ne "" ? [dict get $current paidPartnershipLabel] : [dict get $incoming paidPartnershipLabel]}]]
}

proc streamCacheKey {handle} {
    return "${::STREAM_CACHE_PREFIX}[string tolower $handle]"
}

proc streamCacheHandle {state} {
    set streamHandle [dict get $state stream handle]
    set page [dict get $state page]
    set pageHandleVal [pageHandle $page]
    set profileUniqueId [dict get $state profileInfo uniqueId]
    return [string tolower [expr {$streamHandle ne "" ? $streamHandle : 
                                 ($pageHandleVal ne "" ? $pageHandleVal : 
                                  ($profileUniqueId ne "" ? $profileUniqueId : ""))}]]
}

proc mergeLiveStats {{current {}} {incoming {}}} {
    if {$incoming eq "" || ![dict size $incoming]} {
        return $current
    }
    set defaults [emptyState]
    set merged [dict merge [dict get $defaults liveStats] $current]
    foreach key {viewerCount totalViewers likeCount shareCount followerCount} {
        if {[dict exists $incoming $key] && [dict get $incoming $key] ne ""} {
            dict set merged $key [dict get $incoming $key]
        }
    }
    if {[dict exists $incoming lastUpdatedUtc]} {
        dict set merged lastUpdatedUtc [dict get $incoming lastUpdatedUtc]
    }
    return $merged
}

proc cacheStreamSnapshot {state} {
    # Simplified implementation
    return
}

proc cachedStreamSnapshot {handle} {
    # Simplified implementation
    return ""
}

proc mergeStreamSnapshot {state snapshot} {
    if {$snapshot eq ""} {
        return $state
    }
    set sameHandle [expr {([dict get $state stream handle] eq "" || [dict get $snapshot handle] eq "" || [dict get $state stream handle] eq [dict get $snapshot handle])}]
    if {!$sameHandle} {
        return $state
    }
    dict set state liveStats [mergeLiveStats [dict get $state liveStats] [dict get $snapshot liveStats]]
    if {![llength [dict get $state chatMessages]] && [llength [dict get $snapshot chatMessages]]} {
        dict set state chatMessages [dict get $snapshot chatMessages]
    }
    if {![dict size [dict get $state participants]] && [dict exists $snapshot participants]} {
        dict set state participants [dict get $snapshot participants]
        dict set state participantsTruncated [dict get $snapshot participantsTruncated]
    }
    return $state
}

proc patchState {tabId patch} {
    set state [getState $tabId]
    set newState [dict merge $state $patch]
    return [setState $tabId $newState]
}

proc addMedia {tabId entries source} {
    if {![string is integer $tabId] || $tabId < 0} {
        return
    }
    set state [getState $tabId]
    set mediaKeyProc {item}
    proc mediaKeyProc:item {item} {
        if {[catch {
            set url [dict get $item url]
            set parsed [split $url "/"]
            set path [lindex $parsed end]
            return "[dict get $item protocol]|[expr {[dict get $item audioOnly] ? 1 : 0}]|$path"
        } err]} {
            return [dict get $item url]
        }
    }
    set expiryProc {item}
    proc expiryProc:item {item} {
        if {[catch {
            set url [dict get $item url]
            set query [lindex [split $url "?"] 1]
            if {$query ne ""} {
                foreach param [split $query "&"] {
                    set parts [split $param "="]
                    if {[lindex $parts 0] eq "expire"} {
                        return [lindex $parts 1]
                    }
                }
            }
            return 0
        } err]} {
            return 0
        }
    }
    set byUrl [dict create]
    foreach item [dict get $state media] {
        set key [mediaKeyProc:item $item]
        set previous [dict get $byUrl $key]
        if {$previous eq "" || [expiryProc:item $item] >= [expiryProc:item $previous]} {
            dict set byUrl $key $item
        }
    }
    foreach raw $entries {
        set classified ""
        if {[string is string $raw]} {
            set classified [::core::classifyMediaUrl $raw]
        } else {
            set classified [::core::classifyMediaUrl [dict get $raw url]]
        }
        if {$classified eq ""} {
            continue
        }
        set enriched ""
        if {[dict size $raw] > 0} {
            set enriched [dict merge $classified $raw]
            dict set enriched url [dict get $classified url]
        } else {
            set enriched $classified
        }
        set key [mediaKeyProc:item $enriched]
        set previous [dict get $byUrl $key]
        set candidate [dict create]
        if {$previous ne ""} {
            set candidate [dict merge $previous $enriched]
        } else {
            set candidate $enriched
        }
        dict set candidate source [expr {$previous ne "" && [dict exists $previous source] ? [dict get $previous source] : $source}]
        dict set candidate discoveredAtUtc [expr {$previous ne "" && [dict exists $previous discoveredAtUtc] ? [dict get $previous discoveredAtUtc] : [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]}]
        if {$previous eq "" || [expiryProc:item $candidate] >= [expiryProc:item $previous]} {
            dict set byUrl $key $candidate
        }
    }
    dict set state media [lrange [dict values $byUrl] end-[expr {$::MAX_MEDIA-1}] end]
    setState $tabId $state
}

proc addCaption {tabId caption} {
    set state [getState $tabId]
    set receivedAtUtc [expr {[dict exists $caption receivedAtUtc] ? [dict get $caption receivedAtUtc] : [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]}]
    set timestamp [clock scan $receivedAtUtc]
    if {[dict get $caption source] eq "dom"} {
        set recentWebSocket ""
        foreach item [lreverse [dict get $state captions]] {
            if {[dict get $item method] eq "WebcastCaptionMessage"} {
                set recentWebSocket $item
                break
            }
        }
        if {$recentWebSocket ne "" && 
            abs($timestamp - [clock scan [dict get $recentWebSocket receivedAtUtc]]) < 8000 &&
            $::core::captionsOverlap $caption $recentWebSocket} {
            return
        }
        set last [lindex [dict get $state captions] end]
        if {$last ne "" && [dict get $last source] eq "dom" &&
            $timestamp - [clock scan [dict get $last receivedAtUtc]] < 2500 &&
            $::core::captionsOverlap $last $caption} {
            set replacement ""
            if {[string length [$::core::captionText $caption]] >= [string length [$::core::captionText $last]]} {
                set replacement [dict merge $caption [dict create receivedAtUtc $receivedAtUtc]]
            } else {
                set replacement [dict merge $last [dict create receivedAtUtc $receivedAtUtc]]
            }
            set captions [dict get $state captions]
            set captions [lreplace $captions end end $replacement]
            dict set state captions $captions
            dict set state captionInfo [$::core::mergeObservedCaptionInfo [dict get $state captionInfo] $replacement]
            setState $tabId $state
            return
        }
    }
    set entry [dict merge $caption [dict create receivedAtUtc $receivedAtUtc]]
    set key [expr {[dict exists $entry sentenceId] ? [dict get $entry sentenceId] : 
                  ([dict exists $entry sequenceId] ? [dict get $entry sequenceId] : 
                   [join [lmap content [dict get $entry contents] {
                       format "%s:%s" [dict get $content lang] [dict get $content text]
                   }] "\n"])}]
    set duplicate false
    foreach item [lrange [dict get $state captions] end-19 end] {
        set itemKey [expr {[dict exists $item sentenceId] ? [dict get $item sentenceId] : 
                          ([dict exists $item sequenceId] ? [dict get $item sequenceId] : 
                           [join [lmap content [dict get $item contents] {
                               format "%s:%s" [dict get $content lang] [dict get $content text]
                           }] "\n"])}]
        if {$itemKey eq $key} {
            set duplicate true
            break
        }
    }
    if {$duplicate} {
        return
    }
    if {[dict get $entry method] eq "WebcastCaptionMessage"} {
        set filteredCaptions {}
        foreach item [dict get $state captions] {
            if {![expr {[dict get $item source] eq "dom" &&
                       abs($timestamp - [clock scan [dict get $item receivedAtUtc]]) < 8000 &&
                       $::core::captionsOverlap $item $entry}]} {
                lappend filteredCaptions $item
            }
        }
        dict set state captions $filteredCaptions
    }
    dict with state captions {
        lappend captions $entry
        set captions [lrange $captions end-[expr {$::MAX_CAPTIONS-1}] end]
    }
    dict set state captionInfo [$::core::mergeObservedCaptionInfo [dict get $state captionInfo] $entry]
    setState $tabId $state
}

proc chatKey {author content} {
    return "[string tolower $author]\n[string tolower $content]"
}

proc participantKey {message {fallbackAuthor ""}} {
    if {[dict exists $message userId]} {
        return "id:[dict get $message userId]"
    }
    if {[dict exists $message displayId]} {
        return "handle:[$::core::normalizedIdentity [dict get $message displayId]]"
    }
    set name [expr {[dict exists $message author] ? [dict get $message author] : 
                   ([dict exists $message nickname] ? [dict get $message nickname] : $fallbackAuthor)}]
    if {$name eq ""} {
        set name "chat"
    }
    return "name:[$::core::normalizedIdentity $name]"
}

proc participantMuted {state settings key} {
    set streamMutes [dict get $state streamMutes]
    set permanentMutes [dict get $settings permanentMutes]
    return [expr {[lsearch -exact $streamMutes $key] >= 0 || [lsearch -exact $permanentMutes $key] >= 0}]
}

proc cleanSpeechPayload {value} {
    set cleaned [string map {"\u0000" " " "\u0001" " " "\u0002" " " "\u0003" " " "\u0004" " " "\u0005" " " "\u0006" " " "\u0007" " " "\u0008" " " "\u0009" " " "\u000A" " " "\u000B" " " "\u000C" " " "\u000D" " " "\u000E" " " "\u000F" " " "\u0010" " " "\u0011" " " "\u0012" " " "\u0013" " " "\u0014" " " "\u0015" " " "\u0016" " " "\u0017" " " "\u0018" " " "\u0019" " " "\u001A" " " "\u001B" " " "\u001C" " " "\u001D" " " "\u001E" " " "\u001F" " " "\u007F" " " "\u0080" " " "\u0081" " " "\u0082" " " "\u0083" " " "\u0084" " " "\u0085" " " "\u0086" " " "\u0087" " " "\u0088" " " "\u0089" " " "\u008A" " " "\u008B" " " "\u008C" " " "\u008D" " " "\u008E" " " "\u008F" " " "\u0090" " " "\u0091" " " "\u0092" " " "\u0093" " " "\u0094" " " "\u0095" " " "\u0096" " " "\u0097" " " "\u0098" " " "\u0099" " " "\u009A" " " "\u009B" " " "\u009C" " " "\u009D" " " "\u009E" " " "\u009F" " "} $value]
    regsub -all {\u200b|\u200c|\u200d|\u200e|\u200f|\u202a|\u202b|\u202c|\u202d|\u202e|\u2060|\u2061|\u2062|\u2063|\u2064|\u2065|\u2066|\u2067|\u2068|\u2069|\u206a|\u206b|\u206c|\u206d|\u206e|\u206f|\ufeff} $cleaned "" cleaned
    regsub -all {\ufe00|\ufe01|\ufe02|\ufe03|\ufe04|\ufe05|\ufe06|\ufe07|\ufe08|\ufe09|\ufe0a|\ufe0b|\ufe0c|\ufe0d|\ufe0e|\ufe0f|\u200d} $cleaned "" cleaned
    regsub -all {\ud83d[\ude00-\ude4f]|\ud83c[\udf00-\udfff]|\ud83d[\ude80-\udeff]|\ud83d[\udc00-\uddff]} $cleaned " " cleaned
    regsub -all {\s+} $cleaned " " cleaned
    return [string trim $cleaned]
}

proc speechLanguage {settings item text} {
    if {[dict get $settings speechLanguage] eq "auto" && [regexp {[äöüÄÖÜß]} $text]} {
        return "de-DE"
    }
    return [$::core::resolveSpeechLanguage [dict get $settings speechLanguage] [dict get $item contentLanguage]]
}

proc queueSpeechForTab {tabId state item} {
    if {![dict get $state speech enabled] || [dict get $item muted]} {
        return
    }
    set settings [getSettings]
    if {[dict get $settings gameModeEnabled] && [$::core::shouldFilterGameModeSpeech $item [dict get $state participants] [dict get $state chatMessages]]} {
        return
    }
    set text [$::core::composeSpeechText $item [dict create \
        teamTag [dict get $state stream teamTag] \
        speakNames [expr {[dict get $settings speakNames] ne false}] \
        shortenNames [booleanValue [dict get $settings shortenNames]]]]
    set text [cleanSpeechPayload $text]
    if {$text eq ""} {
        return
    }
    set key "[::$core::spokenNickname [dict get $item author]]|$text"
    set key [string tolower [regsub -all {\s+} $key " "]]
    set lastAt [expr {[dict exists $state speech lastSpokenAtUtc] ? [clock scan [dict get $state speech lastSpokenAtUtc]] : 0}]
    if {$key ne "" && [dict get $state speech lastSpokenKey] eq $key && [clock seconds] - $lastAt <= 20000} {
        return
    }
    dict set state speech [dict merge [dict get $state speech] [dict create \
        status "Vorlesen aktiv · Zeile vorgemerkt." \
        lastSpokenKey $key \
        lastSpokenAtUtc [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"] \
        queueDepth [expr {min(5, [dict get $state speech queueDepth] + 1)}]]]
    setState $tabId $state
    # Simulate sending to offscreen
}

proc participantAliases {participant {fallbackKey ""}} {
    set aliases [list]
    if {$fallbackKey ne ""} {
        lappend aliases $fallbackKey
    }
    if {[dict exists $participant userId]} {
        lappend aliases "id:[dict get $participant userId]"
    }
    if {[dict exists $participant displayId]} {
        lappend aliases "handle:[$::core::normalizedIdentity [dict get $participant displayId]]"
    }
    if {[dict exists $participant name]} {
        lappend aliases "name:[$::core::normalizedIdentity [dict get $participant name]]"
    }
    return [lsort -unique $aliases]
}

proc relayTargetTabId {state} {
    set targetTabId [dict get $state chatTargetTabId]
    if {[string is integer $targetTabId] && $targetTabId >= 0} {
        return $targetTabId
    }
    return ""
}

proc relayToEmbedTab {sourceTabId state type payload} {
    set targetTabId [relayTargetTabId $state]
    if {$targetTabId eq "" || ([dict exists $payload relayedFromTabId] && [dict get $payload relayedFromTabId] eq $sourceTabId)} {
        return
    }
    # Simulate checking target tab
    set targetTabExists true
    if {!$targetTabExists} {
        return
    }
    set relayPayload [dict merge $payload [dict create relayedFromTabId $sourceTabId]]
    switch $type {
        "chat" {
            addChatMessage $targetTabId $relayPayload
        }
        "gift" {
            addGiftMessage $targetTabId $relayPayload
        }
        "live" {
            addLiveEvent $targetTabId $relayPayload
        }
    }
}

proc updateParticipant {state raw author {patch {}}} {
    set requestedKey [participantKey $raw $author]
    set matchedEntry ""
    dict for {key participant} [dict get $state participants] {
        if {[$::core::sameParticipant $participant [dict merge $raw [dict create name $author]]]} {
            set matchedEntry [list $key $participant]
            break
        }
    }
    set key [expr {[dict exists [dict get $state participants] $requestedKey] ? $requestedKey : 
                  ($matchedEntry ne "" ? [lindex $matchedEntry 0] : $requestedKey)}]
    set existing [dict get $state participants $key]
    if {$existing eq "" && [dict size [dict get $state participants]] >= $::MAX_PARTICIPANTS} {
        dict set state participantsTruncated true
        return [list key $key participant ""]
    }
    set participant [dict create key $key]
    if {$existing ne ""} {
        set participant [$::core::mergeParticipantRecord $existing $raw $author $patch]
    } else {
        set participant [$::core::mergeParticipantRecord "" $raw $author $patch]
    }
    dict set state participants $key $participant
    return [list key $key participant $participant]
}

proc observeTeamTag {state author content} {
    if {[dict get $state stream teamTag] ne ""} {
        return [dict get $state stream teamTag]
    }
    set result [$::core::accumulateTeamEvidence [dict get $state stream teamEvidence] $author $content [lmap item [dict get $state chatMessages] {dict get $item content}]]
    dict set state stream teamEvidence [dict get $result evidence]
    if {[dict get $result teamTag] ne ""} {
        dict set state stream teamTag [dict get $result teamTag]
        set updatedMessages {}
        foreach item [dict get $state chatMessages] {
            lappend updatedMessages [dict merge $item [dict create \
