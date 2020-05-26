local game_event_manager = {} --# assume game_event_manager: GAME_EVENT_MANAGER

--v function(self: GAME_EVENT_MANAGER, t: any)
function game_event_manager.log(self, t)
    dev.log(tostring(t), "EVENTS")
end

local queue_times = {
    "FactionTurnStart", "CharacterTurnStart", "RegionTurnStart", "CharacterCompletedBattle"
} --:vector<GAME_EVENT_QUEUE_TIMES>

local default_groups = {"dilemma", "incident", "mission"}

function game_event_manager.new()

    local self = {}
    setmetatable(self, {
        __index = game_event_manager
    }) --# assume self: GAME_EVENT_MANAGER

    --maps event keys to their event object
    self.events = {} --:map<string, GAME_EVENT>
    self.condition_groups = {} --:map<string, EVENT_CONDITION_GROUP>
    --maps event keys to their most recent position in the queue.
    self.queue_map = {} --:map<string, int>
    --holds the actual queue
    self.event_queue = {} --:vector<QUEUED_GAME_EVENT>

    self.schedule = {} --:map<GAME_EVENT_QUEUE_TIMES, vector<EVENT_CONDITION_GROUP>>
    for i = 1, #queue_times do
        self.schedule[queue_times[i]] = {}
    end
    self.save = {
        name = "GAME_EVENT_MANAGER", 
        for_save = {"event_queue", "queue_map"}
    }--:SAVE_SCHEMA
end

local condition_group = require("story/event_condition_groups")

--v function(self: GAME_EVENT_MANAGER, new_condition_group: EVENT_CONDITION_GROUP, schedule: GAME_EVENT_QUEUE_TIMES?)
function game_event_manager.register_condition_group(self, new_condition_group, schedule)
    self.condition_groups[new_condition_group.name] = new_condition_group
    if schedule then
        --# assume schedule: GAME_EVENT_QUEUE_TIMES
        table.insert(self.schedule[schedule], new_condition_group)
    end
end

local game_event = require("story/event")

--v [NO_CHECK] function(self: GAME_EVENT_MANAGER, ...:any) --> WHATEVER
function game_event_manager.build_context_for_event(self, ...)
    -- build an event context
    local context = custom_context:new();
    for i = 1, arg.n do
        local current_obj = arg[i];
        context:add_data(current_obj);
    end
    return context
end

--v function(self: GAME_EVENT_MANAGER, queued_event: QUEUED_GAME_EVENT) --> WHATEVER
function game_event_manager.build_context_from_queued_event(self, queued_event)
    local event = queued_event
    local faction_to_recieve = dev.get_faction(event.faction_key)
    local region_to_recieve = dev.get_region(event.region_key) or true
    local character_to_recieve = dev.get_character(event.char_cqi) or true
    return self:build_context_for_event(event, faction_to_recieve, region_to_recieve, character_to_recieve)
end

--v function(self: GAME_EVENT_MANAGER, event_key: string) --> QUEUED_GAME_EVENT
function game_event_manager.get_event_from_queue(self, event_key)
    local pos = self.queue_map[event_key]
    local event = self.event_queue[pos]
    return event
end

--v function(self: GAME_EVENT_MANAGER, event_key: string) --> boolean
function game_event_manager.remove_event_from_queue(self, event_key)
    if event_key == "" then
        return false
    end
    local position_in_queue = self.queue_map[event_key]
    local queue_entry = self.event_queue[position_in_queue]
    if queue_entry.event_key == event_key then
        table.remove(self.event_queue, position_in_queue)
        self.queue_map[event_key] = nil
        return true
    end
    return false
end

--v function(self: GAME_EVENT_MANAGER, event_object: GAME_EVENT, context: WHATEVER)
function game_event_manager.queue_event(self, event_object, context)
    local queue_entry = {event_key = event_object.key, faction_key = context:faction():name()} --:QUEUED_GAME_EVENT
    if context:character() then
        queue_entry.char_cqi = context:character():command_queue_index()
    end
    if context:region() then
        queue_entry.region_key = context:region():name()
    end
    local pos = #self.event_queue+1
    self.queue_map[event_object.key] = pos
    self.event_queue[pos] = queue_entry
    local groups = event_object.groups
    local current_turn = dev.turn()
    for i = 1, #groups do
        groups[i]:OnMemberEventQueued(event_object.key, current_turn)
    end
    if event_object.trigger_kind == "trait_flag" then
        dev.add_trait(context:character(), event_object.key .. "_flag", false, true)
    end
end

--v function(self: GAME_EVENT_MANAGER, main_group: EVENT_CONDITION_GROUP, event_object: GAME_EVENT, event_context: WHATEVER) --> (boolean, string?)
function game_event_manager.can_queue_event(self, main_group, event_object, event_context)
    local groups_to_check = event_object.groups
    for i = 1, #groups_to_check do
        local group = groups_to_check[i]
        if group ~= main_group then
            if group:is_off_cooldown() and group:has_room_in_queue() then
                local condition_result = group.queue_time_condition(event_context)
                if condition_result then
                    self:log("Event "..event_object.key .. " has passed conditions given by group: "..group.name)
                else
                    return false
                end
            else
                return false
            end
        end
    end
    if not main_group:is_off_cooldown() then 
        return false
    end
    if main_group:has_room_in_queue() then
        return main_group.queue_time_condition(event_context)
    elseif main_group.permits_swapping then
        local chance_to_swap_in = main_group:get_swap_chance(event_object.key)
        if dev.chance(chance_to_swap_in) then
            local swap_out = main_group.last_queued_event
            return main_group.queue_time_condition(event_context), swap_out 
        end
    end
    return false
