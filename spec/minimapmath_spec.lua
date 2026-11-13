local loadModule = require("helpers.load")

describe("MinimapMath", function()
	local MinimapMath

	before_each(function()
		MinimapMath = loadModule("Core/MinimapMath.lua").MinimapMath
	end)

	local function near(expected, actual)
		assert.is_true(math.abs(expected - actual) < 1e-9, "expected " .. expected .. ", got " .. actual)
	end

	describe("Position", function()
		it("puts angle 0 on the right", function()
			local x, y = MinimapMath.Position(0, 80)
			near(80, x)
			near(0, y)
		end)

		it("puts angle 90 at the top", function()
			local x, y = MinimapMath.Position(90, 80)
			near(0, x)
			near(80, y)
		end)

		it("puts angle 225 at the bottom left", function()
			local x, y = MinimapMath.Position(225, 100)
			near(-70.710678118655, x)
			near(-70.710678118655, y)
		end)

		it("returns the origin for radius 0", function()
			local x, y = MinimapMath.Position(123, 0)
			near(0, x)
			near(0, y)
		end)
	end)

	describe("AngleFromOffset", function()
		it("returns 0 for a point on the right", function()
			near(0, MinimapMath.AngleFromOffset(5, 0))
		end)

		it("returns 90 for a point above", function()
			near(90, MinimapMath.AngleFromOffset(0, 5))
		end)

		it("returns 180 for a point on the left", function()
			near(180, MinimapMath.AngleFromOffset(-5, 0))
		end)

		it("returns a value in 0 to 360 for a point below", function()
			near(270, MinimapMath.AngleFromOffset(0, -5))
		end)

		it("returns nil for the center", function()
			assert.is_nil(MinimapMath.AngleFromOffset(0, 0))
		end)

		it("round-trips with Position", function()
			for _, angle in ipairs({ 10, 100, 200, 359 }) do
				local x, y = MinimapMath.Position(angle, 77)
				near(angle, MinimapMath.AngleFromOffset(x, y))
			end
		end)
	end)
end)
