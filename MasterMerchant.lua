-- MasterMerchant Main Addon File
-- Last Updated September 15, 2014
-- Written July 2014 by Dan Stone (@khaibit) - dankitymao@gmail.com
-- Extended Feb 2015 - Oct 2016 by (@Philgo68) - Philgo68@gmail.com
-- Released under terms in license accompanying this file.
-- Distribution without license is prohibited!
local LAM = LibAddonMenu2
local LMP = LibMediaProvider
local internal = _G["LibGuildStore_Internal"]
local sales_data = _G["LibGuildStore_SalesData"]
local sr_index = _G["LibGuildStore_SalesIndex"]
local listings_data = _G["LibGuildStore_ListingsData"]
local purchases_data = _G["LibGuildStore_PurchaseData"]

local OriginalSetupPendingPost

--[[ can not use MasterMerchant.itemsViewSize for example
because that will not be available this early.
]]--
local ITEMS = 'items_vs'
local GUILDS = 'guild_vs'
local LISTINGS = 'listings_vs'
local PURCHASES = 'purchases_vs'
local REPORTS = 'reports_vs'

local CSA_EVENT_SMALL_TEXT = 1
local CSA_EVENT_LARGE_TEXT = 2
local CSA_EVENT_COMBINED_TEXT = 3
local CSA_EVENT_NO_TEXT = 4
local CSA_EVENT_RAID_COMPLETE_TEXT = 5

--[[
used to temporarily ignore sales that are so new
the ammount of time in seconds causes the UI to say
the sale was made 1657 months ago or 71582789 minutes ago.
]]--
MasterMerchant.oneYearInSeconds = ZO_ONE_MONTH_IN_SECONDS * 12

------------------------------
--- MM Stuff               ---
------------------------------
function MasterMerchant:SetFontListChoices()
  if MasterMerchant.effective_lang == "pl" then
    MasterMerchant.fontListChoices = { "Arial Narrow", "Consolas",
                                       "Futura Condensed", "Futura Condensed Bold",
                                       "Futura Condensed Light", "Trajan Pro", "Univers 55",
                                       "Univers 57", "Univers 67", }
    if not MasterMerchant:is_in(MasterMerchant.systemSavedVariables.windowFont, MasterMerchant.fontListChoices) then
      MasterMerchant.systemSavedVariables.windowFont = "Univers 57"
    end
  else
    MasterMerchant.fontListChoices = LMP:List(LMP.MediaType.FONT)
    -- /script d(LibMediaProvider:List(LibMediaProvider.MediaType.FONT))
  end
end

function MasterMerchant.CenterScreenAnnounce_AddMessage(eventId, category, ...)
  local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(category)
  messageParams:ConvertOldParams(...)
  messageParams:SetLifespanMS(3500)
  CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
end

function MasterMerchant:setupGuildColors()
  MasterMerchant:dm("Debug", "setupGuildColors")
  local nextGuild = 0
  while nextGuild < GetNumGuilds() do
    nextGuild = nextGuild + 1
    local nextGuildID = GetGuildId(nextGuild)
    local nextGuildName = GetGuildName(nextGuildID)
    if nextGuildName ~= MM_STRING_EMPTY or nextGuildName ~= nil then
      local r, g, b = GetChatCategoryColor(CHAT_CHANNEL_GUILD_1 - 3 + nextGuild)
      self.guildColor[nextGuildName] = { r, g, b };
    else
      self.guildColor[nextGuildName] = { 255, 255, 255 };
    end
  end
end

function MasterMerchant:CheckTimeframe()
  -- setup focus info
  local daysRange = 10000
  local dayCutoff = GetTimeStamp()
  if not MasterMerchant.isInitialized then
    return dayCutoff - (daysRange * ZO_ONE_DAY_IN_SECONDS), daysRange
  end
  local range = MasterMerchant.systemSavedVariables.defaultDays
  dayCutoff = MasterMerchant.dateRanges[MM_DATERANGE_TODAY].startTimestamp

  if IsControlKeyDown() and IsShiftKeyDown() then
    range = MasterMerchant.systemSavedVariables.ctrlShiftDays
  elseif IsControlKeyDown() then
    range = MasterMerchant.systemSavedVariables.ctrlDays
  elseif IsShiftKeyDown() then
    range = MasterMerchant.systemSavedVariables.shiftDays
  end

  -- 10000 for numDays is more or less like saying it is undefined
  if range == GetString(MM_RANGE_NONE) then return -1, -1 end
  if range == GetString(MM_RANGE_ALL) then daysRange = 10000 end
  if range == GetString(MM_RANGE_FOCUS1) then daysRange = MasterMerchant.systemSavedVariables.focus1 end
  if range == GetString(MM_RANGE_FOCUS2) then daysRange = MasterMerchant.systemSavedVariables.focus2 end
  if range == GetString(MM_RANGE_FOCUS3) then daysRange = MasterMerchant.systemSavedVariables.focus3 end

  return dayCutoff - (daysRange * ZO_ONE_DAY_IN_SECONDS), daysRange
end

function MasterMerchant:IsInBlackList(str)
  if MasterMerchant.systemSavedVariables.blacklist == MM_STRING_EMPTY then return false end
  return zo_plainstrfind(MasterMerchant.systemSavedVariables.blacklist, str)
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

local stats = {}

function stats.CleanUnitPrice(salesRecord)
  return salesRecord.price / salesRecord.quant
end

function stats.GetSortedSales(t)
  local newTable = { }
  for _, v in internal:spairs(t, function(a, b) return stats.CleanUnitPrice(a) < stats.CleanUnitPrice(b) end) do
    newTable[#newTable + 1] = v
  end
  return newTable
end

-- Get the mean value of a table
function stats.mean(t)
  local sum = 0
  local count = 0

  for _, individualSale in pairs(t) do
    sum = sum + individualSale
    count = count + 1
  end

  return (sum / count), count, sum
end

-- Get the mode of a table.  Returns a table of values.
-- Works on anything (not just numbers).
function stats.mode(t)
  local counts = {}

  for _, individualSale in pairs(t) do
    if counts[individualSale] == nil then
      counts[individualSale] = 1
    else
      counts[individualSale] = counts[individualSale] + 1
    end
  end

  local biggestCount = 0

  for _, v in pairs(counts) do
    if v > biggestCount then
      biggestCount = v
    end
  end

  local temp = {}

  for k, v in pairs(counts) do
    if v == biggestCount then
      table.insert(temp, k)
    end
  end

  return temp
end

--[[ Get the median of a table.
Modified: Requires the table to be sorted already
]]--
--(190 –z = (x – μ) / σ 150) / 25 = 1.6.
function stats.median(t, index, range)
  local temp = {}
  local hasRange = index ~= nil and range ~= nil

  if hasRange then
    for i = index, range do
      local individualSale = t[i]
      temp[#temp + 1] = individualSale
    end
  else
    temp = t
  end
  table.sort(temp)

  -- If we have an even number of table elements or odd.
  if math.fmod(#temp, 2) == 0 then
    -- return mean value of middle two elements
    return (temp[#temp / 2] + temp[(#temp / 2) + 1]) / 2
  else
    -- return middle element
    return temp[zo_ceil(#temp / 2)]
  end
end

-- /script d({MasterMerchant.stats.mean(MasterMerchant.a_test)})
function stats.standardDeviation(t)
  local mean
  local vm
  local sum = 0
  local count = 0
  local result

  mean = stats.mean(t)

  for _, individualSale in pairs(t) do
    if type(individualSale) == 'number' then
      vm = individualSale - mean
      sum = sum + (vm * vm)
      count = count + 1
    end
  end

  result = math.sqrt(sum / (count - 1))

  return result
end

function stats.zscore(individualSale, mean, standardDeviation)
  return (individualSale - mean) / standardDeviation
end

function stats.maxmin(t)
  local max = -math.huge
  local min = math.huge

  for _, individualSale in pairs(t) do
    max = zo_max(max, individualSale)
    min = zo_min(min, individualSale)
  end

  return max, min
end

function stats.range(t)
  local highest, lowest = stats.maxmin(t)
  return highest - lowest
end

function stats.getMiddleIndex(count)
  local evenNumber = false
  local quotient, remainder = math.modf(count / 2)
  if remainder == 0 then evenNumber = true end
  local middleIndex = quotient + math.floor(0.5 + remainder)
  return middleIndex, evenNumber
end

--[[ we do not use this function in there are less then three
items in the table.

middleIndex will be rounded up when odd
]]--
function stats.interquartileRange(statsData)
  local statsDataCount = #statsData
  local middleIndex, evenNumber = stats.getMiddleIndex(statsDataCount)
  local quartile1, quartile3
  -- 1,2,3,4
  if evenNumber then
    quartile1 = stats.median(statsData, 1, middleIndex)
    quartile3 = stats.median(statsData, middleIndex + 1, #statsData)
  else
    -- 1,2,3,4,5
    -- odd number
    quartile1 = stats.median(statsData, 1, middleIndex)
    quartile3 = stats.median(statsData, middleIndex, #statsData)
  end
  return quartile1, quartile3, quartile3 - quartile1
end

function stats.evaluateQuartileRangeTable(list, quartile1, quartile3, quartileRange)
  local dataList = { }
  local oldestTime = nil
  local newestTime = nil

  for _, item in pairs(list) do
    local individualSale = item.price / item.quant
    if (individualSale < (quartile1 - 1.5 * quartileRange)) or (individualSale > (quartile3 + 1.5 * quartileRange)) then
      --Debug(string.format("%s : %s was not in range",k,individualSale))
    else
      --Debug(string.format("%s : %s was in range",k,individualSale))
      if oldestTime == nil or oldestTime > item.timestamp then oldestTime = item.timestamp end
      if newestTime == nil or newestTime < item.timestamp then newestTime = item.timestamp end
      table.insert(dataList, item)
    end
  end
  return dataList, oldestTime, newestTime
end

MasterMerchant.stats = stats
-- /script MasterMerchant:GetTooltipStats("|H1:item:54173:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", true)
-- /script MasterMerchant:dm("Debug", MasterMerchant:GetTooltipStats("|H1:item:54484:369:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", true))
-- GetItemLinkItemId("|H0:item:54484:369:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h")
-- 54484  50:16:4:0:0
-- |H1:item:54484:369:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h 50 sales
-- |H1:item:54173:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h gold mat 3000+ sales
-- /script LibPrice.ItemLinkToPriceGold("|H1:item:54173:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", "mm")
-- LibGuildStore_Internal.GetOrCreateIndexFromLink("|H0:item:54484:369:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h")
-- MasterMerchant:GetTooltipStats(54484, "50:16:4:0:0", false, true)
-- Computes the weighted moving average across available data
-- /script MasterMerchant.itemInformationCache = {}
-- /script MasterMerchant:ClearPriceCacheById(54173, "1:0:5:0:0")
-- /script MasterMerchant:ClearBonanzaCachePriceById(54173, "1:0:5:0:0")
-- Vamp Fang |H1:item:64210:177:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h -- 1 bonanza listing no price to chat
-- hide scraps |H1:item:71239:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h -- 1 bonanza listing no price to chat
function MasterMerchant:GetTooltipStats(itemLink, averageOnly, generateGraph)
  -- MasterMerchant:dm("Debug", "GetTooltipStats")
  -- MasterMerchant:dm("Debug", itemLink)
  -- 10000 for numDays is more or less like saying it is undefined, or all
  --[[TODO why is there a days range of 10000. I get that it kinda means
  all days but the daysHistory seems to be the actual number to be using.
  For example when you press SHIFT or CTRL then daysHistory and daysRange
  are the same. However, when you do not modify the data, then daysRange
  is 10000 and daysHistory is however many days you have.

  Answer: because daysRange is 10000 the previous authors multiplied that with
  ZO_ONE_DAY_IN_SECONDS to ensure that all the sales were displayed.
  ]]--
  -- setup early local variables
  local outliersList = {}
  local bonanzaList = {}
  local statsData = {}
  local bonanzaStatsData = {}
  local statsDataCount
  local bonanzaStatsDataCount
  local versionData
  local salesData

  local avgPrice = nil
  local legitSales = nil
  local daysHistory = 10000
  local countSold = nil
  local bonanzaPrice = nil
  local bonanzaListings = nil
  local bonanzaItemCount = nil

  local oldestTime = nil
  local newestTime = nil
  local lowPrice = nil
  local highPrice = nil
  local salesPoints = nil

  local currentGuild = nil
  local currentBuyer = nil
  local currentSeller = nil
  local nameString = nil
  local salesDetails = true
  averageOnly = averageOnly or false
  local nameInBlacklist = false
  local ignoreOutliers = nil
  local numVouchers = 0
  local graphInfo = nil
  local cacheBonanza = false

  -- set timeCheck and daysRange for cache and tooltips
  local timeCheck, daysRange = self:CheckTimeframe()
  if daysRange ~= 10000 then daysHistory = daysRange end

  local returnData = { ['avgPrice'] = avgPrice, ['numSales'] = legitSales, ['numDays'] = daysHistory, ['numItems'] = countSold,
                       ['bonanzaPrice'] = bonanzaPrice, ['bonanzaListings'] = bonanzaListings, ['bonanzaItemCount'] = bonanzaItemCount, ['numVouchers'] = numVouchers,
                       ['graphInfo'] = graphInfo }

  if not MasterMerchant.isInitialized then return returnData end
  if not itemLink then return returnData end

  if not MasterMerchant.systemSavedVariables.showGraph then
    generateGraph = false
  end

  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  local itemType, specializedItemType = GetItemLinkItemType(itemLink)

  local function IsNameInBlacklist()
    if MasterMerchant.blacklistTable == nil then return false end
    if currentGuild and MasterMerchant.blacklistTable[currentGuild] then return true end
    if currentBuyer and MasterMerchant.blacklistTable[currentBuyer] then return true end
    if currentSeller and MasterMerchant.blacklistTable[currentSeller] then return true end
    return false
  end

  local function GetTimeString(timestamp)
    local formattedString = nil
    local quotient, remainder = math.modf((GetTimeStamp() - timestamp) / ZO_ONE_DAY_IN_SECONDS)
    if MasterMerchant.systemSavedVariables.useFormatedTime then
      formattedString = MasterMerchant.TextTimeSince(timestamp)
    else
      if quotient == 0 then
        formattedString = GetString(MM_INDEX_TODAY)
      elseif quotient == 1 then
        formattedString = GetString(MM_INDEX_YESTERDAY)
      elseif quotient >= 2 then
        formattedString = string.format(GetString(SK_TIME_DAYSAGO), quotient)
      end
    end
    return formattedString
  end

  -- local function for processing the dots on the graph
  local function ProcessDots(individualSale, item)
    salesPoints = salesPoints or {}
    local tooltip = nil
    local timeframeString = ""
    local stringPrice = self.LocalizedNumber(individualSale)
    --[[ salesDetails means to add a detailed tooltip to the dot ]]--
    if salesDetails then
      timeframeString = GetTimeString(item.timestamp)
      if item.quant == 1 then
        tooltip = timeframeString .. " " .. string.format(GetString(MM_GRAPH_TIP_SINGLE), currentGuild,
          currentSeller, nameString, currentBuyer, stringPrice)
      else
        tooltip = timeframeString .. " " .. string.format(GetString(MM_GRAPH_TIP), currentGuild, currentSeller,
          nameString, item.quant, currentBuyer, stringPrice)
      end
    else
      -- not detailed
      tooltip = stringPrice .. MM_COIN_ICON_NO_SPACE
    end
    salesPoints[#salesPoints + 1] = { item.timestamp, individualSale, MasterMerchant.guildColor[currentGuild], tooltip, currentSeller }
  end

  local function ProcessSalesInfo(item)
    local individualSale = item.price / item.quant
    if countSold == nil then countSold = 0 end
    countSold = countSold + item.quant
    if avgPrice == nil then avgPrice = 0 end
    avgPrice = avgPrice + item.price
    if legitSales == nil then legitSales = 0 end
    legitSales = legitSales + 1
    if lowPrice == nil then lowPrice = individualSale else lowPrice = zo_min(lowPrice, individualSale) end
    if highPrice == nil then highPrice = individualSale else highPrice = zo_max(highPrice, individualSale) end
    if generateGraph then ProcessDots(individualSale, item) end -- end skip dots
  end

  local function ProcessBonanzaSale(item)
    if bonanzaItemCount == nil then bonanzaItemCount = 0 end
    if bonanzaPrice == nil then bonanzaPrice = 0 end
    if bonanzaListings == nil then bonanzaListings = 0 end
    bonanzaItemCount = bonanzaItemCount + item.quant
    bonanzaPrice = bonanzaPrice + item.price
    bonanzaListings = bonanzaListings + 1
  end

  local function BuildOutliersList(item)
    outliersList[#outliersList + 1] = item
  end

  --[[Reminder the Bonanza Stats Data is built in
  RemoveListingsPerBlacklist. We just have to sort
  the Bonanza Stats Data.
  ]]--

  local function BuildStatsData(item)
    local individualSale = item.price / item.quant
    statsData[#statsData + 1] = individualSale
  end

  local function SortStatsData()
    statsDataCount = #statsData
    table.sort(statsData)
  end

  local function SortBonanzaStatsData()
    bonanzaStatsDataCount = #bonanzaStatsData
    table.sort(bonanzaStatsData)
  end

  -- 10000 for numDays is more or less like saying it is undefined
  --[[TODO why is there a days range of 10000. I get that it kinda means
  all days but the daysHistory seems to be the actual number to be using.
  For example when you press SHIFT or CTRL then daysHistory and daysRange
  are the same. However, when you do not modify the data, then daysRange
  is 10000 and daysHistory is however many days you have.
  ]]--

  salesDetails = MasterMerchant.systemSavedVariables.displaySalesDetails
  ignoreOutliers = MasterMerchant.systemSavedVariables.trimOutliers

  -- make sure we have a list of sales to work with
  local hasSales = MasterMerchant:itemIDHasSales(itemID, itemIndex)
  local hasListings = MasterMerchant:itemIDHasListings(itemID, itemIndex)
  local hasPriceInfo = MasterMerchant:ItemCacheHasPriceInfoById(itemID, itemIndex, daysRange)
  local hasGraph = MasterMerchant:ItemCacheHasGraphInfoById(itemID, itemIndex, daysRange)
  local hasBonanza = MasterMerchant:ItemCacheHasBonanzaInfoById(itemID, itemIndex, daysRange)
  local createGraph = not hasGraph and generateGraph
  if hasSales and (not hasPriceInfo or createGraph) then
    versionData = sales_data[itemID][itemIndex]
    salesData = versionData['sales']
    nameString = versionData.itemDesc
    oldestTime = versionData.oldestTime
    newestTime = versionData.newestTime

    --[[1-2-2021 Our sales data is now ready to be trimmed if
    trim outliers is active.
    ]]--
    --[[1-2-2021 We have determined that there is more then one sale
    in the table and the dayshistory using the daysrange.

    We can now trim outliers if the uses has that active
    ]]--

    --[[1-2-2021 First we will see if the data is already
    calculated.

    1-2-2021 Needs updated

    local lookupDataFound = dataPresent(itemID, itemIndex, daysRange)

    12-11-2022 Old 'daysHistory = daysRange' moved above for tooltips
    ]]--
    if (daysRange == 10000) then
      local quotient, remainder = math.modf((GetTimeStamp() - oldestTime) / ZO_ONE_DAY_IN_SECONDS)
      daysHistory = quotient + math.floor(0.5 + remainder)
    end

    local useDaysRange = daysRange ~= 10000
    oldestTime = nil
    -- start loop for non outliers
    for _, item in pairs(salesData) do
      currentGuild = internal:GetGuildNameByIndex(item.guild)
      currentBuyer = internal:GetAccountNameByIndex(item.buyer)
      currentSeller = internal:GetAccountNameByIndex(item.seller)
      nameInBlacklist = IsNameInBlacklist()
      if not nameInBlacklist then
        if useDaysRange then
          local validTimeDate = item.timestamp > timeCheck
          if validTimeDate then
            if oldestTime == nil or oldestTime > item.timestamp then oldestTime = item.timestamp end
            if ignoreOutliers then BuildOutliersList(item)
            else ProcessSalesInfo(item) end
            BuildStatsData(item)
          end
        else
          if oldestTime == nil or oldestTime > item.timestamp then oldestTime = item.timestamp end
          if ignoreOutliers then BuildOutliersList(item)
          else ProcessSalesInfo(item) end
          BuildStatsData(item)
        end
      end
    end -- end for loop for non outliers
    SortStatsData()
    local mean = stats.mean(statsData)
    local standardDeviation = stats.standardDeviation(statsData)
    if ignoreOutliers and #outliersList >= 6 then
      local quartile1, quartile3, quartileRange = stats.interquartileRange(statsData)
      oldestTime = nil
      for _, item in pairs(outliersList) do
        currentGuild = internal:GetGuildNameByIndex(item.guild)
        currentBuyer = internal:GetAccountNameByIndex(item.buyer)
        currentSeller = internal:GetAccountNameByIndex(item.seller)
        local individualSale = item.price / item.quant
        local withinQuartileRange = not (individualSale < (quartile1 - 1.5 * quartileRange)) or (individualSale > (quartile3 + 1.5 * quartileRange))
        local zscore = stats.zscore(individualSale, mean, standardDeviation)
        local withinZscoreRange = zscore > -1.960 and zscore < 1.960
        if withinQuartileRange and withinZscoreRange then
          -- within range
          if useDaysRange then
            local validTimeDate = item.timestamp > timeCheck
            if validTimeDate then
              if oldestTime == nil or oldestTime > item.timestamp then oldestTime = item.timestamp end
              ProcessSalesInfo(item)
            end
          else
            if oldestTime == nil or oldestTime > item.timestamp then oldestTime = item.timestamp end
            ProcessSalesInfo(item)
          end
        end
      end -- end trim outliers loop if more then 6
    elseif ignoreOutliers and #outliersList < 6 then
      oldestTime = nil
      for _, item in pairs(outliersList) do
        currentGuild = internal:GetGuildNameByIndex(item.guild)
        currentBuyer = internal:GetAccountNameByIndex(item.buyer)
        currentSeller = internal:GetAccountNameByIndex(item.seller)
        -- within range
        if useDaysRange then
          local validTimeDate = item.timestamp > timeCheck
          if validTimeDate then
            if oldestTime == nil or oldestTime > item.timestamp then oldestTime = item.timestamp end
            ProcessSalesInfo(item)
          end
        else
          if oldestTime == nil or oldestTime > item.timestamp then oldestTime = item.timestamp end
          ProcessSalesInfo(item)
        end
      end -- end trim outliers loop if less then 6
    end -- end trim outliers
    if legitSales and legitSales >= 1 then
      avgPrice = avgPrice / countSold
      --[[found an average price of 0.07 which X 200 is 14g
      even 0.01 X 200 is 2g
      ]]--
      if avgPrice < 0.01 then avgPrice = 0.01 end
    end
  end
  if hasPriceInfo and not createGraph then
    local itemInfo = MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange]
    avgPrice = itemInfo.avgPrice
    legitSales = itemInfo.numSales
    daysHistory = itemInfo.numDays
    countSold = itemInfo.numItems
    numVouchers = itemInfo.numVouchers
    local graphInformation = itemInfo.graphInfo
    if graphInformation then
      oldestTime = graphInformation.oldestTime
      lowPrice = graphInformation.low
      highPrice = graphInformation.high
      salesPoints = graphInformation.points
    end
  end
  if hasListings and (not hasBonanza and not averageOnly) then
    bonanzaList = listings_data[itemID][itemIndex]['sales']
    bonanzaList, bonanzaStatsData = RemoveListingsPerBlacklist(bonanzaList)
    SortBonanzaStatsData()
    local bonanzaMean = stats.mean(bonanzaStatsData)
    local bonanzaStandardDeviation = stats.standardDeviation(bonanzaStatsData)
    if #bonanzaList >= 6 then
      local bonanzaQuartile1, bonanzaQuartile3, bonanzaQuartileRange = stats.interquartileRange(bonanzaStatsData)
      for _, item in pairs(bonanzaList) do
        local individualSale = item.price / item.quant
        local withinQuartileRange = not (individualSale < (bonanzaQuartile1 - 1.5 * bonanzaQuartileRange)) or (individualSale > (bonanzaQuartile3 + 1.5 * bonanzaQuartileRange))
        local zscore = stats.zscore(individualSale, bonanzaMean, bonanzaStandardDeviation)
        local withinZscoreRange = zscore > -1.960 and zscore < 1.960
        if withinQuartileRange and withinZscoreRange then
          ProcessBonanzaSale(item)
        end
      end -- end bonanza loop
    else
      for _, item in pairs(bonanzaList) do
        ProcessBonanzaSale(item)
      end -- end bonanza loop
    end
    if (bonanzaItemCount and bonanzaItemCount < 1) or (bonanzaListings and bonanzaListings < 1) then
      if bonanzaPrice == nil then
        MasterMerchant:dm("Warn", "Bonanza information seems incomplete")
        MasterMerchant:dm("Debug", "bonanzaList")
        MasterMerchant:dm("Debug", bonanzaList)
        MasterMerchant:dm("Debug", "bonanzaPrice")
        MasterMerchant:dm("Debug", bonanzaPrice)
        MasterMerchant:dm("Debug", "bonanzaListings")
        MasterMerchant:dm("Debug", bonanzaListings)
        MasterMerchant:dm("Debug", "bonanzaItemCount")
        MasterMerchant:dm("Debug", bonanzaItemCount)
      end
      bonanzaPrice = nil
      bonanzaListings = nil
      bonanzaItemCount = nil
    end
    if bonanzaListings and bonanzaListings >= 1 then
      bonanzaPrice = bonanzaPrice / bonanzaItemCount
    end
    --[[found an average price of 0.07 which X 200 is 14g
    even 0.01 X 200 is 2g
    ]]--
    if bonanzaPrice and bonanzaPrice < 0.01 then bonanzaPrice = 0.01 end
    if bonanzaPrice then cacheBonanza = true end
  end
  if hasBonanza and not cacheBonanza then
    local itemInfo = MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange]
    bonanzaPrice = itemInfo.bonanzaPrice
    bonanzaListings = itemInfo.bonanzaListings
    bonanzaItemCount = itemInfo.bonanzaItemCount
  end
  if itemType == ITEMTYPE_MASTER_WRIT and MasterMerchant.systemSavedVariables.includeVoucherAverage then
    numVouchers = MasterMerchant_Internal:GetVoucherCountByItemLink(itemLink)
  end
  if hasSales and (not hasPriceInfo or createGraph or cacheBonanza) then
    local itemInfo = {
      avgPrice = avgPrice,
      numSales = legitSales,
      numDays = daysHistory,
      numItems = countSold,
      bonanzaPrice = bonanzaPrice,
      bonanzaListings = bonanzaListings,
      bonanzaItemCount = bonanzaItemCount,
      numVouchers = numVouchers,
    }
    graphInfo = { oldestTime = oldestTime, low = lowPrice, high = highPrice, points = salesPoints }
    if legitSales and legitSales > 1500 and salesPoints then
      itemInfo.graphInfo = graphInfo
    end
    MasterMerchant:SetItemCacheById(itemID, itemIndex, daysRange, itemInfo)
  end
  if salesPoints then
    graphInfo = { oldestTime = oldestTime, low = lowPrice, high = highPrice, points = salesPoints }
  end
  returnData = { ['avgPrice'] = avgPrice, ['numSales'] = legitSales, ['numDays'] = daysHistory, ['numItems'] = countSold,
                 ['bonanzaPrice'] = bonanzaPrice, ['bonanzaListings'] = bonanzaListings, ['bonanzaItemCount'] = bonanzaItemCount, ['numVouchers'] = numVouchers,
                 ['graphInfo'] = graphInfo }
  return returnData
end

function MasterMerchant:itemIDHasSales(itemID, itemIndex)
  local hasSales = sales_data[itemID] and sales_data[itemID][itemIndex] and sales_data[itemID][itemIndex]['sales']
  if hasSales then
    local salesCount = sales_data[itemID][itemIndex].totalCount
    return salesCount > 0
  end
  return false
end

function MasterMerchant:itemLinkHasSales(itemLink)
  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  return MasterMerchant:itemIDHasSales(itemID, itemIndex)
end

function MasterMerchant:itemIDHasListings(itemID, itemIndex)
  local hasListings = listings_data[itemID] and listings_data[itemID][itemIndex] and listings_data[itemID][itemIndex]['sales']
  if hasListings then
    local listingsCount = listings_data[itemID][itemIndex].totalCount
    return listingsCount > 0
  end
  return false
end

function MasterMerchant:itemLinkHasListings(itemLink)
  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  return MasterMerchant:itemIDHasListings(itemID, itemIndex)
end

function MasterMerchant:ItemCacheStats(itemLink)
  local timeCheck, daysRange = self:CheckTimeframe()
  if MasterMerchant:ItemCacheHasInfoByItemLink(itemLink, daysRange) then
    local itemID = GetItemLinkItemId(itemLink)
    local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
    return MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange]
  end
  return MasterMerchant:GetTooltipStats(itemLink, true, false)
end

function MasterMerchant:ItemCacheHasGraphInfoById(theIID, itemIndex, daysRange)
  local itemInfo = MasterMerchant.itemInformationCache[theIID] and MasterMerchant.itemInformationCache[theIID][itemIndex] and MasterMerchant.itemInformationCache[theIID][itemIndex][daysRange]
  if itemInfo then
    if MasterMerchant.itemInformationCache[theIID][itemIndex][daysRange].graphInfo then return true end
  end
  return false
end

function MasterMerchant:ItemCacheHasPriceInfoById(theIID, itemIndex, daysRange)
  local itemInfo = MasterMerchant.itemInformationCache[theIID] and MasterMerchant.itemInformationCache[theIID][itemIndex] and MasterMerchant.itemInformationCache[theIID][itemIndex][daysRange]
  if itemInfo then
    if MasterMerchant.itemInformationCache[theIID][itemIndex][daysRange].avgPrice then return true end
  end
  return false
end

function MasterMerchant:ItemCacheHasBonanzaInfoById(theIID, itemIndex, daysRange)
  local itemInfo = MasterMerchant.itemInformationCache[theIID] and MasterMerchant.itemInformationCache[theIID][itemIndex] and MasterMerchant.itemInformationCache[theIID][itemIndex][daysRange]
  if itemInfo then
    if MasterMerchant.itemInformationCache[theIID][itemIndex][daysRange].bonanzaPrice then return true end
  end
  return false
end

function MasterMerchant:ItemCacheHasInfoByItemLink(itemLink, daysRange)
  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  return MasterMerchant:ItemCacheHasPriceInfoById(itemID, itemIndex, daysRange)
end

function MasterMerchant:SetItemCacheById(itemID, itemIndex, daysRange, itemInfo)
  MasterMerchant.itemInformationCache[itemID] = MasterMerchant.itemInformationCache[itemID] or {}
  MasterMerchant.itemInformationCache[itemID][itemIndex] = MasterMerchant.itemInformationCache[itemID][itemIndex] or {}
  MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange] = itemInfo
end

function MasterMerchant:SetItemCacheByItemLink(itemLink, daysRange, itemInfo)
  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  MasterMerchant:SetItemCacheById(itemID, itemIndex, daysRange, itemInfo)
end

function MasterMerchant:ClearPriceCacheById(itemID, itemIndex)
  local itemInfo = MasterMerchant.itemInformationCache[itemID] and MasterMerchant.itemInformationCache[itemID][itemIndex]
  if itemInfo then
    for daysRange, _ in pairs(MasterMerchant.itemInformationCache[itemID][itemIndex]) do
      MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange].avgPrice = nil
      MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange].numSales = nil
      MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange].numDays = nil
      MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange].numItems = nil
      MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange].numVouchers = nil
      MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange].graphInfo = nil
    end
  end
end

function MasterMerchant:ClearItemCacheByItemLink(itemLink)
  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  MasterMerchant:ClearPriceCacheById(itemID, itemIndex)
end

function MasterMerchant:ClearBonanzaCachePriceById(itemID, itemIndex)
  local itemInfo = MasterMerchant.itemInformationCache[itemID] and MasterMerchant.itemInformationCache[itemID][itemIndex]
  if itemInfo then
    for daysRange, _ in pairs(MasterMerchant.itemInformationCache[itemID][itemIndex]) do
      MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange].bonanzaPrice = nil
      MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange].bonanzaListings = nil
      MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange].bonanzaItemCount = nil
    end
  end
