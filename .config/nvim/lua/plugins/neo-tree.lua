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
            indent_marker = "|",
            last_indent_marker = "╰"

          },
          icon = {
            folder_empty = "󰜌",
            folder_nonempty = "",
          },
        },
        enable_git_status = false,
        renderer = {
          add_trailing = false,
          group_empty = false,
        },
       
      })

      vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { fg = "#8a938c", bold = true })  -- merah terang
      vim.api.nvim_set_hl(0, "NeoTreeDirectoryIcon", { fg = "#8a938c", bold = true })  -- pink terang
      vim.api.nvim_set_hl(0, "NeoTreeFileName", { fg = "#8a938c" })                    -- hijau terang
      vim.api.nvim_set_hl(0, "NeoTreeFileNameOpened", { fg = "#8a938c", bold = true }) -- ungu terang
      vim.api.nvim_set_hl(0, "NeoTreeGitAdded", { fg = "#8a938c", bold = true })       -- biru terang
      vim.api.nvim_set_hl(0, "NeoTreeGitModified", { fg = "#8a938c", bold = true })    -- kuning terang
      vim.api.nvim_set_hl(0, "NeoTreeRootName", { fg = "#8a938c", bold = true }) -- orange terang
vim.api.nvim_set_hl(0, "FoldColumn", { fg = "NONE", bg = "NONE" })
vim.api.nvim_set_hl(0, "Folded", { fg = "NONE", bg = "NONE" })
      vim.cmd [[autocmd FileType neo-tree setlocal indentexpr=]]
    end,
  },
}
