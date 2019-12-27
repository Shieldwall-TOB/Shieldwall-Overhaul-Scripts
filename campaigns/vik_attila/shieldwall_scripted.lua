CONST = require("core/constants")
dev = require("core/dev")
dev.log("Development library loaded, starting to load gameplay scripts")
Check = require("core/checks")
Save = require("core/save")

--require UI Libaries
UIScript = {}
local ok, err = pcall( function()
    UIScript.culture_mechanics = require("ui/CultureMechanics")
    UIScript.decree_panel = require("ui/DecreePanel")
end) 
if not ok then
    dev.log("Error loading ui library")
    dev.log(tostring(err))
    dev.log(debug.traceback())
end

--require game data
Gamedata = {}
local ok, err = pcall( function()
    Gamedata.general = require("game_data/general_data")
    Gamedata.base_pop = require("game_data/base_pop_values")
end) 
if not ok then
    dev.log("Error loading module library")
    dev.log(tostring(err))
    dev.log(debug.traceback())
end

--require object models
PettyKingdoms = {} 
local ok, err = pcall( function()
    PettyKingdoms.FactionResource = require("modules/FactionResource")
    PettyKingdoms.RiotManager = require("modules/RiotManager")
    PettyKingdoms.FoodStorage = require("modules/FoodStorage")
    PettyKingdoms.Decree = require("modules/Decree")
    PettyKingdoms.RegionManpower = require("modules/RegionManpower")
end) 
if not ok then
    dev.log("Error loading module library")
    dev.log(tostring(err))
    dev.log(debug.traceback())
end


--require mechanics scripts
local ok, err = pcall( function()
    --global mechanics; these shouldn't need to reference other things!
    require("global_mechanics/Shroud")
    require("global_mechanics/RiotEvents")
    require("global_mechanics/PeasantManpower")
    --culture mechanics
    require("culture_mechanics/burghal")

    --faction mechanics
    require("faction_mechanics/mierce_hoards")
    --decrees: these need to access the data from faction and cultural mechanics; keep them at the bottom.
end) 
if not ok then
    dev.log("Error loading mechanics scripts!")
    dev.log(tostring(err))
    dev.log(debug.traceback())
end

--require traits
traits_manager = require("traits/helpers/trait_manager")

--require episodic scripting


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