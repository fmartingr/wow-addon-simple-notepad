local _, ns = ...
local L = ns.L

local MinimapButton = {}
ns.MinimapButton = MinimapButton

local BUTTON_SIZE = 31
local RADIUS_OFFSET = 5
local ICON_PATH = "Interface\\AddOns\\SimpleNotebook\\Media\\icon"
local TEXTURE_BORDER = 136430
local TEXTURE_BACKGROUND = 136467
local TEXTURE_HIGHLIGHT = 136477

local button = CreateFrame("Button", nil, Minimap)
button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(8)
button:SetHighlightTexture(TEXTURE_HIGHLIGHT)
button:RegisterForClicks("LeftButtonUp")
button:RegisterForDrag("LeftButton")

local background = button:CreateTexture(nil, "BACKGROUND")
background:SetSize(24, 24)
background:SetTexture(TEXTURE_BACKGROUND)
background:SetPoint("CENTER")

local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetSize(18, 18)
icon:SetTexture(ICON_PATH)
icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
icon:SetPoint("CENTER")

local border = button:CreateTexture(nil, "OVERLAY")
border:SetSize(50, 50)
border:SetTexture(TEXTURE_BORDER)
border:SetPoint("TOPLEFT")

local function Place()
	local radius = Minimap:GetWidth() / 2 + RADIUS_OFFSET
	local x, y = ns.MinimapMath.Position(ns.Store.GetMinimapAngle(), radius)
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function OnDragUpdate()
	local centerX, centerY = Minimap:GetCenter()
	local cursorX, cursorY = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	local angle = ns.MinimapMath.AngleFromOffset(cursorX / scale - centerX, cursorY / scale - centerY)
	if angle then
		ns.Store.SetMinimapAngle(angle)
		Place()
	end
end

button:SetScript("OnDragStart", function(self)
	self:LockHighlight()
	GameTooltip:Hide()
	self:SetScript("OnUpdate", OnDragUpdate)
end)

button:SetScript("OnDragStop", function(self)
	self:SetScript("OnUpdate", nil)
	self:UnlockHighlight()
end)

button:SetScript("OnClick", function()
	SimpleNotebook_Toggle()
end)

button:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:SetText(L.ADDON_TITLE)
	GameTooltip:AddLine(L.MINIMAP_TOOLTIP_HINT, 1, 1, 1)
	GameTooltip:Show()
end)

button:SetScript("OnLeave", function()
	GameTooltip:Hide()
end)

button:Hide()

function MinimapButton.Refresh()
	Place()
	button:SetShown(ns.Store.IsMinimapShown())
end

function MinimapButton.OnStoreReady()
	Minimap:HookScript("OnSizeChanged", Place)
	MinimapButton.Refresh()
end
