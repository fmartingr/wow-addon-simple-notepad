# Simple Notebook

A notebook window for World of Warcraft. It keeps notes at three levels and holds chat links.

## Features

- **Native style:** the window uses the standard WoW panel look. You can move it.
- **Three notes:**
  - **Global:** one note for all characters on the account.
  - **Character:** one note for the current character. The tab shows the character name.
  - **Zone:** one note for the current character and the current zone. The tab shows the zone name.
- **Chat links:** click in the note, then shift-click an item, quest, spell, talent, or achievement. The link goes in at the cursor.
- **Autosave:** the note saves on each change.

## Open the window

- Type `/notebook` or `/nb`.
- Click the minimap button. Drag it to move it around the minimap edge.
- Click the addon compartment entry (the small menu button near the minimap).
- Press a key. Set the key in Options > Key Bindings > AddOns > Simple Notebook. No default key exists.

Press ESC once to leave the text area. Press ESC again to close the window.

## Tab rules

- **Settings:** open Settings > AddOns > Simple Notebook. Two checkboxes show or hide the **Global** tab and the **Zone** tab. A third checkbox shows or hides the minimap button. The setting is the same for all characters.
- **Character tab:** it cannot be hidden.
- **Hidden tabs:** a hidden tab keeps its note. The note is back when you show the tab again.
- **Zone key:** one note exists for each zone map. One note exists for each instance. Subzones use the note of their parent zone.
- **No zone:** when the game reports no zone map, the Zone tab is disabled. Its tooltip is "No zone detected".
- **Last tab:** the window opens on the last tab you used. If that tab is hidden or disabled, it opens on the Character tab.

## Limits

- **Notes are written to disk on logout or /reload.** A client crash loses the changes since the last write.
- A click on a link in the note is best effort. It can fail on a client.
- When the note has focus, a shift-click on a bag stack can also open the stack split window. A shift-click on a quest in the objective tracker can also untrack it.
- When the chat edit box holds unsent text, a shift-clicked link goes to chat and not to the note.

## Supported clients

| Client | Interface |
| --- | --- |
| WoW Forever | `16001` |
| Retail (Midnight) | `120105` |

Classic clients are not supported.

## Development

The addon needs Lua 5.1 and these tools: busted, luacov, luacheck, and StyLua. The project root is the addon folder.

```sh
busted                                  # tests (must run on Lua 5.1)
luacheck .                              # lint
stylua --check .                        # format
rm -f luacov.stats.out luacov.report.out
busted --coverage && luacov && sed -n '/^Summary/,$p' luacov.report.out
```

- Each file in `Core/` must have at least 90% line coverage.
- The UI code is not unit tested. Run the checks in `docs/manual-tests.md` in the game, on both clients.
- To test in the game, link or copy the folder to `Interface/AddOns/SimpleNotebook`. Use `/reload` after each change.

## Release

1. Tag the commit: `git tag vX.Y.Z`.
2. Push the tag: `git push origin vX.Y.Z`.
3. The Release workflow builds `SimpleNotebook-vX.Y.Z.zip` with the BigWigsMods packager. It uploads the zip to GitHub Releases.

CurseForge upload:

- `SimpleNotebook.toc` holds the CurseForge project ID (`## X-Curse-Project-ID`).
- Add the repository secret `CF_API_TOKEN` to upload to CurseForge. Without it, the workflow skips CurseForge.

## License

See `LICENSE`.
