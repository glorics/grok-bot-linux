#!/usr/bin/env python3
"""Replace Windows PE .node blobs with Linux binaries.

Public modules: npm / GitHub prebuilds for the versions shipped in the
Windows Grok Bot payload.
Private Cursor modules: our N-API stubs (native/*.c).
"""
from __future__ import annotations

import os
import shutil
import struct
import subprocess
import tarfile
import tempfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEPS: Path | None = None


def is_pe(path: Path) -> bool:
    try:
        with path.open("rb") as f:
            return f.read(2) == b"MZ"
    except OSError:
        return False


def run(cmd: list[str], cwd: Path | None = None) -> None:
    subprocess.check_call(cmd, cwd=cwd)


def npm_pack_extract(spec: str, dest: Path) -> Path:
    dest.mkdir(parents=True, exist_ok=True)
    tmp = Path(tempfile.mkdtemp(prefix="gb-npm-"))
    run(["npm", "pack", "--ignore-scripts", spec], cwd=tmp)
    tgz = next(tmp.glob("*.tgz"))
    with tarfile.open(tgz, "r:gz") as tf:
        tf.extractall(tmp / "ex")
    pkg = tmp / "ex" / "package"
    if not pkg.is_dir():
        raise RuntimeError(f"npm pack {spec} did not contain package/")
    return pkg


def download(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": "grok-bot-linux"})
    with urllib.request.urlopen(req, timeout=120) as r, dest.open("wb") as out:
        shutil.copyfileobj(r, out)


def compile_stub(src: Path, dest: Path, name: str) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    include = os.environ.get("GROKBOT_NODE_INCLUDE", "")
    if not include or not Path(include, "node_api.h").is_file():
        raise RuntimeError("GROKBOT_NODE_INCLUDE must point at node_api.h")
    run(
        [
            "g++",
            "-shared",
            "-fPIC",
            "-O2",
            "-s",
            f"-I{include}",
            str(src),
            "-o",
            str(dest),
            f"-DNODE_GYP_MODULE_NAME={name}",
        ]
    )


def copy_linux_prebuild(extracted_pkg: Path, dest_dir: Path) -> Path:
    candidates = list(extracted_pkg.glob("prebuilds/linux-x64/*.node"))
    candidates += list(extracted_pkg.glob("**/*.linux-x64-gnu.node"))
    if not candidates:
        raise RuntimeError(f"no linux-x64 .node in {extracted_pkg}")
    src = candidates[0]
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / src.name
    shutil.copy2(src, dest)
    return dest


def present(rel: str) -> bool:
    assert DEPS is not None
    return (DEPS / rel).exists()


def main() -> None:
    global DEPS
    unpacked = Path(os.environ["GROKBOT_UNPACKED"])
    DEPS = unpacked / "dist" / "deps"
    if not DEPS.is_dir():
        raise SystemExit(f"missing {DEPS}")

    tmp = Path(tempfile.mkdtemp(prefix="gb-native-"))
    native = ROOT / "native"

    # better-sqlite3 was in 0.24; dropped from 0.28. Electron 42 / Node ABI 146.
    # Payload 12.6.2 has no linux-electron prebuild; 12.11.1 ships v146.
    if present("better-sqlite3"):
        bs_url = (
            "https://github.com/WiseLibs/better-sqlite3/releases/download/"
            "v12.11.1/better-sqlite3-v12.11.1-electron-v146-linux-x64.tar.gz"
        )
        tgz = tmp / "bs.tar.gz"
        download(bs_url, tgz)
        with tarfile.open(tgz, "r:gz") as tf:
            tf.extractall(tmp / "ex")
        node = next((tmp / "ex").rglob("better_sqlite3.node"))
        dest = DEPS / "better-sqlite3" / "build" / "Release" / "better_sqlite3.node"
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(node, dest)
        print("better-sqlite3:", dest)
    else:
        print("skip better-sqlite3 (not in payload)")

    if present("tree-sitter"):
        ts_pkg = npm_pack_extract("tree-sitter@0.21.1", tmp / "tree-sitter")
        ts_dir = DEPS / "tree-sitter"
        shutil.rmtree(ts_dir / "build", ignore_errors=True)
        copy_linux_prebuild(ts_pkg, ts_dir / "prebuilds" / "linux-x64")
        print("tree-sitter linux prebuild installed")
    else:
        print("skip tree-sitter (not in payload)")

    if present("tree-sitter-bash"):
        tsb_pkg = npm_pack_extract(
            "tree-sitter-bash@0.21.0", tmp / "tree-sitter-bash"
        )
        tsb_dir = DEPS / "tree-sitter-bash"
        shutil.rmtree(tsb_dir / "build", ignore_errors=True)
        copy_linux_prebuild(tsb_pkg, tsb_dir / "prebuilds" / "linux-x64")
        print("tree-sitter-bash linux prebuild installed")
    else:
        print("skip tree-sitter-bash (not in payload)")

    if present("whichlang-node"):
        wl_pkg = npm_pack_extract(
            "whichlang-node-linux-x64-gnu@0.2.1", tmp / "whichlang"
        )
        wl_node = next(wl_pkg.glob("*.linux-x64-gnu.node"))
        dest_dir = DEPS / "whichlang-node"
        dest_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy2(wl_node, dest_dir / wl_node.name)
        print("whichlang-node:", wl_node.name)
    else:
        print("skip whichlang-node (not in payload)")

    if present("cursor-proclist"):
        compile_stub(
            native / "cursor_proclist.c",
            DEPS / "cursor-proclist" / "build" / "Release" / "cursor_proclist.node",
            "cursor_proclist",
        )
        print("cursor_proclist stub")
    else:
        print("skip cursor-proclist (not in payload)")

    if present("@anysphere/tree-chunk-napi"):
        compile_stub(
            native / "napi_loadable.c",
            DEPS / "@anysphere" / "tree-chunk-napi" / "tree-chunk-napi.linux-x64-gnu.node",
            "tree_chunk_napi",
        )
        print("tree-chunk-napi stub")
    else:
        print("skip tree-chunk-napi (not in payload)")

    live_pe = []
    for p in DEPS.rglob("*.node"):
        if not is_pe(p):
            continue
        rel = str(p.relative_to(DEPS))
        if "/prebuilds/win32-" in f"/{rel}" or ".win32-" in p.name:
            continue
        live_pe.append(rel)
    if live_pe:
        raise SystemExit("Windows .node still loadable on Linux:\n" + "\n".join(live_pe))
    print("native fix ok")


if __name__ == "__main__":
    main()