end

-- /script MasterMerchant:ClearBonanzaPriceCacheByItemLink("|H1:item:54173:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h")
function MasterMerchant:ClearBonanzaPriceCacheByItemLink(itemLink)
  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  MasterMerchant:ClearBonanzaCachePriceById(itemID, itemIndex)
end

function MasterMerchant:ResetItemInformationCache()
  MasterMerchant.itemInformationCache = { }
end

function MasterMerchant:ValidInfoForCache(avgPrice, numSales, numDays, numItems)
  if avgPrice == nil or numSales == nil or numDays == nil or numItems == nil then
    return false
  end
  return true
end

-- /script d(MasterMerchant:GetTradeSkillInformation("|H1:item:33825:3:1:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:0|h|h"))
-- /script MasterMerchant:itemCraftPrice("|H1:item:68195:5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h")
function MasterMerchant:GetTradeSkillInformation(itemLink)
  local MM_TRADESKILL_ALCHEMY = 77
  local MM_TRADESKILL_PROVISIONING = 76

  local ITEMTYPE_TO_ABILITYINDEX = {
    [ITEMTYPE_POISON] = 4,
    [ITEMTYPE_POTION] = 4,
    [ITEMTYPE_FOOD] = 5,
    [ITEMTYPE_DRINK] = 6,
  }
  local SPECIALIZED_ITEMTYPE_TO_ABILITYINDEX = {
    [SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_FOOD] = 5,
    [SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_DRINK] = 6,
  }
  local itemType, specializedItemType = GetItemLinkItemType(itemLink)
  local skillAbilityIndex = ITEMTYPE_TO_ABILITYINDEX[itemType]
  if (itemType == ITEMTYPE_RECIPE and (specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_FOOD or specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_DRINK)) then
    skillAbilityIndex = SPECIALIZED_ITEMTYPE_TO_ABILITYINDEX[specializedItemType]
  end
  local craftingType = MM_TRADESKILL_PROVISIONING
  if itemType == ITEMTYPE_POTION or itemType == ITEMTYPE_POISON then
    craftingType = MM_TRADESKILL_ALCHEMY
  end

  local numSkillLines = GetNumSkillLines(SKILL_TYPE_TRADESKILL)
  for sl = 1, numSkillLines do
    local skillLineId = GetSkillLineId(SKILL_TYPE_TRADESKILL, sl)
    if skillLineId == craftingType then
      local numAbilities = GetNumSkillAbilities(SKILL_TYPE_TRADESKILL, sl)
      for ab = 1, numAbilities do
        if ab == skillAbilityIndex then
          local _, _, _, _, _, purchased, _, rank = GetSkillAbilityInfo(SKILL_TYPE_TRADESKILL, sl, ab)
          return purchased, rank
        end
      end
    end --
  end
  return false, 0
end

-- /script d(MasterMerchant:GetSkillLineProvisioningAlchemyRank("|H1:item:33825:3:1:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:0|h|h"))
--[[ input: Item link of the Provisioning or Alchemy item. For example the crafted
Grape Preserves not the Recipe ]]--
function MasterMerchant:GetSkillLineProvisioningAlchemyRank(itemLink)
  local multiplier = 1 -- you can't divide by 0
  local purchaced, skillRank = MasterMerchant:GetTradeSkillInformation(itemLink)
  local itemType, specializedItemType = GetItemLinkItemType(itemLink)
  if purchaced then
    if itemType == ITEMTYPE_POTION or itemType == ITEMTYPE_FOOD or itemType == ITEMTYPE_DRINK or (itemType == ITEMTYPE_RECIPE and (specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_FOOD or specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_DRINK)) then
      multiplier = skillRank + 1
    elseif itemType == ITEMTYPE_POISON then
      multiplier = (skillRank + 1) * 4
    end
  end
  if not purchaced and itemType == ITEMTYPE_POISON then
    multiplier = 4
  end
  return multiplier
end

-- /script MasterMerchant:itemCraftPrice("|H1:item:68195:5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h")
-- |H1:item:189488:5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:0|h|h
-- |H1:item:190086:5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h
function MasterMerchant:itemCraftPrice(itemLink)
  local itemType, specializedItemType = GetItemLinkItemType(itemLink)
  local multiplier = MasterMerchant:GetSkillLineProvisioningAlchemyRank(itemLink)

  if (itemType == ITEMTYPE_POTION) or (itemType == ITEMTYPE_POISON) then
    if not IsItemLinkCrafted(itemLink) then
      return nil, nil
    end

    local effect1, effect2, effect3, effect4 = LibAlchemy:GetEffectsFromItemLink(itemLink)
    local solventItemLink = MasterMerchant:GetSolventItemLink(itemLink)
    if effect1 ~= 0 then
      local cost = MasterMerchant.GetItemLinePrice(solventItemLink)
      local bestIngredients = LibAlchemy:getBestCombination({ LibAlchemy.effectsByWritID[effect1], LibAlchemy.effectsByWritID[effect2], LibAlchemy.effectsByWritID[effect3], LibAlchemy.effectsByWritID[effect4] }) or {}
      for _, itemId in pairs(bestIngredients) do
        local ingredientItemLink = string.format('|H1:item:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h', itemId)
        cost = cost + MasterMerchant.GetItemLinePrice(ingredientItemLink)
      end
      return cost, (cost / multiplier)
    else
      return nil, nil
    end
  end

  local numIngredients = MasterMerchant.GetItemLinkRecipeNumIngredients(itemLink)
  if ((numIngredients or 0) == 0) then
    -- Try to clean up item link by moving it to level 1
    itemLink = itemLink:gsub(":0", ":1", 1)
    numIngredients = MasterMerchant.GetItemLinkRecipeNumIngredients(itemLink)
  end

  if ((numIngredients or 0) > 0) then
    local cost = 0
    for i = 1, numIngredients do
      local ingredientItemLink, numRequired = MasterMerchant.GetItemLinkRecipeIngredientInfo(itemLink, i)
      if ingredientItemLink then
        cost = cost + (MasterMerchant.GetItemLinePrice(ingredientItemLink) * numRequired)
      end
    end

    if ((itemType == ITEMTYPE_DRINK) or (itemType == ITEMTYPE_FOOD)
      or (itemType == ITEMTYPE_RECIPE and (specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_FOOD or specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_DRINK))) then
      return cost, (cost / multiplier)
    end
    return cost, nil
  else
    return nil, nil
  end
end

function MasterMerchant.loadRecipesFrom(startNumber, endNumber)
  local checkTime = GetGameTimeMilliseconds()
  local recNumber = startNumber - 1
  local resultLink
  local itemLink
  while true do
    recNumber = recNumber + 1

    itemLink = string.format('|H1:item:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h', recNumber)
    local itemType = GetItemLinkItemType(itemLink)
    if itemType == ITEMTYPE_ENCHANTING_RUNE_ESSENCE then
      table.insert(MasterMerchant.essenceRunes, recNumber)
    elseif itemType == ITEMTYPE_ENCHANTING_RUNE_POTENCY then
      table.insert(MasterMerchant.potencyRunes, recNumber)
    elseif itemType == ITEMTYPE_ENCHANTING_RUNE_ASPECT then
      table.insert(MasterMerchant.aspectRunes, recNumber)
    elseif itemType == ITEMTYPE_POTION_BASE then
      local levelRequired = GetItemLinkRequiredLevel(itemLink) + GetItemLinkRequiredChampionPoints(itemLink)
      MasterMerchant.potionSolvents[levelRequired] = recNumber
      MasterMerchant.potionSolventsItemLinks[recNumber] = MasterMerchant.potionSolventsItemLinks[recNumber] or {}
      MasterMerchant.potionSolventsItemLinks[recNumber][levelRequired] = MasterMerchant.potionSolventsItemLinks[recNumber][levelRequired] or {}
      MasterMerchant.potionSolventsItemLinks[recNumber][levelRequired][1] = itemLink
    elseif itemType == ITEMTYPE_POISON_BASE then
      local levelRequired = GetItemLinkRequiredLevel(itemLink) + GetItemLinkRequiredChampionPoints(itemLink)
      MasterMerchant.poisonSolvents[levelRequired] = recNumber
      MasterMerchant.poisonSolventsItemLinks[recNumber] = MasterMerchant.poisonSolventsItemLinks[recNumber] or {}
      MasterMerchant.poisonSolventsItemLinks[recNumber][levelRequired] = MasterMerchant.poisonSolventsItemLinks[recNumber][levelRequired] or {}
      MasterMerchant.poisonSolventsItemLinks[recNumber][levelRequired][2] = itemLink
    elseif itemType == ITEMTYPE_REAGENT then
      table.insert(MasterMerchant.reagents, recNumber)
      MasterMerchant.reagentItemLinks[recNumber] = MasterMerchant.reagentItemLinks[recNumber] or {}
      MasterMerchant.reagentItemLinks[recNumber][2] = itemLink
      --[[
      MasterMerchant.reagents[recNumber] = {}
      for i = 1, GetMaxTraits() do
          local _, traitName = GetItemLinkReagentTraitInfo(itemLink, i)
          table.insert(MasterMerchant.reagents[recNumber], traitName)
          -- If you get an error here, you don't know all the flower/rune traits....
          MasterMerchant.traits[traitName] = MasterMerchant.traits[traitName] or {}
          table.insert(MasterMerchant.traits[traitName], recNumber)
      end
      --]]
    elseif itemType == ITEMTYPE_RECIPE then
      resultLink = GetItemLinkRecipeResultItemLink(itemLink)

      if (resultLink ~= MM_STRING_EMPTY) then
        MasterMerchant.recipeData[resultLink] = itemLink
        MasterMerchant.recipeCount = MasterMerchant.recipeCount + 1
        --debug
        --d(MasterMerchant.recipeCount .. ') ' .. itemLink .. ' --> ' .. resultLink  .. ' ('  .. recNumber .. ')')
      end
    end

    if (recNumber >= endNumber) then
      MasterMerchant:dm("Info", '|cFFFF00Recipes Initialized -- Found information on ' .. MasterMerchant.recipeCount .. ' recipes.|r')
      MasterMerchant.systemSavedVariables.recipeData = MasterMerchant.recipeData
      MasterMerchant.systemSavedVariables.essenceRunes = MasterMerchant.essenceRunes
      MasterMerchant.systemSavedVariables.potencyRunes = MasterMerchant.potencyRunes
      MasterMerchant.systemSavedVariables.aspectRunes = MasterMerchant.aspectRunes
      MasterMerchant.systemSavedVariables.reagents = MasterMerchant.reagents
      MasterMerchant.systemSavedVariables.potionSolvents = MasterMerchant.potionSolvents
      MasterMerchant.systemSavedVariables.poisonSolvents = MasterMerchant.poisonSolvents
      MasterMerchant.systemSavedVariables.reagentItemLinks = MasterMerchant.reagentItemLinks
      MasterMerchant.systemSavedVariables.potionSolventsItemLinks = MasterMerchant.potionSolventsItemLinks
      MasterMerchant.systemSavedVariables.poisonSolventsItemLinks = MasterMerchant.poisonSolventsItemLinks
      break
    end

    if (GetGameTimeMilliseconds() - checkTime) > 20 then
      local LEQ = LibExecutionQueue:new()
      LEQ:ContinueWith(function() MasterMerchant.loadRecipesFrom(recNumber + 1, endNumber) end, 'Recipe Cont')
      break
    end
  end
end

--[[
 ITEMTYPE_GLYPH_ARMOR
 ITEMTYPE_GLYPH_JEWELRY
 ITEMTYPE_GLYPH_WEAPON

 ITEMTYPE_POISON
 ITEMTYPE_POTION

 ITEMTYPE_ALCHEMY_BASE

 ITEMTYPE_INGREDIENT
 ITEMTYPE_RECIPE

 TRAIT
 /script MasterMerchant:dm("Debug", GetString(ITEMTYPE_ADDITIVE))

 GetString("SI_ITEMTYPE", ITEMTYPE_FOOD)
 GetString("SI_SPECIALIZEDITEMTYPE", SPECIALIZED_ITEMTYPE_BLACKSMITHING_BOOSTER)
 /script MasterMerchant:dm("Debug", GetString("SPECIALIZED_ITEMTYPE_", GetItemLinkItemType(|H0:item:68633:363:50:0:0:0:0:0:0:0:0:0:0:0:0:13:0:0:0:10000:0|h|h)))
 SPECIALIZED_ITEMTYPE_RECIPE_BLACKSMITHING_DIAGRAM_FURNISHING

 GetItemLinkItemType(itemLink)

 33 - ITEMTYPE_POTION_BASE
 58 - ITEMTYPE_POISON_BASE
 31 - ITEMTYPE_REAGENT

 for i = 1, GetMaxTraits() do
  local known, name = GetItemLinkReagentTraitInfo("|H1:item:77583:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", i)
  d(name)
end


|H1:item:45806:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h
|H1:item:45844:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h
|H1:item:45850:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h

]]--
-- LOAD RECIPES
-- /script MasterMerchant.virtualRecipe = nil; MasterMerchant.recipeData = nil; MasterMerchant.setupRecipeInfo()


function MasterMerchant.setupRecipeInfo()
  if not MasterMerchant.recipeData then
    MasterMerchant.recipeData = {}
    MasterMerchant.recipeCount = 0

    MasterMerchant.essenceRunes = {}
    MasterMerchant.aspectRunes = {}
    MasterMerchant.potencyRunes = {}

    MasterMerchant.virtualRecipe = {}
    MasterMerchant.virtualRecipeCount = 0

    MasterMerchant.traits = {}
    MasterMerchant.reagents = {}
    MasterMerchant.potionSolvents = {}
    MasterMerchant.poisonSolvents = {}
    MasterMerchant.reagentItemLinks = {}
    MasterMerchant.potionSolventsItemLinks = {}
    MasterMerchant.poisonSolventsItemLinks = {}

    MasterMerchant:dm("Info", '|cFFFF00Searching Items|r')
    local LEQ = LibExecutionQueue:new()
    LEQ:Add(function() MasterMerchant.loadRecipesFrom(1, 450000) end, 'Search Items')
    LEQ:Add(function() MasterMerchant.BuildEnchantingRecipes(1, 1, 0) end, 'Enchanting Recipes')
    LEQ:Start()
  end
end

