local _, ns = ...
local L = ns.L

local Window = {}
ns.Window = Window

local TAB_INDEX = { global = 1, character = 2, zone = 3 }
local NUM_TABS = 3
local TAB_FIRST_X = 11
local TAB_FIRST_Y = 2
local TAB_SPACING = 3

local storeReady = false
local activeTab
local activeZoneKey

local frame = CreateFrame("Frame", "SimpleNotepadFrame", UIParent, "ButtonFrameTemplate")
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
tinsert(UISpecialFrames, "SimpleNotepadFrame")

local editor = CreateFrame("Frame", nil, frame.Inset, "ScrollingEditBoxTemplate")
editor:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 8, -6)
editor:SetPoint("BOTTOMRIGHT", frame.Inset, "BOTTOMRIGHT", -24, 6)

local scrollBar = CreateFrame("EventFrame", nil, frame.Inset, "MinimalScrollBar")
scrollBar:SetPoint("TOPLEFT", editor, "TOPRIGHT", 4, -2)
scrollBar:SetPoint("BOTTOMLEFT", editor, "BOTTOMRIGHT", 4, 2)
ScrollUtil.RegisterScrollBoxWithScrollBar(editor:GetScrollBox(), scrollBar)

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
tabs[TAB_INDEX.global]:Hide()
tabs[TAB_INDEX.zone]:Hide()

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
	tabs[TAB_INDEX.character]:SetText(UnitName("player"))
end

function Window.ShowTab(tabId, zoneKey)
	-- The editor already holds the bound note, and a reload would reset the cursor and scroll position.
	if tabId ~= activeTab or zoneKey ~= activeZoneKey then
		activeTab = tabId
		activeZoneKey = zoneKey
		editor:SetText(ns.Store.GetNote(tabId, zoneKey))
	end
	PanelTemplates_SetTab(frame, TAB_INDEX[tabId])
	ns.Store.SetLastTab(tabId)
end

for tabId, index in pairs(TAB_INDEX) do
	tabs[index]:SetScript("OnClick", function()
		Window.ShowTab(tabId, activeZoneKey)
	end)
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
	Window.LayoutTabs()
	Window.ShowTab("character", nil)
end

frame:HookScript("OnShow", Window.OnShow)

function Window.OnStoreReady()
	storeReady = true
	Window.UpdateLabels()
	Window.LayoutTabs()
end

function SimpleNotepad_Toggle()
	frame:SetShown(not frame:IsShown())
end

function SimpleNotepad_OnAddonCompartmentClick()
	SimpleNotepad_Toggle()
end

SLASH_SIMPLENOTEPAD1 = "/notepad"
SLASH_SIMPLENOTEPAD2 = "/np"
SlashCmdList.SIMPLENOTEPAD = SimpleNotepad_Toggle

BINDING_HEADER_SIMPLENOTEPAD = L.ADDON_TITLE
BINDING_NAME_SIMPLENOTEPAD_TOGGLE = L.BINDING_TOGGLE
