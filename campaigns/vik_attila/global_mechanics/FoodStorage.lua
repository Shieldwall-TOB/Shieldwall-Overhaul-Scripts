local building_storage_effects = {
    vik_granary_1 = 75,
    vik_granary_2 = 150,
    vik_souterrain_1 = 100,
    vik_souterrain_2 = 150,
    vik_souterrain_3 = 200,
    vik_warehouse_1 = 100,
    vik_warehouse_2 = 150,
    vik_warehouse_3 = 200,
    vik_fogou_1 = 100,
    vik_fogou_2 = 150,
    vik_fogou_3 = 200
}--: map<string, number>


local fs = PettyKingdoms.FoodStorage
for building, quantity in pairs(building_storage_effects) do
    fs.add_food_storage_effect_to_building(building, quantity)
end