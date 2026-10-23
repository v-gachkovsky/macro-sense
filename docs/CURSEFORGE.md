![MacroSense](https://raw.githubusercontent.com/v-gachkovsky/macro-sense/main/docs/banner-v2.png)

**A macro editor that knows macros: autocomplete, highlighting and error checks.**

> **Early development.** MacroSense is young and still growing. If something looks wrong, behaves oddly or
> you miss a feature, please tell me: no report is too small. I read every one and try to fix things as fast
> as I can. Type `/ms bug` in game for the details to include.

The Blizzard macro window is a plain text box. MacroSense opens your macros in a real editor: it suggests
commands, conditions, units, spells and items as you type, colors the syntax, and underlines mistakes before
you find them in combat. The macros stay the game's own, so the Blizzard window, your action bars and other
addons see every change.

**Works on every client:** Retail, Mists of Pandaria Classic, TBC Anniversary, Classic Era and WoW Forever.

---

## Autocomplete

| You type | You get |
|----------|---------|
| `/` | slash commands, emotes, chat commands, commands of your other addons |
| `/cast [` | macro conditions: `combat`, `harm`, `mod`, `stance`, ... |
| `[@` or `[target=` | units: `mouseover`, `focus`, `party1`, `arena2`, ... and `party1target` style chains |
| `[mod:` | `shift`, `ctrl`, `alt`, `cmd` on Mac, left / right keys |
| `[form:` / `[stance:` | your forms with their names |
| `[spec:`, `[equipped:`, `[group:`, `[bar:`, `[btn:`, `[pet:` | specs, weapon and armor types, party / raid, bar pages, buttons, your pet |
| `/cast ` or after `]` / `;` | your spells, then usable items |
| `/use ` | items with a use effect (bags and gear), then spells |
| `/equip ` / `/equipslot 13 ` | gear from your bags |
| a spell with several learned ranks (Classic) | its ranks, highest first: `Fireball(Rank 4)` |
| `#` | `#showtooltip`, `#show` |

**Tab** or **Enter** accepts, **Up / Down** move through the list, **PageUp / PageDown** jump 10, **Esc** closes
it (after a spell, Esc keeps the plain name without a rank). Long lists scroll, also with the mouse wheel.
Typing `[` adds the `]` for you.

## Highlighting and error checks

Commands, conditions, units, values and spell names each get their own color. Mistakes are **underlined**,
the status bar names them (hover for the full list), and the Save button shows a warning sign:

- unknown commands and conditions (a typo like `harmm` or `/cats`)
- a `[` without `]`, or a `]` without `[`
- an empty condition: `[harm,,dead]`
- `@` or `target=` without a unit, `mod:` without a value
- a wrong value: `btn:7`, `group:arena`, `mod:shfit`, or a value where none belongs: `combat:1`
- unknown units like `@mousover` are a yellow **warning**: they may be a player's name

Saving is still allowed: the editor warns, it doesn't block you.

**Mac players:** if a macro with `[mod:cmd]` sits on a key macOS itself uses with Cmd (Cmd+Q quits the game,
Cmd+W, Cmd+H, Cmd+Tab, Cmd+Space, ...), the status bar warns you.

## Make it yours

- **Seven color schemes**: Dark, Light, Graphite, Charcoal, Paper, Monokai, Solarized Dark.
- **Monospace fonts** included: DejaVu Sans Mono, JetBrains Mono, Fira Mono, Source Code Pro, Inconsolata.
  Game fonts and LibSharedMedia fonts work too. Size from 8 to 28.
- **Resizable window**; size and position are remembered.

## Icons and action bars

- Click the macro's icon to pick a new one: the question mark (so `#showtooltip` chooses), your spells and
  items first, then all 27,000+ game icons. **Search** by spell or item name.
- The icon grid can be resized, moved away from the editor and docked back.
- **Drag** a macro from the list, or its icon from the header, straight onto an action bar.

## Editing comforts

- Undo / redo: **Ctrl+Z**, **Ctrl+Y** (or Ctrl+Shift+Z). Save: **Ctrl+S**.
- Line, column and a length counter (macros are limited to 255 characters).
- Asks before discarding unsaved changes.

---

## Commands

| Command | Action |
|---------|--------|
| `/ms` | Open or close the editor (also `/macrosense`, `/msense`) |
| `/ms bug` | Print the versions to include in a bug report |
| `/ms autocomplete` | Turn autocomplete on or off |
| `/ms debug` | Print the editor's key events (helps me with key bugs) |

## Good to know

- Macros can't be created, changed or put on action bars in combat; the game doesn't allow it.
- Action bars of other addons (Bartender, ElvUI, ...) are not checked for the Mac Cmd warning.

## Feedback

Found a bug or have an idea? Open an issue on [GitHub](https://github.com/v-gachkovsky/macro-sense/issues) (or leave a comment on this page) with what
you did, what you expected and what happened (a screenshot helps), plus the output of `/ms bug`.

---

With ❤️ from 🇺🇦
