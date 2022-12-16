local mmInternal = _G["MasterMerchant_Internal"]

function MasterMerchant:GetSingularOrPluralString(singularString, pluralString, formatValue)
  if formatValue > 1 then return string.format(pluralString, formatValue)
  else return string.format(singularString, formatValue) end
end

function MasterMerchant:AvgPricePriceTip(statsInfo, chatText)
  local formatedPriceString
  local goldIcon
  local headerText
  local avgPriceString
  local avgPriceNumSales
  local avgPriceNumItems
  local avgPriceDays
  local includeItemCount = MasterMerchant.systemSavedVariables.includeItemCountPriceToChat
  local fullDataRange = false
  if statsInfo and statsInfo.numDays == 10000 then fullDataRange = true end

  if chatText then goldIcon = "" else goldIcon = MM_COIN_ICON_NO_SPACE end
  if chatText then headerText = GetString(MM_PTC_MM_HEADER) else headerText = GetString(MM_TIP_MM_HEADER) end

  if statsInfo and statsInfo.avgPrice then avgPriceString = string.format(GetString(MM_PTC_PRICE_FORMATER), self.LocalizedNumber(statsInfo.avgPrice)) .. goldIcon end
  if statsInfo and statsInfo.numSales then avgPriceNumSales = MasterMerchant:GetSingularOrPluralString(GetString(MM_PTC_SINGULAR_SALE), GetString(MM_PTC_PLURAL_SALES), statsInfo.numSales) end
  if statsInfo and statsInfo.numItems and includeItemCount then avgPriceNumItems = MasterMerchant:GetSingularOrPluralString(GetString(MM_PTC_SINGULAR_ITEM), GetString(MM_PTC_PLURAL_ITEMS), statsInfo.numItems) end
  if avgPriceNumSales and avgPriceNumItems then avgPriceNumItems = GetString(MM_PTC_SLASH_SEPERATOR) .. avgPriceNumItems end
  if statsInfo and statsInfo.avgPrice and statsInfo.numDays and not fullDataRange then avgPriceDays = MasterMerchant:GetSingularOrPluralString(GetString(MM_PTC_SINGULAR_DAY), GetString(MM_PTC_PLURAL_DAYS), statsInfo.numDays) end

  -- alter avgPriceString if no data is available
  if statsInfo and not statsInfo.avgPrice and fullDataRange then avgPriceString = GetString(MM_NO_DATA_FORMAT) .. GetString(MM_PTC_CLOSING_SEPERATOR) end
  if statsInfo and not statsInfo.avgPrice and not fullDataRange then avgPriceString = string.format(GetString(MM_NO_DATA_RANGE_FORMAT), self.LocalizedNumber(statsInfo.numDays)) .. GetString(MM_PTC_CLOSING_SEPERATOR) end

  formatedPriceString = MasterMerchant.concatTooltip(headerText, avgPriceNumSales, avgPriceNumItems, avgPriceDays, avgPriceString)
  return formatedPriceString
end

