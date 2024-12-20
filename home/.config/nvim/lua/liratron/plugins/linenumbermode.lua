return {
  "sethen/line-number-change-mode.nvim",
  config = function()
    require("line-number-change-mode").setup({
      mode = {
        i = {
          bg = "#a9b665",
          fg = "#374141",
          bold = true,
        },
        n = {
          bg = "#7daea3",
          fg = "#374141",
          bold = true,
        },
        R = {
          bg = "#ea6962",
          fg = "#374141",
          bold = true,
        },
        v = {
          bg = "#c18f41",
          fg = "#374141",
          bold = true,
        },
        V = {
          bg = "#bd6f3e",
          fg = "#374141",
          bold = true,
        },
      },
    })
  end,
}
