return {
  -- 1. Everblush Official Colorscheme Plugin
  {
    "Everblush/nvim",
    name = "everblush",
    lazy = false,
    priority = 1000,
    opts = {
      transparent_background = true,
      nvim_tree = {
        contrast = false,
      },
    },
    config = function(_, opts)
      require("everblush").setup(opts)
      vim.cmd.colorscheme("everblush")

      -- Pastikan borderless separator dan tree lines tetap bersih
      local apply_minimal_hl = function()
        local bg = "#141b1e"
        vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "WinSeparator", { fg = bg, bg = "NONE" })
        vim.api.nvim_set_hl(0, "VertSplit", { fg = bg, bg = "NONE" })
        vim.api.nvim_set_hl(0, "SnacksWinSeparator", { fg = bg, bg = "NONE" })
        vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = bg, bg = "NONE" })
        vim.api.nvim_set_hl(0, "SnacksPickerTree", { fg = "NONE", bg = "NONE" })
        vim.api.nvim_set_hl(0, "FloatBorder", { fg = bg, bg = "NONE" })
        vim.api.nvim_set_hl(0, "EndOfBuffer", { fg = bg, bg = "NONE" })
        vim.api.nvim_set_hl(0, "CursorLine", { bg = "NONE" })

        -- Hilangkan garis bergelombang spellchecker
        vim.api.nvim_set_hl(0, "SpellBad", { underline = false, undercurl = false, sp = "NONE" })
        vim.api.nvim_set_hl(0, "SpellCap", { underline = false, undercurl = false, sp = "NONE" })
        vim.api.nvim_set_hl(0, "SpellLocal", { underline = false, undercurl = false, sp = "NONE" })
        vim.api.nvim_set_hl(0, "SpellRare", { underline = false, undercurl = false, sp = "NONE" })
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = apply_minimal_hl,
      })
      apply_minimal_hl()
    end,
  },

  -- 2. Transparent background plugin (tembus blur terminal & compositor)
  {
    "xiyaowong/transparent.nvim",
    lazy = false,
    priority = 999,
    opts = {
      extra_groups = {
        "NormalFloat",
        "FloatBorder",
        "FloatTitle",
        "TelescopeNormal",
        "TelescopeBorder",
        "TelescopePromptNormal",
        "TelescopePromptBorder",
        "NeoTreeNormal",
        "NeoTreeNormalNC",
        "SnacksPickerNormal",
        "SnacksPickerBorder",
        "SnacksDashboardNormal",
        "BlinkCmpMenu",
        "BlinkCmpMenuBorder",
        "WhichKeyNormal",
        "WhichKeyBorder",
        "StatusLine",
        "StatusLineNC",
        "TabLine",
        "TabLineFill",
        "TabLineSel",
        "WinSeparator",
        "VertSplit",
        "SnacksWinSeparator",
      },
    },
    config = function(_, opts)
      require("transparent").setup(opts)
      require("transparent").clear_prefix("NeoTree")
      require("transparent").clear_prefix("Snacks")
      require("transparent").clear_prefix("Telescope")
      require("transparent").clear_prefix("BlinkCmp")
    end,
  },

  -- 3. Set LazyVim colorscheme to everblush
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "everblush",
    },
  },

  -- 4. Lualine with everblush theme
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options.theme = "everblush"
      opts.options.component_separators = ""
      opts.options.section_separators = ""
    end,
  },
}
