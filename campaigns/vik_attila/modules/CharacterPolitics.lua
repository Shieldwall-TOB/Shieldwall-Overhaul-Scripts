local character_cross_trait_loyalties = {} --:map<string, map<string, int>>

local subcultures_to_title_sets = {
    vik_sub_cult_anglo_viking = "norse",
    vik_sub_cult_english = "saxon",
    vik_sub_cult_irish = "irish",
    vik_sub_cult_scots = "scotish",
    vik_sub_cult_viking = "norse",
    vik_sub_cult_viking_gael = "norse",
    vik_sub_cult_welsh = "welsh"
} --:map<string, string>

local factions_with_trait_overrides = {
    ["vik_fact_gwined"] = true,
    ["vik_fact_strat_clut"] = true,
    ["vik_fact_dyflin"] = true,
    ["vik_fact_sudreyar"] = true,
    ["vik_fact_circenn"] = true,
    ["vik_fact_mide"] = true,
    ["vik_fact_mierce"] = true,
    ["vik_fact_west_seaxe"] = true,
    ["vik_fact_east_engle"] = true,
    ["vik_fact_northymbre"] = true,
    ["vik_fact_northleode"]  = true
} --:map<string, boolean>
local basic_king_title = "shield_leader_titles_king"
local basic_vassal_title = "shield_leader_titles_vassal"

local general_level_trait = "shield_general_" --:string
local admin_level_trait = "vik_gov_province_" --:string
local loyalty_trait = "shield_trait_loyal" --:string
local disloyalty_trait = "shield_trait_disloyal" --:string
local friendship_level_trait = "shield_friendship_" --:string

local character_politics = {} --# assume character_politics:CHARACTER_POLITICS

--v function(cqi: CA_CQI) --> CHARACTER_POLITICS
function character_politics.new(cqi)
    local self = {}
    setmetatable(self, {
        __index = character_politics
    }) --# assume self: CHARACTER_POLITICS

    self.cqi = cqi
    self.last_governorship = "none" --:string
    self.friendship_level = 2 --:int
    self.plot_vulnerability = 0
    self.general_level = 0 --:int
    self.title = 0 --:int
    self.king_level = 0 --:int
    self.last_title = "none" --:string
    self.home_region = "none" --:string
    self.traits = {} --:vector<string>

    self.save = {
        name = "politics_"..tostring(self.cqi), 
        for_save = {"last_governorship", "friendship_level", "general_level", "title", "last_title", "plot_vulnerability"}
    }--:SAVE_SCHEMA
    --dev.Save.attach_to_object(self)
    return self
end 

--v function(self: CHARACTER_POLITICS, t: any)
function character_politics.log(self, t)
    dev.log(tostring(t), "CHAR"..tostring(self.cqi))
end

--v function(self: CHARACTER_POLITICS)
function character_politics.refresh_plot_vulnerability(self)
    local char = dev.get_character(self.cqi)
    local is_king = char:is_faction_leader()
    local loyal_side = is_king or char:has_trait(loyalty_trait)
    local authority = char:gravitas()
    local risk = 0
    for i = 0, char:faction():character_list():num_items() - 1 do
        local other_char = char:faction():character_list():item_at(i)
        if not (other_char:command_queue_index() == char:command_queue_index()) then
            local bonus = 1 --:number
            if other_char:is_faction_leader() then
                bonus = (5 - other_char:gravitas())/2
            elseif other_char:faction():home_region():has_governor() and other_char:faction():home_region():governor():command_queue_index() == other_char:command_queue_index() then
                bonus = 1.5
            elseif other_char:has_trait(general_level_trait.."2") then
                bonus = 1.3
            end
            if other_char:has_trait(loyalty_trait) then
                if loyal_side then
                    authority = dev.mround(authority + (other_char:gravitas() * bonus), 1)
                else
                    risk = dev.mround(risk + (other_char:gravitas() * bonus), 1)
                end
            elseif other_char:has_trait(disloyalty_trait) then
                if not loyal_side then
                    authority = dev.mround(authority + (other_char:gravitas() * bonus), 1)
                else
                    risk = dev.mround(risk + (other_char:gravitas() * bonus), 1)
                end
            end
        end
    end

end

--v function(self: CHARACTER_POLITICS, region: CA_REGION)
function character_politics.do_governor_trait(self, region)
    local province_key = region:province_name()
    local character = region:governor()
    if character == "nil" or character:is_null_interface() then
        self:log(tostring(self.cqi) .. " is returning nil! They're probably dead")
        return
    end
    local trait_key = province_key:gsub("vik_prov_", admin_level_trait)
    local changed_trait = false --:boolean
    if self.last_governorship ~= trait_key and character:has_trait(self.last_governorship) then
        self:log("Removing old Governor trait "..self.last_title)
        cm:force_remove_trait(dev.lookup(character), self.last_title)
        changed_trait = true
    end
    if self.last_governorship ~= trait_key and not character:has_trait(trait_key) then
        self:log("adding new Governor trait "..trait_key)
        dev.add_trait(character, trait_key, changed_trait)
    end
    self.last_governorship = trait_key