function MasterMerchant.BuildEnchantingRecipes(potency, essence, aspect)

  local checkTime = GetGameTimeMilliseconds()

  while true do
    aspect = aspect + 1
    if aspect > #MasterMerchant.aspectRunes then
      aspect = 1
      essence = essence + 1
    end
    if essence > #MasterMerchant.essenceRunes then
      essence = 1
      potency = potency + 1
    end
    if potency > #MasterMerchant.potencyRunes then
      d('|cFFFF00Glyphs Initialized -- Created information on ' .. MasterMerchant.virtualRecipeCount .. ' glyphs.|r')
      MasterMerchant.systemSavedVariables.virtualRecipe = MasterMerchant.virtualRecipe
      break
    end

    MasterMerchant.virtualRecipeCount = MasterMerchant.virtualRecipeCount + 1
    -- Make Glyph
    local potencyNum = MasterMerchant.potencyRunes[potency]
    local essenceNum = MasterMerchant.essenceRunes[essence]
    local aspectNum = MasterMerchant.aspectRunes[aspect]

    local glyph = GetEnchantingResultingItemLink(BAG_VIRTUAL, potencyNum, BAG_VIRTUAL, essenceNum, BAG_VIRTUAL, aspectNum)
    --d(glyph)
    --d(potencyNum .. '.' .. essenceNum .. '.' .. aspectNum)
    if (glyph ~= '') then
      local mmGlyph = zo_strmatch(glyph,
        '|H.-:item:(.-):') .. ':' .. internal.GetOrCreateIndexFromLink(glyph)

      MasterMerchant.virtualRecipe[mmGlyph] = {
        [1] = { ['item'] = string.format('|H1:item:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h',
          potencyNum), ['required'] = 1 },
        [2] = { ['item'] = string.format('|H1:item:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h',
          essenceNum), ['required'] = 1 },
        [3] = { ['item'] = string.format('|H1:item:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h',
          aspectNum), ['required'] = 1 }
      }
    end

    --debug
    --d(glyph)
    --d(MasterMerchant.virtualRecipe[glyph])

    if (GetGameTimeMilliseconds() - checkTime) > 20 then
      local LEQ = LibExecutionQueue:new()
      LEQ:ContinueWith(function() MasterMerchant.BuildEnchantingRecipes(potency, essence, aspect) end,
        'Enchanting Recipes Cont')
      break
    end
  end
end

-- Copyright (c) 2014 Matthew Miller (Mattmillus)
--
-- Permission is hereby granted, free of charge, to any person
-- obtaining a copy of this software and associated documentation
-- files (the "Software"), to deal in the Software without
-- restriction, including without limitation the rights to use,
-- copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following
-- conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.

function MasterMerchant:OnItemLinkAction(itemLink)
  local tipLine = MasterMerchant:GetPriceToChatText(itemLink)
  -- no MM data handled in GetPriceToChatText
  if tipLine then
    local ChatEditControl = CHAT_SYSTEM.textEntry.editControl
    if (not ChatEditControl:HasFocus()) then StartChatInput() end
    local itemText = string.gsub(itemLink, '|H0', '|H1')
    ChatEditControl:InsertText(MasterMerchant.concat(tipLine, GetString(MM_TIP_FOR), itemText))
  end
end

function MasterMerchant:onItemActionLinkCCLink(itemLink)
  local tipLine = MasterMerchant:CraftCostPriceTip(itemLink, true)
  if not tipLine then
    tipLine = GetString(SK_NO_CRAFT_COST_AVAILABLE)
  end
  if tipLine then
    local ChatEditControl = CHAT_SYSTEM.textEntry.editControl
    if (not ChatEditControl:HasFocus()) then StartChatInput() end
    local itemText = string.gsub(itemLink, '|H0', '|H1')
    ChatEditControl:InsertText(MasterMerchant.concat(tipLine, GetString(MM_TIP_FOR), itemText))
  end
end

function MasterMerchant:OnSearchBonanzaPopupInfoLink(itemLink)
  if not itemLink then MasterMerchant:dm("Warn", "OnSearchBonanzaPopupInfoLink has no itemLink") end
  local searchText = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink))
  if not searchText or searchText == MM_STRING_EMPTY then return end
  MasterMerchant.bonanzaSearchText = searchText
  MasterMerchant:SwitchToMasterMerchantListingsView()
  MasterMerchant.listingsScrollList:RefreshFilters()
end

function MasterMerchant:onItemActionPopupInfoLink(itemLink)
  --[[MM_Graph.itemLink was added to there is a current link
  for the graph. When adding a seller to the filter that
  changes the outcome of the calculations so the tooltip
  cache needs to be reset
  ]]--
  if not itemLink then MasterMerchant:dm("Warn", "onItemActionPopupInfoLink has no itemLink") end
  ZO_PopupTooltip_SetLink(itemLink)
end

-- Adjusted Per AssemblerManiac request 2019-2-20
--[[This function adds menu items to the master merchant window
and somehow adds this to the tooltip as well when you don't
really need it there.
]]--
function MasterMerchant.LinkHandler_OnLinkMouseUp(link, button, _, _, linkType, ...)
  if button == MOUSE_BUTTON_INDEX_RIGHT and linkType == ITEM_LINK_TYPE and type(link) == 'string' and #link > 0 and link ~= '' then
    zo_callLater(function()
      if MasterMerchant:itemCraftPrice(link) then
        AddMenuItem(GetString(MM_CRAFT_COST_TO_CHAT), function() MasterMerchant:onItemActionLinkCCLink(link) end)
      end
      AddMenuItem(GetString(MM_STATS_TO_CHAT), function() MasterMerchant:OnItemLinkAction(link) end)
      AddMenuItem(GetString(MM_POPUP_ITEM_DATA), function() MasterMerchant:onItemActionPopupInfoLink(link) end, MENU_ADD_OPTION_LABEL)
      ShowMenu()
    end)
  end
end

--[[This function adds menu items to the popup of the item
when you are at a crafting station
]]--
function MasterMerchant.myOnTooltipMouseUp(control, button, upInside, linkFunction, scene)
  if upInside and button == MOUSE_BUTTON_INDEX_RIGHT then

    local link = linkFunction()

    if (link ~= MM_STRING_EMPTY and string.match(link, '|H.-:item:(.-):')) then
      ClearMenu()

      AddMenuItem(GetString(MM_CRAFT_COST_TO_CHAT), function() MasterMerchant:onItemActionLinkCCLink(link) end)
      AddMenuItem(GetString(MM_STATS_TO_CHAT), function() MasterMerchant:OnItemLinkAction(link) end)
      AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT), function() ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link)) end)
      ShowMenu(scene)
    end
  end
end

function MasterMerchant.myProvisionerOnTooltipMouseUp(control, button, upInside)
  MasterMerchant.myOnTooltipMouseUp(control, button, upInside,
    function()
      local recipeListIndex, recipeIndex = PROVISIONER:GetSelectedRecipeListIndex(), PROVISIONER:GetSelectedRecipeIndex()
      return ZO_LinkHandler_CreateChatLink(GetRecipeResultItemLink, recipeListIndex, recipeIndex)
    end,
    PROVISIONER
  )
end
PROVISIONER.resultTooltip:SetHandler("OnMouseUp", MasterMerchant.myProvisionerOnTooltipMouseUp)
PROVISIONER.resultTooltip:GetNamedChild("Icon"):SetHandler("OnMouseUp", MasterMerchant.myProvisionerOnTooltipMouseUp)

function MasterMerchant.myAlchemyOnTooltipMouseUp(control, button, upInside)
  MasterMerchant.myOnTooltipMouseUp(control, button, upInside,
    function()
      return ZO_LinkHandler_CreateChatLink(GetAlchemyResultingItemLink, ALCHEMY:GetAllCraftingBagAndSlots())
    end,
    ALCHEMY
  )
end
ALCHEMY.tooltip:SetHandler("OnMouseUp", MasterMerchant.myAlchemyOnTooltipMouseUp)
ALCHEMY.tooltip:GetNamedChild("Icon"):SetHandler("OnMouseUp", MasterMerchant.myAlchemyOnTooltipMouseUp)

function MasterMerchant.mySmithingOnTooltipMouseUp(control, button, upInside)
  MasterMerchant.myOnTooltipMouseUp(control, button, upInside,
    function()
      return ZO_LinkHandler_CreateChatLink(GetSmithingPatternResultLink,
        SMITHING.creationPanel:GetSelectedPatternIndex(), SMITHING.creationPanel:GetSelectedMaterialIndex(),
        SMITHING.creationPanel:GetSelectedMaterialQuantity(), SMITHING.creationPanel:GetSelectedItemStyleId(),
        SMITHING.creationPanel:GetSelectedTraitIndex())
    end,
    SMITHING.creationPanel
  )
end
SMITHING.creationPanel.resultTooltip:SetHandler("OnMouseUp", MasterMerchant.mySmithingOnTooltipMouseUp)
SMITHING.creationPanel.resultTooltip:GetNamedChild("Icon"):SetHandler("OnMouseUp", MasterMerchant.mySmithingOnTooltipMouseUp)

function MasterMerchant.myEnchantingOnTooltipMouseUp(control, button, upInside)
  MasterMerchant.myOnTooltipMouseUp(control, button, upInside,
    function()
      return ZO_LinkHandler_CreateChatLink(GetEnchantingResultingItemLink, ENCHANTING:GetAllCraftingBagAndSlots())
    end,
    ENCHANTING
  )
end
ENCHANTING.resultTooltip:SetHandler("OnMouseUp", MasterMerchant.myEnchantingOnTooltipMouseUp)
ENCHANTING.resultTooltip:GetNamedChild("Icon"):SetHandler("OnMouseUp", MasterMerchant.myEnchantingOnTooltipMouseUp)

function MasterMerchant:my_NameHandler_OnLinkMouseUp(player, button, control)
  if (type(player) == 'string' and #player > 0) then
    if (button == MOUSE_BUTTON_INDEX_RIGHT and player ~= '') then
      ClearMenu()
      AddMenuItem(GetString(SI_SOCIAL_LIST_SEND_MESSAGE),
        function() StartChatInput(nil, CHAT_CHANNEL_WHISPER, player) end)
      AddMenuItem(GetString(SI_SOCIAL_MENU_SEND_MAIL), function() MAIL_SEND:ComposeMailTo(player) end)
      ShowMenu(control)
    end
  end
end

function MasterMerchant:my_SellerColumn_OnLinkMouseUp(player, itemLink, button, control)
  if type(player) == 'string' then
    if (button == MOUSE_BUTTON_INDEX_RIGHT and player ~= '') then
      ClearMenu()
      AddMenuItem(GetString(MM_BLACKLIST_MENU_SELLER), function() MM_Graph:OnSellerNameClicked(self, button, player, itemLink) end)
      ShowMenu()
    end
  end
end

function MasterMerchant:my_AddFilterHandler_OnLinkMouseUp(itemLink, button, control)
  if (button == MOUSE_BUTTON_INDEX_RIGHT and itemLink ~= '') then
    ClearMenu()
    if MasterMerchant:itemCraftPrice(itemLink) then
      AddMenuItem(GetString(MM_CRAFT_COST_TO_CHAT), function() self:onItemActionLinkCCLink(itemLink) end,
        MENU_ADD_OPTION_LABEL)
    end
    AddMenuItem(GetString(MM_POPUP_ITEM_DATA), function() self:onItemActionPopupInfoLink(itemLink) end,
      MENU_ADD_OPTION_LABEL)
    AddMenuItem(GetString(MM_STATS_TO_CHAT), function() self:OnItemLinkAction(itemLink) end,
      MENU_ADD_OPTION_LABEL)
    AddMenuItem(GetString(MM_FILTER_MENU_ADD_ITEM), function() MasterMerchant:AddToFilterTable(itemLink) end)
    ShowMenu(control)
  end
end

function MasterMerchant:my_GuildColumn_OnLinkMouseUp(guildZoneId, button, control)
  if not guildZoneId or guildZoneId == 0 then
    MasterMerchant:dm("Info", GetString(MM_ZONE_INVALID))
    return
  end
  if not BMU then
    MasterMerchant:dm("Info", GetString(MM_BEAM_ME_UP_MISSING))
    return
  end
  if (button == MOUSE_BUTTON_INDEX_RIGHT and player ~= '') then
    ClearMenu()
    AddMenuItem(GetString(MM_TRAVEL_TO_ZONE_TEXT), function() BMU.sc_porting(guildZoneId) end)
    ShowMenu(control)
  end
end

function MasterMerchant.PostPendingItem(self)
  --MasterMerchant:dm("Debug", "PostPendingItem")
  if self.pendingItemSlot and self.pendingSaleIsValid then
    local itemLink = GetItemLink(BAG_BACKPACK, self.pendingItemSlot)
    local _, stackCount, _ = GetItemInfo(BAG_BACKPACK, self.pendingItemSlot)
    local itemUniqueId = GetItemUniqueId(BAG_BACKPACK, self.pendingItemSlot)

    local theIID = GetItemLinkItemId(itemLink)
    local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
    local guildId, guildName = GetCurrentTradingHouseGuildDetails()

    local theEvent = {
      guild = guildName,
      guildId = guildId,
      itemLink = itemLink,
      quant = stackCount,
      timestamp = GetTimeStamp(),
      price = self.invoiceSellPrice.sellPrice,
      seller = GetDisplayName(),
      id = itemUniqueId,
    }
    internal:addPostedItem(theEvent)
    MasterMerchant.listIsDirty[REPORTS] = true

    if MasterMerchant.systemSavedVariables.priceCalcAll then
      GS17DataSavedVariables[internal.pricingNamespace] = GS17DataSavedVariables[internal.pricingNamespace] or {}
      GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"] = GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"] or {}
      GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"][theIID] = GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"][theIID] or {}
      GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"][theIID][itemIndex] = self.invoiceSellPrice.sellPrice / stackCount
    else
      GS17DataSavedVariables[internal.pricingNamespace] = GS17DataSavedVariables[internal.pricingNamespace] or {}
      GS17DataSavedVariables[internal.pricingNamespace][guildId] = GS17DataSavedVariables[internal.pricingNamespace][guildId] or {}
      GS17DataSavedVariables[internal.pricingNamespace][guildId][theIID] = GS17DataSavedVariables[internal.pricingNamespace][guildId][theIID] or {}
      GS17DataSavedVariables[internal.pricingNamespace][guildId][theIID][itemIndex] = self.invoiceSellPrice.sellPrice / stackCount
    end

    if MasterMerchant.systemSavedVariables.displayListingMessage then
      MasterMerchant:dm("Info", string.format(MasterMerchant.concat(GetString(MM_APP_MESSAGE_NAME), GetString(MM_LISTING_ALERT)), zo_strformat('<<t:1>>', itemLink), stackCount, self.invoiceSellPrice.sellPrice, guildName))
    end
  end
end

-- End Copyright (c) 2014 Matthew Miller (Mattmillus)

function MasterMerchant:OnTradingHouseListingClicked(itemLink, sellerName)
  -- actually could be seller or guild name
  local lengthBlacklist = string.len(MasterMerchant.systemSavedVariables.blacklist)
  local lengthSellerName = string.len(sellerName) + 2
  if not itemLink then MasterMerchant:dm("Warn", "OnTradingHouseListingClicked has no itemLink") end
  if lengthBlacklist + lengthSellerName > 2000 then
    MasterMerchant:dm("Info", GetString(MM_BLACKLIST_EXCEEDS))
  else
    if not MasterMerchant:IsInBlackList(sellerName) then
      MasterMerchant.systemSavedVariables.blacklist = MasterMerchant.systemSavedVariables.blacklist .. sellerName .. "\n"
      MasterMerchant:ResetItemInformationCache()
      MasterMerchant.blacklistTable = MasterMerchant:BuildTableFromString(MasterMerchant.systemSavedVariables.blacklist)
    end
  end
end

function MasterMerchant:myZO_InventorySlot_ShowContextMenu(inventorySlot)
  local slotType = ZO_InventorySlot_GetType(inventorySlot)
  local guildId, guildName = GetCurrentTradingHouseGuildDetails()
  local itemLink = nil
  if slotType == SLOT_TYPE_ITEM or slotType == SLOT_TYPE_EQUIPMENT or slotType == SLOT_TYPE_BANK_ITEM or slotType == SLOT_TYPE_GUILD_BANK_ITEM or
    slotType == SLOT_TYPE_TRADING_HOUSE_POST_ITEM or slotType == SLOT_TYPE_REPAIR or slotType == SLOT_TYPE_CRAFTING_COMPONENT or slotType == SLOT_TYPE_PENDING_CRAFTING_COMPONENT or
    slotType == SLOT_TYPE_PENDING_CRAFTING_COMPONENT or slotType == SLOT_TYPE_PENDING_CRAFTING_COMPONENT or slotType == SLOT_TYPE_CRAFT_BAG_ITEM then
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    itemLink = GetItemLink(bag, index)
  end
  if slotType == SLOT_TYPE_TRADING_HOUSE_ITEM_RESULT then
    itemLink = GetTradingHouseSearchResultItemLink(ZO_Inventory_GetSlotIndex(inventorySlot))
  end
  if slotType == SLOT_TYPE_TRADING_HOUSE_ITEM_LISTING then
    itemLink = GetTradingHouseListingItemLink(ZO_Inventory_GetSlotIndex(inventorySlot), linkStyle)
  end
  if (itemLink and zo_strmatch(itemLink, '|H.-:item:(.-):')) then
    zo_callLater(function()
      if MasterMerchant.systemSavedVariables.showSearchBonanza then AddMenuItem(GetString(MM_SEARCH_BONANZA), function() self:OnSearchBonanzaPopupInfoLink(itemLink) end, MENU_ADD_OPTION_LABEL) end
      if MasterMerchant:itemCraftPrice(itemLink) then
        AddMenuItem(GetString(MM_CRAFT_COST_TO_CHAT), function() self:onItemActionLinkCCLink(itemLink) end, MENU_ADD_OPTION_LABEL)
      end
      if inventorySlot.sellerName then
        AddMenuItem(GetString(MM_BLACKLIST_MENU_SELLER), function() MasterMerchant:OnTradingHouseListingClicked(itemLink, inventorySlot.sellerName) end)
        AddMenuItem(GetString(MM_BLACKLIST_MENU_GUILD), function() MasterMerchant:OnTradingHouseListingClicked(itemLink, guildName) end)
      end
      AddMenuItem(GetString(MM_POPUP_ITEM_DATA), function() self:onItemActionPopupInfoLink(itemLink) end, MENU_ADD_OPTION_LABEL)
      AddMenuItem(GetString(MM_STATS_TO_CHAT), function() self:OnItemLinkAction(itemLink) end, MENU_ADD_OPTION_LABEL)
      ShowMenu(self)
    end, 50)
  end
end

-- Calculate some stats based on the player's sales
-- and return them as a table.
function MasterMerchant:SalesStats(statsDays)
  -- Initialize some values as we'll be using accumulation in the loop
  -- SK_STATS_TOTAL is a key for the overall stats as a guild is unlikely
  -- to be named that, except maybe just to mess with me :D
  local itemsSold = { ['SK_STATS_TOTAL'] = 0 }
  local goldMade = { ['SK_STATS_TOTAL'] = 0 }
  local largestSingle = { ['SK_STATS_TOTAL'] = { 0, nil } }
  local oldestTime = 0
  local newestTime = 0
  local overallOldestTime = 0
  local kioskSales = { ['SK_STATS_TOTAL'] = 0 }

  -- Set up the guild chooser, with the all guilds/overall option first
  --(other guilds will be added below)
  local guildDropdown = ZO_ComboBox_ObjectFromContainer(MasterMerchantStatsGuildChooser)
  guildDropdown:ClearItems()
  local allGuilds = guildDropdown:CreateItemEntry(GetString(SK_STATS_ALL_GUILDS), function() self:UpdateStatsWindow('SK_STATS_TOTAL') end)
  guildDropdown:AddItem(allGuilds)

  -- 86,400 seconds in a day; this will be the epoch time statsDays ago
  -- (roughly, actual time computations are a LOT more complex but meh)
  local statsDaysEpoch = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * statsDays)

  -- Loop through the player's sales and create the stats as appropriate
  -- (everything or everything with a timestamp after statsDaysEpoch)

  local indexes = sr_index[internal.PlayerSpecialText]
  if indexes then
    for i = 1, #indexes do
      local itemID = indexes[i][1]
      local itemData = indexes[i][2]
      local itemIndex = indexes[i][3]

      local theItem = sales_data[itemID][itemData]['sales'][itemIndex]
      local currentItemLink = internal:GetItemLinkByIndex(theItem['itemLink'])
      local currentGuild = internal:GetGuildNameByIndex(theItem['guild'])
      if theItem.timestamp > statsDaysEpoch then
        -- Items Sold
        itemsSold['SK_STATS_TOTAL'] = itemsSold['SK_STATS_TOTAL'] + 1
        if itemsSold[currentGuild] ~= nil then
          itemsSold[currentGuild] = itemsSold[currentGuild] + 1
        else
          itemsSold[currentGuild] = 1
        end

        -- Kiosk sales
        if theItem.wasKiosk then
          kioskSales['SK_STATS_TOTAL'] = kioskSales['SK_STATS_TOTAL'] + 1
          if kioskSales[currentGuild] ~= nil then
            kioskSales[currentGuild] = kioskSales[currentGuild] + 1
          else
            kioskSales[currentGuild] = 1
          end
        end

        -- Gold made
        goldMade['SK_STATS_TOTAL'] = goldMade['SK_STATS_TOTAL'] + theItem.price
        if goldMade[currentGuild] ~= nil then
          goldMade[currentGuild] = goldMade[currentGuild] + theItem.price
        else
          goldMade[currentGuild] = theItem.price
        end

        -- Check to see if we need to update the newest or oldest timestamp we've seen
        if oldestTime == 0 or theItem.timestamp < oldestTime then oldestTime = theItem.timestamp end
        if newestTime == 0 or theItem.timestamp > newestTime then newestTime = theItem.timestamp end

        -- Largest single sale
        if theItem.price > largestSingle['SK_STATS_TOTAL'][1] then largestSingle['SK_STATS_TOTAL'] = { theItem.price, currentItemLink } end
        if largestSingle[currentGuild] == nil or theItem.price > largestSingle[currentGuild][1] then
          largestSingle[currentGuild] = { theItem.price, currentItemLink }
        end
      end
      -- Check to see if we need to update the overall oldest time (used to set slider range)
      if overallOldestTime == 0 or theItem.timestamp < overallOldestTime then overallOldestTime = theItem.timestamp end
    end
  end
  -- Newest timestamp seen minus oldest timestamp seen is the number of seconds between
  -- them; divided by 86,400 it's the number of days (or at least close enough for this)
  local timeWindow = newestTime - oldestTime
  local dayWindow = 1
  if timeWindow > ZO_ONE_DAY_IN_SECONDS then dayWindow = math.floor(timeWindow / ZO_ONE_DAY_IN_SECONDS) + 1 end

  local overallTimeWindow = GetTimeStamp() - overallOldestTime
  local overallDayWindow = 1
  if overallTimeWindow > ZO_ONE_DAY_IN_SECONDS then overallDayWindow = math.floor(overallTimeWindow / ZO_ONE_DAY_IN_SECONDS) + 1 end

  local goldPerDay = {}
  local kioskPercentage = {}
  local showFullPrice = MasterMerchant.systemSavedVariables.showFullPrice

  -- Here we'll tweak stats as needed as well as add guilds to the guild chooser
  for theGuildName, guildItemsSold in pairs(itemsSold) do
    goldPerDay[theGuildName] = math.floor(goldMade[theGuildName] / dayWindow)
    local kioskSalesTemp = 0
    if kioskSales[theGuildName] ~= nil then kioskSalesTemp = kioskSales[theGuildName] end
    if guildItemsSold == 0 then
      kioskPercentage[theGuildName] = 0
    else
      kioskPercentage[theGuildName] = math.floor((kioskSalesTemp / guildItemsSold) * 100)
    end

    if theGuildName ~= 'SK_STATS_TOTAL' then
      local guildEntry = guildDropdown:CreateItemEntry(theGuildName,
        function() self:UpdateStatsWindow(theGuildName) end)
      guildDropdown:AddItem(guildEntry)
    end

    -- If they have the option set to show prices post-cut, calculate that here
    if not showFullPrice then
      local cutMult = 1 - (GetTradingHouseCutPercentage() / 100)
      goldMade[theGuildName] = math.floor(goldMade[theGuildName] * cutMult + 0.5)
      goldPerDay[theGuildName] = math.floor(goldPerDay[theGuildName] * cutMult + 0.5)
      largestSingle[theGuildName][1] = math.floor(largestSingle[theGuildName][1] * cutMult + 0.5)
    end
  end

  -- Return the statistical data in a convenient table
  return { numSold = itemsSold,
           numDays = dayWindow,
           totalDays = overallDayWindow,
           totalGold = goldMade,
           avgGold = goldPerDay,
           biggestSale = largestSingle,
           kioskPercent = kioskPercentage, }
