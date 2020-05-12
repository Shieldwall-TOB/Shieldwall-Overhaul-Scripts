--this module acts as the central manager of the game's traits system from the perspective of the traits. 
--This is most often used for traits which don't have definite triggers, or have many different triggers.
--If a trait is better systemized as a politics trait, it is done there from the character's perspective.

--this module needs to support the following elements:
-- character triggers: fire off dilemmas external to scripted systems.
-----Powers: Dissident and Loyalist Traits, some trait actions, governor dilemma.
-- Central chance: a referencable chance that can be altered by events.

local traits = {} --# assume traits: TRAITS


--v function(key: string, base_chance: number) --> TRAITS
function traits.new(key, base_chance)
    local self = {}
    setmetatable(self, {
        __index = traits
    }) --# assume self: TRAITS

    self.key = key
    self.trait_chance = base_chance

    --map a string trigger key to info about whether to search to fire the trigger and where it is placed.
    self.triggers_out = {} --:map<string, boolean>
    self.triggers_cqi = {} --:map<string, CA_CQI>

    --which traits can you develop if you're loyal while the king has this trait?
    self.loyalty_trait_development = {} --:vector<string>
    --which traits can you develop if you're disloyal while the king has this trait?
    self.disloyalty_trait_development = {} --:vector<string>

    --have we applied startpos traits?
    self.start_traits_applied = false --:boolean

    self.removal_trait_turns = {} --:map<string, map<string, number>>

    self.save = {
        name = key,
        for_save = {"trait_chance", "triggers_out", "triggers_cqi", "start_traits_applied"}
    }
    dev.Save.attach_to_object(self)
    return self
end


--General Util
--v function(self: TRAITS, t: any)
function traits.log(self, t)
    dev.log(tostring(t), "TRAITS")
end

--Triggers System
--v function(self: TRAITS, suffix: string, event: string, conditional: function(context: WHATEVER) --> (boolean, CA_CHAR), response_function: (function(data: EVENT_RESPONSE))?)
function traits.add_trigger(self, suffix, event, conditional, response_function)
    local comp_key = self.key..suffix
    dev.eh:add_listener(
        self.key..suffix,
        event,
        function(context)
            return not self.triggers_out[comp_key]
        end,
        function(context)
            local ok, char = conditional(context)
            if ok and char and (not char:is_null_interface()) and char:faction():is_human() then
                dev.add_trait(char, comp_key.."_flag", false, true)
                self.triggers_out[comp_key] = true
                self.triggers_cqi[comp_key] = char:command_queue_index()
            end
        end,
        true
    )
    dev.eh:add_listener(
        self.key..suffix,
        "DilemmaChoiceMadeEvent",
        function(context)
            return context:dilemma() == comp_key.."_choice"
        end,
        function(context)
            self.triggers_out[comp_key] = false
            if not self.triggers_cqi[comp_key] then
                self:log(context:dilemma().." occured but there is no CQI trigger set for it!")
                return
            end
            if response_function then
                --# assume response_function:function(data: EVENT_RESPONSE)
                response_function({context = context, has_region = false, has_character = true, character = self.triggers_cqi[comp_key]})
            end
            self.triggers_cqi[comp_key] = nil
        end,
        true
    )
end

--startpos characters

--v function(self: TRAITS, ...: string)
function traits.set_start_pos_characters(self, ...)
    dev.first_tick(function(context)
        if self.start_traits_applied == false then
            self.start_traits_applied = true
            for i = 1, arg.n do
                cm:force_add_trait(arg[i], self.key, false)
            end
            dev.eh:trigger_event("StartPosTraitAdded", self.key)
        end
    end)
end

--trait loyalty effects

--v function(self: TRAITS, index: int, event: string, conditional: function(context: WHATEVER) --> (boolean, CA_CHAR))
function traits.add_trait_loyalty_effect_listener(self, index, event, conditional)
    dev.eh:add_listener(
        self.key..tostring(index),
        event,
        true,
        function(context)
            local ok, char = conditional(context)
            if ok and char and not char:is_null_interface() and char:faction():is_human() and char:has_trait(self.key) then
                local effect_key = "sw_trait_loyalty_"..self.key.."_"..tostring(index)
                dev.add_trait(char, effect_key, false, true)
                self.removal_trait_turns[tostring(char:command_queue_index())] = self.removal_trait_turns[tostring(char:command_queue_index())] or {}
                self.removal_trait_turns[tostring(char:command_queue_index())][effect_key] = cm:model():turn_number() + 12;
            end
        end,
        true
    )

end


--v function(key: string, base_chance: int) --> TRAITS
local function new_trait_manager(key, base_chance)
    local tm = traits.new(key, base_chance)
    dev.eh:add_listener(
        key.."_trait_remover",
        "CharacterTurnStart",
        function(context)
            return not not tm.removal_trait_turns[tostring(context:character():command_queue_index())]
        end,
        function(context)
            for trait, turn in pairs(tm.removal_trait_turns[tostring(context:character():command_queue_index())]) do
                if turn <= cm:model():turn_number() then
                    cm:force_remove_trait(dev.lookup(context:character()), trait)
                    tm.removal_trait_turns[tostring(context:character():command_queue_index())][trait] = nil
                end
            end
        end,
        true
    )
    return tm
end

return {
    new = new_trait_manager
}