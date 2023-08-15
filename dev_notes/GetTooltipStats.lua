MM_MONTH_DAY_FORMAT = 1
MM_DAY_MONTH_FORMAT = 2
MM_MONTH_DAY_YEAR_FORMAT = 3
MM_YEAR_MONTH_DAY_FORMAT = 4
MM_DAY_MONTH_YEAR_FORMAT = 5

local MM_DATE_FORMATS = {
  [MM_MONTH_DAY_FORMAT] = "<<1>>/<<2>>",
  [MM_DAY_MONTH_FORMAT] = "<<2>>/<<1>>",
  [MM_MONTH_DAY_YEAR_FORMAT] = "<<1>>/<<2>>/<<3>>",
  [MM_YEAR_MONTH_DAY_FORMAT] = "<<3>>/<<1>>/<<2>>",
  [MM_DAY_MONTH_YEAR_FORMAT] = "<<2>>/<<1>>/<<3>>",
}

local function GetDateFormattedString(month, day, yearString)
  local dateFormat = MM_DATE_FORMATS[MasterMerchant.systemSavedVariables.dateFormatMonthDay]
  return zo_strformat(dateFormat, month, day, yearString)
end

local function GetTimeDateString(timestamp)
  local timeData = os.date("*t", timestamp)
  local month, day, hour, minute, year = timeData.month, timeData.day, timeData.hour, timeData.min, timeData.year
  local postMeridiem = hour >= 12
  local yearString = string.sub(tostring(year), 3, 4)
  local meridiemString = MasterMerchant.systemSavedVariables.useTwentyFourHourTime and "" or (postMeridiem and "PM" or "AM")
  if not MasterMerchant.systemSavedVariables.useTwentyFourHourTime then
    hour = hour > 12 and hour - 12 or hour
  end
  minute = minute < 10 and "0" .. tostring(minute) or tostring(minute)
  return string.format("%s %s:%s%s", GetDateFormattedString(month, day, yearString), hour, minute, meridiemString)
end

function MasterMerchant.TextTimeSince(timestamp)
  if MasterMerchant.systemSavedVariables.useFormatedTime then
    return GetTimeDateString(timestamp)
  else
    return GetTimeAgo(timestamp)
  end
end

function MasterMerchant:itemIDHasSales(itemID, itemIndex)
  local salesData = sales_data[itemID] and sales_data[itemID][itemIndex]
  if salesData and salesData.sales then
    return salesData.totalCount > 0
  end
  return false
end

function MasterMerchant:ItemCacheHasPriceInfoById(theIID, itemIndex, daysRange)
  local cache = MasterMerchant.itemInformationCache
  local itemInfo = cache[theIID] and cache[theIID][itemIndex] and cache[theIID][itemIndex][daysRange]
  if itemInfo and itemInfo.avgPrice then
    return true
  end
  return false
end

function MasterMerchant:ItemCacheHasBonanzaInfoById(theIID, itemIndex, daysRange)
  local cache = MasterMerchant.itemInformationCache
  local itemInfo = cache[theIID] and cache[theIID][itemIndex] and cache[theIID][itemIndex][daysRange]
  if itemInfo and itemInfo.bonanzaPrice then
    return true
  end
  return false
end

