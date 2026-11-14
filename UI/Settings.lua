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
			"SimpleNotebook_ShowTab_" .. id,
			id,
			SimpleNotebookDB.tabs,
			Settings.VarType.Boolean,
			L["SETTING_SHOW_" .. key],
			true
		)
		setting:SetValueChangedCallback(function()
			ns.Window.Refresh()
		end)
		Settings.CreateCheckbox(category, setting, L["SETTING_SHOW_" .. key .. "_TOOLTIP"])
	end
	local minimapSetting = Settings.RegisterAddOnSetting(
		category,
		"SimpleNotebook_ShowMinimap",
		"show",
		SimpleNotebookDB.minimap,
		Settings.VarType.Boolean,
		L.SETTING_SHOW_MINIMAP,
		true
	)
	minimapSetting:SetValueChangedCallback(function()
		ns.MinimapButton.Refresh()
	end)
	Settings.CreateCheckbox(category, minimapSetting, L.SETTING_SHOW_MINIMAP_TOOLTIP)
	local openSetting = Settings.RegisterAddOnSetting(
		category,
		"SimpleNotebook_OpenOnLogin",
		"openOnLogin",
		SimpleNotebookDB,
		Settings.VarType.Boolean,
		L.SETTING_OPEN_ON_LOGIN,
		false
	)
	Settings.CreateCheckbox(category, openSetting, L.SETTING_OPEN_ON_LOGIN_TOOLTIP)
	Settings.RegisterAddOnCategory(category)
end
