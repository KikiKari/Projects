#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "23e2d5bcd0dab8bb8972f22be6df310a2d5b1b9e6204fb6f08df13d61319042d", "source_sha256": "76a9327ec4d8b7b9abcabfcbbbf89350cb4a3a4fdc0c949a0b343fe059dc87a8", "target_language": "perl6"}
# abstractions-manager.sh — portiert nach perl6
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-manager.sh
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

sub MAIN(|args) {
    run("/home/openclaw/.openclaw/scripts/abstractions-manager-cron.sh", |args);
}