end

-- Table where the guild roster columns shall be placed
MasterMerchant.guild_columns = {}
MasterMerchant.UI_GuildTime = nil

if TamrielTradeCentre then
  MasterMerchant.dealCalcChoices = {
    GetString(GS_DEAL_CALC_TTC_SUGGESTED),
    GetString(GS_DEAL_CALC_TTC_AVERAGE),
    GetString(GS_DEAL_CALC_MM_AVERAGE),
    GetString(GS_DEAL_CALC_BONANZA_PRICE),
  }
  MasterMerchant.dealCalcValues = {
    MM_PRICE_TTC_SUGGESTED,
    MM_PRICE_TTC_AVERAGE,
    MM_PRICE_MM_AVERAGE,
    MM_PRICE_BONANZA,
  }
else
  MasterMerchant.dealCalcChoices = {
    GetString(GS_DEAL_CALC_MM_AVERAGE),
    GetString(GS_DEAL_CALC_BONANZA_PRICE),
  }
  MasterMerchant.dealCalcValues = {
    MM_PRICE_MM_AVERAGE,
    MM_PRICE_BONANZA,
  }
end

MasterMerchant.agsPercentSortChoices = {
  GetString(AGS_PERCENT_ORDER_ASCENDING),
  GetString(AGS_PERCENT_ORDER_DESCENDING),
}
MasterMerchant.agsPercentSortValues = {
  MM_AGS_SORT_PERCENT_ASCENDING,
  MM_AGS_SORT_PERCENT_DESCENDING,
}

local function CheckDealCalcValue()
  if MasterMerchant.systemSavedVariables.dealCalcToUse ~= MM_PRICE_TTC_SUGGESTED then
    MasterMerchant.systemSavedVariables.modifiedSuggestedPriceDealCalc = false
  end
end

local function CheckInventoryValue()
  if MasterMerchant.systemSavedVariables.replacementTypeToUse ~= MM_PRICE_TTC_SUGGESTED then
    MasterMerchant.systemSavedVariables.modifiedSuggestedPriceInventory = false
  end
end

local function CheckVoucherValue()
  if MasterMerchant.systemSavedVariables.voucherValueTypeToUse ~= MM_PRICE_TTC_SUGGESTED then
    MasterMerchant.systemSavedVariables.modifiedSuggestedPriceVoucher = false
  end
end

-- LibAddon init code
function MasterMerchant:LibAddonInit()
  -- configure font choices
  MasterMerchant:SetFontListChoices()
  MasterMerchant:dm("Debug", "LibAddonInit")
  local panelData = {
    type = 'panel',
    name = 'Master Merchant',
    displayName = GetString(MM_APP_NAME),
    author = GetString(MM_APP_AUTHOR),
    version = self.version,
    website = "https://www.esoui.com/downloads/fileinfo.php?id=2753",
    feedback = "https://www.esoui.com/downloads/fileinfo.php?id=2753",
    donation = "https://sharlikran.github.io/",
    registerForRefresh = true,
    registerForDefaults = true,
  }
  LAM:RegisterAddonPanel('MasterMerchantOptions', panelData)

  local optionsData = {}
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(MASTER_MERCHANT_WINDOW_NAME),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#MasterMerchantWindowOptions",
  }
  -- Open main window with mailbox scenes
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_OPEN_MAIL_NAME),
    tooltip = GetString(SK_OPEN_MAIL_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.openWithMail end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.openWithMail = value
      local theFragment = MasterMerchant:ActiveFragment()
      if value then
        -- Register for the mail scenes
        MAIL_INBOX_SCENE:AddFragment(theFragment)
        MAIL_SEND_SCENE:AddFragment(theFragment)
      else
        -- Unregister for the mail scenes
        MAIL_INBOX_SCENE:RemoveFragment(theFragment)
        MAIL_SEND_SCENE:RemoveFragment(theFragment)
      end
    end,
    default = MasterMerchant.systemDefault.openWithMail,
  }
  -- Open main window with trading house scene
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_OPEN_STORE_NAME),
    tooltip = GetString(SK_OPEN_STORE_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.openWithStore end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.openWithStore = value
      local theFragment = MasterMerchant:ActiveFragment()
      if value then
        -- Register for the store scene
        TRADING_HOUSE_SCENE:AddFragment(theFragment)
      else
        -- Unregister for the store scene
        TRADING_HOUSE_SCENE:RemoveFragment(theFragment)
      end
    end,
    default = MasterMerchant.systemDefault.openWithStore,
  }
  -- Show full sale price or post-tax price
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_FULL_SALE_NAME),
    tooltip = GetString(SK_FULL_SALE_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showFullPrice end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.showFullPrice = value
      MasterMerchant.listIsDirty[ITEMS] = true
      MasterMerchant.listIsDirty[GUILDS] = true
      MasterMerchant.listIsDirty[LISTINGS] = true
      MasterMerchant.listIsDirty[PURCHASES] = true
    end,
    default = MasterMerchant.systemDefault.showFullPrice,
  }
  -- Font to use
  optionsData[#optionsData + 1] = {
    type = 'dropdown',
    name = GetString(SK_WINDOW_FONT_NAME),
    tooltip = GetString(SK_WINDOW_FONT_TIP),
    choices = MasterMerchant.fontListChoices,
    getFunc = function() return MasterMerchant.systemSavedVariables.windowFont end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.windowFont = value
      self:UpdateFonts()
      if MasterMerchant.systemSavedVariables.viewSize == ITEMS then self.scrollList:RefreshVisible()
      elseif MasterMerchant.systemSavedVariables.viewSize == GUILDS then self.guildScrollList:RefreshVisible()
      else self.listingScrollList:RefreshVisible() end
    end,
    default = MasterMerchant.systemDefault.windowFont,
  }
  optionsData[#optionsData + 1] = {
    type = 'slider',
    name = GetString(MM_WINDOW_CUSTOM_TIMEFRAME_NAME),
    tooltip = GetString(MM_WINDOW_CUSTOM_TIMEFRAME_TIP),
    min = 15,
    max = 365,
    getFunc = function() return MasterMerchant.systemSavedVariables.customFilterDateRange end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.customFilterDateRange = value end,
    default = MasterMerchant.systemDefault.customFilterDateRange,
  }
  -- Timeformat Options -----------------------------------
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(MASTER_MERCHANT_TIMEFORMAT_OPTIONS),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#TimeFormatOptions",
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_SHOW_TIME_NAME),
    tooltip = GetString(MM_SHOW_TIME_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.useFormatedTime end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.useFormatedTime = value end,
    default = MasterMerchant.systemDefault.useFormatedTime,
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_USE_TWENTYFOUR_HOUR_TIME_NAME),
    tooltip = GetString(MM_USE_TWENTYFOUR_HOUR_TIME_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.useTwentyFourHourTime end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.useTwentyFourHourTime = value end,
    default = MasterMerchant.systemDefault.useTwentyFourHourTime,
    disabled = function() return not MasterMerchant.systemSavedVariables.useFormatedTime end,
  }
  optionsData[#optionsData + 1] = {
    type = 'dropdown',
    name = GetString(MM_DATE_FORMAT_NAME),
    tooltip = GetString(MM_DATE_FORMAT_TIP),
    choices = { GetString(MM_USE_MONTH_DAY_FORMAT), GetString(MM_USE_DAY_MONTH_FORMAT), GetString(MM_USE_MONTH_DAY_YEAR_FORMAT), GetString(MM_USE_YEAR_MONTH_DAY_FORMAT), GetString(MM_USE_DAY_MONTH_YEAR_FORMAT), },
    choicesValues = { MM_MONTH_DAY_FORMAT, MM_DAY_MONTH_FORMAT, MM_MONTH_DAY_YEAR_FORMAT, MM_YEAR_MONTH_DAY_FORMAT, MM_DAY_MONTH_YEAR_FORMAT, },
    getFunc = function() return MasterMerchant.systemSavedVariables.dateFormatMonthDay end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.dateFormatMonthDay = value end,
    default = self:SearchSounds(MasterMerchant.systemDefault.dateFormatMonthDay),
    disabled = function() return not MasterMerchant.systemSavedVariables.useFormatedTime end,
  }
  -- 6 Sound and Alert options
  optionsData[#optionsData + 1] = {
    type = 'submenu',
    name = GetString(SK_ALERT_OPTIONS_NAME),
    tooltip = GetString(SK_ALERT_OPTIONS_TIP),
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#AlertOptions",
    controls = {
      -- On-Screen Alerts
      [1] = {
        type = 'checkbox',
        name = GetString(SK_ALERT_ANNOUNCE_NAME),
        tooltip = GetString(SK_ALERT_ANNOUNCE_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.showAnnounceAlerts end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.showAnnounceAlerts = value end,
        default = MasterMerchant.systemDefault.showAnnounceAlerts,
      },
      [2] = {
        type = 'checkbox',
        name = GetString(SK_ALERT_CYRODIIL_NAME),
        tooltip = GetString(SK_ALERT_CYRODIIL_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.showCyroAlerts end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.showCyroAlerts = value end,
        default = MasterMerchant.systemDefault.showCyroAlerts,
      },
      -- Chat Alerts
      [3] = {
        type = 'checkbox',
        name = GetString(SK_ALERT_CHAT_NAME),
        tooltip = GetString(SK_ALERT_CHAT_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.showChatAlerts end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.showChatAlerts = value end,
        default = MasterMerchant.systemDefault.showChatAlerts,
      },
      -- Sound to use for alerts
      [4] = {
        type = 'dropdown',
        name = GetString(SK_ALERT_TYPE_NAME),
        tooltip = GetString(SK_ALERT_TYPE_TIP),
        choices = self:SoundKeys(),
        getFunc = function() return self:SearchSounds(MasterMerchant.systemSavedVariables.alertSoundName) end,
        setFunc = function(value)
          MasterMerchant.systemSavedVariables.alertSoundName = self:SearchSoundNames(value)
          PlaySound(MasterMerchant.systemSavedVariables.alertSoundName)
        end,
        default = self:SearchSounds(MasterMerchant.systemDefault.alertSoundName),
      },
      -- Whether or not to show multiple alerts for multiple sales
      [5] = {
        type = 'checkbox',
        name = GetString(SK_MULT_ALERT_NAME),
        tooltip = GetString(SK_MULT_ALERT_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.showMultiple end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.showMultiple = value end,
        default = MasterMerchant.systemDefault.showMultiple,
      },
      -- Offline sales report
      [6] = {
        type = 'checkbox',
        name = GetString(SK_OFFLINE_SALES_NAME),
        tooltip = GetString(SK_OFFLINE_SALES_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.offlineSales end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.offlineSales = value end,
        default = MasterMerchant.systemDefault.offlineSales,
      },
      -- should we display the item listed message?
      [7] = {
        type = 'checkbox',
        name = GetString(MM_DISPLAY_LISTING_MESSAGE_NAME),
        tooltip = GetString(MM_DISPLAY_LISTING_MESSAGE_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.displayListingMessage end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.displayListingMessage = value end,
        default = MasterMerchant.systemDefault.displayListingMessage,
        disabled = function() return MasterMerchant.AwesomeGuildStoreDetected end,
      },
    },
  }
  -- 7 Tip display and calculation options
  optionsData[#optionsData + 1] = {
    type = 'submenu',
    name = GetString(MM_CALC_OPTIONS_NAME),
    tooltip = GetString(MM_CALC_OPTIONS_TIP),
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#CalculationDisplayOptions",
    controls = {
      -- On-Screen Alerts
      [1] = {
        type = 'slider',
        name = GetString(MM_DAYS_FOCUS_ONE_NAME),
        tooltip = GetString(MM_DAYS_FOCUS_ONE_TIP),
        min = 1,
        max = 90,
        getFunc = function() return MasterMerchant.systemSavedVariables.focus1 end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.focus1 = value end,
        default = MasterMerchant.systemDefault.focus1,
      },
      [2] = {
        type = 'slider',
        name = GetString(MM_DAYS_FOCUS_TWO_NAME),
        tooltip = GetString(MM_DAYS_FOCUS_TWO_TIP),
        min = 1,
        max = 90,
        getFunc = function() return MasterMerchant.systemSavedVariables.focus2 end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.focus2 = value end,
        default = MasterMerchant.systemDefault.focus2,
      },
      [3] = {
        type = 'slider',
        name = GetString(MM_DAYS_FOCUS_THREE_NAME),
        tooltip = GetString(MM_DAYS_FOCUS_THREE_TIP),
        min = 1,
        max = 90,
        getFunc = function() return MasterMerchant.systemSavedVariables.focus3 end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.focus3 = value end,
        default = MasterMerchant.systemDefault.focus3,
      },
      -- default time range
      [4] = {
        type = 'dropdown',
        name = GetString(MM_DEFAULT_TIME_NAME),
        tooltip = GetString(MM_DEFAULT_TIME_TIP),
        choices = { GetString(MM_RANGE_ALL), GetString(MM_RANGE_FOCUS1), GetString(MM_RANGE_FOCUS2), GetString(MM_RANGE_FOCUS3), GetString(MM_RANGE_NONE) },
        getFunc = function() return MasterMerchant.systemSavedVariables.defaultDays end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.defaultDays = value end,
        default = MasterMerchant.systemDefault.defaultDays,
      },
      -- shift time range
      [5] = {
        type = 'dropdown',
        name = GetString(MM_SHIFT_TIME_NAME),
        tooltip = GetString(MM_SHIFT_TIME_TIP),
        choices = { GetString(MM_RANGE_ALL), GetString(MM_RANGE_FOCUS1), GetString(MM_RANGE_FOCUS2), GetString(MM_RANGE_FOCUS3), GetString(MM_RANGE_NONE) },
        getFunc = function() return MasterMerchant.systemSavedVariables.shiftDays end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.shiftDays = value end,
        default = MasterMerchant.systemDefault.shiftDays,
      },
      -- ctrl time range
      [6] = {
        type = 'dropdown',
        name = GetString(MM_CTRL_TIME_NAME),
        tooltip = GetString(MM_CTRL_TIME_TIP),
        choices = { GetString(MM_RANGE_ALL), GetString(MM_RANGE_FOCUS1), GetString(MM_RANGE_FOCUS2), GetString(MM_RANGE_FOCUS3), GetString(MM_RANGE_NONE) },
        getFunc = function() return MasterMerchant.systemSavedVariables.ctrlDays end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.ctrlDays = value end,
        default = MasterMerchant.systemDefault.ctrlDays,
      },
      -- ctrl-shift time range
      [7] = {
        type = 'dropdown',
        name = GetString(MM_CTRLSHIFT_TIME_NAME),
        tooltip = GetString(MM_CTRLSHIFT_TIME_TIP),
        choices = { GetString(MM_RANGE_ALL), GetString(MM_RANGE_FOCUS1), GetString(MM_RANGE_FOCUS2), GetString(MM_RANGE_FOCUS3), GetString(MM_RANGE_NONE) },
        getFunc = function() return MasterMerchant.systemSavedVariables.ctrlShiftDays end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.ctrlShiftDays = value end,
        default = MasterMerchant.systemDefault.ctrlShiftDays,
      },
      -- blacklisted players and guilds
      [8] = {
        type = 'editbox',
        name = GetString(MM_BLACKLIST_NAME),
        tooltip = GetString(MM_BLACKLIST_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.blacklist end,
        setFunc = function(value)
          MasterMerchant.systemSavedVariables.blacklist = value
          MasterMerchant:ResetItemInformationCache()
          MasterMerchant.blacklistTable = MasterMerchant:BuildTableFromString(MasterMerchant.systemSavedVariables.blacklist)
        end,
        default = MasterMerchant.systemDefault.blacklist,
        isMultiline = true,
        textType = TEXT_TYPE_ALL,
        width = "full"
      },
      -- customTimeframe
      [9] = {
        type = 'slider',
        name = GetString(MM_CUSTOM_TIMEFRAME_NAME),
        tooltip = GetString(MM_CUSTOM_TIMEFRAME_TIP),
        min = 1,
        max = 24 * 31,
        getFunc = function() return MasterMerchant.systemSavedVariables.customTimeframe end,
        setFunc = function(value)
          MasterMerchant.systemSavedVariables.customTimeframe = value
          MasterMerchant.customTimeframeText = MasterMerchant.systemSavedVariables.customTimeframe .. ' ' .. MasterMerchant.systemSavedVariables.customTimeframeType
          MasterMerchant:BuildRosterTimeDropdown()
          MasterMerchant:BuildGuiTimeDropdown()
        end,
        default = MasterMerchant.systemDefault.customTimeframe,
        warning = GetString(MM_CUSTOM_TIMEFRAME_WARN),
        requiresReload = true,
      },
      -- shift time range
      [10] = {
        type = 'dropdown',
        name = GetString(MM_CUSTOM_TIMEFRAME_SCALE_NAME),
        tooltip = GetString(MM_CUSTOM_TIMEFRAME_SCALE_TIP),
        choices = { GetString(MM_CUSTOM_TIMEFRAME_HOURS), GetString(MM_CUSTOM_TIMEFRAME_DAYS), GetString(MM_CUSTOM_TIMEFRAME_WEEKS), GetString(MM_CUSTOM_TIMEFRAME_GUILD_WEEKS) },
        getFunc = function() return MasterMerchant.systemSavedVariables.customTimeframeType end,
        setFunc = function(value)
          MasterMerchant.systemSavedVariables.customTimeframeType = value
          MasterMerchant.customTimeframeText = MasterMerchant.systemSavedVariables.customTimeframe .. ' ' .. MasterMerchant.systemSavedVariables.customTimeframeType
          MasterMerchant:BuildRosterTimeDropdown()
          MasterMerchant:BuildGuiTimeDropdown()
        end,
        default = MasterMerchant.systemDefault.customTimeframeType,
        warning = GetString(MM_CUSTOM_TIMEFRAME_WARN),
        requiresReload = true,
      },
    },
  }
  -- 8 Custom Deal Calc
  optionsData[#optionsData + 1] = {
    type = 'submenu',
    name = GetString(MM_DEALCALC_OPTIONS_NAME),
    tooltip = GetString(MM_DEALCALC_OPTIONS_TIP),
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#CustomDealCalculator",
    controls = {
      -- Enable DealCalc
      [1] = {
        type = 'checkbox',
        name = GetString(MM_DEALCALC_ENABLE_NAME),
        tooltip = GetString(MM_DEALCALC_ENABLE_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.customDealCalc end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.customDealCalc = value end,
        default = MasterMerchant.systemDefault.customDealCalc,
      },
      -- custom customDealBuyIt
      [2] = {
        type = 'slider',
        name = GetString(MM_DEALCALC_BUYIT_NAME),
        tooltip = GetString(MM_DEALCALC_BUYIT_TIP),
        min = 0,
        max = 100,
        getFunc = function() return MasterMerchant.systemSavedVariables.customDealBuyIt end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.customDealBuyIt = value end,
        default = MasterMerchant.systemDefault.customDealBuyIt,
        disabled = function() return not MasterMerchant.systemSavedVariables.customDealCalc end,
      },
      -- customDealSeventyFive
      [3] = {
        type = 'slider',
        name = GetString(MM_DEALCALC_SEVENTYFIVE_NAME),
        tooltip = GetString(MM_DEALCALC_SEVENTYFIVE_TIP),
        min = 0,
        max = 100,
        getFunc = function() return MasterMerchant.systemSavedVariables.customDealSeventyFive end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.customDealSeventyFive = value end,
        default = MasterMerchant.systemDefault.customDealSeventyFive,
        disabled = function() return not MasterMerchant.systemSavedVariables.customDealCalc end,
      },
      -- customDealFifty
      [4] = {
        type = 'slider',
        name = GetString(MM_DEALCALC_FIFTY_NAME),
        tooltip = GetString(MM_DEALCALC_FIFTY_TIP),
        min = 0,
        max = 100,
        getFunc = function() return MasterMerchant.systemSavedVariables.customDealFifty end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.customDealFifty = value end,
        default = MasterMerchant.systemDefault.customDealFifty,
        disabled = function() return not MasterMerchant.systemSavedVariables.customDealCalc end,
      },
      -- customDealTwentyFive
      [5] = {
        type = 'slider',
        name = GetString(MM_DEALCALC_TWENTYFIVE_NAME),
        tooltip = GetString(MM_DEALCALC_TWENTYFIVE_TIP),
        min = 0,
        max = 100,
        getFunc = function() return MasterMerchant.systemSavedVariables.customDealTwentyFive end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.customDealTwentyFive = value end,
        default = MasterMerchant.systemDefault.customDealTwentyFive,
        disabled = function() return not MasterMerchant.systemSavedVariables.customDealCalc end,
      },
      -- customDealZero
      [6] = {
        type = 'slider',
        name = GetString(MM_DEALCALC_ZERO_NAME),
        tooltip = GetString(MM_DEALCALC_ZERO_TIP),
        min = 0,
        max = 100,
        getFunc = function() return MasterMerchant.systemSavedVariables.customDealZero end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.customDealZero = value end,
        default = MasterMerchant.systemDefault.customDealZero,
        disabled = function() return not MasterMerchant.systemSavedVariables.customDealCalc end,
      },
      [7] = {
        type = "description",
        text = GetString(MM_DEALCALC_OKAY_TEXT),
      },
      -- Deal Filter Price
      [8] = {
        type = 'dropdown',
        name = GetString(SK_DEAL_CALC_TYPE_NAME),
        tooltip = GetString(SK_DEAL_CALC_TYPE_TIP),
        choices = MasterMerchant.dealCalcChoices,
        choicesValues = MasterMerchant.dealCalcValues,
        getFunc = function() return MasterMerchant.systemSavedVariables.dealCalcToUse end,
        setFunc = function(value)
          MasterMerchant.systemSavedVariables.dealCalcToUse = value
          CheckDealCalcValue()
        end,
        default = MasterMerchant.systemDefault.dealCalcToUse,
      },
      [9] = {
        type = 'checkbox',
        name = GetString(MM_MODIFIED_TTC_SUGGESTED_NAME),
        tooltip = GetString(MM_MODIFIED_TTC_SUGGESTED_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.modifiedSuggestedPriceDealCalc end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.modifiedSuggestedPriceDealCalc = value end,
        default = MasterMerchant.systemDefault.modifiedSuggestedPriceDealCalc,
        disabled = function() return not (MasterMerchant.systemSavedVariables.dealCalcToUse == MM_PRICE_TTC_SUGGESTED) end,
      },
    },
  }
  -- 9 guild roster menu
  optionsData[#optionsData + 1] = {
    type = 'submenu',
    name = GetString(MM_GUILD_ROSTER_OPTIONS_NAME),
    tooltip = GetString(MM_GUILD_ROSTER_OPTIONS_TIP),
    controls = {
      -- should we display info on guild roster?
      [1] = {
        type = 'checkbox',
        name = GetString(SK_ROSTER_INFO_NAME),
        tooltip = GetString(SK_ROSTER_INFO_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.diplayGuildInfo end,
        setFunc = function(value)

          MasterMerchant.systemSavedVariables.diplayGuildInfo = value
          --[[
          if self.UI_GuildTime then
            self.UI_GuildTime:SetHidden(not value)
          end

          for key, column in pairs(self.guild_columns) do
            column:IsDisabled(not value)
          end
          ]]--

          ReloadUI()

        end,
        default = MasterMerchant.systemDefault.diplayGuildInfo,
        warning = GetString(MM_RELOADUI_WARN),
      },
      [2] = {
        type = 'checkbox',
        name = GetString(MM_SALES_COLUMN_NAME),
        tooltip = GetString(MM_SALES_COLUMN_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.diplaySalesInfo end,
        setFunc = function(value)
          MasterMerchant.systemSavedVariables.diplaySalesInfo = value
          MasterMerchant.guild_columns['sold']:IsDisabled(not value)
        end,
        disabled = function() return not MasterMerchant.systemSavedVariables.diplayGuildInfo end,
        default = MasterMerchant.systemDefault.diplaySalesInfo,
      },
      -- guild roster options
      [3] = {
        type = 'checkbox',
        name = GetString(MM_PURCHASES_COLUMN_NAME),
        tooltip = GetString(MM_PURCHASES_COLUMN_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.diplayPurchasesInfo end,
        setFunc = function(value)
          MasterMerchant.systemSavedVariables.diplayPurchasesInfo = value
          MasterMerchant.guild_columns['bought']:IsDisabled(not value)
        end,
        disabled = function() return not MasterMerchant.systemSavedVariables.diplayGuildInfo end,
        default = MasterMerchant.systemDefault.diplayPurchasesInfo,
      },
      [4] = {
        type = 'checkbox',
        name = GetString(MM_TAXES_COLUMN_NAME),
        tooltip = GetString(MM_TAXES_COLUMN_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.diplayTaxesInfo end,
        setFunc = function(value)
          MasterMerchant.systemSavedVariables.diplayTaxesInfo = value
          MasterMerchant.guild_columns['per']:IsDisabled(not value)
        end,
        disabled = function() return not MasterMerchant.systemSavedVariables.diplayGuildInfo end,
        default = MasterMerchant.systemDefault.diplayTaxesInfo,
      },
      [5] = {
        type = 'checkbox',
        name = GetString(MM_COUNT_COLUMN_NAME),
        tooltip = GetString(MM_COUNT_COLUMN_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.diplayCountInfo end,
        setFunc = function(value)
          MasterMerchant.systemSavedVariables.diplayCountInfo = value
          MasterMerchant.guild_columns['count']:IsDisabled(not value)
        end,
        disabled = function() return not MasterMerchant.systemSavedVariables.diplayGuildInfo end,
        default = MasterMerchant.systemDefault.diplayCountInfo,
      },
    },
  }
  -- 10 Other Tooltips -----------------------------------
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(MASTER_MERCHANT_TOOLTIP_OPTIONS),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#OtherTooltipOptions",
  }
  -- Whether or not to show the pricing graph in tooltips
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_SHOW_GRAPH_NAME),
    tooltip = GetString(SK_SHOW_GRAPH_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showGraph end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showGraph = value end,
    default = MasterMerchant.systemDefault.showGraph,
  }
  -- Whether or not to show the pricing data in tooltips
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_SHOW_PRICING_NAME),
    tooltip = GetString(SK_SHOW_PRICING_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showPricing end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showPricing = value end,
    default = MasterMerchant.systemDefault.showPricing,
  }
  -- Whether or not to show the alternate TTC price in tooltips
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_SHOW_TTC_PRICE_NAME),
    tooltip = GetString(SK_SHOW_TTC_PRICE_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showAltTtcTipline end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showAltTtcTipline = value end,
    default = MasterMerchant.systemDefault.showAltTtcTipline,
  }
  -- Whether or not to show the bonanza price in tooltips
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_SHOW_BONANZA_PRICE_NAME),
    tooltip = GetString(SK_SHOW_BONANZA_PRICE_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showBonanzaPricing end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showBonanzaPricing = value end,
    default = MasterMerchant.systemDefault.showBonanzaPricing,
  }
  -- Whether or not to show the bonanza price if less then 6 listings
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_BONANZA_PRICEONGRAPH_NAME),
    tooltip = GetString(MM_BONANZA_PRICEONGRAPH_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.omitBonanzaPricingGraphLessThanSix end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.omitBonanzaPricingGraphLessThanSix = value end,
    default = MasterMerchant.systemDefault.omitBonanzaPricingGraphLessThanSix,
  }
  -- Whether or not to show tooltips on the graph points
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_GRAPH_INFO_NAME),
    tooltip = GetString(MM_GRAPH_INFO_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.displaySalesDetails end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.displaySalesDetails = value
      MasterMerchant:ResetItemInformationCache()
    end,
    default = MasterMerchant.systemDefault.displaySalesDetails,
  }
  -- Whether or not to show the crafting costs data in tooltips
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_SHOW_CRAFT_COST_NAME),
    tooltip = GetString(SK_SHOW_CRAFT_COST_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showCraftCost end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showCraftCost = value end,
    default = MasterMerchant.systemDefault.showCraftCost,
  }
  -- Whether or not to show the material cost data in tooltips
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_SHOW_MATERIAL_COST_NAME),
    tooltip = GetString(SK_SHOW_MATERIAL_COST_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showMaterialCost end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showMaterialCost = value end,
    default = MasterMerchant.systemDefault.showMaterialCost,
  }
  -- Whether or not to show the quality/level adjustment buttons
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_LEVEL_QUALITY_NAME),
    tooltip = GetString(MM_LEVEL_QUALITY_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.displayItemAnalysisButtons end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.displayItemAnalysisButtons = value end,
    default = MasterMerchant.systemDefault.displayItemAnalysisButtons,
  }
  -- should we trim outliers prices?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_TRIM_OUTLIERS_NAME),
    tooltip = GetString(SK_TRIM_OUTLIERS_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.trimOutliers end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.trimOutliers = value
      MasterMerchant:ResetItemInformationCache()
    end,
    default = MasterMerchant.systemDefault.trimOutliers,
  }
  -- should we trim off decimals?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_TRIM_DECIMALS_NAME),
    tooltip = GetString(SK_TRIM_DECIMALS_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.trimDecimals end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.trimDecimals = value end,
    default = MasterMerchant.systemDefault.trimDecimals,
  }
  -- Section: Price To Chat and Graphtip Options
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(MM_PTC_OPTIONS_HEADER),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#PriceToChatOptions",
  }
  -- Whether or not to show individual item count
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_PTC_CONDENSED_FORMAT_NAME),
    tooltip = GetString(MM_PTC_CONDENSED_FORMAT_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.useCondensedPriceToChat end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.useCondensedPriceToChat = value end,
    default = MasterMerchant.systemDefault.useCondensedPriceToChat,
  }
  -- Whether or not to show ttc info
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_PTC_TTC_DATA_NAME),
    tooltip = GetString(MM_PTC_TTC_DATA_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.includeTTCDataPriceToChat end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.includeTTCDataPriceToChat = value end,
    default = MasterMerchant.systemDefault.includeTTCDataPriceToChat,
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_PTC_ITEM_COUNT_NAME),
    tooltip = GetString(MM_PTC_ITEM_COUNT_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.includeItemCountPriceToChat end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.includeItemCountPriceToChat = value end,
    default = MasterMerchant.systemDefault.includeItemCountPriceToChat,
    disabled = function() return MasterMerchant.systemSavedVariables.useCondensedPriceToChat end,
  }
  -- Whether or not to show the bonanza price if less then 6 listings
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_PTC_BONANZA_NAME),
    tooltip = GetString(MM_PTC_BONANZA_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.omitBonanzaPricingChatLessThanSix end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.omitBonanzaPricingChatLessThanSix = value end,
    default = MasterMerchant.systemDefault.omitBonanzaPricingChatLessThanSix,
  }
  -- should we ommit price per voucher?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_PTC_ADD_VOUCHER_NAME),
    tooltip = GetString(MM_PTC_ADD_VOUCHER_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.includeVoucherAverage end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.includeVoucherAverage = value end,
    default = MasterMerchant.systemDefault.includeVoucherAverage,
  }
  -- replace inventory value type
  optionsData[#optionsData + 1] = {
    type = 'dropdown',
    name = GetString(MM_PTC_VOUCHER_VALUE_TYPE_NAME),
    tooltip = GetString(MM_PTC_VOUCHER_VALUE_TYPE_TIP),
    choices = MasterMerchant.dealCalcChoices,
    choicesValues = MasterMerchant.dealCalcValues,
    getFunc = function() return MasterMerchant.systemSavedVariables.voucherValueTypeToUse end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.voucherValueTypeToUse = value
      CheckVoucherValue()
    end,
    default = MasterMerchant.systemDefault.voucherValueTypeToUse,
    disabled = function() return not MasterMerchant.systemSavedVariables.includeVoucherAverage end,
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_MODIFIED_TTC_SUGGESTED_NAME),
    tooltip = GetString(MM_MODIFIED_TTC_SUGGESTED_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.modifiedSuggestedPriceVoucher end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.modifiedSuggestedPriceVoucher = value end,
    default = MasterMerchant.systemDefault.modifiedSuggestedPriceVoucher,
    disabled = function() return (not MasterMerchant.systemSavedVariables.includeVoucherAverage) or (MasterMerchant.systemSavedVariables.voucherValueTypeToUse ~= MM_PRICE_TTC_SUGGESTED) end,
  }
  -- Section: Inventory Options
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(MASTER_MERCHANT_INVENTORY_OPTIONS),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#InventoryOptions",
  }
  -- should we replace inventory values?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_REPLACE_INVENTORY_VALUES_NAME),
    tooltip = GetString(MM_REPLACE_INVENTORY_VALUES_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.replaceInventoryValues end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.replaceInventoryValues = value end,
    default = MasterMerchant.systemDefault.replaceInventoryValues,
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_REPLACE_INVENTORY_SHOW_UNITPRICE_NAME),
    tooltip = GetString(MM_REPLACE_INVENTORY_SHOW_UNITPRICE_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showUnitPrice end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showUnitPrice = value end,
    default = MasterMerchant.systemDefault.showUnitPrice,
    disabled = function() return not MasterMerchant.systemSavedVariables.replaceInventoryValues end,
  }
  -- replace inventory value type
  optionsData[#optionsData + 1] = {
    type = 'dropdown',
    name = GetString(MM_REPLACE_INVENTORY_VALUE_TYPE_NAME),
    tooltip = GetString(MM_REPLACE_INVENTORY_VALUE_TYPE_TIP),
    choices = MasterMerchant.dealCalcChoices,
    choicesValues = MasterMerchant.dealCalcValues,
    getFunc = function() return MasterMerchant.systemSavedVariables.replacementTypeToUse end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.replacementTypeToUse = value
      CheckInventoryValue()
    end,
    default = MasterMerchant.systemDefault.replacementTypeToUse,
    disabled = function() return not MasterMerchant.systemSavedVariables.replaceInventoryValues end,
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_MODIFIED_TTC_SUGGESTED_NAME),
    tooltip = GetString(MM_MODIFIED_TTC_SUGGESTED_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.modifiedSuggestedPriceInventory end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.modifiedSuggestedPriceInventory = value end,
    default = MasterMerchant.systemDefault.modifiedSuggestedPriceInventory,
    disabled = function() return (not MasterMerchant.systemSavedVariables.replaceInventoryValues) or (MasterMerchant.systemSavedVariables.replacementTypeToUse ~= MM_PRICE_TTC_SUGGESTED) end,
  }
  -- hide Bonanza context menu
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_SHOW_SEARCH_BONANZA_NAME),
    tooltip = GetString(MM_SHOW_SEARCH_BONANZA_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showSearchBonanza end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showSearchBonanza = value end,
    default = MasterMerchant.systemDefault.showSearchBonanza,
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GUILD_STORE_OPTIONS),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#GuildStoreOptions",
  }
  -- Should we show the stack price calculator in the Vanilla UI?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_CALC_NAME),
    tooltip = GetString(SK_CALC_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showCalc end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showCalc = value end,
    default = MasterMerchant.systemDefault.showCalc,
    disabled = function() return MasterMerchant.AwesomeGuildStoreDetected end,
  }
  -- Should we use one price for all or save by guild?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_ALL_CALC_NAME),
    tooltip = GetString(SK_ALL_CALC_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.priceCalcAll end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.priceCalcAll = value end,
    default = MasterMerchant.systemDefault.priceCalcAll,
  }
  -- should we display a Min Profit Filter in AGS?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_MIN_PROFIT_FILTER_NAME),
    tooltip = GetString(MM_MIN_PROFIT_FILTER_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.minProfitFilter end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.minProfitFilter = value end,
    default = MasterMerchant.systemDefault.minProfitFilter,
    disabled = function() return not MasterMerchant.AwesomeGuildStoreDetected end,
    warning = GetString(MM_RELOADUI_WARN),
  }
  -- should we display profit instead of margin?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_DISPLAY_PROFIT_NAME),
    tooltip = GetString(MM_DISPLAY_PROFIT_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.displayProfit end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.displayProfit = value end,
    default = MasterMerchant.systemDefault.displayProfit,
  }
  -- ascending vs descending sort order with AGS
  optionsData[#optionsData + 1] = {
    type = 'dropdown',
    name = GetString(AGS_PERCENT_ORDER_NAME),
    tooltip = GetString(AGS_PERCENT_ORDER_DESC),
    choices = MasterMerchant.agsPercentSortChoices,
    choicesValues = MasterMerchant.agsPercentSortValues,
    getFunc = function() return MasterMerchant.systemSavedVariables.agsPercentSortOrderToUse end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.agsPercentSortOrderToUse = value end,
    default = MasterMerchant.systemDefault.agsPercentSortOrderToUse,
    disabled = function() return not MasterMerchant.AwesomeGuildStoreDetected end,
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GUILD_MASTER_OPTIONS),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#GuildMasterOptions",
  }
  -- should we add taxes to the export?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_SHOW_AMOUNT_TAXES_NAME),
    tooltip = GetString(MM_SHOW_AMOUNT_TAXES_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showAmountTaxes end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showAmountTaxes = value end,
    default = MasterMerchant.systemDefault.showAmountTaxes,
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(MASTER_MERCHANT_DEBUG_OPTIONS),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#MMDebugOptions",
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_DEBUG_LOGGER_NAME),
    tooltip = GetString(MM_DEBUG_LOGGER_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.useLibDebugLogger end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.useLibDebugLogger = value end,
    default = MasterMerchant.systemDefault.useLibDebugLogger,
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_DISABLE_ATT_WARN_NAME),
    tooltip = GetString(MM_DISABLE_ATT_WARN_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.disableAttWarn end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.disableAttWarn = value end,
    default = MasterMerchant.systemDefault.disableAttWarn,
  }

  -- And make the options panel
  LAM:RegisterOptionControls('MasterMerchantOptions', optionsData)
