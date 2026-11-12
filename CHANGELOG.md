# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- A macro's note now shows in its button's tooltip on an action bar too, not only in the list.
- The tag macro: pick one of your macros in its "..." menu, then hold Ctrl + Alt and click a creature or player.
  Its name goes into the macro's `/targetexact` line, so a press targets that one: a rare or a quest mob in a
  crowd, a player in PvP. A click on yourself takes the name out; in combat, the name goes in once it ends. The
  keys are yours to choose in the settings.
- `/ms conditions` lists the macro conditions MacroSense offers that your game client doesn't know, as the game's
  own check tells it: for a bug report, or a client like WoW Forever.
- **Macros** in the game menu opens MacroSense instead of the game's macro window. `/macro` can open it too. Each
  is a choice in the settings (`/ms settings`); the menu's is on from the start.

## [0.17.0] - 2026-11-09

### Added
- Settings: MacroSense now has a page in the game's settings, among the AddOns (or `/ms settings`). There you
  choose the click on a macro on an action bar that opens it in the editor: Shift, Ctrl, Alt or two of them,
  with the right, middle or left mouse button. Or turn it off, if your macros use that click.

### Changed
- Shift + right-click on a macro on an action bar opens it only with Shift alone held: Shift + Ctrl + right-click
  runs the macro, as the click you pick takes just the keys picked.

## [0.16.0] - 2026-11-09

### Added
- The spell list offers your pets' spells too, after your own: the spells of every pet you had out, kept for
  each character. After `[pet:Imp]` it offers only the Imp's spells, once your Imp has been out.

### Changed
- After `[pet:` the list offers your pets by family: Imp, Voidwalker and so on. That is every pet you had out
  (kept for each character) and, in an English game, every demon you can summon. It no longer offers the name
  of the pet that is out: `[pet:Imp]` holds for any Imp.

## [0.15.4] - 2026-11-08

### Fixed
- Two macros with one name in a tab: moving one of them into the other tab could delete the other one, and it
  didn't even go into the trash. Now the macro you move leaves the tab and the other one stays as it is. When
  the character tab has no free slot, the one you picked goes behind the scenes, not the other one.
- @tank and @heal: a macro imported from a code or a chat link, moved from behind the scenes into General, or
  deleted behind the scenes and brought back from the trash came into the game with "@tank" itself. The game
  doesn't know that target, so the macro didn't cast on your tank, and it never got a tank's name later either.
  Now it gets the names of your group's tank and healer, and the new ones from then on.
- A macro made behind the scenes for lack of a free slot, by the wizard or moved there from General, kept the
  names of the tank and healer of that moment instead of @tank and @heal. Now it keeps @tank and @heal.
- A link from the list and the code of a whole tab or of the picked macros held the names of your tank and
  healer. Now they hold the macros as the editor shows them, with @tank and @heal, as "Link this macro in chat"
  already did.
- A text of more than 32 lines in the editor: pointing at the number or note of line 33 or below gave a Lua
  error instead of saying what the line does. Now it says it for every line.
- Macro sets in combat: "Turn on macro sets" went ahead, though the game doesn't let macros change then, and
  turned on again the sets could end up with a macro both in the game and behind the scenes. "/ms sets off" in
  combat said "off" while the sets stayed on. Now both say that macros can't be changed in combat, and nothing
  changes.
- Typing "|" followed by "r" or "c" in the editor, as in a color code inside `/run`, could put the cursor in
  the wrong place. Now it stays where you type.
- A General and a Character macro with one name: the editor, opened again or after a macro was made or
  deleted elsewhere, could switch to the General one. Now it stays on the macro you were editing.
- "Replace all" with unsaved changes in the editor: if a macro was made or deleted while it asked about them,
  the new text could go into the wrong macro. Now it looks for the text once you answer.
- After a comma in `/castrandom` and `/userandom`, and in `/castsequence` by its name in another language of the
  game, no names were suggested for the next spell or item. Now they are.
