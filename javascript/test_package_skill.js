#!/usr/bin/env node
// test_package_skill.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/test_package_skill.py
// auch in: OpenClaw@gateway2:skills/skill-creator/scripts/test_package_skill.py
// Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

/**
 * Regression tests for skill packaging security behavior.
 */

const fs = require('fs');
const os = require('os');
const path = require('path');
const { execSync } = require('child_process');
const { describe, it, beforeEach, afterEach } = require('node:test');
const assert = require('assert');
const { createReadStream, createWriteStream } = require('fs');
const { promisify } = require('util');
const { pipeline } = require('stream/promises');

const pipelineAsync = promisify(pipeline);

// Mock quick_validate module
const fakeQuickValidate = {
  validate_skill: (_path) => [true, "Skill is valid!"]
};

// Save original module if exists
const originalQuickValidate = require.cache[require.resolve('./quick_validate')] || null;

// Replace or add mock to cache
require.cache[require.resolve('./quick_validate')] = {
  exports: fakeQuickValidate
};

const packageSkillModule = require('./package_skill');
const { package_skill } = packageSkillModule;

// Restore original module if existed
if (originalQuickValidate) {
  require.cache[require.resolve('./quick_validate')] = originalQuickValidate;
} else {
  delete require.cache[require.resolve('./quick_validate')];
}

class TestPackageSkillSecurity {
  constructor() {
    this.tempDir = '';
  }

