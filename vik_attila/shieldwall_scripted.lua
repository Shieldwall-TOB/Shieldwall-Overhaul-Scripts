CONST = require("core/constants")
dev = require("core/dev")
dev.log("Development library loaded, starting to load gameplay scripts")
Check = require("core/checks")
Save = require("core/save")

--require UI Libaries
UIScript = {}
local ok, err = pcall( function()
    UIScript.culture_mechanics = require("ui/CultureMechanics")
end) 
if not ok then
    dev.log("Error loading ui library")
    dev.log(tostring(err))
    dev.log(debug.traceback())
end

Gamedata = {}
local ok, err = pcall( function()
    Gamedata.general = require("game_data/general_data")
end) 
if not ok then
    dev.log("Error loading module library")
    dev.log(tostring(err))
    dev.log(debug.traceback())
end

PettyKingdoms = {} 
local ok, err = pcall( function()
    PettyKingdoms.FactionResource = require("modules/FactionResource")
end) 
if not ok then
    dev.log("Error loading module library")
    dev.log(tostring(err))
    dev.log(debug.traceback())
end




local ok, err = pcall( function()
    --global mechanics; these shouldn't need to reference other things!
    require("global_mechanics/Shroud")
    --culture mechanics
    require("culture_mechanics/burghal")

    --faction mechanics

    --decrees: these need to access the data from faction and cultural mechanics; keep them at the bottom.

    --episodic scripting (events): these need to access basically everything, load them last.
end) 
if not ok then
    dev.log("Error loading gameplay scripts!")
    dev.log(tostring(err))
    dev.log(debug.traceback())
end



--[[ old vanilla shit
require("vik_start");
require("vik_burghal");
require("vik_war_fervour");
require("vik_rebels");
require("vik_lists");
require("vik_kingdom_events");
require("vik_ai_personalities");
require("vik_trade_and_shroud");
require("vik_common");
require("vik_victory_conditions");
require("vik_campaign_random_army");
require("vik_invasions");
require("vik_starting_rebellions");
require("vik_seasonal_events");
require("vik_ai_events");
require("vik_dyflin_factions_mechanics");
require("vik_miercna_faction_mechanics");
require("vik_sudreyar_faction_mechanics");
require("vik_strat_clut_faction_mechanics");
require("vik_northymbra_faction_mechanics");
require("vik_circenn_factions_mechanics");
require("laura_test");
require("vik_culture_mechanics_sea_kings");
require("vik_culture_mechanics_viking_army");
require("vik_culture_mechanics_gaelic");
require("vik_culture_mechanics_welsh");
require("vik_culture_mechanics_english");
require("vik_culture_mechanics_common");
require("vik_legendary_traits");
require("vik_starting_traits");
require("vik_tech_locks");
require("vik_tech_unlocks");
require("vik_faction_events");
require("vik_advice");
require("vik_traits");
require("vik_decrees");
require("vik_ai_wars");
require("vik_ai_peace");
--]] 