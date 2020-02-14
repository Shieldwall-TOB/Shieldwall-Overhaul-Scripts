--foreign manpower is offered throughout the game through events.
--Trading with vikings, building certain buildings, fighting wars against vikings durastically increase chance and size of influx. 
--Crisis occur when Vikings become too numerous, but this threshold moves according to the public order, allegience, and faction leader authority of your Kingdom. 
--During Crsis, the player will face dilemma concerning conflict between Vikings and English. 
--If you are not Viking, these events may impact your relationship with the nearby Vikings quite substantially, as they won't like massacres. 
--If you are GVA, you have additional flexibility because Here King allows you to side with the Vikings, or the English, as you chose. Keeping Here King balanced, however, will reduce the likelihood of conflict occuring altogether.
--if you are VSK, you are fully immune from these penalties, and instead will use foreigners as the backbone of your Kingdom.

local low_auth_tension_cap = -10
local low_po_tension_cap = -5
local riots_tension_cap = -15

local MANPOWER_FOREIGN = {} --:map<string, FACTION_RESOURCE>

local FOREIGN_WARRIORS = {
    ["vik_fact_west_seaxe"] = {
        tension = 0, cooldown = 12, crisis = false, last_influx = 0, progression_level = 1
    }
}--:map<string, {tension: int, cooldown: int, crisis: boolean, last_influx: int, progression_level: int}>


--v function(resource: FACTION_RESOURCE) --> string
local function value_converter(resource)
    local info = FOREIGN_WARRIORS[resource.owning_faction]
    if resource.value == 0 then
        return "0"
    elseif info.crisis == true then
        if info.progression_level > 3 then
            return "3"
        else
            return "2"
        end
    else
        return "1"
    end
end


dev.first_tick(function(context)
    local human_factions = cm:get_human_factions()
    for i = 1, #human_factions do
        MANPOWER_FOREIGN[human_factions[i]] = PettyKingdoms.FactionResource.new(human_factions[i], "sw_pop_foreign", "population", 0, 30000, {}, value_converter)
        local foreign = MANPOWER_FOREIGN[human_factions[i]]
        foreign.uic_override = {"layout", "top_center_holder", "resources_bar2", "culture_mechanics"} 
        foreign:reapply()
        
    end


end)