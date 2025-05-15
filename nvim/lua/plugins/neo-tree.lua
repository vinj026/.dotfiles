return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- optional: untuk ikon
      "MunifTanjim/nui.nvim",
    },
    config = function()
      -- Set highlight untuk transparansi
      vim.api.nvim_set_hl(0, "NeoTreeNormal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", { fg = "#1f1d2e", bg = "none" })

      -- Setup NeoTree
      require("neo-tree").setup({
        window = {
          width = 30,
        },
        default_component_configs = {
          indent = {
            padding = 0,
          },
          icon = {
            folder_empty = "󰜌",
            folder_nonempty = "",
          },
        },
        renderer = {
          add_trailing = false,
          group_empty = false,
        },
      })
    end,
  }
}
