# Neovim configuration

A Lua-based Neovim setup that aims to be a close **VS Code replacement**, with familiar keybindings for selection, clipboard operations, navigation, completion, and language tools. It combines Neovim's native LSP, completion, snippets, commenting, and package management with a small set of focused plugins.

The editing model keeps Neovim's modes while making common editor actions feel familiar: Shift-based selections, Ctrl+S to save, Ctrl+C/X/V for clipboard operations, F2 to rename symbols, and Shift+Alt+F to format. Shortcut availability depends on the mode, as documented below.

## Setup

### Requirements

- A recent **Neovim** build providing `vim.pack`, `vim.lsp.config` / `vim.lsp.enable`, native LSP completion, and `vim.snippet`. Startup also unconditionally enables the internal `vim._core.ui2` UI; compatibility therefore depends on that module being available in your build.
- **Git** and access to GitHub for initial plugin installation and updates.
- **ripgrep** (`rg`) for project text search and the configured `:grep` command.
- **clangd** on `PATH` for the configured C/C++ language tooling. Language servers are installed separately from this configuration.
- For installing missing Tree-sitter parsers: the **`tree-sitter` CLI** and a working C compiler. On Windows, the automatic installation check also requires **`cl`** on `PATH`, typically from a Visual Studio developer shell.
- A working **system clipboard provider** for the `+` register. A font with Nerd Font glyphs is useful for the configured symbols.

On Windows, `options.lua` adds `C:/Program Files/LLVM/bin` to `PATH` when that directory exists, making an LLVM installation's tools available inside Neovim.

### Symlink the configuration

Clone this repository, then **symlink its `nvim/` directory into Neovim's configuration location**.

Start `nvim`. Each plugin module registers its dependency with `vim.pack.add()`, which installs missing plugins. Tree-sitter installation follows the toolchain checks described below. Run `:checkhealth` to inspect your environment and `:checkhealth vim.lsp` for language-server issues.

## File structure

```text
nvim/
├── init.lua                      # Entry point and module loading order
└── lua/
    ├── options.lua               # Editor options, environment, filetype overrides
    ├── autocmds.lua              # Event-driven editor behavior
    ├── keymaps.lua               # Editing shortcuts and custom helper functions
    ├── scroll.lua                # Selection cancellation and scroll jumplist origins
    └── plugins/
        ├── init.lua              # Loads all plugin configuration modules
        ├── lsp.lua               # clangd, diagnostics, completion, LSP shortcuts
        ├── treesitter.lua        # Parser installation, highlighting, folds, indentation
        ├── mini-files.lua        # File explorer
        ├── mini-picker.lua       # File/text/buffer pickers and result display
        ├── mini-pairs.lua        # Automatic pairing and smart double quotes
        ├── mini-statuscolumn.lua # Line-number, fold, and sign gutter
        └── mini-statusline.lua   # Global statusline
```

## Plugins

Plugins are managed by Neovim's built-in `vim.pack`.

