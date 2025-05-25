return {
  {
    "xiyaowong/transparent.nvim",
    config = function()
      require("transparent").setup({
        extra_groups = {
          "Normal",
          "NormalNC",
          "EndOfBuffer",
          "LineNr",
          "SignColumn",
          "CursorLine",
          "CursorLineNr",
          "StatusLine",
          "StatusLineNC",
        },
        exclude = {},
      })
      vim.cmd([[
        hi Normal guibg=NONE ctermbg=NONE
        hi NormalNC guibg=NONE ctermbg=NONE
        hi EndOfBuffer guibg=NONE ctermbg=NONE
        hi LineNr guibg=NONE ctermbg=NONE
        hi SignColumn guibg=NONE ctermbg=NONE
        hi CursorLine guibg=NONE ctermbg=NONE
        hi CursorLineNr guibg=NONE ctermbg=NONE
        hi StatusLine guibg=NONE ctermbg=NONE
        hi StatusLineNC guibg=NONE ctermbg=NONE
          hi NormalFloat guibg=NONE
  hi FloatBorder guibg=NONE
      ]])
    end
  },
  {
    'sainnhe/gruvbox-material',
    lazy = false,
    priority = 1000,
    config = function()
      -- Override warna di sini (pastikan tidak ada typo)
      vim.g.gruvbox_material_colors_override = {
        yellow = { "#6c7a71", 214 },
        fg0 = { "#8a938c", 223 },
        orange = { "#90a397", 208 },
        green = { " #5a665f", 142 }
      }

      vim.cmd('colorscheme gruvbox-material')
    end
  }

}
