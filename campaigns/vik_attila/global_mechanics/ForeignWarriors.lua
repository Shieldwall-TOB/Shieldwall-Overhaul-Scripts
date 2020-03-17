--TODO factors!
local recruitment_factor = "manpower_recruitment" --:string
local unit_size_mode_scalar = CONST.__unit_size_scalar
local weight_peasant = 1
local weight_noble = -11
local weight_monk = 9
local weight_foreign = 2

local bad_order_turn_penalty = 3
local riots_turn_penalty = 5
local low_authority_turn_penalty = 3

local base_boiling_time = 12 
local defuse_rate = 2
local crisis_duration = 8
local foreign_warrior_startpos = Gamedata.base_pop.foreign_warrior_startpos

local foreign_warrior_trait_effects = {
    ["shield_heathen_old_ways"] = -25
} --:map<string, number>

local HEREKING_EFFECTS = {
    [1] = 15,
    [2] = 0,
    [3] = -25,
    [4] = -25,
    [5] = 0,
    [6] = 15
}--:map<number, number>


local MANPOWER_FOREIGN = {} --:map<string, FACTION_RESOURCE>
local FOREIGN_WARRIORS = {
    ["vik_fact_west_seaxe"] = {
        crisis_timer = base_boiling_time,
        last_tension = 0,
        in_crisis = false,
        crisis_level = 1,
        building_modifiers = {},
        events_triggered = {}
    }
} --:map<string, {crisis_timer: int, last_tension: int, in_crisis: boolean, crisis_level: int, building_modifiers: map<string, number>, events_triggered: map<string, map<number, number>>}>


--v function(t: any)
local function log(t)
    dev.log(tostring(t), "FW")
end

--v function(faction_key: string)
local function add_blank_foreign_warrior_entry(faction_key)
    FOREIGN_WARRIORS[faction_key] = {
        crisis_timer = base_boiling_time,
        last_tension = 0,
        in_crisis = false,
        crisis_level = 1,
        building_modifiers = {},
        events_triggered = {}
    }
end

--v function(faction: CA_FACTION) --> number
local function get_turn_penalty(faction)
    local auth = faction:faction_leader():gravitas()
    local penalty = 0
    if auth < 5 then
        penalty = low_authority_turn_penalty
    end
    local low_po = false --:boolean
    for j = 0, faction:region_list():num_items() - 1 do
        local region = faction:region_list():item_at(j)
        if region:is_province_capital() then
            local riot_manager = PettyKingdoms.RiotManager.get(region:name())
            if riot_manager.riot_in_progress then
                return penalty + riots_turn_penalty
            elseif riot_manager:public_order() < 0 then
                low_po = true
            end
        end
    end
    if low_po then
        return penalty + bad_order_turn_penalty
    else
        return penalty
    end
end

