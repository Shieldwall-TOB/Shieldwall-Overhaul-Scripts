

local foreigner_riot_events = {
    {
        name = "sw_foreign_dead_wife_",
        required_hostility = 0,
        hostility_change = 1,
        condition = function(context) --:WHATEVER
            return FOREIGN_WARRIORS.hostility == 0
        end,
        response = function(context) --:WHATEVER

        end,
        is_dilemma = false
    },
    {
        name = "sw_foreign_grumpy_neighbours_",
        required_hostility = 1,
        hostility_change = 1,
        condition = function(context) --:WHATEVER
            local region = context:region()
            return FOREIGN_WARRIORS.hostility == 1 
        end,
        response = function(context) --:WHATEVER

        end,
        is_dilemma = false
    },
    {
        name = "sw_foreign_esc_tar_and_feather_",
        required_hostility = 2,
        hostility_change = 1,
        condition = function(context) --:WHATEVER
            return FOREIGN_WARRIORS.hostility == 2
        end,
        response = function(context) --:WHATEVER

        end,
        is_dilemma = false
    }
}--:vector<{name: string, required_hostility: int, hostility_change: int, condition: (function(context: WHATEVER) --> boolean), response: (function(context: WHATEVER)), is_dilemma: boolean}>




dev.first_tick(function(context)
    local riot_manager = PettyKingdoms.RiotManager
    local event_manager = dev.GameEvents
    local fw = FOREIGN_WARRIORS

    local ForeignerRiotEvents = event_manager:create_new_condition_group("ForeignerRiotEvent", function(context)
        local region = context:region() --:CA_REGION
        local is_foreign_province = not not fw.provinces_with_foreigners[region:province_name()]
        return is_foreign_province 
    end) 
    event_manager:register_condition_group(ForeignerRiotEvents)

    for i = 1, #foreigner_riot_events do
        local event_info = foreigner_riot_events[i]
        local event_type = "incident" --:GAME_EVENT_TYPE
        if event_info.is_dilemma then
            event_type = "dilemma" 
        end
        local event = event_manager:create_event(event_info.name, event_type, "concatenate_region")
        event:set_number_allowed_in_queue(1)
        event:add_queue_time_condition(function(context) 
            return (fw.hostility >= event_info.required_hostility) and event_info.condition(context)
        end)
        if CONST.__testcases.__test_foreigner_events then
            event:add_queue_time_condition(function(context)
                local result = hostility.condition(context)
                dev.log("Test for foreigner event: "..event_info.name.." resulted in ".. tostring(result).." (tests ignore hostility req)", "__test_foreigner_events")
                return true
            end)
        end
        event:add_callback(function(context)
            fw.hostility = fw.hostility + event_info.hostility_change
            event_info.response(context)
        end)
        event:join_groups("ProvinceCapitals", "StandardRiotEvent", "ForeignerRiotEvent")
    end

end)