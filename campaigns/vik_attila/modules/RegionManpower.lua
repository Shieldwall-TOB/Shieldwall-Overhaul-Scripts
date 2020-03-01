local region_manpower = {} 
--# assume region_manpower: REGION_MANPOWER

local mod_functions = {} --:map<string, function(faction_key: string, factor_key: string, change: number)>

--basic info
local lord_effect_reduction = 0.5
local lord_cap_proportion = 0.5

--change values
local natural_recovery_rate = 4
local occupation_loss = -30
local sack_loss = -60
local raid_loss = -10
local monk_training_rate = 1

local estate_sizes = {} --:map<string, number>
local settlement_sizes = {} --:map<string, number>
local monastery_sizes = {} --:map<string, number>

--v function(key: string, base_serf: number, base_lord: number) --> REGION_MANPOWER
function region_manpower.new(key, base_serf, base_lord)
    local self = {}
    setmetatable(self, {
        __index = region_manpower
    }) --# assume self: REGION_MANPOWER
    self.key = key

    self.base_serf = base_serf 
    self.base_lord = dev.mround(base_lord*lord_cap_proportion, 1) --:number
    self.loss_cap = 100 --:number
    

    self.settlement_serf_bonus = 0 --:number
    self.estate_lord_bonus = 0 --:number

    self.monk_pop = 0 --:number
    self.monk_cap = 0 --:number

    self.save = {
        name = self.key .. "_manpower",
        for_save = {
             "loss_cap", "settlement_serf_bonus", "estate_lord_bonus", "monk_pop", "monk_cap"
        }, 
    }
    dev.Save.attach_to_object(self)
    return self
end

--v function(self: REGION_MANPOWER, change: number) --> number
function region_manpower.mod_loss_cap(self, change)
    local old_cap = self.loss_cap
    self.loss_cap = dev.clamp(self.loss_cap + change , 0, 100)
    return (self.loss_cap - old_cap)/100
end

--v function(self: REGION_MANPOWER, change: number, factor: string, serfs: boolean, lords: boolean)
function region_manpower.mod_population_through_region(self, change, factor, serfs, lords)
    local loss_percent = self:mod_loss_cap(change)
    local owning_faction = dev.get_region(self.key):owning_faction()
    if owning_faction:is_human() then
        if mod_functions.serf and serfs then
            local loss = dev.mround(self.base_serf*loss_percent, 1)
            mod_functions.serf(owning_faction:name(), factor, loss)
        end
        if mod_functions.lord and lords then
            local loss = dev.mround(self.base_lord*loss_percent*lord_effect_reduction, 1)
            mod_functions.lord(owning_faction:name(), factor, loss)
        end
    end
end

--v function(self: REGION_MANPOWER, change: number, mod: boolean?, factor: string?)
function region_manpower.mod_monks(self, change, mod, factor)
    local old = self.monk_pop
    self.monk_pop = dev.mround(dev.clamp(self.monk_pop + change, 0, self.monk_cap), 1)
    local real_change = self.monk_pop - old
    if mod and factor and mod_functions.monk then
        --# assume factor: string
        mod_functions.monk(dev.get_region(self.key):owning_faction():name(), factor, real_change)
    end
end

--v function(self: REGION_MANPOWER)
function region_manpower.update_monk_cap(self)
    local slot_list = dev.get_region(self.key):settlement():slot_list()
    local cap = 0 --:number
    for i = 0, slot_list:num_items() - 1 do 
        local slot = slot_list:item_at(i)
        if slot:has_building() then
            local key  = slot:building():name()
            if monastery_sizes[key] then
                cap = cap + monastery_sizes[key]
            end
        end
    end
    self.monk_cap = cap
end

local instances = {} --:map<string, REGION_MANPOWER>