function MasterMerchant:BonanzaPriceTip(statsInfo, chatText)
  if statsInfo and not statsInfo.bonanzaPrice then return nil end
  local formatedBonanzaString
  local goldIcon
  local headerText
  local bonanzaPriceString
  local bonanzaNumListingsString
  local bonanzaNumItemsString
  local includeItemCount = MasterMerchant.systemSavedVariables.includeItemCountPriceToChat

  if chatText then goldIcon = "" else goldIcon = MM_COIN_ICON_NO_SPACE end
  if chatText then headerText = GetString(MM_PTC_BONANZA_HEADER) else headerText = GetString(MM_TIP_BONANZA_HEADER) end

  if statsInfo and statsInfo.bonanzaPrice then bonanzaPriceString = string.format(GetString(MM_PTC_PRICE_FORMATER), self.LocalizedNumber(statsInfo.bonanzaPrice)) .. goldIcon end
  if statsInfo and statsInfo.bonanzaListings then bonanzaNumListingsString = MasterMerchant:GetSingularOrPluralString(GetString(MM_PTC_SINGULAR_LISTING), GetString(MM_PTC_PLURAL_LISTINGS), statsInfo.bonanzaListings) end
  if statsInfo and statsInfo.bonanzaItemCount and includeItemCount then bonanzaNumItemsString = MasterMerchant:GetSingularOrPluralString(GetString(MM_PTC_SINGULAR_ITEM), GetString(MM_PTC_PLURAL_ITEMS), statsInfo.bonanzaItemCount) end
  if bonanzaNumListingsString and bonanzaNumItemsString then bonanzaNumItemsString = GetString(MM_PTC_SLASH_SEPERATOR) .. bonanzaNumItemsString .. GetString(MM_PTC_CLOSING_SEPERATOR) end
  if not includeItemCount then bonanzaNumListingsString = bonanzaNumListingsString .. GetString(MM_PTC_CLOSING_SEPERATOR) end

  formatedBonanzaString = MasterMerchant.concatTooltip(headerText, bonanzaNumListingsString, bonanzaNumItemsString, bonanzaPriceString)
  return formatedBonanzaString
end

function MasterMerchant:TTCPriceTip(priceStats, chatText)
  if not chatText and not priceStats and MasterMerchant.systemSavedVariables.showAltTtcTipline then return GetString(MM_NO_TTC_PRICE)
  elseif not priceStats then return nil end

  local formatedTTCString
  local goldIcon
  local headerText
  local suggestedPrice
  local ttcAvgPriceString
  local ttcSuggestedPriceString
  local ttcNumListingsString
  local ttcNumItemsString
  local includeItemCount = MasterMerchant.systemSavedVariables.includeItemCountPriceToChat

  if chatText then goldIcon = "" else goldIcon = MM_COIN_ICON_NO_SPACE end
  if chatText then headerText = GetString(MM_PTC_TTC_HEADER) else headerText = GetString(MM_TIP_TTC_HEADER) end

  if priceStats and priceStats.SuggestedPrice and MasterMerchant.systemSavedVariables.modifiedSuggestedPriceDealCalc then suggestedPrice = priceStats.SuggestedPrice * 1.25
  else suggestedPrice = priceStats.SuggestedPrice end
  if suggestedPrice then ttcSuggestedPriceString = string.format(GetString(MM_PTC_TTC_SUGGESTED), self.LocalizedNumber(suggestedPrice)) .. goldIcon end
  if priceStats and priceStats.Avg then ttcAvgPriceString = string.format(GetString(MM_PTC_TTC_AVERAGE), self.LocalizedNumber(priceStats.Avg)) .. goldIcon end
  if ttcAvgPriceString and ttcSuggestedPriceString then ttcAvgPriceString = GetString(MM_PTC_COMMA_SPACE_SEPERATOR) .. ttcAvgPriceString end
  if priceStats and priceStats.EntryCount then ttcNumListingsString = MasterMerchant:GetSingularOrPluralString(GetString(MM_PTC_SINGULAR_LISTING), GetString(MM_PTC_PLURAL_LISTINGS), priceStats.EntryCount) end
  if chatText and priceStats and priceStats.AmountCount and includeItemCount then ttcNumItemsString = MasterMerchant:GetSingularOrPluralString(GetString(MM_PTC_SINGULAR_ITEM), GetString(MM_PTC_PLURAL_ITEMS), priceStats.AmountCount) end

  if not chatText and ttcNumListingsString or chatText and not includeItemCount then ttcNumListingsString = ttcNumListingsString .. GetString(MM_PTC_CLOSING_SEPERATOR_SPACE) end
  if chatText and ttcNumListingsString and ttcNumItemsString then ttcNumItemsString = GetString(MM_PTC_SLASH_SEPERATOR) .. ttcNumItemsString .. GetString(MM_PTC_CLOSING_SEPERATOR_SPACE) end

  formatedTTCString = MasterMerchant.concatTooltip(headerText, ttcNumListingsString, ttcNumItemsString, ttcSuggestedPriceString, ttcAvgPriceString)
  return formatedTTCString
