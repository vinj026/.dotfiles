return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          globalstatus = false,
          section_separators = { left = "", right = "" },
          disabled_filetypes = {
            statusline = { "neo-tree" }
          },
          theme = {
            normal = {
              a = { fg = "#b4ccbd", bg = "#404943", gui = "bold" },
              b = { fg = "#8a938c", bg = "#353b37" },
              c = { fg = "#8a938c", bg = "NONE" },
            },
            visual = {
              a = { fg = "#272c29", bg = "#ff8678", gui = "bold" }
            }
          }
        },
        sections = {
          lualine_a = {
            { "mode", fmt = function(str) return " " .. str end },
          },
          lualine_b = { "filename" },
          lualine_c = { "branch", "diff" },
          lualine_x = { "filetype" },
          lualine_y = { "diagnostic" },
          lualine_z = { "location" },
        },
      })
    end,
  }
}
