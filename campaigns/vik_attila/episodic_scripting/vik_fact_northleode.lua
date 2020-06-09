local faction_key = "vik_fact_northleode"
--Lategame Invasion: Norse Invade and they aren't very friendly.
--Lategame Invasion: Normans

--v function(t: any)
local function log(t) dev.log(tostring(t), faction_key) end
local rivals = {
    {"vik_fact_northumbria"},
    {"vik_fact_mide", "vik_fact_dyflin"},
    {"vik_fact_east_engle", "vik_fact_west_seaxe"},
    {"vik_fact_mierce", "vik_fact_hellirborg"},
    {"vik_fact_circenn"},
    {"vik_fact_strat_clut"}
} --:vector<vector<string>>
local spawns = {
    ["vik_reg_doneceaster"] = {560,351},
    ["vik_reg_beoferlic"] = {638,386}
} --:map<string, {int, int}>
local armies = {
    ["vik_reg_doneceaster"] = {
        ["dan_mailed_swordsmen"] = {1, 15, 100},
        ["dan_anglian_raiders"] = {1, 2, 60},
        ["est_shield_biters"] = {4, 3, 30},
        ["dan_spearmen"] = {6, 3, 30},
        ["dan_ceorl_archers"] = {2, 2, 35}
    },
    ["vik_reg_beoferlic"] = {
        ["dan_northumbrian_thegns"] = {1, 15, 100},
        ["dan_spearmen"] = {1, 2, 80},
        ["dan_berserkers"] = {6, 3, 50},
        ["dan_anglian_raiders"] = {2, 2, 35}
    }
}--:map<string, map<string, {int, int, int}>>
local bonus_units_ai = {
    ["vik_fact_northleode_ai"] = {
        [1] = {""}
    }
}



-------------------------------------------
----------Events: Northleode!--------------
-------------------------------------------
EVENTS_NORTHLEODE_STRAT_CLUT = false --:boolean
EVENTS_NORTHLEODE_WESTMORINGAS = false--:boolean
EVENTS_NORTHLEODE_BETRAYAL = false--:boolean
EVENTS_NORTHLEODE_BOOKS = 0--:int
EVENTS_NORTHLEODE_KING_OF_NOTHING = false--:boolean
dev.Save.save_value("EVENTS_NORTHLEODE_STRAT_CLUT", EVENTS_NORTHLEODE_STRAT_CLUT, function(t) EVENTS_NORTHLEODE_STRAT_CLUT = t end)
dev.Save.save_value("EVENTS_NORTHLEODE_WESTMORINGAS", EVENTS_NORTHLEODE_WESTMORINGAS, function(t) EVENTS_NORTHLEODE_STRAT_CLUT = t end)
dev.Save.save_value("EVENTS_NORTHLEODE_BETRAYAL", EVENTS_NORTHLEODE_BETRAYAL, function(t) EVENTS_NORTHLEODE_STRAT_CLUT = t end)
dev.Save.save_value("EVENTS_NORTHLEODE_BOOKS", EVENTS_NORTHLEODE_BOOKS, function(t) EVENTS_NORTHLEODE_STRAT_CLUT = t end)
dev.Save.save_value("EVENTS_NORTHLEODE_KING_OF_NOTHING", EVENTS_NORTHLEODE_KING_OF_NOTHING, function(t) EVENTS_NORTHLEODE_STRAT_CLUT = t end)

