#!/usr/bin/env bash
# git_publish.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/git-publish-agent/scripts/git_publish.py
# auch in: OpenClaw@gateway2:skills/git-publish-agent/scripts/git_publish.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Git Publish Agent - Automatisierte Skill-Veröffentlichung

SKILLS_DIR="$HOME/.openclaw/workspace/skills"

git_commit() {
    local skill_path="$1"
    local message="${2:-}"

    if [[ -z "$message" ]]; then
        message="[skill] Auto-update $(basename "$skill_path") - $(date -Iseconds)"
    fi

    (cd "$(dirname "$SKILLS_DIR")" && git add "$skill_path") || return 1
    (cd "$(dirname "$SKILLS_DIR")" && git commit -m "$message") || return 1
    return 0
}

clawhub_publish() {
    local skill_name="$1"
    local skill_path="$SKILLS_DIR/$skill_name"

    if clawhub publish "$skill_path" --slug "$skill_name" --version "1.0.0"; then
        return 0
    else
        return 1
    fi
}

batch_publish() {
    # Check git status
    local changed=()
    local line skill

    while IFS= read -r line; do
        if [[ -n "$line" ]] && [[ "$line" == *"skills/"* ]]; then
            skill=$(echo "$line" | sed -n 's|.*/skills/\([^/]*\)/.*|\1|p')
            if [[ -n "$skill" ]] && ! [[ " ${changed[*]} " =~ " $skill " ]]; then
                changed+=("$skill")
            fi
        fi
    done < <(cd "$(dirname "$SKILLS_DIR")" && git status --short "skills/")

    echo "Changed skills: ${changed[*]}"

    # Publish with delay
    local i=0
    for skill in "${changed[@]:0:5}"; do  # Max 5 per batch
        if (( i > 0 )); then
            echo "Waiting 15min for rate limit..."
            # In real: sleep 900
        fi

        echo "Publishing $skill..."
        if git_commit "$SKILLS_DIR/$skill"; then
            if clawhub_publish "$skill"; then
                echo "  ✓ Published"
            else
                echo "  ✗ Publish failed"
            fi
        else
            echo "  ✗ Commit failed"
        fi
        ((i++))
    done
}

main() {
    local skill=""
    local all=false
    local no_publish=false
    local message=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --skill)
                skill="$2"
                shift 2
                ;;
            --all)
                all=true
                shift
                ;;
            --no-publish)
                no_publish=true
                shift
                ;;
            --message)
                message="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done

    if [[ -n "$skill" ]]; then
        local skill_path="$SKILLS_DIR/$skill"
        if $no_publish; then
            git_commit "$skill_path" "$message"
        else
            git_commit "$skill_path" "$message"
            clawhub_publish "$skill"
        fi
    elif $all; then
        batch_publish
    else
        echo "Use --skill <name> or --all"
    fi
}

main "$@"
