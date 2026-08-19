#!/usr/bin/env node
// package_skill.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/package_skill.py
// auch in: OpenClaw@gateway2:skills/skill-creator/scripts/package_skill.py
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

/**
 * Skill Packager - Creates a distributable .skill file of a skill folder
 *
 * Usage:
 *     node utils/package_skill.js <path/to/skill-folder> [output-directory]
 *
 * Example:
 *     node utils/package_skill.js skills/public/my-skill
 *     node utils/package_skill.js skills/public/my-skill ./dist
 */

const fs = require('fs');
const path = require('path');
const { program } = require('commander');
const AdmZip = require('adm-zip');
const { validateSkill } = require('./quick_validate');

function isWithin(filePath, rootPath) {
    const relative = path.relative(rootPath, filePath);
    return !relative.startsWith('..') && !path.isAbsolute(relative);
}

function packageSkill(skillPath, outputDir = null) {
    // Resolve paths
    skillPath = path.resolve(skillPath);

    // Validate skill folder exists
    if (!fs.existsSync(skillPath)) {
        console.error(`[ERROR] Skill folder not found: ${skillPath}`);
        return null;
    }

    if (!fs.statSync(skillPath).isDirectory()) {
        console.error(`[ERROR] Path is not a directory: ${skillPath}`);
        return null;
    }

    // Validate SKILL.md exists
    const skillMd = path.join(skillPath, 'SKILL.md');
    if (!fs.existsSync(skillMd)) {
        console.error(`[ERROR] SKILL.md not found in ${skillPath}`);
        return null;
    }

    // Run validation before packaging
    console.log('Validating skill...');
    const validationResult = validateSkill(skillPath);
    if (!validationResult.valid) {
        console.error(`[ERROR] Validation failed: ${validationResult.message}`);
        console.error('   Please fix the validation errors before packaging.');
        return null;
    }
    console.log(`[OK] ${validationResult.message}\n`);

    // Determine output location
    const skillName = path.basename(skillPath);
    let outputPath;
    if (outputDir) {
        outputPath = path.resolve(outputDir);
        fs.mkdirSync(outputPath, { recursive: true });
    } else {
        outputPath = process.cwd();
    }

    const skillFilename = path.join(outputPath, `${skillName}.skill`);

    const EXCLUDED_DIRS = new Set(['.git', '.svn', '.hg', '__pycache__', 'node_modules']);

    // Create the .skill file (zip format)
    try {
        const zip = new AdmZip();

        // Walk through the skill directory
        function walkDirectory(currentPath) {
            const items = fs.readdirSync(currentPath, { withFileTypes: true });
            
            for (const item of items) {
                const itemPath = path.join(currentPath, item.name);
                
                // Security: never follow or package symlinks.
                if (fs.lstatSync(itemPath).isSymbolicLink()) {
                    console.warn(`[WARN] Skipping symlink: ${itemPath}`);
                    continue;
                }

                const relativeParts = path.relative(skillPath, itemPath).split(path.sep);
                if (relativeParts.some(part => EXCLUDED_DIRS.has(part))) {
                    continue;
                }

                if (item.isDirectory()) {
                    walkDirectory(itemPath);
                } else if (item.isFile()) {
                    const resolvedFile = path.resolve(itemPath);
                    if (!isWithin(resolvedFile, skillPath)) {
                        console.error(`[ERROR] File escapes skill root: ${itemPath}`);
                        return null;
                    }
                    
                    // If output lives under skillPath, avoid writing archive into itself.
                    if (path.resolve(resolvedFile) === path.resolve(skillFilename)) {
                        console.warn(`[WARN] Skipping output archive: ${itemPath}`);
                        continue;
                    }

                    // Calculate the relative path within the zip.
                    const arcname = path.join(skillName, path.relative(skillPath, itemPath));
                    zip.addLocalFile(itemPath, path.dirname(arcname));
                    console.log(`  Added: ${arcname}`);
                }
            }
        }

        walkDirectory(skillPath);
        zip.writeZip(skillFilename);

        console.log(`\n[OK] Successfully packaged skill to: ${skillFilename}`);
        return skillFilename;

    } catch (e) {
        console.error(`[ERROR] Error creating .skill file: ${e.message}`);
        return null;
    }
}

function main() {
    program
        .arguments('<skill-path> [output-directory]')
        .action((skillPath, outputDir) => {
            console.log(`Packaging skill: ${skillPath}`);
            if (outputDir) {
                console.log(`   Output directory: ${outputDir}`);
            }
            console.log();

            const result = packageSkill(skillPath, outputDir);

            if (result) {
                process.exit(0);
            } else {
                process.exit(1);
            }
        });

    if (process.argv.length < 3) {
        console.log('Usage: node utils/package_skill.js <path/to/skill-folder> [output-directory]');
        console.log('\nExample:');
        console.log('  node utils/package_skill.js skills/public/my-skill');
        console.log('  node utils/package_skill.js skills/public/my-skill ./dist');
        process.exit(1);
    }

    program.parse(process.argv);
}

if (require.main === module) {
    main();
}

module.exports = { packageSkill };