| Plugin | Purpose and configuration |
| --- | --- |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | Supplies language-server configurations; this setup enables `clangd` and uses native Neovim LSP APIs. |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Uses the `main` branch for parser installation and query-based indentation; native Tree-sitter APIs handle highlighting and folding. |
| [mini.files](https://github.com/nvim-mini/mini.files) | File explorer with previews enabled and permanent deletion disabled. |
| [mini.pick](https://github.com/nvim-mini/mini.pick) | Fuzzy file/buffer finding, live text search, and the combined LSP definition/implementation picker. |
| [mini.pairs](https://github.com/nvim-mini/mini.pairs) | Automatic delimiter pairing with custom double-quote handling. |
| [mini.statuscolumn](https://github.com/nvim-mini/mini.statuscolumn) | Compact gutter with line numbers, folds, and a separated sign slot; custom markers for virtual and wrapped lines. |
| [mini.statusline](https://github.com/nvim-mini/mini.statusline) | Default Mini statusline, displayed globally across splits through `laststatus = 3`. |

Update plugins with `:lua vim.pack.update()` and review the package manager's update buffer. Updating `nvim-treesitter` triggers a scheduled `:TSUpdate` to keep installed parsers compatible. This repository currently does not track a package lockfile.

## Keybindings

The **leader key is Space** and the local leader is `\`. In the tables, `Space F F` means press those keys in sequence; `Ctrl+K, Ctrl+I` is a two-part chord. Letter keys are lowercase unless Shift is stated. Modes are **N** (Normal), **I** (Insert), **V** (Visual), **S** (Select), and **C** (command line).

Shift-based navigation and mouse selection use native Select mode, where typing replaces the selection. Esc returns to Normal mode. Terminal support determines whether modified keys such as Ctrl+Shift+arrows, Ctrl+Space, and Ctrl+Enter are distinguishable.

### Editing and navigation

| Keys | Modes | Action |
| --- | --- | --- |
| Ctrl+S | N, I, V, S | Save the current file if modified. |
| Ctrl+A | N, I, V, S | Select the entire buffer. |
| Ctrl+C / Ctrl+X | V, S | Copy / cut the selection to the system clipboard. |
| Ctrl+C / Ctrl+X | N | Copy / cut the current line. |
| Ctrl+V | N, I, V, S, C | Paste; replace a selection or paste into the command line as appropriate. |
| Ctrl+Z / Ctrl+Y | N, I | Undo / redo. |
| Ctrl+Left / Ctrl+Right | N, I | Move by words. |
| Ctrl+Shift+Left / Right | N, I, V, S | Select toward the start / end of a word. |
| Alt+Left / Alt+Right | N, I, V, S, C; operator-pending | Move toward line start / end; extend Visual selections. Command-line mappings use Home / End. |
| Shift+Alt+Left / Right | N, I, V, S | Select to line start / end through native Shift+Home / End. |
| Alt+Up / Alt+Down | N, V, S | Move the current line or selected lines and reindent. |
| Alt+D | N | Delete the current line without replacing the clipboard. |
| Ctrl+Backspace | I, C | Delete the previous word. Uses Ctrl+H outside Neovide. |
| Ctrl+Delete | I, C | Delete the next word. |
| Alt+[ / Alt+] | N | Jump backward / forward through the jumplist. |
| Tab / Shift+Tab | V, S | Indent / unindent while retaining the selection; active Select-mode snippets take priority. |
| `a` | N | Enter Insert mode using `i` semantics. |

The configuration also compensates for the cursor moving left on leaving Insert mode and allows the cursor one position beyond the last character of a line.

Mouse-wheel scrolling (including horizontal and modified wheel events), PageUp / PageDown, and Ctrl+U / Ctrl+D / Ctrl+B / Ctrl+E cancel Visual or Select mode before scrolling. Insert mode stays active when scrolling with the wheel or page keys; its Ctrl-key editing commands retain their native behavior. Native mouse scrolling still affects the split under the pointer.

The cursor's position before the first scroll is added to that window's jumplist. Use **Alt+[** or **Ctrl+O** in Normal mode to return to it, and **Alt+]** or **Ctrl+I** to jump forward again. Repeated scrolling, direction changes, and pauses share one origin until another action, such as editing, cursor navigation, clicking, or jumping. This action-based debounce prevents a pause to read from adding an intermediate location. Ctrl+F and Ctrl+Y retain their configured Find and Redo actions.

Neovim discards jumplist entries on the cursor's current line, even when their columns differ. For horizontal scrolling, the same back / forward shortcuts therefore use a temporary return point to preserve the exact column until another action.

### Search, files, and saved changes

| Keys | Modes | Action |
| --- | --- | --- |
| Ctrl+F | N | Start a buffer search. |
| Ctrl+F | V, S | Start a search prefilled with the selected text. |
| Ctrl+R | V, S | Prepare a whole-buffer substitution using the selected text as the search pattern; enter the replacement and flags. |
| Ctrl+/ | N, V, S | Toggle a line / selection comment using native `gcc` / `gc`. The mapping is encoded as Ctrl+_ for terminals. |
| Space F F | N | Find files. |
| Space F G | N | Search project text live. |
| Space F B | N | Find open buffers. |
| Space D S | N | Open a side-by-side diff against the file's saved contents. |
| Esc | N | Close the saved-file diff if open; otherwise clear search highlighting and command messages. |

The saved-file diff requires an existing file on disk and compares against a snapshot taken when the diff opens. It is useful for reviewing edits before saving.

### Language-server actions

These buffer-local mappings are installed when an LSP client attaches, except Ctrl+Enter and the global diagnostics toggle. The server must support the requested action.

| Keys | Modes | Action |
| --- | --- | --- |
| Ctrl+Enter | N | Pick from combined definitions and implementations. |
| Space L D | N | Go to definition. |
| Space L R | N | Go to implementation. |
| Shift+F12 | N | Find references. |
| F2 | N | Rename symbol. |
| Ctrl+. | N, V | Request code actions. |
| Ctrl+K, Ctrl+I | N | Show hover information. |
| Ctrl+Shift+Space | N, I | Show signature help. |
| Shift+Alt+F | N, V | Format the document, when supported. |
| F8 / Shift+F8 | N | Go to the next / previous diagnostic and show its float. |
| Ctrl+Shift+M | N | Show diagnostics in a floating window. |
| Space T D | N | Toggle diagnostics display. |
| Space L H | N | Toggle buffer inlay hints, when supported. |
