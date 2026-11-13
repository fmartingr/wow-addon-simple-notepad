local _, ns = ...

local Store = {}
ns.Store = Store

local SCHEMA_VERSION = 1
local TAB_IDS = { global = true, character = true, zone = true }
local OPTIONAL_TABS = { global = true, zone = true }

local accountData
local charData

local function repair(value, typeName, default)
	if type(value) == typeName then
		return value
	end
	return default
end

-- NaN and infinity fail `% 1 == 0`; SavedVariables cannot serialize them, so one would corrupt the whole saved file.
local function isPositiveInteger(value)
	return type(value) == "number" and value > 0 and value % 1 == 0
end

local function repairVersion(value)
	return isPositiveInteger(value) and value or SCHEMA_VERSION
end

function Store.Init(accountDB, charDB)
	accountDB = repair(accountDB, "table", {})
	accountDB.schemaVersion = repairVersion(accountDB.schemaVersion)
	accountDB.global = repair(accountDB.global, "string", "")
	accountDB.tabs = repair(accountDB.tabs, "table", {})
	for tabId in pairs(OPTIONAL_TABS) do
		accountDB.tabs[tabId] = repair(accountDB.tabs[tabId], "boolean", true)
	end

	charDB = repair(charDB, "table", {})
	charDB.schemaVersion = repairVersion(charDB.schemaVersion)
	charDB.character = repair(charDB.character, "string", "")
	charDB.zones = repair(charDB.zones, "table", {})
	for key, value in pairs(charDB.zones) do
		if not isPositiveInteger(key) or type(value) ~= "string" or value == "" then
			charDB.zones[key] = nil
		end
	end
	if not TAB_IDS[charDB.lastTab] then
		charDB.lastTab = "character"
	end

	accountData = accountDB
	charData = charDB
	return accountDB, charDB
end

function Store.GetNote(tabId, zoneKey)
	if tabId == "global" then
		return accountData.global
	elseif tabId == "character" then
		return charData.character
	elseif tabId == "zone" then
		if not isPositiveInteger(zoneKey) then
			return ""
		end
		return charData.zones[zoneKey] or ""
	end
	return ""
end

function Store.SetNote(tabId, text, zoneKey)
	if not TAB_IDS[tabId] then
		error("unknown tab: " .. tostring(tabId), 2)
	end
	if type(text) ~= "string" then
		error("note text must be a string, got " .. type(text), 2)
	end
	if tabId == "global" then
		accountData.global = text
	elseif tabId == "character" then
		charData.character = text
	elseif isPositiveInteger(zoneKey) then
		if text == "" then
			charData.zones[zoneKey] = nil
		else
			charData.zones[zoneKey] = text
		end
	end
end

function Store.IsTabEnabled(tabId)
	if tabId == "character" then
		return true
	end
	return OPTIONAL_TABS[tabId] == true and accountData.tabs[tabId] == true
end

function Store.SetTabEnabled(tabId, enabled)
	if OPTIONAL_TABS[tabId] then
		accountData.tabs[tabId] = enabled and true or false
	end
end

function Store.GetLastTab()
	return charData.lastTab
end

function Store.SetLastTab(tabId)
	if TAB_IDS[tabId] then
		charData.lastTab = tabId
	end
end
