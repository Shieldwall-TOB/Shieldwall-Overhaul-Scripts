local rival = {} --# assume rival: RIVAL
local instances = {} --:map<string, RIVAL>


local secondary_factions = {
    ["vik_fact_gwined"] = true,
    ["vik_fact_strat_clut"] = true,
    ["vik_fact_dyflin"] = true,
    ["vik_fact_norse"] = true,
    ["vik_fact_sudreyar"] = true,
    ["vik_fact_circenn"] = true,
    ["vik_fact_normaunds"] = true,
    ["vik_fact_mide"] = true,
    ["vik_fact_mierce"] = true,
    ["vik_fact_west_seaxe"] = true,
    ["vik_fact_east_engle"] = true,
    ["vik_fact_northymbre"] = true,
    ["vik_fact_aileach"] = true,
    ["vik_fact_dene"] = true,
    ["vik_fact_northleode"] = true,
    ["vik_fact_orkneyar"] = true,
    ["vik_fact_ulaid"] = true,
} --:map<string, boolean>


--v function(ax: number, ay: number, bx: number, by: number) --> number
local function distance_2D(ax, ay, bx, by)
    return (((bx - ax) ^ 2 + (by - ay) ^ 2) ^ 0.5);
end;

--v function(players: vector<string>, force: CA_FORCE) --> boolean
local function CheckIfPlayerIsNearFaction(players, force)
    local result = false;
    local force_general = force:general_character();
    if force:faction():is_human() then
        return true
    end
    local radius = 20;
    for i,value in ipairs(players) do
        local player_force_list = dev.get_faction(value):military_force_list();
        local j = 0;
        while (result == false) and (j < player_force_list:num_items()) do
            local player_character = player_force_list:item_at(j):general_character();
            local distance = distance_2D(force_general:logical_position_x(), force_general:logical_position_y(), player_character:logical_position_x(), player_character:logical_position_y());
            result = (distance < radius);
            j = j + 1;
        end
    end
    return result;
end

--v function(self: RIVAL, t: any)
function rival.log(self, t)
    dev.log(tostring(t), "RIVAL")
end

--v function(faction_key: string, kingdom: string, region_list: vector<string>, nation: string, region_list_national:vector<string>) --> RIVAL
function rival.new(faction_key, kingdom, region_list, nation, region_list_national)
    local self = {
        __index = rival
    }--# assume self: RIVAL

    self.faction_name = faction_key
    self.my_regions = {} --:map<string, true>
    self.nation_regions = {} --:map<string, true>
    self.kingdom_level = 0
    for i = 1, #region_list do
        self.my_regions[region_list[i]] = true
    end
    for i = 1, #region_list_national do
        self.nation_regions[region_list_national[i]] = true
    end

    return self

end
--v function(self: RIVAL, is_defender: boolean)
function rival.autowin(self, is_defender)
    if is_defender then
        cm:win_next_autoresolve_battle(self.faction_name);
        cm:modify_next_autoresolve_battle(1, 0, 1, 20, true);
    else
        cm:win_next_autoresolve_battle(self.faction_name);
        cm:modify_next_autoresolve_battle(0, 1, 20, 1, true);
    end
end

--v function(self: RIVAL, faction: CA_FACTION) --> boolean
function rival.is_other_rival(self, faction)
    return not not instances[faction:name()]
end

