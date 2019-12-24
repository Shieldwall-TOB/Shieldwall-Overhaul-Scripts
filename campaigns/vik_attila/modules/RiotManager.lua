local riot_manager = {} --# assume riot_manager:RIOT_MANAGER

local riot_events = {} --:map<string, {condition: (function(rioting_region: RIOT_MANAGER) --> boolean), response: function(context: WHATEVER), is_dilemma: boolean}>

local riot_begins_event = "shield_rebellion_rioting_" --:string
local riot_ends_event = "shield_rioting_ends_" --:string
local riot_duration = 10 --:number

--v function(region_key: string) --> RIOT_MANAGER
function riot_manager.new(region_key)
    local self = {}
    setmetatable(self, {
        __index = riot_manager
    }) --# assume self: RIOT_MANAGER
    self.key = region_key
    --riots
    self.riot_in_progress = false --:boolean
    self.riot_timer = 0 --:number
    self.riot_event_cooldown = 0 --:number
    self.last_riot_event = "none" --:string
    --save schema
    self.save = {
        name = self.key .. "_detail",
        for_save = {
             "riot_in_progress", "riot_timer", "riot_event_cooldown", "last_riot_event"
        }, 
    }
    Save.attach_to_object(self)
    return self
end

--v function(self: RIOT_MANAGER, t: any)
function riot_manager.log(self, t)
    dev.log(tostring(t), self.key)
end

--v function(self: RIOT_MANAGER) --> CA_REGION
function riot_manager.get_region(self)
    return dev.get_region(self.key)
end

--v function(self: RIOT_MANAGER) --> number
function riot_manager.public_order(self)
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

--v function(self: RIOT_MANAGER, public_order: number) --> boolean
function riot_manager.should_riot_start(self, public_order)
    local faction = dev.get_region(self.key):owning_faction()
    local roll = cm:random_number(100)
	self:log("Checking if region can rebel with a -PO ["..public_order.."]. They rolled ["..roll.."] ")
	if public_order > roll then -- public order / 100 chance
		self:log("Chance check passed")
		local character_list = faction:character_list()
		for i = 0, character_list:num_items() - 1 do
			local character = character_list:item_at(i)
			if dev.is_char_normal_general(character) and (not character:region():is_null_interface()) and character:region():name() == self.key then
				local size = 0 --:number
				local army = character:military_force()
				for j = 0, army:unit_list():num_items() - 1 do
					size = size + army:unit_list():item_at(j):percentage_proportion_of_full_strength()
				end
				self:log("Character with army ["..size.."] found in region")
				if size > 500 then
					return false --cannot rebel if an army of 6 or more units is around.
				end
			end
		end
		self:log("Checks passed, region can rebel")
		return true
	end
	return false
end


--v function(self: RIOT_MANAGER, owning_faction: CA_FACTION)
function riot_manager.start_riot(self, owning_faction)
    self.riot_in_progress = true
    self.riot_timer = riot_duration
    local faction_name = owning_faction:name()
    cm:trigger_incident(faction_name, riot_begins_event..self.key, true)
end

--v function(self: RIOT_MANAGER)
function riot_manager.end_riot(self)

end

--v function(self: RIOT_MANAGER)
function riot_manager.find_valid_riot_event(self)
    local owner = dev.get_region(self.key):owning_faction()
    if not owner:is_human() then
        return
    end
    for prefix, event_info in pairs(riot_events) do
        local ok = event_info.condition(self)
        if ok then
            local incident = prefix..self.key
            self:log("Found valid riot event: "..incident)
            if event_info.is_dilemma then
                if event_info.response then
                    dev.respond_to_incident(incident, event_info.response)
                end
                return
            end
            if event_info.response then
                dev.respond_to_incident(incident, event_info.response)
            end
            cm:trigger_incident(owner:name(), incident, true)
        end
    end
end

--v function(self: RIOT_MANAGER)
function riot_manager.new_turn(self)
    local region = self:get_region()
    local region_name = region:name()
    local public_order = self:public_order()
    local owning_faction = region:owning_faction()
    self:log("Starting turn!")
    if self.riot_in_progress then
        --we are rioting!
        self.riot_timer = self.riot_timer - 1 
        if public_order > 0 or self.riot_timer <= 0 then
            self:end_riot()
        elseif self.riot_event_cooldown <= 0 then
            --riot should continue with an event
            self:find_valid_riot_event()
        else
            --riot should reduce cooldowns and continue with no event.
            self.riot_event_cooldown = self.riot_event_cooldown - 1
        end
    elseif public_order < 0 and self:should_riot_start(-1*public_order) then
        --no riot present, and check passed
        self:start_riot(owning_faction)
    end

end

local instances = {} --:map<string, RIOT_MANAGER>
dev.first_tick(function(context)
    local region_list = dev.region_list()
    for i = 0, region_list:num_items() - 1 do
        local region = region_list:item_at(i)
        instances[region:name()] = riot_manager.new(region:name())
    end
    dev.eh:add_listener(
        "RiotManagerRegionChangesOwnership",
        "RegionChangesOwnership",
        true,
        function(context)
            local detail = instances[context:region():name()]
            --reset riot handling
            detail.riot_in_progress = false
            detail.riot_event_cooldown = 0
            detail.riot_timer = 0
        end,
        true)
    dev.eh:add_listener(
        "RiotManagerRegionTurnStart",
        "RegionTurnStart",
        true,
        function(context)
            local detail = instances[context:region():name()]:new_turn()
        end,
        true)
end)

--v function(key: string) --> RIOT_MANAGER
local function get_riot_manager(key)
    return instances[key]
end

--v function(event_prefix: string, conditional: (function(rioting_region: RIOT_MANAGER) --> boolean), response_func: (function(context: WHATEVER)), is_dilemma: boolean?) 
local function add_riot_event(event_prefix, conditional, response_func, is_dilemma)
    riot_events[event_prefix] = {condition = conditional, response = response_func, is_dilemma = not not is_dilemma}
end


return {
    get = get_riot_manager,
    add_event = add_riot_event
}