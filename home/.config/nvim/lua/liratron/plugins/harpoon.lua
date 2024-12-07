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

    vim.keymap.set("n", "ma", function()
      harpoon:list():add()
    end)
    vim.keymap.set("n", "mm", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end)

    vim.keymap.set("n", "mr", function()
      harpoon:list():select(1)
    end)
    vim.keymap.set("n", "ms", function()
      harpoon:list():select(2)
    end)
    vim.keymap.set("n", "mt", function()
      harpoon:list():select(3)
    end)
    vim.keymap.set("n", "mg", function()
      harpoon:list():select(4)
    end)

    -- Toggle previous & next buffers stored within Harpoon list
    vim.keymap.set("n", "mn", function()
      harpoon:list():prev()
    end)
    vim.keymap.set("n", "mp", function()
      harpoon:list():next()
    end)
  end,
}
