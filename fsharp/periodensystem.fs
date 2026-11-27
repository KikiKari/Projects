// abstraction-provenance: {"artifact_sha256": "b0b81115feb79ea569c085629c1150a70a671c80a626a11e8de9d44970a1bd77", "source_sha256": "dd2fb3ad5bb22a75afbf2a71e58025215a6cba660525d3fa1c6b4ea12fc311fb", "target_language": "fsharp"}
// periodensystem.html — portiert nach fsharp
// Quelle: html, Onboarding@main:docs/reference-library/examples/periodensystem.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

open System
open System.IO
open System.Text

type Element = {
    AtomicNumber: int
    Symbol: string
    Name: string
    Mass: string
    Category: string
    Row: int
    Column: int
}

type CategoryInfo = {
    Singular: string
    Plural: string
}

let elements = [
    {AtomicNumber=1; Symbol="H"; Name="Wasserstoff"; Mass="1,008"; Category="nm"; Row=1; Column=1}
    {AtomicNumber=2; Symbol="He"; Name="Helium"; Mass="4,003"; Category="eg"; Row=1; Column=18}
    {AtomicNumber=3; Symbol="Li"; Name="Lithium"; Mass="6,94"; Category="am"; Row=2; Column=1}
    {AtomicNumber=4; Symbol="Be"; Name="Beryllium"; Mass="9,012"; Category="em"; Row=2; Column=2}
    {AtomicNumber=5; Symbol="B"; Name="Bor"; Mass="10,81"; Category="hm"; Row=2; Column=13}
    {AtomicNumber=6; Symbol="C"; Name="Kohlenstoff"; Mass="12,011"; Category="nm"; Row=2; Column=14}
    {AtomicNumber=7; Symbol="N"; Name="Stickstoff"; Mass="14,007"; Category="nm"; Row=2; Column=15}
    {AtomicNumber=8; Symbol="O"; Name="Sauerstoff"; Mass="15,999"; Category="nm"; Row=2; Column=16}
    {AtomicNumber=9; Symbol="F"; Name="Fluor"; Mass="18,998"; Category="h"; Row=2; Column=17}
    {AtomicNumber=10; Symbol="Ne"; Name="Neon"; Mass="20,180"; Category="eg"; Row=2; Column=18}
    {AtomicNumber=11; Symbol="Na"; Name="Natrium"; Mass="22,990"; Category="am"; Row=3; Column=1}
    {AtomicNumber=12; Symbol="Mg"; Name="Magnesium"; Mass="24,305"; Category="em"; Row=3; Column=2}
    {AtomicNumber=13; Symbol="Al"; Name="Aluminium"; Mass="26,982"; Category="ptm"; Row=3; Column=13}
    {AtomicNumber=14; Symbol="Si"; Name="Silicium"; Mass="28,085"; Category="hm"; Row=3; Column=14}
    {AtomicNumber=15; Symbol="P"; Name="Phosphor"; Mass="30,974"; Category="nm"; Row=3; Column=15}
    {AtomicNumber=16; Symbol="S"; Name="Schwefel"; Mass="32,06"; Category="nm"; Row=3; Column=16}
    {AtomicNumber=17; Symbol="Cl"; Name="Chlor"; Mass="35,45"; Category="h"; Row=3; Column=17}
    {AtomicNumber=18; Symbol="Ar"; Name="Argon"; Mass="39,948"; Category="eg"; Row=3; Column=18}
    {AtomicNumber=19; Symbol="K"; Name="Kalium"; Mass="39,098"; Category="am"; Row=4; Column=1}
    {AtomicNumber=20; Symbol="Ca"; Name="Calcium"; Mass="40,078"; Category="em"; Row=4; Column=2}
    {AtomicNumber=21; Symbol="Sc"; Name="Scandium"; Mass="44,956"; Category="tm"; Row=4; Column=3}
    {AtomicNumber=22; Symbol="Ti"; Name="Titan"; Mass="47,867"; Category="tm"; Row=4; Column=4}
    {AtomicNumber=23; Symbol="V"; Name="Vanadium"; Mass="50,942"; Category="tm"; Row=4; Column=5}
    {AtomicNumber=24; Symbol="Cr"; Name="Chrom"; Mass="51,996"; Category="tm"; Row=4; Column=6}
    {AtomicNumber=25; Symbol="Mn"; Name="Mangan"; Mass="54,938"; Category="tm"; Row=4; Column=7}
    {AtomicNumber=26; Symbol="Fe"; Name="Eisen"; Mass="55,845"; Category="tm"; Row=4; Column=8}
    {AtomicNumber=27; Symbol="Co"; Name="Cobalt"; Mass="58,933"; Category="tm"; Row=4; Column=9}
    {AtomicNumber=28; Symbol="Ni"; Name="Nickel"; Mass="58,693"; Category="tm"; Row=4; Column=10}
    {AtomicNumber=29; Symbol="Cu"; Name="Kupfer"; Mass="63,546"; Category="tm"; Row=4; Column=11}
    {AtomicNumber=30; Symbol="Zn"; Name="Zink"; Mass="65,38"; Category="tm"; Row=4; Column=12}
    {AtomicNumber=31; Symbol="Ga"; Name="Gallium"; Mass="69,723"; Category="ptm"; Row=4; Column=13}
    {AtomicNumber=32; Symbol="Ge"; Name="Germanium"; Mass="72,630"; Category="hm"; Row=4; Column=14}
    {AtomicNumber=33; Symbol="As"; Name="Arsen"; Mass="74,922"; Category="hm"; Row=4; Column=15}
    {AtomicNumber=34; Symbol="Se"; Name="Selen"; Mass="78,971"; Category="nm"; Row=4; Column=16}
    {AtomicNumber=35; Symbol="Br"; Name="Brom"; Mass="79,904"; Category="h"; Row=4; Column=17}
    {AtomicNumber=36; Symbol="Kr"; Name="Krypton"; Mass="83,798"; Category="eg"; Row=4; Column=18}
    {AtomicNumber=37; Symbol="Rb"; Name="Rubidium"; Mass="85,468"; Category="am"; Row=5; Column=1}
    {AtomicNumber=38; Symbol="Sr"; Name="Strontium"; Mass="87,62"; Category="em"; Row=5; Column=2}
    {AtomicNumber=39; Symbol="Y"; Name="Yttrium"; Mass="88,906"; Category="tm"; Row=5; Column=3}
    {AtomicNumber=40; Symbol="Zr"; Name="Zirconium"; Mass="91,224"; Category="tm"; Row=5; Column=4}
    {AtomicNumber=41; Symbol="Nb"; Name="Niob"; Mass="92,906"; Category="tm"; Row=5; Column=5}
    {AtomicNumber=42; Symbol="Mo"; Name="Molybdän"; Mass="95,95"; Category="tm"; Row=5; Column=6}
    {AtomicNumber=43; Symbol="Tc"; Name="Technetium"; Mass="98"; Category="tm"; Row=5; Column=7}
    {AtomicNumber=44; Symbol="Ru"; Name="Ruthenium"; Mass="101,07"; Category="tm"; Row=5; Column=8}
    {AtomicNumber=45; Symbol="Rh"; Name="Rhodium"; Mass="102,906"; Category="tm"; Row=5; Column=9}
    {AtomicNumber=46; Symbol="Pd"; Name="Palladium"; Mass="106,42"; Category="tm"; Row=5; Column=10}
    {AtomicNumber=47; Symbol="Ag"; Name="Silber"; Mass="107,868"; Category="tm"; Row=5; Column=11}
    {AtomicNumber=48; Symbol="Cd"; Name="Cadmium"; Mass="112,414"; Category="tm"; Row=5; Column=12}
    {AtomicNumber=49; Symbol="In"; Name="Indium"; Mass="114,818"; Category="ptm"; Row=5; Column=13}
    {AtomicNumber=50; Symbol="Sn"; Name="Zinn"; Mass="118,710"; Category="ptm"; Row=5; Column=14}
    {AtomicNumber=51; Symbol="Sb"; Name="Antimon"; Mass="121,760"; Category="hm"; Row=5; Column=15}
    {AtomicNumber=52; Symbol="Te"; Name="Tellur"; Mass="127,60"; Category="hm"; Row=5; Column=16}
    {AtomicNumber=53; Symbol="I"; Name="Iod"; Mass="126,904"; Category="h"; Row=5; Column=17}
    {AtomicNumber=54; Symbol="Xe"; Name="Xenon"; Mass="131,293"; Category="eg"; Row=5; Column=18}
    {AtomicNumber=55; Symbol="Cs"; Name="Caesium"; Mass="132,905"; Category="am"; Row=6; Column=1}
    {AtomicNumber=56; Symbol="Ba"; Name="Barium"; Mass="137,327"; Category="em"; Row=6; Column=2}
    {AtomicNumber=57; Symbol="La"; Name="Lanthan"; Mass="138,905"; Category="la"; Row=8; Column=3}
    {AtomicNumber=58; Symbol="Ce"; Name="Cer"; Mass="140,116"; Category="la"; Row=8; Column=4}
    {AtomicNumber=59; Symbol="Pr"; Name="Praseodym"; Mass="140,908"; Category="la"; Row=8; Column=5}
    {AtomicNumber=60; Symbol="Nd"; Name="Neodym"; Mass="144,242"; Category="la"; Row=8; Column=6}
    {AtomicNumber=61; Symbol="Pm"; Name="Promethium"; Mass="145"; Category="la"; Row=8; Column=7}
    {AtomicNumber=62; Symbol="Sm"; Name="Samarium"; Mass="150,36"; Category="la"; Row=8; Column=8}
    {AtomicNumber=63; Symbol="Eu"; Name="Europium"; Mass="151,964"; Category="la"; Row=8; Column=9}
    {AtomicNumber=64; Symbol="Gd"; Name="Gadolinium"; Mass="157,25"; Category="la"; Row=8; Column=10}
    {AtomicNumber=65; Symbol="Tb"; Name="Terbium"; Mass="158,925"; Category="la"; Row=8; Column=11}
    {AtomicNumber=66; Symbol="Dy"; Name="Dysprosium"; Mass="162,500"; Category="la"; Row=8; Column=12}
    {AtomicNumber=67; Symbol="Ho"; Name="Holmium"; Mass="164,930"; Category="la"; Row=8; Column=13}
    {AtomicNumber=68; Symbol="Er"; Name="Erbium"; Mass="167,259"; Category="la"; Row=8; Column=14}
    {AtomicNumber=69; Symbol="Tm"; Name="Thulium"; Mass="168,934"; Category="la"; Row=8; Column=15}
    {AtomicNumber=70; Symbol="Yb"; Name="Ytterbium"; Mass="173,045"; Category="la"; Row=8; Column=16}
    {AtomicNumber=71; Symbol="Lu"; Name="Lutetium"; Mass="174,967"; Category="la"; Row=8; Column=17}
    {AtomicNumber=72; Symbol="Hf"; Name="Hafnium"; Mass="178,486"; Category="tm"; Row=6; Column=4}
    {AtomicNumber=73; Symbol="Ta"; Name="Tantal"; Mass="180,948"; Category="tm"; Row=6; Column=5}
    {AtomicNumber=74; Symbol="W"; Name="Wolfram"; Mass="183,84"; Category="tm"; Row=6; Column=6}
    {AtomicNumber=75; Symbol="Re"; Name="Rhenium"; Mass="186,207"; Category="tm"; Row=6; Column=7}
    {AtomicNumber=76; Symbol="Os"; Name="Osmium"; Mass="190,23"; Category="tm"; Row=6; Column=8}
    {AtomicNumber=77; Symbol="Ir"; Name="Iridium"; Mass="192,217"; Category="tm"; Row=6; Column=9}
    {AtomicNumber=78; Symbol="Pt"; Name="Platin"; Mass="195,084"; Category="tm"; Row=6; Column=10}
    {AtomicNumber=79; Symbol="Au"; Name="Gold"; Mass="196,967"; Category="tm"; Row=6; Column=11}
    {AtomicNumber=80; Symbol="Hg"; Name="Quecksilber"; Mass="200,592"; Category="tm"; Row=6; Column=12}
    {AtomicNumber=81; Symbol="Tl"; Name="Thallium"; Mass="204,38"; Category="ptm"; Row=6; Column=13}
    {AtomicNumber=82; Symbol="Pb"; Name="Blei"; Mass="207,2"; Category="ptm"; Row=6; Column=14}
    {AtomicNumber=83; Symbol="Bi"; Name="Bismut"; Mass="208,980"; Category="ptm"; Row=6; Column=15}
    {AtomicNumber=84; Symbol="Po"; Name="Polonium"; Mass="209"; Category="ptm"; Row=6; Column=16}
    {AtomicNumber=85; Symbol="At"; Name="Astat"; Mass="210"; Category="h"; Row=6; Column=17}
    {AtomicNumber=86; Symbol="Rn"; Name="Radon"; Mass="222"; Category="eg"; Row=6; Column=18}
    {AtomicNumber=87; Symbol="Fr"; Name="Francium"; Mass="223"; Category="am"; Row=7; Column=1}
    {AtomicNumber=88; Symbol="Ra"; Name="Radium"; Mass="226"; Category="em"; Row=7; Column=2}
    {AtomicNumber=89; Symbol="Ac"; Name="Actinium"; Mass="227"; Category="ac"; Row=9; Column=3}
    {AtomicNumber=90; Symbol="Th"; Name="Thorium"; Mass="232,038"; Category="ac"; Row=9; Column=4}
    {AtomicNumber=91; Symbol="Pa"; Name="Protactinium"; Mass="231,036"; Category="ac"; Row=9; Column=5}
    {AtomicNumber=92; Symbol="U"; Name="Uran"; Mass="238,029"; Category="ac"; Row=9; Column=6}
    {AtomicNumber=93; Symbol="Np"; Name="Neptunium"; Mass="237"; Category="ac"; Row=9; Column=7}
    {AtomicNumber=94; Symbol="Pu"; Name="Plutonium"; Mass="244"; Category="ac"; Row=9; Column=8}
    {AtomicNumber=95; Symbol="Am"; Name="Americium"; Mass="243"; Category="ac"; Row=9; Column=9}
    {AtomicNumber=96; Symbol="Cm"; Name="Curium"; Mass="247"; Category="ac"; Row=9; Column=10}
    {AtomicNumber=97; Symbol="Bk"; Name="Berkelium"; Mass="247"; Category="ac"; Row=9; Column=11}
    {AtomicNumber=98; Symbol="Cf"; Name="Californium"; Mass="251"; Category="ac"; Row=9; Column=12}
    {AtomicNumber=99; Symbol="Es"; Name="Einsteinium"; Mass="252"; Category="ac"; Row=9; Column=13}
    {AtomicNumber=100; Symbol="Fm"; Name="Fermium"; Mass="257"; Category="ac"; Row=9; Column=14}
    {AtomicNumber=101; Symbol="Md"; Name="Mendelevium"; Mass="258"; Category="ac"; Row=9; Column=15}
    {AtomicNumber=102; Symbol="No"; Name="Nobelium"; Mass="259"; Category="ac"; Row=9; Column=16}
    {AtomicNumber=103; Symbol="Lr"; Name="Lawrencium"; Mass="266"; Category="ac"; Row=9; Column=17}
    {AtomicNumber=104; Symbol="Rf"; Name="Rutherfordium"; Mass="267"; Category="tm"; Row=7; Column=4}
    {AtomicNumber=105; Symbol="Db"; Name="Dubnium"; Mass="268"; Category="tm"; Row=7; Column=5}
    {AtomicNumber=106; Symbol="Sg"; Name="Seaborgium"; Mass="269"; Category="tm"; Row=7; Column=6}
    {AtomicNumber=107; Symbol="Bh"; Name="Bohrium"; Mass="270"; Category="tm"; Row=7; Column=7}
    {AtomicNumber=108; Symbol="Hs"; Name="Hassium"; Mass="270"; Category="tm"; Row=7; Column=8}
    {AtomicNumber=109; Symbol="Mt"; Name="Meitnerium"; Mass="278"; Category="tm"; Row=7; Column=9}
    {AtomicNumber=110; Symbol="Ds"; Name="Darmstadtium"; Mass="281"; Category="tm"; Row=7; Column=10}
    {AtomicNumber=111; Symbol="Rg"; Name="Roentgenium"; Mass="282"; Category="tm"; Row=7; Column=11}
    {AtomicNumber=112; Symbol="Cn"; Name="Copernicium"; Mass="285"; Category="tm"; Row=7; Column=12}
    {AtomicNumber=113; Symbol="Nh"; Name="Nihonium"; Mass="286"; Category="ptm"; Row=7; Column=13}
    {AtomicNumber=114; Symbol="Fl"; Name="Flerovium"; Mass="289"; Category="ptm"; Row=7; Column=14}
    {AtomicNumber=115; Symbol="Mc"; Name="Moscovium"; Mass="289"; Category="ptm"; Row=7; Column=15}
    {AtomicNumber=116; Symbol="Lv"; Name="Livermorium"; Mass="293"; Category="ptm"; Row=7; Column=16}
    {AtomicNumber=117; Symbol="Ts"; Name="Tenness"; Mass="294"; Category="h"; Row=7; Column=17}
    {AtomicNumber=118; Symbol="Og"; Name="Oganesson"; Mass="294"; Category="eg"; Row=7; Column=18}
]

