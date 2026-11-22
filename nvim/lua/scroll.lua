local M = {}

function M.setup()
    local sessions = {}
    local same_line_return = nil
    local scroll_keys = {}
    local jump_keys = {}
    local recording = false
    local namespace = vim.api.nvim_create_namespace("config.scroll")
    local group = vim.api.nvim_create_augroup("config.scroll", { clear = true })

    local function reset()
        if not recording then
            sessions = {}
            same_line_return = nil
        end
    end

    -- A scroll session survives idle pauses. Only another action re-arms it,
    -- so stopping to read never adds the intermediate position to the jumplist.
    vim.on_key(function(_, typed)
        if not typed or typed == "" then
            return
        end
        -- GUI/RPC input can encode Ctrl keys differently from vim.keycode().
        local name = vim.fn.keytrans(typed):lower()
        local mode = vim.fn.mode()
        if not scroll_keys[name]
            and not (jump_keys[name] and mode == "n")
            and not (name:match("^%d+$") and mode == "n")
            and not name:find("scrollwheel", 1, true)
            and name ~= "<mousemove>"
        then
            reset()
        end
    end, namespace)

    local function jump(backward)
        local win = vim.api.nvim_get_current_win()
        local buf = vim.api.nvim_get_current_buf()
        local cursor = vim.api.nvim_win_get_cursor(win)
        local session = sessions[win]
        local count = vim.v.count1
        local destination
        if backward and session and session.buf == buf
            and session.origin[1] == cursor[1] and session.origin[2] ~= cursor[2]
        then
            -- Neovim prunes same-line jumps without comparing columns. Keep
            -- one transient return point so horizontal scrolling is reversible.
            destination = session.origin
            same_line_return = { win = win, buf = buf, origin = destination, destination = cursor }
        elseif backward and same_line_return and same_line_return.win == win
            and same_line_return.buf == buf and vim.deep_equal(cursor, same_line_return.destination)
        then
            destination = same_line_return.origin
        elseif not backward and same_line_return and same_line_return.win == win
            and same_line_return.buf == buf and vim.deep_equal(cursor, same_line_return.origin)
        then
            destination = same_line_return.destination
        else
            same_line_return = nil
        end
        sessions = {}
        if destination then
            vim.api.nvim_win_set_cursor(win, destination)
            count = count - 1
        end
        if count > 0 then
            same_line_return = nil
            vim.cmd.normal({ args = { count .. vim.keycode(backward and "<C-o>" or "<C-i>") }, bang = true })
        end
    end

    for _, key in ipairs({ "<C-o>", "<M-[>", "<C-i>", "<M-]>" }) do
        jump_keys[vim.fn.keytrans(vim.keycode(key)):lower()] = true
        local backward = key == "<C-o>" or key == "<M-[>"
        vim.keymap.set("n", key, function()
            jump(backward)
        end, { desc = backward and "Jump backward" or "Jump forward" })
    end
    jump_keys["<tab>"] = true
    jump_keys["<c-i>"] = true

    vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave", "TextChanged", "TextChangedI" }, {
        group = group,
        callback = reset,
    })
    vim.api.nvim_create_autocmd("WinClosed", {
        group = group,
        callback = function(event)
            sessions[tonumber(event.match)] = nil
        end,
    })

    -- Called by <Cmd>, outside the expression mapping's textlock and after
    -- leaving Visual/Select mode, but before Neovim processes the scroll key.
    M.record = function()
        for win, session in pairs(sessions) do
            if not session.recorded and vim.api.nvim_win_is_valid(win)
                and vim.api.nvim_win_get_buf(win) == session.buf
            then
                recording = true
                vim.api.nvim_win_call(win, function()
                    local cursor = vim.api.nvim_win_get_cursor(win)
                    vim.api.nvim_win_set_cursor(win, session.origin)
                    -- Unlike setpos(), m' also adds the position to the jumplist.
                    vim.cmd.normal({ args = { "m'" }, bang = true })
                    vim.api.nvim_win_set_cursor(win, cursor)
                end)
                recording = false
                session.recorded = true
            end
        end
    end

    M.keyboard = function(key, count)
        M.record()
        -- Page motions can add their own jumps. Only the session origin belongs
        -- in history, even when keyboard and wheel scrolling are mixed.
        vim.cmd.normal({ args = { count .. vim.keycode("<" .. key .. ">") }, bang = true, mods = { keepjumps = true } })
    end

    local function map_scroll(key, mouse, modes)
        scroll_keys[vim.fn.keytrans(vim.keycode(key)):lower()] = true
        vim.keymap.set(modes or { "n", "i", "x", "s" }, key, function()
            local win = mouse and vim.fn.getmousepos().winid or vim.api.nvim_get_current_win()
            if win ~= 0 and vim.api.nvim_win_is_valid(win) then
                local buf = vim.api.nvim_win_get_buf(win)
                if not sessions[win] or sessions[win].buf ~= buf then
                    same_line_return = nil
                    sessions[win] = { buf = buf, origin = vim.api.nvim_win_get_cursor(win) }
                end
            end

            local mode = vim.fn.mode()
            local selection = mode == "v" or mode == "V" or mode == "\22"
                or mode == "s" or mode == "S" or mode == "\19"
            local prefix = selection and "<C-\\><C-n>" or ""
            if not mouse then
                return prefix .. "<Cmd>lua require('scroll').keyboard('" .. key:sub(2, -2) .. "', " .. vim.v.count1 .. ")<CR>"
            end
            -- Return the original mouse event rather than a keyboard substitute:
            -- native scrolling still targets the split under the mouse pointer.
            return prefix .. "<Cmd>lua require('scroll').record()<CR>" .. key
        end, { expr = true, desc = "Scroll and remember the original cursor position" })
    end

    for _, direction in ipairs({ "Up", "Down", "Left", "Right" }) do
        for _, modifier in ipairs({ "", "S-", "C-", "M-", "C-S-", "M-S-", "C-M-", "C-M-S-" }) do
            map_scroll("<" .. modifier .. "ScrollWheel" .. direction .. ">", true)
        end
    end
    -- Ctrl+F and Ctrl+Y already mean Find and Redo in this configuration.
    for _, key in ipairs({ "<PageUp>", "<PageDown>" }) do
        map_scroll(key, false)
    end
    -- In Insert mode these control keys edit text rather than scroll.
    for _, key in ipairs({ "<C-u>", "<C-d>", "<C-b>", "<C-e>" }) do
        map_scroll(key, false, { "n", "x", "s" })
    end
end

return M
