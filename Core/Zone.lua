local _, ns = ...

local Zone = {}
ns.Zone = Zone

local MAP_TYPE_ZONE = 3
local MAP_TYPE_DUNGEON = 4
local MAX_STEPS = 10

function Zone.Resolve(getBestMap, getMapInfo)
	local id = getBestMap("player")
	if id == nil then
		return nil
	end
	for _ = 1, MAX_STEPS do
		local info = getMapInfo(id)
		if info == nil then
			return nil
		end
		if info.mapType == MAP_TYPE_ZONE or info.mapType == MAP_TYPE_DUNGEON then
			return id, info.name
		end
		if info.mapType < MAP_TYPE_ZONE or info.parentMapID == nil or info.parentMapID == 0 then
			return nil
		end
		id = info.parentMapID
	end
	return nil
end
