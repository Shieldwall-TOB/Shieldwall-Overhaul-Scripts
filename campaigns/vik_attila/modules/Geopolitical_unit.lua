--a geopolitical unit consists of a series of factions and a series of behaviours when certain factions are AI or human.
--They track territory which each faction claims and use determine which effects they apply to behaviour.

local vassal_recovery_window = 24
local vassal_recovery_event = "sw_gifts_vassal_region_"
local ally_recovery_window = 12
local ally_recovery_event = "sw_gifts_ally_region_"
local region_defection_bundle = ""
local region_defection_surrender_chance = 35
local region_defection_surrender_surrounded_bonus = 35
local region_defection_surrender_bonus_values = {}
local region_defection_surrender_event = "sw_region_defection_surrender_"
local region_defection_village_event = "sw_gifts_village_defection_"
local region_defection_village_chance = 65
local region_defection_village_own_allegiance_bonus = -50
local region_defection_village_wrong_allegiance_penalty = 35
local region_defection_riots_chance = 20
local region_defection_riots_event = "sw_gifts_our_region_defects_riots_"
local region_defection_defeats_event = "sw_gifts_our_region_defects_defeat_"
local region_defection_victories_event = "sw_gifts_region_defection_victories_"
local region_defection_victories_chance = 15
local region_defection_victories_own_allegiance_bonus = -50
local region_defection_victories_wrong_allegiance_penalty = 90
local region_defection_victories_bonus_values = {}
local region_defection_war_chance = 50
local region_defection_ally_gift_choice = "sw_gifts_region_to_ally_"
local region_defection_ally_gift_levels = 3
local region_defection_ally_time_between_requests = 4;
local region_defection_ally_time_between_requests_scaling = 2;




local geopolitics = {} --# assume geopolitics: GEOPOLITICS

--v function(name: string) --> GEOPOLITICS
function geopolitics.new(name)
    local self = {}
    setmetatable(self, {
        __index = geopolitics
    }) --# assume self: GEOPOLITICS
    self.regions = {} --:vector<string>
    self.faction_kingdom_regions = {} --:map<string, vector<string>>
    self.faction_to_kingdom_sympathy = {} --:map<string, int>
    self.faction_to_nation_sympathy = {} --:map<string, int>
    self.kingdom_threatened_responses = {} --:map<string, function(faction: string, other_faction: string, regions_lost: number, regions_conquered: number, region_moved: string)>
    self.kingdom_expands_responses = {} --:map<string, function(faction: string, other_faction: string, regions_lost: number, regions_conquered: number, region_moved: string)>
    self.use_behaviour_whitelist = false --:boolean
    self.faction_to_permitted_behaviours = {} --:map<string, vector<string>>
    self.regions_active = {} --:map<string, boolean>
    self.faction_controlled_regions = {} --:map<string, map<string, number>>
    self.faction_lost_regions = {} --:map<string, map<string, number>>
    self.region_to_last_major_owner = {}
    self.other_regions = 0 --:int

    return self
end


--v function(self: GEOPOLITICS, faction: string, kingdom: vector<string>, faction_to_kingdom_sympathy: int, faction_to_nation_sympathy: int)
function geopolitics.add_faction(self, faction, kingdom, faction_to_kingdom_sympathy, faction_to_nation_sympathy)
    self.faction_kingdom_regions[faction] = kingdom
    self.faction_to_kingdom_sympathy[faction] = faction_to_kingdom_sympathy
    self.faction_to_nation_sympathy[faction] = faction_to_nation_sympathy
    for i = 1, #kingdom do table.insert(self.regions, kingdom[i]) end
end

--v function(self: GEOPOLITICS, behaviour_key: string, callback: function(faction: string, other_faction: string, regions_lost: number, regions_conquered: number, region_moved: string))
function geopolitics.add_expanding_behaviour(self, behaviour_key, callback)
    self.kingdom_expands_responses[behaviour_key] = callback
end

--v function(self: GEOPOLITICS, behaviour_key: string, callback: function(faction: string, other_faction: string, regions_lost: number, regions_conquered: number, region_moved: string))
function geopolitics.add_threatened_behaviour(self, behaviour_key, callback)
    self.kingdom_threatened_responses[behaviour_key] = callback
end

--v function(self: GEOPOLITICS, faction: string, behaviours: vector<string>)
function geopolitics.whitelist_behaviours_for_faction(self, faction, behaviours)
    self.use_behaviour_whitelist = true
    self.faction_to_permitted_behaviours[faction] = behaviours
end