end

function MasterMerchant:VoucherAveragePriceTip(statsInfo, ttcPriceInfo, chatText)
  if not statsInfo and not ttcPriceInfo then return end
  -- numVouchers > 0 already verified
  local goldIcon
  local formatedPriceString
  local averagePrice
  local avgVoucherString
  local tipFormat = GetString(MM_PTC_PER_VOUCHER)
  local useMMAverage = statsInfo and statsInfo.avgPrice and MasterMerchant.systemSavedVariables.voucherValueTypeToUse == MM_PRICE_MM_AVERAGE
  local useBonanza = statsInfo and statsInfo.bonanzaPrice and MasterMerchant.systemSavedVariables.voucherValueTypeToUse == MM_PRICE_BONANZA
  local useTTCAverage = ttcPriceInfo and ttcPriceInfo.Avg and MasterMerchant.systemSavedVariables.voucherValueTypeToUse == MM_PRICE_TTC_AVERAGE
  local useTTCSuggested = ttcPriceInfo and ttcPriceInfo.SuggestedPrice and MasterMerchant.systemSavedVariables.voucherValueTypeToUse == MM_PRICE_TTC_SUGGESTED

  if chatText then goldIcon = "" else goldIcon = MM_COIN_ICON_NO_SPACE end
  if useMMAverage then averagePrice = statsInfo.avgPrice
  elseif useBonanza then averagePrice = statsInfo.bonanzaPrice
  elseif useTTCAverage then averagePrice = ttcPriceInfo.Avg
  elseif useTTCSuggested then averagePrice = ttcPriceInfo.SuggestedPrice end
  if useTTCSuggested and averagePrice and MasterMerchant.systemSavedVariables.modifiedSuggestedPriceVoucher then averagePrice = averagePrice * 1.25 end

  if averagePrice then
    avgVoucherString = self.LocalizedNumber(averagePrice / statsInfo.numVouchers) .. goldIcon
  end
  if avgVoucherString then
    formatedPriceString = string.format(tipFormat, avgVoucherString)
  end

  return formatedPriceString
end

--[[ |H1:item:79434:364:50:0:0:0:0:0:0:0:0:0:0:0:0:13:0:0:0:10000:0|h|h Yellow Shield
|H1:item:126850:5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h Recipe
]]--
-- |H1:item:90919:359:50:0:0:0:0:0:0:0:0:0:0:0:0:23:0:0:0:10000:0|h|h
-- |H0:item:90919:359:50:0:0:0:0:0:0:0:0:0:0:0:0:23:0:0:0:10000:0|h|h
-- |H1:item:95396:363:50:0:0:0:0:0:0:0:0:0:0:0:0:35:0:0:0:400:0|h|h
-- |H1:item:151661:4:1:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:0|h|h
-- |H1:item:54177:34:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h

