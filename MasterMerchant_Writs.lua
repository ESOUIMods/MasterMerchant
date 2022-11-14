local mmInternal = _G["MasterMerchant_Internal"]
local bitwise = _G["MasterMerchant_Writs_Bitwise"]

local MM_WRITFIELD_ONE = 10
local MM_WRITFIELD_TWO = 11
local MM_WRITFIELD_THREE = 12
local MM_WRITFIELD_FOUR = 13
local MM_WRITFIELD_FIVE = 14
local MM_WRITFIELD_SIX = 15

local MM_WRIT_ITEMTYPE_POTION = 199
local MM_WRIT_ITEMTYPE_POISON = 239

local MM_WRIT_ITEMTYPE_JEWELRY_NECK = 18
local MM_WRIT_ITEMTYPE_JEWELRY_RING = 24

-- |H1:item:71059:6:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h

-- /script d(MasterMerchant_Internal:GetItemLinkVoucherCount("|H1:item:156735:4:1:0:0:0:117956:0:0:0:0:0:0:0:0:0:0:0:0:0:10000|h|h"))
-- |H1:item:156735:4:1:0:0:0:117956:0:0:0:0:0:0:0:0:0:0:0:0:0:10000|h|h
-- |H1:item:156733:4:1:0:0:0:117926:0:0:0:0:0:0:0:0:0:0:0:0:0:10000|h|h
function mmInternal:GetItemLinkVoucherCount(itemLink)
  local data = tonumber(select(24, ZO_LinkHandler_ParseLink(itemLink)))
  local itemType, _ = GetItemLinkItemType(itemLink)
  if itemType == ITEMTYPE_MASTER_WRIT then
    local quotient, remainder = math.modf(data / 10000)
    local voucherCount = quotient + math.floor(0.5 + remainder)
    return voucherCount
  end
  return 0
end

-- /script d({MasterMerchant_Internal:GetWritFields("|H1:item:119696:5:1:0:0:0:199:2:11:21:0:0:0:0:0:0:0:0:0:0:50000|h|h")})
function mmInternal:GetWritFields(itemLink)
  local data = { ZO_LinkHandler_ParseLink(itemLink) }
  local field1 = tonumber(data[MM_WRITFIELD_ONE])
  local field2 = tonumber(data[MM_WRITFIELD_TWO])
  local field3 = tonumber(data[MM_WRITFIELD_THREE])
  local field4 = tonumber(data[MM_WRITFIELD_FOUR])
  local field5 = tonumber(data[MM_WRITFIELD_FIVE])
  local field6 = tonumber(data[MM_WRITFIELD_SIX])
  return field1, field2, field3, field4, field5, field6
end

-- /script d(MasterMerchant_Internal:IsItemLinkAlchemyItem("|H1:item:119696:5:1:0:0:0:199:2:11:21:0:0:0:0:0:0:0:0:0:0:50000|h|h"))
function mmInternal:IsItemLinkAlchemyItem(itemLink)
  local data = mmInternal:GetWritFields(itemLink)
  if (data == MM_WRIT_ITEMTYPE_POTION) or (data == MM_WRIT_ITEMTYPE_POISON) then
    return true
  end
  return false
end

-- /script d(MasterMerchant_Internal:IsItemLinkJewelryItem("|H1:item:153737:5:1:0:0:0:18:255:4:177:21:0:0:0:0:0:0:0:0:0:1837500|h|h"))
function mmInternal:IsItemLinkJewelryItem(itemLink)
  local data = mmInternal:GetWritFields(itemLink)
  if data == MM_WRIT_ITEMTYPE_JEWELRY_NECK or data == MM_WRIT_ITEMTYPE_JEWELRY_RING then
    return true
  end
  return false
end

-- /script d(MasterMerchant_Internal:IsItemLinkFurnitureItem("|H1:item:156735:4:1:0:0:0:117954:0:0:0:0:0:0:0:0:0:0:0:0:0:10000|h|h"))
function mmInternal:IsItemLinkFurnitureItem(itemLink)
  local itemType, _ = GetItemLinkItemType(itemLink)
  local itemId = mmInternal:GetItemLinkRequiredItemId(itemLink)
  if itemId and itemType == ITEMTYPE_MASTER_WRIT then
    local itemRequiredItemLink = string.format('|H1:item:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h', itemId)
    local requiredItemType, _ = GetItemLinkItemType(itemRequiredItemLink)
    if requiredItemType == ITEMTYPE_FURNISHING then
      return true
    end
  end
  return false
