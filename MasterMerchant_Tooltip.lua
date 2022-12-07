local mmInternal = _G["MasterMerchant_Internal"]

--[[TODO refine this, I don't see why we need so many ways to get the
average price and the graph information

Returns:

Formated avgPrice String
Formated bonanzaPrice String
numDays
avgPrice
bonanzaPrice
graphInfo
]]--
function MasterMerchant:AvgPricePriceTip(avgPrice, numSales, numItems, numDays, chatText)
  -- TODO add Bonanza price
  local formatedPriceString = nil
  local tipFormat
  tipFormat = GetString(MM_GRAPHTIP_MM_FORMAT_PLURAL)
  -- change only when needed
  if numDays < 2 then
    tipFormat = GetString(MM_GRAPHTIP_MM_FORMAT_SINGULAR)
  end

  local avePriceString = self.LocalizedNumber(avgPrice)
  -- chatText
  if not chatText then avePriceString = avePriceString .. MM_COIN_ICON_NO_SPACE end
  formatedPriceString = string.format(tipFormat, numSales, numItems, numDays, avePriceString)

  return formatedPriceString
end

--[[TODO refine this, I don't see why we need so many ways to get the
average price and the graph information

Returns:

Formated avgPrice String
Formated bonanzaPrice String
numDays
avgPrice
bonanzaPrice
graphInfo
]]--
function MasterMerchant:BonanzaPriceTip(bonanzaPrice, bonanzaListings, bonanzaItemCount, chatText, numVouchers)
  -- TODO add Bonanza price
  local formatedBonanzaString = nil
  local bonanzaPriceString = self.LocalizedNumber(bonanzaPrice)
  -- chatText
  if not chatText then bonanzaPriceString = bonanzaPriceString .. MM_COIN_ICON_NO_SPACE end
  formatedBonanzaString = string.format(GetString(MM_GRAPHTIP_BONANZA), bonanzaListings, bonanzaItemCount, bonanzaPriceString)

  return formatedBonanzaString
end

--[[
  priceInfo.Avg = avg
  priceInfo.Max = max
  priceInfo.Min = min
  priceInfo.EntryCount = entryCount -- listings
  priceInfo.AmountCount = amountCount -- items
  priceInfo.SuggestedPrice = suggestedPrice

]]--
function MasterMerchant:TTCPriceTip(priceStats)
  if not priceStats then return GetString(MM_NO_TTC_PRICE) end
  local formatedTTCString
  local suggestedPrice = 0
  local averagePrice = 0
  if priceStats and priceStats.Avg then averagePrice = priceStats.Avg end
  if priceStats and priceStats.SuggestedPrice then suggestedPrice = priceStats.SuggestedPrice end
  if MasterMerchant.systemSavedVariables.modifiedSuggestedPriceDealCalc then
    suggestedPrice = suggestedPrice * 1.25
  end
  local suggestedPriceString = self.LocalizedNumber(suggestedPrice) .. MM_COIN_ICON_NO_SPACE
  local avgPriceString = self.LocalizedNumber(averagePrice) .. MM_COIN_ICON_NO_SPACE
  formatedTTCString = string.format(GetString(MM_GRAPHTIP_TTC), priceStats.EntryCount, suggestedPriceString, avgPriceString)
  return formatedTTCString
end

