return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Crystalline Focus` encountered an error loading the Darktide Mod Framework.")

		new_mod("Crystalline Focus", {
			mod_script       = "Crystalline Focus/scripts/mods/Crystalline Focus/Crystalline Focus",
			mod_data         = "Crystalline Focus/scripts/mods/Crystalline Focus/Crystalline Focus_data",
			mod_localization = "Crystalline Focus/scripts/mods/Crystalline Focus/Crystalline Focus_localization",
		})
	end,
	packages = {},
	version = "1.2.1",
}
