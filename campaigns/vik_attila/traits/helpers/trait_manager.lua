--this object helps handle the implementation of a given trait.

local TM_TRIGGERED_DILEMMA = {} --:map<string, map<string, boolean>>

--# assume global class TRAIT_MANAGER
local trait_manager = {} --# assume trait_manager: TRAIT_MANAGER
--v function(trait_key: string) --> TRAIT_MANAGER
function trait_manager.new(trait_key)
    local self = {}
    setmetatable(self, {
        __index = trait_manager
    }) --# assume self: TRAIT_MANAGER
    --stores the name
    self.key = trait_key
    self.first_tick = false --:boolean
    dev.first_tick(function(context) self.first_tick = true end)
    --handle the trait's flag for normal character dilemmas
    self.flagged_cqi = cm:get_saved_value("tm_"..self.key.."_flagged_cqi") or -1 --:CA_CQI
    self.out_for_trigger = not not cm:get_saved_value("tm_"..self.key.."_out_for_trigger")
    --handle the faction leader trait dilemmas
    self.faction_leader_add_choices = {} --:map<string, number>
    self.faction_leader_remove_choices = {} --:map<string, number>
    --startpos characters
    self.startpos_characters = {}
    self.start_traits_applied = not not cm:get_saved_value("tm_"..self.key.."_start_traits_applied")
    --loyalty event auto-removal
    cm:set_saved_value("tm_"..self.key.."_remove_loyalty_event", -1)
    cm:add_listener(
        "TMLoyaltyEventFactionTurnStart",
        "FactionTurnStart",
        function(context)
            return context:faction():is_human() and cm:get_saved_value("tm_"..self.key.."_remove_loyalty_event") == cm:model():turn_number()
        end,
        function(context)
            local faction = context:faction()
            local chars = faction:character_list() 
            for i = 0, chars:num_items() - 1 do
                local char = chars:item_at(i)
                if char:has_trait(self.key.."_loyalty_event_flag") then
                    cm:force_remove_trait(dev.lookup(char), self.key.."_loyalty_event_flag")
                end
            end
            cm:set_saved_value("tm_"..self.key.."_remove_loyalty_event", -1)
        end,
        false 
    )
    --mission handling
    self.mission_active = not not cm:get_saved_value("tm_"..self.key.."_mission_active")
    self.mission_counter = cm:get_saved_value("tm_"..self.key.."_mission_counter") or 0

    return self
end

--v function(self: TRAIT_MANAGER, text: any)
function trait_manager.log(self, text)
    dev.log(tostring(text), "TM-")
end

--v function(self: TRAIT_MANAGER, callback:function())
function trait_manager.wait(self, callback)
    if self.first_tick then
        callback()
    else
        dev.first_tick(function(context)
            callback()
        end)
    end
end


--v function(self: TRAIT_MANAGER)
function trait_manager.cache(self)
    cm:set_saved_value("tm_"..self.key.."_flagged_cqi", self.flagged_cqi)
    cm:set_saved_value("tm_"..self.key.."_out_for_trigger", self.out_for_trigger)
end

--v function(self: TRAIT_MANAGER)
function trait_manager.mission_save(self)
    cm:set_saved_value("tm_"..self.key.."_mission_active", self.mission_active)
    cm:set_saved_value("tm_"..self.key.."_mission_counter",  self.mission_counter)
end

--v function(self: TRAIT_MANAGER, dilemma_key: string, choice: number)
function trait_manager.register_faction_leader_add_trait_dilemma(self, dilemma_key, choice)


end

--v function(self: TRAIT_MANAGER, dilemma_key: string, choice: number)
function trait_manager.register_faction_leader_remove_trait_dilemma(self, dilemma_key, choice)
    cm:add_listener(
        "TMRemoveTraitDilemma",
        "DilemmaChoiceMadeEvent",
        function(context)
            return (not not string.find(context:dilemma(), dilemma_key)) and context:choice() == choice
            --the string find helps in partial match situations.
        end,
        function(context)
            local faction = context:faction()
            if (not faction:faction_leader():is_null_interface()) and faction:faction_leader():has_trait(self.key) then
                cm:force_remove_trait(dev.lookup(faction:faction_leader()), self.key)
            end
        end,
        true)
