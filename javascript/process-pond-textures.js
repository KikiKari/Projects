#!/usr/bin/env node
// process-pond-textures.py — portiert nach javascript
// Quelle: python, Onboarding@main:scripts/process-pond-textures.py
// Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

/**
 * Chroma-key pond textures to add a clean alpha channel.
 *
 * The leaf/blossom source webps ship on solid backgrounds (dark green or white)
 * rather than transparency, so `alphaTest` clipping in three.js has nothing to
 * key on. This produces RGBA PNGs with a soft alpha mask so the R3F planes clip
 * to the real silhouette.
 */

const fs = require('fs');
const path = require('path');
const { createCanvas, loadImage } = require('canvas');

const BASE = "public/media/pond";
const OUT = "public/media/pond/processed";

// Create output directory if it doesn't exist
if (!fs.existsSync(OUT)) {
    fs.mkdirSync(OUT, { recursive: true });
}

function clamp(value, min, max) {
    return Math.min(Math.max(value, min), max);
}

function keyOut(filePath, outFile, mode, feather = 2.0) {
    return loadImage(filePath).then(img => {
        const canvas = createCanvas(img.width, img.height);
        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0);

        const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
        const data = imageData.data;
        const alpha = new Uint8Array(canvas.width * canvas.height);

        for (let i = 0; i < data.length; i += 4) {
            const r = data[i];
            const g = data[i + 1];
            const b = data[i + 2];
            const idx = i / 4;

            if (mode === "green") {
                // Dark-green background: low overall brightness AND green-dominant-but-dark.
                // Foreground leaf is much brighter / lighter green.
                const lum = (r + g + b) / 3.0;
                // background pixels: very dark (lum < ~35) — the bg is ~(3,50,0)=17
                const bg = lum < 40.0;
                alpha[idx] = bg ? 0 : 255;
            } else if (mode === "white") {
                // White background: near-white, low saturation.
                const mn = Math.min(r, g, b);
                const mx = Math.max(r, g, b);
                // background: bright and low chroma
                const isWhite = (mn > 218.0) && ((mx - mn) < 28.0);
                alpha[idx] = isWhite ? 0 : 255;
            } else {
                throw new Error(mode);
            }
        }

        // Apply feathering (Gaussian blur approximation for alpha channel)
        if (feather > 0) {
            const blurredAlpha = new Uint8Array(alpha.length);
            const radius = Math.ceil(feather * 2);
            
            for (let y = 0; y < canvas.height; y++) {
                for (let x = 0; x < canvas.width; x++) {
                    let sum = 0;
                    let count = 0;
                    
                    for (let dy = -radius; dy <= radius; dy++) {
                        for (let dx = -radius; dx <= radius; dx++) {
                            const nx = x + dx;
                            const ny = y + dy;
                            
                            if (nx >= 0 && nx < canvas.width && ny >= 0 && ny < canvas.height) {
                                const distance = Math.sqrt(dx * dx + dy * dy);
                                if (distance <= radius) {
                                    const weight = Math.exp(-(dx * dx + dy * dy) / (2 * feather * feather));
                                    sum += alpha[ny * canvas.width + nx] * weight;
                                    count += weight;
                                }
                            }
                        }
                    }
                    
                    blurredAlpha[y * canvas.width + x] = clamp(Math.round(sum / count), 0, 255);
                }
            }
            
            // Copy blurred alpha back to original array
            for (let i = 0; i < alpha.length; i++) {
                alpha[i] = blurredAlpha[i];
            }
        }

        // Apply alpha channel to image data
        for (let i = 0; i < data.length; i += 4) {
            data[i + 3] = alpha[i / 4];
        }

        ctx.putImageData(imageData, 0, 0);

        // Get bounding box
        let minX = canvas.width, minY = canvas.height, maxX = 0, maxY = 0;
        let hasContent = false;

        for (let y = 0; y < canvas.height; y++) {
            for (let x = 0; x < canvas.width; x++) {
                if (alpha[y * canvas.width + x] > 0) {
                    hasContent = true;
                    minX = Math.min(minX, x);
                    minY = Math.min(minY, y);
                    maxX = Math.max(maxX, x);
                    maxY = Math.max(maxY, y);
                }
            }
        }

        // Crop if needed
        if (hasContent) {
            const width = maxX - minX + 1;
            const height = maxY - minY + 1;
            const croppedCanvas = createCanvas(width, height);
            const croppedCtx = croppedCanvas.getContext('2d');
            croppedCtx.drawImage(canvas, minX, minY, width, height, 0, 0, width, height);
            
            // Save as PNG
            const buffer = croppedCanvas.toBuffer('image/png');
            fs.writeFileSync(outFile, buffer);
            console.log(`${path.basename(filePath)} -> ${path.basename(outFile)} ${width}x${height} (${mode})`);
        } else {
            // Save as PNG
            const buffer = canvas.toBuffer('image/png');
            fs.writeFileSync(outFile, buffer);
            console.log(`${path.basename(filePath)} -> ${path.basename(outFile)} ${canvas.width}x${canvas.height} (${mode})`);
        }
    });
}

// Process all images
Promise.all([
    keyOut(`${BASE}/blaetter/12130585.webp`, `${OUT}/leaf-a.png`, "green"),
    keyOut(`${BASE}/blaetter/48178242.webp`, `${OUT}/leaf-b.png`, "white"),
    keyOut(`${BASE}/blueten/78370994.webp`, `${OUT}/blossom-a.png`, "white", 3.0),
    keyOut(`${BASE}/blueten/70017289.webp`, `${OUT}/blossom-b.png`, "white", 3.0)
]).then(() => {
    console.log("done");
}).catch(err => {
    console.error(err);
});
