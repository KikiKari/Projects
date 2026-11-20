#!/usr/bin/env bash
# github_publisher.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/github_publisher.py
# Erzeugt: 2026-11-20 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Globale Variablen
declare -A LANGUAGES=([perl5]=1 [powershell]=1 [perl6]=1 [tcl]=1 [javascript]=1 [ruby]=1 [python]=1 [lua]=1 [shell]=1 [go]=1)

# Funktion zur Synchronisation des Checkouts
synchronize_checkout() {
    local root="$1"
    local remote="${2:-https://github.com/KikiKari/OpenClaw.git}"
    local branch="${3:-gateway1-abstractions}"
    
    local tmp_dir
    tmp_dir=$(mktemp -d "abstractions-snapshot-XXXXXX")
    local snapshot="$tmp_dir/repo"
    
    # Repository klonen
    git clone --quiet --depth=1 --single-branch --branch "$branch" -- "$remote" "$snapshot" &>/dev/null || {
        rm -rf "$tmp_dir"
        return 1
    }
    
    local revision
    revision=$(git -C "$snapshot" rev-parse HEAD 2>/dev/null) || {
        rm -rf "$tmp_dir"
        return 1
    }
    
    declare -A counts
    
    # Für jede Sprache synchronisieren
    for language in $(printf '%s\n' "${!LANGUAGES[@]}" | sort); do
        local source="$snapshot/$language"
        local target="$root/$language"
        
        # Prüfen ob Symlinks vorhanden sind
        if [[ -L "$source" ]] || [[ -L "$target" ]]; then
            echo "Fehler: Sprachverzeichnis ist ein Symlink" >&2
            rm -rf "$tmp_dir"
            return 1
        fi
        
        # Prüfen ob Remote-Verzeichnis gültig ist
        if [[ -e "$source" ]] && [[ ! -d "$source" ]]; then
            echo "Fehler: Ungültiges Remote-Sprachverzeichnis" >&2
            rm -rf "$tmp_dir"
            return 1
        fi
        
        # Zielverzeichnis erstellen
        mkdir -p "$target"
        
        # Bekannte Hashes sammeln
        declare -A known
        while IFS= read -r -d '' file; do
            if [[ ! -L "$file" ]] && [[ -f "$file" ]]; then
                local hash
                hash=$(sha256sum "$file" | cut -d' ' -f1)
                known["$hash"]=1
            fi
        done < <(find "$target" -maxdepth 1 -type f -print0 2>/dev/null || true)
        
        # Dateien verarbeiten
        local files=()
        if [[ -d "$source" ]]; then
            while IFS= read -r -d '' file; do
                if [[ -L "$file" ]] || [[ ! -f "$file" ]]; then
                    echo "Fehler: Ungültige Remote-Abstraktion" >&2
                    rm -rf "$tmp_dir"
                    return 1
                fi
                files+=("$file")
            done < <(find "$source" -maxdepth 1 -type f -print0 2>/dev/null || true)
        fi
        
        counts["$language"]=${#files[@]}
        
        for file in "${files[@]}"; do
            local data_hash
            data_hash=$(sha256sum "$file" | cut -d' ' -f1)
            
            if [[ -n "${known[$data_hash]:-}" ]]; then
                continue
            fi
            
            local filename
            filename=$(basename "$file")
            local destination="$target/$filename"
            
            # Prüfen ob Ziel bereits existiert
            if [[ -e "$destination" ]] || [[ -L "$destination" ]]; then
                local stem="${filename%.*}"
                local suffix=""
                [[ "$filename" != *.* ]] || suffix=".${filename##*.}"
                destination="$target/${stem}__pool_${data_hash}${suffix}"
            fi
            
            # Datei kopieren
            if [[ -e "$destination" ]] || [[ -L "$destination" ]]; then
                if [[ -L "$destination" ]] || [[ ! -f "$destination" ]] || ! cmp -s "$file" "$destination"; then
                    echo "Fehler: Lokaler Abstraktionskonflikt" >&2
                    rm -rf "$tmp_dir"
                    return 1
                fi
            else
                cp "$file" "$destination"
            fi
            
            known["$data_hash"]=1
        done
    done
    
    rm -rf "$tmp_dir"
    
    # Revision und Zähler zurückgeben
    echo "$revision"
    for lang in $(printf '%s\n' "${!LANGUAGES[@]}" | sort); do
        echo "${lang}:${counts[$lang]:-0}"
    done
}

# Status-Zähler aktualisieren
update_status_counts() {
    local path="$1"
    local revision="$2"
    shift 2
    local counts=("$@")
    
    local content
    content=$(<"$path")
    
    local rows=("## Bestand" "" "GitHub-Stand: \`$revision\`" "" "| Zielsprache | Dateien |" "|---|---:|")
    
    local total=0
    for entry in "${counts[@]}"; do
        local lang="${entry%%:*}"
        local count="${entry#*:}"
        rows+=("| $lang | $count |")
        ((total += count))
    done
    
    rows+=("| **gesamt** | **$total** |" "" "")
    
    # Bestehenden Abschnitt ersetzen
    local temp_file
    temp_file=$(mktemp)
    local in_section=false
    local replaced=false
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "## Bestand" ]]; then
            in_section=true
            if [[ "$replaced" == false ]]; then
                printf '%s\n' "${rows[@]}"
                replaced=true
            fi
            # Überspringe bis zur nächsten Überschrift
            while IFS= read -r next_line || [[ -n "$next_line" ]]; do
                if [[ "$next_line" == "## "* ]] && [[ "$next_line" != "## Bestand" ]]; then
                    echo "$next_line"
                    break
                fi
            done
            continue
        elif [[ "$in_section" == false ]]; then
            echo "$line"
        fi
    done < "$path" > "$temp_file"
    
    if [[ "$replaced" == false ]]; then
        echo "Fehler: Status-Bestandsabschnitt fehlt" >&2
        rm -f "$temp_file"
        return 1
    fi
    
    mv "$temp_file" "$path"
}

