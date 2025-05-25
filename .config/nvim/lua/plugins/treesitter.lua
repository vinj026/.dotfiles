return {
  {
    "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate", -- Update parsers secara otomatis setelah install
    config = function()
      require 'nvim-treesitter.configs'.setup {
        ensure_installed = {
          "lua", "javascript", "html", "css", "python", "go", "bash", "json", "yaml", "typescript", "vue"
        },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false, -- Menonaktifkan regex untuk highlight
        },
        indent = {
          enable = true,
        },

      }
    end,
  }
}
