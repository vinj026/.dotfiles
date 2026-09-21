-- Minimalist UI Settings
vim.opt.fillchars = {
  vert = " ",
  vertleft = " ",
  vertright = " ",
  verthoriz = " ",
  horiz = " ",
  horizup = " ",
  horizdown = " ",
  eob = " ", -- Menghilangkan karakter '~' di baris kosong akhir file
}

-- Clean statusline & cmdline
vim.opt.cmdheight = 0 -- Sembunyikan cmdline saat tidak mengetik command
vim.opt.showmode = false -- Mode sudah terlihat di statusline
vim.opt.laststatus = 3 -- Global statusline tunggal di bawah

-- Nonaktifkan spellchecker
vim.opt.spell = false

-- Nonaktifkan highlight baris kursor (cursorline)
vim.opt.cursorline = false
