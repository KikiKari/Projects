#!/usr/bin/env tclsh
# background.js — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:release/0.7.0/tiktok-live-companion-extension-0.7.0/background.js
# auch in: Projects@TikTok-Live-Companion:release/0.6.0/tiktok-live-companion-extension-0.6.0/background.js
# auch in: Projects@TikTok-Live-Companion-Android:release/0.7.0/tiktok-live-companion-extension-0.7.0/background.js
# auch in: Projects@TikTok-Live-Companion-Android:release/0.6.0/tiktok-live-companion-extension-0.6.0/background.js
# auch in: 2 weiteren Fundstellen
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

package require http
package require json
package require tls

# Constants
set STATE_PREFIX "tlc-tab-"
set HOOK_SCRIPT_ID "tiktok-live-companion-ws-hook"
set SETTINGS_KEY "tlc-settings"
set PROFILE_PREFIX "tlc-profile-"
set MAX_MEDIA 60
set MAX_CAPTIONS 2000
set MAX_CHAT 50
set MAX_EVENT_IDS 500
set MAX_DEBUG 500
set MAX_PARTICIPANTS 5000

# Global state
array set core {}

# Helper functions
proc stateKey {tabId} {
    return "${::STATE_PREFIX}${tabId}"
}

proc emptyState {} {
    return [dict create \
        page [dict create url "" title "" scannedAtUtc null] \
        captionInfo [dict create present false open null supportLang {} location null showType null] \
        profileInfo [dict create present false uniqueId "" nickname "" signature "" avatarUrl "" verified false followingCount 0 followerCount 0 likeCount 0 language "" region ""] \
        aiSummaryInfo [dict create present false summary "" generatedAtUtc null] \
        menuCaptionAvailable false \
        menuCaptionActive false \
        hook [dict create armed false installed false connected false lastError null] \
        stream [dict create key "" handle "" roomId "" teamTag "" teamEvidence {}] \
        liveStats [dict create \
            viewerCount null \
            totalViewers null \
            likeCount null \
            followEvents 0 \
            shareEvents 0 \
            shareCount null \
            followerCount null \
            lastUpdatedUtc null \
            recentEventIds {}] \
        selectedQuality null \
        playerState [dict create \
            available false playing false muted false elapsedText "" pipActive false fullscreenActive false \
            volume 1 volumePercent 100 volumeGainDb 0 peakDbfs null \
            limiterEnabled false limiterThresholdDbfs -6 limiterReductionDb 0 \
            connectedStreams 0 multiGuest false] \
        media {} \
        captions {} \
        chatMessages {} \
        participants {} \
        participantsTruncated false \
        streamMutes {} \
        recentGiftIds {} \
        debug [dict create enabled false entries {}]]
}

proc getState {tabId} {
    # Placeholder implementation - would need actual storage mechanism
    set key [stateKey $tabId]
    if {[info exists ::storage($key)]} {
        return $::storage($key)
    } else {
        return [emptyState]
    }
}

