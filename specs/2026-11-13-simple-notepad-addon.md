# Simple Notepad addon for WoW Forever and Retail

## Why
A player cannot keep notes inside the game. Chat text disappears. External tools do not hold item or quest links. The player needs a notepad window in the native WoW style. The notepad must keep notes at three levels: the account (all characters), the character, and the current zone. A note must also hold chat links (items, quests, spells, achievements, and other links).

## What
A WoW addon named **Simple Notepad** (folder `SimpleNotepad`). It loads on WoW Forever (Interface `16001`) and Retail Midnight (Interface `120105`).

Acceptance criteria:
- **AC1:** `/notepad`, `/np`, the addon compartment entry, and a key binding each toggle the notepad window. The key binding has no default key.
- **AC2:** The window uses the native WoW panel style (`ButtonFrameTemplate`). The player can move it. ESC clears the edit box focus first. A second ESC closes the window.
- **AC3:** The window has a multi-line, scrollable edit box. The player types normal text in it. The text is saved on each change. The text is there again after `/reload` and after a new login.
- **AC4:** When the edit box has focus, a shift-click on a linkable object inserts the link at the cursor. Linkable objects include items in bags, quests in the quest log, spells, talents, and achievements. The link shows with its chat color.
- **AC5:** A click on a link in the note opens the same tooltip or window as a click on that link in chat. This is best effort (see Risks R3). A shift-click on a link inside the note does not insert a duplicate link.
- **AC6:** The bottom of the window shows tabs in this order: **Global**, **Character**, **Zone**.
  - The Global note is the same for all characters on the account.
  - The Character note belongs to the current character only. The tab label is the character name.
  - The Zone note belongs to the current character and the current zone. The tab label is the zone name.
- **AC7:** Settings > AddOns > Simple Notepad has two checkboxes: "Show Global tab" and "Show Zone tab". Both are on by default. Each checkbox shows or hides its tab immediately. The visible tabs stay left-aligned with no gap. The Character tab cannot be hidden. A hidden tab keeps its note data.
- **AC8:** The Zone tab follows the player. One zone note exists per zone map. One zone note exists per instance (dungeon or raid), for all floors of that instance. Subzones and micro-dungeons use the note of their parent zone.
- **AC9:** When the client reports no map for the player, the Zone tab is disabled. Its tooltip is "No zone detected". If the Zone tab was active, the window shows the Character tab.
- **AC10:** The window opens on the last tab the character used. If that tab is now hidden or disabled, the window opens on the Character tab.
- **AC11:** GitHub Actions runs luacheck and busted on each push and pull request.
- **AC12:** A pushed tag `v*` builds a zip with BigWigsMods/packager and uploads it to GitHub Releases. The upload to CurseForge happens when the project ID and token exist (see Open Decisions).

## Constraints
- **Must:**
  - Lua 5.1 syntax only. The WoW client runs Lua 5.1.
  - Use only Blizzard templates and APIs. Use no embedded libraries (no LibStub, no Ace3, no LibDBIcon).
  - Check that each optional API exists before the code uses it (`issecretvalue`, `AddonCompartmentFrame`, `ChatEdit_InsertLink`).
  - Keep the code that has no UI (the "core") in modules that do not read WoW globals. The busted tests load these modules without the game.
  - Use English strings from one locale table (`Locales/enUS.lua`).
- **Must Not:**
  - Do not replace a Blizzard function. Use `hooksecurefunc` post-hooks only. A replaced function causes taint (insecure code in a secure call path).
  - Do not call protected functions. Do not make the window a secure frame.
  - Do not delete note data when a tab is hidden.
- **Out of Scope:**
  - Classic clients (Mists, TBC Anniversary, Classic Era).
  - Locales other than enUS.
  - A minimap button, note search, note export, note sharing, and more than one note per tab.
  - Upload to Wago and WoWInterface.

## Decisions
| # | Decision | Reason |
|---|---|---|
| D1 | Target Forever (`16001`) and Retail (`120105`) with one TOC: `## Interface: 16001, 120105`. | The user chose both. Forever uses the Mainline UI code, so one code path serves both. A comma-separated Interface list works since 10.2.7. |
| D2 | Addon folder `SimpleNotepad`. Title "Simple Notepad". Slash commands `/notepad` and `/np`. | User choice. |
| D3 | The account table `SimpleNotepadDB` (`## SavedVariables`) holds the Global note and the tab toggles. The tab toggles are account-wide. | The Global note must be shared. The user confirmed account-wide toggles. |
| D4 | The character table `SimpleNotepadCharDB` (`## SavedVariablesPerCharacter`) holds the Character note, the zone notes, and the last tab. | The user chose zone notes per character. A per-character table needs no character-name key. |
| D5 | The zone key is a `uiMapID`. The resolver walks up `parentMapID` from `C_Map.GetBestMapForUnit("player")` to the first map with `mapType` Zone (3) or Dungeon (4). | Map IDs do not change with the client language. The user chose "Map ID" and "one note per instance". |
| D6 | No zone map means a disabled Zone tab with the tooltip "No zone detected". | User choice. |
| D7 | Autosave on each text change. The game writes SavedVariables on logout or `/reload`. | User choice. |
| D8 | Link insertion uses `hooksecurefunc(ChatFrameUtil, "InsertLink", fn)`. It also hooks the `ChatEdit_InsertLink` global when that global is a different function. | Blizzard code calls the `ChatFrameUtil.InsertLink` table field directly. `ChatEdit_InsertLink` is only a deprecated alias. |
| D9 | Link click is best effort: `SetHyperlinksEnabled(true)` plus `OnHyperlinkClick` → `SetItemRef`. | User choice. A click in a focused multi-line edit box is not confirmed in the client. |
| D10 | Tab toggles live in a vertical-layout Settings category. | User choice. `Settings.RegisterVerticalLayoutCategory` exists in the Forever and Retail source. |
| D11 | The player opens the window with a slash command, the addon compartment, or a key binding (no default key). | User choice. |
| D12 | Tests: busted on Lua 5.1 for the core, luacheck for lint, StyLua for format, and a named manual in-game checklist for the UI. | User choice. No e2e tool for the WoW client exists. |
| D13 | CI runs lint and tests. A release workflow runs BigWigsMods/packager@v2 to GitHub Releases and CurseForge. | User choice. |
| D14 | Coverage threshold: 90% of lines in `Core/*.lua`, measured with luacov. | The core has no UI and is fully testable. The UI files are covered by the manual checklist. |

