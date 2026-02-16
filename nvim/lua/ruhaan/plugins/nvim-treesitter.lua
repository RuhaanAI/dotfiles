return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("nvim-treesitter.configs").setup({

      -- Languages you actually use (fast + clean)
      ensure_installed = {
        "python",
        "lua",
        "bash",
        "json",
        "yaml",
        "markdown",
        "markdown_inline",
      },

      -- Syntax highlighting
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },

      -- Smart indentation
      indent = {
        enable = true,
      },

      -- Better text objects & motions
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "gnn",
          node_incremental = "grn",
          scope_incremental = "grc",
          node_decremental = "grm",
        },
      },

    })
  end,
}
