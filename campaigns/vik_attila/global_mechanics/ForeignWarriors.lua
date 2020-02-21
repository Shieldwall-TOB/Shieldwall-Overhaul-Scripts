--TODO factors!

local weight_peasant = 1
local weight_noble = -11
local weight_monk = 9
local weight_foreign = 2


local base_boiling_time = 5 
local defuse_rate = 2
local crisis_duration = 8
local foreign_warrior_startpos = {

} --:map<string, map<string, int>>
local MANPOWER_FOREIGN = {} --:map<string, FACTION_RESOURCE>
local FOREIGN_WARRIORS = {
    ["vik_fact_west_seaxe"] = {
        crisis_timer = base_boiling_time,
        last_tension = 0,
        in_crisis = false,
        building_modifiers = {},
        trait_modifiers = {},
        events_triggered = {}
    }
} --:map<string, {crisis_timer: int, last_tension: int, in_crisis: boolean, building_modifiers: map<string, number>, trait_modifiers: map<string, number>, events_triggered: map<string, boolean>}>

--v function(faction_key: string)
local function add_blank_foreign_warrior_entry(faction_key)
    FOREIGN_WARRIORS[faction_key] = {
        crisis_timer = base_boiling_time,
        last_tension = 0,
        in_crisis = false,
        building_modifiers = {},
        trait_modifiers = {},
        events_triggered = {}
    }
end


--v function(faction: CA_FACTION)
local function process_turn_start(faction)
    if FOREIGN_WARRIORS[faction:name()].in_crisis then
        FOREIGN_WARRIORS[faction:name()].crisis_timer = FOREIGN_WARRIORS[faction:name()].crisis_timer - 1;
        if FOREIGN_WARRIORS[faction:name()].crisis_timer <= 0 then
            FOREIGN_WARRIORS[faction:name()].in_crisis = false
        end
        --otherwise, do nothing. Events check this table for a true crisis flag to cause events.
        return
    end
    --find base tension
    local peasant_pressure = weight_peasant * PettyKingdoms.FactionResource.get("sw_pop_serf", faction:name()).value 
    local monk_pressure = weight_monk * PettyKingdoms.FactionResource.get("sw_pop_monk", faction:name()).value 
    local foreigner_pressure = weight_foreign * MANPOWER_FOREIGN[faction:name()].value 
    local base_tensions = peasant_pressure + foreigner_pressure + monk_pressure
    --find building and trait effects.
    local province_weights = {} --:map<string, number>
    local province_effects = {} --:map<string, number>
    for j = 0, faction:region_list():num_items() - 1 do
        local region = faction:region_list():item_at(j)
        province_weights[region:province_name()] = (province_weights[region:province_name()] or 0) + 1
        for building_key, value in pairs(FOREIGN_WARRIORS[faction:name()].building_modifiers) do
            if region:building_superchain_exists(building_key) then
                province_effects[region:province_name()] =  (province_effects[region:province_name()] or 0) + (value/100)
            end
        end
    end
    --apply building and trait effects
    local tensions = base_tensions
    for province, effect in pairs(province_effects) do
        tensions = dev.mround(tensions - ( base_tensions * effect * (province_weights[province]/faction:region_list():num_items()) ), 1)
    end
    --apply reduction from nobles
    local noble_pressure = weight_noble * PettyKingdoms.FactionResource.get("sw_pop_noble", faction:name()).value 
    tensions = tensions + noble_pressure
    --apply tensions
    if tensions > 0 then
        FOREIGN_WARRIORS[faction:name()].crisis_timer = FOREIGN_WARRIORS[faction:name()].crisis_timer - 1
    elseif tensions < 0 then
        FOREIGN_WARRIORS[faction:name()].crisis_timer = dev.mround(dev.clamp(FOREIGN_WARRIORS[faction:name()].crisis_timer + defuse_rate, 0, base_boiling_time), 1)
    end
    FOREIGN_WARRIORS[faction:name()].last_tension = tensions
    if FOREIGN_WARRIORS[faction:name()].crisis_timer == 0 then
        FOREIGN_WARRIORS[faction:name()].in_crisis = true
        FOREIGN_WARRIORS[faction:name()].crisis_timer = crisis_duration
    end
end

--v function(resource: FACTION_RESOURCE) --> string
local function value_converter(resource)
    if resource.value == 0 then
        return "0"
    elseif dev.get_faction(resource.owning_faction):subculture() == "vik_sub_cult_viking_gael" then
        return "6"
    elseif FOREIGN_WARRIORS[resource.owning_faction].in_crisis then
        local region_count = dev.get_faction(resource.owning_faction):region_list():num_items()
        if region_count < 12 then
            return "3"
        elseif region_count < 30 then
            return "4"
        else
            return "5"
        end
    elseif FOREIGN_WARRIORS[resource.owning_faction].last_tension > 0 then
        return "2"
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
        if not FOREIGN_WARRIORS[human_factions[i]] then
            add_blank_foreign_warrior_entry(human_factions[i])
        end
        if dev.is_new_game() and foreign_warrior_startpos[human_factions[i]] then
            for factor, value in pairs(foreign_warrior_startpos[human_factions[i]]) do
                foreign:set_factor(factor, value)
            end
        end
        foreign:reapply()
    end

    dev.eh:add_listener(
        "ForeignWarriorsTurnStart",
        "FactionTurnStart",
        function(context)
            return context:faction():is_human()
        end,
        function(context)
            process_turn_start(context:faction())
            MANPOWER_FOREIGN[context:faction():name()]:reapply()
        end,
        true)
    --TODO add turnstart events

end)
