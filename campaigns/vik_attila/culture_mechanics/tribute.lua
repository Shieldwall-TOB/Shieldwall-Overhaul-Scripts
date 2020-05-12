local TRIBUTE = {} --:map<string, FACTION_RESOURCE>
local tribute_factions = {
    ["vik_fact_sudreyar"] = 15,
    ["vik_fact_dyflin"] = 6
} --:map<string, int>
local tribute_max = 30

--v function(resource: FACTION_RESOURCE) --> string
local function value_converter(resource)
    return tostring(math.floor(resource.value/6))
end
	
dev.first_tick(function(context) 
    dev.log("#### Adding Welsh Mechanics Listeners ####", "HERO")
    local humans = cm:get_human_factions()
    for i = 1, #humans do
        local h_name = humans[i]
        if tribute_factions[h_name] then
            local tribute = PettyKingdoms.FactionResource.new(h_name, "vik_tribute", "resource_bar", tribute_factions[h_name], tribute_max, {}, value_converter)
            TRIBUTE[h_name] = tribute
        end
    end
end)

