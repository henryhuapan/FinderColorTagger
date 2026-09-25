<img width="312" height="49" alt="Screenshot 2026-09-24 at 5 27 13 PM" src="https://github.com/user-attachments/assets/7f2b1ba7-6b8e-4f93-ba73-61d3c3f98cb1" />

# Finder Color Tagger

Version 1.01

A tiny floating macOS utility for applying or removing Red, Orange, Green, and Purple tags from the current Finder selection.

## What it does

- Shows a compact glass-style floating panel centered along the front Finder window title bar.
- Only appears while Finder is the active app.
- Toggles Finder color tags for the items currently selected in Finder.
- Pressing a button once applies that color; pressing it again on an item already using that color removes the label.
- The No Color button removes any standard Finder color while preserving custom non-color tags.
- Switching between Red, Orange, Green, and Purple preserves any non-color Finder tags.
- Supports Command-Q to quit.
- Runs as an accessory app, so it does not take over your Dock.
## Build

Open Terminal in this folder and run:

```bash
chmod +x Scripts/build-app.sh
Scripts/build-app.sh
```

The built app will appear at:

```text
build/Finder Color Tagger.app
```

## First Run Permission

The first time you click a color, macOS may ask for permission to control Finder.

If the prompt does not appear, allow it manually:

```text
System Settings > Privacy & Security > Automation > Finder Color Tagger > Finder
```

## Notes

The app uses Finder selection through AppleScript, then applies macOS tag metadata directly to the selected files and folders.
