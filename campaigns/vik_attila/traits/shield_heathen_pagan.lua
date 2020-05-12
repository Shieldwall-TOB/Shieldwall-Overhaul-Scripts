local tm = traits_manager.new("shield_heathen_pagan")
local NEW_CHARACTER_TRAIT_CHANCE = 10
tm:set_cross_loyalty("shield_faithful_friend_of_the_church", -2)

--dilemma to pick which religion upon fathers death.
--disloyal character turns to paganism (vikings)


tm:add_normal_trait_trigger("CharacterComesOfAge",
function(context)
    local char = context:character()
    if char:family_member():has_father() and char:family_member():father():has_trait("shield_heathen_pagan") then
        return true, char
    end
    return false, char
end)

tm:add_normal_trait_trigger("CharacterCreated",
function(context)
    local char = context:character()
    if char:age() > 18 and char:is_male() and dev.Check.is_char_from_viking_faction(char) then
        --case: if the king is pagan, then invert the chance
        if (not context:character():faction():faction_leader():is_null_interface()) and context:character():faction():faction_leader():has_trait("shield_heathen_pagan") then
            if cm:random_number(100) < (100 - NEW_CHARACTER_TRAIT_CHANCE) then
                return true, char
            end
        elseif cm:random_number(100) < NEW_CHARACTER_TRAIT_CHANCE then
            return true, char
        end
    end
    return false, char
end)


tm:set_start_pos_characters(
    "faction:vik_fact_sudreyar,forename:2147365942",
    "faction:vik_fact_sudreyar,forename:2147366135",
    "faction:vik_fact_sudreyar,forename:2147365979",
    "faction:vik_fact_sudreyar,forename:2147365995",
    "faction:vik_fact_sudreyar,forename:2147366152",
    "faction:vik_fact_dyflin,forename:2147365881",
    "faction:vik_fact_dyflin,forename:2147366107",
    "faction:vik_fact_dyflin,forename:2147366232",
    "faction:vik_fact_dyflin,forename:2147366227"
)