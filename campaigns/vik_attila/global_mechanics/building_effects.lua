
local time_to_event_processors = {
    ["TurnStart"] = {"RegionTurnStart", function(context, --:WHATEVER
        chain_key) --:string
        return context:region():building_superchain_exists(chain_key), context:region()
    end},
    ["EntersRegion"] = {"CharacterEntersGarrison", function(context, --:WHATEVER
        chain_key) --:string
        return context:character():region():building_superchain_exists(chain_key), context:character():region()
    end}
}--:map<string, {string, function(context: WHATEVER, building_key: string)-->(boolean, CA_REGION)}>

--v function(t: any)
local function log(t)
    dev.log(tostring(t), "BUILD")
end


--v function(chain_key: string, time: string, callback: function(region: CA_REGION))
local function add_building_effect(chain_key, time, callback)
    if time_to_event_processors[time] == nil then
        log("Unrecognized building event")
        return
    end
    dev.eh:add_listener(chain_key..time,
        time_to_event_processors[time][1],
        function(context)
            return true
        end,
        function(context)
            local ok, region = time_to_event_processors[time][2](context, chain_key)
            if ok then
                callback(region)
            end
        end, true)
end


local kings_court_check = function(region) --:CA_REGION
    local owner = region:owning_faction()
    local faction_list = dev.faction_list()
    local vassal_count = 0 --:number
    for i = 0, faction_list:num_items() - 1 do
        local vassal = faction_list:item_at(i)
        if vassal:is_vassal_of(owner) then
            vassal_count = vassal_count + 1
        end
    end
    vassal_count = dev.clamp(vassal_count, 0, 5)
    local bundle = cm:get_saved_value("kings_court_bundle") or 0
    if bundle ~= vassal_count then
        if bundle > 0 then
            cm:remove_effect_bundle_from_region("vik_konungsgurtha_"..bundle, region:name())
        end
        if vassal_count > 0 then
            cm:apply_effect_bundle_to_region("vik_konungsgurtha_"..vassal_count, region:name(), 0)
        end
        cm:set_saved_value("kings_court_bundle", vassal_count)
    end
end


add_building_effect("vik_konungsgurtha", "TurnStart", kings_court_check)