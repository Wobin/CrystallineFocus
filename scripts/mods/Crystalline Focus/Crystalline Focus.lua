local mod = get_mod("Crystalline Focus")

local Unit = Unit
local table = table
local Promise = Promise
local Managers = Managers
local delay = Promise.delay
local ScriptUnit = ScriptUnit
local vector3 = Vector3.distance
local table_insert = table.insert
local playerManager = Managers.player
local unitLocalPosition = Unit.local_position
local managers_state = Managers.state
local game_mode_manager = Managers.state.game_mode			
local has_extension = ScriptUnit.has_extension
local HEALTH_ALIVE = HEALTH_ALIVE

mod.radius = 12.5
mod.version = "1.2.1"

mod:io_dofile("Crystalline Focus/scripts/mods/Crystalline Focus/modules/Outlines")
mod:io_dofile("Crystalline Focus/scripts/mods/Crystalline Focus/modules/Zone")


local retrieve_profile = function()        
    local localplayer = playerManager:local_player_safe(1) or nil
    if not localplayer then return end
    local profile = localplayer:profile()
    local talent_extension = has_extension(localplayer.player_unit, "talent_system")
	local has_overload = talent_extension and talent_extension:has_special_rule("psyker_no_knock_down_overload")    
    mod.player = (profile and profile.archetype.name == "psyker" and has_overload) and localplayer or nil    
end


local acceptable_locations = {}
acceptable_locations["coop_complete_objective"] = true
acceptable_locations["survival"] = true
acceptable_locations["shooting_range"] = true

mod.player = nil

mod.on_all_mods_loaded = function()    
    mod:info(mod.version)
    mod:init()
end

mod.on_unload = function(exit_game)
    if mod.remove_all_outlines then
        mod.remove_all_outlines()    
    end
    if mod.remove_zone then
        mod.remove_zone()
    end
    mod.initialised = false
    mod.player = nil    
end

mod.on_game_state_changed = function(status, sub_state_name)
	if sub_state_name == "GameplayStateRun" and status == "enter" then                
        mod:init()
    end
    if sub_state_name == "StateLoading" and status == "exit" then
        mod.on_unload()
    end
end

mod.init = function()    
     game_mode_manager = Managers.state.game_mode			
    if game_mode_manager then        
	    if acceptable_locations[game_mode_manager:game_mode_name()] then            
            delay(3):next(retrieve_profile):next(mod.init_zone):next(function() mod.initialised = true end)
        end    
    end

end

mod:hook_safe(CLASS.InventoryBackgroundView, "on_exit", function()
    delay(3):next(mod.remove_all_outlines):next(mod.remove_zone):next(retrieve_profile)
end)


local function find_enemies_in_radius(center, radius)
    local state_extension = managers_state.extension or Managers.state.extension
    local side_system = state_extension:system("side_system")
    local player_side = side_system and side_system:get_side_from_name("heroes")
    if not player_side then return {} end
    local enemy_units_list = player_side:relation_units("enemy")
    local enemy_units = {}
    
    for _, unit in ipairs(enemy_units_list) do     
        local distance = vector3(center, unitLocalPosition(unit, 1))   
        if HEALTH_ALIVE and HEALTH_ALIVE[unit] and distance <= radius then
            local unit_data_extension = has_extension(unit, "unit_data_system")
            local breed = unit_data_extension and unit_data_extension:breed()
            if breed.tags and breed.tags.elite then                
                local current_health = has_extension(unit, "health_system"):current_health()                
                local reduced_damage = 1200 * (1 - ((distance / 12.5) * (distance / 12.5)))                 
                if current_health <= reduced_damage then 
                    table_insert(enemy_units, unit)
                end
            end
        end
    end
    return enemy_units
end

local manage_outlines = mod.manage_outlines
local delta = 0

mod.update = function(dt)    
    if not mod.initialised then return end    
    if delta > 0.3 then
        if mod.player and Unit.is_valid(mod.player.player_unit) then            
            local extensions =  has_extension(mod.player.player_unit, "unit_data_system")	        
            local warp_charge_component = extensions and extensions:read_component("warp_charge")
            local warp_charge_level = warp_charge_component and warp_charge_component.current_percentage or 0
            if warp_charge_level >= (mod:get("peril_threshold")/100) then
                mod.at_peril_threshold = true                
                local enemies = find_enemies_in_radius(unitLocalPosition(mod.player.player_unit, 1), mod.radius)                     
                manage_outlines(enemies)
                if #enemies > 0 and mod:get("add_ring") then
                    mod.manage_zone()
                else
                    mod.remove_zone()
                end
            else
                mod.at_peril_threshold = false
            end
        end
        delta = 0
    else
        delta = delta + dt    
    end      
end

