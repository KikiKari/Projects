"""Validated CPU/RAM/swap contracts for native AMD64 and future ARM64 work."""
import json
from pathlib import Path


def profile(name="work"):
    data = json.loads(Path(__file__).with_name("resource-profiles.json").read_text())
    value = data["profiles"][name]
    if not (0 < value["cpus"] <= 8 and 0 < value["memory_gib"] <= 16
            and value["swap_gib"] == 8
            and value["memory_swap_gib"] == value["memory_gib"] + value["swap_gib"]):
        raise ValueError("Invalid resource profile")
    return value


def docker_arguments(name="work"):
    value = profile(name)
    return ["--cpus", str(value["cpus"]), "--memory", f'{value["memory_gib"]}g',
            "--memory-swap", f'{value["memory_swap_gib"]}g']


if __name__ == "__main__":
    import sys
    print(json.dumps({"profile": sys.argv[1] if len(sys.argv) > 1 else "work",
                      "docker_arguments": docker_arguments(sys.argv[1] if len(sys.argv) > 1 else "work")}))
