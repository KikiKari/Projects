const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..", "..");
const assetRoot = path.join(root, "site", "public", "assets", "coauthoring-v7");
const assets = [
  "mobile-shazamkit-ios-android.png",
  "browser-observed-people.png",
  "browser-chat-top-chatter.png",
  "codex-security-scan.png",
  "coauthoring-v7-overview.png",
  "features-player-coral.png",
  "architecture-browser-coral.png",
  "installation-browser-coral.png",
  "overview-browser-coral.png",
  "features-player-cyan.png",
  "overview-browser-cyan.png",
  "installation-browser-tiktok.png",
  "architecture-browser-tiktok.png"
];

function read(relative) {
  return fs.readFileSync(path.join(root, relative), "utf8");
}

for (const name of assets) {
  const file = path.join(assetRoot, name);
  if (!fs.existsSync(file)) throw new Error(`Missing CoAuthoring asset: ${name}`);
  const signature = fs.readFileSync(file).subarray(0, 8).toString("hex");
  if (signature !== "89504e470d0a1a0a") throw new Error(`Not a valid PNG: ${name}`);
}

const galleryMarkdown = read("docs/coauthoring-v7.md");
const app = read("site/src/App.tsx");
for (const name of assets) {
  if (!galleryMarkdown.includes(name)) throw new Error(`Gallery markdown does not reference ${name}`);
  if (!app.includes(name)) throw new Error(`Website gallery does not reference ${name}`);
}

for (const diagram of ["architecture.mmd", "recognition-flow.mmd", "platform-deployment.mmd"]) {
  const source = read(`docs/diagrams/${diagram}`);
  if (!/^(flowchart|sequenceDiagram)/m.test(source)) throw new Error(`Unexpected Mermaid source: ${diagram}`);
}

const requiredExternalLinks = [
  "https://kikikari.github.io/OpenClaw/mcp-flow.html",
  "https://github.com/KikiKari/OpenClaw/blob/main/assets/gen_mcp_flow.py",
  "https://github.com/KikiKari/OpenClaw/blob/main/assets/gen_mcp_flow_gif.py"
];
for (const link of requiredExternalLinks) {
  if (!galleryMarkdown.includes(link) || !app.includes(link)) throw new Error(`Missing reproducibility link: ${link}`);
}

const reachability = read("docs/Links-und-Erreichbarkeiten_v7_utf8bom.md");
if (reachability.includes("Öffentlich sichtbar ist 0.5.0")) throw new Error("V7 reachability document still reports 0.5.0 as public");

console.log(`Documentation contract OK: ${assets.length} CoAuthoring images, 3 Mermaid sources, 3 reproducibility links.`);
