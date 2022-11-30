local function GetAveragePrice(itemLink, sellPrice)
  if not MasterMerchant.isInitialized then return sellPrice end
  local averagePrice
  if MasterMerchant.systemSavedVariables.replacementTypeToUse == MasterMerchant.USE_MM_AVERAGE then
    local tipStats = MasterMerchant:GetTooltipStats(itemLink, true, true)
    if tipStats.avgPrice then
      averagePrice = tipStats.avgPrice
    end
  end
  if MasterMerchant.systemSavedVariables.replacementTypeToUse == MasterMerchant.USE_BONANZA then
    local tipStats = MasterMerchant:GetTooltipStats(itemLink, false, true)
    if tipStats.bonanzaPrice then
      averagePrice = tipStats.bonanzaPrice
    end
  end
  if MasterMerchant.systemSavedVariables.replacementTypeToUse == MasterMerchant.USE_TTC_AVERAGE and TamrielTradeCentre then
    local priceStats = MasterMerchant:GetTamrielTradeCentrePrice(itemLink)
    if priceStats and priceStats.Avg > 0 then
      averagePrice = priceStats.Avg
    end
  end
  if MasterMerchant.systemSavedVariables.replacementTypeToUse == MasterMerchant.USE_TTC_SUGGESTED and TamrielTradeCentre then
    local priceStats = MasterMerchant:GetTamrielTradeCentrePrice(itemLink)
    if priceStats and priceStats.SuggestedPrice > 0 then
      averagePrice = priceStats.SuggestedPrice
      if MasterMerchant.systemSavedVariables.modifiedSuggestedPriceInventory then
        averagePrice = priceStats.SuggestedPrice * 1.25
      end
    end
  end
  return averagePrice
end

local function GetInventoryPriceText(averagePrice, stackSellPrice)
  local newSellPrice = MasterMerchant.LocalizedNumber(stackSellPrice)
  if MasterMerchant.systemSavedVariables.showUnitPrice then
    newSellPrice = '|cEEEE33' .. newSellPrice .. '|r' .. MasterMerchant.coinIcon .. "\n" .. '|c1E7CFF' .. MasterMerchant.LocalizedNumber(averagePrice) .. '|r' .. MasterMerchant.coinIcon
  else
    newSellPrice = '|cEEEE33' .. newSellPrice .. '|r' .. MasterMerchant.coinIcon
  end
  return newSellPrice
end

function MasterMerchant:SwitchUnitPrice(rowControl, slot)
  local suppressItemUpdate = false
  if not MasterMerchant.isInitialized then return end
  local sellPriceControl = rowControl:GetNamedChild("SellPrice")
  if not sellPriceControl then return end
  local slotData = slot
  if not MasterMerchant.systemSavedVariables.replaceInventoryValues and not slotData.hasAlteredPrice then return end

  local itemLink = GetItemLink(slotData.bagId, slotData.slotIndex)
  if not itemLink then return end

  if not MasterMerchant.systemSavedVariables.replaceInventoryValues and slotData.hasAlteredPrice then
    local _, sellPrice = GetItemLinkInfo(itemLink)
    slotData.hasAlteredPrice = nil
    slotData.sellPrice = sellPrice
    slotData.stackSellPrice = sellPrice * slotData.stackCount
    sellPriceControl:SetText(slotData.stackSellPrice)
    return
  end

  local averagePrice = GetAveragePrice(itemLink)
  local newSellPrice

  if MasterMerchant.systemSavedVariables.replaceInventoryValues and averagePrice then
    slotData.hasAlteredPrice = true
    slotData.sellPrice = averagePrice
    slotData.stackSellPrice = averagePrice * slotData.stackCount

    newSellPrice = GetInventoryPriceText(averagePrice, slotData.stackSellPrice)
    sellPriceControl:SetText(newSellPrice)
  end
  ZO_SharedInventoryManager:FireCallbacks("SlotUpdated", slotData.bagId, slotData.slotIndex, slotData, suppressItemUpdate)
end

