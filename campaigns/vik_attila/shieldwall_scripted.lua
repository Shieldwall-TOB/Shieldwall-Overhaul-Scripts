CONST = require("core/constants")
dev = require("core/dev")
dev.log("Development library loaded, starting to load gameplay scripts")
dev.Save = require("core/save")
dev.Events = require("core/Events")
dev.Check = require("core/checks")


--require UI Libaries
UIScript = {}
local ok, err = pcall( function()
    UIScript.effect_bundles = require("ui/EffectBundleBar")
    UIScript.culture_mechanics = require("ui/CultureMechanics")
    UIScript.decree_panel = require("ui/DecreePanel")
    UIScript.recruitment_handler = require("ui/RecruitmentHandler")
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
    Gamedata.regions = require("game_data/regions")
    Gamedata.base_pop = require("game_data/base_pop_values")
    Gamedata.unit_info = require("game_data/unit_info")
    Gamedata.spawn_locations = require("game_data/spawn_locations")
    Gamedata.kingdoms = require("game_data/kingdoms")
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
    PettyKingdoms.VassalTracking = require("modules/VassalTracking")
    PettyKingdoms.ForceTracking = require("modules/ForceTracking")
    PettyKingdoms.RiotManager = require("modules/RiotManager")
    PettyKingdoms.FoodStorage = require("modules/FoodStorage")
    PettyKingdoms.Decree = require("modules/Decree")
    PettyKingdoms.Rivals = require("modules/RivalFactions")
    PettyKingdoms.RegionManpower = require("modules/RegionManpower")
    PettyKingdoms.CharacterPolitics = require("modules/CharacterPolitics")
end) 
if not ok then
    dev.log("Error loading module library")
    dev.log(tostring(err))
    dev.log(debug.traceback())
end


--require mechanics scripts
local ok, err = pcall( function()
    --global mechanics; 
    require("global_mechanics/CampaignVictories")
    require("global_mechanics/Shroud")
    require("global_mechanics/RiotEvents")
    require("global_mechanics/Bandits")
    require("global_mechanics/CitiesLandmarks")
    require("global_mechanics/VikingRaiders")
    require("global_mechanics/building_effects")
    --manpower
    require("global_mechanics/PeasantManpower")
    require("global_mechanics/NobleManpower")
    require("global_mechanics/Monks")
    require("global_mechanics/ForeignWarriors")
    --culture mechanics
    require("culture_mechanics/burghal")

    --faction mechanics
    require("faction_mechanics/mierce_hoards")
    --decrees
    require("decrees/WestSeaxeDecrees")
    require("decrees/MierceDecrees")
    require("decrees/NorthleodeDecrees")
end) 
if not ok then
    dev.log("Error loading mechanics scripts!")
    dev.log(tostring(err))
    dev.log(debug.traceback())
end

--require traits

--v [NO_CHECK]function(list:table)
local function require_traits(list)
    for i = 1, #list do
        require("traits/"..list[i])
    end
end
traits_manager = require("traits/helpers/trait_manager")
require_traits(require("traits/TraitTriggers"))

--require episodic scripting
local ok, err = pcall( function()
    require("episodic_scripting/vik_fact_northleode")
end) 
if not ok then
    dev.log("Error loading episodic scripts!")
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