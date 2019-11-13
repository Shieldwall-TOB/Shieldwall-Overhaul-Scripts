--handles script simulated resources (ex. heroism, population, hoards)
local faction_resource = {} --# assume faction_resource: FACTION_RESOURCE

--v function(faction_name: string, resource_key: string, kind: RESOURCE_KIND, default_value: int, cap_value: int, breakdown_factors: map<string, int>) --> FACTION_RESOURCE
function faction_resource.new(faction_name, resource_key, kind, default_value, cap_value,breakdown_factors)
    local self = {}
    setmetatable(self, {
        __index = faction_resource
    }) --# assume self: FACTION_RESOURCE

    self.owning_faction = faction_name
    self.key = resource_key
    self.kind = kind
    self.value = default_value
    self.cap_value = cap_value
    self.last_bundle = nil --:string
    self.full_cap_is_negative = false
    self.conversion_function = function(self) --:FACTION_RESOURCE
         return self.value 
    end
    self.breakdown_factors = breakdown_factors
    self.save = {
        name = self.key .. self.owning_faction, 
        for_save = {"breakdown_factors", "value", "last_bundle", "cap_value"}
    }--:SAVE_SCHEMA
    Save.attach_to_object(self)
    return self
end

--v function(self: FACTION_RESOURCE, t: any)
function faction_resource.log(self, t)
    dev.log(tostring(t), self.key)
end

--v [NO_CHECK] function(self: FACTION_RESOURCE, ...:any)
function faction_resource.set_new_value(self, ...)
    local switch = {
        population = function(self, ...)
            if not (type(arg[2]) == "number") then
                self.log("Set new value for called but supplied arg #2 is not a number")
            else
                self.value = arg[2]
            end
            UIScript.culture_mechanics[self.kind](self.owning_faction, self.key .. "_" .. self.conversion_function(self), self.value)
        end,
        capacity_fill = function(self, ...)
            if type(arg[2]) == "number" and type(arg[3]) == "number" then
                self.value = arg[2]
                self.cap_value = arg[3]
            else
                self.log("Set new value called but supplied args are incorrectly typed: expected two numbers")
            end
    
            UIScript.culture_mechanics[self.kind](self.owning_faction, self.key .. "_" .. self.conversion_function(self), self.value, self.cap_value)
        end,
        resource_bar = function(self, ...)

        end,
        faction_focus = function(self, ...)

        end
    }--:map<RESOURCE_KIND, function(self: FACTION_RESOURCE, any...)>

    if switch[self.kind] then switch[self.kind](self, ...) else self:log("Set new value called with unrecognized mechanic kind: "..self.kind) end
    dev.eh:trigger_event("FactionResourceValueChanged", dev.get_faction(self.owning_faction), self.key)
end

--v function(self: FACTION_RESOURCE, change_value: number, factor: string?)
function faction_resource.change_value(self, change_value, factor)
    --round new value if it is not an integer, then clamp to maximum and 0.
    local new_value = dev.clamp(dev.mround(self.value + change_value, 1), 0, self.cap_value)
    if factor then
        --# assume factor: string!
        self.breakdown_factors[factor] =( self.breakdown_factors[factor] or 0) + dev.mround(change_value, 1)
    end
    self:set_new_value(new_value)
end

return {
    new = faction_resource.new
}