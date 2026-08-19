#!/usr/bin/env node
// styles.css — portiert nach javascript
// Quelle: css, Projects@TikTok-Live-Companion:site/src/styles.css
// auch in: Projects@TikTok-Live-Companion-Android:site/src/styles.css
// auch in: Projects@TikTok-Live-Companion-iOS:site/src/styles.css
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Get __dirname equivalent in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Function to generate CSS content
function generateCSS() {
  // Define CSS variables as an object for easy management
  const rootVars = {
    '--font-family': 'Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
    '--color': '#16233d',
    '--background': '#fffdf9',
    '--font-synthesis': 'none',
    '--text-rendering': 'optimizeLegibility',
    '--ink': '#16233d',
    '--muted': '#60708b',
    '--paper': '#fffdf9',
    '--panel': '#ffffff',
    '--wash': '#eefaff',
    '--line': '#d9e2ec',
    '--coral': '#f15a58',
    '--coral-dark': '#c84245',
    '--cyan': '#10b6d4',
    '--cyan-dark': '#087e99',
    '--navy': '#14223c',
    '--shadow': '0 22px 55px rgba(23, 54, 83, .14)'
  };

  // Helper function to convert variable object to CSS variable string
  function varsToString(vars) {
    return Object.entries(vars)
      .map(([key, value]) => `  ${key}: ${value};`)
      .join('\n');
  }

  // Build the CSS content
  let cssContent = `:root {\n${varsToString(rootVars)}\n}\n\n`;

  // Add base styles
  cssContent += `* { box-sizing: border-box; }\n`;
  cssContent += `html { scroll-behavior: smooth; max-width: 100%; overflow-x: hidden; }\n`;
  cssContent += `body { margin: 0; min-width: 320px; min-height: 100vh; max-width: 100%; overflow-x: hidden; background: var(--paper); }\n`;
  cssContent += `a { color: inherit; }\n`;
  cssContent += `button, input { font: inherit; }\n`;
  cssContent += `button, a { -webkit-tap-highlight-color: transparent; }\n`;
  cssContent += `button:focus-visible, a:focus-visible, input:focus-visible, summary:focus-visible { outline: 3px solid #0a7f9d; outline-offset: 3px; }\n`;
  cssContent += `.page-width { width: min(1180px, calc(100% - 40px)); margin-inline: auto; }\n`;
  cssContent += `.icon { width: 20px; height: 20px; flex: 0 0 auto; }\n\n`;

  // Skip link styles
  cssContent += `.skip-link { position: fixed; z-index: 100; top: 12px; left: 12px; padding: 10px 16px; border-radius: 8px; background: var(--navy); color: white; transform: translateY(-160%); }\n`;
  cssContent += `.skip-link:focus { transform: translateY(0); }\n\n`;

  // Site header styles
  cssContent += `.site-header { min-height: 74px; display: flex; align-items: center; gap: 30px; padding: 12px max(24px, calc((100vw - 1240px) / 2)); border-bottom: 1px solid rgba(217, 226, 236, .8); background: rgba(255, 253, 249, .95); position: sticky; top: 0; z-index: 50; backdrop-filter: blur(12px); }\n`;
  cssContent += `.brand { display: inline-flex; align-items: center; gap: 10px; text-decoration: none; font-weight: 800; white-space: nowrap; letter-spacing: -.02em; }\n`;
  cssContent += `.brand b { color: var(--coral-dark); }\n`;
  cssContent += `.brand-mark { width: 28px; height: 28px; display: block; object-fit: contain; flex: 0 0 auto; }\n`;
  cssContent += `.site-header nav { display: flex; align-items: center; gap: 24px; margin-inline: auto; }\n`;
  cssContent += `.site-header nav a { text-decoration: none; font-size: .9rem; font-weight: 650; color: #42516b; padding: 11px 0; border-bottom: 2px solid transparent; }\n`;
  cssContent += `.site-header nav a:hover, .site-header nav a.active { color: var(--ink); border-bottom-color: var(--coral); }\n`;
  cssContent += `.header-tools { display: flex; align-items: center; gap: 16px; }\n`;
  cssContent += `.search-button { border: 1px solid var(--line); border-radius: 10px; background: white; color: #526078; padding: 8px 10px; display: inline-flex; align-items: center; gap: 8px; cursor: pointer; }\n`;
  cssContent += `.search-button kbd { color: #758198; background: #f2f5f8; border-radius: 5px; padding: 2px 5px; font-size: .7rem; }\n`;
  cssContent += `.language-switch { text-decoration: none; font-size: .82rem; font-weight: 800; }\n`;
  cssContent += `.language-switch span { color: #a9b2bf; margin-inline: 4px; }\n\n`;

  // Hero section styles
  cssContent += `.hero { min-height: 600px; display: grid; grid-template-columns: .9fr 1.1fr; gap: 54px; align-items: center; padding-block: 78px 64px; }\n`;
  cssContent += `.hero h1, .content-page > h1 { margin: 0; font-size: clamp(2.35rem, 5vw, 4.4rem); line-height: 1.04; letter-spacing: -.055em; max-width: 780px; }\n`;
  cssContent += `.hero-copy > p { max-width: 590px; color: var(--muted); font-size: 1.14rem; line-height: 1.75; }\n`;
  cssContent += `.hero-actions { display: flex; flex-wrap: wrap; gap: 12px; margin-block: 28px 20px; }\n`;
  cssContent += `.button { min-height: 48px; display: inline-flex; align-items: center; justify-content: center; gap: 9px; padding: 12px 19px; border-radius: 10px; text-decoration: none; border: 1px solid transparent; font-weight: 800; transition: transform .18s ease, background .18s ease; }\n`;
  cssContent += `.button:hover { transform: translateY(-2px); }\n`;
  cssContent += `.button.primary { color: white; background: var(--coral); box-shadow: 0 8px 22px rgba(241, 90, 88, .25); }\n`;
  cssContent += `.button.primary:hover { background: var(--coral-dark); }\n`;
  cssContent += `.button.secondary { background: white; border-color: #cbd6e1; color: var(--ink); }\n`;
  cssContent += `.compatibility { font-size: .82rem !important; display: flex; align-items: center; gap: 7px; }\n`;
  cssContent += `.edge-dot, .chrome-dot { width: 18px; height: 18px; border-radius: 50%; display: inline-block; }\n`;
  cssContent += `.edge-dot { background: conic-gradient(#0e9ede, #0ac18e, #0e9ede); }\n`;
  cssContent += `.chrome-dot { background: conic-gradient(#e64b3f 0 33%, #f0c646 0 66%, #42a75b 0); border: 5px solid #4385de; }\n\n`;

  // Browser mockup styles
  cssContent += `.browser-mockup { min-height: 440px; position: relative; border: 1px solid #cdd7e1; border-radius: 15px; background: #f7f7f7; box-shadow: var(--shadow); overflow: hidden; transform: perspective(1300px) rotateY(-2deg); }\n`;
  cssContent += `.browser-bar { height: 39px; display: flex; align-items: center; gap: 9px; background: #e9ebef; padding: 0 13px; color: #59657a; font-size: .75rem; }\n`;
  cssContent += `.browser-dot { width: 11px; height: 11px; border-radius: 50%; background: #c3c8d0; }\n`;
  cssContent += `.browser-actions { margin-left: auto; }\n`;
  cssContent += `.browser-content { display: grid; grid-template-columns: 1.5fr .8fr; gap: 8px; padding: 10px; height: 400px; background: white; }\n`;
  cssContent += `.video-placeholder { position: relative; border-radius: 6px; background: radial-gradient(circle at 62% 38%, #3b4b68 0 5%, transparent 6%), linear-gradient(145deg, #071020, #223654 58%, #0b1325); overflow: hidden; }\n`;
  cssContent += `.live-label { position: absolute; top: 13px; left: 13px; padding: 4px 7px; color: white; background: var(--coral); font-size: .62rem; font-weight: 900; border-radius: 4px; }\n`;
  cssContent += `.video-play { position: absolute; inset: 0; margin: auto; width: 48px; height: 48px; border-radius: 50%; display: grid; place-items: center; background: rgba(255,255,255,.85); color: var(--navy); }\n`;
  cssContent += `.video-controls { position: absolute; bottom: 15px; left: 18px; color: white; font-size: .75rem; }\n`;
  cssContent += `.chat-ghost { padding: 18px 10px; display: flex; flex-direction: column; gap: 14px; background: #f8f9fb; }\n`;
  cssContent += `.chat-ghost span { height: 7px; border-radius: 5px; background: #d8dde4; }\n`;
  cssContent += `.panel-mockup { position: absolute; width: 48%; right: 18px; top: 70px; background: white; border-radius: 10px; box-shadow: 0 18px 34px rgba(5, 18, 37, .28); overflow: hidden; }\n`;
  cssContent += `.panel-title { display: flex; align-items: center; gap: 8px; padding: 12px; border-bottom: 1px solid var(--line); background: white; font-size: .78rem; }\n`;
  cssContent += `.panel-title .brand-mark { width: 20px; height: 20px; border-width: 2px; }\n`;
  cssContent += `.panel-title > span:last-child { margin-left: auto; }\n`;
  cssContent += `.panel-row { display: flex; align-items: center; gap: 10px; padding: 13px 15px; border-bottom: 1px solid #edf0f3; font-size: .77rem; }\n`;
  cssContent += `.panel-row .icon { color: var(--cyan-dark); width: 17px; }\n`;
  cssContent += `.panel-row b { margin-left: auto; }\n\n`;

  // Why band styles
  cssContent += `.why-band { background: var(--wash); padding: 66px 0 76px; border-block: 1px solid #d7eef5; }\n`;
  cssContent += `.why-band h2 { text-align: center; font-size: clamp(2rem, 4vw, 3rem); margin: 0 0 12px; letter-spacing: -.04em; }\n`;
  cssContent += `.why-band > div > p { text-align: center; color: var(--muted); margin: 0 auto 44px; }\n`;
  cssContent += `.benefit-rail { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; }\n`;
  cssContent += `.benefit-rail article { border-top: 3px solid var(--cyan); padding: 25px 28px; background: rgba(255,255,255,.65); border-radius: 3px 3px 12px 12px; }\n`;
  cssContent += `.benefit-rail article .icon { width: 30px; height: 30px; color: var(--cyan-dark); }\n`;
  cssContent += `.benefit-rail h3 { margin: 18px 0 9px; }\n`;
  cssContent += `.benefit-rail p { color: var(--muted); line-height: 1.6; }\n\n`;

  // Platform section styles
  cssContent += `.platform-section { padding-block: 68px; }\n`;
  cssContent += `.platform-section > h2 { margin: 0 0 10px; font-size: clamp(1.8rem, 3vw, 2.55rem); letter-spacing: -.035em; }\n`;
  cssContent += `.platform-section > p { color: var(--muted); margin: 0 0 32px; }\n`;
  cssContent += `.platform-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 18px; }\n`;
  cssContent += `.platform-grid article { padding: 26px; border: 1px solid var(--line); border-top: 4px solid var(--coral); border-radius: 10px; background: white; }\n`;
  cssContent += `.platform-grid article:nth-child(2) { border-top-color: var(--cyan); }\n`;
  cssContent += `.platform-grid .icon { width: 30px; height: 30px; color: var(--navy); }\n`;
  cssContent += `.platform-grid h3 { margin: 18px 0 6px; }\n`;
  cssContent += `.platform-grid strong { color: var(--coral-dark); font-size: .82rem; }\n`;
  cssContent += `.platform-grid p { color: var(--muted); line-height: 1.6; margin-bottom: 0; }\n\n`;

  // Content page styles
  cssContent += `.content-page { padding-block: 72px 100px; min-height: 680px; }\n`;
  cssContent += `.content-page > h1 { font-size: clamp(2.4rem, 5vw, 4rem); }\n`;
  cssContent += `.page-lead { font-size: 1.24rem; color: var(--coral-dark); font-weight: 750; margin: 15px 0 40px; }\n`;
  cssContent += `.installation-layout { display: grid; grid-template-columns: .72fr 1.28fr; gap: 60px; align-items: center; margin-top: 45px; }\n`;
  cssContent += `.step-rail { list-style: none; margin: 0; padding: 0; }\n`;
  cssContent += `.step-rail li { position: relative; display: grid; grid-template-columns: 48px 1fr; gap: 17px; padding-bottom: 34px; }\n`;
  cssContent += `.step-rail li:not(:last-child)::before { content: ""; position: absolute; left: 23px; top: 45px; bottom: 4px; width: 2px; background: #d7e1e9; }\n`;
  cssContent += `.step-rail li > span { width: 46px; height: 46px; border: 2px solid #c8d3dd; color: #66758a; border-radius: 50%; display: grid; place-items: center; font-weight: 800; background: var(--paper); z-index: 1; }\n`;
  cssContent += `.step-rail li.current > span { background: var(--coral); border-color: var(--coral); color: white; }\n`;
  cssContent += `.step-rail h2 { font-size: 1.08rem; margin: 2px 0 5px; }\n`;
  cssContent += `.step-rail p { color: var(--muted); line-height: 1.55; margin: 0; }\n`;
  cssContent += `.extension-window { position: relative; border: 1px solid #cad5df; border-radius: 13px; background: white; box-shadow: var(--shadow); overflow: visible; min-height: 370px; }\n`;
  cssContent += `.extension-toolbar { height: 50px; background: #eef1f4; padding: 14px 17px; display: flex; align-items: center; font-size: .74rem; }\n`;
  cssContent += `.extension-toolbar > span { margin-left: auto; display: inline-flex; align-items: center; }\n`;
  cssContent += `.toggle { width: 31px; height: 17px; display: inline-block; background: #c4ccd4; border-radius: 20px; position: relative; vertical-align: middle; }\n`;
  cssContent += `.toggle::after { content: ""; width: 13px; height: 13px; background: white; border-radius: 50%; position: absolute; left: 2px; top: 2px; }\n`;
  cssContent += `.toggle.on { background: var(--cyan-dark); }\n`;
  cssContent += `.toggle.on::after { left: 16px; }\n`;
  cssContent += `.extension-body { padding: 24px; }\n`;
  cssContent += `.extension-body > button { padding: 9px 12px; border: 1px solid #c3ced9; background: white; border-radius: 5px; margin-right: 7px; font-size: .75rem; }\n`;
  cssContent += `.extension-body > button.focused { border: 2px solid var(--coral); position: relative; }\n`;
  cssContent += `.installed-extension { display: grid; grid-template-columns: 36px 1fr auto; gap: 15px; align-items: center; border: 1px solid #dae1e8; border-radius: 8px; padding: 18px; margin-top: 25px; font-size: .78rem; }\n`;
  cssContent += `.installed-extension p { color: var(--muted); margin: 6px 0 0; }\n`;
  cssContent += `.extension-window aside { position: absolute; right: -26px; bottom: -72px; width: 55%; padding: 17px; background: #fff5e7; border-left: 4px solid #f0a23a; box-shadow: 0 10px 25px rgba(80, 57, 24, .16); font-size: .76rem; }\n`;
  cssContent += `.extension-window aside .icon { color: #bd6f0a; }\n`;
  cssContent += `.extension-window aside p { color: #705d45; margin-bottom: 0; line-height: 1.45; }\n`;
  cssContent += `.workflow { margin-top: 120px; padding: 22px; display: grid; grid-template-columns: repeat(5, 1fr); gap: 10px; background: var(--wash); border-radius: 12px; }\n`;
  cssContent += `.workflow > div { position: relative; text-align: center; display: grid; justify-items: center; gap: 8px; font-size: .78rem; }\n`;
  cssContent += `.workflow > div > span { width: 29px; height: 29px; display: grid; place-items: center; border-radius: 50%; background: white; color: var(--cyan-dark); font-weight: 900; }\n`;
  cssContent += `.workflow b { position: absolute; right: -13px; top: 4px; color: var(--cyan-dark); }\n\n`;

  // Feature layout styles
  cssContent += `.feature-layout { display: grid; grid-template-columns: .6fr 1fr 1.1fr; gap: 28px; margin-top: 50px; align-items: stretch; }\n`;
  cssContent += `.feature-tabs { display: flex; flex-direction: column; border: 1px solid var(--line); border-radius: 10px; overflow: hidden; align-self: start; }\n`;
  cssContent += `.feature-tabs button { text-align: left; display: flex; gap: 12px; align-items: center; min-height: 58px; padding: 13px 15px; border: 0; border-bottom: 1px solid var(--line); background: white; color: #42516a; cursor: pointer; }\n`;
  cssContent += `.feature-tabs button:last-child { border-bottom: 0; }\n`;
  cssContent += `.feature-tabs button[aria-selected="true"] { background: var(--coral); color: white; font-weight: 800; }\n`;
  cssContent += `.feature-detail { padding: 30px; background: #fff8f4; border-radius: 12px; border-top: 4px solid var(--coral); }\n`;
  cssContent += `.feature-detail h2 { margin-top: 0; }\n`;
  cssContent += `.feature-detail p { color: var(--muted); line-height: 1.75; }\n`;
  cssContent += `.info-callout { display: flex; gap: 10px; margin-top: 25px; padding: 14px; background: white; color: #6e542b; border-left: 3px solid #e7a84d; font-size: .85rem; }\n`;
  cssContent += `.player-panel { padding: 18px; background: #f8f9fb; border: 1px solid #cfd7e0; border-radius: 12px; box-shadow: 0 15px 35px rgba(21, 40, 66, .13); font-size: .76rem; }\n`;
  cssContent += `.player-panel > small { display: block; color: #6d7890; letter-spacing: .12em; margin: 14px 0 9px; }\n`;
  cssContent += `.player-buttons { display: flex; align-items: center; gap: 10px; }\n`;
  cssContent += `.player-buttons button { width: 34px; height: 34px; border: 0; border-radius: 50%; display: grid; place-items: center; background: var(--coral); color: white; }\n`;
  cssContent += `.slider, .setting-line { flex: 1; height: 4px; border-radius: 4px; background: #cad4de; position: relative; }\n`;
  cssContent += `.slider span { display: block; width: 56%; height: 100%; background: var(--cyan); }\n`;
  cssContent += `.meter-label, .panel-setting { display: flex; align-items: center; justify-content: space-between; gap: 12px; margin: 9px 0; }\n`;
  cssContent += `.meter { display: flex; gap: 2px; height: 20px; }\n`;
  cssContent += `.meter i { flex: 1; background: #d9e0e7; }\n`;
  cssContent += `.meter i.lit { background: var(--cyan); }\n`;
  cssContent += `.panel-setting .setting-line { flex: 1; }\n`;
  cssContent += `.setting-line i { position: absolute; top: -3px; width: 10px; height: 10px; border-radius: 50%; background: var(--coral); }\n`;
  cssContent += `.download-band { margin-top: 60px; display: flex; align-items: center; gap: 12px; flex-wrap: wrap; padding: 25px; background: var(--navy); color: white; border-radius: 13px; }\n`;
  cssContent += `.download-band h2 { margin: 0 auto 0 0; }\n`;
  cssContent += `.download-band .secondary { background: transparent; color: white; border-color: #63718a; }\n\n`;

  // Architecture styles
  cssContent += `.architecture-flow { display: grid; grid-template-columns: repeat(3, 1fr); gap: 30px 42px; margin: 54px 0 50px; }\n`;
  cssContent += `.architecture-node { min-height: 155px; position: relative; padding: 26px; border: 1px solid #bfcfda; border-top: 4px solid var(--cyan); border-radius: 10px; background: white; box-shadow: 0 8px 20px rgba(20, 50, 70, .07); }\n`;
  cssContent += `.architecture-node:nth-child(3n+2) { border-top-color: var(--coral); }\n`;
  cssContent += `.architecture-node h2 { font-size: 1.05rem; }\n`;
  cssContent += `.architecture-node p { color: var(--muted); margin-bottom: 0; }\n`;
  cssContent += `.architecture-node > b { position: absolute; right: -31px; top: 48%; color: var(--cyan-dark); font-size: 1.4rem; }\n`;
  cssContent += `.security-facts { display: flex; gap: 10px; flex-wrap: wrap; margin: 35px 0; }\n`;
  cssContent += `.security-facts span { display: inline-flex; align-items: center; gap: 7px; padding: 10px 14px; background: var(--wash); border: 1px solid #bfe6ee; border-radius: 999px; font-size: .85rem; font-weight: 700; }\n`;
  cssContent += `.security-facts b { color: #15864d; }\n`;
  cssContent += `.risk-band { display: grid; grid-template-columns: 1fr 1fr; gap: 0; margin-top: 38px; border-radius: 10px; overflow: hidden; }\n`;
  cssContent += `.architecture-visualization { display: grid; grid-template-columns: minmax(0, 1.35fr) minmax(260px, .65fr); gap: 28px; align-items: center; margin: 40px 0; padding: 22px; border: 1px solid var(--line); border-radius: 14px; background: #f5f9fb; }\n`;
  cssContent += `.architecture-visualization img { width: 100%; min-width: 0; border-radius: 9px; background: #0f1729; }\n`;
  cssContent += `.architecture-visualization h2 { margin: 7px 0 10px; }\n`;
  cssContent += `.architecture-visualization p { color: var(--muted); line-height: 1.65; }\n`;
  cssContent += `.architecture-visualization .button { margin-top: 8px; }\n`;
  cssContent += `.architecture-gif-link { display: inline-block; margin-left: 15px; font-weight: 800; color: var(--navy); }\n`;
  cssContent += `.risk-band > div { padding: 24px; background: #fff3dc; border-left: 4px solid #e0a131; }\n`;
  cssContent += `.risk-band > div:last-child { background: #eaf8fb; border-left-color: var(--cyan); }\n`;
  cssContent += `.risk-band p { margin-bottom: 0; color: #5e6472; line-height: 1.55; }\n`;
  cssContent += `.security-list { display: grid; grid-template-columns: repeat(2, 1fr); gap: 18px; }\n`;
  cssContent += `.security-list article { padding: 26px; border: 1px solid var(--line); border-radius: 10px; background: white; }\n`;
  cssContent += `.security-list h2 { margin-top: 0; font-size: 1.15rem; }\n`;
  cssContent += `.security-list p { margin-bottom: 0; color: var(--muted); line-height: 1.7; }\n`;
  cssContent += `.faq-list { margin-top: 40px; max-width: 900px; }\n`;
  cssContent += `.faq-list details { border-bottom: 1px solid var(--line); padding: 5px 0; }\n`;
  cssContent += `.faq-list summary { list-style: none; cursor: pointer; padding: 22px 5px; font-weight: 800; display: flex; justify-content: space-between; }\n`;
  cssContent += `.faq-list summary::-webkit-details-marker { display: none; }\n`;
  cssContent += `.faq-list details[open] summary span { transform: rotate(45deg); }\n`;
  cssContent += `.faq-list p { color: var(--muted); line-height: 1.7; padding: 0 28px 20px 5px; }\n`;
  cssContent += `.hash-block { margin-top: 35px; border: 1px solid var(--line); border-radius: 10px; overflow: hidden; background: white; }\n`;
  cssContent += `.hash-block > div { display: flex; justify-content: space-between; align-items: center; padding: 16px 20px; background: #f2f6f8; }\n`;
  cssContent += `.hash-block h2 { font-size: 1rem; margin: 0; }\n`;
  cssContent += `.hash-block button { border: 1px solid #bac8d5; background: white; border-radius: 7px; padding: 8px 12px; cursor: pointer; }\n`;
  cssContent += `.hash-block pre { white-space: pre-wrap; overflow-wrap: anywhere; padding: 20px; color: #344158; font-size: .8rem; }\n`;
  cssContent += `.release-notes { margin-top: 35px; max-width: 850px; }\n`;
  cssContent += `.release-notes p { color: var(--muted); line-height: 1.75; }\n\n`;

  // Dialog styles
  cssContent += `.dialog-backdrop { position: fixed; inset: 0; z-index: 100; background: rgba(6, 15, 30, .56); display: grid; place-items: start center; padding-top: 12vh; }\n`;
  cssContent += `.search-dialog { width: min(650px, calc(100% - 30px)); max-height: 70vh; overflow: auto; border-radius: 14px; background: white; box-shadow: 0 25px 80px rgba(0,0,0,.35); }\n`;
  cssContent += `.search-field { display: flex; align-items: center; gap: 10px; padding: 17px; border-bottom: 1px solid var(--line); }\n`;
  cssContent += `.search-field input { flex: 1; border: 0; outline: 0; font-size: 1.08rem; }\n`;
  cssContent += `.search-field button { border: 0; background: transparent; font-size: 1.5rem; cursor: pointer; }\n`;
  cssContent += `.search-results { padding: 8px; }\n`;
  cssContent += `.search-results button { width: 100%; display: grid; gap: 3px; text-align: left; padding: 13px; border: 0; border-radius: 8px; background: transparent; cursor: pointer; }\n`;
  cssContent += `.search-results button:hover { background: var(--wash); }\n`;
  cssContent += `.search-results small { color: var(--muted); }\n`;
  cssContent += `.search-results p { padding: 20px; color: var(--muted); }\n\n`;

  // Footer styles
  cssContent += `footer { padding: 36px 0; background: #101d34; color: #d8e0eb; }\n`;
  cssContent += `footer .page-width { display: flex; align-items: center; gap: 24px; }\n`;
  cssContent += `footer p { color: #9facbd; margin-right: auto; }\n`;
  cssContent += `footer div > div:last-child { display: flex; gap: 18px; }\n\n`;

  // Media queries
  cssContent += `@
