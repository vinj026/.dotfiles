return {
  {
    "xiyaowong/transparent.nvim", -- Plugin transparan
    config = true,
  },
  {
    "EdenEast/nightfox.nvim",
    lazy = false,    -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require("nightfox").setup({
        options = {
          styles = {
            comment = "italic",
            keyword = "bold",
            functions = "italic,bold"
          }
        }
      })
      require("transparent").setup({
        enable = true,
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

      vim.cmd [[ colorscheme terafox ]]
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
      ]])
    end
  }
}
