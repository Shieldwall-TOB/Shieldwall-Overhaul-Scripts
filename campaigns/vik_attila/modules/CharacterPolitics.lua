local character_politics = {} --# assume character_politics:CHARACTER_POLITICS

--v function(cqi: CA_CQI)
function character_politics.new(cqi)
    local self = {}
    setmetatable(self, {
        __index = character_politics
    }) --# assume self: CHARACTER_POLITICS

    self.last_governorship = "none" --:string
    self.friendship_level = 2 --:string
    self.general_level = 0 --:string
    self.title = 0

end