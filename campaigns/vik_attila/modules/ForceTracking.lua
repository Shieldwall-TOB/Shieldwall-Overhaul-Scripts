local force_tracker = {} --# assume force_tracker: FORCE_TRACKER


--v function() --> FORCE_TRACKER
function force_tracker.new()
    local self = {}
    setmetatable(self, {
        __index = force_tracker
    }) --# assume self: FORCE_TRACKER

    self.forces_cache = {} --:map<string, map<string, number>>
    self.force_casualties = {} --:map<string, map<string, number>>
    self.force_replenishment = {} --:map<string, map<string, number>>

    self.save = {
        name = "FORCE_CACHE",
        for_save = {
             "forces_cache", "force_casualties", "force_replenishment"
        }, 
    }

    return self
end

local instance = force_tracker.new()

dev.pre_first_tick(function(context)
    if dev.is_new_game() then
        local humans = cm:get_human_factions() 
        for i = 1, #humans do
            local char_list = dev.get_faction(humans[i]):character_list()
            for j = 0, char_list:num_items() - 1 do
                local char = char_list:item_at(j)
                if dev.is_char_normal_general(char) then
                    instance.forces_cache[tostring(char:command_queue_index())] = dev.generate_force_cache_entry(char)
                end
            end
        end
    end
    dev.eh:add_listener(
        "ForceCacheCharacterTurnEnd",
        "CharacterTurnEnd",
        function(context)
            return context:character():faction():is_human() and dev.is_char_normal_general(context:character())
        end,
        function(context)
            local char = context:character()
            instance.forces_cache[tostring(char:command_queue_index())] = dev.generate_force_cache_entry(char)
        end,
        true)

    dev.eh:add_listener(
        "ForceCacheCharacterCompletedBattle",
        "CharacterCompletedBattle",
        function(context)
            return context:character():faction():is_human() and (not context:character():military_force():is_null_interface()) and dev.is_char_normal_general(context:character()) 
        end,
        function(context)
            local char = context:character()
            local cache_temp = dev.generate_force_cache_entry(char)
            local old_cache = instance.forces_cache[tostring(char:command_queue_index())]
            local casualties_cache = {} --:map<string, number>
            for unit_key, old_val in pairs(old_cache) do
                local new_val = cache_temp[unit_key] or 0
                casualties_cache[unit_key] = new_val - old_val
            end
            -- values in this cache will be negative numbers.
            instance.force_casualties[tostring(char:command_queue_index())] = casualties_cache
            -- update the internal cache so we can accurately track replenishment
            instance.forces_cache[tostring(char:command_queue_index())] = cache_temp
            --fire event
            dev.eh:trigger_event("CharacterCasualtiesCached", context:character(), casualties_cache) --accessed through context:table_data()
        end,
        true)
    dev.eh:add_listener(
        "ForceCacheCharacterTurnStart",
        "CharacterTurnStart",
        function(context)
            return context:character():faction():is_human() and dev.is_char_normal_general(context:character())
        end,
        function(context)
            local char = context:character()
            local cache_temp = dev.generate_force_cache_entry(char)
            local old_cache = instance.forces_cache[tostring(char:command_queue_index())]
            local replen_cache = {} --:map<string, number>
            for unit_key, old_val in pairs(old_cache) do
                local new_val = cache_temp[unit_key] or 0
                replen_cache[unit_key] = new_val - old_val
            end
            -- values in this cache will be positive numbers
            instance.force_replenishment[tostring(char:command_queue_index())] = replen_cache
            -- update the internal cache so we can accurately track battle casualties.
            instance.forces_cache[tostring(char:command_queue_index())] = cache_temp
            --fire event
            dev.eh:trigger_event("CharacterReplenishmentCached", context:character(), replen_cache)
        end,
        true
    )
end)

--v function(character: CA_CHAR) --> map<string, number>
local function get_last_casualties_for_character(character)
    return instance.force_casualties[tostring(character:command_queue_index())]
end

--v function(character: CA_CHAR) --> map<string, number>
local function get_last_replenishment_for_character(character)
    return instance.force_replenishment[tostring(character:command_queue_index())]
end

return {
    get_character_casualties = get_last_casualties_for_character,
    get_character_replenishment = get_last_replenishment_for_character
}