--v function(turn: number)
local function EventsNorthleode(turn)
    local northleode = dev.get_faction("vik_fact_northleode")


    if northleode:is_human() then
        if turn == 0 then
            cm:trigger_mission("vik_fact_northleode", "sw_start_northleode", true);
        end
        if not dev.get_faction("vik_fact_northymbre"):is_dead() then
            dev.log("Checking northleode faction events!")
            local is_still_vassal = northleode:is_vassal_of(dev.get_faction("vik_fact_northymbre"))
            dev.log("vassal status: ["..tostring(is_still_vassal).."]")
            if is_still_vassal and not northleode:has_effect_bundle("sw_northleode_king_of_nothing") then
                cm:apply_effect_bundle("sw_northleode_king_of_nothing", "vik_fact_northleode", 0)
            elseif not is_still_vassal and northleode:has_effect_bundle("sw_northleode_king_of_nothing") then
                cm:remove_effect_bundle("sw_northleode_king_of_nothing", "vik_fact_northleode")
                if not dev.get_faction("vik_fact_northymbre"):is_human() then
                    for region, location in pairs(spawns) do
                        local army = dev.create_army(armies, 5, region)
                        cm:create_force("vik_fact_northymbre", army, region, location[1], location[2], "plot_invasions_"..dev.invasion_number(), true)
                    end
                    cm:apply_effect_bundle("sw_northumbria_free_army", "vik_fact_northymbre", 15)
                end
            end
            if turn == 2 then
                cm:force_diplomacy("vik_fact_westmoringas", "vik_fact_northymbre", "war", false, false)
                cm:force_diplomacy("vik_fact_northymbre", "vik_fact_westmoringas", "war", false, false)
            end
            if is_still_vassal and (not EVENTS_NORTHLEODE_STRAT_CLUT) and dev.get_faction("vik_fact_strat_clut"):at_war_with(dev.get_faction("vik_fact_westernas")) then
                dev.log("triggering northleode strat clut dilemma")
                cm:trigger_dilemma("vik_fact_northleode", "sw_northleode_help_against_strat_clut", true)
                EVENTS_NORTHLEODE_STRAT_CLUT = true
            elseif turn >= 3 and (not EVENTS_NORTHLEODE_STRAT_CLUT) then
                dev.log("forcing war between strat clut and westernas")
                cm:force_declare_war("vik_fact_strat_clut", "vik_fact_westernas")
            end
            if turn > 14 and is_still_vassal and (not EVENTS_NORTHLEODE_WESTMORINGAS) then
                dev.log("triggering northleode westmoringas dilemma")
                cm:force_diplomacy("vik_fact_westmoringas", "vik_fact_northymbre", "war", true, true)
                cm:force_diplomacy("vik_fact_northymbre", "vik_fact_westmoringas", "war", true, true)
                EVENTS_NORTHLEODE_WESTMORINGAS = true
                cm:trigger_dilemma("vik_fact_northleode", "sw_northleode_help_against_jorvik", true)
            end
            if turn > 25 and is_still_vassal and (not EVENTS_NORTHLEODE_BETRAYAL) then
                dev.log("checking northleode betrayal dilemma")
                if (not dev.get_faction("vik_fact_east_engle"):is_dead()) and (not dev.get_faction("vik_fact_northleode"):at_war_with(dev.get_faction("vik_fact_east_engle"))) then
                    dev.log("rolling for northleode east engle dilemma")
                    if cm:random_number(25) > 15 then
                        dev.log("triggering northleode mierce dilemma")
                        cm:trigger_dilemma("vik_fact_northleode", "sw_northleode_betrayal_east_engle", true)
                        EVENTS_NORTHLEODE_BETRAYAL = true
                    end
                elseif (not dev.get_faction("vik_fact_mierce"):is_dead()) and (not dev.get_faction("vik_fact_northleode"):at_war_with(dev.get_faction("vik_fact_mierce"))) then
                    dev.log("rolling for northleode mierce dilemma")
                    if cm:random_number(25) > 15 then
                        dev.log("triggering northleode mierce dilemma")
                        cm:trigger_dilemma("vik_fact_northleode", "sw_northleode_betrayal_mierce", true)
                        EVENTS_NORTHLEODE_BETRAYAL = true
                    end
                end
            end
        end
    else
        local leader = northleode:faction_leader()
        cm:grant_unit(dev.lookup(leader), "eng_thegns")
    end
end

