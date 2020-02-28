local ui_state = "slaves"

--v function(resource: FACTION_RESOURCE)
local function value_converter(resource)

end

dev.first_tick(function(context)
    for faction_key, start_pos_slaves in pairs(Gamedata.base_pop.slave_faction) do
        if dev.get_faction(faction_key):is_human() then
            local slaves = PettyKingdoms.FactionResource.new(human_factions[i], "vik_dyflin_slaves", "population", 0, 30000, {}, value_converter)
            if dev.is_new_game() then
                slaves:set_new_value(start_pos_slaves)
            end
            



        end
    end

end)