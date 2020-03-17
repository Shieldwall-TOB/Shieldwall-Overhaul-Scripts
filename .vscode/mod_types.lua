--# type global SAVE_SPEC = {save: (function(any) --> string), load: (function(string) --> any)}
--# type global SAVE_SCHEMA = {name: string, for_save: vector<string>, 
--# specifiers:map<string, SAVE_SPEC>?
--#}

--# assume global class RECRUITMENT_HANDLER
--# assume global class TRAITS
--# assume global class FACTION_RESOURCE
--# type global RESOURCE_KIND = "population" | "capacity_fill" | "resource_bar" | "faction_focus"
--# type global EVENT_RESPONSE = {context: WHATEVER, character: CA_CQI?, has_character: boolean, has_region: boolean, region: string?}


--# assume global class FACTION_DECREE_HANDLER
--# assume global class DECREE
--# assume global class VASSAL_FACTION
--# assume global class FORCE_TRACKER
--# assume global class EVENT_SCHEDULE

--# assume global class REGION_MANPOWER
--# assume global class RIOT_MANAGER
--# assume global class CHARACTER_POLITICS
--# assume global class FOOD_MANAGER
--# assume global class RIVAL
--# assume global class GEOPOLITICS

