// abstraction-provenance: {"artifact_sha256": "87fe0b2ed0b25e3cb831d41c7037c390bd87a66756b8c1f20d3d4ab58b3c62e4", "source_sha256": "dd2fb3ad5bb22a75afbf2a71e58025215a6cba660525d3fa1c6b4ea12fc311fb", "target_language": "c"}
// periodensystem.html — portiert nach c
// Quelle: html, Onboarding@main:docs/reference-library/examples/periodensystem.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Elementdatenstruktur
typedef struct {
    int z;           // Ordnungszahl
    char sym[3];     // Symbol
    char name[20];   // Name
    char mass[10];   // Atommasse
    char cat[4];     // Kategorie
    int row;         // Reihe
    int col;         // Spalte
} Element;

// Kategorien
typedef struct {
    char key[4];
    char name[25];
    char namePlural[20];
    char bgColorLight[20];
    char textColorLight[20];
    char bgColorDark[20];
    char textColorDark[20];
} Category;

// Globale Variablen
Element elements[] = {
    {1,"H","Wasserstoff","1,008","nm",1,1},{2,"He","Helium","4,003","eg",1,18},
    {3,"Li","Lithium","6,94","am",2,1},{4,"Be","Beryllium","9,012","em",2,2},
    {5,"B","Bor","10,81","hm",2,13},{6,"C","Kohlenstoff","12,011","nm",2,14},
    {7,"N","Stickstoff","14,007","nm",2,15},{8,"O","Sauerstoff","15,999","nm",2,16},
    {9,"F","Fluor","18,998","h",2,17},{10,"Ne","Neon","20,180","eg",2,18},
    {11,"Na","Natrium","22,990","am",3,1},{12,"Mg","Magnesium","24,305","em",3,2},
    {13,"Al","Aluminium","26,982","ptm",3,13},{14,"Si","Silicium","28,085","hm",3,14},
    {15,"P","Phosphor","30,974","nm",3,15},{16,"S","Schwefel","32,06","nm",3,16},
    {17,"Cl","Chlor","35,45","h",3,17},{18,"Ar","Argon","39,948","eg",3,18},
    {19,"K","Kalium","39,098","am",4,1},{20,"Ca","Calcium","40,078","em",4,2},
    {21,"Sc","Scandium","44,956","tm",4,3},{22,"Ti","Titan","47,867","tm",4,4},
    {23,"V","Vanadium","50,942","tm",4,5},{24,"Cr","Chrom","51,996","tm",4,6},
    {25,"Mn","Mangan","54,938","tm",4,7},{26,"Fe","Eisen","55,845","tm",4,8},
    {27,"Co","Cobalt","58,933","tm",4,9},{28,"Ni","Nickel","58,693","tm",4,10},
    {29,"Cu","Kupfer","63,546","tm",4,11},{30,"Zn","Zink","65,38","tm",4,12},
    {31,"Ga","Gallium","69,723","ptm",4,13},{32,"Ge","Germanium","72,630","hm",4,14},
    {33,"As","Arsen","74,922","hm",4,15},{34,"Se","Selen","78,971","nm",4,16},
    {35,"Br","Brom","79,904","h",4,17},{36,"Kr","Krypton","83,798","eg",4,18},
    {37,"Rb","Rubidium","85,468","am",5,1},{38,"Sr","Strontium","87,62","em",5,2},
    {39,"Y","Yttrium","88,906","tm",5,3},{40,"Zr","Zirconium","91,224","tm",5,4},
    {41,"Nb","Niob","92,906","tm",5,5},{42,"Mo","Molybdän","95,95","tm",5,6},
    {43,"Tc","Technetium","98","tm",5,7},{44,"Ru","Ruthenium","101,07","tm",5,8},
    {45,"Rh","Rhodium","102,906","tm",5,9},{46,"Pd","Palladium","106,42","tm",5,10},
    {47,"Ag","Silber","107,868","tm",5,11},{48,"Cd","Cadmium","112,414","tm",5,12},
    {49,"In","Indium","114,818","ptm",5,13},{50,"Sn","Zinn","118,710","ptm",5,14},
    {51,"Sb","Antimon","121,760","hm",5,15},{52,"Te","Tellur","127,60","hm",5,16},
    {53,"I","Iod","126,904","h",5,17},{54,"Xe","Xenon","131,293","eg",5,18},
    {55,"Cs","Caesium","132,905","am",6,1},{56,"Ba","Barium","137,327","em",6,2},
    {57,"La","Lanthan","138,905","la",8,3},{58,"Ce","Cer","140,116","la",8,4},
    {59,"Pr","Praseodym","140,908","la",8,5},{60,"Nd","Neodym","144,242","la",8,6},
    {61,"Pm","Promethium","145","la",8,7},{62,"Sm","Samarium","150,36","la",8,8},
    {63,"Eu","Europium","151,964","la",8,9},{64,"Gd","Gadolinium","157,25","la",8,10},
    {65,"Tb","Terbium","158,925","la",8,11},{66,"Dy","Dysprosium","162,500","la",8,12},
    {67,"Ho","Holmium","164,930","la",8,13},{68,"Er","Erbium","167,259","la",8,14},
    {69,"Tm","Thulium","168,934","la",8,15},{70,"Yb","Ytterbium","173,045","la",8,16},
    {71,"Lu","Lutetium","174,967","la",8,17},
    {72,"Hf","Hafnium","178,486","tm",6,4},{73,"Ta","Tantal","180,948","tm",6,5},
    {74,"W","Wolfram","183,84","tm",6,6},{75,"Re","Rhenium","186,207","tm",6,7},
    {76,"Os","Osmium","190,23","tm",6,8},{77,"Ir","Iridium","192,217","tm",6,9},
    {78,"Pt","Platin","195,084","tm",6,10},{79,"Au","Gold","196,967","tm",6,11},
    {80,"Hg","Quecksilber","200,592","tm",6,12},{81,"Tl","Thallium","204,38","ptm",6,13},
    {82,"Pb","Blei","207,2","ptm",6,14},{83,"Bi","Bismut","208,980","ptm",6,15},
    {84,"Po","Polonium","209","ptm",6,16},{85,"At","Astat","210","h",6,17},
    {86,"Rn","Radon","222","eg",6,18},
    {87,"Fr","Francium","223","am",7,1},{88,"Ra","Radium","226","em",7,2},
    {89,"Ac","Actinium","227","ac",9,3},{90,"Th","Thorium","232,038","ac",9,4},
    {91,"Pa","Protactinium","231,036","ac",9,5},{92,"U","Uran","238,029","ac",9,6},
    {93,"Np","Neptunium","237","ac",9,7},{94,"Pu","Plutonium","244","ac",9,8},
    {95,"Am","Americium","243","ac",9,9},{96,"Cm","Curium","247","ac",9,10},
    {97,"Bk","Berkelium","247","ac",9,11},{98,"Cf","Californium","251","ac",9,12},
    {99,"Es","Einsteinium","252","ac",9,13},{100,"Fm","Fermium","257","ac",9,14},
    {101,"Md","Mendelevium","258","ac",9,15},{102,"No","Nobelium","259","ac",9,16},
    {103,"Lr","Lawrencium","266","ac",9,17},
    {104,"Rf","Rutherfordium","267","tm",7,4},{105,"Db","Dubnium","268","tm",7,5},
    {106,"Sg","Seaborgium","269","tm",7,6},{107,"Bh","Bohrium","270","tm",7,7},
    {108,"Hs","Hassium","270","tm",7,8},{109,"Mt","Meitnerium","278","tm",7,9},
    {110,"Ds","Darmstadtium","281","tm",7,10},{111,"Rg","Roentgenium","282","tm",7,11},
    {112,"Cn","Copernicium","285","tm",7,12},{113,"Nh","Nihonium","286","ptm",7,13},
    {114,"Fl","Flerovium","289","ptm",7,14},{115,"Mc","Moscovium","289","ptm",7,15},
    {116,"Lv","Livermorium","293","ptm",7,16},{117,"Ts","Tenness","294","h",7,17},
    {118,"Og","Oganesson","294","eg",7,18}
};

