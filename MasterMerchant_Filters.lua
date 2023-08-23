local internal = _G["LibGuildStore_Internal"]

-- IsItemLinkBookKnown, IsItemLinkRecipeKnown
-- /script d(IsItemLinkBookKnown("|H1:item:57576:5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"))
-- /script d(IsItemLinkRecipeKnown("|H1:item:57576:5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"))

MasterMerchant.filterTypes = {}

MM_ITEM_TYPE_NONE = -1

MM_ITEM_TYPE_ALL = 0
MM_ITEM_TYPE_WEAPON = 1
MM_ITEM_TYPE_ARMOR = 2
MM_ITEM_TYPE_JEWELRY = 3
MM_ITEM_TYPE_CONSUMABLE = 4
MM_ITEM_TYPE_CRAFTING = 5
MM_ITEM_TYPE_FURNISHING = 6
MM_ITEM_TYPE_COMPANION = 7
MM_ITEM_TYPE_MISCELLANEOUS = 8
MM_RECIPE_MOTIF_UNKNOWN = 9
MM_RECIPE_MOTIF_KNOWN = 10

MM_ITEM_SUBTYPE_WEAPON_ALL = 0
MM_ITEM_SUBTYPE_WEAPON_ONE_HANDED = 1
MM_ITEM_SUBTYPE_WEAPON_TWO_HANDED = 2
MM_ITEM_SUBTYPE_WEAPON_BOW = 3
MM_ITEM_SUBTYPE_WEAPON_DESTRO_STAFF = 4
MM_ITEM_SUBTYPE_WEAPON_RESTO_STAFF = 5

MM_ITEM_SUBTYPE_ARMOR_ALL = 0
MM_ITEM_SUBTYPE_ARMOR_LIGHT = 1
MM_ITEM_SUBTYPE_ARMOR_MEDIUM = 2
MM_ITEM_SUBTYPE_ARMOR_HEAVY = 3
MM_ITEM_SUBTYPE_ARMOR_SHIELD = 4

MM_ITEM_SUBTYPE_JEWELRY_ALL = 0
MM_ITEM_SUBTYPE_JEWELRY_NECK = 1
MM_ITEM_SUBTYPE_JEWELRY_RING = 2

MM_ITEM_SUBTYPE_CONSUMABLE_ALL = 0
MM_ITEM_SUBTYPE_CONSUMABLE_FOOD = 1
MM_ITEM_SUBTYPE_CONSUMABLE_DRINK = 2
MM_ITEM_SUBTYPE_CONSUMABLE_RECIPE = 3
MM_ITEM_SUBTYPE_CONSUMABLE_POTION = 4
MM_ITEM_SUBTYPE_CONSUMABLE_POISON = 5
MM_ITEM_SUBTYPE_CONSUMABLE_STYLE_MOTIF = 6
MM_ITEM_SUBTYPE_CONSUMABLE_MASTER_WRIT = 7
MM_ITEM_SUBTYPE_CONSUMABLE_CONTAINER = 8
-- 100 to not interfere with vanilla values for ITEMTYPE_xxxxxx
MM_ITEM_SUBTYPE_CONSUMABLE_COLLECTIBLE = 100
MM_ITEM_SUBTYPE_CONSUMABLE_REPAIR_ITEM = 10
MM_ITEM_SUBTYPE_CONSUMABLE_MISCELLANEOUS = 11

MM_ITEM_SUBTYPE_CRAFTING_ALL = 0
MM_ITEM_SUBTYPE_CRAFTING_BLACKSMITHING = 1
MM_ITEM_SUBTYPE_CRAFTING_CLOTHING = 2
MM_ITEM_SUBTYPE_CRAFTING_WOODWORKING = 3
MM_ITEM_SUBTYPE_CRAFTING_JEWELRYCRAFTING = 4
MM_ITEM_SUBTYPE_CRAFTING_ALCHEMY = 5
MM_ITEM_SUBTYPE_CRAFTING_ENCHANTING = 6
MM_ITEM_SUBTYPE_CRAFTING_PROVISIONING = 7
MM_ITEM_SUBTYPE_CRAFTING_STYLE_MATERIAL = 8
MM_ITEM_SUBTYPE_CRAFTING_TRAIT_ITEM = 9
MM_ITEM_SUBTYPE_CRAFTING_FURNISHING_MATERIAL = 10

MM_ITEM_SUBTYPE_COMPANION_ALL = 0
MM_ITEM_SUBTYPE_COMPANION_WEAPONS = 1
MM_ITEM_SUBTYPE_COMPANION_ARMOR = 2
MM_ITEM_SUBTYPE_COMPANION_JEWELRY = 3

MM_ITEM_SUBTYPE_MISCELLANEOUS_ALL = 0
MM_ITEM_SUBTYPE_MISCELLANEOUS_APPEARANCE = 1
MM_ITEM_SUBTYPE_MISCELLANEOUS_GLYPH = 2
MM_ITEM_SUBTYPE_MISCELLANEOUS_SOUL_GEM = 3
MM_ITEM_SUBTYPE_MISCELLANEOUS_SIEGE = 4
MM_ITEM_SUBTYPE_MISCELLANEOUS_TOOL = 5
MM_ITEM_SUBTYPE_MISCELLANEOUS_TROPHY = 6
MM_ITEM_SUBTYPE_MISCELLANEOUS_LURE = 7
MM_ITEM_SUBTYPE_MISCELLANEOUS_TRASH = 8
MM_ITEM_SUBTYPE_MISCELLANEOUS_MISCELLANEOUS = 9

