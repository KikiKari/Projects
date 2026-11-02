#!/usr/bin/env python3
# test_status_overview_player.cjs — portiert nach python
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_status_overview_player.cjs
# Erzeugt: 2026-11-02 durch ABSTRACTIONS_MANAGER.py

import asyncio
import unittest
from unittest.mock import MagicMock, patch
import os
import sys
import time

# Mock DOM-like classes for testing
class Element:
    def __init__(self, tag):
        self.tag = tag
        self.style = {}
        self.classList = MagicMock()
        self.classList.toggle = MagicMock()
        self.children = []
        self.listeners = {}
        self.muted = False
        self.paused = True
        self.src = ''
        self.currentTime = 0
        self.hidden = False
        self.textContent = ''

    def append(self, *nodes):
        self.children.extend(nodes)

    def addEventListener(self, name, fn):
        if name not in self.listeners:
            self.listeners[name] = set()
        self.listeners[name].add(fn)

    def removeEventListener(self, name, fn):
        if name in self.listeners:
            self.listeners[name].discard(fn)

    def emit(self, name):
        if name in self.listeners:
            for fn in list(self.listeners[name]):
                fn()

    def pause(self):
        self.paused = True

    def removeAttribute(self, attr):
        if attr == 'src':
            self.src = ''

    def load(self):
        pass

    def play(self):
        async def play_async():
            await asyncio.sleep(0.001)  # Microtask equivalent
            if 'bad' in self.src:
                self.emit('error')
            else:
                self.currentTime += 1
                self.emit('playing')
                self.emit('timeupdate')
        asyncio.create_task(play_async())
        return asyncio.Future()  # Return a resolved future

