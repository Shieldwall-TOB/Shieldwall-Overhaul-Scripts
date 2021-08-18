--v function(t: any)
local function log(t) dev.log(tostring(t), "SKILLS") end
--household guard is handled by other mechanics.

--v function(char: CA_CHAR, required_skill_checks: vector<(function(CA_CHAR) --> boolean)>,required_not_skills: vector<(function(CA_CHAR) --> boolean)>?) --> boolean
function has_required_skills(char, required_skill_checks, required_not_skills)
    local retval = true --:boolean
    for i = 1, #required_skill_checks do
        if required_skill_checks[i](char) == false then
            retval = false
        end
    end
    if required_not_skills then
        --# assume required_not_skills: vector<(function(CA_CHAR) --> boolean)>
        for i = 1, #required_not_skills do
            if required_not_skills[i](char) then
                retval = false
            end
        end
    end
    --log("Skill Effect Check on ["..tostring(char:command_queue_index()).."] for "..name.." resulted in: "..tostring(retval))
    return retval
end

--v function(name: string, required_skill_checks: vector<(function(CA_CHAR) --> boolean)>, callback: function(context: WHATEVER), required_not_skills: vector<(function(CA_CHAR) --> boolean)>?)
local function add_skill_effect_callback(name, required_skill_checks, callback, required_not_skills) 
    dev.eh:add_listener(
        "SkillEffectsCharTurnStart",
        "CharacterTurnStart",
        function(context) 
            local char = context:character() --:CA_CHAR
            if not char:faction():is_human() then return false end
            return has_required_skills(char, required_skill_checks, required_not_skills)
        end,
        function(context)
            callback(context)
        end,
        true)

end

----------------------------
--Henchmen Rewards Raiding--
----------------------------
--TODO henchmen rewards
dev.first_tick(function(context) 
    



end)

----------------------------
--Bard Rewards Postbattle--
----------------------------
dev.first_tick(function(context) 
    --TODO move to new events system
    --[[
    dev.Events.add_post_battle_event("sw_heroism_bard", function(context)
        return context:character():faction():is_human() and dev.Check.does_char_have_bard(context:character()) and not not PettyKingdoms.FactionResource.get("vik_heroism", context:character():faction())
    end, 3, 12, function(context)
        PettyKingdoms.FactionResource.get("vik_heroism", context:character():faction()):change_value(2) 
        --TODO factors
    end)
    
    dev.Events.add_post_battle_event("sw_heroism_bard_2", function(context)
        return context:character():faction():is_human() and dev.Check.does_char_have_bard(context:character()) and not not PettyKingdoms.FactionResource.get("vik_heroism", context:character():faction())
    end, 3, 16, function(context)
        PettyKingdoms.FactionResource.get("vik_heroism", context:character():faction()):change_value(3) 
        --TODO factors
    end)
    

    dev.Events.add_post_battle_event("sw_heroism_bard_3", function(context)
        return context:character():faction():is_human() and dev.Check.does_char_have_bard(context:character()) and not not PettyKingdoms.FactionResource.get("vik_heroism", context:character():faction())
    end, 3, 24, function(context)
        PettyKingdoms.FactionResource.get("vik_heroism", context:character():faction()):change_value(5) 
        --TODO factors
    end)

    dev.Events.add_post_battle_event("sw_fame_bard", function(context)
        return context:character():faction():is_human() and dev.Check.does_char_have_bard(context:character())
    end, 3, 16)
    --]]
end)



------------------------------
--------Blacksmith Items------
------------------------------
--TODO blacksmith items
--on turn start, if we have a blacksmith and we don't have a blacksmith item yet, give us a dilemma to get one.



------------------------------
--Gothi and Priest Blessings--
------------------------------
local blessings = {} --:map<string, {string, int, int, string?}>
--v function(char: CA_CHAR, bundle: string, turn_to_apply: int, last_bundle: int, region: string?)
local function set_blessing_entry(char, bundle, turn_to_apply, last_bundle, region)
    blessings[tostring(char:command_queue_index())] = {bundle, turn_to_apply, last_bundle, region}
end


