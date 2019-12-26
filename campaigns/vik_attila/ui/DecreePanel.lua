local local_faction_decrees = {} --:map<number, string>
local local_faction_decree_dilemma = {} --:map<number, boolean>

--# type global DECREE_AFFORD_TYPES = "global_cooldown" | "cooldown" | "too_expensive" | "not_summer" | "unlocked" | "active"


--v function(text: any)
local function log(text)
    dev.log(tostring(text), "DecrUI")
end

dev.eh:add_listener(
    "PanelOpenedCampaignDecrees",
    "PanelOpenedCampaign",
    function(context) return context.string == "decrees_panel" end,
    function(context) 
        DECREES_PANEL = context.component;
        dev.eh:trigger_event("UpdateDecrees", dev.get_faction(cm:get_local_faction(true)))
    end,
    true
)
--v function() --> CA_UIC
local function get_decree_panel()
    if DECREES_PANEL then
        return dev.get_uic(DECREES_PANEL)
    else
        log("Warning: Could not provide decrees panel to script!")
        return nil
    end
end



--v function(index: number)
local function trigger_decree_mp_safe(index)
    if local_faction_decree_dilemma[index] then
        get_decree_panel():InterfaceFunction("TriggerDilemma", local_faction_decrees[index])
    else
        get_decree_panel():InterfaceFunction("TriggerIncident", local_faction_decrees[index])
    end
end




--v function(alert: boolean)
local function update_alert_icon(alert)
    dev.get_uic(cm:ui_root(), "decrees_alert_icon"):SetVisible(alert);
end

--v function(index: number, effective_cooldown: number, global_cooldown: boolean, effective_gold_cost: number, currency_cost: number, currency_type: string, duration: number, can_afford: boolean, is_locked: boolean)
local function update_decree_panel(index, effective_cooldown, global_cooldown, effective_gold_cost, currency_cost, currency_type, duration, can_afford, is_locked)
    local faction = cm:model():world():whose_turn_is_it():name();
    local decrees = get_decree_panel()
    local template_address = decrees:Find("vik_decree_"..string.sub(faction, 10).."_"..index)
    local TemplateUIC = UIComponent(template_address)
    local enactButton = UIComponent(TemplateUIC:Find("button_enact"))
    enactButton:SetState("inactive")
    local turnsCounter = UIComponent(enactButton:Find("turns_corner"))
    if effective_cooldown > 0 then
        turnsCounter:SetVisible(true);
        turnsCounter:SetStateText(tostring(effective_cooldown));
    else
        turnsCounter:SetVisible(false);
    end
    local currencyValue = UIComponent(TemplateUIC:Find("other_cost"))
    local currencyIcon = UIComponent(TemplateUIC:Find("currency_icon"))
    if currency_cost == 0 then
        currencyValue:SetVisible(false)
        currencyIcon:SetVisible(false)
    else
        currencyValue:SetVisible(true)
        currencyIcon:SetVisible(true)
        currencyValue:SetStateText(tostring(currency_cost))
        currencyIcon:SetState(currency_type)
    end
    local goldValue = UIComponent(TemplateUIC:Find("dy_value"))
    goldValue:SetStateText(tostring(effective_gold_cost))
    local decreeDuration = UIComponent(TemplateUIC:Find("duration"))
    if duration > 0 then
        decreeDuration:SetVisible(true)
        UIComponent(decreeDuration:Find("turns_corner")):SetStateText(tostring(duration))
    else
        decreeDuration:SetVisible(false)
    end
    local conditionUIC = UIComponent(TemplateUIC:Find("dy_condition"))
    if can_afford and (not is_locked) and effective_cooldown == 0 then
        enactButton:SetState("active")
        conditionUIC:SetState("unlocked")
        return
    end
    if is_locked then
        conditionUIC:SetState("active")
        --TODO counter unlock conditions
    elseif effective_cooldown > 0 then
        if global_cooldown then
            conditionUIC:SetState("global_cooldown")
        else
            conditionUIC:SetState("cooldown")
        end
    elseif can_afford == false then
        conditionUIC:SetState("too_expensive")
    end
    --TODO summer only decrees?
end


--Kailua doesn't like handing the result of string.match to "tonumber" 
--v [NO_CHECK] function(index: number, event: string, is_dilemma: boolean)
local function add_decree_to_ui(index, event, is_dilemma)
    local_faction_decrees[index] = event
    if is_dilemma then
        local_faction_decree_dilemma[index] = true
    end
    dev.eh:add_listener(
        "ComponentLClickUpDecree"..index,
        "ComponentLClickUp", 
		function(context) return context.string == "button_enact" and tonumber( string.match(UIComponent(UIComponent(context.component):Parent()):Id(), "%d+") ) == index end,
		function(context) 
			local index = tonumber(string.match(UIComponent(UIComponent(context.component):Parent()):Id(), "%d+"))
			trigger_decree_mp_safe(index)
		end, 
		true
	);
end

return {
    add_decree = add_decree_to_ui,
    update_panel = update_decree_panel,
    set_alert = update_alert_icon
}