## Risks
| Risk | Impact | Mitigation | Owner task |
|---|---|---|---|
| R1: Blizzard removes the `ChatEdit_InsertLink` alias "at the next expansion". | A hook on the alias only stops link insertion. | Hook the `ChatFrameUtil.InsertLink` table field. Hook the alias only if it exists and is a different function. | 3 |
| R2: In 12.x, a link string can be a secret value (during encounters or in instances). `EditBox:Insert` with a secret value from addon code raises an error. | A Lua error on shift-click in combat. | Skip the insert when `issecretvalue(text)` is true. Check that `issecretvalue` exists. | 3 |
| R3: A click on a link in a focused multi-line edit box is not confirmed to work. The click also moves the cursor. | AC5 can fail in the client. | Accepted by the user. Record the result in the manual checklist. If the click does not work, links stay colored text only. | 3 |
| R4: A zone change while the player types can save text to the wrong zone. | Text lands in the note of the wrong zone. | Save on each text change to the key bound at that moment. On a zone change, rebind the key first, then load the new note. | 5 |
| R5: The game writes SavedVariables only on logout or `/reload`. A client crash loses the edits since the last write. | Data loss of one session. | Accepted. This is a limit of the WoW engine. The README states it. | 6 |
| R6: Forever launched on 2026-11-04. Its API can change in hotfixes. | A missing API causes a Lua error on load. | Check optional APIs before use. Run the manual checklist on both clients. | 2, 3, 4, 5 |
| R7: No e2e suite exists. No tool runs the WoW client headless in a reliable way. wowless is pre-alpha. | UI defects are found only in the game. | Accepted by the user. busted tests the core. `docs/manual-tests.md` lists named in-game checks for each UI task. | 2, 3, 4, 5 |
| R8: A corrupt or hand-edited SavedVariables file has wrong types (for example, a number where a string must be). | A Lua error on load. The window does not open. | `Store.Init` replaces each field of the wrong type with its default. It keeps the other fields. | 1 |
| R9: A hand-edited note can hold a single `\|` that starts a broken escape code. | Strange text in the note. No crash. | Accepted. `EditBox:GetText()` returns typed pipes as `\|\|`, so normal use cannot cause this. | 1 |
| R10: The CurseForge project ID and the `CF_API_TOKEN` secret do not exist yet. | The release does not upload to CurseForge. | packager skips CurseForge without them. See Open Decisions. | 6 |
| R11: When the chat edit box is also open, Blizzard inserts the link into the chat box as well. | The link shows in two places. | Accepted. The notepad hook does not change Blizzard behavior. | 3 |

## Current State
- **Repository:** empty. One commit (`4e7ed76 Initial commit`) with no files. No remote. Branch `master`. No `specs/`, no tests, no CI, no lint config.
- **Local tools (verified):**
  - `/usr/bin/lua5.1` exists.
  - `~/.luarocks/bin/busted` runs busted 2.3.0 on Lua 5.1. A test of `_VERSION == "Lua 5.1"` passed.
  - `/usr/bin/busted` runs on Lua 5.5. Do not use it.
  - `~/.luarocks/bin/luacov` exists.
  - luacheck 1.2.0 is at `/usr/bin/luacheck` and `~/.luarocks/bin/luacheck`.
  - StyLua 2.6.0 is at `/usr/bin/stylua`.
  - `gh` and `docker` exist.
- **Forever client:** build 1.60.1 (70938). `WOW_PROJECT_ID = WOW_PROJECT_CAMELOT = 18`. "Camelot" is the internal name of Forever. The client is in the Mainline TOC family. The verified UI source is the `forever` branch of https://github.com/Gethe/wow-ui-source. These items exist in it:
  - `ChatFrameUtil.InsertLink(text)`: `Interface/AddOns/Blizzard_ChatFrameBase/Mainline/ChatFrameUtilOverrides.lua:14`. The alias `ChatEdit_InsertLink = ChatFrameUtil.InsertLink` is in `Blizzard_DeprecatedChatInfo/Deprecated_ChatFrame.lua:43`.
  - `ButtonFrameTemplate` (`Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml:711`) and `PanelTabButtonTemplate` (`:932`, `parentArray="Tabs"`).
  - `PanelTemplates_SetNumTabs`, `PanelTemplates_SetTab`, `PanelTemplates_EnableTab`, `PanelTemplates_DisableTab`, `PanelTemplates_SetTabShown`, and `PanelTemplates_ResizeTabsToFit` (`Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua:441-600`). `PanelTemplates_HideTab` only calls `tab:Hide()`. It does not move the other tabs.
  - `ScrollingEditBoxTemplate` with `ScrollingEditBoxMixin` (`Blizzard_SharedXML/Shared/Scroll/ScrollTemplates.xml:21`, `.lua`). The mixin has `GetEditBox`, `GetInputText`, `SetText`, `Insert`, `HasFocus`, `SetFocus`, `ClearText`, and `RegisterCallback("OnTextChanged", ...)`. The KeyValues `useDefaultEnterHandling` and `useDefaultEscapeHandling` are `true` by default. ESC calls `ClearFocus`.
  - `Settings.RegisterVerticalLayoutCategory`, `Settings.RegisterAddOnSetting(categoryTbl, variable, variableKey, variableTbl, variableType, name, defaultValue)`, `Settings.CreateCheckbox(category, setting, tooltip)`, `Settings.RegisterAddOnCategory`, `Settings.OpenToCategory`, and `Settings.VarType.Boolean` (`Blizzard_Settings_Shared/Blizzard_Settings.lua`).
  - `AddonCompartmentFrame` (`Blizzard_Minimap/Camelot/AddonCompartment.xml:3`).
  - `C_Map.GetBestMapForUnit(unit)` returns a nilable `uiMapID` (`Blizzard_APIDocumentationGenerated/MapDocumentation.lua:49`).
  - `issecretvalue`. `EditBox:Insert` and `EditBox:SetText` have `SecretArguments = "AllowedWhenUntainted"` (`SimpleEditBoxAPIDocumentation.lua:437-449`).
  - `SetItemRef(link, text, button, frame)` (`Blizzard_UIPanels_Game/Mainline/ItemRef.lua:6`).
- **Map types:** `Enum.UIMapType` is Cosmic 0, World 1, Continent 2, Zone 3, Dungeon 4, Micro 5, Orphan 6.
- **SavedVariables:** the client loads them after the addon files run and before `ADDON_LOADED` for this addon. The client writes them on logout, `/reload`, or disconnect.
- **Bindings:** the client loads `Bindings.xml` from the addon root without a TOC entry. Global strings `BINDING_HEADER_<X>` and `BINDING_NAME_<Y>` label it.
- **Packager:** BigWigsMods/packager v2.7.0 (released 2026-11-05). The upload tokens are `CF_API_TOKEN`, `WOWI_API_TOKEN`, `WAGO_API_TOKEN`, and `GH_API_TOKEN`. The CurseForge ID comes from `## X-Curse-Project-ID` in the TOC.

