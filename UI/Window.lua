local _, ns = ...
local L = ns.L

local Window = {}
ns.Window = Window

local TAB_INDEX = { global = 1, character = 2, zone = 3 }
local NUM_TABS = 3
local TAB_FIRST_X = 11
local TAB_FIRST_Y = 2
local TAB_SPACING = 3
-- 400 frame width minus the first-tab offset (11), two tab gaps (6), and the active tab art overhang (8).
local TAB_MAX_WIDTH = 375

local storeReady = false
local activeTab
local activeZoneKey
local zoneKey = nil
local zoneName = nil

local frame = CreateFrame("Frame", "SimpleNotebookFrame", UIParent, "ButtonFrameTemplate")
ButtonFrameTemplate_HidePortrait(frame)
if frame.SetTitle then
	frame:SetTitle(L.ADDON_TITLE)
elseif frame.TitleContainer and frame.TitleContainer.TitleText then
	frame.TitleContainer.TitleText:SetText(L.ADDON_TITLE)
end
frame:SetSize(400, 450)
frame:SetPoint("CENTER")
frame:Hide()
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:SetToplevel(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
-- ESC or the key binding can hide the frame during a drag, and then OnDragStop never fires.
frame:HookScript("OnHide", frame.StopMovingOrSizing)
tinsert(UISpecialFrames, "SimpleNotebookFrame")

local editor = CreateFrame("Frame", nil, frame.Inset, "ScrollingEditBoxTemplate")
editor:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 8, -6)
editor:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -24, 6)

local scrollBar = CreateFrame("EventFrame", nil, frame.Inset, "MinimalScrollBar")
scrollBar:SetPoint("TOPLEFT", editor, "TOPRIGHT", 4, -2)
scrollBar:SetPoint("BOTTOMLEFT", editor, "BOTTOMRIGHT", 4, 2)
ScrollUtil.RegisterScrollBoxWithScrollBar(editor:GetScrollBox(), scrollBar)

local editBox = editor:GetEditBox()
editBox:SetHyperlinksEnabled(true)
-- A shift-click on a link in the note reaches InsertLink through SetItemRef. Skip it so no duplicate link appears.
editBox:HookScript("OnHyperlinkClick", function(_, link, text, button)
	if IsModifiedClick("CHATLINK") then
		return
	end
	SetItemRef(link, text, button)
end)

local function OnInsertLink(text)
	if ns.Links.ShouldInsert(text, editor:HasFocus(), issecretvalue) then
		editor:Insert(text)
	end
end

if ChatFrameUtil and ChatFrameUtil.InsertLink then
	hooksecurefunc(ChatFrameUtil, "InsertLink", OnInsertLink)
end
-- A hook on the ChatFrameUtil field leaves the ChatEdit_InsertLink global unhooked, even when both name one function.
-- The global is a plain alias, not a wrapper, so one call fires one hook and a link is inserted once.
if type(ChatEdit_InsertLink) == "function" then
	hooksecurefunc("ChatEdit_InsertLink", OnInsertLink)
end

frame.Inset:EnableMouse(true)
frame.Inset:SetScript("OnMouseDown", function()
	editor:SetFocus()
end)

-- PanelTabButtonTemplate has parentArray="Tabs", so CreateFrame appends each tab to frame.Tabs. The assignment pins each tab to its ID.
frame.Tabs = frame.Tabs or {}
local tabs = frame.Tabs
for index = 1, NUM_TABS do
	local tab = CreateFrame("Button", nil, frame, "PanelTabButtonTemplate")
	tab:SetID(index)
	tabs[index] = tab
end
PanelTemplates_SetNumTabs(frame, NUM_TABS)

function Window.LayoutTabs()
	local previous
	for index = 1, NUM_TABS do
		local tab = tabs[index]
		if tab:IsShown() then
			tab:ClearAllPoints()
			if previous then
				tab:SetPoint("TOPLEFT", previous, "TOPRIGHT", TAB_SPACING, 0)
			else
				tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", TAB_FIRST_X, TAB_FIRST_Y)
			end
			previous = tab
		end
	end
end

function Window.UpdateLabels()
	tabs[TAB_INDEX.global]:SetText(L.TAB_GLOBAL)
	tabs[TAB_INDEX.character]:SetText(UnitName("player"))
	tabs[TAB_INDEX.zone]:SetText(zoneName or L.TAB_ZONE)
	-- SetText does not resize a tab, and ResizeTabsToFit may have fixed its width for the old label.
	for index = 1, NUM_TABS do
		PanelTemplates_TabResize(tabs[index])
	end
