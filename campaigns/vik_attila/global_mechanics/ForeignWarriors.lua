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

} --:map<string, {crisis_timer: int, last_tension: int, in_crisis: boolean, crisis_has_fired: boolean, crisis_level: int, building_modifiers: map<string, number>, events_triggered: map<string, {number, number, number}>}>

dev.Save.persist_table(FOREIGN_WARRIORS, "FOREIGN_WARRIORS_T", function(t) FOREIGN_WARRIORS = t end)
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
        crisis_has_fired = false,
        crisis_level = 0,
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
    log("Processing turn "..tostring(turn).." for faction "..faction:name())
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
    for event_key, details in pairs(FOREIGN_WARRIORS[faction:name()].events_triggered) do
        local effect_quantity = details[1]
        local turn_to_remove = details[2] + 10;
        if effect_quantity > 0 and turn < turn_to_remove then
            base_tensions = dev.mround(base_tensions*effect_quantity, 1)
        end
    end
    log("Base Tension: "..tostring(base_tensions))
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
        tensions = dev.mround(tensions + ( base_tensions * effect * (province_weights[province]/faction:region_list():num_items()) ), 1)
    end
    --if the faction is from the Great Viking Army, add Here King.
    if faction:subculture() == "vik_sub_cult_anglo_viking" then
        if faction:has_effect_bundle("vik_here_king_english_1") or faction:has_effect_bundle("vik_here_king_army_1") then
            tensions = dev.mround(tensions + (base_tensions*-0.25), 1)
        elseif faction:has_effect_bundle("vik_here_king_english_2") or faction:has_effect_bundle("vik_here_king_army_2") then
            tensions = dev.mround(tensions + (base_tensions*-0.1), 1)
        elseif faction:has_effect_bundle("vik_here_king_english_3") or faction:has_effect_bundle("vik_here_king_army_3") then
            tensions = dev.mround(tensions + (base_tensions*0.15), 1)
        end
    end
    --if the faction is East Engle and at Peace, increase tensions:
    if faction:name() == "vik_fact_east_engle" then
        local at_war = false --:boolean
        for w = 0, faction:factions_at_war_with():num_items() - 1 do
            at_war = true
            break
        end
        if not at_war then
            tensions = dev.mround(tensions + (base_tensions*0.25), 1)
        end
    end
    log("Tensions before reductions: "..tostring(tensions))
    --apply reduction from nobles
    local noble_pressure = weight_noble * PettyKingdoms.FactionResource.get("sw_pop_noble", faction).value 
    if PettyKingdoms.FactionResource.get("sw_pop_noble", faction).value  > MANPOWER_FOREIGN[faction:name()].value then
        noble_pressure = noble_pressure*2
    end
    for event_key, details in pairs(FOREIGN_WARRIORS[faction:name()].events_triggered) do
        local effect_quantity = details[1]
        local turn_to_remove = details[2] + 10;
        if effect_quantity < 0 and turn < turn_to_remove then
            --noble pressure will be -, effect quantity is also -, we add -1 to avoid a +
            noble_pressure = dev.mround(base_tensions*(effect_quantity*-1), 1)
        elseif turn > turn_to_remove then
            FOREIGN_WARRIORS[faction:name()].events_triggered[event_key] = nil
            break;
        end
    end
    tensions = tensions + noble_pressure
    log("Final net tension: "..tostring(tensions))
    --apply tensions
    if not FOREIGN_WARRIORS[faction:name()].in_crisis then
        if tensions > 0 then
            FOREIGN_WARRIORS[faction:name()].crisis_timer = FOREIGN_WARRIORS[faction:name()].crisis_timer - 1
        elseif tensions < 0 then
            FOREIGN_WARRIORS[faction:name()].crisis_timer = dev.mround(dev.clamp(FOREIGN_WARRIORS[faction:name()].crisis_timer + defuse_rate, 0, base_boiling_time), 1)
        end
    end
    FOREIGN_WARRIORS[faction:name()].last_tension = tensions
    if FOREIGN_WARRIORS[faction:name()].crisis_timer - get_turn_penalty(faction) <= 0 then
        log("Starting Crisis for this faction")
        FOREIGN_WARRIORS[faction:name()].in_crisis = true
        FOREIGN_WARRIORS[faction:name()].crisis_has_fired = false
        FOREIGN_WARRIORS[faction:name()].crisis_timer = crisis_duration
    end
    log("Crisis Timer: "..tostring(FOREIGN_WARRIORS[faction:name()].crisis_timer))
    log("Crisis Level "..tostring(FOREIGN_WARRIORS[faction:name()].crisis_level))
    MANPOWER_FOREIGN[faction:name()]:reapply()
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
        PettyKingdoms.FactionResource.get("sw_pop_foreign", dev.get_faction(faction_name)):change_value(quantity)
    end, "dy_pop_foreign")
    for k, entry in pairs(Gamedata.unit_info.main_unit_size_caste_info) do
        if Gamedata.unit_info.mercenary_units[k] then
            rec_handler:set_cost_of_unit(entry.unit_key, dev.mround(entry.num_men*unit_size_mode_scalar, 1))
        end
    end
    rec_handler:set_resource_tooltip("Foreign Mercenary and Vikingar units require Foreigner population to recruit")
    rec_handler.image_state = "foreigner"