--|H1:item:126850:5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h no MM
--|H1:item:156606:0:0:0:0:0:0:0:0:0:0:0:0:0:0:93:0:0:0:0:0|h|h
function MasterMerchant:GetPriceToChatTipline(statsInfo, priceStats)
  local masterMerchantPTC
  local bonanzaPTC
  local ttcPTC
  local voucherStringPriceToChat

  local includeTTCPricing = TamrielTradeCentre and (MasterMerchant.systemSavedVariables.showAltTtcTipline or MasterMerchant.systemSavedVariables.includeTTCDataPriceToChat)
  local includeVoucherCost = MasterMerchant.systemSavedVariables.includeVoucherAverage
  if includeVoucherCost and statsInfo.numVouchers > 0 then
    voucherStringPriceToChat = MasterMerchant:VoucherAveragePriceTip(statsInfo, priceStats, true)
  end

  -- MasterMerchant:dm("Debug", includeTTCPricing)
  -- MasterMerchant:dm("Debug", includeVoucherCost)
  -- MasterMerchant:dm("Debug", voucherStringPriceToChat)

  masterMerchantPTC = MasterMerchant:AvgPricePriceTip(statsInfo, true)
  bonanzaPTC = MasterMerchant:BonanzaPriceTip(statsInfo, true)
  if includeTTCPricing then ttcPTC = MasterMerchant:TTCPriceTip(priceStats, true) end

  if masterMerchantPTC and not bonanzaPTC and not ttcPTC then masterMerchantPTC = masterMerchantPTC .. GetString(MM_PTC_COLON_SEPERATOR) end
  if bonanzaPTC and not masterMerchantPTC and not ttcPTC then bonanzaPTC = bonanzaPTC .. GetString(MM_PTC_COLON_SEPERATOR) end
  if ttcPTC and includeTTCPricing then ttcPTC = ttcPTC .. GetString(MM_PTC_COLON_SEPERATOR) end

  -- MasterMerchant:dm("Debug", masterMerchantPTC)
  -- MasterMerchant:dm("Debug", bonanzaPTC)
  -- MasterMerchant:dm("Debug", ttcPTC)

  local returnData = MasterMerchant.concat(masterMerchantPTC, bonanzaPTC, ttcPTC, voucherStringPriceToChat)
  -- MasterMerchant:dm("Debug", returnData)
  return returnData
end

function MasterMerchant:GetCondensedPriceToChatTipline(statsInfo, priceStats)
  local includeVoucherCost = MasterMerchant.systemSavedVariables.includeVoucherAverage
  local voucherStringPriceToChat
  local mmPriceString
  local bonanzaPriceString
  local ttcPriceSuggested
  local ttcPriceAvg
  local ttcPriceString
  local fullDataRange
  if statsInfo and statsInfo.numDays == 10000 then fullDataRange = true end

  if statsInfo and statsInfo.avgPrice then mmPriceString = string.format(GetString(MM_MMPTC_CONDENSED_FORMAT), statsInfo.numSales, statsInfo.numDays, self.LocalizedNumber(statsInfo.avgPrice)) end

  if statsInfo and not statsInfo.avgPrice and fullDataRange then mmPriceString = GetString(MM_TIP_MM_HEADER) .. GetString(MM_NO_DATA_FORMAT) .. GetString(MM_PTC_CLOSING_SEPERATOR) end
  if statsInfo and not statsInfo.avgPrice and not fullDataRange then mmPriceString = GetString(MM_TIP_MM_HEADER) .. string.format(GetString(MM_NO_DATA_RANGE_FORMAT), self.LocalizedNumber(statsInfo.numDays)) .. GetString(MM_PTC_CLOSING_SEPERATOR) end

  if statsInfo and statsInfo.bonanzaPrice then bonanzaPriceString = string.format(GetString(MM_BONANZAPTC_CONDENSED_FORMAT), statsInfo.bonanzaListings, self.LocalizedNumber(statsInfo.bonanzaPrice)) end
  if priceStats then
    if priceStats and priceStats.SuggestedPrice then ttcPriceSuggested = self.LocalizedNumber(priceStats.SuggestedPrice) else ttcPriceSuggested = "0" end
    if priceStats and priceStats.Avg then ttcPriceAvg = self.LocalizedNumber(priceStats.Avg) else ttcPriceAvg = "0" end
    ttcPriceString = string.format(GetString(MM_TTCPTC_MM_TTC_FORMAT), ttcPriceSuggested, ttcPriceAvg)
  end
  if includeVoucherCost and statsInfo.numVouchers > 0 then
    voucherStringPriceToChat = MasterMerchant:VoucherAveragePriceTip(statsInfo, priceStats, true)
  end

  local returnData = MasterMerchant.concat(mmPriceString, bonanzaPriceString, ttcPriceString, voucherStringPriceToChat)
  return returnData
