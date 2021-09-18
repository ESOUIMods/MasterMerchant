-- MasterMerchant Utility Functions File
-- Last Updated September 15, 2014
-- Written February 2015 by Chris Lasswell (@Philgo68) - Philgo68@gmail.com
-- Released under terms in license accompanying this file.
-- Distribution without license is prohibited!
local internal = _G["LibGuildStore_Internal"]
specialDWCount = 0

local mfloor = math.floor
local taxFactor = GetTradingHouseCutPercentage() / 200

MMSeller = {
  guild        = {},
  sellerName   = '',
  sales        = {},
  tax          = {},
  count        = {},
  stack        = {},
  rank         = {},
  outsideBuyer = false,
  searchText   = nil
}

function MMSeller:new(_guild, _name, _outsideBuyer, _searchText)
  o = {}   -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self

  o.guild = _guild
  o.sellerName = _name
  o.sales = {}
  o.tax = {}
  o.count = {}
  o.stack = {}
  o.rank = {}
  o.outsideBuyer = _outsideBuyer
  o.searchText = zo_strlower(_searchText or '')
  return o
end

function MMSeller:addSale(rankIndex, amount, stack, sort, tax)
  if sort == nil then sort = true end

  if not self.sales[rankIndex] then
    self.sales[rankIndex] = 0
    self.tax[rankIndex] = 0
    self.count[rankIndex] = 0
    self.stack[rankIndex] = 0
  end

  self.sales[rankIndex] = self.sales[rankIndex] + amount
  self.tax[rankIndex] = self.tax[rankIndex] + (tax or mfloor(amount * taxFactor))  -- Guild gets half the Cut with decimals cut off.
  self.count[rankIndex] = self.count[rankIndex] + 1
  self.stack[rankIndex] = self.stack[rankIndex] + stack

  local guildRanks = self.guild.ranks[rankIndex]

  if (not self.rank[rankIndex]) then
    -- add myself to the guild ranking list, then note my current place
    table.insert(guildRanks, self)
    self.rank[rankIndex] = #guildRanks
  end

  if sort then
    self:sort(rankIndex, guildRanks)
  end
end

function MMSeller:sort(rankIndex, guildRanks)
  while ((self.rank[rankIndex] or 0) > 1) and (guildRanks[self.rank[rankIndex] - 1]) and ((self.sales[rankIndex] or 0) > (guildRanks[self.rank[rankIndex] - 1].sales[rankIndex] or 0)) do

    local swapSeller = guildRanks[self.rank[rankIndex] - 1]

    local tempRank = swapSeller.rank[rankIndex]
    swapSeller.rank[rankIndex] = self.rank[rankIndex]
    self.rank[rankIndex] = tempRank

    -- Make sure guild lists point to the right sellers
    guildRanks[self.rank[rankIndex]] = self
    guildRanks[swapSeller.rank[rankIndex]] = swapSeller
  end
end

function MMSeller:removeSale(rankIndex, amount, stack)
  self.sales[rankIndex] = (self.sales[rankIndex] or 0) - amount
  self.tax[rankIndex] = (self.tax[rankIndex] or 0) - mfloor(amount * taxFactor)  -- Guild gets half the Cut with decimals cut off.
  self.count[rankIndex] = (self.count[rankIndex] or 0) - 1
  self.stack[rankIndex] = (self.stack[rankIndex] or 0) - stack
end

function MMSeller:removeRankIndex(rankIndex)
  if (self.sales[rankIndex]) then self.sales[rankIndex] = nil end
  if (self.tax[rankIndex]) then self.tax[rankIndex] = nil end
  if (self.count[rankIndex]) then self.count[rankIndex] = nil end
  if (self.rank[rankIndex]) then self.rank[rankIndex] = nil end
end

MMGuild = {
  guildName    = '',
  sellers      = {},
  ranks        = {},
  sales        = {},
  tax          = {},
  count        = {},
  stack        = {},
  initDateTime = GetTimeStamp()
}

