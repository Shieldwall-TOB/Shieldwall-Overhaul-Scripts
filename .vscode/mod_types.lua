--# type global SAVE_SCHEMA = {name: string, for_save: vector<string>, 
--# specifiers:map<string, {save: (function(any) --> string), load: (function(string) --> any)}>?
--#}


--# assume global class FACTION_RESOURCE
--# type global RESOURCE_KIND = "population" | "capacity_fill" | "resource_bar" | "faction_focus"
