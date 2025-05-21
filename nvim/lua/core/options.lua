vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.fillchars:append({ eob = " " })


---
--- Lua
vim.o.autowriteall = true
vim.api.nvim_create_autocmd({ 'InsertLeavePre', 'TextChanged', 'TextChangedP' }, {
  pattern = '*',
  callback = function()
    vim.cmd('silent! write')
  end
})

vim.cmd [[
  highlight EndOfBuffer guifg=NONE guibg=NONE
]]
