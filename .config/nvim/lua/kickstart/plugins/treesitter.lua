return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
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
          lookahead = true,
          keymaps = {},
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = { [']f'] = '@function.outer', [']c'] = '@class.outer' },
          goto_next_end = { [']F'] = '@function.outer', [']C'] = '@class.outer' },
          goto_previous_start = { ['[f'] = '@function.outer', ['[c'] = '@class.outer' },
          goto_previous_end = { ['[F'] = '@function.outer', ['[C'] = '@class.outer' },
        },
        swap = {
          enable = true,
          swap_next = { ['<leader>s'] = '@parameter.inner' },
          swap_previous = { ['<leader>S'] = '@parameter.inner' },
        },
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
      vim.g.no_plugin_maps = true
    end,
    config = function()
      local ts_select = require 'nvim-treesitter-textobjects.select'

      local function map_textobjects(bufnr, keymaps)
        local opts = { buffer = bufnr, silent = true }
        for lhs, def in pairs(keymaps) do
          local capture, modes = def[1], def[2]
          if type(modes) == 'string' then
            modes = { modes }
          end
          for _, mode in ipairs(modes) do
            vim.keymap.set(mode, lhs, function()
              ts_select.select_textobject(capture, 'textobjects', mode)
            end, opts)
          end
        end
      end

      -- shared maps that work correctly across most languages
      local common = {
        ['aa'] = { '@parameter.outer', { 'o', 'x' } },
        ['ia'] = { '@parameter.inner', { 'o', 'x' } },
        ['al'] = { '@loop.outer', { 'o', 'x' } },
        ['il'] = { '@loop.inner', { 'o', 'x' } },
        ['ai'] = { '@conditional.outer', { 'o', 'x' } },
        ['ii'] = { '@conditional.inner', { 'o', 'x' } },
      }

      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'c', 'cpp' },
        group = vim.api.nvim_create_augroup('ts_textobjects_cpp', { clear = true }),
        callback = function(ev)
          map_textobjects(
            ev.buf,
            vim.tbl_extend('force', common, {
              ['af'] = { '@function.outer', { 'o', 'x' } }, -- TODO: verify with :InspectTree
              ['if'] = { '@function.inner', { 'o', 'x' } },
              ['ac'] = { '@class.outer', { 'o', 'x' } },
              ['ic'] = { '@class.inner', { 'o', 'x' } },
            })
          )
        end,
      })

      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'python', 'lua', 'go' },
        group = vim.api.nvim_create_augroup('ts_textobjects_generic', { clear = true }),
        callback = function(ev)
          map_textobjects(
            ev.buf,
            vim.tbl_extend('force', common, {
              ['af'] = { '@function.outer', { 'o', 'x' } },
              ['if'] = { '@function.inner', { 'o', 'x' } },
              ['ac'] = { '@class.outer', { 'o', 'x' } },
              ['ic'] = { '@class.inner', { 'o', 'x' } },
            })
          )
        end,
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
