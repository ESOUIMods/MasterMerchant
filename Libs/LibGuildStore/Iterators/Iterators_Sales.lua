local lib = _G["LibGuildStore"]
local internal = _G["LibGuildStore_Internal"]
local sales_data = _G["LibGuildStore_SalesData"]
local sr_index = _G["LibGuildStore_SalesIndex"]
local ASYNC = LibAsync
--[[ can nout use MasterMerchant.itemsViewSize for example
because that will not be available this early.
]]--
local ITEMS = 'items_vs'
local GUILDS = 'guild_vs'
local LISTINGS = 'listings_vs'
local PURCHASES = 'purchases_vs'
local REPORTS = 'reports_vs'

function internal:CheckForDuplicateSale(itemLink, eventID)
  --[[ we need to be able to calculate theIID and itemIndex
  when not used with addToHistoryTables() event though
  the function will calculate them.
  ]]--
  local theIID = GetItemLinkItemId(itemLink)
  if theIID == nil or theIID == 0 then return end
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)

  if sales_data[theIID] and sales_data[theIID][itemIndex] then
    for k, v in pairs(sales_data[theIID][itemIndex]['sales']) do
      if v.id == eventID then
        return true
      end
    end
  end
  return false
end

-- And here we add a new item
function internal:addSalesData(theEvent)
  -- DEBUG  Stop Adding
  --do return end

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

  -- first add new data looks to their tables
  local linkHash = internal:AddSalesTableData("itemLink", theEvent.itemLink)
  local buyerHash = internal:AddSalesTableData("accountNames", theEvent.buyer)
  local sellerHash = internal:AddSalesTableData("accountNames", theEvent.seller)
  local guildHash = internal:AddSalesTableData("guildNames", theEvent.guild)

  --[[The quality effects itemIndex although the ID from the
  itemLink may be the same. We will keep them separate.
  ]]--
  local itemIndex = internal.GetOrCreateIndexFromLink(theEvent.itemLink)
  --[[theIID is used in the SRIndex so define it here.
  ]]--
  local theIID = GetItemLinkItemId(theEvent.itemLink)
  if theIID == nil or theIID == 0 then return false end

  --[[If the ID from the itemLink doesn't exist determine which
  file or container it will belong to using SetGuildStoreData()
  ]]--
  local hashUsed = "alreadyExisted"
  if not sales_data[theIID] then
    sales_data[theIID], hashUsed = internal:SetGuildStoreData(theEvent.itemLink, theIID)
  end

  local insertedIndex = 1

  local searchItemDesc = ""
  local searchItemAdderText = ""

  local newEvent = ZO_DeepTableCopy(theEvent)
  newEvent.itemLink = linkHash
  newEvent.buyer = buyerHash
  newEvent.seller = sellerHash
  newEvent.guild = guildHash

  if sales_data[theIID][itemIndex] then
    local nextLocation = #sales_data[theIID][itemIndex]['sales'] + 1
    searchItemDesc = sales_data[theIID][itemIndex].itemDesc
    searchItemAdderText = sales_data[theIID][itemIndex].itemAdderText
    if sales_data[theIID][itemIndex]['sales'][nextLocation] == nil then
      table.insert(sales_data[theIID][itemIndex]['sales'], nextLocation, newEvent)
      insertedIndex = nextLocation
    else
      table.insert(sales_data[theIID][itemIndex]['sales'], newEvent)
      insertedIndex = #sales_data[theIID][itemIndex]['sales']
    end
  else
    if sales_data[theIID][itemIndex] == nil then sales_data[theIID][itemIndex] = {} end
    if sales_data[theIID][itemIndex]['sales'] == nil then sales_data[theIID][itemIndex]['sales'] = {} end
    searchItemDesc = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(theEvent.itemLink))
    searchItemAdderText = internal:AddSearchToItem(theEvent.itemLink)
    sales_data[theIID][itemIndex] = {
      itemIcon      = GetItemLinkInfo(theEvent.itemLink),
      itemAdderText = searchItemAdderText,
      itemDesc      = searchItemDesc,
      sales         = { newEvent } }
    --internal:dm("Debug", newEvent)
  end
  sales_data[theIID][itemIndex].wasAltered = true
  if sales_data[theIID][itemIndex] and sales_data[theIID][itemIndex].totalCount then
    sales_data[theIID][itemIndex].totalCount = sales_data[theIID][itemIndex].totalCount + 1
  else
    sales_data[theIID][itemIndex].totalCount = 1
  end
  if sales_data[theIID][itemIndex]["oldestTime"] == nil or sales_data[theIID][itemIndex]["oldestTime"] > newEvent["timestamp"] then sales_data[theIID][itemIndex]["oldestTime"] = newEvent["timestamp"] end
  if sales_data[theIID][itemIndex]["newestTime"] == nil or sales_data[theIID][itemIndex]["newestTime"] < newEvent["timestamp"] then sales_data[theIID][itemIndex]["newestTime"] = newEvent["timestamp"] end

  -- this section adds the sales to the lists for the MM window
  local guild
  local adderDescConcat = searchItemDesc .. ' ' .. searchItemAdderText
  local sortSales = not internal.isDatabaseBusy

  guild = internal.guildSales[theEvent.guild] or MMGuild:new(theEvent.guild)
  internal.guildSales[theEvent.guild] = guild
  guild:addSaleByDate(theEvent.seller, theEvent.timestamp, theEvent.price, theEvent.quant, false)

  guild = internal.guildPurchases[theEvent.guild] or MMGuild:new(theEvent.guild)
  internal.guildPurchases[theEvent.guild] = guild
  guild:addSaleByDate(theEvent.buyer, theEvent.timestamp, theEvent.price, theEvent.quant, theEvent.wasKiosk)

  guild = internal.guildItems[theEvent.guild] or MMGuild:new(theEvent.guild)
  internal.guildItems[theEvent.guild] = guild
  guild:addSaleByDate(theEvent.itemLink, theEvent.timestamp, theEvent.price, theEvent.quant, false, nil, adderDescConcat)

  local playerName = string.lower(GetDisplayName())
  local isSelfSale = playerName == string.lower(theEvent.seller)

  if isSelfSale then
    guild = internal.myItems[theEvent.guild] or MMGuild:new(theEvent.guild)
    internal.myItems[theEvent.guild] = guild;
    guild:addSaleByDate(theEvent.itemLink, theEvent.timestamp, theEvent.price, theEvent.quant, false, nil, adderDescConcat)
  end

  local temp = { '', ' ', '', ' ', '', ' ', '', ' ', '', ' ', '', }
  local searchText = ""
  if LibGuildStore_SavedVariables["minimalIndexing"] then
    if isSelfSale then
      searchText = internal.PlayerSpecialText
    end
  else
    if theEvent.buyer then temp[1] = 'b' .. theEvent.buyer end
    if theEvent.seller then temp[3] = 's' .. theEvent.seller end
    temp[5] = theEvent.guild or ''
    temp[7] = searchItemDesc or ''
    temp[9] = searchItemAdderText or ''
    if isSelfSale then
      temp[11] = internal.PlayerSpecialText
    end
    searchText = string.lower(table.concat(temp, ''))
  end

  local searchByWords = zo_strgmatch(searchText, '%S+')
  local wordData = { theIID, itemIndex, insertedIndex }

  -- Index each word
  for i in searchByWords do
    if sr_index[i] == nil then sr_index[i] = {} end
    table.insert(sr_index[i], wordData)
    internal.sr_index_count = internal.sr_index_count + 1
  end

  MasterMerchant.listIsDirty[ITEMS] = true
  MasterMerchant.listIsDirty[GUILDS] = true

  MasterMerchant:ClearItemCacheById(theIID, itemIndex)

  return true
