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
      vim.cmd [[
        highlight NeoTreeNormal guibg=NONE ctermbg=NONE
        highlight NeoTreeNormalNC guibg=NONE ctermbg=NONE
        highlight NeoTreeEndOfBuffer guibg=NONE ctermbg=NONE
        highlight WinSeparator guibg=NONE guifg=NONE
        set fillchars+=vert:\  
      ]]

      -- Setup NeoTree tanpa separator
      require("neo-tree").setup({
        window = {
          width = 30,
          position = "left",
          mappings = {},
          -- Disable border separator dari Neo-tree
          border = "none",
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
  },
}