let categories = Map [
    ("am", {Singular = "Alkalimetall"; Plural = "Alkalimetalle"})
    ("em", {Singular = "Erdalkalimetall"; Plural = "Erdalkalimetalle"})
    ("tm", {Singular = "Übergangsmetall"; Plural = "Übergangsmetalle"})
    ("ptm", {Singular = "Metall (Hauptgr.)"; Plural = "Metalle (Hauptgr.)"})
    ("hm", {Singular = "Halbmetall"; Plural = "Halbmetalle"})
    ("nm", {Singular = "Nichtmetall"; Plural = "Nichtmetalle"})
    ("h", {Singular = "Halogen"; Plural = "Halogene"})
    ("eg", {Singular = "Edelgas"; Plural = "Edelgase"})
    ("la", {Singular = "Lanthanoid"; Plural = "Lanthanoide"})
    ("ac", {Singular = "Actinoid"; Plural = "Actinoide"})
]

let css = """
* { box-sizing: border-box; margin: 0; padding: 0; }
:root {
  --bg: #fafaf7;
  --surface: #ffffff;
  --border: rgba(0,0,0,0.12);
  --text: #1a1a1a;
  --text-muted: #666;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #1a1a1a;
    --surface: #242424;
    --border: rgba(255,255,255,0.15);
    --text: #f0f0f0;
    --text-muted: #aaa;
  }
}
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
  background: var(--bg);
  color: var(--text);
  padding: 24px;
  max-width: 1100px;
  margin: 0 auto;
  line-height: 1.5;
}
h1 { font-size: 22px; font-weight: 500; margin-bottom: 4px; }
.subtitle { color: var(--text-muted); font-size: 14px; margin-bottom: 20px; }
.detail {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 16px 20px;
  min-height: 110px;
  display: flex;
  align-items: center;
  gap: 20px;
  margin-bottom: 16px;
}
.detail-empty {
  color: var(--text-muted);
  font-size: 14px;
  text-align: center;
  width: 100%;
}
.symbol-box {
  font-size: 40px;
  font-weight: 500;
  line-height: 1;
  width: 80px;
  height: 80px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 8px;
  flex-shrink: 0;
}
.info-name { font-size: 20px; font-weight: 500; margin-bottom: 8px; }
.info-meta {
  font-size: 13px;
  color: var(--text-muted);
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 4px 24px;
}
.info-meta b { font-weight: 500; color: var(--text); margin-left: 6px; }
.grid {
  display: grid;
  grid-template-columns: repeat(18, minmax(0, 1fr));
  gap: 3px;
}
.fgrid { margin-top: 8px; }
.cell {
  aspect-ratio: 1;
  border-radius: 4px;
  padding: 3px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-family: inherit;
  line-height: 1;
  transition: transform 0.12s ease;
  border: 0;
  position: relative;
  overflow: hidden;
}
.cell:hover { transform: scale(1.18); z-index: 5; box-shadow: 0 2px 8px rgba(0,0,0,0.15); }
.cell:focus-visible { outline: 2px solid var(--text); outline-offset: 1px; }
.cell.active { outline: 2px solid var(--text); outline-offset: 1px; z-index: 4; }
.cell .num { font-size: 9px; opacity: 0.75; align-self: flex-start; line-height: 1; padding-left: 2px; }
.cell .sym { font-size: 14px; font-weight: 500; margin-top: 2px; }
.cell-marker {
  cursor: default;
  font-size: 9px;
  font-weight: 500;
  border: 1px dashed currentColor;
  background: transparent !important;
}
.cell-marker:hover { transform: none; box-shadow: none; }
.cat-am { background: #FCEBEB; color: #501313; }
.cat-em { background: #FAEEDA; color: #412402; }
.cat-tm { background: #E6F1FB; color: #042C53; }
.cat-ptm { background: #F1EFE8; color: #2C2C2A; }
.cat-hm { background: #E1F5EE; color: #04342C; }
.cat-nm { background: #EAF3DE; color: #173404; }
.cat-h { background: #EEEDFE; color: #26215C; }
.cat-eg { background: #FBEAF0; color: #4B1528; }
.cat-la { background: #FAECE7; color: #4A1B0C; }
.cat-ac { background: #F5C4B3; color: #4A1B0C; }
@media (prefers-color-scheme: dark) {
  .cat-am { background: #791F1F; color: #F7C1C1; }
  .cat-em { background: #633806; color: #FAC775; }
  .cat-tm { background: #0C447C; color: #B5D4F4; }
  .cat-ptm { background: #444441; color: #D3D1C7; }
  .cat-hm { background: #085041; color: #9FE1CB; }
  .cat-nm { background: #27500A; color: #C0DD97; }
  .cat-h { background: #3C3489; color: #CECBF6; }
  .cat-eg { background: #72243E; color: #F4C0D1; }
  .cat-la { background: #712B13; color: #F5C4B3; }
  .cat-ac { background: #993C1D; color: #F5C4B3; }
}
.legend {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: 8px 16px;
  margin-top: 24px;
  font-size: 12px;
  color: var(--text-muted);
}
.legend-item { display: flex; align-items: center; gap: 8px; }
.legend-swatch { width: 14px; height: 14px; border-radius: 3px; flex-shrink: 0; }
"""

