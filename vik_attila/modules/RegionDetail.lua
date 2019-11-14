local region_detail = {} --# assume region_detail:REGION_DETAIL

--v function(savedata: string) --> map<string, number>
local function pop_load_specifier(savedata)
    local split_first = dev.split_string(savedata, ";")
    local ret = {} --:map<string, number>
    for i = 1, #split_first do
        local split_record = dev.split_string(split_first[i], ",")
        ret[split_record[1]] = tonumber(split_record[2])
    end
    return ret
end


--v function(region_key: string, base_pop: map<string, number>?) --> REGION_DETAIL
function region_detail.new(region_key, base_pop)
    local self = {}
    setmetatable(self, {
        __index = region_detail
    }) --# assume self: REGION_DETAIL
    local base_pop = base_pop or {} --# assume base_pop:map<string, number>
    self.key = region_key
    --tracking
    self.last_sacked_turn = 999 --:number
    self.last_ownership_change = 999 --:number
    self.last_build_turn = 999 --:number
    self.last_diaster = 999 --:number
    --riots
    self.riot_in_progress = false --:boolean
    self.riot_timer = 0 --:number
    self.riot_event_cooldown = 0 --:number
    --population
    self.thriving = 0 --:number
    self.thrive_causes = {} --:map<string, number>
    self.has_serfs = not not base_pop["serf"] --:boolean
    self.base_serf_pop = base_pop["serf"] or 100
    self.serf = self.base_serf_pop

    self.has_nobles = not not base_pop["noble"] --:boolean 
    self.base_noble_pop = base_pop["noble"] or 100
    self.noble = self.base_noble_pop

    --these serve as an extra resource to protect, and when you sack a city that does have monks, it can trigger extra events.
    self.has_monks = false
    self.monk = 0
    self.monk_cap = 0
    --save schema
    self.save = {
        name = self.key .. "_detail",
        for_save = {
            "last_sacked_turn", "last_ownership_change", "riot_in_progress", "riot_timer", "riot_event_cooldown",
            "thriving", "thrive_causes", "serfs", "noble", "monk"
        }, 
    }
    Save.attach_to_object(self)
    return self
end

--v function(self: REGION_DETAIL, t: any)
function region_detail.log(self, t)
    dev.log(tostring(t), self.key)
end

--v function(self: REGION_DETAIL) --> CA_REGION
function region_detail.get_region(self)
    return dev.get_region(self.key)
end

--v function(self: REGION_DETAIL) --> number
function region_detail.public_order(self)
    local region = self:get_region()
    return region:sanitation() - region:squalor()
end

--v function(total_food: number) --> (number, string)
local function get_food_effect(total_food)
    local thresholds_to_returns = {
        [-150] = {-5, "Famine"}, --min food, famine
        [-50] = {-3, "Food Shortages"},
        [0] = {-2, "Food Shortages"},
        [100] = {1, "Food Surplus"}, --default level
        [250] = {2, "Food Surplus"}
    }--:map<number, {number, string}>
    local thresholds = {-150, -50, 0, 100, 250} --:vector<number>
    for n = 1, #thresholds do
        if total_food < thresholds_to_returns[thresholds[n]][1] then
            return thresholds_to_returns[thresholds[n]][1], thresholds_to_returns[thresholds[n]][2]
        end
    end
    --if we are above 250 food
    return 3, "Food Surplus"
end


--v function(self: REGION_DETAIL) --> (number, map<string, number>)
function region_detail.thrive_score(self)
    local ret = {} --:map<string, number>
    local region = self:get_region()
    local region_name = region:name()
    local public_order = self:public_order()
    local owning_faction = region:owning_faction()
    local turn = cm:model():turn_number() 
    local thrive_score = 0 --:number
    if owning_faction:is_null_interface() or owning_faction:is_dead() then
        self:log("Aborting population processing due to invalid owning faction state")
        return 0, ret
    end
    local total_food = owning_faction:total_food()
    --v function(k: string, n:number)
    local function alter_thrive_score(k, n)
        thrive_score = thrive_score + n
        ret[k] = n
    end
    --public order
    if self.riot_in_progress then
        --rioting hurts prosperity a lot
        alter_thrive_score("Rioting", - 3)
    elseif public_order > 0 then
        --happiness boosts it moderately
        alter_thrive_score("Happy Populace", 2)
    else
        --unhapinness hurts it minorly
        alter_thrive_score("Unhappy Populace", -1)
    end

    --food
    local effect, reason = get_food_effect(total_food)
    alter_thrive_score(reason, effect)

    --sack
    local sack_difference = turn - self.last_sacked_turn
    if sack_difference < 3 then
        --sacked very recently
        alter_thrive_score("Recently Sacked", -5)
    elseif sack_difference < 12 then
        --sacked this year
        alter_thrive_score("Recently Sacked", -3)
    end

    --building
    local building_difference = turn - self.last_build_turn
    if building_difference < 12 then
        alter_thrive_score("Economic Development", 2)
    end
    
    --occupation
    local occupation_difference = turn - self.last_build_turn
    if occupation_difference < 12 then
        alter_thrive_score("Recently Occupied", -2)
    end

    --events
    local events_difference = turn - self.last_diaster
    if events_difference < 12 then
        alter_thrive_score("Recent Events", -1)
    end

    return thrive_score, ret
