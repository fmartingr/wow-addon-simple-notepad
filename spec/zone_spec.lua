local loadModule = require("helpers.load")

describe("Zone.Resolve", function()
	local Zone, Tabs, Store
	local maps
	local bestMap

	local function getBestMap(unit)
		assert.equal("player", unit)
		return bestMap
	end

	local function getMapInfo(id)
		return maps[id]
	end

	before_each(function()
		local ns = loadModule("Core/Zone.lua")
		loadModule("Core/Store.lua", ns)
		loadModule("Core/Tabs.lua", ns)
		Zone, Tabs, Store = ns.Zone, ns.Tabs, ns.Store
		Store.Init(nil, nil)
		maps = {
			[946] = { mapType = 0, name = "Cosmic", parentMapID = 0 },
			[12] = { mapType = 2, name = "Kalimdor", parentMapID = 946 },
			[84] = { mapType = 3, name = "Stormwind City", parentMapID = 13 },
			[85] = { mapType = 3, name = "Orgrimmar", parentMapID = 12 },
			[13] = { mapType = 2, name = "Eastern Kingdoms", parentMapID = 946 },
			[500] = { mapType = 5, name = "Micro", parentMapID = 84 },
			[600] = { mapType = 6, name = "Orphan", parentMapID = 84 },
			[700] = { mapType = 4, name = "Deadmines", parentMapID = 13 },
			[701] = { mapType = 5, name = "Deadmines Floor 2", parentMapID = 700 },
			[702] = { mapType = 5, name = "Deadmines Floor 3", parentMapID = 700 },
			[800] = { mapType = 5, name = "Loop A", parentMapID = 801 },
			[801] = { mapType = 5, name = "Loop B", parentMapID = 800 },
			[900] = { mapType = 5, name = "No parent", parentMapID = 0 },
			[901] = { mapType = 5, name = "Nil parent" },
			[902] = { mapType = 5, name = "Missing parent", parentMapID = 9999 },
		}
	end)

	it("returns the ID and name of a Zone map", function()
		bestMap = 84
		local key, name = Zone.Resolve(getBestMap, getMapInfo)
		assert.equal(84, key)
		assert.equal("Stormwind City", name)
	end)

	it("returns the parent Zone for a Micro map", function()
		bestMap = 500
		local key, name = Zone.Resolve(getBestMap, getMapInfo)
		assert.equal(84, key)
		assert.equal("Stormwind City", name)
	end)

	it("returns the parent Zone for an Orphan map", function()
		bestMap = 600
		assert.equal(84, (Zone.Resolve(getBestMap, getMapInfo)))
	end)

	it("returns the Dungeon map for a Dungeon floor, with one key for all floors", function()
		bestMap = 701
		local first, name = Zone.Resolve(getBestMap, getMapInfo)
		bestMap = 702
		local second = Zone.Resolve(getBestMap, getMapInfo)
		assert.equal(700, first)
		assert.equal("Deadmines", name)
		assert.equal(first, second)
	end)

	it("returns the Dungeon map when it is the best map", function()
		bestMap = 700
		assert.equal(700, (Zone.Resolve(getBestMap, getMapInfo)))
	end)

	it("returns nil for a Continent", function()
		bestMap = 12
		assert.is_nil(Zone.Resolve(getBestMap, getMapInfo))
	end)

	it("returns nil for a Cosmic map", function()
		bestMap = 946
		assert.is_nil(Zone.Resolve(getBestMap, getMapInfo))
	end)

	it("returns nil when getBestMap returns nil", function()
		bestMap = nil
		assert.is_nil(Zone.Resolve(getBestMap, getMapInfo))
	end)

	it("returns nil when getMapInfo returns nil for the best map", function()
		bestMap = 12345
		assert.is_nil(Zone.Resolve(getBestMap, getMapInfo))
	end)

	it("returns nil when a parent map has no info", function()
		bestMap = 902
		assert.is_nil(Zone.Resolve(getBestMap, getMapInfo))
	end)

	it("returns nil after 10 steps in a map loop", function()
		bestMap = 800
		local calls = 0
		local result = Zone.Resolve(getBestMap, function(id)
			calls = calls + 1
			return maps[id]
		end)
		assert.is_nil(result)
		assert.equal(10, calls)
	end)

	it("returns nil for parentMapID 0", function()
		bestMap = 900
		assert.is_nil(Zone.Resolve(getBestMap, getMapInfo))
	end)

	it("returns nil for a missing parentMapID", function()
		bestMap = 901
		assert.is_nil(Zone.Resolve(getBestMap, getMapInfo))
	end)

	describe("with the Store and Tabs", function()
		it("does not return a note written for one zone key under another", function()
			Store.SetNote("zone", "elwynn", 84)
			assert.equal("elwynn", Store.GetNote("zone", 84))
			assert.equal("", Store.GetNote("zone", 85))
		end)

		it("marks Zone as not clickable when no zone is available", function()
			local visible = Tabs.Visible(Store.IsTabEnabled, false)
			local zone
			for _, entry in ipairs(visible) do
				if entry.id == "zone" then
					zone = entry
				end
			end
			assert.is_false(zone.clickable)
		end)
	end)
end)
