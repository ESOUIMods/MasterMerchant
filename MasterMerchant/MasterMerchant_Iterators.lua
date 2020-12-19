--[[ This file contains all instances of functions that utilize
iterateOverSalesData.
]]--

local ASYNC                     = LibAsync

----------------------------------------
----- Helpers                      -----
----------------------------------------

function MasterMerchant:CleanMule(dataset, currentTask)
  MasterMerchant:dm("Debug", "CleanMule")
  local muleIdCount = 0
  local items       = {}
  currentTask:For (pairs(dataset)):Do(function(iid, id)
    if (id ~= nil) and (type(id) == 'table') then
      items[iid] = id
    else
      muleIdCount = muleIdCount + 1
    end
  end)
  return muleIdCount
end

function MasterMerchant:NonContiguousNonNilCount(tableObject, currentTask)
  local count = 0

  if currentTask then
    currentTask:For (pairs(tableObject)):Do(function(_, v)
      if v ~= nil then count = count + 1 end
    end)
  else
    for _, v in pairs(tableObject) do
      if v ~= nil then count = count + 1 end
    end
  end

  return count
end

function MasterMerchant:CleanTimestamp(salesRecord)
  if (salesRecord == nil) or (salesRecord.timestamp == nil) or (type(salesRecord.timestamp) ~= 'number') then return 0 end
  return salesRecord.timestamp
end