function MMGuild:new(_name)
  local function guild_system_offline()
    local weekCutoff = 1595962800 -- Tuesday, 28-Jul-20 19:00:00 UTC

    if GetWorldName() == 'EU Megaserver' then
      weekCutoff = 1595941200  -- Tuesday, 28-Jul-20 13:00:00 UTC
    end

    while weekCutoff + (7 * ZO_ONE_DAY_IN_SECONDS) < GetTimeStamp() do
      weekCutoff = weekCutoff + (7 * ZO_ONE_DAY_IN_SECONDS)
    end
    return weekCutoff
  end

  o = {}   -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self

  o.guildName = _name
  o.sellers = {}
  o.ranks = {}
  o.count = {}
  o.stack = {}
  o.sales = {}
  o.tax = {}
  o.kiosk_cycle = 0
  o.week_start = 0

  -- /script MasterMerchant:dm("Info", { GetGuildKioskCycleTimes() } )
  -- Calc Guild Week Cutoff
  local _, weekCutoff = GetGuildKioskCycleTimes()
  if weekCutoff == 0 then
    -- guild system is down, do something about it
    weekCutoff = guild_system_offline() -- do not subtract time because of while loop
    o.week_start = weekCutoff -- this is 7 day back already
    o.kiosk_cycle = weekCutoff + (7 * ZO_ONE_DAY_IN_SECONDS) -- add 7 days for when week would end
  end

  -- Calc Day Cutoff in Local Time
  local dayCutoff = GetTimeStamp() - GetSecondsSinceMidnight()

  o.oneStart = dayCutoff -- Today

  o.twoStart = o.oneStart - ZO_ONE_DAY_IN_SECONDS -- yesterday

  -- This Week
  o.threeStart = weekCutoff - 7 * ZO_ONE_DAY_IN_SECONDS -- GetGuildKioskCycleTimes() minus 7 days
  o.threeEnd = weekCutoff -- GetGuildKioskCycleTimes()

  -- Last Week
  o.fourStart = o.threeStart - 7 * ZO_ONE_DAY_IN_SECONDS -- last week Tuesday flip
  o.fourEnd = o.threeStart -- last week end

  -- Previous Week
  o.fiveStart = o.fourStart - 7 * ZO_ONE_DAY_IN_SECONDS
  o.fiveEnd = o.fourStart -- prior week end

  o.sixStart = dayCutoff - 10 * ZO_ONE_DAY_IN_SECONDS -- last 10 days
  o.sevenStart = dayCutoff - 30 * ZO_ONE_DAY_IN_SECONDS -- last 30 days
  o.eightStart = dayCutoff - 7 * ZO_ONE_DAY_IN_SECONDS -- last 7 days

  if MasterMerchant.systemSavedVariables.customTimeframeType == GetString(MM_CUSTOM_TIMEFRAME_HOURS) then
    o.nineStart = GetTimeStamp() - MasterMerchant.systemSavedVariables.customTimeframe * ZO_ONE_HOUR_IN_SECONDS -- last x hours
    o.nineEnd = GetTimeStamp() + 7 * ZO_ONE_DAY_IN_SECONDS
  end
  if MasterMerchant.systemSavedVariables.customTimeframeType == GetString(MM_CUSTOM_TIMEFRAME_DAYS) then
    o.nineStart = GetTimeStamp() - MasterMerchant.systemSavedVariables.customTimeframe * ZO_ONE_DAY_IN_SECONDS -- last x days
    o.nineEnd = GetTimeStamp() + 7 * ZO_ONE_DAY_IN_SECONDS
  end
  if MasterMerchant.systemSavedVariables.customTimeframeType == GetString(MM_CUSTOM_TIMEFRAME_WEEKS) then
    o.nineStart = GetTimeStamp() - MasterMerchant.systemSavedVariables.customTimeframe * ZO_ONE_DAY_IN_SECONDS * 7 -- last x weeks
    o.nineEnd = GetTimeStamp() + 7 * ZO_ONE_DAY_IN_SECONDS
  end
  if MasterMerchant.systemSavedVariables.customTimeframeType == GetString(MM_CUSTOM_TIMEFRAME_GUILD_WEEKS) then
    o.nineStart = weekCutoff - MasterMerchant.systemSavedVariables.customTimeframe * ZO_ONE_DAY_IN_SECONDS * 7 -- last x full guild weeks
    o.nineEnd = weekCutoff
  end
  if o.nineStart == nil then
    -- Default custom timeframe to Last 3 days if it's undefined
    MasterMerchant.systemSavedVariables.customTimeframeType = GetString(MM_CUSTOM_TIMEFRAME_DAYS)
    MasterMerchant.systemSavedVariables.customTimeframe = 3
    o.nineStart = GetTimeStamp() - MasterMerchant.systemSavedVariables.customTimeframe * ZO_ONE_DAY_IN_SECONDS -- last x days
    o.nineEnd = GetTimeStamp() + 7 * ZO_ONE_DAY_IN_SECONDS
  end

  return o
end

function MMGuild:addSale(sellerName, rankIndex, amount, stack, wasKiosk, sort, searchText)
  amount = tonumber(amount)
  if type(stack) ~= 'number' then stack = 1 end

  if not self.ranks[rankIndex] then
    self.ranks[rankIndex] = {}
    self.sales[rankIndex] = 0
    self.tax[rankIndex] = 0
    self.count[rankIndex] = 0
    self.stack[rankIndex] = 0
  end

  self.sales[rankIndex] = self.sales[rankIndex] + amount
  local tax = mfloor(amount * taxFactor)
  self.tax[rankIndex] = self.tax[rankIndex] + tax  -- Guild gets half the Cut with decimals cut off.
  self.count[rankIndex] = self.count[rankIndex] + 1
  self.stack[rankIndex] = self.stack[rankIndex] + stack

  self.sellers[sellerName] = self.sellers[sellerName] or MMSeller:new(self, sellerName, wasKiosk, searchText)
  self.sellers[sellerName]:addSale(rankIndex, amount, stack, sort, tax)
end