MasterMerchant.filterTypes = {
  [MM_ITEM_TYPE_ALL] = {
    up = "EsoUI/Art/Inventory/inventory_tabIcon_all_up.dds",
    down = "EsoUI/Art/Inventory/inventory_tabIcon_all_down.dds",
    filterActive = true,
  },
  [MM_ITEM_TYPE_WEAPON] = {
    up = "EsoUI/Art/Inventory/inventory_tabIcon_weapons_up.dds",
    down = "EsoUI/Art/Inventory/inventory_tabIcon_weapons_down.dds",
    filterActive = false,
    button = MasterMerchantFilterByTypeWindowMenuHeaderWeaponsButton,
    [MM_ITEM_SUBTYPE_WEAPON_ONE_HANDED] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_1handed_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_1handed_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_WEAPON_TWO_HANDED] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_2handed_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_2handed_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_WEAPON_BOW] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_bow_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_bow_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_WEAPON_DESTRO_STAFF] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_damageStaff_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_damageStaff_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_WEAPON_RESTO_STAFF] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_healStaff_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_healStaff_down.dds",
      filterActive = false,
    },
  },
  [MM_ITEM_TYPE_ARMOR] = {
    up = "EsoUI/Art/Inventory/inventory_tabIcon_armor_up.dds",
    down = "EsoUI/Art/Inventory/inventory_tabIcon_armor_down.dds",
    filterActive = false,
    button = MasterMerchantFilterByTypeWindowMenuHeaderArmorButton,
    [MM_ITEM_SUBTYPE_ARMOR_LIGHT] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_armorLight_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_armorLight_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_ARMOR_MEDIUM] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_armorMedium_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_armorMedium_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_ARMOR_HEAVY] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_armorHeavy_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_armorHeavy_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_ARMOR_SHIELD] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_shield_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_shield_down.dds",
      filterActive = false,
    },
  },
  [MM_ITEM_TYPE_JEWELRY] = {
    up = "EsoUI/Art/Crafting/jewelry_tabIcon_icon_up.dds",
    down = "EsoUI/Art/Crafting/jewelry_tabIcon_down.dds",
    filterActive = false,
    button = MasterMerchantFilterByTypeWindowMenuHeaderJewelryButton,
    [MM_ITEM_SUBTYPE_JEWELRY_NECK] = {
      up = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Accessories_Necklace_Up.dds",
      down = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Accessories_Necklace_Down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_JEWELRY_RING] = {
      up = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Accessories_Ring_Up.dds",
      down = "EsoUI/Art/TradingHouse/Tradinghouse_Apparel_Accessories_Ring_Down.dds",
      filterActive = false,
    },
  },
  [MM_ITEM_TYPE_CONSUMABLE] = {
    up = "EsoUI/Art/Inventory/inventory_tabIcon_consumables_up.dds",
    down = "EsoUI/Art/Inventory/inventory_tabIcon_consumables_down.dds",
    filterActive = false,
    button = MasterMerchantFilterByTypeWindowMenuHeaderConsumableButton,
    [MM_ITEM_SUBTYPE_CONSUMABLE_FOOD] = {
      up = "EsoUI/Art/Crafting/provisioner_indexIcon_meat_up.dds",
      down = "EsoUI/Art/Crafting/provisioner_indexIcon_meat_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_CONSUMABLE_DRINK] = {
      up = "EsoUI/Art/Crafting/provisioner_indexIcon_beer_up.dds",
      down = "EsoUI/Art/Crafting/provisioner_indexIcon_beer_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_CONSUMABLE_RECIPE] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_recipe_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_recipe_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_CONSUMABLE_POTION] = {
      up = "EsoUI/Art/TradingHouse/Tradinghouse_Potions_Potionsolvent_Up.dds",
      down = "EsoUI/Art/TradingHouse/Tradinghouse_Potions_Potionsolvent_Down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_CONSUMABLE_POISON] = {
      up = "EsoUI/Art/TradingHouse/Tradinghouse_Potions_Poisonsolvent_Up.dds",
      down = "EsoUI/Art/TradingHouse/Tradinghouse_Potions_Poisonsolvent_Down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_CONSUMABLE_STYLE_MOTIF] = {
      up = "EsoUI/Art/TradingHouse/Tradinghouse_Racial_Style_Motif_Book_Up.dds",
      down = "EsoUI/Art/TradingHouse/Tradinghouse_Racial_Style_Motif_Book_Down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_CONSUMABLE_MASTER_WRIT] = {
      up = "EsoUI/Art/TradingHouse/Tradinghouse_Master_Writ_Up.dds",
      down = "EsoUI/Art/TradingHouse/Tradinghouse_Master_Writ_Down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_CONSUMABLE_CONTAINER] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_container_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_container_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_CONSUMABLE_REPAIR_ITEM] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_repair_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_repair_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_CONSUMABLE_MISCELLANEOUS] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_misc_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_misc_down.dds",
      filterActive = false,
    },
  },
  [MM_ITEM_TYPE_CRAFTING] = {
    up = "EsoUI/Art/Inventory/inventory_tabIcon_crafting_up.dds",
    down = "EsoUI/Art/Inventory/inventory_tabIcon_crafting_down.dds",
    filterActive = false,
    button = MasterMerchantFilterByTypeWindowMenuHeaderCraftingButton,
    [MM_ITEM_SUBTYPE_CRAFTING_BLACKSMITHING] = {
      up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Blacksmithing_Mats_Up.dds",
      down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Blacksmithing_Mats_Down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_CRAFTING_CLOTHING] = {
      up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Tailoring_Mats_Up.dds",
      down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Tailoring_Mats_Down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_CRAFTING_WOODWORKING] = {
      up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Woodworking_Mats_Up.dds",
      down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Woodworking_Mats_Down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_CRAFTING_JEWELRYCRAFTING] = {
      up = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Jewelrymaking_Mats_Up.dds",
      down = "EsoUI/Art/TradingHouse/Tradinghouse_Materials_Jewelrymaking_Mats_Down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_CRAFTING_ALCHEMY] = {
      up = "EsoUI/Art/Crafting/alchemy_tabIcon_reagent_up.dds",
      down = "EsoUI/Art/Crafting/alchemy_tabIcon_reagent_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_CRAFTING_ENCHANTING] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_enchanting_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_enchanting_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_CRAFTING_PROVISIONING] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_provisioning_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_provisioning_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_CRAFTING_STYLE_MATERIAL] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_styleMaterial_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_styleMaterial_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_CRAFTING_TRAIT_ITEM] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_itemTrait_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_Craftbag_itemTrait_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_CRAFTING_FURNISHING_MATERIAL] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_furnishing_material_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_furnishing_material_Down.dds",
      filterActive = false,
    },
  },
  [MM_ITEM_TYPE_FURNISHING] = {
    up = "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_up.dds",
    down = "EsoUI/Art/Crafting/provisioner_indexIcon_furnishings_down.dds",
    filterActive = false,
    button = MasterMerchantFilterByTypeWindowMenuHeaderFurnishingButton,
  },
  [MM_ITEM_TYPE_COMPANION] = {
    up = "EsoUI/Art/Inventory/inventory_tabIcon_companion_up.dds",
    down = "EsoUI/Art/Inventory/inventory_tabIcon_companion_down.dds",
    filterActive = false,
    button = MasterMerchantFilterByTypeWindowMenuHeaderCompanionButton,
    [MM_ITEM_SUBTYPE_COMPANION_WEAPONS] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_weapons_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_weapons_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_COMPANION_ARMOR] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_armor_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_armor_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_COMPANION_JEWELRY] = {
      up = "EsoUI/Art/Crafting/jewelry_tabIcon_icon_up.dds",
      down = "EsoUI/Art/Crafting/jewelry_tabIcon_down.dds",
      filterActive = false,
    },
  },
  [MM_ITEM_TYPE_MISCELLANEOUS] = {
    up = "EsoUI/Art/Inventory/inventory_tabIcon_misc_up.dds",
    down = "EsoUI/Art/Inventory/inventory_tabIcon_misc_down.dds",
    filterActive = false,
    button = MasterMerchantFilterByTypeWindowMenuHeaderMiscButton,
    [MM_ITEM_SUBTYPE_MISCELLANEOUS_APPEARANCE] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_appearance_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_appearance_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_MISCELLANEOUS_GLYPH] = {
      up = "EsoUI/Art/TradingHouse/Tradinghouse_Glyphs_Trio_Up.dds",
      down = "EsoUI/Art/TradingHouse/Tradinghouse_Glyphs_Trio_Down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_MISCELLANEOUS_SOUL_GEM] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_soulgem_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_soulgem_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_MISCELLANEOUS_SIEGE] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_siege_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_siege_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_MISCELLANEOUS_TOOL] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_tool_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_tool_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_MISCELLANEOUS_TROPHY] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_trophy_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_trophy_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_MISCELLANEOUS_LURE] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_bait_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_bait_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_MISCELLANEOUS_TRASH] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_trash_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_trash_down.dds",
      filterActive = false,
    },
    [MM_ITEM_SUBTYPE_MISCELLANEOUS_MISCELLANEOUS] = {
      up = "EsoUI/Art/Inventory/inventory_tabIcon_misc_up.dds",
      down = "EsoUI/Art/Inventory/inventory_tabIcon_misc_down.dds",
      filterActive = false,
    },
  },
  [MM_RECIPE_MOTIF_UNKNOWN] = {
    up = "EsoUI/Art/Campaign/overview_indexIcon_bonus_up.dds",
    down = "EsoUI/Art/Campaign/overview_indexIcon_bonus_down.dds",
    filterActive = false,
    button = MasterMerchantFilterByTypeWindowMenuHeaderUnknownButton,
  },
  [MM_RECIPE_MOTIF_KNOWN] = {
    up = "EsoUI/Art/Journal/journal_tabIcon_loreLibrary_up.dds",
    down = "EsoUI/Art/Journal/journal_tabIcon_loreLibrary_down.dds",
    filterActive = false,
    button = MasterMerchantFilterByTypeWindowMenuHeaderKnownButton,
  },
}

