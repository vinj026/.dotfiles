return {
  {
    "folke/which-key.nvim",
    opts = {
      preset = "helix",
      spec = {
        { "<BS>",      desc = "Decrement Selection", mode = "x" },
        { "<c-space>", desc = "Increment Selection", mode = { "x", "n" } },
      },
    },
  }
}
