# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **Condition values** are suggested after the colon: your forms for `form:` / `stance:` (with their names),
  specializations for `spec:`, weapon and armor types for `equipped:` / `worn:`, `party` / `raid` for
  `group:`, bar pages for `bar:`, button names for `btn:`, your pet for `pet:`, and left / right keys
  (`lshift`, `rctrl`, ...) for `mod:`. Also after `/` for the next value.
- **Longer units**: after a unit id the list offers `...target` and `...pet` (`party1target`,
  `focustargettarget`), and `npc`, `anyenemy`, `softenemy` and the other Retail units are listed.
- **Checks for values**: a wrong value is an error (`btn:7`, `group:arena`, `mod:shfit`, `bar:9`,
  `form:x`), and so is a value for a condition that takes none (`combat:1`).
- **Unknown units** (`@mousover`) are underlined as a **warning** in yellow: they may be a player's name,
  which macros allow.

- **Scrollable suggestions**: the list shows 10 rows and scrolls through all matches (it used to stop
  at 10, so e.g. `Shields` was out of reach in `equipped:`): Up / Down follow the selection, PageUp /
  PageDown jump 10, the mouse wheel scrolls, and a thin scroll bar shows where you are.

### Changed
- The status bar shows errors first, then the Mac Cmd shortcut warning, then other warnings; the Save
  alert icon is for errors only. The tooltip lists everything, errors in red and warnings in yellow.
- Mistakes in the word being typed are no longer hidden until the cursor moves on, which let a macro be
  saved without seeing them: a word that can't become valid (`@mousovr`, `btn:7`) is marked at once, one
  that still may (`comb`) after a short pause in typing, and Save always checks everything.
- A word typed in full no longer lists other words that only contain it (`shift` no longer shows
  `lshift`); longer words that start with it still show.

### Fixed
- Clicking a suggestion with the mouse closed the list without inserting it: pressing the mouse on the
  list took the focus from the text, and the list closed before the click. It now stays open, the focus
  returns to the text and the clicked item goes in. Dragging the list's scroll bar works the same way.

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
