--a universally called helper.
--used to coordinate the trigger of dilemmas.
local game_events = {}
game_events.turnstart_events = {} --:map<int, vector<string>>
game_events.postbattle_events = {} --:map<int, vector<string>>
game_events.post_occupy_or_sack_events = {} --:map<int, vector<string>>
game_events.last_event_turn = {} --:map<string, int>
game_events.event_conditions = {} --:map<string, (function(context: WHATEVER) --> boolean)>
game_events.save = {
    name = "game_event_manager",
    for_save = {"last_event_turn"}
}

local max_priority_levels = 4 --:int

dev.first_tick(function(context)
    dev.Save.attach_to_object(game_events)
    dev.eh:add_listener(
        "DilemmaIssued",
        "DilemmaIssued",
        true,
        function(context)
            game_events.last_event_turn[context:faction():name()] = cm:model():turn_number() 
        end,
        true
    )

    --find a valid dilemma on faction turn begin normal phase.
    dev.eh:add_listener(
        "EventsFactionBeginTurnPhaseNormal",
        "FactionBeginTurnPhaseNormal",
        function(context)
            return context:faction():is_human() and ((game_events.last_event_turn[context:faction():name()] or 0) < cm:model():turn_number())
        end,
        function(context)
            for i = 1, max_priority_levels do
                local events = game_events.turnstart_events[i]
                if events then 
                    for j = 1, #events do
                        local event_key = events[j]
                        if game_events.event_conditions[event_key] then
                            if game_events.event_conditions[event_key](context) then
                                cm:trigger_dilemma(context:faction():name(), event_key, true)
                                return
                            end
                        end
                    end
                end
            end
        end,
        true
    )
    --find a valid dilemma to trigger post battle
    dev.eh:add_listener(
        "EventsCharacterCompletedBattle",
        "CharacterCompletedBattle",
        function(context)
            return context:character():faction():is_human()
        end,
        function(context)
            for i = 1, max_priority_levels do
                local events = game_events.postbattle_events[i]
                if events then 
                    for j = 1, #events do
                        local event_key = events[j]
                        if game_events.event_conditions[event_key] then
                            if game_events.event_conditions[event_key](context) then
                                cm:trigger_dilemma(context:faction():name(), event_key, true)
                                return
                            end
                        end
                    end
                end
            end
        end,
        true
    )

end)


--v function(event_key: string, condition: (function(context: WHATEVER) --> boolean), priority: int)
local function add_turnstart_event(event_key, condition, priority)
    game_events.turnstart_events[priority] = game_events.turnstart_events[priority] or {}
    table.insert(game_events.turnstart_events[priority], event_key)
    game_events.event_conditions[event_key] = condition
end

return {
    add_turnstart_event = add_turnstart_event
}