--v function(self: GEOPOLITICS, thinker: string, other_faction: string, regions_to_consider: vector<string>, other_factions_regions: vector<string>, region_moved: string)
function geopolitics.think(self, thinker, other_faction, regions_to_consider, other_factions_regions, region_moved)

    local regions_owned = 0
    local regions_total = #regions_to_consider + #other_factions_regions
    local regions_conquered = 0
    local regions_lost = 0
    local was_loss = false --:boolean
    for i = 1, #regions_to_consider do
        local region = dev.get_region(regions_to_consider[i])
        if region:owning_faction():name() == thinker then
            regions_owned = regions_owned + 1;
            
        else
            regions_lost = regions_lost + 1;
            if region_moved == region:name() then
                was_loss = true
            end
        end
    end
    local white_list = {}
    local was_event = false --:boolean
    --fire behaviours
    if was_loss then
        if not self.use_behaviour_whitelist then
            for behaviour, callback in pairs(self.kingdom_threatened_responses) do
                was_event = callback(thinker, other_faction, regions_lost, regions_conquered, region_moved) or false
            end
        else
            for i = 1, #self.faction_to_permitted_behaviours[thinker] do
                local callback = self.kingdom_threatened_responses[self.faction_to_permitted_behaviours[thinker][i]]
                was_event = callback(thinker, other_faction, regions_lost, regions_conquered, region_moved) or false
            end
        end
    else
        if not self.use_behaviour_whitelist then
            for behaviour, callback in pairs(self.kingdom_expands_responses) do
                was_event = callback(thinker, other_faction, regions_lost, regions_conquered, region_moved) or false
            end
        else
            for i = 1, #self.faction_to_permitted_behaviours[thinker] do
                local callback = self.kingdom_expands_responses[self.faction_to_permitted_behaviours[thinker][i]]
                was_event = callback(thinker, other_faction, regions_lost, regions_conquered, region_moved) or false
            end
        end
    end
    if was_event then
        return
    end
    --if the faction who just took this region is someones vassal
    if (was_loss and PettyKingdoms.VassalTracking.is_faction_vassal(other_faction)) or (not was_loss and PettyKingdoms.VassalTracking.is_faction_vassal(thinker)) then
        local liege = PettyKingdoms.VassalTracking.get_faction_liege(thinker)
        if was_loss then
            local liege = PettyKingdoms.VassalTracking.get_faction_liege(other_faction)
        end
        if dev.get_faction(liege):is_human() then
            dev.eh:trigger_event("RegionCapturedByHumansVassal")
            --did this region used to belong to our liege?
            if self.faction_lost_regions[liege][region_moved]
            and self.faction_lost_regions[liege][region_moved] > cm:model():turn_number() - vassal_recovery_window then
                --does our liege still own the capital nearby?
                local capital = Gamedata.regions.get_province_capital_of_regions_province(region_moved)
                local owns_region = capital:owning_faction():name() == liege
                if not owns_region then
                    --or have a region bordering this one
                    for k = 0, capital:adjacent_region_list():num_items() do
                        if capital:adjacent_region_list():item_at(k):owning_faction() == liege then
                            owns_region = true
                        end
                    end
                end
                if owns_region then
                    cm:trigger_incident(liege, vassal_recovery_event, true)
                    cm:transfer_region_to_faction(region_moved, liege)
                    return
                end
            end
        end
    end
    --if the faction who just took this region is a humans ally
    local is_human = false --:boolean
    local humans = cm:get_human_factions()
    for i = 1, #humans do
        local human = humans[i]
        local ally = thinker
        if was_loss then
            ally = other_faction
        end
        if dev.get_faction(human):is_ally_vassal_or_client_state_of(ally) then
            --did this region used to belong to our liege?
            if self.faction_lost_regions[human][region_moved]
            and self.faction_lost_regions[human][region_moved] > cm:model():turn_number() - ally_recovery_window then
                --does our human still own the capital nearby?
                local capital = Gamedata.regions.get_province_capital_of_regions_province(region_moved)
                local owns_region = capital:owning_faction():name() == human
                if not owns_region then
                    --or have a region bordering this one
                    for k = 0, capital:adjacent_region_list():num_items() do
                        if capital:adjacent_region_list():item_at(k):owning_faction() == human then
                            owns_region = true
                        end
                    end
                end
                if owns_region then
                    cm:trigger_incident(human, vassal_recovery_event, true)
                    cm:transfer_region_to_faction(region_moved, human)
                    return
                end
            end
        end
    end

end


--v function(self: GEOPOLITICS)
function geopolitics.activate(self)

    for i = 1, #self.regions do self.regions_active[self.regions[i]] = true end
    for faction_key, region_list in pairs(self.faction_kingdom_regions) do
        for j = 0, dev.get_faction(faction_key):region_list():num_items() - 1 do
            local region = dev.get_faction(faction_key):region_list():item_at(j)
            self.faction_controlled_regions[faction_key] = self.faction_controlled_regions[faction_key] or {}
            self.faction_controlled_regions[faction_key][region:name()] = cm:model():turn_number()
        end
        dev.eh:add_listener(
            "GeopoliticsRegionChangesOwnership",
            "RegionChangesOwnership",
            function(context)
                return context:prev_faction():name() == faction_key
            end,
            function(context)
                local region = context:region()
                local other_faction = region:owning_faction():name()
                local faction_key = context:prev_faction():name() 
                self.faction_lost_regions[faction_key] = self.faction_lost_regions[faction_key] or {}
                self.faction_lost_regions[faction_key][region:name()] = cm:model():turn_number()
                self.faction_controlled_regions[faction_key] = self.faction_controlled_regions[faction_key] or {}
                self.faction_controlled_regions[faction_key][region:name()] = nil
                self:think(faction_key, other_faction, self.faction_kingdom_regions[faction_key], self.faction_kingdom_regions[other_faction], region:name())
            end,
            true)
        dev.eh:add_listener(
            "GeopoliticsRegionChangesOwnership",
            "RegionChangesOwnership",
            function(context)
                return context:region():owning_faction():name() == faction_key
            end,
            function(context)
                local faction_key = context:region():owning_faction():name()
                local region = context:region()
                local other_faction = context:prev_faction():name()
                self.faction_controlled_regions[faction_key] = self.faction_controlled_regions[faction_key] or {}
                self.faction_controlled_regions[faction_key][region:name()] = cm:model():turn_number()
                self.faction_lost_regions[faction_key] = self.faction_controlled_regions[faction_key] or {}
                self.faction_lost_regions[faction_key][region:name()] = nil
                self:think(faction_key, other_faction, self.faction_kingdom_regions[faction_key], self.faction_kingdom_regions[other_faction], region:name())
            end,
            true)
    end
end


local instances = {}--:map<string, GEOPOLITICS> 

return {
    new = function(name) --:string
        instances[name] = geopolitics.new(name)
        return instances[name]
    end,
    get = function(name) --:string
        return instances[name] or geopolitics.new(name)
    end
}