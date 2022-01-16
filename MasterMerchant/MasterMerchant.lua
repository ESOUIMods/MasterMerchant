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

local OriginalSetupPendingPost

--[[ can nout use MasterMerchant.itemsViewSize for example
because that will not be available this early.
]]--
local ITEMS = 'items_vs'
local GUILDS = 'guild_vs'
local LISTINGS = 'listings_vs'
local PURCHASES = 'purchases_vs'
local REPORTS = 'reports_vs'

CSA_EVENT_SMALL_TEXT = 1
CSA_EVENT_LARGE_TEXT = 2
CSA_EVENT_COMBINED_TEXT = 3
CSA_EVENT_NO_TEXT = 4
CSA_EVENT_RAID_COMPLETE_TEXT = 5
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
    if nextGuildName ~= "" or nextGuildName ~= nil then
      local r, g, b = GetChatCategoryColor(CHAT_CHANNEL_GUILD_1 - 3 + nextGuild)
      self.guildColor[nextGuildName] = { r, g, b };
    else
      self.guildColor[nextGuildName] = { 255, 255, 255 };
    end
  end
end

function MasterMerchant:CheckTimeframe()
  -- setup focus info
  local range = MasterMerchant.systemSavedVariables.defaultDays
  if IsControlKeyDown() and IsShiftKeyDown() then
    range = MasterMerchant.systemSavedVariables.ctrlShiftDays
  elseif IsControlKeyDown() then
    range = MasterMerchant.systemSavedVariables.ctrlDays
  elseif IsShiftKeyDown() then
    range = MasterMerchant.systemSavedVariables.shiftDays
  end

  -- 10000 for numDays is more or less like saying it is undefined
  local daysRange = 10000
  if range == GetString(MM_RANGE_NONE) then return -1, -1 end
  if range == GetString(MM_RANGE_ALL) then daysRange = 10000 end
  if range == GetString(MM_RANGE_FOCUS1) then daysRange = MasterMerchant.systemSavedVariables.focus1 end
  if range == GetString(MM_RANGE_FOCUS2) then daysRange = MasterMerchant.systemSavedVariables.focus2 end
  if range == GetString(MM_RANGE_FOCUS3) then daysRange = MasterMerchant.systemSavedVariables.focus3 end

  return GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * daysRange), daysRange
end

local function BuildBlacklistTable(str)
  local t = {}
  local function helper(line)
    if line ~= "" then
      t[line] = true
    end
    return ""
  end
  helper((str:gsub("(.-)\r?\n", helper)))
  if next(t) then return t end
end

function RemoveListingsPerBlacklist(list)
  local currentGuild = nil
  local currentSeller = nil
  local blacklistTable = nil
  local nameInBlacklist = nil
  local dataList = { }

  local function IsNameInBlacklist()
    if not blacklistTable then return false end
    if currentGuild and blacklistTable[currentGuild] then return true end
    if currentSeller and blacklistTable[currentSeller] then return true end
    return false
  end

  blacklistTable = BuildBlacklistTable(MasterMerchant.systemSavedVariables.blacklist)
  for i, item in pairs(list) do
    nameInBlacklist = IsNameInBlacklist()
    if not nameInBlacklist then
      table.insert(dataList, item)
    end
  end
  return dataList
end

function UseSalesByTimestamp(list, timeCheck)
  local dataList = { }
  local count = 0
  local oldestTime = nil
  local newestTime = nil
  for i, item in pairs(list) do
    if item.timestamp > timeCheck then
      if oldestTime == nil or oldestTime > item.timestamp then oldestTime = item.timestamp end
      if newestTime == nil or newestTime < item.timestamp then newestTime = item.timestamp end
      count = count + 1
      table.insert(dataList, item)
    end
  end
  return dataList, count, oldestTime, newestTime
end

local stats = {}

function stats.CleanUnitPrice(salesRecord)
  return salesRecord.price / salesRecord.quant
end

function stats.GetSortedSales(t)
  local newTable = { }
  for k, v in internal:spairs(t, function(a, b) return stats.CleanUnitPrice(a) < stats.CleanUnitPrice(b) end) do
    table.insert(newTable, v)
  end
  return newTable
end

-- Get the mean value of a table
function stats.mean(t)
  local sum = 0
  local count = 0

  for key, item in pairs(t) do
    local individualSale = item.price / item.quant
    sum = sum + individualSale
    count = count + 1
  end

  return (sum / count), count, sum
end

