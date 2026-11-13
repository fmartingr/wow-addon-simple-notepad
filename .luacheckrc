std = "lua51"
max_line_length = false
codes = true
exclude_files = { ".lua/**", ".luarocks/**", ".release/**" }

globals = {
	"SimpleNotepadDB",
	"SimpleNotepadCharDB",
	"SimpleNotepadFrame",
	"SimpleNotepad_Toggle",
	"SimpleNotepad_OnAddonCompartmentClick",
	"SLASH_SIMPLENOTEPAD1",
	"SLASH_SIMPLENOTEPAD2",
	"BINDING_HEADER_SIMPLENOTEPAD",
	"BINDING_NAME_SIMPLENOTEPAD_TOGGLE",
}

read_globals = {
	"ButtonFrameTemplate_HidePortrait",
	"CreateFrame",
	"PanelTemplates_SetNumTabs",
	"PanelTemplates_SetTab",
	"ScrollUtil",
	SlashCmdList = { fields = { SIMPLENOTEPAD = { read_only = false } } },
	"UIParent",
	"UISpecialFrames",
	"UnitName",
	"tinsert",
}

files["spec/**"] = { std = "+busted" }
