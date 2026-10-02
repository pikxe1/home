local map = vim.keymap.set
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"


-- Always return to Normal mode in select mode
-- --------------------------------------------
map("s", "<Esc>", "<C-\\><C-n>", { desc = "Exit Select mode" })


-- Map a to i, for convienience
-- --------------------------------------------
map("n", "a", "i" , { desc = "Map a to i" })


-- Alt + Left/Right behaves like Home/End
-- ----------------------------------------
map({ "n", "o" }, "<M-Left>", "^", { desc = "Start of line" })
map({ "n", "o" }, "<M-Right>", "$<Right>", { desc = "End of line" })
map("i", "<M-Left>", "<C-o>^", { desc = "Start of line" })
map("i", "<M-Right>", "<C-o>$", { desc = "End of line" })
map("c", "<M-Left>", "<Home>", { desc = "Start of command line" })
map("c", "<M-Right>", "<End>", { desc = "End of command line" })
map("x", "<M-Left>", "^", { desc = "Extend to start of line" })
map("x", "<M-Right>", "$", { desc = "Extend to end of line" })
map("s", "<M-Left>", "<Esc>^", { desc = "Start of line" })
map("s", "<M-Right>", "<Esc>$", { desc = "End of line" })


-- Shift + Alt extends a selection to the start/end of the line
-- --------------------------------------------------------------
map({ "n", "i", "x", "s" }, "<M-S-Left>", "<S-Home>", {
    remap = true,
    desc = "Select to start of line",
})
map({ "n", "i", "x", "s" }, "<M-S-Right>", "<S-End>", {
    remap = true,
    desc = "Select to end of line",
})


-- Shift + Ctrl + left/right motions
-- ----------------------------------
map("n", "<C-S-Left>", "gh<C-o>b", { desc = "Select to start of word" })
map("i", "<C-S-Left>", "<C-o>gh<C-o>b", { desc = "Select to start of word" })
map("x", "<C-S-Left>", "b", { desc = "Select to start of word" })
map("s", "<C-S-Left>", "<C-o>b", { desc = "Select to start of word" })

map("n", "<C-S-Right>", "gh<C-o>e", { desc = "Select to end of word" })
map("i", "<C-S-Right>", "<C-o>gh<C-o>e", { desc = "Select to end of word" })
map("x", "<C-S-Right>", "e", { desc = "Select to end of word" })
map("s", "<C-S-Right>", "<C-o>e", { desc = "Select to end of word" })


-- Custom word motions with Ctrl-left and Ctrl-right
-- --------------------------------------------------
local function word_motion_right()
    -- Stop one position past the final character before searching for a word on the next line
    if vim.fn.col(".") == vim.fn.col("$") - 1 then
        return "<Right>"
    end
    return "e<Right>"
end

map("n", "<C-Left>", "b", { desc = "Word motion to left" })
map("n", "<C-Right>", word_motion_right, { expr = true, desc = "Word motion to right" })
map("i", "<C-Left>", "<C-o>b", { desc = "Word motion to left" })
map("i", "<C-Right>", function()
    return "<C-o>" .. word_motion_right()
end, { expr = true, desc = "Word motion to right" })


-- Word motions in Operator Pending
-- ---------------------------------
-- map("o", "<C-Left>", "b", { desc = "Word motion to left" })
-- map("o", "<C-Right>", "e", { desc = "Word motion to right" })


-- Save file
-- ----------
map({ "n", "i", "x", "s" }, "<C-s>", function()
    vim.cmd.update()
end, { desc = "Save file" })
map({ "n", "i", "x", "s" }, "<C-a>", "<Esc>ggVG<C-G>", {
    desc = "Select all",
})


-- Cut, Copy, Paste if selection is present
-- Note: `gV` prevents Select mode from restoring its selection later
-- (otherwise can mess up yank highlight)
-- ---------------------------------------
map("v", "<C-c>", '"+ygV', { desc = "Copy" })
map("v", "<C-x>", '"+d', { desc = "Cut" })
map("n", "<C-v>", 'p', { desc = "Paste" })
map("i", "<C-v>", '<C-o>P', { desc = "Paste" })
map("v", "<C-v>", 'P', { desc = "Paste over selection" })
map("c", "<C-v>", "<C-r>+", { desc = "Paste into command line" })


-- Cut/Copy/Paste line if not selection
-- -------------------------------------
map("n", "<C-c>", '"+yy', { desc = "Copy line" })
map("n", "<C-x>", '"+dd', { desc = "Cut line" })
map("n", "<M-d>", '"_dd', { desc = "Delete line" })


