-- Colorscheme. Replaces the NixOS rice's hand-written lua/theme.lua +
-- lua/matugen-colors.lua, which built highlight groups from a wallpaper-derived
-- palette. Catppuccin is a fixed palette, so upstream's plugin does the job with
-- far less to maintain.
return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000, -- load before other plugins so they pick up the colours
  config = function()
    require("catppuccin").setup({
      flavour = "mocha",
      transparent_background = false,
      -- Match the rice's restraint: no italic comments, minimal decoration.
      no_italic = false,
      styles = {
        comments = { "italic" },
        conditionals = {},
      },
      integrations = {
        gitsigns = true,
        telescope = { enabled = true },
        treesitter = true,
        which_key = true,
        cmp = true,
        native_lsp = { enabled = true },
      },
    })
    vim.cmd.colorscheme("catppuccin")
  end,
}
