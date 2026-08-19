#!/usr/bin/env node
// quick_validate.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/quick_validate.py
// auch in: OpenClaw@gateway2:skills/skill-creator/scripts/quick_validate.py
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

/**
 * Quick validation script for skills - minimal version
 */

const fs = require('fs');
const path = require('path');

const MAX_SKILL_NAME_LENGTH = 64;

function _extractFrontmatter(content) {
    const lines = content.split('\n');
    if (lines.length === 0 || lines[0].trim() !== '---') {
        return null;
    }
    for (let i = 1; i < lines.length; i++) {
        if (lines[i].trim() === '---') {
            return lines.slice(1, i).join('\n');
        }
    }
    return null;
}

function _parseSimpleFrontmatter(frontmatterText) {
    /**
     * Minimal fallback parser used when PyYAML is unavailable.
     * Supports simple `key: value` mappings used by SKILL.md frontmatter.
     */
    const parsed = {};
    let currentKey = null;
    const lines = frontmatterText.split('\n');
    
    for (const rawLine of lines) {
        const stripped = rawLine.trim();
        if (!stripped || stripped.startsWith('#')) {
            continue;
        }

        const isIndented = rawLine.startsWith(' ') || rawLine.startsWith('\t');
        if (isIndented) {
            if (currentKey === null) {
                return null;
            }
            const currentValue = parsed[currentKey];
            parsed[currentKey] = currentValue ? `${currentValue}\n${stripped}` : stripped;
            continue;
        }

        if (!stripped.includes(':')) {
            return null;
        }
        
        const parts = stripped.split(':', 2);
        let key = parts[0].trim();
        let value = parts[1] ? parts[1].trim() : '';
        
        if (!key) {
            return null;
        }
        
        if ((value.startsWith('"') && value.endsWith('"')) || 
            (value.startsWith("'") && value.endsWith("'"))) {
            value = value.substring(1, value.length - 1);
        }
        
        parsed[key] = value;
        currentKey = key;
    }
    return parsed;
}

function validateSkill(skillPath) {
    /** Basic validation of a skill */
    const skillMdPath = path.join(skillPath, 'SKILL.md');
    
    if (!fs.existsSync(skillMdPath)) {
        return [false, 'SKILL.md not found'];
    }

    let content;
    try {
        content = fs.readFileSync(skillMdPath, 'utf8');
    } catch (e) {
        return [false, `Could not read SKILL.md: ${e.message}`];
    }

    const frontmatterText = _extractFrontmatter(content);
    if (frontmatterText === null) {
        return [false, 'Invalid frontmatter format'];
    }
    
    let frontmatter;
    try {
        frontmatter = _parseSimpleFrontmatter(frontmatterText);
        if (frontmatter === null) {
            return [false, 'Invalid YAML in frontmatter: unsupported syntax'];
        }
    } catch (e) {
        return [false, `Invalid YAML in frontmatter: ${e.message}`];
    }

    const allowedProperties = new Set(['name', 'description', 'license', 'allowed-tools', 'metadata']);

    const unexpectedKeys = Object.keys(frontmatter).filter(key => !allowedProperties.has(key));
    if (unexpectedKeys.length > 0) {
        const allowed = Array.from(allowedProperties).sort().join(', ');
        const unexpected = unexpectedKeys.sort().join(', ');
        return [false, `Unexpected key(s) in SKILL.md frontmatter: ${unexpected}. Allowed properties are: ${allowed}`];
    }

    if (!('name' in frontmatter)) {
        return [false, "Missing 'name' in frontmatter"];
    }
    if (!('description' in frontmatter)) {
        return [false, "Missing 'description' in frontmatter"];
    }

    let name = frontmatter.name || '';
    if (typeof name !== 'string') {
        return [false, `Name must be a string, got ${typeof name}`];
    }
    name = name.trim();
    if (name) {
        if (!/^[a-z0-9-]+$/.test(name)) {
            return [false, `Name '${name}' should be hyphen-case (lowercase letters, digits, and hyphens only)`];
        }
        if (name.startsWith('-') || name.endsWith('-') || name.includes('--')) {
            return [false, `Name '${name}' cannot start/end with hyphen or contain consecutive hyphens`];
        }
        if (name.length > MAX_SKILL_NAME_LENGTH) {
            return [false, `Name is too long (${name.length} characters). Maximum is ${MAX_SKILL_NAME_LENGTH} characters.`];
        }
    }

    let description = frontmatter.description || '';
    if (typeof description !== 'string') {
        return [false, `Description must be a string, got ${typeof description}`];
    }
    description = description.trim();
    if (description) {
        if (description.includes('<') || description.includes('>')) {
            return [false, 'Description cannot contain angle brackets (< or >)'];
        }
        if (description.length > 1024) {
            return [false, `Description is too long (${description.length} characters). Maximum is 1024 characters.`];
        }
    }

    return [true, 'Skill is valid!'];
}

if (require.main === module) {
    if (process.argv.length !== 3) {
        console.log('Usage: node quick_validate.js <skill_directory>');
        process.exit(1);
    }

    const [valid, message] = validateSkill(process.argv[2]);
    console.log(message);
    process.exit(valid ? 0 : 1);
}
