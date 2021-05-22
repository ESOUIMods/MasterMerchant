local lib            = _G["LibGuildStore"]
local internal       = _G["LibGuildStore_Internal"]

local ASYNC          = LibAsync
local LGH            = LibHistoire

----------------------------------------
----- Helpers                      -----
----------------------------------------

-- DEBUG
function internal:CompareItemIds(dataset)
  internal:dm("Debug", "CompareItemIds")
  local saveData = dataset[internal.dataNamespace]
  local itemIds  = {}
  for itemID, itemData in pairs(saveData) do
    for itemIndex, itemIndexData in pairs(itemData) do
      for key, sale in pairs(itemIndexData['sales']) do
        if not itemIds[sale.id] then
          itemIds[sale.id] = true
        else
          internal:dm("Debug", "Duplicate ID")
        end
      end
    end
  end
  internal:dm("Debug", "CompareItemIds Done")
end

function internal:NonContiguousNonNilCount(tableObject)
  local count = 0

  for _, v in pairs(tableObject) do
    if v ~= nil then count = count + 1 end
  end

  return count
end

function internal:CleanTimestamp(salesRecord)
  if (salesRecord == nil) or (salesRecord.timestamp == nil) or (type(salesRecord.timestamp) ~= 'number') then return 0 end
  return salesRecord.timestamp
end

function internal:spairs(t, order)
  -- all the indexes
  local indexes = {}
  for k in pairs(t) do indexes[#indexes + 1] = k end

  -- if order function given, sort by it by passing the table's a, b values
  -- otherwise just sort by the index values
  if order then
    table.sort(indexes, function(a, b) return order(t[a], t[b]) end)
  else
    table.sort(indexes)
  end

  -- return the iterator function
  local i = 0
  return function()
    i = i + 1
    if indexes[i] then
      return indexes[i], t[indexes[i]]
    end
  end
end

function internal:IsValidItemLink(itemLink)
  -- itemLink should be the full link here
  local validLink = true
  local _, count  = string.gsub(itemLink, ':', ':')
  if count ~= 22 then
    internal:dm("Debug", "count ~= 22")
    validLink = false
  end
  local theIID      = GetItemLinkItemId(itemLink)
  local itemIdMatch = tonumber(zo_strmatch(itemLink, '|H.-:item:(.-):'))
  if not theIID then
    internal:dm("Debug", "theIID was nil I guess?")
    validLink = false
  end
  if theIID and (theIID ~= itemIdMatch) then
    validLink = false
    internal:dm("Debug", "theIID ~= itemIdMatch")
  end
  local itemlinkName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink))
  if internal:is_empty_or_nil(itemlinkName) then
    internal:dm("Debug", "itemlinkName was empty or nil")
    validLink = false
  end
  if not validLink then
    internal:dm("Debug", MasterMerchant.ItemCodeText(itemLink))
  end
  return validLink
end

----------------------------------------
----- Functions                    -----
----------------------------------------

function internal:RenewExtraData(otherData)
  local savedVars = otherData[internal.dataNamespace]

  for itemID, itemIndex in pairs(savedVars) do
    for field, itemIndexData in pairs(itemIndex) do
      if itemIndexData.wasAltered then
        local oldestTime = nil
        local totalCount = 0
        for sale, saleData in pairs(itemIndexData['sales']) do
          totalCount = totalCount + 1
          if oldestTime == nil or oldestTime > saleData.timestamp then oldestTime = saleData.timestamp end
        end
        if savedVars[itemID][field] then
          savedVars[itemID][field].totalCount = totalCount
          savedVars[itemID][field].oldestTime = oldestTime
          savedVars[itemID][field].wasAltered = false
        else
          --internal:dm("Warn", "Empty or nil savedVars[internal.dataNamespace]")
        end
      end
    end
  end
end