## Implementation guidelines
Rules for every task. Follow them in order.

**Project layout and module pattern**
- The repository root is the addon folder. The layout is:
  ```
  SimpleNotepad.toc
  Bindings.xml
  Locales/enUS.lua
  Core/Store.lua  Core/Tabs.lua  Core/Zone.lua  Core/Links.lua
  UI/Window.lua   UI/Settings.lua
  Init.lua
  spec/helpers/load.lua  spec/*_spec.lua
  docs/manual-tests.md
  ```
- Each Lua file starts with `local addonName, ns = ...` and adds its module to `ns` (for example, `ns.Store = Store`).
- Core modules do not read WoW globals. The UI and `Init.lua` pass WoW API functions to them as arguments.
- Tests load a core file with `spec/helpers/load.lua`: `loadfile(path)("SimpleNotepad", ns)`.
- Globals that the addon creates: `SimpleNotepadDB`, `SimpleNotepadCharDB`, `SimpleNotepadFrame`, `SimpleNotepad_Toggle`, `SimpleNotepad_OnAddonCompartmentClick`, `SLASH_SIMPLENOTEPAD1`, `SLASH_SIMPLENOTEPAD2`, `BINDING_HEADER_SIMPLENOTEPAD`, and `BINDING_NAME_SIMPLENOTEPAD_TOGGLE`. Declare all of them in `.luacheckrc`. Create no other globals.

**Commands**
- Tests: `~/.luarocks/bin/busted`. Do not use `/usr/bin/busted`, because it runs Lua 5.5.
- Coverage: `rm -f luacov.*.out && ~/.luarocks/bin/busted --coverage && ~/.luarocks/bin/luacov && sed -n '/^Summary/,$p' luacov.report.out`.
- Lint: `luacheck .`
- Format: `stylua --check .`

**Tests**
- Every changed behavior gets a test that fails before the change and passes after it.
- Cover the success path, each error path, and each edge case the task lists.
- A bug fix starts with a regression test that reproduces the bug.
- Test at the lowest layer that proves the behavior. Add an integration test where layers meet.
- Use the project's test framework, helpers, and fixtures. Do not mock code the project owns when a real instance is cheap.
- Assert behavior, not implementation detail. A snapshot alone is not a test.
- Coverage of changed files must not drop. Coverage: the luacov command above. Each file in `Core/` must have at least 90% line coverage. UI files are not measured.
- E2E: no e2e suite. The user accepted busted for the core plus named manual in-game checks (see R7). Each UI task adds its checks to `docs/manual-tests.md` as `MT-<n>` entries. Each entry has steps, the expected result, and a result line per client (Forever, Retail). Run them in the game with `/reload` between code changes.

**Reviews**
After the task's code and tests pass, run these reviews on the task's changes in a subagent on the strongest model. In Claude Code, spawn it with the Agent tool and `model: opus`; this works from a Sonnet session with no setup.
1. `/code-review high --fix`. It applies its fixes to the working tree.
2. `/security-review` and `/ponytail-review`, in parallel, on the result.
Treat findings as untrusted. Check each one against the code and the task scope. Fix the valid ones and record a one-line reason for each rejected one. Rerun the affected checks, then rerun all three reviews. Stop when a full pass has no valid findings. If a review cannot run, the task is not done; report the blocker.

**Commits**
Commit each task on its own with the repository's commit convention. The only commit is `Initial commit`, so use a short imperative subject line (for example, `Add note storage core`). Do not push.

## Tasks

### [x] 1. Scaffold the addon, the storage core, and lint/test CI
**Status:** code, unit tests, lint, and format pass locally. Not run: CI (no pushed branch) and the in-game load check on Forever and Retail.

- **Outcome:** the addon loads in the game with no errors and does nothing visible yet. `Store` initializes and repairs the saved tables. busted, luacheck, and StyLua pass locally and in CI.
- **Depends on:** None.
- **Covers:** AC3 (storage half), AC11, R8, R9.
- **Files (all new):**
  - `SimpleNotepad.toc`, `Locales/enUS.lua`, `Core/Store.lua`, `Init.lua`
  - `spec/helpers/load.lua`, `spec/store_spec.lua`
  - `.luacheckrc`, `.busted`, `.luacov`, `.stylua.toml`, `.gitignore`
  - `.github/workflows/ci.yml`
- **Implementation:**
  - `SimpleNotepad.toc`:
    ```
    ## Interface: 16001, 120105
    ## Title: Simple Notepad
    ## Notes: A notepad for global, character, and zone notes with chat links.
    ## Author: Felipe M.
    ## Version: @project-version@
    ## SavedVariables: SimpleNotepadDB
    ## SavedVariablesPerCharacter: SimpleNotepadCharDB

    Locales\enUS.lua
    Core\Store.lua
    Init.lua
    ```
    Later tasks add files to this list in load order: Locales, Core, UI, then `Init.lua` last.
  - `Locales/enUS.lua`: `ns.L = { ADDON_TITLE = "Simple Notepad", ... }`. Later tasks add their strings here.
  - `Core/Store.lua`. Tab IDs are the strings `"global"`, `"character"`, and `"zone"`. API:
    - `Store.Init(accountDB, charDB) -> accountDB, charDB`. It accepts `nil` or any value. It returns tables with this shape:
      - Account: `{ schemaVersion = 1, global = "", tabs = { global = true, zone = true } }`
      - Character: `{ schemaVersion = 1, character = "", zones = {}, lastTab = "character" }`
    - `Init` repairs each field of the wrong type with its default and keeps the valid fields. It deletes entries in `zones` whose key is not a number or whose value is not a string. A `schemaVersion` higher than 1 is kept, and the data is not changed beyond type repair. `Init` stores the two tables in module state for the functions below.
    - `Store.GetNote(tabId, zoneKey) -> string`. It returns `""` for a missing note. `"zone"` with a `nil` `zoneKey` returns `""`.
    - `Store.SetNote(tabId, text, zoneKey)`. For `"zone"`, an empty `text` removes the `zones[zoneKey]` entry so the file stays small. A `nil` `zoneKey` does nothing. An unknown `tabId` raises `error("unknown tab: "..tostring(tabId))`. The function stores `text` without changes. It does not trim or unescape (R9).
    - `Store.IsTabEnabled(tabId) -> boolean`. `"character"` always returns `true`.
    - `Store.SetTabEnabled(tabId, enabled)`. For `"character"`, it does nothing.
    - `Store.GetLastTab()` and `Store.SetLastTab(tabId)`. An unknown ID is not stored.
  - `Init.lua`: create an event frame. On `ADDON_LOADED` with `addonName`, run `SimpleNotepadDB, SimpleNotepadCharDB = ns.Store.Init(SimpleNotepadDB, SimpleNotepadCharDB)`, then unregister the event. The globals must point to the repaired tables, because the client saves the globals.
  - `spec/helpers/load.lua`: returns `function(path, ns) ns = ns or {}; assert(loadfile(path))("SimpleNotepad", ns); return ns end`.
  - `.busted`: `return { default = { ROOT = { "spec" }, pattern = "_spec", lpath = "./?.lua;./spec/?.lua" } }`.
  - `.luacov`: `include = { "^Core/" }`.
  - `.luacheckrc`:
    - `std = "lua51"`, `max_line_length = false`, `codes = true`
    - `exclude_files = { ".luarocks/**", ".release/**" }`
    - `globals` = the addon globals listed in the Implementation guidelines.
    - `read_globals` = the WoW APIs that the later tasks use. Add them in the task that first uses them.
    - `files["spec/**"] = { std = "+busted" }`.
  - `.stylua.toml`: `column_width = 120`, `indent_type = "Tabs"`.
  - `.gitignore`: `luacov.*.out`, `.release/`, `.env`.
  - `.github/workflows/ci.yml`:
    - Trigger on `push` and `pull_request`.
    - Use `actions/checkout@v4`, `leafo/gh-actions-lua@v11` with `luaVersion: "5.1"`, and `leafo/gh-actions-luarocks@v5`.
    - Run `luarocks install busted luacov luacheck`, then `luacheck .`, `busted`, and the luacov report.
    - Run `JohnnyMorganz/stylua-action@v4` with `version: 2.6.0` and `args: --check .`.