end

function MasterMerchant:SpecialMessage(force)
  if GetDisplayName() == '@sylviermoone' or (GetDisplayName() == '@Philgo68' and force) then
    local daysCount = math.floor(((GetTimeStamp() - (1460980800 + 38 * ZO_ONE_DAY_IN_SECONDS + 19 * ZO_ONE_HOUR_IN_SECONDS)) / ZO_ONE_DAY_IN_SECONDS) * 4) / 4
    if (daysCount > (MasterMerchant.systemSavedVariables.daysPast or 0)) or force then
      MasterMerchant.systemSavedVariables.daysPast = daysCount

      local rem = daysCount - math.floor(daysCount)
      daysCount = math.floor(daysCount)

      if rem == 0 then
        MasterMerchant.CenterScreenAnnounce_AddMessage('MasterMerchantAlert', CSA_EVENT_SMALL_TEXT,
          "Objective_Complete",
          string.format("Keep it up!!  You've made it %s complete days!!", daysCount))
      end

      if rem == 0.25 then
        MasterMerchant.CenterScreenAnnounce_AddMessage('MasterMerchantAlert', CSA_EVENT_SMALL_TEXT,
          "Objective_Complete",
          string.format("Working your way through day %s...", daysCount + 1))
      end

      if rem == 0.5 then
        MasterMerchant.CenterScreenAnnounce_AddMessage('MasterMerchantAlert', CSA_EVENT_SMALL_TEXT,
          "Objective_Complete",
          string.format("Day %s half way done!", daysCount + 1))
      end

      if rem == 0.75 then
        MasterMerchant.CenterScreenAnnounce_AddMessage('MasterMerchantAlert', CSA_EVENT_SMALL_TEXT,
          "Objective_Complete",
          string.format("Just a little more to go in day %s...", daysCount + 1))
      end

    end
  end
end

function MasterMerchant:ExportSalesReport()
  local export = ZO_SavedVars:NewAccountWide('ShopkeeperSavedVars', 1, "EXPORT", {}, nil)

  local numGuilds = GetNumGuilds()
  local guildNum = self.guildNumber
  if guildNum > numGuilds then
    MasterMerchant:dm("Info", GetString(MM_EXPORTING_INVALID))
    return
  end

  local guildID = GetGuildId(guildNum)
  local guildName = GetGuildName(guildID)

  MasterMerchant:dm("Info", string.format(GetString(MM_EXPORTING), guildName))
  export[guildName] = {}
  local list = export[guildName]

  local numGuildMembers = GetNumGuildMembers(guildID)
  for guildMemberIndex = 1, numGuildMembers do
    local displayName, note, rankIndex, status, secsSinceLogoff = GetGuildMemberInfo(guildID, guildMemberIndex)

    local amountBought = 0
    if internal.guildPurchases and
      internal.guildPurchases[guildName] and
      internal.guildPurchases[guildName].sellers and
      internal.guildPurchases[guildName].sellers[displayName] and
      internal.guildPurchases[guildName].sellers[displayName].sales then
      amountBought = internal.guildPurchases[guildName].sellers[displayName].sales[MasterMerchant.systemSavedVariables.rankIndexRoster] or 0
    end

    local amountSold = 0
    if internal.guildSales and
      internal.guildSales[guildName] and
      internal.guildSales[guildName].sellers and
      internal.guildSales[guildName].sellers[displayName] and
      internal.guildSales[guildName].sellers[displayName].sales then
      amountSold = internal.guildSales[guildName].sellers[displayName].sales[MasterMerchant.systemSavedVariables.rankIndexRoster] or 0
    end

    -- sample [2] = "@Name&Sales&Purchases&Rank"
    local amountTaxes = 0
    amountTaxes = math.floor(amountSold * 0.035)
    if MasterMerchant.systemSavedVariables.showAmountTaxes then
      table.insert(list, displayName .. "&" .. amountSold .. "&" .. amountBought .. "&" .. amountTaxes .. "&" .. rankIndex)
    else
      table.insert(list, displayName .. "&" .. amountSold .. "&" .. amountBought .. "&" .. rankIndex)
    end
  end

end

function MasterMerchant:ExportSalesActivity()
  local export = ZO_SavedVars:NewAccountWide('ShopkeeperSavedVars', 1, "SALES", {}, nil)

  local numGuilds = GetNumGuilds()
  local guildNum = self.guildNumber
  local guildID
  local guildName

  if guildNum > numGuilds then
    guildName = 'ALL'
  else
    guildID = GetGuildId(guildNum)
    guildName = GetGuildName(guildID)
  end
  export[guildName] = {}
  local list = export[guildName]

  local epochStart = MasterMerchant.dateRanges[MasterMerchant.systemSavedVariables.rankIndexRoster].startTimestamp
  local epochEnd = nil
  if MasterMerchant.dateRanges[MasterMerchant.systemSavedVariables.rankIndexRoster].endTimestamp then
    epochEnd = MasterMerchant.dateRanges[MasterMerchant.systemSavedVariables.rankIndexRoster].endTimestamp
  end
  local function ValidDaterange(timestamp)
    if epochEnd then
      if timestamp >= epochStart and timestamp < epochEnd then return true end
    else
      if timestamp >= epochStart then return true end
    end
    return false
  end

  for _, v in pairs(sales_data) do
    for _, dataList in pairs(v) do
      if dataList['sales'] then
        for _, sale in pairs(dataList['sales']) do
          local currentItemLink = internal:GetItemLinkByIndex(sale['itemLink'])
          local currentGuild = internal:GetGuildNameByIndex(sale['guild'])
          local currentBuyer = internal:GetAccountNameByIndex(sale['buyer'])
          local currentSeller = internal:GetAccountNameByIndex(sale['seller'])
          if ValidDaterange(sale.timestamp) and (guildName == 'ALL' or guildName == currentGuild) then
            table.insert(list,
              currentSeller .. "&" ..
                currentBuyer .. "&" ..
                currentItemLink .. "&" ..
                sale.quant .. "&" ..
                sale.timestamp .. "&" ..
                tostring(sale.wasKiosk) .. "&" ..
                sale.price .. "&" ..
                currentGuild .. "&" ..
                dataList['itemDesc'] .. "&" ..
                dataList['itemAdderText']
            )
          end
        end
      end
    end
  end

end

function MasterMerchant:ExportPersonalSales()
  local export = ZO_SavedVars:NewAccountWide('ShopkeeperSavedVars', 1, "PERSONALSALES", {}, nil)
  local numGuilds = GetNumGuilds()
  local guildNum = self.guildNumber
  local guildID = GetGuildId(guildNum)
  local guildName = GetGuildName(guildID)
  export[guildName] = {}
  local list = export[guildName]
  local playerName = zo_strlower(GetDisplayName())

  local epochStart = MasterMerchant.dateRanges[MasterMerchant.systemSavedVariables.rankIndexRoster].startTimestamp
  local epochEnd = nil
  if MasterMerchant.dateRanges[MasterMerchant.systemSavedVariables.rankIndexRoster].endTimestamp then
    epochEnd = MasterMerchant.dateRanges[MasterMerchant.systemSavedVariables.rankIndexRoster].endTimestamp
  end
  local function ValidDaterange(timestamp)
    if epochEnd then
      if timestamp >= epochStart and timestamp < epochEnd then return true end
    else
      if timestamp >= epochStart then return true end
    end
    return false
  end

  for _, v in pairs(sales_data) do
    for _, dataList in pairs(v) do
      if dataList['sales'] then
        for _, sale in pairs(dataList['sales']) do
          local currentGuild = internal:GetGuildNameByIndex(sale['guild'])
          local currentBuyer = internal:GetAccountNameByIndex(sale['buyer'])
          local currentSeller = internal:GetAccountNameByIndex(sale['seller'])
          local isSelfSale = playerName == zo_strlower(currentSeller)
          if ValidDaterange(sale.timestamp) and isSelfSale and guildName == currentGuild then
            table.insert(list,
              currentSeller .. "&" ..
                currentBuyer .. "&" ..
                currentGuild .. "&" ..
                sale.quant .. "&" ..
                dataList['itemDesc'] .. "&" ..
                sale.price .. "&" ..
                sale.timestamp
            )
          end
        end
      end
    end
  end

end

function MasterMerchant:ExportShoppingList()
  local export = ZO_SavedVars:NewAccountWide('ShopkeeperSavedVars', 1, "PURCHASES", {}, nil)
  export["data"] = {}
  local list = export["data"]
  local epochStart = MasterMerchant.dateRanges[MasterMerchant.systemSavedVariables.rankIndexRoster].startTimestamp
  local epochEnd = nil
  if MasterMerchant.dateRanges[MasterMerchant.systemSavedVariables.rankIndexRoster].endTimestamp then
    epochEnd = MasterMerchant.dateRanges[MasterMerchant.systemSavedVariables.rankIndexRoster].endTimestamp
  end
  local function ValidDaterange(timestamp)
    if epochEnd then
      if timestamp >= epochStart and timestamp < epochEnd then return true end
    else
      if timestamp >= epochStart then return true end
    end
    return false
  end

  for _, v in pairs(purchases_data) do
    for _, dataList in pairs(v) do
      if dataList['sales'] then
        for _, sale in pairs(dataList['sales']) do
          local currentGuild = internal:GetGuildNameByIndex(sale['guild'])
          local currentSeller = internal:GetAccountNameByIndex(sale['seller'])
          local currentBuyer = internal:GetAccountNameByIndex(sale['buyer'])
          if ValidDaterange(sale.timestamp) then
            table.insert(list,
              currentSeller .. "&" ..
                currentBuyer .. "&" ..
                currentGuild .. "&" ..
                sale.quant .. "&" ..
                dataList['itemDesc'] .. "&" ..
                sale.price .. "&" ..
                sale.timestamp
            )
          end
        end
      end
    end
  end

