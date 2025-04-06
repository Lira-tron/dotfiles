return {
  "echasnovski/mini.nvim",
  version = false,
  config = function()
    require("mini.icons").setup()
    require("mini.move").setup({

      keys = {
        { "H", mode = "v", desc = "Move visual block left" },
        { "L", mode = "v", desc = "Move visual block right" },
        { "J", mode = "v", desc = "Move visual block down" },
        { "K", mode = "v", desc = "Move visual block up" },
      },
      opts = {
        mappings = {
          -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
          left = "H",
          right = "L",
          down = "J",
          up = "K",
        },
      },
    })

    local function ai_buffer(ai_type)
      local start_line, end_line = 1, vim.fn.line("$")
      if ai_type == "i" then
        -- Skip first and last blank lines for `i` textobject
        local first_nonblank, last_nonblank = vim.fn.nextnonblank(start_line), vim.fn.prevnonblank(end_line)
        -- Do nothing for buffer with all blanks
        if first_nonblank == 0 or last_nonblank == 0 then
          return { from = { line = start_line, col = 1 } }
        end
        start_line, end_line = first_nonblank, last_nonblank
      end

      local to_col = math.max(vim.fn.getline(end_line):len(), 1)
      return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
    end

    local ai = require("mini.ai")
    ai.setup({
      n_lines = 500,
      custom_textobjects = {
        o = ai.gen_spec.treesitter({ -- code block
          a = { "@block.outer", "@conditional.outer", "@loop.outer" },
          i = { "@block.inner", "@conditional.inner", "@loop.inner" },
        }),
        f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
        c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
        t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
        d = { "%f[%d]%d+" }, -- digits
        e = { -- Word with case
          { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
          "^().*()$",
        },
        g = ai_buffer, -- buffer
        u = ai.gen_spec.function_call(), -- u for "Usage"
        U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
      },
    })
    require("mini.bufremove").setup()
    require("mini.indentscope").setup()
    require("mini.splitjoin").setup()
    require("mini.pairs").setup()
    require("mini.surround").setup({
      mappings = {
        add = "gsa", -- Add surrounding in Normal and Visual modes
        delete = "gsd", -- Delete surrounding
        find = "gsf", -- Find surrounding (to the right)
        find_left = "gsF", -- Find surrounding (to the left)
        highlight = "gsh", -- Highlight surrounding
        replace = "gsr", -- Replace surrounding
        update_n_lines = "gsn", -- Update `n_lines`
      },
    })
  end,
}
