-- MasterMerchant Utility Functions File
-- Last Updated September 15, 2014
-- Written February 2015 by Chris Lasswell (@Philgo68) - Philgo68@gmail.com
-- Released under terms in license accompanying this file.
-- Distribution without license is prohibited!
specialDWCount = 0

local mfloor = math.floor
local taxFactor = GetTradingHouseCutPercentage() / 200

 MMSeller = {
    guild = {},
    sellerName = '',
    sales = {},
    tax = {},
    count = {},
    stack = {},
    rank = {},
    outsideBuyer = false,
    searchText = nil
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
      o.searchText = string.lower(_searchText or '')
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
      guildRanks[self.rank[rankIndex] ] = self
      guildRanks[swapSeller.rank[rankIndex] ] = swapSeller
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
      guildName = '',
      sellers = {},
      ranks = {},
      sales = {},
      tax = {},
      count = {},
      stack = {},
      initDateTime = GetTimeStamp()
}

  function MMGuild:new(_name)
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

      -- Calc Guild Week Cutoff
      local weekCutoff = 1595811600 -- 21:00 Sunday ET / 01:00 UTC Monday
      if GetTimeStamp() > 1596416400 then
        weekCutoff = weekCutoff + (42 * 3600)  -- + 42 hours = 15:00 Tuesday ET / 19:00 Tuesday UTC
      end

      if GetWorldName() == 'EU Megaserver' then
        if GetTimeStamp() > 1596416400 then
          weekCutoff = weekCutoff - (6 * 3600) -- move to 19:00 UTC Sunday
        else
          weekCutoff = weekCutoff - (5 * 3600) -- move to 14:00 UTC Tuesday
        end
      end

	    while weekCutoff + (7 * 86400) < GetTimeStamp() do
        weekCutoff = weekCutoff + (7 * 86400)
      end

      -- Calc Day Cutoff in Local Time
      local dayCutoff = GetTimeStamp() - GetSecondsSinceMidnight()

      o.oneStart = dayCutoff -- Today

      o.twoStart = o.oneStart - 86400 -- yesterday

      o.threeStart = weekCutoff -- back up to Monday for this week

      o.fourStart = o.threeStart - 7 * 86400 -- last week start
      o.fourEnd = o.threeStart -- last week end

      o.fiveStart = o.fourStart - 7 * 86400 -- prior week start
      o.fiveEnd = o.fourStart -- prior week end

      o.sixStart = GetTimeStamp() - 10 * 86400 -- last 10 days
      o.sevenStart = GetTimeStamp() - 30 * 86400 -- last 30 days
      o.eightStart = GetTimeStamp() - 7 * 86400 -- last 7 days

      if MasterMerchant:ActiveSettings().customTimeframeType == GetString(MM_CUSTOM_TIMEFRAME_HOURS) then
        o.nineStart = GetTimeStamp() - MasterMerchant:ActiveSettings().customTimeframe * 3600 -- last x hours
        o.nineEnd = GetTimeStamp() + 7 * 86400
      end
      if MasterMerchant:ActiveSettings().customTimeframeType == GetString(MM_CUSTOM_TIMEFRAME_DAYS) then
        o.nineStart = GetTimeStamp() - MasterMerchant:ActiveSettings().customTimeframe * 86400 -- last x days
        o.nineEnd = GetTimeStamp() + 7 * 86400
      end
      if MasterMerchant:ActiveSettings().customTimeframeType == GetString(MM_CUSTOM_TIMEFRAME_WEEKS) then
        o.nineStart = GetTimeStamp() - MasterMerchant:ActiveSettings().customTimeframe * 86400 * 7 -- last x weeks
        o.nineEnd = GetTimeStamp() + 7 * 86400
      end
      if MasterMerchant:ActiveSettings().customTimeframeType == GetString(MM_CUSTOM_TIMEFRAME_GUILD_WEEKS) then
        o.nineStart = weekCutoff - MasterMerchant:ActiveSettings().customTimeframe * 86400 * 7 -- last x full guild weeks
        o.nineEnd = weekCutoff
      end
      if o.nineStart == nil then
        -- Default custom timeframe to Last 3 days if it's undefined
        MasterMerchant:ActiveSettings().customTimeframeType = GetString(MM_CUSTOM_TIMEFRAME_DAYS)
        MasterMerchant:ActiveSettings().customTimeframe = 3
        o.nineStart = GetTimeStamp() - MasterMerchant:ActiveSettings().customTimeframe * 86400 -- last x days
        o.nineEnd = GetTimeStamp() + 7 * 86400
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

  function MMGuild:addSaleByDate(sellerName, date, amount, stack, wasKiosk, sort, searchText)
    if sellerName == nil then return end
    if date == nil then return end
    if type(date) ~= 'number' then return end
    if (date >= self.oneStart) then self:addSale(sellerName, 1, amount, stack, wasKiosk, sort, searchText) end;
    if (date >= self.twoStart and date < self.oneStart) then self:addSale(sellerName, 2, amount, stack, wasKiosk, sort, searchText) end;
    if (date >= self.threeStart) then self:addSale(sellerName, 3, amount, stack, wasKiosk, sort, searchText) end;
    if (date >= self.fourStart and date < self.fourEnd) then self:addSale(sellerName, 4, amount, stack, wasKiosk, sort, searchText) end;
    if (date >= self.fiveStart and date < self.fiveEnd) then self:addSale(sellerName, 5, amount, stack, wasKiosk, sort, searchText) end;
    if (date >= self.sixStart) then self:addSale(sellerName, 6, amount, stack, wasKiosk, sort, searchText) end;
    if (date >= self.sevenStart) then self:addSale(sellerName, 7, amount, stack, wasKiosk, sort, searchText) end;
    if (date >= self.eightStart) then self:addSale(sellerName, 8, amount, stack, wasKiosk, sort, searchText) end;
    if (date >= self.nineStart and date < self.nineEnd) then self:addSale(sellerName, 9, amount, stack, wasKiosk, sort, searchText) end;
  end

  function MMGuild:removeSaleByDate(sellerName, date, amount, stack)
    if sellerName == nil then return end
    if (date >= self.oneStart) then self:removeSale(sellerName, 1, amount) end;
    if (date >= self.twoStart and date < self.oneStart) then self:removeSale(sellerName, 2, amount, stack) end;
    if (date >= self.threeStart) then self:removeSale(sellerName, 3, amount, stack) end;
    if (date >= self.fourStart and date < self.fourEnd) then self:removeSale(sellerName, 4, amount, stack) end;
    if (date >= self.fiveStart and date < self.fiveEnd) then self:removeSale(sellerName, 5, amount, stack) end;
    if (date >= self.sixStart) then self:removeSale(sellerName, 6, amount, stack) end;
    if (date >= self.sevenStart) then self:removeSale(sellerName, 7, amount, stack) end;
    if (date >= self.eightStart) then self:removeSale(sellerName, 8, amount, stack) end;
    if (date >= self.nineStart and date < self.nineEnd) then self:removeSale(sellerName, 9, amount, stack) end;
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


