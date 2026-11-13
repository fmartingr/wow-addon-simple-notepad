local _, ns = ...

-- Lua 5.3+ drops math.atan2 and gives math.atan a second argument instead; WoW runs Lua 5.1.
local atan2 = math.atan2 or math.atan

local MinimapMath = {}
ns.MinimapMath = MinimapMath

function MinimapMath.Position(angle, radius)
	local radians = math.rad(angle)
	return math.cos(radians) * radius, math.sin(radians) * radius
end

function MinimapMath.AngleFromOffset(dx, dy)
	if dx == 0 and dy == 0 then
		return nil
	end
	return math.deg(atan2(dy, dx)) % 360
end