end

--[[ sr_index, originally SRIndex is an inverted index of the
ScanResults table. Each key is a word found in one of the sales
items' searched fields (buyer, guild, item name) and a table
of the sales_data, originally SalesData indexes that contain
that word.
]]--

----------------------------------------
----- iterateOverSalesData         -----
----------------------------------------

function internal:iterateOverSalesData(itemid, versionid, saleid, prefunc, loopfunc, postfunc, extraData)
  extraData.versionCount = (extraData.versionCount or 0)
  extraData.idCount = (extraData.idCount or 0)
  extraData.checkMilliseconds = (extraData.checkMilliseconds or 20)

  if prefunc then
    prefunc(extraData)
  end

  local checkTime = GetGameTimeMilliseconds()
  local versionlist
  if itemid == nil then
    itemid, versionlist = next(sales_data, itemid)
    extraData.versionRemoved = false
    versionid = nil
  else
    versionlist = sales_data[itemid]
  end
  while (itemid ~= nil) do
    local versiondata
    if versionid == nil then
      versionid, versiondata = next(versionlist, versionid)
      extraData.saleRemoved = false
      saleid = nil
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
          local skipTheRest = loopfunc(itemid, versionid, versiondata, saleid, saledata, extraData)
          extraData.saleRemoved = extraData.saleRemoved or (versiondata['sales'][saleid] == nil)
          if skipTheRest then
            saleid = nil
          else
            saleid, saledata = next(versiondata['sales'], saleid)
          end
          -- We've run out of time, wait and continue with next sale
          if saleid and (GetGameTimeMilliseconds() - checkTime) > extraData.checkMilliseconds then
            local LEQ = LibExecutionQueue:new()
            LEQ:ContinueWith(function() internal:iterateOverSalesData(itemid, versionid, saleid, nil, loopfunc,
              postfunc,
              extraData) end, nil)
            return
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
      if (versionlist[versionid] ~= nil and ((versiondata['sales'] == nil) or (internal:NonContiguousNonNilCount(versiondata['sales']) < 1) or (not zo_strmatch(tostring(versionid),
        "^%d+:%d+:%d+:%d+:%d+")))) then
        extraData.versionCount = (extraData.versionCount or 0) + 1
        versionlist[versionid] = nil
        extraData.versionRemoved = true
      end

      if LibGuildStore_SavedVariables["updateAdditionalText"] then
        local itemData = nil
        for sid, sd in pairs(versiondata['sales']) do
          if (sd ~= nil) and (type(sd) == 'table') then
            itemData = sd
            break
          end
        end

        if itemData then
          itemLink = internal:GetItemLinkByIndex(itemData["itemLink"])
          if itemLink then
            versiondata['itemAdderText'] = internal:AddSearchToItem(itemLink)
            versiondata['itemDesc'] = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink))
          end
        end
      end
      if extraData.wasAltered then
        versiondata["wasAltered"] = true
        extraData.wasAltered = false
      end
      -- Go onto the next Version
      versionid, versiondata = next(versionlist, versionid)
      extraData.saleRemoved = false
      saleid = nil
      if versionid and (GetGameTimeMilliseconds() - checkTime) > extraData.checkMilliseconds then
        local LEQ = LibExecutionQueue:new()
        LEQ:ContinueWith(function() internal:iterateOverSalesData(itemid, versionid, saleid, nil, loopfunc, postfunc,
          extraData) end, nil)
        return
      end
    end

    if extraData.versionRemoved then
      local versions = {}
      for vid, vd in pairs(sales_data[itemid]) do
        if (vd ~= nil) and (type(vd) == 'table') then
          versions[vid] = vd
        end
      end
      sales_data[itemid] = versions
    end

    if (sales_data[itemid] ~= nil and ((internal:NonContiguousNonNilCount(versionlist) < 1) or (type(itemid) ~= 'number'))) then
      extraData.idCount = (extraData.idCount or 0) + 1
      sales_data[itemid] = nil
    end

    -- Go on to the next Item
    itemid, versionlist = next(sales_data, itemid)
    extraData.versionRemoved = false
    versionid = nil
  end

  if postfunc then
    postfunc(extraData)
  end
