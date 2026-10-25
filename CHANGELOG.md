# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **Tab** or **Enter** in a macro's name goes on to its text. A new macro whose icon you haven't picked then
  gets the icon of the spell or item of yours it is named after (`Fireball`, `Kick Focus`, `Poly MO`); with no
  match, or with `#showtooltip` in its text, it keeps the question mark.

## [0.4.0] - 2026-10-25

### Added
- **Share** under the macro list: a code of the macro, of the tab or of all your macros, to copy and send,
  and **Import a code** to make macros from one. The import window says what the code holds and where each
  macro goes; nothing is replaced (a taken name gets a number), and a code cut short or changed is refused.
- **Trash** under the macro list: the macros deleted here, in the game's macro window or by another addon
  (the last 30 of each tab) come back with a click, into their tab, under a free name if theirs is taken.
  The x next to one deletes it for good.
- **Backups** under the macro list: all your macros as they were, one made by itself on the first login of
  a day when they changed and one whenever you ask (the last 10, for each character). Restoring one gives
  its macros their text and icon back and makes the deleted ones again; macros made since stay, and a
  backup of the macros now is made first. The x next to a backup deletes it.

### Changed
- The Copy and Delete buttons are gone: each macro in the list has a copy button (the same menu: a duplicate,
  or a copy in the other tab) and an x (delete, after asking) at its end. Any macro can be copied, not only
  the one being edited, and the one being edited stays open, with its unsaved changes, when another one is
  deleted. New and New (Wizard) share a row, so the list is a row taller.
- A macro renamed in the game's macro window keeps its earlier versions under the new name, as one renamed
  here does.

### Fixed
- The icon chosen for a macro is kept, as the game's macro window keeps it, not the one the macro shows at the
  moment: a question mark (so `#showtooltip` shows the spell's icon) stays a question mark when the macro is
  saved, copied, shared or brought back from the trash.

## [0.3.0] - 2026-10-25

### Added
- **Shift + right-click on a macro on an action bar** opens the editor on that macro instead of running it,
  and the button's tooltip says so. On the game's action bars and those of Bartender, Dominos and ElvUI.
- On a Mac, a macro's tooltip on the action bar warns when Cmd with its key is a macOS shortcut (Cmd+Q quits
  the game), as the editor's status bar does, and the button with that key turns red (on the game's bars).
- The icon grid also has the icons you put in `Interface\Icons` yourself, as the game's macro window does,
  searchable by their file names.

### Changed
- **Icon search** finds an icon by the name of any spell in the game that uses it, not only by your own spells
  and items, and by achievements on Retail and Mists of Pandaria. The game has no names for its icons: they are
  looked up in the background the first time the icon grid opens in a session (a few seconds; the grid's
  bottom line shows how far). Pointing at an icon shows its names, and case doesn't count in Cyrillic or
  accented names there either.

### Fixed
- The macOS shortcut warning missed most macros on action bars: for a macro that shows a spell the game gives
  the spell's ID, not the macro's. Macros on bars are now found by the name their button shows. The same mix-up
  left the `/click` suggestions without the name of such a macro, or showed another macro's name.

## [0.2.1] - 2026-10-24

### Changed
- **Search by first letters** takes capitals now, two or more: `DA` finds Demon Armor, `SWP` Shadow Word: Pain,
  `CA` or `CoA` Curse of Agony (a small letter for a small word). Small letters stay in one word: `ds` no longer
  finds Demon Skin, and `nmd` finds `nomod` (the letters of a word in their order, from its start). The names that
  start with what you typed come first, and a space goes on to the next word (`sh wo`). Capitals that are no
  name's first letters count as small ones.

### Fixed
- Case no longer counts in Cyrillic names or in names with accented letters: `дем` finds Демонічна броня, `écl`
  Éclair de givre, and capitals work there too (`ДБ`, `ÉDG`).

## [0.2.0] - 2026-10-24

### Added
- **Macro wizard**: **New (Wizard)** over New / Copy / Delete opens a form for a new macro: the command
  (`/cast` and `/use` for one spell or item, `/castsequence` with what starts it over, `/castrandom`, and
  `/target`, `/focus`, `/assist` on units, a key clearing the target or focus, `/target` by name too, and pet
  commands: one without a key, one per key held), the spell or item (by its name or the first letters of its
  words), on whom in order (mouseover, focus, your target, yourself, your pet, party members 1-4, target's
  target, arena enemies 1-3, the cursor, or as usual), friends, enemies or anyone and alive only (set from the
  spell), another spell or unit on Shift / Ctrl / Alt and Cmd on a Mac (with a fallback unit of its own), and
  also: stop your cast first, trinkets, auto attack, your pet, the nearest enemy if none is targeted, out of
  your form or off your mount first, a buff cancelled first, a line said in chat. The macro shows as you
  choose; Create macro saves it under a free name in the tab you pick and opens it in the editor.
