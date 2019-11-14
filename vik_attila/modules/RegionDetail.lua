local region_detail = {} --# assume region_detail:REGION_DETAIL

--v function(region_key: string)
function region_detail.new(region_key)
    local self = {}
    setmetatable(self, {
        __index = region_detail
    })

    self.last_sacked_turn = -1
    self.last_ownership_change = -1
    self.key = region_key
    self.riot_in_progress = false --:boolean
    self.riot_timer = 0 --:number
    self.riot_event_cooldown = 0 --:number
end

--v function(self: REGION_DETAIL, t: any)
function region_detail.log(self, t)
    dev.log(tostring(t), self.key)
end

--v function(self: REGION_DETAIL) --> CA_REGION
function region_detail.get_region(self)
    return dev.get_region(self.key)
end

--v function(self: REGION_DETAIL) --> number
function region_detail.public_order(self)
    local region = self:get_region()
    return region:sanitation() - region:squalor()
end

--v function(self: REGION_DETAIL) --> 

--v function(self: REGION_DETAIL) --> CA_REGION
function region_detail.new_turn(self)
    local region = self:get_region()
    local region_name = region:name()
    local public_order = self:public_order()
    local owning_faction = region:owning_faction()
    self:log("Starting turn!")
    if self.riot_in_progress then
        --we are rioting!
        if public_order > 0 then
            --riot should end
        elseif self.riot_event_cooldown == 0 then
            --riot should continue with an event
        else
            --riot should reduce cooldowns and continue with no event.
        end
    else
        --no riot present
    end
end



return {

}