proc pageHandle {page} {
    if {[dict exists $page url]} {
        set url [dict get $page url]
        if {[regexp {^https?://[^/]+/@([^/]+)} $url -> handle]} {
            return [string tolower $handle]
        }
    }
    return ""
}

proc profileKey {handle} {
    return "${::PROFILE_PREFIX}[string tolower $handle]"
}

proc cacheProfile {profile} {
    # Placeholder implementation
}

proc cachedProfile {handle} {
    # Placeholder implementation
    return {}
}

proc addDebug {tabId event {detail {}}} {
    # Placeholder implementation
}

proc redactUrl {raw} {
    if {[catch {set url [::http::formatQuery $raw]}]} {
        return "ungültig"
    }
    return $url
}

proc setState {tabId state} {
    set key [stateKey $tabId]
    set ::storage($key) $state
    # Would send message in real implementation
    return $state
}

proc getSettings {} {
    # Placeholder implementation
    return [dict create \
        autoHook false \
        keepSpeechActive false \
        speechVolume 0.5 \
        speechLanguage "auto" \
        speakNames true \
        shortenNames false \
        serviceUrl "http://127.0.0.1:43117" \
        pairingCode "" \
        songRecognitionEnabled false \
        permanentMutes {}]
}

proc setSettings {patch} {
    # Placeholder implementation
    set settings [getSettings]
    dict for {key value} $patch {
        dict set settings $key $value
    }
    return $settings
}

proc loopbackServiceUrl {value} {
    if {[catch {set url [::http::formatQuery $value]}]} {
        return ""
    }
    if {![regexp {^http://(127\.0\.0\.1|localhost)(:\d+)?(/.*)?$} $url]} {
        return ""
    }
    return [regsub {(/.*)?$} $url ""]
}

proc profileCompleteness {profile} {
    set fields [list uniqueId nickname signature followingCount followerCount likeCount]
    set count 0
    foreach field $fields {
        if {[dict exists $profile $field] && [dict get $profile $field] ne ""} {
            incr count
        }
    }
    return $count
}

proc mergeProfile {current incoming} {
    if {![dict exists $incoming present] || ![dict get $incoming present]} {
        return $current
    }
    if {![dict exists $current present] || ![dict get $current present] || 
        [profileCompleteness $incoming] >= [profileCompleteness $current]} {
        return $incoming
    }
    set result $incoming
    dict for {key value} $current {
        if {![dict exists $result $key] || [dict get $result $key] eq ""} {
            dict set result $key $value
        }
    }
    dict set result live [expr {[dict get $current live] || [dict get $incoming live]}]
    return $result
}

proc patchState {tabId patch} {
    set state [getState $tabId]
    dict for {key value} $patch {
        dict set state $key $value
    }
    setState $tabId $state
}

proc addMedia {tabId entries source} {
    if {![string is integer $tabId] || $tabId < 0} {
        return
    }
    set state [getState $tabId]
    
    # Create map of existing media
    array set byUrl {}
    foreach item [dict get $state media] {
        if {[dict exists $item url]} {
            set url [dict get $item url]
            set key "$source|$url"
            set byUrl($key) $item
        }
    }
    
    # Process new entries
    foreach raw $entries {
        set classified {}
        if {[string is list $raw] && [llength $raw] > 1} {
            # Assume it's a dict-like structure
            if {[dict exists $raw url]} {
                set classified [classifyMediaUrl [dict get $raw url]]
            }
        } else {
            set classified [classifyMediaUrl $raw]
        }
        
        if {[dict size $classified] > 0} {
            set enriched $classified
            if {[string is list $raw] && [llength $raw] > 1} {
                dict for {k v} $raw {
                    if {$k ne "url"} {
                        dict set enriched $k $v
                    }
                }
                dict set enriched url [dict get $classified url]
            }
            
            set key "$source|[dict get $enriched url]"
            if {![info exists byUrl($key)] || 
                [dict get $enriched discoveredAtUtc] > [dict get $byUrl($key) discoveredAtUtc]} {
                dict set enriched source $source
                dict set enriched discoveredAtUtc [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]
                set byUrl($key) $enriched
            }
        }
    }
    
    # Convert back to list and limit
    set mediaList {}
    foreach item [array names byUrl] {
        lappend mediaList $byUrl($item)
    }
    set mediaList [lrange $mediaList end-[expr {$::MAX_MEDIA-1}] end]
    dict set state media $mediaList
    setState $tabId $state
}

proc addCaption {tabId caption} {
    set state [getState $tabId]
    if {![dict exists $caption receivedAtUtc]} {
        dict set caption receivedAtUtc [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]
    }
    set captions [dict get $state captions]
    lappend captions $caption
    set captions [lrange $captions end-[expr {$::MAX_CAPTIONS-1}] end]
    dict set state captions $captions
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
        return "handle:[string tolower [dict get $message displayId]]"
    }
    set name [dict get $message author]
    if {$name eq ""} {
        set name [dict get $message nickname]
    }
    if {$name eq ""} {
        set name $fallbackAuthor
    }
    if {$name eq ""} {
        set name "chat"
    }
    return "name:[string tolower $name]"
}

proc participantMuted {state settings key} {
    set streamMutes [dict get $state streamMutes]
    set permanentMutes [dict get $settings permanentMutes]
    return [expr {[lsearch -exact $streamMutes $key] >= 0 || [lsearch -exact $permanentMutes $key] >= 0}]
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
        lappend aliases "handle:[string tolower [dict get $participant displayId]]"
    }
    if {[dict exists $participant name]} {
        lappend aliases "name:[string tolower [dict get $participant name]]"
    }
    return [lsort -unique $aliases]
}

proc updateParticipant {stateVar raw author {patch {}}} {
    upvar $stateVar state
    
    set requestedKey [participantKey $raw $author]
    set matchedKey ""
    dict for {key participant} [dict get $state participants] {
        if {[sameParticipant $participant [dict merge $raw [dict create name $author]]]} {
            set matchedKey $key
            break
        }
    }
    
    set key $requestedKey
    if {![dict exists $state participants $requestedKey] && $matchedKey ne ""} {
        set key $matchedKey
    }
    
    set existing {}
    if {[dict exists $state participants $key]} {
        set existing [dict get $state participants $key]
    }
    
    if {[dict size $existing] == 0 && [dict size [dict get $state participants]] >= $::MAX_PARTICIPANTS} {
        dict set state participantsTruncated true
        return [list key $key participant {}]
    }
    
    set participant [mergeParticipantRecord $existing $raw $author $patch]
    dict set state participants $key $participant
    return [list key $key participant $participant]
}

proc observeTeamTag {stateVar author content} {
    upvar $stateVar state
    
    if {[dict get $state stream teamTag] ne ""} {
        return [dict get $state stream teamTag]
    }
    
    set evidence [dict get $state stream teamEvidence]
    set chatMessages [dict get $state chatMessages]
    set contents {}
    foreach item $chatMessages {
        lappend contents [dict get $item content]
    }
    
    set result [accumulateTeamEvidence $evidence $author $content $contents]
    dict set state stream teamEvidence [dict get $result evidence]
    
    if {[dict exists $result teamTag]} {
        set teamTag [dict get $result teamTag]
        dict set state stream teamTag $teamTag
        
        set newMessages {}
        foreach item $chatMessages {
            dict set item author [stripTeamTag [dict get $item author] $teamTag]
            dict set item content [stripTeamTag [dict get $item content] $teamTag]
            lappend newMessages $item
        }
        dict set state chatMessages $newMessages
        
        set participants [dict get $state participants]
        dict for {pKey participant} $participants {
            dict set participant name [stripTeamTag [dict get $participant name] $teamTag]
            dict set participants $pKey $participant
        }
        dict set state participants $participants
    }
    
    return [dict get $state stream teamTag]
}

proc resetStreamData {stateVar identity} {
    upvar $stateVar state
    
    dict set state stream key "[dict get $identity handle]|[dict get $identity roomId]"
    dict set state stream handle [dict get $identity handle]
    dict set state stream roomId [dict get $identity roomId]
    dict set state stream teamTag ""
    dict set state stream teamEvidence {}
    dict set state chatMessages {}
    dict set state participants {}
    dict set state participantsTruncated false
    dict set state streamMutes {}
    dict set state recentGiftIds {}
    dict set state liveStats [dict get [emptyState] liveStats]
}

proc applyStreamIdentity {stateVar {identity {}}} {
    upvar $stateVar state
    
    set handle [string tolower [dict get $identity handle]]
    if {$handle eq "" && [dict exists $state stream handle]} {
        set handle [dict get $state stream handle]
    }
    
    set roomId [dict get $identity roomId]
    if {$roomId eq "" && [dict exists $state stream roomId]} {
        set roomId [dict get $state stream roomId]
    }
    
    set currentHandle ""
    set currentRoomId ""
    if {[dict exists $state stream handle]} {
        set currentHandle [dict get $state stream handle]
    }
    if {[dict exists $state stream roomId]} {
        set currentRoomId [dict get $state stream roomId]
    }
    
    set changed [streamIdentityChanged [dict create handle $currentHandle roomId $currentRoomId] \
                                     [dict create handle $handle roomId $roomId]]
    
    if {$changed} {
        resetStreamData state [dict create handle $handle roomId $roomId]
    } else {
        dict set state stream handle $handle
        dict set state stream roomId $roomId
        dict set state stream key "$handle|$roomId"
    }
}

proc addChatMessage {tabId rawMessage} {
    if {![string is integer $tabId] || $tabId < 0} {
        return
    }
    
    set rawAuthor [sanitizeChatText [dict get $rawMessage nickname]]
    if {$rawAuthor eq ""} {
        set rawAuthor [sanitizeChatText [dict get $rawMessage displayId]]
    }
    if {$rawAuthor eq ""} {
        set rawAuthor [sanitizeChatText [dict get $rawMessage author]]
    }
    if {$rawAuthor eq ""} {
        set rawAuthor "Chat"
    }
    
    set content [sanitizeChatText [dict get $rawMessage content]]
    if {$content eq ""} {
        return
    }
    
    set state [getState $tabId]
    set teamTag [observeTeamTag state $rawAuthor $content]
    set author [stripTeamTag $rawAuthor $teamTag]
    if {$author eq ""} {
        set author "Chat"
    }
    set content [stripTeamTag $content $teamTag]
    
    if {![dict exists $rawMessage receivedAtUtc]} {
        dict set rawMessage receivedAtUtc [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]
    }
    set receivedAtUtc [dict get $rawMessage receivedAtUtc]
    set dedupeKey [chatKey $author $content]
    set receivedAt [clock scan $receivedAtUtc]
    
    set duplicate false
    foreach item [dict get $state chatMessages] {
        set existingKey [dict get $item dedupeKey]
        if {![dict exists $item dedupeKey]} {
            set existingKey [chatKey [dict get $item author] [dict get $item content]]
        }
        set existingAt [clock scan [dict get $item receivedAtUtc]]
        if {$existingKey eq $dedupeKey && abs($receivedAt - $existingAt) <= 15000} {
            set duplicate true
            break
        }
    }
    
    if {$duplicate} {
        return
    }
    
    set participantResult [updateParticipant state $rawMessage $author]
    set participantKey [lindex $participantResult 1]
    set participant [lindex $participantResult 3]
    
    if {[dict size $participant] > 0} {
        dict incr participant messageCount
        dict incr participant wordCount [wordCount $content]
    }
    
    set settings [getSettings]
    set chatMessages [dict get $state chatMessages]
    set newItem [dict create \
        messageId [dict get $rawMessage messageId] \
        author $author \
        content $content \
        userId [dict get $rawMessage userId] \
        displayId [dict get $rawMessage displayId] \
        participantKey $participantKey \
        muted [participantMuted $state $settings $participantKey] \
        contentLanguage [dict get $rawMessage contentLanguage] \
        source [dict get $rawMessage source] \
        receivedAtUtc $receivedAtUtc \
        dedupeKey $dedupeKey]
    lappend chatMessages $newItem
    set chatMessages [lrange $chatMessages end-[expr {$::MAX_CHAT-1}] end]
    dict set state chatMessages $chatMessages
    setState $tabId $state
}

proc addGiftMessage {tabId rawMessage} {
    if {![string is integer $tabId] || $tabId < 0} {
        return
    }
    
    if {[dict get $rawMessage source] eq "websocket" && [dict get $rawMessage repeatEnd] eq "false"} {
        return
    }
    
    set state [getState $tabId]
    set teamTag [dict get $state stream teamTag]
    set author [stripTeamTag [dict get $rawMessage nickname] $teamTag]
    if {$author eq ""} {
        set author [stripTeamTag [dict get $rawMessage displayId] $teamTag]
    }
    if {$author eq ""} {
        set author [stripTeamTag [dict get $rawMessage author] $teamTag]
    }
    if {$author eq ""} {
        set author "Chat"
    }
    
    set count [expr {max(1, int([dict get $rawMessage repeatCount]))}]
    if {$count eq ""} {
        set count 1
    }
    
    set receivedAt [clock scan [dict get $rawMessage receivedAtUtc]]
    set timeBucket [expr {int($receivedAt / 15000)}]
    set correlationId "gift-match:[string tolower $author]:$count:$timeBucket"
    set messageId ""
    if {[dict exists $rawMessage messageId]} {
        set messageId "gift:[dict get $rawMessage messageId]"
    }
    
    set recentGiftIds [dict get $state recentGiftIds]
    if {($messageId ne "" && [lsearch -exact $recentGiftIds $messageId] >= 0) || 
        [lsearch -exact $recentGiftIds $correlationId] >= 0} {
        return
    }
    
    lappend recentGiftIds $messageId $correlationId
    set recentGiftIds [lrange $recentGiftIds end-[expr {$::MAX_EVENT_IDS-1}] end]
    dict set state recentGiftIds $recentGiftIds
    
    set participantResult [updateParticipant state $rawMessage $author]
    set participant [lindex $participantResult 3]
    
    if {[dict size $participant] > 0} {
        dict incr participant giftEventCount
        dict incr participant giftItemCount $count
    }
    
    setState $tabId $state
}

proc greaterNumericString {current incoming} {
    if {$incoming eq ""} {
        return $current
    }
    if {$current eq ""} {
        return $incoming
    }
    if {[catch {set result [expr {wide($incoming) >= wide($current) ? $incoming : $current}]}]} {
        return $incoming
    }
    return $result
}

proc addLiveEvent {tabId liveEvent} {
    set state [getState $tabId]
    set stats [dict get $state liveStats]
    if {[dict size $stats] == 0} {
        set stats [dict get [emptyState] liveStats]
    }
    
    set eventId ""
    if {[dict exists $liveEvent messageId]} {
        set eventId "[dict get $liveEvent method]:[dict get $liveEvent messageId]"
    }
    
    if {$eventId ne "" && [lsearch -exact [dict get $stats recentEventIds] $eventId] >= 0} {
        return
    }
    
    switch [dict get $liveEvent method] {
        "WebcastRoomUserSeqMessage" {
            if {[dict exists $liveEvent viewerCount]} {
                dict set stats viewerCount [dict get $liveEvent viewerCount]
            }
            if {[dict exists $liveEvent totalViewers]} {
                dict set stats totalViewers [greaterNumericString [dict get $stats totalViewers] [dict get $liveEvent totalViewers]]
            }
        }
        "WebcastLikeMessage" {
            if {[dict exists $liveEvent likeCount]} {
                dict set stats likeCount [greaterNumericString [dict get $stats likeCount] [dict get $liveEvent likeCount]]
            }
        }
        "WebcastSocialMessage" {
            if {[dict get $liveEvent kind] eq "follow"} {
                dict incr stats followEvents
            }
            if {[dict get $liveEvent kind] eq "share"} {
                dict incr stats shareEvents
            }
            if {[dict exists $liveEvent followerCount]} {
                dict set stats followerCount [greaterNumericString [dict get $stats followerCount] [dict get $liveEvent followerCount]]
            }
            if {[dict exists $liveEvent shareCount]} {
                dict set stats shareCount [greaterNumericString [dict get $stats shareCount] [dict get $liveEvent shareCount]]
            }
        }
    }
    
    if {$eventId ne ""} {
        set recentEventIds [dict get $stats recentEventIds]
        lappend recentEventIds $eventId
        set recentEventIds [lrange $recentEventIds end-[expr {$::MAX_EVENT_IDS-1}] end]
        dict set stats recentEventIds $recentEventIds
    }
    
    if {![dict exists $liveEvent receivedAtUtc]} {
        dict set liveEvent receivedAtUtc [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]
    }
    dict set stats lastUpdatedUtc [dict get $liveEvent receivedAtUtc]
    dict set state liveStats $stats
    setState $tabId $state
}

proc ensureHookRegistered {{persistAcrossSessions false}} {
    # Placeholder implementation
}

proc unregisterHook {} {
    # Placeholder implementation
}

proc setHookFlag {tabId enabled} {
    # Placeholder implementation
    set state [getState $tabId]
    dict set state hook armed $enabled
    dict set state hook installed false
    dict set state hook connected false
    dict set state hook lastError null
    if {$enabled} {
        dict set state liveStats [dict get [emptyState] liveStats]
    }
    setState $tabId $state
}

proc resetTabWithHook {tabId} {
    # Placeholder implementation
    set state [emptyState]
    # Would get tab info in real implementation
    dict set state page url "https://www.tiktok.com/"
    dict set state page title "TikTok"
    dict set state hook armed true
    setState $tabId $state
}

proc waitForTabComplete {tabId expectedPrefix {timeoutMs 12000}} {
    # Placeholder implementation
}

proc forceProfileRefresh {tabId} {
    # Placeholder implementation
}

proc classifyMediaUrl {url} {
    # Placeholder implementation
    return [dict create url $url protocol "unknown" audioOnly false]
}

proc sanitizeChatText {text} {
    # Placeholder implementation
    return [string trim $text]
}

proc stripTeamTag {text teamTag} {
    # Placeholder implementation
    return $text
}

proc sameParticipant {p1 p2} {
    # Placeholder implementation
    return false
}

proc mergeParticipantRecord {existing raw author patch} {
    # Placeholder implementation
    set result [dict create \
        key "" \
        name $author \
        messageCount 0 \
        wordCount 0 \
        giftEventCount 0 \
        giftItemCount 0]
    dict for {key value} $existing {
        dict set result $key $value
    }
    dict for {key value} $raw {
        dict set result $key $value
    }
    dict for {key value} $patch {
        dict set result $key $value
    }
    return $result
}

proc accumulateTeamEvidence {evidence author content contents} {
    # Placeholder implementation
    return [dict create evidence $evidence teamTag ""]
}

proc streamIdentityChanged {current incoming} {
    # Placeholder implementation
    return [expr {[dict get $current handle] ne [dict get $incoming handle] || 
                  [dict get $current roomId] ne [dict get $incoming roomId]}]
}

proc wordCount {content} {
    # Placeholder implementation
    return [llength [split $content " "]]
}

proc normalizedIdentity {id} {
    # Placeholder implementation
    return [string tolower $id]
}

# Main event loop placeholder
puts "Background service started"

# Simulate some basic functionality
if {[info exists argv0] && $argv0 eq [info script]} {
    # Example usage
    set testState [emptyState]
    puts "Empty state created"
    
    # Test adding media
    addMedia 1 [list "https://example.com/video.mp4"] "test"
    puts "Media added"
    
    # Test getting state
    set state [getState 1]
    puts "State retrieved"
}
