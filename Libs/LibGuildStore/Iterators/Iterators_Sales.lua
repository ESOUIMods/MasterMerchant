local internal = _G["LibGuildStore_Internal"]
local sales_data = _G["LibGuildStore_SalesData"]
local sr_index = _G["LibGuildStore_SalesIndex"]
local ASYNC = LibAsync
--[[ can nout use MasterMerchant.itemsViewSize for example
because that will not be available this early.
]]--
local ITEMS = 'items_vs'
local GUILDS = 'guild_vs'

function internal:CheckForDuplicateSale(itemLink, eventID)
  --[[ we need to be able to calculate theIID and itemIndex
  when not used with addToHistoryTables() event though
  the function will calculate them.
  ]]--
  local theIID = GetItemLinkItemId(itemLink)
  if theIID == nil or theIID == 0 then return end
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)

  if sales_data[theIID] and sales_data[theIID][itemIndex] then
    for _, v in pairs(sales_data[theIID][itemIndex]['sales']) do
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
  -- if true then return false end

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
  local formattedItemName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(theEvent.itemLink))
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
    sales_data[theIID], hashUsed = internal:SetGuildStoreData(formattedItemName, theIID)
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
    searchItemDesc = formattedItemName
    searchItemAdderText = internal:AddSearchToItem(theEvent.itemLink)
    sales_data[theIID][itemIndex] = {
      itemIcon = GetItemLinkInfo(theEvent.itemLink),
      itemAdderText = searchItemAdderText,
      itemDesc = searchItemDesc,
      sales = { newEvent } }
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

  guild = internal.guildSales[theEvent.guild] or MMGuild:new(theEvent.guild)
  internal.guildSales[theEvent.guild] = guild
  guild:addSaleByDate(theEvent.seller, theEvent.timestamp, theEvent.price, theEvent.quant, false, nil)

  guild = internal.guildPurchases[theEvent.guild] or MMGuild:new(theEvent.guild)
  internal.guildPurchases[theEvent.guild] = guild
  guild:addSaleByDate(theEvent.buyer, theEvent.timestamp, theEvent.price, theEvent.quant, theEvent.wasKiosk, nil)

  guild = internal.guildItems[theEvent.guild] or MMGuild:new(theEvent.guild)
  internal.guildItems[theEvent.guild] = guild
  guild:addSaleByDate(theEvent.itemLink, theEvent.timestamp, theEvent.price, theEvent.quant, false, nil, adderDescConcat)

  local playerName = zo_strlower(GetDisplayName())
  local isSelfSale = playerName == zo_strlower(theEvent.seller)

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
    searchText = zo_strlower(table.concat(temp, ''))
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

  MasterMerchant:ClearPriceCacheById(theIID, itemIndex)

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
  extraData.checkMilliseconds = (extraData.checkMilliseconds or MM_WAIT_TIME_IN_MILLISECONDS_DEFAULT)

  if prefunc then
    prefunc(extraData)
  end

  local checkTime = GetGameTimeMilliseconds()
  local versionlist
  local itemLink
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
    itemLink = nil
    --[[ begin loop over ['x:x:x:x:x'] ]]--
    while (versionid ~= nil) do
      if versiondata['sales'] then
        local saledata
        if saleid == nil then
          saleid, saledata = next(versiondata['sales'], saleid)
        else
          saledata = versiondata['sales'][saleid]
        end
        if not itemLink and saledata and saledata["itemLink"] then itemLink = internal:GetItemLinkByIndex(saledata["itemLink"]) end
        --[[ begin loop over ['sales'] ]]--
        while (saleid ~= nil) do
          --[[skipTheRest is true here from Truncate Sales because in that function
          you are looping over all the sales. Normally you are not and only processing
          a single sale. Therefore when skipTheRest is false you use:

          saleid, saledata = next(versiondata['sales'], saleid)

          to get the next sale and process it
          ]]--
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
            LEQ:ContinueWith(function() internal:iterateOverSalesData(itemid, versionid, saleid, nil, loopfunc, postfunc, extraData) end, nil)
            return
          end
        end
        --[[ end of loop over ['sales'] ]]--

        if extraData.saleRemoved then
          local sales = {}
          local salesCount = 0
          extraData.newSalesCount = nil
          for _, sd in pairs(versiondata['sales']) do
            if (sd ~= nil) and (type(sd) == 'table') then
              table.insert(sales, sd)
              salesCount = salesCount + 1
            end
          end
          versiondata['sales'] = sales
          versiondata["totalCount"] = salesCount
        end

        if extraData.newSalesCount then
          versiondata["totalCount"] = extraData.newSalesCount
        end
      end

      -- If we just deleted all the sales, clear the bucket out
      if (versionlist[versionid] ~= nil and ((versiondata['sales'] == nil) or (versiondata["totalCount"] < 1) or (not zo_strmatch(tostring(versionid), "^%d+:%d+:%d+:%d+:%d+")))) then
        extraData.versionCount = (extraData.versionCount or 0) + 1
        versionlist[versionid] = nil
        extraData.versionRemoved = true
      end

      -- Sharlikran
      if LibGuildStore_SavedVariables["updateAdditionalText"] and not extraData.saleRemoved then
        if itemLink then
          versiondata['itemAdderText'] = internal:AddSearchToItem(itemLink)
          versiondata['itemDesc'] = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink))
        end
      end

      -- Sharlikran
      if extraData.wasAltered and not extraData.saleRemoved then
        versiondata["wasAltered"] = true
        extraData.wasAltered = false
      end

      -- Go onto the next Version
      versionid, versiondata = next(versionlist, versionid)
      extraData.saleRemoved = false
      extraData.newSalesCount = nil
      saleid = nil
      if versionid and (GetGameTimeMilliseconds() - checkTime) > extraData.checkMilliseconds then
        local LEQ = LibExecutionQueue:new()
        LEQ:ContinueWith(function() internal:iterateOverSalesData(itemid, versionid, saleid, nil, loopfunc, postfunc, extraData) end, nil)
        return
      end
    end
    --[[ end loop over ['x:x:x:x:x'] ]]--

    if extraData.versionRemoved then
      local versions = {}
      for vid, vd in pairs(sales_data[itemid]) do
        if (vd ~= nil) and (type(vd) == 'table') then
          versions[vid] = vd
        end
      end
      sales_data[itemid] = versions
    end

    -- If we just deleted everything, clear the bucket out
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
-- /script LibGuildStore_Internal:TruncateSalesHistory()
function internal:TruncateSalesHistory()
  internal:dm("Debug", "TruncateSalesHistory")

  -- DEBUG  TruncateSalesHistory
  -- do return end

  local prefunc = function(extraData)
    extraData.start = GetTimeStamp()
    extraData.deleteCount = 0
    extraData.epochBack = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * LibGuildStore_SavedVariables["historyDepth"])
    extraData.wasAltered = false
    extraData.newSalesCount = 0
    extraData.minItemCount = LibGuildStore_SavedVariables["minItemCount"]
    extraData.maxItemCount = LibGuildStore_SavedVariables["maxItemCount"]
    extraData.minSalesInterval = LibGuildStore_SavedVariables["minSalesInterval"]
    extraData.useSalesInterval = LibGuildStore_SavedVariables["minSalesInterval"] > 0
    extraData.useSalesHistory = LibGuildStore_SavedVariables["useSalesHistory"]

    internal:DatabaseBusy(true)
  end

  local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData)

    local salesDeleted = 0
    local salesCount = versiondata.totalCount
    --[[TODO Determine how the salesCount can be 0 and there is an empty
    sale in the table.
    [8] = {},
    ]]--
    if salesCount == 0 then
      versiondata['sales'] = {}
      extraData.saleRemoved = false
      extraData.newSalesCount = 0
      return true -- value true for return
    end
    local salesDataTable = internal:spairs(versiondata['sales'], function(a, b) return internal:CleanTimestamp(a) < internal:CleanTimestamp(b) end)
    for salesId, salesData in salesDataTable do
      local removeSale = false
      local invalidTimestamp = salesData['timestamp'] == nil or type(salesData['timestamp']) ~= 'number'
      local additionalCriteria = salesCount > extraData.maxItemCount or invalidTimestamp or salesData['timestamp'] < extraData.epochBack
      if extraData.useSalesHistory then
        if salesData['timestamp'] < extraData.epochBack or invalidTimestamp then removeSale = true end
      elseif extraData.useSalesInterval then
        local minInterval = GetTimeStamp() - (extraData.minSalesInterval * ZO_ONE_DAY_IN_SECONDS)
        if (salesCount > extraData.minItemCount and salesData['timestamp'] < minInterval) and additionalCriteria then removeSale = true end
      else
        if salesCount > extraData.minItemCount and additionalCriteria then removeSale = true end
      end
      -- Remove it by setting it to nil
      if removeSale then
        versiondata['sales'][salesId] = nil
        salesDeleted = salesDeleted + 1
        salesCount = salesCount - 1
        extraData.wasAltered = true
      end
    end
    extraData.deleteCount = extraData.deleteCount + salesDeleted
    extraData.newSalesCount = salesCount
    --[[ `for saleid, saledata in salesDataTable do` is not a loop
    to Lua so we can not get the oldest time of the first element
    and break. Mark the list altered and clean up in RenewExtraData.

    Also since we have to get the new oldest time, renew the totalCount
    with RenewExtraData also.
    ]]--
    return true -- value true for return
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
    extraData.checkMilliseconds = MM_WAIT_TIME_IN_MILLISECONDS_SHORT
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

    local playerName = zo_strlower(GetDisplayName())
    local selfSale = playerName == zo_strlower(currentSeller)
    local searchText = ""
    if LibGuildStore_SavedVariables["minimalIndexing"] then
      if selfSale then
        searchText = internal.PlayerSpecialText
      end
    else
      versiondata.itemAdderText = versiondata.itemAdderText or self.addedSearchToItem(currentItemLink)
      versiondata.itemDesc = versiondata.itemDesc or zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(currentItemLink))
      versiondata.itemIcon = versiondata.itemIcon or GetItemLinkInfo(currentItemLink)

      local temp = { '', ' ', '', ' ', '', ' ', '', ' ', '', ' ', '', }
      if currentBuyer then temp[1] = 'b' .. currentBuyer end
      if currentSeller then temp[3] = 's' .. currentSeller end
      temp[5] = currentGuild or ''
      temp[7] = versiondata.itemDesc or ''
      temp[9] = versiondata.itemAdderText or ''
      if selfSale then
        temp[11] = internal.PlayerSpecialText
      end
      searchText = zo_strlower(table.concat(temp, ''))
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
    -- no return
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