end)

local events = dev.GameEvents
local events_regional = {
    sw_foreign_bees_ = {
        event_type = "incident",
        group = {"ProvinceCapitals", "GenericForeignWarriors"}
    },
    sw_foreign_soldiers_ = {
        event_type = "incident",
        group = {"ProvinceCapitals", "GenericForeignWarriorsMid"},
        callback = function(context) --:WHATEVER

        end
    },
    sw_foreign_warriors_trial_fair_ = {
        event_type = "incident",
        group = {"ProvinceCapitals"}
    },
    sw_foreign_esc_gothi_ = {
        event_type = "incident",
        group = {"NotProvinceCapitals", "EscalationsForeignWarriorsLate"},
        callback = function(context) --:WHATEVER
            local faction = context:faction() --:CA_FACTION
            local fw = FOREIGN_WARRIORS[faction:name()] 
            fw.crisis_level = fw.crisis_level + 1
        end
    },
    sw_foreign_oaths_ = {
        event_type = "dilemma",
        group = {"ProvinceCapitals", "IsSaxonFaction", "GenericForeignWarriorsMid"},
        callback = function(context) --:WHATEVER

        end
    },
    sw_foreign_cows_ = {
        event_type = "incident",
        group = {"ProvinceCapitals", "GenericForeignWarriors"}
    },
    sw_foreign_fields_ = {
        event_type = "incident",
        group = {"NotProvinceCapitals", "GenericForeignWarriors"}
    },
    sw_foreign_settlement_ = {
        event_type = "incident",
        group = {"ProvinceCapitals", "GenericForeignWarriorsLate"}
    },
    sw_foreign_displacement_ = {
        event_type = "dilemma",
        group = {"ProvinceCapitals"},
        callback = function(context) --:WHATEVER

        end
    },
    sw_foreign_dead_wife_ = {
        event_type = "incident",
        group = {"NotProvinceCapitals", "EscalationsForeignWarriorsEarly"},
        callback = function(context) --:WHATEVER
            local faction = context:faction() --:CA_FACTION
            local fw = FOREIGN_WARRIORS[faction:name()] 
            fw.crisis_level = fw.crisis_level + 1
        end
    },
    sw_foreign_banditry_ = {
        event_type = "incident",
        group = {"NotProvinceCapitals", "GenericForeignWarriorsMid"}
    },
    sw_foreign_warriors_trial_unfair_ = {
        event_type = "incident",
        group = {"ProvinceCapitals", "GenericForeignWarriors"}
    },
    sw_foreign_grumpy_neighbours_ = {
        event_type = "incident",
        group = {"NotProvinceCapitals", "EscalationsForeignWarriorsEarly"},
        callback = function(context) --:WHATEVER
            local faction = context:faction() --:CA_FACTION
            local fw = FOREIGN_WARRIORS[faction:name()] 
            fw.crisis_level = fw.crisis_level + 1
        end
    },
    sw_foreign_food_stores_ = {
        event_type = "incident",
        group = {"ProvinceCapitals", "GenericForeignWarriors"},
        callback = function(context) --:WHATEVER
            local region = context:region() --:CA_REGION
            PettyKingdoms.FoodStorage.get(region:owning_faction():name()):lose_food_from_region(region)
        end
    },
    sw_foreign_army_ = {
        event_type = "incident",
        group = {"NotProvinceCapitals"} 
        --",GenericForeignWarriorsMid"},        callback = function(context) --:WHATEVER

        --end
    },
    sw_foreign_esc_tar_and_feather_ = {
        event_type = "incident",
        group = {"NotProvinceCapitals", "EscalationsForeignWarriorsLate"},
        callback = function(context) --:WHATEVER
            local faction = context:faction() --:CA_FACTION
            local fw = FOREIGN_WARRIORS[faction:name()] 
            fw.crisis_level = fw.crisis_level + 1
        end
    },
    sw_foreign_ports_ = {
        event_type = "incident",
        group = {"ProvinceCapitals", "GenericForeignWarriorsLate"}
    },
    sw_foreign_spies_ = {
        event_type = "incident",
        group = {"ProvinceCapitals", "GenericForeignWarriorsLate"}
    },
    sw_foreign_settlers_drive_out_ = {
        event_type = "dilemma",
        group = {"ProvinceCapitals"},
        callback = function(context) --:WHATEVER

        end
    },
    sw_foreign_plot_governor_ = {
        event_type = "dilemma",
        group = {"ProvinceCapitals", "GenericForeignWarriorsLate"},
        callback = function(context) --:WHATEVER

        end
    },
    sw_foreign_esc_vandalism_ = {
        event_type = "incident",
        group = {"ProvinceCapitals", "EscalationsForeignWarriorsLate"},
        callback = function(context) --:WHATEVER
            local faction = context:faction() --:CA_FACTION
            local fw = FOREIGN_WARRIORS[faction:name()] 
            fw.crisis_level = fw.crisis_level + 1
        end
    },
    sw_foreign_church_crafts_ = {
        event_type = "incident",
        group = {"ProvinceCapitals", "GenericForeignWarriorsMid"}
    },
    sw_foreign_settlers_drive_out_here_king_ = {
        event_type = "dilemma",
        group = {"ProvinceCapitals"},
        callback = function(context) --:WHATEVER

        end
    },
    sw_foreign_sheep_ = {
        event_type = "incident",
        group = {"NotProvinceCapitals", "GenericForeignWarriors"}
    },
    sw_foreign_drunk_brawl_ = {
        event_type = "incident",
        group = {"ProvinceCapitals", "GenericForeignWarriors"}
    },
    sw_foreign_priest_assaulted_ = {
        event_type = "incident",
        group = {"ProvinceCapitals", "GenericForeignWarriors"}
    },
    sw_foreign_mine_ = {
        event_type = "incident",
        group = {"NotProvinceCapitals", "GenericForeignWarriors"}
    },
} --:map<string, {event_type: GAME_EVENT_TYPE, group: vector<string>, callback: (function(context: WHATEVER))?}>

