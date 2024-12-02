return {
  "vimwiki/vimwiki",
  ft = "vimwiki",
  keys = {
    { "<space>w<space>w", "<Plug>VimwikiMakeDiaryNote", desc = "VimwikiMakeDiaryNote" },
  },
  init = function()
    vim.g.vimwiki_list = {
      {
        path = "~/workplace/LimonoctNvim/src/LimonoctNvim/notes",
        name = "WorkNotes",
        syntax = "markdown",
        ext = ".md",
        custom_wiki2html = "~/.local/bin/m2h_pandoc.py",
        base_url = "~/workplace/LimonoctNvim/src/LimonoctNvim/notes/",
        custom_wiki2html_args = table.concat({
          '--metadata title-prefix="Notes"',
        }),
        auto_generate_links = 1,
        auto_export = 1,
        links_space_char = "_",
        diary_frequency = "monthly",
        diary_header = "Bullet Journal",
        diary_rel_path = "journal",
        diary_caption_level = -1,
        diary_index = "index",
      },
    }

    -- open index.wiki when opening a folder
    vim.g.vimwiki_dir_link = "index"

    -- Not always consider a .wiki or .md file to be a wiki.
    vim.g.vimwiki_global_ext = 0

    vim.g.vimwiki_markdown_link_ext = 1

    -- Add highlight groups to headers
    vim.g.vimwiki_hl_headers = 1
  end,
}
