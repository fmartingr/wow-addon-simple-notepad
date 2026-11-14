local addonName, ns = ...

local ZONE_EVENTS = {
	PLAYER_ENTERING_WORLD = true,
	ZONE_CHANGED_NEW_AREA = true,
	ZONE_CHANGED = true,
	ZONE_CHANGED_INDOORS = true,
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
for event in pairs(ZONE_EVENTS) do
	frame:RegisterEvent(event)
end
-- arg1 is the addon name for ADDON_LOADED and isInitialLogin for PLAYER_ENTERING_WORLD.
frame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == addonName then
			SimpleNotebookDB, SimpleNotebookCharDB = ns.Store.Init(SimpleNotebookDB, SimpleNotebookCharDB)
			ns.Window.OnStoreReady()
			ns.MinimapButton.OnStoreReady()
			ns.SettingsPanel.OnStoreReady()
			self:UnregisterEvent("ADDON_LOADED")
		end
	elseif ZONE_EVENTS[event] then
		ns.Window.UpdateZone()
		if event == "PLAYER_ENTERING_WORLD" and arg1 and ns.Store.IsOpenOnLogin() then
			ns.Window.OpenCharacter()
		end
	end
end)
