MANPOWER_NOBLE[human_factions[i]] = PettyKingdoms.FactionResource.new(human_factions[i], "sw_pop_noble", "population", 0, 30000, {}, function(self)
    return "3" 
    --TODO pop value to bundle conversion
end)
local nobles = MANPOWER_NOBLE[human_factions[i]]
nobles.uic_override = {"layout", "top_center_holder"} 