return {
  {
    "echasnovski/mini.nvim",
    version = false,
    config = function()
      require('mini.basics').setup({
        -- Options. Set to `false` to disable.
        options = {
          basic = true,
          extra_ui = false,
          win_borders = 'default',
        },

        mappings = {
          basic = true,
          option_toggle_prefix = [[\]],
          windows = false,
          move_with_alt = false,
        },

        autocommands = {
          basic = true,
          relnum_in_visual_mode = false,
        },

        silent = false,
      })
      require("mini.starter").setup({
        evaluate_single = true,
        header = table.concat({
          " ███╗   ██╗██╗   ██╗██╗███╗   ███╗ ",
          " ████╗  ██║██║   ██║██║████╗ ████║ ",
          " ██╔██╗ ██║██║   ██║██║██╔████╔██║ ",
          " ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
          " ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
          " ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝ ", }, "\n"),
        items = {
          { name = "New File",     action = "enew",                         section = "Menu" },
          { name = "Find File",    action = "Telescope find_files",         section = "Menu" },
          { name = "Recent Files", action = "Telescope oldfiles",           section = "Menu" },
          { name = "Config",       action = "edit ~/.config/nvim/init.lua", section = "Menu" },
          { name = "Quit",         action = "qa",                           section = "Menu" },
        },
        footer = ""
      })
      require("mini.comment").setup()
      require("mini.pairs").setup()
      require("mini.surround").setup()
      require('mini.ai').setup()
      require("mini.indentscope").setup({
        symbol = ".",
        options = { try_as_border = true },
      })

      vim.api.nvim_set_hl(0, 'MiniStatuslineDevinfo', { fg = '#75a98d', bg = 'NONE' })
      vim.api.nvim_set_hl(0, 'MiniStatuslineFileinfo', { fg = '#75a98d', bg = 'NONE' })
      vim.api.nvim_set_hl(0, 'MiniStatuslineInactive', { fg = '#75a98d', bg = 'NONE' })
      vim.api.nvim_set_hl(0, 'MiniStatuslineFilename', { bg = 'NONE' })
      vim.api.nvim_set_hl(0, 'MiniStatuslineModeNormal', { fg = '#000000', bg = '#75a98d', bold = true })
    end,
  },
}