-- Undo/Redo
-- ----------
map({"n"}, "<C-z>", "u", { desc = "Undo" })
map({"i"}, "<C-z>", "<C-o>u", { desc = "Undo" })
map({"n"}, "<C-y>", "<C-r>", { desc = "Redo" })
map({"i"}, "<C-y>", "<C-o><C-r>", { desc = "Undo" })


-- Jumplist navigation
-- --------------------
map("n", "<M-[>", "<C-o>", { desc = "Jump backward" })
map("n", "<M-]>", "<C-i>", { desc = "Jump forward" })


-- Set Ctrl-BS and Ctrl-Del to delete next and previous word
-- -----------------------------------------------------------
if vim.g.neovide then
  map({ "i", "c" }, "<C-BS>", "<C-w>", { noremap = true, desc = "Delete previous word" })
else
  map({ "i", "c" }, "<C-H>", "<C-w>", { noremap = true, desc = "Delete previous word" })
end
map("i", "<C-Del>", "<C-O>de", { desc = "Delete next word" })
map("c", "<C-Del>", function()
    local line = vim.fn.getcmdline()
    local position = vim.fn.getcmdpos()
    local tail = line:sub(position)
    -- Delete leading whitespace and one keyword/punctuation run.
    -- Regex byte offsets match command-line cursor positions, including multibyte text.
    local length = vim.fn.matchend(tail, [[^\s*\%(\k\+\|\%(\k\@!\S\)\+\)]])
    if length < 0 then
        length = #tail -- Only whitespace (or nothing) remains.
    end
    vim.fn.setcmdline(line:sub(1, position - 1) .. tail:sub(length + 1), position)
end, { desc = "Delete next command-line word" })


-- Move the cursor to back original position when leaving Insert (fixes "i" quirk)
-- -------------------------------------------------------------------------------
local insert_cursor_col = 0
vim.api.nvim_create_autocmd({ "InsertEnter", "CursorMovedI" }, {
  callback = function()
    insert_cursor_col = vim.api.nvim_win_get_cursor(0)[2]
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    local cursor = vim.api.nvim_win_get_cursor(0)

    -- Neovim moved the cursor one character left when leaving Insert mode.
    if cursor[2] ~= insert_cursor_col then
      cursor[2] = cursor[2] + 1
      vim.api.nvim_win_set_cursor(0, cursor)
    end
  end,
})


-- Move lines
-- -----------
-- no selection moves current line
map("n", "<M-Down>", "<cmd>move .+1<CR>==", { desc = "Move line down" })
map("n", "<M-Up>", "<cmd>move .-2<CR>==", { desc = "Move line up" })
-- move visual selection
map("x", "<M-Down>", ":move '>+1<CR>gv=gv", { desc = "Move selection down" })
map("x", "<M-Up>", ":move '<-2<CR>gv=gv", { desc = "Move selection up" })
-- move select-mode selection
map("s", "<M-Down>", "<C-g>:move '>+1<CR>gv=gv<C-g>", { desc = "Move selection down" })
map("s", "<M-Up>", "<C-g>:move '<-2<CR>gv=gv<C-g>", { desc = "Move selection up" })


-- Trigger Find
-- -------------
map("n", "<C-f>", "/", { desc = "Find" })


-- Comment toggle
-- ----------------
map("n", "<C-_>", "gcc", { remap = true, desc = "Toggle comment" })
map("x", "<C-_>", "gc", { remap = true, desc = "Toggle comment selection" })
map("s", "<C-_>", "<C-g>gc", { remap = true, desc = "Toggle comment selection" })


-- File explorer and fuzzy finding
-- --------------------------------

-- map("n", "<leader>e", function()
--     local path = vim.api.nvim_buf_get_name(0)
--     require("mini.files").open(path ~= "" and path or nil)
-- end, { desc = "Open file explorer" })

map("n", "<leader>ff", function()
    require("mini.pick").builtin.files()
end, { desc = "Find files" })

map("n", "<leader>fg", function()
    require("mini.pick").builtin.grep_live()
end, { desc = "Find text" })

map("n", "<leader>fb", function()
    require("mini.pick").builtin.buffers()
end, { desc = "Find buffers" })


