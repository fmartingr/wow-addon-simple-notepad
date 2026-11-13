local _, ns = ...
local L = ns.L

local SettingsPanel = {}
ns.SettingsPanel = SettingsPanel

local OPTIONAL_TABS = { "global", "zone" }

function SettingsPanel.OnStoreReady()
	local category = Settings.RegisterVerticalLayoutCategory(L.ADDON_TITLE)
	for _, id in ipairs(OPTIONAL_TABS) do
		local key = id:upper()
		local setting = Settings.RegisterAddOnSetting(
			category,
			"SimpleNotepad_ShowTab_" .. id,
			id,
			SimpleNotepadDB.tabs,
			Settings.VarType.Boolean,
			L["SETTING_SHOW_" .. key],
			true
		)
		setting:SetValueChangedCallback(function()
			ns.Window.Refresh()
		end)
		Settings.CreateCheckbox(category, setting, L["SETTING_SHOW_" .. key .. "_TOOLTIP"])
	end
	Settings.RegisterAddOnCategory(category)
end
