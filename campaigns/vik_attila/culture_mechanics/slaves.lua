local ui_state = "slaves"

--v function(resource: FACTION_RESOURCE) --> string
local function value_converter(resource)
    return  "1"
end

dev.first_tick(function(context)
    for faction_key, start_pos_slaves in pairs(Gamedata.base_pop.slaves_factions) do
        if dev.get_faction(faction_key):is_human() then
            local slaves = PettyKingdoms.FactionResource.new(faction_key, "vik_dyflin_slaves", "population", start_pos_slaves, 30000, {}, value_converter)
            if dev.is_new_game() then
                slaves:set_new_value(start_pos_slaves)
            end
        end
    end
    if not Gamedata.base_pop.slaves_factions[cm:get_local_faction(true)] then
        UIScript.recruitment_handler.disable_recruitment_cost_type_for_faction(cm:get_local_faction(true), "dy_pop_slaves")
    end
end)