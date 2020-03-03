--the south of england has the following allegiance groups:
--1. The Saxons: they will unite when under heavy attack.
--2. The Welsh: they will be more likely to attack Saxons when united and they will be more likely to attack people already engaged in a war.
--3. The Great Viking Army: will be more likely to devolve into infighting when they are winnning.
--4. The Boroughs will hate people who conquer them.
local boroughs = {
    "vik_fact_hellirborg",
    "vik_fact_steinnborg",
    "vik_fact_hylrborg",
    "vik_fact_djurby",
    "vik_fact_ledeborg"
}


dev.first_tick(function(context)
    dev.log("Geopolitics eng_south starting")
    local south_england = PettyKingdoms.Geopolitics.new("eng_south")
    local factions_to_add = {
        ["vik_fact_west_seaxe"] = function(faction) --:CA_FACTION 
            return Gamedata.regions.province_list_to_region_list(
                Gamedata.kingdoms.kingdom_provinces(faction))
        end,
        ["vik_fact_mierce"] = function(faction) --:CA_FACTION 
            return Gamedata.regions.province_list_to_region_list(
                Gamedata.kingdoms.kingdom_provinces(faction))
        end,
        ["vik_fact_east_engle"] = function(faction) --:CA_FACTION 
            return Gamedata.regions.province_list_to_region_list(
                Gamedata.kingdoms.kingdom_provinces(faction))
        end,
        ["vik_fact_northymbre"] = function(faction) --:CA_FACTION 
            return Gamedata.regions.province_list_to_region_list(
                Gamedata.kingdoms.kingdom_provinces(faction))
        end,
        ["vik_fact_gwined"] = function(faction) --:CA_FACTION 
            return Gamedata.regions.province_list_to_region_list(
                Gamedata.kingdoms.kingdom_provinces(faction))
        end,
        ["vik_fact_powis"] = function(faction) --:CA_FACTION 
            return Gamedata.regions.province_list_to_region_list(
                Gamedata.kingdoms.kingdom_provinces(dev.get_faction("vik_fact_gwined")))
        end,
        ["vik_fact_seisilwig"] = function(faction) --:CA_FACTION 
            return Gamedata.regions.province_list_to_region_list(
                Gamedata.kingdoms.kingdom_provinces(dev.get_faction("vik_fact_gwined")))
        end,
        ["vik_fact_hellirborg"] = function(faction) --:CA_FACTION 
            local retval = {} --:vector<string>
            for i = 1, #boroughs do
                local region_list = faction:region_list()
                for j = 0, region_list:num_items() - 1 do 
                    retval[#retval+1] = region_list:item_at(j):name()
                end
            end
            return retval
        end,
        ["vik_fact_steinnborg"] = function(faction) --:CA_FACTION 
            local retval = {} --:vector<string>
            for i = 1, #boroughs do
                local region_list = faction:region_list()
                for j = 0, region_list:num_items() - 1 do 
                    retval[#retval+1] = region_list:item_at(j):name()
                end
            end return retval
        end,
        ["vik_fact_hylrborg"] = function(faction) --:CA_FACTION 
            local retval = {} --:vector<string>
            for i = 1, #boroughs do
                local region_list = faction:region_list()
                for j = 0, region_list:num_items() - 1 do 
                    retval[#retval+1] = region_list:item_at(j):name()
                end
            end return retval
        end,
        ["vik_fact_djurby"] = function(faction) --:CA_FACTION 
            local retval = {} --:vector<string>
            for i = 1, #boroughs do
                local region_list = faction:region_list()
                for j = 0, region_list:num_items() - 1 do 
                    retval[#retval+1] = region_list:item_at(j):name()
                end
            end return retval
        end,
        ["vik_fact_ledeborg"] = function(faction) --:CA_FACTION 
            local retval = {} --:vector<string>
            for i = 1, #boroughs do
                local region_list = faction:region_list()
                for j = 0, region_list:num_items() - 1 do 
                    retval[#retval+1] = region_list:item_at(j):name()
                end
            end return retval
        end
    } --:map<string, function(CA_FACTION) --> vector<string>>
    if dev.is_new_game() then
        for k, v in pairs(factions_to_add) do
            south_england:add_faction(k, v(dev.get_faction(k)), {}, {})
        end
    end
    

    south_england:activate()
end)