--v function(context: WHATEVER, turn:number)
local function EventCharacterCompletesBattleNorthleode(context, turn)
    if not cm:get_saved_value("start_mission_done_northleode") then
        local wicing_leader = dev.get_faction("vik_fact_wicing"):faction_leader()
        local beburg = dev.get_faction("vik_fact_northleode"):home_region():settlement()
        if dev.get_faction("vik_fact_wicing"):is_dead() or dev.distance(beburg:logical_position_x(), beburg:logical_position_y(), wicing_leader:logical_position_x(), wicing_leader:logical_position_y()) > 80 then
            cm:set_saved_value("start_mission_done_northleode", true)
            cm:override_mission_succeeded_status("vik_fact_northleode", "sw_start_northleode", true)
        end
    end
end

--v function(context: WHATEVER, turn: number, is_fail: boolean)
local function EventsMissionsNorthleode(context, turn, is_fail)


end

--v function(context: WHATEVER, turn: number)
local function EventsDilemmasNorthleode(context, turn)
	local dilemma = context:dilemma() --:string
	local choice = context:choice() --:number
	if dilemma == "sw_northleode_help_against_strat_clut" then
		if choice == 0 then
			cm:force_declare_war("vik_fact_northymbre", "vik_fact_strat_clut")
		end
	end
	if dilemma == "sw_northleode_help_against_jorvik" then
		if choice == 0 then
			cm:force_declare_war("vik_fact_northleode", "vik_fact_northymbre")
		else
			cm:force_declare_war("vik_fact_northymbre", "vik_fact_westmoringas")
		end
	end
	if dilemma == "sw_northleode_betrayal_east_engle" then
		if choice == 0 then
			cm:force_declare_war("vik_fact_northleode", "vik_fact_northymbre")
			if (not dev.get_faction("vik_fact_east_engle"):at_war_with(dev.get_faction("vik_fact_northymbre"))) then
				cm:force_declare_war("vik_fact_east_engle", "vik_fact_northymbre")
			end
		end
	end
	if dilemma == "sw_northleode_betrayal_mierce" then
		if choice == 0 then
			cm:force_declare_war("vik_fact_northleode", "vik_fact_northymbre")
			if (not dev.get_faction("vik_fact_mierce"):at_war_with(dev.get_faction("vik_fact_northymbre"))) then
				cm:force_declare_war("vik_fact_mierce", "vik_fact_northymbre")
			end
		end
	end
end



dev.first_tick(function(context)
    if not dev.get_faction(faction_key):is_human() then
        return
    end
    if dev.is_new_game() then
        EventsNorthleode(0)
    end
    for k = 1, #rivals do
        local r = cm:random_number(#rivals[k])
        local rival_to_create = rivals[k][r]
        log("Adding Rival: "..rival_to_create)
        PettyKingdoms.Rivals.new_rival(rival_to_create, 
        Gamedata.kingdoms.faction_kingdoms[faction_key],  Gamedata.kingdoms.kingdom_provinces(dev.get_faction(faction_key)),
        Gamedata.kingdoms.faction_nations[faction_key], Gamedata.kingdoms.nation_provinces(dev.get_faction(faction_key))
    )
    end
    dev.eh:add_listener(
        "FactionTurnStart_Events",
        "FactionTurnStart",
        function(context) return context:faction():name() == faction_key end,
        function(context) EventsNorthleode(cm:model():turn_number()) end,
        true
    );
    dev.eh:add_listener(
        "DilemmaChoiceMadeEvent_Events",
        "DilemmaChoiceMadeEvent",
        true,
        function(context) EventsDilemmasNorthleode(context, cm:model():turn_number()) end,
        true
    );
    dev.eh:add_listener(
        "CharacterCompletedBattle_Events",
        "CharacterCompletedBattle",
        function(context) return context:faction():name() == faction_key end,
        function(context) EventCharacterCompletesBattleNorthleode(context, cm:model():turn_number()) end,
        true
    );
    dev.eh:add_listener(
        "MissionSucceeded_Events",
        "MissionSucceeded",
        true,
        function(context) EventsMissionsNorthleode(context, cm:model():turn_number(), false) end,
        true
    );
    dev.eh:add_listener(
        "MissionFailed_Events",
        "MissionFailed",
        true,
        function(context) EventsMissionsNorthleode(context,cm:model():turn_number(), true) end,
        true
    );
end)