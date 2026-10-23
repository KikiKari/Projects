"""Start a new Linux Codex process in a bounded user scope; never restart existing sessions."""
import os
import sys
from resource_profiles import profile

value = profile(os.environ.get("TLC_RESOURCE_PROFILE", "work"))
os.execvp("systemd-run", ["systemd-run", "--user", "--scope", "--quiet",
                         "-p", f'CPUQuota={value["cpus"] * 100}%',
                         "-p", f'MemoryMax={value["memory_gib"]}G',
                         "-p", f'MemorySwapMax={value["swap_gib"]}G',
                         "codex", *sys.argv[1:]])
