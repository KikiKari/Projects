#!/usr/bin/env python3
"""
Schnelle Abstraktion eines einzelnen Scripts
"""
import argparse
import sys
from pathlib import Path
from datetime import datetime

# Template-Definitionen
TEMPLATES = {
    "perl5": {
        "ext": ".pl",
        "shebang": "#!/usr/bin/env perl",
        "header": "use strict;\nuse warnings;\nuse feature 'say';\n",
        "main_block": "sub main {\n    # TODO: Implementiere Funktionalität\n}\n\nmain();\n",
    },
    "perl6": {
        "ext": ".raku",
        "shebang": "#!/usr/bin/env raku",
        "header": "use v6;\n",
        "main_block": "sub MAIN() {\n    # TODO: Implementiere Funktionalität\n}\n",
    },
    "javascript": {
        "ext": ".js",
        "shebang": "#!/usr/bin/env node",
        "header": "const fs = require('fs');\nconst path = require('path');\n",
        "main_block": "function main() {\n    // TODO: Implementiere Funktionalität\n}\n\nmain();\n",
    },
    "python": {
        "ext": ".py",
        "shebang": "#!/usr/bin/env python3",
        "header": "import sys\nimport os\nfrom pathlib import Path\n",
        "main_block": "def main():\n    # TODO: Implementiere Funktionalität\n    pass\n\nif __name__ == '__main__':\n    main()\n",
    },
    "shell": {
        "ext": ".sh",
        "shebang": "#!/bin/bash",
        "header": "set -euo pipefail\n",
        "main_block": "main() {\n    # TODO: Implementiere Funktionalität\n    :\n}\n\nmain \"$@\"\n",
    },
    "powershell": {
        "ext": ".ps1",
        "shebang": "#!/usr/bin/env pwsh",
        "header": "#Requires -Version 7\n",
        "main_block": "function Main {\n    # TODO: Implementiere Funktionalität\n}\n\nMain\n",
    },
    "tcl": {
        "ext": ".tcl",
        "shebang": "#!/usr/bin/env tclsh",
        "header": "package require Tcl 8.6\n",
        "main_block": "proc main {} {\n    # TODO: Implementiere Funktionalität\n}\n\nmain\n",
    },
    "ruby": {
        "ext": ".rb",
        "shebang": "#!/usr/bin/env ruby",
        "header": "require 'json'\nrequire 'fileutils'\n",
        "main_block": "def main\n  # TODO: Implementiere Funktionalität\nend\n\nmain if __FILE__ == $PROGRAM_NAME\n",
    },
    "lua": {
        "ext": ".lua",
        "shebang": "#!/usr/bin/env lua",
        "header": "",
        "main_block": "local function main()\n    -- TODO: Implementiere Funktionalität\nend\n\nmain()\n",
    },
    "go": {
        "ext": ".go",
        "shebang": "// +build ignore",
        "header": "package main\n\nimport (\n    \"fmt\"\n    \"os\"\n)\n",
        "main_block": "func main() {\n    // TODO: Implementiere Funktionalität\n    _ = fmt.Sprintf\n    _ = os.Args\n}\n",
    },
}

REPO_PATH = Path("/home/openclaw/.openclaw/workspace/git/Abstraktionen")


def get_source_lang(script_path: Path) -> str:
    ext_map = {
        "py": "Python", "js": "JavaScript", "sh": "Shell",
        "pl": "Perl", "rb": "Ruby", "ps1": "PowerShell"
    }
    return ext_map.get(script_path.suffix[1:], "Unknown")


def create_stub(source_path: Path, target_lang: str) -> Path:
    if target_lang not in TEMPLATES:
        raise ValueError(f"Unknown language: {target_lang}")

    template = TEMPLATES[target_lang]
    source_lang = get_source_lang(source_path)

    try:
        with open(source_path, 'r', encoding='utf-8', errors='ignore') as f:
            preview_lines = f.read().split('\n')[:10]
    except Exception as e:
        preview_lines = [f"# Error reading: {e}"]

    target_dir = REPO_PATH / target_lang
    target_dir.mkdir(parents=True, exist_ok=True)
    target_file = target_dir / f"{source_path.stem}{template['ext']}"

    if target_file.exists():
        print(f"⚠️  Already exists: {target_file}")
        return target_file

    comment = "#" if target_lang not in ("javascript", "go") else "//"
    preview = f"\n{comment} ".join(preview_lines)

    content = (
        f"{template['shebang']}\n"
        f"{comment} {source_path.stem} - {target_lang.title()} Version\n"
        f"{comment} Portiert von {source_lang}\n"
        f"{comment} Original: {source_path}\n"
        f"{comment} Erstellt: {datetime.now().strftime('%Y-%m-%d %H:%M')}\n"
        f"{comment}\n"
        f"{template['header']}\n"
        f"{comment} === ORIGINAL PREVIEW ===\n"
        f"{comment} {preview}\n"
        f"{comment} === END PREVIEW ===\n\n"
        f"{template['main_block']}"
    )

    with open(target_file, 'w') as f:
        f.write(content)

    print(f"✅ Created: {target_file}")
    return target_file


def main():
    parser = argparse.ArgumentParser(description="Create script abstraction")
    parser.add_argument("--source", "-s", required=True, help="Source script path")
    parser.add_argument("--target-lang", "-l", required=True, help="Target language")
    parser.add_argument("--use-model", "-m", help="Use AI model for generation")
    args = parser.parse_args()

    source_path = Path(args.source)
    if not source_path.exists():
        print(f"❌ Source not found: {source_path}")
        sys.exit(1)

    target_file = create_stub(source_path, args.target_lang)

    if args.use_model:
        print(f"🤖 Model generation with {args.use_model} - not yet implemented")

    print(f"\n📁 Abstraction ready at: {target_file}")
    print(f"📝 Next steps:")
    print(f"   1. Edit {target_file}")
    print(f"   2. Implement functionality")
    print(f"   3. Test with: {TEMPLATES[args.target_lang]['shebang'].split()[-1]} {target_file}")


if __name__ == "__main__":
    main()
