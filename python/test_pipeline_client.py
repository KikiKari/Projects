#!/usr/bin/env python3
# test_pipeline_client.cjs — portiert nach python
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_pipeline_client.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_pipeline_client.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_pipeline_client.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

import asyncio
import json
import os
import unittest
from collections import defaultdict
from unittest.mock import AsyncMock, MagicMock
import sys

class TestPipelineClient(unittest.IsolatedAsyncioTestCase):
    
    def client(self):
        local = {'tlc-settings': {'universalCaptionApiKey': 'universal-secret', 'pairingCode': 'pair-secret'}}
        session = {}
        rows = {}
        received = []
        
        # Create a mock storage object
        def storage(data):
            async def get(keys):
                if isinstance(keys, str):
                    keys = [keys]
                return {key: data.get(key) for key in keys}
            
            async def set_vals(values):
                data.update(values)
                
            return {'get': get, 'set': set_vals}
        
        # Mock database operations
        class Database:
            def transaction(self):
                class Transaction:
                    def object_store(self):
                        class ObjectStore:
                            async def put(self, row):
                                rows[row['eventId']] = self._structured_clone(row)
                                
                            async def delete(self, id):
                                if id in rows:
                                    del rows[id]
                                    
                            async def get_all(self):
                                return [self._structured_clone(row) for row in rows.values()]
                                
                            def _structured_clone(self, obj):
                                return json.loads(json.dumps(obj))
                        
                        return ObjectStore()
                    
                    async def __aenter__(self):
                        return self
                        
                    async def __aexit__(self, exc_type, exc_val, exc_tb):
                        pass
                        
                return Transaction()
        
        # Mock fetch function
        async def fetch(url, options=None):
            if url.endswith('/events'):
                body = json.loads(options['body'])
                received.append(body)
            return {'ok': True, 'json': AsyncMock(return_value={'cursor': len(received)})}
        
        # Create context-like environment
        context = {
            'crypto': MagicMock(),
            'indexedDB': Database(),
            'AbortSignal': MagicMock(),
            'console': MagicMock(),
            'chrome': {
                'storage': {
                    'local': storage(local),
                    'session': storage(session)
                },
                'runtime': {'id': 'self'},
                'alarms': {
                    'create': lambda: None,
                    'onAlarm': {'addListener': lambda fn: None}
                }
            },
            'fetch': fetch
        }
        
        # Load the pipeline client script
        script_path = os.path.join(os.path.dirname(__file__), '../browser-extension/pipeline-client.js')
        with open(script_path, 'r') as f:
            script_content = f.read()
        
        # Execute the script in our context (this is a simplified approach)
        # In reality, you'd need to properly sandbox this or convert the JS logic to Python
        exec(script_content, context)
        
        return {
            'api': context.get('TLCPipelines', {}),
            'local': local,
            'session': session,
            'received': received,
            'rows': rows
        }
    
    async def test_one_key_two_tabs_reload_and_delayed_old_document_events_stay_separate(self):
        c = self.client()
        
        # Start documents
        await c['api'].start(1, 'doc-a')
        await c['api'].start(2, 'doc-b')
        
        # Publish first chat message
        await c['api'].publish(1, 'chat', {'text': 'first'}, 'pair-secret', 'chat', 'doc-a')
        
        # Start another document
        await c['api'].start(1, 'doc-c')
        
        # Publish late and current messages
        await c['api'].publish(1, 'chat', {'text': 'late'}, 'late', 'chat', 'doc-a')
        await c['api'].publish(1, 'chat', {'text': 'current'}, 'current', 'chat')
        
        # Wait for processing
        for i in range(30):
            await asyncio.sleep(0)  # Yield control
            if hasattr(c['api'], 'flush'):
                await c['api'].flush()
        
        # Assertions
        self.assertEqual(len(c['rows']), 0)
        
        chats = [row for row in c['received'] if row.get('pipeline') == 'chat' and row.get('availability') == 'available']
        document_ids = [row.get('documentId') for row in chats]
        self.assertEqual(document_ids, ['doc-a', 'doc-a', 'doc-c'])
        
        self.assertEqual(chats[0].get('raw'), '[credential removed]')
        self.assertEqual(chats[0].get('credentialsRedacted'), True)
        
        b = next((row for row in c['received'] if row.get('documentId') == 'doc-b'), None)
        self.assertNotEqual(chats[0].get('tabId'), b.get('tabId'))
        self.assertEqual(chats[0].get('clientId'), b.get('clientId'))
        
        event_ids = [row.get('eventId') for row in c['received']]
        self.assertEqual(len(set(event_ids)), len(event_ids))

if __name__ == '__main__':
    unittest.main()