end

--v function(self: CHARACTER_POLITICS, character: CA_CHAR)
function character_politics.update_loyalty_traits(self, character)
    self:log("Checking friendship loyalty trait")
    local king = character:faction():faction_leader()
    if not king or king:is_null_interface() then
        self:log("ERROR: could not get a handle on the king!")
        return
    end
    local friendship = 2 --:int
    --update cross loyalty
    for trait_key, relation_pairs in pairs(character_cross_trait_loyalties) do
        if character:has_trait(trait_key) then
            --we have a trait which has cross loyalty effects.
            for other_trait, change_value in pairs(relation_pairs) do
                --if the king has the trait that is cross loyalty, apply the change
                if king:has_trait(other_trait) then
                    self:log("Cross loyalty found between trait: "..trait_key.." and trait: "..other_trait)
                    friendship = friendship + change_value
                end
            end
        end
    end
    local friendship = dev.mround(dev.clamp(friendship, 0, 4), 1)
    self:log("Friendship is: "..friendship)
    local old_bundle = friendship_level_trait..tostring(self.friendship_level)
    local new_bundle = friendship_level_trait..tostring(friendship)
    local changed_trait = false --:boolean
    if old_bundle ~= new_bundle and character:has_trait(old_bundle) then  
        self:log("Removing old friendship trait "..old_bundle)
        cm:force_remove_trait(dev.lookup(character), old_bundle)
        changed_trait = true
    end
    if old_bundle ~= new_bundle and not character:has_trait(new_bundle) then
        self:log("adding new friendship trait "..new_bundle)
        dev.add_trait(character, new_bundle, changed_trait)
    end
    self.friendship_level = friendship
    self:log("Not faction leader: checking loyalty")
    if character:loyalty() > 4 then
        local old_bundle = disloyalty_trait
        local new_bundle = loyalty_trait
        local changed_trait = false --:boolean
        if old_bundle ~= new_bundle and character:has_trait(old_bundle) then
            self:log("Removing old loyalty trait "..old_bundle)
            cm:force_remove_trait(dev.lookup(character), old_bundle)
            changed_trait = true
        end
        if old_bundle ~= new_bundle and not character:has_trait(new_bundle) then
            self:log("adding new loyalty trait "..new_bundle)
            dev.add_trait(character, new_bundle, changed_trait)
        end
    else
        local old_bundle = loyalty_trait
        local new_bundle = disloyalty_trait
        if old_bundle ~= new_bundle and character:has_trait(old_bundle) then
            self:log("Removing old loyalty trait "..old_bundle)
            cm:force_remove_trait(dev.lookup(character), old_bundle)
            changed_trait = true
        end
        if old_bundle ~= new_bundle  and not character:has_trait(new_bundle)then
            self:log("adding new loyalty trait "..new_bundle)
            dev.add_trait(character, new_bundle, changed_trait)
        end
    end
end

--v function(self: CHARACTER_POLITICS, character: CA_CHAR)
function character_politics.update_king_traits(self, character)
    self:log("Checking faction leader trait")
    if character:has_trait(loyalty_trait) or character:has_trait(disloyalty_trait) then
        --if they have either of these, they haven't been king very long.
        --we need to remove any traits that kings can't get.
        dev.remove_trait(character, loyalty_trait)
        dev.remove_trait(character, disloyalty_trait)
        dev.remove_trait(character, friendship_level_trait..tostring(self.friendship_level))
    end
    local trait_key = basic_king_title
    local changed_trait = false --:boolean
    if PettyKingdoms.VassalTracking.is_faction_vassal(character:faction():name()) then
        trait_key = basic_vassal_title
    end
    if factions_with_trait_overrides[character:faction():name()] then
        trait_key = "shield_leader_titles_"..character:faction():name().."_"..self.king_level
    end
    if self.last_title ~= trait_key and character:has_trait(self.last_title) then
        self:log("Removing old King trait "..self.last_title)
        cm:force_remove_trait(dev.lookup(character), self.last_title)
        changed_trait = true
    end
    if self.last_title ~= trait_key and not character:has_trait(trait_key) then
        self:log("adding new King trait "..trait_key)
        dev.add_trait(character, trait_key, changed_trait)
    end
    self.last_title = trait_key
end

