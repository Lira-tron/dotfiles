return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      -- Creates a beautiful debugger UI

      -- Installs the debug adapters for you
      "williamboman/mason.nvim",
      "theHamsta/nvim-dap-virtual-text",
    },
        -- stylua: ignore
        keys = {
            { "<leader>dR", function() require("dap").run_to_cursor() end, desc = "Run to Cursor", },
            { "<leader>de", function() require("dapui").eval(vim.fn.input "[Expression] > ") end, desc = "Evaluate Input", },
            { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input "[Condition] > ") end, desc = "Conditional Breakpoint", },
            { "<leader>dv", function() require("dapui").toggle() end, desc = "Toggle UI", },
            { "<leader>ds", function() require("dap").step_back() end, desc = "Step Back", },
            { "<leader>dc", function() require("dap").continue() end, desc = "Continue", },
            { "<leader>dd", function() require("dap").disconnect() end, desc = "Disconnect", },
            { "<leader>dE", function() require("dapui").eval() end, mode = {"n", "v"}, desc = "Evaluate", },
            { "<leader>dS", function() require("dap").session() end, desc = "Get Session", },
            { "<leader>dh", function() require("dap.ui.widgets").hover() end, desc = "Hover Variables", },
            { "<leader>do", function() require("dap.ui.widgets").scopes() end, desc = "Scopes", },
            { "<F1>", function() require("dap").step_into() end, desc = "Step Into", },
            { "<F2>", function() require("dap").step_over() end, desc = "Step Over", },
            { "<leader>dp", function() require("dap").pause.toggle() end, desc = "Pause", },
            { "<leader>dq", function() require("dap").close() end, desc = "Quit", },
            { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL", },
            { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint", },
            { "<leader>dx", function() require("dap").terminate() end, desc = "Terminate", },
            { "<F3>", function() require("dap").step_out() end, desc = "Step Out", },
            { "<leader>dlb", function() require("telescope").extensions.dap.list_breakpoints() end, desc = 'Debug: List breakpoints' },
            { "<leader>dlv", function() require("telescope").extensions.dap.variables() end, desc = 'Debug: Open Variables' },
            { "<leader>dV", function() require("dapui").float_element("scopes") end, desc = 'Debug: Open Variables' },
        },
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      -- Function to calculate dap-ui sidebar width with min and max constraints
      local function calculate_sidebar_width()
        local width = vim.o.columns
        local min_width = 20
        local max_width = 40
        if width > 160 then
          return max_width
        elseif width > 120 then
          return math.floor(min_width + (width - 120) / 40 * (max_width - min_width))
        else
          return min_width
        end
      end

      local sidebar_width = calculate_sidebar_width()

      -- Function to determine dap-ui layouts based on terminal size
      local function get_dapui_layout()
        local width = vim.o.columns
        local height = vim.o.lines
        local sidebar_width = calculate_sidebar_width()

        if width > 120 then
          return {
            {
              elements = { "scopes", "breakpoints", "stacks", "watches" },
              size = sidebar_width, -- Width for left panel
              position = "left",
            },
            {
              elements = { "repl", "console" },
              size = math.floor(height * 0.3), -- Height for bottom panel
              position = "bottom",
            },
          }
        elseif width > 80 then
          return {
            {
              elements = { "scopes", "breakpoints", "stacks" },
              size = sidebar_width, -- Width for left panel
              position = "left",
            },
            -- REPL and console are hidden on medium screens
          }
        else
          return {
            {
              elements = { "scopes", "breakpoints" },
              size = sidebar_width, -- Width for left panel
              position = "left",
            },
            -- REPL and console are hidden on small screens
          }
        end
      end

      -- Setup dap-ui with dynamic layout
      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "*" }, -- Custom icons
        controls = { -- Custom control icons
          element = "repl",
          enabled = true,
          icons = {
            pause = "⏸",
            play = "▶",
            step_into = "⏎",
            step_over = "⏭",
            step_out = "⏮",
            step_back = "b",
            run_last = "▶▶",
            terminate = "⏹",
            disconnect = "⏏",
          },
        },
        floating = {
          border = "single",
          mappings = {
            close = { "q", "<Esc>" },
          },
        },
        layouts = get_dapui_layout(), -- Apply dynamic layout
      })

      dap.listeners.after.event_initialized["dapui_config"] = dapui.open
      -- dap.listeners.before.event_terminated["dapui_config"] = dapui.close
      -- dap.listeners.before.event_exited["dapui_config"] = dapui.close
    end,
  },
  {
    "leoluz/nvim-dap-go",
    ft = "go",
    dependencies = { "mfussenegger/nvim-dap" },
    build = "go install github.com/go-delve/delve/cmd/dlv@latest",
    config = function()
      require("dap-go").setup()
      vim.keymap.set("n", "<leader>dtn", function()
        require("dap-go").debug_test()
      end, { desc = "Debug: Start debug test" })
      vim.keymap.set("n", "<leader>dtl", function()
        require("dap-go").debug_last_test()
      end, { desc = "Debug: Start debug last test" })
    end,
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap" },
    config = true,
  },
  {
    "nvim-telescope/telescope-dap.nvim",
    dependencies = { "mfussenegger/nvim-dap" },
    config = true,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = { "mfussenegger/nvim-dap", "williamboman/mason.nvim" },
    config = true,
  },
}