- **Search by first letters**: names of several words come up by the first letters of their words: `da`
  finds Demon Armor, `swp` Shadow Word: Pain, `ca` Curse of Agony (small words may be left out). Those come
  first in the list, then the names that start with what you typed, then the rest.
- A command the game version has but does nothing with is a warning: `/petmoveto` in Classic Era and TBC,
  where the pet's Move To is not in the game yet (it came with Cataclysm). The wizard doesn't offer it there.

### Fixed
- Picking `nomod` from the suggestions no longer adds `:` after it: `[nomod]` alone is how it is used, and
  `nomod:shift` still works. A wrong modifier after `nomod:` (`nomod:shfit`) is marked now, as after `mod:`.

## [0.1.0] - 2026-10-23

### Added
- **Shorten**: a button in the header writes the same macro in fewer characters and says how many it saves:
  `target=` becomes `@`, long condition names become short ones (`modifier` -> `mod`, `stance` -> `form`,
  ...), `[x] Fear; Fear` becomes `[x][]Fear`, `[pet:Succubus][pet:Incubus]` becomes
  `[pet:Succubus/Incubus]`, and spaces the game doesn't need go. Chat, `/run`, other addons' commands and
  lines with errors stay as they are; Ctrl+Z brings the old text back.
- **History**: every change saved to a macro, in the editor, the game's macro window or by another addon,
  keeps the text it replaced (the last 10 per macro). **History** in the header lists them with when they
  were saved; hover one to read it, click it to put it back in the editor, then Save. The versions follow a
  macro renamed in the editor.
- **Copy** under the macro list: **Duplicate** copies the macro into the same tab, **Copy to Character** /
  **Copy to General** into the other one, with what the editor shows. The copy gets a free name
  (`Fear 2`), so key bindings stay with one macro.
- **Search** above the macro list (Ctrl+F from the editor): it keeps the macros whose name or text has what
  you type, and the tabs say how many match in each. Enter opens the first match, Esc clears it.
- **`reset=` in `/castsequence`**: `target`, `combat`, `shift`, `ctrl`, `alt` and seconds are suggested after
  `reset=` and after each `/` (the ones not used yet), and a wrong value is an error (`reset=tagret`,
  `reset=1.5`, an empty `reset=`), like `reset=` in a command other than `/castsequence`.
- **Items by slot**: after `/use 1` the list offers equipment slots with what is in them (`13` Trinket 1:
  ...), after `/use 0 ` the slots of that bag that hold something, and `/equipslot ` first offers the slots,
  then gear. Slot numbers, `0 1` and `item:6948` are colored as values instead of spell names; a slot that
  doesn't exist (`/use 23`), `/equipslot` without the slot or the item, and `item:` without a number are
  errors. The live preview names the slot: `/use 13` shows `Trinket 1`.
- **`/click`**: the list offers the buttons there are now, with what is on them (the game's bars,
  Bartender4, ElvUI and Dominos, the extra action button, popups), then the mouse buttons, then `true` for a
  click on key press. A name no button has now and a frame that is not a button are warnings, a misspelled
  mouse button gets a fix, and `down` as the last word is a warning: the game reads it as no.
- **Minimap button**: a click opens or closes the editor, a drag moves it along the edge (square minimaps
  too), and `/ms minimap` hides it. On Retail, MacroSense is in the addon menu by the minimap too.

### Changed
- **Live preview** moved to the title bar, next to the font and the scheme, to make room in the header.

### Fixed
- With a pet out on Classic Era, TBC Anniversary and Mists of Pandaria Classic, the Character tab didn't open,
  a picked suggestion didn't go in and a macro opened without its text: reading the pet's spells failed on
  these clients. The typo check now reads them the way they allow, and if it can't read your spells, items
  or mounts, only the check is skipped, not the editor.
- WoW Forever and Retail allow 30 character macros, not 18: the Character tab counts to 30 there, and New and
  Copy fill every slot.

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
