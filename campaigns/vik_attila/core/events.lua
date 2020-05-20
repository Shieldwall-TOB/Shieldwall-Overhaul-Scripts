--a universally called helper.
--used to coordinate the trigger of dilemmas.
local game_events = {}
--v function(t: any)
local function log(t)
    dev.log(tostring(t), "EVNT")
end
game_events.turnstart_events = {} --:map<int, vector<string>>
game_events.postbattle_events = {} --:map<int, vector<string>>
game_events.occupation_events = {} --:map<int, vector<string>>
game_events.sacking_events = {} --:map<int, vector<string>>
game_events.raider_events = {} --:map<int, vector<string>>
game_events.stored_responses = {} --:map<string, function(context: WHATEVER)>
game_events.event_cooldowns = {} --:map<string, int>
game_events.region_queue = {} --:vector<{faction: string, region: string, event: string}>
game_events.regional_events_last_queued = {} --:map<string, string>
game_events.region_events = {} --:map<int, vector<string>>
game_events.region_event_validity = {} --: map<string, {bool, bool}>
game_events.turnstart_queue = {} --:vector<{faction: string, dilemma: string}>
game_events.last_event_turn = {} --:map<string, int>
game_events.already_happened = {} --:map<string, int>
game_events.event_conditions = {} --:map<string, (function(context: WHATEVER) --> boolean)>
game_events.incidents = {} --:map<string, boolean>

game_events.save = {
    name = "game_event_manager",
    for_save = {"last_event_turn", "turnstart_queue", "already_happened", "region_queue"}
}

--v function(event_key: string) --> boolean
local function is_off_cooldown(event_key)
 return (not game_events.event_cooldowns[event_key]) or (not game_events.already_happened[event_key]) or (cm:model():turn_number() >= (game_events.already_happened[event_key] + game_events.event_cooldowns[event_key]))
end




