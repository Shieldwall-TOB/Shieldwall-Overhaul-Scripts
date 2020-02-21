local hof_key = ""
local hof_dilemma = ""

local cooldowns = {
    [1] = 40,
    [2] = 30,
    [3] = 25,
    [4] = 20,
    [5] = 18,
    [6] = 15,
    [7] = 12
} --:map<int, int>
 --after this its always 10. 

--v function(hof_count: int) --> int
local function get_cooldown(hof_count)
    return cooldowns[hof_count] or 10
end

local hofs = {

}--:map<string, number>

dev.first_tick(function(context) 
    if dev.is_new_game() then
        local players = cm:get_human_factions()
        for i = 1, #players do hofs[players[i]] = 0 end
    end
    dev.eh:add_listener(
        "Hofs",
        "FactionTurnStart",
        function(context)
            return context:faction():is_human() and context:faction():faction_leader():has_trait("shield_heathen_pagan")
        end,
        function(context)
            local count = 0
            local faction = context:faction()
            local region_list = faction:region_list()
            for i = 0, region_list:num_items() - 1 do
                if region_list:item_at(i):building_exists(hof_key) then
                    count = count + 1;
                end
            end
            if count == 0 then
                return
            end
            local cooldown_current = hofs[faction:name()] or 0
            local target = get_cooldown(count)
            if cooldown_current > target then hofs[faction:name()] = (target - 3) else
                hofs[faction:name()] = cooldown_current - 1
            end
        end,
        true
    )

    dev.Events.add_turnstart_event(hof_dilemma, function(context)
        local key = context:faction():name()
        return hofs[key] and hofs[key] == 0 
    end, 4, false)
end)



dev.Save.persist_table(hofs, "hof_cd", function(t) hofs = t end)