function MasterMerchant:CreateOrUpdateSlotData(existingSlotData, bagId, slotIndex, isNewItem)
  MasterMerchant.a_test = "Something used me"
  local icon, stackCount, sellPrice, meetsUsageRequirement, locked, equipType, _, functionalQuality, displayQuality = GetItemInfo(bagId, slotIndex)
  local launderPrice = GetItemLaunderPrice(bagId, slotIndex)

  local hadItemInSlotBefore = false
  local wasSameItemInSlotBefore = false
  local hasItemInSlotNow = stackCount > 0
  local newUniqueId = hasItemInSlotNow and GetItemUniqueId(bagId, slotIndex) or nil

  local slot = existingSlotData

  if not slot then
    if hasItemInSlotNow then
      slot = {}
    end
  else
    hadItemInSlotBefore = slot.stackCount > 0
    wasSameItemInSlotBefore = hadItemInSlotBefore and hasItemInSlotNow and slot.uniqueId == newUniqueId
  end

  if not hasItemInSlotNow then
    if hadItemInSlotBefore then
      return nil, SHARED_INVENTORY_SLOT_RESULT_REMOVED
    end
    return nil, SHARED_INVENTORY_SLOT_RESULT_NO_CHANGE
  end

  local rawNameBefore = slot.rawName
  slot.rawName = GetItemName(bagId, slotIndex)
  if rawNameBefore ~= slot.rawName then
    slot.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, slot.rawName)
  end
  slot.requiredLevel = GetItemRequiredLevel(bagId, slotIndex)
  slot.requiredChampionPoints = GetItemRequiredChampionPoints(bagId, slotIndex)

  if not wasSameItemInSlotBefore then
    slot.itemType, slot.specializedItemType = GetItemType(bagId, slotIndex)
    slot.uniqueId = GetItemUniqueId(bagId, slotIndex)
  end

  if MasterMerchant.systemSavedVariables.replaceInventoryValues then
    local itemLink = GetItemLink(bagId, slotIndex)
    sellPrice = GetAveragePrice(itemLink, sellPrice)
  end
  slot.iconFile = icon
  slot.stackCount = stackCount
  slot.sellPrice = sellPrice
  slot.launderPrice = launderPrice
  slot.stackSellPrice = stackCount * sellPrice
  MasterMerchant.aa_test = slot.stackSellPrice
  slot.stackLaunderPrice = stackCount * launderPrice
  slot.bagId = bagId
  slot.slotIndex = slotIndex
  -- Items flagged equipped unique can only have one equipped, which means once they are
  -- equipped they are no longer equippable, but we don't want to color these items red
  -- in GamepadInventory once they are equipped, because that doesn't make any sense.
  slot.meetsUsageRequirement = meetsUsageRequirement or (bagId == BAG_WORN)
  slot.locked = locked
  slot.functionalQuality = functionalQuality
  slot.displayQuality = displayQuality
  -- slot.quality is deprecated, included here for addon backwards compatibility
  slot.quality = displayQuality
  slot.equipType = equipType
  slot.isPlayerLocked = IsItemPlayerLocked(bagId, slotIndex)
  slot.isBoPTradeable = IsItemBoPAndTradeable(bagId, slotIndex)
  slot.isJunk = IsItemJunk(bagId, slotIndex)
  slot.statValue = GetItemStatValue(bagId, slotIndex) or 0
  slot.itemInstanceId = GetItemInstanceId(bagId, slotIndex) or nil
  slot.brandNew = isNewItem
  slot.stolen = IsItemStolen(bagId, slotIndex)
  slot.filterData = { GetItemFilterTypeInfo(bagId, slotIndex) }
  slot.condition = GetItemCondition(bagId, slotIndex)
  slot.isPlaceableFurniture = IsItemPlaceableFurniture(bagId, slotIndex)
  slot.traitInformation = GetItemTraitInformation(bagId, slotIndex)
  slot.traitInformationSortOrder = ZO_GetItemTraitInformation_SortOrder(slot.traitInformation)
  slot.sellInformation = GetItemSellInformation(bagId, slotIndex)
  slot.sellInformationSortOrder = ZO_GetItemSellInformationCustomSortOrder(slot.sellInformation)
  slot.actorCategory = GetItemActorCategory(bagId, slotIndex)
  --Don't bother checking for guild bank or buyback because we don't care in those cases
  --In the case of the craft bag or companion worn bag, it isn't possible for a build item to live there, so we can just immediately infer false
  if bagId == BAG_GUILDBANK or bagId == BAG_BUYBACK or bagId == BAG_VIRTUAL or bagId == BAG_COMPANION_WORN then
    slot.isInArmory = false
  else
    slot.isInArmory = IsItemInArmory(bagId, slotIndex)
  end

  local isFromCrownCrate = IsItemFromCrownCrate(bagId, slotIndex)
  slot.isGemmable = false
  slot.requiredPerGemConversion = nil
  slot.gemsAwardedPerConversion = nil
  if isFromCrownCrate then
    local requiredPerGemConversion, gemsAwardedPerConversion = GetNumCrownGemsFromItemManualGemification(bagId, slotIndex)
    if requiredPerGemConversion > 0 and gemsAwardedPerConversion > 0 then
      slot.requiredPerGemConversion = requiredPerGemConversion
      slot.gemsAwardedPerConversion = gemsAwardedPerConversion
      slot.isGemmable = true
    end
  end

  slot.isFromCrownStore = IsItemFromCrownStore(bagId, slotIndex)

  if wasSameItemInSlotBefore and slot.age ~= 0 then
    -- don't modify the age, keep it the same relative sort - for now?
    -- Age is only set to 0 before this point from ClearNewStatus, so if brandNew is false
    -- but age isn't 0, something has tried to set brandNew to false without calling ClearNewStatus,
    -- so we can still rely on it actually being new.
    slot.brandNew = true
  elseif isNewItem then
    slot.age = GetFrameTimeSeconds()
  else
    slot.age = 0
  end

  ZO_SharedInventoryManager:RefreshStatusSortOrder(slot)

  MasterMerchant.aaa_test = slot
  if hadItemInSlotBefore then
    if isNewItem then
      return slot, SHARED_INVENTORY_SLOT_RESULT_REMOVE_AND_ADD
    else
      return slot, SHARED_INVENTORY_SLOT_RESULT_UPDATED
    end
  end

  return slot, SHARED_INVENTORY_SLOT_RESULT_ADDED
end