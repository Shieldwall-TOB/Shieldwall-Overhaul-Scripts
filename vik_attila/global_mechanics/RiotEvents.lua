local riot_events = {
    {
        name = "sw_rebellion_rioting_household_guard_",
        condition = function(riot_manager) --:RIOT_MANAGER
            local region = dev.get_region(riot_manager.key)
            return region:has_governor() and cm:random_number(100) > 50 and Check.does_char_have_household_guard(region:governor())
        end,
        response = function(context) --:WHATEVER
            local region_key = string.gsub(context:dilemma(), "sw_rebellion_rioting_household_guard_", "")
            if context:choice() == 1 then
                --TODO reduce peasant manpower
            end
        end,
        is_dilemma = true
    }
}--:vector<{name: string, condition: (function(rioting_region: RIOT_MANAGER) --> boolean), response: (function(context: WHATEVER)), is_dilemma: boolean}>

local riot_manager = PettyKingdoms.RiotManager
for i = 1, #riot_events do
    local event = riot_events[i]
    riot_manager.add_event(event.name, event.condition, event.response, event.is_dilemma)
end