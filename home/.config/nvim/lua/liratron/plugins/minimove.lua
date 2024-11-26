return {
  'echasnovski/mini.move',
  version = false,
  keys = {
    { 'H', mode = 'v', desc = 'Move visual block left' },
    { 'L', mode = 'v', desc = 'Move visual block right' },
    { 'J', mode = 'v', desc = 'Move visual block down' },
    { 'K', mode = 'v', desc = 'Move visual block up' },
  },
  opts = {
    mappings = {
      -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
      left = 'H',
      right = 'L',
      down = 'J',
      up = 'K',
    },
  },
}
