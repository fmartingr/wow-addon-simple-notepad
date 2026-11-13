local _, ns = ...

local Links = {}
ns.Links = Links

function Links.ShouldInsert(text, hasFocus, isSecret)
	if not hasFocus then
		return false
	end
	if type(isSecret) == "function" and isSecret(text) then
		return false
	end
	return type(text) == "string" and text ~= ""
end