end

function MasterMerchant:GetPriceToChatText(itemLink)
  local statsInfo = MasterMerchant:GetTooltipStats(itemLink, false, false)
  local priceStats
  local includeTTCPricing = TamrielTradeCentre and (MasterMerchant.systemSavedVariables.showAltTtcTipline or MasterMerchant.systemSavedVariables.includeTTCDataPriceToChat)
  if includeTTCPricing then
    priceStats = TamrielTradeCentrePrice:GetPriceInfo(itemLink)
  end
  if MasterMerchant.systemSavedVariables.useCondensedPriceToChat then return MasterMerchant:GetCondensedPriceToChatTipline(statsInfo, priceStats)
  else return MasterMerchant:GetPriceToChatTipline(statsInfo, priceStats) end
end

--[[TODO update how craft cost string is created and avoid overriding the string
when you have per item costs
]]--
function MasterMerchant:CraftCostPriceTip(itemLink, chatText)
  local cost, costPerItem = self:itemCraftPrice(itemLink)
  local costTipString = ""
  local costPerItemTipString = ""
  local craftTip = ""
  local craftingTooltipString = ""
  if cost then
    costTipString = self.LocalizedNumber(cost)
    craftTip = GetString(MM_CRAFTCOST_PRICE_TIP)
    if not chatText then craftTip = craftTip .. MM_COIN_ICON_NO_SPACE end
    craftingTooltipString = string.format(craftTip, costTipString)
  end
  -- if costPerItem, craftingTooltipString is overridden
  if costPerItem then
    costPerItemTipString = self.LocalizedNumber(costPerItem)
    craftTip = GetString(MM_CRAFTCOSTPER_PRICE_TIP)
    if not chatText then craftTip = craftTip .. MM_COIN_ICON_NO_SPACE end
    craftingTooltipString = string.format(craftTip, costTipString, costPerItemTipString)
  end
  if craftingTooltipString ~= MM_STRING_EMPTY then
    return craftingTooltipString
  else
    return nil
  end
end

-- /script d(MasterMerchant:MaterialCostPriceTip("|H1:item:156731:4:1:0:0:0:117940:0:0:0:0:0:0:0:0:0:0:0:0:0:10000|h|h"))
function MasterMerchant:MaterialCostPriceTip(itemLink, writCost)
  local cost = mmInternal:MaterialCostPrice(itemLink)
  local costTipString = ""
  local writCostTipString = ""
  local totalCostTipString = ""
  local materialTooltipString = ""
  local totalCost = 0
  if cost and not writCost then
    costTipString = MasterMerchant.LocalizedNumber(cost) .. MM_COIN_ICON_NO_SPACE
    materialTooltipString = string.format(GetString(MM_MATCOST_PRICE_TIP), costTipString)
  elseif cost and writCost then
    totalCost = cost + writCost
    costTipString = MasterMerchant.LocalizedNumber(cost) .. MM_COIN_ICON_NO_SPACE
    writCostTipString = MasterMerchant.LocalizedNumber(writCost) .. MM_COIN_ICON_NO_SPACE
    totalCostTipString = MasterMerchant.LocalizedNumber(totalCost) .. MM_COIN_ICON_NO_SPACE
    materialTooltipString = string.format(GetString(MM_MATCOST_PLUS_WRITCOST_TIP), costTipString, writCostTipString, totalCostTipString)
  end
  local qtyRequired = mmInternal:GetWinterWritRequiredQty(itemLink)
  if materialTooltipString ~= MM_STRING_EMPTY and not qtyRequired then
    materialTooltipString = materialTooltipString .. "\n(qty not in database)"
  end
  if materialTooltipString ~= MM_STRING_EMPTY then
    return materialTooltipString
  else
    return nil
  end
end
