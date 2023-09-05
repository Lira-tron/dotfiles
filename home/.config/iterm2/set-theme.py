#!/usr/bin/env python3.9

import iterm2
import asyncio
import os


async def main():
    theme_filepath = os.path.join(os.environ['XDG_CONFIG_HOME'], 'theme')

    if not os.path.isfile(theme_filepath):
        return

    with open(theme_filepath) as f:
        theme = f.readline().strip()

        await set_theme(theme)


async def set_theme(theme):
    connection = await iterm2.Connection.async_create()
    preset = await iterm2.ColorPreset.async_get(connection, theme)
    profiles = await iterm2.PartialProfile.async_query(connection)

    for partial in profiles:
        await partial.async_set_color_preset(preset)


asyncio.run(main())