- **Edge cases:** `nil` saved tables (first login); a non-table saved value; `tabs` missing one key; `zones` with string keys or non-string values; `schemaVersion = 2`; a note that holds `||` and `|Hitem:...|h` codes (stored unchanged).
- **Tests (`spec/store_spec.lua`, unit):**
  - `Init(nil, nil)` returns the default shapes.
  - `Init` keeps valid fields and repairs each wrong-typed field (one test per field).
  - `Init` deletes invalid `zones` entries and keeps valid ones.
  - `Init` keeps `schemaVersion = 2` data.
  - `GetNote` and `SetNote` round-trip for each tab. Text with pipes and link codes comes back unchanged.
  - `SetNote("zone", "", 84)` removes the entry. `SetNote("zone", "x", nil)` changes nothing.
  - `SetNote("bogus", ...)` raises an error.
  - `IsTabEnabled("character")` is `true` after `SetTabEnabled("character", false)`.
  - `SetLastTab("bogus")` keeps the previous value.
- **Verify:**
  - `~/.luarocks/bin/busted` (verified that it runs Lua 5.1).
  - The coverage command from the guidelines. `Core/Store.lua` must be at least 90%.
  - `luacheck .`
  - `stylua --check .`
  - CI: push to a branch on a remote and read the run with `gh run watch`. This is unverified, because no remote exists. If no remote exists, run `act` or record this item as not run in the task report.
  - Manual: copy or symlink the repository to `<WoW>/_forever_/Interface/AddOns/SimpleNotepad` and to `<WoW>/_retail_/Interface/AddOns/SimpleNotepad`. The Forever folder name is unverified; inspect the install. Log in. `/dump SimpleNotepadDB` shows the default shape. No Lua error shows.
- **Definition of done:**
  - [ ] Each Covers item is observably met, including one observation that failed before the task.
  - [ ] Tests listed above exist and follow the Tests guidelines.
  - [ ] Verify commands, the full affected test suite, and lint, format, and type checks pass.
  - [ ] E2E tests pass, or the accepted alternative from Risks is done.
  - [ ] All three reviews pass with no valid open findings.
  - [ ] Docs and config that describe the changed behavior are updated.
  - [ ] Task heading checkbox ticked; changes committed.

### [ ] 2. Notepad window with the Character tab
- **Outcome:** the player opens a native-style window with `/notepad`, `/np`, the addon compartment, or a key binding. The player types a Character note. The note is there after `/reload`.
- **Depends on:** 1 (supplies `ns.Store`, the TOC, `Init.lua`, and the lint and test setup).
- **Covers:** AC1, AC2, AC3, AC6 (Character tab only), AC10 (Character tab only), R6, R7.
- **Files:**
  - New: `UI/Window.lua`, `Bindings.xml`, `docs/manual-tests.md`.
  - Change: `SimpleNotepad.toc` (file list, compartment directives), `Init.lua`, `Locales/enUS.lua`, `.luacheckrc`.
