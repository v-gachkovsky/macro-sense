# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project uses [Semantic Versioning](https://semver.org/).

## [0.1.0-beta1] - 2026-10-23

First public version. The addon is in early development: please report anything that looks wrong.

### Added
- **Editor window** for the game's own macros (General and Character), opened with `/ms` or the
  **MacroSense** button next to the Blizzard macro window: create, edit, rename, delete, revert.
  Movable and resizable; size and position are remembered.
- **Autocomplete** that knows where you are: slash commands, emotes and addon commands after `/`,
  conditions after `[`, units after `@` / `target=`, modifiers after `mod:` (`cmd` on Mac),
  spells and usable items after `/cast` / `/use`, gear after `/equip`, and learned spell ranks
  (Classic) after a spell name. Tab or Enter accepts, Up / Down move, Esc closes.
- **Syntax highlighting** with seven color schemes (Dark, Light, Graphite, Charcoal, Paper, Monokai,
  Solarized Dark) and five free monospace fonts (DejaVu Sans Mono, JetBrains Mono, Fira Mono,
  Source Code Pro, Inconsolata) plus game and LibSharedMedia fonts, size 8 to 28.
- **Error checks**: unknown commands and conditions, unclosed or stray brackets, empty conditions,
  `@` without a unit, `mod:` without a value. Errors are underlined, named in the status bar (all of
  them on hover) and marked on the Save button.
- **Mac**: a warning when a `[mod:cmd]` macro sits on a key macOS uses with Cmd (Cmd+Q, Cmd+W, ...).
- **Icon picker**: the question mark for `#showtooltip`, your spells and items first, then every game
  icon, with search. Resizable, can be moved away and docked back to the editor.
- **Drag to action bars** from the macro list or the icon in the header.
- Auto-closing `[` `]`, undo / redo (Ctrl+Z, Ctrl+Y), Ctrl+S to save, line / column and length counter.
- `/ms bug` prints the versions to include in a bug report.
