# Finder Color Tagger

A tiny floating macOS utility for toggling the current Finder selection between Red, Orange, Green, and no label.

## What it does

- Shows a compact glass-style floating panel centered along the front Finder window title bar.
- Only appears while Finder is the active app.
- Reattaches after sleep, wake, unlock, screen changes, and Space changes.
- Uses a Finder tracking loop that only moves the panel when its target frame changes.
- Falls back to the top center of the screen when no Finder window is open.
- Lets you drag the panel around from its background.
- Toggles Finder color tags for the items currently selected in Finder.
- Pressing a button once applies that color; pressing it again on an item already using that color removes the label.
- Switching between Red, Orange, and Green preserves any non-color Finder tags.
- Supports Command-Q to quit.
- Includes the custom ColorTagger app icon.
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