end

----------------------------------------
----- Setup                        -----
----------------------------------------

-- TODO is salesData important here
-- Yes it does not use SavedVars but the global table
function internal:TruncateSalesHistory()
  internal:dm("Debug", "TruncateSalesHistory")

  -- DEBUG  TruncateSalesHistory
  -- do return end

  local prefunc = function(extraData)
    extraData.start = GetTimeStamp()
    extraData.deleteCount = 0
    extraData.epochBack = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * LibGuildStore_SavedVariables["historyDepth"])
    extraData.wasAltered = false

    internal:DatabaseBusy(true)
  end

  local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData)

    local salesDeleted = 0
    salesCount = versiondata.totalCount
    local salesDataTable = internal:spairs(versiondata['sales'],
      function(a, b) return internal:CleanTimestamp(a) < internal:CleanTimestamp(b) end)
    for saleid, saledata in salesDataTable do
      if LibGuildStore_SavedVariables["useSalesHistory"] then
        if (saledata['timestamp'] < extraData.epochBack
          or saledata['timestamp'] == nil
          or type(saledata['timestamp']) ~= 'number'
        ) then
          -- Remove it by setting it to nil
          versiondata['sales'][saleid] = nil
          salesDeleted = salesDeleted + 1
          extraData.wasAltered = true
        end
      else
        if salesCount > LibGuildStore_SavedVariables["minItemCount"] and
          (salesCount > LibGuildStore_SavedVariables["maxItemCount"]
            or saledata['timestamp'] == nil
            or type(saledata['timestamp']) ~= 'number'
            or saledata['timestamp'] < extraData.epochBack
          ) then
          -- Remove it by setting it to nil
          versiondata['sales'][saleid] = nil
          salesDeleted = salesDeleted + 1
          salesCount = salesCount - 1
          extraData.wasAltered = true
        end
      end
    end
    extraData.deleteCount = extraData.deleteCount + salesDeleted
    --[[ `for saleid, saledata in salesDataTable do` is not a loop
    to Lua so we can not get the oldest time of the first element
    and break. Mark the list altered and clean up in RenewExtraData.

    Also since we have to get the new oldest time, renew the totalCount
    with RenewExtraData also.
    ]]--
    return true
  end

  local postfunc = function(extraData)
    internal:DatabaseBusy(false)
    if LibGuildStore_SavedVariables["showTruncateSummary"] then
      internal:dm("Info", string.format(GetString(GS_TRUNCATE_SALES_COMPLETE), GetTimeStamp() - extraData.start, extraData.deleteCount))
    end
  end

  if not internal.isDatabaseBusy then
    internal:iterateOverSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

end

----------------------------------------
----- Indexers at Startup          -----
----------------------------------------

