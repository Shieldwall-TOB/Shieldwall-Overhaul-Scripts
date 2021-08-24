local faction_key = "vik_fact_mierce"
--v function(t: any)
local function log(t) dev.log(tostring(t), faction_key) end
local rivals = {
    {"vik_fact_gwined"},
    {"vik_fact_mide", "vik_fact_dyflin"},
    {"vik_fact_east_engle", "vik_fact_west_seaxe"},
    {"vik_fact_northymbre"},
    {"vik_fact_northleode", "vik_fact_strat_clut"},
    {"vik_fact_circenn", "vik_fact_sudreyar"}
} --:vector<vector<string>>

-------------------------------------------
----------Events: Mierce!--------------
-------------------------------------------


--v function(turn: number)
local function EventsMierce(turn)

end

--v function(context: WHATEVER, turn: number)
local function EventsMissionsMierce(context, turn)


end

--v function(context: WHATEVER, turn: number)
local function EventsDilemmasMierce(context, turn)

end



dev.first_tick(function(context)
    if not dev.get_faction(faction_key):is_human() then
        return
    end
    if dev.is_new_game() then
        cm:trigger_mission("vik_fact_mierce", "sw_start_mierce", true);
    end
    if not cm:get_saved_value("start_mission_done_mierce") then
        cm:set_saved_value("start_mission_done_mierce", true)
        dev.eh:add_listener(
            "StartMissionNorthleode",
            "CharacterCompletedBattle",
            function(context)
                local main_attacker_faction = cm:pending_battle_cache_get_attacker_faction_name(1);
                local main_defender_faction = cm:pending_battle_cache_get_defender_faction_name(1);
                if main_attacker_faction == "vik_fact_mierce" and main_defender_faction == "vik_fact_ledeborg" and cm:model():pending_battle():attacker():won_battle() then
                    return true
                elseif main_defender_faction == "vik_fact_mierce" and main_attacker_faction == "vik_fact_ledeborg" and not cm:model():pending_battle():attacker():won_battle() then
                    return true
                end
                if dev.get_faction("vik_fact_ledeborg"):is_dead() then
                    return true
                end
                return false
            end,
            function(context)
                cm:set_saved_value("start_mission_done_mierce", true)
                cm:override_mission_succeeded_status("vik_fact_mierce", "sw_start_mierce", true)
            end,
            false)
    end
    for k = 1, #rivals do
        local r = cm:random_number(#rivals[k])
        local rival_to_create = rivals[k][r]
        log("Adding Rival: "..rival_to_create)
        PettyKingdoms.Rivals.new_rival(rival_to_create, 
        Gamedata.kingdoms.faction_kingdoms[rival_to_create],  Gamedata.kingdoms.kingdom_provinces(dev.get_faction(rival_to_create)),
        Gamedata.kingdoms.faction_nations[rival_to_create], Gamedata.kingdoms.nation_provinces(dev.get_faction(rival_to_create)))
    end

end)