int elements_count = sizeof(elements)/sizeof(elements[0]);

Category categories[] = {
    {"am", "Alkalimetall", "Alkalimetalle", "#FCEBEB", "#501313", "#791F1F", "#F7C1C1"},
    {"em", "Erdalkalimetall", "Erdalkalimetalle", "#FAEEDA", "#412402", "#633806", "#FAC775"},
    {"tm", "Übergangsmetall", "Übergangsmetalle", "#E6F1FB", "#042C53", "#0C447C", "#B5D4F4"},
    {"ptm", "Metall (Hauptgr.)", "Metalle (Hauptgr.)", "#F1EFE8", "#2C2C2A", "#444441", "#D3D1C7"},
    {"hm", "Halbmetall", "Halbmetalle", "#E1F5EE", "#04342C", "#085041", "#9FE1CB"},
    {"nm", "Nichtmetall", "Nichtmetalle", "#EAF3DE", "#173404", "#27500A", "#C0DD97"},
    {"h", "Halogen", "Halogene", "#EEEDFE", "#26215C", "#3C3489", "#CECBF6"},
    {"eg", "Edelgas", "Edelgase", "#FBEAF0", "#4B1528", "#72243E", "#F4C0D1"},
    {"la", "Lanthanoid", "Lanthanoide", "#FAECE7", "#4A1B0C", "#712B13", "#F5C4B3"},
    {"ac", "Actinoid", "Actinoide", "#F5C4B3", "#4A1B0C", "#993C1D", "#F5C4B3"}
};