let generateHtml() =
    let sb = StringBuilder()
    sb.AppendLine("<!DOCTYPE html>") |> ignore
    sb.AppendLine("<html lang=\"de\">") |> ignore
    sb.AppendLine("<head>") |> ignore
    sb.AppendLine("<meta charset=\"UTF-8\">") |> ignore
    sb.AppendLine("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">") |> ignore
    sb.AppendLine("<title>Interaktives Periodensystem</title>") |> ignore
    sb.AppendLine("<style>") |> ignore
    sb.Append(css) |> ignore
    sb.AppendLine("</style>") |> ignore
    sb.AppendLine("</head>") |> ignore
    sb.AppendLine("<body>") |> ignore
    sb.AppendLine("<h1>Periodensystem der Elemente</h1>") |> ignore
    sb.AppendLine("<p class=\"subtitle\">Klicke auf ein Element, um Details zu sehen.</p>") |> ignore
    sb.AppendLine("<div class=\"detail\" id=\"detail\"><div class=\"detail-empty\">Klicke auf ein Element, um Details zu sehen</div></div>") |> ignore
    sb.AppendLine("<div class=\"grid\" id=\"main\"></div>") |> ignore
    sb.AppendLine("<div class=\"grid fgrid\" id=\"fblock\"></div>") |> ignore
    sb.AppendLine("<div class=\"legend\" id=\"legend\"></div>") |> ignore
    
    // JavaScript section
    sb.AppendLine("<script>") |> ignore
    sb.AppendLine("const E = [") |> ignore
    
    for i, el in elements |> List.mapi (fun i x -> (i, x)) do
        let comma = if i < elements.Length - 1 then "," else ""
        sb.AppendFormat("  [{0},'{1}','{2}','{3}','{4}',{5},{6}]{7}\n", 
            el.AtomicNumber, el.Symbol, el.Name, el.Mass, el.Category, el.Row, el.Column, comma) |> ignore
    
    sb.AppendLine("];") |> ignore
    sb.AppendLine("const CAT = {") |> ignore
    
    let catEntries = categories 
                     |> Map.toList 
                     |> List.map (fun (key, info) -> sprintf "  %s:'%s'" key info.Singular)
    sb.AppendLine(String.Join(",\n", catEntries)) |> ignore
    sb.AppendLine("};") |> ignore
    sb.AppendLine("const CATPL = {") |> ignore
    
    let catPlEntries = categories 
                      |> Map.toList 
                      |> List.map (fun (key, info) -> sprintf "  %s:'%s'" key info.Plural)
    sb.AppendLine(String.Join(",\n", catPlEntries)) |> ignore
    sb.AppendLine("};") |> ignore
    
    sb.AppendLine("""
function showDetail(el) {
  const [z, sym, name, mass, cat, row, col] = el;
  const period = row >= 8 ? (row === 8 ? 6 : 7) : row;
  const group = row >= 8 ? 'f-Block' : col;
  document.getElementById('detail').innerHTML = `
    <div class="symbol-box cat-${cat}">${sym}</div>
    <div style="flex:1;min-width:0">
      <div class="info-name">${name}</div>
      <div class="info-meta">
        <span>Ordnungszahl:<b>${z}</b></span>
        <span>Atommasse:<b>${mass} u</b></span>
        <span>Periode:<b>${period}</b></span>
        <span>Gruppe:<b>${group}</b></span>
        <span style="grid-column:1/-1">Kategorie:<b>${CAT[cat]}</b></span>
      </div>
    </div>`;
  document.querySelectorAll('.cell.active').forEach(c => c.classList.remove('active'));
  const cell = document.querySelector(`[data-z="${z}"]`);
  if (cell) cell.classList.add('active');
}
function makeCell(el) {
  const [z, sym, name, mass, cat, row, col] = el;
  const c = document.createElement('button');
  c.className = `cell cat-${cat}`;
  c.style.gridColumn = col;
  c.style.gridRow = row >= 8 ? row - 7 : row;
  c.dataset.z = z;
  c.title = `${name} (${sym})`;
  c.innerHTML = `<span class="num">${z}</span><span class="sym">${sym}</span>`;
  c.onclick = () => showDetail(el);
  return c;
}
const main = document.getElementById('main');
const fblock = document.getElementById('fblock');
[[6, 'la', '57-71'], [7, 'ac', '89-103']].forEach(([r, cat, txt]) => {
  const m = document.createElement('div');
  m.className = `cell cell-marker cat-${cat}`;
  m.style.gridColumn = 3;
  m.style.gridRow = r;
  m.textContent = txt;
  main.appendChild(m);
});
E.forEach(el => {
  const c = makeCell(el);
  if (el[5] >= 8) fblock.appendChild(c);
  else main.appendChild(c);
});
const legend = document.getElementById('legend');
Object.entries(CATPL).forEach(([k, v]) => {
  const item = document.createElement('div');
  item.className = 'legend-item';
  item.innerHTML = `<span class="legend-swatch cat-${k}"></span><span>${v}</span>`;
  legend.appendChild(item);
});
""") |> ignore
    
    sb.AppendLine("</script>") |> ignore
    sb.AppendLine("</body>") |> ignore
    sb.AppendLine("</html>") |> ignore
    sb.ToString()

[<EntryPoint>]
let main argv =
    let outputPath = 
        if argv.Length > 0 then argv.[0] 
        else "periodensystem.html"
    
    let htmlContent = generateHtml()
    File.WriteAllText(outputPath, htmlContent, Encoding.UTF8)
    printfn "HTML file generated: %s" outputPath
    0
