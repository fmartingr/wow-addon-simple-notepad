local loadModule = require("helpers.load")

local LOCALES = { "enUS", "deDE", "esES", "esMX", "frFR", "itIT", "ptBR" }

describe("Locales", function()
	local realGetLocale = _G.GetLocale

	after_each(function()
		_G.GetLocale = realGetLocale
	end)

	local function boot(client)
		_G.GetLocale = function()
			return client
		end
		return loadModule("Locales.lua")
	end

	local function specifiers(text)
		local found = {}
		for spec in text:gmatch("%%[%d%.]*[sdf]") do
			found[#found + 1] = spec
		end
		return table.concat(found, ",")
	end

	it("has every enUS key in every locale", function()
		local ns = boot("enUS")
		for _, locale in ipairs(LOCALES) do
			assert.is_table(ns.locales[locale], locale)
			for key in pairs(ns.locales.enUS) do
				assert.is_string(ns.locales[locale][key], locale .. "." .. key)
			end
		end
	end)

	it("has no extra key in a locale", function()
		local ns = boot("enUS")
		for _, locale in ipairs(LOCALES) do
			for key in pairs(ns.locales[locale]) do
				assert.is_string(ns.locales.enUS[key], locale .. "." .. key)
			end
		end
	end)

	it("keeps the format specifiers of enUS", function()
		local ns = boot("enUS")
		for _, locale in ipairs(LOCALES) do
			for key, text in pairs(ns.locales.enUS) do
				assert.equals(specifiers(text), specifiers(ns.locales[locale][key]), locale .. "." .. key)
			end
		end
	end)

	it("uses the client locale", function()
		local ns = boot("deDE")
		assert.equals(ns.locales.deDE.NO_ZONE, ns.L.NO_ZONE)
	end)

	it("falls back to enUS for an unknown client locale", function()
		local ns = boot("koKR")
		assert.equals("No zone detected", ns.L.NO_ZONE)
	end)

	it("falls back to enUS for a key missing in the client locale", function()
		local ns = boot("frFR")
		ns.locales.frFR.NO_ZONE = nil
		assert.equals("No zone detected", ns.L.NO_ZONE)
	end)

	it("returns the key for an unknown key", function()
		local ns = boot("enUS")
		assert.equals("NOPE", ns.L.NOPE)
	end)

	it("shares the enUS table with enGB and the esES table with esMX", function()
		local ns = boot("enUS")
		assert.equals(ns.locales.enUS, ns.locales.enGB)
		assert.equals(ns.locales.esES, ns.locales.esMX)
	end)
end)
