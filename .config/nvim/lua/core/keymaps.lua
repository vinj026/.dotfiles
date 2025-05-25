local keymap = vim.keymap.set
vim.g.mapleader = " "

vim.keymap.set("n", "<Leader>w", ":w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<Leader>q", ":q<CR>", { desc = "Quit" })
vim.keymap.set("n", "<Leader>qq", ":qall<CR>", { desc = "Quit" })

vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { desc = "Resize Up" })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { desc = "Resize Down" })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Resize Left" })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Resize Right" })

vim.keymap.set("n", "<Leader>e", "<Cmd>Neotree toggle<CR>", { desc = "Open file explorer" })

vim.keymap.set("n", "<leader>ls", ":LivePreview start<CR>", { desc = "Start LivePreview" })
vim.keymap.set("n", "<leader>lq", ":LivePreview stop<CR>", { desc = "Stop LivePreview" })

vim.keymap.set({ "n", "v" }, "y", '"+y', { noremap = true, silent = true })
vim.keymap.set("n", "yy", '"+yy', { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "p", '"+p', { noremap = true, silent = true })
vim.keymap.set("n", "P", '"+P', { noremap = true, silent = true })

-- Keymap untuk toggle zoom font di Neovim (GUI Version)
vim.api.nvim_set_keymap("n", "<C-+>", ":lua IncreaseFontSize()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-->", ":lua DecreaseFontSize()<CR>", { noremap = true, silent = true })

-- Function untuk resize font (khusus GUI Neovim: Neovide, WezTerm, dll)
local font_size = 14 -- Default font size

function IncreaseFontSize()
  font_size = font_size + 1
  vim.opt.guifont = "FiraCode Nerd Font:h" .. font_size
end

function DecreaseFontSize()
  font_size = font_size - 1
  vim.opt.guifont = "FiraCode Nerd Font:h" .. font_size
end
