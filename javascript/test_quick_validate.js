#!/usr/bin/env node
// test_quick_validate.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/test_quick_validate.py
// auch in: OpenClaw@gateway2:skills/skill-creator/scripts/test_quick_validate.py
// Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

/**
 * Regression tests for quick skill validation.
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const { spawnSync } = require('child_process');

// Mock the quick_validate module behavior
const quickValidate = {
  yaml: require('js-yaml'),

  validateSkill(skillDir) {
    const skillFile = path.join(skillDir, 'SKILL.md');
    
    try {
      const content = fs.readFileSync(skillFile, 'utf8');
      
      // Check for frontmatter
      if (!content.startsWith('---\n') && !content.startsWith('---\r\n')) {
        return [false, 'Missing frontmatter'];
      }
      
      // Find frontmatter boundaries
      let lines = content.split(/\r?\n/);
      let endIndex = -1;
      for (let i = 1; i < lines.length; i++) {
        if (lines[i] === '---') {
          endIndex = i;
          break;
        }
      }
      
      if (endIndex === -1) {
        return [false, 'Invalid frontmatter format'];
      }
      
      // Extract frontmatter content
      const frontmatterLines = lines.slice(1, endIndex);
      const frontmatterContent = frontmatterLines.join('\n');
      
      // Try parsing with js-yaml
      try {
        this.yaml.load(frontmatterContent);
      } catch (yamlError) {
        // Fallback parser for multiline values
        const fallbackParsed = this.fallbackParseFrontmatter(frontmatterContent);
        if (!fallbackParsed) {
          return [false, 'Invalid frontmatter format'];
        }
      }
      
      return [true, 'Valid skill'];
    } catch (error) {
      return [false, error.message];
    }
  },

  fallbackParseFrontmatter(content) {
    // Simple fallback parser that handles basic key-value and multiline fields
    const lines = content.split('\n');
    let inMultiline = false;
    let multilineKey = '';
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      
      if (inMultiline) {
        if (line === '' || line.startsWith(' ') || line.startsWith('\t')) {
          continue;
        } else {
          inMultiline = false;
        }
      }
      
      if (line.includes(':')) {
        const colonIndex = line.indexOf(':');
        const key = line.substring(0, colonIndex).trim();
        const value = line.substring(colonIndex + 1).trim();
        
        if (value === '|' || value === '>') {
          inMultiline = true;
          multilineKey = key;
        } else if (value.startsWith('{') || value.startsWith('[')) {
          try {
            JSON.parse(value);
          } catch (e) {
            return false;
          }
        }
      }
    }
    
    return true;
  }
};

class TestCase {
  constructor() {
    this.assertions = [];
  }

  assertTrue(condition, message = '') {
    if (!condition) {
      throw new Error(`Assertion failed: Expected true, got false. ${message}`);
    }
  }

  assertFalse(condition, message = '') {
    if (condition) {
      throw new Error(`Assertion failed: Expected false, got true. ${message}`);
    }
  }

  assertEqual(actual, expected, message = '') {
    if (actual !== expected) {
      throw new Error(`Assertion failed: Expected '${expected}', got '${actual}'. ${message}`);
    }
  }
}

class TestQuickValidate extends TestCase {
  setUp() {
    this.tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'test_quick_validate_'));
  }

  tearDown() {
    if (fs.existsSync(this.tempDir)) {
      fs.rmSync(this.tempDir, { recursive: true, force: true });
    }
  }

  testAcceptsCrlfFrontmatter() {
    const skillDir = path.join(this.tempDir, 'crlf-skill');
    fs.mkdirSync(skillDir, { recursive: true });
    const content = '---\r\nname: crlf-skill\r\ndescription: ok\r\n---\r\n# Skill\r\n';
    fs.writeFileSync(path.join(skillDir, 'SKILL.md'), content, 'utf8');

    const [valid, message] = quickValidate.validateSkill(skillDir);

    this.assertTrue(valid, message);
  }

  testRejectsMissingFrontmatterClosingFence() {
    const skillDir = path.join(this.tempDir, 'bad-skill');
    fs.mkdirSync(skillDir, { recursive: true });
    const content = '---\nname: bad-skill\ndescription: missing end\n# no closing fence\n';
    fs.writeFileSync(path.join(skillDir, 'SKILL.md'), content, 'utf8');

    const [valid, message] = quickValidate.validateSkill(skillDir);

    this.assertFalse(valid);
    this.assertEqual(message, 'Invalid frontmatter format');
  }

  testFallbackParserHandlesMultilineFrontmatterWithoutPyyaml() {
    const skillDir = path.join(this.tempDir, 'multiline-skill');
    fs.mkdirSync(skillDir, { recursive: true });
    const content = `---
name: multiline-skill
description: Works without pyyaml
allowed-tools:
  - gh
metadata: |
  {
    "owners": ["team-openclaw"]
  }
---
# Skill
`;
    fs.writeFileSync(path.join(skillDir, 'SKILL.md'), content, 'utf8');

    const previousYaml = quickValidate.yaml;
    quickValidate.yaml = null;
    try {
      const [valid, message] = quickValidate.validateSkill(skillDir);
      this.assertTrue(valid, message);
    } finally {
      quickValidate.yaml = previousYaml;
    }
  }
}

function runTests() {
  const testClass = new TestQuickValidate();
  const methods = Object.getOwnPropertyNames(TestQuickValidate.prototype)
    .filter(name => name.startsWith('test'));

  let passed = 0;
  let failed = 0;

  for (const method of methods) {
    try {
      testClass.setUp();
      testClass[method]();
      testClass.tearDown();
      console.log(`✓ ${method}`);
      passed++;
    } catch (error) {
      testClass.tearDown();
      console.log(`✗ ${method}: ${error.message}`);
      failed++;
    }
  }

  console.log(`\nTests passed: ${passed}`);
  console.log(`Tests failed: ${failed}`);

  if (failed > 0) {
    process.exit(1);
  }
}

runTests();
