#!/usr/bin/env python3
# test_scanner_limits.cjs — portiert nach python
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_scanner_limits.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_scanner_limits.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_scanner_limits.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_scanner_limits.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

import asyncio
import json
import os
import sys
from typing import Any, Dict, List, Callable
import copy

# Mock classes and functions to simulate the JavaScript environment
class MockDate:
    @staticmethod
    def now():
        return 0

class MockMouseEvent:
    def __init__(self, *args, **kwargs):
        pass

def mock_set_timeout(fn: Callable[[], None]) -> int:
    fn()
    return 1

def mock_scroll_to(*args, **kwargs):
    pass

def mock_scroll_by(*args, **kwargs):
    pass

def structured_clone(obj):
    return copy.deepcopy(obj)

async def main():
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    sources = [
        ["browser-extension/content.js", "  function explicitCardSummary", True],
        ["mobile-shared/webview-bridge.js", "  function primaryVideo", False]
    ]
    
    for file, end_marker, browser in sources:
        with open(os.path.join(root, file), 'r', encoding='utf-8') as f:
            source = f.read()
        
        start_index = source.find("  async function scanRecommendations(run)")
        if start_index == -1:
            raise AssertionError("Could not find scanRecommendations function")
            
        end_index = source.find(end_marker, start_index)
        if end_index == -1:
            raise AssertionError(f"Could not find end marker {end_marker}")
            
        code = source[start_index:end_index]
        if len(code) <= 100:
            raise AssertionError("Code segment too short")
        
        # Import content-core module
        content_core_path = os.path.join(root, "browser-extension/content-core.js")
        if not os.path.exists(content_core_path):
            raise FileNotFoundError(f"content-core.js not found at {content_core_path}")
        
        # For each test case
        for n in [1, 50, 51, 299, 300, 301]:
            updates = []
            cards = []
            for i in range(301):
                card_obj = {
                    'scrollIntoView': lambda: None,
                    'dispatchEvent': lambda: None
                }
                cards.append({
                    'handle': f"creator{i}",
                    'card': card_obj
                })
            
            run = {
                'limit': min(n, 300),
                'sourceUrl': "https://www.tiktok.com/@creator/live",
                'runId': "test",
                'cancelled': False
            }
            
            # Create a mock context similar to VM context
            context_globals = {
                'root': {},
                'scrollX': 0,
                'scrollY': 0,
                'innerHeight': 800,
                'location': {'href': run['sourceUrl']},
                'Date': MockDate,
                'MouseEvent': MockMouseEvent,
                'setTimeout': mock_set_timeout,
                'window': {
                    'scrollX': 0,
                    'scrollY': 0,
                    'innerHeight': 800,
                    'scrollTo': mock_scroll_to,
                    'scrollBy': mock_scroll_by
                },
                'scrollTo': mock_scroll_to,
                'scrollBy': mock_scroll_by,
                'activeRecommendationScan': run,
                'RECOMMENDATION_SCAN_MAX_ROUNDS': 12,
                'RECOMMENDATION_SCAN_MAX_MS': 45000,
                'recommendationCards': lambda: cards,
                'recommendationItem': lambda e, p: {
                    'handle': e['handle'],
                    'position': p,
                    'title': "x" * 300
                },
                'text': str,
                'emit': lambda type, p: updates.append(structured_clone(p)),
                'emitRecommendationProgress': lambda r, status, items: updates.append(structured_clone({
                    'status': status,
                    'items': items
                }))
            }
            
            # Execute the code in the context
            exec(code, context_globals)
            
            # Run the scanRecommendations function
            if 'scanRecommendations' in context_globals:
                await context_globals['scanRecommendations'](run)
            else:
                raise NameError("scanRecommendations function not defined")
            
            # Assertions
            if not updates:
                raise AssertionError("No updates recorded")
                
            last_update = updates[-1]
            if last_update.get('status') != 'complete':
                raise AssertionError(f"Expected status 'complete', got '{last_update.get('status')}'")
                
            expected_items_length = min(n, 300)
            if len(last_update.get('items', [])) != expected_items_length:
                raise AssertionError(f"Expected {expected_items_length} items, got {len(last_update.get('items', []))}")
                
            if last_update.get('items', []) and last_update['items'][-1].get('position') != expected_items_length:
                raise AssertionError(f"Expected last item position {expected_items_length}, got {last_update['items'][-1].get('position')}")
        
        print(f"PASS synthetic production scan loop: {file}; 1,50,51,299,300,301")

if __name__ == "__main__":
    asyncio.run(main())
