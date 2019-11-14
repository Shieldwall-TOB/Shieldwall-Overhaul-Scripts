local BURGHAL_FACTIONS = {
    "vik_fact_west_seaxe",
    "vik_fact_mierce",
    "vik_fact_northleode"
}--:vector<string>

ENG_BURGHAL = {} --:map<string, FACTION_RESOURCE>

for i = 1, #BURGHAL_FACTIONS do
    local resource = PettyKingdoms.FactionResource.new(BURGHAL_FACTIONS[i], "vik_english_peasant", "capacity_fill", 0, 3, {})
    ENG_BURGHAL[BURGHAL_FACTIONS[i]] = resource
    resource.conversion_function = function(self) --:FACTION_RESOURCE
        if self.value >= self.cap_value then
            return "positive"
        else
            return "negative"
        end
    end
end

--v function(region_list: CA_REGION_LIST) --> (number, number)
local function calculate_burghal_value(region_list)
    local new_brughal = 0 --:number
	local new_total = 0 --:number
	local check_reg = {} --:map<CA_CQI, boolean>
	for i = 0, region_list:num_items() - 1 do
		local region = region_list:item_at(i)
		if region:is_province_capital() then
			if region:has_governor() and (not check_reg[region:governor():command_queue_index()]) then
				new_total = new_total+ 1;
				check_reg[region:governor():command_queue_index()] = true
				if region:governor():loyalty() >= 5 then 
					 new_brughal = new_brughal + 1;
				end
			end
		end
    end
    return new_brughal, new_total
end

--v function(faction_name: string)
local function refresh_burghal(faction_name)
    local new_value, new_total = calculate_burghal_value(dev.get_faction(faction_name):region_list())
    ENG_BURGHAL[faction_name]:set_new_value(new_value, new_total)
end

dev.first_tick(function(context)
    for i = 1, #BURGHAL_FACTIONS do
        local faction_name = BURGHAL_FACTIONS[i]
        if dev.get_faction(faction_name):is_human() then
            refresh_burghal(faction_name)
            dev.turn_start(faction_name, function(context)
                refresh_burghal(context:faction():name())
            end)

        end
    end
end)