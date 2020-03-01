--a universally called helper.
--used to coordinate the trigger of dilemmas.
local game_events = {}
game_events.turnstart_events = {} --:map<int, vector<string>>
game_events.postbattle_events = {} --:map<int, vector<string>>
game_events.occupation_events = {} --:map<int, vector<string>>
game_events.sacking_events = {} --:map<int, vector<string>>
game_events.raider_events = {} --:map<int, vector<string>>
game_events.stored_responses = {} --:map<string, function(context: WHATEVER)>

game_events.region_events = {} --:map<int, vector<string>>
game_events.region_event_validity = {} --: map<string, {bool, bool}>
game_events.turnstart_queue = {} --:vector<{faction: string, dilemma: string}>
game_events.last_event_turn = {} --:map<string, int>
game_events.nonrepeatable = {} --:map<string, boolean>
game_events.already_happened = {} --:map<string, boolean>
game_events.event_conditions = {} --:map<string, (function(context: WHATEVER) --> boolean)>
game_events.incidents = {} --:map<string, boolean>

game_events.save = {
    name = "game_event_manager",
    for_save = {"last_event_turn", "turnstart_queue", "already_happened"}
}

local max_priority_levels = 4 --:int
--v function(event_key: string,faction: CA_FACTION, region: string?)
local function trigger_event(event_key, faction, region)
    local is_regional = false
    local is_incident = false
    if game_events.incidents[event_key] then
        is_incident = true
    end
    if game_events.region_event_validity[event_key] then
        --# assume region: string!
        is_regional = true
        event_key = event_key  .. region
    end
    if is_incident then
        if game_events.stored_responses[event_key] then
            dev.respond_to_incident(event_key, game_events.stored_responses[event_key])
        end
        cm:trigger_incident(faction:name(), event_key, true)
    elseif not (game_events.last_event_turn[faction:name()] == cm:model():turn_number()) and cm:model():world():whose_turn_is_it():name() == faction:name() then
        if game_events.stored_responses[event_key] then
            dev.respond_to_dilemma(event_key, game_events.stored_responses[event_key])
        end
        cm:trigger_dilemma(faction:name(), event_key, true)
    else
        game_events.turnstart_queue[#game_events.turnstart_queue+1] = {faction = faction:name(), dilemma = event_key}
    end
end

dev.first_tick(function(context)
    dev.Save.attach_to_object(game_events)
    dev.eh:add_listener(
        "DilemmaIssued",
        "DilemmaIssued",
        true,
        function(context)
            game_events.last_event_turn[context:faction():name()] = cm:model():turn_number() 
            game_events.already_happened[context:dilemma()] = true
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
            for i = 1, #game_events.turnstart_queue do
                if game_events.turnstart_queue[i].faction == context:faction():name() then
                    cm:trigger_dilemma(game_events.turnstart_queue[i].faction, game_events.turnstart_queue[i].dilemma, true)
                    table.remove(game_events.turnstart_queue, i)
                    return
                end
            end
            local turn_difference = cm:model():turn_number() - (game_events.last_event_turn[context:faction():name()] or 0)
            for i = 1, max_priority_levels do
                local events = game_events.turnstart_events[i]
                if events and turn_difference >= i then 
                    for j = 1, #events do
                        local event_key = events[j]
                        if (not game_events.nonrepeatable[event_key]) or (not game_events.already_happened[event_key]) then
                            if game_events.event_conditions[event_key](context) then
                                if game_events.stored_responses[event_key] then
                                    dev.respond_to_dilemma(event_key, game_events.stored_responses[event_key])
                                end
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
    --find any valid region events
    dev.eh:add_listener(
        "EventsRegionTurnStart",
        "RegionTurnStart",
        function(context)
            return context:region():owning_faction():is_human()
        end,
        function(context)
            local region = context:region()
            local faction = region:owning_faction() --:CA_FACTION
            local can_fire_dilemma = not (game_events.last_event_turn[faction:name()] == cm:model():turn_number())
            for i = 1, max_priority_levels do
                local events = game_events.region_events[i]
                if events then
                    for j = 1, #events do
                        local event_key = events[i]
                        if game_events.event_conditions[event_key] then
                            local capitals, villages = game_events.region_event_validity[event_key][1], game_events.region_event_validity[event_key][2]
                            if ((region:is_province_capital() and capitals) or ((not region:is_province_capital()) and villages)) and game_events.event_conditions[event_key](context) then
                               trigger_event(event_key, faction, region:name())
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


--v function(event_key: string, condition: (function(context: WHATEVER) --> boolean), priority: int, do_not_repeat: boolean?, response_function: (function(context: WHATEVER))?)
local function add_turnstart_event(event_key, condition, priority, do_not_repeat, response_function)
    game_events.turnstart_events[priority] = game_events.turnstart_events[priority] or {}
    table.insert(game_events.turnstart_events[priority], event_key)
    game_events.event_conditions[event_key] = condition
    if do_not_repeat then
        game_events.nonrepeatable[event_key] = true
    end
end

--v [NO_CHECK] function(event_key: string, faction_name: string, above_all_others: boolean?)
local function queue_event_for_turn_start(event_key, faction_name, above_all_others)
    if above_all_others then
        table.insert(game_events.turnstart_queue, {faction = faction_name, dilemma = event_key}, 1)
    else
        table.insert(game_events.turnstart_queue, {faction = faction_name, dilemma = event_key})
    end
end

--v function(prefix: string, capitals: boolean, villages: boolean, is_dilemma: boolean,  condition: (function(context: WHATEVER) --> boolean), priority: int, do_not_repeat: boolean?, response_function: (function(context: WHATEVER))?)
local function add_regional_event(prefix, capitals, villages, is_dilemma, condition, priority, do_not_repeat, response_function)
    game_events.region_events[priority] = game_events.region_events[priority] or {}
    table.insert(game_events.region_events[priority], prefix)
    game_events.event_conditions[prefix] = condition
    if do_not_repeat then
        game_events.nonrepeatable[prefix] = true
    end
    game_events.region_event_validity[prefix] = {capitals, villages}
    if not is_dilemma then
        game_events.incidents[prefix] = true
    end
end

return {
    trigger_turnstart_dilemma = queue_event_for_turn_start,
    add_turnstart_event = add_turnstart_event,
    add_regional_event = add_regional_event
}