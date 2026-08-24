# grok-bot-debian

Unofficial **Grok Bot** client for **Debian 12 Bookworm** (x86_64).

This is **not** an xAI or Cursor product. Linux desktop is not supported upstream.
This repo builds a Bookworm-runnable AppImage from the **official Windows installer**.

Tested on: **Debian GNU/Linux 12 (bookworm), amd64** — Grok Bot 0.24.0, same Cursor account, bot roster and cloud computer intact.

## What you get

- An AppImage that launches Grok Bot on Bookworm
- A `.desktop` launcher (dock / app menu)
- A wrapper that always starts **this** build (no fallback to the old official 0.20 `.deb`)

## Build from the Windows installer

You do **not** commit the `.exe`. You pass it in, or the script downloads it from Cursor’s CDN.

```bash
# Official Windows installer (example: 0.24.0)
# https://downloads.cursor.com/grokbot/stable/win32-x64/0.24.0/Grok_Bot_0.24.0_Setup.exe

./scripts/build-from-windows.sh --exe /path/to/Grok_Bot_0.24.0_Setup.exe
# or, download + build:
./scripts/build-from-windows.sh 0.24.0
```

Output:

- `dist/Grok_Bot_<ver>_x86_64.AppImage`
- `dist/Grok_Bot_<ver>_linux_x64.tar.gz`

## Install on Bookworm

```bash
./scripts/install-bookworm.sh dist/Grok_Bot_0.24.0_x86_64.AppImage
```

Then click **Grok Bot** in the dock, or run `grok-bot`.

The first launch may take a few seconds (AppImage mount). Sign in with the **same** Cursor / SuperGrok Plus account you already use. Your bots live in the cloud; this app is only the remote control.

## Bookworm notes

| Item | Status on Bookworm |
| --- | --- |
| glibc | 2.36. The AppImage is launched with `--no-sandbox`. |
| FUSE | `libfuse2` is required for the AppImage. |
| GPU | Wayland works; do not inherit Flatpak GL paths. |
| Old `.deb` 0.20 | Do not use. Cursor pulled official Linux packages. |

## Credits

- Porting method (Windows NSIS → Electron Linux + native rebuild): [Nichokas/grokbot-linux-port](https://github.com/Nichokas/grokbot-linux-port)
- Grok Bot itself: xAI / Cursor. All product trademarks stay with them.

## License

Scripts in this repository: see `LICENSE`.

Grok Bot binaries are **not** ours. Do not commit the Windows `.exe`, `app.asar`, or built AppImages if you want a source-only repo. Built artifacts are derived at build time from Cursor’s Windows distribution.
