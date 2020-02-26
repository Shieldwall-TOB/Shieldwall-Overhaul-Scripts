--manages forming kingdoms.
--how does this crap work in Coop? Don't ask me. I'm not entirely sure why coop games don't just have normal victory conditions.
--gonna leave it broken for MP campaigns for now.

local nations = {
    ["vik_fact_circenn"] = "scotland",
    ["vik_fact_west_seaxe"] = "england",
    ["vik_fact_mierce"] = "england",
    ["vik_fact_mide"]  = "temhair",
    ["vik_fact_east_engle"]  = "north_sea_empire",
    ["vik_fact_northymbre"]  = "north_sea_empire",
    ["vik_fact_strat_clut"]  = "old_north",
    ["vik_fact_gwined"]  = "wales",
    ["vik_fact_dyflin"]  = "norse_gaelic_sea",
    ["vik_fact_sudreyar"]  = "norse_gaelic_sea",
    ["vik_fact_northleode"]  = "england"
} --:map<string, string>

local formable_kingdoms = {
    ["vik_fact_circenn"] = "scotland",
    ["vik_fact_west_seaxe"] = "anglo_saxon",
    ["vik_fact_mierce"] = "anglo_saxon",
    ["vik_fact_mide"]  = "ireland",
    ["vik_fact_east_engle"]  = "danelaw",
    ["vik_fact_northymbre"]  = "danelaw",
    ["vik_fact_strat_clut"]  = "old_north",
    ["vik_fact_gwined"]  = "wales",
    ["vik_fact_dyflin"]  = "irish_vikings",
    ["vik_fact_sudreyar"]  = "lochlann",
    ["vik_fact_northleode"]  = "anglo_saxon"
} --:map<string, string>

local victory_incidents = {
    ["vik_vc_conquest_1"] = "vik_incident_short_victory_conquest",
    ["vik_vc_fame_1"] = "vik_incident_short_victory_fame",
    ["vik_vc_fame_2"] = "vik_incident_long_victory_fame",
    ["vik_vc_conquest_2"] = "vik_incident_long_victory_conquest"
} --:map<string, string>

local final_victory_events = {
    ["vik_vc_fame_2"] = "vik_incident_invasion_end_1_fame",
    ["vik_vc_conquest_2"] = "vik_incident_invasion_end_1_conquest"
} --:map<string, string>

local victory_cutscenes = {
    ["vik_vc_conquest_1"] = "vik_victory_domination_short",
    ["vik_vc_fame_1"] = "vik_victory_fame_short",
    ["vik_vc_fame_2"] = "vik_victory_fame_long",
    ["vik_vc_conquest_2"] = "vik_victory_domination_long",
    ["vik_vc_kingdom_2"] = "vik_victory_kingdom_long",
    ["vik_vc_kingdom_1"] = "vik_victory_kingdom_short",
    ["vik_vc_invasion"] = "vik_victory_ultimate"
} --:map<string, string>

local victories = {

} --:map<string, {bool, bool, string, string}>

--v function(faction: CA_FACTION, kingdom: string, long_victory: boolean, no_message:boolean?)
function KingdomSetFounderFaction(faction, kingdom, long_victory, no_message)
    cm:set_faction_name_override(faction:name(), "vik_fact_kingdom_"..kingdom);
	local founder = "ai";
    local faction_string = string.gsub(faction:name(), "vik_fact_", "")
	--Remove old effect bundles for player and apply new effect bundles
	if faction:is_human() then
        founder = "player";
        if kingdom == nations[faction:name()] then
            if faction:has_effect_bundle("vik_kingdom_"..formable_kingdoms[faction:name()].."_"..faction_string) then
                cm:remove_effect_bundle("vik_kingdom_"..formable_kingdoms[faction:name()].."_"..faction_string, faction:name())
            end
            cm:apply_effect_bundle("vik_kingdom_"..kingdom.."_"..faction_string, faction:name(), 0)
        else
            if faction:has_effect_bundle("vik_faction_trait_"..faction_string) then
                cm:remove_effect_bundle("vik_faction_trait_"..faction_string, faction:name())
            end
            cm:apply_effect_bundle("vik_kingdom_"..kingdom.."_"..faction_string, faction:name(), 0)
        end
	end
	
    --Fire the incident

	local incident = "vik_incident_kingdom_formed_"..kingdom.."_"..founder;
	if long_victory == true then
		incident = "vik_incident_kingdom_formed_"..kingdom.."_player_long_victory";
    end
    dev.eh:trigger_event("FactionFormsKingdom", faction, kingdom)
    if not no_message then
        cm:trigger_incident(faction:name(), incident, true)
    end
end

--v function(faction: CA_FACTION, mission: string)
local function apply_victory_mission(faction, mission)
    if not not string.find(mission, "_1") then
        --short victory
        if mission == "vik_vc_kingdom_1" then
            KingdomSetFounderFaction(faction, formable_kingdoms[faction:name()], false)
            victories[faction:name()][3] = formable_kingdoms[faction:name()]
        end
        if victories[faction:name()][1] == false and victory_cutscenes[mission] then
            cm:register_instant_movie(victory_cutscenes[mission])
            cm:unlock_technology(faction:name(), "vik_mil_cap_1")
            victories[faction:name()][1] = true
            if victory_incidents[mission] then
                cm:trigger_incident(faction:name(), victory_incidents[mission], true)
            end
        end
    elseif not not string.find(mission, "_2") then
        --long victory
        if mission == "vik_vc_kingdom_2" then
            KingdomSetFounderFaction(faction, nations[faction:name()], not victories[faction:name()][2])
            victories[faction:name()][3] = nations[faction:name()]
        end
        if victories[faction:name()][2] == false then
            victories[faction:name()][2] = true
            cm:register_instant_movie(victory_cutscenes[mission])
            if final_victory_events[mission] then
                cm:trigger_incident(faction:name(), final_victory_events[mission], true)
            end
        elseif victory_incidents[mission] then
            cm:trigger_incident(faction:name(), victory_incidents[mission], true)
        end
    elseif mission == "vik_vc_invasion" then
        cm:register_instant_movie("vik_victory_ultimate"); 
    end
end


dev.first_tick(function(context) 

    if cm:is_multiplayer() == false then
        if dev.is_new_game() then
            victories[cm:get_local_faction(true)] = {false, false, "", ""}
        end
        local faction = dev.get_faction(cm:get_local_faction(true))
        if victories[cm:get_local_faction(true)] then
            --set names after loading
            if victories[cm:get_local_faction(true)][3] ~= "" and formable_kingdoms[faction:name()] then
                KingdomSetFounderFaction(faction, formable_kingdoms[faction:name()], false, true)
            end
            if victories[cm:get_local_faction(true)][4] ~= "" then
                KingdomSetFounderFaction(faction,nations[faction:name()], false, true)
            end 
        end
        if victories[cm:get_local_faction(true)][1] == false then
            cm:lock_technology(cm:get_local_faction(true), "vik_mil_cap_1")
        end
        dev.eh:add_listener(
			"MissionSucceeded_Victory",
			"MissionSucceeded",
            function(context)
               return (not not string.find(context:mission(), "vik_vc_")) and (not not formable_kingdoms[context:faction():name()])
            end,
            function(context) 
                local mission = context:mission() --:string
                local faction = context:faction() --:CA_FACTION
                apply_victory_mission(faction, mission)
            end,
			true
		);
    end
end )


--dev.Save.persist_table(victories, "victory_cnd", function(t) victories = t end)