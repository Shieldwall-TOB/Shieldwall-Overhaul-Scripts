local faction_decree_handler = {} --# assume faction_decree_handler: FACTION_DECREE_HANDLER
local handler_instances = {} --:map<string, FACTION_DECREE_HANDLER>
local decree = {} --# assume decree: DECREE
local decree_instances = {} --:map<string, map<string, DECREE>>

--v function(t: string)
local function log(t)
    dev.log(t, "DECREE")
end

--v function(faction_key: string, global_cooldown: number) --> FACTION_DECREE_HANDLER
function faction_decree_handler.new(faction_key, global_cooldown)
    local self = {}
    setmetatable(self, {__index = faction_decree_handler}) 
    --# assume self: FACTION_DECREE_HANDLER
    self.owning_faction = faction_key
    self.global_cooldown = global_cooldown
    self.current_global = 0
    self.zero_cost_turns = 0
    self.save = {
        name = self.owning_faction .. "_decrees",
        for_save = {"current_global", "zero_cost_turns"}
    }--:SAVE_SCHEMA
    Save.attach_to_object(self)
    return self
end

--v function(faction_key: string, global_cooldown: number)
local function new_decree_handler(faction_key, global_cooldown)
    local new_instance = faction_decree_handler.new(faction_key, global_cooldown)
    handler_instances[faction_key] = new_instance
end

--v function(faction_name: string, index: number, event: string, duration: number, cooldown: number, currency: string?, currency_cost: number?, is_dilemma: boolean?) --> DECREE
function decree.new(faction_name, index, event, duration, cooldown, currency, currency_cost, is_dilemma)
    local self = {}
    setmetatable(self, {__index = decree})
    --# assume self: DECREE

    self.key = "decree_"..faction_name .. "_" .. index
    
    self.i = index
    self.owning_faction = faction_name
    self.handler = handler_instances[self.owning_faction] or new_decree_handler(self.owning_faction, 0)
    self.is_locked = true --:boolean
    self.can_ever_relock = false --:boolean
    self.callback = function(decree) end --:function(decree: DECREE)
    self.gold_cost = 0
    self.currency = currency or "none" --:string
    self.currency_cost = currency_cost or 0 --:number
    self.event = event
    self.is_dilemma = not not is_dilemma 
    self.cooldown = cooldown
    self.current_cooldown = 0
    self.duration = duration

    if self.owning_faction == cm:get_local_faction(true) then
        UIScript.decree_panel.add_decree(self.i, self.event, self.is_dilemma)
    end

    self.save = {
        name = self.key,
        for_save = {"current_cooldown", "is_locked"}
    }--:SAVE_SCHEMA
    Save.attach_to_object(self)
    return self 
end

local currency_cost_applicators = {
    ["influence"] = function(decree) --:DECREE
        --influence costs are incurred using decree events themselves.
        --do nothing.
    end
} --:map<string, function(decree: DECREE)>
local currency_cost_checkers = {
    ["influence"] = function(faction_name) --:string
        local faction = dev.get_faction(faction_name)
        if faction:faction_leader():is_null_interface() then 
            return 0
        end
        return faction:faction_leader():gravitas()
    end
} --:map<string, (function(faction_name: string) --> number)>


--v function(self: DECREE, script_event: string, conditional: function(context: WHATEVER) --> (boolean, boolean?))
function decree.add_unlock_condition(self, script_event, conditional)
    dev.eh:add_listener(
        self.key.."_unlocks",
        script_event,
        function(context)
            return self.is_locked or self.can_ever_relock
        end,
        function(context)
            local unlock, relock = conditional(context)
            if unlock == true then 
                self.is_locked = false
            elseif not not relock and self.can_ever_relock then
                self.is_locked = true
            end
        end,
        true)

end

--v function(self: DECREE)
function decree.apply_costs(self)
    if self.gold_cost ~= 0 then
        cm:treasury_mod(self.owning_faction, self.gold_cost)
    end
    local currency_applicator = currency_cost_applicators[self.currency]
    if currency_applicator then
        currency_applicator(self)
    else
        log("Missing currency cost applicator for ["..self.currency.."]")
    end
end

--v function(self: DECREE) --> number
function decree.get_effective_gold_cost(self)
    local effective_gold = self.gold_cost
    if self.handler.zero_cost_turns > 0 then
        effective_gold = 0
    end
    return effective_gold
end

--v function(self: DECREE, effective_gold_cost: number) --> boolean
function decree.can_owner_afford(self, effective_gold_cost)
    local faction = dev.get_faction(self.owning_faction)
    if faction:treasury() > effective_gold_cost then
        --we can afford gold
        if self.currency_cost == 0 then
            can_afford = true
        elseif currency_cost_checkers[self.currency] and currency_cost_checkers[self.currency](faction:name()) > self.currency_cost then
            can_afford = true
        end
    end
    return can_afford
end


--v function(self: DECREE)
function decree.update_panel(self)
    local faction = dev.get_faction(self.owning_faction)
    if faction:name() ~= cm:model():world():whose_turn_is_it():name() then
        log("Called to update panel for "..self.key.." when it isn't the owning faction's turn!")
        return
    end
    local global_cd = self.handler.current_global
    local is_global = false
    local effective_cooldown = self.current_cooldown
    if global_cd > 0 and global_cd > self.current_cooldown then
        is_global = true
        effective_cooldown = global_cd
    end
    local effective_gold = self:get_effective_gold_cost()
    local can_afford = self:can_owner_afford(effective_gold)
    UIScript.decree_panel.update_panel(self.i, effective_cooldown, is_global, effective_gold, self.currency_cost, self.currency, self.duration, can_afford, self.is_locked)
end



--v function(faction_name: string, index: number, event: string, duration: number, cooldown: number, currency: string?, currency_cost: number?, is_dilemma: boolean?) --> DECREE
local function new_decree(faction_name, index, event, duration, cooldown, currency, currency_cost, is_dilemma)
    local instance = decree.new(faction_name, index, event, duration, cooldown, currency, currency_cost, is_dilemma)
    decree_instances[faction_name] = decree_instances[faction_name] or {}
    decree_instances[faction_name][event] = instance
    if is_dilemma then
        dev.eh:add_listener(
            instance.key.."_occured",
            "DilemmaIssuedEvent",
            function(context)
                return context:dilemma() == instance.event
            end,
            function(context) 
                dev.respond_to_dilemma(instance.event, function(context)
                    if instance.callback then
                        instance.callback(instance)
                    end
                end)
            end,
            true
        );
    else
        dev.eh:add_listener(
            instance.key.."_occured",
            "IncidentOccuredEvent",
            function(context)
                return context:dilemma() == instance.event
            end,
            function(context) 
                if instance.handler.global_cooldown > 0 then
                    instance.handler.current_global = instance.handler.global_cooldown
                end
                dev.respond_to_incident(instance.event, function(context)
                    if instance.callback then
                        instance.callback(instance)
                    end
                end)
            end,
            true
        );
    end
    dev.eh:add_listener(
        instance.key.."_panel",
        "UpdateDecrees",
        function(context)
            return context:faction():name() == instance.owning_faction
        end,
        function(context)
            instance:update_panel()
        end,
        true
    )
    return instance
end


return {
    add_faction_handler = new_decree_handler,
    add_decree = new_decree
}