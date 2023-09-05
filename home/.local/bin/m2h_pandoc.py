#!/usr/bin/env python3

import subprocess
import os
import sys


def main(
    force,
    syntax,
    extension,
    output_dir,
    input_file,
    css_file,
    template_path,
    template_default,
    template_ext,
    root_path,
    *custom_args,
):
    input_file_name = os.path.splitext(os.path.basename(input_file))[0]
    output_file = os.path.join(output_dir.replace("_html", ""), input_file_name) + os.path.extsep + "html"

    root_file = root_path + "index.html"

    command = [
        "pandoc",
        "--lua-filter", os.path.expanduser("~/.local/bin/pandoc_filters.lua"),
        "--from", "gfm-task_lists+hard_line_breaks" if syntax == "markdown" else syntax,
        "--to", "html5",
        "--highlight-style=pygments",
        "--css", os.path.expanduser("~/.cache/notes/styles.css"),
        "--quiet",
        "--output", output_file,
        "--metadata", "rootDir={}".format(root_file),
        "--standalone",
        "--template", os.path.expanduser("~/.cache/notes/template.html5"),
    ] + list(custom_args)

    command.append(input_file)

    # Prune empty elements from command list
    command = list(filter(None, command))

    # Run command
    subprocess.run(command, check=True, encoding="utf8")


if __name__ == "__main__":
    main(*sys.argv[1:])
