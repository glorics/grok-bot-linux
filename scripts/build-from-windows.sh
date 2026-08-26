#!/usr/bin/env bash
# Build a Linux x86_64 Grok Bot AppImage from the official Windows installer.
# Linux x86_64 build. Requires: 7z, curl, unzip, node/npm, g++, python3.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="${ROOT}/dist"
CACHE="${ROOT}/.cache"
ELECTRON_VERSION="${ELECTRON_VERSION:-42.1.0}"

usage() {
  cat <<EOF
Usage: $(basename "$0") --exe /path/to/Grok_Bot_X.Y.Z_Setup.exe [X.Y.Z]
       $(basename "$0") X.Y.Z
EOF
}

EXE=""
VERSION=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --exe) EXE="${2:?}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "unknown option $1" >&2; usage >&2; exit 1 ;;
    *) VERSION="$1"; shift ;;
  esac
done

if [[ -n ${EXE} ]]; then
  EXE="$(readlink -f "$EXE")"
  [[ -f $EXE ]] || { echo "not found: $EXE" >&2; exit 1; }
  if [[ -z $VERSION && $EXE =~ Grok_Bot_([0-9]+\.[0-9]+\.[0-9]+)_Setup\.exe$ ]]; then
    VERSION="${BASH_REMATCH[1]}"
  fi
fi
VERSION="${VERSION:-0.24.0}"

if [[ -z $EXE ]]; then
  mkdir -p "$CACHE"
  EXE="${CACHE}/Grok_Bot_${VERSION}_Setup.exe"
  if [[ ! -f $EXE ]]; then
    url="https://downloads.cursor.com/grokbot/stable/win32-x64/${VERSION}/Grok_Bot_${VERSION}_Setup.exe"
    echo "Downloading ${url}"
    curl -fL --retry 3 -A 'Mozilla/5.0' -o "$EXE" "$url"
  fi
fi

if [[ -f ${HOME}/.nvm/nvm.sh ]]; then
  # shellcheck disable=SC1091
  source "${HOME}/.nvm/nvm.sh"
fi
NODE_INCLUDE="${GROKBOT_NODE_INCLUDE:-}"
if [[ -z $NODE_INCLUDE ]]; then
  NODE_INCLUDE="$(dirname "$(find "${HOME}/.nvm/versions/node" -name node_api.h 2>/dev/null | sort | tail -1)")"
fi
[[ -f ${NODE_INCLUDE}/node_api.h ]] || { echo "node_api.h not found" >&2; exit 1; }
export GROKBOT_NODE_INCLUDE="$NODE_INCLUDE"
export PATH="${HOME}/.nvm/versions/node/$(node -v)/bin:${PATH:-}"

command -v 7z >/dev/null || { echo "need p7zip-full (7z)" >&2; exit 1; }
command -v g++ >/dev/null || { echo "need g++" >&2; exit 1; }
command -v unzip >/dev/null || { echo "need unzip" >&2; exit 1; }

WORKDIR="$(mktemp -d -t grokbot-deb-XXXXXX)"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

echo "Windows installer : $EXE"
echo "Grok Bot version  : $VERSION"
echo "Electron          : $ELECTRON_VERSION"
echo "Workdir           : $WORKDIR"

NSIS="${WORKDIR}/nsis"
APP="${WORKDIR}/winapp"
mkdir -p "$NSIS" "$APP"
( cd "$NSIS" && 7z x -y "$EXE" >/dev/null )
PAYLOAD="$(find "$NSIS" -type f \( -name 'app-64.7z' -o -name 'app-32.7z' \) | head -1)"
[[ -n $PAYLOAD ]] || { echo "app-64.7z missing from NSIS payload" >&2; exit 1; }
7z x -y "$PAYLOAD" -o"$APP" >/dev/null
ASAR="${APP}/resources/app.asar"
[[ -f $ASAR ]] || { echo "resources/app.asar missing" >&2; exit 1; }

EL_ZIP="${CACHE}/electron-v${ELECTRON_VERSION}-linux-x64.zip"
mkdir -p "$CACHE"
if [[ ! -f $EL_ZIP ]]; then
  curl -fL --retry 3 -o "$EL_ZIP" \
    "https://github.com/electron/electron/releases/download/v${ELECTRON_VERSION}/electron-v${ELECTRON_VERSION}-linux-x64.zip"
fi
EL="${WORKDIR}/electron"
mkdir -p "$EL"
unzip -q "$EL_ZIP" -d "$EL"

STAGE="${WORKDIR}/Grok_Bot_${VERSION}_linux_x64"
mkdir -p "${STAGE}/resources"
cp "$EL/electron" "${STAGE}/grok-bot"
chmod 755 "${STAGE}/grok-bot"
for f in chrome-sandbox chrome_crashpad_handler libEGL.so libGLESv2.so libffmpeg.so \
         libvk_swiftshader.so libvulkan.so.1 vk_swiftshader_icd.json \
         icudtl.dat snapshot_blob.bin v8_context_snapshot.bin \
         chrome_100_percent.pak chrome_200_percent.pak resources.pak LICENSE.electron.txt LICENSES.chromium.html; do
  [[ -e $EL/$f ]] && cp -a "$EL/$f" "$STAGE/"