end

-- /script d(MasterMerchant_Internal:GetItemLinkRequiredItemId("|H1:item:156735:4:1:0:0:0:117954:0:0:0:0:0:0:0:0:0:0:0:0:0:10000|h|h"))
function mmInternal:GetItemLinkRequiredItemId(itemLink)
  local itemId = mmInternal:GetWritFields(itemLink)
  local itemType, _ = GetItemLinkItemType(itemLink)
  local alchemyItem = mmInternal:IsItemLinkAlchemyItem(itemLink)
  local jewelryItem = mmInternal:IsItemLinkJewelryItem(itemLink)
  -- real item link for, |H1:item:117942:2:1:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:0|h|h normal rough butcher knife
  if itemType == ITEMTYPE_MASTER_WRIT and not alchemyItem and not jewelryItem then
    return itemId
  end
  return nil
end

-- /script d(MasterMerchant_Internal:GetItemLinkFurnatureId("|H1:item:156735:4:1:0:0:0:117954:0:0:0:0:0:0:0:0:0:0:0:0:0:10000|h|h"))
function mmInternal:GetItemLinkFurnatureId(itemLink)
  if mmInternal:IsItemLinkFurnitureItem(itemLink) then
    local itemId = mmInternal:GetItemLinkRequiredItemId(itemLink)
    return string.format('|H1:item:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h', itemId)
  end
  return nil
end

function mmInternal:MaterialCostPrice(itemLink)
  local cost = 0
  local numIngredients = 0
  local winterWritsRequiredQty = nil
  local flavorText = GetItemLinkFlavorText(itemLink)
  local furnatureItemLink = mmInternal:GetItemLinkFurnatureId(itemLink)
  if not furnatureItemLink then
    return nil
  end

  numIngredients = MasterMerchant.GetItemLinkRecipeNumIngredients(furnatureItemLink)
  if ((numIngredients or 0) == 0) then
    -- Try to clean up item link by moving it to level 1
    furnatureItemLink = furnatureItemLink:gsub(":0", ":1", 1)
    numIngredients = MasterMerchant.GetItemLinkRecipeNumIngredients(furnatureItemLink)
  end

  if ((numIngredients or 0) > 0) then
    for i = 1, numIngredients do
      local ingredientItemLink, numRequired = MasterMerchant.GetItemLinkRecipeIngredientInfo(furnatureItemLink, i)
      if ingredientItemLink then
        cost = cost + (MasterMerchant.GetItemLinePrice(ingredientItemLink) * numRequired)
      end
    end

    local qtyRequired = mmInternal:GetWinterWritRequiredQty(furnatureItemLink)
    if qtyRequired and qtyRequired > 0 then
      return cost * qtyRequired
    else
      return cost
    end
  else
    return nil
  end
end

function mmInternal:MaterialCostPriceTip(itemLink, writCost)
  local cost = mmInternal:MaterialCostPrice(itemLink)
  local costTipString = ""
  local writCostTipString = ""
  local totalCostTipString = ""
  local materialTooltipString = ""
  local totalCost = 0
  if cost and not writCost then
    costTipString = MasterMerchant.LocalizedNumber(cost) .. MasterMerchant.coinIcon
    materialTooltipString = string.format(GetString(MM_MATCOST_PRICE_TIP), costTipString)
  elseif cost and writCost then
    totalCost = cost + writCost
    costTipString = MasterMerchant.LocalizedNumber(cost) .. MasterMerchant.coinIcon
    writCostTipString = MasterMerchant.LocalizedNumber(writCost) .. MasterMerchant.coinIcon
    totalCostTipString = MasterMerchant.LocalizedNumber(totalCost) .. MasterMerchant.coinIcon
    materialTooltipString = string.format(GetString(MM_MATCOST_PLUS_WRITCOST_TIP), costTipString, writCostTipString, totalCostTipString)
  end
  local qtyRequired = mmInternal:GetWinterWritRequiredQty(itemLink)
  if qtyRequired and qtyRequired == 0 then
    materialTooltipString = materialTooltipString .. "\n(qty not in database)"
  end
  if materialTooltipString ~= "" then
    return materialTooltipString
  else
    return nil
  end
