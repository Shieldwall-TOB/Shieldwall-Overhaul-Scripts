--how many events can be triggered from this group?
--chance formula
local condition_group = {} --# assume condition_group: EVENT_CONDITION_GROUP

--v function(name: string) --> EVENT_CONDITION_GROUP
function condition_group.new(name)
    local self = {}
    setmetatable(self, {
        __index = condition_group
    }) --# assume self: EVENT_CONDITION_GROUP

    self.name = name
    self.members = {} --:map<string, GAME_EVENT>

    self.last_turn_occured = 0

    --flags how many currently in queue, and how many allowed in queue.
    self.num_allowed_queued = 0
    self.currently_in_queue = 0
    self.last_queued_event = "" --:string 

    --allows for controlling a shared cooldown for a group of events.
    self.cooldown = 0
    
    --swapouts
    --allows for setting an event which cannot queue due to violation of num_allowed_queued for this group to roll for a chance to displace the currently queued event.
    self.permits_swapping = false --:boolean
    self.swap_custom_chances = {} --:map<string, int>

    --queue time conditons
    --allows events in the same group to share conditions for queue time.
    self.queue_time_condition = function(context) return true end --:function(context: WHATEVER) --> boolean

    self.callback = function(context) end --:function(context: WHATEVER)

    self.save = {
        name = "event_condition_group_"..name, 
        for_save = {"last_turn_occured", "last_queued_event"}
    }--:SAVE_SCHEMA
    dev.Save.attach_to_object(self)
    return self
end

--queries
--v function(self: EVENT_CONDITION_GROUP) --> boolean
function condition_group.is_off_cooldown(self)
    return self.cooldown == 0 or dev.turn() > self.last_turn_occured + self.cooldown
end

--v function(self: EVENT_CONDITION_GROUP) --> boolean
function condition_group.has_room_in_queue(self)
    return self.num_allowed_queued == 0 or self.currently_in_queue < self.num_allowed_queued
end

--v function(self: EVENT_CONDITION_GROUP, event_key: string) --> int
function condition_group.get_swap_chance(self, event_key)
    return self.swap_custom_chances[event_key] or 50
end

--mods
--v [NO_CHECK] function(self: EVENT_CONDITION_GROUP, event: GAME_EVENT)
function condition_group.add_event(self, event)
    self.members[event.key] = event
end

--v function(self: EVENT_CONDITION_GROUP)
function condition_group.enable_swapping(self)
    self.permits_swapping = true
end

--v function(self: EVENT_CONDITION_GROUP, cooldown: int)
function condition_group.set_cooldown(self, cooldown)
    self.cooldown = cooldown
end

--v function(self: EVENT_CONDITION_GROUP, num_allowed: int)
function condition_group.set_number_allowed_in_queue(self, num_allowed)
    self.num_allowed_queued = num_allowed
end

--v function(self: EVENT_CONDITION_GROUP, callback: function(context: WHATEVER))
function condition_group.add_callback(self, callback)
    self.callback  = callback
end

--system
--v function(self: EVENT_CONDITION_GROUP, event: string,turn: int)
function condition_group.OnMemberEventQueued(self, event, turn)
    self.currently_in_queue = self.currently_in_queue + 1
    self.last_queued_event = event
end

--v function(self: EVENT_CONDITION_GROUP, event: string, turn: int)
function condition_group.OnMemberEventRemovedFromQueue(self, event, turn)
    self.currently_in_queue = self.currently_in_queue - 1
    if self.last_queued_event == event then
        self.last_queued_event = ""
    end
end

--v function(self: EVENT_CONDITION_GROUP, event: string, turn: int)
function condition_group.OnMemberEventOccured(self, event, turn)
    self.currently_in_queue = self.currently_in_queue - 1
    if self.last_queued_event == event then
        self.last_queued_event = ""
    end
    self.last_turn_occured = turn
end


return {
    new = condition_group.new
}