-- For faster searching of large histories, we'll maintain an inverted
-- index of search terms - here we build the indexes from the existing table
function internal:IndexSalesData()
  internal:dm("Debug", "IndexSalesData")

  -- DEBUG  Stop Indexing
  --do return end

  local prefunc = function(extraData)
    extraData.start = GetTimeStamp()
    extraData.checkMilliseconds = ZO_ONE_MINUTE_IN_SECONDS
    extraData.indexCount = 0
    extraData.wordsIndexCount = 0
    extraData.wasAltered = false
    internal:DatabaseBusy(true)
  end

  local loopfunc = function(numberID, itemData, versiondata, itemIndex, soldItem, extraData)

    extraData.indexCount = extraData.indexCount + 1

    local currentItemLink = internal:GetItemLinkByIndex(soldItem['itemLink'])
    local currentGuild = internal:GetGuildNameByIndex(soldItem['guild'])
    local currentBuyer = internal:GetAccountNameByIndex(soldItem['buyer'])
    local currentSeller = internal:GetAccountNameByIndex(soldItem['seller'])

    local playerName = string.lower(GetDisplayName())
    local selfSale = playerName == string.lower(currentSeller)
    local temp = { '', ' ', '', ' ', '', ' ', '', ' ', '', ' ', '', }
    local searchText = ""
    if LibGuildStore_SavedVariables["minimalIndexing"] then
      if selfSale then
        searchText = internal.PlayerSpecialText
      end
    else
      versiondata.itemAdderText = versiondata.itemAdderText or self.addedSearchToItem(currentItemLink)
      versiondata.itemDesc = versiondata.itemDesc or GetItemLinkName(currentItemLink)
      versiondata.itemIcon = versiondata.itemIcon or GetItemLinkInfo(currentItemLink)

      if currentBuyer then temp[1] = 'b' .. currentBuyer end
      if currentSeller then temp[3] = 's' .. currentSeller end
      temp[5] = currentGuild or ''
      temp[7] = versiondata.itemDesc or ''
      temp[9] = versiondata.itemAdderText or ''
      if selfSale then
        temp[11] = internal.PlayerSpecialText
      end
      searchText = string.lower(table.concat(temp, ''))
    end

    -- Index each word
    local searchByWords = zo_strgmatch(searchText, '%S+')
    local wordData = { numberID, itemData, itemIndex }
    for i in searchByWords do
      if sr_index[i] == nil then
        extraData.wordsIndexCount = extraData.wordsIndexCount + 1
        sr_index[i] = {}
      end
      table.insert(sr_index[i], wordData)
      internal.sr_index_count = internal.sr_index_count + 1
    end

  end

  local postfunc = function(extraData)
    internal:DatabaseBusy(false)
    if LibGuildStore_SavedVariables["showIndexingSummary"] then
      internal:dm("Info", string.format(GetString(GS_INDEXING_SUMMARY), GetTimeStamp() - extraData.start, extraData.indexCount, extraData.wordsIndexCount))
    end
  end

  if not internal.isDatabaseBusy then
    internal:iterateOverSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

end

function internal:InitItemHistory()
  internal:dm("Debug", "InitItemHistory")

  local extradata = {}

  if internal.guildItems == nil then
    internal.guildItems = {}
    extradata.doGuildItems = true
  end

  if internal.myItems == nil then
    internal.myItems = {}
    extradata.doMyItems = true
    extradata.playerName = string.lower(GetDisplayName())
  end

  if internal.guildSales == nil then
    internal.guildSales = {}
    extradata.doGuildSales = true
  end

  if internal.guildPurchases == nil then
    internal.guildPurchases = {}
    extradata.doGuildPurchases = true
  end

  if (extradata.doGuildItems or extradata.doMyItems or extradata.doGuildSales or extradata.doGuildPurchases) then

    local prefunc = function(extraData)
      extraData.start = GetTimeStamp()
      internal:DatabaseBusy(true)
      extraData.totalRecords = 0
      extraData.wasAltered = false
    end

    local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData)
      extraData.totalRecords = extraData.totalRecords + 1
      local currentGuild = internal:GetGuildNameByIndex(saledata['guild'])
      if currentGuild then
        local currentSeller = internal:GetAccountNameByIndex(saledata['seller'])
        local currentBuyer = internal:GetAccountNameByIndex(saledata['buyer'])

        if (extradata.doGuildItems) then
          if not internal.guildItems[currentGuild] then
            internal.guildItems[currentGuild] = MMGuild:new(currentGuild)
          end
          local guild = internal.guildItems[currentGuild]
          local _, firstsaledata = next(versiondata.sales, nil)
          local firstsaledataItemLink = internal:GetItemLinkByIndex(firstsaledata.itemLink)
          local searchDataDesc = versiondata.itemDesc or zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(firstsaledataItemLink))
          local searchDataAdder = versiondata.itemAdderText or internal:AddSearchToItem(firstsaledataItemLink)
          local searchData = searchDataDesc .. ' ' .. searchDataAdder
          guild:addSaleByDate(firstsaledataItemLink, saledata.timestamp, saledata.price, saledata.quant, false, false, searchData)
        end

        if (extradata.doMyItems and string.lower(currentSeller) == extradata.playerName) then
          if not internal.myItems[currentGuild] then
            internal.myItems[currentGuild] = MMGuild:new(currentGuild)
          end
          local guild = internal.myItems[currentGuild]
          local _, firstsaledata = next(versiondata.sales, nil)
          local firstsaledataItemLink = internal:GetItemLinkByIndex(firstsaledata.itemLink)
          local searchDataDesc = versiondata.itemDesc or zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(firstsaledataItemLink))
          local searchDataAdder = versiondata.itemAdderText or internal:AddSearchToItem(firstsaledataItemLink)
          local searchData = searchDataDesc .. ' ' .. searchDataAdder
          guild:addSaleByDate(firstsaledataItemLink, saledata.timestamp, saledata.price, saledata.quant, false, false, searchData)
        end

        if (extradata.doGuildSales) then
          if not internal.guildSales[currentGuild] then
            internal.guildSales[currentGuild] = MMGuild:new(currentGuild)
          end
          local guild = internal.guildSales[currentGuild]
          guild:addSaleByDate(currentSeller, saledata.timestamp, saledata.price, saledata.quant, false, false)
        end

        if (extradata.doGuildPurchases) then
          if not internal.guildPurchases[currentGuild] then
            internal.guildPurchases[currentGuild] = MMGuild:new(currentGuild)
          end
          local guild = internal.guildPurchases[currentGuild]
          guild:addSaleByDate(currentBuyer, saledata.timestamp, saledata.price, saledata.quant, saledata.wasKiosk, false)
        end
      end
      return false
    end

    local postfunc = function(extraData)

      if (extradata.doGuildItems) then
        for _, guild in pairs(internal.guildItems) do
          guild:sort()
        end
      end

      if (extradata.doMyItems) then
        for _, guild in pairs(internal.myItems) do
          guild:sort()
        end
      end

      if (extradata.doGuildSales) then
        for guildName, guild in pairs(internal.guildSales) do
          guild:sort()
        end
      end

      if (extradata.doGuildPurchases) then
        for _, guild in pairs(internal.guildPurchases) do
          guild:sort()
        end
      end

      internal:DatabaseBusy(false)

      internal.totalSales = extraData.totalRecords
      if LibGuildStore_SavedVariables["showGuildInitSummary"] then
        internal:dm("Info", string.format(GetString(GS_INIT_SALES_HISTORY_SUMMARY), GetTimeStamp() - extraData.start,
          internal.totalSales))
      end
    end

    if not internal.isDatabaseBusy then
      internal:iterateOverSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, extradata)
    end

  end
