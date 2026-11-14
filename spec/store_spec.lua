local loadModule = require("helpers.load")

describe("Store", function()
	local Store

	before_each(function()
		Store = loadModule("Core/Store.lua").Store
	end)

	describe("Init", function()
		it("returns default shapes for nil input", function()
			local account, char = Store.Init(nil, nil)
			assert.same({
				schemaVersion = 1,
				global = "",
				tabs = { global = true, zone = true },
				openOnLogin = false,
				minimap = { angle = 225, show = true },
			}, account)
			assert.same({ schemaVersion = 1, character = "", zones = {}, lastTab = "character" }, char)
		end)

		it("returns default shapes for non-table input", function()
			local account, char = Store.Init(5, "x")
			assert.same({
				schemaVersion = 1,
				global = "",
				tabs = { global = true, zone = true },
				openOnLogin = false,
				minimap = { angle = 225, show = true },
			}, account)
			assert.same({ schemaVersion = 1, character = "", zones = {}, lastTab = "character" }, char)
		end)

		it("keeps valid fields", function()
			local account, char = Store.Init({
				schemaVersion = 1,
				global = "g",
				tabs = { global = false, zone = false },
				openOnLogin = true,
				minimap = { angle = 90, show = false },
			}, { schemaVersion = 1, character = "c", zones = { [84] = "z" }, lastTab = "zone" })
			assert.same({
				schemaVersion = 1,
				global = "g",
				tabs = { global = false, zone = false },
				openOnLogin = true,
				minimap = { angle = 90, show = false },
			}, account)
			assert.same({ schemaVersion = 1, character = "c", zones = { [84] = "z" }, lastTab = "zone" }, char)
		end)

		it("keeps the table identity of valid input", function()
			local input = { global = "g" }
			local account = Store.Init(input, nil)
			assert.equal(input, account)
		end)

		it("repairs a wrong-typed account schemaVersion", function()
			local account = Store.Init({ schemaVersion = "1" }, nil)
			assert.equal(1, account.schemaVersion)
		end)

		it("repairs a wrong-typed global note and keeps the other fields", function()
			local account = Store.Init({ global = 5, tabs = { global = false } }, nil)
			assert.equal("", account.global)
			assert.is_false(account.tabs.global)
		end)

		it("repairs a wrong-typed tabs table", function()
			local account = Store.Init({ tabs = "x" }, nil)
			assert.same({ global = true, zone = true }, account.tabs)
		end)

		it("repairs a wrong-typed tab toggle and keeps the other toggle", function()
			local account = Store.Init({ tabs = { global = "no", zone = false } }, nil)
			assert.is_true(account.tabs.global)
			assert.is_false(account.tabs.zone)
		end)

		it("fills a missing tab toggle", function()
			local account = Store.Init({ tabs = { zone = false } }, nil)
			assert.is_true(account.tabs.global)
			assert.is_false(account.tabs.zone)
		end)

		it("repairs a wrong-typed character schemaVersion", function()
			local _, char = Store.Init(nil, { schemaVersion = {} })
			assert.equal(1, char.schemaVersion)
		end)

		it("repairs a non-finite schemaVersion", function()
			local account, char = Store.Init({ schemaVersion = 0 / 0 }, { schemaVersion = math.huge })
			assert.equal(1, account.schemaVersion)
			assert.equal(1, char.schemaVersion)
			local _, char2 = Store.Init(nil, { schemaVersion = -math.huge })
			assert.equal(1, char2.schemaVersion)
		end)

		it("repairs a wrong-typed character note", function()
			local _, char = Store.Init(nil, { character = false, lastTab = "zone" })
			assert.equal("", char.character)
			assert.equal("zone", char.lastTab)
		end)

		it("repairs a wrong-typed zones table", function()
			local _, char = Store.Init(nil, { zones = 7 })
			assert.same({}, char.zones)
		end)

		it("repairs a wrong-typed lastTab", function()
			local _, char = Store.Init(nil, { lastTab = 3 })
			assert.equal("character", char.lastTab)
		end)

		it("repairs an unknown lastTab", function()
			local _, char = Store.Init(nil, { lastTab = "bogus" })
			assert.equal("character", char.lastTab)
		end)

		it("deletes invalid zones entries and keeps valid ones", function()
			local _, char = Store.Init(nil, { zones = { [84] = "ok", ["85"] = "bad key", [86] = 5, [87] = "ok2" } })
			assert.same({ [84] = "ok", [87] = "ok2" }, char.zones)
		end)

		it("deletes non-integer zones keys", function()
			local _, char = Store.Init(
				nil,
				{ zones = { [84.5] = "frac", [math.huge] = "inf", [-math.huge] = "-inf", [85] = "ok" } }
			)
			assert.same({ [85] = "ok" }, char.zones)
		end)

		it("deletes zero and negative zones keys", function()
			local _, char = Store.Init(nil, { zones = { [0] = "zero", [-84] = "neg", [85] = "ok" } })
			assert.same({ [85] = "ok" }, char.zones)
		end)

		it("deletes empty zones entries", function()
			local _, char = Store.Init(nil, { zones = { [84] = "", [85] = "ok" } })
			assert.same({ [85] = "ok" }, char.zones)
		end)

		it("keeps schemaVersion 2 data", function()
			local account, char = Store.Init(
				{ schemaVersion = 2, global = "g" },
				{ schemaVersion = 2, character = "c" }
			)
			assert.equal(2, account.schemaVersion)
			assert.equal("g", account.global)
			assert.equal(2, char.schemaVersion)
			assert.equal("c", char.character)
		end)
	end)

	describe("notes", function()
		before_each(function()
			Store.Init(nil, nil)
		end)

		it("returns an empty string for missing notes", function()
			assert.equal("", Store.GetNote("global"))
			assert.equal("", Store.GetNote("character"))
			assert.equal("", Store.GetNote("zone", 84))
		end)

		it("returns an empty string for the zone tab without a key", function()
			assert.equal("", Store.GetNote("zone", nil))
		end)

		it("returns an empty string for an unknown tab", function()
			assert.equal("", Store.GetNote("bogus"))
		end)

		it("round-trips each tab", function()
			Store.SetNote("global", "g")
			Store.SetNote("character", "c")
			Store.SetNote("zone", "z84", 84)
			Store.SetNote("zone", "z85", 85)
			assert.equal("g", Store.GetNote("global"))
			assert.equal("c", Store.GetNote("character"))
			assert.equal("z84", Store.GetNote("zone", 84))
			assert.equal("z85", Store.GetNote("zone", 85))
		end)

		it("stores pipes and link codes unchanged", function()
			local text = "a || b |cff0070dd|Hitem:19019::::::::|h[Thunderfury]|h|r"
			Store.SetNote("global", text)
			Store.SetNote("character", text)
			Store.SetNote("zone", text, 84)
			assert.equal(text, Store.GetNote("global"))
			assert.equal(text, Store.GetNote("character"))
			assert.equal(text, Store.GetNote("zone", 84))
		end)

		it("does not trim text", function()
			Store.SetNote("character", "  x \n")
			assert.equal("  x \n", Store.GetNote("character"))
		end)

		it("removes the zone entry for empty text", function()
			local _, char = Store.Init(nil, { zones = { [84] = "x" } })
			Store.SetNote("zone", "", 84)
			assert.is_nil(char.zones[84])
		end)

		it("does nothing for a zone note without a key", function()
			local _, char = Store.Init(nil, nil)
			Store.SetNote("zone", "x", nil)
			assert.same({}, char.zones)
		end)

		it("does nothing for a zone note with a non-number key", function()
			local _, char = Store.Init(nil, nil)
			Store.SetNote("zone", "x", "84")
			assert.same({}, char.zones)
			assert.equal("", Store.GetNote("zone", "84"))
		end)

		it("does nothing for a zone note with a NaN key", function()
			local _, char = Store.Init(nil, nil)
			Store.SetNote("zone", "x", 0 / 0)
			assert.same({}, char.zones)
			assert.equal("", Store.GetNote("zone", 0 / 0))
		end)

		it("does nothing for a zone note with an infinite or fractional key", function()
			local _, char = Store.Init(nil, nil)
			Store.SetNote("zone", "x", math.huge)
			Store.SetNote("zone", "x", 84.5)
			assert.same({}, char.zones)
			assert.equal("", Store.GetNote("zone", math.huge))
		end)

		it("raises an error for non-string text and keeps the note", function()
			Store.SetNote("global", "g")
			Store.SetNote("character", "c")
			Store.SetNote("zone", "z", 84)
			assert.has_error(function()
				Store.SetNote("global", nil)
			end, "note text must be a string, got nil")
			assert.has_error(function()
				Store.SetNote("character", 5)
			end, "note text must be a string, got number")
			assert.has_error(function()
				Store.SetNote("zone", {}, 84)
			end, "note text must be a string, got table")
			assert.equal("g", Store.GetNote("global"))
			assert.equal("c", Store.GetNote("character"))
			assert.equal("z", Store.GetNote("zone", 84))
		end)

		it("raises an error for an unknown tab", function()
			assert.has_error(function()
				Store.SetNote("bogus", "x")
			end, "unknown tab: bogus")
		end)

		it("reports an unknown tab before invalid text", function()
			assert.has_error(function()
				Store.SetNote("bogus", nil)
			end, "unknown tab: bogus")
		end)

		it("does not return a zone note for another key", function()
			Store.SetNote("zone", "x", 84)
			assert.equal("", Store.GetNote("zone", 85))
		end)
	end)

	describe("tab toggles", function()
		before_each(function()
			Store.Init(nil, nil)
		end)

		it("enables global and zone by default", function()
			assert.is_true(Store.IsTabEnabled("global"))
			assert.is_true(Store.IsTabEnabled("zone"))
		end)

		it("changes the toggles", function()
			Store.SetTabEnabled("global", false)
			Store.SetTabEnabled("zone", false)
			assert.is_false(Store.IsTabEnabled("global"))
			assert.is_false(Store.IsTabEnabled("zone"))
			Store.SetTabEnabled("global", true)
			assert.is_true(Store.IsTabEnabled("global"))
		end)

		it("keeps the character tab enabled", function()
			Store.SetTabEnabled("character", false)
			assert.is_true(Store.IsTabEnabled("character"))
		end)

		it("reports an unknown tab as not enabled", function()
			assert.is_false(Store.IsTabEnabled("bogus"))
		end)

		it("reports an unknown tab as not enabled even when saved data has it", function()
			Store.Init({ tabs = { bogus = true } }, nil)
			assert.is_false(Store.IsTabEnabled("bogus"))
		end)

		it("ignores an unknown tab in SetTabEnabled", function()
			Store.SetTabEnabled("bogus", true)
			assert.is_false(Store.IsTabEnabled("bogus"))
		end)
	end)

	describe("last tab", function()
		before_each(function()
			Store.Init(nil, nil)
		end)

		it("defaults to character", function()
			assert.equal("character", Store.GetLastTab())
		end)

		it("stores a valid tab", function()
			Store.SetLastTab("zone")
			assert.equal("zone", Store.GetLastTab())
		end)

		it("keeps the previous value for an unknown tab", function()
			Store.SetLastTab("global")
			Store.SetLastTab("bogus")
			assert.equal("global", Store.GetLastTab())
		end)
	end)
	describe("minimap", function()
		it("repairs a wrong-typed minimap table", function()
			local account = Store.Init({ minimap = "x" }, nil)
			assert.same({ angle = 225, show = true }, account.minimap)
		end)

		it("repairs a wrong-typed angle and show flag independently", function()
			local account = Store.Init({ minimap = { angle = "up", show = 1 } }, nil)
			assert.same({ angle = 225, show = true }, account.minimap)
			account = Store.Init({ minimap = { angle = 10, show = "no" } }, nil)
			assert.same({ angle = 10, show = true }, account.minimap)
		end)

		it("repairs NaN and infinite angles", function()
			assert.equal(225, Store.Init({ minimap = { angle = 0 / 0 } }, nil).minimap.angle)
			assert.equal(225, Store.Init({ minimap = { angle = math.huge } }, nil).minimap.angle)
			assert.equal(225, Store.Init({ minimap = { angle = -math.huge } }, nil).minimap.angle)
		end)

		it("normalizes a saved angle into 0 to 360", function()
			assert.equal(350, Store.Init({ minimap = { angle = -10 } }, nil).minimap.angle)
			assert.equal(20, Store.Init({ minimap = { angle = 380 } }, nil).minimap.angle)
		end)

		it("stores a new angle and normalizes it", function()
			Store.Init(nil, nil)
			Store.SetMinimapAngle(-90)
			assert.equal(270, Store.GetMinimapAngle())
		end)

		it("ignores an angle that is not a finite number", function()
			Store.Init(nil, nil)
			Store.SetMinimapAngle(45)
			Store.SetMinimapAngle("x")
			Store.SetMinimapAngle(0 / 0)
			Store.SetMinimapAngle(math.huge)
			assert.equal(45, Store.GetMinimapAngle())
		end)

		it("reports the show flag", function()
			Store.Init(nil, nil)
			assert.is_true(Store.IsMinimapShown())
			Store.Init({ minimap = { show = false } }, nil)
			assert.is_false(Store.IsMinimapShown())
		end)
	end)

	describe("openOnLogin", function()
		it("defaults to false", function()
			Store.Init(nil, nil)
			assert.is_false(Store.IsOpenOnLogin())
		end)

		it("keeps a true value", function()
			Store.Init({ openOnLogin = true }, nil)
			assert.is_true(Store.IsOpenOnLogin())
		end)

		it("repairs a wrong type", function()
			local account = Store.Init({ openOnLogin = "yes" }, nil)
			assert.is_false(account.openOnLogin)
		end)
	end)
end)
