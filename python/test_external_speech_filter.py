#!/usr/bin/env python3
# test_external_speech_filter.cjs — portiert nach python
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_external_speech_filter.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

import unittest
from browser_extension.content_core import shouldFilterExternalSpeechTrigger as filter

class TestExternalSpeechFilter(unittest.TestCase):
    def test_filter_combinations(self):
        """Test all combinations of enabled flag and text inputs"""
        test_cases = [
            (False, '.Text'),
            (False, '. Text'),
            (False, '  .Text'),
            (False, '\t\n. Text'),
            (False, 'Normal'),
            (False, 'Ein Satz. Noch einer'),
            (False, ''),
            (True, '.Text'),
            (True, '. Text'),
            (True, '  .Text'),
            (True, '\t\n. Text'),
            (True, 'Normal'),
            (True, 'Ein Satz. Noch einer'),
            (True, '')
        ]
        
        for enabled, text in test_cases:
            with self.subTest(enabled=enabled, text=text):
                expected = enabled and text.lstrip().startswith('.')
                self.assertEqual(filter(text, enabled), expected)

if __name__ == '__main__':
    unittest.main()
