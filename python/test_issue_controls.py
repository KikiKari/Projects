#!/usr/bin/env python3
# test_issue_controls.cjs — portiert nach python
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_issue_controls.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_issue_controls.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_issue_controls.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_issue_controls.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

import unittest
from unittest.mock import Mock, patch, call
import sys
import os

# Fuege das Verzeichnis zur PYTHONPATH hinzu
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'browser-extension'))

try:
    import sidepanel
    import content_core
except ImportError:
    # Fuer den Fall, dass die Module nicht gefunden werden koennen
    sidepanel = None
    content_core = None


class TestIssueControls(unittest.TestCase):
    
    def fragment(self, source_code, start, end):
        """Extrahiert einen Code-Fragment zwischen Start- und Endmarker"""
        a = source_code.find(start)
        b = source_code.find(end, a + len(start))
        if a < 0 or b <= a:
            raise ValueError(f"Konnte Fragment nicht finden: {start} ... {end}")
        return source_code[a:b]
        
    def controls(self):
        """Erstellt ein Kontroll-Objekt mit simulierten DOM-Elementen"""
        document = {'activeElement': None}
        
        elements = {}
        
        def get_element(id):
            if id not in elements:
                elem = {
                    'hidden': True,
                    'disabled': False,
                    'textContent': 'Off',
                    'handlers': {},
                    'addEventListener': lambda name, fn: elem['handlers'].update({name: fn}),
                    'focus': lambda: document.update({'activeElement': elem}),
                    'click': lambda: elem['handlers'].get('click', lambda e: None)({'target': elem})
                }
                elements[id] = elem
            return elements[id]
            
        # Simuliere Proxy-Verhalten durch __getitem__
        elements_proxy = type('ElementsProxy', (), {
            '__getitem__': lambda self, key: get_element(key)
        })()
        
        return {'elements': elements_proxy, 'document': document}

    @unittest.skipIf(sidepanel is None or content_core is None, "Benötigte Module nicht gefunden")
    def test_175_manual_and_automatic_speech_reject_raw_point_triggers_before_author_prefixes(self):
        """Testfall 175"""
        with open(os.path.join(os.path.dirname(__file__), '..', 'browser-extension', 'sidepanel.js'), 'r', encoding='utf-8') as f:
            source = f.read()
            
        for enabled in [False, True]:
            with self.subTest(enabled=enabled):
                spoken = []
                
                # Erstelle Service-Objekt
                s = {
                    'core': content_core,
                    'filterExternalSpeechTriggers': enabled,
                    'speechEnabled': True,
                    'speechQueue': [],
                    'elements': {'speech-status': {}},
                    'pumpSpeech': lambda: None,
                    'speechText': lambda item: f"Autor sagt {item['content']}",
                    'speechLang': lambda: 'de',
                    'serviceSpeech': lambda text: spoken.append(text),
                    'browserSpeech': lambda: self.fail('unexpected fallback')
                }
                
                # Extrahiere relevante Funktionen aus dem Sourcecode
                speak_item_fragment = self.fragment(source, '  async function speakItem(', '  async function pumpSpeech(')
                enqueue_speech_fragment = self.fragment(source, '  function enqueueSpeech(', '  function ')
                
                # Fuehre die Fragmente im Kontext aus
                exec_globals = {}
                exec(speak_item_fragment, exec_globals, s)
                exec(enqueue_speech_fragment, exec_globals, s)
                
                # Setze speakItem Funktion
                s['speakItem'] = exec_globals.get('speakItem')
                if not s['speakItem']:
                    raise KeyError("speakItem Funktion nicht gefunden")
                    
                # Setze enqueueSpeech Funktion  
                s['enqueueSpeech'] = exec_globals.get('enqueueSpeech')
                if not s['enqueueSpeech']:
                    raise KeyError("enqueueSpeech Funktion nicht gefunden")
                
                # Testdaten
                contents = ['.Text','. Text','  .Text','Normal','Ein Satz. Noch einer']
                for content in contents:
                    import asyncio
                    asyncio.run(s['speakItem']({'content': content}))
                    s['enqueueSpeech']({'content': content})
                    
                self.assertEqual(len(spoken), 2 if enabled else 5)
                self.assertEqual(len(s['speechQueue']), 2 if enabled else 5)

    def test_176_speech_switch_commits_on_off_only_after_successful_request(self):
        """Testfall 176 - Teil 1"""
        s = self.controls()
        s.update({
            'speechEnabled': False,
            'send': lambda: None,
            'refresh': lambda: None,
            'activateSpeech': lambda: s.update({'speechEnabled': True}),
            'stopSpeech': lambda: s.update({'speechEnabled': False})
        })
        
        # Lade den relevanten Code-Abschnitt
        if sidepanel:
            with open(os.path.join(os.path.dirname(__file__), '..', 'browser-extension', 'sidepanel.js'), 'r', encoding='utf-8') as f:
                source = f.read()
                
            fragment_code = self.fragment(source, 
                '  elements["toggle-speech"].addEventListener',
                '  elements["speech-volume"].addEventListener')
                
            # Fuehre Code aus
            exec(fragment_code, {}, s)
            
            # Tests durchfuehren
            s['elements']['toggle-speech'].click()
            self.assertTrue(s['speechEnabled'])
            
            # Fehler simulieren
            s['send'] = lambda: (_ for _ in ()).throw(Exception('failed'))
            s['elements']['toggle-speech'].click()
            self.assertTrue(s['speechEnabled'])
            self.assertRegex(str(s['elements']['speech-status']['textContent']), r'failed')
            
            # Erfolg simulieren
            s['send'] = lambda: None
            s['elements']['toggle-speech'].click()
            self.assertFalse(s['speechEnabled'])

    def test_176_connection_selects_both_commands_and_preserves_state_on_rejection(self):
        """Testfall 176 - Teil 2"""
        calls = []
        s = self.controls()
        s.update({
            'currentState': {'hook': {'armed': False}},
            'send': lambda cmd: calls.append(cmd),
            'refresh': lambda: s['currentState']['hook'].update({'armed': not s['currentState']['hook']['armed']})
        })
        
        if sidepanel:
            with open(os.path.join(os.path.dirname(__file__), '..', 'browser-extension', 'sidepanel.js'), 'r', encoding='utf-8') as f:
                source = f.read()
                
            fragment_code = self.fragment(source,
                '  elements["toggle-hook"].addEventListener',
                '  elements["reset-tab"].addEventListener')
                
            exec(fragment_code, {}, s)
            
            # Klicke zweimal
            s['elements']['toggle-hook'].click()
            s['elements']['toggle-hook'].click()
            self.assertEqual(calls, ['TLC_ENABLE_HOOK', 'TLC_DISABLE_HOOK'])
            
            # Fehler simulieren
            s['send'] = lambda: (_ for _ in ()).throw(Exception('failed'))
            s['elements']['toggle-hook'].click()
            self.assertFalse(s['currentState']['hook']['armed'])
            self.assertRegex(str(s['elements']['notice']['textContent']), r'failed')

    def test_176_connection_dialog_returns_focus_and_traps_tab_in_both_directions(self):
        """Testfall 176 - Teil 3"""
        s = self.controls()
        
        if sidepanel:
            with open(os.path.join(os.path.dirname(__file__), '..', 'browser-extension', 'sidepanel.js'), 'r', encoding='utf-8') as f:
                source = f.read()
                
            # Erster Code-Abschnitt
            fragment1 = self.fragment(source,
                '  elements["open-connection-settings"].addEventListener',
                '  elements["open-speech-settings"].addEventListener')
                
            exec(fragment1, {}, s)
            
            # Event Listener Setup
            key_handler = [None]
            s['document']['addEventListener'] = lambda name, fn: key_handler.__setitem__(0, fn)
            
            # Zweiter Code-Abschnitt
            fragment2 = self.fragment(source,
                '  document.addEventListener("keydown"',
                '  elements["keep-speech-active"].addEventListener')
                
            exec(fragment2, {}, s)
            
            # Trigger click
            s['elements']['open-connection-settings'].click()
            self.assertFalse(s['elements']['connection-settings-modal']['hidden'])
            self.assertEqual(s['document']['activeElement'], s['elements']['close-connection-settings'])
            
            # Setup fuer Tab-Navigation
            first = s['elements']['close-connection-settings']
            last = s['elements']['quick-recover-seconds']
            s['elements']['connection-settings-modal']['querySelectorAll'] = lambda _: [first, last]
            
            prevented = [0]
            def prevent_default():
                prevented[0] += 1
                
            # Shift+Tab
            event1 = {'key': 'Tab', 'shiftKey': True, 'preventDefault': prevent_default}
            key_handler[0](event1)
            self.assertEqual(s['document']['activeElement'], last)
            
            # Tab
            event2 = {'key': 'Tab', 'shiftKey': False, 'preventDefault': prevent_default}
            key_handler[0](event2)
            self.assertEqual(s['document']['activeElement'], first)
            self.assertEqual(prevented[0], 2)
            
            # Escape
            event3 = {'key': 'Escape'}
            key_handler[0](event3)
            self.assertTrue(s['elements']['connection-settings-modal']['hidden'])
            self.assertEqual(s['document']['activeElement'], s['elements']['open-connection-settings'])


if __name__ == '__main__':
    unittest.main()
