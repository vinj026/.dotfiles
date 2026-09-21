return {
  -- 1. Minimalist File Tree & Pickers (Snacks.nvim)
  {
    "folke/snacks.nvim",
    opts = {
      styles = {
        minimal = {
          wo = {
            fillchars = "eob: ,lastline:…,vert: ,horiz: ",
          },
        },
        split = {
          wo = {
            fillchars = "eob: ,lastline:…,vert: ,horiz: ",
          },
        },
      },
      picker = {
        -- Hapus garis pohon (│, ├╴, └╴) -> gunakan indentasi spasi bersih
        icons = {
          tree = {
            vertical = "  ",
            middle   = "  ",
            last     = "  ",
          },
        },
        layouts = {
          sidebar = {
            preview = "main",
            layout = {
              backdrop = false,
              width = 36,
              min_width = 30,
              height = 0,
              position = "left",
              border = "none",
              box = "vertical",
              {
                win = "input",
                height = 1,
                border = "none",
                title = "{title}",
                title_pos = "center",
              },
              { win = "list", border = "none" },
            },
          },
        },
        sources = {
          explorer = {
            layout = {
              preset = "sidebar",
              preview = false,
            },
            auto_close = false,
            formatters = {
              file = {
                filename_only = true,
              },
            },
          },
        },
      },
    },
  },

  -- 2. Minimalist Flat Lualine
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options.component_separators = ""
      opts.options.section_separators = ""
    end,
  },
}
