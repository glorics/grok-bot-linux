# Tested

| | |
| --- | --- |
| OS | Debian GNU/Linux 12 (bookworm), amd64 |
| glibc | 2.36 |
| Desktop | GNOME, Wayland |
| Node (build) | v24.14.1 |
| Grok Bot | 0.24.0 |
| Electron | 42.1.0 |
| Input | Official `Grok_Bot_0.24.0_Setup.exe` (win32-x64) |
| Builder | `scripts/build-from-windows.sh` |
| Date | 2026-08-24 |

Checks on that host:

- AppImage starts with `--no-sandbox --ozone-platform-hint=auto`
- GPU process stays up on Wayland
- Existing Cursor account and bot roster remain
- Cloud bots keep running after the window is closed

The artifact is linux-x64 glibc (not musl, not ARM). Native modules need
glibc ≥ 2.34; Debian 12 (glibc 2.36) is the only first-party host.

Community reports:

| Distro | Status | Source |
| --- | --- | --- |
| Arch Linux | AppImage 0.24.0 runs | [@RawXennial](https://x.com/RawXennial/status/2092756795840204804), 2026-08-26 |
| SteamOS 3.8.25 (Plasma 6 Wayland) | AppImage launches; taskbar icon is the generic Wayland W | [#1](https://github.com/glorics/grok-bot-linux/issues/1) |
| Fedora Workstation 43/44 | untested; ABI should be fine, FUSE 2 is the likely snag | README Fedora section |
