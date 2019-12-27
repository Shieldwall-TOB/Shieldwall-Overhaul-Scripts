local region_manpower = {} 
--# assume region_manpower: REGION_MANPOWER

--basic info
local serf_min_mult = 20
local serf_max_mult = 135
local lord_min_mult = 50
local lord_max_mult = 100
local lord_effect_reduction = 0.5

--change values
local natural_recovery_rate = 4
local occupation_loss = -30
local sack_loss = -60
local raid_loss = -10

local estate_sizes = {} --:map<string, number>
local settlement_sizes = {} --:map<string, number>

--v function(key: string, base_serf: number, base_lord: number) --> REGION_MANPOWER
function region_manpower.new(key, base_serf, base_lord)
    local self = {}
    setmetatable(self, {
        __index = region_manpower
    }) --# assume self: REGION_MANPOWER
    self.key = key
    self.base_serf = base_serf/100 --:number
    self.base_lord = base_lord/100 --:number
    self.serf_multi = 100 --:number
    self.lord_multi = 100 --:number

    self.settlement_serf_bonus = 0 --:number
    self.estate_lord_bonus = 0 --:number

    self.save = {
        name = self.key .. "_manpower",
        for_save = {
             "serf_multi", "lord_multi", "settlement_serf_bonus", "estate_lord_bonus"
        }, 
    }
    Save.attach_to_object(self)
    return self
end

--v function(self: REGION_MANPOWER, change: number)
function region_manpower.mod_manpower(self, change)
    self.serf_multi = dev.clamp(self.serf_multi + change , serf_min_mult, serf_max_mult+self.settlement_serf_bonus)
    self.lord_multi = dev.clamp(self.lord_multi + (change*lord_effect_reduction), lord_min_mult, lord_max_mult)
end

--v function(self: REGION_MANPOWER, change: number)
function region_manpower.mod_serf_manpower_only(self, change)
    self.serf_multi = dev.clamp(self.serf_multi + change , serf_min_mult, serf_max_mult+self.settlement_serf_bonus)
end

--v function(self: REGION_MANPOWER, change: number)
function region_manpower.mod_lord_(self, change)
    self.lord_multi = dev.clamp(self.serf_multi + (change*lord_effect_reduction), lord_min_mult, lord_max_mult)
end


local instances = {} --:map<string, REGION_MANPOWER>

dev.first_tick(function(context)
    local region_list = dev.region_list()
    for i = 0, region_list:num_items() - 1 do
        local current_region = region_list:item_at(i)
        local base_pop = Gamedata.base_pop[current_region:name()] or {serf = 150, lord = 50}
        local instance = region_manpower.new(current_region:name(), base_pop.serf, base_pop.lord)
        instances[current_region:name()] = instance
    end
    dev.eh:add_listener(
        "ManpowerRegionChangesOwner",
        "RegionChangesOwnership",
        true,
        function(context)
            local rmp = instances[context:region():name()]
            rmp:mod_manpower(occupation_loss)
        end,
        true)
    dev.eh:add_listener(
        "ManpowerRegionTurnStart",
        "RegionTurnStart",
        true,
        function(context)
            local rmp = instances[context:region():name()]
            rmp:mod_manpower(natural_recovery_rate)
        end,
        true)
    dev.eh:add_listener(
        "ManpowerCharacterRaiding",
        "CharacterTurnStart",
        function(context)
            local char = context:character()
            return (not char:region():is_null_interface()) and (not char:military_force():is_null_interface())
            and (char:military_force():active_stance() == "MILITARY_FORCE_ACTIVE_STANCE_TYPE_LAND_RAID")
        end,
        function(context)
            local rmp = instances[context:character():region():name()]
            rmp:mod_manpower(raid_loss)
        end,
        true
    )
    dev.eh:add_listener(
        "ManpowerCharacterPerformsOccupationDecisionSack",
        "CharacterPerformsOccupationDecisionSack",
        true,
        function(context)
            local region = dev.closest_settlement_to_char(context:character())
            if cm:model():turn_number() - dev.last_time_sacked(region) > 1 then
                local rmp = instances[region]
                rmp:mod_manpower(sack_loss)
            end
        end,
        true)
end)






--v function(settlement: string, size: number)
local function set_settlement_size(settlement, size)
    settlement_sizes[settlement] = size
end

--v function(estate: string, size: number)
local function set_estate_size(estate, size)
    estate_sizes[estate] = size
end

--v function(region_name: string) --> REGION_MANPOWER
local function get_region_manpower(region_name)
    return instances[region_name]
end

return {
    add_settlement_pop_bonus = set_settlement_size,
    add_estate_pop_bonus = set_estate_size,
    get = get_region_manpower
}