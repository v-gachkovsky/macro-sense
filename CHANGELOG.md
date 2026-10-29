# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- A click on the issue in the status bar puts the cursor on it (a misspelled name is still fixed by the click).
- **More one-click fixes** in the status bar: a typo in a command, condition, unit or value (`/cats` → `/cast`,
  `harmm` → `harm`, `@mousover` → `@mouseover`, `mod:shfit`, `reset=tagret`), a missing `]` or `[`, a stray `]`, the
  comma of an empty condition, a value where none belongs (`combat:1`). The tooltip says what the click does.
- **What a word means**: point at a word in the editor. A command, a condition (`nodead` reads "The unit is not
  dead."), a unit, `#showtooltip`, `reset=` get a few plain words; a spell or item shows the
  game's own tooltip. In English and Ukrainian.
- A talent or specialization change that breaks macros on your bars says so on the screen (`MacroSense: 2 macros
  on your bars use spells you don't have now`), their names in chat.
- **Drag a spell, mount or item onto the text** (or pick it up and click), or Shift-click it while typing: its name
  goes in at the cursor, after `/cast` or `/use` on an empty line.
- **Import a macro's text from a guide** (Wowhead, Icy Veins, a forum): Share > Import a code or text takes plain
  text too, one macro or several split by an empty line, each named after its first spell, with its icon. **Share >
  Copy this macro's text** gives the text to post.
- **The wizard makes mount macros** ("Ride a mount"): a mount for anywhere, one where you can fly, one for water,
  another with Shift, Ctrl or Alt held. The list offers only your mounts (the collection, mount items, Summon
  Felsteed, Travel Form...). A press on a mount gets you off it, not in the air unless you choose so: `/cast [nomounted,swimming] Sea Turtle; [nomounted,flyable] Gryphon; [nomounted] Steed`,
  `/dismount [mounted,noflying]`. Its `#showtooltip` names the same mounts, so on a mount the icon stays the
  mount's, not a question mark.
- **The wizard's When row**: the macro works only in or out of combat, in stealth or not, in a group, a raid or
  alone, with your pet out or not, in one of your forms or none (`[combat,nostealth,form:1]` on every branch). For
  /cast and /use, **otherwise** names what it casts the rest of the time (`/cast [stealth] Ambush; Sinister
  Strike`). A step-by-step question asks the same.

### Fixed

- A macro with `@tank` or `@heal` open in the editor could turn into the names written into the game's macro
  (`@none` with no tank) when your group changed, and saving it then lost the tags.
- The editor's tooltips (a line's explanation, a word's meaning) no longer show through the wizard or the questions window above it.

## [0.8.1] - 2026-10-29

### Changed
- **Shift-click a macro in the list** links it in chat wherever the cursor is: into the message you are typing,
  or the chat opens with the link. An alt's macro can be linked the same way.

## [0.8.0] - 2026-10-28

### Added
- **Spells you don't have now** are a warning in the editor and in the macro list: a talent you haven't chosen,
  another specialization's spell, one you learn later (with its level). A branch whose conditions check that
  themselves (`[spec:2]`, `[talent:...]`, `[known:...]`) is not marked. On the action bars such a macro turns
  yellow (the game's bars, Bartender, Dominos, ElvUI), and its tooltip says why. The warnings follow your talents
  and specialization as they change. Retail and WoW Forever: the talent tree; Mists of Pandaria: the talents of
  each row and the other specializations' spells; Classic Era and TBC: the talents with no points.
- Suggestions name the specialization of a spell that is not yours now (`Chaos Bolt  Destruction`).
- **A line in plain words**: point at a line's number, or at its note, and its tooltip says what the whole line
  does, every branch of it: `with Shift held: Polymorph on your focus, if it is an enemy and alive`, then
  `otherwise: Frostbolt`. Units tried one after another, the commands of the client's language, form and
  specialization names. In English and Ukrainian.
- **Your other characters' macros** in the Character tab, under each character's name (your realm first): their own
  macros as they were when you last played them, to read and to copy into this character or General. The search
  finds them too, and a character can be forgotten.
- **Link a macro in chat**: Share > Link this macro in chat, or Shift-click on it in the list while typing, puts
  `[MacroSense: Fear MO]` into the message. With MacroSense it is a link: a click asks the one who wrote it (an
  addon whisper) and opens the macro's code in the import window, to see and import. Only the macros you link are
  given, as they were then, the last 20.
- **Move to Character** / **Move to General** in a macro's copy menu: into the other tab, with its buttons on your
  action bars, its history and its name (`Fear 2` when that tab has one), and not into the trash.
- **Not on action bars** under the search: only the macros on no action bar, to free slots. MacroSense remembers
  the bars of each of your specializations and characters as it last saw them, so a macro another specialization
  or, for a general one, another character has counts as used. Hovering a macro in the list says where it is;
  deleting one says it in the question, and moving one those bars have asks first.
- **`@tank` and `@heal`**: your group's tank and healer as units, other than you, a raid's main tank first
  (`/cast [@tank,help,nodead][@pet,help,nodead] Misdirection`). The game doesn't know them, so its macro has the
  name of the one with the role (`@Bob`), or `@none` while nobody has it; MacroSense writes the new name in when
  your group changes, out of combat, and a new tank or healer in your macros is said in red mid-screen
  (`MacroSense: your group's new tank is Bob`), and so is one a macro has no room for. The editor shows and saves the macro with `@tank`, so you can change it and
  it keeps working; the live preview, the explanations and the suggestions know them. The wizard offers them next
  to Mouseover and Focus (Group's tank, Group's healer). A macro changed outside MacroSense (the Blizzard window)
  is no longer kept up to date.

### Changed
- The wizard puts `/startattack` right before the spell: after `/stopcasting`, trinkets and the lines that leave
  your form, get you off your mount, cancel a buff or target the nearest enemy, so the attack goes to the target
  they leave (it came last).
- In a macro's tooltip on the action bars, what MacroSense adds (its warnings, Shift + right-click) comes after a
  blank line, apart from the game's own lines.
- The macro open in the editor shows as it is saved when it changes elsewhere (the Blizzard window, another
  addon), unless you have unsaved changes in it.
- The name of a player in your group is no unknown unit: `[@Bob]` gets no warning while Bob is in it.

### Fixed
- `/castrandom` and `/userandom` lists are read name by name, as `/castsequence` ones are: a typo in one of their
  spells gets its fix (the whole list was taken for one name).

## [0.7.0] - 2026-10-26

### Added
- **Step by step** in the wizard: one question at a time, in plain words, for players new to macros. What the
  macro should do, the spell or item, where it goes and who then when that one is not there, friends or
  enemies (asked only when the game doesn't say what the spell is for; friends dead or alive, for a
  resurrection), what Shift, Ctrl or Alt (Cmd on a Mac) do, anything else, the name and who keeps the macro. A
  spell for enemies is not offered for yourself, your pet or party members, one for friends not for arena
  enemies. Each answer shows the macro's words for it (`@mouseover`), the macro shows at the bottom from the
  first answer, and Back goes back with the answers kept. The wizard asks step by step the first time; **All
  options** shows the whole form with the answers so far, **Step by step** goes back, and the wizard opens as
  you left it. In English and Ukrainian.
- **Spell ranks** in the wizard (Classic): a spell with several learned ranks lists them once picked, the spell
  itself first (the highest rank, also after you learn a new one); step by step it is a question of its own.

### Changed
- In the wizard, a spell or item that goes to nobody but you (Demon Armor, Bear Form: the game says it has no
  range) gets no units: step by step there is no "where" question for it, and the form sets On to As usual.
  So does a key that casts it.
- The live preview names the command a line runs: `runs /startattack`, `runs /target @focus`, `runs /yell`
  (it said only "runs"). "No match" is now "conditions not met", "nothing" is "does nothing", and a line said
  in chat is "says it in chat".
- The tooltip of New (Wizard) says it can ask a few simple questions.
- In the wizard, a key's own spell is checked for what it is for, whatever the macro's spell is: with Shadow
  Bolt as the macro's spell, Flash Heal on Shift goes to friends (`help`).
- A spell the game says is for friends and for enemies alike (Holy Shock) no longer sets the wizard's Only to
  Enemies. Picking a spell the game says nothing about after one it did sets it back to Anyone there.

### Fixed
- Deleting the macro being edited opens the next one, or the one before after the last: its text no longer
  stays in the editor as an unsaved new macro that asks to be discarded when you open another one.
- The editor's header shows the icon the macro shows in the game, as the list and the action bars do: with the
  question mark and `#showtooltip`, the spell's icon, also when a key held changes it (it showed the question
  mark). The question mark is still the icon saved, and its tooltip says what it does.

## [0.6.1] - 2026-10-26

### Changed
- **Cancel a buff** in the wizard and `/cancelaura` in the editor offer buffs, not every spell: the buffs on you
  now, then those you have had (MacroSense keeps the last 200 a character has had).
- In Ukrainian, backups are «Бекапи», as players call them (they were «Копії»).
- The tooltips of Live preview, Shorten, New (Wizard), Share, Trash, Backups and Back up now say plainly what
  they do, with their limits: the trash keeps the last 30 deleted macros of each tab and its menu shows the
  12 newest; each character keeps its last 10 backups.

## [0.6.0] - 2026-10-26

### Added
- **Ukrainian**: the whole interface in Ukrainian (the window, the wizard, menus, tooltips, the error checks,
  the live preview, chat lines), picked in the list in the editor's header; switching the language reloads
  the interface, after asking in the language picked. On a client whose font has no Cyrillic letters the
  interface uses the game's Friz Quadrata that has them.

### Changed
- Menus are as wide as their longest line.
- The history menu says "1 char", not "1 chars".

## [0.5.0] - 2026-10-25

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
