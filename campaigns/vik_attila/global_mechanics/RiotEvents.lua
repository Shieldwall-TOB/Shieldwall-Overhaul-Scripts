local riot_events = {
    {
        name = "sw_rebellion_rioting_household_guard_",
        condition = function(context) --:WHATEVER
            local region = context:region()
            return region:has_governor() and dev.chance(50) and dev.Check.does_char_have_household_guard(region:governor()) == true
        end,
        response = function(context) --:WHATEVER
            local region = context:region() --:CA_REGION
            if context:choice() == 1 then
                --TODO reduce peasant manpower
            end
        end,
        is_dilemma = true
    },
    {
        name = "sw_rebellion_bad_governor_",
        condition = function(context) --:WHATEVER
            local region = context:region()
            return region:has_governor() and dev.chance(33) and dev.Check.does_char_have_household_guard(region:governor()) == false and region:governor():has_trait("shield_elder_beloved") == false
        end,
        response = function(context) --:WHATEVER
            local region = context:region() --:CA_REGION
            local gov = region:governor():command_queue_index()
            cm:kill_character("character_cqi:"..tostring(gov), false, true)
        end,
        is_dilemma = false
    },
    {
        name = "sw_rebellion_food_stores_",
        condition = function(context) --:WHATEVER
            local region = context:region()
            return PettyKingdoms.FoodStorage.get(region:owning_faction():name()):does_region_have_food_storage(region)
        end,
        response = function(context) --:WHATEVER
            local region = context:region() --:CA_REGION
            PettyKingdoms.FoodStorage.get(region:owning_faction():name()):lose_food_from_region(region)
        end,
        is_dilemma = false
    },
    {
        name = "sw_rebellion_lost_clergy_",
        condition = function(context) --:WHATEVER
            local region = PettyKingdoms.RegionManpower.get(context:region():name())
            return region.monk_pop > 0 
        end,
        response = function(context) --:WHATEVER
            local region = context:region() --:CA_REGION
            local loss = dev.clamp(PettyKingdoms.RegionManpower.get(region:name()).monk_pop * -0.5, -40, 0)
            PettyKingdoms.RegionManpower.get(region:name()):mod_monks(dev.mround(loss, 1), true, "monk_riots")
        end,
        is_dilemma = false
    },
    {
        name = "sw_rebellion_lost_nobles_",
        condition = function(context) --:WHATEVER
           
            local all_regions_in_province = Gamedata.regions.get_regions_in_regions_province(context:region():name())
            local retval = false --:boolean
            for i = 1, #all_regions_in_province do
                local region = PettyKingdoms.RegionManpower.get(context:region():name())
                if region.estate_lord_bonus and region.estate_lord_bonus > 0 then
                    return true
                end
            end
            return retval
        end,
        response = function(context) --:WHATEVER
            local region_key = context:region():name() --:string
            local region = PettyKingdoms.RegionManpower.get(region_key)
            region:mod_population_through_region(-20, "manpower_riots", false, true)
        end,
        is_dilemma = false
    },
    {
        name = "shield_rebellion_corruption_",
        condition = function(context) --:WHATEVER
            local region = context:region()
            local eligible = region:has_governor() and not region:governor():has_trait("shield_brute_corrupt") 
            local allegiance = (region:majority_religion() == "vik_religion_banditry") or (not not string.find(region:majority_religion(), "usurper"))
            return eligible and allegiance
        end,
        response = function(context) --:WHATEVER
            local region = context:region() --:CA_REGION
            if not region:governor():has_trait("shield_brute_corrupt")  then
                dev.add_trait(region:governor(), "sheild_brute_corrupt", true)
            end
        end,
        is_dilemma = false
    },
    {
        name = "shield_rebellion_become_berserker_",
        condition = function(context) --:WHATEVER
            local region = context:region() --:CA_REGION
            local governor = context:governor() --: CA_CHAR
            local governor_eligible = governor and governor:has_trait("shield_heathen_pagan")
            local chance = 25
            if governor_eligible and (region:governor():has_trait("shield_warrior_champion") or region:governor():has_trait("shield_warrior_proven_warrior")) then
                chance = chance + 25
            end
            if governor_eligible and region:governor():has_trait("shield_heathen_beast_slayer") then
                chance = chance + 15
            end
            if governor_eligible and region:governor():has_trait("shield_brute_bloodythirsty") then
                chance = chance + 15
            end
            return governor_eligible and cm:random_number(100) <= chance
        end,
        response = function(context) --:WHATEVER
            local region = context:region() --:CA_REGION
            local trait = "shield_heathen_legendary_wolfskin"
            if region:owning_faction():subculture() == "vik_sub_cult_anglo_viking" then
                trait = "shield_heathen_legendary_bearskin"
            end
            if not region:governor():has_trait(trait)  then
                dev.add_trait(region:governor(), trait, true)
            end
        end,
        is_dilemma = false
    },
    {
        name = "sw_rebellion_henchmen_",
        condition = function(context) --:WHATEVER
            local region = context:region()
            return region:has_governor() and cm:random_number(100) > 50 and dev.Check.does_char_have_household_guard(region:governor()) == true
        end,
        response = function(context) --:WHATEVER
            local region = context:region() --:CA_REGION
            if context:choice() == 0 then
                local region_manpower = PettyKingdoms.RegionManpower.get(region:name())
                region_manpower:mod_population_through_region(-20, "manpower_riots", true, false)
            end
        end,
        is_dilemma = true
    }
}--:vector<{name: string, condition: (function(context: WHATEVER) --> boolean), response: (function(context: WHATEVER)), is_dilemma: boolean}>

dev.first_tick(function(context)
    local riot_manager = PettyKingdoms.RiotManager
    local event_manager = dev.GameEvents

    local StandardRiotEvents = event_manager:create_new_condition_group("StandardRiotEvent", function(context)
        local rm = riot_manager.get(context:region():name())
        local is_rioting = rm.riot_in_progress
        local is_off_cd = rm.riot_event_cooldown == 0 
        return is_rioting and (is_off_cd or CONST.__testcases.__test_riots)
    end) 
    StandardRiotEvents:set_number_allowed_in_queue(3)
    StandardRiotEvents:add_callback(function(context)
        local rm = riot_manager.get(context:region():name())
        rm.riot_event_cooldown = 2
    end)
    event_manager:register_condition_group(StandardRiotEvents, "RegionTurnStart")

    for i = 1, #riot_events do
        local event_info = riot_events[i]
        local event_type = "incident" --:GAME_EVENT_TYPE
        if event_info.is_dilemma then
            event_type = "dilemma" 
        end
        local event = event_manager:create_event(event_info.name, event_type, "concatenate_region")
        event:set_number_allowed_in_queue(1)
        event:add_queue_time_condition(event_info.condition)
        if CONST.__testcases.__test_riots then
            event:add_queue_time_condition(function(context)
                local result = events_info.condition(context)
                dev.log("Test for riot event: "..event_info.name.." resulted in ".. tostring(result), "__test_riots")
                return true
            end)
        end
        event:add_callback(event_info.response)
        event:join_groups("ProvinceCapitals", "StandardRiotEvent")
    end
end)