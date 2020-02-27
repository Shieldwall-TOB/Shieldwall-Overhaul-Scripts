--# type global SAVE_SPEC = {save: (function(any) --> string), load: (function(string) --> any)}
--# type global SAVE_SCHEMA = {name: string, for_save: vector<string>, 
--# specifiers:map<string, SAVE_SPEC>?
--#}

--# assume global class RECRUITMENT_HANDLER

--# assume global class FACTION_RESOURCE
--# type global RESOURCE_KIND = "population" | "capacity_fill" | "resource_bar" | "faction_focus"

--# assume global class FACTION_DECREE_HANDLER
--# assume global class DECREE
--# assume global class VASSAL_FACTION
--# assume global class FORCE_TRACKER

--# assume global class REGION_MANPOWER
--# assume global class RIOT_MANAGER
--# assume global class CHARACTER_POLITICS
--# assume global class FOOD_MANAGER
--# assume global class RIVAL