return {
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      -- make sure ripgrep is installed on your OS (brew install ripgrep)
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },

    config = function()
      local telescope = require('telescope')
      local home = vim.loop.os_homedir()

      telescope.load_extension('fzf')

      telescope.setup({
        defaults = {
          wrap_results = true,
          layout_strategy = "vertical",
          layout_config = {
            vertical = { width = 0.9, preview_cutoff = 10 },
          },
          -- Make ripgrep see dotfiles but still skip .git
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
            "--glob", "!**/.git/*",
          },
          mappings = {
            i = {
              ["<esc>"] = require("telescope.actions").close,
              ["<C-Down>"] = require("telescope.actions").cycle_history_next,
              ["<C-Up>"]   = require("telescope.actions").cycle_history_prev,
            },
          },
        },

        pickers = {
          -- Force file pickers to start at $HOME and see hidden files
          find_files = {
            cwd = home,
            -- use ripgrep to respect our hidden/.git rules
            find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
            wrap_results = true,
          },
          live_grep = {
            cwd = home, -- vimgrep_arguments already include --hidden/--glob
          },
          buffers = { sort_mru = true, ignore_current_buffer = true },
          diagnostics = { wrap_results = true },
          lsp_references = { wrap_results = true },
          lsp_definitions = { wrap_results = true },
        },
      })
    end,

    keys = {
      -- See :help telescope.builtin
      { '<leader>fo', function()
          require('telescope.builtin').oldfiles {
            prompt_title = 'Recent files',
            sort_mru = true,
          }
        end, desc = 'Old (recent) files' },

      { '<leader><space>', '<cmd>Telescope buffers<cr>', desc = 'Buffers' },
      { '<leader>b',       '<cmd>Telescope buffers<cr>', desc = 'Buffers' },
      { '<leader>p',       '<cmd>Telescope buffers<cr>', desc = 'Buffers' },

      { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find filenames' },
      { '<leader>fm', '<cmd>Telescope marks<cr>',      desc = 'Marks' },
      { '<leader>fw', '<cmd>Telescope live_grep<cr>',  desc = 'Grep files' },
      { '<leader>ld', '<cmd>Telescope diagnostics<cr>',desc = 'diagnostics' },

      { '<leader>fb', function()
          require('telescope.builtin').live_grep {
            prompt_title = 'grep open files',
            grep_open_files = true,
          }
        end, desc = 'Grep open files' },

      { '<leader>fc',
        function() require('telescope.builtin').current_buffer_fuzzy_find() end,
        desc = 'Grep this file' },

      { '<leader>:', function()
          require('telescope.builtin').command_history { prompt_title = 'Command history' }
        end, desc = 'cmd history' },

      { '<leader>ls', function()
          local ok = pcall(require, 'aerial')
          if ok then
            require('telescope').extensions.aerial.aerial()
          else
            require('telescope.builtin').lsp_document_symbols()
          end
        end, desc = 'Search symbols' },
    },
  },
}
