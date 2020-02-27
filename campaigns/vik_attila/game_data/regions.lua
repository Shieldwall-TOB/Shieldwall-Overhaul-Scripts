local province_to_regions = {} --:map<string, vector<string>>
local province_capitals = {} --:map<string, string>

dev.pre_first_tick(function(context)
    for i = 0, dev.region_list():num_items() - 1 do
        local region = dev.region_list():item_at(i)
        province_to_regions[region:province_name()] = province_to_regions[region:province_name()] or {}
        table.insert(province_to_regions[region:province_name()], region:name())
        if region:is_province_capital() then
            province_capitals[region:province_name()] = region:name()
        end
    end
end)

--v function(region: string | CA_REGION) --> vector<string>
local function get_regions_in_regions_province(region)
    --# assume is_region: function(faction: any) --> boolean
    local region_obj = nil --:CA_REGION
    if is_string(region) then
        --# assume region: string
        region_obj = dev.get_region(region) 
    elseif is_region(region) then
        --# assume region: CA_REGION
        region_obj = region
    else
        return nil
    end
    return province_to_regions[region_obj:province_name()]
end

--v function(region: string|CA_REGION) --> CA_REGION
local function get_province_capital_of_regions_province(region)
    --# assume is_region: function(faction: any) --> boolean
    local region_obj = nil --:CA_REGION
    if is_string(region) then
        --# assume region: string
        region_obj = dev.get_region(region) 
    elseif is_region(region) then
        --# assume region: CA_REGION
        region_obj = region
    else
        return nil
    end
    return dev.get_region(province_capitals[region_obj:province_name()])

end

return {
    get_regions_in_regions_province = get_regions_in_regions_province,
    get_province_capital_of_regions_province = get_province_capital_of_regions_province
}