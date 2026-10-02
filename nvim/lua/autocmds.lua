local group = vim.api.nvim_create_augroup("config.autocmds", { clear = true })

-- Hightlight Copied text
vim.api.nvim_create_autocmd("TextYankPost", {
    group = group,
    callback = function()
        vim.hl.on_yank({ timeout = 150 })
    end,
})

-- Reload files changed by another program when returning to Neovim.
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
    group = group,
    command = "checktime",
})

-- Return to the last cursor position when reopening a file.
vim.api.nvim_create_autocmd("BufReadPost", {
    group = group,
    callback = function(event)
        local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
        local line_count = vim.api.nvim_buf_line_count(event.buf)
        if mark[1] > 0 and mark[1] <= line_count then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- Equal all open window splits whenever your Neovim or terminal window is resized.
vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    command = "wincmd =",
})

-- A lone colon is interpreted as a label while it is being typed, which
-- momentarily moves expressions such as `std::` to column zero.
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "c", "cpp" },
    callback = function()
        vim.opt_local.indentkeys:remove(":")
        vim.opt_local.cinkeys:remove(":")
    end,
})

-- Close window using q
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "help", "man", "qf", "checkhealth", "lspinfo" },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set("n", "q", "<Cmd>close<CR>", {
            buffer = event.buf,
            nowait = true,
            desc = "Close window",
        })
    end,
})
