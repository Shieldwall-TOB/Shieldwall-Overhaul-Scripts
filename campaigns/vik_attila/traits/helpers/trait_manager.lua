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

    self.key = trait_key
    self.start_traits_applied = false --:boolean
    self.chance_modifiers = {} --:vector<(function(character: CA_CHAR)--> int)>
    self.prohibiters = {} --:vector<(function(character:CA_CHAR) --> boolean)>
    self.anti_traits = {} --:map<string, boolean>
    self.base_chance = 100

    self.already_triggered_choices = {} --:map<string, map<string, boolean>>
    self.condition_group = dev.GameEvents:create_new_condition_group(trait_key)
    self.condition_group:set_number_allowed_in_queue(1)
    self.condition_group:set_cooldown(2)
    dev.GameEvents:register_condition_group(self.condition_group, "CharacterTurnStart")
    self.save = {
        name = trait_key.."_manager", 
        for_save = {"start_traits_applied", "already_triggered_choices"}
    }--:SAVE_SCHEMA
    dev.Save.attach_to_object(self)

    return self
end

--v function(self: TRAIT_MANAGER, text: any)
function trait_manager.log(self, text)
    dev.log(tostring(text), "TRAITS")
end

--v function(self: TRAIT_MANAGER, char: CA_CHAR) --> int
function trait_manager.get_chance(self, char)
    local chance = self.base_chance 
    for i = 1, #self.chance_modifiers do
        chance = chance + self.chance_modifiers[i](char)  
    end
    return chance
end

--v function(self: TRAIT_MANAGER, character: CA_CHAR) --> boolean
function trait_manager.is_trait_valid_on_character(self, character)
    local pol_char = PettyKingdoms.CharacterPolitics.get(character)
    for i = 1, #pol_char.traits do
        if self.anti_traits[pol_char.traits[i]] then
            return false
        end
    end
    for i = 1, #self.prohibiters do
        if self.prohibiters[i](character) == false then
            return false
        end
    end
    return true
end

--v function(self: TRAIT_MANAGER, character: CA_CHAR, even_if_invalid: boolean?) --> boolean
function trait_manager.add_to_character(self, character, even_if_invalid)
    if even_if_invalid or self:is_trait_valid_on_character(character) then
        dev.add_trait(character, self.key, true)
        return true
    end
    return false
end

--v function(self: TRAIT_MANAGER, ...:string)
function trait_manager.set_anti_traits(self, ...)
    for i = 1, arg.n do
        self.anti_traits[arg[i]] = true
    end
end

--v function(self: TRAIT_MANAGER, chance: int)
function trait_manager.set_base_chance(self, chance)
    self.base_chance = chance
end

--v function(self: TRAIT_MANAGER, dilemma_key: string, additional_condition: function(character: CA_CHAR) --> boolean, should_use_chance: boolean)
function trait_manager.add_trait_gained_dilemma(self, dilemma_key, additional_condition, should_use_chance)
    self.already_triggered_choices[dilemma_key] = self.already_triggered_choices[dilemma_key] or {}
    local event = dev.GameEvents:create_event(dilemma_key, "dilemma", "trait_flag")
    event:add_queue_time_condition(function(context)
        local character = context:character() --:CA_CHAR

        return (not self.already_triggered_choices[dilemma_key][tostring(character:command_queue_index())])
        and (not character:is_faction_leader())
        and (not should_use_chance or dev.chance(self:get_chance(character))) 
        and (self:is_trait_valid_on_character(character) and additional_condition(character))
    end)
    event:join_groups(self.condition_group.name)
    event:add_callback(function(context)
        local character = context:character() --:CA_CHAR
        self.already_triggered_choices[dilemma_key][tostring(character:command_queue_index())] = true
    end)
end


--v function(self: TRAIT_MANAGER, modifier: (function(character: CA_CHAR) --> int))
function trait_manager.add_chance_modifier(self, modifier)
    table.insert(self.chance_modifiers, modifier)
end
--v function(self: TRAIT_MANAGER, prohibiter: (function(character: CA_CHAR) --> boolean))
function trait_manager.add_prohibiter(self, prohibiter)
    table.insert(self.prohibiters, prohibiter)
end

--v function(self: TRAIT_MANAGER, ...:string)
function trait_manager.set_start_pos_characters(self, ...)
    dev.first_tick(function(context)
        if self.start_traits_applied == false then
            cm:set_saved_value("tm_"..self.key.."_start_traits_applied", true)
            for i = 1, arg.n do
                cm:force_add_trait(arg[i], self.key, false)
            end
            dev.eh:trigger_event("StartPosTraitAdded", self.key)
        end
    end)
end


return {
    new = trait_manager.new
}