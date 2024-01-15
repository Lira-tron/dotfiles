return {
  "mrded/nvim-lsp-notify",
  event = "BufReadPre",
  dependencies = {
    { "rcarriga/nvim-notify" },
  },
  config = true,
}
