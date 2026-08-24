#!/usr/bin/env bash
# Build a Debian Bookworm Grok Bot AppImage from the official Windows installer.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR="${ROOT}/vendor/grokbot-linux-port"
DIST="${ROOT}/dist"
WORK="${ROOT}/work"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--exe /path/Grok_Bot_X.Y.Z_Setup.exe] [X.Y.Z]

Examples:
  $(basename "$0") --exe ~/Downloads/Grok_Bot_0.24.0_Setup.exe
  $(basename "$0") 0.24.0
EOF
}

EXE=""
VERSION=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --exe)
      EXE="${2:?--exe requires a path}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      VERSION="$1"
      shift
      ;;
  esac
done

if [[ -n $EXE ]]; then
  EXE="$(readlink -f "$EXE")"
  [[ -f $EXE ]] || { echo "exe not found: $EXE" >&2; exit 1; }
  if [[ -z $VERSION ]]; then
    if [[ $EXE =~ Grok_Bot_([0-9]+\.[0-9]+\.[0-9]+)_Setup\.exe$ ]]; then
      VERSION="${BASH_REMATCH[1]}"
    else
      echo "cannot guess version from filename; pass it as last argument" >&2
      exit 1
    fi
  fi
fi

VERSION="${VERSION:-0.24.0}"

if [[ ! -x ${VENDOR}/scripts/port.sh ]]; then
  echo "vendor port missing. Clone it:" >&2
  echo "  git clone --depth 1 https://github.com/Nichokas/grokbot-linux-port.git ${VENDOR}" >&2
  exit 1
fi

# Bookworm: Node from nvm, headers next to this repo.
if [[ -f ${HOME}/.nvm/nvm.sh ]]; then
  # shellcheck disable=SC1091
  source "${HOME}/.nvm/nvm.sh"
fi
export CPATH="${ROOT}/.include:${CPATH:-}"
export C_INCLUDE_PATH="${ROOT}/.include:${C_INCLUDE_PATH:-}"
export CPLUS_INCLUDE_PATH="${ROOT}/.include:${CPLUS_INCLUDE_PATH:-}"
mkdir -p "${ROOT}/.include"
if [[ ! -e ${ROOT}/.include/node && -d ${HOME}/.nvm/versions/node ]]; then
  NODE_INC="$(find "${HOME}/.nvm/versions/node" -path '*/include/node/node_api.h' | sort | tail -1 || true)"
  if [[ -n ${NODE_INC:-} ]]; then
    ln -sfn "$(dirname "$NODE_INC")" "${ROOT}/.include/node"
  fi
fi

mkdir -p "$DIST" "$WORK/scripts"
cp -a "${VENDOR}/scripts/." "$WORK/scripts/"
PORT_COPY="${WORK}/scripts/port.sh"
# SCRIPT_DIR becomes WORK/scripts so native-stubs resolve; REPO_ROOT=WORK.

python3 - "$PORT_COPY" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
t = p.read_text()
old = """  if ! download_with_retry "${win32_url}" "${installer_path}"; then
    echo "warn: win32 installer download failed for ${GROK_VERSION}" >&2"""
new = """  if [[ -n "${GROKBOT_WINDOWS_EXE:-}" ]]; then
    echo "Using local Windows installer: ${GROKBOT_WINDOWS_EXE}" >&2
    cp -a "${GROKBOT_WINDOWS_EXE}" "${installer_path}"
  elif ! download_with_retry "${win32_url}" "${installer_path}"; then
    echo "warn: win32 installer download failed for ${GROK_VERSION}" >&2"""
if old not in t:
    raise SystemExit("port.sh download block not found — upstream script changed")
t = t.replace(old, new, 1)
old2 = """      for cand in /usr/include/node /usr/include/nodejs /usr/local/include/node; do
        if [[ -f "${cand}/node_api.h" ]]; then
          node_include="${cand}"
          break
        fi
      done"""
new2 = """      for cand in ${GROKBOT_NODE_INCLUDE:-} /usr/include/node /usr/include/nodejs /usr/local/include/node; do
        [[ -n "${cand}" ]] || continue
        if [[ -f "${cand}/node_api.h" ]]; then
          node_include="${cand}"
          break
        fi
      done"""
if old2 not in t:
    raise SystemExit("port.sh node_api include block not found — upstream script changed")
t = t.replace(old2, new2, 1)
p.write_text(t)
print("patched port.sh for local exe + Bookworm node headers")
PY

# native-stubs live next to the original port.sh
export GROKBOT_NODE_INCLUDE="${ROOT}/.include/node"
if [[ -n $EXE ]]; then
  export GROKBOT_WINDOWS_EXE="$EXE"
fi

cd "$WORK"
echo "Building Grok Bot ${VERSION} for linux-x64 (Debian Bookworm host)..."
bash "$PORT_COPY" "$VERSION"

mkdir -p "$DIST"
if [[ -d ${WORK}/dist ]]; then
  cp -a "${WORK}/dist/"*.AppImage "${DIST}/" 2>/dev/null || true
  cp -a "${WORK}/dist/"*.tar.gz "${DIST}/" 2>/dev/null || true
fi

echo
echo "Artifacts in ${DIST}:"
ls -lh "$DIST" || true