-- local region = context:region() --:CA_REGION
-- local fw =  FOREIGN_WARRIORS[region:owning_faction():name()]
local regional_event_conditions = {
    ["sw_foreign_warriors_trial_fair_"] = function(context) --:WHATEVER
        return false --cannot get this until we implement a different thing.
    end,
    ["sw_foreign_warriors_trial_unfair_"] = function(context) --:WHATEVER
        local region = context:region() --:CA_REGION
        local fw =  FOREIGN_WARRIORS[region:owning_faction():name()]
        local has_building = region:building_superchain_exists("vik_moot_hill") or region:building_superchain_exists("vik_court")
        local has_bonus = not not fw.building_modifiers["vik_moot_hill"] or not not fw.building_modifiers["vik_court"]
        return has_building and not has_bonus
    end,
    ["sw_foreign_cows_"] = function(context) --:WHATEVER
        local region = context:region() --:CA_REGION
        local has_building = region:building_superchain_exists("vik_pasture")
        return has_building 
    end,
    ["sw_foreign_sheep_"] = function(context) --:WHATEVER
        local region = context:region() --:CA_REGION
        local has_building = region:building_exists("vik_cloth_2") or region:building_exists("vik_cloth_3")
        return has_building 
    end,
    ["sw_foreign_drunk_brawl_"] = function(context) --:WHATEVER
        local region = context:region() --:CA_REGION
        local has_building = region:building_superchain_exists("vik_alehouse") 
        return has_building 
    end,
    ["sw_foreign_priest_assaulted_"] = function(context) --:WHATEVER
        local region = context:region() --:CA_REGION
        local has_building = region:building_superchain_exists("vik_church") or region:building_superchain_exists("vik_monastery")
        --we are in crisis at level 1-3
        return  has_building
    end,
    ["sw_foreign_fields_"] = function(context) --:WHATEVER
        local region = context:region() --:CA_REGION
        local has_building = region:building_superchain_exists("vik_farm")
        return has_building 
    end,
    ["sw_foreign_spies_"] = function(context) --:WHATEVER
        --TODO at war with vikings
        return false
    end,
    ["sw_foreign_plot_governor_"] = function(context) --:WHATEVER
        --TODO disloyal gov with viking ways, or just being a viking
        return false
    end
}--:map<string, (function(context: WHATEVER) --> boolean)>