end

-- Called after store scans complete, re-creates indexes if need be,
-- and updates the slider range. Once this is done it updates the
-- displayed table, sending a message to chat if the scan was initiated
-- via the 'refresh' or 'reset' buttons.

function MasterMerchant:PostScanParallel(guildName, doAlert)
  if not MasterMerchant.isInitialized then return end
  -- If the index is blank (first scan after login or after reset),
  -- build the indexes now that we have a scanned table.
  -- self:setScanningParallel(false, guildName)

  -- If there's anything in the alert queue, handle it.
  if #internal.alertQueue[guildName] > 0 then
    -- Play an alert chime once if there are any alerts in the queue
    if MasterMerchant.systemSavedVariables.showChatAlerts or MasterMerchant.systemSavedVariables.showAnnounceAlerts then
      PlaySound(MasterMerchant.systemSavedVariables.alertSoundName)
    end

    local numSold = 0
    local totalGold = 0
    local numAlerts = #internal.alertQueue[guildName]
    local lastEvent = {}
    -- theEvent in the alertQueue is not altered so no lookup is needed
    for i = 1, numAlerts do
      local theEvent = table.remove(internal.alertQueue[guildName], 1)
      numSold = numSold + 1
      --[[
      local theEvent = {
        buyer = p2,
        guild = guildName,
        itemName = p4,
        quant = p3,
        saleTime = eventTime,
        salePrice = p5,
        seller = p1,
        kioskSale = false,
        id = Id64ToString(eventId)
      }
      local newSalesItem =
        {buyer = theEvent.buyer,
        guild = theEvent.guild,
        itemLink = theEvent.itemName,
        quant = tonumber(theEvent.quant),
        timestamp = tonumber(theEvent.saleTime),
        price = tonumber(theEvent.salePrice),
        seller = theEvent.seller,
        wasKiosk = theEvent.kioskSale,
        id = theEvent.id
      }
      [1] =
      {
        ["price"] = 120,
        ["itemLink"] = "|H0:item:45057:359:50:26848:359:50:0:0:0:0:0:0:0:0:0:5:0:0:0:0:0|h|h",
        ["id"] = 1353657539,
        ["guild"] = "Unstable Unicorns",
        ["buyer"] = "@Traeky",
        ["quant"] = 1,
        ["wasKiosk"] = true,
        ["timestamp"] = 1597969403,
        ["seller"] = "@cherrypick",
      },
      ]]--

      -- Adjust the price if they want the post-cut prices instead
      local dispPrice = theEvent.price
      if not MasterMerchant.systemSavedVariables.showFullPrice then
        local cutPrice = dispPrice * (1 - (GetTradingHouseCutPercentage() / 100))
        dispPrice = math.floor(cutPrice + 0.5)
      end
      totalGold = totalGold + dispPrice

      -- Offline sales report
      if MasterMerchant.isFirstScan and MasterMerchant.systemSavedVariables.offlineSales then
        local stringPrice = self.LocalizedNumber(dispPrice)
        local textTime = self.TextTimeSince(theEvent.timestamp)
        if i == 1 then
          MasterMerchant:dm("Info", MasterMerchant.concat(GetString(MM_APP_MESSAGE_NAME), GetString(SK_SALES_REPORT)))
        end
        MasterMerchant:dm("Info", zo_strformat('<<t:1>>', theEvent.itemLink) .. GetString(MM_APP_TEXT_TIMES) .. theEvent.quant .. MM_STRING_SEPARATOR_DASHES .. stringPrice .. MM_COIN_ICON_LEADING_SPACE .. MM_STRING_SEPARATOR_DASHES .. theEvent.guild)
        if i == numAlerts then
          -- Total of offline sales
          MasterMerchant:dm("Info", string.format(GetString(SK_SALES_ALERT_GROUP), numAlerts, self.LocalizedNumber(totalGold)))
          MasterMerchant:dm("Info", MasterMerchant.concat(GetString(MM_APP_MESSAGE_NAME), GetString(SK_SALES_REPORT_END)))
        end
      else
        -- Else ends of Offline sales report

        -- Any additional on screen alerts
        -- If they want multiple alerts, we'll alert on each loop iteration
        -- or if there's only one.
        if MasterMerchant.systemSavedVariables.showMultiple or numAlerts == 1 then
          -- Insert thousands separators for the price
          local stringPrice = self.LocalizedNumber(dispPrice)

          -- On-screen alert; map index 37 is Cyrodiil
          if MasterMerchant.systemSavedVariables.showAnnounceAlerts and
            (MasterMerchant.systemSavedVariables.showCyroAlerts or GetCurrentMapZoneIndex ~= 37) then

            -- We'll add a numerical suffix to avoid queueing two identical messages in a row
            -- because the alerts will 'miss' if we do
            local textTime = self.TextTimeSince(theEvent.timestamp)
            local alertSuffix = ''
            if lastEvent[1] ~= nil and theEvent.itemLink == lastEvent[1].itemLink and textTime == lastEvent[2] then
              lastEvent[3] = lastEvent[3] + 1
              alertSuffix = ' (' .. lastEvent[3] .. ')'
            else
              lastEvent[1] = theEvent
              lastEvent[2] = textTime
              lastEvent[3] = 1
            end
            MasterMerchant.CenterScreenAnnounce_AddMessage('MasterMerchantAlert', CSA_EVENT_SMALL_TEXT, SOUNDS.NONE, string.format(GetString(SK_SALES_ALERT_COLOR), zo_strformat('<<t:1>>', theEvent.itemLink), theEvent.quant, stringPrice, theEvent.guild, textTime) .. alertSuffix)
          end -- End of on screen announce

          -- Chat alert
          if MasterMerchant.systemSavedVariables.showChatAlerts then
            MasterMerchant:dm("Info", string.format(MasterMerchant.concat(GetString(MM_APP_MESSAGE_NAME), GetString(SK_SALES_ALERT)), zo_strformat('<<t:1>>', theEvent.itemLink), theEvent.quant, stringPrice, theEvent.guild, self.TextTimeSince(theEvent.timestamp)))
          end -- End of show chat alert
        end -- End of multiple alerts or numAlerts == 1

      end -- End of Offline sales report or show all sales reports

      -- Otherwise, we'll just alert once with a summary at the end
      if not MasterMerchant.systemSavedVariables.showMultiple and numAlerts > 1 then
        -- Insert thousands separators for the price
        local stringPrice = self.LocalizedNumber(totalGold)

        if MasterMerchant.systemSavedVariables.showAnnounceAlerts and (MasterMerchant.systemSavedVariables.showCyroAlerts or GetCurrentMapZoneIndex ~= 37) then
          MasterMerchant.CenterScreenAnnounce_AddMessage('MasterMerchantAlert', CSA_EVENT_SMALL_TEXT, MasterMerchant.systemSavedVariables.alertSoundName, string.format(GetString(SK_SALES_ALERT_GROUP_COLOR), numSold, stringPrice))
        end

        -- Chat alert
        if MasterMerchant.systemSavedVariables.showChatAlerts then
          MasterMerchant:dm("Info", string.format(MasterMerchant.concat(GetString(MM_APP_MESSAGE_NAME), GetString(SK_SALES_ALERT_GROUP)), numSold, stringPrice))
        end
      end -- End of once with a summary

    end -- End for loop of the queue
  end -- End of if #numalerts

  --self:SpecialMessage(false)

  -- Set the stats slider past the max if this is brand new data
  if MasterMerchant.isFirstScan and doAlert then MasterMerchantStatsWindowSlider:SetValue(15) end
  MasterMerchant.isFirstScan = false
end

function MasterMerchant:initGMTools()
  MasterMerchant:dm("Debug", "initGMTools")
  -- Stub for GM Tools init
end

function MasterMerchant:initPurchaseTracking()
  MasterMerchant:dm("Debug", "initPurchaseTracking")
  -- Stub for Purchase Tracking init
end

function MasterMerchant:initSellingAdvice()
  if MasterMerchant.originalSellingSetupCallback then return end

  if TRADING_HOUSE and TRADING_HOUSE.postedItemsList then

    local dataType = TRADING_HOUSE.postedItemsList.dataTypes[2]

    MasterMerchant.originalSellingSetupCallback = dataType.setupCallback
    if MasterMerchant.originalSellingSetupCallback then
      dataType.setupCallback = function(...)
        local row, data = ...
        MasterMerchant.originalSellingSetupCallback(...)
        zo_callLater(function() MasterMerchant.AddSellingAdvice(row, data) end, 1)
      end
    else
      MasterMerchant:dm("Debug", GetString(MM_ADVICE_ERROR))
    end
  end

  if TRADING_HOUSE_GAMEPAD then
  end
end

function MasterMerchant.AddSellingAdvice(rowControl, result)
  if not MasterMerchant.isInitialized then return end
  local sellingAdvice = rowControl:GetNamedChild('SellingAdvice')
  if (not sellingAdvice) then
    local controlName = rowControl:GetName() .. 'SellingAdvice'
    sellingAdvice = rowControl:CreateControl(controlName, CT_LABEL)

    local anchorControl = rowControl:GetNamedChild('TimeRemaining')
    local _, point, relTo, relPoint, offsX, offsY = anchorControl:GetAnchor(0)
    anchorControl:ClearAnchors()
    anchorControl:SetAnchor(point, relTo, relPoint, offsX, offsY - 10)

    sellingAdvice:SetAnchor(TOPLEFT, anchorControl, BOTTOMLEFT, 0, 0)
    sellingAdvice:SetFont('/esoui/common/fonts/univers67.otf|14|soft-shadow-thin')
  end

  --[[TODO make sure that the itemLink is not an empty string by mistake
  ]]--
  local itemLink = GetTradingHouseListingItemLink(result.slotIndex)
  if itemLink and itemLink ~= MM_STRING_EMPTY then
    local dealValue, margin, profit = MasterMerchant.GetDealInformation(itemLink, result.purchasePrice, result.stackCount)
    if dealValue then
      if dealValue > MM_DEAL_VALUE_DONT_SHOW then
        if MasterMerchant.systemSavedVariables.displayProfit then
          sellingAdvice:SetText(MasterMerchant.LocalizedNumber(profit) .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t')
        else
          sellingAdvice:SetText(string.format('%.2f', margin) .. '%')
        end
        -- TODO I think this colors the number in the guild store
        --[[
        ZO_Currency_FormatPlatform(CURT_MONEY, tonumber(stringPrice), ZO_CURRENCY_FORMAT_AMOUNT_ICON, {color: someColorDef})
        ]]--
        local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, dealValue)
        if dealValue == MM_DEAL_VALUE_OVERPRICED then
          r = 0.98;
          g = 0.01;
          b = 0.01;
        end
        sellingAdvice:SetColor(r, g, b, 1)
        sellingAdvice:SetHidden(false)
      else
        sellingAdvice:SetHidden(true)
      end
    else
      sellingAdvice:SetHidden(true)
    end
  end
  sellingAdvice = nil
end

function MasterMerchant:initBuyingAdvice()
  --[[Keyboard Mode has a TRADING_HOUSE.searchResultsList
  that is set to
  ZO_TradingHouseBrowseItemsRightPaneSearchResults and
  then from there, there is a
  dataTypes[1].dataType.setupCallback.

  This does not exist in GamepadMode
  ]]--
  if MasterMerchant.originalSetupCallback then return end
  if TRADING_HOUSE and TRADING_HOUSE.searchResultsList then

    local dataType = TRADING_HOUSE.searchResultsList.dataTypes[1]

    MasterMerchant.originalSetupCallback = dataType.setupCallback
    if MasterMerchant.originalSetupCallback then
      dataType.setupCallback = function(...)
        local row, data = ...
        MasterMerchant.originalSetupCallback(...)
        zo_callLater(function() MasterMerchant.AddBuyingAdvice(row, data) end, 1)
      end
    else
      MasterMerchant:dm("Debug", GetString(MM_ADVICE_ERROR))
    end
  end

  if TRADING_HOUSE_GAMEPAD then
  end
end

--[[ TODO update this for the colors and the value so that when there
isn't any buying advice then it is blank or 0
]]--
function MasterMerchant.AddBuyingAdvice(rowControl, result)
  if not MasterMerchant.isInitialized then return end
  local buyingAdvice = rowControl:GetNamedChild('BuyingAdvice')
  if (not buyingAdvice) then
    local controlName = rowControl:GetName() .. 'BuyingAdvice'
    buyingAdvice = rowControl:CreateControl(controlName, CT_LABEL)

    if (not AwesomeGuildStore) then
      local anchorControl = rowControl:GetNamedChild('SellPricePerUnit')
      local _, point, relTo, relPoint, offsX, offsY = anchorControl:GetAnchor(0)
      anchorControl:ClearAnchors()
      anchorControl:SetAnchor(point, relTo, relPoint, offsX, offsY + 10)
    end

    local anchorControl = rowControl:GetNamedChild('TimeRemaining')
    local _, point, relTo, relPoint, offsX, offsY = anchorControl:GetAnchor(0)
    anchorControl:ClearAnchors()
    anchorControl:SetAnchor(point, relTo, relPoint, offsX, offsY - 10)
    buyingAdvice:SetAnchor(TOPLEFT, anchorControl, BOTTOMLEFT, 0, 0)
    buyingAdvice:SetFont('/esoui/common/fonts/univers67.otf|14|soft-shadow-thin')
  end

  local index = result.slotIndex
  if (AwesomeGuildStore) then index = result.itemUniqueId end
  local itemLink = GetTradingHouseSearchResultItemLink(index)
  local dealValue, margin, profit = MasterMerchant.GetDealInformation(itemLink, result.purchasePrice, result.stackCount)
  if dealValue then
    if dealValue > MM_DEAL_VALUE_DONT_SHOW then
      if MasterMerchant.systemSavedVariables.displayProfit then
        buyingAdvice:SetText(MasterMerchant.LocalizedNumber(profit) .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t')
      else
        buyingAdvice:SetText(string.format('%.2f', margin) .. '%')
      end
      -- TODO I think this colors the number in the guild store
      local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, dealValue)
      if dealValue == MM_DEAL_VALUE_OVERPRICED then
        r = 0.98;
        g = 0.01;
        b = 0.01;
      end
      buyingAdvice:SetColor(r, g, b, 1)
      buyingAdvice:SetHidden(false)
    else
      buyingAdvice:SetHidden(true)
    end
  else
    buyingAdvice:SetHidden(true)
  end
  buyingAdvice = nil
end

function MasterMerchant:BuildRosterTimeDropdown()
  local timeDropdown = ZO_ComboBox_ObjectFromContainer(MasterMerchantRosterTimeChooser)
  timeDropdown:ClearItems()

  MasterMerchant.systemSavedVariables.rankIndexRoster = MasterMerchant.systemSavedVariables.rankIndexRoster or MM_DATERANGE_TODAY

  local timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_TODAY), function() self:UpdateRosterWindow(MM_DATERANGE_TODAY) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == MM_DATERANGE_TODAY then timeDropdown:SetSelectedItem(GetString(MM_INDEX_TODAY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_YESTERDAY), function() self:UpdateRosterWindow(MM_DATERANGE_YESTERDAY) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == MM_DATERANGE_YESTERDAY then timeDropdown:SetSelectedItem(GetString(MM_INDEX_YESTERDAY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_THISWEEK), function() self:UpdateRosterWindow(MM_DATERANGE_THISWEEK) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == MM_DATERANGE_THISWEEK then timeDropdown:SetSelectedItem(GetString(MM_INDEX_THISWEEK)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_LASTWEEK), function() self:UpdateRosterWindow(MM_DATERANGE_LASTWEEK) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == MM_DATERANGE_LASTWEEK then timeDropdown:SetSelectedItem(GetString(MM_INDEX_LASTWEEK)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_PRIORWEEK), function() self:UpdateRosterWindow(MM_DATERANGE_PRIORWEEK) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == MM_DATERANGE_PRIORWEEK then timeDropdown:SetSelectedItem(GetString(MM_INDEX_PRIORWEEK)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_7DAY), function() self:UpdateRosterWindow(MM_DATERANGE_7DAY) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == MM_DATERANGE_7DAY then timeDropdown:SetSelectedItem(GetString(MM_INDEX_7DAY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_10DAY), function() self:UpdateRosterWindow(MM_DATERANGE_10DAY) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == MM_DATERANGE_10DAY then timeDropdown:SetSelectedItem(GetString(MM_INDEX_10DAY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_30DAY), function() self:UpdateRosterWindow(MM_DATERANGE_30DAY) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == MM_DATERANGE_30DAY then timeDropdown:SetSelectedItem(GetString(MM_INDEX_30DAY)) end

  timeEntry = timeDropdown:CreateItemEntry(MasterMerchant.customTimeframeText, function() self:UpdateRosterWindow(MM_DATERANGE_CUSTOM) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == MM_DATERANGE_CUSTOM then timeDropdown:SetSelectedItem(MasterMerchant.customTimeframeText) end
end

--/script ZO_SharedRightBackground:SetWidth(1088)
function MasterMerchant:InitRosterChanges()
  if MasterMerchant.systemSavedVariables.diplayGuildInfo then
    MasterMerchant:dm("Debug", "InitRosterChanges")
  else
    MasterMerchant:dm("Debug", "Roster Changes not enabled")
    return
  end
  -- LibGuildRoster adding the Sold Column
  MasterMerchant.guild_columns['sold'] = LibGuildRoster:AddColumn({
    key = 'MM_Sold',
    disabled = not MasterMerchant.systemSavedVariables.diplayGuildInfo or not MasterMerchant.systemSavedVariables.diplaySalesInfo,
    width = 110,
    header = {
      title = GetString(SK_SALES_COLUMN),
      align = TEXT_ALIGN_RIGHT
    },
    row = {
      align = TEXT_ALIGN_RIGHT,
      data = function(guildId, data, index)

        local amountSold = 0

        if internal.guildSales and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName] and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName] and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales then

          amountSold = internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales[MasterMerchant.systemSavedVariables.rankIndexRoster or MM_DATERANGE_TODAY] or 0

        end

        return amountSold

      end,
      format = function(value)
        return MasterMerchant.LocalizedNumber(value) .. " |t16:16:EsoUI/Art/currency/currency_gold.dds|t"
      end
    }
  })

  -- LibGuildRoster adding the Bought Column
  MasterMerchant.guild_columns['bought'] = LibGuildRoster:AddColumn({
    key = 'MM_Bought',
    disabled = not MasterMerchant.systemSavedVariables.diplayGuildInfo or not MasterMerchant.systemSavedVariables.diplayPurchasesInfo,
    width = 110,
    header = {
      title = GetString(SK_PURCHASES_COLUMN),
      align = TEXT_ALIGN_RIGHT
    },
    row = {
      align = TEXT_ALIGN_RIGHT,
      data = function(guildId, data, index)

        local amountBought = 0

        if internal.guildPurchases and
          internal.guildPurchases[GUILD_ROSTER_MANAGER.guildName] and
          internal.guildPurchases[GUILD_ROSTER_MANAGER.guildName].sellers and
          internal.guildPurchases[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName] and
          internal.guildPurchases[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales then

          amountBought = internal.guildPurchases[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales[MasterMerchant.systemSavedVariables.rankIndexRoster or MM_DATERANGE_TODAY] or 0

        end

        return amountBought

      end,
      format = function(value)
        return MasterMerchant.LocalizedNumber(value) .. " |t16:16:EsoUI/Art/currency/currency_gold.dds|t"
      end
    }
  })

  -- LibGuildRoster adding the Tax Column
  MasterMerchant.guild_columns['per'] = LibGuildRoster:AddColumn({
    key = 'MM_PerChg',
    disabled = not MasterMerchant.systemSavedVariables.diplayGuildInfo or not MasterMerchant.systemSavedVariables.diplayTaxesInfo,
    width = 90,
    header = {
      title = GetString(SK_PER_CHANGE_COLUMN),
      align = TEXT_ALIGN_RIGHT,
      tooltip = GetString(SK_PER_CHANGE_TIP)
    },
    row = {
      align = TEXT_ALIGN_RIGHT,
      data = function(guildId, data, index)

        local amountSold = 0

        if internal.guildSales and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName] and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName] and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales then

          amountSold = internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales[MasterMerchant.systemSavedVariables.rankIndexRoster or MM_DATERANGE_TODAY] or 0
        end

        return math.floor(amountSold * 0.035)

      end,
      format = function(value)
        return MasterMerchant.LocalizedNumber(value) .. " |t16:16:EsoUI/Art/currency/currency_gold.dds|t"
      end
    }
  })

  -- LibGuildRoster adding the Count Column
  --[[ MM Note: I have no idea why anyone would want the count of sales?
  That's what this seems to be. However, as far as stats go it's about the only
  other usefull thing to display.
  ]]--
  MasterMerchant.guild_columns['count'] = LibGuildRoster:AddColumn({
    key = 'MM_Count',
    disabled = not MasterMerchant.systemSavedVariables.diplayGuildInfo or not MasterMerchant.systemSavedVariables.diplayCountInfo,
    width = 70,
    header = {
      title = GetString(SK_COUNT_COLUMN),
      align = TEXT_ALIGN_RIGHT
    },
    row = {
      align = TEXT_ALIGN_RIGHT,
      data = function(guildId, data, index)

        local saleCount = 0

        if internal.guildSales and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName] and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName] and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales then

          saleCount = internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].count[MasterMerchant.systemSavedVariables.rankIndexRoster or MM_DATERANGE_TODAY] or 0

        end

        return saleCount

      end,
      format = function(value)
        return MasterMerchant.LocalizedNumber(value)
      end
    }
  })

  -- Guild Time dropdown choice box
  MasterMerchant.UI_GuildTime = CreateControlFromVirtual('MasterMerchantRosterTimeChooser', ZO_GuildRoster, 'MasterMerchantStatsGuildDropdown')

  -- Placing Guild Time dropdown at the bottom of the Count Column when it has been generated
  LibGuildRoster:OnRosterReady(function()
    local countColumnControl = MasterMerchant.guild_columns['count']:GetHeader()
    local rosterListHeight = ZO_GuildRosterListContents:GetHeight()
    MasterMerchant.UI_GuildTime:SetAnchor(TOP, countColumnControl, BOTTOMRIGHT, -80, rosterListHeight)
    MasterMerchant.UI_GuildTime:SetDimensions(180, 25)

    -- Don't render the dropdown this cycle if the settings have columns disabled
    if not MasterMerchant.systemSavedVariables.diplayGuildInfo then
      MasterMerchant.UI_GuildTime:SetHidden(true)
    end

  end)

  MasterMerchant.UI_GuildTime.m_comboBox:SetSortsItems(false)

  MasterMerchant:BuildRosterTimeDropdown()
end