--v function(faction: CA_FACTION)
local function process_turn_start(faction)
    local turn = cm:model():turn_number()
    if FOREIGN_WARRIORS[faction:name()].in_crisis then
        FOREIGN_WARRIORS[faction:name()].crisis_timer = FOREIGN_WARRIORS[faction:name()].crisis_timer - 1;
        if FOREIGN_WARRIORS[faction:name()].crisis_timer <= 0 then
            FOREIGN_WARRIORS[faction:name()].in_crisis = false
            if FOREIGN_WARRIORS[faction:name()].crisis_level == 1 then
                FOREIGN_WARRIORS[faction:name()].crisis_level = 2
            end
        end
        --otherwise, do nothing. Events check this table for a true crisis flag to cause events.
        return
    end
    --find base tension
    local peasant_pressure = weight_peasant * PettyKingdoms.FactionResource.get("sw_pop_serf", faction).value 
    local monk_pressure = weight_monk * PettyKingdoms.FactionResource.get("sw_pop_monk", faction).value 
    local foreigner_pressure = weight_foreign * MANPOWER_FOREIGN[faction:name()].value 
    local base_tensions = peasant_pressure + foreigner_pressure + monk_pressure
    for event_key, effect_pair in pairs(FOREIGN_WARRIORS[faction:name()].events_triggered) do
        for effect_quantity, turn_to_remove in pairs(effect_pair) do
            if effect_quantity > 0 and turn < turn_to_remove then
                base_tensions = dev.mround(base_tensions*effect_quantity, 1)
            end
        end
    end
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
        if region:is_province_capital() and region:has_governor() then
            for trait_key, value in pairs(foreign_warrior_trait_effects) do
                if region:governor():has_trait(trait_key) then
                    province_effects[region:province_name()] =  (province_effects[region:province_name()] or 0) + (value/100)
                end
            end
        end
    end
    --apply building and trait effects
    local tensions = base_tensions
    for province, effect in pairs(province_effects) do
        tensions = dev.mround(tensions - ( base_tensions * effect * (province_weights[province]/faction:region_list():num_items()) ), 1)
    end
    --if the faction is from the Great Viking Army, add Here King.
    if faction:subculture() == "vik_sub_cult_anglo_viking" then
        --TODO get here king value
    end
    --apply reduction from nobles
    local noble_pressure = weight_noble * PettyKingdoms.FactionResource.get("sw_pop_noble", faction).value 
    if PettyKingdoms.FactionResource.get("sw_pop_noble", faction).value  > MANPOWER_FOREIGN[faction:name()].value then
        noble_pressure = noble_pressure*2
    end
    for event_key, effect_pair in pairs(FOREIGN_WARRIORS[faction:name()].events_triggered) do
        for effect_quantity, turn_to_remove in pairs(effect_pair) do
            if effect_quantity < 0 and turn < turn_to_remove then
                --noble pressure will be -, effect quantity is also -, we add -1 to avoid a +
                noble_pressure = dev.mround(base_tensions*(effect_quantity*-1), 1)
            elseif turn > turn_to_remove then
                FOREIGN_WARRIORS[faction:name()].events_triggered[event_key] = nil
                break;
            end
        end
    end
    tensions = tensions + noble_pressure
    --apply tensions
    if tensions > 0 then
        FOREIGN_WARRIORS[faction:name()].crisis_timer = FOREIGN_WARRIORS[faction:name()].crisis_timer - 1
    elseif tensions < 0 then
        FOREIGN_WARRIORS[faction:name()].crisis_timer = dev.mround(dev.clamp(FOREIGN_WARRIORS[faction:name()].crisis_timer + defuse_rate, 0, base_boiling_time), 1)
    end
    FOREIGN_WARRIORS[faction:name()].last_tension = tensions
    if FOREIGN_WARRIORS[faction:name()].crisis_timer - get_turn_penalty(faction) <= 0 then
        FOREIGN_WARRIORS[faction:name()].in_crisis = true
        FOREIGN_WARRIORS[faction:name()].crisis_timer = crisis_duration
    end
    --see if crisis needs to escalate automatically.
    if FOREIGN_WARRIORS[faction:name()].crisis_level < 3 and faction:region_list():num_items() > 20 then
        FOREIGN_WARRIORS[faction:name()].crisis_level = 3
    end
end

--v function(resource: FACTION_RESOURCE) --> string
local function value_converter(resource)
    if not FOREIGN_WARRIORS[resource.owning_faction] then
        add_blank_foreign_warrior_entry(resource.owning_faction)
    end
    if resource.value == 0 then
        return "1"
    elseif dev.get_faction(resource.owning_faction):name() == "vik_fact_sudreyar" then
        return "7"
    elseif FOREIGN_WARRIORS[resource.owning_faction].in_crisis then
        local region_count = dev.get_faction(resource.owning_faction):region_list():num_items()
        if FOREIGN_WARRIORS[resource.owning_faction].crisis_level <= 2 then
            return "4"
        elseif FOREIGN_WARRIORS[resource.owning_faction].crisis_level <= 4 then
            return "5"
        else
            return "6"
        end
    elseif FOREIGN_WARRIORS[resource.owning_faction].last_tension > 0 then
        return "3"
    else 
        return "2"
    end
end