end

----------------------------------------
----- CleanOutBad                  -----
----------------------------------------

function internal:CleanOutBad()
  internal:dm("Debug", "CleanOutBad")

  local prefunc = function(extraData)
    extraData.start = GetTimeStamp()
    extraData.moveCount = 0
    extraData.deleteCount = 0
    extraData.checkMilliseconds = 120
    extraData.eventIdIsNumber = 0
    extraData.badItemLinkCount = 0
    extraData.wasAltered = false

    internal:DatabaseBusy(true)
    if LibGuildStore_SavedVariables["updateAdditionalText"] then
      internal:dm("Debug", "Description Text Will be updated")
    end
  end

  local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData)
    --saledata.itemDesc = nil
    --saledata.itemAdderText = nil

    local currentItemLink = internal:GetItemLinkByIndex(saledata['itemLink'])
    local currentGuild = internal:GetGuildNameByIndex(saledata['guild'])
    local currentBuyer = internal:GetAccountNameByIndex(saledata['buyer'])
    local currentSeller = internal:GetAccountNameByIndex(saledata['seller'])
    if type(saledata) ~= 'table'
      or saledata['timestamp'] == nil
      or type(saledata['timestamp']) ~= 'number'
      or saledata['timestamp'] < 0
      or saledata['price'] == nil
      or type(saledata['price']) ~= 'number'
      or saledata['quant'] == nil
      or type(saledata['quant']) ~= 'number'
      or saledata['guild'] == nil
      or currentGuild == nil
      or currentBuyer == nil
      or type(currentBuyer) ~= 'string'
      or string.sub(currentBuyer, 1, 1) ~= '@'
      or currentSeller == nil
      or type(currentSeller) ~= 'string'
      or string.sub(currentSeller, 1, 1) ~= '@'
      or saledata['id'] == nil then
      -- Remove it
      if type(currentGuild) ~= 'string' then
        internal:dm("Warn", "currentGuild was not a string")
        internal:dm("Warn", saledata['guild'])
        internal:dm("Warn", currentGuild)
      end
      versiondata['sales'][saleid] = nil
      extraData.wasAltered = true
      extraData.deleteCount = extraData.deleteCount + 1
      return
    end
    local key, count = string.gsub(currentItemLink, ':', ':')
    local theIID = GetItemLinkItemId(currentItemLink)
    local itemIdMatch = tonumber(zo_strmatch(currentItemLink, '|H.-:item:(.-):'))
    local itemlinkName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(currentItemLink))
    --[[
    if LibGuildStore_SavedVariables["updateAdditionalText"] then
      local itemIndex = internal.GetOrCreateIndexFromLink(currentItemLink)
      sales_data[theIID][itemIndex]['itemAdderText'] = internal:AddSearchToItem(currentItemLink)
      sales_data[theIID][itemIndex]['itemDesc'] = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(currentItemLink))
    end
    ]]--
    -- /script internal:dm("Debug", zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName("|H0:item:69354:363:50:0:0:0:0:0:0:0:0:0:0:0:0:19:0:0:0:0:0|h|h")))
    -- /script internal:dm("Debug", internal:AddSearchToItem("|H0:item:69354:363:50:0:0:0:0:0:0:0:0:0:0:0:0:19:0:0:0:0:0|h|h"))
    if not internal:IsValidItemLink(currentItemLink) then
      -- Remove it
      -- saledata['itemLink']
      local dataInfo = {
        lang        = MasterMerchant.effective_lang,
        individualSale = versiondata['sales'][saleid],
        namespace    = internal.dataNamespace,
        timestamp = GetTimeStamp(),
        itemLink = currentItemLink
      }
      if GS17DataSavedVariables["erroneous_links"] == nil then GS17DataSavedVariables["erroneous_links"] = {} end
      if GS17DataSavedVariables["erroneous_links"][itemid] == nil then GS17DataSavedVariables["erroneous_links"][itemid] = {} end
      table.insert(GS17DataSavedVariables["erroneous_links"][itemid], dataInfo)
      versiondata['sales'][saleid] = nil
      extraData.wasAltered = true
      extraData.badItemLinkCount = extraData.badItemLinkCount + 1
      return
    end
    local newid = GetItemLinkItemId(currentItemLink)
    local newversion = internal.GetOrCreateIndexFromLink(currentItemLink)
    if type(saledata['id']) == 'number' then
      saledata['id'] = tostring(saledata['id'])
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
        buyer     = currentBuyer,
        guild     = currentGuild,
        itemLink  = currentItemLink,
        quant     = saledata.quant,
        timestamp = saledata.timestamp,
        price     = saledata.price,
        seller    = currentSeller,
        wasKiosk  = saledata.wasKiosk,
        id        = Id64ToString(saledata.id)
      }
      internal:addSalesData(theEvent)
      extraData.moveCount = extraData.moveCount + 1
      -- Remove it from it's current location
      versiondata['sales'][saleid] = nil
      extraData.wasAltered = true
      extraData.deleteCount = extraData.deleteCount + 1
      return
    end
  end

  local postfunc = function(extraData)

    internal:dm("Info", string.format(GetString(GS_CLEANING_TIME_ELAPSED), GetTimeStamp() - extraData.start))
    internal:dm("Info", string.format(GetString(GS_CLEANING_BAD_REMOVED),
      (extraData.badItemLinkCount + extraData.deleteCount) - extraData.moveCount))
    internal:dm("Info", string.format(GetString(GS_CLEANING_REINDEXED), extraData.moveCount))
    internal:dm("Info", string.format(GetString(GS_CLEANING_WRONG_VERSION), extraData.versionCount))
    internal:dm("Info", string.format(GetString(GS_CLEANING_WRONG_ID), extraData.idCount))
    --internal:dm("Info", string.format(GetString(GS_CLEANING_WRONG_MULE), extraData.muleIdCount))
    internal:dm("Info", string.format(GetString(GS_CLEANING_STRINGS_CONVERTED), extraData.eventIdIsNumber))
    internal:dm("Info", string.format(GetString(GS_CLEANING_BAD_ITEMLINKS), extraData.badItemLinkCount))

    local LEQ = LibExecutionQueue:new()
    if extraData.deleteCount > 0 then
      internal:dm("Info", GetString(GS_REINDEXING_EVERYTHING))
      --rebuild everything
      local sr_index = {}
      _G["LibGuildStore_SalesIndex"] = sr_index
      internal.sr_index_count = 0

      internal.guildPurchases = {}
      internal.guildSales = {}
      internal.guildItems = {}
      internal.myItems = {}
      LEQ:Add(function() internal:RenewExtraSalesDataAllContainers() end, 'RenewExtraSalesDataAllContainers')
      LEQ:Add(function() internal:InitItemHistory() end, 'InitItemHistory')
      LEQ:Add(function() internal:IndexSalesData() end, 'indexHistoryTables')
      LEQ:Add(function() internal:dm("Info", GetString(GS_REINDEXING_COMPLETE)) end, 'Done')
    end

    LEQ:Add(function()
      internal:DatabaseBusy(false)
    end, '')
    LEQ:Start()

  end

  if not internal.isDatabaseBusy then
    internal:iterateOverSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

  LibGuildStore_SavedVariables["updateAdditionalText"] = false
