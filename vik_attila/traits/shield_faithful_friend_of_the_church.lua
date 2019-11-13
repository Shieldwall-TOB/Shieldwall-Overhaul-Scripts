local tm = traits_manager.new("shield_faithful_friend_of_the_church")
local NEW_CHARACTER_TRAIT_CHANCE = 5
local FLAG_TRAIT_CHANCE = 20

tm:add_normal_trait_trigger("CharacterCreated",
function(context)
    local char = context:character()
    if char:age() > 18 and char:is_male() then
        --Only grant randomly if the King isn't pagan
        if (not context:character():faction():faction_leader():is_null_interface()) and not context:character():faction():faction_leader():has_trait("shield_heathen_pagan") then
            if cm:random_number(100) < NEW_CHARACTER_TRAIT_CHANCE then
                return false, char
            end
        end
    end
    return false, char
end)

tm:add_dilemma_flag_listener( "CharacterTurnStart",
function(context)
    local char = context:character()
    --cannot trigger for pagans
    if char:has_trait("shield_heathen_pagan") then
        return false, char
    end
    --if character is too loyal
    if char:loyalty() > 7 then
        return false, char
    end
    --if character is near a church
    if Check.is_char_near_church(char) then
        return  cm:random_number(100) < FLAG_TRAIT_CHANCE , char 
    else
        return false, char
    end
end)

tm:add_faction_leader_trait_mission("BuildingCompleted", 
function(context)
    local building = context:building()
    if building:superchain() == "vik_church" then
        return true, context:building():faction()
    end
    return false, nil
end, 2)


tm:set_start_pos_characters(
    --wessex starting characters
    "faction:vik_fact_west_seaxe,forename:2147363490",
    "faction:vik_fact_west_seaxe,forename:2147363123",
    --east engle
    "faction:vik_fact_east_engle,forename:2147366862",
    --miercna
    "faction:vik_fact_miercna,forename:2147363481"
)