--v function(self: RIVAL, context: WHATEVER) --> (boolean, boolean)
function rival.get_battle_info(self, context) 
    local attacking_faction = context:pending_battle():attacker():faction() --:CA_FACTION
    local defending_faction = context:pending_battle():defender():faction() --:CA_FACTION
    local location = context:pending_battle():attacker():region()
    local attacker_territory = false --:boolean
    local defender_territory = false --:boolean
    if not location:is_null_interface() then
         attacker_territory = (self.faction_name == attacking_faction:name()) --be the attacker
          and (
              (self.kingdom_level == 0 and self.my_regions[location:name()])  --be either a petty kingdom inside your major kingdom
            or (self.kingdom_level > 0 and self.nation_regions[location:name()]) --or a major kingdom inside your nation
        )   
        defender_territory = (self.faction_name == defending_faction:name()) --be the defender
        and (
            (self.kingdom_level == 0 and self.my_regions[location:name()])  --be either a petty kingdom inside your major kingdom
          or (self.kingdom_level > 0 and self.nation_regions[location:name()]) --or a major kingdom inside your nation
      )   
    end
    local attacker_is_major = self:is_other_rival(attacking_faction) 
	local defender_is_major = self:is_other_rival(defending_faction) 
	local attacker_is_secondary = PettyKingdoms.VassalTracking.is_faction_vassal(defending_faction:name()) or attacking_faction:is_human() or secondary_factions[attacking_faction:name()] or dev.Check.is_faction_player_ally(attacking_faction)
    local defender_is_secondary = PettyKingdoms.VassalTracking.is_faction_vassal(defending_faction:name()) or defending_faction:is_human() or secondary_factions[defending_faction:name()] or dev.Check.is_faction_player_ally(attacking_faction)
    if CONST.__write_output_to_logfile then
        --v function(t: any)
        local function MELOG(t) self:log(t) end
        MELOG("\n#### BATTLE ####\n"..attacking_faction:name().." v "..defending_faction:name());
        do
            local print = MELOG
            local a_mf = context:pending_battle():defender():military_force() --:CA_FORCE
            local b_mf = context:pending_battle():attacker():military_force() --:CA_FORCE
            local vec = {b_mf, a_mf} --:vector<CA_FORCE>
            local name = "attacker"
            print("Outputting battle info for crash debug")
            --v function(t: string)
            local function print(t) MELOG("\t"..t) end
            print("is seige?: "..tostring(context:pending_battle():seige_battle()))
            print("is night battle?: "..tostring(context:pending_battle():night_battle()))
            print("is naval battle?: "..tostring(context:pending_battle():naval_battle()))
            print("has contested garrison?: "..tostring(context:pending_battle():seige_battle()))
            for i = 1, 2 do
                print(name.." info:")
                --v function(t: string)
                local function print(t) MELOG("\t\t"..t) end
                
                local current_mf = vec[i]
                print("faction ".. current_mf:faction():name())
                if current_mf:has_general() then
                    print(name.." has general")
                    local gen = current_mf:general_character()
                    do
                        --v function(t: string)
                        local function print(t) MELOG("\t\t\t"..t) end
                        print("rank ".. tostring(gen:rank()))
                        print("is faction leader?" .. tostring(gen:is_faction_leader()))
                        if gen:region():is_null_interface() then
                            print("region null interface -- at sea")
                        else
                            print("region ".. gen:region():name())
                        end
                    end
                end
                print("Unit list: ")
                --v function(t: string)
                local function print(t) MELOG("\t\t"..t) end
                for j = 0, current_mf:unit_list():num_items() - 1 do
                    print(current_mf:unit_list():item_at(j):unit_key())
                end
                name = "defender"
            end
        end


    end
    --abort if players are nearby
    if CheckIfPlayerIsNearFaction(cm:get_human_factions(), context:pending_battle():attacker()) then
        return false, false
    end
    --abort if the defender is secondary.
    if defender_is_secondary then
        return false, false
    end
    --if both are major, we're in our territory, but we're attacking, abort
    if attacker_territory and defender_is_major then
        return false, false
    --if we're in our territory and they aren't major, win.
    elseif attacker_territory then
        return true, false
    --if they're in our territory and aren't major, we win.
    elseif defender_territory and not attacker_is_major then
        return false, true
    end
    --if its not your territory, but you are the attacker
    if (not defender_territory) and (not attacker_territory) and (self.faction_name == attacking_faction:name()) then
        --if we're attacking a protected faction, abort
        if defender_is_secondary then
            return false, false
        else
            --otherwise, give a win to attackers
            return true, false
        end
    --if its not your territory, but you are the defender
    elseif (not defender_territory) and (not attacker_territory) and self.faction_name == defending_faction:name() then
        --if we're defending a protected faction, abort
        if attacker_is_secondary then
            return false, false
        else
            --otherwise, give a win to defenders
            return false, true
        end
    end
    return false, false
end



--v function(faction_key: string, kingdom: string, region_list: vector<string>, nation: string, region_list_national:vector<string>) --> RIVAL
local function make_rival_faction(faction_key, kingdom, region_list, nation, region_list_national)
    local new_rival = rival.new(faction_key, kingdom, region_list, nation, region_list_national)
    instances[faction_key] = new_rival
    dev.eh:add_listener(
        "GuarenteedEmpires"..faction_key,
        "PendingBattle",
        function(context)
            local attacking_faction = context:pending_battle():attacker():faction() --:CA_FACTION
            local defending_faction = context:pending_battle():defender():faction() --:CA_FACTION
            return attacking_faction:name() == faction_key or defending_faction:name() == faction_key
        end,
        function(context)
            local attacking_faction = context:pending_battle():attacker():faction() --:CA_FACTION
            local defending_faction = context:pending_battle():defender():faction() --:CA_FACTION
            local buff_attacker, buff_defender = new_rival:get_battle_info(context)
            if buff_attacker and (attacking_faction:name() == faction_key) then
                new_rival:autowin(false)
            elseif buff_defender and (defending_faction:name() == faction_key) then
                new_rival:autowin(true)
            end
        end,
        true
    )

    return new_rival
end

--v function(key: string) --> boolean
local function is_rival(key)
    return not not instances[key]
end

return {
    is_rival = is_rival,
    new_rival = make_rival_faction
}