function MasterMerchant.TradingHouseSetupPendingPost(self)
  --MasterMerchant:dm("Debug", "TradingHouseSetupPendingPost")
  OriginalSetupPendingPost(self)

  if (self.pendingItemSlot) then
    local itemLink = GetItemLink(BAG_BACKPACK, self.pendingItemSlot)
    local _, stackCount, _ = GetItemInfo(BAG_BACKPACK, self.pendingItemSlot)

    local theIID = GetItemLinkItemId(itemLink)
    local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
    local selectedGuildId = GetSelectedTradingHouseGuildId()
    local pricingData = nil

    if MasterMerchant.systemSavedVariables.priceCalcAll then
      if GS17DataSavedVariables[internal.pricingNamespace] and GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"] and GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"][theIID] and GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"][theIID][itemIndex] then
        pricingData = GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"][theIID][itemIndex]
      end
    else
      if GS17DataSavedVariables[internal.pricingNamespace] and GS17DataSavedVariables[internal.pricingNamespace][selectedGuildId] and GS17DataSavedVariables[internal.pricingNamespace][selectedGuildId][theIID] and GS17DataSavedVariables[internal.pricingNamespace][selectedGuildId][theIID][itemIndex] then
        pricingData = GS17DataSavedVariables[internal.pricingNamespace][selectedGuildId][theIID][itemIndex]
      end
    end

    if pricingData then
      self:SetPendingPostPrice(math.floor(pricingData * stackCount))
    else
      local tipStats = MasterMerchant:ItemCacheStats(itemLink, false)
      if (tipStats.avgPrice) then
        self:SetPendingPostPrice(math.floor(tipStats.avgPrice * stackCount))
      end
    end
  end
end

local function CompleteMasterMerchantSetup()
  MasterMerchant:dm("Debug", "CompleteMasterMerchantSetup")
  local theFragment
  -- Add the MasterMerchant window to the mail and trading house scenes if the
  -- player's settings indicate they want that behavior
  MasterMerchant.salesUiFragment = ZO_FadeSceneFragment:New(MasterMerchantWindow)
  MasterMerchant.guildUiFragment = ZO_FadeSceneFragment:New(MasterMerchantGuildWindow)
  MasterMerchant.listingUiFragment = ZO_FadeSceneFragment:New(MasterMerchantListingWindow)
  MasterMerchant.purchaseUiFragment = ZO_FadeSceneFragment:New(MasterMerchantPurchaseWindow)
  MasterMerchant.reportsUiFragment = ZO_FadeSceneFragment:New(MasterMerchantReportsWindow)

  if MasterMerchant.systemSavedVariables.viewSize == ITEMS then theFragment = MasterMerchant.salesUiFragment end
  if MasterMerchant.systemSavedVariables.viewSize == GUILDS then theFragment = MasterMerchant.guildUiFragment end
  if MasterMerchant.systemSavedVariables.viewSize == LISTINGS then theFragment = MasterMerchant.listingUiFragment end
  if MasterMerchant.systemSavedVariables.viewSize == PURCHASES then theFragment = MasterMerchant.purchaseUiFragment end
  if MasterMerchant.systemSavedVariables.viewSize == REPORTS then theFragment = MasterMerchant.reportsUiFragment end
  if not theFragment then theFragment = MasterMerchant.salesUiFragment end

  if MasterMerchant.systemSavedVariables.openWithMail then
    MAIL_INBOX_SCENE:AddFragment(theFragment)
    MAIL_SEND_SCENE:AddFragment(theFragment)
  end

  if MasterMerchant.systemSavedVariables.openWithStore then
    TRADING_HOUSE_SCENE:AddFragment(theFragment)
  end

  MasterMerchant.isInitialized = true
  MasterMerchant.listIsDirty[ITEMS] = true
  MasterMerchant.listIsDirty[GUILDS] = true
  MasterMerchant.listIsDirty[LISTINGS] = true
  MasterMerchant.listIsDirty[PURCHASES] = true
  MasterMerchant.listIsDirty[REPORTS] = true
  MasterMerchant:dm("Info", string.format(GetString(MM_INITIALIZED), internal.totalSales, internal.totalPurchases, internal.totalListings, internal.totalPosted, internal.totalCanceled))
  -- LibAlchemy.SOURCE_MM = 1
  local libSource = 1
  LibAlchemy:InitializePrices(libSource)
end

-- ShopkeeperSavedVars["Default"]["MasterMerchant"]["$AccountWide"]
-- ["pricingData"]
-- self.savedVariables.verbose = value
-- self.acctSavedVariables.delayInit = nil
-- self:ActiveSettings().verbose = value
-- self.systemSavedVariables.verbose = value
-- MasterMerchant.systemSavedVariables.verbose = value
-- Init function
function MasterMerchant:FirstInitialize()
  MasterMerchant:dm("Debug", "FirstInitialize")
  -- SavedVar defaults
  local old_defaults = {
    dataLocations = {}, -- unused as of 5-15-2021 but has to stay here
    pricingData = {}, -- added 12-31 but has always been there
    historyDepth = 30,
    minItemCount = 20,
    maxItemCount = 5000,
    blacklist = '',
  }

  local systemDefault = {
    -- old settings
    dataLocations = {}, -- unused as of 5-15-2021 but has to stay here
    pricingData = {}, -- added 12-31 but has always been there
    showChatAlerts = false,
    showMultiple = true,
    openWithMail = true,
    openWithStore = true,
    showFullPrice = true,
    salesWinLeft = 10, -- winLeft
    salesWinTop = 85, -- winTop
    guildWinLeft = 10,
    guildWinTop = 85,
    listingWinLeft = 10,
    listingWinTop = 85,
    purchaseWinLeft = 10,
    purchaseWinTop = 85,
    reportsWinLeft = 10,
    reportsWinTop = 85,
    statsWinLeft = 720,
    statsWinTop = 820,
    feedbackWinLeft = 720,
    feedbackWinTop = 420,
    windowFont = "ProseAntique",
    showAnnounceAlerts = true,
    showCyroAlerts = true,
    alertSoundName = "Book_Acquired",
    showUnitPrice = false,
    viewSize = ITEMS,
    offlineSales = true,
    showPricing = true,
    showBonanzaPricing = true,
    useCondensedPriceToChat = false,
    omitBonanzaPricingGraphLessThanSix = false,
    omitBonanzaPricingChatLessThanSix = false,
    includeItemCountPriceToChat = false,
    includeTTCDataPriceToChat = true,
    includeVoucherAverage = false,
    voucherValueTypeToUse = MM_PRICE_MM_AVERAGE,
    isWindowMovable = false,
    showAltTtcTipline = true,
    showCraftCost = true,
    showMaterialCost = true,
    showGraph = true,
    showCalc = true,
    priceCalcAll = true,
    minProfitFilter = true,
    rankIndex = MM_DATERANGE_TODAY,
    rankIndexRoster = MM_DATERANGE_TODAY,
    viewBuyerSeller = 'buyer',
    viewGuildBuyerSeller = 'seller',
    trimOutliers = false,
    trimDecimals = false,
    replaceInventoryValues = false,
    replacementTypeToUse = MM_PRICE_MM_AVERAGE,
    displaySalesDetails = false,
    displayItemAnalysisButtons = false,
    focus1 = 10,
    focus2 = 3,
    focus3 = 30,
    blacklist = '',
    defaultDays = GetString(MM_RANGE_ALL),
    shiftDays = GetString(MM_RANGE_FOCUS1),
    ctrlDays = GetString(MM_RANGE_FOCUS2),
    ctrlShiftDays = GetString(MM_RANGE_FOCUS3),
    displayProfit = false,
    displayListingMessage = false,
    -- settingsToUse
    customTimeframe = 90,
    customTimeframeType = GetString(MM_CUSTOM_TIMEFRAME_DAYS),
    diplayGuildInfo = false,
    diplayPurchasesInfo = true,
    diplaySalesInfo = true,
    diplayTaxesInfo = true,
    diplayCountInfo = true,
    showAmountTaxes = false,
    useLibDebugLogger = false, -- added 11-28
    --[[TODO settings moved to LGS or removed
    ]]--
    -- conversion vars
    verThreeItemIDConvertedToString = false, -- this only converts id64 at this time
    shouldReindex = false,
    shouldAdderText = false,
    showGuildInitSummary = false,
    showIndexingSummary = false,
    lastReceivedEventID = {}, -- unused, see LGS
    --[[you could assign this as the default but it needs to be a global var instead
    customTimeframeText = tostring(90) .. ' ' .. GetString(MM_CUSTOM_TIMEFRAME_DAYS),

    Assigned to: MasterMerchant.customTimeframeText
    ]]--
    minimalIndexing = false,
    useSalesHistory = false,
    historyDepth = 30,
    minItemCount = 20,
    maxItemCount = 5000,
    disableAttWarn = false,
    dealCalcToUse = MM_PRICE_MM_AVERAGE,
    agsPercentSortOrderToUse = MM_AGS_SORT_PERCENT_ASCENDING,
    modifiedSuggestedPriceDealCalc = false,
    modifiedSuggestedPriceInventory = false,
    modifiedSuggestedPriceVoucher = false,
    showUnitPrice = false,
    showSearchBonanza = true,
    useFormatedTime = false,
    useTwentyFourHourTime = false,
    dateFormatMonthDay = MM_MONTH_DAY_FORMAT,
    customDealCalc = false,
    customDealBuyIt = 90,
    customDealSeventyFive = 75,
    customDealFifty = 50,
    customDealTwentyFive = 25,
    customDealZero = 0,
    windowTimeRange = MM_WINDOW_TIME_RANGE_DEFAULT,
    customFilterDateRange = 90,
  }

  -- Finished setting up defaults, assign to global
  MasterMerchant.systemDefault = systemDefault
  -- Populate savedVariables
  --[[TODO address saved vars
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM00DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM00DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')

  The above two lines from one of the
  ]]--
  --[[TODO Pick one
  self.savedVariables is used by the containers but with 'MasterMerchant' for the namespace
  self.acctSavedVariables seems to be no longer used
  self.systemSavedVariables is what is used when you are supposedly swaping between acoutwide
  or not such as

  example: MasterMerchant.systemSavedVariables.showChatAlerts = MasterMerchant.systemSavedVariables.showChatAlerts
  ]]--
  self.savedVariables = ZO_SavedVars:New('ShopkeeperSavedVars', 1, GetDisplayName(), old_defaults)
  --[[ MasterMerchant.systemSavedVariables.scanHistory is no longer used for MasterMerchant.systemSavedVariables.scanHistory
  acording to the comment below but elf.acctSavedVariables is used when you are supposedly
  swaping between acoutwide or not such as mentioned above

  ShopkeeperSavedVars["Default"]["MasterMerchant"]["$AccountWide"][GetUnitName("player")][GetDisplayName()]

  ^^^ For reference may not be correct
  ]]--
  self.acctSavedVariables = ZO_SavedVars:NewAccountWide('ShopkeeperSavedVars', 1, GetDisplayName(), old_defaults)
  self.systemSavedVariables = ZO_SavedVars:NewAccountWide('ShopkeeperSavedVars', 1, nil, systemDefault, nil, 'MasterMerchant')

  local sv = ShopkeeperSavedVars["Default"]["MasterMerchant"]["$AccountWide"]
  -- Clean up saved variables (from previous versions)
  for key, _ in pairs(sv) do
    -- Delete key-value pair if the key can't also be found in the default settings (except for version)
    if key ~= "version" and systemDefault[key] == nil then
      sv[key] = nil
    end
  end

  MasterMerchant:BuildDateRangeTable()
  MasterMerchant:BuildFilterDateRangeTable()
  MasterMerchant.blacklistTable = MasterMerchant:BuildTableFromString(MasterMerchant.systemSavedVariables.blacklist)

  -- TODO Check historyDepth is only set once on first run
  if LibGuildStore_SavedVariables[internal.firstrunNamespace] then
    MasterMerchant:dm("Debug", "Checked Old MM Settings")
    if MasterMerchant.systemSavedVariables.historyDepth then
      LibGuildStore_SavedVariables["historyDepth"] = math.max(MasterMerchant.systemSavedVariables.historyDepth,
        LibGuildStore_SavedVariables["historyDepth"])
    end
    if MasterMerchant.systemSavedVariables.minItemCount then
      LibGuildStore_SavedVariables["minItemCount"] = math.max(MasterMerchant.systemSavedVariables.minItemCount,
        LibGuildStore_SavedVariables["minItemCount"])
    end
    if MasterMerchant.systemSavedVariables.maxItemCount then
      LibGuildStore_SavedVariables["maxItemCount"] = math.max(MasterMerchant.systemSavedVariables.maxItemCount,
        LibGuildStore_SavedVariables["maxItemCount"])
    end
  end

  --[[ Added 8-27-2021, for some reason if the last view size on a reload UI
  or upon log in is something like LISTINGS then the game will hag for a while

  TODO figure out why it's doing that because I mark the list dirty and I don't
  want to refresh the data or the filter, unless this just happesn upon creation
  ]]--
  MasterMerchant.systemSavedVariables.viewSize = ITEMS

  MasterMerchant.systemSavedVariables.diplayGuildInfo = MasterMerchant.systemSavedVariables.diplayGuildInfo or false

  --MasterMerchant:CreateControls()

  -- updated 11-22 needs to be here to make string
  MasterMerchant.customTimeframeText = MasterMerchant.systemSavedVariables.customTimeframe .. ' ' .. MasterMerchant.systemSavedVariables.customTimeframeType

  --[[TODO find a better way then these hacks
  ]]--
  -- History Depth
  if self.acctSavedVariables.historyDepth then
    MasterMerchant.systemSavedVariables.historyDepth = math.max(MasterMerchant.systemSavedVariables.historyDepth,
      self.acctSavedVariables.historyDepth)
    self.acctSavedVariables.historyDepth = nil
  end
  if self.savedVariables.historyDepth then
    MasterMerchant.systemSavedVariables.historyDepth = math.max(MasterMerchant.systemSavedVariables.historyDepth,
      self.savedVariables.historyDepth)
    self.savedVariables.historyDepth = nil
  end

  -- Min Count
  if self.acctSavedVariables.minItemCount then
    MasterMerchant.systemSavedVariables.minItemCount = math.max(MasterMerchant.systemSavedVariables.minItemCount,
      self.acctSavedVariables.minItemCount)
    self.acctSavedVariables.minItemCount = nil
  end
  if self.savedVariables.minItemCount then
    MasterMerchant.systemSavedVariables.minItemCount = math.max(MasterMerchant.systemSavedVariables.minItemCount,
      self.savedVariables.minItemCount)
    self.savedVariables.minItemCount = nil
  end

  -- Max Count
  if self.acctSavedVariables.maxItemCount then
    MasterMerchant.systemSavedVariables.maxItemCount = math.max(MasterMerchant.systemSavedVariables.maxItemCount,
      self.acctSavedVariables.maxItemCount)
    self.acctSavedVariables.maxItemCount = nil
  end
  if self.savedVariables.maxItemCount then
    MasterMerchant.systemSavedVariables.maxItemCount = math.max(MasterMerchant.systemSavedVariables.maxItemCount,
      self.savedVariables.maxItemCount)
    self.savedVariables.maxItemCount = nil
  end

  -- Blacklist
  if not internal:is_empty_or_nil(self.acctSavedVariables.blacklist) then
    MasterMerchant.systemSavedVariables.blacklist = self.acctSavedVariables.blacklist
    self.acctSavedVariables.blacklist = nil
  end
  if not internal:is_empty_or_nil(self.savedVariables.blacklist) then
    MasterMerchant.systemSavedVariables.blacklist = self.savedVariables.blacklist
    self.savedVariables.blacklist = nil
  end

  TRADING_HOUSE_SCENE:RegisterCallback("StateChange", function(oldState, newState)
    if newState == SCENE_SHOWING then
      MasterMerchant.tradingHouseOpened = true
    elseif newState == SCENE_HIDDEN then
      MasterMerchant.tradingHouseOpened = false
    end
  end)

  --[[
  GAMEPAD_VENDOR_SCENE:RegisterCallback("StateChange", function(oldState, newState)
  MasterMerchant.a1_test = "Vendor Scene"
  MasterMerchant.a2_test = newState
  MasterMerchant.a3_test = oldState
    if newState == SCENE_SHOWING then
      ZO_SharedInventoryManager:PerformFullUpdateOnBagCache(BAG_BACKPACK)
    end
  end)
  ]]--

  -- MoveFromOldAcctSavedVariables STEP Removed
  -- AdjustItemsAllContainers() STEP Removed
  -- ReIndexSalesAllContainers() STEP Removed
  -- ReferenceSalesAllContainers() STEP Removed
  -- New, added 9/26
  self:InitRosterChanges()

  self:setupGuildColors()

  -- Setup the options menu and main windows
  self:LibAddonInit()
  self:SetupMasterMerchantWindow()
  self:RestoreWindowPosition()
  self:SetWindowLockIcon()
  self:SetWindowLock()
  self:CheckFilterTimerangeState()

  LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, self.LinkHandler_OnLinkMouseUp)

  ZO_PreHook('ZO_InventorySlot_ShowContextMenu', function(rowControl) self:myZO_InventorySlot_ShowContextMenu(rowControl) end)

  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_TRADING_HOUSE_SELECTED_GUILD_CHANGED, function()
    if MasterMerchant.systemSavedVariables.priceCalcAll then
      MasterMerchant.systemSavedVariables.pricingData = GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"] or {}
    else
      local selectedGuildId = GetSelectedTradingHouseGuildId()
      MasterMerchant.systemSavedVariables.pricingData = GS17DataSavedVariables[internal.pricingNamespace][selectedGuildId] or {}
    end
  end)

  -- Because we allow manual toggling of the MasterMerchant window in those scenes (without
  -- making that setting permanent), we also have to hide the window on closing them
  -- if they're not part of the scene.
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_MAIL_CLOSE_MAILBOX, function()
    if not MasterMerchant.systemSavedVariables.openWithMail then
      self:ActiveWindow():SetHidden(true)
      MasterMerchantStatsWindow:SetHidden(true)
      MasterMerchantFilterByNameWindow:SetHidden(true)
      MasterMerchantFilterByTypeWindow:SetHidden(true)
    end
  end)

  --[[TODO Trader tracking if it was banker or kiosk
  ]]--
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLOSE_TRADING_HOUSE, function()
    MasterMerchant.ClearDealInfoCache()
    if not MasterMerchant.systemSavedVariables.openWithStore then
      self:ActiveWindow():SetHidden(true)
      MasterMerchantStatsWindow:SetHidden(true)
      MasterMerchantFilterByNameWindow:SetHidden(true)
      MasterMerchantFilterByTypeWindow:SetHidden(true)
    end
  end)

  -- We also want to make sure the MasterMerchant windows are hidden in the game menu
  ZO_PreHookHandler(ZO_GameMenu_InGame, 'OnShow', function()
    self:ActiveWindow():SetHidden(true)
    MasterMerchantStatsWindow:SetHidden(true)
    MasterMerchantFeedback:SetHidden(true)
    MasterMerchantFilterByNameWindow:SetHidden(true)
    MasterMerchantFilterByTypeWindow:SetHidden(true)
  end)

  if not AwesomeGuildStore then
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_TRADING_HOUSE_PENDING_ITEM_UPDATE,
      function(eventCode, slotId, isPending)
        local stackSize = GetSlotStackSize(BAG_BACKPACK, slotId)
        if MasterMerchant.systemSavedVariables.showCalc and isPending and stackSize > 1 then
          local theLink = GetItemLink(BAG_BACKPACK, slotId, LINK_STYLE_DEFAULT)
          local postedStats = self:GetTooltipStats(theLink, true, false)
          local floorPrice = 0
          if postedStats.avgPrice then floorPrice = string.format('%.2f', postedStats['avgPrice']) end
          MasterMerchantPriceCalculatorStack:SetText(GetString(MM_APP_TEXT_TIMES) .. stackSize)
          MasterMerchantPriceCalculatorUnitCostAmount:SetText(floorPrice)
          MasterMerchantPriceCalculatorTotal:SetText(GetString(MM_TOTAL_TITLE) .. self.LocalizedNumber(math.floor(floorPrice * stackSize)) .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t')
          MasterMerchantPriceCalculator:SetHidden(false)
        else MasterMerchantPriceCalculator:SetHidden(true) end
      end)
  end

  --[[TODO see if this or something else can be used in Gamepad mode
  ]]--
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_TRADING_HOUSE_RESPONSE_RECEIVED, function(_, responseType, result)
    if responseType == TRADING_HOUSE_RESULT_POST_PENDING and result == TRADING_HOUSE_RESULT_SUCCESS then MasterMerchantPriceCalculator:SetHidden(true) end
    -- Set up guild store buying advice
    self:initBuyingAdvice()
    self:initSellingAdvice()
  end)

  if not AwesomeGuildStore then
    ZO_PreHook('CancelTradingHouseListing', function(index)
      --MasterMerchant:dm("Debug", "CancelTradingHouseListing")
      local itemLink = GetTradingHouseListingItemLink(index)
      local icon, itemName, displayQuality, stackCount, sellerName, timeRemaining, salePrice, currencyType, itemUniqueId, salePricePerUnit = GetTradingHouseListingItemInfo(index)
      local guildId, guildName = GetCurrentTradingHouseGuildDetails()
      local theEvent = {
        guild = guildName,
        guildId = guildId,
        itemLink = itemLink,
        quant = stackCount,
        timestamp = GetTimeStamp(),
        price = salePrice,
        seller = sellerName,
        id = itemUniqueId,
      }
      internal:addCancelledItem(theEvent)
      MasterMerchant.listIsDirty[REPORTS] = true
    end)
  end
  -- I could do this with action layer pop/push, but it's kind've a pain
  -- when it's just these I want to hook
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLOSE_BANK, function()
    self:ActiveWindow():SetHidden(true)
    MasterMerchant:ToggleMasterMerchantFilterWindows()
  end)
  --    MasterMerchantWindow:SetHidden(true)
  --    MasterMerchantGuildWindow:SetHidden(true)
  --  end)
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLOSE_GUILD_BANK, function()
    self:ActiveWindow():SetHidden(true)
    MasterMerchant:ToggleMasterMerchantFilterWindows()
  end)
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLOSE_STORE, function()
    self:ActiveWindow():SetHidden(true)
    MasterMerchant:ToggleMasterMerchantFilterWindows()
  end)
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_END_CRAFTING_STATION_INTERACT, function()
    self:ActiveWindow():SetHidden(true)
    MasterMerchant:ToggleMasterMerchantFilterWindows()
  end)

  -- We'll add stats to tooltips for items we have data for, if desired
  ZO_PreHookHandler(PopupTooltip, 'OnUpdate', function() self:addStatsPopupTooltip(PopupTooltip) end)
  ZO_PreHookHandler(PopupTooltip, 'OnHide', function() self:remStatsPopupTooltip(PopupTooltip) end)
  ZO_PreHookHandler(ItemTooltip, 'OnUpdate', function() self:GenerateStatsItemTooltip() end)
  ZO_PreHookHandler(ItemTooltip, 'OnHide', function() self:remStatsItemTooltip() end)

  ZO_PreHookHandler(ZO_ProvisionerTopLevelTooltip, 'OnUpdate', function() self:addStatsProvisionerTooltip(ZO_ProvisionerTopLevelTooltip) end)
  ZO_PreHookHandler(ZO_ProvisionerTopLevelTooltip, 'OnHide', function() self:remStatsPopupTooltip(ZO_ProvisionerTopLevelTooltip) end)

  --[[ This is to save the sale price however AGS has its own routines and uses
  its value first so this is usually not seen, although it does save NA and EU
  separately
  ]]--
  if AwesomeGuildStore then
    AwesomeGuildStore:RegisterCallback(AwesomeGuildStore.callback.ITEM_POSTED,
      function(guildId, itemLink, price, stackCount)
        local theIID = GetItemLinkItemId(itemLink)
        local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
        local selectedGuildId = GetSelectedTradingHouseGuildId()

        if MasterMerchant.systemSavedVariables.priceCalcAll then
          GS17DataSavedVariables[internal.pricingNamespace] = GS17DataSavedVariables[internal.pricingNamespace] or {}
          GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"] = GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"] or {}
          GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"][theIID] = GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"][theIID] or {}
          GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"][theIID][itemIndex] = price / stackCount
        else
          GS17DataSavedVariables[internal.pricingNamespace] = GS17DataSavedVariables[internal.pricingNamespace] or {}
          GS17DataSavedVariables[internal.pricingNamespace][selectedGuildId] = GS17DataSavedVariables[internal.pricingNamespace][selectedGuildId] or {}
          GS17DataSavedVariables[internal.pricingNamespace][selectedGuildId][theIID] = GS17DataSavedVariables[internal.pricingNamespace][selectedGuildId][theIID] or {}
          GS17DataSavedVariables[internal.pricingNamespace][selectedGuildId][theIID][itemIndex] = price / stackCount
        end

      end)
  else
    if TRADING_HOUSE then
      OriginalSetupPendingPost = TRADING_HOUSE.SetupPendingPost
      TRADING_HOUSE.SetupPendingPost = MasterMerchant.TradingHouseSetupPendingPost
      ZO_PreHook(TRADING_HOUSE, 'PostPendingItem', MasterMerchant.PostPendingItem)
    end
  end

  -- Set up GM Tools, if also installed
  self:initGMTools()

  -- Set up purchase tracking, if also installed
  self:initPurchaseTracking()

  -- Hook for Writ and Vendor icons
  MasterMerchant:InitializeHooks()

  -- Item List Sort management
  ZO_SharedInventoryManager.CreateOrUpdateSlotData = MasterMerchant.CreateOrUpdateSlotData
  --Watch inventory listings
  for _, i in pairs(PLAYER_INVENTORY.inventories) do
    local listView = i.listView
    if listView and listView.dataTypes and listView.dataTypes[1] then
      local originalCall = listView.dataTypes[1].setupCallback

      listView.dataTypes[1].setupCallback = function(rowControl, slot)
        originalCall(rowControl, slot)
        MasterMerchant:SetInventorySellPriceText(rowControl, slot)
      end
    end
  end

  -- Watch Decon list
  local originalCall = ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack.dataTypes[1].setupCallback
  SecurePostHook(ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack.dataTypes[1], "setupCallback", function(rowControl, slot)
    originalCall(rowControl, slot)
    MasterMerchant:SetInventorySellPriceText(rowControl, slot)
  end)

  -- With nothing only the item removed from teh craft bag updates, with the call above - not slot and hasItemInSlotNow
  --[[
  -- this one updated the entire inventory once I removed something from the craft bag, but not the new iten in the inventory
  -- Stowing it did not update the craft bag
  ZO_PreHook(ZO_SharedInventoryManager, "CreateOrUpdateSlotData", function(sharedInventoryPointer, existingSlotData, bagId, slotIndex, isNewItem)
    local canReplacePrice = MasterMerchant.isInitialized and MasterMerchant.systemSavedVariables.replaceInventoryValues and existingSlotData and not existingSlotData.hasAlteredPrice
    if canReplacePrice then
      existingSlotData = MasterMerchant:ReplaceInventorySellPriceFromHookOrCallback(existingSlotData)
    end
  end)

  -- this one updated the item in the inventory
  SecurePostHook(ZO_SharedInventoryManager, "HandleSlotCreationOrUpdate", function(sharedInventoryPointer, bagCache, bagId, slotIndex, isNewItem, isLastUpdateForMessage)
    local slot = bagCache[slotIndex]
    local canReplacePrice = MasterMerchant.isInitialized and MasterMerchant.systemSavedVariables.replaceInventoryValues and slot and not slot.hasAlteredPrice
    if canReplacePrice then
      slot = MasterMerchant:ReplaceInventorySellPriceFromHookOrCallback(slot)
      bagCache[slotIndex] = slot
    end
  end)

  ZO_PreHook(ZO_SharedInventoryManager, "HandleSlotCreationOrUpdate", function(sharedInventoryPointer, bagCache, bagId, slotIndex, isNewItem, isLastUpdateForMessage)
    local slot = bagCache[slotIndex]
    local canReplacePrice = MasterMerchant.isInitialized and MasterMerchant.systemSavedVariables.replaceInventoryValues and existingSlotData and not existingSlotData.hasAlteredPrice
    if canReplacePrice then
      slot = MasterMerchant:ReplaceInventorySellPriceFromHookOrCallback(slot)
      bagCache[slotIndex] = slot
    end
  end)
  SecurePostHook(ZO_SharedInventoryManager, "CreateOrUpdateSlotData", function(sharedInventoryPointer, existingSlotData, bagId, slotIndex, isNewItem)
    local canReplacePrice = MasterMerchant.isInitialized and MasterMerchant.systemSavedVariables.replaceInventoryValues and existingSlotData and not existingSlotData.hasAlteredPrice
    if canReplacePrice then
      existingSlotData = MasterMerchant:ReplaceInventorySellPrice(existingSlotData)
    end
  end)
  ]]--
