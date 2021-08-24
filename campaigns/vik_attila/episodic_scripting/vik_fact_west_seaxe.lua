local faction_key = "vik_fact_west_seaxe"
--v function(t: any)
local function log(t) dev.log(tostring(t), faction_key) end
local rivals = {
    {"vik_fact_gwined"},
    {"vik_fact_mide", "vik_fact_dyflin"},
    {"vik_fact_east_engle"},
    {"vik_fact_strat_clut", "vik_fact_northymbre"},
    {"vik_fact_circenn", "vik_fact_sudreyar"}
} --:vector<vector<string>>

-------------------------------------------
----------Events: WestSeaxe!--------------
-------------------------------------------


--v function(turn: number)
local function EventsWestSeaxe(turn)

end

--v function(context: WHATEVER, turn: number)
local function EventsMissionsWestSeaxe(context, turn)


end

--v function(context: WHATEVER, turn: number)
local function EventsDilemmasWestSeaxe(context, turn)

end



dev.first_tick(function(context)
    if not dev.get_faction(faction_key):is_human() then
        return
    end
    if dev.is_new_game() then
        cm:trigger_mission("vik_fact_west_seaxe", "sw_start_wessex", true);

    end
    if not cm:get_saved_value("start_mission_done_west_seaxe") then
        dev.eh:add_listener(
            "FactionDestroyed_WestSeaxe",
            "FactionDestroyed",
            function(context)
                return context:faction():name() == "vik_fact_jorvik"
            end,
            function(context)
                cm:set_saved_value("start_mission_done_west_seaxe", true)
                cm:override_mission_succeeded_status("vik_fact_west_seaxe", "sw_start_wessex", true)
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