end

--private function
--v function(self: TRAIT_MANAGER, char: CA_CHAR)
local function apply_trait_dilemma_for_character(self, char)
    if (not char:faction():is_human()) then
        if cm:random_number(100) > 50 then
            cm:force_add_trait(dev.lookup(char) ,self.key, false)
        end
        return 
    end
    if (not char:is_faction_leader()) and (not char:has_trait(self.key)) and (not char:has_trait(self.key.."_flag")) then
        cm:force_add_trait(dev.lookup(char) ,self.key.."_flag", false)
        dev.log("Added trait trigger ["..self.key.."] to character ["..tostring(char:command_queue_index()).."] from faction ["..char:faction():name().."] ")
        self.out_for_trigger = true
        self.flagged_cqi = char:command_queue_index()
        self:cache()
    end
end


--v [NO_CHECK] function(self: TRAIT_MANAGER)
function trait_manager.clear_trait_flag(self)
    self.flagged_cqi = -1
    self.out_for_trigger = false
    self:cache() 
end


--v function(self: TRAIT_MANAGER, event: string, conditional_function: function(context: WHATEVER) --> (boolean, CA_CHAR?), on_trigger: (function(cqi: CA_CQI))? )
function trait_manager.add_dilemma_flag_listener(self, event, conditional_function, on_trigger)
    local flag = self.key .."_flag"
    self:wait(function()
        --listen for trigger
        cm:add_listener(
            "TraitTrigger"..self.key,
            event,
            function(context)
                return true
            end,
            function(context)
                local flag = self.key .."_flag"
                self:log("Evaluating trait validity ".. self.key)
                local valid, char = conditional_function(context)
                --exclude case, no character returned
                --# assume char: CA_CHAR
                if (not char) or char:is_null_interface() then
                    return 
                end
                --case: out for trigger and trigger char now invalid
                if self.out_for_trigger and (not valid) then
                    if char:command_queue_index() == self.flagged_cqi then
                        cm:force_remove_trait(dev.lookup(char), flag)
                        self:clear_trait_flag()
                    end
                end
                --case: valid, not yet out for a trigger, not previously triggered for this CQI
                if valid and (not self.out_for_trigger) and ((not TM_TRIGGERED_DILEMMA[flag]) or (not TM_TRIGGERED_DILEMMA[flag][tostring(char:command_queue_index())])) then
                    apply_trait_dilemma_for_character(self, char)
                end
            end,
            true)

        --removes flags after a trait choice so that you don't get spammed with the same one.
        --also handles responses
        cm:add_listener(
            "DilemmaChoiceMadeEventRemoveFlagsTraitName",
            "DilemmaChoiceMadeEvent",
            function(context)
                return not not string.find(context:dilemma(), self.key.."_choice")
            end,
            function(context)
                for i = 0, context:faction():character_list():num_items() - 1 do
                    local char = context:faction():character_list():item_at(i)
                    if char:has_trait(flag) then
                        if on_trigger then
                            --# assume on_trigger: function(cqi: CA_CQI)
                            on_trigger(char:command_queue_index())
                        end
                        if TM_TRIGGERED_DILEMMA[flag] == nil then
                            TM_TRIGGERED_DILEMMA[flag] = {}
                        end
                        TM_TRIGGERED_DILEMMA[flag][tostring(char:command_queue_index())] = true --saves the fact its happened for this character
                        cm:force_remove_trait(dev.lookup(char), flag) --ensures we don't repeat the same event over and over
                        self:clear_trait_flag()--makes the trait available again for new characters to take
                    end
                end
            end, true)
        cm:add_listener(
            "IncidentOccuredEventRemoveFlags",
            "IncidentOccuredEvent",
            function(context)
                return not not string.find(context:dilemma(), self.key.."_choice")
            end,
            function(context)
                for i = 0, context:faction():character_list():num_items() - 1 do
                    local char = context:faction():character_list():item_at(i)
                    if char:has_trait(flag) then
                        if on_trigger then
                            --# assume on_trigger: function(cqi: CA_CQI)
                            on_trigger(char:command_queue_index())
                        end
                        cm:force_remove_trait(dev.lookup(char), flag) --ensures we don't repeat the same event over and over
                        if TM_TRIGGERED_DILEMMA[flag] == nil then
                            TM_TRIGGERED_DILEMMA[flag] = {}
                        end
                        TM_TRIGGERED_DILEMMA[flag][tostring(char:command_queue_index())] = true --saves the fact its happened for this character
                        self:clear_trait_flag() --makes the trait available again for new characters to take
                    end
                end
            end, true)

    end)
