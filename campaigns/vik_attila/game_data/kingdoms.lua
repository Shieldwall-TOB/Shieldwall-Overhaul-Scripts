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
    ["vik_fact_circenn"] = "alba",
    ["vik_fact_west_seaxe"] = "anglo_saxon",
    ["vik_fact_mierce"] = "anglo_saxon",
    ["vik_fact_mide"]  = "ireland",
    ["vik_fact_east_engle"]  = "danelaw",
    ["vik_fact_northymbre"]  = "danelaw",
    ["vik_fact_strat_clut"]  = "prydein",
    ["vik_fact_gwined"]  = "prydein",
    ["vik_fact_dyflin"]  = "irish_vikings",
    ["vik_fact_sudreyar"]  = "lochlann",
    ["vik_fact_northleode"]  = "anglo_saxon"
} --:map<string, string>



local kingdoms_borders = {
    ["vik_fact_circenn_1"] = {" vik_prov_circenn","vik_prov_monadh","vik_prov_aurmoreb","vik_prov_athfochla","vik_prov_airer_goidel","vik_prov_cait","vik_prov_iarmoreb","vik_prov_loden","vik_prov_strat_clut"},
    ["vik_fact_west_seaxe_1"] = {},
    ["vik_fact_mierce_1"] = {},
    ["vik_fact_mide_1"]  = {},
    ["vik_fact_east_engle_1"]  = {},
    ["vik_fact_northymbre_1"]  = {},
    ["vik_fact_strat_clut_1"]  = {},
    ["vik_fact_gwined_1"]  = {},
    ["vik_fact_dyflin_1"]  = {},
    ["vik_fact_sudreyar_1"]  = {},
    ["vik_fact_northleode_1"]  = {"vik_prov_loden", "vik_prov_beornice", "vik_prov_north_thryding", "vik_prov_east_thryding", "vik_prov_west_thryding"},
    ["vik_fact_circenn_2"] = {" vik_prov_circenn","vik_prov_monadh","vik_prov_aurmoreb","vik_prov_athfochla","vik_prov_airer_goidel","vik_prov_cait","vik_prov_iarmoreb","vik_prov_loden","vik_prov_strat_clut","vik_prov_druim_alban", "vik_prov_sudreyar", "vik_prov_aileach", "vik_prov_dal_naraidi", "vik_prov_east_thryding", "vik_prov_agmundrenesse"},
    ["vik_fact_west_seaxe_2"] = {},
    ["vik_fact_mierce_2"] = {},
    ["vik_fact_mide_2"]  = {},
    ["vik_fact_east_engle_2"]  = {},
    ["vik_fact_northymbre_2"]  = {"vik_prov_east_thryding", "vik_prov_north_thryding", "vik_prov_west_thryding", "vik_prov_beornice"},
    ["vik_fact_strat_clut_2"]  = {},
    ["vik_fact_gwined_2"]  = {},
    ["vik_fact_dyflin_2"]  = {},
    ["vik_fact_sudreyar_2"]  = {},
    ["vik_fact_northleode_2"]  = {"vik_prov_loden", "vik_prov_beornice", "vik_prov_north_thryding", "vik_prov_east_thryding", "vik_prov_west_thryding", "vik_prov_strat_clut", "vik_prov_monadh"}
}--:map<string, vector<string>>

local kingdom_vassal_requirements = {
    ["vik_fact_east_engle_1"] = 9,
    ["vik_fact_northymbre_1"] = 9,
    ["vik_fact_east_engle_2"] = 14,
    ["vik_fact_northymbre_2"] = 14
}

local kingdom_sea_region_requirements = {
    ["vik_fact_dyflin_1"]  = {},
    ["vik_fact_sudreyar_1"]  = {},
    ["vik_fact_sudreyar_2"]  = {},
    ["vik_fact_dyflin_2"]  = {}
}--:map<string, vector<string>>

return {
    kingdom_provinces = function(faction) --:CA_FACTION
        return kingdoms_borders[faction:name().."_1"]
    end,
    nation_provinces = function(faction)--:CA_FACTION
        return kingdoms_borders[faction:name().."_2"]
    end,
    faction_nations = nations,
    faction_kingdoms = formable_kingdoms
}