--[[ Get the median of a table.
Modified: Requires the table to be sorted already
]]--
function stats.median(t, index, range)
  local temp = {}
  index = index or 1
  range = range or #t

  for i = index, range do
    local individualSale = t[i].price / t[i].quant
    table.insert(temp, individualSale)
  end

  table.sort(temp)

  -- If we have an even number of table elements or odd.
  if math.fmod(#temp, 2) == 0 then
    -- return mean value of middle two elements
    return (temp[#temp / 2] + temp[(#temp / 2) + 1]) / 2
  else
    -- return middle element
    return temp[math.ceil(#temp / 2)]
  end
end

function stats.maxmin(t)
  local max = -math.huge
  local min = math.huge

  for key, item in pairs(t) do
    local individualSale = item.price / item.quant
    max = math.max(max, individualSale)
    min = zo_min(min, individualSale)
  end

  return max, min
end

function stats.range(t)
  local highest, lowest = stats.maxmin(t)
  return highest - lowest
end

-- Get the mode of a table.  Returns a table of values.
-- Works on anything (not just numbers).
function stats.mode(t)
  local counts = {}

  for key, item in pairs(t) do
    local individualSale = item.price / item.quant
    if counts[individualSale] == nil then
      counts[individualSale] = 1
    else
      counts[individualSale] = counts[individualSale] + 1
    end
  end

  local biggestCount = 0

  for k, v in pairs(counts) do
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
function stats.interquartileRange(t)
  local sortedSales = stats.GetSortedSales(t)
  local middleIndex, evenNumber = stats.getMiddleIndex(#sortedSales)
  -- 1,2,3,4
  if evenNumber then
    quartile1 = stats.median(sortedSales, 1, middleIndex)
    quartile3 = stats.median(sortedSales, middleIndex + 1, #sortedSales)
  else
    -- 1,2,3,4,5
    -- odd number
    quartile1 = stats.median(sortedSales, 1, middleIndex)
    quartile3 = stats.median(sortedSales, middleIndex, #sortedSales)
  end
  return quartile1, quartile3, quartile3 - quartile1
end

function stats.evaluateQuartileRangeTable(list, quartile1, quartile3, quartileRange)
  local dataList = { }
  local oldestTime = nil
  local newestTime = nil

  for i, item in pairs(list) do
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

function MasterMerchant:GetWritCount(itemLink)
  local writcount = 0
  local quotient, remainder = math.modf(tonumber(zo_strmatch(itemLink, ':(%d-)$')) / 10000)
  writcount = quotient + math.floor(0.5 + remainder)
  return writcount
end
-- MasterMerchant:GetTooltipStats(theIID, itemIndex, avgOnly, priceEval)
-- GetItemLinkItemId("|H0:item:54484:369:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h")
-- 54484  50:16:4:0:0
-- LibGuildStore_Internal.GetOrCreateIndexFromLink("|H0:item:54484:369:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h")
-- MasterMerchant:GetTooltipStats(54484, "50:16:4:0:0", false, true)
-- Computes the weighted moving average across available data
function MasterMerchant:GetTooltipStats(theIID, itemIndex, avgOnly, priceEval)
  -- 10000 for numDays is more or less like saying it is undefined
  --[[TODO why is there a days range of 10000. I get that it kinda means
  all days but the daysHistory seems to be the actual number to be using.
  For example when you press SHIFT or CTRL then daysHistory and daysRange
  are the same. However, when you do not modify the data, then daysRange
  is 10000 and daysHistory is however many days you have.
  ]]--
  -- setup early local variables
  local list = {}
  local outliersList = {}
  local bonanzaList = {}

  local avgPrice = nil
  local legitSales = nil
  local daysHistory = 10000
  local countSold = nil
  local bonanzaPrice = nil
  local bonanzaSales = nil
  local bonanzaCount = nil

  local oldestTime = nil
  local newestTime = nil
  local lowPrice = nil
  local highPrice = nil
  local salesPoints = {}

  local timeInterval = nil
  local currentGuild = nil
  local currentBuyer = nil
  local currentSeller = nil
  local weigtedCountSold = 0
  local dayInterval = 0
  local nameString = nil
  local clickable = nil
  local skipDots = nil
  local nameInBlacklist = false
  local blacklistTable = nil
  local ignoreOutliers = nil

  local function IsNameInBlacklist()
    if not blacklistTable then return false end
    if currentGuild and blacklistTable[currentGuild] then return true end
    if currentBuyer and blacklistTable[currentBuyer] then return true end
    if currentSeller and blacklistTable[currentSeller] then return true end
    return false
  end

  -- local function for processing the dots on the graph
  local function ProcessDots(individualSale, item)
    local tooltip = nil
    local timeframeString = ""
    local stringPrice = self.LocalizedNumber(individualSale)
    --[[ clickable means to add a detailed tooltip to the dot
    rather then actually click anything
    ]]--
    if clickable then
      local quotient, remainder = math.modf((GetTimeStamp() - item.timestamp) / ZO_ONE_DAY_IN_SECONDS)
      if quotient == 0 then
        timeframeString = GetString(MM_INDEX_TODAY)
      elseif quotient == 1 then
        timeframeString = GetString(MM_INDEX_YESTERDAY)
      elseif quotient >= 2 then
        timeframeString = quotient .. " days ago"
      end
      if item.quant == 1 then
        tooltip = timeframeString .. " " .. string.format(GetString(MM_GRAPH_TIP_SINGLE), currentGuild,
          currentSeller, nameString, currentBuyer, stringPrice)
      else
        tooltip = timeframeString .. " " .. string.format(GetString(MM_GRAPH_TIP), currentGuild, currentSeller,
          nameString, item.quant, currentBuyer, stringPrice)
      end
    else
      -- not clickable or detailed
      tooltip = stringPrice .. '|t16:16:EsoUI/Art/currency/currency_gold.dds|t'
    end
    table.insert(salesPoints,
      { item.timestamp, individualSale, MasterMerchant.guildColor[currentGuild], tooltip, currentSeller })
  end

  local function ProcessSalesInfo(item)
    local weightValue = 0
    -- get individualSale
    local individualSale = item.price / item.quant
    -- determine if it is an outlier, if toggle is on
    if countSold == nil then countSold = 0 end
    countSold = countSold + item.quant
    if avgPrice == nil then avgPrice = 0 end
    if timeInterval > ZO_ONE_DAY_IN_SECONDS then
      weightValue = dayInterval - math.floor((GetTimeStamp() - item.timestamp) / ZO_ONE_DAY_IN_SECONDS)
      avgPrice = avgPrice + (item.price * weightValue)
      weigtedCountSold = weigtedCountSold + (item.quant * weightValue)
    else
      avgPrice = avgPrice + item.price
    end
    if legitSales == nil then legitSales = 0 end
    legitSales = legitSales + 1
    if lowPrice == nil then lowPrice = individualSale else lowPrice = zo_min(lowPrice, individualSale) end
    if highPrice == nil then highPrice = individualSale else highPrice = math.max(highPrice, individualSale) end
    if not skipDots then ProcessDots(individualSale, item) end -- end skip dots
  end

  local function ProcessBonanzaSale(item)
    if bonanzaCount == nil then bonanzaCount = 0 end
    if bonanzaPrice == nil then bonanzaPrice = 0 end
    if bonanzaSales == nil then bonanzaSales = 0 end
    bonanzaCount = bonanzaCount + item.quant
    bonanzaPrice = bonanzaPrice + item.price
    bonanzaSales = bonanzaSales + 1
  end

  -- 10000 for numDays is more or less like saying it is undefined
  --[[TODO why is there a days range of 10000. I get that it kinda means
  all days but the daysHistory seems to be the actual number to be using.
  For example when you press SHIFT or CTRL then daysHistory and daysRange
  are the same. However, when you do not modify the data, then daysRange
  is 10000 and daysHistory is however many days you have.
  ]]--

  local returnData = { ['avgPrice']     = avgPrice, ['numSales'] = legitSales, ['numDays'] = daysHistory, ['numItems'] = countSold,
                       ['bonanzaPrice'] = bonanzaPrice, ['bonanzaSales'] = bonanzaSales, ['bonanzaCount'] = bonanzaCount,
                       ['graphInfo']    = { ['oldestTime'] = oldestTime, ['low'] = lowPrice, ['high'] = highPrice, ['points'] = salesPoints } }
  if not MasterMerchant.isInitialized then return returnData end
  clickable = MasterMerchant.systemSavedVariables.displaySalesDetails
  skipDots = not MasterMerchant.systemSavedVariables.showGraph
  ignoreOutliers = MasterMerchant.systemSavedVariables.trimOutliers

  if priceEval then skipDots = true end

  -- set time for cache
  local timeCheck, daysRange = self:CheckTimeframe()

  -- make sure we have a list of sales to work with
  if MasterMerchant:itemIDHasSales(theIID, itemIndex) and not MasterMerchant:ItemCacheHasInfoById(theIID, itemIndex, daysRange) then
    if not sales_data[theIID][itemIndex].oldestTime then internal:UpdateExtraSalesData(sales_data[theIID][itemIndex]) end
    nameString = sales_data[theIID][itemIndex].itemDesc
    oldestTime = sales_data[theIID][itemIndex].oldestTime
    newestTime = sales_data[theIID][itemIndex].newestTime
    blacklistTable = BuildBlacklistTable(MasterMerchant.systemSavedVariables.blacklist)
    list = sales_data[theIID][itemIndex]['sales']

    --[[
    if daysRange ~= 10000 then
      list, initCount, oldestTime, newestTime = UseSalesByTimestamp(list, timeCheck)
    end
    ]]--

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

    local lookupDataFound = dataPresent(theIID, itemIndex, daysRange)
    ]]--
    if (daysRange == 10000) then
      local quotient, remainder = math.modf((GetTimeStamp() - oldestTime) / ZO_ONE_DAY_IN_SECONDS)
      daysHistory = quotient + math.floor(0.5 + remainder)
    else
      daysHistory = daysRange
    end

    timeInterval = newestTime - oldestTime
    if timeInterval > ZO_ONE_DAY_IN_SECONDS then
      dayInterval = math.floor((GetTimeStamp() - oldestTime) / ZO_ONE_DAY_IN_SECONDS) + 1
    end
    local useDaysRange = daysRange ~= 10000
    -- timeInterval determined reset if SHIFT CTRL used
    oldestTime = nil
    -- start loop for non outliers
    for i, item in pairs(list) do
      currentGuild = internal:GetGuildNameByIndex(item.guild)
      currentBuyer = internal:GetAccountNameByIndex(item.buyer)
      currentSeller = internal:GetAccountNameByIndex(item.seller)
      nameInBlacklist = IsNameInBlacklist()
      if not nameInBlacklist and not ignoreOutliers then
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
      else
        if useDaysRange then
          local validTimeDate = item.timestamp > timeCheck
          if validTimeDate then
            table.insert(outliersList, item)
          end
        else
          table.insert(outliersList, item)
        end
      end
    end -- end for loop for non outliers
    if ignoreOutliers then
      if #outliersList >= 6 then
        local quartile1, quartile3, quartileRange = stats.interquartileRange(outliersList)
        oldestTime = nil
        for i, item in pairs(outliersList) do
          currentGuild = internal:GetGuildNameByIndex(item.guild)
          currentBuyer = internal:GetAccountNameByIndex(item.buyer)
          currentSeller = internal:GetAccountNameByIndex(item.seller)
          local individualSale = item.price / item.quant
          if (individualSale < (quartile1 - 1.5 * quartileRange)) or (individualSale > (quartile3 + 1.5 * quartileRange)) then
            --Debug(string.format("%s : %s was not in range",k,individualSale))
          else
            -- within range
            nameInBlacklist = IsNameInBlacklist()
            if not nameInBlacklist then
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
          end
        end -- end for loop for outliers
      else
        -- end trim outliers if more then 6
        oldestTime = nil
        for i, item in pairs(outliersList) do
          currentGuild = internal:GetGuildNameByIndex(item.guild)
          currentBuyer = internal:GetAccountNameByIndex(item.buyer)
          currentSeller = internal:GetAccountNameByIndex(item.seller)
          -- within range
          nameInBlacklist = IsNameInBlacklist()
          if not nameInBlacklist then
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
        end -- end for loop for outliers less then 6
      end -- end trim outliers if less then 6
    end -- end trim outliers
    if legitSales and legitSales >= 1 then
      if timeInterval > ZO_ONE_DAY_IN_SECONDS then
        avgPrice = avgPrice / weigtedCountSold
      else
        avgPrice = avgPrice / countSold
      end
      --[[found an average price of 0.07 which X 200 is 14g
      even 0.01 X 200 is 2g
      ]]--
      if avgPrice < 0.01 then avgPrice = 0.01 end
    end
  else
    if MasterMerchant:ItemCacheHasInfoById(theIID, itemIndex, daysRange) then
      local itemInfo = MasterMerchant.itemInformationCache[theIID][itemIndex][daysRange]
      avgPrice = itemInfo.avgPrice
      legitSales = itemInfo.numSales
      daysHistory = itemInfo.numDays
      countSold = itemInfo.numItems
      local graphInformation = itemInfo.graphInfo
      oldestTime = graphInformation.oldestTime
      lowPrice = graphInformation.low
      highPrice = graphInformation.high
      salesPoints = graphInformation.points
    end
  end
  if not avgOnly and not priceEval and not MasterMerchant:ItemCacheHasInfoById(theIID, itemIndex, daysRange) then
    local itemInfo = {
      avgPrice  = avgPrice,
      numSales  = legitSales,
      numDays   = daysHistory,
      numItems  = countSold,
      graphInfo = { oldestTime = oldestTime, low = lowPrice, high = highPrice, points = salesPoints },
    }
    if legitSales and legitSales > 1500 then
      MasterMerchant:SetItemCacheById(theIID, itemIndex, daysRange, itemInfo)
    end
  end
  if not avgOnly and MasterMerchant:itemIDHasListings(theIID, itemIndex) then
    bonanzaList = listings_data[theIID][itemIndex]['sales']
    bonanzaList = RemoveListingsPerBlacklist(bonanzaList)
    if #bonanzaList >= 6 then
      local bonanzaQuartile1, bonanzaQuartile3, bonanzaQuartileRange = stats.interquartileRange(bonanzaList)
      for i, item in pairs(bonanzaList) do
        local individualSale = item.price / item.quant
        if (individualSale < (bonanzaQuartile1 - 1.5 * bonanzaQuartileRange)) or (individualSale > (bonanzaQuartile3 + 1.5 * bonanzaQuartileRange)) then
          --Debug(string.format("%s : %s was not in range",k,individualSale))
        else
          ProcessBonanzaSale(item)
        end
      end -- end bonanza loop
    else
      for i, item in pairs(bonanzaList) do
        ProcessBonanzaSale(item)
      end -- end bonanza loop
    end
    if (bonanzaCount and bonanzaCount < 1) or (bonanzaSales and bonanzaSales < 1) then
      if bonanzaPrice == nil then
        MasterMerchant:dm("Warn", "Bonanza information seems incomplete")
        MasterMerchant:dm("Debug", "bonanzaList")
        MasterMerchant:dm("Debug", bonanzaList)
        MasterMerchant:dm("Debug", "bonanzaPrice")
        MasterMerchant:dm("Debug", bonanzaPrice)
        MasterMerchant:dm("Debug", "bonanzaSales")
        MasterMerchant:dm("Debug", bonanzaSales)
        MasterMerchant:dm("Debug", "bonanzaCount")
        MasterMerchant:dm("Debug", bonanzaCount)
      end
      bonanzaPrice = nil
      bonanzaSales = nil
      bonanzaCount = nil
    end
    if bonanzaSales and bonanzaSales >= 1 then
      bonanzaPrice = bonanzaPrice / bonanzaCount
    end
    --[[found an average price of 0.07 which X 200 is 14g
    even 0.01 X 200 is 2g
    ]]--
    if bonanzaPrice and bonanzaPrice < 0.01 then bonanzaPrice = 0.01 end
  end
  returnData = { ['avgPrice']     = avgPrice, ['numSales'] = legitSales, ['numDays'] = daysHistory, ['numItems'] = countSold,
                 ['bonanzaPrice'] = bonanzaPrice, ['bonanzaSales'] = bonanzaSales, ['bonanzaCount'] = bonanzaCount,
                 ['graphInfo']    = { ['oldestTime'] = oldestTime, ['low'] = lowPrice, ['high'] = highPrice, ['points'] = salesPoints } }
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

function MasterMerchant:ItemCacheStats(itemLink, clickable)
  local timeCheck, daysRange = self:CheckTimeframe()
  if MasterMerchant:ItemCacheHasInfoByItemLink(itemLink, daysRange) then
    local itemID = GetItemLinkItemId(itemLink)
    local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
    return MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange]
  end
  return MasterMerchant:GetTooltipStats(itemID, itemIndex, true, true)
end

function MasterMerchant:ItemCacheHasInfoById(theIID, itemIndex, daysRange)
  local itemInfo = MasterMerchant.itemInformationCache[theIID] and MasterMerchant.itemInformationCache[theIID][itemIndex] and MasterMerchant.itemInformationCache[theIID][itemIndex][daysRange]
  if itemInfo then
    if not MasterMerchant.itemInformationCache[theIID][itemIndex][daysRange].avgPrice or
      not MasterMerchant.itemInformationCache[theIID][itemIndex][daysRange].numSales or
      not MasterMerchant.itemInformationCache[theIID][itemIndex][daysRange].numDays or
      not MasterMerchant.itemInformationCache[theIID][itemIndex][daysRange].numItems or
      not MasterMerchant.itemInformationCache[theIID][itemIndex][daysRange].graphInfo then
      return false
    end
    return true
  end
  return false
end

function MasterMerchant:ItemCacheHasInfoByItemLink(itemLink, daysRange)
  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  return MasterMerchant:ItemCacheHasInfoById(itemID, itemIndex, daysRange)
end

function MasterMerchant:SetItemCacheById(itemID, itemIndex, daysRange, itemInfo)
  if MasterMerchant.itemInformationCache[itemID] == nil then MasterMerchant.itemInformationCache[itemID] = {} end
  if MasterMerchant.itemInformationCache[itemID][itemIndex] == nil then MasterMerchant.itemInformationCache[itemID][itemIndex] = {} end
  if MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange] == nil then MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange] = {} end
  MasterMerchant.itemInformationCache[itemID][itemIndex][daysRange] = itemInfo
end

function MasterMerchant:SetItemCacheByItemLink(itemLink, daysRange, itemInfo)
  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  MasterMerchant:SetItemCacheById(itemID, itemIndex, itemInfo)
end

function MasterMerchant:ClearItemCacheById(itemID, itemIndex)
  local itemInfo = MasterMerchant.itemInformationCache[itemID] and MasterMerchant.itemInformationCache[itemID][itemIndex]
  if itemInfo then
    MasterMerchant.itemInformationCache[itemID][itemIndex] = nil
  end
end

function MasterMerchant:ClearItemCacheByItemLink(itemLink)
  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  MasterMerchant:ClearItemCacheById(itemID, itemIndex)
end

function MasterMerchant:ValidInfoForCache(avgPrice, numSales, numDays, numItems)
  if avgPrice == nil or numSales == nil or numDays == nil or numItems == nil then
    return false
  end
  return true
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
function MasterMerchant:AvgPricePriceTip(avgPrice, numSales, numItems, numDays, chatText)
  -- TODO add Bonanza price
  local formatedPriceString = nil
  tipFormat = GetString(MM_TIP_FORMAT_MULTI)
  -- change only when needed
  if numDays < 2 then
    tipFormat = GetString(MM_TIP_FORMAT_SINGLE)
  end

  local avePriceString = self.LocalizedNumber(avgPrice)
  -- chatText
  if not chatText then avePriceString = avePriceString .. '|t16:16:EsoUI/Art/currency/currency_gold.dds|t' end
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
function MasterMerchant:BonanzaPriceTip(bonanzaPrice, bonanzaSales, bonanzaCount, chatText)
  -- TODO add Bonanza price
  local formatedBonanzaString = nil
  local bonanzaPriceString = self.LocalizedNumber(bonanzaPrice)
  -- chatText
  if not chatText then bonanzaPriceString = bonanzaPriceString .. '|t16:16:EsoUI/Art/currency/currency_gold.dds|t' end
  formatedBonanzaString = string.format(GetString(MM_BONANZA_TIP), bonanzaSales, bonanzaCount, bonanzaPriceString)

  return formatedBonanzaString
end

function MasterMerchant:TTCPriceTip(itemLink)
  local formatedTTCString = nil
  local priceStats = MasterMerchant:GetTamrielTradeCentrePrice(itemLink)
  if priceStats then
    local suggestedPriceString = self.LocalizedNumber(priceStats.SuggestedPrice)
    local avgPriceString = self.LocalizedNumber(priceStats.Avg)
    suggestedPriceString = suggestedPriceString .. '|t16:16:EsoUI/Art/currency/currency_gold.dds|t'
    avgPriceString = avgPriceString .. '|t16:16:EsoUI/Art/currency/currency_gold.dds|t'
    formatedTTCString = string.format(GetString(MM_TTC_ALT_TIP), priceStats.EntryCount, suggestedPriceString, avgPriceString)
  else
    formatedTTCString = GetString(MM_NO_TTC_PRICE)
  end

  return formatedTTCString
end

function MasterMerchant.GetItemLinkRecipeNumIngredients(itemLink)
  local numIngredients = GetItemLinkRecipeNumIngredients(itemLink)
  if numIngredients > 0 then
    return numIngredients
  end

  -- Clear player crafted flag and switch to H0 and see if this is an item resulting from a fixed recipe.
  local switchItemLink = string.gsub(string.gsub(itemLink, '0:1:0:0:0:0|h', '0:0:0:0:0:0|h'), '|H1:', '|H0:')
  if MasterMerchant.recipeData[switchItemLink] then
    return GetItemLinkRecipeNumIngredients(MasterMerchant.recipeData[switchItemLink])
  end


  --switch to MM pricing Item style
  local mmStyleLink = zo_strmatch(switchItemLink, '|H.-:item:(.-):')
  if mmStyleLink then
    mmStyleLink = mmStyleLink .. ':' .. internal.GetOrCreateIndexFromLink(switchItemLink)
    if MasterMerchant.virtualRecipe[mmStyleLink] then
      return #MasterMerchant.virtualRecipe[mmStyleLink]
    end
  end

  --[[
  -- See if it's a craftable thingy: potion, armor, weapon
  local itemType, specializedItemType = GetItemLinkItemType('itemLink')


  --]]

  --[[
local itemType = GetItemLinkItemType(itemLink)
  local equipType = GetItemLinkEquipType(itemLink)
local weaponType = GetItemLinkWeaponType(itemLink)
local armorType = GetItemLinkArmorType(itemLink)
local trait = GetItemLinkTraitInfo(itemLink)
local quality = GetItemLinkQuality(itemLink)
local level = GetItemLinkRequiredLevel(itemLink)


  --]]
  return 0
end

function MasterMerchant.GetItemLinkRecipeIngredientInfo(itemLink, i)
  local ingLink = GetItemLinkRecipeIngredientItemLink(itemLink, i)
  if ingLink ~= '' then
    local _, _, numRequired = GetItemLinkRecipeIngredientInfo(itemLink, i)
    return ingLink, numRequired
  end

  local switchItemLink = string.gsub(string.gsub(itemLink, '0:1:0:0:0:0|h', '0:0:0:0:0:0|h'), '|H1:', '|H0:')
  if MasterMerchant.recipeData[switchItemLink] then
    return MasterMerchant.GetItemLinkRecipeIngredientInfo(MasterMerchant.recipeData[switchItemLink], i)
  end

  local mmStyleLink = zo_strmatch(switchItemLink, '|H.-:item:(.-):')
  if mmStyleLink then
    mmStyleLink = mmStyleLink .. ':' .. internal.GetOrCreateIndexFromLink(switchItemLink)
    if MasterMerchant.virtualRecipe[mmStyleLink] then
      return MasterMerchant.virtualRecipe[mmStyleLink][i].item, MasterMerchant.virtualRecipe[mmStyleLink][i].required
    end
  end

  return nil, nil

  --[[
  -- See if it's something for which we've built a recipe
  local itemType, specializedItemType = GetItemLinkItemType('itemLink')

  -- script /d(GetItemLinkRequiredLevel('

  -- Glyph |H1:item:5365:145:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h
  -- /script d(GetItemLinkItemType('|H1:item:5365:145:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h'))
  if itemType == ITEMTYPE_GLYPH_ARMOR or itemType == ITEMTYPE_GLYPH_JEWELRY or itemType == ITEMTYPE_GLYPH_WEAPON then
      if i == 3 then
          -- Aspect : Quality / Color
          return MasterMerchant.AspectRunes[GetItemLinkQuality(itemLink)], 1
      end
      local level = GetItemLinkRequiredLevel(itemLink)
      local cp = GetItemLinkRequiredChampionPoints(itemLink)

      if i == 1 then
          -- Potency : Level & Positive/Negative
      end
      if i == 2 then
          -- Essence : Attibute
      end
  end
  --]]
end

-- TODO fix craft cost
function MasterMerchant:itemCraftPrice(itemLink)

  local itemType = GetItemLinkItemType(itemLink)

  if (itemType == ITEMTYPE_POTION) or (itemType == ITEMTYPE_POISON) then

    -- Potions/Posions aren't done yet
    if true then
      return nil
    end

    if not IsItemLinkCrafted(itemLink) then
      return nil
    end
    local level = GetItemLinkRequiredLevel(itemLink) + GetItemLinkRequiredChampionPoints(itemLink)
    local solvent = (itemType == ITEMTYPE_POTION and MasterMerchant.potionSolvents[level]) or MasterMerchant.poisonSolvents[level]
    local ingLink = string.format('|H1:item:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h', solvent)
    local cost = MasterMerchant.GetItemLinePrice(ingLink)

    --for i = 1, GetMaxTraits() do
    --    local hasTraitAbility, traitAbilityDescription, traitCooldown, traitHasScaling, traitMinLevel, traitMaxLevel, traitIsChampionPoints = GetItemLinkTraitOnUseAbilityInfo(itemLink, i)
    --    if(hasTraitAbility) then
    --    end
    --end
    return cost / 4
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
      local ingLink, numRequired = MasterMerchant.GetItemLinkRecipeIngredientInfo(itemLink, i)
      if ingLink then
        cost = cost + (MasterMerchant.GetItemLinePrice(ingLink) * numRequired)
      end
    end

    local itemType, specializedItemType = GetItemLinkItemType(itemLink)
    -- Food or Drink or Recipe Food/Drink
    if ((itemType == ITEMTYPE_DRINK) or (itemType == ITEMTYPE_FOOD)
      or (itemType == ITEMTYPE_RECIPE and (specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_FOOD or specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_DRINK))) then
      cost = cost / 4
    end
    return cost
  else
    return nil
  end
end

--[[TODO Verified Good
]]--
function MasterMerchant:CraftCostPriceTip(itemLink, chatText)
  local cost = self:itemCraftPrice(itemLink)
  if cost then
    craftTip = GetString(MM_CRAFTCOST_PRICE_TIP)
    local craftTipString = self.LocalizedNumber(cost)
    -- chatText
    if not chatText then craftTip = craftTip .. '|t16:16:EsoUI/Art/currency/currency_gold.dds|t' end

    return string.format(craftTip, craftTipString)
  else
    return nil
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
      MasterMerchant.potionSolvents[GetItemLinkRequiredLevel(itemLink) + GetItemLinkRequiredChampionPoints(itemLink)] = recNumber
    elseif itemType == ITEMTYPE_POISON_BASE then
      MasterMerchant.poisonSolvents[GetItemLinkRequiredLevel(itemLink) + GetItemLinkRequiredChampionPoints(itemLink)] = recNumber
    elseif itemType == ITEMTYPE_REAGENT then
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

      if (resultLink ~= "") then
        MasterMerchant.recipeData[resultLink] = itemLink
        MasterMerchant.recipeCount = MasterMerchant.recipeCount + 1
        --DEBUG
        --d(MasterMerchant.recipeCount .. ') ' .. itemLink .. ' --> ' .. resultLink  .. ' ('  .. recNumber .. ')')
      end
    end

    if (recNumber >= endNumber) then
      MasterMerchant:dm("Info", '|cFFFF00Recipes Initialized -- Found information on ' .. MasterMerchant.recipeCount .. ' recipes.|r')
      MasterMerchant.systemSavedVariables.recipeData = MasterMerchant.recipeData
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

    MasterMerchant.reagents = {}
    MasterMerchant.traits = {}
    MasterMerchant.potionSolvents = {}
    MasterMerchant.poisonSolvents = {}

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

    local glyph = GetEnchantingResultingItemLink(5, potencyNum, 5, essenceNum, 5, aspectNum)
    --d(glyph)
    --d(potencyNum .. '.' .. essenceNum .. '.' .. aspectNum)
    if (glyph ~= '') then
      local mmGlyph = zo_strmatch(glyph,
        '|H.-:item:(.-):') .. ':' .. internal.GetOrCreateIndexFromLink(glyph)

      MasterMerchant.virtualRecipe[mmGlyph] = {
        [1] = { ['item']            = string.format('|H1:item:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h',
          potencyNum), ['required'] = 1 },
        [2] = { ['item']            = string.format('|H1:item:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h',
          essenceNum), ['required'] = 1 },
        [3] = { ['item']           = string.format('|H1:item:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h',
          aspectNum), ['required'] = 1 }
      }
    end

    --DEBUG
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

-- |H1:item:90919:359:50:0:0:0:0:0:0:0:0:0:0:0:0:23:0:0:0:10000:0|h|h
-- |H0:item:90919:359:50:0:0:0:0:0:0:0:0:0:0:0:0:23:0:0:0:10000:0|h|h
-- |H1:item:95396:363:50:0:0:0:0:0:0:0:0:0:0:0:0:35:0:0:0:400:0|h|h
-- |H1:item:151661:4:1:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:0|h|h
function MasterMerchant:OnItemLinkAction(itemLink)
  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  local tipLine = nil
  local bonanzaTipline = nil
  -- old values: tipLine, bonanzaTipline, numDays, avgPrice, bonanzaPrice, graphInfo
  local statsInfo = self:GetTooltipStats(itemID, itemIndex, false, true)
  if statsInfo.avgPrice then
    tipLine = MasterMerchant:AvgPricePriceTip(statsInfo.avgPrice, statsInfo.numSales, statsInfo.numItems,
      statsInfo.numDays, true)
  end
  if statsInfo.bonanzaPrice then
    bonanzaTipline = MasterMerchant:BonanzaPriceTip(statsInfo.bonanzaPrice, statsInfo.bonanzaSales, statsInfo.bonanzaCount, true)
  end

  if not tipLine then
    -- 10000 for numDays is more or less like saying it is undefined
    if statsInfo.numDays == 10000 then
      tipLine = GetString(MM_TIP_FORMAT_NONE)
    else
      tipLine = string.format(GetString(MM_TIP_FORMAT_NONE_RANGE), statsInfo.numDays)
    end
  end
  if bonanzaTipline then
    bonanzaTipline = MasterMerchant.concat(":", bonanzaTipline)
  end
  local ChatEditControl = CHAT_SYSTEM.textEntry.editControl
  if (not ChatEditControl:HasFocus()) then StartChatInput() end
  local itemText = string.gsub(itemLink, '|H0', '|H1')
  ChatEditControl:InsertText(MasterMerchant.concat(tipLine, bonanzaTipline, GetString(MM_TIP_FOR), itemText))
end

function MasterMerchant:onItemActionLinkCCLink(itemLink)
  local tipLine = MasterMerchant:CraftCostPriceTip(itemLink, true)
  if not tipLine then
    tipLine = "No Crafting Price Available"
  end
  if tipLine then
    local ChatEditControl = CHAT_SYSTEM.textEntry.editControl
    if (not ChatEditControl:HasFocus()) then StartChatInput() end
    local itemText = string.gsub(itemLink, '|H0', '|H1')
    ChatEditControl:InsertText(MasterMerchant.concat(tipLine, GetString(MM_TIP_FOR), itemText))
  end
end

function MasterMerchant:onItemActionPopupInfoLink(itemLink)
  --[[MM_Graph.itemLink was added to there is a current link
  for the graph. When adding a seller to the filter that
  changes the outcome of the calculations so the tooltip
  cache needs to be reset
  ]]--
  MM_Graph.itemLink = itemLink
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
      AddMenuItem(GetString(MM_POPUP_ITEM_DATA), function() MasterMerchant:onItemActionPopupInfoLink(link) end,
        MENU_ADD_OPTION_LABEL)

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

    if (link ~= "" and string.match(link, '|H.-:item:(.-):')) then
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
    if (button == 2 and player ~= '') then
      ClearMenu()
      AddMenuItem(GetString(SI_SOCIAL_LIST_SEND_MESSAGE),
        function() StartChatInput(nil, CHAT_CHANNEL_WHISPER, player) end)
      AddMenuItem(GetString(SI_SOCIAL_MENU_SEND_MAIL), function() MAIL_SEND:ComposeMailTo(player) end)
      ShowMenu(control)
    end
  end
end

function MasterMerchant:my_AddFilterHandler_OnLinkMouseUp(itemLink, button, control)
  if (button == 2 and itemLink ~= '') then
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
  if not Teleporter then
    MasterMerchant:dm("Info", GetString(MM_BEAM_ME_UP_MISSING))
    return
  end
  if (button == 2 and player ~= '') then
    ClearMenu()
    AddMenuItem(GetString(MM_TRAVEL_TO_ZONE_TEXT), function() Teleporter.sc_porting(guildZoneId) end)
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
      guild     = guildName,
      guildId   = guildId,
      itemLink  = itemLink,
      quant     = stackCount,
      timestamp = GetTimeStamp(),
      price     = self.invoiceSellPrice.sellPrice,
      seller    = GetDisplayName(),
      id        = itemUniqueId,
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

MasterMerchant.CustomDealCalc = {
  ['@Causa'] = function(setPrice, salesCount, purchasePrice, stackCount)
    local deal = -1
    local margin = 0
    local profit = -1
    if (setPrice) then
      local unitPrice = purchasePrice / stackCount
      profit = (setPrice - unitPrice) * stackCount
      margin = tonumber(string.format('%.2f', (((setPrice * .92) - unitPrice) / unitPrice) * 100))

      if (margin >= 100) then
        deal = 5
      elseif (margin >= 75) then
        deal = 4
      elseif (margin >= 50) then
        deal = 3
      elseif (margin >= 25) then
        deal = 2
      elseif (margin >= 0) then
        deal = 1
      else
        deal = 0
      end
    else
      -- No sales seen
      deal = -2
      margin = nil
    end
    return deal, margin, profit
  end
}

MasterMerchant.CustomDealCalc['@freakyfreak'] = MasterMerchant.CustomDealCalc['@Causa']

function MasterMerchant:myZO_InventorySlot_ShowContextMenu(inventorySlot)
  local st = ZO_InventorySlot_GetType(inventorySlot)
  link = nil
  if st == SLOT_TYPE_ITEM or st == SLOT_TYPE_EQUIPMENT or st == SLOT_TYPE_BANK_ITEM or st == SLOT_TYPE_GUILD_BANK_ITEM or
    st == SLOT_TYPE_TRADING_HOUSE_POST_ITEM or st == SLOT_TYPE_REPAIR or st == SLOT_TYPE_CRAFTING_COMPONENT or st == SLOT_TYPE_PENDING_CRAFTING_COMPONENT or
    st == SLOT_TYPE_PENDING_CRAFTING_COMPONENT or st == SLOT_TYPE_PENDING_CRAFTING_COMPONENT or st == SLOT_TYPE_CRAFT_BAG_ITEM then
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    link = GetItemLink(bag, index)
  end
  if st == SLOT_TYPE_TRADING_HOUSE_ITEM_RESULT then
    link = GetTradingHouseSearchResultItemLink(ZO_Inventory_GetSlotIndex(inventorySlot))
  end
  if st == SLOT_TYPE_TRADING_HOUSE_ITEM_LISTING then
    link = GetTradingHouseListingItemLink(ZO_Inventory_GetSlotIndex(inventorySlot), linkStyle)
  end
  if (link and zo_strmatch(link, '|H.-:item:(.-):')) then
    zo_callLater(function()
      if MasterMerchant:itemCraftPrice(link) then
        AddMenuItem(GetString(MM_CRAFT_COST_TO_CHAT), function() self:onItemActionLinkCCLink(link) end,
          MENU_ADD_OPTION_LABEL)
      end
      AddMenuItem(GetString(MM_POPUP_ITEM_DATA), function() self:onItemActionPopupInfoLink(link) end,
        MENU_ADD_OPTION_LABEL)
      AddMenuItem(GetString(MM_STATS_TO_CHAT), function() self:OnItemLinkAction(link) end,
        MENU_ADD_OPTION_LABEL)
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
  local allGuilds = guildDropdown:CreateItemEntry(GetString(SK_STATS_ALL_GUILDS),
    function() self:UpdateStatsWindow('SK_STATS_TOTAL') end)
  guildDropdown:AddItem(allGuilds)

  -- 86,400 seconds in a day; this will be the epoch time statsDays ago
  -- (roughly, actual time computations are a LOT more complex but meh)
  local statsDaysEpoch = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * statsDays)

  -- Loop through the player's sales and create the stats as appropriate
  -- (everything or everything with a timestamp after statsDaysEpoch)

  indexes = sr_index[internal.PlayerSpecialText]
  if indexes then
    for i = 1, #indexes do
      local itemID = indexes[i][1]
      local itemData = indexes[i][2]
      local itemIndex = indexes[i][3]

      local theItem = sales_data[itemID][itemData]['sales'][itemIndex]
      local currentItemLink = internal:GetItemLinkByIndex(theItem['itemLink'])
      local currentGuild = internal:GetGuildNameByIndex(theItem['guild'])
      local currentBuyer = internal:GetAccountNameByIndex(theItem['buyer'])
      local currentSeller = internal:GetAccountNameByIndex(theItem['seller'])
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
  return { numSold      = itemsSold,
           numDays      = dayWindow,
           totalDays    = overallDayWindow,
           totalGold    = goldMade,
           avgGold      = goldPerDay,
           biggestSale  = largestSingle,
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
    MasterMerchant.USE_TTC_SUGGESTED,
    MasterMerchant.USE_TTC_AVERAGE,
    MasterMerchant.USE_MM_AVERAGE,
    MasterMerchant.USE_BONANZA,
  }
else
  MasterMerchant.dealCalcChoices = {
  GetString(GS_DEAL_CALC_MM_AVERAGE),
  GetString(GS_DEAL_CALC_BONANZA_PRICE),
  }
  MasterMerchant.dealCalcValues = {
    MasterMerchant.USE_MM_AVERAGE,
    MasterMerchant.USE_BONANZA,
  }
end
-- LibAddon init code
function MasterMerchant:LibAddonInit()
  -- configure font choices
  MasterMerchant:SetFontListChoices()
  MasterMerchant:dm("Debug", "LibAddonInit")
  local panelData = {
    type                = 'panel',
    name                = 'Master Merchant',
    displayName         = GetString(MM_APP_NAME),
    author              = GetString(MM_APP_AUTHOR),
    version             = self.version,
    website             = "https://www.esoui.com/downloads/fileinfo.php?id=2753",
    feedback            = "https://www.esoui.com/downloads/fileinfo.php?id=2753",
    donation            = "https://sharlikran.github.io/",
    registerForRefresh  = true,
    registerForDefaults = true,
  }
  LAM:RegisterAddonPanel('MasterMerchantOptions', panelData)

  local optionsData = {
    [1]  = {
      type    = "header",
      name    = GetString(MASTER_MERCHANT_WINDOW_NAME),
      width   = "full",
      helpUrl = "https://esouimods.github.io/3-master_merchant.html#MasterMerchantWindowOptions",
    },
    -- Open main window with mailbox scenes
    [2]  = {
      type    = 'checkbox',
      name    = GetString(SK_OPEN_MAIL_NAME),
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
    },
    -- Open main window with trading house scene
    [3]  = {
      type    = 'checkbox',
      name    = GetString(SK_OPEN_STORE_NAME),
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
    },
    -- Show full sale price or post-tax price
    [4]  = {
      type    = 'checkbox',
      name    = GetString(SK_FULL_SALE_NAME),
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
    },
    -- Font to use
    [5]  = {
      type    = 'dropdown',
      name    = GetString(SK_WINDOW_FONT_NAME),
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
    },
    -- 6 Sound and Alert options
    [6]  = {
      type     = 'submenu',
      name     = GetString(SK_ALERT_OPTIONS_NAME),
      tooltip  = GetString(SK_ALERT_OPTIONS_TIP),
      helpUrl  = "https://esouimods.github.io/3-master_merchant.html#AlertOptions",
      controls = {
        -- On-Screen Alerts
        [1] = {
          type    = 'checkbox',
          name    = GetString(SK_ALERT_ANNOUNCE_NAME),
          tooltip = GetString(SK_ALERT_ANNOUNCE_TIP),
          getFunc = function() return MasterMerchant.systemSavedVariables.showAnnounceAlerts end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.showAnnounceAlerts = value end,
          default = MasterMerchant.systemDefault.showAnnounceAlerts,
        },
        [2] = {
          type    = 'checkbox',
          name    = GetString(SK_ALERT_CYRODIIL_NAME),
          tooltip = GetString(SK_ALERT_CYRODIIL_TIP),
          getFunc = function() return MasterMerchant.systemSavedVariables.showCyroAlerts end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.showCyroAlerts = value end,
          default = MasterMerchant.systemDefault.showCyroAlerts,
        },
        -- Chat Alerts
        [3] = {
          type    = 'checkbox',
          name    = GetString(SK_ALERT_CHAT_NAME),
          tooltip = GetString(SK_ALERT_CHAT_TIP),
          getFunc = function() return MasterMerchant.systemSavedVariables.showChatAlerts end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.showChatAlerts = value end,
          default = MasterMerchant.systemDefault.showChatAlerts,
        },
        -- Sound to use for alerts
        [4] = {
          type    = 'dropdown',
          name    = GetString(SK_ALERT_TYPE_NAME),
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
          type    = 'checkbox',
          name    = GetString(SK_MULT_ALERT_NAME),
          tooltip = GetString(SK_MULT_ALERT_TIP),
          getFunc = function() return MasterMerchant.systemSavedVariables.showMultiple end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.showMultiple = value end,
          default = MasterMerchant.systemDefault.showMultiple,
        },
        -- Offline sales report
        [6] = {
          type    = 'checkbox',
          name    = GetString(SK_OFFLINE_SALES_NAME),
          tooltip = GetString(SK_OFFLINE_SALES_TIP),
          getFunc = function() return MasterMerchant.systemSavedVariables.offlineSales end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.offlineSales = value end,
          default = MasterMerchant.systemDefault.offlineSales,
        },
        -- should we display the item listed message?
        [7] = {
          type     = 'checkbox',
          name     = GetString(MM_DISPLAY_LISTING_MESSAGE_NAME),
          tooltip  = GetString(MM_DISPLAY_LISTING_MESSAGE_TIP),
          getFunc  = function() return MasterMerchant.systemSavedVariables.displayListingMessage end,
          setFunc  = function(value) MasterMerchant.systemSavedVariables.displayListingMessage = value end,
          default  = MasterMerchant.systemDefault.displayListingMessage,
          disabled = function() return MasterMerchant.AwesomeGuildStoreDetected end,
        },
      },
    },
    -- 7 Tip display and calculation options
    [7]  = {
      type     = 'submenu',
      name     = GetString(MM_CALC_OPTIONS_NAME),
      tooltip  = GetString(MM_CALC_OPTIONS_TIP),
      helpUrl  = "https://esouimods.github.io/3-master_merchant.html#CalculationDisplayOptions",
      controls = {
        -- On-Screen Alerts
        [1]  = {
          type    = 'slider',
          name    = GetString(MM_DAYS_FOCUS_ONE_NAME),
          tooltip = GetString(MM_DAYS_FOCUS_ONE_TIP),
          min     = 1,
          max     = 90,
          getFunc = function() return MasterMerchant.systemSavedVariables.focus1 end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.focus1 = value end,
          default = MasterMerchant.systemDefault.focus1,
        },
        [2]  = {
          type    = 'slider',
          name    = GetString(MM_DAYS_FOCUS_TWO_NAME),
          tooltip = GetString(MM_DAYS_FOCUS_TWO_TIP),
          min     = 1,
          max     = 90,
          getFunc = function() return MasterMerchant.systemSavedVariables.focus2 end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.focus2 = value end,
          default = MasterMerchant.systemDefault.focus2,
        },
        [3]  = {
          type    = 'slider',
          name    = GetString(MM_DAYS_FOCUS_THREE_NAME),
          tooltip = GetString(MM_DAYS_FOCUS_THREE_TIP),
          min     = 1,
          max     = 90,
          getFunc = function() return MasterMerchant.systemSavedVariables.focus3 end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.focus3 = value end,
          default = MasterMerchant.systemDefault.focus3,
        },
        -- default time range
        [4]  = {
          type    = 'dropdown',
          name    = GetString(MM_DEFAULT_TIME_NAME),
          tooltip = GetString(MM_DEFAULT_TIME_TIP),
          choices = { GetString(MM_RANGE_ALL), GetString(MM_RANGE_FOCUS1), GetString(MM_RANGE_FOCUS2), GetString(MM_RANGE_FOCUS3), GetString(MM_RANGE_NONE) },
          getFunc = function() return MasterMerchant.systemSavedVariables.defaultDays end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.defaultDays = value end,
          default = MasterMerchant.systemDefault.defaultDays,
        },
        -- shift time range
        [5]  = {
          type    = 'dropdown',
          name    = GetString(MM_SHIFT_TIME_NAME),
          tooltip = GetString(MM_SHIFT_TIME_TIP),
          choices = { GetString(MM_RANGE_ALL), GetString(MM_RANGE_FOCUS1), GetString(MM_RANGE_FOCUS2), GetString(MM_RANGE_FOCUS3), GetString(MM_RANGE_NONE) },
          getFunc = function() return MasterMerchant.systemSavedVariables.shiftDays end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.shiftDays = value end,
          default = MasterMerchant.systemDefault.shiftDays,
        },
        -- ctrl time range
        [6]  = {
          type    = 'dropdown',
          name    = GetString(MM_CTRL_TIME_NAME),
          tooltip = GetString(MM_CTRL_TIME_TIP),
          choices = { GetString(MM_RANGE_ALL), GetString(MM_RANGE_FOCUS1), GetString(MM_RANGE_FOCUS2), GetString(MM_RANGE_FOCUS3), GetString(MM_RANGE_NONE) },
          getFunc = function() return MasterMerchant.systemSavedVariables.ctrlDays end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.ctrlDays = value end,
          default = MasterMerchant.systemDefault.ctrlDays,
        },
        -- ctrl-shift time range
        [7]  = {
          type    = 'dropdown',
          name    = GetString(MM_CTRLSHIFT_TIME_NAME),
          tooltip = GetString(MM_CTRLSHIFT_TIME_TIP),
          choices = { GetString(MM_RANGE_ALL), GetString(MM_RANGE_FOCUS1), GetString(MM_RANGE_FOCUS2), GetString(MM_RANGE_FOCUS3), GetString(MM_RANGE_NONE) },
          getFunc = function() return MasterMerchant.systemSavedVariables.ctrlShiftDays end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.ctrlShiftDays = value end,
          default = MasterMerchant.systemDefault.ctrlShiftDays,
        },
        [8]  = {
          type    = 'slider',
          name    = GetString(MM_NO_DATA_DEAL_NAME),
          tooltip = GetString(MM_NO_DATA_DEAL_TIP),
          min     = 0,
          max     = 5,
          getFunc = function() return MasterMerchant.systemSavedVariables.noSalesInfoDeal end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.noSalesInfoDeal = value end,
          default = MasterMerchant.systemDefault.noSalesInfoDeal,
        },
        -- blacklisted players and guilds
        [9]  = {
          type        = 'editbox',
          name        = GetString(MM_BLACKLIST_NAME),
          tooltip     = GetString(MM_BLACKLIST_TIP),
          getFunc     = function() return MasterMerchant.systemSavedVariables.blacklist end,
          setFunc     = function(value)
            MasterMerchant.systemSavedVariables.blacklist = value
            MasterMerchant.itemInformationCache = { }
          end,
          default     = MasterMerchant.systemDefault.blacklist,
          isMultiline = true,
          textType    = TEXT_TYPE_ALL,
          width       = "full"
        },
        -- customTimeframe
        [10] = {
          type    = 'slider',
          name    = GetString(MM_CUSTOM_TIMEFRAME_NAME),
          tooltip = GetString(MM_CUSTOM_TIMEFRAME_TIP),
          min     = 1,
          max     = 24 * 31,
          getFunc = function() return MasterMerchant.systemSavedVariables.customTimeframe end,
          setFunc = function(value)
            MasterMerchant.systemSavedVariables.customTimeframe = value
            MasterMerchant.customTimeframeText = MasterMerchant.systemSavedVariables.customTimeframe .. ' ' .. MasterMerchant.systemSavedVariables.customTimeframeType
            MasterMerchant:BuildRosterTimeDropdown()
            MasterMerchant:BuildGuiTimeDropdown()
          end,
          default = MasterMerchant.systemDefault.customTimeframe,
        },
        -- shift time range
        [11] = {
          type    = 'dropdown',
          name    = GetString(MM_CUSTOM_TIMEFRAME_SCALE_NAME),
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
        },
      },
    },
    -- 8 guild roster menu
    [8]  = {
      type     = 'submenu',
      name     = GetString(MM_GUILD_ROSTER_OPTIONS_NAME),
      tooltip  = GetString(MM_GUILD_ROSTER_OPTIONS_TIP),
      controls = {
        -- should we display info on guild roster?
        [1] = {
          type    = 'checkbox',
          name    = GetString(SK_ROSTER_INFO_NAME),
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
          type     = 'checkbox',
          name     = GetString(MM_SALES_COLUMN_NAME),
          tooltip  = GetString(MM_SALES_COLUMN_TIP),
          getFunc  = function() return MasterMerchant.systemSavedVariables.diplaySalesInfo end,
          setFunc  = function(value)
            MasterMerchant.systemSavedVariables.diplaySalesInfo = value
            MasterMerchant.guild_columns['sold']:IsDisabled(not value)
          end,
          disabled = function() return not MasterMerchant.systemSavedVariables.diplayGuildInfo end,
          default  = MasterMerchant.systemDefault.diplaySalesInfo,
        },
        -- guild roster options
        [3] = {
          type     = 'checkbox',
          name     = GetString(MM_PURCHASES_COLUMN_NAME),
          tooltip  = GetString(MM_PURCHASES_COLUMN_TIP),
          getFunc  = function() return MasterMerchant.systemSavedVariables.diplayPurchasesInfo end,
          setFunc  = function(value)
            MasterMerchant.systemSavedVariables.diplayPurchasesInfo = value
            MasterMerchant.guild_columns['bought']:IsDisabled(not value)
          end,
          disabled = function() return not MasterMerchant.systemSavedVariables.diplayGuildInfo end,
          default  = MasterMerchant.systemDefault.diplayPurchasesInfo,
        },
        [4] = {
          type     = 'checkbox',
          name     = GetString(MM_TAXES_COLUMN_NAME),
          tooltip  = GetString(MM_TAXES_COLUMN_TIP),
          getFunc  = function() return MasterMerchant.systemSavedVariables.diplayTaxesInfo end,
          setFunc  = function(value)
            MasterMerchant.systemSavedVariables.diplayTaxesInfo = value
            MasterMerchant.guild_columns['per']:IsDisabled(not value)
          end,
          disabled = function() return not MasterMerchant.systemSavedVariables.diplayGuildInfo end,
          default  = MasterMerchant.systemDefault.diplayTaxesInfo,
        },
        [5] = {
          type     = 'checkbox',
          name     = GetString(MM_COUNT_COLUMN_NAME),
          tooltip  = GetString(MM_COUNT_COLUMN_TIP),
          getFunc  = function() return MasterMerchant.systemSavedVariables.diplayCountInfo end,
          setFunc  = function(value)
            MasterMerchant.systemSavedVariables.diplayCountInfo = value
            MasterMerchant.guild_columns['count']:IsDisabled(not value)
          end,
          disabled = function() return not MasterMerchant.systemSavedVariables.diplayGuildInfo end,
          default  = MasterMerchant.systemDefault.diplayCountInfo,
        },
      },
    },
    -- 9 Other Tooltips -----------------------------------
    [9]  = {
      type    = "header",
      name    = GetString(MASTER_MERCHANT_TOOLTIP_OPTIONS),
      width   = "full",
      helpUrl = "https://esouimods.github.io/3-master_merchant.html#OtherTooltipOptions",
    },
    -- Whether or not to show the pricing graph in tooltips
    [10] = {
      type    = 'checkbox',
      name    = GetString(SK_SHOW_GRAPH_NAME),
      tooltip = GetString(SK_SHOW_GRAPH_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.showGraph end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.showGraph = value end,
      default = MasterMerchant.systemDefault.showGraph,
    },
    -- Whether or not to show the pricing data in tooltips
    [11] = {
      type    = 'checkbox',
      name    = GetString(SK_SHOW_PRICING_NAME),
      tooltip = GetString(SK_SHOW_PRICING_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.showPricing end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.showPricing = value end,
      default = MasterMerchant.systemDefault.showPricing,
    },
    -- Whether or not to show the bonanza price in tooltips
    [12] = {
      type    = 'checkbox',
      name    = GetString(SK_SHOW_BONANZA_PRICE_NAME),
      tooltip = GetString(SK_SHOW_BONANZA_PRICE_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.showBonanzaPricing end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.showBonanzaPricing = value end,
      default = MasterMerchant.systemDefault.showBonanzaPricing,
    },
    -- Whether or not to show the alternate TTC price in tooltips
    [13] = {
      type    = 'checkbox',
      name    = GetString(SK_SHOW_TTC_PRICE_NAME),
      tooltip = GetString(SK_SHOW_TTC_PRICE_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.showAltTtcTipline end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.showAltTtcTipline = value end,
      default = MasterMerchant.systemDefault.showAltTtcTipline,
    },
    -- Whether or not to show tooltips on the graph points
    [14] = {
      type    = 'checkbox',
      name    = GetString(MM_GRAPH_INFO_NAME),
      tooltip = GetString(MM_GRAPH_INFO_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.displaySalesDetails end,
      setFunc = function(value)
        MasterMerchant.systemSavedVariables.displaySalesDetails = value
        MasterMerchant.itemInformationCache = { }
      end,
      default = MasterMerchant.systemDefault.displaySalesDetails,
    },
    -- Whether or not to show the crafting costs data in tooltips
    [15] = {
      type    = 'checkbox',
      name    = GetString(SK_SHOW_CRAFT_COST_NAME),
      tooltip = GetString(SK_SHOW_CRAFT_COST_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.showCraftCost end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.showCraftCost = value end,
      default = MasterMerchant.systemDefault.showCraftCost,
    },
    -- Whether or not to show the quality/level adjustment buttons
    [16] = {
      type    = 'checkbox',
      name    = GetString(MM_LEVEL_QUALITY_NAME),
      tooltip = GetString(MM_LEVEL_QUALITY_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.displayItemAnalysisButtons end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.displayItemAnalysisButtons = value end,
      default = MasterMerchant.systemDefault.displayItemAnalysisButtons,
    },
    -- should we trim outliers prices?
    [17] = {
      type    = 'checkbox',
      name    = GetString(SK_TRIM_OUTLIERS_NAME),
      tooltip = GetString(SK_TRIM_OUTLIERS_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.trimOutliers end,
      setFunc = function(value)
        MasterMerchant.systemSavedVariables.trimOutliers = value
        MasterMerchant.itemInformationCache = { }
      end,
      default = MasterMerchant.systemDefault.trimOutliers,
    },
    -- should we trim off decimals?
    [18] = {
      type    = 'checkbox',
      name    = GetString(SK_TRIM_DECIMALS_NAME),
      tooltip = GetString(SK_TRIM_DECIMALS_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.trimDecimals end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.trimDecimals = value end,
      default = MasterMerchant.systemDefault.trimDecimals,
    },
    [19] = {
      type    = "header",
      name    = GetString(MASTER_MERCHANT_INVENTORY_OPTIONS),
      width   = "full",
      helpUrl = "https://esouimods.github.io/3-master_merchant.html#InventoryOptions",
    },
    -- should we replace inventory values?
    [20] = {
      type    = 'checkbox',
      name    = GetString(MM_REPLACE_INVENTORY_VALUES_NAME),
      tooltip = GetString(MM_REPLACE_INVENTORY_VALUES_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.replaceInventoryValues end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.replaceInventoryValues = value end,
      default = MasterMerchant.systemDefault.replaceInventoryValues,
      warning = GetString(MM_RESET_LISTINGS_WARN),
    },
    -- replace inventory value type
    [21] = {
      type          = 'dropdown',
      name          = GetString(MM_REPLACE_INVENTORY_VALUE_TYPE_NAME),
      tooltip       = GetString(MM_REPLACE_INVENTORY_VALUE_TYPE_TIP),
      choices       = MasterMerchant.dealCalcChoices,
      choicesValues = MasterMerchant.dealCalcValues,
      getFunc       = function() return MasterMerchant.systemSavedVariables.replacementTypeToUse end,
      setFunc       = function(value) MasterMerchant.systemSavedVariables.replacementTypeToUse = value end,
      default       = MasterMerchant.systemDefault.replacementTypeToUse,
      disabled      = function() return not MasterMerchant.systemSavedVariables.replaceInventoryValues end,
      warning       = GetString(MM_RESET_LISTINGS_WARN),
    },
    [22] = {
      type    = "header",
      name    = GetString(GUILD_STORE_OPTIONS),
      width   = "full",
      helpUrl = "https://esouimods.github.io/3-master_merchant.html#GuildStoreOptions",
    },
    -- Should we show the stack price calculator in the Vanilla UI?
    [23] = {
      type    = 'checkbox',
      name    = GetString(SK_CALC_NAME),
      tooltip = GetString(SK_CALC_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.showCalc end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.showCalc = value end,
      default = MasterMerchant.systemDefault.showCalc,
    },
    -- Should we use one price for all or save by guild?
    [24] = {
      type    = 'checkbox',
      name    = GetString(SK_ALL_CALC_NAME),
      tooltip = GetString(SK_ALL_CALC_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.priceCalcAll end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.priceCalcAll = value end,
      default = MasterMerchant.systemDefault.priceCalcAll,
    },
    -- should we display a Min Profit Filter in AGS?
    [25] = {
      type    = 'checkbox',
      name    = GetString(MM_MIN_PROFIT_FILTER_NAME),
      tooltip = GetString(MM_MIN_PROFIT_FILTER_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.minProfitFilter end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.minProfitFilter = value end,
      default = MasterMerchant.systemDefault.minProfitFilter,
    },
    -- should we display profit instead of margin?
    [26] = {
      type    = 'checkbox',
      name    = GetString(MM_SAUCY_NAME),
      tooltip = GetString(MM_SAUCY_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.saucy end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.saucy = value end,
      default = MasterMerchant.systemDefault.saucy,
    },
    -- Deal Filter Price
    [27] = {
      type          = 'dropdown',
      name          = GetString(SK_DEAL_CALC_TYPE_NAME),
      tooltip       = GetString(SK_DEAL_CALC_TYPE_TIP),
      choices       = MasterMerchant.dealCalcChoices,
      choicesValues = MasterMerchant.dealCalcValues,
      getFunc       = function() return MasterMerchant.systemSavedVariables.dealCalcToUse end,
      setFunc       = function(value) MasterMerchant.systemSavedVariables.dealCalcToUse = value end,
      default       = MasterMerchant.systemDefault.dealCalcToUse,
    },
    [28] = {
      type    = "header",
      name    = GetString(GUILD_MASTER_OPTIONS),
      width   = "full",
      helpUrl = "https://esouimods.github.io/3-master_merchant.html#GuildMasterOptions",
    },
    -- should we add taxes to the export?
    [29] = {
      type    = 'checkbox',
      name    = GetString(MM_SHOW_AMOUNT_TAXES_NAME),
      tooltip = GetString(MM_SHOW_AMOUNT_TAXES_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.showAmountTaxes end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.showAmountTaxes = value end,
      default = MasterMerchant.systemDefault.showAmountTaxes,
    },
    [30] = {
      type    = "header",
      name    = GetString(MASTER_MERCHANT_DEBUG_OPTIONS),
      width   = "full",
      helpUrl = "https://esouimods.github.io/3-master_merchant.html#MMDebugOptions",
    },
    [31] = {
      type    = 'checkbox',
      name    = GetString(MM_DEBUG_LOGGER_NAME),
      tooltip = GetString(MM_DEBUG_LOGGER_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.useLibDebugLogger end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.useLibDebugLogger = value end,
      default = MasterMerchant.systemDefault.useLibDebugLogger,
    },
    [32] = {
      type    = 'checkbox',
      name    = GetString(MM_DISABLE_ATT_WARN_NAME),
      tooltip = GetString(MM_DISABLE_ATT_WARN_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.disableAttWarn end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.disableAttWarn = value end,
      default = MasterMerchant.systemDefault.disableAttWarn,
    },
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

function MasterMerchant:ExportLastWeek()
  local export = ZO_SavedVars:NewAccountWide('ShopkeeperSavedVars', 1, "EXPORT", {}, nil)

  local dataSet = internal.guildPurchases
  local dataSet = internal.guildSales

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
    local online = (status ~= PLAYER_STATUS_OFFLINE)
    local rankId = GetGuildRankId(guildID, rankIndex)

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
      table.insert(list,
        displayName .. "&" .. amountSold .. "&" .. amountBought .. "&" .. amountTaxes .. "&" .. rankIndex)
    else
      table.insert(list, displayName .. "&" .. amountSold .. "&" .. amountBought .. "&" .. rankIndex)
    end
  end

end

function MasterMerchant:ExportSalesData()
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

  local epochBack = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * 10)
  for k, v in pairs(sales_data) do
    for j, dataList in pairs(v) do
      if dataList['sales'] then
        for _, sale in pairs(dataList['sales']) do
          local currentItemLink = internal:GetItemLinkByIndex(sale['itemLink'])
          local currentGuild = internal:GetGuildNameByIndex(sale['guild'])
          local currentBuyer = internal:GetAccountNameByIndex(sale['buyer'])
          local currentSeller = internal:GetAccountNameByIndex(sale['seller'])
          if sale.timestamp >= epochBack and (guildName == 'ALL' or guildName == currentGuild) then
            local itemDesc = dataList['itemDesc']
            itemDesc = itemDesc:gsub("%^.*$", "", 1)
            itemDesc = string.gsub(" " .. itemDesc, "%s%l", string.upper):sub(2)

            table.insert(list,
              currentSeller .. "&" ..
                currentBuyer .. "&" ..
                currentItemLink .. "&" ..
                sale.quant .. "&" ..
                sale.timestamp .. "&" ..
                tostring(sale.wasKiosk) .. "&" ..
                sale.price .. "&" ..
                currentGuild .. "&" ..
                itemDesc .. "&" ..
                dataList['itemAdderText']
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
        local textTime = self.TextTimeSince(theEvent.timestamp, true)
        if i == 1 then
          MasterMerchant:dm("Info", MasterMerchant.concat(GetString(MM_APP_MESSAGE_NAME), GetString(SK_SALES_REPORT)))
        end
        MasterMerchant:dm("Info", zo_strformat('<<t:1>>', theEvent.itemLink) .. GetString(MM_APP_TEXT_TIMES) .. theEvent.quant .. ' -- ' .. stringPrice .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t -- ' .. theEvent.guild)
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
            local textTime = self.TextTimeSince(theEvent.timestamp, true)
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
            MasterMerchant:dm("Info", string.format(MasterMerchant.concat(GetString(MM_APP_MESSAGE_NAME), GetString(SK_SALES_ALERT)), zo_strformat('<<t:1>>', theEvent.itemLink), theEvent.quant, stringPrice, theEvent.guild, self.TextTimeSince(theEvent.timestamp, true)))
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
  if itemLink and itemLink ~= "" then
    local dealValue, margin, profit = MasterMerchant.GetDealInformation(itemLink, result.purchasePrice, result.stackCount)
    if dealValue then
      if dealValue > -1 then
        if MasterMerchant.systemSavedVariables.saucy then
          sellingAdvice:SetText(MasterMerchant.LocalizedNumber(profit) .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t')
        else
          sellingAdvice:SetText(string.format('%.2f', margin) .. '%')
        end
        -- TODO I think this colors the number in the guild store
        --[[
        ZO_Currency_FormatPlatform(CURT_MONEY, tonumber(stringPrice), ZO_CURRENCY_FORMAT_AMOUNT_ICON, {color: someColorDef})
        ]]--
        local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, dealValue)
        if dealValue == 0 then
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
  --MasterMerchant.a_test_var = TRADING_HOUSE
  --MasterMerchant.b_test_var = TRADING_HOUSE_GAMEPAD
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
    if dealValue > -1 then
      if MasterMerchant.systemSavedVariables.saucy then
        buyingAdvice:SetText(MasterMerchant.LocalizedNumber(profit) .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t')
      else
        buyingAdvice:SetText(string.format('%.2f', margin) .. '%')
      end
      -- TODO I think this colors the number in the guild store
      local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, dealValue)
      if dealValue == 0 then
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

  MasterMerchant.systemSavedVariables.rankIndexRoster = MasterMerchant.systemSavedVariables.rankIndexRoster or 1

  local timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_TODAY),
    function() self:UpdateRosterWindow(1) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == 1 then timeDropdown:SetSelectedItem(GetString(MM_INDEX_TODAY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_YESTERDAY), function() self:UpdateRosterWindow(2) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == 2 then timeDropdown:SetSelectedItem(GetString(MM_INDEX_YESTERDAY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_THISWEEK), function() self:UpdateRosterWindow(3) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == 3 then timeDropdown:SetSelectedItem(GetString(MM_INDEX_THISWEEK)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_LASTWEEK), function() self:UpdateRosterWindow(4) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == 4 then timeDropdown:SetSelectedItem(GetString(MM_INDEX_LASTWEEK)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_PRIORWEEK), function() self:UpdateRosterWindow(5) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == 5 then timeDropdown:SetSelectedItem(GetString(MM_INDEX_PRIORWEEK)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_7DAY), function() self:UpdateRosterWindow(8) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == 8 then timeDropdown:SetSelectedItem(GetString(MM_INDEX_7DAY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_10DAY), function() self:UpdateRosterWindow(6) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == 6 then timeDropdown:SetSelectedItem(GetString(MM_INDEX_10DAY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_30DAY), function() self:UpdateRosterWindow(7) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == 7 then timeDropdown:SetSelectedItem(GetString(MM_INDEX_30DAY)) end

  timeEntry = timeDropdown:CreateItemEntry(MasterMerchant.customTimeframeText,
    function() self:UpdateRosterWindow(9) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == 9 then timeDropdown:SetSelectedItem(MasterMerchant.customTimeframeText) end
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
    key      = 'MM_Sold',
    disabled = not MasterMerchant.systemSavedVariables.diplayGuildInfo or not MasterMerchant.systemSavedVariables.diplaySalesInfo,
    width    = 110,
    header   = {
      title = GetString(SK_SALES_COLUMN),
      align = TEXT_ALIGN_RIGHT
    },
    row      = {
      align  = TEXT_ALIGN_RIGHT,
      data   = function(guildId, data, index)

        local amountSold = 0

        if internal.guildSales and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName] and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName] and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales then

          amountSold = internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales[MasterMerchant.systemSavedVariables.rankIndexRoster or 1] or 0

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
    key      = 'MM_Bought',
    disabled = not MasterMerchant.systemSavedVariables.diplayGuildInfo or not MasterMerchant.systemSavedVariables.diplayPurchasesInfo,
    width    = 110,
    header   = {
      title = GetString(SK_PURCHASES_COLUMN),
      align = TEXT_ALIGN_RIGHT
    },
    row      = {
      align  = TEXT_ALIGN_RIGHT,
      data   = function(guildId, data, index)

        local amountBought = 0

        if internal.guildPurchases and
          internal.guildPurchases[GUILD_ROSTER_MANAGER.guildName] and
          internal.guildPurchases[GUILD_ROSTER_MANAGER.guildName].sellers and
          internal.guildPurchases[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName] and
          internal.guildPurchases[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales then

          amountBought = internal.guildPurchases[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales[MasterMerchant.systemSavedVariables.rankIndexRoster or 1] or 0

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
    key      = 'MM_PerChg',
    disabled = not MasterMerchant.systemSavedVariables.diplayGuildInfo or not MasterMerchant.systemSavedVariables.diplayTaxesInfo,
    width    = 90,
    header   = {
      title   = GetString(SK_PER_CHANGE_COLUMN),
      align   = TEXT_ALIGN_RIGHT,
      tooltip = GetString(SK_PER_CHANGE_TIP)
    },
    row      = {
      align  = TEXT_ALIGN_RIGHT,
      data   = function(guildId, data, index)

        local amountSold = 0

        if internal.guildSales and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName] and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName] and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales then

          amountSold = internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales[MasterMerchant.systemSavedVariables.rankIndexRoster or 1] or 0
        end

        return math.floor(amountSold * 0.035)

      end,
      format = function(value)
        return MasterMerchant.LocalizedNumber(value) .. " |t16:16:EsoUI/Art/currency/currency_gold.dds|t"
      end
    }
  })

  -- LibGuildRoster adding the Count Column
  MasterMerchant.guild_columns['count'] = LibGuildRoster:AddColumn({
    key      = 'MM_Count',
    disabled = not MasterMerchant.systemSavedVariables.diplayGuildInfo or not MasterMerchant.systemSavedVariables.diplayCountInfo,
    width    = 70,
    header   = {
      title = GetString(SK_COUNT_COLUMN),
      align = TEXT_ALIGN_RIGHT
    },
    row      = {
      align  = TEXT_ALIGN_RIGHT,
      data   = function(guildId, data, index)

        local saleCount = 0

        if internal.guildSales and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName] and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName] and
          internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales then

          saleCount = internal.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].count[MasterMerchant.systemSavedVariables.rankIndexRoster or 1] or 0

        end

        return saleCount

      end,
      format = function(value)
        return MasterMerchant.LocalizedNumber(value) .. " |t16:16:EsoUI/Art/currency/currency_gold.dds|t"
      end
    }
  })

  -- Guild Time dropdown choice box
  MasterMerchant.UI_GuildTime = CreateControlFromVirtual('MasterMerchantRosterTimeChooser', ZO_GuildRoster, 'MasterMerchantStatsGuildDropdown')

  -- Placing Guild Time dropdown at the bottom of the Count Column when it has been generated
  LibGuildRoster:OnRosterReady(function()
    MasterMerchant.UI_GuildTime:SetAnchor(TOP, MasterMerchant.guild_columns['count']:GetHeader(), BOTTOMRIGHT, -80, 570)
    MasterMerchant.UI_GuildTime:SetDimensions(180, 25)

    -- Don't render the dropdown this cycle if the settings have columns disabled
    if not MasterMerchant.systemSavedVariables.diplayGuildInfo then
      MasterMerchant.UI_GuildTime:SetHidden(true)
    end

  end)

  MasterMerchant.UI_GuildTime.m_comboBox:SetSortsItems(false)

  MasterMerchant:BuildRosterTimeDropdown()

end

function MasterMerchant.SetupPendingPost(self)
  --MasterMerchant:dm("Debug", "SetupPendingPost")
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

--[[ register event monitor
local function OnPlayerDeactivated(eventCode)
  EVENT_MANAGER:UnregisterForEvent(MasterMerchant.name.."_EventMon", EVENT_GUILD_HISTORY_RESPONSE_RECEIVED)
end
EVENT_MANAGER:RegisterForEvent(MasterMerchant.name.."_EventDisable", EVENT_PLAYER_DEACTIVATED, OnPlayerDeactivated)

local function OnPlayerActivated(eventCode)
  EVENT_MANAGER:RegisterForEvent(MasterMerchant.name.."_EventMon", EVENT_GUILD_HISTORY_RESPONSE_RECEIVED, function(...) MasterMerchant:ProcessGuildHistoryResponse(...) end)
end
EVENT_MANAGER:RegisterForEvent(MasterMerchant.name.."_EventEnable", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
]]--

local function CompleteMasterMerchantSetup()
  MasterMerchant:dm("Debug", "CompleteMasterMerchantSetup")

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
  old_defaults = {
    dataLocations = {}, -- unused as of 5-15-2021 but has to stay here
    pricingData   = {}, -- added 12-31 but has always been there
    historyDepth  = 30,
    minItemCount  = 20,
    maxItemCount  = 5000,
    blacklist     = '',
  }

  local systemDefault = {
    -- old settings
    dataLocations                   = {}, -- unused as of 5-15-2021 but has to stay here
    pricingData                     = {}, -- added 12-31 but has always been there
    showChatAlerts                  = false,
    showMultiple                    = true,
    openWithMail                    = true,
    openWithStore                   = true,
    showFullPrice                   = true,
    salesWinLeft                    = 10, -- winLeft
    salesWinTop                     = 85, -- winTop
    guildWinLeft                    = 10,
    guildWinTop                     = 85,
    listingWinLeft                  = 10,
    listingWinTop                   = 85,
    purchaseWinLeft                 = 10,
    purchaseWinTop                  = 85,
    reportsWinLeft                  = 10,
    reportsWinTop                   = 85,
    statsWinLeft                    = 720,
    statsWinTop                     = 820,
    feedbackWinLeft                 = 720,
    feedbackWinTop                  = 420,
    windowFont                      = "ProseAntique",
    showAnnounceAlerts              = true,
    showCyroAlerts                  = true,
    alertSoundName                  = "Book_Acquired",
    showUnitPrice                   = false,
    viewSize                        = ITEMS,
    offlineSales                    = true,
    showPricing                     = true,
    showBonanzaPricing              = true,
    showAltTtcTipline               = true,
    showCraftCost                   = true,
    showGraph                       = true,
    showCalc                        = true,
    priceCalcAll                    = true,
    minProfitFilter                 = true,
    rankIndex                       = 1,
    rankIndexRoster                 = 1,
    viewBuyerSeller                 = 'buyer',
    viewGuildBuyerSeller            = 'seller',
    trimOutliers                    = false,
    trimDecimals                    = false,
    replaceInventoryValues          = false,
    replacementTypeToUse            = MasterMerchant.USE_MM_AVERAGE,
    displaySalesDetails             = false,
    displayItemAnalysisButtons      = false,
    noSalesInfoDeal                 = 2,
    focus1                          = 10,
    focus2                          = 3,
    focus3                          = 30,
    blacklist                       = '',
    defaultDays                     = GetString(MM_RANGE_ALL),
    shiftDays                       = GetString(MM_RANGE_FOCUS1),
    ctrlDays                        = GetString(MM_RANGE_FOCUS2),
    ctrlShiftDays                   = GetString(MM_RANGE_FOCUS3),
    saucy                           = false,
    displayListingMessage           = false,
    -- settingsToUse
    customTimeframe                 = 90,
    customTimeframeType             = GetString(MM_CUSTOM_TIMEFRAME_DAYS),
    diplayGuildInfo                 = false,
    diplayPurchasesInfo             = true,
    diplaySalesInfo                 = true,
    diplayTaxesInfo                 = true,
    diplayCountInfo                 = true,
    showAmountTaxes                 = false,
    useLibDebugLogger               = false, -- added 11-28
    --[[TODO settings moved to LGS or removed
    ]]--
    -- conversion vars
    verThreeItemIDConvertedToString = false, -- this only converts id64 at this time
    shouldReindex                   = false,
    shouldAdderText                 = false,
    showGuildInitSummary            = false,
    showIndexingSummary             = false,
    lastReceivedEventID             = {}, -- unused, see LGS
    --[[you can assign this as the default but it needs to be a global var
    customTimeframeText = tostring(90) .. ' ' .. GetString(MM_CUSTOM_TIMEFRAME_DAYS),
    ]]--
    minimalIndexing                 = false,
    useSalesHistory                 = false,
    historyDepth                    = 30,
    minItemCount                    = 20,
    maxItemCount                    = 5000,
    disableAttWarn                  = false,
    dealCalcToUse                   = MasterMerchant.USE_MM_AVERAGE,
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
  MasterMerchant.show_log = self.systemSavedVariables.useLibDebugLogger

  local sv = ShopkeeperSavedVars["Default"]["MasterMerchant"]["$AccountWide"]
  -- Clean up saved variables (from previous versions)
  for key, val in pairs(sv) do
    -- Delete key-value pair if the key can't also be found in the default settings (except for version)
    if key ~= "version" and systemDefault[key] == nil then
      sv[key] = nil
    end
  end

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

  self.currentGuildID = GetGuildId(1) or 0

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

  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_TRADING_HOUSE_PENDING_ITEM_UPDATE,
    function(eventCode, slotId, isPending)
      if MasterMerchant.systemSavedVariables.showCalc and isPending and GetSlotStackSize(1, slotId) > 1 then
        local theLink = GetItemLink(1, slotId, LINK_STYLE_DEFAULT)
        local theIID = GetItemLinkItemId(theLink)
        local theIData = internal.GetOrCreateIndexFromLink(theLink)
        local postedStats = self:GetTooltipStats(theIID, theIData, true, true)
        MasterMerchantPriceCalculatorStack:SetText(GetString(MM_APP_TEXT_TIMES) .. GetSlotStackSize(1, slotId))
        local floorPrice = 0
        if postedStats.avgPrice then floorPrice = string.format('%.2f', postedStats['avgPrice']) end
        MasterMerchantPriceCalculatorUnitCostAmount:SetText(floorPrice)
        MasterMerchantPriceCalculatorTotal:SetText(GetString(MM_TOTAL_TITLE) .. self.LocalizedNumber(math.floor(floorPrice * GetSlotStackSize(1,
          slotId))) .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t')
        MasterMerchantPriceCalculator:SetHidden(false)
      else MasterMerchantPriceCalculator:SetHidden(true) end
    end)

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
        guild     = guildName,
        guildId   = guildId,
        itemLink  = itemLink,
        quant     = stackCount,
        timestamp = GetTimeStamp(),
        price     = salePrice,
        seller    = sellerName,
        id        = itemUniqueId,
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

  ZO_PreHookHandler(ZO_ProvisionerTopLevelTooltip, 'OnUpdate', function() self:addStatsPopupTooltip(ZO_ProvisionerTopLevelTooltip) end)
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
      TRADING_HOUSE.SetupPendingPost = MasterMerchant.SetupPendingPost
      ZO_PreHook(TRADING_HOUSE, 'PostPendingItem', MasterMerchant.PostPendingItem)
    end
  end

  -- Set up GM Tools, if also installed
  self:initGMTools()

  -- Set up purchase tracking, if also installed
  self:initPurchaseTracking()

  --Watch inventory listings
  for _, i in pairs(PLAYER_INVENTORY.inventories) do
    local listView = i.listView
    if listView and listView.dataTypes and listView.dataTypes[1] then
      local originalCall = listView.dataTypes[1].setupCallback

      listView.dataTypes[1].setupCallback = function(control, slot)
        originalCall(control, slot)
        self:SwitchUnitPrice(control, slot)
      end
    end
  end

  -- Watch Decon list
  local originalCall = ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack.dataTypes[1].setupCallback
  ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack.dataTypes[1].setupCallback = function(control, slot)
    originalCall(control, slot)
    self:SwitchUnitPrice(control, slot)
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
  InitItemHistory Removed
  InitItemHistory iterateOverSalesData Removed
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
    end, 'ArkadiusDataActive')
    LEQ:Start()
  end, 10)
end

function MasterMerchant:SwitchUnitPrice(control, slot)
  local averagePrice = 0
  if MasterMerchant.systemSavedVariables.replaceInventoryValues then
    local bagId = control.dataEntry.data.bagId
    local slotIndex = control.dataEntry.data.slotIndex
    local itemLink = bagId and GetItemLink(bagId, slotIndex) or GetItemLink(slotIndex)

    if itemLink then
      local theIID = GetItemLinkItemId(itemLink)
      local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)

      if MasterMerchant.systemSavedVariables.replacementTypeToUse == MasterMerchant.USE_MM_AVERAGE then
        local tipStats = MasterMerchant:GetTooltipStats(theIID, itemIndex, true, true)
        if tipStats.avgPrice then
          averagePrice = tipStats.avgPrice
        end
      end
      if MasterMerchant.systemSavedVariables.replacementTypeToUse == MasterMerchant.USE_BONANZA then
        local tipStats = MasterMerchant:GetTooltipStats(theIID, itemIndex, false, true)
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
        end
      end

      if averagePrice and averagePrice > 0 then
        if not control.dataEntry.data.mmOriginalPrice then
          control.dataEntry.data.mmOriginalPrice = control.dataEntry.data.sellPrice
          control.dataEntry.data.mmOriginalStackPrice = control.dataEntry.data.stackSellPrice
        end

        control.dataEntry.data.mmPrice = tonumber(string.format('%.0f', averagePrice))
        control.dataEntry.data.stackSellPrice = tonumber(string.format('%.0f', averagePrice * control.dataEntry.data.stackCount))
        control.dataEntry.data.sellPrice = control.dataEntry.data.mmPrice

        local sellPriceControl = control:GetNamedChild("SellPrice")
        if (sellPriceControl) then
          sellPrice = MasterMerchant.LocalizedNumber(control.dataEntry.data.stackSellPrice)
          sellPrice = '|cEEEE33' .. sellPrice .. '|r |t16:16:EsoUI/Art/currency/currency_gold.dds|t'
          sellPriceControl:SetText(sellPrice)
        end
      else
        if control.dataEntry.data.mmOriginalPrice then
          control.dataEntry.data.sellPrice = control.dataEntry.data.mmOriginalPrice
          control.dataEntry.data.stackSellPrice = control.dataEntry.data.mmOriginalStackPrice
        end
        local sellPriceControl = control:GetNamedChild("SellPrice")
        if (sellPriceControl) then
          sellPrice = MasterMerchant.LocalizedNumber(control.dataEntry.data.stackSellPrice)
          sellPrice = sellPrice .. '|t16:16:EsoUI/Art/currency/currency_gold.dds|t'
          sellPriceControl:SetText(sellPrice)
        end
      end
    end
  end
end

function MasterMerchant:InitScrollLists()
  MasterMerchant:dm("Debug", "InitScrollLists")

  self:SetupScrollLists()

  -- sets isFirstScan to true if offlineSales enabled so that alerts are displayed
  MasterMerchant.isFirstScan = MasterMerchant.systemSavedVariables.offlineSales

  local numGuilds = GetNumGuilds()
  if numGuilds > 0 then
    MasterMerchant.currentGuildID = GetGuildId(1) or 0
    --MasterMerchant:UpdateControlData()
    --MasterMerchant:dm("Debug", "MasterMerchant.currentGuildID: " .. MasterMerchant.currentGuildID)
  else
    -- used for event index on guild history tab
    MasterMerchant.currentGuildID = 0
  end
  for i = 1, numGuilds do
    local guildID = GetGuildId(i)
    local guildName = GetGuildName(guildID)
    for m = 1, GetNumGuildMembers(guildID) do
      local guildMemInfo, _, _, _, _ = GetGuildMemberInfo(guildID, m)
      if MasterMerchant.guildMemberInfo[guildID] == nil then MasterMerchant.guildMemberInfo[guildID] = {} end
      MasterMerchant.guildMemberInfo[guildID][string.lower(guildMemInfo)] = true
    end
  end


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
--/script d({TamrielTradeCentrePrice:GetPriceInfo("|H0:item:100393:27:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h")})
--/script d({MasterMerchant:GetTamrielTradeCentrePrice("|H0:item:100393:27:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h")})
--[[
  MasterMerchant.USE_TTC_SUGGESTED,
  MasterMerchant.USE_TTC_AVERAGE,
  MasterMerchant.USE_MM_AVERAGE,
  MasterMerchant.USE_BONANZA,
]]--
function MasterMerchant:GetTamrielTradeCentrePrice(itemLink)
  local priceStats = TamrielTradeCentrePrice:GetPriceInfo(itemLink)
  if priceStats then priceStats.Avg = priceStats.Avg or 0 end
  if priceStats then priceStats.SuggestedPrice = priceStats.SuggestedPrice or 0 end
  if priceStats then priceStats.EntryCount = priceStats.EntryCount or 1 end
  return priceStats
end

MasterMerchant.GetDealInformation = function(itemLink, purchasePrice, stackCount)

  local key = string.format("%s_%d_%d", itemLink, purchasePrice, stackCount)
  if (not dealInfoCache[key]) then
    local setPrice = nil
    local salesCount = 0
    local theIID = GetItemLinkItemId(itemLink)
    local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
    if MasterMerchant.systemSavedVariables.dealCalcToUse == MasterMerchant.USE_MM_AVERAGE then
      local tipStats = MasterMerchant:GetTooltipStats(theIID, itemIndex, true, true)
      if tipStats.avgPrice then
        setPrice = tipStats['avgPrice']
        salesCount = tipStats['numSales']
      end
    end
    if MasterMerchant.systemSavedVariables.dealCalcToUse == MasterMerchant.USE_BONANZA then
      local tipStats = MasterMerchant:GetTooltipStats(theIID, itemIndex, false, true)
      if tipStats.bonanzaPrice then
        setPrice = tipStats.bonanzaPrice
        salesCount = tipStats.bonanzaSales
      end
    end
    if MasterMerchant.systemSavedVariables.dealCalcToUse == MasterMerchant.USE_TTC_AVERAGE and TamrielTradeCentre then
      local priceStats = MasterMerchant:GetTamrielTradeCentrePrice(itemLink)
      if priceStats and priceStats.Avg > 0 then
        setPrice = priceStats.Avg
        salesCount = priceStats.EntryCount
      end
    end
    if MasterMerchant.systemSavedVariables.dealCalcToUse == MasterMerchant.USE_TTC_SUGGESTED and TamrielTradeCentre then
      local priceStats = MasterMerchant:GetTamrielTradeCentrePrice(itemLink)
      if priceStats and priceStats.SuggestedPrice > 0 then
        setPrice = priceStats.SuggestedPrice
        salesCount = priceStats.EntryCount
      end
    end
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
  end
end

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
      MasterMerchant:ExportLastWeek()
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
      MasterMerchant:dm("Info", GetString(MM_SALES_EXPORT_START))
      MasterMerchant:ExportSalesData()
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
    MasterMerchant.systemSavedVariables.saucy = not MasterMerchant.systemSavedVariables.saucy
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

-- Register for the OnAddOnLoaded event
EVENT_MANAGER:RegisterForEvent(MasterMerchant.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
