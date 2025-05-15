return {
  {
    'stevearc/conform.nvim',
    opts = {},
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          javascript = { "prettierd", "prettier", stop_after_first = true },
          html = { "prettierd", "prettier" },
          css = { "prettierd", "prettier" },
          vue = { "prettierd", "prettier" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_format = fallback,
        },
      })
    end
  }
}
