MANPOWER_SERF = {} --:map<string, FACTION_RESOURCE>

local region_factor = "culture_manpower_region_population"
local devastation_factor = "culture_manpower_region_devastation"
local recruitment_factor = "culture_manpower_recruitment"
local thriving_factor = "culture_manpower_thriving_regions"
local growth_factor = "culture_manpower_growth"
local famine_factor = "culture_manpower_famine"

local base_growth = 2 
local famine_loss = 6 
local unit_size_mode_scalar = 0.5 --0.5 is shieldwall's default sizes.

local peasant_castes = {
    very_light = true,
    medium = true,
    light = true
}--:map<string, boolean>


--v function(total_food: number) --> (int, string)
local function get_food_effect(total_food)
    local thresholds_to_returns = {
        [-150] = {0, "Famine"}, --min food, famine, handled elsewhere
        [-50] = {-1, "Food Shortages"},
        [0] = {0, "Food Shortages"},
        [100] = {1, "Food Surplus"}, --default level
        [250] = {2, "Food Surplus"}
    }--:map<number, {int, string}>
    local thresholds = {-150, -50, 0, 100, 250} --:vector<number>
    for n = 1, #thresholds do
        if total_food < thresholds_to_returns[thresholds[n]][1] then
            return thresholds_to_returns[thresholds[n]][1], thresholds_to_returns[thresholds[n]][2]
        end
    end
    --if we are above 250 food
    return 3, "Food Surplus"
end

--v function(faction: CA_FACTION)
local function apply_turn_start(faction)
    local region_pop_factor = 0
    local lost_to_devastation = 0
    local gained_from_thriving = 0
    local serfs = MANPOWER_SERF[faction:name()]
    local past_growth = serfs:get_factor(growth_factor)
    local past_famine = serfs:get_factor(famine_factor) --this will be a negative number
    local past_levy = serfs:get_factor(recruitment_factor) --this will be a negative number
    local actual_pop_base = past_growth + past_famine + past_levy
    local region_list = dev.region_list(faction)
    for i = 0, region_list:num_items() - 1 do
        local current_region = region_list:item_at(i)
        local region_manpower = PettyKingdoms.RegionManpower.get(current_region:name())
        local base_pop = dev.mround(region_manpower.base_serf*100, 1)
        region_pop_factor = region_pop_factor + base_pop
        if region_manpower.serf_multi < 100 then
            lost_to_devastation = lost_to_devastation + dev.mround(region_manpower.base_serf*(100-region_manpower.serf_multi), 1)
        elseif region_manpower.serf_multi > 100 then
            gained_from_thriving = gained_from_thriving + dev.mround(region_manpower.base_serf * (region_manpower.serf_multi - 100), 1)
        end
        actual_pop_base = actual_pop_base + dev.mround(region_manpower.base_serf*region_manpower.serf_multi, 1)
    end
    --regional factors
    serfs:set_factor(region_factor, region_pop_factor)
    serfs:set_factor(devastation_factor, lost_to_devastation)
    serfs:set_factor(thriving_factor, gained_from_thriving)
    --growth and famine
    local total_food = faction:total_food()
    if total_food >= -50 then
        if actual_pop_base < 200 then
            actual_pop_base = 200 --to prevent people from permanently running out of pop
        end
        local growth_perc_this_turn = base_growth + get_food_effect(total_food)
        local growth = dev.mround(actual_pop_base * (growth_perc_this_turn/100), 1)
        serfs:change_value(growth, growth_factor)
    else
        local loss = dev.mround(-1*(actual_pop_base * (famine_loss/100)), 1)
        serfs:change_value(loss, famine_factor)
    end
end

dev.first_tick(function(context) 

    local human_factions = cm:get_human_factions()
    for i = 1, #human_factions do
        MANPOWER_SERF[human_factions[i]] = PettyKingdoms.FactionResource.new(human_factions[i], "sw_pop_serf", "population", 0, 30000, {}, function(self)
            return "3" 
            --TODO pop value to bundle conversion
        end)
        local serfs = MANPOWER_SERF[human_factions[i]]
        serfs.uic_override = {"layout", "top_center_holder", "cult_all_pop_serf"} 
    end    


    dev.eh:add_listener(
        "SerfsFactionBeginTurnPhaseNormal",
        "FactionBeginTurnPhaseNormal",
        function(context)
            return context:faction():is_human() 
        end,
        function(context)
            local faction = context:faction()
            apply_turn_start(faction)
        end,
        true)
    apply_turn_start(cm:model():world():whose_turn_is_it())


    local rec_handler = UIScript.recruitment_handler.add_resource("sw_pop_serf", function(faction_name)
        return PettyKingdoms.FactionResource.get("sw_pop_serf", faction_name).value
    end, 
    function(faction_name, quantity)
        PettyKingdoms.FactionResource.get("sw_pop_serf", faction_name):change_value(quantity)
    end, "dy_pop_peasant")
    for k, entry in pairs(Gamedata.unit_info) do
        if peasant_castes[entry.caste] then
            rec_handler:set_cost_of_unit(entry.unit_key, dev.mround(entry.num_men*unit_size_mode_scalar, 1))
        end
    end
    rec_handler:set_resource_tooltip("Caesar send help")
    rec_handler.image_state = "peasant"
end)




