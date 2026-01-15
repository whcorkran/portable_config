return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    priority = 800,
    build = ':TSUpdate',
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      -- your existing languages:
      vim.list_extend(
        opts.ensure_installed,
        { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'python', 'cpp', 'go' }
      )

      opts.auto_install = true
      opts.highlight = { enable = true, additional_vim_regex_highlighting = { 'ruby' } }
      opts.indent = { enable = true, disable = { 'ruby' } }

      -- >>> Treesitter Textobjects config <<<
      opts.textobjects = {
        select = {
          enable = true,
          lookahead = true, -- jump forward to nearest textobject
          keymaps = {
            -- functions
            ['af'] = '@function.outer',
            ['if'] = '@function.inner',
            ['ac'] = '@class.outer',
            ['ic'] = '@class.inner',
            ['ab'] = '@block.outer',
            ['ib'] = '@block.inner',
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = { [']f'] = '@function.outer' },
          goto_previous_start = { ['[f'] = '@function.outer' },
        },
        -- swap = { enable = true, swap_next = { ['<leader>a'] = '@parameter.inner' }, swap_previous = { ['<leader>A'] = '@parameter.inner' }, },
        lsp_interop = {
          enable = true,
          border = 'none',
          floating_preview_opts = {},
          peek_definition_code = {
            ['<leader>fd'] = '@function.outer',
            ['<leader>Fd'] = '@class.outer',
          },
        },
      }

      return opts
    end, -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    init = function()
      -- Disable entire built-in ftplugin mappings to avoid conflicts.
      -- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
      vim.g.no_plugin_maps = true
    end,
    config = function() end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
