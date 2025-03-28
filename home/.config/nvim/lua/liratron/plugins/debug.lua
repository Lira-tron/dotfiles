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
            { "<leader>dp", function() require("dap").step_back() end, desc = "Step Back", },
            { "<leader>dc", function() require("dap").continue() end, desc = "Continue", },
            { "<leader>dd", function() require("dap").disconnect() end, desc = "Disconnect", },
            { "<leader>dE", function() require("dapui").eval() end, mode = {"n", "v"}, desc = "Evaluate", },
            { "<leader>dS", function() require("dap").session() end, desc = "Get Session", },
            { "<leader>dh", function() require("dap.ui.widgets").hover() end, desc = "Hover Variables", },
            { "<leader>do", function() require("dap.ui.widgets").scopes() end, desc = "Scopes", },
            { "<F1>", function() require("dap").step_into() end, desc = "Step Into", },
            { "<F2>", function() require("dap").step_over() end, desc = "Step Over", },
            { "<leader>dP", function() require("dap").pause.toggle() end, desc = "Pause", },
            { "<leader>dq", function() require("dap").close() end, desc = "Quit", },
            { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL", },
            { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint", },
            { "<leader>dx", function() require("dap").terminate() end, desc = "Terminate", },
            { "<F3>", function() require("dap").step_out() end, desc = "Step Out", },
            { "<leader>dsb", function() require("telescope").extensions.dap.list_breakpoints() end, desc = 'Debug: List breakpoints' },
            { "<leader>dsv", function() require("telescope").extensions.dap.variables() end, desc = 'Debug: Open Variables' },
            { "<leader>dsc", function() require("telescope").extensions.dap.configurations() end, desc = 'Debug: Open Configurations' },
            { "<leader>dsC", function() require("telescope").extensions.dap.commands() end, desc = 'Debug: Open Commands' },
            { "<leader>dsf", function() require("telescope").extensions.dap.frames() end, desc = 'Debug: Open Frames' },
            { "<leader>dV", function() require("dapui").float_element("scopes") end, desc = 'Debug: Open Variables' },
        },
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      vim.fn.sign_define("DapBreakpoint", { text = "🥊", texthl = "", linehl = "", numhl = "" })
      dapui.setup()
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