dev.first_tick(function(context)
    local human_factions = cm:get_human_factions()

    for i = 1, #human_factions do
        MANPOWER_FOREIGN[human_factions[i]] = PettyKingdoms.FactionResource.new(human_factions[i], "sw_pop_foreign", "population", foreign_warrior_startpos[human_factions[i]] or 0, 30000, {}, value_converter)
        local foreign = MANPOWER_FOREIGN[human_factions[i]]
        foreign.uic_override = {"layout", "top_center_holder", "resources_bar2", "culture_mechanics"} 
        if not FOREIGN_WARRIORS[human_factions[i]] then
            add_blank_foreign_warrior_entry(human_factions[i])
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


    local rec_handler = UIScript.recruitment_handler.add_resource("sw_pop_foreign", function(faction_name)
        return PettyKingdoms.FactionResource.get("sw_pop_foreign", dev.get_faction(faction_name)).value
    end, 
    function(faction_name, quantity)
        PettyKingdoms.FactionResource.get("sw_pop_foreign", dev.get_faction(faction_name)):change_value(quantity, recruitment_factor)
    end, "dy_pop_foreign")
    for k, entry in pairs(Gamedata.unit_info.main_unit_size_caste_info) do
        if Gamedata.unit_info.mercenary_units[k] then
            rec_handler:set_cost_of_unit(entry.unit_key, dev.mround(entry.num_men*unit_size_mode_scalar, 1))
        end
    end
    rec_handler:set_resource_tooltip("Foreign Mercenary and Vikingar units require Foreigner population to recruit")
    rec_handler.image_state = "foreigner"

end)
---{is_dilemma, is_capitals, is_villages, fw_pop_changes, fw_tensions_changes, can_repeat}
local events_regional = {
    sw_foreign_warriors_trial_fair_ = {false, true, false, 
            {}, 
            {[1] = -1.10},
        24},
    sw_foreign_warriors_trial_unfair_ = {false, true, false, 
            {}, 
            {[1] = 1.10},
            24},
    sw_foreign_settlers_conquest_ = {false, false, true, {[1]=120}, {}, 0},
    sw_foreign_settlers_drive_out_ = {true, true, false, {}, {}, 24},
    sw_foreign_settlers_drive_out_here_king_ = {true, true, false, {}, {}, 24},
    sw_foreign_dead_wife_ = {false, false, true, {}, {}, 24},
    sw_foreign_grumpy_neighbours_ = {false, false, true, {}, {}, 24},
    sw_foreign_drunk_brawl_ = {false, true, false, {}, {}, 24},
    sw_foreign_priest_assaulted_ = {false, true, false, {}, {}, 24},
    sw_foreign_sheep_ = {false, false, true, {}, {}, 24},
    sw_foreign_fields_ = {false, false, true, {}, {}, 24},
    sw_foreign_cows_ = {false, false, false, {}, {}, 24},
    sw_foreign_bees_ = {false, true, false, {}, {}, 24},
    sw_foreign_esc_vandalism_ = {false, true, false, {}, {}, 24},
    sw_foreign_esc_tar_and_feather_ = {false, false, true, {}, {}, 24},
    sw_foreign_esc_gothi_ = {false, false, true, {}, {}, 24},
    sw_foreign_church_crafts_ = {false, true, false, {}, {}, 24},
    sw_foreign_mine_ = {false, false, true, {}, {}, 24},
    sw_foreign_soldiers_ = {false, true, false, {}, {}, 24},
    sw_foreign_food_stores_ = {false, true, false, {}, {}, 24},
    sw_foreign_banditry_ = {false, false, true, {}, {}, 24},
    sw_foreign_settlement_ = {false, true, false, {}, {}, 24},
    sw_foreign_spies_ = {false, true, false, {}, {}, 24},
    sw_foreign_plot_governor_ = {true, true, false, {}, {}, 24},
    sw_foreign_displacement_ = {true, true, false, {}, {}, 24},
    sw_foreign_army_ = {false, false, true, {}, {}, 24},
    sw_foreign_oaths_ = {true, true, false, {}, {}, 24},
    sw_foreign_ports_ = {false, true, false, {}, {}, 24}
} --:map<string, {boolean, boolean, boolean, map<int, number>, map<int, number>, int}>