-- DEBUG
function internal:VerifyItemLinks(hash, task)
  local saveFile   = _G[string.format("GS%02dDataSavedVariables", hash)]
  local fileString = string.format("GS%02dDataSavedVariables", hash)
  task:Then(function(task) internal:dm("Debug", string.format("VerifyItemLinks for: %s", fileString)) end)
  task:Then(function(task) internal:dm("Debug", hash) end)
  local savedVars = saveFile[internal.dataNamespace]

  task:For(pairs(savedVars)):Do(function(itemID, itemIndex)
    task:For(pairs(itemIndex)):Do(function(field, itemIndexData)
      task:For(pairs(itemIndexData['sales'])):Do(function(sale, saleData)
        local currentLink = internal:GetStringByIndex(internal.GS_CHECK_ITEMLINK, saleData.itemLink)
        local currentHash = internal:MakeHashString(currentLink)
        if currentHash ~= hash then
          task:Then(function(task) internal:dm("Debug", "sale in wrong file") end)
        end
      end)
    end)
  end)
end

function internal:AddNewData(otherData)
  local savedVars = otherData[internal.dataNamespace]

  for itemID, itemIndex in pairs(savedVars) do
    for field, itemIndexData in pairs(itemIndex) do
      local oldestTime = nil
      local totalCount = 0
      for sale, saleData in pairs(itemIndexData['sales']) do
        totalCount = totalCount + 1
        if saleData.timestamp then
          if oldestTime == nil or oldestTime > saleData.timestamp then oldestTime = saleData.timestamp end
        else
          if internal:is_empty_or_nil(saleData) then
            internal:dm("Warn", "Empty Table Detected!")
            internal:dm("Warn", itemID)
            internal:dm("Warn", sale)
            itemIndexData['sales'][sale] = nil
          end
        end
      end
      if savedVars[itemID][field] then
        savedVars[itemID][field].totalCount = totalCount
        savedVars[itemID][field].oldestTime = oldestTime
        savedVars[itemID][field].wasAltered = false
      else
        --internal:dm("Warn", "Empty or nil savedVars[internal.dataNamespace]")
      end
    end
  end
end

-- Renew extra data if list was altered
function internal:RenewExtraDataAllContainers()
  internal:dm("Debug", "Add new data to LibGuildStore concatanated data array")
  internal:RenewExtraData(GS00DataSavedVariables)
  internal:RenewExtraData(GS01DataSavedVariables)
  internal:RenewExtraData(GS02DataSavedVariables)
  internal:RenewExtraData(GS03DataSavedVariables)
  internal:RenewExtraData(GS04DataSavedVariables)
  internal:RenewExtraData(GS05DataSavedVariables)
  internal:RenewExtraData(GS06DataSavedVariables)
  internal:RenewExtraData(GS07DataSavedVariables)
  internal:RenewExtraData(GS08DataSavedVariables)
  internal:RenewExtraData(GS09DataSavedVariables)
  internal:RenewExtraData(GS10DataSavedVariables)
  internal:RenewExtraData(GS11DataSavedVariables)
  internal:RenewExtraData(GS12DataSavedVariables)
  internal:RenewExtraData(GS13DataSavedVariables)
  internal:RenewExtraData(GS14DataSavedVariables)
  internal:RenewExtraData(GS15DataSavedVariables)
end

-- Add new data to concatanated data array
function internal:AddNewDataAllContainers()
  internal:dm("Debug", "Add new data to concatanated data array")
  internal:AddNewData(GS00DataSavedVariables)
  internal:AddNewData(GS01DataSavedVariables)
  internal:AddNewData(GS02DataSavedVariables)
  internal:AddNewData(GS03DataSavedVariables)
  internal:AddNewData(GS04DataSavedVariables)
  internal:AddNewData(GS05DataSavedVariables)
  internal:AddNewData(GS06DataSavedVariables)
  internal:AddNewData(GS07DataSavedVariables)
  internal:AddNewData(GS08DataSavedVariables)
  internal:AddNewData(GS09DataSavedVariables)
  internal:AddNewData(GS10DataSavedVariables)
  internal:AddNewData(GS11DataSavedVariables)
  internal:AddNewData(GS12DataSavedVariables)
  internal:AddNewData(GS13DataSavedVariables)
  internal:AddNewData(GS14DataSavedVariables)
  internal:AddNewData(GS15DataSavedVariables)
end

