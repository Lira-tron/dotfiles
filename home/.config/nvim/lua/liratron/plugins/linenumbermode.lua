return {
  "sethen/line-number-change-mode.nvim",
  config = function()
    local palette = require("concoctis.palette").get_palette()

    if palette == nil then
      return nil
    end

    require("line-number-change-mode").setup({
      mode = {
        i = {
          bg = palette.green,
          fg = '#374141',
          bold = true,
        },
        n = {
          bg = palette.blue,
          fg = '#374141',
          bold = true,
        },
        R = {
          bg = '#ea6962',
          fg = '#374141',
          bold = true,
        },
        v = {
          bg = '#c18f41',
          fg = '#374141',
          bold = true,
        },
        V = {
          bg = palette.mauve,
          fg = palette.mantle,
          bold = true,
        },
      },
    })
  end,
}
