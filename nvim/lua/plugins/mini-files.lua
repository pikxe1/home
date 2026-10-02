vim.pack.add({
    { src = "https://github.com/nvim-mini/mini.files" },
})

require("mini.files").setup({
    options = {
        permanent_delete = false,
    },
    windows = {
        preview = true,
    },
})
