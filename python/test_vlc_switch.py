#!/usr/bin/env python3
# test_vlc_switch.cjs — portiert nach python
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_vlc_switch.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_vlc_switch.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_vlc_switch.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_vlc_switch.cjs
# Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

import os
import re
import unittest
from unittest.mock import MagicMock, patch, call


class TestVLCSwitch(unittest.TestCase):

    def setUp(self):
        # Simulate JavaScript environment and objects
        self.listeners = {}
        self.native = {'muted': False, 'paused': False}
        self.fallback = {'muted': False, 'paused': False}
        self.media = [self.native, self.fallback]
        self.unrelated_video = {'muted': False, 'paused': False}
        self.speech_audio = {'muted': False, 'paused': False}
        self.surface = {'querySelectorAll': lambda selector: self.media if selector == 'video' else []}
        self.fallback['closest'] = lambda: {'parentElement': self.surface}
        self.gain = {'value': 0.7}
        self.changed = None

        # Mock context for content.js
        self.context = {
            'audioPipeline': {'video': self.native, 'outputGain': {'gain': self.gain}},
            'document': {
                'querySelectorAll': lambda: (_ for _ in ()).throw(Exception('Must not globally suppress page media')),
                'documentElement': {},
                'addEventListener': lambda name, fn: self.listeners.update({name: fn}),
                'removeEventListener': lambda name: self.listeners.pop(name, None)
            },
            'MutationObserver': type('MutationObserver', (), {
                '__init__': lambda s, fn: setattr(self, 'changed', fn),
                'observe': lambda s: None,
                'disconnect': lambda s: None
            })
        }

        # Load and execute relevant parts of content.js
        script_dir = os.path.dirname(os.path.abspath(__file__))
        content_js_path = os.path.join(script_dir, '../browser-extension/content.js')
        with open(content_js_path, 'r', encoding='utf-8') as f:
            source = f.read()

        start_idx = source.find('  function suppressNativeAudio(')
        end_idx = source.find('  async function playMediaFallback(')
        code_to_run = source[start_idx:end_idx]

        exec(code_to_run, self.context)

        # Call suppressNativeAudio
        self.release = self.context['suppressNativeAudio'](self.fallback)

    def test_suppress_native_audio(self):
        self.assertTrue(self.native['muted'])
        self.assertTrue(self.native['paused'])
        self.assertEqual(self.gain['value'], 0)
        self.assertFalse(self.fallback['muted'])
        self.assertFalse(self.fallback['paused'])

    def test_play_event_listener(self):
        self.native['paused'] = False
        play_listener = self.listeners.get('play')
        if play_listener:
            play_listener()
        self.assertTrue(self.native['paused'])

    def test_media_change_observer(self):
        replacement = {'muted': False, 'paused': False}
        self.media.append(replacement)
        if self.changed:
            self.changed()
        self.assertTrue(replacement['muted'])
        self.assertTrue(replacement['paused'])

    def test_release_function(self):
        self.release()
        self.assertFalse(self.native['muted'])
        self.assertFalse(self.native['paused'])
        self.assertEqual(self.gain['value'], 0.7)
        self.assertEqual(len(self.listeners), 0)
        self.assertFalse(self.unrelated_video['paused'])
        self.assertFalse(self.speech_audio['paused'])

    def test_unrelated_audio_pipeline(self):
        self.context['audioPipeline']['video'] = self.unrelated_video
        release_unrelated = self.context['suppressNativeAudio'](self.fallback)
        self.assertEqual(self.gain['value'], 0.7)
        release_unrelated()

    def test_background_script_normal_live(self):
        script_dir = os.path.dirname(os.path.abspath(__file__))
        background_js_path = os.path.join(script_dir, '../browser-extension/background.js')
        with open(background_js_path, 'r', encoding='utf-8') as f:
            background = f.read()

        start_idx = background.find('async function openNormalLive(')
        end_idx = background.find('chrome.sidePanel.setPanelBehavior')
        normal_code = background[start_idx:end_idx]

        self.assertIn('await chrome.tabs.update(tabId, { url: normalLiveUrl(handle) })', normal_code)
        self.assertNotIn('if (reloading)', normal_code)
        self.assertIn('if (holder?.isConnected) return holder.querySelector("video")', background)

    @patch('builtins.print')
    def test_exercise_switch_click_handler(self, mock_print):
        script_dir = os.path.dirname(os.path.abspath(__file__))
        sidepanel_js_path = os.path.join(script_dir, '../browser-extension/sidepanel.js')
        with open(sidepanel_js_path, 'r', encoding='utf-8') as f:
            panel = f.read()

        click_start = panel.find('  elements["player-vlc-frame"].addEventListener("click"')
        click_end = panel.find('  elements["player-volume"].addEventListener', click_start)
        click_code = panel[click_start:click_end]

        starts = 0

        def run_player(action, target):
            nonlocal starts
            self.assertEqual(action, 'play-vlc-source')
            self.assertEqual(target, button)
            starts += 1

        button = MagicMock()
        panel_context = {
            'elements': {'player-vlc-frame': button},
            'installVlcIfNeeded': lambda: (_ for _ in ()).throw(Exception('Internal replacement must not wait for desktop installation')),
            'runPlayer': run_player
        }

        exec(click_code, panel_context)

        # Simulate click event
        if button.addEventListener.called:
            args, kwargs = button.addEventListener.call_args
            if args[0] == 'click':
                args[1]()  # Call the event handler

        self.assertEqual(starts, 1)

    def test_primary_video_selection(self):
        script_dir = os.path.dirname(os.path.abspath(__file__))
        content_js_path = os.path.join(script_dir, '../browser-extension/content.js')
        with open(content_js_path, 'r', encoding='utf-8') as f:
            source = f.read()

        start_idx = source.find('  function primaryVideo()')
        end_idx = source.find('  function playerToggleControl()')
        code_to_run = source[start_idx:end_idx]

        large_native = {
            'closest': lambda: None,
            'getBoundingClientRect': lambda: {'width': 1000, 'height': 1000}
        }
        small_replacement = {
            'closest': lambda: {},
            'getBoundingClientRect': lambda: {'width': 100, 'height': 100}
        }

        selection_context = {
            'activeMediaFallbackItem': {},
            'mediaFallbackRunning': False,
            'document': {
                'querySelector': lambda: small_replacement,
                'querySelectorAll': lambda: [large_native, small_replacement]
            }
        }

        exec(code_to_run, selection_context)

        primary_video_func = selection_context.get('primaryVideo')
        self.assertEqual(primary_video_func(), small_replacement)

        selection_context['activeMediaFallbackItem'] = None
        selection_context['mediaFallbackRunning'] = True
        self.assertEqual(primary_video_func(), small_replacement)

        selection_context['mediaFallbackRunning'] = False
        self.assertEqual(primary_video_func(), large_native)

    @patch('builtins.print')
    def test_open_normal_live_navigation(self, mock_print):
        navigated = 0

        async def tabs_get(*args):
            return {'url': 'https://www.tiktok.com/@test/live'}

        async def tabs_update(*args):
            nonlocal navigated
            navigated += 1

        ctx = {
            'chrome': {
                'tabs': {
                    'get': tabs_get,
                    'update': tabs_update
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

        script_dir = os.path.dirname(os.path.abspath(__file__))
        background_js_path = os.path.join(script_dir, '../browser-extension/background.js')
        with open(background_js_path, 'r', encoding='utf-8') as f:
            background = f.read()

        start_idx = background.find('async function openNormalLive(')
        end_idx = background.find('chrome.sidePanel.setPanelBehavior')
        normal_code = background[start_idx:end_idx]

        exec(normal_code, ctx)

        import asyncio
        asyncio.run(ctx['openNormalLive'](1))

        self.assertEqual(navigated, 1)

    @patch('builtins.print')
    def test_play_media_fallback_failure(self, mock_print):
        released = 0
        removed = 0
        created = 0

        video = {
            'pause': lambda: None,
            'removeAttribute': lambda: None,
            'load': lambda: None
        }

        def ensure_media_fallback_video():
            nonlocal created
            created += 1
            return video

        def suppress_native_audio():
            def release():
                nonlocal released
                released += 1
            return release

        player_context = {
            'mediaFallbackRunning': False,
            'mediaFallbackPageUrl': 'live',
            'location': {'href': 'live'},
            'attemptedMediaFallbackUrls': set(),
            'activeMediaFallbackItem': None,
            'releaseNativeAudio': None,
            'mediaFallbackCandidates': lambda x: x,
            'mediaFallbackKey': lambda x: x['url'],
            'ensureMediaFallbackVideo': ensure_media_fallback_video,
            'suppressNativeAudio': suppress_native_audio,
            'setMediaFallbackStatus': lambda: None,
            'destroyMediaFallbackPlayer': lambda: None,
            'tryMediaUrl': lambda: {'ok': False, 'reason': 'test failure'},
            'getPlayerState': lambda: {},
            'document': {'getElementById': lambda: {'remove': lambda: setattr(locals(), 'removed', removed := removed + 1)}}
        }

        script_dir = os.path.dirname(os.path.abspath(__file__))
        content_js_path = os.path.join(script_dir, '../browser-extension/content.js')
        with open(content_js_path, 'r', encoding='utf-8') as f:
            source = f.read()

        start_idx = source.find('  async function playMediaFallback(')
        end_idx = source.find('  async function configureLimiter(')
        code_to_run = source[start_idx:end_idx]

        exec(code_to_run, player_context)

        import asyncio

        # Test empty sources
        result_empty = asyncio.run(player_context['playMediaFallback']([]))
        self.assertEqual(created, 0)

        # Test failed startup
        result_failed = asyncio.run(player_context['playMediaFallback']([{'url': 'test', 'quality': 'test'}]))
        self.assertFalse(result_failed['activated'])
        self.assertEqual(released, 1)
        self.assertEqual(removed, 1)
        self.assertFalse(player_context['mediaFallbackRunning'])


if __name__ == '__main__':
    unittest.main()