- In the older game versions, a new rank of a spell had MacroSense save again every macro with its name
  anywhere in the text: a new rank of Heal also touched macros of Flash Heal or Greater Heal, or a chat line
  with the word. Now only the macros that cast or show that very spell are saved again.
- The wizard's "Not while channeling it" for spells in turn or at random: with the list's first row left empty,
  the macro waited for any channel to end, not for its own spell's. Now it names the first spell of the list.
- The wizard's "Not while channeling it" with Shift, Ctrl or Alt casting another spell: the key's spell waited for
  the macro's main spell to end, not for itself (`[mod:alt,nochanneling:Drain Life] Drain Soul`). Now each
  spell waits for itself: `[mod:alt,nochanneling:Drain Soul] Drain Soul; [nochanneling:Drain Life] Drain Life`.
- `/ms` with a word it doesn't know listed its commands without `/ms sets`. Now it lists that one too.

### Changed
- The names of your specializations, offered after `[spec:` and used to tell what a line does, now come from
  the game function Retail has for them now. The old one, which Retail marked to go in patch 11.2.0, is used
  only by the clients that have no other.

## [0.15.3] - 2026-11-07

### Fixed
- On a Mac, a macro with `[mod:cmd]` on Q no longer warns that Cmd+Q quits the game: WoW doesn't quit on it,
  the key goes to the game as any other.
- A macro the game lost while MacroSense wasn't looking (the game's macros back as they were at a login) stayed
  behind the scenes in "This character's", and putting it into "This character's" from another set said it was
  added but didn't bring it into the game. Now it comes into the game, as "Take in" already brought it.

## [0.15.2] - 2026-11-07

### Fixed
- A hunter's macros from the spellbook on Forever: the book names Call Pet after your pet ("Call Wiwwiw"), and
  the macro was made with that name, which the game doesn't cast, so its buttons kept the spell too. Now the
  macro casts "Call Pet" and takes the spell's place on the buttons. The editor no longer takes the pet's name
  for a spell either.

## [0.15.1] - 2026-11-07

### Fixed
- Two macros of one name in the character tab: changing specialization could delete both and keep only one
  text. The game lets macros share a name, but MacroSense tells them apart by name. Now it doesn't move such a
  macro into a set or behind the scenes, and while a set's macro has a twin the sets wait and say which name
  to change. Renamed, they go on.
- `@tank` and `@heal` behind the scenes: a macro saved there, or put away, kept the name of the tank or
  healer then, and that name stayed after it came back into the game. Now its set keeps the tags; the
  macro gets your group's names when it comes in, and the new ones as the group changes.
- Macros behind the scenes have a history too: each change keeps the text it replaced, as for a macro in
  the game ("History" shows them, "Find and replace" keeps them). Backups hold them as well, each in its
  set; restored, one gets its text back or comes back behind the scenes. Before, a backup had only the
  macros in the game, and none at all when every macro was behind the scenes.
- Macros from the spellbook: an interrupt joined to another spell on a key lost "Stop your cast first".
  Now the macro stops the cast only when that key casts the interrupt (`/stopcasting [mod:ctrl]`), and
  the other spell casts as before. The wizard reads such a line back.
- Deleting a macro from the spellbook that casts two spells (one joined on a key) could put the joined
  spell on its buttons instead of the one the macro was made for. Now it is always the macro's own spell.
- A game client in another language: a macro with its own name of `/cast` (`/zaubern` in German) is now
  seen as casting its spells, as the editor already saw it. The spellbook doesn't offer those spells again,
  and "Sort by spells" knows where such a macro works.
- A macro linked in chat opened as a blank white window for anyone who hadn't opened MacroSense since logging
  in. Now the window has its colors and text from the first click.

### Changed
- The tests run on GitHub on every push and pull request, and a release isn't packed or published while
  one fails.

## [0.15.0] - 2026-11-06