-- local region = context:region() --:CA_REGION
-- local fw =  FOREIGN_WARRIORS[region:owning_faction():name()]
local regional_event_conditions = {
    ["sw_foreign_warriors_trial_fair_"] = function(context) --:WHATEVER
        return false --cannot get this until we implement a different thing.
    end,
    ["sw_foreign_warriors_trial_unfair_"] = function(context) --:WHATEVER
        local region = context:region() --:CA_REGION
        local fw =  FOREIGN_WARRIORS[region:owning_faction():name()]
        local is_human = region:owning_faction():is_human()
        if (not is_human) or (not fw) then
            return false
        end
        local has_building = region:building_superchain_exists("vik_moot_hill") or region:building_superchain_exists("vik_court")
        local has_bonus = not not fw.building_modifiers["vik_moot_hill"] or not not fw.building_modifiers["vik_court"]
        return has_building and fw.in_crisis and fw.crisis_level > 2 and fw.crisis_level < 5 and not has_bonus
    end,
    ["sw_foreign_settlers_conquest_"] = function(context) --:WHATEVER
        return false
    end,
    ["sw_foreign_dead_wife_"] = function(context) --:WHATEVER
        local region = context:region() --:CA_REGION
        local fw =  FOREIGN_WARRIORS[region:owning_faction():name()]
        local is_human = region:owning_faction():is_human()
        if (not is_human) or (not fw) then
            return false
        end
        --we aren't in crisis, but last tension value was negative, we're more than halfway to crisis. 
        return (not fw.in_crisis) and fw.last_tension > 0 and (fw.crisis_timer - get_turn_penalty(region:owning_faction()) <= base_boiling_time/2 ) and fw.crisis_level <= 2
    end,
    ["sw_foreign_grumpy_neighbours_"] = function(context) --:WHATEVER
        local region = context:region() --:CA_REGION
        local fw =  FOREIGN_WARRIORS[region:owning_faction():name()]
        local is_human = region:owning_faction():is_human()
        if (not is_human) or (not fw) then
            return false
        end
        --we aren't in crisis, but last tension value was negative, we're more than halfway to crisis. 
        return (not fw.in_crisis) and fw.last_tension > 0 and (fw.crisis_timer - get_turn_penalty(region:owning_faction()) <= base_boiling_time/2 ) and fw.crisis_level <= 2
    end
}--:map<string, (function(context: WHATEVER) --> boolean)>

dev.first_tick(function(context)
    if CONST.__testcases.__test_foreigner_events then
        for event_key, event_details in pairs(events_regional) do
            if regional_event_conditions[event_key] then
                log("Adding Foreign Warrior Event to regional event handler: "..event_key)
                dev.Events.add_regional_event(event_key, event_details[2], event_details[3], event_details[1], function(context) log("During testing, conditon for: "..event_key.." is returning: "..tostring(regional_event_conditions[event_key])) return true end,
                1, event_details[6])

            end
        end 
        return 
    end
    for event_key, event_details in pairs(events_regional) do
        if regional_event_conditions[event_key] then
            log("Adding Foreign Warrior Event to regional event handler: "..event_key)
            dev.Events.add_regional_event(
                event_key,
                event_details[2],
                event_details[3], 
                event_details[1], 
                function(context)
                    local region = context:region() --:CA_REGION
                    return ((event_details[2] and region:is_province_capital()) or (event_details[3] and not region:is_province_capital())) and regional_event_conditions[event_key](context)
                end, 
                3, 
                event_details[6],
                function(context) --:WHATEVER
                    local region_key = string.gsub(context:dilemma(), event_key, "")
                    local faction_name = dev.get_region(region_key):owning_faction():name()
                    local num = 1
                    if event_details[1] then
                        num = num + context:choice()
                    end
                    if not not event_details[4][num] then
                        PettyKingdoms.FactionResource.get("sw_pop_foreign", dev.get_faction(faction_name)):change_value(event_details[4][num])
                    end
                    if not not event_details[5][num] then
                        FOREIGN_WARRIORS[faction_name].events_triggered[event_key] = {[event_details[5][num]] = cm:model():turn_number() + 10}
                    end
                end)
    
        end
    end 
    dev.eh:add_listener(
        "RegionChangesOwnership",
        "RegionChangesOwnership",
        function(context)
            return context:region():owning_faction():is_human() and cm:model():turn_number() - dev.Events.last_event_occurance("sw_foreign_settlers_conquest_") > 2
        end,
        function(context)
            local turn_diff = dev.clamp(cm:model():turn_number() - dev.Events.last_event_occurance("sw_foreign_settlers_conquest_"), 1, 8)
            local chance = 50 - dev.mround(40/turn_diff, 1)
            if dev.Check.is_faction_viking_faction(context:prev_faction()) then
                chance = chance + 40
            elseif context:prev_faction():subculture() == "vik_sub_cult_welsh" then
                chance = dev.mround(chance/4, 1)
            end
            log("Conquest event chance: "..tostring(chance))
            if cm:random_number(100) < chance then
                dev.Events.force_regional_event("sw_foreign_settlers_conquest_", context:region():name(), context:region():owning_faction():name())
            end
        end,
        true
    )
end)


local events_characters = {

}







local events_generic = {

}