#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "d5d93340c689f8489e311ab96492e1414e526e201a6b77c06360e7c782f39e98", "source_sha256": "a19d3a3ec8b016d9d04f485dc499f8ad715431708b02863f2ac58f3208061edd", "target_language": "javascript"}
// peak-limiter.css — portiert nach javascript
// Quelle: css, Projects@abstractions:css/peak-limiter.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

function generateCSS() {
    const comments = [
        '/* abstraction-provenance: {"artifact_sha256": "3f2b97b726a0a4643711dc1dc285df9b75511cc4f35fbe168e178bf60aeaa00d", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "css"} */',
        '/* peak-limiter.html — portiert nach css */',
        '/* Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html */',
        '/* auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html */',
        '/* auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html */',
        '/* auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html */',
        '/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */'
    ];

    const styles = {
        body: {
            font: '16px system-ui',
            'max-width': '1000px',
            margin: '40px auto',
            padding: '20px'
        },
        pre: {
            'white-space': 'pre-wrap'
        },
        button: {
            padding: '12px'
        }
    };

    let cssContent = comments.join('\n') + '\n\n';

    for (const [selector, rules] of Object.entries(styles)) {
        cssContent += `${selector} {\n`;
        for (const [property, value] of Object.entries(rules)) {
            cssContent += `  ${property}: ${value};\n`;
        }
        cssContent += '}\n\n';
    }

    return cssContent;
}

function writeCSSToFile(filePath) {
    const cssContent = generateCSS();
    const dir = path.dirname(filePath);
    
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
    
    fs.writeFileSync(filePath, cssContent, 'utf8');
}

if (require.main === module) {
    const outputPath = process.argv[2] || 'peak-limiter.css';
    writeCSSToFile(outputPath);
    console.log(`CSS file generated at: ${outputPath}`);
}

module.exports = { generateCSS, writeCSSToFile };