end

function MasterMerchant:SecondInitialize()
  MasterMerchant:dm("Debug", "SecondInitialize")
  --[[
  Order of events:

  OnAddOnLoaded
  Initialize
  Move the old single addon sales history
  Convert event IDs to string if not converted
  Update indexs if not converted
  Bring seperate lists together
  InitRosterChanges
  setupGuildColors
  LibAddonInit
  SetupMasterMerchantWindow
  UpdateFonts
  RegisterFonts
  RestoreWindowPosition
  initGMTools
  initPurchaseTracking
  BuildAccountNameLookup Removed
  BuildItemLinkNameLookup Removed
  BuildGuildNameLookup Removed
  TruncateHistory Removed
  TruncateHistory iterateOverSalesData Removed
  InitSalesHistory Removed
  InitSalesHistory iterateOverSalesData Removed
  indexHistoryTables Removed
  indexHistoryTables iterateOverSalesData Removed
  InitScrollLists
  SetupScrollLists
  SetupListenerLibHistoire
  ]]--
  -- Right, we're all set up, so wait for the player activated event
  -- and then do an initial (deep) scan in case it's been a while since the player
  -- logged on, then use RegisterForUpdate to set up a timed scan.
  zo_callLater(function()
    local LEQ = LibExecutionQueue:new()
    LEQ:Add(function() MasterMerchant:dm("Info", GetString(MM_INITIALIZING)) end, 'MMInitializing')
    LEQ:Add(function() MasterMerchant:BuildRemovedItemIdTable() end, 'BuildRemovedItemIdTable')
    LEQ:Add(function() MasterMerchant:InitScrollLists() end, 'InitScrollLists')
    LEQ:Add(function() internal:SetupListenerLibHistoire() end, 'SetupListenerLibHistoire')
    LEQ:Add(function() CompleteMasterMerchantSetup() end, 'CompleteMasterMerchantSetup')
    LEQ:Add(function()
      if internal:MasterMerchantDataActive() then
        MasterMerchant:dm("Info", GetString(MM_MMXXDATA_OBSOLETE))
      end
    end, 'MasterMerchantDataActive')
    LEQ:Add(function()
      if internal:ArkadiusDataActive() then
        if not MasterMerchant.systemSavedVariables.disableAttWarn then
          MasterMerchant:dm("Info", GetString(MM_ATT_DATA_ENABLED))
        end
      end
    end, 'ArkadiusDataActive')
    LEQ:Add(function()
      if ShoppingList then
        MasterMerchant:dm("Info", GetString(MM_SHOPPINGLIST_OBSOLETE))
      end
    end, 'ShoppingListActive')
    LEQ:Start()
  end, 10)
end

function MasterMerchant:InitScrollLists()
  MasterMerchant:dm("Debug", "InitScrollLists")

  self:SetupScrollLists()

  -- sets isFirstScan to true if offlineSales enabled so that alerts are displayed
  MasterMerchant.isFirstScan = MasterMerchant.systemSavedVariables.offlineSales

  --[[ Sales exist, but no way to know from what source
  previously this would set a variable of veryFirstScan to false
  and true just below
  ]]--

  --[[
if NonContiguousCount(sales_data) > 0 then
else
  MasterMerchant:dm("Info", MasterMerchant.concat(GetString(MM_APP_MESSAGE_NAME), GetString(SK_FIRST_SCAN)))
end
]]--

  -- for mods using the old syntax
  if GS17DataSavedVariables then
    if MasterMerchant.systemSavedVariables.priceCalcAll then
      MasterMerchant.systemSavedVariables.pricingData = GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"] or {}
    else
      local selectedGuildId = GetSelectedTradingHouseGuildId()
      MasterMerchant.systemSavedVariables.pricingData = GS17DataSavedVariables[internal.pricingNamespace][selectedGuildId] or {}
    end
  end
end

local dealInfoCache = {}
MasterMerchant.ClearDealInfoCache = function()
  ZO_ClearTable(dealInfoCache)
end

function MasterMerchant:GetAveragePriceAndCount(itemLink, priceType)
  if not MasterMerchant.isInitialized then return end
  local averagePrice
  local salesCount = 0
  local evalType
  if priceType == MM_GETPRICE_TYPE_DEALCALC then evalType = MasterMerchant.systemSavedVariables.dealCalcToUse
  elseif priceType == MM_GETPRICE_TYPE_INV_REPLACEMENT then evalType = MasterMerchant.systemSavedVariables.replacementTypeToUse end

  if evalType == MM_PRICE_MM_AVERAGE then
    local priceStats = MasterMerchant:GetTooltipStats(itemLink, true, false)
    if priceStats and priceStats.avgPrice then
      averagePrice = priceStats['avgPrice']
      salesCount = priceStats['numSales']
    end
  end
  if evalType == MM_PRICE_BONANZA then
    local priceStats = MasterMerchant:GetTooltipStats(itemLink, false, false)
    if priceStats and priceStats.bonanzaPrice then
      averagePrice = priceStats.bonanzaPrice
      salesCount = priceStats.bonanzaListings
    end
  end
  if evalType == MM_PRICE_TTC_AVERAGE and TamrielTradeCentre then
    local priceStats = TamrielTradeCentrePrice:GetPriceInfo(itemLink)
    if priceStats and priceStats.Avg and priceStats.Avg > 0 then averagePrice = priceStats.Avg end
    if priceStats and priceStats.EntryCount then salesCount = priceStats.EntryCount end
  end
  if evalType == MM_PRICE_TTC_SUGGESTED and TamrielTradeCentre then
    local priceStats = TamrielTradeCentrePrice:GetPriceInfo(itemLink)
    if priceStats and priceStats.SuggestedPrice and priceStats.SuggestedPrice > 0 then averagePrice = priceStats.SuggestedPrice end
    if priceStats and priceStats.EntryCount then salesCount = priceStats.EntryCount end
    if averagePrice and MasterMerchant.systemSavedVariables.modifiedSuggestedPriceDealCalc then
      averagePrice = averagePrice * 1.25
    end
  end
  return averagePrice, salesCount
end
-- /script d(MasterMerchant.GetDealInformation("|H1:item:182625:4:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", 10000, 2))
-- /script d(MasterMerchant.GetDealInformation("|H1:item:191220:362:50:0:0:0:0:0:0:0:0:0:0:0:0:8:0:0:0:300:0|h|h", 1111, 1))
MasterMerchant.GetDealInformation = function(itemLink, purchasePrice, stackCount)

  local key = string.format("%s_%d_%d", itemLink, purchasePrice, stackCount)
  if (not dealInfoCache[key]) then
    local setPrice, salesCount = MasterMerchant:GetAveragePriceAndCount(itemLink, MM_GETPRICE_TYPE_DEALCALC)
    dealInfoCache[key] = { MasterMerchant.DealCalculator(setPrice, salesCount, purchasePrice, stackCount) }
  end
  return unpack(dealInfoCache[key])
end

function MasterMerchant:SendNote(gold)
  MasterMerchantFeedback:SetHidden(true)
  SCENE_MANAGER:Show('mailSend')
  ZO_MailSendToField:SetText('@Sharlikran')
  ZO_MailSendSubjectField:SetText('Master Merchant')
  QueueMoneyAttachment(gold)
  ZO_MailSendBodyField:TakeFocus()
end


--[[TODO Setup OnItemSelected to be used if needed
I forget why I added this but AGS and the Vanilla AH
Are properly defined for LGS
]]--
function OnItemSelected()
  local isPlayerViewingTrader = GAMEPAD_TRADING_HOUSE_SELL.itemList.list.active
  local selectedItem = GAMEPAD_TRADING_HOUSE_SELL.itemList.list.selectedIndex
  local searchData = ZO_TradingHouse_GamepadMaskContainerSellList.scrollList.dataList.itemData.searchData
  local itemSelected = searchData[selectedItem]
  local bagId = itemInventorySlot.bagId
  local slotId = itemInventorySlot.slotId
  local itemLink = GetItemLink(bagId, slotId)
  -- << alter price on scroll list >>
end

--[[TODO verify when player is using Gamepad
IsInGamepadPreferredMode()
]]--

-------------------------------------------------------------------------------
-- LMP - Removed Fonts v1.1
-------------------------------------------------------------------------------
--
-- Copyright (c) 2014 Ales Machat (Garkin)
--
-- Permission is hereby granted, free of charge, to any person
-- obtaining a copy of this software and associated documentation
-- files (the 'Software'), to deal in the Software without
-- restriction, including without limitation the rights to use,
-- copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following
-- conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
-- OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
-- HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
-- OTHER DEALINGS IN THE SOFTWARE.
function MasterMerchant:RegisterFonts()
  MasterMerchant:dm("Debug", "RegisterFonts")
  LMP:Register("font", "Arial Narrow", [[MasterMerchant/Fonts/arialn.ttf]])
  LMP:Register("font", "ESO Cartographer", [[MasterMerchant/Fonts/esocartographer-bold.otf]])
  LMP:Register("font", "Fontin Bold", [[MasterMerchant/Fonts/fontin_sans_b.otf]])
  LMP:Register("font", "Fontin Italic", [[MasterMerchant/Fonts/fontin_sans_i.otf]])
  LMP:Register("font", "Fontin Regular", [[MasterMerchant/Fonts/fontin_sans_r.otf]])
  LMP:Register("font", "Fontin SmallCaps", [[MasterMerchant/Fonts/fontin_sans_sc.otf]])
end

local function CheckLibGuildStoreReady()
  MasterMerchant:dm("Debug", "CheckLibGuildStoreReady")
  local LGS = LibGuildStore
  if LGS.guildStoreReady then
    MasterMerchant:SecondInitialize()
  else
    zo_callLater(function() CheckLibGuildStoreReady() end, 10000)
  end
end

local function OnPlayerActivated(eventCode)
  MasterMerchant:dm("Debug", "OnPlayerActivated")
  CheckLibGuildStoreReady()
  EVENT_MANAGER:UnregisterForEvent(MasterMerchant.name, EVENT_PLAYER_ACTIVATED)
end
EVENT_MANAGER:RegisterForEvent(MasterMerchant.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

local function OnAddOnLoaded(eventCode, addOnName)
  if addOnName:find('^ZO_') then return end
  if addOnName == MasterMerchant.name then
    MasterMerchant:dm("Debug", "MasterMerchant Loaded")
    -- Set up /mm as a slash command toggle for the main window
    SLASH_COMMANDS['/mm'] = MasterMerchant.Slash
    MasterMerchant:FirstInitialize()
  elseif addOnName == "AwesomeGuildStore" then
    -- Set up AGS integration, if it's installed
    MasterMerchant:initAGSIntegration()
  elseif addOnName == "WritWorthy" then
    if WritWorthy and WritWorthy.CreateParser then MasterMerchant.wwDetected = true end
  elseif addOnName == "MasterWritInventoryMarker" then
    if MWIM_SavedVariables then MasterMerchant.mwimDetected = true end
  end

end
EVENT_MANAGER:RegisterForEvent(MasterMerchant.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

function MasterMerchant.Slash(allArgs)
  local args = ""
  local guildNumber = 0
  local hoursBack = 0
  local argNum = 0
  for w in zo_strgmatch(allArgs, "%w+") do
    argNum = argNum + 1
    if argNum == 1 then args = w end
    if argNum == 2 then guildNumber = tonumber(w) end
    if argNum == 3 then hoursBack = tonumber(w) end
  end
  args = string.lower(args)

  if args == 'help' then
    MasterMerchant:dm("Info", GetString(MM_HELP_WINDOW))
    MasterMerchant:dm("Info", GetString(MM_HELP_CLEARPRICES))
    MasterMerchant:dm("Info", GetString(MM_HELP_INVISIBLE))
    MasterMerchant:dm("Info", GetString(MM_HELP_EXPORT))
    MasterMerchant:dm("Info", GetString(MM_HELP_SALES))
    MasterMerchant:dm("Info", GetString(MM_HELP_PERSONAL))
    MasterMerchant:dm("Info", GetString(MM_HELP_PURCHASES))
    MasterMerchant:dm("Info", GetString(MM_HELP_DEAL))
    MasterMerchant:dm("Info", GetString(MM_HELP_TYPES))
    MasterMerchant:dm("Info", GetString(MM_HELP_TRAITS))
    MasterMerchant:dm("Info", GetString(MM_HELP_QUALITY))
    MasterMerchant:dm("Info", GetString(MM_HELP_EQUIP))
    return
  end

  if args == 'export' then
    if not MasterMerchant.isInitialized then
      MasterMerchant:dm("Info", GetString(MM_STILL_INITIALIZING))
      return
    end
    MasterMerchant.guildNumber = guildNumber
    if (MasterMerchant.guildNumber > 0) and (GetNumGuilds() > 0) then
      MasterMerchant:dm("Info", GetString(MM_EXPORT_START))
      MasterMerchant:ExportSalesReport()
      MasterMerchant:dm("Info", GetString(MM_EXPORT_COMPLETE))
    else
      MasterMerchant:dm("Info", GetString(MM_GUILD_INDEX_INCLUDE))
      MasterMerchant:dm("Info", GetString(MM_GUILD_EXPORT_EXAMPLE))
      for i = 1, GetNumGuilds() do
        local guildID = GetGuildId(i)
        local guildName = GetGuildName(guildID)
        MasterMerchant:dm("Info", string.format(GetString(MM_GUILD_INDEX_NAME), i, guildName))
      end
    end
    return
  end

  if args == 'sales' then
    if not MasterMerchant.isInitialized then
      MasterMerchant:dm("Info", GetString(MM_STILL_INITIALIZING))
      return
    end
    MasterMerchant.guildNumber = guildNumber
    if (MasterMerchant.guildNumber > 0) and (GetNumGuilds() > 0) then
      MasterMerchant:dm("Info", GetString(MM_SALES_ACTIVITY_EXPORT_START))
      MasterMerchant:ExportSalesActivity()
      MasterMerchant:dm("Info", GetString(MM_EXPORT_COMPLETE))
    else
      MasterMerchant:dm("Info", GetString(MM_GUILD_INDEX_INCLUDE))
      MasterMerchant:dm("Info", GetString(MM_GUILD_SALES_EXAMPLE))
      for i = 1, GetNumGuilds() do
        local guildID = GetGuildId(i)
        local guildName = GetGuildName(guildID)
        MasterMerchant:dm("Info", string.format(GetString(MM_GUILD_INDEX_NAME), i, guildName))
      end
    end
    return
  end

  if args == 'personal' then
    if not MasterMerchant.isInitialized then
      MasterMerchant:dm("Info", GetString(MM_STILL_INITIALIZING))
      return
    end
    MasterMerchant.guildNumber = guildNumber
    if (MasterMerchant.guildNumber > 0) and (GetNumGuilds() > 0) then
      MasterMerchant:dm("Info", GetString(MM_SALES_PERSONAL_EXPORT_START))
      MasterMerchant:ExportPersonalSales()
      MasterMerchant:dm("Info", GetString(MM_EXPORT_COMPLETE))
    else
      MasterMerchant:dm("Info", GetString(MM_GUILD_INDEX_INCLUDE))
      MasterMerchant:dm("Info", GetString(MM_PERSONAL_SALES_EXAMPLE))
      for i = 1, GetNumGuilds() do
        local guildID = GetGuildId(i)
        local guildName = GetGuildName(guildID)
        MasterMerchant:dm("Info", string.format(GetString(MM_GUILD_INDEX_NAME), i, guildName))
      end
    end
    return
  end

  if args == 'purchases' then
    if not MasterMerchant.isInitialized then
      MasterMerchant:dm("Info", GetString(MM_STILL_INITIALIZING))
      return
    end
    MasterMerchant:dm("Info", GetString(MM_EXPORT_SHOPPING_LIST_START))
    MasterMerchant:ExportShoppingList()
    MasterMerchant:dm("Info", GetString(MM_EXPORT_COMPLETE))
    return
  end

  if args == '42' then
    MasterMerchant:SpecialMessage(true)
    return
  end

  if args == 'clearprices' then
    if MasterMerchant.systemSavedVariables.priceCalcAll then
      GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"] = {}
    else
      GS17DataSavedVariables[internal.pricingNamespace] = {}
    end

    MasterMerchant:dm("Info", GetString(MM_CLEAR_SAVED_PRICES))
    return
  end

  if args == 'invisible' then
    MasterMerchant.systemSavedVariables.salesWinLeft = MasterMerchant.systemDefault.salesWinLeft
    MasterMerchant.systemSavedVariables.salesWinTop = MasterMerchant.systemDefault.salesWinTop
    MasterMerchant.systemSavedVariables.guildWinLeft = MasterMerchant.systemDefault.guildWinLeft
    MasterMerchant.systemSavedVariables.guildWinTop = MasterMerchant.systemDefault.guildWinTop
    MasterMerchant.systemSavedVariables.listingWinLeft = MasterMerchant.systemDefault.listingWinLeft
    MasterMerchant.systemSavedVariables.listingWinTop = MasterMerchant.systemDefault.listingWinTop
    MasterMerchant.systemSavedVariables.purchaseWinLeft = MasterMerchant.systemDefault.purchaseWinLeft
    MasterMerchant.systemSavedVariables.purchaseWinTop = MasterMerchant.systemDefault.purchaseWinTop
    MasterMerchant.systemSavedVariables.reportsWinLeft = MasterMerchant.systemDefault.reportsWinLeft
    MasterMerchant.systemSavedVariables.reportsWinTop = MasterMerchant.systemDefault.reportsWinTop

    MasterMerchant.systemSavedVariables.statsWinLeft = MasterMerchant.systemDefault.statsWinLeft
    MasterMerchant.systemSavedVariables.statsWinTop = MasterMerchant.systemDefault.statsWinTop
    MasterMerchant.systemSavedVariables.feedbackWinLeft = MasterMerchant.systemDefault.feedbackWinLeft
    MasterMerchant.systemSavedVariables.feedbackWinTop = MasterMerchant.systemDefault.feedbackWinTop
    MasterMerchant:RestoreWindowPosition()
    MasterMerchant:dm("Info", GetString(MM_RESET_POSITION))
    return
  end

  if args == 'deal' or args == 'saucy' then
    MasterMerchant.systemSavedVariables.displayProfit = not MasterMerchant.systemSavedVariables.displayProfit
    MasterMerchant:dm("Info", GetString(MM_GUILD_DEAL_TYPE))
    return
  end

  if args == 'types' then
    local message = 'Item types: '
    for i = 0, 71 do
      message = message .. i .. ')' .. GetString("SI_ITEMTYPE", i) .. ', '
    end
    MasterMerchant:dm("Info", message)
    return
  end

  if args == 'traits' then
    local message = 'Item traits: '
    for i = 0, 33 do
      message = message .. i .. ')' .. GetString("SI_ITEMTRAITTYPE", i) .. ', '
    end
    MasterMerchant:dm("Info", message)
    return
  end

  if args == 'quality' then
    local message = 'Item quality: '
    for i = 0, 5 do
      message = message .. GetString("SI_ITEMQUALITY", i) .. ', '
    end
    MasterMerchant:dm("Info", message)
    return
  end

  if args == 'equip' then
    local message = 'Equipment types: '
    for i = 1, 15 do
      message = message .. GetString("SI_EQUIPTYPE", i) .. ', '
    end
    MasterMerchant:dm("Info", message)
    return
  end

  MasterMerchant:ToggleMasterMerchantWindow()
end
