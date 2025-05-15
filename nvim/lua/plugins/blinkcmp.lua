return {
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      -- Snippet Engine
      {
        "L3MON4D3/LuaSnip",
        build = (function()
          if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
            return
          end
          return "make install_jsregexp"
        end)(),
      },
      "saadparwaiz1/cmp_luasnip", -- Sumber snippet untuk cmp

      -- Sumber Autocomplete
      "hrsh7th/cmp-nvim-lsp", -- Dari LSP
      "hrsh7th/cmp-buffer",   -- Dari text di buffer
      "hrsh7th/cmp-path",     -- Path filesystem
      "hrsh7th/cmp-cmdline",  -- Untuk command line

      -- Tambahan
      "rafamadriz/friendly-snippets", -- Snippet template
      "onsails/lspkind.nvim",         -- Ikon VSCode-style
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")
      require("luasnip").filetype_extend("html", { "javascript" })
      -- Muat snippet bawaan
      require("luasnip.loaders.from_vscode").lazy_load()
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          -- Navigasi item
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),

          -- Scroll dokumentasi
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),

          -- Kontrol menu
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),

          -- Konfirmasi pilihan
          ["<CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true, -- Auto-select item pertama
          }),

          -- Super Tab (Enhanced Tab)
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),

          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 },
          { name = "luasnip",  priority = 750 },
          { name = "buffer",   priority = 500 },
          { name = "path",     priority = 250 },
          { name = "codeium",  priority = 100 },
        }),
        formatting = {
          format = lspkind.cmp_format({
            mode = "symbol_text",
            maxwidth = 50,
            ellipsis_char = "...",
            menu = {
              buffer = "[Buf]",
              nvim_lsp = "[LSP]",
              luasnip = "[Snip]",
              path = "[Path]",
            },
          }),
        },
        experimental = {
          ghost_text = true, -- Teks transparan preview
        },
        performance = {
          throttle = 100, -- Delay 100ms setelah mengetik
        },
      })

      -- Autocomplete untuk command line (/ dan :)
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = "buffer" } },
      })
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
      })
    end,
  },
}
