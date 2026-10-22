#!/usr/bin/env python3
# test_external_speech_filter.cjs — portiert nach python
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_external_speech_filter.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

import unittest
from content_core import shouldFilterExternalSpeechTrigger as filter_func, normalizeExternalSpeechTriggerCharacters as normalize

class TestExternalSpeechFilter(unittest.TestCase):
    
    def test_basic_filtering(self):
        for enabled in [False, True]:
            for text in ['.Text', '. Text', '  .Text', '\t\n. Text', 'Normal', 'Ein Satz. Noch einer', '']:
                with self.subTest(enabled=enabled, text=text):
                    expected = enabled and text.lstrip().startswith('.')
                    self.assertEqual(filter_func(text, enabled), expected)

    def test_0PE_187_literal_prefixes(self):
        """0PE-187: individual literal prefixes, commas and semicolons are not separators"""
        for enabled in [False, True]:
            for text in ['.Hallo', ',Hallo', '- Hallo', '  , Hallo']:
                with self.subTest(enabled=enabled, text=text):
                    self.assertEqual(filter_func(text, enabled, '.,-'), enabled)
            
            for text in ['Hallo, zusammen.', 'Normal-Text', 'Hallo', '.']:
                with self.subTest(enabled=enabled, text=text):
                    self.assertEqual(filter_func(text, enabled, ',-'), False)
            
            with self.subTest(enabled=enabled, text=';Hallo'):
                self.assertEqual(filter_func(';Hallo', enabled, ';'), enabled)
                
            with self.subTest(enabled=enabled, text='[Hallo'):
                self.assertEqual(filter_func('[Hallo', enabled, '['), enabled)
                
            with self.subTest(enabled=enabled, text='Hallo'):
                self.assertEqual(filter_func('Hallo', enabled, '['), False)

    def test_0PE_187_unicode_triggers(self):
        """0PE-187: five Unicode scalar triggers, paste sanitization and explicit empty selection"""
        self.assertEqual(normalize(None), '.')
        self.assertEqual(normalize(''), '')
        self.assertEqual(normalize('.,-;:!='), '.,-;:')
        self.assertEqual(normalize(' a1 "\'.,- '), '.,-')
        self.assertEqual(normalize('😀😁😂😃😄😅'), '😀😁😂😃😄')
        self.assertEqual(filter_func('😀Hallo', True, '😀'), True)
        self.assertEqual(filter_func('.Hallo', True, ''), False)
        self.assertEqual(filter_func('.Hallo', True, ','), False)

if __name__ == '__main__':
    unittest.main()
