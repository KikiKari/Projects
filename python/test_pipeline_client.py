#!/usr/bin/env python3
# test_pipeline_client.cjs — portiert nach python
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_pipeline_client.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_pipeline_client.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_pipeline_client.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_pipeline_client.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

import asyncio
import json
import os
from collections import defaultdict
from copy import deepcopy
import unittest.mock as mock
from unittest import IsolatedAsyncioTestCase


class Storage:
    def __init__(self, data):
        self.data = data

    async def get(self, keys):
        if isinstance(keys, str):
            keys = [keys]
        return {key: self.data.get(key) for key in keys}

    async def set(self, values):
        self.data.update(deepcopy(values))


class Database:
    def __init__(self):
        self.rows = {}

    def transaction(self):
        class Transaction:
            def __init__(self, db):
                self.db = db

            def objectStore(self, name):
                class ObjectStore:
                    def __init__(self, db):
                        self.db = db

                    def put(self, row):
                        class Request:
                            def __init__(self, db, row):
                                self.result = None
                                asyncio.get_event_loop().call_soon(lambda: setattr(self, 'result', None))
                                asyncio.get_event_loop().call_soon(lambda: self.onsuccess() if hasattr(self, 'onsuccess') else None)
                                asyncio.get_event_loop().call_soon(lambda: tx.oncomplete() if hasattr(tx, 'oncomplete') else None)
                                self.db.rows[row['eventId']] = deepcopy(row)

                            def onsuccess(self):
                                pass

                        req = Request(self.db, row)
                        return req

                    def delete(self, id):
                        class Request:
                            def __init__(self, db, id):
                                self.result = None
                                asyncio.get_event_loop().call_soon(lambda: setattr(self, 'result', None))
                                asyncio.get_event_loop().call_soon(lambda: self.onsuccess() if hasattr(self, 'onsuccess') else None)
                                asyncio.get_event_loop().call_soon(lambda: tx.oncomplete() if hasattr(tx, 'oncomplete') else None)
                                if id in self.db.rows:
                                    del self.db.rows[id]

                            def onsuccess(self):
                                pass

                        req = Request(self.db, id)
                        return req

                    def getAll(self):
                        class Request:
                            def __init__(self, db):
                                self.result = None
                                asyncio.get_event_loop().call_soon(lambda: setattr(self, 'result', [deepcopy(row) for row in db.rows.values()]))
                                asyncio.get_event_loop().call_soon(lambda: self.onsuccess() if hasattr(self, 'onsuccess') else None)
                                asyncio.get_event_loop().call_soon(lambda: tx.oncomplete() if hasattr(tx, 'oncomplete') else None)

                            def onsuccess(self):
                                pass

                        req = Request(self.db)
                        return req

                return ObjectStore(self.db)

        tx = Transaction(self)
        return tx


class IndexedDB:
    def open(self, name, version):
        class Request:
            def __init__(self):
                self.result = None
                asyncio.get_event_loop().call_soon(lambda: setattr(self, 'result', database))
                asyncio.get_event_loop().call_soon(lambda: self.onsuccess() if hasattr(self, 'onsuccess') else None)

            def onsuccess(self):
                pass

        req = Request()
        return req


def client():
    local = {'tlc-settings': {'universalCaptionApiKey': 'universal-secret', 'pairingCode': 'pair-secret'}}
    session = {}
    rows = {}
    received = []

    storage_local = Storage(local)
    storage_session = Storage(session)
    database = Database()
    indexed_db = IndexedDB()

    # Mock fetch function
    async def fetch(url, options=None):
        if url.endswith('/events'):
            body = json.loads(options['body']) if options and 'body' in options else {}
            received.append(body)
        response = type('Response', (), {
            'ok': True,
            'json': mock.AsyncMock(return_value={'cursor': len(received)})
        })()
        return response

    # Create a global context similar to JavaScript's globalThis
    context = {
        'crypto': mock.MagicMock(),
        'indexedDB': indexed_db,
        'AbortSignal': mock.MagicMock(),
        'console': mock.MagicMock(),
        'chrome': {
            'storage': {
                'local': storage_local,
                'session': storage_session
            },
            'runtime': {
                'id': 'self'
            },
            'alarms': {
                'create': lambda *args: None,
                'onAlarm': {
                    'addListener': lambda *args: None
                }
            }
        },
        'fetch': fetch
    }

    # Read and execute the pipeline-client.js file
    script_path = os.path.join(os.path.dirname(__file__), '../browser-extension/pipeline-client.js')
    with open(script_path, 'r') as f:
        script_content = f.read()

    # Execute the script in the context (this is a simplified approach)
    exec(script_content, context)

    return {
        'api': context.get('TLCPipelines'),
        'local': local,
        'session': session,
        'received': received,
        'rows': database.rows
    }


class TestPipelineClient(IsolatedAsyncioTestCase):
    async def test_one_key_two_tabs_reload_and_delayed_old_document_events_stay_separate(self):
        c = client()
        await c['api'].start(1, 'doc-a')
        await c['api'].start(2, 'doc-b')
        await c['api'].publish(1, 'chat', {'text': 'first'}, 'pair-secret', 'chat', 'doc-a')
        await c['api'].start(1, 'doc-c')
        await c['api'].publish(1, 'chat', {'text': 'late'}, 'late', 'chat', 'doc-a')
        await c['api'].publish(1, 'chat', {'text': 'current'}, 'current', 'chat')
        
        for i in range(30):
            await asyncio.sleep(0)  # Yield control to event loop
            await c['api'].flush()
            
        self.assertEqual(len(c['rows']), 0)
        chats = [row for row in c['received'] if row.get('pipeline') == 'chat' and row.get('availability') == 'available']
        self.assertEqual([row.get('documentId') for row in chats], ['doc-a', 'doc-a', 'doc-c'])
        self.assertEqual(chats[0].get('raw'), '[credential removed]')
        self.assertEqual(chats[0].get('credentialsRedacted'), True)
        b = next((row for row in c['received'] if row.get('documentId') == 'doc-b'), None)
        self.assertNotEqual(chats[0].get('tabId'), b.get('tabId'))
        self.assertEqual(chats[0].get('clientId'), b.get('clientId'))
        event_ids = [row.get('eventId') for row in c['received']]
        self.assertEqual(len(set(event_ids)), len(event_ids))


if __name__ == '__main__':
    unittest.main()
