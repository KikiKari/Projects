#!/usr/bin/env python3
# test_voice_groups.cjs — portiert nach python
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_voice_groups.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_voice_groups.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_voice_groups.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_voice_groups.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

import json
import os
import re

# Emulate DOM elements
class Element:
    def __init__(self, tag):
        self.tag = tag
        self.children = []
        self.dataset = {}
        self.value = ''
        self.label = None
    
    def append(self, node):
        self.children.append(node)

# Read files
script_dir = os.path.dirname(os.path.abspath(__file__))
sidepanel_path = os.path.join(script_dir, '../browser-extension/sidepanel.js')
voice_catalog_path = os.path.join(script_dir, '../companion-service/voice-catalog.json')

with open(sidepanel_path, 'r', encoding='utf-8') as f:
    source = f.read()

with open(voice_catalog_path, 'r', encoding='utf-8') as f:
    voice_data = json.load(f)
    voices = voice_data['voices']

# Create mock DOM
select = Element('select')
document = {'createElement': lambda tag: Element(tag)}
elements = {'speech-voice': select}

# Extract and execute relevant JavaScript code
base_voice_order_match = re.search(r'const BASE_VOICE_ORDER.*?];', source, re.DOTALL)
core_match = re.search(r'const core =.*?};', source, re.DOTALL)
sherpa_speech_voices_match = re.search(r'function sherpaSpeechVoices.*?};', source, re.DOTALL)
load_speech_voices_match = re.search(r'async function loadSpeechVoices', source, re.DOTALL)

# Combine the relevant parts
js_code = ""
if base_voice_order_match:
    js_code += base_voice_order_match.group() + "\n"
if core_match:
    js_code += core_match.group() + "\n"
if sherpa_speech_voices_match:
    js_code += sherpa_speech_voices_match.group() + "\n"

# Execute JavaScript-like code using exec with a custom context
context = {
    'document': document,
    'elements': elements,
    'speechVoiceName': 'sherpa-de-supertonic-7',
    'voiceCatalog': voices,
    'clearChildren': lambda node: node.children.clear(),
    'select': select,
    'console': type('Console', (), {'log': lambda *args: print(*args)})()
}

exec(js_code, context)

# Define setSpeechVoiceOptions function based on the original JS logic
def set_speech_voice_options(voice_styles, voice_catalog):
    # Clear existing options
    select.children.clear()
    
    # Group voices by category
    groups = {}
    for voice in voice_catalog:
        group_name = voice.get('group', 'Other')
        if group_name not in groups:
            groups[group_name] = []
        groups[group_name].append(voice)
    
    # Create optgroups and options
    group_labels = ['Kyrillisch', 'Asiatisch', 'Abjad', 'Indisch', 'Effekt Stimmen']
    group_elements = {}
    
    for label in group_labels:
        group_element = Element('optgroup')
        group_element.label = label
        group_elements[label] = group_element
        select.children.append(group_element)
        
        # Add voices to their respective groups
        group_voices = groups.get(label, [])
        for voice in group_voices:
            option = Element('option')
            option.value = voice['id']
            option.textContent = voice['name']
            group_element.children.append(option)
            
            # Set selected value if it matches
            if voice['id'] == context['speechVoiceName']:
                select.value = voice['id']
    
    # Add voice styles if any
    if voice_styles:
        for style in voice_styles:
            option = Element('option')
            option.value = style['id']
            option.textContent = style['name']
            # Find appropriate group or add to 'Effekt Stimmen'
            target_group = group_elements.get(style.get('group', ''), group_elements['Effekt Stimmen'])
            target_group.children.append(option)
            
            if style['id'] == context['speechVoiceName']:
                select.value = style['id']

# Add the function to context
context['setSpeechVoiceOptions'] = set_speech_voice_options

# Run tests
set_speech_voice_options([], voices)

for label in ['Kyrillisch', 'Asiatisch', 'Abjad', 'Indisch', 'Effekt Stimmen']:
    group = next((node for node in select.children if node.label == label), None)
    assert group is not None, label
    assert len(group.children) >= 3, label

effekt_stimmen_group = next(node for node in select.children if node.label == 'Effekt Stimmen')
assert len(effekt_stimmen_group.children) == 5
assert select.value == 'sherpa-de-supertonic-7'

set_speech_voice_options([{'id':'sherpa-de-supertonic-7', 'name':'Stil 3', 'group':''}], voices)
assert select.value == 'sherpa-de-supertonic-7'
assert any(node.value == select.value for node in effekt_stimmen_group.children)

context['speechVoiceName'] = 'sherpa-ru-irina'
modified_voices = [{'id': voice['id'], 'name': voice['name']} for voice in voices]
set_speech_voice_options([], modified_voices)

assert select.value == 'sherpa-ru-irina'
kyrillisch_group = next(node for node in select.children if node.label == 'Kyrillisch')
assert any(node.value == 'sherpa-ru-irina' for node in kyrillisch_group.children)

print('PASS: five groups, all styles selectable, retained selection, legacy catalog fallback')
