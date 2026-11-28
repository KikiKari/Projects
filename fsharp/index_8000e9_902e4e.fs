// abstraction-provenance: {"artifact_sha256": "54db31c758b16b08d91d6478f1f5968b3d9fa2d27bbf0e4d7c0d471c3976e430", "source_sha256": "902e4e6fa157d8f76bb20b7b21eb51af1e266f087317cd16510ad7f701088c8a", "target_language": "fsharp"}
// index_8000e9.css — portiert nach fsharp
// Quelle: css, Projects@abstractions:css/index_8000e9.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

let generateCSS () =
    let root = """
:root {
  --bg: #FAF8F4;
  --ink: #1B1A17;
  --accent: #A8542F;
  --accent-2: #2E7D7B;
  --font-display: 'Newsreader', Georgia, serif;
  --font-body: 'Hanken Grotesk', -apple-system, sans-serif;
  --font-mono: 'JetBrains Mono', monospace;
}
"""
    
    let resetAndBase = """
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: var(--font-body);
  background: var(--bg);
  color: var(--ink);
  padding: 32px 16px 80px;
}

h1 {
  font-family: var(--font-display);
  font-weight: 500;
  font-size: 28px;
  max-width: 1400px;
  margin: 0 auto 12px;
}

.intro {
  max-width: 1400px;
  margin: 0 auto 32px;
  color: #666;
  font-size: 14px;
  line-height: 1.5;
}

.grid {
  display: grid;
  gap: 32px;
  max-width: 1400px;
  margin: 0 auto;
}

.variant {
  background: #000;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 12px 40px rgba(0,0,0,0.15);
}

.variant-header {
  background: #fff;
  padding: 16px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  border-bottom: 1px solid #eee;
}

.variant-label {
  font-family: var(--font-mono);
  font-size: 11px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: var(--accent);
  font-weight: 600;
}

.variant-title {
  font-family: var(--font-display);
  font-size: 20px;
  font-weight: 500;
}

.variant-desc {
  font-size: 13px;
  color: #666;
  flex: 1;
  text-align: right;
}

.scene {
  position: relative;
  aspect-ratio: 16 / 9;
  background: url('bg.png') center/cover no-repeat;
  overflow: hidden;
}

.orb {
  position: absolute;
  width: 12%;
  aspect-ratio: 1;
  left: 42%;
  top: 55%;
  transform: translate(-50%, -50%);
  cursor: pointer;
}

.orb img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}
"""
    
    let variant1 = """
/* Variante 1: Karte daneben */
.card-preview {
  position: absolute;
  left: 55%;
  top: 45%;
  background: rgba(255,255,255,0.98);
  padding: 16px 20px;
  border-radius: 12px;
  box-shadow: 0 8px 24px rgba(0,0,0,0.25);
  width: 240px;
  animation: slideIn 0.3s ease-out;
}

.card-preview .badge {
  display: inline-block;
  background: var(--accent-2);
  color: white;
  font-family: var(--font-mono);
  font-size: 9px;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  padding: 3px 8px;
  border-radius: 3px;
  margin-bottom: 8px;
}

.card-preview h3 {
  font-family: var(--font-display);
  font-size: 18px;
  font-weight: 500;
  margin-bottom: 6px;
  color: var(--ink);
}

.card-preview p {
  font-size: 12px;
  color: #555;
  line-height: 1.4;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateX(-8px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}
"""
    
    let variant2 = """
/* Variante 2: Minimaler Tooltip */
.tooltip {
  position: absolute;
  left: 42%;
  top: 46%;
  transform: translate(-50%, -100%);
  color: white;
  text-shadow: 0 2px 12px rgba(0,0,0,0.8);
  font-family: var(--font-display);
  font-size: 20px;
  font-weight: 500;
  white-space: nowrap;
  animation: fadeUp 0.3s ease-out;
}

@keyframes fadeUp {
  from {
    opacity: 0;
    transform: translate(-50%, -80%);
  }
  to {
    opacity: 1;
    transform: translate(-50%, -100%);
  }
}
"""
    
    let variant3 = """
/* Variante 3: Vollflächiges Overlay */
.full-overlay {
  position: absolute;
  inset: 0;
  background: rgba(0,0,0,0.5);
  backdrop-filter: blur(6px);
  display: flex;
  align-items: center;
  justify-content: center;
  animation: fadeIn 0.35s ease-out;
}

.full-overlay .panel {
  background: rgba(255,255,255,0.98);
  padding: 32px 40px;
  border-radius: 20px;
  max-width: 420px;
  box-shadow: 0 20px 60px rgba(0,0,0,0.4);
  text-align: center;
}

.full-overlay .badge {
  display: inline-block;
  background: var(--accent);
  color: white;
  font-family: var(--font-mono);
  font-size: 10px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  padding: 4px 10px;
  border-radius: 4px;
  margin-bottom: 14px;
}

.full-overlay h3 {
  font-family: var(--font-display);
  font-size: 28px;
  font-weight: 500;
  margin-bottom: 10px;
  color: var(--ink);
}

.full-overlay p {
  font-size: 14px;
  color: #555;
  line-height: 1.5;
  margin-bottom: 20px;
}

.full-overlay .preview-img {
  width: 100%;
  aspect-ratio: 16/10;
  background: linear-gradient(135deg, #A8542F, #2E7D7B);
  border-radius: 8px;
  margin-bottom: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-family: var(--font-mono);
  font-size: 11px;
  letter-spacing: 0.15em;
  opacity: 0.9;
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}
"""
    
    let instructionAndMedia = """
.instruction {
  text-align: center;
  color: #999;
  font-size: 12px;
  margin-top: 16px;
  font-family: var(--font-mono);
  letter-spacing: 0.15em;
  text-transform: uppercase;
}

@media (max-width: 900px) {
  .card-preview {
    width: 180px;
    padding: 12px 14px;
  }
  
  .card-preview h3 {
    font-size: 15px;
  }
  
  .card-preview p {
    font-size: 11px;
  }
  
  .tooltip {
    font-size: 15px;
  }
  
  .full-overlay .panel {
    padding: 20px 24px;
    max-width: 300px;
  }
  
  .full-overlay h3 {
    font-size: 20px;
  }
}
"""
    
    root + resetAndBase + variant1 + variant2 + variant3 + instructionAndMedia

[<EntryPoint>]
let main argv =
    let cssContent = generateCSS()
    match argv with
    | [||] -> 
        printfn "%s" cssContent
        0
    | [|filename|] -> 
        System.IO.File.WriteAllText(filename, cssContent)
        0
    | _ -> 
        printfn "Usage: program [<output-file>]"
        1
