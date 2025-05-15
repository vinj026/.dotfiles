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