end

--v function(self: GAME_EVENT_MANAGER, event_key: string, event_context: WHATEVER)
function game_event_manager.force_check_and_queue_event(self, event_key, event_context)
    local event_object = self.events[event_key]
    if not event_object then
        self:log("Tried to force check and queue for an event: "..event_key.." but this event does not have any registry in the events manager")
    end
    if self:can_queue_event(event_object.own_group, event_object, event_context) then
        self:queue_event(event_object, event_context)
    end
end

--v function(self: GAME_EVENT_MANAGER, player_faction: CA_FACTION)
function game_event_manager.fire_queued_events(self, player_faction)
    local other_player_events = {} --:vector<QUEUED_GAME_EVENT>
    for i = 1, #self.event_queue do
        local queue_record = self.event_queue[i]
        local event_object = self.events[queue_record.event_key]
        if queue_record.faction_key == player_faction:name() then
            if event_object.trigger_kind ~= "trait_flag" then
                local context = self:build_context_from_queued_event(queue_record)
                event_object:trigger(context)
            else
                table.insert(other_player_events, queue_record)
            end
        else
            table.insert(other_player_events, queue_record)
        end
    end
    self.event_queue = {}
    self.queue_map = {}
    for i = 1, #other_player_events do
        local queue_entry = other_player_events[i]
        local pos = #self.event_queue+1
        self.queue_map[queue_entry.event_key] = pos
        self.event_queue[pos] = queue_entry
    end
end

--v function(self: GAME_EVENT_MANAGER, player_faction: CA_FACTION)
function game_event_manager.start_player_turn(self, player_faction)
    --do faction turn start trigger time
    local qt = "FactionTurnStart" --:GAME_EVENT_QUEUE_TIMES
    local scheduled_groups = self.schedule[qt]
    local context = self:build_context_for_event(player_faction)
    for i = 1, #scheduled_groups do
        local this_group = scheduled_groups[i]
        for event_key, event_object in pairs(this_group.members) do
            local can_queue, displaces_event = self:can_queue_event(this_group, event_object, context)
            if can_queue and displaces_event then
                if self:remove_event_from_queue(displaces_event) then
                    self:queue_event(event_object, context)
                end
            elseif can_queue then
                self:queue_event(event_object, context)
            end
        end
    end
    --do region turn start trigger time
    local qt = "RegionTurnStart" --:GAME_EVENT_QUEUE_TIMES
    local scheduled_groups = self.schedule[qt]
    local region_list = player_faction:region_list()
    for i = 1, #scheduled_groups do
        local this_group = scheduled_groups[i]
        for event_key, event_object in pairs(this_group.members) do
            for j = 0, region_list:num_items() - 1 do
                local region_context = self:build_context_for_event(player_faction, region_list:item_at(j))
                local can_queue, displaces_event = self:can_queue_event(this_group, event_object, region_context)
                if can_queue and displaces_event then
                    if self:remove_event_from_queue(displaces_event) then
                        self:queue_event(event_object, region_context)
                    end
                elseif can_queue then
                    self:queue_event(event_object, region_context)
                end
            end
        end
    end
    --do character turn start trigger time
    local qt = "CharacterTurnStart" --:GAME_EVENT_QUEUE_TIMES
    local scheduled_groups = self.schedule[qt]
    local character_list = player_faction:character_list()
    for i = 1, #scheduled_groups do
        local this_group = scheduled_groups[i]
        for event_key, event_object in pairs(this_group.members) do
            for j = 0, character_list:num_items() - 1 do
                local character = character_list:item_at(j)
                if dev.is_char_normal_general(character) then
                    local character_context = self:build_context_for_event(player_faction, character, character:region())
                    local can_queue, displaces_event = self:can_queue_event(this_group, event_object, character_context)
                    if can_queue and displaces_event then
                        if self:remove_event_from_queue(displaces_event) then
                            self:queue_event(event_object, character_context)
                        end
                    elseif can_queue then
                        self:queue_event(event_object, character_context)
                    end
                end
            end
        end
    end
    --fire the events waiting in the Queue
    self:fire_queued_events(player_faction)
end

local active_manager = nil --:GAME_EVENT_MANAGER
local function initialize_game_events()
    --init objects
    game_event.init(condition_group.new)
    active_manager = game_event_manager.new()
    --create basic groups
    local dilemma = condition_group.new("dilemma")
    dilemma.num_allowed_in_queue = 1
    dilemma.cooldown = 1
    active_manager:register_condition_group(dilemma)

    local mission = condition_group.new("mission")
    mission.num_allowed_in_queue = 1
    mission.cooldown = 5
    active_manager:register_condition_group(mission)

    local incident = condition_group.new("incident")
    active_manager:register_condition_group(incident)

    dev.eh:add_listener(
        "EventsCore",
        "FactionTurnStart",
        function(context)
            return context:faction():is_human()
        end,
        function(context)
            active_manager:start_player_turn(context:faction())
        end,
        true
    )
    dev.eh:add_listener(
        "EventsCore",
        "DilemmaIssued",
        true,
        function(context)
            local key = context:dilemma() --:string
            if active_manager.events[key] and active_manager.events[key].trigger_kind == "trait_flag" then
                local queued_event = active_manager:get_event_from_queue(key)
                if queued_event then
                    local event_context = active_manager:build_context_from_queued_event(queued_event)
                    if event_context then
                        active_manager.events[key]:trigger(event_context)
                    end
                end
            end
        end,
        true
    )
end

return {
    init = initialize_game_events,
    events = active_manager
}