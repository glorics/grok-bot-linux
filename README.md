# grok-bot-linux — retired

**This unofficial Linux port is retired.**

Cursor now publishes official Grok Bot Linux packages on
[`downloads.cursor.com`](https://downloads.cursor.com). They are the same
**0.30.0** desktop client as macOS/Windows, not a Windows-installer rebuild.

This repository (`glorics/grok-bot-linux`) was a community Windows-to-Linux
Electron port. Use the official packages instead.

The x.ai/bot **More downloads** page still lists macOS, Windows, and iOS only.
Linux is not advertised there, and
[official docs](https://docs.x.ai/grok-bot/get-started) still say Linux is
unavailable. The packages below are nevertheless on Cursor’s CDN.

## Official 0.30.0 (linux/x64)

Build: `2385d097738b3719cc5ecd9281a107aa106215f1`

| Format | URL |
| --- | --- |
| AppImage | https://downloads.cursor.com/grokbot/stable/2385d097738b3719cc5ecd9281a107aa106215f1/linux/x64/Grok_Bot_0.30.0.AppImage |
| `.deb` | https://downloads.cursor.com/grokbot/stable/2385d097738b3719cc5ecd9281a107aa106215f1/linux/x64/grok-bot_0.30.0_amd64.deb |
| `.rpm` | https://downloads.cursor.com/grokbot/stable/2385d097738b3719cc5ecd9281a107aa106215f1/linux/x64/Grok_Bot_0.30.0.rpm |
| `.tar.gz` | https://downloads.cursor.com/grokbot/stable/2385d097738b3719cc5ecd9281a107aa106215f1/linux/x64/Grok_Bot_0.30.0.tar.gz |

arm64 `.deb`:
https://downloads.cursor.com/grokbot/stable/2385d097738b3719cc5ecd9281a107aa106215f1/linux/arm64/grok-bot_0.30.0_arm64.deb

```bash
# AppImage (Omarchy / Arch / any distro with FUSE)
curl -fLO https://downloads.cursor.com/grokbot/stable/2385d097738b3719cc5ecd9281a107aa106215f1/linux/x64/Grok_Bot_0.30.0.AppImage
chmod +x Grok_Bot_0.30.0.AppImage
./Grok_Bot_0.30.0.AppImage
```

On Omarchy / Hyprland, add `--ozone-platform-hint=auto` if needed.

Releases of this unofficial port remain for history. They are no longer
maintained.