-- Paste the selected text when we do copy and paste 
-- --------------------------------------------------
local function selected_search_pattern()
    local selection_type = vim.fn.mode()

    -- getregion() expects Visual-mode types, even when the selection is in Select mode
    if selection_type == "s" then
        selection_type = "v"
    elseif selection_type == "S" then
        selection_type = "V"
    elseif selection_type == "\19" then
        selection_type = "\22"
    end

    local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), {
        type = selection_type,
    })
    local text = table.concat(lines, "\n")

    return vim.fn.escape(text, "\\/.*$^~[]"):gsub("\n", "\\n")
end

map("v", "<C-f>", function()
    return vim.keycode("<Esc>") .. "/" .. selected_search_pattern()
end, { expr = true, replace_keycodes = false, desc = "Find selection" })

map("v", "<C-r>", function()
    return vim.keycode("<Esc>") .. ":%s/" .. selected_search_pattern() .. "/"
end, { expr = true, replace_keycodes = false, desc = "Replace selection" })


-- Use Neovim's built-in completion menu without a completion plugin.
-- -------------------------------------------------------------------
map("i", "<C-Space>", function()
    vim.lsp.completion.get()
end, { desc = "Trigger completion" })
map("i", "<CR>", function()
    if vim.fn.pumvisible() == 1 then
        return vim.keycode("<C-y>")
    end

    return _G.MiniPairs and MiniPairs.cr() or vim.keycode("<CR>")
end, {
    expr = true,
    replace_keycodes = false,
    desc = "Accept completion or insert newline",
})


-- Make Enter keymap work for completion selection and to trigger execute in command mode
-- ---------------------------------------------------------------------------------------
map("c", "<CR>", function()
    return vim.fn.wildmenumode() == 1 and "<C-y>" or "<CR>"
end, { expr = true, desc = "Accept command completion or execute command" })


-- Make TAB keymap work for Indent / Cycle through completion menu
-- ---------------------------------------------------------------------------------------
local function select_completion_item(offset)
    -- Popup selection indexes refer to the currently visible matches, not to
    -- every completion item originally returned by the LSP server.
    local info = vim.fn.complete_info({ "matches", "selected" })
    local item_count = #info.matches
    if item_count == 0 then
        return
    end

    local target
    if info.selected == -1 then
        target = offset > 0 and 0 or item_count - 1
    else
        target = (info.selected + offset) % item_count
    end

    -- Change only the popup selection. The item is inserted by <CR> below.
    vim.api.nvim_select_popupmenu_item(target, false, false, {})
end

local function has_text_before_cursor()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local column = cursor[2]
    if column == 0 then
        return false
    end

    local line = vim.api.nvim_get_current_line()
    return line:sub(column, column):match("%s") == nil
end

local function jump_active_snippet(direction)
    if vim.snippet.active({ direction = direction }) then
        vim.snippet.jump(direction)
        return true
    end

    return false
end

map("i", "<Tab>", function()
    if vim.fn.pumvisible() == 1 then
        select_completion_item(1)
        return
    end

    if jump_active_snippet(1) then
        return
    end

    if has_text_before_cursor()
        and #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/completion" }) > 0
    then
        vim.lsp.completion.get()
        return
    end

    vim.api.nvim_feedkeys(vim.keycode("<Tab>"), "n", false)
end, { desc = "Trigger completion, jump snippet, or insert tab" })

map("i", "<S-Tab>", function()
    if vim.fn.pumvisible() == 1 then
        select_completion_item(-1)
        return
    end

    if jump_active_snippet(-1) then
        return
    end

    vim.api.nvim_feedkeys(vim.keycode("<C-d>"), "n", false)
end, { desc = "Select previous completion, jump snippet, or unindent" })

-- Indent selections while keeping them selected.
map("x", "<Tab>", ">gv", { desc = "Indent selection" })
map("x", "<S-Tab>", "<gv", { desc = "Unindent selection" })

-- Nonempty snippet placeholders use Select mode.
map("s", "<Tab>", function()
    if not jump_active_snippet(1) then
        vim.api.nvim_feedkeys(vim.keycode("<C-g>>gv<C-g>"), "n", false)
    end
end, { desc = "Jump snippet or indent selection" })

map("s", "<S-Tab>", function()
    if not jump_active_snippet(-1) then
        vim.api.nvim_feedkeys(vim.keycode("<C-g><gv<C-g>"), "n", false)
    end
end, { desc = "Jump snippet or unindent selection" })