function MasterMerchant:VoucherAveragePriceTip(statsInfo, ttcPriceInfo, chatText)
  if not statsInfo and not ttcPriceInfo then return end
  -- TODO add other prices
  -- numVouchers > 0 already verified
  local formatedPriceString
  local averagePrice
  local avgVoucherString
  local tipFormat = GetString(MM_PTC_PER_VOUCHER)
  local useMMAverage = statsInfo and statsInfo.SuggestedPrice and MasterMerchant.systemSavedVariables.voucherValueTypeToUse == MM_PRICE_MM_AVERAGE
  local useBonanza = statsInfo and statsInfo.SuggestedPrice and MasterMerchant.systemSavedVariables.voucherValueTypeToUse == MM_PRICE_BONANZA
  local useTTCAverage = ttcPriceInfo and ttcPriceInfo.Avg and MasterMerchant.systemSavedVariables.voucherValueTypeToUse == MM_PRICE_TTC_AVERAGE
  local useTTCSuggested = ttcPriceInfo and ttcPriceInfo.SuggestedPrice and MasterMerchant.systemSavedVariables.voucherValueTypeToUse == MM_PRICE_TTC_SUGGESTED

  if useMMAverage then averagePrice = statsInfo.avgPrice
  elseif useBonanza then averagePrice = statsInfo.bonanzaPrice
  elseif useTTCAverage then averagePrice = ttcPriceInfo.Avg
  elseif useTTCSuggested then averagePrice = ttcPriceInfo.SuggestedPrice end

  if averagePrice then
    avgVoucherString = self.LocalizedNumber(averagePrice / statsInfo.numVouchers)
  end
  -- chatText
  if not chatText and avgVoucherString then avgVoucherString = avgVoucherString .. MM_COIN_ICON_NO_SPACE end
  if avgVoucherString then
    formatedPriceString = string.format(tipFormat, avgVoucherString)
  end

  return formatedPriceString
end

function MasterMerchant:GetSingularOrPluralString(singularString, pluralString, formatValue)
  if formatValue > 1 then return string.format(pluralString, formatValue)
  else return string.format(singularString, formatValue) end
end

-- |H1:item:90919:359:50:0:0:0:0:0:0:0:0:0:0:0:0:23:0:0:0:10000:0|h|h
-- |H0:item:90919:359:50:0:0:0:0:0:0:0:0:0:0:0:0:23:0:0:0:10000:0|h|h
-- |H1:item:95396:363:50:0:0:0:0:0:0:0:0:0:0:0:0:35:0:0:0:400:0|h|h
-- |H1:item:151661:4:1:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:0|h|h
-- |H1:item:54177:34:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h

