std = "lua51"
max_line_length = false
codes = true
exclude_files = { ".lua/**", ".luarocks/**", ".release/**" }

globals = {
	"SimpleNotebookDB",
	"SimpleNotebookCharDB",
	"SimpleNotebookFrame",
	"SimpleNotebook_Toggle",
	"SimpleNotebook_OnAddonCompartmentClick",
	"SLASH_SIMPLENOTEBOOK1",
	"SLASH_SIMPLENOTEBOOK2",
	"BINDING_HEADER_SIMPLENOTEBOOK",
	"BINDING_NAME_SIMPLENOTEBOOK_TOGGLE",
}

read_globals = {
	"ButtonFrameTemplate_HidePortrait",
	"C_Map",
	"ChatEdit_InsertLink",
	"ChatFrameUtil",
	"CreateFrame",
	"GameTooltip",
	"PanelTemplates_ResizeTabsToFit",
	"PanelTemplates_SetTabEnabled",
	"PanelTemplates_SetTabShown",
	"PlaySound",
	"Settings",
	"SOUNDKIT",
	"IsModifiedClick",
	"PanelTemplates_SetNumTabs",
	"PanelTemplates_TabResize",
	"PanelTemplates_SetTab",
	"ScrollUtil",
	"SetItemRef",
	SlashCmdList = { fields = { SIMPLENOTEBOOK = { read_only = false } } },
	"UIParent",
	"UISpecialFrames",
	"UnitName",
	"hooksecurefunc",
	"issecretvalue",
	"tinsert",
}

files["spec/**"] = { std = "+busted" }
