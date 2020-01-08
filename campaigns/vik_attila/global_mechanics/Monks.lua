local MANPOWER_MONK = {} --:map<string, FACTION_RESOURCE>

--v function(resource: FACTION_RESOURCE) --> string
local function value_converter(resource)
    local offset = 0
    local god_damn_pagan_idolatry = dev.get_faction(resource.owning_faction):faction_leader():has_trait("shield_heathen_pagan")
    if god_damn_pagan_idolatry then
        offset = 8
    end
    return tostring(dev.clamp(math.ceil(resource.value/45)+1+offset, 1+offset, 8+offset))
end

local sizes = {
	["vik_court_school_1"] = { ["building"] = "vik_court_school_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 10, ["value_damaged"] = 10},
	["vik_court_school_2"] = { ["building"] = "vik_court_school_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 15, ["value_damaged"] = 15},
	["vik_court_school_3"] = { ["building"] = "vik_court_school_3", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_benedictine_abbey_1"] = { ["building"] = "vik_benedictine_abbey_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 10, ["value_damaged"] = 10},
	["vik_benedictine_abbey_2"] = { ["building"] = "vik_benedictine_abbey_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_benedictine_abbey_b_2"] = { ["building"] = "vik_benedictine_abbey_b_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 10, ["value_damaged"] = 10},
	["vik_celi_de_abbey_1"] = { ["building"] = "vik_celi_de_abbey_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 10, ["value_damaged"] = 10},
	["vik_celi_de_abbey_2"] = { ["building"] = "vik_celi_de_abbey_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_ceil_de_abbey_b_2"] = { ["building"] = "vik_ceil_de_abbey_b_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 10, ["value_damaged"] = 10},
	["vik_abbey_1"] = { ["building"] = "vik_abbey_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 10, ["value_damaged"] = 10},
	["vik_abbey_2"] = { ["building"] = "vik_abbey_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_abbey_b_2"] = { ["building"] = "vik_abbey_b_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 10, ["value_damaged"] = 10},
	["vik_scoan_abbey_1"] = { ["building"] = "vik_scoan_abbey_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 10, ["value_damaged"] = 10},
	["vik_scoan_abbey_2"] = { ["building"] = "vik_scoan_abbey_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_scoan_abbey_3"] = { ["building"] = "vik_scoan_abbey_3", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 30, ["value_damaged"] = 30},
	["vik_st_brigit_1"] = { ["building"] = "vik_st_brigit_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_st_brigit_2"] = { ["building"] = "vik_st_brigit_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 30, ["value_damaged"] = 30},
	["vik_st_brigit_3"] = { ["building"] = "vik_st_brigit_3", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_st_swithun_1"] = { ["building"] = "vik_st_swithun_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_st_swithun_2"] = { ["building"] = "vik_st_swithun_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 30, ["value_damaged"] = 30},
	["vik_st_swithun_3"] = { ["building"] = "vik_st_swithun_3", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_nunnaminster_1"] = { ["building"] = "vik_nunnaminster_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_achad_bo_1"] = { ["building"] = "vik_achad_bo_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_achad_bo_2"] = { ["building"] = "vik_achad_bo_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_achad_bo_3"] = { ["building"] = "vik_achad_bo_3", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_achad_bo_4"] = { ["building"] = "vik_achad_bo_4", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_achad_bo_5"] = { ["building"] = "vik_achad_bo_5", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_st_ciaran_1"] = { ["building"] = "vik_st_ciaran_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_st_ciaran_2"] = { ["building"] = "vik_st_ciaran_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_st_ciaran_3"] = { ["building"] = "vik_st_ciaran_3", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_st_ciaran_4"] = { ["building"] = "vik_st_ciaran_4", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_st_ciaran_5"] = { ["building"] = "vik_st_ciaran_5", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_st_columbe_1"] = { ["building"] = "vik_st_columbe_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_st_columbe_2"] = { ["building"] = "vik_st_columbe_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_st_columbe_3"] = { ["building"] = "vik_st_columbe_3", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_st_columbe_4"] = { ["building"] = "vik_st_columbe_4", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_st_columbe_5"] = { ["building"] = "vik_st_columbe_5", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_st_patraic_1"] = { ["building"] = "vik_st_patraic_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_st_patraic_2"] = { ["building"] = "vik_st_patraic_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_st_patraic_3"] = { ["building"] = "vik_st_patraic_3", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_st_patraic_4"] = { ["building"] = "vik_st_patraic_4", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_st_patraic_5"] = { ["building"] = "vik_st_patraic_5", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_monastery_1"] = { ["building"] = "vik_monastery_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_monastery_2"] = { ["building"] = "vik_monastery_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_monastery_3"] = { ["building"] = "vik_monastery_3", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_monastery_4"] = { ["building"] = "vik_monastery_4", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_monastery_5"] = { ["building"] = "vik_monastery_5", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_rock_caisil_1"] = { ["building"] = "vik_rock_caisil_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_rock_caisil_2"] = { ["building"] = "vik_rock_caisil_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_rock_caisil_3"] = { ["building"] = "vik_rock_caisil_3", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_rock_caisil_4"] = { ["building"] = "vik_rock_caisil_4", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_rock_caisil_5"] = { ["building"] = "vik_rock_caisil_5", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_st_ringan_1"] = { ["building"] = "vik_st_ringan_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_st_ringan_2"] = { ["building"] = "vik_st_ringan_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_st_ringan_3"] = { ["building"] = "vik_st_ringan_3", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 30, ["value_damaged"] = 30},
	["vik_st_ringan_4"] = { ["building"] = "vik_st_ringan_4", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_st_ringan_5"] = { ["building"] = "vik_st_ringan_5", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 50, ["value_damaged"] = 50},
	["vik_st_cuthbert_1"] = { ["building"] = "vik_st_cuthbert_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_st_cuthbert_2"] = { ["building"] = "vik_st_cuthbert_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_st_cuthbert_3"] = { ["building"] = "vik_st_cuthbert_3", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 30, ["value_damaged"] = 30},
	["vik_st_cuthbert_4"] = { ["building"] = "vik_st_cuthbert_4", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_st_cuthbert_5"] = { ["building"] = "vik_st_cuthbert_5", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 50, ["value_damaged"] = 50},
	["vik_st_dewi_1"] = { ["building"] = "vik_st_dewi_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 10, ["value_damaged"] = 10},
	["vik_st_dewi_2"] = { ["building"] = "vik_st_dewi_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_st_dewi_3"] = { ["building"] = "vik_st_dewi_3", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 30, ["value_damaged"] = 30},
	["vik_st_dewi_4"] = { ["building"] = "vik_st_dewi_4", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_st_dewi_5"] = { ["building"] = "vik_st_dewi_5", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 50, ["value_damaged"] = 50},
	["vik_st_edmund_1"] = { ["building"] = "vik_st_edmund_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_st_edmund_2"] = { ["building"] = "vik_st_edmund_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_st_edmund_3"] = { ["building"] = "vik_st_edmund_3", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 30, ["value_damaged"] = 30},
	["vik_st_edmund_4"] = { ["building"] = "vik_st_edmund_4", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
	["vik_st_edmund_5"] = { ["building"] = "vik_st_edmund_5", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 50, ["value_damaged"] = 50},
	["vik_school_ros_1"] = { ["building"] = "vik_school_ros_1", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_school_ros_2"] = { ["building"] = "vik_school_ros_2", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 20, ["value_damaged"] = 20},
	["vik_school_ros_3"] = { ["building"] = "vik_school_ros_3", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 30, ["value_damaged"] = 30},
	["vik_school_ros_4"] = { ["building"] = "vik_school_ros_4", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 40, ["value_damaged"] = 40},
    ["vik_school_ros_5"] = { ["building"] = "vik_school_ros_5", ["effect"] = "shield_scripted_pop_cap_monk",  ["value"] = 50, ["value_damaged"] = 50}
} --:map<string, {building: string, effect: string, value: number, value_damaged: number}>

for building, data in pairs(sizes) do
    PettyKingdoms.RegionManpower.add_monastery_pop_cap(building, data.value)
end
local sizes = nil


dev.first_tick(function(context)
    local human_factions = cm:get_human_factions()



    for i = 1, #human_factions do
        MANPOWER_MONK[human_factions[i]] = PettyKingdoms.FactionResource.new(human_factions[i], "sw_pop_monk", "population", 0, 30000, {}, value_converter)
        local monk = MANPOWER_MONK[human_factions[i]]
        monk.uic_override = {"layout", "top_center_holder", "resources_bar2", "culture_mechanics"} 
        monk:reapply()
        if dev.is_new_game() then
            local region_list = dev.get_faction(human_factions[i]):region_list()
            for j = 0, region_list:num_items() - 1 do
                local current_region = region_list:item_at(j)     
                local manpower_obj = PettyKingdoms.RegionManpower.get(current_region:name())
                manpower_obj:update_monk_cap()
                if manpower_obj.monk_cap > 0 then
                    manpower_obj:mod_monks(manpower_obj.monk_cap/4, true, "monk_training") 
                    --TODO figure out why this isn't working
                end
            end
        end
    end



    PettyKingdoms.RegionManpower.activate("monk", function(faction_key, factor_key, change)
        local pop = PettyKingdoms.FactionResource.get("sw_pop_monk", faction_key)
        if pop then
            pop:change_value(change, factor_key)
        end
    end)


end)