function MasterMerchant:ResetFilters()
  -- MasterMerchant:dm("Debug", "ResetFilters")
  for key, value in pairs(MasterMerchant.filterTypes) do
    if value.filterActive then value.filterActive = false end
    if value.button then
      MasterMerchant:ResetFilterState(value.button, key)
    end
  end
  MasterMerchant.filterTypes[MM_ITEM_TYPE_ALL].filterActive = true
  MasterMerchant:RefreshAlteredWindowData(true)
end

function MasterMerchant:UpdateFilterState(control, filterType)
  -- MasterMerchant:dm("Debug", "UpdateFilterState")
  local buttonControl
  local function filtersCleared()
    for _, value in pairs(MasterMerchant.filterTypes) do
      if value.filterActive then return false end
    end
    return true
  end

  if not MasterMerchant.filterTypes[filterType].filterActive then MasterMerchant.filterTypes[filterType].filterActive = false end
  local recipeToggleFilter = filterType == MM_RECIPE_MOTIF_KNOWN or filterType == MM_RECIPE_MOTIF_UNKNOWN
  if recipeToggleFilter then
    if filterType == MM_RECIPE_MOTIF_KNOWN then
      MasterMerchant.filterTypes[MM_RECIPE_MOTIF_KNOWN].filterActive = not MasterMerchant.filterTypes[MM_RECIPE_MOTIF_KNOWN].filterActive
    end
    if filterType == MM_RECIPE_MOTIF_UNKNOWN then
      MasterMerchant.filterTypes[MM_RECIPE_MOTIF_UNKNOWN].filterActive = not MasterMerchant.filterTypes[MM_RECIPE_MOTIF_UNKNOWN].filterActive
    end
    if filterType == MM_RECIPE_MOTIF_KNOWN and MasterMerchant.filterTypes[MM_RECIPE_MOTIF_UNKNOWN].filterActive then
      MasterMerchant.filterTypes[MM_RECIPE_MOTIF_UNKNOWN].filterActive = false
      buttonControl = MasterMerchant.filterTypes[MM_RECIPE_MOTIF_UNKNOWN].button
      buttonControl:SetNormalTexture(MasterMerchant.filterTypes[MM_RECIPE_MOTIF_UNKNOWN].up)
    end
    if filterType == MM_RECIPE_MOTIF_UNKNOWN and MasterMerchant.filterTypes[MM_RECIPE_MOTIF_KNOWN].filterActive then
      MasterMerchant.filterTypes[MM_RECIPE_MOTIF_KNOWN].filterActive = false
      buttonControl = MasterMerchant.filterTypes[MM_RECIPE_MOTIF_KNOWN].button
      buttonControl:SetNormalTexture(MasterMerchant.filterTypes[MM_RECIPE_MOTIF_KNOWN].up)
    end
  else
    MasterMerchant.filterTypes[filterType].filterActive = not MasterMerchant.filterTypes[filterType].filterActive
  end

  local texture = ""
  if MasterMerchant.filterTypes[filterType].filterActive then
    texture = MasterMerchant.filterTypes[filterType].down
  else
    texture = MasterMerchant.filterTypes[filterType].up
  end
  control:SetNormalTexture(texture)

  if filterType ~= MM_RECIPE_MOTIF_KNOWN and filterType ~= MM_RECIPE_MOTIF_UNKNOWN then
    MasterMerchant.filterTypes[MM_ITEM_TYPE_ALL].filterActive = false
  end
  if filtersCleared() then MasterMerchant.filterTypes[MM_ITEM_TYPE_ALL].filterActive = true end
  MasterMerchant:RefreshAlteredWindowData(true)
