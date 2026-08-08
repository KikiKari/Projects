#!/usr/bin/env perl
# background.js — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/browser-extension/background.js
# auch in: Projects@TikTok-Live-Companion:release/0.7.1/tiktok-live-companion-extension-0.7.1/background.js
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/background.js
# auch in: Projects@TikTok-Live-Companion-Android:release/0.7.1/tiktok-live-companion-extension-0.7.1/background.js
# auch in: 2 weiteren Fundstellen
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use JSON::PP;
use Data::UUID;
use URI::Escape;
use Time::HiRes qw(time);
use List::Util qw(max min);
use Scalar::Util qw(looks_like_number);

my $STATE_PREFIX = "tlc-tab-";
my $LEGACY_HOOK_SCRIPT_ID = "tiktok-live-companion-ws-hook";
my $SETTINGS_KEY = "tlc-settings";
my $SERVICE_INSTALL_KEY = "tlc-service-install";
my $PROFILE_PREFIX = "tlc-profile-";
my $STREAM_CACHE_PREFIX = "tlc-stream-";
my $MAX_MEDIA = 60;
my $MAX_CAPTIONS = 2000;
my $MAX_CHAT = 500;
my $MAX_EVENT_IDS = 500;
my $MAX_DEBUG = 500;
my $MAX_PARTICIPANTS = 5000;

