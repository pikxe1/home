vim.pack.add({
    { src = "https://github.com/nvim-mini/mini.statuscolumn" },
})

local statuscolumn = require("mini.statuscolumn")

-- The default `=lfs` layout puts signs directly beside the line number (for
-- example, `4W`). Keep the compact single sign slot, but give it a clear
-- boundary from the number instead of reserving a second, usually empty slot.
local content = statuscolumn.gen_content.main({
    { format = "=lfs", sign = " %s", sep = "▏" },
    { ltype = "virt", lnum = "•" },
    { ltype = "wrap", lnum = "↳" },
    { win = "inactive", sep = " " },
})

statuscolumn.setup({ content = content })
