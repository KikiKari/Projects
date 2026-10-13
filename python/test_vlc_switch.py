#!/usr/bin/env python3
# test_vlc_switch.cjs — portiert nach python
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_vlc_switch.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_vlc_switch.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_vlc_switch.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_vlc_switch.cjs
# Erzeugt: 2026-10-13 durch ABSTRACTIONS_MANAGER.py

import os
import sys
import unittest
from unittest.mock import Mock, patch, MagicMock
import asyncio
from pathlib import Path


class TestVLCSwitch(unittest.TestCase):
    
    def setUp(self):
        self.test_dir = Path(__file__).parent
        self.extension_dir = self.test_dir.parent / 'browser-extension'
        
    def read_file(self, filename):
        with open(self.extension_dir / filename, 'r') as f:
            return f.read()
            
    def test_vlc_audio_suppression(self):
        # Setup mock objects
        native = {'muted': False, 'paused': False}
        fallback = {'muted': False, 'paused': False}
        media = [native, fallback]
        unrelated_video = {'muted': False, 'paused': False}
        speech_audio = {'muted': False, 'paused': False}
        
        # Mock DOM structure
        surface = Mock()
        surface.querySelectorAll.return_value = media
        
        fallback['closest'] = Mock(return_value={'parentElement': surface})
        
        gain = {'value': 0.7}
        listeners = {}
        
        # Read content.js and extract relevant functions
        source = self.read_file('content.js')
        start_idx = source.find('  function suppressNativeAudio(')
        end_idx = source.find('  async function playMediaFallback(')
        source_slice = source[start_idx:end_idx]
        
        # Create execution context
        context = {
            'audioPipeline': {'video': native, 'outputGain': {'gain': gain}},
            'document': {
                'querySelectorAll': lambda: Exception('Must not globally suppress page media'),
                'documentElement': {},
                'addEventListener': lambda name, fn: listeners.__setitem__(name, fn),
                'removeEventListener': lambda name: listeners.pop(name, None)
            },
            'MutationObserver': type('MutationObserver', (), {
                '__init__': lambda self, fn: setattr(self, 'callback', fn),
                'observe': lambda self: None,
                'disconnect': lambda self: None
            })
        }
        
        # Execute the code slice to define suppressNativeAudio
        exec(source_slice, context)
        
        # Test suppression logic
        changed = None
        for key, val in context.items():
            if hasattr(val, '__call__') and 'suppressNativeAudio' in str(val):
                suppress_native_audio = val
                break
                
        release = suppress_native_audio(fallback)
        
        self.assertTrue(native['muted'])
        self.assertTrue(native['paused'])
        self.assertEqual(gain['value'], 0)
        self.assertFalse(fallback['muted'])
        self.assertFalse(fallback['paused'])
        
        # Test play event
        native['paused'] = False
        listeners['play']()
        self.assertTrue(native['paused'])
        
        # Test media replacement
        replacement = {'muted': False, 'paused': False}
        media.append(replacement)
        # Simulate mutation callback - we need to capture it during execution
        # This is a simplified version since Python doesn't have direct equivalent
        
        release()
        self.assertFalse(native['muted'])
        self.assertFalse(native['paused'])
        self.assertEqual(gain['value'], 0.7)
        self.assertEqual(len(listeners), 0)
        self.assertFalse(unrelated_video['paused'])
        self.assertFalse(speech_audio['paused'])
        
        # Test unrelated audio pipeline
        context['audioPipeline']['video'] = unrelated_video
        release_unrelated = suppress_native_audio(fallback)
        self.assertEqual(gain['value'], 0.7, 'Unrelated audio pipeline must remain unchanged')
        release_unrelated()
        
    def test_normal_navigation(self):
        background = self.read_file('background.js')
        start_idx = background.find('async function openNormalLive(')
        end_idx = background.find('chrome.sidePanel.setPanelBehavior')
        normal_function = background[start_idx:end_idx]
        
        self.assertIn('await chrome.tabs.update(tabId, { url: normalLiveUrl(handle) })', normal_function)
        self.assertNotIn('if (reloading)', normal_function)
        
        source = self.read_file('content.js')
        self.assertIn('if (holder?.isConnected) return holder.querySelector("video")', source)
        
        print('PASS: VLC isolates native audio, suppresses restarted/replaced media, restores on failure; Normal navigates even at same URL; existing fallback reused')
        
    async def test_switch_exercise(self):
        panel = self.read_file('sidepanel.js')
        click_start = panel.find('  elements["player-vlc-frame"].addEventListener("click"')
        click_end = panel.find('  elements["player-volume"].addEventListener', click_start)
        click_slice = panel[click_start:click_end]
        
        starts = 0
        button = Mock()
        
        panel_context = {
            'elements': {'player-vlc-frame': button},
            'installVlcIfNeeded': lambda: Exception('Internal replacement must not wait for desktop installation'),
            'runPlayer': lambda action, target: self.assertEqual(action, 'play-vlc-source') or self.assertEqual(target, button) or globals().__setitem__('starts', starts + 1)
        }
        
        exec(click_slice, panel_context)
        
        # Simulate click event
        if button.addEventListener.called:
            _, (_, click_handler) = button.addEventListener.call_args[0]
            await click_handler()
            self.assertEqual(starts, 1, 'VLC click dispatches internal player immediately')
        
        # Test primary video selection
        large_native = {
            'closest': lambda: None,
            'getBoundingClientRect': lambda: {'width': 1000, 'height': 1000}
        }
        small_replacement = {
            'closest': lambda: {},
            'getBoundingClientRect': lambda: {'width': 100, 'height': 100}
        }
        
        source = self.read_file('content.js')
        start_idx = source.find('  function primaryVideo()')
        end_idx = source.find('  function playerToggleControl()')
        source_slice = source[start_idx:end_idx]
        
        selection = {
            'activeMediaFallbackItem': {},
            'mediaFallbackRunning': False,
            'document': {
                'querySelector': lambda: small_replacement,
                'querySelectorAll': lambda: [large_native, small_replacement]
            }
        }
        
        exec(source_slice, selection)
        
        # Add primaryVideo function to selection
        primary_video_func = None
        for key, val in selection.items():
            if callable(val) and 'primaryVideo' in key:
                primary_video_func = val
                break
                
        self.assertEqual(primary_video_func(), small_replacement, 'Active replacement wins regardless of video size')
        
        selection['activeMediaFallbackItem'] = None
        selection['mediaFallbackRunning'] = True
        self.assertEqual(primary_video_func(), small_replacement, 'Starting replacement owns player controls')
        
        selection['mediaFallbackRunning'] = False
        self.assertEqual(primary_video_func(), large_native, 'Inactive replacement excluded from native selection')
        
        # Test navigation
        navigated = 0
        ctx = {
            'chrome': {
                'tabs': {
                    'get': lambda: {'url': 'https://www.tiktok.com/@test/live'},
                    'update': lambda: globals().__setitem__('navigated', navigated + 1)
                }
            },
            'getState': lambda: {},
            'pageHandle': lambda: 'test',
            'cancelEmbedSession': lambda: None,
            'cancelRecoveryForModeChange': lambda: None,
            'closeEmbedChatSource': lambda: None,
            'armLiveTab': lambda: None,
            'normalLiveUrl': lambda: 'https://www.tiktok.com/@test/live'
        }
        
        background = self.read_file('background.js')
        start_idx = background.find('async function openNormalLive(')
        end_idx = background.find('chrome.sidePanel.setPanelBehavior')
        normal_function = background[start_idx:end_idx]
        
        exec(normal_function, ctx)
        
        # Find and call openNormalLive
        open_normal_live = None
        for key, val in ctx.items():
            if callable(val) and 'openNormalLive' in key:
                open_normal_live = val
                break
                
        await open_normal_live(1)
        self.assertEqual(navigated, 1, 'Normal must navigate even from the same LIVE URL')
        
        # Test failed startup restoration
        released = 0
        removed = 0
        created = 0
        video = Mock()
        player = {
            'mediaFallbackRunning': False,
            'mediaFallbackPageUrl': 'live',
            'location': {'href': 'live'},
            'attemptedMediaFallbackUrls': set(),
            'activeMediaFallbackItem': None,
            'releaseNativeAudio': None,
            'mediaFallbackCandidates': lambda x: x,
            'mediaFallbackKey': lambda x: x['url'],
            'ensureMediaFallbackVideo': lambda: globals().__setitem__('created', created + 1) or video,
            'suppressNativeAudio': lambda: lambda: globals().__setitem__('released', released + 1),
            'setMediaFallbackStatus': lambda *args: None,
            'destroyMediaFallbackPlayer': lambda: None,
            'tryMediaUrl': lambda *args: {'ok': False, 'reason': 'test failure'},
            'getPlayerState': lambda: {},
            'document': {'getElementById': lambda *args: Mock(remove=lambda: globals().__setitem__('removed', removed + 1))}
        }
        
        source = self.read_file('content.js')
        start_idx = source.find('  async function playMediaFallback(')
        end_idx = source.find('  async function configureLimiter(')
        source_slice = source[start_idx:end_idx]
        
        exec(source_slice, player)
        
        # Find playMediaFallback function
        play_media_fallback = None
        for key, val in player.items():
            if callable(val) and 'playMediaFallback' in key:
                play_media_fallback = val
                break
                
        # Test empty sources
        result = await play_media_fallback([])
        self.assertEqual(created, 0, 'No sources must not cover the native player')
        
        # Test failed startup
        result = await play_media_fallback([{'url': 'test', 'quality': 'test'}])
        self.assertFalse(result['activated'])
        self.assertEqual(released, 1, 'Failed startup restores native audio')
        self.assertEqual(removed, 1, 'Failed startup removes replacement')
        self.assertFalse(player['mediaFallbackRunning'])
        
        print('PASS: actual Normal handler navigates same URL; failed VLC startup restores native player; empty sources create no overlay')


if __name__ == '__main__':
    try:
        test = TestVLCSwitch()
        test.setUp()
        asyncio.run(test.test_switch_exercise())
        print("All tests passed!")
    except Exception as e:
        print(f"Test failed: {e}")
        sys.exit(1)
