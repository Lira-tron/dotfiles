return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup()

    local conf = require("telescope.config").values
    local function toggle_telescope(harpoon_files)
      local file_paths = {}
      for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
      end

      require("telescope.pickers")
        .new({}, {
          prompt_title = "Harpoon",
          finder = require("telescope.finders").new_table({
            results = file_paths,
          }),
          previewer = conf.file_previewer({}),
          sorter = conf.generic_sorter({}),
        })
        :find()
    end

    vim.keymap.set("n", "<leader>sm", function()
      toggle_telescope(harpoon:list())
    end, { desc = "Open harpoon window" })

    vim.keymap.set("n", "<leader>ma", function()
      harpoon:list():add()
    end, { desc = "Add"})
    vim.keymap.set("n", "mm", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = "Menu"})

    vim.keymap.set("n", "<leader>mr", function()
      harpoon:list():select(1)
    end, { desc = "Go to 1"})
    vim.keymap.set("n", "<leader>ms", function()
      harpoon:list():select(2)
    end, { desc = "Go to 2"})
    vim.keymap.set("n", "<leader>mt", function()
      harpoon:list():select(3)
    end, { desc = "Go to 3"})
    vim.keymap.set("n", "<leader>mg", function()
      harpoon:list():select(4)
    end, { desc = "Go to 4"})

    -- Toggle previous & next buffers stored within Harpoon list
    vim.keymap.set("n", "<leader>mp", function()
      harpoon:list():prev()
    end, { desc = "prev"})
    vim.keymap.set("n", "<leader>mn", function()
      harpoon:list():next()
    end, { desc = "Next"})
  end,
}
