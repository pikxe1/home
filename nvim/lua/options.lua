local opt = vim.opt

-- Make the system LLVM installation available to clangd and Treesitter on
-- Windows without requiring Neovim itself to be launched from a dev shell.
if vim.fn.has("win32") == 1 then
    local llvm_bin = "C:/Program Files/LLVM/bin"
    if vim.fn.isdirectory(llvm_bin) == 1 and not vim.env.PATH:find(llvm_bin, 1, true) then
        vim.env.PATH = llvm_bin .. ";" .. vim.env.PATH
    end
end

-- Indentation
------------------------------------------
opt.tabstop = 8 -- Tab width    // https://www.reddit.com/r/vim/wiki/tabstop/
opt.shiftwidth = 4 -- Indent width
opt.softtabstop = 4 -- Soft tab stop
opt.expandtab = true -- Use spaces instead of tabs
opt.autoindent = true -- Copy indent from current line
opt.shiftround = true -- Round indent

-- Search settings
------------------------------------------
opt.ignorecase = true -- Case insensitive search
opt.smartcase = true -- Case sensitive if uppercase in search
opt.hlsearch = true -- Highlight all search results
opt.incsearch = true -- Show matches as you type
    
-- Visual settings
------------------------------------------
opt.number = true -- Line numbers
opt.relativenumber = false -- Relative line numbers
opt.cursorline = true -- Highlight current line
opt.wrap = false -- Don't wrap lines
opt.scrolloff = 8 -- Keep 10 lines above/below cursor
opt.sidescrolloff = 8 -- Keep 8 columns left/right of cursor
opt.termguicolors = true -- Enable 24-bit colors
opt.signcolumn = "yes" -- Always show sign column
opt.showmatch = true -- Highlight matching brackets
opt.cmdheight = 2 -- Cmd line height
opt.confirm = true -- Confirm to save changes before exiting modified buffer
opt.synmaxcol = 300 -- Syntax highlighting limit in column
opt.ruler = false -- Disable the default ruler (line,col number in status line)
opt.virtualedit = "onemore" -- Allow cursor to move one past the last char in current line
opt.showcmd = false -- Do not show the selected character info
opt.showmode = false -- Don't show mode in command line
-- opt.winminwidth = 5 -- Minimum window width
-- opt.winblend = 0 -- Floating window transparency
opt.laststatus = 3 -- global statusline
opt.list = false -- Show some invisible characters (tabs...)
opt.winborder = "rounded" -- global floating window border (all vim.lsp, vim.diagnostic, etc.)
opt.fillchars = {
    foldopen    = "",
    foldclose   = "",
    diff        = "╱",
    eob         = "",
    lastline    = "󰇘",
    trunc       = "…",
    truncrl     = "…",
}

-- Completion Options
------------------------------------------
opt.pumheight = 8 -- Ins-Cpl menu height
-- opt.pummaxwidth = 60 -- Ins-Cpl popup width
opt.completeopt = "menu,menuone,noinsert,popup" -- Insert the selected item only when it is confirmed
opt.pumborder = "rounded" -- completion popup menu border

-- File handling
------------------------------------------
opt.backup = false -- Don't create backup files
-- opt.writebackup = false -- Don't create backup before writing
-- opt.swapfile = false -- Don't create swap files
opt.undofile = true -- Persistent undo
opt.undolevels = 10000
opt.undodir = vim.fn.expand("~/.nvim/undodir") -- Undo directory
opt.isfname:append("@-@")
opt.updatetime = 1000 -- time for swap file update and for CursorHold
opt.timeoutlen = 1000 -- time for key maps sequences
opt.ttimeoutlen = 50 -- Terminal Key code timeout
opt.autoread = true -- Auto reload files changed outside vim

-- Behavior settings
------------------------------------------
opt.winfixbuf = false -- disable winfixbuf globally
opt.hidden = true -- Allow hidden buffers
opt.errorbells = false -- No error bells
opt.backspace = "indent,eol,start,nostop" -- Better backspace behavior
opt.autochdir = false -- Don't auto change directory
-- opt.path:append("**") -- include subdirectories in search
opt.mouse = "a" -- Enable mouse support
opt.clipboard = "unnamedplus" -- Sync with system clipboard
opt.modifiable = true -- Allow buffer modifications CHECK - good for readonly
opt.encoding = "UTF-8" -- Set encoding

-- Native, editor-style selection
------------------------------------------
opt.keymodel = "startsel,stopsel"
opt.selectmode = "key,mouse"
opt.selection = "exclusive"
opt.whichwrap:append({ ["<"] = true, [">"] = true, ["["] = true, ["]"] = true })

-- Folding settings
------------------------------------------
opt.smoothscroll = false -- does not work properly
opt.foldlevel = 99 -- Start with all folds open
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep --no-heading --smart-case"

-- Split behavior
------------------------------------------
opt.splitbelow = true -- Horizontal splits go below
opt.splitright = true -- Vertical splits go right
opt.splitkeep = "screen" -- Make the original window remain still when split screen

-- Command-line completion
------------------------------------------
opt.wildmenu = true
opt.wildmode = "longest:full,full"
opt.wildignore:append({ "*.o" })

-- Better diff options
------------------------------------------
opt.diffopt:append("linematch:60")

-- Performance improvements
------------------------------------------
opt.redrawtime = 10000
opt.maxmempattern = 20000

-- Markdown
-- ref: https://vi.stackexchange.com/questions/25956/no-highlighting-for-replacement-text-using-conceal/25957
-- ref: https://alok.github.io/2018/05/09/more-about-vim-conceal/
-- ref: https://gist.github.com/huytd/668fc018b019fbc49fa1c09101363397
------------------------------------------
opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
vim.g.markdown_recommended_style = 0


-- Random
------------------------------------------

-- Create undo directory for undodir
local undodir = vim.fn.expand("~/.nvim/undodir")
if vim.fn.isdirectory(undodir) == 0 then
    vim.fn.mkdir(undodir, "p")
end

-- `.env`, `.env.*` and `*.env` are detected as filetype `env` by Neovim itself
vim.filetype.add({
    extension = {
        txt = "markdown",
        ejs = "embedded_template",
    },
    filename = {
        ["env"] = "env",
    },
})
