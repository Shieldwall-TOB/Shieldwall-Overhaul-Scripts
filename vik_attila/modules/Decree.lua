local decree = {} --# assume decree: DECREE

--v function(faction_name: string, index: number, owned_data: map<string, string>, event: string)
function decree.new(faction_name, index, owned_data, event)
    local self = {}
    setmetatable(self, {__index = decree})
    --# assume self: DECREE

    self.key = faction_name .. "_" .. index
    
    self.i = index
    self.owning_faction = faction_name
    self.condition = function() return true end --:function() --> boolean
    self.event = event
    self.is_dilemma = false --:boolean
    self.owned_data = owned_data
    self.save = {
        name = self.key,
        for_save = {"owned_data"}
    }--:SAVE_SCHEMA
    Save.attach_to_object(self)
    return self 
end

return {
    new = decree.new
}