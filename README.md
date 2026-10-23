# MacroSense

A macro editor for World of Warcraft: its own window with a monospace font, syntax highlighting,
color schemes and context-aware autocomplete. Macros are the game's own (`CreateMacro` / `EditMacro`),
so they stay in sync with the Blizzard macro UI.

Open it with `/ms` (or `/macrosense`, `/msense`), or the **MacroSense** button next to the Blizzard macro window.

Click the macro icon to choose another one: the question mark first (`#showtooltip` then picks the icon),
then icons of your spells and items, then every macro icon of the game. Search matches spell and item names.

## Autocomplete

| You type | You get |
|---|---|
| `/` | slash commands, emotes, chat commands (Blizzard and addons) |
| `/cast [` | macro conditions |
| `[@` / `[target=` | unit ids |
| `[mod:` | `shift`, `ctrl`, `alt` |
| `/cast ` or after `]` / `;` | spells, then usable items from bags |
| a spell with several learned ranks (Classic) | its ranks, highest first: Tab inserts `Fireball(Rank 2)`, Esc keeps `Fireball` |
| `/use ` | usable items from bags and gear, then spells |
| `/equip ` / `/equipslot 13 ` | gear from bags |
| `#` | `#showtooltip`, `#show` |

Keys: **Tab** / **Enter** accept, **Up / Down** move, **Esc** closes the list.
Editor: **Ctrl+S** save, **Ctrl+Z** undo, **Ctrl+Y** / **Ctrl+Shift+Z** redo.

## Look

- Fonts: DejaVu Sans Mono (default), JetBrains Mono, Fira Mono, Source Code Pro, Inconsolata,
  game fonts, and any LibSharedMedia font. Size 8 to 28.
- Schemes: Dark, Light, Graphite, Charcoal, Paper, Monokai, Solarized Dark (palettes after the
  built-in themes of VS Code and JetBrains IDEs). Each macro token has a semantic role (keyword, property, string, ...),
  and a scheme colors roles, so new schemes are easy to add in `Themes.lua`.
- Unknown commands and conditions are shown in the error color.
- Mac: when a macro with `[mod:cmd]` is on a key that macOS uses with Cmd (Cmd+Q quits the game,
  Cmd+W, Cmd+H, Cmd+Tab, Cmd+Space, ...), the status bar warns. Keys are found from a direct
  `MACRO name` binding and the standard action bars; bars of addons (Bartender, ElvUI) are not checked.

## Commands

- `/ms` - open / close the editor
- `/ms autocomplete` - toggle autocomplete
- `/ms debug` - print the editor's key events (to diagnose key handling)

## Layout

- `MacroSense/Parser.lua`: what the word under the cursor is. Pure Lua.
- `MacroSense/Highlight.lua`: tokenizer, colorizer, cursor mapping between raw and colored text. Pure Lua.
- `MacroSense/Completion.lua`: ranks suggestions. Pure Lua.
- `MacroSense/Data.lua`, `MacroSense/Themes.lua`: static commands, conditions, units; fonts, schemes.
- `MacroSense/Sources.lua`: live slash commands, spellbook and items (Retail and Classic APIs).
- `MacroSense/Shortcuts.lua`: macOS shortcut check for `[mod:cmd]`.
- `MacroSense/CodeBox.lua`: the highlighted EditBox with undo.
- `MacroSense/Autocomplete.lua`, `MacroSense/Popup.lua`: suggestion list.
- `MacroSense/Widgets.lua`, `MacroSense/Window.lua`: the window.

## Tests

```sh
lua tests/run.lua   # parser, completion, highlighting, schemes
lua tests/ui.lua    # the whole addon against a fake WoW API
```

## Fonts

Shipped fonts are free: DejaVu (Bitstream Vera license), JetBrains Mono, Fira Mono,
Source Code Pro and Inconsolata (SIL OFL 1.1). Licenses are in `MacroSense/Media/Fonts/`.
