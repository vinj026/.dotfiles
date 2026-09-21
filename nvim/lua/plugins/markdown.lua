return {
  -- Markdown inline rendering for CCNA notes & checkboxes
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
    ft = { "markdown" },
    opts = {
      heading = {
        sign = false,
        icons = { "# ", "## ", "### ", "#### ", "##### ", "###### " },
      },
      checkbox = {
        enabled = true,
        unchecked = { icon = "󰄱 " },
        checked = { icon = "󰱒 " },
      },
      code = {
        sign = false,
        width = "block",
        right_pad = 1,
      },
    },
  },
}
