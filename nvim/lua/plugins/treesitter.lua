local group = vim.api.nvim_create_augroup("config.treesitter", { clear = true })

-- Keep installed parsers compatible whenever nvim-treesitter is updated.
vim.api.nvim_create_autocmd("PackChanged", {
	group = group,
	callback = function(event)
		local data = event.data
		if data.kind ~= "update" or data.spec.name ~= "nvim-treesitter" then
			return
		end

		vim.schedule(function()
			vim.cmd("TSUpdate")
		end)
	end,
})

vim.pack.add({
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
})

local parsers = {
	"bash",
	"c",
	"cpp",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"query",
	"toml",
	"vim",
	"vimdoc",
}

vim.treesitter.language.register("bash", "sh")
vim.treesitter.language.register("json", "jsonc")

local filetypes = vim.iter(parsers)
	:map(vim.treesitter.language.get_filetypes)
	:flatten()
	:totable()

local missing = vim.iter(parsers)
	:filter(function(parser)
		return not vim.treesitter.language.add(parser)
	end)
	:totable()

-- Neovim ships several core parsers. Install only the missing ones, and only
-- when the host has the toolchain required by the current Treesitter CLI.
local can_compile = vim.fn.executable("tree-sitter") == 1
if vim.fn.has("win32") == 1 then
	can_compile = can_compile and vim.fn.executable("cl") == 1
end
if can_compile and #missing > 0 then
	require("nvim-treesitter").install(missing)
end

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = filetypes,
	callback = function(event)
		if not pcall(vim.treesitter.start, event.buf) then
			return
		end

		vim.wo.foldmethod = "expr"
		vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

		local filetype = vim.bo[event.buf].filetype
		local language = vim.treesitter.language.get_lang(filetype)
		if language and vim.treesitter.query.get(language, "indents") then
			vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end
	end,
})
