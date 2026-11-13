# Manual in-game tests

The WoW client has no headless test tool. These checks cover the UI code. The busted tests cover the core.

## Format

- Each entry is named `MT-<n>`.
- Each entry lists steps and the expected result.
- Each entry has one result line per client.
- Result values: `pass`, `fail`, `not run`, or `not reproduced`.
- Before each run, enter `/console scriptErrors 1`.
- After each code change, enter `/reload`.
- Install path Retail: `<WoW>/_retail_/Interface/AddOns/SimpleNotepad`.
- Install path Forever: `<WoW>/_forever_/Interface/AddOns/SimpleNotepad` (folder name not verified).

## Task 2: window and Character tab

### MT-1 Open the window
Steps:
1. Enter `/notepad`.
2. Enter `/np`.
3. Click the addon compartment entry.
4. Bind a key in Key Bindings > AddOns > Simple Notepad, then press it.
5. Click in the text area, then click the addon compartment entry.

Expected: each action toggles the window. The compartment entry shows the note icon. Step 5 closes the window.
- Forever: not run
- Retail: not run

### MT-2 ESC behavior
Steps:
1. Open the window and click in the text area.
2. Press ESC once.
3. Press ESC again.

Expected: the first ESC removes focus from the text area. The window stays open. The second ESC closes the window.
- Forever: not run
- Retail: not run

### MT-3 Window position
Steps:
1. Drag the window by its title bar to a new place.
2. Enter `/reload`.
3. Open the window.
4. Start to drag the window. Press ESC while the mouse button is still down. Release the button and open the window.

Expected: after step 3, the window is at the same place. After step 4, the window does not follow the cursor.
- Forever: not run
- Retail: not run

### MT-4 Note persistence
Steps:
1. Type three lines of text in the Character tab.
2. Enter `/reload` and open the window.
3. Log out, log in, and open the window.
4. Type lines until the text is taller than the text area.
5. Delete all text, then enter `/reload` and open the window.

Expected: the text is the same after steps 2 and 3. After step 4, the scroll bar scrolls the text. After step 5, the note is empty and no error shows.
- Forever: not run
- Retail: not run

### MT-5 No Lua errors
Steps:
1. Enter `/console scriptErrors 1`.
2. Do MT-1 to MT-4.

Expected: no Lua error window shows.
- Forever: not run
- Retail: not run

## Task 3: link insertion and link click

### MT-6 Insert links
Steps:
1. Open the window and click in the text area.
2. Shift-click a bag item.
3. Shift-click a quest in the quest log.
4. Shift-click a spell in the spellbook.
5. Shift-click a talent.
6. Shift-click an achievement.

Expected: each link appears at the cursor in its chat color.
- Forever: not run
- Retail: not run

### MT-7 No focus, no insert
Steps:
1. Open the window and press ESC once to remove focus.
2. Shift-click a bag item.

Expected: the note does not change.
- Forever: not run
- Retail: not run

### MT-8 Click a link in the note
Steps:
1. Put an item link in the note.
2. Click the link.

Expected: the item tooltip shows, as for a link in chat. Record pass or fail for each client. If it fails, links stay colored text only (risk R3).
- Forever: not run
- Retail: not run

### MT-9 Shift-click a link in the note
Steps:
1. Put an item link in the note.
2. Shift-click that link.

Expected: no second link is inserted.
- Forever: not run
- Retail: not run

### MT-10 Secret values
Steps:
1. Enter an instance and start an encounter.
2. Open the window, click in the text area, and shift-click a bag item.

Expected: no Lua error shows. The note does not change when the link is secret.
- Forever: not run
- Retail: not run

### MT-11 Links after reload
Steps:
1. Put two links in the note.
2. Enter `/reload` and open the window.

Expected: both links show with color.
- Forever: not run
- Retail: not run

## Task 4: Global tab and Settings toggles

### MT-12 Global note is shared
Steps:
1. On character A, open the Global tab and type a note.
2. Log in on character B and open the Global tab.

Expected: the same note shows.
- Forever: not run
- Retail: not run

### MT-13 Hide the Global tab
Steps:
1. Open Settings > AddOns > Simple Notepad. ESC closes the notepad window before it opens the game menu, so open the settings first.
2. Enter `/np`, open the Global tab, and move the window so its tabs are not under the Settings panel.
3. Clear "Show Global tab".

Expected: the Global tab disappears at once. The other tabs move left with no gap. The Character tab shows. Also clear "Show Zone tab": only the Character tab is left, at the left edge.
- Forever: not run
- Retail: not run

### MT-14 Show the Global tab again
Steps:
1. Check "Show Global tab".
2. Open the Global tab.

Expected: the old Global note is back.
- Forever: not run
- Retail: not run

### MT-15 Last tab
Steps:
1. Close the window while the Global tab is active.
2. Enter `/reload` and open the window.
3. Clear "Show Global tab" while the window is closed, then open the window.

Expected: after step 2 the window opens on Global. After step 3 the window opens on Character.
- Forever: not run
- Retail: not run
