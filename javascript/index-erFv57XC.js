#!/usr/bin/env node
// index-erFv57XC.css — portiert nach javascript
// Quelle: css, Projects@Weather-Check:Weather-Check/assets/index-erFv57XC.css
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function generateCSS() {
  const cssRules = [];
  
  // Add import rule
  cssRules.push('@import"url(\'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap\')"');
  
  // Universal selector rules
  cssRules.push('*,:before,:after{--tw-border-spacing-x:0;--tw-border-spacing-y:0;--tw-translate-x:0;--tw-translate-y:0;--tw-rotate:0;--tw-skew-x:0;--tw-skew-y:0;--tw-scale-x:1;--tw-scale-y:1;--tw-pan-x: ;--tw-pan-y: ;--tw-pinch-zoom: ;--tw-scroll-snap-strictness:proximity;--tw-gradient-from-position: ;--tw-gradient-via-position: ;--tw-gradient-to-position: ;--tw-ordinal: ;--tw-slashed-zero: ;--tw-numeric-figure: ;--tw-numeric-spacing: ;--tw-numeric-fraction: ;--tw-ring-inset: ;--tw-ring-offset-width:0px;--tw-ring-offset-color:#fff;--tw-ring-color:rgb(59 130 246 / .5);--tw-ring-offset-shadow:0 0 #0000;--tw-ring-shadow:0 0 #0000;--tw-shadow:0 0 #0000;--tw-shadow-colored:0 0 #0000;--tw-blur: ;--tw-brightness: ;--tw-contrast: ;--tw-grayscale: ;--tw-hue-rotate: ;--tw-invert: ;--tw-saturate: ;--tw-sepia: ;--tw-drop-shadow: ;--tw-backdrop-blur: ;--tw-backdrop-brightness: ;--tw-backdrop-contrast: ;--tw-backdrop-grayscale: ;--tw-backdrop-hue-rotate: ;--tw-backdrop-invert: ;--tw-backdrop-opacity: ;--tw-backdrop-saturate: ;--tw-backdrop-sepia: ;--tw-contain-size: ;--tw-contain-layout: ;--tw-contain-paint: ;--tw-contain-style: }');
  
  // Backdrop rules
  cssRules.push('::backdrop{--tw-border-spacing-x:0;--tw-border-spacing-y:0;--tw-translate-x:0;--tw-translate-y:0;--tw-rotate:0;--tw-skew-x:0;--tw-skew-y:0;--tw-scale-x:1;--tw-scale-y:1;--tw-pan-x: ;--tw-pan-y: ;--tw-pinch-zoom: ;--tw-scroll-snap-strictness:proximity;--tw-gradient-from-position: ;--tw-gradient-via-position: ;--tw-gradient-to-position: ;--tw-ordinal: ;--tw-slashed-zero: ;--tw-numeric-figure: ;--tw-numeric-spacing: ;--tw-numeric-fraction: ;--tw-ring-inset: ;--tw-ring-offset-width:0px;--tw-ring-offset-color:#fff;--tw-ring-color:rgb(59 130 246 / .5);--tw-ring-offset-shadow:0 0 #0000;--tw-ring-shadow:0 0 #0000;--tw-shadow:0 0 #0000;--tw-shadow-colored:0 0 #0000;--tw-blur: ;--tw-brightness: ;--tw-contrast: ;--tw-grayscale: ;--tw-hue-rotate: ;--tw-invert: ;--tw-saturate: ;--tw-sepia: ;--tw-drop-shadow: ;--tw-backdrop-blur: ;--tw-backdrop-brightness: ;--tw-backdrop-contrast: ;--tw-backdrop-grayscale: ;--tw-backdrop-hue-rotate: ;--tw-backdrop-invert: ;--tw-backdrop-opacity: ;--tw-backdrop-saturate: ;--tw-backdrop-sepia: ;--tw-contain-size: ;--tw-contain-layout: ;--tw-contain-paint: ;--tw-contain-style: }');
  
  // Border box rules
  cssRules.push('*,:before,:after{box-sizing:border-box;border-width:0;border-style:solid;border-color:#e5e7eb}');
  
  // Before/after content
  cssRules.push(':before,:after{--tw-content:""}');
  
  // HTML and host rules
  cssRules.push('html,:host{line-height:1.5;-webkit-text-size-adjust:100%;-moz-tab-size:4;-o-tab-size:4;tab-size:4;font-family:var(--font-sans);font-feature-settings:normal;font-variation-settings:normal;-webkit-tap-highlight-color:transparent}');
  
  // Body rules
  cssRules.push('body{margin:0;line-height:inherit}');
  
  // HR rules
  cssRules.push('hr{height:0;color:inherit;border-top-width:1px}');
  
  // Abbreviation rules
  cssRules.push('abbr:where([title]){-webkit-text-decoration:underline dotted;text-decoration:underline dotted}');
  
  // Heading rules
  cssRules.push('h1,h2,h3,h4,h5,h6{font-size:inherit;font-weight:inherit}');
  
  // Anchor rules
  cssRules.push('a{color:inherit;text-decoration:inherit}');
  
  // Bold rules
  cssRules.push('b,strong{font-weight:bolder}');
  
  // Code rules
  cssRules.push('code,kbd,samp,pre{font-family:var(--font-mono);font-feature-settings:normal;font-variation-settings:normal;font-size:1em}');
  
  // Small rules
  cssRules.push('small{font-size:80%}');
  
  // Sub/sup rules
  cssRules.push('sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline}');
  cssRules.push('sub{bottom:-.25em}');
  cssRules.push('sup{top:-.5em}');
  
  // Table rules
  cssRules.push('table{text-indent:0;border-color:inherit;border-collapse:collapse}');
  
  // Form element rules
  cssRules.push('button,input,optgroup,select,textarea{font-family:inherit;font-feature-settings:inherit;font-variation-settings:inherit;font-size:100%;font-weight:inherit;line-height:inherit;letter-spacing:inherit;color:inherit;margin:0;padding:0}');
  cssRules.push('button,select{text-transform:none}');
  cssRules.push('button,input:where([type=button]),input:where([type=reset]),input:where([type=submit]){-webkit-appearance:button;background-color:transparent;background-image:none}');
  
  // Focus ring rules
  cssRules.push(':-moz-focusring{outline:auto}');
  cssRules.push(':-moz-ui-invalid{box-shadow:none}');
  
  // Progress rules
  cssRules.push('progress{vertical-align:baseline}');
  
  // Spin button rules
  cssRules.push('::-webkit-inner-spin-button,::-webkit-outer-spin-button{height:auto}');
  
  // Search input rules
  cssRules.push('[type=search]{-webkit-appearance:textfield;outline-offset:-2px}');
  cssRules.push('::-webkit-search-decoration{-webkit-appearance:none}');
  cssRules.push('::-webkit-file-upload-button{-webkit-appearance:button;font:inherit}');
  
  // Summary rules
  cssRules.push('summary{display:list-item}');
  
  // Margin reset rules
  cssRules.push('blockquote,dl,dd,h1,h2,h3,h4,h5,h6,hr,figure,p,pre{margin:0}');
  cssRules.push('fieldset{margin:0;padding:0}');
  cssRules.push('legend{padding:0}');
  cssRules.push('ol,ul,menu{list-style:none;margin:0;padding:0}');
  cssRules.push('dialog{padding:0}');
  
  // Textarea rules
  cssRules.push('textarea{resize:vertical}');
  
  // Placeholder rules
  cssRules.push('input::-moz-placeholder,textarea::-moz-placeholder{opacity:1;color:#9ca3af}');
  cssRules.push('input::placeholder,textarea::placeholder{opacity:1;color:#9ca3af}');
  
  // Button rules
  cssRules.push('button,[role=button]{cursor:pointer}');
  cssRules.push(':disabled{cursor:default}');
  
  // Media rules
  cssRules.push('img,svg,video,canvas,audio,iframe,embed,object{display:block;vertical-align:middle}');
  cssRules.push('img,video{max-width:100%;height:auto}');
  
  // Hidden rules
  cssRules.push('[hidden]:where(:not([hidden=until-found])){display:none}');
  
  // Utility classes
  cssRules.push('.sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border-width:0}');
  cssRules.push('.pointer-events-none{pointer-events:none}');
  cssRules.push('.pointer-events-auto{pointer-events:auto}');
  cssRules.push('.visible{visibility:visible}');
  cssRules.push('.invisible{visibility:hidden}');
  cssRules.push('.fixed{position:fixed}');
  cssRules.push('.absolute{position:absolute}');
  cssRules.push('.relative{position:relative}');
  cssRules.push('.inset-0{inset:0}');
  cssRules.push('.inset-x-0{left:0;right:0}');
  cssRules.push('.inset-y-0{top:0;bottom:0}');
  cssRules.push('.-bottom-12{bottom:-3rem}');
  cssRules.push('.-left-12{left:-3rem}');
  cssRules.push('.-right-12{right:-3rem}');
  cssRules.push('.-top-12{top:-3rem}');
  cssRules.push('.bottom-0{bottom:0}');
  cssRules.push('.left-0{left:0}');
  cssRules.push('.left-1{left:.25rem}');
  cssRules.push('.left-1\\/2{left:50%}');
  cssRules.push('.left-2{left:.5rem}');
  cssRules.push('.left-4{left:1rem}');
  cssRules.push('.left-\\[50\\%\\]{left:50%}');
  cssRules.push('.right-0{right:0}');
  cssRules.push('.right-1{right:.25rem}');
  cssRules.push('.right-2{right:.5rem}');
  cssRules.push('.right-3{right:.75rem}');
  cssRules.push('.right-4{right:1rem}');
  cssRules.push('.top-0{top:0}');
  cssRules.push('.top-1\\.5{top:.375rem}');
  cssRules.push('.top-1\\/2{top:50%}');
  cssRules.push('.top-16{top:4rem}');
  cssRules.push('.top-2{top:.5rem}');
  cssRules.push('.top-20{top:5rem}');
  cssRules.push('.top-3\\.5{top:.875rem}');
  cssRules.push('.top-32{top:8rem}');
  cssRules.push('.top-4{top:1rem}');
  cssRules.push('.top-\\[1px\\]{top:1px}');
  cssRules.push('.top-\\[50\\%\\]{top:50%}');
  cssRules.push('.top-\\[60\\%\\]{top:60%}');
  cssRules.push('.top-full{top:100%}');
  cssRules.push('.z-10{z-index:10}');
  cssRules.push('.z-20{z-index:20}');
  cssRules.push('.z-50{z-index:50}');
  cssRules.push('.z-\\[100\\]{z-index:100}');
  cssRules.push('.z-\\[1\\]{z-index:1}');
  cssRules.push('.-mx-1{margin-left:-.25rem;margin-right:-.25rem}');
  cssRules.push('.mx-2{margin-left:.5rem;margin-right:.5rem}');
  cssRules.push('.mx-3\\.5{margin-left:.875rem;margin-right:.875rem}');
  cssRules.push('.mx-4{margin-left:1rem;margin-right:1rem}');
  cssRules.push('.mx-auto{margin-left:auto;margin-right:auto}');
  cssRules.push('.my-0\\.5{margin-top:.125rem;margin-bottom:.125rem}');
  cssRules.push('.my-1{margin-top:.25rem;margin-bottom:.25rem}');
  cssRules.push('.-ml-4{margin-left:-1rem}');
  cssRules.push('.-mt-4{margin-top:-1rem}');
  cssRules.push('.mb-1{margin-bottom:.25rem}');
  cssRules.push('.mb-2{margin-bottom:.5rem}');
  cssRules.push('.mb-3{margin-bottom:.75rem}');
  cssRules.push('.mb-4{margin-bottom:1rem}');
  cssRules.push('.mb-6{margin-bottom:1.5rem}');
  cssRules.push('.mb-8{margin-bottom:2rem}');
  cssRules.push('.ml-1{margin-left:.25rem}');
  cssRules.push('.ml-1\\.5{margin-left:.375rem}');
  cssRules.push('.ml-2{margin-left:.5rem}');
  cssRules.push('.ml-auto{margin-left:auto}');
  cssRules.push('.mr-2{margin-right:.5rem}');
  cssRules.push('.mt-0\\.5{margin-top:.125rem}');
  cssRules.push('.mt-1\\.5{margin-top:.375rem}');
  cssRules.push('.mt-2{margin-top:.5rem}');
  cssRules.push('.mt-24{margin-top:6rem}');
  cssRules.push('.mt-3{margin-top:.75rem}');
  cssRules.push('.mt-4{margin-top:1rem}');
  cssRules.push('.mt-auto{margin-top:auto}');
  cssRules.push('.block{display:block}');
  cssRules.push('.inline-block{display:inline-block}');
  cssRules.push('.flex{display:flex}');
  cssRules.push('.inline-flex{display:inline-flex}');
  cssRules.push('.table{display:table}');
  cssRules.push('.grid{display:grid}');
  cssRules.push('.hidden{display:none}');
  cssRules.push('.aspect-square{aspect-ratio:1 / 1}');
  cssRules.push('.aspect-video{aspect-ratio:16 / 9}');
  cssRules.push('.size-4{width:1rem;height:1rem}');
  cssRules.push('.h-1\\.5{height:.375rem}');
  cssRules.push('.h-10{height:2.5rem}');
  cssRules.push('.h-11{height:2.75rem}');
  cssRules.push('.h-12{height:3rem}');
  cssRules.push('.h-14{height:3.5rem}');
  cssRules.push('.h-16{height:4rem}');
  cssRules.push('.h-2{height:.5rem}');
  cssRules.push('.h-2\\.5{height:.625rem}');
  cssRules.push('.h-20{height:5rem}');
  cssRules.push('.h-3{height:.75rem}');
  cssRules.push('.h-3\\.5{height:.875rem}');
  cssRules.push('.h-32{height:8rem}');
  cssRules.push('.h-4{height:1rem}');
  cssRules.push('.h-5{height:1.25rem}');
  cssRules.push('.h-6{height:1.5rem}');
  cssRules.push('.h-7{height:1.75rem}');
  cssRules.push('.h-8{height:2rem}');
  cssRules.push('.h-9{height:2.25rem}');
  cssRules.push('.h-\\[1px\\]{height:1px}');
  cssRules.push('.h-\\[var\\(--radix-navigation-menu-viewport-height\\)\\]{height:var(--radix-navigation-menu-viewport-height)}');
  cssRules.push('.h-\\[var\\(--radix-select-trigger-height\\)\\]{height:var(--radix-select-trigger-height)}');
  cssRules.push('.h-auto{height:auto}');
  cssRules.push('.h-full{height:100%}');
  cssRules.push('.h-px{height:1px}');
  cssRules.push('.h-svh{height:100svh}');
  cssRules.push('.max-h-\\[--radix-context-menu-content-available-height\\]{max-height:var(--radix-context-menu-content-available-height)}');
  cssRules.push('.max-h-\\[--radix-select-content-available-height\\]{max-height:var(--radix-select-content-available-height)}');
  cssRules.push('.max-h-\\[300px\\]{max-height:300px}');
  cssRules.push('.max-h-\\[var\\(--radix-dropdown-menu-content-available-height\\)\\]{max-height:var(--radix-dropdown-menu-content-available-height)}');
  cssRules.push('.max-h-screen{max-height:100vh}');
  cssRules.push('.min-h-0{min-height:0px}');
  cssRules.push('.min-h-10{min-height:2.5rem}');
  cssRules.push('.min-h-8{min-height:2rem}');
  cssRules.push('.min-h-9{min-height:2.25rem}');
  cssRules.push('.min-h-\\[80px\\]{min-height:80px}');
  cssRules.push('.min-h-dvh{min-height:100dvh}');
  cssRules.push('.min-h-screen{min-height:100vh}');
  cssRules.push('.min-h-svh{min-height:100svh}');
  cssRules.push('.w-0{width:0px}');
  cssRules.push('.w-1{width:.25rem}');
  cssRules.push('.w-10{width:2.5rem}');
  cssRules.push('.w-11{width:2.75rem}');
  cssRules.push('.w-12{width:3rem}');
  cssRules.push('.w-14{width:3.5rem}');
  cssRules.push('.w-16{width:4rem}');
  cssRules.push('.w-2{width:.5rem}');
  cssRules.push('.w-2\\.5{width:.625rem}');
  cssRules.push('.w-20{width:5rem}');
  cssRules.push('.w-3{width:.75rem}');
  cssRules.push('.w-3\\.5{width:.875rem}');
  cssRules.push('.w-3\\/4{width:75%}');
  cssRules.push('.w-32{width:8rem}');
  cssRules.push('.w-4{width:1rem}');
  cssRules.push('.w-5{width:1.25rem}');
  cssRules.push('.w-64{width:16rem}');
  cssRules.push('.w-7{width:1.75rem}');
  cssRules.push('.w-72{width:18rem}');
  cssRules.push('.w-8{width:2rem}');
  cssRules.push('.w-9{width:2.25rem}');
  cssRules.push('.w-\\[100px\\]{width:100px}');
  cssRules.push('.w-\\[1px\\]{width:1px}');
  cssRules.push('.w-\\[var\\(--sidebar-width\\)\\]{width:var(--sidebar-width)}');
  cssRules.push('.w-auto{width:auto}');
  cssRules.push('.w-full{width:100%}');
  cssRules.push('.w-max{width:-moz-max-content;width:max-content}');
  cssRules.push('.w-px{width:1px}');
  cssRules.push('.min-w-0{min-width:0px}');
  cssRules.push('.min-w-10{min-width:2.5rem}');
  cssRules.push('.min-w-11{min-width:2.75rem}');
  cssRules.push('.min-w-5{min-width:1.25rem}');
  cssRules.push('.min-w-9{min-width:2.25rem}');
  cssRules.push('.min-w-\\[12rem\\]{min-width:12rem}');
  cssRules.push('.min-w-\\[8rem\\]{min-width:8rem}');
  cssRules.push('.min-w-\\[var\\(--radix-select-trigger-width\\)\\]{min-width:var(--radix-select-trigger-width)}');
  cssRules.push('.max-w-\\[var\\(--skeleton-width\\)\\]{max-width:var(--skeleton-width)}');
  cssRules.push('.max-w-lg{max-width:32rem}');
  cssRules.push('.max-w-max{max-width:-moz-max-content;max-width:max-content}');
  cssRules.push('.max-w-md{max-width:28rem}');
  cssRules.push('.max-w-sm{max-width:24rem}');
  cssRules.push('.flex-1{flex:1 1 0%}');
  cssRules.push('.shrink-0{flex-shrink:0}');
  cssRules.push('.grow{flex-grow:1}');
  cssRules.push('.grow-0{flex-grow:0}');
  cssRules.push('.basis-full{flex-basis:100%}');
  cssRules.push('.caption-bottom{caption-side:bottom}');
  cssRules.push('.border-collapse{border-collapse:collapse}');
  cssRules.push('.origin-\\[--radix-context-menu-content-transform-origin\\]{transform-origin:var(--radix-context-menu-content-transform-origin)}');
  cssRules.push('.origin-\\[--radix-dropdown-menu-content-transform-origin\\]{transform-origin:var(--radix-dropdown-menu-content-transform-origin)}');
  cssRules.push('.origin-\\[--radix-hover-card-content-transform-origin\\]{transform-origin:var(--radix-hover-card-content-transform-origin)}');
  cssRules.push('.origin-\\[--radix-menubar-content-transform-origin\\]{transform-origin:var(--radix-menubar-content-transform-origin)}');
  cssRules.push('.origin-\\[--radix-popover-content-transform-origin\\]{transform-origin:var(--radix-popover-content-transform-origin)}');
  cssRules.push('.origin-\\[--radix-select-content-transform-origin\\]{transform-origin:var(--radix-select-content-transform-origin)}');
  cssRules.push('.origin-\\[--radix-tooltip-content-transform-origin\\]{transform-origin:var(--radix-tooltip-content-transform-origin)}');
  cssRules.push('.-translate-x-1\\/2{--tw-translate-x:-50%;transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}');
  cssRules.push('.-translate-x-px{--tw-translate-x:-1px;transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}');
  cssRules.push('.-translate-y-1\\/2{--tw-translate-y:-50%;transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}');
  cssRules.push('.translate-x-\\[-50\\%\\]{--tw-translate-x:-50%;transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}');
  cssRules.push('.translate-x-px{--tw-translate-x:1px;transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}');
  cssRules.push('.translate-y-\\[-50\\%\\]{--tw-translate-y:-50%;transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}');
  cssRules.push('.rotate-45{--tw-rotate:45deg;transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}');
  cssRules.push('.rotate-90{--tw-rotate:90deg;transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}');
  cssRules.push('.transform{transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}');
  
  // Animation keyframes
  cssRules.push('@keyframes pulse{50%{opacity:.5}}');
  cssRules.push('.animate-pulse{animation:pulse 2s cubic-bezier(.4,0,.6,1) infinite}');
  cssRules.push('@keyframes spin{to{transform:rotate(360deg)}}');
  cssRules.push('.animate-spin{animation:spin 1s linear infinite}');
  
  // Cursor rules
  cssRules.push('.cursor-default{cursor:default}');
  cssRules.push('.cursor-pointer{cursor:pointer}');
  cssRules.push('.touch-none{touch-action:none}');
  cssRules.push('.select-none{-webkit-user-select:none;-moz-user-select:none;user-select:none}');
  cssRules.push('.list-none{list-style-type:none}');
  
  // Grid rules
  cssRules.push('.grid-cols-3{grid-template-columns:repeat(3,minmax(0,1fr))}');
  cssRules.push('.grid-cols-4{grid-template-columns:repeat(4,minmax(0,1fr))}');
  
  // Flex rules
  cssRules.push('.flex-row{flex-direction:row}');
  cssRules.push('.flex-col{flex-direction:column}');
  cssRules.push('.flex-col-reverse{flex-direction:column-reverse}');
  cssRules.push('.flex-wrap{flex-wrap:wrap}');
  cssRules.push('.items-start{align-items:flex-start}');
  cssRules.push('.items-end{align-items:flex-end}');
  cssRules.push('.items-center{align-items:center}');
  cssRules.push('.items-stretch{align-items:stretch}');
  cssRules.push('.justify-center{justify-content:center}');
  cssRules.push('.justify-between{justify-content:space-between}');
  
  // Gap rules
  cssRules.push('.gap-1{gap:.25rem}');
  cssRules.push('.gap-1\\.5{gap:.375rem}');
  cssRules.push('.gap-2{gap:.5rem}');
  cssRules.push('.gap-3{gap:.75rem}');
  cssRules.push('.gap-4{gap:1rem}');
  cssRules.push('.gap-8{gap:2rem}');
  
  // Space rules
  cssRules.push('.space-x-1>:not([hidden])~:not([hidden]){--tw-space-x-reverse:0;margin-right:calc(.25rem * var(--tw-space-x-reverse));margin-left:calc(.25rem * calc(1 - var(--tw-space-x-reverse)))}');
  cssRules.push('.space-x-4>:not([hidden])~:not([hidden]){--tw-space-x-reverse:0;margin-right:calc(1rem * var(--tw-space-x-reverse));margin-left:calc(1rem * calc(1 - var(--tw-space-x-reverse)))}');
  cssRules.push('.space-y-1>:not([hidden])~:not([hidden]){--tw-space-y-reverse:0;margin-top:calc(.25rem * calc(1 - var(--tw-space-y-reverse)));margin-bottom:calc(.25rem * var(--tw-space-y-reverse))}');
  cssRules.push('.space-y-1\\.5>:not([hidden])~:not([hidden]){--tw-space-y-reverse:0;margin-top:calc(.375rem * calc(1 - var(--tw-space-y-reverse)));margin-bottom:calc(.375rem * var(--tw-space-y-reverse))}');
  cssRules.push('.space-y-2>:not([hidden])~:not([hidden]){--tw-space-y-reverse:0;margin-top:calc(.5rem * calc(1 - var(--tw-space-y-reverse)));margin-bottom:calc(.5rem * var(--tw-space-y-reverse))}');
  cssRules.push('.space-y-3>:not([hidden])~:not([hidden]){--tw-space-y-reverse:0;margin-top:calc(.75rem * calc(1 - var(--tw-space-y-reverse)));margin-bottom:calc(.75rem * var(--tw-space-y-reverse))}');
  cssRules.push('.space-y-4>:not([hidden])~:not([hidden]){--tw-space-y-reverse:0;margin-top:calc(1rem * calc(1 - var(--tw-space-y-reverse)));margin-bottom:calc(1rem * var(--tw-space-y-reverse))}');
  cssRules.push('.space-y-5>:not([hidden])~:not([hidden]){--tw-space-y-reverse:0;margin-top:calc(1.25rem * calc(1 - var(--tw-space-y-reverse)));margin-bottom:calc(1.25rem * var(--tw-space-y-reverse))}');
  cssRules.push('.space-y-8>:not([hidden])~:not([hidden]){--tw-space-y-reverse:0;margin-top:calc(2rem * calc(1 - var(--tw-space-y-reverse)));margin-bottom:calc(2rem * var(--tw-space-y-reverse))}');
  
  // Overflow rules
  cssRules.push('.overflow-auto{overflow:auto}');
  cssRules.push('.overflow-hidden{overflow:hidden}');
  cssRules.push('.overflow-y-auto{overflow-y:auto}');
  cssRules.push('.overflow-x-hidden{overflow-x:hidden}');
  cssRules.push('.truncate{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}');
  cssRules.push('.whitespace-nowrap{white-space:nowrap}');
  cssRules.push('.break-words{overflow-wrap:break-word}');
  
  // Border radius rules
  cssRules.push('.rounded-2xl{border-radius:1rem}');
  cssRules.push('.rounded-3xl{border-radius:1.5rem}');
  cssRules.push('.rounded-\\[2px\\]{border-radius:2px}');
  cssRules.push('.rounded-\\[inherit\\]{border-radius:inherit}');
  cssRules.push('.rounded-full{border-radius:9999px}');
  cssRules.push('.rounded-lg{border-radius:.5625rem}');
  cssRules.push('.rounded-md{border-radius:.375rem}');
  cssRules.push('.rounded-sm{border-radius:.1875rem}');
  cssRules.push('.rounded-xl{border-radius:.75rem}');
  cssRules.push('.rounded-t-\\[10px\\]{border-top-left-radius:10px;border-top-right-radius:10px}');
  cssRules.push('.rounded-tl-sm{border-top-left-radius:.1875rem}');
  
  // Border width rules
  cssRules.push('.border{border-width:1px}');
  cssRules.push('.border-2{border-width:2px}');
  cssRules.push('.border-\\[1\\.5px\\]{border-width:1.5px}');
  cssRules.push('.border-\\[5px\\]{border-width:5px}');
  cssRules.push('.border-y{border-top-width:1px;border-bottom-width:1px}');
  cssRules.push('.border-b{border-bottom-width:1px}');
  cssRules.push('.border-l{border-left-width:1px}');
  cssRules.push('.border-r{border-right-width:1px}');
  cssRules.push('.border-t{border-top-width:1px}');
  cssRules.push('.border-dashed{border-style:dashed}');
  
  // Border color rules
  cssRules.push('.border-\\[--color-border\\]{border-color:var(--color-border)}');
  cssRules.push('.border-\\[hsl\\(var\\(--border\\)\\)\\]{border-color:hsl(var(--border))}');
  cssRules.push('.border-\\[hsl\\(var\\(--primary\\)\\)\\]{border-color:hsl(var(--primary))}');
  cssRules.push('.border-\\[hsl\\(var\\(--primary\\)\\)\\]\\/10{border-color:hsl(var(--primary) / .1)}');
  cssRules.push('.border-\\[hsl\\(var\\(--primary\\)\\)\\]\\/20{border-color:hsl(var(--primary) / .2)}');
  cssRules.push('.border-\\[hsl\\(var\\(--primary\\)\\)\\]\\/30{border-color:hsl(var(--primary) / .3)}');
  cssRules.push('.border-amber-500\\/20{border-color:#f59e0b33}');
  cssRules.push('.border-amber-500\\/40{border-color:#f59e0b66}');
  cssRules.push('.border-border\\/50{border-color:hsl(var(--border) / .5)}');
  cssRules.push('.border-card-border{--tw-border-opacity:1;border-color:hsl(var(--card-border) / var(--tw-border-opacity, 1))}');
  cssRules.push('.border-destructive{--tw-border-opacity:1;border-color:hsl(var(--destructive) / var(--tw-border-opacity, 1))}');
  cssRules.push('.border-destructive-border{border-color:var(--destructive-border)}');
  cssRules.push('.border-destructive\\/50{border-color:hsl(var(--destructive) / .5)}');
  cssRules.push('.border-emerald-500\\/30{border-color:#10b9814d}');
  cssRules.push('.border-emerald-500\\/40{border-color:#10b98166}');
  cssRules.push('.border-green-400{--tw-border-opacity:1;border-color:rgb(74 222 128 / var(--tw-border-opacity, 1))}');
  cssRules.push('.border-input{--tw-border-opacity:1;border-color:hsl(var(--input) / var(--tw-border-opacity, 1))}');
  cssRules.push('.border-primary{--tw-border-opacity:1;border-color:hsl(var(--primary) / var(--tw-border-opacity, 1))}');
  cssRules.push('.border-primary-border{border-color:var(--primary-border)}');
  cssRules.push('.border-red-500\\/20{border-color:#ef444433}');
  cssRules.push('.border-red-500\\/30{border-color:#ef44444d}');
  cssRules.push('.border-secondary-border{border-color:var(--secondary-border)}');
  cssRules.push('.border-sidebar-border{--tw-border-opacity:1;border-color:hsl(var(--sidebar-border) / var(--tw-border-opacity,