  setUp() {
    this.tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'test_skill_'));
  }

  tearDown() {
    if (fs.existsSync(this.tempDir)) {
      fs.rmSync(this.tempDir, { recursive: true });
    }
  }

  createSkill(name = "test-skill") {
    const skillDir = path.join(this.tempDir, name);
    fs.mkdirSync(skillDir, { recursive: true });
    fs.writeFileSync(
      path.join(skillDir, "SKILL.md"),
      "---\nname: test-skill\ndescription: test\n---\n"
    );
    fs.writeFileSync(
      path.join(skillDir, "script.py"),
      "print('ok')\n"
    );
    return skillDir;
  }

  async testPackagesNormalFiles() {
    const skillDir = this.createSkill("normal-skill");
    const outDir = path.join(this.tempDir, "out");
    fs.mkdirSync(outDir);

    const result = package_skill(skillDir, outDir);

    assert.notStrictEqual(result, null);
    const skillFile = path.join(outDir, "normal-skill.skill");
    assert.strictEqual(fs.existsSync(skillFile), true);
    
    // Extract and check contents
    const AdmZip = require('adm-zip');
    const zip = new AdmZip(skillFile);
    const entries = zip.getEntries();
    const names = new Set(entries.map(entry => entry.entryName));
    
    assert.strictEqual(names.has("normal-skill/SKILL.md"), true);
    assert.strictEqual(names.has("normal-skill/script.py"), true);
  }

  async testSkipsSymlinkToExternalFile() {
    const skillDir = this.createSkill("symlink-file-skill");
    const outside = path.join(this.tempDir, "outside-secret.txt");
    fs.writeFileSync(outside, "super-secret\n");
    const link = path.join(skillDir, "loot.txt");
    const outDir = path.join(this.tempDir, "out");
    fs.mkdirSync(outDir);

    try {
      fs.symlinkSync(outside, link);
    } catch (error) {
      if (error.code === 'EPERM' || error.code === 'EACCES' || process.platform === 'win32') {
        console.log("Skipping symlink test - not supported on this platform");
        return;
      }
      throw error;
    }

    const result = package_skill(skillDir, outDir);
    assert.notStrictEqual(result, null);
    const skillFile = path.join(outDir, "symlink-file-skill.skill");
    assert.strictEqual(fs.existsSync(skillFile), true);
    
    // Extract and check contents
    const AdmZip = require('adm-zip');
    const zip = new AdmZip(skillFile);
    const entries = zip.getEntries();
    const names = new Set(entries.map(entry => entry.entryName));
    
    assert.strictEqual(names.has("symlink-file-skill/SKILL.md"), true);
    assert.strictEqual(names.has("symlink-file-skill/script.py"), true);
    assert.strictEqual(names.has("symlink-file-skill/loot.txt"), false);
  }

  async testSkipsSymlinkDirectory() {
    const skillDir = this.createSkill("symlink-dir-skill");
    const outsideDir = path.join(this.tempDir, "outside");
    fs.mkdirSync(outsideDir);
    fs.writeFileSync(path.join(outsideDir, "secret.txt"), "secret\n");
    const link = path.join(skillDir, "docs");
    const outDir = path.join(this.tempDir, "out");
    fs.mkdirSync(outDir);

    try {
      fs.symlinkSync(outsideDir, link, 'dir');
    } catch (error) {
      if (error.code === 'EPERM' || error.code === 'EACCES' || process.platform === 'win32') {
        console.log("Skipping symlink directory test - not supported on this platform");
        return;
      }
      throw error;
    }

    const result = package_skill(skillDir, outDir);
    assert.notStrictEqual(result, null);
    const skillFile = path.join(outDir, "symlink-dir-skill.skill");
    
    // Extract and check contents
    const AdmZip = require('adm-zip');
    const zip = new AdmZip(skillFile);
    const entries = zip.getEntries();
    const names = new Set(entries.map(entry => entry.entryName));
    
    assert.strictEqual(names.has("symlink-dir-skill/SKILL.md"), true);
    assert.strictEqual(names.has("symlink-dir-skill/script.py"), true);
    assert.strictEqual(names.has("symlink-dir-skill/docs/secret.txt"), false);
  }

  async testRejectsResolvedPathOutsideSkillRoot() {
    const skillDir = this.createSkill("escape-skill");
    const outDir = path.join(this.tempDir, "out");
    fs.mkdirSync(outDir);

    // Save original function
    const originalWithin = packageSkillModule._is_within;

    // Create a mock version of _is_within
    packageSkillModule._is_within = function(pathObj, root) {
      if (path.basename(pathObj) === "script.py") {
        return false;
      }
      return originalWithin(pathObj, root);
    };

    const result = package_skill(skillDir, outDir);

    // Restore original function
    packageSkillModule._is_within = originalWithin;

    assert.strictEqual(result, null);
  }

  async testAllowsNestedRegularFiles() {
    const skillDir = this.createSkill("nested-skill");
    const nested = path.join(skillDir, "lib", "helpers");
    fs.mkdirSync(nested, { recursive: true });
    fs.writeFileSync(
      path.join(nested, "util.py"),
      "def run():\n    return 1\n"
    );
    const outDir = path.join(this.tempDir, "out");
    fs.mkdirSync(outDir);

    const result = package_skill(skillDir, outDir);

    assert.notStrictEqual(result, null);
    const skillFile = path.join(outDir, "nested-skill.skill");
    
    // Extract and check contents
    const AdmZip = require('adm-zip');
    const zip = new AdmZip(skillFile);
    const entries = zip.getEntries();
    const names = new Set(entries.map(entry => entry.entryName));
    
    assert.strictEqual(names.has("nested-skill/lib/helpers/util.py"), true);
  }

  async testSkipsOutputArchiveWhenOutputDirIsSkillDir() {
    const skillDir = this.createSkill("self-output-skill");

    const result = package_skill(skillDir, skillDir);

    assert.notStrictEqual(result, null);
    const skillFile = path.join(skillDir, "self-output-skill.skill");
    assert.strictEqual(fs.existsSync(skillFile), true);
    
    // Extract and check contents
    const AdmZip = require('adm-zip');
    const zip = new AdmZip(skillFile);
    const entries = zip.getEntries();
    const names = new Set(entries.map(entry => entry.entryName));
    
    assert.strictEqual(names.has("self-output-skill/SKILL.md"), true);
    assert.strictEqual(names.has("self-output-skill/script.py"), true);
    assert.strictEqual(names.has("self-output-skill/self-output-skill.skill"), false);
  }
}

// Run tests
async function runTests() {
  const tester = new TestPackageSkillSecurity();
  
  console.log("Running testPackagesNormalFiles...");
  tester.setUp();
  await tester.testPackagesNormalFiles();
  tester.tearDown();
  
  console.log("Running testSkipsSymlinkToExternalFile...");
  tester.setUp();
  await tester.testSkipsSymlinkToExternalFile();
  tester.tearDown();
  
  console.log("Running testSkipsSymlinkDirectory...");
  tester.setUp();
  await tester.testSkipsSymlinkDirectory();
  tester.tearDown();
  
  console.log("Running testRejectsResolvedPathOutsideSkillRoot...");
  tester.setUp();
  await tester.testRejectsResolvedPathOutsideSkillRoot();
  tester.tearDown();
  
  console.log("Running testAllowsNestedRegularFiles...");
  tester.setUp();
  await tester.testAllowsNestedRegularFiles();
  tester.tearDown();
  
  console.log("Running testSkipsOutputArchiveWhenOutputDirIsSkillDir...");
  tester.setUp();
  await tester.testSkipsOutputArchiveWhenOutputDirIsSkillDir();
  tester.tearDown();
  
  console.log("All tests passed!");
}

runTests().catch(error => {
  console.error("Test failed:", error);
  process.exit(1);
});
