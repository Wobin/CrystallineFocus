local mod = get_mod("Crystalline Focus")

return {
	name = mod:localize("mod_name"),	
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "peril_threshold",			
				type = "numeric",
				default_value = 80,
				range = {0, 100},
			},
			{
				setting_id = "add_ring",			
				type = "checkbox",
				default_value = true,				
			},
		}
	}
}