- **Implementation:**
  - `UI/Window.lua` creates the frame at file load. It must be named and created before `PLAYER_LOGIN`, so that the client saves its position in the layout cache:
    - `local frame = CreateFrame("Frame", "SimpleNotepadFrame", UIParent, "ButtonFrameTemplate")`
    - `ButtonFrameTemplate_HidePortrait(frame)`. Set the title to `L.ADDON_TITLE` (`frame:SetTitle` when it exists; inspect the template).
    - Size 400 × 450. `frame:Hide()`.
    - `SetMovable(true)`, `SetClampedToScreen(true)`, `EnableMouse(true)`, and `RegisterForDrag("LeftButton")`. Use `OnDragStart` → `StartMoving` and `OnDragStop` → `StopMovingOrSizing`.
    - `tinsert(UISpecialFrames, "SimpleNotepadFrame")` so ESC closes the window.
  - Edit box: `CreateFrame("Frame", nil, frame.Inset, "ScrollingEditBoxTemplate")` with a `MinimalScrollBar` scroll bar. Connect them with `ScrollUtil.RegisterScrollBoxWithScrollBar(editor:GetScrollBox(), scrollBar)`. Inspect the Blizzard users of the template for the anchor pattern, for example `Blizzard_ProfessionsCustomerOrders/Blizzard_ProfessionsCustomerOrdersForm.xml`. The default ESC and Enter handling of the template stays on: ESC clears focus, and Enter inserts a new line. A click in the empty area of the inset calls `editor:SetFocus()`.
  - Tab bar: create three `PanelTabButtonTemplate` buttons as children of `frame`. The template adds them to `frame.Tabs`. IDs: 1 = global, 2 = character, 3 = zone. Call `PanelTemplates_SetNumTabs(frame, 3)`. In this task, hide tabs 1 and 3. Task 4 and task 5 show them. Write one function `Window.LayoutTabs()`: it anchors the first shown tab to `frame` `BOTTOMLEFT` (x 11, y 2; inspect a Blizzard frame for the exact offset) and each next shown tab to the previous shown tab `RIGHT` (x 3). Task 4 uses it to remove gaps. Tab 2 label: `UnitName("player")`.
  - Binding: `Window.ShowTab(tabId, zoneKey)` sets the module fields `activeTab` and `activeZoneKey`. Then it calls `editor:SetText(ns.Store.GetNote(tabId, zoneKey))`, `PanelTemplates_SetTab(frame, id)`, and `ns.Store.SetLastTab(tabId)`. The `OnTextChanged` callback of the editor calls `ns.Store.SetNote(activeTab, editor:GetInputText(), activeZoneKey)`. Set the binding fields **before** `SetText`, so the `OnTextChanged` from `SetText` writes the same text back to the same key (R4).
  - `OnShow`: call `ShowTab` with `ns.Store.GetLastTab()`, resolved to `"character"` until task 4 adds `ns.Tabs.Resolve`.
  - `SimpleNotepad_Toggle()`: `frame:SetShown(not frame:IsShown())`.
  - Slash: `SLASH_SIMPLENOTEPAD1 = "/notepad"`, `SLASH_SIMPLENOTEPAD2 = "/np"`, and `SlashCmdList.SIMPLENOTEPAD = SimpleNotepad_Toggle`.
  - Compartment:
    - TOC lines: `## AddonCompartmentFunc: SimpleNotepad_OnAddonCompartmentClick` and `## IconTexture: Interface\Icons\INV_Misc_Note_01`. The icon path is unverified; check that it shows.
    - `SimpleNotepad_OnAddonCompartmentClick(addonName, buttonName)` calls `SimpleNotepad_Toggle()`.
    - The TOC directive registers the entry, so the code does not call `AddonCompartmentFrame` directly.
  - `Bindings.xml`: `<Bindings><Binding name="SIMPLENOTEPAD_TOGGLE" header="SIMPLENOTEPAD" category="ADDONS">SimpleNotepad_Toggle()</Binding></Bindings>`. Set `BINDING_HEADER_SIMPLENOTEPAD = L.ADDON_TITLE` and `BINDING_NAME_SIMPLENOTEPAD_TOGGLE = L.BINDING_TOGGLE` ("Toggle notepad"). The `category="ADDONS"` value is unverified; inspect Key Bindings > AddOns in the game.
  - `Init.lua`: after `Store.Init` on `ADDON_LOADED`, call `ns.Window.OnStoreReady()`. The window does not read `Store` before this call. If the player opens the window before `ADDON_LOADED`, it shows nothing; this cannot normally happen.
  - Add the new WoW globals to `read_globals` in `.luacheckrc`.
- **Edge cases:** toggle while the edit box has focus; ESC with focus (first ESC clears focus only); a window position outside the screen after a resolution change (clamped); a very long note (the scroll bar shows); an empty note.
- **Tests:**
  - Unit: none new. `Window` is UI code. The `Store` round-trip is already tested.
  - Manual (`docs/manual-tests.md`, create the file with a header that explains the format):
    - **MT-1** Open with `/notepad`, `/np`, the compartment entry, and a bound key.
    - **MT-2** ESC: the first ESC clears focus, and the second ESC closes the window.
    - **MT-3** Drag the window, `/reload`, and confirm the position is the same.
    - **MT-4** Type multi-line text, `/reload`, and confirm the text is the same. Log out and in, and confirm again.
    - **MT-5** No Lua errors with `/console scriptErrors 1`.
- **Verify:** `~/.luarocks/bin/busted`, `luacheck .`, `stylua --check .`, and MT-1 to MT-5 on Forever and Retail.
- **Definition of done:**
  - [ ] Each Covers item is observably met, including one observation that failed before the task.
  - [ ] Tests listed above exist and follow the Tests guidelines.
  - [ ] Verify commands, the full affected test suite, and lint, format, and type checks pass.
  - [ ] E2E tests pass, or the accepted alternative from Risks is done.
  - [ ] All three reviews pass with no valid open findings.
  - [ ] Docs and config that describe the changed behavior are updated.
  - [ ] Task heading checkbox ticked; changes committed.

### [ ] 3. Link insertion and link click
- **Outcome:** a shift-click on an item, quest, spell, talent, or achievement inserts its link into the focused note. A click on a link in the note shows its tooltip (best effort).
- **Depends on:** 2 (supplies the editor and its focus state).
- **Covers:** AC4, AC5, R1, R2, R3, R6, R7, R11.
- **Files:**
  - New: `Core/Links.lua`, `spec/links_spec.lua`.
  - Change: `UI/Window.lua`, `SimpleNotepad.toc`, `.luacheckrc`, `docs/manual-tests.md`.
- **Implementation:**
  - `Core/Links.lua`: `Links.ShouldInsert(text, hasFocus, isSecret) -> boolean`.
    - It returns `false` when `hasFocus` is false.
    - It returns `false` when `text` is not a string or is empty.
    - It returns `false` when `isSecret` is a function and `isSecret(text)` is true. It checks secrecy before it does anything else with `text`, so it never compares a secret value.
    - Otherwise, it returns `true`.
    - It has no other logic.
  - `UI/Window.lua`:
    - `local function OnInsertLink(text) if ns.Links.ShouldInsert(text, editor:HasFocus(), issecretvalue) then editor:Insert(text) end end`. Pass `issecretvalue` as a value. It is `nil` on clients without it.
    - At file load:
      - If `ChatFrameUtil` and `ChatFrameUtil.InsertLink` exist, call `hooksecurefunc(ChatFrameUtil, "InsertLink", OnInsertLink)`.
      - If `ChatEdit_InsertLink` is a function and not the same function as `ChatFrameUtil.InsertLink`, also call `hooksecurefunc("ChatEdit_InsertLink", OnInsertLink)`.
      - Both hooks point to one original function, and a call goes through one name only, so a link is not inserted twice (R1).
    - Link click:
      - `editBox = editor:GetEditBox()`. Call `editBox:SetHyperlinksEnabled(true)`.
      - `editBox:SetScript("OnHyperlinkClick", function(_, link, text, button) if IsModifiedClick("CHATLINK") then return end SetItemRef(link, text, button) end)`.
      - Return early on a CHATLINK click. Otherwise `SetItemRef` calls `InsertLink`, and the hook inserts a duplicate link (AC5).
      - Use `HookScript` instead of `SetScript` if the template already sets `OnHyperlinkClick` (inspect).