dev.first_tick(function(context)
    --first step is to register each condition group
    --generic group for all events
    local event_group_general = events:create_new_condition_group("GenericForeignWarriors", function(context)
        local region = context:region()
        local fw =  FOREIGN_WARRIORS[region:owning_faction():name()]
        return fw.in_crisis and fw.crisis_level > 0
     end)
    events:register_condition_group(event_group_general, "RegionTurnStart")
    --events which start in the midgame
    local event_group_general_mid = events:create_new_condition_group("GenericForeignWarriorsMid", function(context)
        local region = context:region()
        local fw =  FOREIGN_WARRIORS[region:owning_faction():name()]
        return fw.in_crisis and fw.crisis_level > 2 
    end)
    events:register_condition_group(event_group_general_mid, "RegionTurnStart")
    --lategame only events
    local event_group_general_late = events:create_new_condition_group("GenericForeignWarriorsLate", function(context)
        local region = context:region()
        local fw =  FOREIGN_WARRIORS[region:owning_faction():name()]
        return fw.in_crisis and fw.crisis_level > 4 
    end)
    events:register_condition_group(event_group_general_late, "RegionTurnStart")
    --escalation events for earlier
    local escalation_events_early = events:create_new_condition_group("EscalationsForeignWarriorsEarly", function(context)
        local region = context:region()
        local fw =  FOREIGN_WARRIORS[region:owning_faction():name()]
        return fw.in_crisis and fw.crisis_level < 2 
     end)
    escalation_events_early:set_cooldown(8)
    escalation_events_early:set_number_allowed_in_queue(1)
    events:register_condition_group(escalation_events_early, "RegionTurnStart")
    --escalation events once the system has "kicked off"
    local escalation_events_late = events:create_new_condition_group("EscalationsForeignWarriorsLate", function(context)
        local region = context:region()
        local fw =  FOREIGN_WARRIORS[region:owning_faction():name()]
        return fw.in_crisis and fw.crisis_level >= 2 
     end)
    escalation_events_late:set_cooldown(8)
    escalation_events_late:set_number_allowed_in_queue(1)
    events:register_condition_group(escalation_events_late, "RegionTurnStart")
    --step two, adding all the events
    --loop through events and construct, adding conditions and callbacks where found
    for event_key, event_details in pairs(events_regional) do
        log("Adding Foreign Warrior Event to regional event handler: "..event_key)
        local current = events:create_event(event_key, event_details.event_type, "concatenate_region")
        if regional_event_conditions[event_key] then
            current:add_queue_time_condition(regional_event_conditions[event_key])
        end
        current:set_cooldown(6)
        current:set_number_allowed_in_queue(1)
        if event_details.callback then
            --# assume event_details.callback: function(context: WHATEVER)
            current:add_callback(event_details.callback)
        end
        for i = 1, #event_details.group do
            current:join_group(event_details.group[i])
        end
    end 
    --step three, add the conquest event and set it up
    local conquest_event = events:create_event("sw_foreign_settlers_conquest_", "incident", "concatenate_region")
    conquest_event:set_cooldown(5)
    conquest_event:add_callback(function(context) 
        local faction = context:faction() --:CA_FACTION
        local resource = PettyKingdoms.FactionResource.get("sw_pop_foreign", faction)
        resource:change_value(120)
    end)
    --TODO post capture events should be formalized into a second queue system. This will suck.
    dev.eh:add_listener(
        "RegionChangesOwnership",
        "RegionChangesOwnership",
        function(context)
            return context:region():owning_faction():is_human() and (not context:region():is_province_capital())
        end,
        function(context)
            local chance = 30
            if dev.Check.is_faction_viking_faction(context:prev_faction()) then
                chance = chance + 40
            elseif context:prev_faction():subculture() == "vik_sub_cult_welsh" then
                chance = dev.mround(chance/4, 1)
            end
            log("Conquest event chance: "..tostring(chance))
            if dev.chance(chance) then
                local region = context:region()
                local context = events:build_context_for_event("sw_foreign_settlers_conquest_", region, region:owning_faction())
                events:force_check_and_trigger_event_immediately("sw_foreign_settlers_conquest_", context)
            end
        end,
        true)
end)