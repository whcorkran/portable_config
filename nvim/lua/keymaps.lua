-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- fast quit
-- close nvim if we enter the empty buffer
vim.keymap.set('n', 'Q', function()
  local buffers = vim.fn.getbufinfo { buflisted = 1 }
  if #buffers > 1 then
    vim.cmd 'bp | bd #'
  else
    vim.cmd 'enew | q'
  end
end, { desc = 'Close Buffer' })

-- buffer cycling
vim.keymap.set('n', '<Tab>', function()
  if vim.bo.filetype ~= 'neo-tree' then
    vim.cmd ':bn'
  end
end, { desc = 'Cycle between buffers' })

-- split a file into a new tmux pane
vim.api.nvim_create_user_command('SplitTmux', function()
  local file = vim.fn.expand '%:p'
  local line = vim.fn.line '.'
  vim.fn.system(string.format('tmux split-window -h "nvim +%d %s"', line, file))
end, {})
vim.keymap.set('n', '<leader>w', function()
  vim.cmd ':SplitTmux'
end, { desc = 'Open file in new split' })

-- Move current line up/down
vim.keymap.set('n', '<A-j>', ':m .+1<CR>==')
vim.keymap.set('n', '<A-k>', ':m .-2<CR>==')

-- Move selected block up/down
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv")

-- Keep selection when indenting/deindenting in visual mode
vim.keymap.set('v', '<', '<gv', { noremap = true, silent = true })
vim.keymap.set('v', '>', '>gv', { noremap = true, silent = true })

-- Show diagnostic
vim.keymap.set('n', '<leader>e', function()
  vim.diagnostic.open_float(nil, { focus = false })
end, { desc = 'View diagnostic in floating window' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Free yourself from the tyranny of the arrow keys
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- [[ Insert Mode]]
-- alt delete word
vim.keymap.set('i', '<M-BS>', '<C-W>', { desc = 'Delete previous word', noremap = true, silent = true })

-- ctrl delete line
vim.keymap.set('i', '<C-BS>', '<C-o>d0', { desc = 'Delete previous line', noremap = true, silent = true })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- System clipboard paste
vim.keymap.set('n', '<leader>y', '"+y')
vim.keymap.set('v', '<leader>y', '"+y')
vim.keymap.set('n', '<leader>p', '"+p')
vim.keymap.set('v', '<leader>p', '"+p')

-- git
local fugitive_height = 12
vim.keymap.set('n', '<leader>gt', function()
  vim.cmd 'G'
  vim.cmd('resize' .. fugitive_height)
end, { desc = 'Git status (bottom split, fixed height)' })
