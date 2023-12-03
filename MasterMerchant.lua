-- MasterMerchant Main Addon File
-- Last Updated September 15, 2014
-- Written July 2014 by Dan Stone (@khaibit) - dankitymao@gmail.com
-- Extended Feb 2015 - Oct 2016 by (@Philgo68) - Philgo68@gmail.com
-- Released under terms in license accompanying this file.
-- Distribution without license is prohibited!
local LMP = LibMediaProvider
local internal = _G["LibGuildStore_Internal"]
local sales_data = _G["LibGuildStore_SalesData"]
local sr_index = _G["LibGuildStore_SalesIndex"]
local listings_data = _G["LibGuildStore_ListingsData"]
local purchases_data = _G["LibGuildStore_PurchaseData"]
local mmUtils = _G["MasterMerchant_Internal"]

local OriginalSetupPendingPost

--[[ can not use MasterMerchant.itemsViewSize for example
because that will not be available this early.
]]--
local ITEMS = 'items_vs'
local GUILDS = 'guild_vs'
local LISTINGS = 'listings_vs'
local PURCHASES = 'purchases_vs'
local REPORTS = 'reports_vs'

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
  local daysRange = MM_DAYS_RANGE_ALL
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
  if range == MM_RANGE_VALUE_NONE then return MM_DAYS_RANGE_NONE, MM_DAYS_RANGE_NONE end
  if range == MM_RANGE_VALUE_ALL then daysRange = MM_DAYS_RANGE_ALL end
  if range == MM_RANGE_VALUE_FOCUS1 then daysRange = MasterMerchant.systemSavedVariables.focus1 end
  if range == MM_RANGE_VALUE_FOCUS2 then daysRange = MasterMerchant.systemSavedVariables.focus2 end
  if range == MM_RANGE_VALUE_FOCUS3 then daysRange = MasterMerchant.systemSavedVariables.focus3 end

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
    local blacklistTable = MasterMerchant.blacklistTable
    if blacklistTable == nil then return false end
    return (currentGuild and blacklistTable[currentGuild]) or
      (currentSeller and blacklistTable[currentSeller])
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

  local modeValues = {}

  for k, v in pairs(counts) do
    if v == biggestCount then
      table.insert(modeValues, k)
    end
  end

  return modeValues
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
    -- Return mean value of middle two elements
    local middleIndex = zo_ceil(#temp / 2)
    return (temp[middleIndex] + temp[middleIndex + 1]) / 2
  else
    -- Return middle element
    local middleIndex = zo_ceil(#temp / 2)
    return temp[middleIndex]
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

  if count <= 1 then
    return 0
  end
  result = math.sqrt(sum / (count - 1))

  return result
end

function stats.zscore(individualSale, mean, standardDeviation)
  local result = (individualSale - mean) / standardDeviation
  if result ~= result then return 0 end
  return result
end

function stats.findMinMax(t)
  local maxVal = -math.huge
  local minVal = math.huge

  for _, individualSale in pairs(t) do
    maxVal = zo_max(maxVal, individualSale)
    minVal = zo_min(minVal, individualSale)
  end

  return maxVal, minVal
end

function stats.range(t)
  local highest, lowest = stats.findMinMax(t)
  return highest - lowest
end

function stats.getMiddleIndex(count)
  local evenNumber = false
  local quotient, remainder = math.modf(count / 2)
  if remainder == 0 then evenNumber = true end
  local middleIndex = quotient + zo_floor(0.5 + remainder)
  return middleIndex, evenNumber
end

function stats.medianAbsoluteDeviation(t)
  local medianValue = stats.median(t)
  local absoluteDeviations = {}

  for _, value in pairs(t) do
    local absoluteDeviation = zo_abs(value - medianValue)
    table.insert(absoluteDeviations, absoluteDeviation)
  end

  return stats.median(absoluteDeviations)
end

function stats.calculateMADThreshold(statsData, maxDev)
  local medianAbsoluteDev = stats.medianAbsoluteDeviation(statsData)
  local median = stats.median(statsData)
  local madThreshold = median + (medianAbsoluteDev * maxDev)
  return madThreshold
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

function stats.getLowerAndUpperPercentages(percentage)
  local function getPercent(percentage)
    if type(percentage) == "number" and percentage >= 0 then
      local floatPercentage = percentage / 100
      return tonumber(string.format("%.2f", floatPercentage))
    else
      return nil -- Invalid input
    end
  end

  local lowerPercent = getPercent(percentage)
  local upperPercent = getPercent(100 - percentage)
  return lowerPercent, upperPercent
end

function stats.getUpperLowerPercentileIndexes(statsData, percentage)
  local lowerPercent, upperPercent = stats.getLowerAndUpperPercentages(percentage)
  local lowerIndex = zo_ceil(#statsData * lowerPercent)
  local upperIndex = zo_ceil(#statsData * upperPercent)
  return lowerIndex, upperIndex
end

function stats.getUpperLowerContextFactors(statsData, percentage)
  local lowerIndex, upperIndex = stats.getUpperLowerPercentileIndexes(statsData, percentage)
  local lowerContextFactor = statsData[lowerIndex]
  local upperContextFactor = statsData[upperIndex]
  return lowerContextFactor, upperContextFactor
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
-- /script mmUtils:ClearItemCacheById(54173, "1:0:5:0:0")
-- /script mmUtils:ClearBonanzaCacheById(54173, "1:0:5:0:0")
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
  local zScoreThreshold = 2.054
  local maxDeviation = 2.7
  local iqrMultiplier = 1.5
  local iqrThreshold = 3 -- Minimum threshold for data set size to apply IQR
  local useOuterPercentile = MasterMerchant.systemSavedVariables.trimOutliersWithPercentile
  local ignoreOutliers = MasterMerchant.systemSavedVariables.trimOutliers
  local percentage = MasterMerchant.systemSavedVariables.outlierPercentile
  local trimAgressive = MasterMerchant.systemSavedVariables.trimOutliersAgressive

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
  local daysHistory = MM_DAYS_RANGE_ALL
  local countSold = nil
  local bonanzaPrice = nil
  local bonanzaListings = nil
  local bonanzaItemCount = nil

  local oldestTime = nil
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
  local numVouchers = 0
  local graphInfo = nil
  local updateItemCache = false
  local updateBonanzaCache = false
  local updateGraphinfoCache = false

  local hasSales = false
  local hasListings = false

  -- set timeCheck and daysRange for cache and tooltips
  local timeCheck, daysRange = self:CheckTimeframe()
  if daysRange ~= MM_DAYS_RANGE_ALL then daysHistory = daysRange end

  local returnData = { ['avgPrice'] = avgPrice, ['numSales'] = legitSales, ['numDays'] = daysHistory, ['numItems'] = countSold,
                       ['bonanzaPrice'] = bonanzaPrice, ['bonanzaListings'] = bonanzaListings, ['bonanzaItemCount'] = bonanzaItemCount, ['numVouchers'] = numVouchers,
                       ['graphInfo'] = graphInfo }

  if not MasterMerchant.isInitialized or not itemLink or timeCheck == MM_DAYS_RANGE_NONE then
    return returnData
  end

  if not MasterMerchant.systemSavedVariables.showGraph then
    generateGraph = false
  end

  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  local itemType, specializedItemType = GetItemLinkItemType(itemLink)

  local function IsNameInBlacklist()
    local blacklistTable = MasterMerchant.blacklistTable
    if blacklistTable == nil then return false end
    return (currentGuild and blacklistTable[currentGuild]) or
      (currentBuyer and blacklistTable[currentBuyer]) or
      (currentSeller and blacklistTable[currentSeller])
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
    updateGraphinfoCache = true
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

  local function AssignOldestTimestamp(timestamp)
    if oldestTime == nil or oldestTime > timestamp then oldestTime = timestamp end
  end

  local function ProcessItemWithTimestamp(item, useDaysRange, buildOutliersAndStats)
    local isValidTimeDate = not useDaysRange or item.timestamp > timeCheck

    if isValidTimeDate then
      AssignOldestTimestamp(item.timestamp)
      if (ignoreOutliers or useOuterPercentile) and buildOutliersAndStats then
        BuildOutliersList(item)
      else
        ProcessSalesInfo(item)
      end

      if buildOutliersAndStats then
        BuildStatsData(item)
      end
    end
  end

  local function FilterOutliers(item, calculatedStatsData)
    -- useOuterPercentile, MasterMerchant.systemSavedVariables.trimOutliersWithPercentile
    -- trimAgressive, MasterMerchant.systemSavedVariables.trimOutliersAgressive
    -- dataCount, mean, stdev, quartile1, quartile3, quartileRange, madThreshold, lowerPercentile, upperPercentile
    local mean = calculatedStatsData.mean
    local stdev = calculatedStatsData.stdev
    local quartile1, quartile3, quartileRange = calculatedStatsData.quartile1, calculatedStatsData.quartile3, calculatedStatsData.quartileRange
    local madThreshold = calculatedStatsData.madThreshold
    local isIQRApplicable = calculatedStatsData.dataCount >= iqrThreshold
    local lowerPercentile, upperPercentile = calculatedStatsData.lowerPercentile, calculatedStatsData.upperPercentile

    local individualSale = item.price / item.quant
    local zScore = stats.zscore(individualSale, mean, stdev)
    local isWithinMadThreshold = individualSale <= madThreshold
    local isZScoreValid = zScore <= zScoreThreshold and zScore >= -zScoreThreshold

    -- when trimAgressive is false then isWithinMadThreshold is ignored by making it true, regardless of the calculation
    if not trimAgressive then isWithinMadThreshold = true end

    if useOuterPercentile then
      local isWithinPercentile = individualSale >= lowerPercentile and individualSale <= upperPercentile
      if isWithinPercentile then
        return true
      end
    elseif ignoreOutliers then
      if isIQRApplicable then
        local isWithinIQR = individualSale >= quartile1 - iqrMultiplier * quartileRange and individualSale <= quartile3 + iqrMultiplier * quartileRange
        if isWithinIQR and isWithinMadThreshold and isZScoreValid then
          return true
        end
      else
        if isWithinMadThreshold and isZScoreValid then
          return true
        end
      end
    end

    return false
  end

  -- 10000 for numDays is more or less like saying it is undefined
  --[[TODO why is there a days range of 10000. I get that it kinda means
  all days but the daysHistory seems to be the actual number to be using.
  For example when you press SHIFT or CTRL then daysHistory and daysRange
  are the same. However, when you do not modify the data, then daysRange
  is 10000 and daysHistory is however many days you have.
  ]]--

  salesDetails = MasterMerchant.systemSavedVariables.displaySalesDetails

  -- make sure we have a list of sales to work with
  hasSales = MasterMerchant:itemIDHasSales(itemID, itemIndex)
  hasListings = MasterMerchant:itemIDHasListings(itemID, itemIndex)
  local hasSalesPrice = mmUtils:ItemCacheHasPriceInfoById(itemID, itemIndex, daysRange)
  local hasBonanzaPrice = mmUtils:BonanzaCacheHasPriceInfoById(itemID, itemIndex, daysRange)
  local hasGraphinfo = mmUtils:CacheHasGraphInfoById(itemID, itemIndex, daysRange)
  local createGraph = generateGraph and not hasGraphinfo
  if hasSales and (not hasSalesPrice or createGraph) then
    versionData = sales_data[itemID][itemIndex]
    salesData = versionData['sales']
    nameString = versionData.itemDesc
    oldestTime = versionData.oldestTime

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
    if (daysRange == MM_DAYS_RANGE_ALL) then
      local quotient, remainder = math.modf((GetTimeStamp() - oldestTime) / ZO_ONE_DAY_IN_SECONDS)
      daysHistory = quotient + zo_floor(0.5 + remainder)
    end

    local useDaysRange = daysRange ~= MM_DAYS_RANGE_ALL
    oldestTime = nil
    -- start loop for non outliers
    for _, item in pairs(salesData) do
      currentGuild = internal:GetGuildNameByIndex(item.guild)
      currentBuyer = internal:GetAccountNameByIndex(item.buyer)
      currentSeller = internal:GetAccountNameByIndex(item.seller)
      nameInBlacklist = IsNameInBlacklist()
      if not nameInBlacklist then
        ProcessItemWithTimestamp(item, useDaysRange, true)
      end
    end -- end for loop for non outliers
    SortStatsData()
    if ignoreOutliers or useOuterPercentile then
      if (outliersList and next(outliersList)) and (statsDataCount and statsDataCount > 0) then
        oldestTime = nil
        local madThreshold = stats.calculateMADThreshold(statsData, maxDeviation)
        local mean = stats.mean(statsData)
        local stdev = stats.standardDeviation(statsData)
        local quartile1, quartile3, quartileRange = stats.interquartileRange(statsData)
        local lowerPercentile, upperPercentile = stats.getUpperLowerContextFactors(statsData, percentage)
        local calculatedStatsData = {
          dataCount = statsDataCount,
          mean = mean,
          stdev = stdev,
          quartile1 = quartile1,
          quartile3 = quartile3,
          quartileRange = quartileRange,
          madThreshold = madThreshold,
          lowerPercentile = lowerPercentile,
          upperPercentile = upperPercentile,
        }
        for _, item in pairs(outliersList) do
          currentGuild = internal:GetGuildNameByIndex(item.guild)
          currentBuyer = internal:GetAccountNameByIndex(item.buyer)
          currentSeller = internal:GetAccountNameByIndex(item.seller)
          local nonOutlier = FilterOutliers(item, calculatedStatsData)
          if nonOutlier then
            ProcessItemWithTimestamp(item, useDaysRange, false)
          end
        end
      end
    end -- end trim outliers
    if legitSales and legitSales >= 1 then
      avgPrice = avgPrice / countSold
      --[[found an average price of 0.07 which X 200 is 14g
      even 0.01 X 200 is 2g
      ]]--
      if avgPrice < 0.01 then avgPrice = 0.01 end
    end
    if avgPrice then updateItemCache = true end
  end
  if hasListings and (not hasBonanzaPrice and not averageOnly) then
    bonanzaList = listings_data[itemID][itemIndex]['sales']
    bonanzaList, bonanzaStatsData = RemoveListingsPerBlacklist(bonanzaList)
    SortBonanzaStatsData()
    if (bonanzaList and next(bonanzaList)) and (bonanzaStatsDataCount and bonanzaStatsDataCount > 0) then
      local madThreshold = stats.calculateMADThreshold(bonanzaStatsData, maxDeviation)
      local mean = stats.mean(bonanzaStatsData)
      local stdev = stats.standardDeviation(bonanzaStatsData)
      local quartile1, quartile3, quartileRange = stats.interquartileRange(bonanzaStatsData)
      local lowerPercentile, upperPercentile = stats.getUpperLowerContextFactors(bonanzaStatsData, percentage)
      local calculatedStatsData = {
        dataCount = bonanzaStatsDataCount,
        mean = mean,
        stdev = stdev,
        quartile1 = quartile1,
        quartile3 = quartile3,
        quartileRange = quartileRange,
        madThreshold = madThreshold,
        lowerPercentile = lowerPercentile,
        upperPercentile = upperPercentile,
      }
      for _, item in pairs(bonanzaList) do
        local nonOutlier = FilterOutliers(item, calculatedStatsData)
        if nonOutlier then
          ProcessBonanzaSale(item)
        end
      end
      if bonanzaListings and bonanzaListings >= 1 then
        bonanzaPrice = bonanzaPrice / bonanzaItemCount
        --[[found an average price of 0.07 which X 200 is 14g
        even 0.01 X 200 is 2g
        ]]--
        if bonanzaPrice and bonanzaPrice < 0.01 then bonanzaPrice = 0.01 end
      end
      if bonanzaPrice then updateBonanzaCache = true end
    end
    --[[
    if MasterMerchant.systemSavedVariables.useLibDebugLogger and (bonanzaPrice == nil or (bonanzaItemCount == nil and bonanzaListings == nil)) then
      MasterMerchant:dm("Warn", "Examine this Bonanza data to see if it is accurate.")
      if next(bonanzaList) then
        if #bonanzaList <= 10 then
          MasterMerchant:dm("Debug", "bonanzaList", bonanzaList)
          MasterMerchant:dm("Debug", "bonanzaStatsData", bonanzaStatsData)
        end
      end
      MasterMerchant:dm("Debug", "bonanzaPrice", bonanzaPrice)
      MasterMerchant:dm("Debug", "bonanzaListings", bonanzaListings)
      MasterMerchant:dm("Debug", "bonanzaItemCount", bonanzaItemCount)

      bonanzaPrice = nil
      bonanzaListings = nil
      bonanzaItemCount = nil
    end
    ]]--
  end
  if itemType == ITEMTYPE_MASTER_WRIT and MasterMerchant.systemSavedVariables.includeVoucherAverage then
    numVouchers = mmUtils:GetVoucherCountByItemLink(itemLink)
  end
  -- Retrieve Item (['sales']) information including graph if hasSalesPrice and not generating new graphInfo
  if hasSalesPrice and not createGraph then
    local itemInfo = mmUtils:GetItemCacheStats(itemLink, daysRange)
    if itemInfo then
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
  end
  -- Retrieve Bonanza (['listings']) information from the cache if we aren't generating it again
  -- not verified
  if hasBonanzaPrice then
    local itemInfo = mmUtils:GetBonanzaCacheStats(itemLink, daysRange)
    if itemInfo then
      bonanzaPrice = itemInfo.bonanzaPrice
      bonanzaListings = itemInfo.bonanzaListings
      bonanzaItemCount = itemInfo.bonanzaItemCount
    end
  end
  -- Setup Graphinfo if salesPoints exists
  if salesPoints then
    graphInfo = { oldestTime = oldestTime, low = lowPrice, high = highPrice, points = salesPoints }
  end
  -- Assign Item (['sales']) information to the cache
  if hasSales and updateItemCache then
    local itemInfo = {
      avgPrice = avgPrice,
      numSales = legitSales,
      numDays = daysHistory,
      numItems = countSold,
      numVouchers = numVouchers,
    }
    mmUtils:SetItemCacheById(itemID, itemIndex, daysRange, itemInfo)
  end
  -- Assign Bonanza (['listings']) information to the cache
  if hasListings and updateBonanzaCache then
    local itemInfo = {
      bonanzaPrice = bonanzaPrice,
      bonanzaListings = bonanzaListings,
      bonanzaItemCount = bonanzaItemCount,
    }
    mmUtils:SetBonanzaCacheById(itemID, itemIndex, daysRange, itemInfo)
  end
  -- Assign Graphinfo to the Item (['sales']) Cache
  if hasSales and salesPoints and updateGraphinfoCache then
    if legitSales and legitSales > 1500 then
      mmUtils:SetGraphInfoCacheById(itemID, itemIndex, daysRange, graphInfo)
    end
  end
  returnData = { ['avgPrice'] = avgPrice, ['numSales'] = legitSales, ['numDays'] = daysHistory, ['numItems'] = countSold, ['numVouchers'] = numVouchers,
                 ['bonanzaPrice'] = bonanzaPrice, ['bonanzaListings'] = bonanzaListings, ['bonanzaItemCount'] = bonanzaItemCount,
                 ['graphInfo'] = graphInfo }
  return returnData
end

function MasterMerchant:itemIDHasSales(itemID, itemIndex)
  local salesData = sales_data[itemID] and sales_data[itemID][itemIndex]
  if salesData and salesData.sales then
    return salesData.totalCount > 0
  end
  return false
end

function MasterMerchant:itemLinkHasSales(itemLink)
  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  return MasterMerchant:itemIDHasSales(itemID, itemIndex)
end

function MasterMerchant:itemIDHasListings(itemID, itemIndex)
  local itemData = listings_data[itemID] and listings_data[itemID][itemIndex]
  if itemData then
    return itemData.totalCount > 0
  end
  return false
end

function MasterMerchant:itemLinkHasListings(itemLink)
  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  return MasterMerchant:itemIDHasListings(itemID, itemIndex)
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
      LEQ:continueWith(function() MasterMerchant.loadRecipesFrom(recNumber + 1, endNumber) end, 'Recipe Cont')
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
    LEQ:addTask(function() MasterMerchant.loadRecipesFrom(1, 450000) end, 'Search Items')
    LEQ:addTask(function() MasterMerchant.BuildEnchantingRecipes(1, 1, 0) end, 'Enchanting Recipes')
    LEQ:start()
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
      LEQ:continueWith(function() MasterMerchant.BuildEnchantingRecipes(potency, essence, aspect) end,
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
    local itemText = zo_strgsub(itemLink, '|H0', '|H1')
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
    local itemText = zo_strgsub(itemLink, '|H0', '|H1')
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

    if (link ~= MM_STRING_EMPTY and zo_strmatch(link, '|H.-:item:(.-):')) then
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

function MasterMerchant.PostPendingItem()
  --MasterMerchant:dm("Debug", "PostPendingItem")
  local tradingHouse = TRADING_HOUSE
  if tradingHouse.pendingItemSlot and tradingHouse.pendingSaleIsValid then
    local itemLink = GetItemLink(BAG_BACKPACK, tradingHouse.pendingItemSlot)
    local _, stackCount, _ = GetItemInfo(BAG_BACKPACK, tradingHouse.pendingItemSlot)
    local itemUniqueId = GetItemUniqueId(BAG_BACKPACK, tradingHouse.pendingItemSlot)

    local theIID = GetItemLinkItemId(itemLink)
    local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
    local guildId, guildName = GetCurrentTradingHouseGuildDetails()

    local theEvent = {
      guild = guildName,
      guildId = guildId,
      itemLink = itemLink,
      quant = stackCount,
      timestamp = GetTimeStamp(),
      price = tradingHouse.invoiceSellPrice.sellPrice,
      seller = GetDisplayName(),
      id = itemUniqueId,
    }
    internal:addPostedItem(theEvent)
    MasterMerchant.listIsDirty[REPORTS] = true
    local pricingDataNamespace = GS17DataSavedVariables[internal.pricingNamespace]
    local priceDataKey = MasterMerchant.systemSavedVariables.priceCalcAll and "pricingdataall" or guildId
    pricingDataNamespace[priceDataKey] = pricingDataNamespace[priceDataKey] or {}
    local pricingDataInfo = pricingDataNamespace[priceDataKey]

    pricingDataInfo[theIID] = pricingDataInfo[theIID] or {}
    pricingDataInfo[theIID][itemIndex] = tradingHouse.invoiceSellPrice.sellPrice / stackCount

    if MasterMerchant.systemSavedVariables.displayListingMessage then
      local messageFormatter = MasterMerchant.concat(GetString(MM_APP_MESSAGE_NAME), GetString(MM_LISTING_ALERT))
      local message = string.format(
        messageFormatter,
        zo_strformat('<<t:1>>', itemLink),
        stackCount,
        tradingHouse.invoiceSellPrice.sellPrice,
        guildName
      )
      MasterMerchant:dm("Info", message)
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
      mmUtils:ResetItemAndBonanzaCache()
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
  if timeWindow > ZO_ONE_DAY_IN_SECONDS then dayWindow = zo_floor(timeWindow / ZO_ONE_DAY_IN_SECONDS) + 1 end

  local overallTimeWindow = GetTimeStamp() - overallOldestTime
  local overallDayWindow = 1
  if overallTimeWindow > ZO_ONE_DAY_IN_SECONDS then overallDayWindow = zo_floor(overallTimeWindow / ZO_ONE_DAY_IN_SECONDS) + 1 end

  local goldPerDay = {}
  local kioskPercentage = {}
  local showFullPrice = MasterMerchant.systemSavedVariables.showFullPrice

  -- Here we'll tweak stats as needed as well as add guilds to the guild chooser
  for theGuildName, guildItemsSold in pairs(itemsSold) do
    goldPerDay[theGuildName] = zo_floor(goldMade[theGuildName] / dayWindow)
    local kioskSalesTemp = 0
    if kioskSales[theGuildName] ~= nil then kioskSalesTemp = kioskSales[theGuildName] end
    if guildItemsSold == 0 then
      kioskPercentage[theGuildName] = 0
    else
      kioskPercentage[theGuildName] = zo_floor((kioskSalesTemp / guildItemsSold) * 100)
    end

    if theGuildName ~= 'SK_STATS_TOTAL' then
      local guildEntry = guildDropdown:CreateItemEntry(theGuildName,
        function() self:UpdateStatsWindow(theGuildName) end)
      guildDropdown:AddItem(guildEntry)
    end

    -- If they have the option set to show prices post-cut, calculate that here
    if not showFullPrice then
      local cutMult = 1 - (GetTradingHouseCutPercentage() / 100)
      goldMade[theGuildName] = zo_floor(goldMade[theGuildName] * cutMult + 0.5)
      goldPerDay[theGuildName] = zo_floor(goldPerDay[theGuildName] * cutMult + 0.5)
      largestSingle[theGuildName][1] = zo_floor(largestSingle[theGuildName][1] * cutMult + 0.5)
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
  local dateRange = MasterMerchant.systemSavedVariables.rankIndexRoster

  MasterMerchant:dm("Info", string.format(GetString(MM_EXPORTING), guildName))
  export[guildName] = {}
  local list = export[guildName]

  local numGuildMembers = GetNumGuildMembers(guildID)
  for guildMemberIndex = 1, numGuildMembers do
    local displayName, note, rankIndex, status, secsSinceLogoff = GetGuildMemberInfo(guildID, guildMemberIndex)

    local amountBought = mmUtils:GetGuildPurchases(guildName, displayName, dateRange)

    local amountSold = mmUtils:GetGuildSales(guildName, displayName, dateRange)

    -- sample [2] = "@Name&Sales&Purchases&Rank"
    local amountTaxes = 0
    amountTaxes = zo_floor(amountSold * 0.035)
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

function MasterMerchant:PostScanParallel(guildName)
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
        dispPrice = zo_floor(cutPrice + 0.5)
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
            (MasterMerchant.systemSavedVariables.showCyroAlerts or GetCurrentMapZoneIndex() ~= 37) then

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
            MasterMerchant.CenterScreenAnnounce_AddMessage('MasterMerchantAlert', CSA_CATEGORY_SMALL_TEXT, SOUNDS.NONE, string.format(GetString(SK_SALES_ALERT_COLOR), zo_strformat('<<t:1>>', theEvent.itemLink), theEvent.quant, stringPrice, theEvent.guild, textTime) .. alertSuffix)
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

        if MasterMerchant.systemSavedVariables.showAnnounceAlerts and (MasterMerchant.systemSavedVariables.showCyroAlerts or GetCurrentMapZoneIndex() ~= 37) then
          MasterMerchant.CenterScreenAnnounce_AddMessage('MasterMerchantAlert', CSA_CATEGORY_SMALL_TEXT, MasterMerchant.systemSavedVariables.alertSoundName, string.format(GetString(SK_SALES_ALERT_GROUP_COLOR), numSold, stringPrice))
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
  if MasterMerchant.isFirstScan then MasterMerchantStatsWindowSlider:SetValue(15) end
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

  --[[TODO make sure that the itemLink is not an empty string by mistake]]--
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

  local timeEntries = {
    { range = MM_DATERANGE_TODAY, label = MM_INDEX_TODAY },
    { range = MM_DATERANGE_YESTERDAY, label = MM_INDEX_YESTERDAY },
    { range = MM_DATERANGE_THISWEEK, label = MM_INDEX_THISWEEK },
    { range = MM_DATERANGE_LASTWEEK, label = MM_INDEX_LASTWEEK },
    { range = MM_DATERANGE_PRIORWEEK, label = MM_INDEX_PRIORWEEK },
    { range = MM_DATERANGE_7DAY, label = MM_INDEX_7DAY },
    { range = MM_DATERANGE_10DAY, label = MM_INDEX_10DAY },
    { range = MM_DATERANGE_30DAY, label = MM_INDEX_30DAY },
    { range = MM_DATERANGE_CUSTOM, label = MasterMerchant.customTimeframeText }
  }

  for _, entry in ipairs(timeEntries) do
    local label = GetString(entry.label)
    if entry.range == MM_DATERANGE_CUSTOM then label = entry.label end
    local timeEntry = timeDropdown:CreateItemEntry(label, function() self:UpdateRosterWindow(entry.range) end)
    timeDropdown:AddItem(timeEntry)
    if MasterMerchant.systemSavedVariables.rankIndexRoster == entry.range then
      timeDropdown:SetSelectedItem(label)
    end
  end
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
        local dateRange = MasterMerchant.systemSavedVariables.rankIndexRoster or MM_DATERANGE_TODAY
        local amountSold = mmUtils:GetGuildSales(GUILD_ROSTER_MANAGER.guildName, data.displayName, dateRange)
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
        local dateRange = MasterMerchant.systemSavedVariables.rankIndexRoster or MM_DATERANGE_TODAY
        local amountBought = mmUtils:GetGuildPurchases(GUILD_ROSTER_MANAGER.guildName, data.displayName, dateRange)
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
        local dateRange = MasterMerchant.systemSavedVariables.rankIndexRoster or MM_DATERANGE_TODAY
        local amountSold = mmUtils:GetGuildSales(GUILD_ROSTER_MANAGER.guildName, data.displayName, dateRange)
        return zo_floor(amountSold * 0.035)
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
        local dateRange = MasterMerchant.systemSavedVariables.rankIndexRoster or MM_DATERANGE_TODAY
        local saleCount = mmUtils:GetSalesCount(GUILD_ROSTER_MANAGER.guildName, data.displayName, dateRange)
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
  -- MasterMerchantPriceCalculatorUnitCostAmount
  local tipStats
  local tradingHouse = TRADING_HOUSE

  if (tradingHouse.pendingItemSlot) then
    local itemLink = GetItemLink(BAG_BACKPACK, tradingHouse.pendingItemSlot)
    local _, stackCount, _ = GetItemInfo(BAG_BACKPACK, tradingHouse.pendingItemSlot)

    local theIID = GetItemLinkItemId(itemLink)
    local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
    local selectedGuildId = GetSelectedTradingHouseGuildId()
    local pricingData = nil

    local pricingDataNamespace = GS17DataSavedVariables[internal.pricingNamespace]
    local priceDataKey = MasterMerchant.systemSavedVariables.priceCalcAll and "pricingdataall" or selectedGuildId
    pricingDataNamespace[priceDataKey] = pricingDataNamespace[priceDataKey] or {}
    local pricingDataInfo = pricingDataNamespace[priceDataKey]

    if pricingDataInfo and pricingDataInfo[theIID] and pricingDataInfo[theIID][itemIndex] then
      pricingData = pricingDataInfo[theIID][itemIndex]
    end

    if pricingData then
      tradingHouse:SetPendingPostPrice(zo_floor(pricingData * stackCount))
    else
      local timeCheck, daysRange = MasterMerchant:CheckTimeframe()
      tipStats = mmUtils:GetItemCacheStats(itemLink, daysRange)
      if tipStats == nil then tipStats = MasterMerchant:GetTooltipStats(itemLink, true, false) end
      if tipStats and tipStats.avgPrice then
        tradingHouse:SetPendingPostPrice(zo_floor(tipStats.avgPrice * stackCount))
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

local function UpdateVars()
  if not LibGuildStore_SavedVariables then return end

  local defaultSavedVars = ShopkeeperSavedVars["Default"]
  if not defaultSavedVars then return end

  local displayNameSavedVars = defaultSavedVars[GetDisplayName()]
  if not displayNameSavedVars then return end

  local unitNameSavedVars = displayNameSavedVars[GetUnitName("player")]
  local accountWideSavedVars = displayNameSavedVars["$AccountWide"]
  if not unitNameSavedVars or not accountWideSavedVars then return end
  if not unitNameSavedVars[GetDisplayName()] or not accountWideSavedVars[GetDisplayName()] then return end

  local oldSavedVariables = unitNameSavedVars[GetDisplayName()]
  local oldAcctSavedVariables = accountWideSavedVars[GetDisplayName()]

  local variables = {
    "historyDepth", "minItemCount", "maxItemCount", "blacklist",
  }

  if not LibGuildStore_SavedVariables.masterMerchantVariablesImported then
    MasterMerchant:dm("Debug", "Checked Old MM Settings")

    for _, key in ipairs(variables) do
      local acctValue = oldSavedVariables[key]
      local savedValue = oldAcctSavedVariables[key]
      local systemValue = MasterMerchant.systemSavedVariables[key]

      if acctValue and key ~= "blacklist" then
        LibGuildStore_SavedVariables[key] = zo_max(acctValue, LibGuildStore_SavedVariables[key])
      end

      if savedValue and key ~= "blacklist" then
        LibGuildStore_SavedVariables[key] = zo_max(savedValue, LibGuildStore_SavedVariables[key])
      end

      if systemValue and key ~= "blacklist" then
        LibGuildStore_SavedVariables[key] = zo_max(systemValue, LibGuildStore_SavedVariables[key])
      end

      -- Check if the key is "blacklist" and not an empty string
      if key == "blacklist" then
        if acctValue and acctValue ~= MM_STRING_EMPTY then
          LibGuildStore_SavedVariables[key] = acctValue
        end

        if savedValue and savedValue ~= MM_STRING_EMPTY then
          LibGuildStore_SavedVariables[key] = savedValue
        end

        if systemValue and systemValue ~= MM_STRING_EMPTY then
          LibGuildStore_SavedVariables[key] = systemValue
        end
      end
    end

    MasterMerchant.systemSavedVariables.masterMerchantVariablesImported = true
  end
  if oldSavedVariables and not internal:is_empty_or_nil(oldSavedVariables) then
    ShopkeeperSavedVars["Default"][GetDisplayName()][GetUnitName("player")][GetDisplayName()] = nil
  end
  if oldAcctSavedVariables and not internal:is_empty_or_nil(oldAcctSavedVariables) then
    ShopkeeperSavedVars["Default"][GetDisplayName()]["$AccountWide"][GetDisplayName()] = nil
  end
end

local function SetupBackupWarning()
    local URL_LINK_TYPE = "mmdocs_url"
    local DISABLE_LINK_TYPE = "mmbackupwarn_disable"
    local function HandleLinkClick(link, button, text, linkStyle, linkType)
        if button ~= MOUSE_BUTTON_INDEX_LEFT then return end
        if linkType == URL_LINK_TYPE then
            RequestOpenUnsafeURL(text)
            return true
        elseif linkType == DISABLE_LINK_TYPE then
            if not MasterMerchant.systemSavedVariables.disableBackupWarning then
                MasterMerchant.systemSavedVariables.disableBackupWarning = true
                CHAT_ROUTER:AddSystemMessage("[MasterMerchant] Warning disabled.")
            end
            return true
        end
    end
    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_CLICKED_EVENT, HandleLinkClick)
    LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, HandleLinkClick)

    EVENT_MANAGER:RegisterForEvent(MasterMerchant.name .. "_BackupWarn" , EVENT_PLAYER_ACTIVATED, function()
        EVENT_MANAGER:UnregisterForEvent(MasterMerchant.name .. "_BackupWarn" , EVENT_PLAYER_ACTIVATED)
        zo_callLater(function()
            local urlLink = ZO_LinkHandler_CreateLinkWithoutBrackets("https://esouimods.github.io/3-master_merchant.html#MajorChangeswithUpdate41", nil, URL_LINK_TYPE)
            if GetAPIVersion() < 101041 then
                if not MasterMerchant.systemSavedVariables.disableBackupWarning then
                    local disableLink = ZO_LinkHandler_CreateLink("Click here to disable this warning", nil, DISABLE_LINK_TYPE)
                    CHAT_ROUTER:AddSystemMessage("|cff6a00[MasterMerchant Warning] Major changes involving guild sales history will occur with Update 41. All sales information from your LibHistoire data cache will be deleted! It is important to read the Master Merchant documentation for information on how to back up your sales data in case of any future data corruption: |c0094ff" .. urlLink .. "|r " .. disableLink)
                end
            else
                CHAT_ROUTER:AddSystemMessage("|cff6a00[Warning] This version of Master Merchant is not compatible with the current game version. Make sure to update to the latest version, but be aware that all previously cached data from LibHistoire will be deleted!")
            end
        end, 1000)
    end)
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
  local systemDefault = {
    -- old settings
    dataLocations = {}, -- unused as of 5-15-2021 but has to stay here for mm import
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
    trimDecimals = false,
    replaceInventoryValues = false,
    replacementTypeToUse = MM_PRICE_MM_AVERAGE,
    displaySalesDetails = false,
    displayItemAnalysisButtons = false,
    focus1 = 10,
    focus2 = 3,
    focus3 = 30,
    blacklist = '',
    defaultDays = MM_RANGE_VALUE_ALL,
    shiftDays = MM_RANGE_VALUE_FOCUS1,
    ctrlDays = MM_RANGE_VALUE_FOCUS2,
    ctrlShiftDays = MM_RANGE_VALUE_FOCUS3,
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
    --[[you could assign this as the default but it needs to be a global var instead
    customTimeframeText = tostring(90) .. ' ' .. GetString(MM_CUSTOM_TIMEFRAME_DAYS),

    Assigned to: MasterMerchant.customTimeframeText
    ]]--
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
    -- outliers
    trimOutliers = false,
    trimOutliersWithPercentile = false,
    outlierPercentile = 5,
    trimOutliersAgressive = false,
    masterMerchantVariablesImported = false,
    disableBackupWarning = false,
  }

  -- Finished setting up defaults, assign to global
  MasterMerchant.systemDefault = systemDefault
  -- Populate savedVariables
  --[[August 25 2023, addressed unused savedVariables issue
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM00DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM00DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')

  The above two lines from one of the old MM00DataSavedVariables modules, I think. I forget why that's there.

  self.savedVariables is used by the containers but with 'MasterMerchant' for the namespace
  self.acctSavedVariables seems to be no longer used
  self.systemSavedVariables is what is used when you are supposedly swaping between acoutwide
  or not such as

  example: MasterMerchant.systemSavedVariables.showChatAlerts = MasterMerchant.systemSavedVariables.showChatAlerts
  self.savedVariables = ZO_SavedVars:New('ShopkeeperSavedVars', 1, GetDisplayName(), old_defaults)
  MasterMerchant.systemSavedVariables.scanHistory is no longer used for MasterMerchant.systemSavedVariables.scanHistory

  savedVariables = ShopkeeperSavedVars["Default"]["@Sharlikran"]["Sharlikran"]["@Sharlikran"]["test"]

  savedVariables = ShopkeeperSavedVars["Default"][GetDisplayName()][GetUnitName("player")][GetDisplayName()]["test"]

  according to the comment below but elf.acctSavedVariables is used when you are supposedly
  swapping between account wide or not such as mentioned above

  ShopkeeperSavedVars["Default"]["MasterMerchant"]["$AccountWide"][GetUnitName("player")][GetDisplayName()]
  ^^^ For reference may not be correct

  acctSavedVariables = ShopkeeperSavedVars["Default"][GetDisplayName()]["$AccountWide"][GetDisplayName()]["test"]
  self.acctSavedVariables = ZO_SavedVars:NewAccountWide('ShopkeeperSavedVars', 1, GetDisplayName(), old_defaults)
  ]]--
  self.systemSavedVariables = ZO_SavedVars:NewAccountWide('ShopkeeperSavedVars', 1, nil, systemDefault, nil, 'MasterMerchant')

  UpdateVars()

  local sv = ShopkeeperSavedVars["Default"]["MasterMerchant"]["$AccountWide"]
  -- Clean up saved variables (from previous versions)
  for key, _ in pairs(sv) do
    -- Delete key-value pair if the key can't also be found in the default settings (except for version)
    if key ~= "version" and systemDefault[key] == nil then
      sv[key] = nil
    end
  end

  SetupBackupWarning()
  MasterMerchant:BuildDateRangeTable()
  MasterMerchant:BuildFilterDateRangeTable()
  MasterMerchant.blacklistTable = MasterMerchant:BuildTableFromString(MasterMerchant.systemSavedVariables.blacklist)
  mmUtils:CreateDaysRangeChoices()
  mmUtils:UpdateDaysRangeSettings()

  --[[ Added 8-27-2021, for some reason if the last view size on a reload UI
  or upon log in is something like LISTINGS then the game will hang for a while

  TODO figure out why it's doing that because I mark the list dirty and I don't
  want to refresh the data or the filter, unless this just happesn upon creation
  ]]--
  MasterMerchant.systemSavedVariables.viewSize = ITEMS

  --MasterMerchant:CreateControls()

  -- updated 11-22 needs to be here to make string
  MasterMerchant.customTimeframeText = MasterMerchant.systemSavedVariables.customTimeframe .. ' ' .. MasterMerchant.systemSavedVariables.customTimeframeType

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
          MasterMerchantPriceCalculatorTotal:SetText(GetString(MM_TOTAL_TITLE) .. self.LocalizedNumber(zo_floor(floorPrice * stackSize)) .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t')
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
        local tradingHouse = TRADING_HOUSE
        local theIID = GetItemLinkItemId(itemLink)
        local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
        local selectedGuildId = GetSelectedTradingHouseGuildId()

        local pricingDataNamespace = GS17DataSavedVariables[internal.pricingNamespace]
        local priceDataKey = MasterMerchant.systemSavedVariables.priceCalcAll and "pricingdataall" or selectedGuildId
        pricingDataNamespace[priceDataKey] = pricingDataNamespace[priceDataKey] or {}
        local pricingDataInfo = pricingDataNamespace[priceDataKey]
        pricingDataInfo[theIID] = pricingDataInfo[theIID] or {}
        pricingDataInfo[theIID][itemIndex] = tradingHouse.invoiceSellPrice.sellPrice / stackCount

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

local function GetDuplicatedValues(dataTable)
  local valueCounts = {}
  local duplicatedValues = {}

  for value, count in pairs(dataTable) do
    if not valueCounts[count] then
      valueCounts[count] = value
    elseif valueCounts[count] then
      duplicatedValues[value] = true
      duplicatedValues[valueCounts[count]] = true
    end
  end
  return duplicatedValues
end

local function DisplayDupeWarning()
  MasterMerchant.duplicateAccountNames = GetDuplicatedValues(GS17DataSavedVariables["accountNames"])
  MasterMerchant.duplicateItemLinks = GetDuplicatedValues(GS16DataSavedVariables["itemLink"])
  MasterMerchant.duplicateGuildNames = GetDuplicatedValues(GS16DataSavedVariables["guildNames"])

  if next(MasterMerchant.duplicateAccountNames) or next(MasterMerchant.duplicateItemLinks) or next(MasterMerchant.duplicateGuildNames) then
    ZO_Dialogs_ShowDialog("MasterMerchantDuplicateGuildStoreDataDialog")
  end
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
    LEQ:addTask(function() MasterMerchant:dm("Info", GetString(MM_INITIALIZING)) end, 'MMInitializing')
    LEQ:addTask(function() MasterMerchant:BuildRemovedItemIdTable() end, 'BuildRemovedItemIdTable')
    LEQ:addTask(function() MasterMerchant:InitScrollLists() end, 'InitScrollLists')
    LEQ:addTask(function() internal:SetupListenerLibHistoire() end, 'SetupListenerLibHistoire')
    LEQ:addTask(function() CompleteMasterMerchantSetup() end, 'CompleteMasterMerchantSetup')
    LEQ:addTask(function() DisplayDupeWarning() end, 'DisplayDupeWarning')
    LEQ:addTask(function()
      if internal:MasterMerchantDataActive() then
        MasterMerchant:dm("Info", GetString(MM_MMXXDATA_OBSOLETE))
      end
    end, 'MasterMerchantDataActive')
    LEQ:addTask(function()
      if internal:ArkadiusDataActive() then
        if not MasterMerchant.systemSavedVariables.disableAttWarn then
          MasterMerchant:dm("Info", GetString(MM_ATT_DATA_ENABLED))
        end
      end
    end, 'ArkadiusDataActive')
    LEQ:addTask(function()
      if ShoppingList then
        MasterMerchant:dm("Info", GetString(MM_SHOPPINGLIST_OBSOLETE))
      end
    end, 'ShoppingListActive')
    LEQ:start()
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
  LMP:Register("font", "Arial Narrow", "$(MM_ARIAL_NARROW)")
  LMP:Register("font", "ESO Cartographer", "$(MM_ESO_CARTOGRAPHER)")
  LMP:Register("font", "Fontin Bold", "$(MM_FONTIN_BOLD)")
  LMP:Register("font", "Fontin Italic", "$(MM_FONTIN_BOLD)")
  LMP:Register("font", "Fontin Regular", "$(MM_FONTIN_REGULAR)")
  LMP:Register("font", "Fontin SmallCaps", "$(MM_FONTIN_SMALLCAPS)")
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
  args = zo_strlower(args)

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

  if args == 'clearprices' then
    if MasterMerchant.systemSavedVariables.priceCalcAll then
      GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"] = {}
      MasterMerchant:dm("Info", GetString(MM_CLEAR_SAVED_PRICES))
    else
      local selectedGuildId = GetSelectedTradingHouseGuildId()
      GS17DataSavedVariables[internal.pricingNamespace][selectedGuildId] = {}
      MasterMerchant:dm("Info", GetString(MM_CLEAR_SAVED_PRICES_GUILD))
    end
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