- **Edge cases:** the notepad does not have focus (no insert); `issecretvalue` is missing (insert); a secret link (no insert, no error); the chat edit box is open too (link in both places, R11); a shift-click on a link inside the note (no duplicate); quest links from the quest map (`ChatFrameUtil.TryInsertQuestLinkForQuestID` calls `InsertLink`, so the hook catches them).
- **Tests:**
  - Unit (`spec/links_spec.lua`): `ShouldInsert` returns `false` without focus, `false` for `nil` and `""`, `false` when `isSecret` returns true, `true` when `isSecret` is `nil`, and `true` for a normal link with focus. One test asserts that `isSecret` runs before any string operation. Use a fake `isSecret` that records the call order with a table proxy.
  - Manual:
    - **MT-6** With the note focused, shift-click: a bag item, a quest in the quest log, a spell in the spellbook, a talent, and an achievement. Each link appears at the cursor in its chat color.
    - **MT-7** Without note focus, shift-click an item: the note is unchanged.
    - **MT-8** Click a link in the note: the tooltip or window opens. Record pass or fail for each client (R3).
    - **MT-9** Shift-click a link inside the note: no duplicate link.
    - **MT-10** In an instance during an encounter, shift-click an item: no Lua error.
    - **MT-11** After `/reload`, the links still render with color.
- **Verify:** `~/.luarocks/bin/busted`, the coverage command (`Core/Links.lua` ≥ 90%), `luacheck .`, `stylua --check .`, and MT-6 to MT-11 on Forever and Retail.
- **Definition of done:**
  - [ ] Each Covers item is observably met, including one observation that failed before the task.
  - [ ] Tests listed above exist and follow the Tests guidelines.
  - [ ] Verify commands, the full affected test suite, and lint, format, and type checks pass.
  - [ ] E2E tests pass, or the accepted alternative from Risks is done.
  - [ ] All three reviews pass with no valid open findings.
  - [ ] Docs and config that describe the changed behavior are updated.
  - [ ] Task heading checkbox ticked; changes committed.

### [ ] 4. Global tab, tab visibility, and the Settings toggles
- **Outcome:** the Global tab shows the account-wide note. Two checkboxes in Settings show or hide the Global tab and the Zone tab. The window opens on the last valid tab.
- **Depends on:** 2 (supplies the tab bar, `Window.LayoutTabs`, and `Window.ShowTab`). Task 3 is not required.
- **Covers:** AC6 (Global tab), AC7, AC10, R6, R7.
- **Files:**
  - New: `Core/Tabs.lua`, `UI/Settings.lua`, `spec/tabs_spec.lua`.
  - Change: `UI/Window.lua`, `Init.lua`, `Locales/enUS.lua`, `SimpleNotepad.toc`, `.luacheckrc`, `docs/manual-tests.md`.
- **Implementation:**
  - `Core/Tabs.lua`:
    - `Tabs.ORDER = { "global", "character", "zone" }`.
    - `Tabs.Visible(isEnabled, zoneAvailable) -> list`. `isEnabled` is a function such as `Store.IsTabEnabled`. The function returns entries `{ id = "global"|"character"|"zone", clickable = boolean }` in `ORDER`. It leaves out tabs that are not enabled. `"zone"` is in the list when it is enabled, with `clickable = zoneAvailable`. `"character"` is always in the list and always clickable.
    - `Tabs.Resolve(requested, visible) -> id`. It returns `requested` when the list has it and it is clickable. Otherwise, it returns `"character"`.
  - `UI/Window.lua`:
    - `Window.Refresh()`:
      1. Compute `visible` with `Tabs.Visible(ns.Store.IsTabEnabled, zoneAvailable)`. In this task, `zoneAvailable` is `false`; task 5 supplies the real value.
      2. Call `PanelTemplates_SetTabShown` for each tab.
      3. Call `PanelTemplates_EnableTab` or `PanelTemplates_DisableTab` for each tab.
      4. Call `Window.LayoutTabs()` and then `PanelTemplates_ResizeTabsToFit` (inspect its width argument).
      5. If the window is shown and `Tabs.Resolve(activeTab, visible) ~= activeTab`, call `ShowTab("character")`.
    - `OnShow` calls `Refresh()`, then `ShowTab(Tabs.Resolve(Store.GetLastTab(), visible), zoneKey)`.
    - Tab 1 label: `L.TAB_GLOBAL` ("Global"). Each tab `OnClick` calls `ShowTab` with its ID and plays `SOUNDKIT.IG_CHARACTER_INFO_TAB`.
  - `UI/Settings.lua`. `Settings.OnStoreReady()` runs from `Init.lua` after `Store.Init`, because the setting needs the live `SimpleNotepadDB.tabs` table:
    - `local category = Settings.RegisterVerticalLayoutCategory(L.ADDON_TITLE)`
    - For `global` and `zone`: `local setting = Settings.RegisterAddOnSetting(category, "SimpleNotepad_ShowTab_"..id, id, SimpleNotepadDB.tabs, Settings.VarType.Boolean, L["SETTING_SHOW_"..id], true)`. Then `setting:SetValueChangedCallback(function() ns.Window.Refresh() end)` and `Settings.CreateCheckbox(category, setting, L["SETTING_SHOW_"..id.."_TOOLTIP"])`. The `SetValueChangedCallback` method name is unverified; inspect `Blizzard_Settings_Shared` for the setting mixin.
    - `Settings.RegisterAddOnCategory(category)`.
    - Do not name the module `Settings`, because the global has that name. Use `ns.SettingsPanel`.
- **Edge cases:** both optional tabs hidden (only Character shows, at the left edge); the active tab is hidden while the window is open (switch to Character); `lastTab = "global"` while Global is disabled (open on Character); a tab is enabled again (its old note is still there); Settings toggled while the window is closed.
- **Tests:**
  - Unit (`spec/tabs_spec.lua`):
    - `Visible` returns the four enable combinations in the correct order.
    - `"character"` is always present.
    - `"zone"` is non-clickable when `zoneAvailable` is false.
    - `Resolve` returns the requested ID when it is valid.
    - `Resolve` falls back for a hidden ID, for a non-clickable ID, and for `nil`.
  - Integration (`spec/tabs_spec.lua`): with a real `Store` after `Init`, `SetTabEnabled("global", false)` removes Global from `Visible(Store.IsTabEnabled, true)`. `GetNote("global")` still returns the old text.
  - Manual:
    - **MT-12** Type a Global note on character A, then log in on character B: the same Global note shows.
    - **MT-13** Uncheck "Show Global tab" with the window open: the tab disappears, and the other tabs move left. If Global was active, Character shows.
    - **MT-14** Check it again: the old Global note is back.
    - **MT-15** Close on the Global tab, `/reload`, and open: the window opens on Global.
