--implementation of the hoards mechanic for mierce 

MIERCE_HOARDS = PettyKingdoms.FactionResource.new("vik_fact_mierce", "sw_hoards", "capacity_fill", 1, 3, {})
dev.first_tick(function(context)
    MIERCE_HOARDS:reapply()
end)