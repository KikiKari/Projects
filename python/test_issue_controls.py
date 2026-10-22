#!/usr/bin/env python3
# test_issue_controls.cjs — portiert nach python
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_issue_controls.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_issue_controls.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_issue_controls.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_issue_controls.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

import unittest
from unittest.mock import Mock, patch, call
import asyncio
import sys
import os

# Add the parent directory to sys.path to import modules
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

class TestIssueControls(unittest.TestCase):
    def setUp(self):
        # Mock the required modules and functions
        self.mock_core = Mock()
        self.mock_core.process_text = Mock(side_effect=lambda x: x)
        
    def fragment(self, source, start, end):
        """Extract code fragment between start and end markers"""
        a = source.find(start)
        b = source.find(end, a + len(start))
        if a < 0 or b <= a:
            raise AssertionError(f"Could not find fragment between '{start}' and '{end}'")
        return source[a:b]
        
    def controls(self):
        """Create mock DOM elements and document"""
        class MockElement:
            def __init__(self, id):
                self.id = id
                self.hidden = True
                self.disabled = False
                self.checked = False
                self.value = ''
                self.textContent = 'Off'
                self.handlers = {}
                self.document = None
                
            def addEventListener(self, name, fn):
                self.handlers[name] = fn
                
            def focus(self):
                if self.document:
                    self.document.activeElement = self
                    
            def click(self):
                if 'click' in self.handlers:
                    return self.handlers['click']({'target': self})
                    
            def querySelectorAll(self, selector):
                return []
                
        class MockDocument:
            def __init__(self):
                self.activeElement = None
                self.event_listeners = {}
                
            def addEventListener(self, name, fn):
                self.event_listeners[name] = fn
                
        document = MockDocument()
        elements = {}
        
        def get_element(id):
            if id not in elements:
                elements[id] = MockElement(id)
                elements[id].document = document
            return elements[id]
            
        # Override getitem to create elements on demand
        elements.__getitem__ = lambda self, key: get_element(key)
        elements.get = lambda key, default=None: get_element(key)
        
        return {'elements': elements, 'document': document}

    async def test_175_manual_and_automatic_speech_reject_raw_point_triggers_before_author_prefixes(self):
        # Read the source file
        source_path = os.path.join(os.path.dirname(__file__), '../browser-extension/sidepanel.js')
        with open(source_path, 'r', encoding='utf-8') as f:
            source = f.read()
            
        for enabled in [False, True]:
            spoken = []
            
            # Create test context
            s = {
                'core': self.mock_core,
                'filterExternalSpeechTriggers': enabled,
                'externalSpeechTriggerCharacters': '.',
                'speechEnabled': True,
                'speechQueue': [],
                'elements': {'speech-status': {}},
                'pumpSpeech': lambda: None,
                'speechText': lambda item: f"Autor sagt {item['content']}",
                'speechLang': lambda: 'de',
                'serviceSpeech': lambda text: spoken.append(text),
                'browserSpeech': lambda: exec('raise AssertionError("unexpected fallback")')
            }
            
            # Extract and execute relevant code fragments
            speak_item_code = self.fragment(source, '  async function speakItem(', '  async function pumpSpeech(')
            enqueue_speech_code = self.fragment(source, '  function enqueueSpeech(', '  function ')
            
            # Execute the code in the context
            exec(speak_item_code, s)
            exec(enqueue_speech_code, s)
            
            # Test with various content
            test_contents = ['.Text', '. Text', '  .Text', 'Normal', 'Ein Satz. Noch einer']
            for content in test_contents:
                await s['speakItem']({'content': content})
                s['enqueueSpeech']({'content': content})
                
            expected_count = 2 if enabled else 5
            self.assertEqual(len(spoken), expected_count)
            self.assertEqual(len(s['speechQueue']), expected_count)

    async def test_187_input_truncates_pasted_values_and_checkbox_preserves_selection(self):
        calls = []
        s = {**self.controls()}
        s['core'] = self.mock_core
        s['filterExternalSpeechTriggers'] = False
        s['externalSpeechTriggerCharacters'] = '.'
        s['send'] = lambda type, **payload: calls.append({'type': type, **payload})
        
        # Read and execute the relevant code fragment
        source_path = os.path.join(os.path.dirname(__file__), '../browser-extension/sidepanel.js')
        with open(source_path, 'r', encoding='utf-8') as f:
            source = f.read()
            
        code_fragment = self.fragment(source, '  elements["filter-external-speech-triggers"].addEventListener', '  elements["game-mode"].addEventListener')
        exec(code_fragment, s)
        
        # Test input handling
        input_elem = s['elements']['external-speech-trigger-characters']
        input_elem.value = '.,-;:!'
        await input_elem.handlers['input']()
        self.assertEqual(input_elem.value, '.,-;:')
        self.assertEqual(calls[-1]['externalSpeechTriggerCharacters'], '.,-;:')
        
        # Test checkbox handling
        toggle = s['elements']['filter-external-speech-triggers']
        toggle.checked = True
        await toggle.handlers['change']()
        toggle.checked = False
        await toggle.handlers['change']()
        self.assertEqual(input_elem.value, '.,-;:')
        self.assertEqual(input_elem.disabled, False)
        self.assertEqual(calls[-1]['filterExternalSpeechTriggers'], False)
        
        # Test emoji truncation
        input_elem.value = '😀😁😂😃😄😅'
        await input_elem.handlers['input']()
        self.assertEqual(input_elem.value, '😀😁😂😃😄')
        
        # Test empty value
        input_elem.value = ''
        await input_elem.handlers['input']()
        self.assertEqual(calls[-1]['externalSpeechTriggerCharacters'], '')

    async def test_187_custom_prefixes_apply_to_manual_and_automatic_speech_before_author_prefixes(self):
        source_path = os.path.join(os.path.dirname(__file__), '../browser-extension/sidepanel.js')
        with open(source_path, 'r', encoding='utf-8') as f:
            source = f.read()
            
        for enabled in [False, True]:
            spoken = []
            s = {
                'core': self.mock_core,
                'filterExternalSpeechTriggers': enabled,
                'externalSpeechTriggerCharacters': '.,-',
                'speechEnabled': True,
                'speechQueue': [],
                'elements': {'speech-status': {}},
                'pumpSpeech': lambda: None,
                'speechText': lambda item: f"Autor sagt {item['content']}",
                'speechLang': lambda: 'de',
                'serviceSpeech': lambda text: spoken.append(text),
                'browserSpeech': lambda: exec('raise AssertionError("unexpected fallback")')
            }
            
            # Extract and execute relevant code fragments
            speak_item_code = self.fragment(source, '  async function speakItem(', '  async function pumpSpeech(')
            enqueue_speech_code = self.fragment(source, '  function enqueueSpeech(', '  function ')
            
            exec(speak_item_code, s)
            exec(enqueue_speech_code, s)
            
            # Test with various content
            test_contents = ['.Hallo', ',Hallo', '- Hallo', 'Hallo, zusammen.']
            for content in test_contents:
                await s['speakItem']({'content': content})
                s['enqueueSpeech']({'content': content})
                
            expected_count = 1 if enabled else 4
            self.assertEqual(len(spoken), expected_count)
            self.assertEqual(len(s['speechQueue']), expected_count)

    async def test_176_speech_switch_commits_on_off_only_after_successful_request(self):
        s = {**self.controls()}
        s['speechEnabled'] = False
        s['send'] = lambda: None
        s['refresh'] = lambda: None
        s['activateSpeech'] = lambda: setattr(s, 'speechEnabled', True)
        s['stopSpeech'] = lambda: setattr(s, 'speechEnabled', False)
        
        # Read and execute the relevant code fragment
        source_path = os.path.join(os.path.dirname(__file__), '../browser-extension/sidepanel.js')
        with open(source_path, 'r', encoding='utf-8') as f:
            source = f.read()
            
        code_fragment = self.fragment(source, '  elements["toggle-speech"].addEventListener', '  elements["speech-volume"].addEventListener')
        exec(code_fragment, s)
        
        # Test successful toggle
        await s['elements']['toggle-speech'].click()
        self.assertEqual(s['speechEnabled'], True)
        
        # Test failed toggle
        s['send'] = lambda: exec('raise Exception("failed")')
        await s['elements']['toggle-speech'].click()
        self.assertEqual(s['speechEnabled'], True)
        self.assertRegex(s['elements']['speech-status'].textContent, r'failed')
        
        # Test successful toggle off
        s['send'] = lambda: None
        await s['elements']['toggle-speech'].click()
        self.assertEqual(s['speechEnabled'], False)

    async def test_176_connection_selects_both_commands_and_preserves_state_on_rejection(self):
        calls = []
        s = {**self.controls()}
        s['currentState'] = {'hook': {'armed': False}}
        s['send'] = lambda cmd: calls.append(cmd)
        s['refresh'] = lambda: setattr(s['currentState']['hook'], 'armed', not s['currentState']['hook']['armed'])
        
        # Read and execute the relevant code fragment
        source_path = os.path.join(os.path.dirname(__file__), '../browser-extension/sidepanel.js')
        with open(source_path, 'r', encoding='utf-8') as f:
            source = f.read()
            
        code_fragment = self.fragment(source, '  elements["toggle-hook"].addEventListener', '  elements["reset-tab"].addEventListener')
        exec(code_fragment, s)
        
        # Test successful toggles
        await s['elements']['toggle-hook'].click()
        await s['elements']['toggle-hook'].click()
        self.assertEqual(calls, ['TLC_ENABLE_HOOK', 'TLC_DISABLE_HOOK'])
        
        # Test failed toggle
        s['send'] = lambda: exec('raise Exception("failed")')
        await s['elements']['toggle-hook'].click()
        self.assertEqual(s['currentState']['hook']['armed'], False)
        self.assertRegex(s['elements']['notice'].textContent, r'failed')

    def test_176_connection_dialog_returns_focus_and_traps_tab_in_both_directions(self):
        s = self.controls()
        
        # Read and execute the relevant code fragments
        source_path = os.path.join(os.path.dirname(__file__), '../browser-extension/sidepanel.js')
        with open(source_path, 'r', encoding='utf-8') as f:
            source = f.read()
            
        code1 = self.fragment(source, '  elements["open-connection-settings"].addEventListener', '  elements["open-speech-settings"].addEventListener')
        code2 = self.fragment(source, '  document.addEventListener("keydown"', '  elements["keep-speech-active"].addEventListener')
        
        exec(code1, s)
        
        key_handler = None
        def add_event_listener(name, fn):
            nonlocal key_handler
            key_handler = fn
            
        s['document'].addEventListener = add_event_listener
        exec(code2, s)
        
        # Test opening connection settings
        s['elements']['open-connection-settings'].click()
        self.assertEqual(s['elements']['connection-settings-modal'].hidden, False)
        self.assertEqual(s['document'].activeElement, s['elements']['close-connection-settings'])
        
        # Setup modal elements
        first = s['elements']['close-connection-settings']
        last = s['elements']['quick-recover-seconds']
        s['elements']['connection-settings-modal'].querySelectorAll = lambda selector: [first, last]
        
        # Test tab navigation
        prevented = 0
        def prevent_default():
            nonlocal prevented
            prevented += 1
            
        key_handler({'key': 'Tab', 'shiftKey': True, 'preventDefault': prevent_default})
        self.assertEqual(s['document'].activeElement, last)
        
        key_handler({'key': 'Tab', 'shiftKey': False, 'preventDefault': prevent_default})
        self.assertEqual(s['document'].activeElement, first)
        self.assertEqual(prevented, 2)
        
        # Test escape key
        key_handler({'key': 'Escape'})
        self.assertEqual(s['elements']['connection-settings-modal'].hidden, True)
        self.assertEqual(s['document'].activeElement, s['elements']['open-connection-settings'])


if __name__ == '__main__':
    unittest.main()