int categories_count = sizeof(categories)/sizeof(categories[0]);

// Funktion zur Ausgabe des HTML-Headers
void print_html_header(FILE *file) {
    fprintf(file, "<!DOCTYPE html>\n");
    fprintf(file, "<html lang=\"de\">\n");
    fprintf(file, "<head>\n");
    fprintf(file, "<meta charset=\"UTF-8\">\n");
    fprintf(file, "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n");
    fprintf(file, "<title>Interaktives Periodensystem</title>\n");
    fprintf(file, "<style>\n");
    fprintf(file, "* { box-sizing: border-box; margin: 0; padding: 0; }\n");
    fprintf(file, ":root {\n");
    fprintf(file, "  --bg: #fafaf7;\n");
    fprintf(file, "  --surface: #ffffff;\n");
    fprintf(file, "  --border: rgba(0,0,0,0.12);\n");
    fprintf(file, "  --text: #1a1a1a;\n");
    fprintf(file, "  --text-muted: #666;\n");
    fprintf(file, "}\n");
    fprintf(file, "@media (prefers-color-scheme: dark) {\n");
    fprintf(file, "  :root {\n");
    fprintf(file, "    --bg: #1a1a1a;\n");
    fprintf(file, "    --surface: #242424;\n");
    fprintf(file, "    --border: rgba(255,255,255,0.15);\n");
    fprintf(file, "    --text: #f0f0f0;\n");
    fprintf(file, "    --text-muted: #aaa;\n");
    fprintf(file, "  }\n");
    fprintf(file, "}\n");
    fprintf(file, "body {\n");
    fprintf(file, "  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;\n");
    fprintf(file, "  background: var(--bg);\n");
    fprintf(file, "  color: var(--text);\n");
    fprintf(file, "  padding: 24px;\n");
    fprintf(file, "  max-width: 1100px;\n");
    fprintf(file, "  margin: 0 auto;\n");
    fprintf(file, "  line-height: 1.5;\n");
    fprintf(file, "}\n");
    fprintf(file, "h1 { font-size: 22px; font-weight: 500; margin-bottom: 4px; }\n");
    fprintf(file, ".subtitle { color: var(--text-muted); font-size: 14px; margin-bottom: 20px; }\n");
    fprintf(file, ".detail {\n");
    fprintf(file, "  background: var(--surface);\n");
    fprintf(file, "  border: 1px solid var(--border);\n");
    fprintf(file, "  border-radius: 12px;\n");
    fprintf(file, "  padding: 16px 20px;\n");
    fprintf(file, "  min-height: 110px;\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  gap: 20px;\n");
    fprintf(file, "  margin-bottom: 16px;\n");
    fprintf(file, "}\n");
    fprintf(file, ".detail-empty {\n");
    fprintf(file, "  color: var(--text-muted);\n");
    fprintf(file, "  font-size: 14px;\n");
    fprintf(file, "  text-align: center;\n");
    fprintf(file, "  width: 100%%;\n");
    fprintf(file, "}\n");
    fprintf(file, ".symbol-box {\n");
    fprintf(file, "  font-size: 40px;\n");
    fprintf(file, "  font-weight: 500;\n");
    fprintf(file, "  line-height: 1;\n");
    fprintf(file, "  width: 80px;\n");
    fprintf(file, "  height: 80px;\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  justify-content: center;\n");
    fprintf(file, "  border-radius: 8px;\n");
    fprintf(file, "  flex-shrink: 0;\n");
    fprintf(file, "}\n");
    fprintf(file, ".info-name { font-size: 20px; font-weight: 500; margin-bottom: 8px; }\n");
    fprintf(file, ".info-meta {\n");
    fprintf(file, "  font-size: 13px;\n");
    fprintf(file, "  color: var(--text-muted);\n");
    fprintf(file, "  display: grid;\n");
    fprintf(file, "  grid-template-columns: repeat(2, minmax(0, 1fr));\n");
    fprintf(file, "  gap: 4px 24px;\n");
    fprintf(file, "}\n");
    fprintf(file, ".info-meta b { font-weight: 500; color: var(--text); margin-left: 6px; }\n");
    fprintf(file, ".grid {\n");
    fprintf(file, "  display: grid;\n");
    fprintf(file, "  grid-template-columns: repeat(18, minmax(0, 1fr));\n");
    fprintf(file, "  gap: 3px;\n");
    fprintf(file, "}\n");
    fprintf(file, ".fgrid { margin-top: 8px; }\n");
    fprintf(file, ".cell {\n");
    fprintf(file, "  aspect-ratio: 1;\n");
    fprintf(file, "  border-radius: 4px;\n");
    fprintf(file, "  padding: 3px;\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  flex-direction: column;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  justify-content: center;\n");
    fprintf(file, "  cursor: pointer;\n");
    fprintf(file, "  font-family: inherit;\n");
    fprintf(file, "  line-height: 1;\n");
    fprintf(file, "  transition: transform 0.12s ease;\n");
    fprintf(file, "  border: 0;\n");
    fprintf(file, "  position: relative;\n");
    fprintf(file, "  overflow: hidden;\n");
    fprintf(file, "}\n");
    fprintf(file, ".cell:hover { transform: scale(1.18); z-index: 5; box-shadow: 0 2px 8px rgba(0,0,0,0.15); }\n");
    fprintf(file, ".cell:focus-visible { outline: 2px solid var(--text); outline-offset: 1px; }\n");
    fprintf(file, ".cell.active { outline: 2px solid var(--text); outline-offset: 1px; z-index: 4; }\n");
    fprintf(file, ".cell .num { font-size: 9px; opacity: 0.75; align-self: flex-start; line-height: 1; padding-left: 2px; }\n");
    fprintf(file, ".cell .sym { font-size: 14px; font-weight: 500; margin-top: 2px; }\n");
    fprintf(file, ".cell-marker {\n");
    fprintf(file, "  cursor: default;\n");
    fprintf(file, "  font-size: 9px;\n");
    fprintf(file, "  font-weight: 500;\n");
    fprintf(file, "  border: 1px dashed currentColor;\n");
    fprintf(file, "  background: transparent !important;\n");
    fprintf(file, "}\n");
    fprintf(file, ".cell-marker:hover { transform: none; box-shadow: none; }\n");
    
    // Dynamische CSS-Klassen für Kategorien
    for(int i = 0; i < categories_count; i++) {
        fprintf(file, ".cat-%s { background: %s; color: %s; }\n", 
                categories[i].key, categories[i].bgColorLight, categories[i].textColorLight);
    }
    
    fprintf(file, "@media (prefers-color-scheme: dark) {\n");
    for(int i = 0; i < categories_count; i++) {
        fprintf(file, "  .cat-%s { background: %s; color: %s; }\n", 
                categories[i].key, categories[i].bgColorDark, categories[i].textColorDark);
    }
    fprintf(file, "}\n");
    
    fprintf(file, ".legend {\n");
    fprintf(file, "  display: grid;\n");
    fprintf(file, "  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));\n");
    fprintf(file, "  gap: 8px 16px;\n");
    fprintf(file, "  margin-top: 24px;\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  color: var(--text-muted);\n");
    fprintf(file, "}\n");
    fprintf(file, ".legend-item { display: flex; align-items: center; gap: 8px; }\n");
    fprintf(file, ".legend-swatch { width: 14px; height: 14px; border-radius: 3px; flex-shrink: 0; }\n");
    fprintf(file, "</style>\n");
    fprintf(file, "</head>\n");
    fprintf(file, "<body>\n");
    fprintf(file, "<h1>Periodensystem der Elemente</h1>\n");
    fprintf(file, "<p class=\"subtitle\">Klicke auf ein Element, um Details zu sehen.</p>\n");
    fprintf(file, "<div class=\"detail\" id=\"detail\"><div class=\"detail-empty\">Klicke auf ein Element, um Details zu sehen</div></div>\n");
}