--|H1:item:126850:5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h no MM
--|H1:item:156606:0:0:0:0:0:0:0:0:0:0:0:0:0:0:93:0:0:0:0:0|h|h
function MasterMerchant:GetTiplineInfo(itemLink)
  -- old values: tipLine, bonanzaTipline, numDays, avgPrice, bonanzaPrice, graphInfo
  local statsInfo = MasterMerchant:GetTooltipStats(itemLink, false, false)
  local ttcPriceInfo
  local includeTTCPricing = TamrielTradeCentre and (MasterMerchant.systemSavedVariables.showAltTtcTipline or MasterMerchant.systemSavedVariables.includeTTCDataPriceToChat)
  if includeTTCPricing then
    ttcPriceInfo = TamrielTradeCentrePrice:GetPriceInfo(itemLink)
  end

  local avgPriceString
  local avgPriceNone
  local avgPriceDays
  local avgPriceNumItems
  local avgPriceNumSales
  local bonanzaPriceString
  local bonanzaNumListingsString
  local bonanzaNumItemsString
  local ttcAvgPriceString
  local ttcSuggestedPriceString
  local ttcNumListingsString
  local ttcNumItemsString
  local voucherStringPriceToChat

  local includeItemCount = MasterMerchant.systemSavedVariables.includeItemCountPriceToChat
  local includeVoucherCost = MasterMerchant.systemSavedVariables.includeVoucherAverage
  local fullDataRange = statsInfo.numDays == 10000

  if statsInfo and statsInfo.avgPrice then avgPriceString = self.LocalizedNumber(statsInfo.avgPrice) end
  if statsInfo and not statsInfo.avgPrice then
    -- 10000 for numDays is more or less like saying it is undefined
    if fullDataRange then
      avgPriceNone = GetString(MM_TIP_FORMAT_NONE)
    else
      avgPriceNone = string.format(GetString(MM_TIP_FORMAT_NONE_RANGE), statsInfo.numDays)
    end
  end
  if statsInfo and statsInfo.numSales then avgPriceNumSales = MasterMerchant:GetSingularOrPluralString(GetString(MM_PTC_SINGULAR_SALE), GetString(MM_PTC_PLURAL_SALES), statsInfo.numSales) end
  if statsInfo and statsInfo.numItems and includeItemCount then avgPriceNumItems = MasterMerchant:GetSingularOrPluralString(GetString(MM_PTC_SINGULAR_ITEM), GetString(MM_PTC_PLURAL_ITEMS), statsInfo.numItems) end
  if statsInfo and statsInfo.numDays and not fullDataRange then avgPriceDays = MasterMerchant:GetSingularOrPluralString(GetString(MM_PTC_SINGULAR_DAY), GetString(MM_PTC_PLURAL_DAYS), statsInfo.numDays) end

  if statsInfo and statsInfo.bonanzaPrice then bonanzaPriceString = self.LocalizedNumber(statsInfo.bonanzaPrice) end
  if statsInfo and statsInfo.bonanzaListings then bonanzaNumListingsString = MasterMerchant:GetSingularOrPluralString(GetString(MM_PTC_SINGULAR_LISTING), GetString(MM_PTC_PLURAL_LISTINGS), statsInfo.bonanzaListings) end
  if statsInfo and statsInfo.bonanzaItemCount and includeItemCount then bonanzaNumItemsString = MasterMerchant:GetSingularOrPluralString(GetString(MM_PTC_SINGULAR_ITEM), GetString(MM_PTC_PLURAL_ITEMS), statsInfo.bonanzaItemCount) end

  if includeTTCPricing then
    if ttcPriceInfo and ttcPriceInfo.Avg then ttcAvgPriceString = self.LocalizedNumber(ttcPriceInfo.Avg) end
    if ttcPriceInfo and ttcPriceInfo.SuggestedPrice then ttcSuggestedPriceString = self.LocalizedNumber(ttcPriceInfo.SuggestedPrice) end
    if ttcPriceInfo and ttcPriceInfo.EntryCount then ttcNumListingsString = MasterMerchant:GetSingularOrPluralString(GetString(MM_PTC_SINGULAR_LISTING), GetString(MM_PTC_PLURAL_LISTINGS), ttcPriceInfo.EntryCount) end
    if ttcPriceInfo and ttcPriceInfo.AmountCount and includeItemCount then ttcNumItemsString = MasterMerchant:GetSingularOrPluralString(GetString(MM_PTC_SINGULAR_ITEM), GetString(MM_PTC_PLURAL_ITEMS), ttcPriceInfo.AmountCount) end
  end

  if includeVoucherCost and statsInfo.numVouchers > 0 then
    voucherStringPriceToChat = MasterMerchant:VoucherAveragePriceTip(statsInfo, ttcPriceInfo, true)
  end

  -- MasterMerchant:dm("Debug", avgPriceString)
  -- MasterMerchant:dm("Debug", avgPriceNone)
  -- MasterMerchant:dm("Debug", avgPriceNumSales)
  -- MasterMerchant:dm("Debug", avgPriceNumItems)
  -- MasterMerchant:dm("Debug", avgPriceDays)
  -- MasterMerchant:dm("Debug", bonanzaPriceString)
  -- MasterMerchant:dm("Debug", bonanzaNumListingsString)
  -- MasterMerchant:dm("Debug", bonanzaNumItemsString)
  -- MasterMerchant:dm("Debug", ttcAvgPriceString)
  -- MasterMerchant:dm("Debug", ttcSuggestedPriceString)
  -- MasterMerchant:dm("Debug", ttcNumListingsString)
  -- MasterMerchant:dm("Debug", ttcNumItemsString)
  -- MasterMerchant:dm("Debug", voucherStringPriceToChat)

  local returnData = MasterMerchant.concat(avgPriceString, avgPriceNone, avgPriceNumSales, avgPriceNumItems, avgPriceDays, bonanzaPriceString,
    bonanzaNumListingsString, bonanzaNumItemsString, ttcAvgPriceString, ttcSuggestedPriceString, ttcNumListingsString,
    ttcNumItemsString, voucherStringPriceToChat)
  -- MasterMerchant:dm("Debug", returnData)
  return returnData
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