-- Wrap the current Visual/Select selection by typing an opening delimiter.
-- -------------------------------------------------------------------------
local function surround_selection(opening, closing)
    local selection_type = vim.fn.mode()
    if selection_type == "s" then
        selection_type = "v"
    elseif selection_type == "S" then
        selection_type = "V"
    elseif selection_type == "\19" then
        selection_type = "\22"
    end

    local regions = vim.fn.getregionpos(vim.fn.getpos("v"), vim.fn.getpos("."), {
        type = selection_type,
        exclusive = vim.o.selection == "exclusive",
        eol = true,
    })
    if #regions == 0 then
        return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local first_change = true

    local function insert_at(position, text, after_character)
        local row = position[2] - 1
        local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
        local column

        if position[3] == 0 or position[3] > #line then
            column = #line
        elseif after_character then
            local character = vim.fn.charidx(line, position[3] - 1)
            column = vim.fn.byteidx(line, character + 1)
            if column < 0 then
                column = #line
            end
        else
            column = position[3] - 1
        end

        if not first_change then
            vim.cmd.undojoin()
        end
        vim.api.nvim_buf_set_text(bufnr, row, column, row, column, { text })
        first_change = false
    end

    if selection_type == "\22" then
        -- A block selection is wrapped independently on every selected line.
        for index = #regions, 1, -1 do
            insert_at(regions[index][2], closing, true)
            insert_at(regions[index][1], opening, false)
        end
    else
        insert_at(regions[#regions][2], closing, true)
        insert_at(regions[1][1], opening, false)
    end

    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
end

for key, pair in pairs({
    ['"'] = { '"', '"' },
    ["'"] = { "'", "'" },
    ["("] = { "(", ")" },
    ["["] = { "[", "]" },
    ["{"] = { "{", "}" },
}) do
    map("v", key, function()
        surround_selection(pair[1], pair[2])
    end, { desc = "Surround selection with " .. pair[1] .. pair[2] })
end

-- Show Current Unsaved changes in the buffer using `leader + ds`
-- ---------------------------------------------------------------
local diff_state = nil

local function close_diff()
    if not diff_state then
        return
    end

    local current_win = diff_state.current_win
    local saved_win = diff_state.saved_win

    if vim.api.nvim_win_is_valid(current_win) then
        vim.api.nvim_set_current_win(current_win)
        vim.cmd("diffoff")
    end

    if vim.api.nvim_win_is_valid(saved_win) then
        vim.api.nvim_win_close(saved_win, true)
    end

    if vim.api.nvim_win_is_valid(current_win) then
        vim.api.nvim_set_current_win(current_win)
    end

    diff_state = nil
end

local function open_diff()
    if  diff_state and 
        vim.api.nvim_win_is_valid(diff_state.current_win) and 
        vim.api.nvim_win_is_valid(diff_state.saved_win)
    then
        return
    end

    if diff_state then
        close_diff()
    end

    local current_buf = vim.api.nvim_get_current_buf()
    local current_win = vim.api.nvim_get_current_win()

    local file = vim.api.nvim_buf_get_name(current_buf)

    if file == "" then
        vim.notify("Buffer has no associated file", vim.log.levels.WARN)
        return
    end

    if vim.fn.filereadable(file) ~= 1 then
        vim.notify("File has not been saved yet", vim.log.levels.WARN)
        return
    end

    local filetype = vim.bo[current_buf].filetype

    vim.cmd("vnew")

    local saved_win = vim.api.nvim_get_current_win()
    local saved_buf = vim.api.nvim_get_current_buf()

    vim.bo[saved_buf].buftype = "nofile"
    vim.bo[saved_buf].bufhidden = "wipe"
    vim.bo[saved_buf].swapfile = false
    vim.bo[saved_buf].filetype = filetype

    local lines = vim.fn.readfile(file)
    vim.api.nvim_buf_set_lines(saved_buf, 0, -1, false, lines)

    vim.bo[saved_buf].modifiable = false

    -- Saved version
    vim.cmd("diffthis")

    -- Current unsaved version
    vim.api.nvim_set_current_win(current_win)
    vim.cmd("diffthis")

    diff_state = {
        current_buf = current_buf,
        current_win = current_win,
        saved_buf = saved_buf,
        saved_win = saved_win,
    }
end

vim.keymap.set("n", "<leader>ds", open_diff, {
    silent = true,
    desc = "Open diff against saved file",
})

vim.keymap.set("n", "<Esc>", function()
    if diff_state then
        close_diff()
        return
    end

    vim.cmd("nohlsearch")
    vim.cmd("echo ''")
end, {
    desc = "Close diff or clear search highlight and message",
})
