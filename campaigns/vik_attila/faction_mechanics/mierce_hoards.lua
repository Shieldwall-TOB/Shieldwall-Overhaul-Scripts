--implementation of the hoards mechanic for mierce 

local save_string_place = "sw_mierce_last_capital"
local save_string_bundle = "sw_mierce_last_bundle"
local faction_key = "vik_fact_mierce"
dev.first_tick(function(context)
    if dev.get_faction(faction_key):is_human() then
        MIERCE_HOARDS = PettyKingdoms.FactionResource.new(faction_key, "sw_hoards", "capacity_fill", 1, 3, {})
        MIERCE_HOARDS:reapply()
        if dev.is_new_game() then
            local faction_capital = dev.get_faction(faction_key):home_region()
            if not faction_capital:is_null_interface() then
                local bundle = MIERCE_HOARDS.last_bundle
                if bundle then
                    cm:apply_effect_bundle_to_region(bundle, faction_capital:name(), 0)
                    cm:set_saved_value(save_string_bundle, bundle)
                    cm:set_saved_value(save_string_place, faction_capital:name())
                end
            end
        end
        dev.eh:add_listener(
            "HoardsValueChange",
            "FactionResourceValueChanged",
            function(context)
                return context.string == "sw_hoards"
            end,
            function(context)
                local old_bundle = cm:get_saved_value(save_string_bundle)
                local old_capital = cm:get_saved_value(save_string_place)
                if dev.get_region(old_capital):owning_faction():name() == context:faction():name() then
                    cm:remove_effect_bundle_from_region(old_bundle, old_capital)
                end
                local faction_capital = context:faction():home_region()
                local bundle = MIERCE_HOARDS.last_bundle
                if bundle then
                    cm:apply_effect_bundle_to_region(bundle, faction_capital:name(), 0)
                    cm:set_saved_value(save_string_bundle, bundle)
                    cm:set_saved_value(save_string_place, faction_capital:name())
                end
            end,
            true)
    end
end)