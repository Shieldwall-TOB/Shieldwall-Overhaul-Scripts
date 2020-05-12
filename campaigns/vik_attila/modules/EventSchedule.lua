--defines systems for managing the level of recurrence for given events.
--a global events object is available from dev which tracks whether events have occured,
--whether missions are active, what choices have been taken, and if a dilemma should be possible.

--these objects control triggering incidents missions or traits at controlled interval.
--a budget determines whether events are sought.
--A priority level acts as both the cost of an event to budget and also the order for searching.

local event_schedule = {} --# assume event_schedule: EVENT_SCHEDULE

--v function(name: string) --> EVENT_SCHEDULE
function event_schedule.new(name)
    local self = {}
    setmetatable(self, {
        __index = event_schedule
    }) --# assume self: EVENT_SCHEDULE


    self.name = name
    --hold all event keys in cost arrays.
    self.events = {} --:map<int, vector<string>>
    --indicates 'mission', 'dilemma' vs. 'incident'
    self.event_types = {} --:map<string, string>
    --holds info regarding conditionality on each type.
    self.dilemma_infos = {}
    self.incident_infos = {}
    self.mission_infos = {}
    --how many events can we trigger?
    self.budget = 0
    --how much budget before we stop building up more?
    self.budget_max = 0
    --increasing this number makes events rarer - requiring budget to reach cost + offset to fire events.
    self.budget_offset = 0
    --changes the rate at which the budget is restored to allow more events.
    self.budget_recovery_rate = 0


    return self

end


--on event
    --is this type regional or factional?