local function RemoveListingsPerBlacklist(list)
  local nameInBlacklist = nil
  local currentGuild = nil
  local currentSeller = nil
  local dataList = { }
  local statsData = { }

  local function IsNameInBlacklist()
    if MasterMerchant.blacklistTable == nil then return false end
    if currentGuild and MasterMerchant.blacklistTable[currentGuild] then return true end
    if currentSeller and MasterMerchant.blacklistTable[currentSeller] then return true end
    return false
  end

  for _, item in pairs(list) do
    currentGuild = internal:GetGuildNameByIndex(item.guild)
    currentSeller = internal:GetAccountNameByIndex(item.seller)
    nameInBlacklist = IsNameInBlacklist()
    if not nameInBlacklist then
      local individualSale = item.price / item.quant
      dataList[#dataList + 1] = item
      statsData[#statsData + 1] = individualSale
    end
  end
  return dataList, statsData
end

function MasterMerchant:GetTooltipStats(itemLink, averageOnly, generateGraph)
  local avgPrice, legitSales, daysHistory, countSold, bonanzaPrice, bonanzaListings, bonanzaItemCount, numVouchers, graphInfo
  local versionData, salesData, itemInfo
  local outliersList, bonanzaList, statsData, bonanzaStatsData, salesPoints
  local lowestPrice, highestPrice, oldestTime, newestTime

  local function IsNameInBlacklist()
  local blacklistTable = MasterMerchant.blacklistTable
    if blacklistTable == nil then return false end
    return (currentGuild and blacklistTable[currentGuild]) or
           (currentBuyer and blacklistTable[currentBuyer]) or
           (currentSeller and blacklistTable[currentSeller])
  end

  local function ProcessDots(individualSale, item)
    salesPoints = salesPoints or {}
    local tooltip = nil
    local timeframeString = GetTimeString(item.timestamp)
    local stringPrice = self.LocalizedNumber(individualSale)
    if salesDetails then
      if item.quant == 1 then
        tooltip = timeframeString .. " " .. string.format(GetString(MM_GRAPH_TIP_SINGLE), currentGuild,
          currentSeller, nameString, currentBuyer, stringPrice)
      else
        tooltip = timeframeString .. " " .. string.format(GetString(MM_GRAPH_TIP), currentGuild, currentSeller,
          nameString, item.quant, currentBuyer, stringPrice)
      end
    else
      tooltip = stringPrice .. MM_COIN_ICON_NO_SPACE
    end
    salesPoints[#salesPoints + 1] = { item.timestamp, individualSale, MasterMerchant.guildColor[currentGuild], tooltip, currentSeller }
  end

  local function ProcessSalesInfo(item)
    local individualSale = item.price / item.quant
    countSold = (countSold or 0) + item.quant
    avgPrice = (avgPrice or 0) + item.price
    legitSales = (legitSales or 0) + 1
    lowestPrice = lowestPrice and math.min(lowestPrice, individualSale) or individualSale
    highestPrice = highestPrice and math.max(highestPrice, individualSale) or individualSale
    if generateGraph then ProcessDots(individualSale, item) end
  end

  local function ProcessBonanzaSale(item)
    bonanzaItemCount = (bonanzaItemCount or 0) + item.quant
    bonanzaPrice = (bonanzaPrice or 0) + item.price
    bonanzaListings = (bonanzaListings or 0) + 1
  end

  local function BuildOutliersList(item)
    outliersList[#outliersList + 1] = item
  end

  local function BuildStatsData(item)
    local individualSale = item.price / item.quant
    statsData[#statsData + 1] = individualSale
  end

  local function SortStatsData()
    table.sort(statsData)
  end

  local function SortBonanzaStatsData()
    table.sort(bonanzaStatsData)
  end

  local function BuildGraphInfo()
    graphInfo = {
      oldestTime = oldestTime,
      low = lowestPrice,
      high = highestPrice,
      points = salesPoints
    }
  end

  local function CalculateDaysHistory()
    if daysRange == 10000 then
      local quotient, remainder = math.modf((GetTimeStamp() - oldestTime) / ZO_ONE_DAY_IN_SECONDS)
      daysHistory = quotient + math.floor(0.5 + remainder)
    end
  end

  local function ProcessSalesData(salesData)
    for _, item in pairs(salesData) do
      currentGuild = internal:GetGuildNameByIndex(item.guild)
      currentBuyer = internal:GetAccountNameByIndex(item.buyer)
      currentSeller = internal:GetAccountNameByIndex(item.seller)
      if not IsNameInBlacklist() then
        if daysRange == 10000 or item.timestamp > timeCheck then
          if oldestTime == nil or oldestTime > item.timestamp then oldestTime = item.timestamp end
          if ignoreOutliers then BuildOutliersList(item)
          else ProcessSalesInfo(item) end
          BuildStatsData(item)
        end
      end
    end
  end

  local function ProcessBonanzaList(bonanzaList)
    bonanzaList, bonanzaStatsData = RemoveListingsPerBlacklist(bonanzaList)
    for _, item in pairs(bonanzaList) do
      if not IsNameInBlacklist() then
        ProcessBonanzaSale(item)
      end
    end
  end

  local function LoadSalesData()
    versionData = sales_data[itemID][itemIndex]
    salesData = versionData['sales']
    nameString = versionData.itemDesc
    oldestTime = versionData.oldestTime
    newestTime = versionData.newestTime
    CalculateDaysHistory()
    ProcessSalesData(salesData)
    SortStatsData()
  end

  local function LoadPriceInfo()
    itemInfo = MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange]
    avgPrice = itemInfo.avgPrice
    legitSales = itemInfo.numSales
    daysHistory = itemInfo.numDays
    countSold = itemInfo.numItems
    numVouchers = itemInfo.numVouchers
    local graphInformation = itemInfo.graphInfo
    if graphInformation then
      oldestTime = graphInformation.oldestTime
      lowestPrice = graphInformation.low
      highestPrice = graphInformation.high
      salesPoints = graphInformation.points
    end
  end

  local function LoadBonanzaInfo()
    itemInfo = MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange]
    bonanzaPrice = itemInfo.bonanzaPrice
    bonanzaListings = itemInfo.bonanzaListings
    bonanzaItemCount = itemInfo.bonanzaItemCount
  end

  if not MasterMerchant.isInitialized or not itemLink then
    return { avgPrice = avgPrice, numSales = legitSales, numDays = daysHistory, numItems = countSold,
             bonanzaPrice = bonanzaPrice, bonanzaListings = bonanzaListings, bonanzaItemCount = bonanzaItemCount,
             numVouchers = numVouchers, graphInfo = graphInfo }
  end

  if not MasterMerchant.systemSavedVariables.showGraph then
    generateGraph = false
  end

  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  local itemType, specializedItemType = GetItemLinkItemType(itemLink)

  local timeCheck, daysRange = self:CheckTimeframe()
  if daysRange ~= 10000 then daysHistory = daysRange end

  if hasSales and (not hasPriceInfo or generateGraph) then
    LoadSalesData()
  end

  if hasPriceInfo and not generateGraph then
    LoadPriceInfo()
  end

  if hasListings and not (hasBonanza or averageOnly) then
    bonanzaList = listings_data[itemID][itemIndex]['sales']
    ProcessBonanzaList(bonanzaList)
    SortBonanzaStatsData()
    if bonanzaListings and bonanzaListings < 1 then
      bonanzaPrice = nil
      bonanzaListings = nil
      bonanzaItemCount = nil
    end
    if bonanzaListings and bonanzaListings >= 1 then
      bonanzaPrice = bonanzaPrice / bonanzaItemCount
      if bonanzaPrice < 0.01 then bonanzaPrice = 0.01 end
    end
  end

  if hasBonanza and not cacheBonanza then
    LoadBonanzaInfo()
  end

  if itemType == ITEMTYPE_MASTER_WRIT and MasterMerchant.systemSavedVariables.includeVoucherAverage then
    numVouchers = MasterMerchant_Internal:GetVoucherCountByItemLink(itemLink)
  end

  if hasSales and (not hasPriceInfo or generateGraph or cacheBonanza) then
    itemInfo = {
      avgPrice = avgPrice,
      numSales = legitSales,
      numDays = daysHistory,
      numItems = countSold,
      bonanzaPrice = bonanzaPrice,
      bonanzaListings = bonanzaListings,
      bonanzaItemCount = bonanzaItemCount,
      numVouchers = numVouchers,
    }
    if legitSales and legitSales > 1500 and salesPoints then
      BuildGraphInfo()
    end
    MasterMerchant:SetItemCacheById(itemID, itemIndex, daysRange, itemInfo)
  end

  if salesPoints then
    BuildGraphInfo()
  end

  return { avgPrice = avgPrice, numSales = legitSales, numDays = daysHistory, numItems = countSold,
           bonanzaPrice = bonanzaPrice, bonanzaListings = bonanzaListings, bonanzaItemCount = bonanzaItemCount,
           numVouchers = numVouchers, graphInfo = graphInfo }
end