### Added
- Save in combat: the game doesn't let macros change then, so MacroSense keeps the change and saves it as
  soon as combat ends. The status bar says "Saves when combat ends" meanwhile. A macro behind the scenes
  saves in combat at once.
- The wizard: "Not while channeling it" and "Not while channeling" under When (`[nochanneling:Drain Soul]`,
  `[nochanneling]`), and "!" by each spell (`!Shoot`: pressed again, it stays on), in the form and in the
  questions. It reads them back from a macro you have.
- "With mistakes" under the search: only the macros with a mistake or a warning, every macro checked at once;
  the tabs say how many each has.
- History: a version's tooltip shows what it changes in the text now, line by line as a diff: the lines that
  go in red, the ones that come back in green.
- Notes: "Add a note" in a macro's "..." keeps a line of your own about it, outside its 255 characters; the
  macro's tooltip in the list shows it. It follows the macro renamed or moved, and into the Trash and back.
- Find and replace: "Replace" next to the search (Ctrl+H) changes a word or a spell in many macros at once, in
  the General and Character tabs or, with macro sets on, in the sets you tick. Each macro's History keeps the
  text it had.
- Many macros at once: "Pick" puts a check before each macro and each group in the list; one click picks a macro
  or a whole group and one more takes it back, Ctrl+click (Cmd+click on a Mac) picks a macro too. On the row over
  the list "All" picks every macro shown or none, x takes back every pick, and "Actions" shares, moves, puts into a
  set or deletes them all; with macro sets on it also takes them into the game or puts them behind the scenes.
- Favorites and folders in the General tab: a macro's "..." puts it at the top under Favorites, or into a folder of
  your own, and so does dragging it there; a right click on a folder's name renames or deletes it. Picked macros
  go into one all at once.
- "What if" by the live preview: the notes next to the lines for a moment you set up yourself, the keys held,
  combat, and who your target, mouseover and focus are. A mouseover macro can be checked with the editor open. It
  says when a spell won't cast there: one for enemies on a friend, a dead enemy or nobody.

### Changed
- Less work when many action buttons change at once (a change of specialization, login): MacroSense looks at
  the bars once, not for each button.
- The in-game help and the guide tell of the warnings for a part of a macro that never runs, and of Primary and
  Secondary in the older clients.

### Fixed
- The wizard dropped the spell of a macro written by hand with `[nomod]` (`/cast [nomod] Shadow Bolt; [mod:alt]
  !Shoot`): the spell field stayed empty and the spell was gone from the text. `[nomod]` is now the macro's own
  spell, and the wizard writes the keys first.

## [0.14.0] - 2026-11-05

### Added
- A warning for a part of a macro that never runs: the game takes the first part whose conditions hold, so
  after `[]` or a part with no conditions the rest never run. `/cast [@mouseover,harm][] Arcane Shot;
  [mod:alt] Hunter's Mark` never casts Hunter's Mark: the Alt part has to come first. The same for a spell on
  a line below one that always casts a spell with the global cooldown; when that spell has a cooldown of its
  own, the warning says the line below works only while it is on cooldown. When a key chooses the parts
  (`[mod:alt]`), Ctrl+click on the warning puts them first, in one line.
- Ctrl+click on underlined text in the editor fixes it (Cmd+click on a Mac).
- From Spellbook: delete one of its macros in MacroSense and its spell comes back onto the macro's buttons, if
  the macro still casts it. Before, the buttons were left empty.

### Changed
- The status bar: a click goes to the issue's line, Ctrl+click (Cmd+click on a Mac) fixes it. Before, a click
  fixed it at once.

### Fixed
- Macro sets in Classic Era, TBC, Mists of Pandaria and WoW Forever: the two talent groups are named Primary
  and Secondary. In WoW Forever the sets follow the talent groups now, as the action bars do; before, both
  shared the one specialization named as the class. What was kept under it goes to the talent group chosen
  at the next login.
- Macro sets: a deleted macro's buttons are forgotten at once. Before, they were kept until the next login or
  change of specialization, and a new macro with the same name could go onto them.