end

-- /script d(MasterMerchant_Internal:GetWinterWritRequiredQty("|H1:item:118034:2:1:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:0|h|h"))
function mmInternal:GetWinterWritRequiredQty(itemLink)
  local itemId = GetItemLinkItemId(itemLink)
  if mmInternal.winterWritsRequiredQty[itemId] ~= nil and mmInternal.winterWritsRequiredQty[itemId] > 0 then
    return mmInternal.winterWritsRequiredQty[itemId]
  elseif mmInternal.winterWritsRequiredQty[itemId] ~= nil and mmInternal.winterWritsRequiredQty[itemId] < 0 then
    return 0
  end
  return nil
end

-- Deep Winter Charity Writs
mmInternal.winterWritsRequiredQty = {
  [117954] = 12, -- Rough Crate, Bolted
  [117926] = 12, -- Rough Stretcher, Military
  [117956] = 12, -- Rough Box, Boarded
  [117942] = 12, -- Rough Knife, Butcher
  [115153] = -1, -- Breton Bed, Bunk
  [118036] = -1, -- Common Candle, Set
  [118012] = -1, -- Common Washtub, Empty
  [118048] = 1, -- Common Table, Slanted
  [117991] = -1, -- Stool, Carved
  [118007] = -1, -- Common Basket, Tall
  [118034] = -1, -- Common Platter, Serving
  [120410] = 3, -- Rough Cup, Empty
  [117943] = 3, -- Rough Bowl, Common
  [117929] = 12, -- Rough Crate, Reinforced
  [117960] = 12, -- Rough Container, Cargo
  [117940] = 12, -- Rough Hatchet, Practical
}
-- provisioning writ, purple, |H1:item:119693:5:1:0:0:0:71059:0:0:0:0:0:0:0:0:0:0:0:0:0:400000|h|h
-- enchanting writ, yellow, |H1:item:121528:6:1:0:0:0:45869:225:5:0:0:0:0:0:0:0:0:0:0:0:66000|h|h
-- alchemy writ, purple, |H1:item:119696:5:1:0:0:0:199:2:11:21:0:0:0:0:0:0:0:0:0:0:50000|h|h
-- cloth writ, yellow, |H1:item:121533:6:1:0:0:0:37:190:5:224:15:82:0:0:0:0:0:0:0:0:787200|h|h
-- blacksmith writ, yellow,  |H1:item:121529:6:1:0:0:0:46:188:5:51:11:117:0:0:0:0:0:0:0:0:1037400|h|h
-- woodowrking writ, purple,  |H1:item:119681:5:1:0:0:0:71:192:4:539:26:62:0:0:0:0:0:0:0:0:576000|h|h
-- jewelry writ, purple, |H1:item:153737:5:1:0:0:0:18:255:4:177:21:0:0:0:0:0:0:0:0:0:1837500|h|h
-- winter writ, blue, |H1:item:156735:4:1:0:0:0:117954:0:0:0:0:0:0:0:0:0:0:0:0:0:10000|h|h
--[[
    ,   writ1            = tonumber(x[10])
    ,   writ2            = tonumber(x[11])
    ,   writ3            = tonumber(x[12])
    ,   writ4            = tonumber(x[13])
    ,   writ5            = tonumber(x[14])
    ,   writ6            = tonumber(x[15])
    -- provisioning
    recipe      = fields.writ1
-- enchanting
        local glyph_id    = fields.writ1
    local level_num   = fields.writ2
    local quality_num = fields.writ3
-- jewelry
-- alchemy
        local solvent_id  = fields.writ1
    -- blacksmith/clothier/woodworking
    local item_num      = fields.writ1
    local material_num  = fields.writ2
    local quality_num   = fields.writ3
    local set_num       = fields.writ4
    local trait_num     = fields.writ5
    local motif_num     = fields.writ6
]]--