dev.first_tick(function (context)
    local region_list = dev.region_list()
    for i = 0, region_list:num_items() - 1 do
        local current_region = region_list:item_at(i)
        local base_pop = Gamedata.base_pop.region_values[current_region:name()] or {serf = 150, lord = 50}
        local instance = region_manpower.new(current_region:name(), base_pop.serf, base_pop.lord)
        instances[current_region:name()] = instance
        instance:update_monk_cap()
    end
    dev.eh:add_listener(
        "ManpowerRegionChangesOwner",
        "RegionChangesOwnership",
        true,
        function(context)
            --when a region changes ownership, add its base pop and also some occupation loss. Remove the base pop from whoever is losing the region.
            local rmp = instances[context:region():name()]
            local old_loss_cap_perc = rmp.loss_cap/100
            local lost_perc = rmp:mod_loss_cap(occupation_loss)
            local old_faction = context:prev_faction()
            local new_faction = context:region():owning_faction()
            local current_region = context:region() --:CA_REGION
            local old_monks = rmp.monk_pop
            rmp:update_monk_cap()
            rmp:mod_monks(rmp.monk_pop*occupation_loss/100)
            if new_faction:is_human() then
                if mod_functions.serf then
                    local loss = dev.mround(rmp.base_serf*lost_perc, 1)
                    mod_functions.serf(new_faction:name(), "manpower_region_sacked_or_occupied", loss)
                    mod_functions.serf(new_faction:name(), "manpower_region_population", rmp.base_serf)
                end
                if mod_functions.lord then
                    local loss = dev.mround(rmp.base_lord*lost_perc*lord_effect_reduction, 1)
                    mod_functions.lord(new_faction:name(), "manpower_region_sacked_or_occupied", loss)
                    local lord_region_factor = rmp.base_lord 
                    local lord_allegiance_factor = 0 --:number
                    if current_region:majority_religion() == new_faction:state_religion() then
                        lord_allegiance_factor = lord_allegiance_factor + (current_region:majority_religion_percentage()/100)*rmp.base_lord
                    else
                        lord_allegiance_factor = lord_allegiance_factor - dev.mround(rmp.base_lord/2, 1)
                    end
                    mod_functions.lord(new_faction:name(), "manpower_region_population", rmp.base_lord)
                    mod_functions.lord(new_faction:name(), "manpower_region_allegiance", lord_allegiance_factor)
                end
                if mod_functions.monk then
                    mod_functions.monk(new_faction:name(), "monk_gained_settlements", rmp.monk_pop)
                end
            end
            if old_faction:is_human() then
                if mod_functions.serf then
                    mod_functions.serf(old_faction:name(), "manpower_region_population", dev.mround(rmp.base_serf*-1*old_loss_cap_perc, 1))
                end
                if mod_functions.lord then
                    --loss the regions manpower
                    mod_functions.lord(old_faction:name(), "manpower_region_population", dev.mround(rmp.base_lord*-1*old_loss_cap_perc, 1))
                    local lord_allegiance_factor = 0 --:number
                    if current_region:majority_religion() == old_faction:state_religion() then
                        lord_allegiance_factor = lord_allegiance_factor + (current_region:majority_religion_percentage()/100)*rmp.base_lord
                    else
                        lord_allegiance_factor = lord_allegiance_factor - dev.mround(rmp.base_lord/2, 1)
                    end
                    --loss all allegiance from this region
                    mod_functions.lord(old_faction:name(), "manpower_region_allegiance", -1*lord_allegiance_factor)
                end
                if mod_functions.monk then
                    mod_functions.monk(old_faction:name(), "monk_lost_settlements", old_monks)
                end
                if Gamedata.base_pop.slaves_factions[old_faction:name()] then
                    --TODO slaves
                end
            end
        end,
        true)
    dev.eh:add_listener(
        "ManpowerRegionTurnStart",
        "RegionTurnStart",
        true,
        function(context)
            local rmp = instances[context:region():name()]
            rmp:mod_loss_cap(natural_recovery_rate)
            if context:region():owning_faction():is_human() then
                rmp:update_monk_cap()
                rmp:mod_monks(monk_training_rate, true, "monk_training")
            end
            if Gamedata.base_pop.slaves_factions[context:region():owning_faction():name()] then
                --TODO slaves
            end
        end,
        true)
    dev.eh:add_listener(
        "ManpowerCharacterRaiding",
        "CharacterTurnEnd",
        function(context)
            local char = context:character()
            return (not char:region():is_null_interface()) and (not char:military_force():is_null_interface())
            and (char:military_force():active_stance() == "MILITARY_FORCE_ACTIVE_STANCE_TYPE_LAND_RAID")
        end,
        function(context)
            local rmp = instances[context:character():region():name()]
            local lost_perc = rmp:mod_loss_cap(raid_loss)
            local owning_faction = context:character():region():owning_faction()
            if owning_faction:is_human() then
                if mod_functions.serf then
                    local loss = dev.mround(rmp.base_serf*lost_perc, 1)
                    mod_functions.serf(owning_faction:name(), "manpower_region_raided", loss)
                end
                if mod_functions.lord then
                    local loss = dev.mround(rmp.base_lord*lost_perc*lord_effect_reduction, 1)
                    mod_functions.lord(owning_faction:name(), "manpower_region_raided", loss)
                end
                --TODO add monks here
                if Gamedata.base_pop.slaves_factions[owning_faction:name()] then
                    --TODO slaves
                end
            end
        end,
        true
    )
    dev.eh:add_listener(
        "ManpowerCharacterPerformsOccupationDecisionSack",
        "CharacterPerformsOccupationDecisionSack",
        true,
        function(context)
            local region = dev.closest_settlement_to_char(context:character())
            local owning_faction = dev.get_region(region):owning_faction()
            if cm:model():turn_number() - dev.last_time_sacked(region) > 1 then
                local rmp = instances[region]
                local lost_perc = rmp:mod_loss_cap(sack_loss)
                if owning_faction:is_human() then
                    if mod_functions.serf then
                        local loss = dev.mround(rmp.base_serf*lost_perc, 1)
                        mod_functions.serf(owning_faction:name(), "manpower_region_sacked_or_occupied", loss)
                    end
                    if mod_functions.lord then
                        local loss = dev.mround(rmp.base_lord*lost_perc*lord_effect_reduction, 1)
                        mod_functions.lord(owning_faction:name(), "manpower_region_sacked_or_occupied", loss)
                    end
                end
                rmp:update_monk_cap()
                rmp:mod_monks(-1*rmp.monk_pop, true, "monk_sacking")
            end
            if context:character():faction():is_human() and Gamedata.base_pop.slaves_factions[context:character():faction():name()] then
                    --TODO slaves
            end
        end,
        true)
end)



--v function(pop_type: string, mod: function(faction_key: string, factor_key: string, change: number))
local function add_mod_for_pop_type(pop_type, mod)
    mod_functions[pop_type] = mod
end


--v function(settlement: string, size: number)
local function set_settlement_size(settlement, size)
    settlement_sizes[settlement] = size
end

--v function(estate: string, size: number)
local function set_estate_size(estate, size)
    estate_sizes[estate] = size
end

--v function(monastery: string, size: number)
local function set_monastery_size(monastery, size)
    monastery_sizes[monastery] = size
end

--v function(region_name: string) --> REGION_MANPOWER
local function get_region_manpower(region_name)
    return instances[region_name]
end


return {
    activate = add_mod_for_pop_type,
    add_settlement_pop_bonus = set_settlement_size,
    add_estate_pop_bonus = set_estate_size,
    add_monastery_pop_cap = set_monastery_size,
    get = get_region_manpower
}