local ui_state = "slaves"
local unit_size_mode_scalar = CONST.__unit_size_scalar
local recruitment_factor = "manpower_recruitment" --:string

--v function(resource: FACTION_RESOURCE) --> string
local function value_converter(resource)
    return tostring(dev.clamp(math.ceil(resource.value/300), 0, 16))
end

dev.first_tick(function(context)
    for faction_key, start_pos_slaves in pairs(Gamedata.base_pop.slaves_factions) do
        if dev.get_faction(faction_key):is_human() then
            local slaves = PettyKingdoms.FactionResource.new(faction_key, "vik_dyflin_slaves", "population", start_pos_slaves, 30000, {}, value_converter)
            if dev.is_new_game() then
                slaves:set_factor("manpower_region_raided", start_pos_slaves)
                slaves:reapply()
            end
        end
    end
    if (not Gamedata.base_pop.slaves_factions[cm:get_local_faction(true)]) and (not cm:is_multiplayer()) then
        UIScript.recruitment_handler.disable_recruitment_cost_type_for_faction(cm:get_local_faction(true), "dy_pop_slaves")
    else
        PettyKingdoms.RegionManpower.activate("slave", function(faction_key, factor_key, change)
            local pop = PettyKingdoms.FactionResource.get("vik_dyflin_slaves", dev.get_faction(faction_key))
            if pop then
                pop:change_value(change, factor_key)
            end
        end)

        local rec_handler = UIScript.recruitment_handler.add_resource("vik_dyflin_slaves", function(faction_name)
            return PettyKingdoms.FactionResource.get("vik_dyflin_slaves", dev.get_faction(faction_name)).value
        end, 
        function(faction_name, quantity)
            PettyKingdoms.FactionResource.get("vik_dyflin_slaves", dev.get_faction(faction_name)):change_value(quantity, recruitment_factor)
        end, "dy_pop_slaves")
        for k, entry in pairs(Gamedata.unit_info.main_unit_size_caste_info) do
            if Gamedata.unit_info.slave_units[k] then
                rec_handler:set_cost_of_unit(entry.unit_key, dev.mround(entry.num_men*unit_size_mode_scalar, 1))
            end
        end
        rec_handler:set_resource_tooltip("Thrall units require slave population to recruit")
        rec_handler.image_state = "slaves"
    end



end)