# Placeholder for core functionality - would need to be implemented or imported
package TLC_CONTENT_CORE {
    sub EMPTY_PROFILE_INFO { return {} }
    sub EMPTY_AI_SUMMARY_INFO { return {} }
    sub limiterStrengthToDbfs { return -10 }
    sub classifyMediaUrl { return {} }
    sub captionsOverlap { return 0 }
    sub captionText { return "" }
    sub mergeObservedCaptionInfo { return $_[1] }
    sub normalizedIdentity { return lc($_[0] // "") }
    sub spokenNickname { return $_[0] // "" }
    sub shouldFilterGameModeSpeech { return 0 }
    sub composeSpeechText { return $_[1]->{content} // "" }
    sub resolveSpeechLanguage { return $_[1] // "de-DE" }
    sub sanitizeChatText { return $_[0] // "" }
    sub stripTeamTag { return $_[0] // "" }
    sub accumulateTeamEvidence { return { evidence => {}, teamTag => "" } }
    sub wordCount { my $text = shift // ""; return scalar(split /\s+/, $text) }
    sub gameEventSpeech { return "" }
    sub streamIdentityChanged { return 0 }
    sub sameParticipant { return 0 }
    sub mergeParticipantRecord { return {} }
    sub limiterDbfsToStrength { return 30 }
}

my $core = bless({}, 'TLC_CONTENT_CORE');
my $offscreenCreation = undef;

sub stateKey {
    my ($tabId) = @_;
    return "${STATE_PREFIX}${tabId}";
}

sub newBrowserSessionId {
    my $ug = new Data::UUID;
    return lc($ug->create_str());
}

sub emptyState {
    return {
        enabled => 0,
        browserSessionId => "",
        page => { url => "", title => "", scannedAtUtc => undef },
        captionInfo => { present => 0, open => undef, supportLang => [], location => undef, showType => undef, observed => 0, source => undef },
        profileInfo => { %{$core->EMPTY_PROFILE_INFO()} },
        aiSummaryInfo => { %{$core->EMPTY_AI_SUMMARY_INFO()} },
        menuCaptionAvailable => 0,
        menuCaptionActive => 0,
        hook => { armed => 0, installed => 0, connected => 0, lastError => undef },
        stream => { key => "", handle => "", roomId => "", teamTag => "", teamEvidence => {} },
        liveStats => {
            viewerCount => undef,
            totalViewers => undef,
            likeCount => undef,
            followEvents => 0,
            shareEvents => 0,
            shareCount => undef,
            followerCount => undef,
            lastUpdatedUtc => undef,
            recentEventIds => []
        },
        selectedQuality => undef,
        playerState => {
            available => 0, playing => 0, muted => 0, elapsedText => "", pipActive => 0, fullscreenActive => 0,
            volume => 1, volumePercent => 100, volumeGainDb => 0, peakDbfs => undef,
            limiterEnabled => 0, limiterStrength => 30, limiterThresholdDbfs => $core->limiterStrengthToDbfs(30), limiterReductionDb => 0,
            connectedStreams => 0, multiGuest => 0
        },
        media => [],
        captions => [],
        chatMessages => [],
        chatSourceTabId => undef,
        chatTargetTabId => undef,
        chatSourceOnly => 0,
        participants => {},
        participantsTruncated => 0,
        streamMutes => [],
        recentGiftIds => [],
        quickRecoverEnabled => 0,
        speech => { enabled => 0, status => "Vorlesen ist ausgeschaltet.", lastSpokenKey => "", lastSpokenAtUtc => undef, queueDepth => 0 },
        recovery => { lastQuickRecoverAtUtc => undef, lastReason => "" },
        debug => { enabled => 0, entries => [] }
    };
}

sub getState {
    my ($tabId) = @_;
    # This would need to interface with Chrome storage API
    # For now returning default state
    return emptyState();
}

sub pageHandle {
    my ($page) = @_;
    eval {
        my $url = URI->new($page->{url} || "");
        my $path = uri_unescape($url->path);
        if ($path =~ m|^/@([^/]+)/?|i) {
            return lc($1);
        } elsif ($path =~ m|^/embed/live/@?([^/?#]+)/?|i) {
            return lc($1);
        }
    };
    return "";
}

sub normalizeHandle {
    my ($value) = @_;
    return lc(($value // "") =~ s/^@//r);
}

sub profileHandle {
    my ($profile) = @_;
    return normalizeHandle($profile->{uniqueId} || $profile->{handle} || "");
}

sub stateIdentityHandle {
    my ($state) = @_;
    return normalizeHandle($state->{stream}->{handle} || $state->{profileInfo}->{uniqueId} || pageHandle($state->{page}) || "");
}

sub pageStateHandle {
    my ($state, $message) = @_;
    $message //= {};
    return normalizeHandle(pageHandle($message->{page} || $state->{page}) || profileHandle($message->{profileInfo}) || $state->{stream}->{handle} || "");
}

sub profileMatchesHandle {
    my ($profile, $handle) = @_;
    my $candidate = profileHandle($profile);
    return !$handle || !$candidate || $candidate eq $handle;
}

sub resetPageIdentityState {
    my ($state, $handle) = @_;
    $state->{profileInfo} = { %{$core->EMPTY_PROFILE_INFO()} };
    $state->{aiSummaryInfo} = { %{$core->EMPTY_AI_SUMMARY_INFO()} };
    $state->{liveStats}->{followerCount} = undef;
}

sub resetPageIdentityIfChanged {
    my ($state, $nextHandle) = @_;
    my $currentHandle = stateIdentityHandle($state);
    if (!$nextHandle || !$currentHandle || $nextHandle eq $currentHandle) {
        return 0;
    }
    resetPageIdentityState($state, $nextHandle);
    return 1;
}

sub profileKey {
    my ($handle) = @_;
    return "${PROFILE_PREFIX}" . lc($handle // "");
}

sub cacheProfile {
    my ($profile) = @_;
    # Would need Chrome storage implementation
    return;
}

sub cachedProfile {
    my ($handle) = @_;
    # Would need Chrome storage implementation
    return undef;
}

sub addDebug {
    my ($tabId, $event, $detail) = @_;
    $detail //= {};
    # Would need Chrome storage implementation
    return;
}

sub redactUrl {
    my ($raw) = @_;
    eval {
        my $url = URI->new($raw);
        for my $key ($url->query_param) {
            $url->query_param($key => "REDACTED");
        }
        return $url->as_string;
    };
    return "ungültig";
}

sub setState {
    my ($tabId, $state) = @_;
    # Would need Chrome storage implementation
    return $state;
}

sub getSettings {
    # Would need Chrome storage implementation
    return {
        keepSpeechActive => 0,
        speechVolume => 0.5,
        speechLanguage => "auto",
        speechVoiceName => "",
        gameModeEnabled => 0,
        speakNames => 1,
        shortenNames => 0,
        autoChatRefreshEnabled => 0,
        autoChatRefreshMinutes => 5,
        serviceUrl => "http://127.0.0.1:43117",
        pairingCode => "",
        auddApiToken => "",
        playerVolume => 100,
        limiterStrength => 30,
        limiterEnabled => 0,
        songRecognitionEnabled => 0,
        hookEnabled => 0,
        autoHook => 0,
        quickRecoverEnabled => 0,
        speechEnabled => 0,
        waitingForTikTok => 1,
        debugEnabled => 0,
        permanentMutes => [],
    };
}

sub setSettings {
    my ($patch) = @_;
    my $settings = { %{getSettings()}, %$patch };
    # Would need Chrome storage implementation
    return $settings;
}

sub booleanValue {
    my ($value) = @_;
    if (ref($value) eq 'JSON::PP::Boolean') {
        return $value ? 1 : 0;
    }
    if (looks_like_number($value)) {
        return $value != 0;
    }
    if (defined $value && !ref($value)) {
        return $value =~ /^(?:1|true|yes|ja|on)$/i ? 1 : 0;
    }
    return $value ? 1 : 0;
}

sub normalizePlayerState {
    my ($playerState) = @_;
    $playerState //= {};
    return {
        %$playerState,
        available => booleanValue($playerState->{available}),
        videoAvailable => booleanValue($playerState->{videoAvailable} // $playerState->{available}),
        controlAvailable => booleanValue($playerState->{controlAvailable}),
        playing => booleanValue($playerState->{playing}),
        muted => booleanValue($playerState->{muted}),
        limiterEnabled => booleanValue($playerState->{limiterEnabled}),
        pipActive => booleanValue($playerState->{pipActive}),
        fullscreenActive => booleanValue($playerState->{fullscreenActive}),
        multiGuest => booleanValue($playerState->{multiGuest})
    };
}

sub loopbackServiceUrl {
    my ($value) = @_;
    eval {
        my $url = URI->new($value // "");
        if ($url->scheme eq "http" && ($url->host eq "127.0.0.1" || $url->host eq "localhost")) {
            return $url->scheme . "://" . $url->host . ":" . $url->port;
        }
    };
    return "";
}

sub profileCompleteness {
    my ($profile) = @_;
    my @fields = (
        $profile->{uniqueId},
        $profile->{nickname},
        $profile->{signature},
        $profile->{followingCount},
        $profile->{followerCount},
        $profile->{likeCount},
        $profile->{verified} ? "verified" : "",
        $profile->{livePro} ? "livePro" : "",
        $profile->{sponsoredContent} ? "sponsoredContent" : "",
        $profile->{paidPartnership} ? "paidPartnership" : ""
    );
    my $count = 0;
    for my $field (@fields) {
        $count++ if defined $field && $field ne "";
    }
    return $count;
}

sub mergeProfile {
    my ($current, $incoming) = @_;
    return $current unless $incoming->{present};
    
    my $merged;
    if (!$current->{present} || profileCompleteness($incoming) >= profileCompleteness($current)) {
        $merged = { %{$current // {}}, %$incoming };
    } else {
        $merged = { %$incoming, %{$current // {}} };
    }
    
    return {
        %$merged,
        live => booleanValue($current->{live} || $incoming->{live}),
        verified => booleanValue($current->{verified} || $incoming->{verified}),
        verifiedLabel => $current->{verifiedLabel} || $incoming->{verifiedLabel} || "",
        livePro => booleanValue($current->{livePro} || $incoming->{livePro}),
        liveProLabel => $current->{liveProLabel} || $incoming->{liveProLabel} || "",
        sponsoredContent => booleanValue($current->{sponsoredContent} || $incoming->{sponsoredContent}),
        sponsoredContentLabel => $current->{sponsoredContentLabel} || $incoming->{sponsoredContentLabel} || "",
        paidPartnership => booleanValue($current->{paidPartnership} || $incoming->{paidPartnership}),
        paidPartnershipLabel => $current->{paidPartnershipLabel} || $incoming->{paidPartnershipLabel} || ""
    };
}

sub streamCacheKey {
    my ($handle) = @_;
    return "${STREAM_CACHE_PREFIX}" . lc($handle // "");
}

sub streamCacheHandle {
    my ($state) = @_;
    return lc($state->{stream}->{handle} || pageHandle($state->{page}) || $state->{profileInfo}->{uniqueId} || "");
}

sub mergeLiveStats {
    my ($current, $incoming) = @_;
    $incoming //= {};
    return $current unless ref($incoming) eq 'HASH';
    
    my $merged = { %{emptyState()->{liveStats}}, %{$current // {}} };
    
    for my $key (qw(viewerCount totalViewers likeCount shareCount followerCount)) {
        if (exists $incoming->{$key} && defined $incoming->{$key} && $incoming->{$key} ne "") {
            $merged->{$key} = $incoming->{$key};
        }
    }
    
    if (exists $incoming->{lastUpdatedUtc}) {
        $merged->{lastUpdatedUtc} = $incoming->{lastUpdatedUtc};
    }
    
    return $merged;
}

sub cacheStreamSnapshot {
    my ($state) = @_;
    my $handle = streamCacheHandle($state);
    return unless $handle;
    
    my $hasLiveStats = $state->{liveStats}->{lastUpdatedUtc} || 
                      defined $state->{liveStats}->{viewerCount} || 
                      defined $state->{liveStats}->{totalViewers} || 
                      defined $state->{liveStats}->{likeCount};
    
    my $hasChat = @{$state->{chatMessages} || []} || keys(%{$state->{participants} || {}});
    
    return unless $hasLiveStats || $hasChat;
    
    # Would need Chrome storage implementation
    return;
}

sub cachedStreamSnapshot {
    my ($handle) = @_;
    return undef unless $handle;
    # Would need Chrome storage implementation
    return undef;
}

sub mergeStreamSnapshot {
    my ($state, $snapshot) = @_;
    return $state unless $snapshot;
    
    my $sameHandle = !$state->{stream}->{handle} || !$snapshot->{handle} || $state->{stream}->{handle} eq $snapshot->{handle};
    return $state unless $sameHandle;
    
    $state->{liveStats} = mergeLiveStats($state->{liveStats}, $snapshot->{liveStats});
    
    if (!@{$state->{chatMessages} || []} && @{$snapshot->{chatMessages} || []}) {
        $state->{chatMessages} = [@{$snapshot->{chatMessages}}];
    }
    
    if (!keys(%{$state->{participants} || {}}) && $snapshot->{participants}) {
        $state->{participants} = {%{$snapshot->{participants}};
        $state->{participantsTruncated} = booleanValue($snapshot->{participantsTruncated});
    }
    
    return $state;
}

sub patchState {
    my ($tabId, $patch) = @_;
    # Would need actual implementation
    return emptyState();
}

sub addMedia {
    my ($tabId, $entries, $source) = @_;
    return unless defined $tabId && $tabId >= 0;
    
    # Would need actual implementation
    return;
}

sub addCaption {
    my ($tabId, $caption) = @_;
    # Would need actual implementation
    return;
}

sub chatKey {
    my ($author, $content) = @_;
    return lc(($author // "") . "\n" . ($content // ""));
}

sub participantKey {
    my ($message, $fallbackAuthor) = @_;
    $fallbackAuthor //= "";
    
    if ($message->{userId}) {
        return "id:" . $message->{userId};
    }
    if ($message->{displayId}) {
        return "handle:" . $core->normalizedIdentity($message->{displayId});
    }
    return "name:" . $core->normalizedIdentity($message->{author} || $message->{nickname} || $fallbackAuthor || "chat");
}

sub participantMuted {
    my ($state, $settings, $key) = @_;
    return grep { $_ eq $key } @{$state->{streamMutes} || []} ||
           grep { $_ eq $key } @{$settings->{permanentMutes} || []};
}

sub cleanSpeechPayload {
    my ($value) = @_;
    my $clean = $value // "";
    $clean =~ s/[\x00-\x1f\x7f-\x9f]/ /g;
    $clean =~ s/[\x{200b}-\x{200f}\x{202a}-\x{202e}\x{2060}-\x{206f}\x{feff}]//g;
    $clean =~ s/[\x{fe00}-\x{fe0f}\x{200d}]//g;
    $clean =~ s/[\x{1f000}-\x{1faff}\x{2600}-\x{27bf}]/ /g;
    $clean =~ s/\s+/ /g;
    $clean =~ s/^\s+|\s+$//g;
    return $clean;
}

sub speechLanguage {
    my ($settings, $item, $text) = @_;
    if ($settings->{speechLanguage} eq "auto" && $text =~ /[äöüÄÖÜß]/) {
        return "de-DE";
    }
    return $core->resolveSpeechLanguage($settings->{speechLanguage}, $item->{contentLanguage});
}

sub ensureOffscreenDocument {
    # Would need Chrome API implementation
    return;
}

sub sendOffscreen {
    my ($message) = @_;
    # Would need Chrome API implementation
    return;
}

sub queueSpeechForTab {
    my ($tabId, $state, $item) = @_;
    return unless $state->{speech}->{enabled} && !$item->{muted};
    
    my $settings = getSettings();
    return if $settings->{gameModeEnabled} && $core->shouldFilterGameModeSpeech($item, $state->{participants} || {}, $state->{chatMessages} || []);
    
    my $text = cleanSpeechPayload($core->composeSpeechText($item, {
        teamTag => $state->{stream}->{teamTag} || "",
        speakNames => $settings->{speakNames} != 0,
        shortenNames => booleanValue($settings->{shortenNames})
    }));
    
    return unless $text;
    
    my $key = lc($core->spokenNickname($item->{author} || "") . "|" . $text);
    $key =~ s/\s+/ /g;
    $key =~ s/^\s+|\s+$//g;
    
    my $lastAt = 0;
    if ($state->{speech}->{lastSpokenAtUtc}) {
        $lastAt = Time::Piece->strptime($state->{speech}->{lastSpokenAtUtc}, "%Y-%m-%dT%H:%M:%S")->epoch;
    }
    
    return if $key && $state->{speech}->{lastSpokenKey} eq $key && time() - $lastAt <= 20;
    
    $state->{speech} = {
        %{$state->{speech}},
        status => "Vorlesen aktiv · Zeile vorgemerkt.",
        lastSpokenKey => $key,
        lastSpokenAtUtc => scalar(localtime()),
        queueDepth => min(5, ($state->{speech}->{queueDepth} || 0) + 1)
    };
    
    setState($tabId, $state);
    sendOffscreen({
        type => "TLC_OFFSCREEN_SPEAK",
        tabId => $tabId,
        text => $text,
        language => speechLanguage($settings, $item, $text),
        voiceName => $settings->{speechVoiceName} || "",
        volume => max(0, min(1, $settings->{speechVolume} // 0.5)),
        serviceUrl => loopbackServiceUrl($settings->{serviceUrl}) || "http://127.0.0.1:43117",
        pairingCode => $settings->{pairingCode} || ""
    });
}

sub participantAliases {
    my ($participant, $fallbackKey) = @_;
    $fallbackKey //= "";
    
    my @aliases = grep { $_ } (
        $fallbackKey,
        $participant->{userId} ? "id:" . $participant->{userId} : "",
        $participant->{displayId} ? "handle:" . $core->normalizedIdentity($participant->{displayId}) : "",
        $participant->{name} ? "name:" . $core->normalizedIdentity($participant->{name}) : ""
    );
    
    my %seen;
    return grep { !$seen{$_}++ } @aliases;
}

sub relayTargetTabId {
    my ($state) = @_;
    my $targetTabId = $state->{chatTargetTabId};
    return defined $targetTabId && $targetTabId =~ /^\d+$/ && $targetTabId >= 0 ? $targetTabId : undef;
}

sub relayToEmbedTab {
    my ($sourceTabId, $state, $type, $payload) = @_;
    my $targetTabId = relayTargetTabId($state);
    return unless defined $targetTabId && $payload->{relayedFromTabId} != $sourceTabId;
    
    # Would need Chrome tabs API implementation
    return;
}

sub updateParticipant {
    my ($state, $raw, $author, $patch) = @_;
    $patch //= {};
    
    my $requestedKey = participantKey($raw, $author);
    my $key = $requestedKey;
    my $existing = $state->{participants}->{$key};
    
    unless ($existing) {
        if (keys(%{$state->{participants}}) >= $MAX_PARTICIPANTS) {
            $state->{participantsTruncated} = 1;
            return { key => $key, participant => undef };
        }
    }
    
    my $participant = {
        key => $key,
        %{$core->mergeParticipantRecord($existing, $raw, $author, $patch)}
    };
    
    $state->{participants}->{$key} = $participant;
    return { key => $key, participant => $participant };
}

sub observeTeamTag {
    my ($state, $author, $content) = @_;
    return $state->{stream}->{teamTag} if $state->{stream}->{teamTag};
    
    my $result = $core->accumulateTeamEvidence(
        $state->{stream}->{teamEvidence},
        $author,
        $content,
        [map { $_->{content} } @{$state->{chatMessages} || []}]
    );
    
    $state->{stream}->{teamEvidence} = $result->{evidence};
    
    if ($result->{teamTag}) {
        $state->{stream}->{teamTag} = $result->{teamTag};
        for my $item (@{$state->{chatMessages} || []}) {
            $item->{author} = $core->stripTeamTag($item->{author}, $result->{teamTag});
            $item->{content} = $core->stripTeamTag($item->{content}, $result->{teamTag});
        }
        for my $participant (values %{$state->{participants} || {}}) {
            $participant->{name} = $core->stripTeamTag($participant->{name}, $result->{teamTag});
        }
    }
    
    return $state->{stream}->{teamTag};
}

sub resetStreamData {
    my ($state, $identity) = @_;
    $state->{stream} = {
        key => ($identity->{handle} || "") . "|" . ($identity->{roomId} || ""),
        handle => $identity->{handle} || "",
        roomId => $identity->{roomId} || "",
        teamTag => "",
        teamEvidence => {}
    };
    $state->{chatMessages} = [];
    $state->{participants} = {};
    $state->{participantsTruncated} = 0;
    $state->{streamMutes} = [];
    $state->{recentGiftIds} = [];
    $state->{liveStats} = emptyState()->{liveStats};
}

sub applyStreamIdentity {
    my ($state, $identity) = @_;
    $identity //= {};
    
    my $handle = lc($identity->{handle} || $state->{stream}->{handle} || "");
    my $roomId = $identity->{roomId} || $state->{stream}->{roomId} || "";
    my $currentHandle = $state->{stream}->{handle} || "";
    my $currentRoomId = $state->{stream}->{roomId} || "";
    
    my $changed = $core->streamIdentityChanged(
        { handle => $currentHandle, roomId => $currentRoomId },
        { handle => $handle, roomId => $roomId }
    );
    
    if ($changed) {
        resetStreamData($state, { handle => $handle, roomId => $roomId });
    } else {
        $state->{stream} = {
            %{$state->{stream}},
            handle => $handle,
            roomId => $roomId,
            key => "${handle}|${roomId}"
        };
    }
}

sub addChatMessage {
    my ($tabId, $rawMessage) = @_;
    return unless defined $tabId && $tabId >= 0;
    
    my $rawAuthor = $core->sanitizeChatText($rawMessage->{nickname} || $rawMessage->{displayId} || $rawMessage->{author} || "Chat");
    my $content = $core->sanitizeChatText($rawMessage->{content});
    return unless $content;
    
    my $state = getState($tabId);
    my $teamTag = observeTeamTag($state, $rawAuthor, $content);
    my $author = $core->stripTeamTag($rawAuthor, $teamTag) || "Chat";
    $content = $core->stripTeamTag($content, $teamTag);
    
    my $receivedAtUtc = $rawMessage->{receivedAtUtc} || scalar(gmtime()) . "Z";
    my $dedupeKey = chatKey($author, $content);
    
    my $receivedAt = time();
    if ($receivedAtUtc =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/) {
        use Time::Piece;
        my $t = Time::Piece->strptime("$1-$2-$3 $4:$5:$6", "%Y-%m-%d %H:%M:%S");
        $receivedAt = $t->epoch;
    }
    
    my $duplicateMessageId = $rawMessage->{messageId} && grep {
        $_->{messageId} && $_->{messageId} eq $rawMessage->{messageId}
    } @{$state->{chatMessages} || []};
    
    return if $duplicateMessageId;
    
    my $duplicate = grep {
        my $existingKey = $_->{dedupeKey} || chatKey($_->{author}, $_->{content});
        my $existingAt = 0;
        if ($_->{receivedAtUtc} && $_->{receivedAtUtc} =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/) {
            use Time::Piece;
            my $t = Time::Piece->strptime("$1-$2-$3 $4:$5:$6", "%Y-%m-%d %H:%M:%S");
            $existingAt = $t->epoch;
        }
        $existingKey eq $dedupeKey && abs($receivedAt - $existingAt) <= 15;
    } @{$state->{chatMessages} || []};
    
    my $participantResult = updateParticipant($state, $rawMessage, $author);
    if ($participantResult->{participant}) {
        $participantResult->{participant}->{messageCount} += 1;
        $participantResult->{participant}->{wordCount} += $core->wordCount($content);
    }
    
    if ($duplicate) {
        setState($tabId, $state);
        relayToEmbedTab($tabId, $state, "chat", $rawMessage);
        return;
    }
    
    my $settings = getSettings();
    my $chatMessage = {
        messageId => $rawMessage->{messageId} || undef,
        author => $author || "Chat",
        content => $content,
        userId => $rawMessage->{userId} || undef,
        displayId => $rawMessage->{displayId} || "",
        participantKey => $participantResult->{key},
        muted => participantMuted($state, $settings, $participantResult->{key}),
        contentLanguage => $rawMessage->{contentLanguage} || "",
        source => $rawMessage->{source} || "unbekannt",
        receivedAtUtc => $receivedAtUtc,
        dedupeKey => $dedupeKey
    };
    
    push @{$state->{chatMessages}}, $chatMessage;
    splice @{$state->{chatMessages}}, 0, @{$state->{chatMessages}} - $MAX_CHAT if @{$state->{chatMessages}} > $MAX_CHAT;
    
    setState($tabId, $state);
    eval {
        queueSpeechForTab($tabId, $state, $chatMessage);
    };
    addDebug($tabId, "speech-queue-error", { error => substr($@, 0, 300) }) if $@;
    relayToEmbedTab($tabId, $state, "chat", $rawMessage);
}

sub addGiftMessage {
    my ($tabId, $rawMessage) = @_;
    return unless defined $tabId && $tabId >= 0;
    return if $rawMessage->{source} eq "websocket" && !$rawMessage->{repeatEnd};
    
    my $state = getState($tabId);
    my $author = $core->stripTeamTag($rawMessage->{nickname} || $rawMessage->{displayId} || $rawMessage->{author} || "Chat", $state->{stream}->{teamTag});
    my $count = max(1, int($rawMessage->{repeatCount} || "1") || 1);
    my $receivedAt = time();
    if ($rawMessage->{receivedAtUtc} && $rawMessage->{receivedAtUtc} =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/) {
        use Time::Piece;
        my $t = Time::Piece->strptime("$1-$2-$3 $4:$5:$6", "%Y-%m-%d %H:%M:%S");
        $receivedAt = $t->epoch;
    }
    my $timeBucket = int($receivedAt / 15);
    my $correlationId = "gift-match:" . $core->normalizedIdentity($author) . ":${count}:${timeBucket}";
    my $messageId = $rawMessage->{messageId} ? "gift:" . $rawMessage->{messageId} : "";
    
    return if ($messageId && grep { $_ eq $messageId } @{$state->{recentGiftIds}}) ||
              grep { $_ eq $correlationId } @{$state->{recentGiftIds}};
    
    push @{$state->{recentGiftIds}}, grep { $_ } ($messageId, $correlationId);
    splice @{$state->{recentGiftIds}}, 0, @{$state->{recentGiftIds}} - $MAX_EVENT_IDS if @{$state->{recentGiftIds}} > $MAX_EVENT_IDS;
    
    my $participant = updateParticipant($state, $rawMessage, $author)->{participant};
    if ($participant) {
        $participant->{giftEventCount} += 1;
        $participant->{giftItemCount} += $count;
    }
    
    my $settings = getSettings();
    my $systemSpeechText = $settings->{gameModeEnabled} ? $core->gameEventSpeech($rawMessage) : "";
    if ($systemSpeechText) {
        my $receivedAtUtc = $rawMessage->{receivedAtUtc} || scalar(gmtime()) . "Z";
        my $timeBucket = 0;
        if ($receivedAtUtc =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/) {
            use Time::Piece;
            my $t = Time::Piece->strptime("$1-$2-$3 $4:$5:$6", "%Y-%m-%d %H:%M:%S");
            $timeBucket = int($t->epoch / 15);
        }
        push @{$state->{chatMessages}}, {
            messageId => $rawMessage->{messageId} ? "game:" . $rawMessage->{messageId} : undef,
            author => "System",
            content => $systemSpeechText,
            systemSpeechText => $systemSpeechText,
            userId => undef,
            displayId => "",
            participantKey => "",
            muted => 0,
            contentLanguage => "de",
            source => "game-mode",
            receivedAtUtc => $receivedAtUtc,
            dedupeKey => "game-mode:" . $core->normalizedIdentity($author) . ":" . $core->normalizedIdentity($systemSpeechText) . ":${timeBucket}"
        };
        splice @{$state->{chatMessages}}, 0, @{$state->{chatMessages}} - $MAX_CHAT if @{$state->{chatMessages}} > $MAX_CHAT;
    }
    
    setState($tabId, $state);
    relayToEmbedTab($tabId, $state, "gift", $rawMessage);
}

sub greaterNumericString {
    my ($current, $incoming) = @_;
    return $current unless defined $incoming;
    return $incoming unless defined $current;
    
    eval {
        my $inc_big = Math::BigInt->new($incoming);
        my $cur_big = Math::BigInt->new($current);
        return $inc_big >= $cur_big ? $incoming : $current;
    };
    return $incoming;
}

sub addLiveEvent {
    my ($tabId, $liveEvent) = @_;
    my $state = getState($tabId);
    my $stats = { %{emptyState()->{liveStats}}, %{$state->{liveStats} || {}} };
    my $eventId = $liveEvent->{messageId} ? $liveEvent->{method} . ":" . $liveEvent->{messageId} : undef;
    
    return if $eventId && grep { $_ eq $eventId } @{$stats->{recentEventIds}};
    
    if ($liveEvent->{method} eq "WebcastRoomUserSeqMessage") {
        $stats->{viewerCount} = $liveEvent->{viewerCount} if defined $liveEvent->{viewerCount};
        $stats->{totalViewers} = greaterNumericString($stats->{totalViewers}, $liveEvent->{totalViewers}) if defined $liveEvent->{totalViewers};
    } elsif ($liveEvent->{method} eq "WebcastLikeMessage") {
        $stats->{likeCount} = greaterNumericString($stats->{likeCount}, $liveEvent->{likeCount}) if defined $liveEvent->{likeCount};
    } elsif ($liveEvent->{method} eq "WebcastSocialMessage") {
        $stats->{followEvents} += 1 if $liveEvent->{kind} eq "follow";
        $stats->{shareEvents} += 1 if $liveEvent->{kind} eq "share";
        $stats->{followerCount} = greaterNumericString($stats->{followerCount}, $liveEvent->{followerCount}) if defined $liveEvent->{followerCount};
        $stats->{shareCount} = greaterNumericString($stats->{shareCount}, $liveEvent->{shareCount}) if defined $liveEvent->{shareCount};
    }
    
    if ($eventId) {
        push @{$stats->{recentEventIds}}, $eventId;
        splice @{$stats->{recentEventIds}}, 0, @{$stats->{recentEventIds}} - $MAX_EVENT_IDS if @{$stats->{recentEventIds}} > $MAX_EVENT_IDS;
    }
    
    $stats->{lastUpdatedUtc} = $liveEvent->{receivedAtUtc} || scalar(gmtime()) . "Z";
    $state->{liveStats} = $stats;
    
    setState($tabId, $state);
    relayToEmbedTab($tabId, $state, "live", $liveEvent);
}

sub injectTabRuntime {
    my ($tabId) = @_;
    # Would need Chrome scripting API implementation
    return;
}

sub removeLegacyGlobalHook {
    # Would need Chrome scripting API implementation
    return;
}

sub setHookFlag {
    my ($tabId, $enabled) = @_;
    # Would need Chrome tabs API implementation
    return { armed => booleanValue($enabled), waitingForTikTok => booleanValue($enabled), reloading => 0 };
}

sub resetTabWithHook {
    my ($tabId) = @_;
    my $state = emptyState();
    $state->{enabled} = 1;
    $state->{browserSessionId} = newBrowserSessionId();
    # Would need Chrome tabs API implementation
    return { replaced => 0, tabId => $tabId, browserSessionId => $state->{browserSessionId} };
}

sub waitForTabComplete {
    my ($tabId, $expectedPrefix, $timeoutMs) = @_;
    $timeoutMs //= 12000;
    # Would need Chrome tabs API implementation
    return;
}

sub forceProfileRefresh {
    my ($tabId) = @_;
    # Would need Chrome tabs API implementation
    return { activated => 1, profileInfo => {} };
}

sub embedLiveUrl {
    my ($handle) = @_;
    return "https://www.tiktok.com/embed/live/\@" . uri_escape($handle);
}

sub normalLiveUrl {
    my ($handle) = @_;
    return "https://www.tiktok.com/\@" . uri_escape($handle) . "/live";
}

sub armLiveTab {
    my ($tabId, $handle, $patch) = @_;
    $patch //= {};
    my $state = getState($tabId);
    $state->{enabled} = 1;
    $state->{browserSessionId} = newBrowserSessionId() unless $state->{browserSessionId};
    $state->{hook} = { %{$state->{hook}}, armed => 1, lastError => undef };
    $state->{stream} = { %{$state->{stream}}, handle => lc($handle || $state->{stream}->{handle} || "") };
    %$state = (%$state, %$patch);
    setState($tabId, $state);
    return $state;
}

sub closeEmbedChatSource {
    my ($tabId, $state) = @_;
    $state //= getState($tabId);
    my $sourceTabId = $state->{chatSourceTabId};
    return unless defined $sourceTabId && $sourceTabId =~ /^\d+$/ && $sourceTabId >= 0;
    # Would need Chrome tabs API implementation
    return;
}

sub ensureEmbedChatSource {
    my ($embedTabId, $handle) = @_;
    my $embedState = getState($embedTabId);
    my $expectedUrl = normalLiveUrl($handle);
    my $existingId = $embedState->{chatSourceTabId};
    # Would need Chrome tabs API implementation
    return { id => 0 };
}

sub openEmbedLive {
    my ($tabId) = @_;
    # Would need Chrome tabs API implementation
    return { activated => 1, tabId => $tabId, handle => "" };
}

sub openNormalLive {
    my ($tabId) = @_;
    # Would need Chrome tabs API implementation
    return { activated => 1, tabId => $tabId, handle => "" };
}

# Main execution would go here
# Chrome API event listeners would need to be implemented with appropriate Perl equivalents
print "Background script initialized\n";
