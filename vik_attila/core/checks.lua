--v function(t: any)
local function log(t)
    dev.log(tostring(t), "Check")
end

--HELPERS
--could be moved
--what is the distance between two points?
--v function(ax: number, ay: number, bx: number, by: number) --> number
local function distance_2D(ax, ay, bx, by)
    return (((bx - ax) ^ 2 + (by - ay) ^ 2) ^ 0.5);
end;


--CHECKS

--v [NO_CHECK] function(ca_object: any) --> boolean
local function check_not_null(ca_object)
    if not ca_object.is_null_interface then
        log("Call to check not null provided an object without the is_null_interface method!")
    end
        
    return not ca_object:is_null_interface()
end

--v function(faction: CA_FACTION) --> boolean
local function check_is_faction_human(faction)
    return faction:is_human()
end

--v function(faction: CA_FACTION) --> boolean
local function check_is_faction_viking_faction(faction)
    local viking_sc = {
        vik_sub_cult_viking_gael = true,
        vik_sub_cult_anglo_viking = true
    } --:map<string, boolean>
    return not not viking_sc[faction:subculture()]
end

--v function(region: CA_REGION) --> boolean
local function check_is_region_low_public_order(region)
    return (region:squalor() - region:sanitation() > 0) 
end

--v function(char: CA_CHAR) --> boolean
local function check_is_char_near_church(char)
    local church_superchains = {
        "vik_abbey",
        "vik_church",
        "vik_monastery",
        "vik_nunnaminster",
        "vik_school_ros",
        "vik_scoan_abbey"
       --[[ "vik_st_brigit",
        "vik_st_ciaran",
        "vik_st_columbe",
        "vik_st_cuthbert",
        "vik_st_dewi",
        "vik_st_edmund",
        "vik_st_patraic",
        "vik_st_ringan",
        "vik_st_swithun" 
        we check for these using string.find to save time--]] 
    }
    local char_faction_regions = char:faction():region_list()
    local x, y = char:logical_position_x(), char:logical_position_y()
    if char_faction_regions:is_empty() then
        return false
    else
        for i = 0, char_faction_regions:num_items() - 1 do
            local current_region = char_faction_regions:item_at(i)
            local superchain = current_region:settlement():slot_list():item_at(0):building():superchain()
            local xb, yb = current_region:settlement():logical_position_x(), current_region:settlement():logical_position_y()
            if string.find(superchain, "_st_") then
                return (distance_2D(x, y, xb, yb) < 200)
            else
                for j = 1, #church_superchains do
                    if church_superchains[j] == superchain then
                        return (distance_2D(x, y, xb, yb) < 200)
                    end
                end
            end
        end
    end
    return false
end


--v function(char: CA_CHAR) --> boolean
local function check_is_char_from_viking_faction(char)
    local viking_sc = {
        vik_sub_cult_viking_gael = true,
        vik_sub_cult_anglo_viking = true
    } --:map<string, boolean>
    return not not viking_sc[char:faction():subculture()]
end

--v function(character: CA_CHAR) --> boolean
local function check_does_char_have_household_guard(character)
	local faction_to_follower_trait = {
		["vik_fact_circenn"] = "vik_follower_champion_circenn",
		["vik_fact_west_seaxe"] = "vik_follower_champion_west_seaxe",
		["vik_fact_mierce"] = "vik_follower_champion_mierce",
		["vik_fact_mide"]  = "vik_follower_champion_mide",
		["vik_fact_east_engle"]  = "vik_follower_champion_east_engle",
		["vik_fact_northymbre"]  = "vik_follower_champion_northymbre",
		["vik_fact_strat_clut"]  = "vik_follower_champion_strat_clut",
		["vik_fact_gwined"]  = "vik_follower_champion_gwined",
		["vik_fact_dyflin"]  = "vik_follower_champion_dyflin",
		["vik_fact_sudreyar"]  = "vik_follower_champion_sudreyar",
		["vik_fact_northleode"]  = "vik_follower_champion",
		["vik_fact_caisil"]  = "vik_follower_champion",
		["nil"] = "vik_follower_champion"
	} --:map<string, string>

	local faction_name = character:faction():name()
	local skill_key = faction_to_follower_trait[faction_name]
	if skill_key == nil then
		skill_key = faction_to_follower_trait["nil"]
	end
	if character:has_skill(skill_key.."_2") then
		return true
	end
	return false
end



return {
    not_null = check_not_null,
    --faction
    is_faction_human = check_is_faction_human,
    is_faction_viking_faction = check_is_faction_viking_faction,
    --region
    is_region_low_public_order = check_is_region_low_public_order,
    --characters
    is_char_from_viking_faction = check_is_char_from_viking_faction,
    is_char_near_church = check_is_char_near_church,
    does_char_have_household_guard = check_does_char_have_household_guard
}