end

function MasterMerchant:ResetFilterState(control, filterType)
  if not MasterMerchant.filterTypes[filterType] then return end
  local texture = ""
  if MasterMerchant.filterTypes[filterType].filterActive then
    texture = MasterMerchant.filterTypes[filterType].down
  else
    texture = MasterMerchant.filterTypes[filterType].up
  end
  control:SetNormalTexture(texture)
end

local MM_ITEM_FILTER_ITEM_SUBTYPES = {
  [MM_ITEM_TYPE_WEAPON] = {
    [WEAPONTYPE_AXE] = MM_ITEM_SUBTYPE_WEAPON_ONE_HANDED,
    [WEAPONTYPE_HAMMER] = MM_ITEM_SUBTYPE_WEAPON_ONE_HANDED,
    [WEAPONTYPE_SWORD] = MM_ITEM_SUBTYPE_WEAPON_ONE_HANDED,
    [WEAPONTYPE_DAGGER] = MM_ITEM_SUBTYPE_WEAPON_ONE_HANDED,
    [WEAPONTYPE_TWO_HANDED_AXE] = MM_ITEM_SUBTYPE_WEAPON_TWO_HANDED,
    [WEAPONTYPE_TWO_HANDED_HAMMER] = MM_ITEM_SUBTYPE_WEAPON_TWO_HANDED,
    [WEAPONTYPE_TWO_HANDED_SWORD] = MM_ITEM_SUBTYPE_WEAPON_TWO_HANDED,
    [WEAPONTYPE_BOW] = MM_ITEM_SUBTYPE_WEAPON_BOW,
    [WEAPONTYPE_FIRE_STAFF] = MM_ITEM_SUBTYPE_WEAPON_DESTRO_STAFF,
    [WEAPONTYPE_FROST_STAFF] = MM_ITEM_SUBTYPE_WEAPON_DESTRO_STAFF,
    [WEAPONTYPE_LIGHTNING_STAFF] = MM_ITEM_SUBTYPE_WEAPON_DESTRO_STAFF,
    [WEAPONTYPE_HEALING_STAFF] = MM_ITEM_SUBTYPE_WEAPON_RESTO_STAFF,
  },
  [MM_ITEM_TYPE_ARMOR] = {
    [ARMORTYPE_HEAVY] = MM_ITEM_SUBTYPE_ARMOR_HEAVY,
    [ARMORTYPE_LIGHT] = MM_ITEM_SUBTYPE_ARMOR_LIGHT,
    [ARMORTYPE_MEDIUM] = MM_ITEM_SUBTYPE_ARMOR_MEDIUM,
    [WEAPONTYPE_SHIELD] = MM_ITEM_SUBTYPE_ARMOR_SHIELD,
  },
  [MM_ITEM_TYPE_JEWELRY] = {
    [EQUIP_TYPE_RING] = MM_ITEM_SUBTYPE_JEWELRY_RING,
    [EQUIP_TYPE_NECK] = MM_ITEM_SUBTYPE_JEWELRY_NECK,
  },
  [MM_ITEM_TYPE_COMPANION] = {
    [ITEMTYPE_WEAPON] = MM_ITEM_SUBTYPE_COMPANION_WEAPONS,
    [ITEMTYPE_ARMOR] = MM_ITEM_SUBTYPE_COMPANION_ARMOR,
    [MM_ITEM_TYPE_JEWELRY] = MM_ITEM_SUBTYPE_COMPANION_JEWELRY,
  },
  [MM_ITEM_TYPE_CONSUMABLE] = {
    [ITEMTYPE_FOOD] = MM_ITEM_SUBTYPE_CONSUMABLE_FOOD,
    [ITEMTYPE_DRINK] = MM_ITEM_SUBTYPE_CONSUMABLE_DRINK,
    [ITEMTYPE_RECIPE] = MM_ITEM_SUBTYPE_CONSUMABLE_RECIPE,
    [ITEMTYPE_POTION] = MM_ITEM_SUBTYPE_CONSUMABLE_POTION,
    [ITEMTYPE_POISON] = MM_ITEM_SUBTYPE_CONSUMABLE_POISON,
    [ITEMTYPE_RACIAL_STYLE_MOTIF] = MM_ITEM_SUBTYPE_CONSUMABLE_STYLE_MOTIF,
    [ITEMTYPE_MASTER_WRIT] = MM_ITEM_SUBTYPE_CONSUMABLE_MASTER_WRIT,
    -- CONTAINER
    [ITEMTYPE_CONTAINER] = MM_ITEM_SUBTYPE_CONSUMABLE_CONTAINER,
    [ITEMTYPE_CONTAINER_CURRENCY] = MM_ITEM_SUBTYPE_CONSUMABLE_CONTAINER,
    -- REPAIR_ITEM
    [ITEMTYPE_TOOL] = MM_ITEM_SUBTYPE_CONSUMABLE_REPAIR_ITEM,
    [ITEMTYPE_AVA_REPAIR] = MM_ITEM_SUBTYPE_CONSUMABLE_REPAIR_ITEM,
    [ITEMTYPE_CROWN_REPAIR] = MM_ITEM_SUBTYPE_CONSUMABLE_REPAIR_ITEM,
    [ITEMTYPE_GROUP_REPAIR] = MM_ITEM_SUBTYPE_CONSUMABLE_REPAIR_ITEM,
    --MISC
    [ITEMTYPE_FISH] = MM_ITEM_SUBTYPE_CONSUMABLE_MISCELLANEOUS,
    [ITEMTYPE_RECALL_STONE] = MM_ITEM_SUBTYPE_CONSUMABLE_MISCELLANEOUS,
    [ITEMTYPE_DYE_STAMP] = MM_ITEM_SUBTYPE_CONSUMABLE_MISCELLANEOUS,
    [MM_ITEM_SUBTYPE_CONSUMABLE_COLLECTIBLE] = MM_ITEM_SUBTYPE_CONSUMABLE_MISCELLANEOUS,
  },
  [MM_ITEM_TYPE_CRAFTING] = {
    -- ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING
    [ITEMTYPE_BLACKSMITHING_RAW_MATERIAL] = MM_ITEM_SUBTYPE_CRAFTING_BLACKSMITHING,
    [ITEMTYPE_BLACKSMITHING_MATERIAL] = MM_ITEM_SUBTYPE_CRAFTING_BLACKSMITHING,
    [ITEMTYPE_BLACKSMITHING_BOOSTER] = MM_ITEM_SUBTYPE_CRAFTING_BLACKSMITHING,
    -- ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING
    [ITEMTYPE_CLOTHIER_RAW_MATERIAL] = MM_ITEM_SUBTYPE_CRAFTING_CLOTHING,
    [ITEMTYPE_CLOTHIER_MATERIAL] = MM_ITEM_SUBTYPE_CRAFTING_CLOTHING,
    [ITEMTYPE_CLOTHIER_BOOSTER] = MM_ITEM_SUBTYPE_CRAFTING_CLOTHING,
    -- ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING
    [ITEMTYPE_WOODWORKING_RAW_MATERIAL] = MM_ITEM_SUBTYPE_CRAFTING_WOODWORKING,
    [ITEMTYPE_WOODWORKING_MATERIAL] = MM_ITEM_SUBTYPE_CRAFTING_WOODWORKING,
    [ITEMTYPE_WOODWORKING_BOOSTER] = MM_ITEM_SUBTYPE_CRAFTING_WOODWORKING,
    -- ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING
    [ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL] = MM_ITEM_SUBTYPE_CRAFTING_JEWELRYCRAFTING,
    [ITEMTYPE_JEWELRYCRAFTING_MATERIAL] = MM_ITEM_SUBTYPE_CRAFTING_JEWELRYCRAFTING,
    [ITEMTYPE_JEWELRYCRAFTING_RAW_BOOSTER] = MM_ITEM_SUBTYPE_CRAFTING_JEWELRYCRAFTING,
    [ITEMTYPE_JEWELRYCRAFTING_BOOSTER] = MM_ITEM_SUBTYPE_CRAFTING_JEWELRYCRAFTING,
    -- ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY
    [ITEMTYPE_REAGENT] = MM_ITEM_SUBTYPE_CRAFTING_ALCHEMY,
    [ITEMTYPE_POTION_BASE] = MM_ITEM_SUBTYPE_CRAFTING_ALCHEMY,
    [ITEMTYPE_POISON_BASE] = MM_ITEM_SUBTYPE_CRAFTING_ALCHEMY,
    -- ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING
    [ITEMTYPE_ENCHANTING_RUNE_ASPECT] = MM_ITEM_SUBTYPE_CRAFTING_ENCHANTING,
    [ITEMTYPE_ENCHANTING_RUNE_POTENCY] = MM_ITEM_SUBTYPE_CRAFTING_ENCHANTING,
    [ITEMTYPE_ENCHANTING_RUNE_ESSENCE] = MM_ITEM_SUBTYPE_CRAFTING_ENCHANTING,
    -- ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING
    [ITEMTYPE_INGREDIENT] = MM_ITEM_SUBTYPE_CRAFTING_PROVISIONING,
    [ITEMTYPE_SPICE] = MM_ITEM_SUBTYPE_CRAFTING_PROVISIONING,
    [ITEMTYPE_FLAVORING] = MM_ITEM_SUBTYPE_CRAFTING_PROVISIONING,
    -- ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL
    [ITEMTYPE_STYLE_MATERIAL] = MM_ITEM_SUBTYPE_CRAFTING_STYLE_MATERIAL,
    [ITEMTYPE_RAW_MATERIAL] = MM_ITEM_SUBTYPE_CRAFTING_STYLE_MATERIAL,
    -- ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM
    [ITEMTYPE_ARMOR_TRAIT] = MM_ITEM_SUBTYPE_CRAFTING_TRAIT_ITEM,
    [ITEMTYPE_WEAPON_TRAIT] = MM_ITEM_SUBTYPE_CRAFTING_TRAIT_ITEM,
    [ITEMTYPE_JEWELRY_RAW_TRAIT] = MM_ITEM_SUBTYPE_CRAFTING_TRAIT_ITEM,
    [ITEMTYPE_JEWELRY_TRAIT] = MM_ITEM_SUBTYPE_CRAFTING_TRAIT_ITEM,
    -- ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING_MATERIAL
    [ITEMTYPE_FURNISHING_MATERIAL] = MM_ITEM_SUBTYPE_CRAFTING_FURNISHING_MATERIAL,
  },
  -- MM_ITEM_TYPE_FURNISHING there is no subtype
  [MM_ITEM_TYPE_MISCELLANEOUS] = {
    [ITEMTYPE_COSTUME] = MM_ITEM_SUBTYPE_MISCELLANEOUS_APPEARANCE,
    [ITEMTYPE_DISGUISE] = MM_ITEM_SUBTYPE_MISCELLANEOUS_APPEARANCE,
    [ITEMTYPE_TABARD] = MM_ITEM_SUBTYPE_MISCELLANEOUS_APPEARANCE,
    [ITEMTYPE_GLYPH_WEAPON] = MM_ITEM_SUBTYPE_MISCELLANEOUS_GLYPH,
    [ITEMTYPE_GLYPH_ARMOR] = MM_ITEM_SUBTYPE_MISCELLANEOUS_GLYPH,
    [ITEMTYPE_GLYPH_JEWELRY] = MM_ITEM_SUBTYPE_MISCELLANEOUS_GLYPH,
    [ITEMTYPE_SOUL_GEM] = MM_ITEM_SUBTYPE_MISCELLANEOUS_SOUL_GEM,
    [ITEMTYPE_SIEGE] = MM_ITEM_SUBTYPE_MISCELLANEOUS_SIEGE,
    -- [ITEMTYPE_LOCKPICK] = MM_ITEM_SUBTYPE_MISCELLANEOUS_TOOL,
    [ITEMTYPE_TROPHY] = MM_ITEM_SUBTYPE_MISCELLANEOUS_TROPHY,
    [ITEMTYPE_COLLECTIBLE] = MM_ITEM_SUBTYPE_MISCELLANEOUS_TROPHY,
    [ITEMTYPE_TREASURE] = MM_ITEM_SUBTYPE_MISCELLANEOUS_TROPHY,
    [ITEMTYPE_LURE] = MM_ITEM_SUBTYPE_MISCELLANEOUS_LURE,
    [ITEMTYPE_TRASH] = MM_ITEM_SUBTYPE_MISCELLANEOUS_TRASH,
  },
}