function MasterMerchant:spairs(currentTask, t, order)
  -- all the indexes
  local indexes = {}
  currentTask:For (pairs(t)):Do(function(k)
    indexes[#indexes + 1] = k
  end)

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

function MasterMerchant:IsValidItemLink(itemLink)
  local validLink = true
  local _, count  = string.gsub(itemLink, ':', ':')
  if count ~= 22 then validLink = false end
  local theIID      = GetItemLinkItemId(itemLink)
  local itemIdMatch = tonumber(string.match(itemLink, '|H.-:item:(.-):'))
  if not theIID then validLink = false end
  if theIID and (theIID ~= itemIdMatch) then validLink = false end
  local itemlinkName = GetItemLinkName(itemLink)
  if MasterMerchant:is_empty_or_nil(itemlinkName) then validLink = false end
  return validLink
end

----------------------------------------
----- iterateOverSalesData         -----
----------------------------------------

function MasterMerchant:iterateOverSalesData(itemid, versionid, saleid, prefunc, loopfunc, postfunc, extraData, currentTask)
  extraData.versionCount      = (extraData.versionCount or 0)
  extraData.idCount           = (extraData.idCount or 0)
  extraData.checkMilliseconds = (extraData.checkMilliseconds or 20)

  if prefunc then
    prefunc(extraData, currentTask)
  end

  local checkTime = GetGameTimeMilliseconds()
  local versionlist
  if itemid == nil then
    itemid, versionlist      = next(self.salesData, itemid)
    extraData.versionRemoved = false
    versionid                = nil
  else
    versionlist = self.salesData[itemid]
  end
  while (itemid ~= nil) do
    local versiondata
    if versionid == nil then
      versionid, versiondata = next(versionlist, versionid)
      extraData.saleRemoved  = false
      saleid                 = nil
    else
      versiondata = versionlist[versionid]
    end
    while (versionid ~= nil) do
      if versiondata['sales'] then
        local saledata
        if saleid == nil then
          saleid, saledata = next(versiondata['sales'], saleid)
        else
          saledata = versiondata['sales'][saleid]
        end
        while (saleid ~= nil) do
          local skipTheRest     = loopfunc(itemid, versionid, versiondata, saleid, saledata, extraData, currentTask)
          extraData.saleRemoved = extraData.saleRemoved or (versiondata['sales'][saleid] == nil)
          if skipTheRest then
            saleid = nil
          else
            saleid, saledata = next(versiondata['sales'], saleid)
          end
        end

        if extraData.saleRemoved then
          local sales = {}
          for sid, sd in pairs(versiondata['sales']) do
            if (sd ~= nil) and (type(sd) == 'table') then
              table.insert(sales, sd)
            end
          end
          versiondata['sales'] = sales
        end
      end

      -- If we just deleted all the sales, clear the bucket out
      if (versionlist[versionid] ~= nil and ((versiondata['sales'] == nil) or (MasterMerchant:NonContiguousNonNilCount(versiondata['sales'], currentTask) < 1) or (not string.match(tostring(versionid),
        "^%d+:%d+:%d+:%d+:%d+")))) then
        extraData.versionCount   = (extraData.versionCount or 0) + 1
        versionlist[versionid]   = nil
        extraData.versionRemoved = true
      end

      -- Go onto the next Version
      versionid, versiondata = next(versionlist, versionid)
      extraData.saleRemoved  = false
      saleid                 = nil
    end

    if extraData.versionRemoved then
      local versions = {}
      for vid, vd in pairs(self.salesData[itemid]) do
        if (vd ~= nil) and (type(vd) == 'table') then
          versions[vid] = vd
        end
      end
      self.salesData[itemid] = versions
    end

    if (self.salesData[itemid] ~= nil and ((MasterMerchant:NonContiguousNonNilCount(versionlist, currentTask) < 1) or (type(itemid) ~= 'number'))) then
      extraData.idCount      = (extraData.idCount or 0) + 1
      self.salesData[itemid] = nil
    end

    -- Go on to the next Item
    itemid, versionlist      = next(self.salesData, itemid)
    extraData.versionRemoved = false
    versionid                = nil
  end

  if postfunc then
    postfunc(extraData, currentTask)
  end
end

----------------------------------------
----- Setup                        -----
----------------------------------------

function MasterMerchant:TruncateHistory(currentTask)
  MasterMerchant:dm("Debug", "TruncateHistory")

  -- DEBUG  TruncateHistory
  -- do return end

  local prefunc  = function(extraData, currentTask)
    extraData.start       = GetTimeStamp()
    extraData.deleteCount = 0
    extraData.epochBack   = GetTimeStamp() - (86400 * MasterMerchant.systemSavedVariables.historyDepth)

    self:setScanning(true)
  end

  local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData, currentTask)

    local salesCount = MasterMerchant:NonContiguousNonNilCount(versiondata['sales'], currentTask)
    local salesDataTable = MasterMerchant:spairs(currentTask, versiondata['sales'], function(a, b) return MasterMerchant:CleanTimestamp(a) < MasterMerchant:CleanTimestamp(b) end)
    for saleid, saledata in salesDataTable do
      if MasterMerchant.systemSavedVariables.useSalesHistory then
        if (saledata['timestamp'] < extraData.epochBack
          or saledata['timestamp'] == nil
          or type(saledata['timestamp']) ~= 'number'
        ) then
          -- Remove it by setting it to nil
          versiondata['sales'][saleid] = nil
          extraData.deleteCount        = extraData.deleteCount + 1
          salesCount                   = salesCount - 1
        end
      else
        if salesCount > MasterMerchant.systemSavedVariables.minItemCount and
          (salesCount > MasterMerchant.systemSavedVariables.maxItemCount
            or saledata['timestamp'] == nil
            or type(saledata['timestamp']) ~= 'number'
            or saledata['timestamp'] < extraData.epochBack
          ) then
          -- Remove it by setting it to nil
          versiondata['sales'][saleid] = nil
          extraData.deleteCount        = extraData.deleteCount + 1
          salesCount                   = salesCount - 1
        end
      end
    end
    return true

  end

  local postfunc = function(extraData, currentTask)

    extraData.muleIdCount = 0
    if extraData.deleteCount > 0 then
      extraData.muleIdCount = extraData.muleIdCount + MasterMerchant:CleanMule(MM00Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + MasterMerchant:CleanMule(MM01Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + MasterMerchant:CleanMule(MM02Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + MasterMerchant:CleanMule(MM03Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + MasterMerchant:CleanMule(MM04Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + MasterMerchant:CleanMule(MM05Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + MasterMerchant:CleanMule(MM06Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + MasterMerchant:CleanMule(MM07Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + MasterMerchant:CleanMule(MM08Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + MasterMerchant:CleanMule(MM09Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + MasterMerchant:CleanMule(MM10Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + MasterMerchant:CleanMule(MM11Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + MasterMerchant:CleanMule(MM12Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + MasterMerchant:CleanMule(MM13Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + MasterMerchant:CleanMule(MM14Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + MasterMerchant:CleanMule(MM15Data.savedVariables.SalesData, currentTask)
    end
    self:setScanning(false)

    MasterMerchant:v(4, 'Trimming: ' .. GetTimeStamp() - extraData.start .. ' seconds to trim:')
    MasterMerchant:v(4, '  ' .. extraData.deleteCount .. ' old records removed.')

  end

  if not self.isScanning then
    self:iterateOverSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

end

function MasterMerchant:InitItemHistory(currentTask)
  MasterMerchant:dm("Debug", "InitItemHistory")

  MasterMerchant:v(3, 'Starting Guild and Item total initialization')

  local extradata = {}

  if self.guildItems == nil then
    self.guildItems        = {}
    extradata.doGuildItems = true
  end

  if self.myItems == nil then
    self.myItems         = {}
    extradata.doMyItems  = true
    extradata.playerName = string.lower(GetDisplayName())
  end

  if self.guildSales == nil then
    self.guildSales        = {}
    extradata.doGuildSales = true
  end

  if self.guildPurchases == nil then
    self.guildPurchases        = {}
    extradata.doGuildPurchases = true
  end

  if (extradata.doGuildItems or extradata.doMyItems or extradata.doGuildSales or extradata.doGuildPurchases) then

    local prefunc     = function(extraData, currentTask)
      extraData.start = GetTimeStamp()
      self:setScanning(true)
      extraData.totalRecords = 0
    end

    local loopfunc    = function(itemid, versionid, versiondata, saleid, saledata, extraData, currentTask)
      extraData.totalRecords = extraData.totalRecords + 1
      if (not (saledata == {})) and saledata.guild then
        if (extradata.doGuildItems) then
          self.guildItems[saledata.guild] = self.guildItems[saledata.guild] or MMGuild:new(saledata.guild)
          local guild                     = self.guildItems[saledata.guild]
          local _, firstsaledata          = next(versiondata.sales, nil)
          local seatchData                = versiondata.itemDesc .. ' ' .. versiondata.itemAdderText
          guild:addSaleByDate(firstsaledata.itemLink, saledata.timestamp, saledata.price, saledata.quant, false, false,
            seatchData)
        end

        if (extradata.doMyItems and string.lower(saledata.seller) == extradata.playerName) then
          self.myItems[saledata.guild] = self.myItems[saledata.guild] or MMGuild:new(saledata.guild)
          local guild                  = self.myItems[saledata.guild]
          local _, firstsaledata       = next(versiondata.sales, nil)
          local seatchData             = versiondata.itemDesc .. ' ' .. versiondata.itemAdderText
          guild:addSaleByDate(firstsaledata.itemLink, saledata.timestamp, saledata.price, saledata.quant, false, false,
            seatchData)
        end

        if (extradata.doGuildSales) then
          self.guildSales[saledata.guild] = self.guildSales[saledata.guild] or MMGuild:new(saledata.guild)
          local guild                     = self.guildSales[saledata.guild]
          guild:addSaleByDate(saledata.seller, saledata.timestamp, saledata.price, saledata.quant, false, false)
        end

        if (extradata.doGuildPurchases) then
          self.guildPurchases[saledata.guild] = self.guildPurchases[saledata.guild] or MMGuild:new(saledata.guild)
          local guild                         = self.guildPurchases[saledata.guild]
          guild:addSaleByDate(saledata.buyer, saledata.timestamp, saledata.price, saledata.quant, saledata.wasKiosk,
            false)
        end
      end
      return false
    end

    local postfunc    = function(extraData, currentTask)

      if (extradata.doGuildItems) then
        for _, guild in pairs(self.guildItems) do
          guild:sort()
        end
      end

      if (extradata.doMyItems) then
        for _, guild in pairs(self.myItems) do
          guild:sort()
        end
      end

      if (extradata.doGuildSales) then
        for guildName, guild in pairs(self.guildSales) do
          guild:sort()
        end
      end

      if (extradata.doGuildPurchases) then
        for _, guild in pairs(self.guildPurchases) do
          guild:sort()
        end
      end

      self:setScanning(false)
      self.totalRecords = extraData.totalRecords
      MasterMerchant:v(3, 'Init Guild and Item totals: ' .. GetTimeStamp() - extraData.start .. ' seconds to init ' .. self.totalRecords .. ' records.')
    end

    if not self.isScanning then
      self:iterateOverSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, extradata)
    end

  end
end

-- For faster searching of large histories, we'll maintain an inverted
-- index of search terms - here we build the indexes from the existing table
function MasterMerchant:indexHistoryTables(currentTask)
  MasterMerchant:dm("Debug", "indexHistoryTables")

  -- DEBUG  Stop Indexing
  --do return end

  local prefunc    = function(extraData, currentTask)
    if MasterMerchant.systemSavedVariables.minimalIndexing then
      MasterMerchant:v(3, 'Minimal Indexing...')
    else
      MasterMerchant:v(3, 'Full Indexing...')
    end
    extraData.start             = GetTimeStamp()
    extraData.checkMilliseconds = 60
    extraData.indexCount        = 0
    extraData.wordsIndexCount   = 0
    self.SRIndex                = {}
    self:setScanning(true)
  end

  local tconcat    = table.concat
  local tinsert    = table.insert
  local tolower    = string.lower
  local temp       = { 'b', '', ' s', '', ' ', '', ' ', '', ' ', '', ' ', '' }
  local playerName = tolower(GetDisplayName())

  local loopfunc   = function(numberID, itemData, versiondata, itemIndex, soldItem, extraData, currentTask)

    extraData.indexCount = extraData.indexCount + 1

    local searchText
    if MasterMerchant.systemSavedVariables.minimalIndexing then
      if playerName == tolower(soldItem['seller']) then
        searchText = tolower(MasterMerchant.PlayerSpecialText)
      else
        searchText = ''
      end
    else
      versiondata.itemAdderText = versiondata.itemAdderText or self.addedSearchToItem(soldItem['itemLink'])
      versiondata.itemDesc      = versiondata.itemDesc or GetItemLinkName(soldItem['itemLink'])
      versiondata.itemIcon      = versiondata.itemIcon or GetItemLinkInfo(soldItem['itemLink'])

      temp[2]                   = soldItem['buyer'] or ''
      temp[4]                   = soldItem['seller'] or ''
      temp[6]                   = soldItem['guild'] or ''
      temp[8]                   = versiondata.itemDesc or ''
      temp[10]                  = versiondata.itemAdderText or ''
      if playerName == tolower(soldItem['seller']) then
        temp[12] = MasterMerchant.PlayerSpecialText
      else
        temp[12] = ''
      end
      searchText = tolower(tconcat(temp, ''))
    end

    -- Index each word
    local searchByWords = string.gmatch(searchText, '%S+')
    local wordData      = { numberID, itemData, itemIndex }
    for i in searchByWords do
      if self.SRIndex[i] == nil then
        extraData.wordsIndexCount = extraData.wordsIndexCount + 1
        self.SRIndex[i]           = {}
      end
      tinsert(self.SRIndex[i], wordData)
    end

  end

  local postfunc   = function(extraData, currentTask)
    self:setScanning(false)
    MasterMerchant:v(3, 'Indexing: ' .. GetTimeStamp() - extraData.start .. ' seconds to index:')
    MasterMerchant:v(3, '  ' .. extraData.indexCount .. ' sales records')
    if extraData.wordsIndexCount > 1 then
      MasterMerchant:v(3, '  ' .. extraData.wordsIndexCount .. ' unique words')
    end
  end

  if not self.isScanning then
    self:iterateOverSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

end

----------------------------------------
----- CleanOutBad                  -----
----------------------------------------

function MasterMerchant:CleanOutBad()
  local currentTask = ASYNC:Create("CleanOutBad")

  local prefunc  = function(extraData, currentTask)
    extraData.start             = GetTimeStamp()
    extraData.moveCount         = 0
    extraData.deleteCount       = 0
    extraData.checkMilliseconds = 120
    extraData.eventIdIsNumber   = 0
    extraData.badItemLinkCount  = 0

    self:setScanning(true)
  end

  local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData, currentTask)
    --saledata.itemDesc = nil
    --saledata.itemAdderText = nil

    if saledata['timestamp'] == nil
      or type(saledata['timestamp']) ~= 'number'
      or saledata['timestamp'] < 0
      or saledata['price'] == nil
      or type(saledata['price']) ~= 'number'
      or saledata['quant'] == nil
      or type(saledata['quant']) ~= 'number'
      or saledata['guild'] == nil
      or saledata['buyer'] == nil
      or type(saledata['buyer']) ~= 'string'
      or string.sub(saledata['buyer'], 1, 1) ~= '@'
      or saledata['seller'] == nil
      or type(saledata['seller']) ~= 'string'
      or string.sub(saledata['seller'], 1, 1) ~= '@'
      or saledata['id'] == nil then
      -- Remove it
      versiondata['sales'][saleid] = nil
      extraData.deleteCount        = extraData.deleteCount + 1
      return
    end
    local key, count   = string.gsub(saledata['itemLink'], ':', ':')
    local theIID       = GetItemLinkItemId(saledata['itemLink'])
    local itemIdMatch  = tonumber(string.match(saledata['itemLink'], '|H.-:item:(.-):'))
    local itemlinkName = GetItemLinkName(saledata['itemLink'])
    if not MasterMerchant:IsValidItemLink(saledata['itemLink']) then
      -- Remove it
      versiondata['sales'][saleid] = nil
      extraData.badItemLinkCount   = extraData.badItemLinkCount + 1
      return
    end
    local newid      = GetItemLinkItemId(saledata['itemLink'])
    local newversion = MasterMerchant.makeIndexFromLink(saledata['itemLink'])
    if type(saledata['id']) == 'number' then
      saledata['id']            = tostring(saledata['id'])
      extraData.eventIdIsNumber = extraData.eventIdIsNumber + 1
    end
    if ((newid ~= itemid) or (newversion ~= versionid)) then
      -- Move this records by inserting it another list and keep a count
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
      local theEvent = {
        buyer     = saledata.buyer,
        guild     = saledata.guild,
        itemLink  = saledata.itemLink,
        quant     = saledata.quant,
        timestamp = saledata.timestamp,
        price     = saledata.price,
        seller    = saledata.seller,
        wasKiosk  = saledata.wasKiosk,
        id        = Id64ToString(saledata.id)
      }
      MasterMerchant:addToHistoryTables(theEvent)
      extraData.moveCount          = extraData.moveCount + 1
      -- Remove it from it's current location
      versiondata['sales'][saleid] = nil
      extraData.deleteCount        = extraData.deleteCount + 1
      return
    end
  end

  local postfunc = function(extraData, currentTask)

    extraData.muleIdCount = 0
    if extraData.deleteCount > 0 then
      extraData.muleIdCount = extraData.muleIdCount + self:CleanMule(MM00Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + self:CleanMule(MM01Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + self:CleanMule(MM02Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + self:CleanMule(MM03Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + self:CleanMule(MM04Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + self:CleanMule(MM05Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + self:CleanMule(MM06Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + self:CleanMule(MM07Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + self:CleanMule(MM08Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + self:CleanMule(MM09Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + self:CleanMule(MM10Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + self:CleanMule(MM11Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + self:CleanMule(MM12Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + self:CleanMule(MM13Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + self:CleanMule(MM14Data.savedVariables.SalesData, currentTask)
      extraData.muleIdCount = extraData.muleIdCount + self:CleanMule(MM15Data.savedVariables.SalesData, currentTask)
    end

    MasterMerchant:v(2, 'Cleaning: ' .. GetTimeStamp() - extraData.start .. ' seconds to clean:')
    MasterMerchant:v(2,
      '  ' .. (extraData.badItemLinkCount + extraData.deleteCount) - extraData.moveCount .. ' bad sales records removed')
    MasterMerchant:v(2, '  ' .. extraData.moveCount .. ' sales records re-indexed')
    MasterMerchant:v(2, '  ' .. extraData.versionCount .. ' bad item versions')
    MasterMerchant:v(2, '  ' .. extraData.idCount .. ' bad item IDs')
    MasterMerchant:v(2, '  ' .. extraData.muleIdCount .. ' bad mule item IDs')
    MasterMerchant:v(2, '  ' .. extraData.eventIdIsNumber .. ' events with numbers converted to strings')
    MasterMerchant:v(2, '  ' .. extraData.badItemLinkCount .. ' bad item links removed')

    local LEQ = LibExecutionQueue:new()
    if extraData.deleteCount > 0 then
      MasterMerchant:v(5, 'Reindexing Everything.')
      --rebuild everything
      self.SRIndex        = {}

      self.guildPurchases = {}
      self.guildSales     = {}
      self.guildItems     = {}
      self.myItems        = {}
      LEQ:Add(function() self:InitItemHistory() end, 'InitItemHistory')
      LEQ:Add(function() self:indexHistoryTables() end, 'indexHistoryTables')
      LEQ:Add(function() MasterMerchant:v(5, 'Reindexing Complete.') end, 'Done')
    end

    LEQ:Add(function()
      self:setScanning(false)
    end, '')
    LEQ:Start()

  end

  if not self.isScanning then
    self:iterateOverSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

  MasterMerchant.systemSavedVariables.shouldReindex   = false
  MasterMerchant.systemSavedVariables.shouldAdderText = false
end

----------------------------------------
----- SlideSales                   -----
----------------------------------------

function MasterMerchant:SlideSales(goback)
  local currentTask = ASYNC:Create("SlideSales")

  local prefunc  = function(extraData, currentTask)
    extraData.start     = GetTimeStamp()
    extraData.moveCount = 0
    extraData.oldName   = GetDisplayName()
    extraData.newName   = extraData.oldName .. 'Slid'
    if extraData.oldName == '@kindredspiritgr' then extraData.newName = '@kindredthesexybiotch' end

    if goback then extraData.oldName, extraData.newName = extraData.newName, extraData.oldName end

    self:setScanning(true)
  end

  local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData, currentTask)
    if saledata['seller'] == extraData.oldName then
      saledata['seller']  = extraData.newName
      extraData.moveCount = extraData.moveCount + 1
    end
  end

  local postfunc = function(extraData, currentTask)

    MasterMerchant:v(2, 'Sliding: ' .. GetTimeStamp() - extraData.start .. ' seconds to slide ' .. extraData.moveCount .. ' sales records to ' .. extraData.newName .. '.')
    self.SRIndex[MasterMerchant.PlayerSpecialText] = {}
    self:setScanning(false)

  end

  if not self.isScanning then
    self:iterateOverSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

end
