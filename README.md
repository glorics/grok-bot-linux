# grok-bot-linux

Unofficial **Grok Bot** desktop client for **Linux x86_64**.

This is **not** an xAI or Cursor product. They do not ship a Linux app.
This project builds one from the **official Windows installer**: extract the
payload, run it on Electron for Linux, and replace the Windows-only native
addons.

**Tested on Debian 12 Bookworm** (amd64, glibc 2.36, GNOME/Wayland) with
Grok Bot 0.24.0. The AppImage is a generic linux-x64 build, so other distros
with glibc ≥ 2.36 may work. Only Bookworm is verified.

## Install

From a [release](https://github.com/glorics/grok-bot-linux/releases):

```bash
chmod +x Grok_Bot_0.24.0_x86_64.AppImage
./Grok_Bot_0.24.0_x86_64.AppImage --no-sandbox
```

To register a dock / menu launcher on Debian or similar:

```bash
./scripts/install-linux.sh Grok_Bot_0.24.0_x86_64.AppImage
```

Sign in with the same Cursor / SuperGrok Plus account. Bots live on the cloud
computer; this app is only the remote control.

## Build from the Windows installer

```bash
./scripts/build-from-windows.sh --exe /path/to/Grok_Bot_0.24.0_Setup.exe
```

If you omit `--exe`, the script downloads that version from Cursor’s CDN.

Needs: `p7zip-full`, `curl`, `unzip`, `g++`, `python3`, Node.js, and
`squashfs-tools` for the AppImage.

Output: `dist/Grok_Bot_<ver>_x86_64.AppImage` and a `.tar.gz`.

## What this is / is not

- It **is** a Linux wrapper around Cursor’s Windows desktop payload.
- It is **not** a reimplementation of Grok Bot, and it is **not** official.
- Do not commit the `.exe`, `app.asar`, or built AppImages. They are produced
  at build time.

## License

Scripts in this repository: `LICENSE` (MIT). Grok Bot belongs to xAI / Cursor.
