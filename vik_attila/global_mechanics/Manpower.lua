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
        MANPOWER_NOBLE[human_factions[i]] = PettyKingdoms.FactionResource.new(human_factions[i], "sw_pop_noble", "population", 0, 30000, {}, function(self)
            return "3" 
            --TODO pop value to bundle conversion
        end)
        local nobles = MANPOWER_NOBLE[human_factions[i]]
        local serf_total = 0 --:number
        local noble_total = 0 --:number
        local region_list = dev.get_faction(human_factions[i]):region_list()
        for i = 0, region_list:num_items() - 1 do 
            local region_detail = PettyKingdoms.RegionDetail.get(region_list:item_at(i):name())
            serf_total = serf_total + region_detail.serf
            noble_total = noble_total + region_detail.noble
        end
        serfs:set_new_value(serf_total)
        nobles:set_new_value(noble_total)
    end    
    dev.eh:add_listener(
        "RegionDetailPopulationChangedSerfs",
        "RegionDetailPopulationChanged",
        function(context)
            return context.string == "serf" and context:region():owning_faction():is_human()
        end,
        function(context)
            local change = context.table.old - context.table.new
            --TODO add factor breakdown.
            if change > 0 then
                MANPOWER_SERF[context:region():owning_faction():name()]:change_value(change)
            elseif change < 0 then
                MANPOWER_SERF[context:region():owning_faction():name()]:change_value(change)
            end
        end,
        true)
    dev.eh:add_listener(
        "RegionDetailPopulationChangedNobles",
        "RegionDetailPopulationChanged",
        function(context)
            return context.string == "noble" and context:region():owning_faction():is_human()
        end,
        function(context)
            local change = context.table.old - context.table.new
            --TODO add factor breakdown.
            if change > 0 then
                MANPOWER_NOBLE[context:region():owning_faction():name()]:change_value(change)
            elseif change < 0 then
                MANPOWER_NOBLE[context:region():owning_faction():name()]:change_value(change)
            end
        end,
        true)
end)