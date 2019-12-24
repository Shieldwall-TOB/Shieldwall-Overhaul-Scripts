MANPOWER_SERF = {} --:map<string, FACTION_RESOURCE>
MANPOWER_NOBLE = {} --:map<string, FACTION_RESOURCE>




dev.first_tick(function(context) 

    local human_factions = cm:get_human_factions()
    for i = 1, #human_factions do
        MANPOWER_SERF[human_factions[i]] = PettyKingdoms.FactionResource.new(human_factions[i], "sw_pop_serf", "population", 0, 30000, {}, function(self)
            return "3" 
            --TODO pop value to bundle conversion
        end)
        local serfs = MANPOWER_SERF[human_factions[i]]
        serfs.uic_override = {"layout", "top_center_holder"} 
        
        local serf_total = 0 --:number
      
 
        serfs:set_new_value(serf_total)
    end    

    
end)