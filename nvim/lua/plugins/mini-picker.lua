vim.pack.add({
    { src = "https://github.com/nvim-mini/mini.pick" },
})

local mini_pick = require("mini.pick")

local function show_without_position(buf_id, items, query)
    local display_items = vim.tbl_map(function(item)
        if type(item) ~= "string" then
            return item
        end

        local path, lnum, col, text = item:match("^(.-)%z(%d+)%z(%d+)%z(.*)$")
        if not path then
            return item
        end

        return {
            path = path,
            lnum = tonumber(lnum),
            col = tonumber(col),
            text = path .. " │ " .. text,
        }
    end, items)

    mini_pick.default_show(buf_id, display_items, query, { show_icons = true })
end

mini_pick.setup({
    mappings = {
        choose_in_vsplit = "<M-v>",
        paste_clipboard = {
            char = "<C-v>",
            func = function()
                vim.paste(vim.fn.getreg("+", 1, true), -1)
            end,
        },
    },
    source = {
        show = show_without_position,
    },
})