end


--v function(self: TRAIT_MANAGER, event: string, conditional_function: function(context: WHATEVER) --> (boolean, CA_CHAR?), ...:string)
function trait_manager.add_normal_trait_trigger(self, event, conditional_function, ...) 
    --the veriadic args are used for traits to also add when this particular listener fires. Used for traits that always come together.
    self:wait(function()
        cm:add_listener(
            "TMTraitTriggerNormal"..self.key,
            event,
            true,
            function(context)
                local valid, char = conditional_function(context)
                --case: function returned a valid character
                if valid and char then
                    --# assume char: CA_CHAR
                    if not char:has_trait(self.key) then
                        cm:force_add_trait(dev.lookup(char), self.key, true)
                    end
                    
                    for i = 1, arg.n do
                        if not char:has_trait(arg[i]) then
                            cm:force_add_trait(dev.lookup(char), arg[i], true)
                        end
                    end
                end
            end,
            true
        )
    end)
end

--v function(self: TRAIT_MANAGER, ...:string)
function trait_manager.set_start_pos_characters(self, ...)
    dev.first_tick(function(context)
        if self.start_traits_applied == false then
            cm:set_saved_value("tm_"..self.key.."_start_traits_applied", true)
            for i = 1, arg.n do
                cm:force_add_trait(arg[i], self.key, false)
            end
        end
    end)
end

--v function(self: TRAIT_MANAGER, other_trait: string, effect: number)
function trait_manager.set_cross_loyalty(self, other_trait, effect)
    PettyKingdoms.CharacterPolitics.add_trait_cross_loyalty_to_trait(self.key, other_trait, dev.mround(effect, 1))
end

--v function(self: TRAIT_MANAGER, event: string, conditional_function: (function(context:WHATEVER) --> (boolean, CA_FACTION)))
function trait_manager.set_loyalty_event_condition(self, event, conditional_function)
    self:wait(function()
    cm:add_listener(
        "TMLoyaltyEvent"..self.key,
        event,
        function(context)
            return true
        end,
        function(context)
            local valid, faction = conditional_function(context)
            if valid and faction then
                self:log("Loyalty event occured for trait ["..self.key.."]")
                local chars = faction:character_list() 
                for i = 0, chars:num_items() - 1 do
                    local char = chars:item_at(i)
                    if not char:is_faction_leader() and char:has_trait(self.key) then
                        cm:force_add_trait(dev.lookup(char), self.key.."_loyalty_event_flag", false)
                    end
                end
                cm:set_saved_value("tm_"..self.key.."_remove_loyalty_event", cm:model():turn_number() + 3)
            end
        end,
        true
    )
    --removes flags after a trait loyalty event so that you don't get spammed with the same one.
    cm:add_listener(
        "DilemmaChoiceMadeEventRemoveFlagsTraitName",
        "DilemmaChoiceMadeEvent",
        function(context)
            return not not string.find(context:dilemma(), self.key.."_loyalty_event")
        end,
        function(context)
            local faction = context:faction()
            local chars = faction:character_list() 
            for i = 0, chars:num_items() - 1 do
                local char = chars:item_at(i)
                if char:has_trait(self.key.."_loyalty_event_flag") then
                    cm:force_remove_trait(dev.lookup(char), self.key.."_loyalty_event_flag")
                end
            end
        end, true)
    cm:add_listener(
        "IncidentOccuredEventRemoveFlags",
        "IncidentOccuredEvent",
        function(context)
            return not not string.find(context:dilemma(), self.key.."_loyalty_event")
        end,
        function(context)
            local faction = context:faction()
            local chars = faction:character_list() 
            for i = 0, chars:num_items() - 1 do
                local char = chars:item_at(i)
                if char:has_trait(self.key.."_loyalty_event_flag") then
                    cm:force_remove_trait(dev.lookup(char), self.key.."_loyalty_event_flag")
                end
            end
        end, true)
    end)