function MasterMerchant:IsItemLinkTypeConsumable(itemType)
  local consumables = {
    -- FOOD
    [ITEMTYPE_FOOD] = true,
    -- DRINK
    [ITEMTYPE_DRINK] = true,
    -- RECIPE
    [ITEMTYPE_RECIPE] = true,
    -- POTION
    [ITEMTYPE_POTION] = true,
    -- POISON
    [ITEMTYPE_POISON] = true,
    -- STYLE_MOTIF
    [ITEMTYPE_RACIAL_STYLE_MOTIF] = true,
    -- MASTER_WRIT
    [ITEMTYPE_MASTER_WRIT] = true,
    -- CONTAINER
    [ITEMTYPE_CONTAINER] = true,
    [ITEMTYPE_CONTAINER_CURRENCY] = true,
    -- REPAIR_ITEM
    [ITEMTYPE_TOOL] = true,
    [ITEMTYPE_AVA_REPAIR] = true,
    [ITEMTYPE_CROWN_REPAIR] = true,
    [ITEMTYPE_GROUP_REPAIR] = true,
    --MISC
    [ITEMTYPE_FISH] = true,
    [ITEMTYPE_RECALL_STONE] = true,
    [ITEMTYPE_DYE_STAMP] = true,
  }
  if consumables[itemType] then
    return true
  end
  return false
