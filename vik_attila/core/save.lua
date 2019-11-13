local log_tab = 0
--v function(t: any, loud: boolean?)
local function log(t, loud)
    if (not CONST.__should_output_save_load) and (not loud) then
        return
    end
    output_text = tostring(t) --:string
    if log_tab > 0 then
        for i = 1, log_tab do
            output_text = "\t"..output_text
        end
    end
    dev.log(output_text, "SAVEGAME")
end


--helper for tables
--v function(str: string, delim: string) --> vector<string>
local function SplitString(str, delim)
    local res = { };
    local pattern = string.format("([^%s]+)%s()", delim, delim);
    --# assume pos: WHATEVER
    while (true) do
        line, pos = str:match(pattern, pos);
        if line == nil then break end;
        table.insert(res, line);
    end
    return res;
end

local type_switch = {
    ["string"] = function(field)--:string
         return field end,
    ["number"] = function(field) --:number
        return tostring(field) end,
    ["table"] = function(field) --:map<any, any>
        local ret = ""
        for k, v in pairs(field) do
            ret = ret .. tostring(k) .. "," .. tostring(v) .. ";"
        end
        return ret
    end,
    ["boolean"] = function(field) --:boolean
        return tostring(field)
    end
} -- explicit type

--v function(save_string: string) --> map<string, WHATEVER>
local function parse_save_string(save_string)
    local retval = {} --:map<string, WHATEVER>
    local fields = SplitString(save_string, "|")
    for f = 1, #fields do
        local name_value_splitter = SplitString(fields[f], ":")
        local field_name = name_value_splitter[1]
        local field_string = name_value_splitter[2]
        if string.find(field_name, ";") then
            --it is a table
            retval[field_name] = {}
            local table_entries = SplitString(save_string, ";");
            for i = 1, #table_entries do
                local record = SplitString(table_entries[i], ",");
                retval[field_name][record[1]] = record[2];
            end
        else
            --it isn't.
            if field_string == "true" then
                retval[field_name] = true
            elseif field_string == "false" then
                retval[field_name] = false
            elseif not not tonumber(field_string) then
                retval[field_name] = tonumber(field_string)
            else
                retval[field_name] = field_string
            end
        end
    end
    return retval
end

--v [NO_CHECK] function(obj:any)
local function attach(obj)
    if not obj.save then
        --TODO log
        return
    end

    --save callback
    cm:register_saving_game_callback(function(context) 
        local ok, err = pcall(function()
            local save_string = "" --:string
            log("Saving object: "..obj.save.name)
            for i = 1, #obj.save.for_save do
                local field_name = obj.save.for_save[i]
                local field = (obj[field_name])
                log_tab = 1
                if field == nil or field == "" then
                    -- do nothing, this field does not currently exist.
                elseif obj.save.specifiers[field_name] then
                    --if we have a save specifier and this field exists, use it
                    save_string = save_string .. "|" .. field_name .. ":" .. obj.save.specifiers[field_name].save(field) .. ":"
                elseif type_switch[type(field)] then
                    save_string = save_string .. "|" .. field_name .. ":" .. type_switch[type(field)](field) .. ":"
                else
                    log("Asked to save a field of type ".. type(field).. "in object ".. obj.save.name .. " which is not a recognized savable type.", true)
                end
            end
            log_tab = 0
            cm:save_value(obj.save.name, save_string, context)
        end) 
        if not ok then
            log("Error savng object:")
            log(err, true) log(debug.traceback())
            log_tab = 0  
        end
    end)
    --load callback
    cm:register_loading_game_callback(function(context)
        local ok, err = pcall(function()
            local save_string = cm:load_value(obj.save.name, "", context)
            local loaded_table = parse_save_string(save_string, obj)
            for key, value in pairs(loaded_table) do
                obj[key] = loaded_table[key]
            end
        end) 
        if not ok then
            log("Error loading object:")
            log(err, true)
            log(debug.traceback())
            log_tab = 0 
        end
    end)
end

return {
    attach_to_object = attach
}