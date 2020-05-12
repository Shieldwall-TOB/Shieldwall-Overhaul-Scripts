local HEROISM = {} --:map<string, FACTION_RESOURCE>
local heroism_factions = {
    ["vik_fact_gwined"] = 15,
    ["vik_fact_strat_clut"] = 11
} --:map<string, int>
local heroism_max = 30

--v function(resource: FACTION_RESOURCE) --> string
local function value_converter(resource)
    return tostring(math.floor(resource.value/6))
end
	
dev.first_tick(function(context) 
    dev.log("#### Adding Welsh Mechanics Listeners ####", "HERO")
    local humans = cm:get_human_factions()
    for i = 1, #humans do
        local h_name = humans[i]
        if heroism_factions[h_name] then
            local heroism = PettyKingdoms.FactionResource.new(h_name, "vik_heroism", "resource_bar", heroism_factions[h_name], heroism_max, {}, value_converter)
            HEROISM[h_name] = heroism
        end
    end
end)