done
[[ -d $EL/locales ]] && cp -a "$EL/locales" "$STAGE/"
chmod 755 "${STAGE}/chrome_crashpad_handler" 2>/dev/null || true
chmod 4755 "${STAGE}/chrome-sandbox" 2>/dev/null || chmod 755 "${STAGE}/chrome-sandbox"

cp -a "$ASAR" "${STAGE}/resources/app.asar"
if [[ -d ${APP}/resources/app.asar.unpacked ]]; then
  cp -a "${APP}/resources/app.asar.unpacked" "${STAGE}/resources/"
fi
find "${STAGE}/resources/app.asar.unpacked" -type d -exec chmod 755 {} +
find "${STAGE}/resources/app.asar.unpacked" -type f -exec chmod 644 {} +

# Unpack the asar *before* swapping natives: @electron/asar follows the
# unpacked tree and errors if Windows .node files have already been removed.
ASAR_TMP="${WORKDIR}/asar-unpacked"
npx --yes @electron/asar extract "${STAGE}/resources/app.asar" "$ASAR_TMP"

export GROKBOT_UNPACKED="${STAGE}/resources/app.asar.unpacked"
python3 "${ROOT}/scripts/fix_natives.py"

# Pin Wayland/XDG identity to grok-bot before the asar is packed.
export GROKBOT_ASAR_TMP="$ASAR_TMP"
python3 "${ROOT}/scripts/fix_desktop_identity.py"

if [[ -d ${STAGE}/resources/app.asar.unpacked/dist/deps ]]; then
  rm -rf "${ASAR_TMP}/dist/deps"
  mkdir -p "${ASAR_TMP}/dist"
  cp -a "${STAGE}/resources/app.asar.unpacked/dist/deps" "${ASAR_TMP}/dist/deps"
fi
npx --yes @electron/asar pack "$ASAR_TMP" "${STAGE}/resources/app.asar"

ICON="$(find "$ASAR_TMP" "${STAGE}/resources" -name 'app-icon*.png' 2>/dev/null | head -1 || true)"
if [[ -n ${ICON} && -f $ICON ]]; then
  cp "$ICON" "${STAGE}/grok-bot.png"
fi

mkdir -p "$DIST"
TARBALL="${DIST}/Grok_Bot_${VERSION}_linux_x64.tar.gz"
tar -C "$WORKDIR" -czf "$TARBALL" "Grok_Bot_${VERSION}_linux_x64"
echo "tarball $TARBALL"

# AppImage
if command -v mksquashfs >/dev/null; then
  APPDIR="${WORKDIR}/AppDir"
  mkdir -p "${APPDIR}/usr/bin" "${APPDIR}/usr/share/applications"
  cp -a "${STAGE}/." "${APPDIR}/usr/bin/"
  ICON_SRC="${STAGE}/grok-bot.png"
  if [[ ! -f $ICON_SRC ]]; then
    ICON_SRC="$(find "${STAGE}" "$ASAR_TMP" -name 'app-icon*.png' 2>/dev/null | head -1 || true)"
  fi
  if [[ -n ${ICON_SRC} && -f $ICON_SRC ]]; then
    cp "$ICON_SRC" "${APPDIR}/grok-bot.png"
    cp "$ICON_SRC" "${APPDIR}/.DirIcon"
    # Same 256px asset at each hicolor size; Plasma picks a slot, AppRun
    # installs the same files into the user XDG tree on first launch.
    for size in 16 22 24 32 48 64 128 256; do
      mkdir -p "${APPDIR}/usr/share/icons/hicolor/${size}x${size}/apps"
      cp "$ICON_SRC" "${APPDIR}/usr/share/icons/hicolor/${size}x${size}/apps/grok-bot.png"
    done
  fi
  cat > "${APPDIR}/grok-bot.desktop" <<EOF
[Desktop Entry]
Name=Grok Bot
Comment=Grok Bot desktop agent
Exec=grok-bot --no-sandbox --class=grok-bot
Icon=grok-bot
Type=Application
Categories=Network;Utility;
Terminal=false
StartupNotify=true
StartupWMClass=grok-bot
MimeType=x-scheme-handler/sand;x-scheme-handler/grokbot;
X-AppImage-Version=${VERSION}
EOF
  cp "${APPDIR}/grok-bot.desktop" "${APPDIR}/usr/share/applications/"
  install -m 0755 "${ROOT}/packaging/AppRun" "${APPDIR}/AppRun"

  TOOL="${CACHE}/appimagetool"
  if [[ ! -x $TOOL ]]; then
    curl -fL --retry 3 -o "$TOOL" \
      "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x "$TOOL"
  fi
  APPIMAGE="${DIST}/Grok_Bot_${VERSION}_x86_64.AppImage"
  if ! ARCH=x86_64 "$TOOL" --appimage-extract-and-run "$APPDIR" "$APPIMAGE"; then
    echo "warn: AppImage step failed; tarball is still in dist/" >&2
  else
    chmod +x "$APPIMAGE"
    echo "appimage $APPIMAGE"
  fi
fi

echo "done ${VERSION}"
ls -lh "$DIST"
