# Tested on Debian Bookworm

Host used for the first known-good build:

| | |
| --- | --- |
| OS | Debian GNU/Linux 12 (bookworm), amd64 |
| Kernel | 6.1.0 (bookworm) |
| glibc | 2.36 |
| Desktop | GNOME, Wayland |
| Node (build) | v24.14.1 via nvm |
| Grok Bot | 0.24.0 |
| Electron | 42.1.0 |
| Input | Official `Grok_Bot_0.24.0_Setup.exe` (win32-x64, NSIS) |
| Output | `Grok_Bot_0.24.0_x86_64.AppImage` (129M) |
| Date | 2026-08-24 |

Runtime checks on this host:

- AppImage starts with `--no-sandbox --ozone-platform-hint=auto`
- GPU process stays up on Wayland
- Session keeps the existing Cursor account
- Existing bot roster (cloud computer) is reachable after relaunch
- Closing the window does not destroy cloud bots

This does **not** mean Cursor supports Linux. It means this unofficial pipeline produced a client that ran on this Bookworm machine.
