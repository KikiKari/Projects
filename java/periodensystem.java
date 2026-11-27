// abstraction-provenance: {"artifact_sha256": "29a51e0111229686ce28af3ff620d55b8f5bdb934233fedb0bd3585bd9e952b0", "source_sha256": "dd2fb3ad5bb22a75afbf2a71e58025215a6cba660525d3fa1c6b4ea12fc311fb", "target_language": "java"}
// periodensystem.html — portiert nach java
// Quelle: html, Onboarding@main:docs/reference-library/examples/periodensystem.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.util.*;

public class Periodensystem {
    private static final String[][] ELEMENTS = {
        {"1","H","Wasserstoff","1,008","nm","1","1"},{"2","He","Helium","4,003","eg","1","18"},
        {"3","Li","Lithium","6,94","am","2","1"},{"4","Be","Beryllium","9,012","em","2","2"},
        {"5","B","Bor","10,81","hm","2","13"},{"6","C","Kohlenstoff","12,011","nm","2","14"},
        {"7","N","Stickstoff","14,007","nm","2","15"},{"8","O","Sauerstoff","15,999","nm","2","16"},
        {"9","F","Fluor","18,998","h","2","17"},{"10","Ne","Neon","20,180","eg","2","18"},
        {"11","Na","Natrium","22,990","am","3","1"},{"12","Mg","Magnesium","24,305","em","3","2"},
        {"13","Al","Aluminium","26,982","ptm","3","13"},{"14","Si","Silicium","28,085","hm","3","14"},
        {"15","P","Phosphor","30,974","nm","3","15"},{"16","S","Schwefel","32,06","nm","3","16"},
        {"17","Cl","Chlor","35,45","h","3","17"},{"18","Ar","Argon","39,948","eg","3","18"},
        {"19","K","Kalium","39,098","am","4","1"},{"20","Ca","Calcium","40,078","em","4","2"},
        {"21","Sc","Scandium","44,956","tm","4","3"},{"22","Ti","Titan","47,867","tm","4","4"},
        {"23","V","Vanadium","50,942","tm","4","5"},{"24","Cr","Chrom","51,996","tm","4","6"},
        {"25","Mn","Mangan","54,938","tm","4","7"},{"26","Fe","Eisen","55,845","tm","4","8"},
        {"27","Co","Cobalt","58,933","tm","4","9"},{"28","Ni","Nickel","58,693","tm","4","10"},
        {"29","Cu","Kupfer","63,546","tm","4","11"},{"30","Zn","Zink","65,38","tm","4","12"},
        {"31","Ga","Gallium","69,723","ptm","4","13"},{"32","Ge","Germanium","72,630","hm","4","14"},
        {"33","As","Arsen","74,922","hm","4","15"},{"34","Se","Selen","78,971","nm","4","16"},
        {"35","Br","Brom","79,904","h","4","17"},{"36","Kr","Krypton","83,798","eg","4","18"},
        {"37","Rb","Rubidium","85,468","am","5","1"},{"38","Sr","Strontium","87,62","em","5","2"},
        {"39","Y","Yttrium","88,906","tm","5","3"},{"40","Zr","Zirconium","91,224","tm","5","4"},
        {"41","Nb","Niob","92,906","tm","5","5"},{"42","Mo","Molybdän","95,95","tm","5","6"},
        {"43","Tc","Technetium","98","tm","5","7"},{"44","Ru","Ruthenium","101,07","tm","5","8"},
        {"45","Rh","Rhodium","102,906","tm","5","9"},{"46","Pd","Palladium","106,42","tm","5","10"},
        {"47","Ag","Silber","107,868","tm","5","11"},{"48","Cd","Cadmium","112,414","tm","5","12"},
        {"49","In","Indium","114,818","ptm","5","13"},{"50","Sn","Zinn","118,710","ptm","5","14"},
        {"51","Sb","Antimon","121,760","hm","5","15"},{"52","Te","Tellur","127,60","hm","5","16"},
        {"53","I","Iod","126,904","h","5","17"},{"54","Xe","Xenon","131,293","eg","5","18"},
        {"55","Cs","Caesium","132,905","am","6","1"},{"56","Ba","Barium","137,327","em","6","2"},
        {"57","La","Lanthan","138,905","la","8","3"},{"58","Ce","Cer","140,116","la","8","4"},
        {"59","Pr","Praseodym","140,908","la","8","5"},{"60","Nd","Neodym","144,242","la","8","6"},
        {"61","Pm","Promethium","145","la","8","7"},{"62","Sm","Samarium","150,36","la","8","8"},
        {"63","Eu","Europium","151,964","la","8","9"},{"64","Gd","Gadolinium","157,25","la","8","10"},
        {"65","Tb","Terbium","158,925","la","8","11"},{"66","Dy","Dysprosium","162,500","la","8","12"},
        {"67","Ho","Holmium","164,930","la","8","13"},{"68","Er","Erbium","167,259","la","8","14"},
        {"69","Tm","Thulium","168,934","la","8","15"},{"70","Yb","Ytterbium","173,045","la","8","16"},
        {"71","Lu","Lutetium","174,967","la","8","17"},
        {"72","Hf","Hafnium","178,486","tm","6","4"},{"73","Ta","Tantal","180,948","tm","6","5"},
        {"74","W","Wolfram","183,84","tm","6","6"},{"75","Re","Rhenium","186,207","tm","6","7"},
        {"76","Os","Osmium","190,23","tm","6","8"},{"77","Ir","Iridium","192,217","tm","6","9"},
        {"78","Pt","Platin","195,084","tm","6","10"},{"79","Au","Gold","196,967","tm","6","11"},
        {"80","Hg","Quecksilber","200,592","tm","6","12"},{"81","Tl","Thallium","204,38","ptm","6","13"},
        {"82","Pb","Blei","207,2","ptm","6","14"},{"83","Bi","Bismut","208,980","ptm","6","15"},
        {"84","Po","Polonium","209","ptm","6","16"},{"85","At","Astat","210","h","6","17"},
        {"86","Rn","Radon","222","eg","6","18"},
        {"87","Fr","Francium","223","am","7","1"},{"88","Ra","Radium","226","em","7","2"},
        {"89","Ac","Actinium","227","ac","9","3"},{"90","Th","Thorium","232,038","ac","9","4"},
        {"91","Pa","Protactinium","231,036","ac","9","5"},{"92","U","Uran","238,029","ac","9","6"},
        {"93","Np","Neptunium","237","ac","9","7"},{"94","Pu","Plutonium","244","ac","9","8"},
        {"95","Am","Americium","243","ac","9","9"},{"96","Cm","Curium","247","ac","9","10"},
        {"97","Bk","Berkelium","247","ac","9","11"},{"98","Cf","Californium","251","ac","9","12"},
        {"99","Es","Einsteinium","252","ac","9","13"},{"100","Fm","Fermium","257","ac","9","14"},
        {"101","Md","Mendelevium","258","ac","9","15"},{"102","No","Nobelium","259","ac","9","16"},
        {"103","Lr","Lawrencium","266","ac","9","17"},
        {"104","Rf","Rutherfordium","267","tm","7","4"},{"105","Db","Dubnium","268","tm","7","5"},
        {"106","Sg","Seaborgium","269","tm","7","6"},{"107","Bh","Bohrium","270","tm","7","7"},
        {"108","Hs","Hassium","270","tm","7","8"},{"109","Mt","Meitnerium","278","tm","7","9"},
        {"110","Ds","Darmstadtium","281","tm","7","10"},{"111","Rg","Roentgenium","282","tm","7","11"},
        {"112","Cn","Copernicium","285","tm","7","12"},{"113","Nh","Nihonium","286","ptm","7","13"},
        {"114","Fl","Flerovium","289","ptm","7","14"},{"115","Mc","Moscovium","289","ptm","7","15"},
        {"116","Lv","Livermorium","293","ptm","7","16"},{"117","Ts","Tenness","294","h","7","17"},
        {"118","Og","Oganesson","294","eg","7","18"}
    };

