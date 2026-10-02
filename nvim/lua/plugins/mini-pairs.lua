vim.pack.add({
    { src = "https://github.com/nvim-mini/mini.pairs" },
})
local mini_pairs = require("mini.pairs")

-- mini.pairs handles standard behavior for ' () [] {} ` out of the box
mini_pairs.setup({})

local function parse_current_line(row)
    pcall(function()
        local parser = vim.treesitter.get_parser(0)
        if parser then
            parser:parse({ row, row + 1 })
        end
    end)
end

---Find the closest comment node at the given position.
---Stops at the first match instead of traversing to the root of the AST.
local function get_comment_node(row, col)
    if col < 0 then
        return nil
    end

    local ok, node = pcall(vim.treesitter.get_node, {
        bufnr = 0,
        pos = { row, col },
    })
    if not ok or not node then
        return nil
    end

    while node do
        if node:type():find("comment", 1, true) then
            return node
        end
        node = node:parent()
    end

    return nil
end

local function is_in_comment(row, col, line)
    if col == 0 then
        return false
    end

    local left = get_comment_node(row, col - 1)
    if not left then
        return false
    end

    -- If between two characters, both must belong to the same comment node
    if col < #line then
        local right = get_comment_node(row, col)
        return right ~= nil and left == right
    end

    -- At the end of the line: verify if the comment ended before the cursor
    local _, _, end_row, end_col = left:range()
    if end_row == row and end_col <= col then
        local text_before = line:sub(1, col)
        if text_before:match("%*/$") or text_before:match("%-%->$") or text_before:match("%]%]=*$") then
            return false
        end
    end

    return true
end

---Checks whether the current line ends with an unclosed double quote.
---Still tracks single quotes lexically so quotes inside '...' (e.g. '"')
---are ignored and don't count as unclosed double quotes.
local function has_unclosed_double_quote(line, row)
    local current_quote = nil
    local escaped = false

    for i = 1, #line do
        local char = line:sub(i, i)

        if char == "\\" then
            escaped = not escaped
        else
            if not escaped and (char == '"' or char == "'") then
                if not get_comment_node(row, i - 1) then
                    if current_quote == nil then
                        current_quote = char
                    elseif current_quote == char then
                        current_quote = nil
                    end
                end
            end
            escaped = false
        end
    end

    return current_quote == '"'
end

-- Smart double quote mapping
vim.keymap.set("i", '"', function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1] - 1
    local cursor_column = cursor[2]
    local line = vim.api.nvim_get_current_line()
    local neigh_pattern = "^[^\\]"

    parse_current_line(row)

    -- 1. Jump over if a double quote is already the character under cursor
    if line:sub(cursor_column + 1, cursor_column + 1) == '"' then
        return mini_pairs.closeopen('""', neigh_pattern)
    end

    -- 2. Do not autopair inside comments
    if is_in_comment(row, cursor_column, line) then
        return '"'
    end

    -- 3. If line has an unclosed double quote, insert single " to close it
    if has_unclosed_double_quote(line, row) then
        return '"'
    end

    -- 4. Otherwise, autopair ""
    return mini_pairs.closeopen('""', neigh_pattern)
end, {
    expr = true,
    replace_keycodes = false,
    desc = "MiniPairs smart double quote",
})