end

local function FinalizePurge(count)
  local LEQ = LibExecutionQueue:new()
  if count > 0 then
    --rebuild everything
    local sr_index = {}
    _G["LibGuildStore_SalesIndex"] = sr_index
    internal.sr_index_count = 0

    internal.guildPurchases = {}
    internal.guildSales = {}
    internal.guildItems = {}
    internal.myItems = {}
    LEQ:Add(function() internal:InitItemHistory() end, 'InitItemHistory')
    LEQ:Add(function() internal:IndexSalesData() end, 'indexHistoryTables')
  end
  LEQ:Add(function()
    internal:DatabaseBusy(false);
    internal:dm("Info", GetString(GS_REINDEXING_COMPLETE))
  end, 'LetScanningContinue')
  LEQ:Start()
end

function internal:PurgeDups()
  local task = ASYNC:Create("PurgeDups")
  task:Call(function(task) internal:dm("Info", GetString(GS_PURGING_DUPLICATES)) end)

  if not internal.isDatabaseBusy then
    --task:Then(function(task) internal:dm("Debug", "Database ready") end)
    task:Then(function(task) internal:DatabaseBusy(true) end)

    local start = GetTimeStamp()
    local eventArray = { }
    local count = 0
    local newSales
    local deletedSales = { }

    --spin thru history and remove dups
    task:For(pairs(sales_data)):Do(function(itemNumber, itemNumberData)
      --task:Then(function(task) internal:dm("Debug", itemNumber) end)
      task:For(pairs(itemNumberData)):Do(function(itemIndex, itemData)
        if itemData['sales'] then
          local dup
          newSales = {}
          task:For(pairs(itemData['sales'])):Do(function(key, checking)
            local currentItemLink = internal:GetItemLinkByIndex(checking.itemLink)
            local validLink = internal:IsValidItemLink(currentItemLink)
            dup = false
            if checking.id == nil then
              --[[
              if internal.systemSavedVariables.useLibDebugLogger then
                internal:dm("Debug", 'Nil ID found')
              end
              ]]--
              dup = true
            end
            if eventArray[checking.id] then
              --[[
              if internal.systemSavedVariables.useLibDebugLogger then
                internal:dm("Debug", 'Dupe found: ' .. checking.id .. ': ' .. currentItemLink)
                internal:Expected(checking.id)
              end
              ]]--
              dup = true
            end
            if not validLink then dup = true end
            if dup then
              -- Remove it by not putting it in the new list, but keep a count
              table.insert(deletedSales, checking)
              count = count + 1
            else
              table.insert(newSales, checking)
              eventArray[checking.id] = true
            end
          end)
          itemData['sales'] = newSales
        end
      end)
    end)
    --task:Then(function(task) internal:dm("Verbose", internal:NonContiguousNonNilCount(eventArray)) end)
    eventArray = {} -- clear array
    GS16DataSavedVariables["deletedSales"] = deletedSales
    task:Then(function(task) internal:dm("Info", string.format(GetString(GS_DUP_PURGE), GetTimeStamp() - start, count)) end)
    task:Then(function(task) internal:dm("Info", GetString(GS_REINDEXING_EVERYTHING)) end)
    task:Finally(function(task) FinalizePurge(count) end)
  end