## [0.13.1] - 2026-11-05

### Fixed
- WoW Forever: /petmoveto is no longer marked as "not in this game version", and the wizard offers "Move to the
  cursor" for the pet again. Forever has the world of Classic Era, but its game carries the command out.

## [0.13.0] - 2026-11-05

### Added
- **Macro sets**: more macros than a character's 30 slots. Tick "Macro sets" in the editor, and each
  specialization gets macros of its own: choose it, and its macros come into the game, onto the buttons they had,
  while the others' wait behind the scenes. Class macros are the same on all your characters of one class; this
  character's stay in every specialization. A macro with the same name in two specializations just changes its
  text, so its buttons never move. A backup of your macros is made first.
- With the sets on, the Character tab shows every macro, in the game and behind the scenes, by set: the class's
  yellow, the specialization now green, the rest red, one kept behind the scenes on purpose grey. Those behind the
  scenes open, change, are made and deleted like any other.
- "..." on a macro (a right click too): put it away or take it in, keep it behind the scenes in a specialization
  not chosen now, move or copy it to another set, duplicate it, send it back to this character's, or to the other
  tab. Drag it onto a group to move it there, with Ctrl to copy it; a sign by the mouse shows whether it can go
  there, and the chat says why not.
- With no free slot, a new macro (New, the wizard, a copy, the trash, From Spellbook, an import) or a general one
  moved into the Character tab is made behind the scenes, after asking ("Don't remind me again").
- Turned off, the macros behind the scenes come into the game, as many as fit; with more than fit, you choose
  which. Turned on again, they go back where they were, with what you changed meanwhile.
- MacroSense learns the spells of each specialization while you play it: a macro that can't be cast in its
  specialization says so, and "Sort by spells" offers to put each macro where its spells are.
- **Macro sets on another character**: "Share" > "Export macro sets..." makes a code of the sets you tick, and
  "Import a code or text..." takes it, or the sets of another character of yours. Each set goes into its own,
  another class's into this character's (said first); a taken name gets a number, the very same macro is skipped.
- Your other characters' macros in the Character tab include those behind the scenes, with their set.
- A change of the sets that breaks halfway is undone: your macros, sets and buttons are as they were, and the chat
  says so.
- Dragging a macro onto the General or Character tab moves it there, with Ctrl copies it, with the sets off too.
- From Spellbook: "Select all" (all ticked, "Clear all"), and "Offer all again", which forgets the spells you left
  out and the macros you deleted. A spell you deleted the macro of is offered again.
- The guide (`/ms help` and docs/GUIDE.md) has a section on macro sets; `/ms sets log` prints what they did, for a
  bug report.

### Changed
- One "..." on each macro in the list for copying and moving, instead of the copy icon.
- A code of macros starts with "MacroSense:" now; codes with "MacroSense1:" are read as before.
- From Spellbook: a spell whose tooltip names no range (Howl of Terror, Demonic Circle, rituals) gets no target to
  choose.
- A search in the editor shows what it finds from the top, and Enter opens the first one.

### Fixed
- The Macros from the Spellbook window (/ms book) and the guide (/ms help), opened before the editor, showed
  plain white: they had no colors until the editor's window was opened once.

## [0.12.0] - 2026-11-02

### Added
- **In-game** color scheme: the windows take the game's own dialog background and border, and the buttons, check
  boxes, input fields and dropdowns are the game's own: red buttons with gold letters, its check boxes, its input
  frames and arrows. Each client draws them in its own art. It is the scheme a new install starts with; a scheme
  you chose before stays.

### Changed
- Step by step, a click on an answer or on a spell from the list only chooses it: the macro at the bottom shows
  what it writes, another one can be chosen instead, and "Next" goes on.

### Fixed
- In Retail, the words the spellbook shows under a spell's name ("Racial", a specialization) were taken for its
  rank, so the Macros from the Spellbook window showed the Lower rank column. It is gone there now, with no empty
  space left in its place.