function MMGuild:removeSale(sellerName, rankIndex, amount, stack)
  if (self.sellers[sellersName]) then self.sellers[sellersName]:removeSale(rankIndex, amount, stack) end

  self.sales[rankIndex] = (self.sales[rankIndex] or 0) - amount
  self.tax[rankIndex] = (self.tax[rankIndex] or 0) - mfloor(amount * taxFactor)  -- Guild gets half the Cut with decimals cut off.
  self.count[rankIndex] = (self.count[rankIndex] or 0) - 1
  self.stack[rankIndex] = (self.stack[rankIndex] or 0) - stack
end

function MMGuild:removeRankIndex(rankIndex)
  --if (self.sellers[sellersName]) then self.sellers[sellersName]:removeRankIndex(rankIndex) end

  if (self.sales[rankIndex]) then self.sales[rankIndex] = nil end
  if (self.tax[rankIndex]) then self.tax[rankIndex] = nil end
  if (self.count[rankIndex]) then self.count[rankIndex] = nil end
  if (self.rank[rankIndex]) then self.rank[rankIndex] = nil end
end

function MMGuild:addSaleByDate(sellerName, timestamp, amount, stack, wasKiosk, sort, searchText)
  if sellerName == nil then return end
  if timestamp == nil then return end
  if type(timestamp) ~= 'number' then return end
  if (timestamp >= self.oneStart) then self:addSale(sellerName, 1, amount, stack, wasKiosk, sort, searchText) end ;
  if (timestamp >= self.twoStart and timestamp < self.oneStart) then self:addSale(sellerName, 2, amount, stack, wasKiosk, sort,
    searchText) end ;
  if (timestamp >= self.threeStart and timestamp < self.threeEnd) then self:addSale(sellerName, 3, amount, stack, wasKiosk, sort,
    searchText) end ;
  if (timestamp >= self.fourStart and timestamp < self.fourEnd) then self:addSale(sellerName, 4, amount, stack, wasKiosk, sort,
    searchText) end ;
  if (timestamp >= self.fiveStart and timestamp < self.fiveEnd) then self:addSale(sellerName, 5, amount, stack, wasKiosk, sort,
    searchText) end ;
  if (timestamp >= self.sixStart) then self:addSale(sellerName, 6, amount, stack, wasKiosk, sort, searchText) end ;
  if (timestamp >= self.sevenStart) then self:addSale(sellerName, 7, amount, stack, wasKiosk, sort, searchText) end ;
  if (timestamp >= self.eightStart) then self:addSale(sellerName, 8, amount, stack, wasKiosk, sort, searchText) end ;
  if (timestamp >= self.nineStart and timestamp < self.nineEnd) then self:addSale(sellerName, 9, amount, stack, wasKiosk, sort,
    searchText) end ;
end

function MMGuild:removeSaleByDate(sellerName, timestamp, amount, stack)
  if sellerName == nil then return end
  if (timestamp >= self.oneStart) then self:removeSale(sellerName, 1, amount) end ;
  if (timestamp >= self.twoStart and timestamp < self.oneStart) then self:removeSale(sellerName, 2, amount, stack) end ;
  if (timestamp >= self.threeStart and timestamp < self.threeEnd) then self:removeSale(sellerName, 3, amount, stack) end ;
  if (timestamp >= self.fourStart and timestamp < self.fourEnd) then self:removeSale(sellerName, 4, amount, stack) end ;
  if (timestamp >= self.fiveStart and timestamp < self.fiveEnd) then self:removeSale(sellerName, 5, amount, stack) end ;
  if (timestamp >= self.sixStart) then self:removeSale(sellerName, 6, amount, stack) end ;
  if (timestamp >= self.sevenStart) then self:removeSale(sellerName, 7, amount, stack) end ;
  if (timestamp >= self.eightStart) then self:removeSale(sellerName, 8, amount, stack) end ;
  if (timestamp >= self.nineStart and timestamp < self.nineEnd) then self:removeSale(sellerName, 9, amount, stack) end ;
end

function MMGuild:sortRankIndex(rankIndex)
  MasterMerchant.shellSort(self.ranks[rankIndex] or {}, function(sortA, sortB)
    return (sortA.sales[rankIndex] or 0) > (sortB.sales[rankIndex] or 0)
  end)

  local i = 1
  while self.ranks[rankIndex] and self.ranks[rankIndex][i] do
    self.ranks[rankIndex][i].rank[rankIndex] = i
    i = i + 1
  end
end

function MMGuild:sort()
  self:sortRankIndex(1)
  self:sortRankIndex(2)
  self:sortRankIndex(3)
  self:sortRankIndex(4)
  self:sortRankIndex(5)
  self:sortRankIndex(6)
  self:sortRankIndex(7)
  self:sortRankIndex(8)
  self:sortRankIndex(9)
end

function MMGuild:addPurchaseByDate(sellerName, timestamp, amount, stack, wasKiosk, sort, searchText)
  if sellerName == nil then return end
  if timestamp == nil then return end
  if type(timestamp) ~= 'number' then return end
  self:addSale(sellerName, 1, amount, stack, wasKiosk, sort, searchText)
end