end

----------------------------------------
----- SlideSales                   -----
----------------------------------------

function internal:SlideSales(goback)

  local prefunc = function(extraData)
    extraData.start = GetTimeStamp()
    extraData.moveCount = 0
    extraData.wasAltered = false
    extraData.oldName = GetDisplayName()
    extraData.newName = extraData.oldName .. 'Slid'
    if extraData.oldName == '@kindredspiritgr' then extraData.newName = '@kindredthesexybiotch' end

    if goback then extraData.oldName, extraData.newName = extraData.newName, extraData.oldName end

    internal:DatabaseBusy(true)
  end

  local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData)
    if saledata['seller'] == extraData.oldName then
      saledata['seller'] = extraData.newName
      extraData.moveCount = extraData.moveCount + 1
    end
  end

  local postfunc = function(extraData)

    internal:dm("Info", string.format(GetString(GS_SLIDING_SUMMARY), GetTimeStamp() - extraData.start, extraData.moveCount, extraData.newName))
    sr_index[internal.PlayerSpecialText] = {}
    internal:DatabaseBusy(false)

  end

  if not internal.isDatabaseBusy then
    internal:iterateOverSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

end

function internal:ReferenceSales(otherData)
  local savedVars = otherData[internal.dataNamespace]

  for itemid, versionlist in pairs(savedVars) do
    if sales_data[itemid] then
      for versionid, versiondata in pairs(versionlist) do
        if sales_data[itemid][versionid] then
          if versiondata['sales'] then
            sales_data[itemid][versionid]['sales'] = sales_data[itemid][versionid]['sales'] or {}
            -- IPAIRS
            for saleid, saledata in pairs(versiondata['sales']) do
              if (type(saleid) == 'number' and type(saledata) == 'table' and type(saledata["timestamp"]) == 'number') then
                table.insert(sales_data[itemid][versionid]['sales'], saledata)
              end
            end
            local _, first = next(versiondata['sales'], nil)
            if first then
              sales_data[itemid][versionid].itemIcon = GetItemLinkInfo(first.itemLink)
              sales_data[itemid][versionid].itemAdderText = internal:AddSearchToItem(first.itemLink)
              sales_data[itemid][versionid].itemDesc = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(first.itemLink))
            end
          end
        else
          sales_data[itemid][versionid] = versiondata
        end
      end
      savedVars[itemid] = nil
    else
      sales_data[itemid] = versionlist
    end
  end
end

-- Bring seperate lists together we can still access the sales history all together
function internal:ReferenceSalesDataContainer()
  internal:dm("Debug", "Reference Sales Data Containers")
  internal:ReferenceSales(GS00DataSavedVariables)
  internal:ReferenceSales(GS01DataSavedVariables)
  internal:ReferenceSales(GS02DataSavedVariables)
  internal:ReferenceSales(GS03DataSavedVariables)
  internal:ReferenceSales(GS04DataSavedVariables)
  internal:ReferenceSales(GS05DataSavedVariables)
  internal:ReferenceSales(GS06DataSavedVariables)
  internal:ReferenceSales(GS07DataSavedVariables)
  internal:ReferenceSales(GS08DataSavedVariables)
  internal:ReferenceSales(GS09DataSavedVariables)
  internal:ReferenceSales(GS10DataSavedVariables)
  internal:ReferenceSales(GS11DataSavedVariables)
  internal:ReferenceSales(GS12DataSavedVariables)
  internal:ReferenceSales(GS13DataSavedVariables)
  internal:ReferenceSales(GS14DataSavedVariables)
  internal:ReferenceSales(GS15DataSavedVariables)
