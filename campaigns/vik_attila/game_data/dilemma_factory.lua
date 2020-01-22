--creates files for use in dilemmas tables.

local files = {}
local uid = {}
local uid_start = 90100

local choice_strings = {
    [1] = "FIRST",
    [2] = "SECOND",
    [3] = "THIRD",
    [4] = "FOURTH"
}--:map<int, string>

--v function()
local function get_files()
    files.dilemmas_tables = io.open("dilemmas_tables.tsv", "a")
    files.cdir_events_dilemma_option_junctions_tables = io.open("cdir_events_dilemma_option_junctions_tables.tsv", "a")
    uid.cdir_events_dilemma_option_junctions_tables_uid = uid_start
    uid.cdir_events_dilemma_option_junctions_tables = function()
        uid.cdir_events_dilemma_option_junctions_tables_uid = uid.cdir_events_dilemma_option_junctions_tables_uid + 1
        return uid.cdir_events_dilemma_option_junctions_tables_uid - 1 
    end
    files.cdir_events_dilemma_choice_details_tables = io.open("cdir_events_dilemma_choice_details_tables", "a")
    files.cdir_events_dilemma_payloads_tables = io.open("cdir_events_dilemma_payloads_tables", "a")
    uid.cdir_events_dilemma_payloads_tables_uid = uid_start
    uid.cdir_events_dilemma_payloads_tables = function()
        uid.cdir_events_dilemma_payloads_tables_uid = uid.cdir_events_dilemma_payloads_tables_uid + 1
        return uid.cdir_events_dilemma_payloads_tables_uid - 1 
    end

end

--v function(name: string, region_list: CA_REGION_LIST, filter: (function(region: CA_REGION) --> boolean), num_choices: int,  payloads: map<int, vector<string>>, ui_image: string)
local function create_region_dilemma(name, region_list, filter, num_choices, payloads, ui_image)
    for h = 0, region_list:num_items() - 1 do
        local current_region = region_list:item_at(h)
        if filter(current_region) then
            local dilemma_key = name..current_region:name()
            files.dilemmas_tables:write(dilemma_key.."\tFALSE\tPH\tPH\tmessage_generic_news.png\t"..ui_image.."\tTRUE\tYbor\n")
            files.cdir_events_dilemma_option_junctions_tables:write(uid.cdir_events_dilemma_option_junctions_tables().."\t"..dilemma_key.."\tVAR_CHANCE\t100\n")
            files.cdir_events_dilemma_option_junctions_tables:write(uid.cdir_events_dilemma_option_junctions_tables().."\t"..dilemma_key.."\tGEN_CND_REGION\t"..current_region:name().."\n")
            files.cdir_events_dilemma_option_junctions_tables:write(uid.cdir_events_dilemma_option_junctions_tables().."\t"..dilemma_key.."\tGEN_TARGET_REGION\t\n")
            files.cdir_events_dilemma_option_junctions_tables:write(uid.cdir_events_dilemma_option_junctions_tables().."\t"..dilemma_key.."\tGEN_CND_OWNS\t\n")

            for i = 1, num_choices do
                files.cdir_events_dilemma_choice_details_tables:write(choice_strings[i].."\t"..dilemma_key.."\n")
                for j = 1, #payloads[i] do
                    local payload_string = payloads[i][j]
                    files.cdir_events_dilemma_payloads_tables:write(uid.cdir_events_dilemma_payloads_tables().."\t"..choice_strings[i].."\t"..dilemma_key.."\t"..payload_string.."\n")
                end
            end

        end
    end
end