-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  branch = 'v3.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    'nvim-tree/nvim-web-devicons', -- optional, but recommended
  },
  lazy = false,
  keys = {
    {
      '\\',
      function()
        require('neo-tree.command').execute {
          toggle = true,
          source = 'filesystem',
          position = 'left',
          reveal_force_cwd = true,
        }
      end,
      desc = 'NeoTree reveal',
      silent = true,
    },
  },
  opts = {
    hidden_root_node = true,
    retain_hidden_root_indent = true,
    close_if_last_window = true,
    filesystem = {
      follow_current_file = { enabled = true }, -- highlight the active file
      filtered_items = { hide_dotfiles = false }, -- show dotfiles if you like
      use_libuv_file_watcher = true, -- auto-refresh on change
      -- never show these
      never_show = {
        '.DS_Store',
      },
    },

    default_component_configs = {
      indent = {
        with_markers = true,
        with_expanders = true, -- VS Code-style twisty arrows
      },
      git_status = {
        symbols = { added = 'A', modified = 'M', deleted = 'D' },
      },
      icon = {
        folder_closed = '',
        folder_open = '',
        folder_empty = '',
      },
    },

    window = {
      width = 40,
      mappings = {
        ['<space>'] = 'toggle_node',
        ['<cr>'] = 'open',
        ['a'] = 'add', -- new file
        ['d'] = 'delete',
        ['r'] = 'rename',
        ['/'] = 'fuzzy_finder',
      },
    },
  },
}
