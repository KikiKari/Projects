#!/usr/bin/env python3
# test_status_overview.cjs — portiert nach python
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_status_overview.cjs
# Erzeugt: 2026-11-02 durch ABSTRACTIONS_MANAGER.py

import unittest
from unittest.mock import AsyncMock, Mock, patch
import asyncio
import json
import re
import os

class TestStatusOverview(unittest.IsolatedAsyncioTestCase):
    
    def setUp(self):
        # Simulate reading the worker script
        self.source = """
class TLCOverview {
    constructor() {
        this.rows = [];
        this.config = {handles: [], interval: 5};
        this.playing = new Set();
    }
    
    async message(msg, sender) {
        const type = msg.type;
        if (type === 'TLC_OVERVIEW_SET') {
            Object.assign(this.config, msg.config);
            while (this.rows.length < this.config.handles.length) this.rows.push({handle: '', status: 'unknown', media: []});
            for (let i = 0; i < this.config.handles.length; i++) this.rows[i].handle = this.config.handles[i];
            return {handles: this.config.handles};
        }
        if (type === 'TLC_OVERVIEW_GET') {
            return {rows: this.rows.map(r => ({...r})), config: {...this.config}};
        }
        if (type === 'TLC_OVERVIEW_CHECK') {
            // Simplified check logic
            return {rows: this.rows};
        }
        if (type === 'TLC_OVERVIEW_OPEN') {
            if (!msg.windowId) throw new Error('Browserfenster');
            chrome.tabs.create({url: chrome.runtime.getURL('status-overview.html'), windowId: msg.windowId});
            return {};
        }
        if (type === 'TLC_OVERVIEW_PLAYBACK') {
            const {index, handle, playing} = msg;
            if (playing) this.playing.add(index);
            else this.playing.delete(index);
            return {};
        }
        if (type === 'TLC_OVERVIEW_RETRY') {
            const {index, handle} = msg;
            if (index >= this.rows.length || this.rows[index].handle !== handle) throw new Error('nicht gefunden');
            chrome.session[`tlc-overview-retry-${index}`] = {handle};
            return {};
        }
        if (type === 'TLC_OVERVIEW_RESET') {
            for (let i = 0; i < this.rows.length; i++) this.rows[i] = {handle: '', status: 'unknown', media: []};
            return {};
        }
    }
}

globalThis.TLCOverview = TLCOverview;
"""
        
    def setup(self, fetch_impl, captured=None):
        local_storage = {}
        session_storage = {}
        alarms = {}
        opened_tabs = []
        
        def storage(data):
            return {
                'get': AsyncMock(side_effect=lambda keys: (
                    {k: v for k, v in data.items()} if keys is None 
                    else {k: data[k] for k in (keys if isinstance(keys, list) else [keys]) if k in data}
                )),
                'set': AsyncMock(side_effect=lambda values: data.update(values)),
                'remove': AsyncMock(side_effect=lambda key: data.pop(key, None))
            }
            
        chrome = {
            'storage': {
                'local': storage(local_storage),
                'session': storage(session_storage)
            },
            'alarms': {
                'onAlarm': {'addListener': lambda f: setattr(chrome['alarms'], 'on_alarm_func', f)},
                'create': AsyncMock(side_effect=lambda n, v: alarms.update({n: v})),
                'clear': AsyncMock(side_effect=lambda n: alarms.pop(n, None))
            },
            'runtime': {
                'onStartup': {'addListener': lambda _: None},
                'getURL': lambda x: f'chrome-extension://test/{x}'
            },
            'tabs': {
                'create': AsyncMock(side_effect=lambda v: opened_tabs.append(v)),
                'get': AsyncMock(return_value={'id': 1, 'url': 'chrome-extension://test/status-overview.html'})
            }
        }
        
        if captured:
            chrome['tabs']['query'] = AsyncMock(return_value=captured['tabs'])
            chrome['tabs']['sendMessage'] = AsyncMock(side_effect=lambda id_: captured['scans'].append(id_))
            
        core = {
            'inspectMetadata': lambda room: {'media': room.get('media', [])},
            'liveHandleFromUrl': lambda url: (re.search(r'@([^/]+)', url) or [None, ''])[1]
        }
        
        context = {
            'chrome': chrome,
            'core': core,
            'fetch': fetch_impl,
            'getState': AsyncMock(side_effect=lambda id_: captured['states'][id_] if captured and id_ in captured.get('states', {}) else {'media': []}),
            'URL': None,
            'Date': None,
            'Set': set,
            'Map': dict,
            'Object': object,
            'Array': list,
            'Math': None,
            'Number': None,
            'String': None,
            'Promise': None,
            'AbortController': None,
            'setTimeout': lambda f, _: asyncio.create_task(asyncio.sleep(0.01)).add_done_callback(lambda _: f()),
            'clearTimeout': None
        }
        
        # Execute the source code in the context
        exec(self.source, context)
        context['overview'] = context['TLCOverview']()
        
        async def fire():
            if hasattr(chrome['alarms'], 'on_alarm_func'):
                chrome['alarms']['on_alarm_func']({'name': 'tlc-overview-check'})
            await asyncio.sleep(0.01)
            
        return {
            'api': context['overview'],
            'opened': opened_tabs,
            'session': session_storage,
            'alarms': alarms,
            'fire': fire
        }

    def html(self, handle, status, media=None):
        if media is None:
            media = []
        return f"<script id=\"SIGI_STATE\" type=\"application/json\">{json.dumps({'LiveRoom': {'liveRoomUserInfo': {'user': {'uniqueId': handle}, 'liveRoom': {'status': status, 'media': media}}}})}</script>"

    async def test_checks_live_and_offline_via_direct_requests_without_opening_tabs(self):
        requested = []
        async def fetch_impl(url):
            requested.append(url)
            name = re.search(r'@([^/]+)', url).group(1)
            status = 2 if name == 'one' else 4
            media = [{'url': 'https://cdn.test/a.flv', 'audioOnly': False}]
            return {'ok': True, 'text': AsyncMock(return_value=self.html(name, status, media))}
            
        x = self.setup(fetch_impl)
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'handles': ['@One', 'Two'], 'interval': 5}})
        await x['api'].message({'type': 'TLC_OVERVIEW_CHECK'})
        result = await x['api'].message({'type': 'TLC_OVERVIEW_GET'})
        rows = result['rows']
        
        self.assertEqual(rows[0]['status'], 'online')
        self.assertEqual(len(rows[0]['media']), 1)
        self.assertEqual(rows[1]['status'], 'offline')
        self.assertEqual(len(rows[1]['media']), 0)
        self.assertEqual(len(requested), 2)
        self.assertEqual(len(x['opened']), 0)
        self.assertEqual(x['alarms']['tlc-overview-check']['periodInMinutes'], 5)

    async def test_unavailable_or_mismatched_response_is_an_error_never_falsely_offline(self):
        async def fetch_impl(url):
            if '@one/' in url:
                return {'ok': False}
            else:
                return {'ok': True, 'text': AsyncMock(return_value=self.html('other', 4))}
                
        x = self.setup(fetch_impl)
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'handles': ['one', 'two']}})
        await x['api'].message({'type': 'TLC_OVERVIEW_CHECK'})
        result = await x['api'].message({'type': 'TLC_OVERVIEW_GET'})
        rows = result['rows']
        
        self.assertEqual(rows[0]['status'], 'error')
        self.assertEqual(rows[1]['status'], 'error')

    async def test_rejects_duplicate_and_invalid_names_opens_overview_in_requested_window(self):
        async def fetch_impl(url):
            return {}
            
        x = self.setup(fetch_impl)
        
        with self.assertRaises(Exception) as cm:
            await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'handles': ['a', '@A']}})
        self.assertIn('einmal', str(cm.exception))
        
        with self.assertRaises(Exception) as cm:
            await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'handles': ['bad/name']}})
        self.assertIn('Ungültiger', str(cm.exception))
        
        await x['api'].message({'type': 'TLC_OVERVIEW_OPEN', 'windowId': 23})
        self.assertEqual(x['opened'][0]['windowId'], 23)
        self.assertIn('status-overview.html', x['opened'][0]['url'])
        
        with self.assertRaises(Exception) as cm:
            await x['api'].message({'type': 'TLC_OVERVIEW_OPEN'})
        self.assertIn('Browserfenster', str(cm.exception))

    async def test_does_not_apply_an_obsolete_result_after_changing_a_handle(self):
        release_future = asyncio.Future()
        
        async def fetch_impl(url):
            await release_future
            return {'ok': True, 'text': AsyncMock(return_value=self.html('one', 2))}
            
        x = self.setup(fetch_impl)
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'handles': ['one']}})
        check_task = asyncio.create_task(x['api'].message({'type': 'TLC_OVERVIEW_CHECK'}))
        await asyncio.sleep(0.01)
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'handles': ['two']}})
        release_future.set_result(None)
        await check_task
        result = await x['api'].message({'type': 'TLC_OVERVIEW_GET'})
        row = result['rows'][0]
        
        self.assertEqual(row['handle'], 'two')
        self.assertEqual(row['status'], 'unknown')

    async def test_playing_streams_are_skipped_until_playback_stops_and_timer_can_be_disabled(self):
        seen = []
        
        async def fetch_impl(url):
            seen.append(url)
            name = re.search(r'@([^/]+)', url).group(1)
            return {'ok': True, 'text': AsyncMock(return_value=self.html(name, 2))}
            
        x = self.setup(fetch_impl)
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'handles': ['one', 'two'], 'interval': 5}})
        sender = {'tab': {'id': 42}, 'url': 'chrome-extension://test/status-overview.html'}
        await x['api'].message({'type': 'TLC_OVERVIEW_PLAYBACK', 'index': 0, 'handle': 'one', 'playing': True}, sender)
        await x['api'].message({'type': 'TLC_OVERVIEW_CHECK'})
        
        self.assertEqual(len(seen), 1)
        self.assertIn('@two', seen[0])
        
        await x['api'].message({'type': 'TLC_OVERVIEW_PLAYBACK', 'index': 0, 'handle': 'one', 'playing': False}, sender)
        await x['api'].message({'type': 'TLC_OVERVIEW_CHECK'})
        self.assertEqual(len(seen), 3)
        
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'handles': ['one', 'two'], 'enabled': False}})
        self.assertNotIn('tlc-overview-check', x['alarms'])
        await x['fire']()
        self.assertEqual(len(seen), 3)

    async def test_persists_settings_limits_sources_and_resets_only_handles(self):
        media = [{'url': f'https://cdn.test/{i}.flv', 'audioOnly': i == 0} for i in range(35)]
        
        async def fetch_impl(url):
            return {'ok': True, 'text': AsyncMock(return_value=self.html('one', 2, media))}
            
        x = self.setup(fetch_impl)
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'handles': ['one'], 'interval': 7, 'maxLinks': 30, 'showLinks': True, 'autoSort': True, 'skipOnline': False}})
        await x['api'].message({'type': 'TLC_OVERVIEW_CHECK'})
        state = await x['api'].message({'type': 'TLC_OVERVIEW_GET'})
        
        self.assertEqual(len(state['rows'][0]['media']), 30)
        self.assertEqual(state['rows'][0]['media'][0]['audioOnly'], True)
        
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'maxLinks': 5}})
        state = await x['api'].message({'type': 'TLC_OVERVIEW_GET'})
        self.assertEqual(len(state['rows'][0]['media']), 5)
        
        await x['api'].message({'type': 'TLC_OVERVIEW_RESET'})
        state = await x['api'].message({'type': 'TLC_OVERVIEW_GET'})
        self.assertEqual(state['rows'][0]['handle'], '')
        self.assertEqual(len(state['rows'][0]['media']), 0)
        self.assertEqual(state['config']['interval'], 7)
        self.assertEqual(state['config']['autoSort'], True)
        self.assertEqual(state['config']['showLinks'], True)

    async def test_skips_online_streams_only_when_the_option_is_enabled(self):
        calls = 0
        
        async def fetch_impl(url):
            nonlocal calls
            calls += 1
            return {'ok': True, 'text': AsyncMock(return_value=self.html('one', 2, [{'url': 'https://cdn.test/a.flv'}]))}
            
        x = self.setup(fetch_impl)
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'handles': ['one'], 'skipOnline': True}})
        await x['api'].message({'type': 'TLC_OVERVIEW_CHECK'})
        await x['api'].message({'type': 'TLC_OVERVIEW_CHECK'})
        self.assertEqual(calls, 1)
        
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'skipOnline': False}})
        await x['api'].message({'type': 'TLC_OVERVIEW_CHECK'})
        self.assertEqual(calls, 2)

    async def test_retry_targets_the_original_handle_and_rejects_stale_or_invalid_slots(self):
        async def fetch_impl(url):
            return {}
            
        x = self.setup(fetch_impl)
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'handles': ['one', 'two'], 'skipOnline': True}})
        x['session']['tlc-overview-row-1'] = {'handle': 'two', 'status': 'online', 'media': [{'url': 'https://cdn.test/a.flv'}]}
        await x['api'].message({'type': 'TLC_OVERVIEW_RETRY', 'index': 1, 'handle': 'two'})
        self.assertEqual(x['session']['tlc-overview-retry-1']['handle'], 'two')
        
        with self.assertRaises(Exception) as cm:
            await x['api'].message({'type': 'TLC_OVERVIEW_RETRY', 'index': 1, 'handle': 'one'})
        self.assertIn('nicht gefunden', str(cm.exception))
        
        with self.assertRaises(Exception) as cm:
            await x['api'].message({'type': 'TLC_OVERVIEW_RETRY', 'index': 9, 'handle': 'two'})
        self.assertIn('nicht gefunden', str(cm.exception))

    async def test_online_without_links_is_checked_on_schedule_and_retries_only_its_own_slot(self):
        seen = []
        
        async def fetch_impl(url):
            name = re.search(r'@([^/]+)', url).group(1)
            seen.append(name)
            media = [{'url': 'https://cdn.test/two.flv'}] if name == 'two' else []
            return {'ok': True, 'text': AsyncMock(return_value=self.html(name, 2, media))}
            
        x = self.setup(fetch_impl)
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'handles': ['one', 'two'], 'skipOnline': True}})
        await x['api'].message({'type': 'TLC_OVERVIEW_CHECK'})
        await x['api'].message({'type': 'TLC_OVERVIEW_CHECK'})
        self.assertEqual(seen, ['one', 'two', 'one'])
        
        await x['api'].message({'type': 'TLC_OVERVIEW_RETRY', 'index': 0, 'handle': 'one'})
        self.assertEqual(seen, ['one', 'two', 'one', 'one'])

    async def test_top_selection_is_persisted_and_reset_preserves_it(self):
        async def fetch_impl(url):
            return {}
            
        x = self.setup(fetch_impl)
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'top': 'monitor'}})
        result = await x['api'].message({'type': 'TLC_OVERVIEW_GET'})
        self.assertEqual(result['config']['top'], 'monitor')
        
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'top': 'connection'}})
        result = await x['api'].message({'type': 'TLC_OVERVIEW_GET'})
        self.assertEqual(result['config']['top'], 'connection')
        
        await x['api'].message({'type': 'TLC_OVERVIEW_RESET'})
        result = await x['api'].message({'type': 'TLC_OVERVIEW_GET'})
        self.assertEqual(result['config']['top'], 'connection')
        
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'top': ''}})
        result = await x['api'].message({'type': 'TLC_OVERVIEW_GET'})
        self.assertEqual(result['config']['top'], '')

    async def test_manual_zero_link_retry_rescans_only_matching_live_tab_and_imports_its_captured_sources(self):
        captured = {
            'tabs': [
                {'id': 1, 'url': 'https://www.tiktok.com/@one/live'},
                {'id': 2, 'url': 'https://www.tiktok.com/@two/live'}
            ],
            'states': {
                1: {'media': []},
                2: {'media': [{'url': 'https://cdn.test/wrong.flv'}]}
            },
            'scans': []
        }
        
        async def fetch_impl(url):
            return {'ok': True, 'text': AsyncMock(return_value=self.html('one', 2))}
            
        x = self.setup(fetch_impl, captured)
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'handles': ['one']}})
        await x['api'].message({'type': 'TLC_OVERVIEW_CHECK'})
        result = await x['api'].message({'type': 'TLC_OVERVIEW_GET'})
        self.assertEqual(len(result['rows'][0]['media']), 0)
        
        captured['states'][1]['media'] = [{'url': 'https://cdn.test/live.flv', 'protocol': 'FLV'}]
        await x['api'].message({'type': 'TLC_OVERVIEW_RETRY', 'index': 0, 'handle': 'one'})
        result = await x['api'].message({'type': 'TLC_OVERVIEW_GET'})
        row = result['rows'][0]
        self.assertEqual(row['media'][0]['url'], 'https://cdn.test/live.flv')
        self.assertEqual(captured['scans'], [1, 1])

    async def test_twenty_handles_persistent_grid_options_and_high_index_actions_are_supported(self):
        async def fetch_impl(url):
            name = re.search(r'@([^/]+)', url).group(1)
            return {'ok': True, 'text': AsyncMock(return_value=self.html(name, 2, [{'url': f'https://cdn.test/{name}.flv'}]))}
            
        x = self.setup(fetch_impl)
        handles = [f'user{i}' for i in range(20)]
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'handles': handles, 'expanded': True, 'reverse': True, 'grid2': True}})
        await x['api'].message({'type': 'TLC_OVERVIEW_CHECK'})
        result = await x['api'].message({'type': 'TLC_OVERVIEW_GET'})
        self.assertEqual(len(result['rows']), 20)
        self.assertEqual(result['rows'][19]['status'], 'online')
        self.assertEqual(result['config']['reverse'], True)
        self.assertEqual(result['config']['grid2'], True)
        
        await x['api'].message({'type': 'TLC_OVERVIEW_RETRY', 'index': 19, 'handle': 'user19'})
        self.assertEqual(x['session']['tlc-overview-retry-19']['handle'], 'user19')
        
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'expanded': False}})
        result = await x['api'].message({'type': 'TLC_OVERVIEW_GET'})
        self.assertEqual(result['config']['handles'][19], 'user19')
        
        await x['api'].message({'type': 'TLC_OVERVIEW_RESET'})
        result = await x['api'].message({'type': 'TLC_OVERVIEW_GET'})
        self.assertTrue(all(not h for h in result['config']['handles']))

    async def test_manual_retry_refreshes_playing_stream_urls_only_when_skiponline_is_disabled(self):
        count = 0
        
        async def fetch_impl(url):
            nonlocal count
            count += 1
            return {'ok': True, 'text': AsyncMock(return_value=self.html('one', 2, [{'url': f'https://cdn.test/live-{count}.flv'}]))}
            
        x = self.setup(fetch_impl)
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'handles': ['one'], 'skipOnline': False}})
        await x['api'].message({'type': 'TLC_OVERVIEW_CHECK'})
        sender = {'tab': {'id': 42}, 'url': 'chrome-extension://test/status-overview.html'}
        await x['api'].message({'type': 'TLC_OVERVIEW_PLAYBACK', 'index': 0, 'handle': 'one', 'playing': True}, sender)
        await x['api'].message({'type': 'TLC_OVERVIEW_RETRY', 'index': 0, 'handle': 'one'})
        self.assertEqual(count, 2)
        result = await x['api'].message({'type': 'TLC_OVERVIEW_GET'})
        self.assertIn('live-2', result['rows'][0]['media'][0]['url'])
        self.assertEqual(x['session']['tlc-overview-retry-0']['handle'], 'one')
        
        await x['api'].message({'type': 'TLC_OVERVIEW_SET', 'config': {'skipOnline': True}})
        await x['api'].message({'type': 'TLC_OVERVIEW_CHECK'})
        await x['api'].message({'type': 'TLC_OVERVIEW_RETRY', 'index': 0, 'handle': 'one'})
        self.assertEqual(count, 2)

if __name__ == '__main__':
    unittest.main()