end

function MasterMerchant:IsItemLinkTypeCrafting(itemType)
  local craftingMats = {
    -- ITEM_TYPE_DISPLAY_CATEGORY_BLACKSMITHING
    [ITEMTYPE_BLACKSMITHING_RAW_MATERIAL] = true,
    [ITEMTYPE_BLACKSMITHING_MATERIAL] = true,
    [ITEMTYPE_BLACKSMITHING_BOOSTER] = true,
    -- ITEM_TYPE_DISPLAY_CATEGORY_CLOTHING
    [ITEMTYPE_CLOTHIER_RAW_MATERIAL] = true,
    [ITEMTYPE_CLOTHIER_MATERIAL] = true,
    [ITEMTYPE_CLOTHIER_BOOSTER] = true,
    -- ITEM_TYPE_DISPLAY_CATEGORY_WOODWORKING
    [ITEMTYPE_WOODWORKING_RAW_MATERIAL] = true,
    [ITEMTYPE_WOODWORKING_MATERIAL] = true,
    [ITEMTYPE_WOODWORKING_BOOSTER] = true,
    -- ITEM_TYPE_DISPLAY_CATEGORY_JEWELRYCRAFTING
    [ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL] = true,
    [ITEMTYPE_JEWELRYCRAFTING_MATERIAL] = true,
    [ITEMTYPE_JEWELRYCRAFTING_RAW_BOOSTER] = true,
    [ITEMTYPE_JEWELRYCRAFTING_BOOSTER] = true,
    -- ITEM_TYPE_DISPLAY_CATEGORY_ALCHEMY
    [ITEMTYPE_REAGENT] = true,
    [ITEMTYPE_POTION_BASE] = true,
    [ITEMTYPE_POISON_BASE] = true,
    -- ITEM_TYPE_DISPLAY_CATEGORY_ENCHANTING
    [ITEMTYPE_ENCHANTING_RUNE_ASPECT] = true,
    [ITEMTYPE_ENCHANTING_RUNE_POTENCY] = true,
    [ITEMTYPE_ENCHANTING_RUNE_ESSENCE] = true,
    -- ITEM_TYPE_DISPLAY_CATEGORY_PROVISIONING
    [ITEMTYPE_INGREDIENT] = true,
    [ITEMTYPE_SPICE] = true,
    [ITEMTYPE_FLAVORING] = true,
    -- ITEM_TYPE_DISPLAY_CATEGORY_STYLE_MATERIAL
    [ITEMTYPE_STYLE_MATERIAL] = true,
    [ITEMTYPE_RAW_MATERIAL] = true,
    -- ITEM_TYPE_DISPLAY_CATEGORY_TRAIT_ITEM
    [ITEMTYPE_ARMOR_TRAIT] = true,
    [ITEMTYPE_WEAPON_TRAIT] = true,
    [ITEMTYPE_JEWELRY_RAW_TRAIT] = true,
    [ITEMTYPE_JEWELRY_TRAIT] = true,
    -- ITEM_TYPE_DISPLAY_CATEGORY_FURNISHING_MATERIAL
    [ITEMTYPE_FURNISHING_MATERIAL] = true,
  }
  if craftingMats[itemType] then
    return true
  end
  return false
end