// Funktion zur Ausgabe des HTML-Footers
void print_html_footer(FILE *file) {
    fprintf(file, "<script>\n");
    fprintf(file, "const E = [\n");
    for(int i = 0; i < elements_count; i++) {
        fprintf(file, "  [%d,'%s','%s','%s','%s',%d,%d]%s\n", 
                elements[i].z, elements[i].sym, elements[i].name, elements[i].mass, elements[i].cat,
                elements[i].row, elements[i].col, (i < elements_count - 1) ? "," : "");
    }
    fprintf(file, "];\n");
    
    fprintf(file, "const CAT = {\n");
    for(int i = 0; i < categories_count; i++) {
        fprintf(file, "  %s:'%s'%s\n", 
                categories[i].key, categories[i].name, 
                (i < categories_count - 1) ? "," : "");
    }
    fprintf(file, "};\n");
    
    fprintf(file, "const CATPL = {\n");
    for(int i = 0; i < categories_count; i++) {
        fprintf(file, "  %s:'%s'%s\n", 
                categories[i].key, categories[i].namePlural, 
                (i < categories_count - 1) ? "," : "");
    }
    fprintf(file, "};\n");
    
    fprintf(file, "function showDetail(el) {\n");
    fprintf(file, "  const [z, sym, name, mass, cat, row, col] = el;\n");
    fprintf(file, "  const period = row >= 8 ? (row === 8 ? 6 : 7) : row;\n");
    fprintf(file, "  const group = row >= 8 ? 'f-Block' : col;\n");
    fprintf(file, "  document.getElementById('detail').innerHTML = `\n");
    fprintf(file, "    <div class=\"symbol-box cat-${cat}\">${sym}</div>\n");
    fprintf(file, "    <div style=\"flex:1;min-width:0\">\n");
    fprintf(file, "      <div class=\"info-name\">${name}</div>\n");
    fprintf(file, "      <div class=\"info-meta\">\n");
    fprintf(file, "        <span>Ordnungszahl:<b>${z}</b></span>\n");
    fprintf(file, "        <span>Atommasse:<b>${mass} u</b></span>\n");
    fprintf(file, "        <span>Periode:<b>${period}</b></span>\n");
    fprintf(file, "        <span>Gruppe:<b>${group}</b></span>\n");
    fprintf(file, "        <span style=\"grid-column:1/-1\">Kategorie:<b>${CAT[cat]}</b></span>\n");
    fprintf(file, "      </div>\n");
    fprintf(file, "    </div>`;\n");
    fprintf(file, "  document.querySelectorAll('.cell.active').forEach(c => c.classList.remove('active'));\n");
    fprintf(file, "  const cell = document.querySelector(`[data-z=\"${z}\"]`);\n");
    fprintf(file, "  if (cell) cell.classList.add('active');\n");
    fprintf(file, "}\n");
    
    fprintf(file, "function makeCell(el) {\n");
    fprintf(file, "  const [z, sym, name, mass, cat, row, col] = el;\n");
    fprintf(file, "  const c = document.createElement('button');\n");
    fprintf(file, "  c.className = `cell cat-${cat}`;\n");
    fprintf(file, "  c.style.gridColumn = col;\n");
    fprintf(file, "  c.style.gridRow = row >= 8 ? row - 7 : row;\n");
    fprintf(file, "  c.dataset.z = z;\n");
    fprintf(file, "  c.title = `${name} (${sym})`;\n");
    fprintf(file, "  c.innerHTML = `<span class=\"num\">${z}</span><span class=\"sym\">${sym}</span>`;\n");
    fprintf(file, "  c.onclick = () => showDetail(el);\n");
    fprintf(file, "  return c;\n");
    fprintf(file, "}\n");
    
    fprintf(file, "const main = document.getElementById('main');\n");
    fprintf(file, "const fblock = document.getElementById('fblock');\n");
    fprintf(file, "[[6, 'la', '57-71'], [7, 'ac', '89-103']].forEach(([r, cat, txt]) => {\n");
    fprintf(file, "  const m = document.createElement('div');\n");
    fprintf(file, "  m.className = `cell cell-marker cat-${cat}`;\n");
    fprintf(file, "  m.style.gridColumn = 3;\n");
    fprintf(file, "  m.style.gridRow = r;\n");
    fprintf(file, "  m.textContent = txt;\n");
    fprintf(file, "  main.appendChild(m);\n");
    fprintf(file, "});\n");
    fprintf(file, "E.forEach(el => {\n");
    fprintf(file, "  const c = makeCell(el);\n");
    fprintf(file, "  if (el[5] >= 8) fblock.appendChild(c);\n");
    fprintf(file, "  else main.appendChild(c);\n");
    fprintf(file, "});\n");
    
    fprintf(file, "const legend = document.getElementById('legend');\n");
    fprintf(file, "Object.entries(CATPL).forEach(([k, v]) => {\n");
    fprintf(file, "  const item = document.createElement('div');\n");
    fprintf(file, "  item.className = 'legend-item';\n");
    fprintf(file, "  item.innerHTML = `<span class=\"legend-swatch cat-${k}\"></span><span>${v}</span>`;\n");
    fprintf(file, "  legend.appendChild(item);\n");
    fprintf(file, "});\n");
    fprintf(file, "</script>\n");
    fprintf(file, "</body>\n");
    fprintf(file, "</html>\n");
}

// Hauptfunktion
int main(int argc, char *argv[]) {
    FILE *output_file;
    
    // Prüfen der Kommandozeilenargumente
    if(argc != 2) {
        fprintf(stderr, "Verwendung: %s <ausgabedatei.html>\n", argv[0]);
        return 1;
    }
    
    // Öffnen der Ausgabedatei
    output_file = fopen(argv[1], "w");
    if(output_file == NULL) {
        fprintf(stderr, "Fehler: Kann Datei %s nicht öffnen\n", argv[1]);
        return 1;
    }
    
    // HTML generieren
    print_html_header(output_file);
    
    // Grid-Container ausgeben
    fprintf(output_file, "<div class=\"grid\" id=\"main\"></div>\n");
    fprintf(output_file, "<div class=\"grid fgrid\" id=\"fblock\"></div>\n");
    fprintf(output_file, "<div class=\"legend\" id=\"legend\"></div>\n");
    
    print_html_footer(output_file);
    
    // Datei schließen
    fclose(output_file);
    
    printf("HTML-Datei erfolgreich erstellt: %s\n", argv[1]);
    return 0;
}