## [0.11.1] - 2026-11-01

### Changed
- The guide, the guide in game (a section of its own), the README and the CurseForge page tell about Macros from
  the Spellbook and `/ms book`, with a screenshot of its window; the window map shows the new button.

### Fixed
- Macros from the Spellbook: a spell's macro shows just over the mouse, also over the spell's name, where it
  didn't show at all; a click on the check shows it as it is now.
- Macros from the Spellbook: without a macro for the pet, its choices are dim and show "—" instead of looking
  usable.

## [0.11.0] - 2026-11-01

### Added
- **Macros from the Spellbook** ("From Spellbook" in the editor, or `/ms book`): macros for the spells of your
  spellbook, many at once. Check the spells; each macro names its spell with no rank, so it always casts the
  highest rank you know. Choose where attacks and helpful spells go (the unit under the mouse, your target or your
  focus), and for any spell on its own, over that choice; whether attacks start auto attack and interrupts stop your cast first. When there is not enough room,
  join a spell to another one's macro on Shift, Ctrl, Alt or Cmd; a spell with ranks can have a lower rank on a key
  too. A hunter or warlock gets one macro for the pet: what it does with no key and with each key. The macros go
  into the character's tab and onto the action bars in place of their spells. Spells that some macro casts
  already are left out, and next time only the spells you learned since are checked.

### Changed
- A long choice in a drop-down list goes on to a second line instead of being cut off.

### Fixed
- Classic clients whose spellbook shows only the highest rank of a spell: the lower ranks you know are offered
  too, when you type a rank and in Macros from the Spellbook.
- Classic: after you learn a new rank of a spell, a macro that casts it with no rank (`/cast Shadow Bolt`) kept
  showing and casting the old one until you edited it. MacroSense now saves such macros again by itself, after
  combat if you are in one. Their text stays the same, and the history keeps no version of it.

## [0.10.1] - 2026-10-31

### Changed
- The guide has a map of the MacroSense window: a screenshot with its parts numbered, and what each one is for.
- The guide and the guide in game name buttons and tabs in quotes ("New (Wizard)", «Майстер») and no longer say
  where they are ("under the list", "at the top"): the map shows it.

## [0.10.0] - 2026-10-31

### Added
- **Macros, step by step**: a guide in English and Ukrainian (`docs/GUIDE.md`, `docs/GUIDE_UA.md`) on what
  macros are, what they can do and how to make them with MacroSense, with pictures and ready-made macros.
- **?** in the editor's title bar, and `/ms help`: the macro guide in game, section by section: what a macro is,
  your first macro, the wizard, how a line reads and how the game picks, commands, conditions and units, what
  macros can't do, ready-made macros with a **Create** button, typing less, and the full guide's link to copy.
- **Practice** in the guide: tasks with your own spells and your class (a mouseover cast, Shift on your focus,
  your interrupt, a sequence, your pet, a heal). Write the macro in the editor and press **Check**: it looks at
  what the macro does, not how it is written, and says what to change. **Answer** shows one way to write it.
- The `!` of `/cast !Shoot` or `!Stealth` explains itself under the mouse: it only turns the spell on, so a press
  doesn't stop your shooting or take you out of stealth. The line's explanation says so too:
  `Shoot (only turns it on)`.

### Fixed
- Opening another MacroSense window (the guide, the wizard, the icons, Share) takes the keys from the editor:
  typing no longer goes into the macro text hidden behind it.

## [0.9.2] - 2026-10-30

### Changed
- A new macro starts with `#showtooltip` on the first line, the cursor on the second.
- A new macro you haven't touched (no name, no icon picked, nothing written but `#showtooltip`) is dropped
  without asking when you open another macro.
- A new macro is saved with the question mark unless you picked an icon, so the game shows the spell's icon
  and changes it as `#showtooltip` does. Before, the icon of the spell it was named after was saved, and stayed
  the same. Imported macros without an icon get the question mark too.
