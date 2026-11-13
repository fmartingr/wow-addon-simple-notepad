local addonName, ns = ...

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedName)
	if event == "ADDON_LOADED" and loadedName == addonName then
		SimpleNotepadDB, SimpleNotepadCharDB = ns.Store.Init(SimpleNotepadDB, SimpleNotepadCharDB)
		ns.Window.OnStoreReady()
		ns.SettingsPanel.OnStoreReady()
		self:UnregisterEvent("ADDON_LOADED")
	end
end)