end

function Window.ShowTab(tabId, noteZoneKey)
	if tabId ~= "zone" then
		noteZoneKey = nil
	end
	-- The editor already holds the bound note, and a reload would reset the cursor and scroll position.
	if tabId ~= activeTab or noteZoneKey ~= activeZoneKey then
		activeTab = tabId
		activeZoneKey = noteZoneKey
		editor:SetText(ns.Store.GetNote(tabId, noteZoneKey))
	end
	PanelTemplates_SetTab(frame, TAB_INDEX[tabId])
	-- ResizeTabsToFit sizes around the selected tab and does nothing without one, so it must follow every selection.
	PanelTemplates_ResizeTabsToFit(frame, TAB_MAX_WIDTH)
	ns.Store.SetLastTab(tabId)
end

for tabId, index in pairs(TAB_INDEX) do
	tabs[index]:SetScript("OnClick", function()
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
		Window.ShowTab(tabId, zoneKey)
	end)
end

local function ApplyVisibility()
	local visible = ns.Tabs.Visible(ns.Store.IsTabEnabled, zoneKey ~= nil)
	local clickable = {}
	for _, entry in ipairs(visible) do
		clickable[entry.id] = entry.clickable
	end
	for tabId, index in pairs(TAB_INDEX) do
		PanelTemplates_SetTabShown(frame, index, clickable[tabId] ~= nil)
		PanelTemplates_SetTabEnabled(frame, index, clickable[tabId] == true)
	end
	Window.LayoutTabs()
	PanelTemplates_ResizeTabsToFit(frame, TAB_MAX_WIDTH)
	return visible
end

function Window.Refresh()
	if not storeReady then
		return
	end
	local visible = ApplyVisibility()
	if frame:IsShown() and ns.Tabs.Resolve(activeTab, visible) ~= activeTab then
		Window.ShowTab("character", nil)
	end
end

editor:RegisterCallback("OnTextChanged", function()
	if storeReady and activeTab then
		ns.Store.SetNote(activeTab, editor:GetInputText(), activeZoneKey)
	end
end, Window)

function Window.OnShow()
	if not storeReady then
		return
	end
	Window.UpdateLabels()
	local visible = ApplyVisibility()
	Window.ShowTab(ns.Tabs.Resolve(ns.Store.GetLastTab(), visible), zoneKey)
end

frame:HookScript("OnShow", Window.OnShow)

-- PanelTabButtonTemplate sets motionScriptsWhileDisabled, so the disabled tab still gets OnEnter.
-- Its own OnEnter shows a truncated label in full, and its OnLeave hides the tooltip.
tabs[TAB_INDEX.zone]:HookScript("OnEnter", function(self)
	if zoneKey == nil then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L.NO_ZONE)
		GameTooltip:Show()
	end
end)

function Window.UpdateZone()
	local newKey, newName = ns.Zone.Resolve(C_Map.GetBestMapForUnit, C_Map.GetMapInfo)
	if newKey == zoneKey and newName == zoneName then
		return
	end
	local keyChanged = newKey ~= zoneKey
	zoneKey = newKey
	zoneName = newName
	if not storeReady then
		return
	end
	Window.UpdateLabels()
	Window.Refresh()
	if keyChanged and newKey ~= nil and frame:IsShown() and activeTab == "zone" then
		Window.ShowTab("zone", newKey)
	end
end

function Window.OnStoreReady()
	storeReady = true
	Window.UpdateLabels()
	Window.Refresh()
end

function SimpleNotebook_Toggle()
	frame:SetShown(not frame:IsShown())
end

function SimpleNotebook_OnAddonCompartmentClick()
	SimpleNotebook_Toggle()
end

SLASH_SIMPLENOTEBOOK1 = "/notebook"
SLASH_SIMPLENOTEBOOK2 = "/nb"
SlashCmdList.SIMPLENOTEBOOK = SimpleNotebook_Toggle

BINDING_HEADER_SIMPLENOTEBOOK = L.ADDON_TITLE
BINDING_NAME_SIMPLENOTEBOOK_TOGGLE = L.BINDING_TOGGLE