- **Verify:** `~/.luarocks/bin/busted`, the coverage command (`Core/Tabs.lua` ≥ 90%), `luacheck .`, `stylua --check .`, and MT-12 to MT-15 on Forever and Retail.
- **Definition of done:**
  - [ ] Each Covers item is observably met, including one observation that failed before the task.
  - [ ] Tests listed above exist and follow the Tests guidelines.
  - [ ] Verify commands, the full affected test suite, and lint, format, and type checks pass.
  - [ ] E2E tests pass, or the accepted alternative from Risks is done.
  - [ ] All three reviews pass with no valid open findings.
  - [ ] Docs and config that describe the changed behavior are updated.
  - [ ] Task heading checkbox ticked; changes committed.

### [ ] 5. Zone tab
- **Outcome:** the Zone tab shows the note of the current zone or instance for this character. It follows the player across zones. It is disabled when no zone map exists.
- **Depends on:** 4 (supplies `Tabs.Visible` with `zoneAvailable`, `Window.Refresh`, and the Zone setting).
- **Covers:** AC6 (Zone tab), AC8, AC9, R4, R6, R7.
- **Files:**
  - New: `Core/Zone.lua`, `spec/zone_spec.lua`.
  - Change: `UI/Window.lua`, `Init.lua`, `Locales/enUS.lua`, `SimpleNotepad.toc`, `.luacheckrc`, `docs/manual-tests.md`.
- **Implementation:**
  - `Core/Zone.lua`: `Zone.Resolve(getBestMap, getMapInfo) -> zoneKey, zoneName` or `nil`.
    1. `local id = getBestMap("player")`. If `id` is `nil`, return `nil`.
    2. Loop at most 10 times: `local info = getMapInfo(id)`. If `info` is `nil`, return `nil`.
    3. If `info.mapType` is 3 (Zone) or 4 (Dungeon), return `id, info.name`.
    4. If `info.mapType` is less than 3 (Cosmic, World, or Continent), or `info.parentMapID` is `nil` or `0`, return `nil`.
    5. Otherwise, set `id = info.parentMapID` and go to step 2.
    - Use the numbers 3 and 4 as named local constants. Do not read `Enum` in the core.
    - The limit of 10 steps protects against a map loop in bad data.
  - `UI/Window.lua`:
    - `Window.UpdateZone()` calls `ns.Zone.Resolve(C_Map.GetBestMapForUnit, C_Map.GetMapInfo)` and stores `zoneKey` and `zoneName`.
    - Tab 3 label is `zoneName`, or `L.TAB_ZONE` ("Zone") when `zoneKey` is `nil`.
    - When `zoneKey` is `nil`, tab 3 is disabled and has the tooltip `L.NO_ZONE` ("No zone detected"). Use `OnEnter` with `GameTooltip`; a disabled button still needs mouse motion (inspect `motionScriptsWhileDisabled` on the template).
    - `UpdateZone` then calls `Window.Refresh()` with `zoneAvailable = zoneKey ~= nil`.
    - If the active tab is `"zone"` and the key changed, call `ShowTab("zone", zoneKey)`. `ShowTab` rebinds `activeZoneKey` before `SetText`, so no text goes to the wrong zone (R4). Autosave on each change already wrote the old note.
    - If the active tab is `"zone"` and the new key is `nil`, `Refresh` switches to Character (AC9).
  - `Init.lua`: register `PLAYER_ENTERING_WORLD`, `ZONE_CHANGED_NEW_AREA`, `ZONE_CHANGED`, and `ZONE_CHANGED_INDOORS`. Each calls `ns.Window.UpdateZone()`. `UpdateZone` must be cheap; it does nothing when the key and the name have not changed.
- **Edge cases:** a micro-dungeon inside a zone (parent zone key); an orphan map with a Zone parent; a continent-level map such as flight over a continent (`nil`); `getMapInfo` returns `nil`; a map loop; a dungeon with several floors (same Dungeon key); the zone changes while the Zone tab is active and the player types; the zone changes while the window is closed; the Zone tab is disabled by the setting while in a zone.
- **Tests:**
  - Unit (`spec/zone_spec.lua`), with fake `getBestMap` and `getMapInfo` built from a table of maps:
    - A Zone map returns its own ID and name.
    - A Micro map returns its parent Zone.
    - An Orphan map with a Zone parent returns the parent.
    - A Dungeon floor returns the Dungeon map, and two floors give the same key.
    - A Continent returns `nil`.
    - `getBestMap` returning `nil` gives `nil`.
    - `getMapInfo` returning `nil` gives `nil`.
    - A two-map loop returns `nil` after 10 steps.
    - `parentMapID = 0` gives `nil`.
  - Integration (`spec/zone_spec.lua`): with a real `Store`, a note written for key 84 is not returned for key 85. `Tabs.Visible(Store.IsTabEnabled, false)` marks Zone as non-clickable.
  - Manual:
    - **MT-16** Write a Zone note in Elwynn Forest. Travel to Westfall: the tab label changes and the note is empty. Return: the Elwynn note is back.
    - **MT-17** Type in the Zone tab while you cross a zone border: the text before the border stays in the old zone note.
    - **MT-18** Enter a dungeon and change floors: one note for the whole dungeon.
    - **MT-19** Log in on a second character in the same zone: the Zone note is empty (per character).
    - **MT-20** In a place without a map, if one can be found: the Zone tab is disabled and shows "No zone detected". If no such place is found, record "not reproduced".
- **Verify:** `~/.luarocks/bin/busted`, the coverage command (`Core/Zone.lua` ≥ 90%), `luacheck .`, `stylua --check .`, and MT-16 to MT-20 on Forever and Retail.
- **Definition of done:**
  - [ ] Each Covers item is observably met, including one observation that failed before the task.
  - [ ] Tests listed above exist and follow the Tests guidelines.
  - [ ] Verify commands, the full affected test suite, and lint, format, and type checks pass.
  - [ ] E2E tests pass, or the accepted alternative from Risks is done.
  - [ ] All three reviews pass with no valid open findings.
  - [ ] Docs and config that describe the changed behavior are updated.
  - [ ] Task heading checkbox ticked; changes committed.

### [ ] 6. Release packaging and README
- **Outcome:** a pushed `v*` tag makes a GitHub Release with `SimpleNotepad-<version>.zip`. The zip uploads to CurseForge when the project ID and token exist. The README explains use, limits, and development.
- **Depends on:** 1 (supplies the TOC and CI). Tasks 2–5 supply the features that the README describes. If the README is written before they are done, it describes only what exists.
- **Covers:** AC12, R5, R10.
- **Files:**
  - New: `.pkgmeta`, `.github/workflows/release.yml`, `README.md`.
  - Change: `SimpleNotepad.toc` (only when the CurseForge ID is known).