end

--v function(self: TRAIT_MANAGER, event: string, conditional_function: (function(context:WHATEVER) --> (boolean, CA_FACTION)), choices: map<number, boolean>)
function trait_manager.add_faction_leader_dilemma(self, event, conditional_function, choices)
    cm:add_listener(
        "TMFactionLeaderDilemma"..self.key,
        event,
        true,
        function(context)
            local valid, faction = conditional_function(context)
            if valid and faction and faction:is_human() and not faction:faction_leader():is_null_interface() then
                local character = faction:faction_leader()
                local dilemma = self.key.."_kings_choice"
                if (not TM_TRIGGERED_DILEMMA[dilemma]) or (not TM_TRIGGERED_DILEMMA[dilemma][tostring(character:command_queue_index())]) and not character:has_trait(self.key) then
                    cm:trigger_dilemma(faction:name(), dilemma, true)
                    if TM_TRIGGERED_DILEMMA[dilemma] == nil then
                        TM_TRIGGERED_DILEMMA[dilemma] = {}
                    end
                    TM_TRIGGERED_DILEMMA[dilemma][tostring(character:command_queue_index())] = true
                end
            end
        end,
        true)
        cm:add_listener(
            "DilemmaChoiceMadeEventTMFactionLeaderDilemma"..self.key,
            "DilemmaChoiceMadeEvent",
            function(context)
                return not not string.find(context:dilemma(), self.key.."_kings_choice")
            end,
            function(context)
                local faction = context:faction()
                local character = faction:faction_leader()
                local dilemma = context:dilemma()
                local choice = context:choice()
                if choices[choice] == true then
                    cm:force_add_trait(dev.lookup(character), self.key, true)
                end
            end, true)
end

--v function(self: TRAIT_MANAGER, event: string, completion_condition: (function(context: WHATEVER) --> boolean), num_to_complete: number)
function trait_manager.add_faction_leader_trait_mission(self, event, completion_condition, num_to_complete)
    cm:add_listener(
        "TMMissionIssued"..self.key,
        "MissionIssued",
        function(context)
            return context:mission():mission_record_key() == self.key.."_king_mission"
        end,
        function(context)
            self.mission_active = true
            self:mission_save()
        end,
        true
    )
    cm:add_listener(
        "TMMissionCompletion"..self.key,
        event,
        function(context)
            return self.mission_active
        end,
        function(context)
            local valid, faction = completion_condition(context)
            if valid and faction then
                self:log("Faction ["..faction:name().."] trait mission progress ["..self.key.."] is at ["..self.mission_counter.."] out of ["..num_to_complete.."]  ")
                self.mission_counter = self.mission_counter + 1
            end
            if self.mission_counter >= num_to_complete and faction then
                self:log("Completing mission for trait ["..self.key.."]")
                cm:override_mission_succeeded_status(faction:name(), self.key.."_king_mission", true)
                cm:force_add_trait(dev.lookup(faction:faction_leader()), self.key, true)
                self.mission_counter = 0
                self.mission_active = false
            end
            self:mission_save()
        end,
        true
    )

end

cm:register_loading_game_callback(
    function(context)
		TM_TRIGGERED_DILEMMA = cm:load_value("TM_TRIGGERED_DILEMMA", {}, context);
	end
);

cm:register_saving_game_callback(
	function(context)
        cm:save_value("TM_TRIGGERED_DILEMMA", TM_TRIGGERED_DILEMMA, context);
	end
);


return {
    new = trait_manager.new
}