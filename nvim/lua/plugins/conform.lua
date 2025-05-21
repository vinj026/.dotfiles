return {
  'stevearc/conform.nvim',
  config = function()
    require("conform").setup({
      formatters_by_ft = {
        javascript = { "prettierd", "prettier" },
        html = { "prettierd", "prettier" },
        css = { "prettierd", "prettier" },
        vue = { "prettierd", "prettier" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = true,     -- Menggunakan LSP untuk fallback
      },
      stop_after_first = true, -- Ditempatkan di luar
    })
  end
}
