"use strict";

// Linux desktop identity for the unofficial Grok Bot build.
// Runs before the bundled main process so Plasma Wayland can map
// xdg_toplevel app_id "grok-bot" to grok-bot.desktop + Icon=grok-bot.
const { app } = require("electron");
const fs = require("node:fs");
const path = require("node:path");

const DESKTOP_NAME = "grok-bot.desktop";
const WM_CLASS = "grok-bot";

function resolveBundledIcon() {
  const execDir = path.dirname(process.execPath);
  const candidates = [
    path.join(execDir, "grok-bot.png"),
    path.join(execDir, "..", "share", "icons", "hicolor", "256x256", "apps", "grok-bot.png"),
    path.join(execDir, "..", "..", "grok-bot.png"),
    path.join(
      execDir,
      "..",
      "..",
      "usr",
      "share",
      "icons",
      "hicolor",
      "256x256",
      "apps",
      "grok-bot.png"
    ),
  ];
  for (const candidate of candidates) {
    try {
      if (fs.existsSync(candidate)) return candidate;
    } catch {
      // ignore unreadable candidates
    }
  }
  return undefined;
}

if (process.platform === "linux") {
  try {
    app.setDesktopName(DESKTOP_NAME);
  } catch {
    // Electron always exposes this on Linux; ignore older runtimes.
  }
  app.commandLine.appendSwitch("class", WM_CLASS);

  const bundledIcon = resolveBundledIcon();
  if (bundledIcon) {
    app.on("browser-window-created", (_event, win) => {
      try {
        win.setIcon(bundledIcon);
      } catch {
        // Hidden / offscreen windows may reject setIcon.
      }
    });
  }
}

require("./dist/electron-main/main.cjs");
