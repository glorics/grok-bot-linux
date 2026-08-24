#!/usr/bin/env bash
# Install a built AppImage as the stable Grok Bot launcher on Linux.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPIMAGE="${1:-}"

if [[ -z $APPIMAGE ]]; then
  APPIMAGE="$(ls -1t "${ROOT}/dist"/Grok_Bot_*_x86_64.AppImage 2>/dev/null | head -1 || true)"
fi
if [[ -z ${APPIMAGE} || ! -f $APPIMAGE ]]; then
  echo "usage: $0 /path/to/Grok_Bot_X.Y.Z_x86_64.AppImage" >&2
  exit 1
fi
APPIMAGE="$(readlink -f "$APPIMAGE")"

DEST_DIR="${HOME}/Applications"
DEST="${DEST_DIR}/GrokBot-current.AppImage"
BIN="${HOME}/.local/bin"
DESKTOP_DIR="${HOME}/.local/share/applications"
ICON_DIR="${HOME}/.local/share/icons/hicolor"

mkdir -p "$DEST_DIR" "$BIN" "$DESKTOP_DIR" \
  "${ICON_DIR}/256x256/apps" "${ICON_DIR}/1024x1024/apps" \
  "${HOME}/.grokbot"

# Replace a previous symlink instead of writing through it.
rm -f "$DEST"
cp -f "$APPIMAGE" "$DEST"
chmod +x "$DEST"
base="$(basename "$APPIMAGE")"
if [[ $base != GrokBot-current.AppImage ]]; then
  rm -f "${DEST_DIR}/${base}"
  cp -f "$APPIMAGE" "${DEST_DIR}/${base}"
  chmod +x "${DEST_DIR}/${base}"
fi

install -m 0755 "${ROOT}/packaging/grok-bot.wrapper" "${BIN}/grok-bot"
# Wrapper reads GROKBOT_APPIMAGE or ~/Applications/GrokBot-current.AppImage

install -m 0644 "${ROOT}/packaging/grok-bot.desktop" "${DESKTOP_DIR}/grok-bot.desktop"
# Absolute Exec so the dock works even if ~/.local/bin is not in the desktop PATH.
sed -i "s|^Exec=grok-bot %U$|Exec=${BIN}/grok-bot %U|" "${DESKTOP_DIR}/grok-bot.desktop"
sed -i "s|^TryExec=grok-bot$|TryExec=${DEST}|" "${DESKTOP_DIR}/grok-bot.desktop"

# Reuse existing icons if present; otherwise leave Icon=grok-bot for hicolor.
if [[ ! -f ${ICON_DIR}/256x256/apps/grok-bot.png ]]; then
  echo "note: no grok-bot.png in ${ICON_DIR}; the menu may show a generic icon until you add one"
fi

update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
gtk-update-icon-cache -f "${ICON_DIR}" 2>/dev/null || true
xdg-desktop-menu forceupdate 2>/dev/null || true

echo "Installed:"
echo "  AppImage : $DEST"
echo "  Command  : ${BIN}/grok-bot"
echo "  Desktop  : ${DESKTOP_DIR}/grok-bot.desktop"
echo
echo "Click Grok Bot in the dock, or run: grok-bot"