-- Add new data to concatanated data array
-- /script LibGuildStore_Internal:VerifyAllItemLinks()
-- DEBUG
function internal:VerifyAllItemLinks()
  local task = ASYNC:Create("VerifyAllItemLinks")
  task:Call(function(task) internal:DatabaseBusy(true) end)
      :Then(function(task) internal:VerifyItemLinks(00, task) end)
      :Then(function(task) internal:VerifyItemLinks(01, task) end)
      :Then(function(task) internal:VerifyItemLinks(02, task) end)
      :Then(function(task) internal:VerifyItemLinks(03, task) end)
      :Then(function(task) internal:VerifyItemLinks(04, task) end)
      :Then(function(task) internal:VerifyItemLinks(05, task) end)
      :Then(function(task) internal:VerifyItemLinks(06, task) end)
      :Then(function(task) internal:VerifyItemLinks(07, task) end)
      :Then(function(task) internal:VerifyItemLinks(08, task) end)
      :Then(function(task) internal:VerifyItemLinks(09, task) end)
      :Then(function(task) internal:VerifyItemLinks(10, task) end)
      :Then(function(task) internal:VerifyItemLinks(11, task) end)
      :Then(function(task) internal:VerifyItemLinks(12, task) end)
      :Then(function(task) internal:VerifyItemLinks(13, task) end)
      :Then(function(task) internal:VerifyItemLinks(14, task) end)
      :Then(function(task) internal:VerifyItemLinks(15, task) end)
      :Then(function(task) internal:dm("Debug", "VerifyAllItemLinks Done") end)
      :Finally(function(task) internal:DatabaseBusy(false) end)
end

function internal:DatabaseBusy(start)
  internal.isDatabaseBusy = start
  --[[
  if start then
    for i = 1, GetNumGuilds() do
      local guildId = GetGuildId(i)
      internal.LibHistoireListener[guildId]:Stop()
      internal.LibHistoireListener[guildId] = {}
    end
  end
  if not start then
    internal:SetupListenerLibHistoire()
  end
  ]]--
  if not MasterMerchant then return end

  --[[ TODO this may be used for something else
  MasterMerchantResetButton:SetEnabled(not start)
  MasterMerchantGuildResetButton:SetEnabled(not start)
  MasterMerchantRefreshButton:SetEnabled(not start)
  MasterMerchantGuildRefreshButton:SetEnabled(not start)
  ]]--

  if not start then
    MasterMerchantWindowLoadingIcon.animation:Stop()
    MasterMerchantGuildWindowLoadingIcon.animation:Stop()
    MasterMerchantListingWindowLoadingIcon.animation:Stop()
    MasterMerchantPurchaseWindowLoadingIcon.animation:Stop()
  end

  MasterMerchantWindowLoadingIcon:SetHidden(not start)
  MasterMerchantGuildWindowLoadingIcon:SetHidden(not start)
  MasterMerchantListingWindowLoadingIcon:SetHidden(not start)
  MasterMerchantPurchaseWindowLoadingIcon:SetHidden(not start)

  if start then
    MasterMerchantWindowLoadingIcon.animation:PlayForward()
    MasterMerchantGuildWindowLoadingIcon.animation:PlayForward()
    MasterMerchantListingWindowLoadingIcon.animation:PlayForward()
    MasterMerchantPurchaseWindowLoadingIcon.animation:PlayForward()
  end
end

