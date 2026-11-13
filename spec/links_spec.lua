local loadModule = require("helpers.load")

describe("Links.ShouldInsert", function()
	local Links
	local LINK = "|cff0070dd|Hitem:19019::::::::|h[Thunderfury]|h|r"

	before_each(function()
		Links = loadModule("Core/Links.lua").Links
	end)

	it("returns true for a normal link with focus", function()
		assert.is_true(Links.ShouldInsert(LINK, true, function()
			return false
		end))
	end)

	it("returns true when isSecret is nil", function()
		assert.is_true(Links.ShouldInsert(LINK, true, nil))
	end)

	it("returns false without focus", function()
		assert.is_false(Links.ShouldInsert(LINK, false, nil))
		assert.is_false(Links.ShouldInsert(LINK, nil, nil))
	end)

	it("returns false for nil text", function()
		assert.is_false(Links.ShouldInsert(nil, true, nil))
	end)

	it("returns false for empty text", function()
		assert.is_false(Links.ShouldInsert("", true, nil))
	end)

	it("returns false for text that is not a string", function()
		assert.is_false(Links.ShouldInsert(42, true, nil))
		assert.is_false(Links.ShouldInsert({}, true, nil))
	end)

	it("returns false when isSecret returns true", function()
		assert.is_false(Links.ShouldInsert(LINK, true, function()
			return true
		end))
	end)

	it("does not call isSecret without focus", function()
		local called = false
		Links.ShouldInsert(LINK, false, function()
			called = true
			return false
		end)
		assert.is_false(called)
	end)

	it("checks secrecy before it touches the text in any way", function()
		local events = {}
		local text = setmetatable({}, {
			__index = function()
				events[#events + 1] = "index"
				error("text was read")
			end,
			__tostring = function()
				events[#events + 1] = "tostring"
				error("text was read")
			end,
			__len = function()
				events[#events + 1] = "len"
				error("text was read")
			end,
		})
		local seen
		local result = Links.ShouldInsert(text, true, function(value)
			events[#events + 1] = "isSecret"
			seen = value
			return true
		end)
		assert.is_false(result)
		assert.equal(text, seen)
		assert.same({ "isSecret" }, events)
	end)
end)