local gothi_bundle = "sw_gothi_"
local priest_bundle = "sw_priest_"
local gov_suffix = "_gov"
local num_bundles = 3
local change_turns = 9

--v function(prefix: string, entry: {string, int, int, string?}) --> (string, int)
local function get_next_bundle(prefix, entry)
    local last_a = entry[3]
    local new_a = cm:random_number(num_bundles) 
    if new_a == last_a then new_a = new_a + 1 end if new_a > num_bundles then new_a = 1 end
    return prefix..new_a, new_a
end


dev.first_tick(function(context) 
    add_skill_effect_callback(gothi_bundle, {dev.Check.does_char_have_gothi}, function(context)
        local char = context:character() --:CA_CHAR
        local turn = cm:model():turn_number()
        local entry = blessings[tostring(char:command_queue_index())] or {"", 0, 0}
        local should_check_gov = not not entry[4]
        --if we have an unexpired bundle on a governor, delete it.
        if entry[2] > turn and should_check_gov then
            local region = dev.get_region(entry[4])
            if (not region:has_governor()) or region:governor():command_queue_index() ~= char:command_queue_index() then
                cm:remove_effect_bundle_from_region(entry[1], entry[4])
                entry[4] = nil
                entry[2] = turn
            end
        end
        --if we don't have a bundle out, put one out!
        if entry[2] <= turn then
            local bundle, bnum = get_next_bundle(gothi_bundle, entry)
            local pols_char = PettyKingdoms.CharacterPolitics.get(char:command_queue_index())
            local region = nil --:string
            if not pols_char then
                --# assume pols_char:WHATEVER
                pols_char = {last_governorship = "vik_gov_province_"}
            end
            local governorship = string.gsub(pols_char.last_governorship, "vik_gov_province_", "vik_prov_")
            local gov_region = Gamedata.regions.get_capital_with_province_key(governorship)
            if gov_region then
                region = gov_region:name()
                bundle = bundle .. gov_suffix
                cm:apply_effect_bundle_to_region(bundle, region, change_turns)
            elseif char:has_military_force() then
                cm:apply_effect_bundle_to_characters_force(bundle, char:command_queue_index(), 0, true)
            end
            set_blessing_entry(char, bundle, turn + change_turns, bnum)
        end
    end, {dev.Check.does_char_have_priest})
    add_skill_effect_callback(priest_bundle, {dev.Check.does_char_have_priest}, function(context)
        local char = context:character() --:CA_CHAR
        local turn = cm:model():turn_number()
        local entry = blessings[tostring(char:command_queue_index())] or {"", 0, 0}
        local should_check_gov = not not entry[4]
        --if we have an unexpired bundle on a governor, delete it.
        if entry[2] > turn and should_check_gov then
            local region = dev.get_region(entry[4])
            if (not region:has_governor()) or region:governor():command_queue_index() ~= char:command_queue_index() then
                cm:remove_effect_bundle_from_region(entry[1], entry[4])
                entry[4] = nil
                entry[2] = turn
            end
        end
        --if we don't have a bundle out, put one out!
        if entry[2] <= turn then
            local bundle, bnum = get_next_bundle(priest_bundle, entry)
            local pols_char = PettyKingdoms.CharacterPolitics.get(char:command_queue_index())
            local region = nil --:string
            if not pols_char then
                --# assume pols_char:WHATEVER
                pols_char = {last_governorship = "vik_gov_province_"}
            end
            local governorship = string.gsub(pols_char.last_governorship, "vik_gov_province_", "vik_prov_")
            local gov_region = Gamedata.regions.get_capital_with_province_key(governorship)
            if gov_region then
                region = gov_region:name()
                bundle = bundle .. gov_suffix
                cm:apply_effect_bundle_to_region(bundle, region, change_turns)
            else
                cm:apply_effect_bundle_to_characters_force(bundle, char:command_queue_index(), change_turns, true)
            end
            set_blessing_entry(char, bundle, turn + change_turns, bnum)
        end
    end, {dev.Check.does_char_have_gothi})
end)

dev.Save.persist_table(blessings, "skills_blessings", function(t) blessings = t end)