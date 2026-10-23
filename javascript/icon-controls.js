#!/usr/bin/env node
// icon-controls.css — portiert nach javascript
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/icon-controls.css
// Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Helper function to generate CSS rules for icon styles
function generateIconStyleRules(styleName) {
  const icons = [
    'auto-chat-refresh-counter',
    'browser',
    'captions',
    'chat-counter',
    'fullscreen',
    'mute',
    'off',
    'on',
    'pip',
    'play',
    'player',
    'protection-slider',
    'recommendation-counter',
    'report',
    'reset',
    'settings',
    'status',
    'stop',
    'unmute',
    'volume-slider'
  ];

  const rules = [];
  rules.push(`html[data-icon-style="${styleName}"] {`);
  
  for (const icon of icons) {
    rules.push(`  --icon-${icon}:url("icons/${styleName}/${icon}.png");`);
  }
  
  rules.push('}');
  return rules.join('\n');
}

// Generate the complete CSS content
function generateCSS() {
  const sections = [];
  
  // Add icon style definitions
  sections.push(generateIconStyleRules('plastisch'));
  sections.push(generateIconStyleRules('glass'));
  sections.push(generateIconStyleRules('linear'));
  
  // Add general control styles
  sections.push(`
button[data-control-icon]::before,
.control-icon::before {
  content: "";
  display: inline-block;
  width: 32px;
  height: 32px;
  flex: 0 0 32px;
  background: var(--control-icon) center/contain no-repeat;
  vertical-align: middle;
  margin-inline-end: 0;
  pointer-events: none;
}`);

  sections.push(`
button[data-control-icon] {
  min-height: 44px;
  min-width: 44px;
  font-size: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}`);

  sections.push(`
button[data-control-icon][hidden] {
  display: none;
}`);

  sections.push(`
input[type="checkbox"] {
  appearance: none;
  -webkit-appearance: none;
  width: 44px;
  height: 44px;
  min-width: 44px;
  border: 0;
  background: var(--icon-off) center/40px no-repeat;
  cursor: pointer;
  vertical-align: middle;
}`);

  sections.push(`
input[type="checkbox"]:checked {
  background-image: var(--icon-on);
}`);

  sections.push(`
input[type="checkbox"]:focus-visible,
button[data-control-icon]:focus-visible {
  outline: 2px solid #1769df;
  outline-offset: 2px;
}`);

  sections.push(`
input[type="checkbox"]:disabled {
  opacity: .45;
  cursor: default;
}`);

  sections.push(`
.control-icon {
  display: inline-flex;
  align-items: center;
}`);

  sections.push(`
input[type="range"] {
  min-height: 32px;
}`);

  sections.push(`
.icon-style-setting {
  display: flex;
  align-items: center;
  gap: 8px;
}`);

  // Add individual icon control definitions
  const controlIcons = [
    'auto-chat-refresh-counter',
    'browser',
    'captions',
    'chat-counter',
    'fullscreen',
    'mute',
    'off',
    'on',
    'pip',
    'play',
    'player',
    'protection-slider',
    'recommendation-counter',
    'report',
    'reset',
    'settings',
    'status',
    'stop',
    'unmute',
    'volume-slider'
  ];

  const iconRules = controlIcons.map(icon => 
    `[data-control-icon="${icon}"] { --control-icon:var(--icon-${icon}); }`
  ).join('\n');
  
  sections.push(iconRules);
  
  return sections.join('\n\n');
}

// Main execution
function main() {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    console.log(generateCSS());
  } else {
    const outputPath = args[0];
    const cssContent = generateCSS();
    writeFileSync(outputPath, cssContent);
  }
}

main();
