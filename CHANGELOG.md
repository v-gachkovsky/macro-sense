# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **Shorten**: a button in the header writes the same macro in fewer characters and says how many it saves:
  `target=` becomes `@`, long condition names become short ones (`modifier` -> `mod`, `stance` -> `form`,
  ...), `[x] Fear; Fear` becomes `[x][]Fear`, `[pet:Succubus][pet:Incubus]` becomes
  `[pet:Succubus/Incubus]`, and spaces the game doesn't need go. Chat, `/run`, other addons' commands and
  lines with errors stay as they are; Ctrl+Z brings the old text back.

## [0.1.0-beta3] - 2026-10-23

### Added
- **Typos in spell and item names**: a name that is not known but close to a known one gets a yellow
  warning, `did you mean "Shadow Bolt"?`, and a click on it in the status bar fixes the name. Names
  nothing is close to stay unmarked (spells of another spec or pet, items not in the bags). Known names
  are your spells, your pets' spells (remembered from every pet you summon), items in your bags (and
  every item seen before) and, on Retail, your mounts.
- **Live preview**: next to each line, what it would do if you pressed the macro now: the spell or item
  and its target (`Fear @mouseover`), `no match` when no condition holds, `runs` for other commands,
  `stops here` / `not reached` around a `/stopmacro`, and the icon `#showtooltip` shows. It follows held
  modifiers, your target, mouseover, pet and combat; the game itself checks the conditions. **Live
  preview** in the header turns it off.
- **Marks in the macro list**: a macro with errors has a red name and the warning sign, one with only
  warnings a yellow name, and hovering it lists the issues line by line.

### Changed
- The **MacroSense** button sits in the title bar of the Blizzard macro window, next to its close button,
  instead of outside the window.

### Fixed
- Secure commands the game keeps out of addons' reach (`/petmoveto`, `/petaggressive`, `/targetparty`,
  `/worldmarker`, ...) were marked as unknown commands and missing from the suggestions after `/`. The
  game's own `IsSecureCmd` now confirms them, so only those your client has are offered.

## [0.1.0-beta2] - 2026-10-23

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

- **Line numbers** in a gutter on the left: error messages refer to lines, so they no longer have to be
  counted. A wrapped line keeps one number, the cursor's line is bright, and the gutter follows the font
  and its size (it widens past 99 lines).
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