function internal:InitSalesHistory()
  internal:dm("Debug", "InitSalesHistory")

  local extradata = {}

  if internal.guildItems == nil then
    internal.guildItems = {}
    extradata.doGuildItems = true
  end

  if internal.myItems == nil then
    internal.myItems = {}
    extradata.doMyItems = true
    extradata.playerName = zo_strlower(GetDisplayName())
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

        if (extradata.doMyItems and zo_strlower(currentSeller) == extradata.playerName) then
          if not internal.myItems[currentGuild] then
            internal.myItems[currentGuild] = MMGuild:new(currentGuild)
          end
          local _, firstsaledata = next(versiondata.sales, nil)
          local firstsaledataItemLink = internal:GetItemLinkByIndex(firstsaledata.itemLink)
          local searchDataDesc = versiondata.itemDesc or zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(firstsaledataItemLink))
          local searchDataAdder = versiondata.itemAdderText or internal:AddSearchToItem(firstsaledataItemLink)
          local searchData = searchDataDesc .. ' ' .. searchDataAdder
          local guild = internal.myItems[currentGuild]
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
      return false  -- value false for return
    end

    local postfunc = function(extraData)

      if (extradata.doGuildItems) then
        for _, guild in pairs(internal.guildItems) do
          guild:SortAllRanks()
        end
      end

      if (extradata.doMyItems) then
        for _, guild in pairs(internal.myItems) do
          guild:SortAllRanks()
        end
      end

      if (extradata.doGuildSales) then
        for _, guild in pairs(internal.guildSales) do
          guild:SortAllRanks()
        end
      end

      if (extradata.doGuildPurchases) then
        for _, guild in pairs(internal.guildPurchases) do
          guild:SortAllRanks()
        end
      end

      internal:DatabaseBusy(false)

      internal.totalSales = extraData.totalRecords
      if LibGuildStore_SavedVariables["showGuildInitSummary"] then
        internal:dm("Info", string.format(GetString(GS_INIT_SALES_HISTORY_SUMMARY), GetTimeStamp() - extraData.start, internal.totalSales))
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
    extraData.checkMilliseconds = MM_WAIT_TIME_IN_MILLISECONDS_LONG
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
      return -- no value for return
    end
    local validLink, theIID, itemIdMatch = internal:IsValidItemLink(currentItemLink)
    if not validLink then
      local dataInfo = {
        lang = MasterMerchant.effective_lang,
        individualSale = versiondata['sales'][saleid],
        namespace = internal.dataNamespace,
        timestamp = GetTimeStamp(),
        itemLink = currentItemLink,
        theIID = theIID,
        itemIdMatch = itemIdMatch,
        itemLinkLookupValue = saledata['itemLink']
      }
      GS17DataSavedVariables["erroneous_links"] = GS17DataSavedVariables["erroneous_links"] or {}
      GS17DataSavedVariables["erroneous_links"][itemid] = GS17DataSavedVariables["erroneous_links"][itemid] or {}
      table.insert(GS17DataSavedVariables["erroneous_links"][itemid], dataInfo)
      -- Remove sale
      versiondata['sales'][saleid] = nil
      extraData.wasAltered = true
      extraData.badItemLinkCount = extraData.badItemLinkCount + 1
      return -- no value for return
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
        buyer = currentBuyer,
        guild = currentGuild,
        itemLink = currentItemLink,
        quant = saledata.quant,
        timestamp = saledata.timestamp,
        price = saledata.price,
        seller = currentSeller,
        wasKiosk = saledata.wasKiosk,
        id = Id64ToString(saledata.id)
      }
      internal:addSalesData(theEvent)
      extraData.moveCount = extraData.moveCount + 1
      -- Remove it from it's current location
      versiondata['sales'][saleid] = nil
      extraData.wasAltered = true
      extraData.deleteCount = extraData.deleteCount + 1
      return -- no value for return
    end
  end

  local postfunc = function(extraData)

    internal:dm("Info", string.format(GetString(GS_CLEANING_TIME_ELAPSED), GetTimeStamp() - extraData.start))
    internal:dm("Info", string.format(GetString(GS_CLEANING_BAD_REMOVED), (extraData.badItemLinkCount + extraData.deleteCount) - extraData.moveCount))
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
      LibGuildStore_SavedVariables["updateAdditionalText"] = false
      LEQ:Add(function() internal:RenewExtraSalesDataAllContainers() end, 'RenewExtraSalesDataAllContainers')
      LEQ:Add(function() internal:InitSalesHistory() end, 'InitSalesHistory')
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
    LEQ:Add(function() internal:InitSalesHistory() end, 'InitSalesHistory')
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
    task:For(pairs(sales_data)):Do(function(_, itemNumberData)
      --task:Then(function(task) internal:dm("Debug", itemNumber) end)
      task:For(pairs(itemNumberData)):Do(function(_, itemData)
        if itemData['sales'] then
          local dup
          newSales = {}
          task:For(pairs(itemData['sales'])):Do(function(_, checking)
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
    -- no return
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
local function ResetSalesDataNA()
  GS00Data:ResetSalesDataNA()
  GS01Data:ResetSalesDataNA()
  GS02Data:ResetSalesDataNA()
  GS03Data:ResetSalesDataNA()
  GS04Data:ResetSalesDataNA()
  GS05Data:ResetSalesDataNA()
  GS06Data:ResetSalesDataNA()
  GS07Data:ResetSalesDataNA()
  GS08Data:ResetSalesDataNA()
  GS09Data:ResetSalesDataNA()
  GS10Data:ResetSalesDataNA()
  GS11Data:ResetSalesDataNA()
  GS12Data:ResetSalesDataNA()
  GS13Data:ResetSalesDataNA()
  GS14Data:ResetSalesDataNA()
  GS15Data:ResetSalesDataNA()
end

local function ResetSalesDataEU()
  GS00Data:ResetSalesDataEU()
  GS01Data:ResetSalesDataEU()
  GS02Data:ResetSalesDataEU()
  GS03Data:ResetSalesDataEU()
  GS04Data:ResetSalesDataEU()
  GS05Data:ResetSalesDataEU()
  GS06Data:ResetSalesDataEU()
  GS07Data:ResetSalesDataEU()
  GS08Data:ResetSalesDataEU()
  GS09Data:ResetSalesDataEU()
  GS10Data:ResetSalesDataEU()
  GS11Data:ResetSalesDataEU()
  GS12Data:ResetSalesDataEU()
  GS13Data:ResetSalesDataEU()
  GS14Data:ResetSalesDataEU()
  GS15Data:ResetSalesDataEU()
end

-- Handle the reset button - clear out the search and scan tables,
-- and set the time of the last scan to nil, then force a scan.
function internal:ResetSalesData()
  internal:dm("Debug", "ResetSalesData")
  if GetWorldName() == 'NA Megaserver' then
    ResetSalesDataNA()
  else
    ResetSalesDataEU()
  end
  internal:DatabaseBusy(true)
  LibGuildStore_SavedVariables[internal.firstrunNamespace] = true
  LibGuildStore_SavedVariables.libHistoireScanByTimestamp = true
  ReloadUI()
end

function internal:Expected(eventID)
  for _, itemNumberData in pairs(sales_data) do
    for itemIndex, itemData in pairs(itemNumberData) do
      if itemData['sales'] then
        for _, checking in pairs(itemData['sales']) do
          local checkIdString = checking.id
          if type(checking.id) ~= 'string' then
            checkIdString = tostring(checking.id)
          end
          if checkIdString == eventID then
            local _, specializedItemType = GetItemLinkItemType(checking.itemLink)
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
-- DEBUG checkForDoubles
function internal:checkForDoubles()

  local dataList = {
    [0] = GS00DataSavedVariables,
    [1] = GS01DataSavedVariables,
    [2] = GS02DataSavedVariables,
    [3] = GS03DataSavedVariables,
    [4] = GS04DataSavedVariables,
    [5] = GS05DataSavedVariables,
    [6] = GS06DataSavedVariables,
    [7] = GS07DataSavedVariables,
    [8] = GS08DataSavedVariables,
    [9] = GS09DataSavedVariables,
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