local max_priority_levels = 4 --:int
--v function(event_key: string,faction: CA_FACTION, region: string?)
local function trigger_event(event_key, faction, region)
    if not faction:is_human() then
        return
    end
    local is_regional = false
    local is_incident = false
    local response = game_events.stored_responses[event_key]
    game_events.already_happened[event_key] = cm:model():turn_number()
    if game_events.incidents[event_key] then
        is_incident = true
    end
    if game_events.region_event_validity[event_key] then
        --# assume region: string!
        is_regional = true
        event_key = event_key  .. region
    end
    log("Triggering event with event key: "..event_key)
    if is_incident then
        if response then
            dev.respond_to_incident(event_key, response)
        end
        cm:trigger_incident(faction:name(), event_key, true)
    elseif not (game_events.last_event_turn[faction:name()] == cm:model():turn_number()) and cm:model():world():whose_turn_is_it():name() == faction:name() then
        if response then
            dev.respond_to_dilemma(event_key, response)
        end
        cm:trigger_dilemma(faction:name(), event_key, true)
    else
        game_events.turnstart_queue[#game_events.turnstart_queue+1] = {faction = faction:name(), dilemma = event_key}
    end
end

dev.post_first_tick(function(context)
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
            for i = 1, #game_events.turnstart_queue do
                if game_events.turnstart_queue[i].faction == context:faction():name() then
                    trigger_event(game_events.turnstart_queue[i].dilemma, dev.get_faction(game_events.turnstart_queue[i].faction))
                    table.remove(game_events.turnstart_queue, i)
                    return
                end
            end
            local turn_difference = cm:model():turn_number() - (game_events.last_event_turn[context:faction():name()] or 0)
            for i = 1, max_priority_levels do
                local events = game_events.turnstart_events[i]
                if events and turn_difference >= i then 
                    local r = cm:random_number(#events)
                    for j = 1, #events do
                        local event_index = j + r
                        if event_index > #events then
                            event_index =  event_index - #events
                        end
                        local event_key = events[event_index]

                        if is_off_cooldown(event_key) and game_events.event_conditions[event_key](context) then
                            if game_events.stored_responses[event_key] then
                                dev.respond_to_dilemma(event_key, game_events.stored_responses[event_key])
                            end
                            cm:trigger_dilemma(context:faction():name(), event_key, true)
                            return
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
            local faction = context:character():faction() --:CA_FACTION
            local can_fire_dilemma = not (game_events.last_event_turn[faction:name()] == cm:model():turn_number())
            for i = 1, max_priority_levels do
                local events = game_events.postbattle_events[i]
                if events then 
                    local r = cm:random_number(#events)
                    for j = 1, #events do
                        local event_index = j + r
                        if event_index > #events then
                            event_index =  event_index - #events
                        end
                        local event_key = events[event_index]
                        if game_events.event_conditions[event_key] then
                            if (game_events.incidents[event_key] or can_fire_dilemma) and game_events.event_conditions[event_key](context) then
                                trigger_event(event_key, faction)
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
            for i = 1, #game_events.region_queue do
                if game_events.region_queue[i].region == context:region():name() then
                    if can_fire_dilemma or game_events.incidents[game_events.region_queue[i].event] then
                        trigger_event(game_events.region_queue[i].event, dev.get_faction(game_events.region_queue[i].faction), game_events.region_queue[i].region)
                        table.remove(game_events.region_queue, i)
                        return
                    end
                end
            end

            for i = 1, max_priority_levels do
                local events = game_events.region_events[i]
                if events then
                    local r = cm:random_number(#events)
                    for j = 1, #events do
                        local event_index = j + r
                        if event_index > #events then
                            event_index =  event_index - #events
                        end
                        local event_key = events[event_index]
                        if game_events.event_conditions[event_key] then
                            local capitals = game_events.region_event_validity[event_key][1]
                            local villages = game_events.region_event_validity[event_key][2]
                            if (((region:is_province_capital() and capitals) or ((not region:is_province_capital()) and villages))) and is_off_cooldown(event_key) then
                                if game_events.event_conditions[event_key](context) and (can_fire_dilemma or game_events.incidents[event_key]) then
                                trigger_event(event_key, faction, region:name())
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end,
        true
    )

end)


--v function(event_key: string, condition: (function(context: WHATEVER) --> boolean), priority: int, cooldown: int?, response_function: (function(context: WHATEVER))?)
local function add_turnstart_event(event_key, condition, priority, cooldown, response_function)
    game_events.turnstart_events[priority] = game_events.turnstart_events[priority] or {}
    table.insert(game_events.turnstart_events[priority], event_key)
    game_events.event_conditions[event_key] = condition
    if cooldown then
        --# assume event_cooldowns: int!
        game_events.event_cooldowns[event_key] = cooldown
    else
        game_events.event_cooldowns[event_key] = 1
    end
    if response_function then
        game_events.stored_responses[event_key] = response_function
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

--v function(prefix: string, capitals: boolean, villages: boolean, is_dilemma: boolean,  condition: (function(context: WHATEVER) --> boolean), priority: int, cooldown: int?, response_function: (function(context: WHATEVER))?)
local function add_regional_event(prefix, capitals, villages, is_dilemma, condition, priority, cooldown, response_function)
    game_events.region_events[priority] = game_events.region_events[priority] or {}
    table.insert(game_events.region_events[priority], prefix)
    game_events.event_conditions[prefix] = condition
    if cooldown then
        game_events.event_cooldowns[prefix] = cooldown
    end
    game_events.region_event_validity[prefix] = {capitals, villages}
    if not is_dilemma then
        game_events.incidents[prefix] = true
    end
    if response_function then
        game_events.stored_responses[prefix] = response_function
    end
end

--v function(prefix: string, region_key: string, faction: string)
local function force_regional_event(prefix, region_key, faction)
    if not  game_events.region_event_validity[prefix] then
        log("Failed to force regional event: no event record for: "..prefix)
        return 
    end
    log("Adding regional event "..prefix..region_key.." to queue")
    local region = dev.get_region(region_key)

    local capitals = game_events.region_event_validity[prefix][1]
    local villages = game_events.region_event_validity[prefix][2]
    if not (capitals and region:is_province_capital() or (villages and not region:is_province_capital())) then
        return
    end
    table.insert(game_events.region_queue, {event = prefix, faction = faction, region = region_key})
end


--v function(event_key: string, condition: (function(context: WHATEVER) --> boolean), priority: int, cooldown: int?, response_function: (function(context: WHATEVER))?)
local function add_post_battle_event(event_key, condition, priority, cooldown, response_function)
    game_events.postbattle_events[priority] = game_events.postbattle_events[priority] or {}
    table.insert(game_events.postbattle_events[priority], event_key)
    game_events.event_conditions[event_key] = condition
    if cooldown then
        --# assume event_cooldowns: int!
        game_events.event_cooldowns[event_key] = cooldown
    else
        game_events.event_cooldowns[event_key] = 1
    end

end

--v function(event: string) --> number
local function last_event_occurance(event)
    return game_events.already_happened[event] or 0
end

--v function(event: string) --> boolean
local function has_event_occured(event)
    return not not game_events.already_happened[event]
end

--v function(event: string)
local function register_as_incident(event)
    game_events.incidents[event] = true
end

--v function(event: string, faction:CA_FACTION, region: string?)
local function trigger_incident(event, faction, region)
    game_events.incidents[event] = true
    trigger_event(event, faction, region)
end

return {
    trigger_event = trigger_event,
    trigger_turnstart_dilemma = queue_event_for_turn_start,
    add_turnstart_event = add_turnstart_event,
    add_regional_event = add_regional_event,
    force_regional_event = force_regional_event,
    last_event_occurance = last_event_occurance,
    has_event_occured = has_event_occured,
    register_as_incident = register_as_incident,
    trigger_incident = trigger_incident,
    add_post_battle_event = add_post_battle_event,
    is_off_cooldown = is_off_cooldown
}