end


--v function(self: REGION_DETAIL)
function region_detail.new_turn(self)
    local region = self:get_region()
    local region_name = region:name()
    local public_order = self:public_order()
    local owning_faction = region:owning_faction()
    self:log("Starting turn!")
    if self.riot_in_progress then
        --we are rioting!
        if public_order > 0 then
            --riot should end
        elseif self.riot_event_cooldown == 0 then
            --riot should continue with an event
        else
            --riot should reduce cooldowns and continue with no event.
        end
    else
        --no riot present
    end

    local thrive_score, causes = self:thrive_score()
    if self.thriving < 0 then
        if thrive_score < 0 then
            self.thriving = self.thriving - 1
        elseif thrive_score > 0 then
            self.thriving = 1
        end
    elseif self.thriving > 0 then
        if thrive_score > 0  then
            self.thriving = self.thriving + 1
        elseif thrive_score < 0 then
            self.thriving = -1
        end
    else --region is neither trending down nor up
        if thrive_score > 0 then
            self.thriving = 1
        elseif thrive_score < 0 then
            self.thriving = -1
        end
    end
    self.thrive_causes = causes
    local serf_change = 0
    local monk_change = 0
    local noble_change = 0
    if self.thriving < -1 then
        --start losing population after two turns at a rate of 3% of base per turn
        if self.has_serfs then
            serf_change = dev.mround((self.base_serf_pop / 100)*-3, 1)
        end
        if self.has_nobles then
            noble_change = dev.mround((self.base_noble_pop / 100)*-3, 1)
        end
        --monks are only lost directly when being sacked or occupied.
    elseif self.thriving > 1 then
        --start gaining population after two turns
        --4% for peasants
        if self.has_serfs then
            serf_change = dev.mround((self.base_serf_pop / 100)*4, 1)
        end
        --2% for lords
        if self.has_nobles then
            noble_change = dev.mround((self.base_noble_pop /100)*2, 1)
        end
        --either 1 monk per turn or 5% of monk_cap to a max of 8
        if self.has_monks and self.monk_cap > 0 then
            monk_change = dev.mround(dev.clamp((self.monk_cap /100)*5, 1, 8), 1)
        end
    end
    --set the new regional populations    
    if self.has_serfs then
        local min = dev.mround(self.base_serf_pop*0.55, 1)
        local max = dev.mround(self.base_serf_pop*1.35, 1)
        local old_value = self.serf
        self.serf = dev.mround(dev.clamp(self.serf+serf_change, min,max), 1)
        dev.eh:trigger_event("RegionDetailPopulationChanged", dev.get_region(self.key), "serf", {new = self.serf, old = old_value, cap = max})
    end
    if self.has_nobles then
        local min = dev.mround(self.base_noble_pop*0.55, 1)
        local max = dev.mround(self.base_noble_pop*1.35, 1)
        local old_value = self.noble
        self.noble = dev.mround(dev.clamp(self.noble+noble_change, min,max), 1)
        dev.eh:trigger_event("RegionDetailPopulationChanged", dev.get_region(self.key), "noble", {new = self.noble, old = old_value, cap = max})
    end
    if self.has_monks then
        local old_value = self.monk
        self.monk = dev.mround(dev.clamp(self.monk+monk_change, 0, self.monk_cap), 1)
        dev.eh:trigger_event("RegionDetailPopulationChanged", dev.get_region(self.key), "monk", {new = self.monk, old = old_value, cap = self.monk_cap})
    end
end

local instances = {} --:map<string, REGION_DETAIL>
dev.first_tick(function(context)
    local region_list = dev.region_list()
    for i = 0, region_list:num_items() - 1 do
        local region = region_list:item_at(i)
        instances[region:name()] = region_detail.new(region:name())
    end
    dev.eh:add_listener(
        "RegionDetailCharacterPerformsOccupationDecisionSack",
        "CharacterPerformsOccupationDecisionSack",
        function(context)
            return not context:character():region():is_null_interface()
        end,
        function(context)
            local detail = instances[context:character():region():name()]
            detail.last_sacked_turn = cm:model():turn_number()
        end,
        true)
    dev.eh:add_listener(
        "RegionDetailRegionChangesOwnership",
        "RegionChangesOwnership",
        true,
        function(context)
            local detail = instances[context:region():name()]
            detail.last_ownership_change = cm:model():turn_number()
            --reset riot handling
            detail.riot_in_progress = false
            detail.riot_event_cooldown = 0
            detail.riot_timer = 0
        end,
        true)
    --TODO more listeners for the rest of this object's tracking.
end)

--v function(key: string) --> REGION_DETAIL
local function get_region_detail(key)
    return instances[key]
end


return {
    get = get_region_detail
}