function MasterMerchant:IsItemLinkTypeMiscellaneous(itemType)
  local miscellaneousTypes = {
    -- APPEARANCE
    [ITEMTYPE_COSTUME] = true,
    [ITEMTYPE_DISGUISE] = true,
    [ITEMTYPE_TABARD] = true,
    -- GLYPH
    [ITEMTYPE_GLYPH_WEAPON] = true,
    [ITEMTYPE_GLYPH_ARMOR] = true,
    [ITEMTYPE_GLYPH_JEWELRY] = true,
    -- SOUL_GEM
    [ITEMTYPE_SOUL_GEM] = true,
    -- SIEGE
    [ITEMTYPE_SIEGE] = true,
    -- TROPHY
    [ITEMTYPE_TROPHY] = true,
    [ITEMTYPE_COLLECTIBLE] = true,
    [ITEMTYPE_TREASURE] = true,
    -- LURE
    [ITEMTYPE_LURE] = true,
    -- TRASH
    [ITEMTYPE_TRASH] = true,
  }
  if miscellaneousTypes[itemType] then
    return true
  end
  return false
end

function MasterMerchant:IsItemLinkLearnedCollectible(specializedItemType)
  if not specializedItemType then return false end
  local specializedItemtypesOfContainers = {
    [SPECIALIZED_ITEMTYPE_CONTAINER_STYLE_PAGE] = true,
    [SPECIALIZED_ITEMTYPE_COLLECTIBLE_STYLE_PAGE] = true,
    [SPECIALIZED_ITEMTYPE_CONTAINER] = true,
  }
  if specializedItemtypesOfContainers[specializedItemType] then
    return true
  end
  return false
end

function MasterMerchant:GetItemLinkItemType(itemLink)
  local filterType = MM_ITEM_TYPE_NONE
  local subFilterType = MM_ITEM_TYPE_NONE
  local weaponType = MM_ITEM_TYPE_NONE
  local armorType = MM_ITEM_TYPE_NONE
  local equipType = MM_ITEM_TYPE_NONE
  local subfilterOut = nil
  local itemType, specializedItemType = GetItemLinkItemType(itemLink)
  local isCompanionItem = false
  if itemType == ITEMTYPE_WEAPON or itemType == ITEMTYPE_ARMOR then
    isCompanionItem = GetItemLinkActorCategory(itemLink) == GAMEPLAY_ACTOR_CATEGORY_COMPANION
  end
  if itemType == ITEMTYPE_WEAPON then
    weaponType = GetItemLinkWeaponType(itemLink)
    filterType = MM_ITEM_TYPE_WEAPON
    subFilterType = weaponType
    if weaponType == WEAPONTYPE_SHIELD and not isCompanionItem then
      filterType = MM_ITEM_TYPE_ARMOR
    end
  end
  if itemType == ITEMTYPE_ARMOR then
    equipType = GetItemLinkEquipType(itemLink)
    armorType = GetItemLinkArmorType(itemLink)
    filterType = MM_ITEM_TYPE_ARMOR
    -- set to armor type for lookup table
    subFilterType = armorType
    -- set to Jewelry if ring or neck
    if equipType == EQUIP_TYPE_NECK or equipType == EQUIP_TYPE_RING then
      filterType = MM_ITEM_TYPE_JEWELRY
      subFilterType = equipType
    end
  end
  if isCompanionItem then
    filterType = MM_ITEM_TYPE_COMPANION
    subFilterType = itemType
    if weaponType ~= MM_ITEM_TYPE_NONE and weaponType == WEAPONTYPE_SHIELD then
      subFilterType = ITEMTYPE_ARMOR
    end
    if equipType ~= MM_ITEM_TYPE_NONE and (equipType == EQUIP_TYPE_NECK or equipType == EQUIP_TYPE_RING) then
      subFilterType = MM_ITEM_TYPE_JEWELRY
    end
  end
  --MasterMerchant:dm("Info", itemType)
  --MasterMerchant:dm("Info", specializedItemType)
  if MasterMerchant:IsItemLinkTypeConsumable(itemType) then
    filterType = MM_ITEM_TYPE_CONSUMABLE
    if MasterMerchant:IsCollectibleValidForPlayer(itemLink) then
      subFilterType = MM_ITEM_SUBTYPE_CONSUMABLE_COLLECTIBLE
    else
      subFilterType = itemType
    end
  end
  if MasterMerchant:IsItemLinkTypeCrafting(itemType) then
    filterType = MM_ITEM_TYPE_CRAFTING
    subFilterType = itemType
  end
  if itemType == ITEMTYPE_FURNISHING then
    filterType = MM_ITEM_TYPE_FURNISHING
  end
  if MasterMerchant:IsItemLinkTypeMiscellaneous(itemType) then
    filterType = MM_ITEM_TYPE_MISCELLANEOUS
    subFilterType = itemType
  end

  --[[ murky crystal,
  ]]--
  if itemType == ITEMTYPE_NONE and specializedItemType == SPECIALIZED_ITEMTYPE_NONE then
    filterType = MM_ITEM_TYPE_MISCELLANEOUS
    subFilterType = MM_ITEM_SUBTYPE_MISCELLANEOUS_MISCELLANEOUS
  end

  --[[ values are set to MM_ITEM_TYPE_NONE as a way to avoid compare against
  nil errors, so set nil here
  ]]--
  if filterType == MM_ITEM_TYPE_NONE then filterType = MM_ITEM_TYPE_MISCELLANEOUS end
  if subFilterType == MM_ITEM_TYPE_NONE then subFilterType = nil end
  -- if both are still set then get the subfilter unless it is a Companion Item
  if filterType and subFilterType then
    subfilterOut = MM_ITEM_FILTER_ITEM_SUBTYPES[filterType][subFilterType]
  end

  return filterType, subfilterOut
end

function MasterMerchant:IsCollectibleValidForPlayer(itemLink)
  local containerCollectibleId = GetItemLinkContainerCollectibleId(itemLink)
  local isValidForPlayer = IsCollectibleValidForPlayer(containerCollectibleId)
  if isValidForPlayer then
    return true
  end
  return false
end

