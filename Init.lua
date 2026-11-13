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
frame:SetScript("OnEvent", function(self, event, loadedName)
	if event == "ADDON_LOADED" then
		if loadedName == addonName then
			SimpleNotebookDB, SimpleNotebookCharDB = ns.Store.Init(SimpleNotebookDB, SimpleNotebookCharDB)
			ns.Window.OnStoreReady()
			ns.MinimapButton.OnStoreReady()
			ns.SettingsPanel.OnStoreReady()
			self:UnregisterEvent("ADDON_LOADED")
		end
	elseif ZONE_EVENTS[event] then
		ns.Window.UpdateZone()
	end
end)
