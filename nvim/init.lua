require("vim._core.ui2").enable({})

require("options")
require("autocmds")
require("keymaps") -- Note: Place before loading plugins
require("plugins")