function MasterMerchant:IsItemLinkKnownUnknown(itemLink)
  local known = false
  local itemType, specializedItemType = GetItemLinkItemType(itemLink)
  if itemType == ITEMTYPE_RECIPE then
    known = IsItemLinkRecipeKnown(itemLink)
  end
  if itemType == ITEMTYPE_RACIAL_STYLE_MOTIF then
    known = IsItemLinkBookKnown(itemLink)
  end
  if MasterMerchant:IsItemLinkLearnedCollectible(specializedItemType) then
    if MasterMerchant:IsCollectibleValidForPlayer(itemLink) then
      local containerCollectibleId = GetItemLinkContainerCollectibleId(itemLink)
      known = IsCollectibleUnlocked(containerCollectibleId)
    end
  end
  return known
  --[[
    special case when the itemType is something you can learn like
    a Recipe or Motif, or a Collectible you can aquire

    returns the vanilla ItemType and True or False if known for subfilterOut
    if itemType == ITEMTYPE_RECIPE then
      filterType = itemType
      subfilterOut = IsItemLinkRecipeKnown(itemLink)
    end
    if itemType == ITEMTYPE_RACIAL_STYLE_MOTIF then
      filterType = itemType
      subfilterOut = IsItemLinkBookKnown(itemLink)
    end
    -- ITEMTYPE_COLLECTIBLE
    if MasterMerchant:IsItemLinkLearnedCollectible(specializedItemType) then
      local containerCollectibleId = GetItemLinkContainerCollectibleId(itemLink)
      local isValidForPlayer = IsCollectibleValidForPlayer(containerCollectibleId)
      if isValidForPlayer then
        filterType = itemType
        subfilterOut = IsCollectibleUnlocked(containerCollectibleId)
      else
        filterType = MM_ITEM_TYPE_MISCELLANEOUS
        subfilterOut = MM_ITEM_SUBTYPE_MISCELLANEOUS_TROPHY
      end
    end
  ]]--
end

function MasterMerchant:IsItemLinkLearnable(itemLink)
  local itemType, specializedItemType = GetItemLinkItemType(itemLink)
  local isLearnedCollectible = MasterMerchant:IsItemLinkLearnedCollectible(specializedItemType)
  if itemType == ITEMTYPE_RECIPE or itemType == ITEMTYPE_RACIAL_STYLE_MOTIF or isLearnedCollectible then
    return true
  end
  return false
end

function MasterMerchant:CollectibleUnlockState(itemLink)
  return IsItemSetCollectionPieceUnlocked(GetItemLinkItemId(itemLink))
end

function MasterMerchant:IsItemLinkCollectible(itemLink)
  return IsItemSetCollectionPieceUnlocked(GetItemLinkItemId(itemLink))
end

--[[
/script LibGuildStore_MasterMerchant:dm("Info", {MasterMerchant:GetItemLinkItemType("|H1:item:175565:124:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", true)})

/script LibGuildStore_MasterMerchant:dm("Info", MasterMerchant:IsItemLinkFiltered("|H1:item:171741:124:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", true))

/script LibGuildStore_MasterMerchant:dm("Info", MasterMerchant:IsItemLinkFiltered("|H0:item:10897:358:50:0:0:0:0:0:0:0:0:0:0:0:0:8:0:0:0:10000:0|h|h", true))

/script LibGuildStore_MasterMerchant:dm("Info", LibGuildStore_Internal:AddSearchToItem("|H0:item:97217:362:50:0:0:0:0:0:0:0:0:0:0:0:0:6:0:0:0:0:0|h|h"))

/script LibGuildStore_MasterMerchant:dm("Info", MasterMerchant:CollectibleUnlockState("|H1:item:45851:21:6:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", true))
]]--
function MasterMerchant:IsItemLinkFiltered(itemLink)
  local itemType, specializedItemType = MasterMerchant:GetItemLinkItemType(itemLink)
  local knownFilterActive = MasterMerchant.filterTypes[MM_RECIPE_MOTIF_KNOWN].filterActive
  local unknownFilterActive = MasterMerchant.filterTypes[MM_RECIPE_MOTIF_UNKNOWN].filterActive
  local isLearnable = MasterMerchant:IsItemLinkLearnable(itemLink)
  local isKnowToggleActive = knownFilterActive or unknownFilterActive
  local showAll = MasterMerchant.filterTypes[MM_ITEM_TYPE_ALL].filterActive
  local typeFilterActive = MasterMerchant.filterTypes[itemType].filterActive
  local isCollectibleItem = IsItemLinkSetCollectionPiece(itemLink)
  local collectible = isCollectibleItem and (itemType == MM_ITEM_TYPE_WEAPON or itemType == MM_ITEM_TYPE_ARMOR or itemType == MM_ITEM_TYPE_JEWELRY)
  local isKnown = nil
  local isCollected = nil
  if isLearnable then
    isKnown = MasterMerchant:IsItemLinkKnownUnknown(itemLink)
  end
  if collectible then
    isCollected = MasterMerchant:CollectibleUnlockState(itemLink)
  end

  -------------------------------------------------
  ----- Show All                                        -----
  -------------------------------------------------
  if isKnowToggleActive and isLearnable and showAll then
    if isKnown and not unknownFilterActive then
      return true
    end
    if isKnown and unknownFilterActive then
      return false
    end

    if not isKnown and not knownFilterActive then
      return true
    end
    if not isKnown and knownFilterActive then
      return false
    end
  end
  -------------------------------------------------
  ----- Active Filter                                   -----
  -------------------------------------------------
  if isKnowToggleActive and isLearnable and typeFilterActive then
    if isKnown and not unknownFilterActive then
      return true
    end
    if isKnown and unknownFilterActive then
      return false
    end
    if not isKnown and not knownFilterActive then
      return true
    end
    if not isKnown and knownFilterActive then
      return false
    end
  end
  -------------------------------------------------
  ----- Collectable                                   -----
  -------------------------------------------------
  if isKnowToggleActive and collectible and typeFilterActive then
    if isCollected and not unknownFilterActive then
      return true
    end
    if isCollected and unknownFilterActive then
      return false
    end
    if not isCollected and not knownFilterActive then
      return true
    end
    if not isCollected and knownFilterActive then
      return false
    end
  end

  -------------------------------------------------
  ----- Exiting                                            -----
  -------------------------------------------------
  if typeFilterActive then
    return true
  end
  if showAll then
    return true
  end
  return false
end