    private static final Map<String, String> CATEGORY_NAMES = new HashMap<>();
    private static final Map<String, String> CATEGORY_NAMES_PLURAL = new HashMap<>();

    static {
        CATEGORY_NAMES.put("am", "Alkalimetall");
        CATEGORY_NAMES.put("em", "Erdalkalimetall");
        CATEGORY_NAMES.put("tm", "Übergangsmetall");
        CATEGORY_NAMES.put("ptm", "Metall (Hauptgr.)");
        CATEGORY_NAMES.put("hm", "Halbmetall");
        CATEGORY_NAMES.put("nm", "Nichtmetall");
        CATEGORY_NAMES.put("h", "Halogen");
        CATEGORY_NAMES.put("eg", "Edelgas");
        CATEGORY_NAMES.put("la", "Lanthanoid");
        CATEGORY_NAMES.put("ac", "Actinoid");

        CATEGORY_NAMES_PLURAL.put("am", "Alkalimetalle");
        CATEGORY_NAMES_PLURAL.put("em", "Erdalkalimetalle");
        CATEGORY_NAMES_PLURAL.put("tm", "Übergangsmetalle");
        CATEGORY_NAMES_PLURAL.put("ptm", "Metalle (Hauptgr.)");
        CATEGORY_NAMES_PLURAL.put("hm", "Halbmetalle");
        CATEGORY_NAMES_PLURAL.put("nm", "Nichtmetalle");
        CATEGORY_NAMES_PLURAL.put("h", "Halogene");
        CATEGORY_NAMES_PLURAL.put("eg", "Edelgase");
        CATEGORY_NAMES_PLURAL.put("la", "Lanthanoide");
        CATEGORY_NAMES_PLURAL.put("ac", "Actinoide");
    }

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Verwendung: java Periodensystem <ausgabedatei>");
            System.exit(1);
        }

        try (PrintWriter writer = new PrintWriter(new FileWriter(args[0]))) {
            generateHtml(writer);
        } catch (IOException e) {
            System.err.println("Fehler beim Schreiben der Datei: " + e.getMessage());
            System.exit(1);
        }
    }

    private static void generateHtml(PrintWriter writer) {
        writer.println("<!DOCTYPE html>");
        writer.println("<html lang=\"de\">");
        writer.println("<head>");
        writer.println("<meta charset=\"UTF-8\">");
        writer.println("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">");
        writer.println("<title>Interaktives Periodensystem</title>");
        writer.println("<style>");
        writer.println("* { box-sizing: border-box; margin: 0; padding: 0; }");
        writer.println(":root {");
        writer.println("  --bg: #fafaf7;");
        writer.println("  --surface: #ffffff;");
        writer.println("  --border: rgba(0,0,0,0.12);");
        writer.println("  --text: #1a1a1a;");
        writer.println("  --text-muted: #666;");
        writer.println("}");
        writer.println("@media (prefers-color-scheme: dark) {");
        writer.println("  :root {");
        writer.println("    --bg: #1a1a1a;");
        writer.println("    --surface: #242424;");
        writer.println("    --border: rgba(255,255,255,0.15);");
        writer.println("    --text: #f0f0f0;");
        writer.println("    --text-muted: #aaa;");
        writer.println("  }");
        writer.println("}");
        writer.println("body {");
        writer.println("  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;");
        writer.println("  background: var(--bg);");
        writer.println("  color: var(--text);");
        writer.println("  padding: 24px;");
        writer.println("  max-width: 1100px;");
        writer.println("  margin: 0 auto;");
        writer.println("  line-height: 1.5;");
        writer.println("}");
        writer.println("h1 { font-size: 22px; font-weight: 500; margin-bottom: 4px; }");
        writer.println(".subtitle { color: var(--text-muted); font-size: 14px; margin-bottom: 20px; }");
        writer.println(".detail {");
        writer.println("  background: var(--surface);");
        writer.println("  border: 1px solid var(--border);");
        writer.println("  border-radius: 12px;");
        writer.println("  padding: 16px 20px;");
        writer.println("  min-height: 110px;");
        writer.println("  display: flex;");
        writer.println("  align-items: center;");
        writer.println("  gap: 20px;");
        writer.println("  margin-bottom: 16px;");
        writer.println("}");
        writer.println(".detail-empty {");
        writer.println("  color: var(--text-muted);");
        writer.println("  font-size: 14px;");
        writer.println("  text-align: center;");
        writer.println("  width: 100%;");
        writer.println("}");
        writer.println(".symbol-box {");
        writer.println("  font-size: 40px;");
        writer.println("  font-weight: 500;");
        writer.println("  line-height: 1;");
        writer.println("  width: 80px;");
        writer.println("  height: 80px;");
        writer.println("  display: flex;");
        writer.println("  align-items: center;");
        writer.println("  justify-content: center;");
        writer.println("  border-radius: 8px;");
        writer.println("  flex-shrink: 0;");
        writer.println("}");
        writer.println(".info-name { font-size: 20px; font-weight: 500; margin-bottom: 8px; }");
        writer.println(".info-meta {");
        writer.println("  font-size: 13px;");
        writer.println("  color: var(--text-muted);");
        writer.println("  display: grid;");
        writer.println("  grid-template-columns: repeat(2, minmax(0, 1fr));");
        writer.println("  gap: 4px 24px;");
        writer.println("}");
        writer.println(".info-meta b { font-weight: 500; color: var(--text); margin-left: 6px; }");
        writer.println(".grid {");
        writer.println("  display: grid;");
        writer.println("  grid-template-columns: repeat(18, minmax(0, 1fr));");
        writer.println("  gap: 3px;");
        writer.println("}");
        writer.println(".fgrid { margin-top: 8px; }");
        writer.println(".cell {");
        writer.println("  aspect-ratio: 1;");
        writer.println("  border-radius: 4px;");
        writer.println("  padding: 3px;");
        writer.println("  display: flex;");
        writer.println("  flex-direction: column;");
        writer.println("  align-items: center;");
        writer.println("  justify-content: center;");
        writer.println("  cursor: pointer;");
        writer.println("  font-family: inherit;");
        writer.println("  line-height: 1;");
        writer.println("  transition: transform 0.12s ease;");
        writer.println("  border: 0;");
        writer.println("  position: relative;");
        writer.println("  overflow: hidden;");
        writer.println("}");
        writer.println(".cell:hover { transform: scale(1.18); z-index: 5; box-shadow: 0 2px 8px rgba(0,0,0,0.15); }");
        writer.println(".cell:focus-visible { outline: 2px solid var(--text); outline-offset: 1px; }");
        writer.println(".cell.active { outline: 2px solid var(--text); outline-offset: 1px; z-index: 4; }");
        writer.println(".cell .num { font-size: 9px; opacity: 0.75; align-self: flex-start; line-height: 1; padding-left: 2px; }");
        writer.println(".cell .sym { font-size: 14px; font-weight: 500; margin-top: 2px; }");
        writer.println(".cell-marker {");
        writer.println("  cursor: default;");
        writer.println("  font-size: 9px;");
        writer.println("  font-weight: 500;");
        writer.println("  border: 1px dashed currentColor;");
        writer.println("  background: transparent !important;");
        writer.println("}");
        writer.println(".cell-marker:hover { transform: none; box-shadow: none; }");
        writer.println(".cat-am { background: #FCEBEB; color: #501313; }");
        writer.println(".cat-em { background: #FAEEDA; color: #412402; }");
        writer.println(".cat-tm { background: #E6F1FB; color: #042C53; }");
        writer.println(".cat-ptm { background: #F1EFE8; color: #2C2C2A; }");
        writer.println(".cat-hm { background: #E1F5EE; color: #04342C; }");
        writer.println(".cat-nm { background: #EAF3DE; color: #173404; }");
        writer.println(".cat-h { background: #EEEDFE; color: #26215C; }");
        writer.println(".cat-eg { background: #FBEAF0; color: #4B1528; }");
        writer.println(".cat-la { background: #FAECE7; color: #4A1B0C; }");
        writer.println(".cat-ac { background: #F5C4B3; color: #4A1B0C; }");
        writer.println("@media (prefers-color-scheme: dark) {");
        writer.println("  .cat-am { background: #791F1F; color: #F7C1C1; }");
        writer.println("  .cat-em { background: #633806; color: #FAC775; }");
        writer.println("  .cat-tm { background: #0C447C; color: #B5D4F4; }");
        writer.println("  .cat-ptm { background: #444441; color: #D3D1C7; }");
        writer.println("  .cat-hm { background: #085041; color: #9FE1CB; }");
        writer.println("  .cat-nm { background: #27500A; color: #C0DD97; }");
        writer.println("  .cat-h { background: #3C3489; color: #CECBF6; }");
        writer.println("  .cat-eg { background: #72243E; color: #F4C0D1; }");
        writer.println("  .cat-la { background: #712B13; color: #F5C4B3; }");
        writer.println("  .cat-ac { background: #993C1D; color: #F5C4B3; }");
        writer.println("}");
        writer.println(".legend {");
        writer.println("  display: grid;");
        writer.println("  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));");
        writer.println("  gap: 8px 16px;");
        writer.println("  margin-top: 24px;");
        writer.println("  font-size: 12px;");
        writer.println("  color: var(--text-muted);");
        writer.println("}");
        writer.println(".legend-item { display: flex; align-items: center; gap: 8px; }");
        writer.println(".legend-swatch { width: 14px; height: 14px; border-radius: 3px; flex-shrink: 0; }");
        writer.println("</style>");
        writer.println("</head>");
        writer.println("<body>");
        writer.println("<h1>Periodensystem der Elemente</h1>");
        writer.println("<p class=\"subtitle\">Klicke auf ein Element, um Details zu sehen.</p>");
        writer.println("<div class=\"detail\" id=\"detail\"><div class=\"detail-empty\">Klicke auf ein Element, um Details zu sehen</div></div>");
        writer.println("<div class=\"grid\" id=\"main\"></div>");
        writer.println("<div class=\"grid fgrid\" id=\"fblock\"></div>");
        writer.println("<div class=\"legend\" id=\"legend\"></div>");
        writer.println("<script>");
        writer.println("const E = [");

        for (String[] element : ELEMENTS) {
            writer.print("  [" + String.join(",", Arrays.stream(element).map(s -> "'" + s + "'").toArray(String[]::new)) + "]");
            writer.println(",");
        }

        writer.println("];");
        writer.println("const CAT = " + mapToJson(CATEGORY_NAMES) + ";");
        writer.println("const CATPL = " + mapToJson(CATEGORY_NAMES_PLURAL) + ";");
        writer.println("function showDetail(el) {");
        writer.println("  const [z, sym, name, mass, cat, row, col] = el;");
        writer.println("  const period = row >= 8 ? (row === 8 ? 6 : 7) : row;");
        writer.println("  const group = row >= 8 ? 'f-Block' : col;");
        writer.println("  document.getElementById('detail').innerHTML = `");
        writer.println("    <div class=\"symbol-box cat-${cat}\">${sym}</div>");
        writer.println("    <div style=\"flex:1;min-width:0\">");
        writer.println("      <div class=\"info-name\">${name}</div>");
        writer.println("      <div class=\"info-meta\">");
        writer.println("        <span>Ordnungszahl:<b>${z}</b></span>");
        writer.println("        <span>Atommasse:<b>${mass} u</b></span>");
        writer.println("        <span>Periode:<b>${period}</b></span>");
        writer.println("        <span>Gruppe:<b>${group}</b></span>");
        writer.println("        <span style=\"grid-column:1/-1\">Kategorie:<b>${CAT[cat]}</b></span>");
        writer.println("      </div>");
        writer.println("    </div>`;");
        writer.println("  document.querySelectorAll('.cell.active').forEach(c => c.classList.remove('active'));");
        writer.println("  const cell = document.querySelector(`[data-z=\"${z}\"]`);");
        writer.println("  if (cell) cell.classList.add('active');");
        writer.println("}");
        writer.println("function makeCell(el) {");
        writer.println("  const [z, sym, name, mass, cat, row, col] = el;");
        writer.println("  const c = document.createElement('button');");
        writer.println("  c.className = `cell cat-${cat}`;");
        writer.println("  c.style.gridColumn = col;");
        writer.println("  c.style.gridRow = row >= 8 ? row - 7 : row;");
        writer.println("  c.dataset.z = z;");
        writer.println("  c.title = `${name} (${sym})`;");
        writer.println("  c.innerHTML = `<span class=\"num\">${z}</span><span class=\"sym\">${sym}</span>`;");
        writer.println("  c.onclick = () => showDetail(el);");
        writer.println("  return c;");
        writer.println("}");
        writer.println("const main = document.getElementById('main');");
        writer.println("const fblock = document.getElementById('fblock');");
        writer.println("[[6, 'la', '57-71'], [7, 'ac', '89-103']].forEach(([r, cat, txt]) => {");
        writer.println("  const m = document.createElement('div');");
        writer.println("  m.className = `cell cell-marker cat-${cat}`;");
        writer.println("  m.style.gridColumn = 3;");
        writer.println("  m.style.gridRow = r;");
        writer.println("  m.textContent = txt;");
        writer.println("  main.appendChild(m);");
        writer.println("});");
        writer.println("E.forEach(el => {");
        writer.println("  const c = makeCell(el);");
        writer.println("  if (el[5] >= 8) fblock.appendChild(c);");
        writer.println("  else main.appendChild(c);");
        writer.println("});");
        writer.println("const legend = document.getElementById('legend');");
        writer.println("Object.entries(CATPL).forEach(([k, v]) => {");
        writer.println("  const item = document.createElement('div');");
        writer.println("  item.className = 'legend-item';");
        writer.println("  item.innerHTML = `<span class=\"legend-swatch cat-${k}\"></span><span>${v}</span>`;");
        writer.println("  legend.appendChild(item);");
        writer.println("});");
        writer.println("</script>");
        writer.println("</body>");
        writer.println("</html>");
    }

    private static String mapToJson(Map<String, String> map) {
        StringBuilder sb = new StringBuilder();
        sb.append("{");
        boolean first = true;
        for (Map.Entry<String, String> entry : map.entrySet()) {
            if (!first) sb.append(",");
            sb.append(entry.getKey()).append(":\"").append(entry.getValue()).append("\"");
            first = false;
        }
        sb.append("}");
        return sb.toString();
    }
}