--v function(self: CHARACTER_POLITICS, character: CA_CHAR)
function character_politics.update_general_trait(self, character)
    if character:has_military_force() and character:military_force():is_army() and (not character:military_force():is_armed_citizenry()) then
        self:log("Checking general trait")
        if character:military_force():unit_list():num_items() > 15 then
            local old_bundle = general_level_trait..tostring(self.general_level-1)
            local new_bundle = general_level_trait.."1"
            local changed_trait = false --:boolean
            if character:has_trait(old_bundle) then
                self:log("Removing old general trait "..old_bundle)
                cm:force_remove_trait(dev.lookup(character), old_bundle)
                changed_trait = true
            end
            if old_bundle ~= new_bundle and not character:has_trait(new_bundle) then
                self:log("adding new general trait "..new_bundle)
                dev.add_trait(character, new_bundle, changed_trait)
            end
            self.general_level = 2
        else
            local old_bundle = general_level_trait..tostring(self.general_level-1)
            local new_bundle = general_level_trait.."0"
            local changed_trait = false --:boolean
            if old_bundle ~= new_bundle and character:has_trait(old_bundle) then
                self:log("Removing old general trait "..old_bundle)
                cm:force_remove_trait(dev.lookup(character), old_bundle)
                changed_trait = true
            end
            if old_bundle ~= new_bundle and not character:has_trait(new_bundle) then
                self:log("adding new general trait "..new_bundle)
                dev.add_trait(character, new_bundle, changed_trait)
            end
            self.general_level = 1
        end
    elseif self.general_level > 0 then
        self:log("Not a general")
        dev.remove_trait(character, general_level_trait..tostring(self.general_level-1))
        self.general_level = 0
    end
end
--v function(self: CHARACTER_POLITICS)
function character_politics.turn_start(self)
    local character = dev.get_character(self.cqi)
    self:log("processing turn start")
    if character == "nil" or character:is_null_interface() then
        self:log(tostring(self.cqi) .. " is returning nil! They're probably dead")
        return
    end
    self:refresh_plot_vulnerability()
    self:log("Checking faction leader status")
    if character:is_faction_leader() then
        self:update_king_traits(character)
    else 
        self:update_loyalty_traits(character)
    end
    self:update_general_trait(character)
        
end

local instances = {} --:map<CA_CQI, CHARACTER_POLITICS>

dev.first_tick(function(context)
    local humans = cm:get_human_factions()
    for i = 1, #humans do
        local characters = dev.get_faction(humans[i]):character_list()
        for j = 0, characters:num_items() - 1 do
            local current = characters:item_at(j)
            if current:character_type("general")  and is_number(current:command_queue_index()) then
                instances[current:command_queue_index()] = character_politics.new(current:command_queue_index())
                instances[current:command_queue_index()]:log("Created pols char")
            end
            if dev.is_new_game() and instances[current:command_queue_index()] then
                instances[current:command_queue_index()]:turn_start()
            end
        end
        local regions = dev.get_faction(humans[i]):region_list()
        for j = 0, regions:num_items() - 1 do
            local current = regions:item_at(j)
            if current:has_governor() and instances[current:governor():command_queue_index()] then
                instances[current:governor():command_queue_index()]:do_governor_trait(current)
            end
        end
    end

    dev.eh:add_listener(
        "CharacterPoliticsTurnStart",
        "CharacterTurnStart",
        function(context)
            return context:character():faction():is_human()
        end,
        function(context)
            local char = context:character() --:CA_CHAR
            if not instances[char:command_queue_index()] then
                instances[char:command_queue_index()] = character_politics.new(char:command_queue_index())
            end
            instances[char:command_queue_index()]:turn_start()
        end,
        true)
    dev.eh:add_listener(
        "CharacterPoliticsTurnStart",
        "RegionTurnStart",
        function(context)
            return context:region():owning_faction():is_human() and context:region():has_governor()
        end,
        function(context)
            local char = context:region():governor() --:CA_CHAR
            if not instances[char:command_queue_index()] then
                instances[char:command_queue_index()] = character_politics.new(char:command_queue_index())
            end
            instances[char:command_queue_index()]:do_governor_trait(context:region())
        end,
        true)
    dev.eh:add_listener(
        "CharacterPoliticsFactionFormsKingdom",
        "FactionFormsKingdom",
        function(context)
            return context:faction():is_human()
        end,
        function(context)
            local char = context:faction():faction_leader() --:CA_CHAR
            if not instances[char:command_queue_index()] then
                instances[char:command_queue_index()] = character_politics.new(char:command_queue_index())
            end
            instances[char:command_queue_index()].king_level = instances[char:command_queue_index()].king_level + 1
        end,
        true)
        dev.eh:add_listener(
            "CharacterGainsTraitPolitics",
            "CharacterGainsTrait",
            function(context)
                return context:character():faction():is_human()
            end,
            function(context)
                local char = context:character() --:CA_CHAR
                if not instances[char:command_queue_index()] then
                    instances[char:command_queue_index()] = character_politics.new(char:command_queue_index())
                end
                instances[char:command_queue_index()].traits[#instances[char:command_queue_index()].traits+1] = context.string
                instances[char:command_queue_index()]:log("Gained trait: "..context.string)
            end,
            true)

end)
--v function(trait_key: string, to_trait: string, effect_bonus_value: int)
local function add_trait_cross_loyalty_to_trait(trait_key, to_trait, effect_bonus_value)
    character_cross_trait_loyalties[trait_key] = character_cross_trait_loyalties[trait_key] or {}
    character_cross_trait_loyalties[trait_key][to_trait] = effect_bonus_value
end


return {
    add_trait_cross_loyalty_to_trait = add_trait_cross_loyalty_to_trait
}