- An icon you chose, in a macro with `#showtooltip`, has a padlock in its corner, in the editor and the list:
  the game won't change that icon, and the tooltip says how to let it (choose the question mark).
- A macro with the question mark shows the game's icon in the list too, and it changes there while you hold a
  key. Where the game shows only the question mark (a new macro, or one just saved), MacroSense picks the icon
  as the game does: of what `#showtooltip` shows right now, else of the first line that casts or uses
  something right now. If that gives nothing (no line works right now, or the item isn't in your bags), the
  first spell or item the text names, whatever its conditions (the game knows the icons of items you don't
  carry); last, the macro's name. Such an icon is greyed while your action bars show the question mark, and
  its tooltip says why.

## [0.9.1] - 2026-10-30

### Added
- Autocomplete offers every condition the other way round too (`nochanneling`, `nomounted`, `noflying`,
  `nostealth`, `noharm`, `nogroup`, `noknown:`...), and `party`, `raid`, `shapeshift`, `modifier`. Conditions a
  client's game doesn't have yet (`advflyable`, `petbattle`, `pvptalent`, `extrabar`) are not offered there.
- After `channeling:` and `nochanneling:` the list offers only your channeled spells (Drain Life, Mind Flay...),
  not every spell. Each spell's tooltip is read once and kept until the next patch of the game.

### Changed
- The names of the game's icons (for the icon search) are looked up once and kept, not in each session: after
  the first time they are there at once, until the next patch or another language. A lookup cut short goes on
  where it stopped.

## [0.9.0] - 2026-10-30

### Added
- **Open a macro you have in the wizard**: **Wizard** next to History opens the macro shown with its answers filled
  in (the spell, the units in order, the keys, the When row, mounts, gear, the rest), typed by hand or not. **Put in
  editor** puts the new text in the editor: Save keeps it, undo takes it back. Lines the wizard would write its own
  way or leave out (`/run`, a second `/cast`) are named before anything changes.
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
- **The wizard puts on gear** ("Put on gear"): up to four items from your bags or what you wear, each in its
  default slot or one you pick (only those it fits: the other trinket or ring, the off hand for a one-hand
  weapon), always or only with a key held, and an equipment set
  where the game has them: `/equipslot [mod:shift] 14 Lucky Charm`, `/equipset PvP`.
- **The wizard's When row**: the macro works only in or out of combat, in stealth or not, in a group, a raid or
  alone, with your pet out or not, in one of your forms or none (`[combat,nostealth,form:1]` on every branch). For
  /cast and /use, **otherwise** names what it casts the rest of the time (`/cast [stealth] Ambush; Sinister
  Strike`). A step-by-step question asks the same.

### Fixed

- MacroSense's windows stayed over the game's own (bags, the spellbook, the character window) even when you clicked
  those. Now they share one layer: the window you clicked last is on top.
- A click on a scroll bar's track scrolled the wrong way (to scroll down you had to click near the top). Now the
  thumb jumps to where you click, in the macro list, the editor, the icons and the suggestions.
- A macro with `@tank` or `@heal` open in the editor could turn into the names written into the game's macro
  (`@none` with no tank) when your group changed, and saving it then lost the tags.
- In Ukrainian, "Вставити в редактор" didn't fit its button in the wizard.
- The editor's tooltips (a line's explanation, a word's meaning) no longer show through the wizard or the questions window above it.

### Changed
- `/ms bug` and the message after an update name every way to report a bug: GitHub Issues, the comments on
  CurseForge, or email.
- **The trash menu lists every deleted macro** (up to 30 per tab), not only the 12 newest. A long menu shows 20
  rows at a time; the mouse wheel or its scroll bar goes through the rest.
- Plainer words in tooltips and hints, in English and Ukrainian: whole short sentences instead of chains of
  colons. The Ukrainian says the same thing the same way everywhere (трінкет, стелс, вдягає), and `channeling` is
  a channeled spell, not any cast.

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
