-- https://github.com/HakonHarnes/img-clip.nvim

-- Filename: ~/github/dotfiles-latest/neovim/neobean/lua/plugins/img-clip.lua
-- ~/github/dotfiles-latest/neovim/neobean/lua/plugins/img-clip.lua

return {
  "HakonHarnes/img-clip.nvim",
  event = "VeryLazy",
  opts = {
    -- add options here
    -- or leave it empty to use the default settings
    default = {

      -- file and directory options
      -- expands dir_path to an absolute path
      -- When you paste a new image, and you hover over its path, instead of:
      -- test-images-img/2024-06-03-at-10-58-55.webp
      -- You would see the entire path:
      -- /Users/linkarzu/github/obsidian_main/999-test/test-images-img/2024-06-03-at-10-58-55.webp
      --
      -- IN MY CASE I DON'T WANT TO USE ABSOLUTE PATHS
      -- if I switch to a nother computer and I have a different username,
      -- therefore a different home directory, that's a problem because the
      -- absolute paths will be pointing to a different directory
      use_absolute_path = false, ---@type boolean

      -- make dir_path relative to current file rather than the cwd
      -- To see your current working directory run `:pwd`
      -- So if this is set to false, the image will be created in that cwd
      -- In my case, I want images to be where the file is, so I set it to true
      relative_to_current_file = true, ---@type boolean

      -- -- I want to save the images in a directory named after the current file,
      -- -- but I want the name of the dir to end with `-img`
      -- dir_path = function()
      --   return vim.fn.expand("%:t:r") .. "-img"
      -- end,

      -- If you want to get prompted for the filename when pasting an image
      -- This is the actual name that the physical file will have
      -- If you set it to true, enter the name without spaces or extension `test-image-1`
      -- Remember we specified the extension above
      --
      -- I don't want to give my images a name, but instead autofill it using
      -- the date and time as shown on `file_name` below
      prompt_for_file_name = false, ---@type boolean
      file_name = "%y%m%d-%H%M%S", ---@type string

      -- -- Set the extension that the image file will have
      -- -- I'm also specifying the image options with the `process_cmd`
      -- -- Notice that I HAVE to convert the images to the desired format
      -- -- If you don't specify the output format, you won't see the size decrease

      extension = "avif", ---@type string
      process_cmd = "magick convert - -quality 75 avif:-", ---@type string

      -- extension = "webp", ---@type string
      -- process_cmd = "convert - -quality 75 webp:-", ---@type string

      -- extension = "png", ---@type string
      -- process_cmd = "convert - -quality 75 png:-", ---@type string

      -- extension = "jpg", ---@type string
      -- process_cmd = "convert - -quality 75 jpg:-", ---@type string

      -- -- Here are other conversion options to play around
      -- -- Notice that with this other option you resize all the images
      -- process_cmd = "convert - -quality 75 -resize 50% png:-", ---@type string

      -- -- Other parameters I found in stackoverflow
      -- -- https://stackoverflow.com/a/27269260
      -- --
      -- -- -depth value
      -- -- Color depth is the number of bits per channel for each pixel. For
      -- -- example, for a depth of 16 using RGB, each channel of Red, Green, and
      -- -- Blue can range from 0 to 2^16-1 (65535). Use this option to specify
      -- -- the depth of raw images formats whose depth is unknown such as GRAY,
      -- -- RGB, or CMYK, or to change the depth of any image after it has been read.
      -- --
      -- -- compression-filter (filter-type)
      -- -- compression level, which is 0 (worst but fastest compression) to 9 (best but slowest)
      -- process_cmd = "convert - -depth 24 -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 png:-",
      --
      -- -- These are for jpegs
      -- process_cmd = "convert - -sampling-factor 4:2:0 -strip -interlace JPEG -colorspace RGB -quality 75 jpg:-",
      -- process_cmd = "convert - -strip -interlace Plane -gaussian-blur 0.05 -quality 75 jpg:-",
      --
    },

    -- filetype specific options
    filetypes = {
      markdown = {
        -- encode spaces and special characters in file path
        url_encode_path = true, ---@type boolean

        -- -- The template is what specifies how the alternative text and path
        -- -- of the image will appear in your file
        --
        -- -- $CURSOR will paste the image and place your cursor in that part so
        -- -- you can type the "alternative text", keep in mind that this will
        -- -- not affect the name that the image physically has
        -- template = "![$CURSOR]($FILE_PATH)", ---@type string
        --
        -- -- This will just statically type "Image" in the alternative text
        -- template = "![Image]($FILE_PATH)", ---@type string
        --
        -- I want to use blink.cmp to easily find images with the LSP, so adding ./ lamw25wmal
        template = "![Image](./$FILE_PATH)",
        --
        -- -- This will dynamically configure the alternative text to show the
        -- -- same that you configured as the "file_name" above
        -- -- I really don't need to see the entire filename in the alternative
        -- -- text field, so just switched it to show "Image"
        -- template = "![$FILE_NAME]($FILE_PATH)", ---@type string
      },
      vimwiki = {
        -- encode spaces and special characters in file path
        url_encode_path = true, ---@type boolean

        -- -- The template is what specifies how the alternative text and path
        -- -- of the image will appear in your file
        --
        -- -- $CURSOR will paste the image and place your cursor in that part so
        -- -- you can type the "alternative text", keep in mind that this will
        -- -- not affect the name that the image physically has
        -- template = "![$CURSOR]($FILE_PATH)", ---@type string
        --
        -- -- This will just statically type "Image" in the alternative text
        -- template = "![Image]($FILE_PATH)", ---@type string
        --
        -- I want to use blink.cmp to easily find images with the LSP, so adding ./ lamw25wmal
        template = "![Image](./$FILE_PATH)",
        --
        -- -- This will dynamically configure the alternative text to show the
        -- -- same that you configured as the "file_name" above
        -- -- I really don't need to see the entire filename in the alternative
        -- -- text field, so just switched it to show "Image"
        -- template = "![$FILE_NAME]($FILE_PATH)", ---@type string
      },
    },
  },
  keys = {
    {
      "<leader>fip",
      function()
        local pasted_image = require("img-clip").paste_image()
        if pasted_image then
          -- "Update" saves only if the buffer has been modified since the last save
          vim.cmd("silent! update")
          -- Get the current line
          local line = vim.api.nvim_get_current_line()
          -- Move cursor to end of line
          vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], #line })
          -- I reload the file, otherwise I cannot view the image after pasted
          vim.cmd("edit!")
        end
      end,
      mode = { "n", "i" },
      desc = "[F]ile [Image] [P]aste from system clipboard",
    },
    {
      "<leader>fio",
      function()
        local function get_image_path()
          -- Get the current line
          local line = vim.api.nvim_get_current_line()
          -- Pattern to match image path in Markdown
          local image_pattern = "%[.-%]%((.-)%)"
          -- Extract relative image path
          local _, _, image_path = string.find(line, image_pattern)
          return image_path
        end
        -- Get the image path
        local image_path = get_image_path()
        if image_path then
          -- Check if the image path starts with "http" or "https"
          if string.sub(image_path, 1, 4) == "http" then
            print("URL image, use 'gx' to open it in the default browser.")
          else
            -- Construct absolute image path
            local current_file_path = vim.fn.expand("%:p:h")
            local absolute_image_path = current_file_path .. "/" .. image_path
            -- Construct command to open image in Preview
            local command = "open -a Preview " .. vim.fn.shellescape(absolute_image_path)
            -- Execute the command
            local success = os.execute(command)
            if success then
              print("Opened image in Preview: " .. absolute_image_path)
            else
              print("Failed to open image in Preview: " .. absolute_image_path)
            end
          end
        else
          print("No image found under the cursor")
        end
      end,
      mode = { "n" },
      desc = "[F]ile [I]mage [O]pen under cursor in Preview"
    },
    {
      "<leader>fid",
      function()
        local function get_image_path()
          local line = vim.api.nvim_get_current_line()
          local image_pattern = "%[.-%]%((.-)%)"
          local _, _, image_path = string.find(line, image_pattern)
          return image_path
        end
        local image_path = get_image_path()
        if not image_path then
          vim.api.nvim_echo({ { "No image found under the cursor", "WarningMsg" } }, false, {})
          return
        end
        if string.sub(image_path, 1, 4) == "http" then
          vim.api.nvim_echo({ { "URL image cannot be deleted from disk.", "WarningMsg" } }, false, {})
          return
        end
        local current_file_path = vim.fn.expand("%:p:h")
        local absolute_image_path = current_file_path .. "/" .. image_path
        -- Check if file exists
        if vim.fn.filereadable(absolute_image_path) == 0 then
          vim.api.nvim_echo(
            { { "Image file does not exist:\n", "ErrorMsg" }, { absolute_image_path, "ErrorMsg" } },
            false,
            {}
          )
          return
        end
        if vim.fn.executable("trash") == 0 then
          vim.api.nvim_echo({
            { "- Trash utility not installed. Make sure to install it first\n", "ErrorMsg" },
            { "- In macOS run `brew install trash`\n",                          nil },
          }, false, {})
          return
        end
        -- Cannot see the popup as the cursor is on top of the image name, so saving
        -- its position, will move it to the top and then move it back
        local current_pos = vim.api.nvim_win_get_cursor(0) -- Save cursor position
        vim.api.nvim_win_set_cursor(0, { 1, 0 })           -- Move to top
        vim.ui.select({ "yes", "no" }, { prompt = "Delete image file? " }, function(choice)
          vim.api.nvim_win_set_cursor(0, current_pos)      -- Move back to image line
          if choice == "yes" then
            local success, _ = pcall(function()
              vim.fn.system({ "trash", vim.fn.fnameescape(absolute_image_path) })
            end)
            -- Verify if file still exists after deletion attempt
            if success and vim.fn.filereadable(absolute_image_path) == 1 then
              -- Try with rm if trash deletion failed
              -- Keep in mind that if deleting with `rm` the images won't go to the
              -- macos trash app, they'll be gone
              -- This is useful in case trying to delete imaes mounted in a network
              -- drive, like for my blogpost lamw25wmal
              --
              -- Cannot see the popup as the cursor is on top of the image name, so saving
              -- its position, will move it to the top and then move it back
              current_pos = vim.api.nvim_win_get_cursor(0) -- Save cursor position
              vim.api.nvim_win_set_cursor(0, { 1, 0 })     -- Move to top
              vim.ui.select({ "yes", "no" }, { prompt = "Trash deletion failed. Try with rm command? " },
                function(rm_choice)
                  vim.api.nvim_win_set_cursor(0, current_pos) -- Move back to image line
                  if rm_choice == "yes" then
                    local rm_success, _ = pcall(function()
                      vim.fn.system({ "rm", vim.fn.fnameescape(absolute_image_path) })
                    end)
                    if rm_success and vim.fn.filereadable(absolute_image_path) == 0 then
                      vim.api.nvim_echo({
                        { "Image file deleted from disk using rm:\n", "Normal" },
                        { absolute_image_path,                        "Normal" },
                      }, false, {})
                      -- require("image").clear()
                      vim.cmd("edit!")
                      vim.cmd("normal! dd")
                    else
                      vim.api.nvim_echo({
                        { "Failed to delete image file with rm:\n", "ErrorMsg" },
                        { absolute_image_path,                      "ErrorMsg" },
                      }, false, {})
                    end
                  end
                end)
            elseif success and vim.fn.filereadable(absolute_image_path) == 0 then
              vim.api.nvim_echo({
                { "Image file deleted from disk:\n", "Normal" },
                { absolute_image_path,               "Normal" },
              }, false, {})
              -- require("image").clear()
              vim.cmd("edit!")
              vim.cmd("normal! dd")
            else
              vim.api.nvim_echo({
                { "Failed to delete image file:\n", "ErrorMsg" },
                { absolute_image_path,              "ErrorMsg" },
              }, false, {})
            end
          else
            vim.api.nvim_echo({ { "Image deletion canceled.", "Normal" } }, false, {})
          end
        end)
      end,
      mode = { "n" },
      desc = "[F]ile [I]mage [D]elete",
    }
  },
}
