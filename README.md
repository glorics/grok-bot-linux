# grok-bot-linux

Unofficial **Grok Bot** desktop client for **Linux x86_64**.

This is **not** an xAI or Cursor product. They do not ship a Linux app.
This project builds one from the **official Windows installer**: extract the
payload, run it on Electron for Linux, and replace the Windows-only native
addons.

**Tested on Debian 12 Bookworm** (amd64, glibc 2.36, GNOME/Wayland) with
Grok Bot **0.28.0**. The AppImage is a generic linux-x64 / glibc build (not musl,
not ARM). Binaries need glibc ≥ 2.34. Bookworm is the first-party host.
**Arch Linux** and **Linux Mint**: community-confirmed. Fedora notes are below.
0.24.0 remains on the [releases](https://github.com/glorics/grok-bot-linux/releases)
page.

## Install

From a [release](https://github.com/glorics/grok-bot-linux/releases):

```bash
chmod +x Grok_Bot_0.28.0_x86_64.AppImage
./Grok_Bot_0.28.0_x86_64.AppImage --no-sandbox
```

`--no-sandbox` is required. The AppImage cannot ship a working Chromium
setuid sandbox.

To register a dock / menu launcher (XDG, any distro):

```bash
./scripts/install-linux.sh Grok_Bot_0.28.0_x86_64.AppImage
```

Sign in with the same Cursor / SuperGrok Plus account. Bots live on the cloud
computer; this app is only the remote control.

## Arch Linux

**Community-confirmed.** [@RawXennial](https://x.com/RawXennial/status/2092756795840204804)
reported the 0.24.0 AppImage runs on Arch (2026-08-26). glibc on Arch is newer
than Debian 12, so the ABI is fine. First-party testing is still Debian 12 only.

```bash
chmod +x Grok_Bot_0.28.0_x86_64.AppImage
./Grok_Bot_0.28.0_x86_64.AppImage --no-sandbox
```

If the AppImage will not mount (`libfuse.so.2` / `fusermount` missing):

```bash
sudo pacman -S fuse2
```

Same FUSE fallbacks as elsewhere: `APPIMAGE_EXTRACT_AND_RUN=1` or the
release tarball. Menu entry (XDG, no AUR package yet):

```bash
./scripts/install-linux.sh Grok_Bot_0.28.0_x86_64.AppImage
```

## Linux Mint

**Community-confirmed.** [@r_u_thinking](https://x.com/r_u_thinking/status/2092805544411111796)
reported 0.28.0 builds and runs on Mint (2026-08-27). Mint is Ubuntu/Debian, so
the AppImage and `install-linux.sh` path is the same as above. First-party
testing is still Debian 12 only.

If the AppImage will not mount (`libfuse.so.2` missing):

```bash
sudo apt install libfuse2t64 || sudo apt install libfuse2
```

## Fedora

**Not verified.** Fedora Workstation x86_64 (43/44) should run this: glibc
is newer than Debian 12, the payload is `linux-x64-gnu`, and the install
script uses XDG paths (`~/Applications`, `~/.local`), not `apt`.

The usual failure is FUSE 2, not glibc. Fedora 43/44 no longer install fuse2
by default, and the AppImage runtime still looks for `fusermount`.

```bash
sudo dnf install fuse fuse-libs
chmod +x Grok_Bot_0.28.0_x86_64.AppImage
./Grok_Bot_0.28.0_x86_64.AppImage --no-sandbox
```

If it still will not mount (`libfuse.so.2` / `fusermount` missing), skip FUSE:

```bash
APPIMAGE_EXTRACT_AND_RUN=1 ./Grok_Bot_0.28.0_x86_64.AppImage --no-sandbox
```

Or use the tarball from the same release (no FUSE at all):

```bash
tar -xzf Grok_Bot_0.28.0_linux_x64.tar.gz
./Grok_Bot_0.28.0_linux_x64/grok-bot --no-sandbox --ozone-platform-hint=auto
```

Menu entry: `./scripts/install-linux.sh Grok_Bot_0.28.0_x86_64.AppImage`

If the window never appears (common with NVIDIA):

```bash
./Grok_Bot_0.28.0_x86_64.AppImage --no-sandbox --ozone-platform=x11
```

If SELinux blocks a file from Downloads:

```bash
restorecon -v ./Grok_Bot_0.28.0_x86_64.AppImage
```

Will not work: aarch64, musl, or a box with no GTK3. On a bare KDE spin:

```bash
sudo dnf install gtk3 nss atk at-spi2-atk cups-libs alsa-lib mesa-libgbm
```

Silverblue / Kinoite: prefer `APPIMAGE_EXTRACT_AND_RUN=1` or the tarball
rather than layering fuse2.

## Build from the Windows installer

```bash
./scripts/build-from-windows.sh --exe /path/to/Grok_Bot_0.28.0_Setup.exe
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
