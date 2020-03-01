local riot_events = {
    {
        name = "sw_rebellion_rioting_household_guard_",
        condition = function(riot_manager) --:RIOT_MANAGER
            local region = dev.get_region(riot_manager.key)
            return region:has_governor() and cm:random_number(100) > 50 and dev.Check.does_char_have_household_guard(region:governor())
        end,
        response = function(context) --:WHATEVER
            cm:set_saved_value(context:dilemma(), cm:model():turn_number())
            local region_key = string.gsub(context:dilemma(), "sw_rebellion_rioting_household_guard_", "")
            if context:choice() == 1 then
                --TODO reduce peasant manpower
            end
        end,
        is_dilemma = true
    },
    {
        name = "sw_rebellion_bad_governor_",
        condition = function(riot_manager) --:RIOT_MANAGER
            local region = dev.get_region(riot_manager.key)
            return region:has_governor() and cm:random_number(100) > 33 and not dev.Check.does_char_have_household_guard(region:governor())
        end,
        response = function(context) --:WHATEVER
            cm:set_saved_value(context:dilemma(), cm:model():turn_number())
            local region_key = string.gsub(context:dilemma(), "sw_rebellion_bad_governor_", "")
            local region = dev.get_region(region_key)
            local gov = region:governor():command_queue_index()
            cm:kill_character("character_cqi:"..tostring(gov), false, true)
        end,
        is_dilemma = false
    },
    {
        name = "sw_rebellion_food_stores_",
        condition = function(riot_manager) --:RIOT_MANAGER
            local region = dev.get_region(riot_manager.key)
            return PettyKingdoms.FoodStorage.get(region:owning_faction():name()):does_region_have_food_storage(region)
        end,
        response = function(context) --:WHATEVER
            cm:set_saved_value(context:dilemma(), cm:model():turn_number())
            local region_key = string.gsub(context:dilemma(), "sw_rebellion_food_stores_", "")
            local region = dev.get_region(region_key)
            PettyKingdoms.FoodStorage.get(region:owning_faction():name()):lose_food_from_region(region)
        end,
        is_dilemma = false
    },
    {
        name = "sw_rebellion_lost_clergy_",
        condition = function(riot_manager) --:RIOT_MANAGER
            local region = PettyKingdoms.RegionManpower.get(riot_manager.key)
            return region.monk_pop > 0 
        end,
        response = function(context) --:WHATEVER
            cm:set_saved_value(context:dilemma(), cm:model():turn_number())
            local region_key = string.gsub(context:dilemma(), "sw_rebellion_lost_clergy_", "")
            local region = dev.get_region(region_key)
            local loss = dev.clamp(PettyKingdoms.RegionManpower.get(region_key).monk_pop * -0.5, -40, 0)
            PettyKingdoms.RegionManpower.get(region_key):mod_monks(dev.mround(loss, 1), true, "monk_riots")
        end,
        is_dilemma = false
    },
    {
        name = "sw_rebellion_lost_nobles_",
        condition = function(riot_manager) --:RIOT_MANAGER
           
            local all_regions_in_province = Gamedata.regions.get_regions_in_regions_province(riot_manager.key)
            local retval = false --:boolean
            for i = 1, #all_regions_in_province do
                local region = PettyKingdoms.RegionManpower.get(riot_manager.key)
                if region.estate_lord_bonus and region.estate_lord_bonus > 0 then
                    return true
                end
            end
            return retval
        end,
        response = function(context) --:WHATEVER
            local region_key = string.gsub(context:dilemma(), "sw_rebellion_lost_nobles_", "")
            local region = PettyKingdoms.RegionManpower.get(region_key)
            region:mod_population_through_region(-20, "manpower_riots", false, true)
        end,
        is_dilemma = false
    },
    {
        name = "shield_rebellion_corruption_",
        condition = function(riot_manager) --:RIOT_MANAGER
            local region = dev.get_region(riot_manager.key)
            local eligible = region:has_governor() and not region:governor():has_trait("shield_brute_corrupt") 
            local allegiance = (region:majority_religion() == "vik_religion_banditry") or (not not string.find(region:majority_religion(), "usurper"))
            return eligible and allegiance
        end,
        response = function(context) --:WHATEVER
            cm:set_saved_value(context:dilemma(), cm:model():turn_number())
            local region_key = string.gsub(context:dilemma(), "shield_rebellion_corruption_", "")
            local region = dev.get_region(region_key)
            if not region:governor():has_trait("shield_brute_corrupt")  then
                dev.add_trait(region:governor(), "sheild_brute_corrupt", true)
            end
        end,
        is_dilemma = false
    },
    {
        name = "shield_rebellion_become_berserker_",
        condition = function(riot_manager) --:RIOT_MANAGER
            local region = dev.get_region(riot_manager.key)
            local governor_elible = region:has_governor() and region:governor():has_trait("shield_heathen_pagan")
            local chance = 25
            if governor_elible and region:governor():has_trait("shield_warrior_champion") or region:governor():has_trait("shield_warrior_proven_warrior") then
                chance = chance + 25
            end
            if governor_elible and region:governor():has_trait("shield_heathen_beast_slayer") then
                chance = chance + 15
            end
            if governor_elible and region:governor():has_trait("shield_brute_bloodythirsty") then
                chance = chance + 15
            end
            return governor_elible and cm:random_number(100) <= chance
        end,
        response = function(context) --:WHATEVER
            cm:set_saved_value(context:dilemma(), cm:model():turn_number())
            local region_key = string.gsub(context:dilemma(), "shield_rebellion_become_berserker_", "")
            local region = dev.get_region(region_key)
            local trait = "shield_heathen_legendary_wolfskin"
            if region:owning_faction():subculture() == "vik_sub_cult_anglo_viking" then
                trait = "shield_heathen_legendary_bearskin"
            end
            if not region:governor():has_trait(trait)  then
                dev.add_trait(region:governor(), trait, true)
            end
        end,
        is_dilemma = false
    }
}--:vector<{name: string, condition: (function(rioting_region: RIOT_MANAGER) --> boolean), response: (function(context: WHATEVER)), is_dilemma: boolean}>

local riot_manager = PettyKingdoms.RiotManager
for i = 1, #riot_events do
    local event = riot_events[i]
    riot_manager.add_event(event.name, event.condition, event.response, event.is_dilemma)
end