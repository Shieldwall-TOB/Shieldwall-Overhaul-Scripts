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

--v function(char: CA_CHAR) --> boolean
local function check_is_char_from_viking_faction(char)
    local viking_sc = {
        vik_sub_cult_viking_gael = true,
        vik_sub_cult_anglo_viking = true
    } --:map<string, boolean>
    return not not viking_sc[char:faction():subculture()]
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





return {
    not_null = check_not_null,
    is_char_from_viking_faction = check_is_char_from_viking_faction,
    is_faction_viking_faction = check_is_faction_viking_faction,
    is_region_low_public_order = check_is_region_low_public_order,
    is_char_near_church = check_is_char_near_church
}