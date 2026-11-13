local _, ns = ...

local Tabs = {}
ns.Tabs = Tabs

Tabs.ORDER = { "global", "character", "zone" }

function Tabs.Visible(isEnabled, zoneAvailable)
	local visible = {}
	for _, id in ipairs(Tabs.ORDER) do
		if id == "character" then
			visible[#visible + 1] = { id = id, clickable = true }
		elseif isEnabled(id) then
			visible[#visible + 1] = { id = id, clickable = id ~= "zone" or zoneAvailable == true }
		end
	end
	return visible
end

function Tabs.Resolve(requested, visible)
	for _, entry in ipairs(visible) do
		if entry.id == requested and entry.clickable then
			return requested
		end
	end
	return "character"
end