# Artefakt zur Warteschlange hinzufügen
queue_artifact() {
    local state_ref="$1"
    local root="$2"
    local path="$3"
    
    # Prüfen ob Artefakt ein Symlink ist
    if [[ -L "$path" ]]; then
        echo "Fehler: Artefakt darf kein Symlink sein" >&2
        return 1
    fi
    
    # Relativen Pfad bestimmen
    local abs_path
    abs_path=$(realpath "$path")
    local root_abs
    root_abs=$(realpath "$root")
    
    # Prüfen ob innerhalb des Roots
    if [[ "$abs_path" != "$root_abs"* ]]; then
        echo "Fehler: Artefakt liegt außerhalb eines Sprachverzeichnisses" >&2
        return 1
    fi
    
    local rel_path="${abs_path#$root_abs/}"
    if [[ "$rel_path" == "/"* ]]; then
        rel_path="${rel_path#/}"
    fi
    
    # Prüfen ob in gültigem Sprachverzeichnis
    local first_part
    first_part=$(echo "$rel_path" | cut -d'/' -f1)
    if [[ "$rel_path" != "STATUS.md" ]] && { [[ -z "${LANGUAGES[$first_part]:-}" ]] || [[ "$first_part" == "STATUS.md" ]]; }; then
        echo "Fehler: Artefakt liegt außerhalb eines Sprachverzeichnisses" >&2
        return 1
    fi
    
    # Hash berechnen und zur Warteschlange hinzufügen
    local hash
    hash=$(sha256sum "$path" | cut -d' ' -f1)
    
    # In State speichern (vereinfachte Implementierung)
    eval "$state_ref['ausstehende_veroeffentlichungen'][\"$rel_path\"]=\"$hash\""
}

# Ausstehende Artefakte veröffentlichen
publish_pending() {
    local root="$1"
    local token="$2"
    local sync_function="${3:-}"
    
    # Prüfen ob Token vorhanden
    if [[ -z "${token:-}" ]] || [[ -z "${token// /}" ]]; then
        return 1
    fi
    
    local root_abs
    root_abs=$(realpath "$root")
    
    # Header für API-Anfragen
    local auth_header="Authorization: Bearer ${token// /}"
    local accept_header="Accept: application/vnd.github+json"
    local api_version="X-GitHub-Api-Version: 2022-11-28"
    local user_agent="User-Agent: abstractions-manager"
    
    local success=0
    
    # Prüfen ob Synchronisation erforderlich
    if [[ -n "${sync_function:-}" ]]; then
        # Synchronisation durchführen
        local sync_result
        sync_result=$(synchronize_checkout "$root_abs" 2>/dev/null) || {
            echo "Fehler bei der Synchronisation" >&2
            return 1
        }
        
        local revision=""
        local counts=()
        while IFS= read -r line; do
            if [[ -z "$revision" ]]; then
                revision="$line"
            else
                counts+=("$line")
            fi
        done <<< "$sync_result"
        
        # STATUS.md aktualisieren falls vorhanden
        if [[ -f "$root_abs/STATUS.md" ]]; then
            update_status_counts "$root_abs/STATUS.md" "$revision" "${counts[@]}"
        fi
    fi
    
    return $success
}
