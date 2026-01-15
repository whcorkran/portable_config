return {
  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      -- Useful for getting pretty icons, but requires a Nerd Font.
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      -- Let 'Q' cleanly close Telescope pickers
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'TelescopePrompt', 'TelescopeResults' },
        callback = function(ev)
          vim.keymap.set('n', 'Q', function()
            pcall(require('telescope.actions').close, require('telescope.actions.state').get_current_picker(ev.buf))
          end, { buffer = ev.buf, silent = true })
        end,
      })

      local telescope = require 'telescope'
      local themes = require 'telescope.themes'
      local ivy = themes.get_ivy
      local dropdown = themes.get_dropdown

      telescope.setup {
        -- Global default: Ivy theme for all pickers
        defaults = ivy {

          prompt_prefix = '   ',
          selection_caret = ' ',
          results_title = false,
          dynamic_preview_title = true,
          winblend = 4, -- subtle transparency

          path_display = { 'smart', 'truncate' },

          vimgrep_arguments = {
            'rg',
            '--follow',
            '--hidden',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
            '--trim',
            '-g',
            '!**/.git/*',
          },

          sorting_strategy = 'ascending',
        },

        pickers = {
          buffers = ivy {
            border = true,
            previewer = false,
            results_title = false,
            prompt_title = false,
            winblend = 0,
            layout_config = { width = 0.45, height = 0.35 },
            sort_mru = true,
            path_display = { 'tail' },
          },
        },

        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
          fzf = {
            case_mode = 'smart_case',
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
          },

          -- File browser: big window, preview, prompt at bottom
          file_browser = {
            grouped = true,
            select_buffer = true,
            sorting_strategy = 'ascending',
            hidden = false,
            initial_mode = 'normal',

            layout_strategy = 'flex',
            layout_config = {
              width = 0.96,
              height = 0.92,
              horizontal = {
                preview_width = 0.66,
                prompt_position = 'bottom',
              },
              vertical = {
                preview_height = 0.55,
                prompt_position = 'bottom',
              },
            },

            previewer = true,
          },
        },
      }

      -- Enable Telescope extensions if they are installed
      pcall(telescope.load_extension, 'fzf')
      pcall(telescope.load_extension, 'ui-select')
      pcall(telescope.load_extension, 'file_browser')

      -- File Browser config
      vim.keymap.set('n', '<leader>fb', function()
        telescope.extensions.file_browser.file_browser {
          path = vim.fn.expand '%:p:h',
        }
      end, { desc = 'File Browser' })

      -- See `:help telescope.builtin`
      local builtin = require 'telescope.builtin'
      local state = require 'telescope.actions.state'
      local actions = require 'telescope.actions'

      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><Space>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      vim.keymap.set('n', '<leader>sc', function()
        builtin.colorscheme(themes.get_ivy {
          ignore_builtins = true,
          enable_preview = true,

          attach_mappings = function(prompt_bufnr, map)
            local function save_color()
              local entry = state.get_selected_entry()
              local color = entry.value
              local color_file = vim.fn.stdpath 'data' .. '/last_colorscheme'
              vim.fn.writefile({ color }, color_file)
              actions.select_default(prompt_bufnr)
            end

            map('i', '<CR>', save_color)
            map('n', '<CR>', save_color)
            return true
          end,
        })
      end, { desc = '[S]earch [C]olorscheme' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