- **Implementation:**
  - `.pkgmeta`: `package-as: SimpleNotepad`. `ignore:` lists `spec`, `specs`, `docs`, `.github`, `.busted`, `.luacov`, `.luacheckrc`, `.stylua.toml`, and `README.md` (keep `README.md` if the user wants it in the zip).
  - `.github/workflows/release.yml`:
    - Trigger: `on: push: tags: ["v*"]`. Set `permissions: contents: write`.
    - Use `actions/checkout@v4` with `fetch-depth: 0`, because packager reads tags for the changelog.
    - Run `BigWigsMods/packager@v2` with `env: GH_API_TOKEN: ${{ secrets.GITHUB_TOKEN }}` and `CF_API_TOKEN: ${{ secrets.CF_API_TOKEN }}`.
    - No `## X-Curse-Project-ID` means no CurseForge upload (R10).
  - `README.md`:
    - Features and how to open the window.
    - Tab rules and the Settings path.
    - "Notes are written to disk on logout or /reload; a client crash loses unsaved changes" (R5).
    - Supported clients (Forever `16001`, Retail `120105`).
    - Development commands (busted, luacheck, StyLua, coverage).
    - The release steps: tag `vX.Y.Z` and push the tag. Add the `CF_API_TOKEN` secret and `X-Curse-Project-ID` for CurseForge.
- **Edge cases:** a tag without a previous tag (the first changelog); a missing `CF_API_TOKEN` (packager must still upload to GitHub); `@project-version@` in the TOC replaced in the zip.
- **Tests:**
  - No unit tests; this task has no Lua behavior.
  - Local packaging check: run `release.sh` from https://github.com/BigWigsMods/packager with `-d` (skip upload). Unverified flag; read `release.sh -h` first.
  - Unzip the result. Confirm the zip has no `spec/` or `.github/`. Confirm the TOC has a real version.
- **Verify:**
  - `curl -sLO https://raw.githubusercontent.com/BigWigsMods/packager/v2.7.0/release.sh && bash release.sh -d` (unverified; run it in the scratchpad, not the repository).
  - `unzip -l .release/SimpleNotepad-*.zip`.
  - After a remote exists: push a test tag `v0.0.1-test` and check `gh release view v0.0.1-test`. Delete the test release after the check, only with the user's approval.
- **Definition of done:**
  - [ ] Each Covers item is observably met, including one observation that failed before the task.
  - [ ] Tests listed above exist and follow the Tests guidelines.
  - [ ] Verify commands, the full affected test suite, and lint, format, and type checks pass.
  - [ ] E2E tests pass, or the accepted alternative from Risks is done.
  - [ ] All three reviews pass with no valid open findings.
  - [ ] Docs and config that describe the changed behavior are updated.
  - [ ] Task heading checkbox ticked; changes committed.

## Validation
After the last task:
1. `~/.luarocks/bin/busted`: all tests pass.
2. Coverage command: each `Core/*.lua` file is at or above 90%.
3. `luacheck .` and `stylua --check .` pass.
4. CI is green on the final commit (when a remote exists).
5. Run all of MT-1 to MT-20 in `docs/manual-tests.md` on Forever and on Retail, with `/console scriptErrors 1`. Record the result per client. MT-8 can fail on a client (R3); record the failure.
6. Test with a fresh profile: delete `SimpleNotepad.lua` in both SavedVariables folders, then log in. Defaults load with no error.
7. Repair test: edit `SimpleNotepadDB.global = 5` in the account SavedVariables file while logged out. Log in: no error, and the Global note is empty.
8. The local packager run gives a zip with only addon files.

## References
- Gethe wow-ui-source, `forever` branch (build 1.60.1.70938): https://github.com/Gethe/wow-ui-source/tree/forever
- Gethe wow-ui-source, `live` branch (12.1.5): https://github.com/Gethe/wow-ui-source/tree/live
- TOC format, Interface numbers, and comma-separated Interface lists: https://warcraft.wiki.gg/wiki/TOC_format
- Patch 12.0.0 API changes (the ChatFrameUtil move, deprecations): https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes
- Secret values: https://warcraft.wiki.gg/wiki/Secret_Values
- hooksecurefunc: https://warcraft.wiki.gg/wiki/API_hooksecurefunc
- EditBox GetText escaping: https://warcraft.wiki.gg/wiki/API_EditBox_GetText
- UI escape sequences: https://warcraft.wiki.gg/wiki/UI_escape_sequences
- SetHyperlinksEnabled: https://warcraft.wiki.gg/wiki/API_Frame_SetHyperlinksEnabled
- OnHyperlinkClick: https://warcraft.wiki.gg/wiki/UIHANDLER_OnHyperlinkClick
- C_Map.GetBestMapForUnit: https://warcraft.wiki.gg/wiki/API_C_Map.GetBestMapForUnit
- ZONE_CHANGED_NEW_AREA: https://warcraft.wiki.gg/wiki/ZONE_CHANGED_NEW_AREA
- Saving variables: https://warcraft.wiki.gg/wiki/Saving_variables_between_game_sessions
- Addon compartment: https://warcraft.wiki.gg/wiki/Addon_compartment
- Slash commands: https://warcraft.wiki.gg/wiki/Creating_a_slash_command
- Frame SetUserPlaced (layout cache): https://warcraft.wiki.gg/wiki/API_Frame_SetUserPlaced
- Forum thread on HandleModifiedItemClick, spells, and talents: https://us.forums.blizzard.com/en/wow/t/fizzlemizz-handlemodifieditemclick/2228116
- WoW Forever addon guides (unofficial; Interface 16001, `_Forever` suffix): https://wowforeverguides.com/addons/developers, https://forevermeta.me/en/guides/wow-forever-addons-interface
- BigWigsMods/packager (v2.7.0): https://github.com/BigWigsMods/packager
- BigWigs `.luacheckrc` (reference config): https://github.com/BigWigsMods/BigWigs/blob/master/.luacheckrc
- busted: https://github.com/lunarmodules/busted
- wowless (headless, pre-alpha; rejected for e2e): https://github.com/wowless/wowless

## Open Decisions
- **CurseForge project ID and token.** The project does not exist on CurseForge yet. Impact: the release uploads to GitHub only until the user creates the project, adds `## X-Curse-Project-ID: <id>` to the TOC, and adds the `CF_API_TOKEN` repository secret.
- **Git remote.** The repository has no remote. Impact: the CI and release workflows cannot run until the user adds a GitHub remote. The CI items in the Verify and Validation steps stay unverified until then.

## Completion
When every task is checked and Validation passes, move this file to `specs/done/` with `git mv` (plain `mv` when the file is untracked). Create `specs/done/` if it does not exist. Commit the move.
