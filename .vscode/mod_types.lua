--# type global SAVE_SPEC = {save: (function(any) --> string), load: (function(string) --> any)}
--# type global SAVE_SCHEMA = {name: string, for_save: vector<string>, 
--# specifiers:map<string, SAVE_SPEC>?
--#}


--# assume global class FACTION_RESOURCE
--# type global RESOURCE_KIND = "population" | "capacity_fill" | "resource_bar" | "faction_focus"

--# assume global class DECREE

--# assume global class RIOT_MANAGER