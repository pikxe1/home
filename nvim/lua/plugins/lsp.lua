vim.pack.add({
    { src = "https://github.com/neovim/nvim-lspconfig" },
})

local group = vim.api.nvim_create_augroup("config.lsp", { clear = true })

local function show_keyword_help()
    vim.cmd("normal! K")
end

local function is_nvim_config_buffer(bufnr)
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path == "" then
        return false
    end

    local normalize = function(value)
        value = vim.fs.normalize(value):gsub("\\", "/"):gsub("/+$", "")
        return vim.fn.has("win32") == 1 and value:lower() or value
    end

    path = normalize(path)
    local config_dir = normalize(vim.fn.stdpath("config"))
    return path == config_dir or vim.startswith(path, config_dir .. "/")
end

local function pick_definitions_and_implementations(bufnr, fallback_to_keyword_help)
    local methods = {
        { name = "", method = "textDocument/definition", rank = 1 },
        { name = "󱌣", method = "textDocument/implementation", rank = 2 },
    }
    local requests = {}

    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        for _, method in ipairs(methods) do
            if client:supports_method(method.method, bufnr) then
                table.insert(requests, {
                    client = client,
                    name = method.name,
                    method = method.method,
                    rank = method.rank,
                })
            end
        end
    end

    if #requests == 0 then
        if fallback_to_keyword_help then
            show_keyword_help()
        else
            vim.notify("No LSP client supports definitions or implementations", vim.log.levels.INFO)
        end
        return
    end

    local remaining = #requests
    local locations = {}

    local function finish_request()
        remaining = remaining - 1
        if remaining > 0 then
            return
        end

        local items = vim.tbl_values(locations)
        if #items == 0 then
            if fallback_to_keyword_help then
                show_keyword_help()
            else
                vim.notify("No definitions or implementations found", vim.log.levels.INFO)
            end
            return
        end

        table.sort(items, function(left, right)
            if left.rank ~= right.rank then
                return left.rank < right.rank
            end
            if left.path ~= right.path then
                return left.path:lower() < right.path:lower()
            end
            if left.lnum ~= right.lnum then
                return left.lnum < right.lnum
            end
            return left.col < right.col
        end)

        for _, item in ipairs(items) do
            local kinds = {}
            for _, method in ipairs(methods) do
                if item.kinds[method.name] then
                    table.insert(kinds, method.name)
                end
            end

            local display_path = vim.fn.fnamemodify(item.path, ":.")
            item.text = table.concat(kinds, " + ") .. " │ " .. display_path .. " │ " .. item.line_text
            item.kinds = nil
            item.line_text = nil
            item.rank = nil
        end

        require("mini.pick").start({
            source = {
                items = items,
                name = "LSP definitions + implementations",
            },
        })
    end

    for _, request in ipairs(requests) do
        local params = vim.lsp.util.make_position_params(0, request.client.offset_encoding)
        local did_request = request.client:request(
            request.method,
            params,
            vim.schedule_wrap(function(err, result)
                if not err and result then
                    local result_list = vim.islist(result) and result or { result }
                    local location_items = vim.lsp.util.locations_to_items(
                        result_list,
                        request.client.offset_encoding
                    )

                    for _, location in ipairs(location_items) do
                        local path = location.filename
                        local key = table.concat({
                            vim.fs.normalize(path):lower(),
                            location.lnum,
                            location.col,
                        }, "\0")
                        local item = locations[key]

                        if item then
                            item.kinds[request.name] = true
                            item.rank = math.min(item.rank, request.rank)
                        else
                            locations[key] = {
                                path = path,
                                lnum = location.lnum,
                                col = location.col,
                                end_lnum = location.end_lnum,
                                end_col = location.end_col,
                                line_text = vim.trim(location.text or ""),
                                kinds = { [request.name] = true },
                                rank = request.rank,
                            }
                        end
                    end
                end

                finish_request()
            end),
            bufnr
        )

        if not did_request then
            finish_request()
        end
    end
end

local function find_lsp_locations_or_config_help()
    local bufnr = vim.api.nvim_get_current_buf()
    pick_definitions_and_implementations(bufnr, is_nvim_config_buffer(bufnr))
end

local location_map_options = {
    desc = "Find definitions and implementations with config help fallback",
}

vim.keymap.set("n", "<C-Enter>", find_lsp_locations_or_config_help, location_map_options)

-- Older Windows terminals encode Ctrl+Enter as Ctrl+J instead of the
-- distinguishable <C-CR> sequence used by newer terminals and GUIs.
if vim.fn.has("win32") == 1 then
    vim.keymap.set("n", "<C-j>", find_lsp_locations_or_config_help, location_map_options)
end

vim.diagnostic.config({
    severity_sort = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    virtual_text = {
        spacing = 2,
        source = "if_many",
    },
    float = {
        source = true,
    },
})

local diagnostics_enabled = true

vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    callback = function(event)
        vim.diagnostic.enable(false, { bufnr = event.buf })
    end,
    desc = "Hide diagnostics in Insert mode",
})

vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    callback = function(event)
        if diagnostics_enabled then
            vim.diagnostic.enable(true, { bufnr = event.buf })
        end
    end,
    desc = "Restore diagnostics after Insert mode",
})

vim.keymap.set("n", "<leader>td", function()
    diagnostics_enabled = not diagnostics_enabled
    vim.diagnostic.enable(diagnostics_enabled)
    vim.notify("Diagnostics " .. (diagnostics_enabled and "enabled" or "disabled"))
end, { desc = "Toggle diagnostics display" })

vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(event)
        local client = assert(vim.lsp.get_client_by_id(event.data.client_id))
        local map = function(lhs, rhs, desc, modes)
            vim.keymap.set(modes or "n", lhs, rhs, {
                buffer = event.buf,
                desc = "LSP: " .. desc,
            })
        end

        if client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = false })
        end

        if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(false, { bufnr = event.buf })
            map("<leader>lh", function()
                local is_enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })
                vim.lsp.inlay_hint.enable(not is_enabled, { bufnr = event.buf })
            end, "Toggle Inlay Hints")
        end

        map("<leader>ld", vim.lsp.buf.definition, "Find definition")
        map("<leader>lr", vim.lsp.buf.implementation, "Find implementation")
        map("<S-F12>", vim.lsp.buf.references, "Find references")
        map("<F2>", vim.lsp.buf.rename, "Rename symbol")
        map("<C-.>", vim.lsp.buf.code_action, "Code action", { "n", "x" })
        map("<C-k><C-i>", vim.lsp.buf.hover, "Show hover")
        map("<C-S-Space>", vim.lsp.buf.signature_help, "Signature help", { "n", "i" })
        if client:supports_method("textDocument/formatting") then
            map("<S-M-f>", function()
                vim.lsp.buf.format({ async = true, bufnr = event.buf })
            end, "Format document", { "n", "x" })
        end
        map("<F8>", function()
            vim.diagnostic.jump({ count = 1, float = true })
        end, "Next problem")
        map("<S-F8>", function()
            vim.diagnostic.jump({ count = -1, float = true })
        end, "Previous problem")
        map("<C-S-m>", vim.diagnostic.open_float, "Show problem")
    end,
})

vim.lsp.config("clangd", {
    cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--completion-style=detailed",
        "--header-insertion=iwyu",
        "--function-arg-placeholders=true",
    },
})

vim.lsp.enable("clangd")
