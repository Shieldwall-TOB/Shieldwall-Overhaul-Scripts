local faction_decree_handler = {} --# assume faction_decree_handler: FACTION_DECREE_HANDLER
local handler_instances = {} --:map<string, FACTION_DECREE_HANDLER>
local decree = {} --# assume decree: DECREE
local decree_instances = {} --:map<string, map<number, DECREE>>

--v function(faction_key: string, global_cooldown: number)
function faction_decree_handler.new(faction_key, global_cooldown)
    local self = {}
    setmetatable(self, {__index = faction_decree_handler}) 
    --# assume self: FACTION_DECREE_HANDLER
    self.owning_faction = faction_key
    self.global_cooldown = global_cooldown

    return self
end


local currency_cost_applicators = {} --:map<string, function(number)>

--v function(faction_name: string, index: number, event: string, duration: number, cooldown: number, currency: string?, currency_cost: number?) --> DECREE
function decree.new(faction_name, index, event, duration, cooldown, currency, currency_cost)
    local self = {}
    setmetatable(self, {__index = decree})
    --# assume self: DECREE

    self.key = "decree_"..faction_name .. "_" .. index
    
    self.i = index
    self.owning_faction = faction_name
    self.condition = function(decree) return true end --:function(decree: DECREE) --> boolean
    self.callback = function(decree) end --:function(decree: DECREE)
    self.gold_cost = 0
    self.currency = currency or "none" --:string
    self.currency_cost = currency_cost or 0 --:number
    self.event = event
    self.is_dilemma = false --:boolean
    self.cooldown = cooldown
    self.current_cooldown = 0


    self.save = {
        name = self.key,
        for_save = {"current_cooldown"}
    }--:SAVE_SCHEMA
    Save.attach_to_object(self)
    return self 
end


--v function(faction_key: string, global_cooldown: number)
local function new_decree_handler(faction_key, global_cooldown)
    local new_instance = faction_decree_handler.new(faction_key, global_cooldown)
    handler_instances[faction_key] = new_instance
end


--v function(faction_name: string, index: number, event: string, duration: number, cooldown: number, currency: string?, currency_cost: number?) --> DECREE
local function new_decree(faction_name, index, event, duration, cooldown, currency, currency_cost)
    local instance = decree.new(faction_name, index, event, duration, cooldown, currency, currency_cost)
    decree_instances[faction_name] = decree_instances[faction_name] or {}
    decree_instances[faction_name][index] = instance

end


return {
    add_faction_handler = new_decree_handler,
    add_decree = new_decree
}