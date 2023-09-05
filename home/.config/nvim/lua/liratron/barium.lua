local util = require 'lspconfig.util'

vim.filetype.add({ filename = { Config = "brazilconfig" } })

return {
  default_config = {
    cmd = { 'barium' },
    filetypes = { 'brazilconfig' },
    root_dir = function(fname)
      return util.find_git_ancestor(fname)
    end,
    settings = {},
  },
}