end

----------------------------------------
----- Reset Data Functions         -----
----------------------------------------

-- Handle the reset button - clear out the search and scan tables,
-- and set the time of the last scan to nil, then force a scan.
function internal:ResetSalesData()
  if GetWorldName() == 'NA Megaserver' and internal.dataToReset == internal.GS_EU_NAMESPACE then
    internal:dm("Info", GetString(GS_RESET_NA_INSTEAD))
    return
  end
  if GetWorldName() == 'EU Megaserver' and internal.dataToReset == internal.GS_NA_NAMESPACE then
    internal:dm("Info", GetString(GS_RESET_EU_INSTEAD))
    return
  end

  internal:dm("Debug", "DoReset")
  local sales_data = {}
  local sr_index = {}
  _G["LibGuildStore_SalesData"] = sales_data
  _G["LibGuildStore_SalesIndex"] = sr_index
  internal.sr_index_count = 0

  GS00DataSavedVariables[internal.dataToReset] = {}
  GS01DataSavedVariables[internal.dataToReset] = {}
  GS02DataSavedVariables[internal.dataToReset] = {}
  GS03DataSavedVariables[internal.dataToReset] = {}
  GS04DataSavedVariables[internal.dataToReset] = {}
  GS05DataSavedVariables[internal.dataToReset] = {}
  GS06DataSavedVariables[internal.dataToReset] = {}
  GS07DataSavedVariables[internal.dataToReset] = {}
  GS08DataSavedVariables[internal.dataToReset] = {}
  GS09DataSavedVariables[internal.dataToReset] = {}
  GS10DataSavedVariables[internal.dataToReset] = {}
  GS11DataSavedVariables[internal.dataToReset] = {}
  GS12DataSavedVariables[internal.dataToReset] = {}
  GS13DataSavedVariables[internal.dataToReset] = {}
  GS14DataSavedVariables[internal.dataToReset] = {}
  GS15DataSavedVariables[internal.dataToReset] = {}

  internal.guildPurchases = {}
  internal.guildSales = {}
  internal.guildItems = {}
  internal.myItems = {}
  if MasterMerchantGuildWindow:IsHidden() then
    MasterMerchant.scrollList:RefreshData()
  else
    MasterMerchant.guildScrollList:RefreshData()
  end
  internal:DatabaseBusy(false)
  internal:dm("Info", internal:concat(GetString(MM_APP_MESSAGE_NAME), GetString(SK_RESET_DONE)))
  internal:dm("Info", internal:concat(GetString(MM_APP_MESSAGE_NAME), GetString(SK_REFRESH_START)))
  MasterMerchant.isFirstScan = true
  --[[needs updating so start and stop the listener then
  init everyting
  ]]--
  internal:RefreshLibGuildStore()
  internal:SetupListenerLibHistoire()
  internal:StartQueue()
end

function internal:Expected(eventID)
  for itemNumber, itemNumberData in pairs(sales_data) do
    for itemIndex, itemData in pairs(itemNumberData) do
      if itemData['sales'] then
        for _, checking in pairs(itemData['sales']) do
          local checkIdString = checking.id
          if type(checking.id) ~= 'string' then
            checkIdString = tostring(checking.id)
          end
          if checkIdString == eventID then
            local itemType, specializedItemType = GetItemLinkItemType(checking.itemLink)
            internal:dm("Debug", "Expected: " .. checking.itemLink .. " found in " .. itemIndex)
            if (specializedItemType ~= 0) then
              internal:dm("Debug", internal:concat("For",
                zo_strformat("<<t:1>>", GetString("SI_SPECIALIZEDITEMTYPE", specializedItemType))))
            end
          end
        end
      end
    end
  end
end

-- TODO not updated
-- DEBUG
function internal:checkForDoubles()

  local dataList = {
    [0]  = GS00DataSavedVariables,
    [1]  = GS01DataSavedVariables,
    [2]  = GS02DataSavedVariables,
    [3]  = GS03DataSavedVariables,
    [4]  = GS04DataSavedVariables,
    [5]  = GS05DataSavedVariables,
    [6]  = GS06DataSavedVariables,
    [7]  = GS07DataSavedVariables,
    [8]  = GS08DataSavedVariables,
    [9]  = GS09DataSavedVariables,
    [10] = GS10DataSavedVariables,
    [11] = GS11DataSavedVariablesa,
    [12] = GS12DataSavedVariables,
    [13] = GS13DataSavedVariables,
    [14] = GS14DataSavedVariables,
    [15] = GS15DataSavedVariables,
  }

  for i = 0, 14, 1 do
    for itemid, versionlist in pairs(dataList[i]) do
      for versionid, _ in pairs(versionlist) do
        for j = i + 1, 15, 1 do
          if dataList[j][itemid] and dataList[j][itemid][versionid] then
            internal:dm("Info", itemid .. '/' .. versionid .. ' is in ' .. i .. ' and ' .. j .. '.')
          end
        end
      end
    end
  end
end

