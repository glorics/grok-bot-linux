# Tested

Current first-party build (Linux packaging 0.28.1, Windows payload 0.28.0):

| | |
| --- | --- |
| OS | Debian GNU/Linux 12 (bookworm), amd64 |
| glibc | 2.36 |
| Desktop | GNOME, Wayland |
| Node (build) | v24.14.1 |
| Grok Bot | 0.28.0 |
| Electron | 42.1.0 |
| Input | Official `Grok_Bot_0.28.0_Setup.exe` (win32-x64) |
| Builder | `scripts/build-from-windows.sh` |
| Linux packaging | 0.28.1 (`StartupWMClass=grok-bot`, AppRun does not rewrite an existing dock Exec) |
| Date | 2026-08-27 |

Checks on that host:

- AppImage starts with `--no-sandbox --ozone-platform-hint=auto`
- Crashpad reports `_version=0.28.0` / Electron 42.1.0
- GPU process and renderer stay up on Wayland
- Isolated-profile smoke test (did not reuse the live 0.24 session)
- 0.28.1 AppRun left `Exec=/home/manny/.local/bin/grok-bot` unchanged on GNOME
- 0.28.1 patched `StartupWMClass` to `grok-bot` and kept the dock wrapper

Previous first-party build (still published):

| | |
| --- | --- |
| Grok Bot | 0.24.0 |
| Electron | 42.1.0 |
| Input | Official `Grok_Bot_0.24.0_Setup.exe` (win32-x64) |
| Date | 2026-08-24 |

0.24.0 extra checks: existing Cursor account and bot roster remain; cloud bots
keep running after the window is closed.

0.28 dropped Windows natives that 0.24 needed (`better-sqlite3`,
`whichlang-node`, `@anysphere/tree-chunk-napi`). Remaining replacements:
`cursor-proclist` stub, `tree-sitter` 0.21.1, `tree-sitter-bash` 0.21.0.

The artifact is linux-x64 glibc (not musl, not ARM). Native modules need
glibc ≥ 2.34; Debian 12 (glibc 2.36) is the only first-party host.

Community reports:

| Distro | Status | Source |
| --- | --- | --- |
| Arch Linux | AppImage 0.24.0 runs | [@RawXennial](https://x.com/RawXennial/status/2092756795840204804), 2026-08-26 |
| Linux Mint | 0.28.0 builds and runs | [@r_u_thinking](https://x.com/r_u_thinking/status/2092805544411111796), 2026-08-27 |
| SteamOS 3.8.25 (Plasma 6 Wayland) | 0.28.1 taskbar icon is the Grokbot PNG (was the generic Wayland W on 0.24) | [#1](https://github.com/glorics/grok-bot-linux/issues/1) |
| Fedora Workstation 43/44 | untested; ABI should be fine, FUSE 2 is the likely snag | README Fedora section |
