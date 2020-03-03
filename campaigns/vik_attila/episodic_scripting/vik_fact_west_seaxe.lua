local faction_key = "vik_fact_west_seaxe"
--v function(t: any)
local function log(t) dev.log(tostring(t), faction_key) end
local rivals = {
    {"vik_fact_gwined"},
    {"vik_fact_mide", "vik_fact_dyflin"},
    {"vik_fact_east_engle"},
    {"vik_fact_strat_clut", "vik_fact_northumbria"},
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
    for k = 1, #rivals do
        local r = cm:random_number(#rivals[k])
        local rival_to_create = rivals[k][r]
        log("Adding Rival: "..rival_to_create)



        PettyKingdoms.RivalFactions.new_rival(rival_to_create)
    end

end)