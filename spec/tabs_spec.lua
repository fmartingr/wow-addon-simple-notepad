local loadModule = require("helpers.load")

local function ids(visible)
	local result = {}
	for index, entry in ipairs(visible) do
		result[index] = entry.id
	end
	return result
end

local function find(visible, id)
	for _, entry in ipairs(visible) do
		if entry.id == id then
			return entry
		end
	end
end

describe("Tabs", function()
	local Tabs, Store

	before_each(function()
		local ns = loadModule("Core/Tabs.lua")
		loadModule("Core/Store.lua", ns)
		Tabs = ns.Tabs
		Store = ns.Store
		Store.Init(nil, nil)
	end)

	local function enabledFrom(global, zone)
		return function(id)
			if id == "global" then
				return global
			end
			return zone
		end
	end

	describe("Visible", function()
		it("lists all tabs in order when both are enabled", function()
			assert.same({ "global", "character", "zone" }, ids(Tabs.Visible(enabledFrom(true, true), true)))
		end)

		it("leaves out Global when it is disabled", function()
			assert.same({ "character", "zone" }, ids(Tabs.Visible(enabledFrom(false, true), true)))
		end)

		it("leaves out Zone when it is disabled", function()
			assert.same({ "global", "character" }, ids(Tabs.Visible(enabledFrom(true, false), true)))
		end)

		it("lists only Character when both are disabled", function()
			assert.same({ "character" }, ids(Tabs.Visible(enabledFrom(false, false), true)))
		end)

		it("never asks isEnabled about Character", function()
			local asked = {}
			Tabs.Visible(function(id)
				asked[#asked + 1] = id
				return false
			end, true)
			assert.same({ "global", "zone" }, asked)
		end)

		it("keeps Character clickable", function()
			assert.is_true(find(Tabs.Visible(enabledFrom(false, false), false), "character").clickable)
		end)

		it("keeps Global clickable when the zone is unavailable", function()
			assert.is_true(find(Tabs.Visible(enabledFrom(true, true), false), "global").clickable)
		end)

		it("marks Zone as not clickable when the zone is unavailable", function()
			assert.is_false(find(Tabs.Visible(enabledFrom(true, true), false), "zone").clickable)
			assert.is_false(find(Tabs.Visible(enabledFrom(true, true), nil), "zone").clickable)
		end)

		it("marks Zone as clickable when the zone is available", function()
			assert.is_true(find(Tabs.Visible(enabledFrom(true, true), true), "zone").clickable)
		end)
	end)

	describe("Resolve", function()
		local visible

		before_each(function()
			visible = Tabs.Visible(enabledFrom(true, true), true)
		end)

		it("returns a requested tab that is visible and clickable", function()
			assert.equal("global", Tabs.Resolve("global", visible))
			assert.equal("character", Tabs.Resolve("character", visible))
			assert.equal("zone", Tabs.Resolve("zone", visible))
		end)

		it("falls back for a hidden tab", function()
			local hidden = Tabs.Visible(enabledFrom(false, true), true)
			assert.equal("character", Tabs.Resolve("global", hidden))
		end)

		it("falls back for a tab that is not clickable", function()
			local blocked = Tabs.Visible(enabledFrom(true, true), false)
			assert.equal("character", Tabs.Resolve("zone", blocked))
		end)

		it("falls back for nil", function()
			assert.equal("character", Tabs.Resolve(nil, visible))
		end)

		it("falls back for an unknown tab", function()
			assert.equal("character", Tabs.Resolve("bogus", visible))
		end)
	end)

	describe("with the Store", function()
		it("removes Global from the list when the Store disables it, and keeps the note", function()
			Store.SetNote("global", "kept")
			Store.SetTabEnabled("global", false)
			assert.same({ "character", "zone" }, ids(Tabs.Visible(Store.IsTabEnabled, true)))
			assert.equal("kept", Store.GetNote("global"))
		end)

		it("shows Global again with the old note after the Store enables it", function()
			Store.SetNote("global", "kept")
			Store.SetTabEnabled("global", false)
			Store.SetTabEnabled("global", true)
			assert.same({ "global", "character", "zone" }, ids(Tabs.Visible(Store.IsTabEnabled, true)))
			assert.equal("kept", Store.GetNote("global"))
		end)
	end)
end)
