-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- Matikan fitur bawaan LazyVim yang menyalakan spellcheck di file markdown/text
pcall(vim.api.nvim_del_augroup_by_name, "lazyvim_wrap_spell")

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "plaintex", "typst", "gitcommit" },
  desc = "Nonaktifkan spellchecker pada file markdown",
  callback = function()
    vim.opt_local.spell = false
  end,
})

-- Pastikan tidak ada karakter garis vertikal atau border di window mana pun
vim.api.nvim_create_autocmd({ "WinNew", "WinEnter", "BufWinEnter", "FileType" }, {
  desc = "Pastikan fillchars pemisah selalu spasi bersih",
  callback = function()
    vim.opt_local.fillchars:append({
      vert = " ",
      vertleft = " ",
      vertright = " ",
      verthoriz = " ",
      horiz = " ",
      horizup = " ",
      horizdown = " ",
      eob = " ",
    })
  end,
})
