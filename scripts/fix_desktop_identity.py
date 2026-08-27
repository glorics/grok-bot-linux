#!/usr/bin/env python3
"""Pin the extracted asar to the grok-bot Linux desktop identity.

The Windows payload ships as name=sand / productName="Grok Bot" with no
desktopName, and the bundled main process clears BrowserWindow.icon when
packaged. Plasma Wayland then sees app_id grok-bot with nothing to resolve.

This inserts a small CJS wrapper as the Electron entry point so the Linux
build always declares grok-bot.desktop / --class=grok-bot before ready and
applies the bundled PNG to new windows.
"""
from __future__ import annotations

import json
import os
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WRAPPER = ROOT / "packaging" / "linux-desktop-identity.cjs"
ORIGINAL_MAIN = "dist/electron-main/main.cjs"


def main() -> None:
    asar_tmp = Path(os.environ.get("GROKBOT_ASAR_TMP", "")).resolve()
    if not asar_tmp.is_dir():
        raise SystemExit("GROKBOT_ASAR_TMP must point at the extracted asar tree")

    pkg_path = asar_tmp / "package.json"
    if not pkg_path.is_file():
        raise SystemExit(f"missing {pkg_path}")
    if not (asar_tmp / ORIGINAL_MAIN).is_file():
        raise SystemExit(f"missing {asar_tmp / ORIGINAL_MAIN}")
    if not WRAPPER.is_file():
        raise SystemExit(f"missing {WRAPPER}")

    pkg = json.loads(pkg_path.read_text(encoding="utf-8"))
    if not isinstance(pkg, dict):
        raise SystemExit("package.json must be an object")

    pkg["desktopName"] = "grok-bot.desktop"
    pkg["main"] = "linux-desktop-identity.cjs"
    pkg_path.write_text(json.dumps(pkg, indent=2) + "\n", encoding="utf-8")

    shutil.copy2(WRAPPER, asar_tmp / "linux-desktop-identity.cjs")
    print(f"desktop identity: desktopName={pkg['desktopName']} main={pkg['main']}")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:
        print(f"fix_desktop_identity failed: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