class TestStatusOverviewPlayer(unittest.TestCase):
    
    def setUp(self):
        # Load the JavaScript source code
        script_path = os.path.join(os.path.dirname(__file__), '../browser-extension/status-overview-player.js')
        with open(script_path, 'r', encoding='utf-8') as f:
            self.source_code = f.read()
        
    async def wait(self, ms):
        await asyncio.sleep(ms/1000)
        
    async def execute_test_in_context(self, context_vars):
        # Create a mock execution environment
        globals_dict = {
            'document': context_vars['document'],
            'chrome': context_vars['chrome'],
            'window': context_vars['window'],
            'URL': context_vars.get('URL', MagicMock()),
            'Date': context_vars.get('Date', MagicMock()),
            'Promise': context_vars.get('Promise', MagicMock()),
            'Number': context_vars.get('Number', MagicMock()),
            'String': context_vars.get('String', MagicMock()),
            'Array': context_vars.get('Array', MagicMock()),
            'JSON': context_vars.get('JSON', MagicMock()),
            'Object': context_vars.get('Object', MagicMock()),
            'Map': context_vars.get('Map', MagicMock()),
            'setTimeout': context_vars.get('setTimeout', lambda fn, delay: asyncio.get_event_loop().call_later(delay/1000, fn)),
            'clearTimeout': context_vars.get('clearTimeout', MagicMock()),
            'console': MagicMock()
        }
        
        # Execute the source code in this context
        exec(self.source_code, globals_dict)
        return globals_dict
        
    async def test_nine_independent_tiles_start_muted_and_try_next_source(self):
        grid = Element('main')
        change = None
        rows = [
            {
                'handle': f'user{i}',
                'status': 'online',
                'checkedAt': time.time() * 1000,
                'media': [
                    {'protocol': 'hls', 'url': 'https://example.test/bad.m3u8'},
                    {'protocol': 'hls', 'url': 'https://example.test/good.m3u8'}
                ]
            } for i in range(9)
        ]
        
        def add_listener_fn(fn):
            nonlocal change
            change = fn
            
        context = {
            'document': {
                'getElementById': lambda: grid,
                'createElement': lambda tag: Element(tag)
            },
            'chrome': {
                'runtime': {
                    'sendMessage': lambda: asyncio.Future()
                },
                'storage': {
                    'onChanged': {
                        'addListener': add_listener_fn
                    }
                }
            },
            'window': {
                'addEventListener': lambda *args: None
            }
        }
        
        # Mock the sendMessage to return our data
        future_result = asyncio.Future()
        future_result.set_result({
            'ok': True,
            'config': {'interval': 5},
            'rows': rows
        })
        context['chrome']['runtime']['sendMessage'] = lambda: future_result
        
        await self.execute_test_in_context(context)
        await self.wait(20)
        
        self.assertEqual(len(grid.children), 29)
        for tile in grid.children[:9]:
            self.assertTrue(tile.children[1].muted)
            self.assertIn('good', tile.children[1].src)
            self.assertIn('abgespielt', tile.children[2].textContent)
            
        rows[0] = {
            'handle': 'user0',
            'status': 'offline',
            'checkedAt': time.time() * 1000,
            'media': []
        }
        change({'tlc-overview-row-0': {}}, 'session')
        await self.wait(10)
        
        self.assertTrue(grid.children[0].hidden)
        self.assertIn('good', grid.children[1].children[1].src)
        
    async def test_retry_switches_only_requested_tile_tries_remaining_sources_and_can_restart_single_source(self):
        grid = Element('main')
        change = None
        rows = [
            {
                'handle': f'user{i}',
                'status': 'online',
                'checkedAt': (time.time() - 600) * 1000,
                'media': [
                    {'protocol': 'hls', 'url': f'https://example.test/{i}-first.m3u8'},
                    {'protocol': 'hls', 'url': f'https://example.test/{i}-bad.m3u8'},
                    {'protocol': 'hls', 'url': f'https://example.test/{i}-next.m3u8'}
                ]
            } for i in range(9)
        ]
        
        for row in rows:
            row['checkedAt'] = time.time() * 1000
            
        def add_listener_fn(fn):
            nonlocal change
            change = fn
            
        context = {
            'document': {
                'getElementById': lambda: grid,
                'createElement': lambda tag: Element(tag)
            },
            'chrome': {
                'runtime': {
                    'sendMessage': lambda: asyncio.Future()
                },
                'storage': {
                    'onChanged': {
                        'addListener': add_listener_fn
                    }
                }
            },
            'window': {
                'addEventListener': lambda *args: None
            }
        }
        
        # Mock the sendMessage to return our data
        future_result = asyncio.Future()
        future_result.set_result({
            'ok': True,
            'config': {'interval': 5},
            'rows': rows
        })
        context['chrome']['runtime']['sendMessage'] = lambda: future_result
        
        await self.execute_test_in_context(context)
        await self.wait(20)
        
        untouched = grid.children[1].children[1].src
        self.assertIn('first', grid.children[0].children[1].src)
        
        change({'tlc-overview-retry-0': {'newValue': {'handle': 'user0', 'nonce': 1}}}, 'session')
        await self.wait(20)
        
        self.assertIn('next', grid.children[0].children[1].src)
        self.assertEqual(grid.children[1].children[1].src, untouched)
        
        change({'tlc-overview-retry-0': {'newValue': {'handle': 'other', 'nonce': 2}}}, 'session')
        await self.wait(10)
        self.assertIn('next', grid.children[0].children[1].src)
        
        rows[0]['media'] = [{'protocol': 'hls', 'url': 'https://example.test/only.m3u8'}]
        rows[0]['checkedAt'] = time.time() * 1000
        change({'tlc-overview-row-0': {}}, 'session')
        await self.wait(10)
        
        change({'tlc-overview-retry-0': {'newValue': {'handle': 'user0', 'nonce': 3}}}, 'session')
        await self.wait(10)
        self.assertIn('only', grid.children[0].children[1].src)
        
    async def test_selects_first_online_entries_among_20_reverse_order_and_four_tile_mode_without_restarting_retained_streams(self):
        grid = Element('main')
        change = None
        config = {'interval': 5, 'expanded': True, 'grid2': True, 'reverse': False, 'autoSort': True}
        rows = [
            {
                'handle': f'user{i}',
                'status': 'online' if i % 2 == 1 else 'offline',
                'checkedAt': time.time() * 1000,
                'media': [{'protocol': 'hls', 'url': f'https://example.test/{i}.m3u8'}]
            } for i in range(20)
        ]
        
        def add_listener_fn(fn):
            nonlocal change
            change = fn
            
        context = {
            'document': {
                'getElementById': lambda: grid,
                'createElement': lambda tag: Element(tag)
            },
            'chrome': {
                'runtime': {
                    'sendMessage': lambda: asyncio.Future()
                },
                'storage': {
                    'onChanged': {
                        'addListener': add_listener_fn
                    }
                }
            },
            'window': {
                'addEventListener': lambda *args: None
            },
            'Map': dict
        }
        
        # Mock the sendMessage to return our data
        future_result = asyncio.Future()
        future_result.set_result({
            'ok': True,
            'config': config,
            'rows': rows
        })
        context['chrome']['runtime']['sendMessage'] = lambda: future_result
        
        await self.execute_test_in_context(context)
        await self.wait(20)
        
        def shown():
            result = []
            for i, tile in enumerate(grid.children[:20]):
                if not tile.hidden:
                    result.append(i)
            return result
            
        self.assertEqual(shown(), [1, 3, 5, 7])
        
        config['reverse'] = True
        change({'tlc-overview-config': {}}, 'local')
        await self.wait(20)
        self.assertEqual(shown(), [13, 15, 17, 19])
        self.assertEqual(grid.children[19].style.get('order', ''), '0')
        
        config['grid2'] = False
        change({'tlc-overview-config': {}}, 'local')
        await self.wait(20)
        self.assertEqual(len(shown()), 9)
        self.assertEqual(grid.children[19].style.get('order', ''), '0')
        
        config['expanded'] = False
        change({'tlc-overview-config': {}}, 'local')
        await self.wait(20)
        self.assertEqual(shown(), [1, 3, 5, 7])

if __name__ == '__main__':
    unittest.main()