--[[
  Reference for internal:AddSearchToItem

  ["sales"] =
  {
      [1] =
      {
          ["itemLink"] = "|H0:item:68633:359:50:0:0:0:0:0:0:0:0:0:0:0:0:13:0:0:0:10000:0|h|h",
          ["timestamp"] = 1604974613,
          ["guild"] = "Unstable Unicorns",
          ["buyer"] = "@misscastalot",
          ["seller"] = "@thecloakgirl",
          ["wasKiosk"] = true,
          ["price"] = 500,
          ["id"] = "1414605555",
          ["quant"] = 1,
      },
  },
  ["itemDesc"] = "Helm of the Pariah",
  ["itemAdderText"] = "cp160 green  fine  set mark of the pariah  apparel  well-fitted  head ",
  ["itemIcon"] = "/esoui/art/icons/gear_malacath_heavy_head_a.dds",

  weapon
  /script internal:dm("Debug", GetNumTradingHouseSearchResultItemLinkAsFurniturePreviewVariations("|H0:item:68633:363:50:0:0:0:0:0:0:0:0:0:0:0:0:13:0:0:0:10000:0|h|h"))
  /script internal:dm("Debug", GetItemLinkRequiredChampionPoints("|H0:item:167719:2:50:0:0:0:0:0:0:0:0:0:0:0:0:111:0:0:0:10000:0|h|h"))
  /script internal:dm("Debug", GetItemLinkReagentTraitInfo("|H1:item:45839:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"))
  armor

  /script internal:dm("Debug", zo_strformat("<<t:1>>", GetString("SI_ITEMFILTERTYPE", GetItemLinkFilterTypeInfo("|H1:item:167644:362:50:0:0:0:0:0:0:0:0:0:0:0:0:111:0:0:0:300:0|h|h"))))


  SI_ITEMFILTERTYPE
  /script adder = ""; adder = internal:concat(adder, "weapon"); internal:dm(adder)

  What is Done:
	Line 16112: * GetItemLinkItemType(*string* _itemLink_)
	Line 16130: * GetItemLinkRequiredLevel(*string* _itemLink_)
	Line 16133: * GetItemLinkRequiredChampionPoints(*string* _itemLink_)
	Line 16214: * GetItemLinkDisplayQuality(*string* _itemLink_)
	Line 16118: * GetItemLinkArmorType(*string* _itemLink_)
	Line 15863: * GetItemLinkFilterTypeInfo(*string* _itemLink_)
	Line 16181: * GetItemLinkSetInfo(*string* _itemLink_, *bool* _equipped_)
	Line 16121: * GetItemLinkWeaponType(*string* _itemLink_)
	Line 16226: * GetItemLinkEquipType(*string* _itemLink_)
	Line 15966: * GetItemLinkTraitType(*string* _itemLink_)



	Line 10252: * GetComparisonEquipSlotsFromItemLink(*string* _itemLink_)
	Line 10278: * GetItemLinkInfo(*string* _itemLink_)
	Line 11409: * GetItemTraitInformationFromItemLink(*string* _itemLink_)
	Line 13353: * SetCustomerServiceTicketItemTargetByLink(*string* _itemLink_)
	Line 15728: * GetLinkType(*string* _itemLink_)
	Line 15963: * GetItemLinkTraitCategory(*string* _itemLink_)
	Line 16103: * GetItemLinkName(*string* _itemLink_)
	Line 16106: * GetItemLinkItemId(*string* _itemLink_)
	Line 16109: * GetItemLinkIcon(*string* _itemLink_)
	Line 16115: * GetItemLinkItemUseType(*string* _itemLink_)
	Line 16124: * GetItemLinkWeaponPower(*string* _itemLink_)
	Line 16127: * GetItemLinkArmorRating(*string* _itemLink_, *bool* _considerCondition_)
	Line 16136: * GetItemLinkValue(*string* _itemLink_, *bool* _considerCondition_)
	Line 16139: * GetItemLinkCondition(*string* _itemLink_)
	Line 16145: * GetItemLinkMaxEnchantCharges(*string* _itemLink_)
	Line 16148: * GetItemLinkNumEnchantCharges(*string* _itemLink_)
	Line 16154: * GetItemLinkEnchantInfo(*string* _itemLink_)
	Line 16157: * GetItemLinkDefaultEnchantId(*string* _itemLink_)
	Line 16160: * GetItemLinkAppliedEnchantId(*string* _itemLink_)
	Line 16163: * GetItemLinkFinalEnchantId(*string* _itemLink_)
	Line 16172: * GetItemLinkOnUseAbilityInfo(*string* _itemLink_)
	Line 16175: * GetItemLinkTraitOnUseAbilityInfo(*string* _itemLink_, *luaindex* _index_)
	Line 16178: * GetItemLinkTraitInfo(*string* _itemLink_)
	Line 16187: * GetItemLinkSetBonusInfo(*string* _itemLink_, *bool* _equipped_, *luaindex* _index_)
	Line 16190: * GetItemLinkNumContainerSetIds(*string* _itemLink_)
	Line 16193: * GetItemLinkContainerSetInfo(*string* _itemLink_, *luaindex* _containerSetIndex_)
	Line 16196: * GetItemLinkContainerSetBonusInfo(*string* _itemLink_, *luaindex* _containerSetIndex_, *luaindex* _bonusIndex_)
	Line 16199: * GetItemLinkFlavorText(*string* _itemLink_)
	Line 16208: * GetItemLinkSiegeMaxHP(*string* _itemLink_)
	Line 16211: * GetItemLinkFunctionalQuality(*string* _itemLink_)
	Line 16217: * GetItemLinkSiegeType(*string* _itemLink_)
	Line 16232: * GetItemLinkCraftingSkillType(*string* _itemLink_)
	Line 16238: * GetItemLinkEnchantingRuneName(*string* _itemLink_)
	Line 16241: * GetItemLinkEnchantingRuneClassification(*string* _itemLink_)
	Line 16244: * GetItemLinkRequiredCraftingSkillRank(*string* _itemLink_)
	Line 16250: * GetItemLinkBindType(*string* _itemLink_)
	Line 16253: * GetItemLinkGlyphMinLevels(*string* _itemLink_)
	Line 16262: * GetItemLinkFurnishingLimitType(*string* _itemLink_)
	Line 16268: * GetItemLinkBookTitle(*string* _itemLink_)
	Line 16286: * GetItemLinkRecipeResultItemLink(*string* _itemLink_, *[LinkStyle|#LinkStyle]* _linkStyle_)
	Line 16289: * GetItemLinkRecipeNumIngredients(*string* _itemLink_)
	Line 16292: * GetItemLinkRecipeIngredientInfo(*string* _itemLink_, *luaindex* _index_)
	Line 16295: * GetItemLinkRecipeIngredientItemLink(*string* _itemLink_, *luaindex* _index_, *[LinkStyle|#LinkStyle]* _linkStyle_)
	Line 16298: * GetItemLinkRecipeNumTradeskillRequirements(*string* _itemLink_)
	Line 16301: * GetItemLinkRecipeTradeskillRequirement(*string* _itemLink_, *luaindex* _tradeskillIndex_)
	Line 16304: * GetItemLinkRecipeQualityRequirement(*string* _itemLink_)
	Line 16307: * GetItemLinkRecipeCraftingSkillType(*string* _itemLink_)
	Line 16310: * GetItemLinkReagentTraitInfo(*string* _itemLink_, *luaindex* _index_)
	Line 16313: * GetItemLinkItemStyle(*string* _itemLink_)
	Line 16316: * GetItemLinkShowItemStyleInTooltip(*string* _itemLink_)
	Line 16319: * GetItemLinkRefinedMaterialItemLink(*string* _itemLink_, *[LinkStyle|#LinkStyle]* _linkStyle_)
	Line 16322: * GetItemLinkMaterialLevelDescription(*string* _itemLink_)
	Line 16343: * GetItemLinkStacks(*string* _itemLink_)
	Line 16349: * GetItemLinkDyeIds(*string* _itemLink_)
	Line 16352: * GetItemLinkDyeStampId(*string* _itemLink_)
	Line 16355: * GetItemLinkFurnitureDataId(*string* _itemLink_)
	Line 16358: * GetItemLinkGrantedRecipeIndices(*string* _itemLink_)
	Line 16364: * GetItemLinkOutfitStyleId(*string* _itemLink_)
	Line 16367: * GetItemLinkTooltipRequiresCollectibleId(*string* _itemLink_)
	Line 16376: * GetItemLinkCombinationId(*string* _itemLink_)
	Line 16379: * GetItemLinkCombinationDescription(*string* _itemLink_)
	Line 16382: * GetItemLinkTradingHouseItemSearchName(*string* _itemLink_)
	Line 16385: * GetItemLinkContainerCollectibleId(*string* _itemLink_)
	Line 16422: * GetItemLinkNumItemTags(*string* _itemLink_)
	Line 16425: * GetItemLinkItemTagInfo(*string* _itemLink_, *luaindex* _itemTagIndex_)
	Line 16484: * GetItemLinkSellInformation(*string* _itemLink_)
	Line 17329: * GetNumTradingHouseSearchResultItemLinkAsFurniturePreviewVariations(*string* _itemLink_)
	Line 17332: * GetTradingHouseSearchResultItemLinkAsFurniturePreviewVariationDisplayName(*string* _itemLink_, *luaindex* _variation_)
  internal:concat("weapon", "weapon")
]]--
