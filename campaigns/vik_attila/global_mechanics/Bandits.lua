BANDITS = {} --:map<string,CA_CQI>
BANDIT_ID = 0 --:number
local bandit_faction = "vik_fact_jorvik"
local raid_stance = "MILITARY_FORCE_ACTIVE_STANCE_TYPE_LAND_RAID"
local bandit_spawns = Gamedata.spawn_locations.BanditSpawns
local events = dev.GameEvents
local bandit_spawn_event = "sw_rebellion_bandits_" --:string


--v function(region: CA_REGION) --> boolean
local function is_owned_force_nearby(region)
    local check_list = {}--:map<string, boolean>
    check_list[region:name()] = true
    for j = 0, region:adjacent_region_list():num_items() - 1 do
        check_list[region:adjacent_region_list():item_at(j):name()] = true
    end
    local char_list = region:owning_faction():character_list()
    for j = 0, char_list:num_items() - 1 do
        local current = char_list:item_at(j)
        if dev.is_char_normal_general(current) then
            if not current:region():is_null_interface() then
                if check_list[current:region():name()] then
                    return true
                end
            end
        end
    end
    return false
end

--v function(region: CA_REGION) --> CA_CQI
local function is_bandit_force_nearby(region)
    local faction_character_list = dev.get_faction(bandit_faction):character_list()
    for i = 0, faction_character_list:num_items() - 1 do
        local character = faction_character_list:item_at(i)
        if dev.is_char_normal_general(character) then
            if not character:region():is_null_interface() and character:region():name() == region:name() then
                return character:command_queue_index()
            end
        end
    end
    return nil
end

dev.first_tick(function(context)

    events:create_event(bandit_spawn_event, "incident", "concatenate_region")

    dev.eh:add_listener(
        "RegionTurnEndBanditSpawnCheck",
        "RegionTurnEnd",
        function(context)
            if context:region():owning_faction():is_null_interface() or context:region():is_province_capital() then
                return false
            end
            if dev.get_faction("vik_fact_west_seaxe"):is_human() and not cm:get_saved_value("start_mission_done_west_seaxe") then
                return false
            end
            if not context:region():owning_faction():is_human() then
                return false
            end
            dev.log("Evaluating bandit spawn potential in "..context:region():name(), "BANDIT")
            local majority_religion = context:region():majority_religion() == "vik_religion_banditry" 
            local no_forces_nearby = (not is_owned_force_nearby(context:region()))
            local region_has_spawner = (not not bandit_spawns[context:region():name()])
            dev.log("Region has spawner: ["..tostring(region_has_spawner).."], forces nearby: ["..tostring(no_forces_nearby).."], has_bandit_religion: ["..tostring(majority_religion).."]", "BANDIT")
            return no_forces_nearby and region_has_spawner and majority_religion
        end,
        function(context)
            local region = context:region()
            local owner = region:owning_faction()
            if not not BANDITS[region:name()] then
            --bandits already exist here 
                local bandit_cqi = tonumber(BANDITS[region:name()])  
                --# assume bandit_cqi: CA_CQI
                local bandit_general = dev.get_character(bandit_cqi)
                if not bandit_general then
                    --he's probably ded.
                    BANDITS[region:name()] = nil
                end
                return    
            end
            --double check if we have bandits here already
            local nearby_bandit = is_bandit_force_nearby(region)
            if not not nearby_bandit then
                BANDITS[region:name()] = nearby_bandit
                return
            end
            local num_units_to_add = 2
            -- Sets the number of invading armies based upon difficulty settings
            local difficulty = cm:model():difficulty_level();
            if  difficulty == -1 then -- Hard
                num_units_to_add = 3
            elseif difficulty == -2 then -- Very Hard
                num_units_to_add = 4
            elseif difficulty == -3 then -- Legendary
                num_units_to_add = 4
            end
            local bandit_army = "wel_valley_spearmen,wel_valley_spearmen,dan_fyrd_archers"
            local random_add = {"dan_fyrd_archers", "wel_valley_spearmen", "est_fighters", "est_fighters", "dan_ceorl_javelinmen", "dan_ceorl_javelinmen", "est_mailed_horsemen"} --:vector<string>
            for i = 1, num_units_to_add do 
                bandit_army = bandit_army .. "," .. random_add[cm:random_number(#random_add)]
            end
            BANDIT_ID = BANDIT_ID + 1
            local ID = "bandit_spawn_"..BANDIT_ID
            cm:create_force(bandit_faction, bandit_army, region:name(), bandit_spawns[region:name()][1], bandit_spawns[region:name()][2], ID, true)
            if owner:is_human() then
                local context = events:build_context_for_event(bandit_spawn_event, region, owner)
                events:force_check_and_queue_event(bandit_spawn_event, context)
            end
        end,
    true)

    dev.eh:add_listener(
        "BanditsCharacterCreated",
        "CharacterCreated",
        function(context)
            return context:character():faction():name() == bandit_faction
        end,
        function(context)
            local cqi = context:character():command_queue_index()
            local region = context:character():region()
            if region:is_null_interface() then
                dev.log("bandit region for "..tostring(cqi).."is null!")
                return
            end
            cm:disable_movement_for_character(dev.lookup(cqi))
        end,
        true
    )

    dev.eh:add_listener(
        "FactionTurnStartBandits",
        "FactionTurnStart",
        function(context)
            return context:faction():name() == bandit_faction
        end,
        function(context)
            local char_list = context:faction():character_list()
            for i = 0, char_list:num_items() - 1 do
                local bandit = char_list:item_at(i)
                local region = bandit:region()
                if region:is_null_interface() then
                    dev.log("bandit region for "..tostring(bandit:command_queue_index()).."is null!")
                    return
                end
                if not BANDITS[region:name()] then
                    BANDITS[region:name()] = bandit:command_queue_index()
                    if region:owning_faction():is_human() then
                        cm:trigger_incident(region:owning_faction():name(), "shield_rebellion_bandits_"..region:name(), true)
                    end
                end
                if not context:faction():at_war_with(region:owning_faction()) then
                    if not PettyKingdoms.VassalTracking.is_faction_vassal(region:owning_faction():name()) then
                        cm:force_declare_war(bandit_faction, region:owning_faction():name())
                    else
                        local vassal_master = PettyKingdoms.VassalTracking.get_faction_liege(region:owning_faction():name())
                        cm:force_declare_war(bandit_faction, vassal_master)
                    end
                end
                if bandit:has_military_force() and not bandit:military_force():active_stance() == raid_stance then
                    cm:force_character_force_into_stance(dev.lookup(bandit:command_queue_index()), raid_stance)
                end
            end
        end,
        true)

    if dev.is_new_game() then
        local char_list = dev.get_faction(bandit_faction):character_list()
        for i = 0, char_list:num_items() - 1 do
            local bandit = char_list:item_at(i)
            if bandit:has_military_force() then
                cm:disable_movement_for_character(dev.lookup(bandit))
                if not bandit:region():is_null_interface() then
                    BANDITS[bandit:region():name()] = bandit:command_queue_index()
                    cm:force_character_force_into_stance(dev.lookup(bandit:command_queue_index()), raid_stance)
                end
            end
        end
    end
end) 


dev.Save.save_value("BANDIT_ID", BANDIT_ID, function(t) BANDIT_ID = t end)
dev.Save.persist_table(BANDITS, "BANDITS" , function(t) BANDITS = t end)



