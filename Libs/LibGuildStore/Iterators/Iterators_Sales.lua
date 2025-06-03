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
  when not used with addToHistoryTables() even though
  the function will calculate them.
  ]]--
  local theIID = GetItemLinkItemId(itemLink)
  if theIID == nil or theIID == 0 then return end
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)

  if sales_data[theIID] and sales_data[theIID][itemIndex] then
    for _, v in pairs(sales_data[theIID][itemIndex]['sales']) do
      if type(v.id) == "string" or v.id == eventID then
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
  local newEvent = ZO_DeepTableCopy(theEvent)
  local eventItemLink = newEvent.itemLink
  local eventBuyer = newEvent.buyer
  local eventSeller = newEvent.seller
  local eventGuild = newEvent.guild
  local timestamp = newEvent.timestamp

  -- first add new data lookups to their tables
  local linkHash = internal:AddSalesTableData("itemLink", eventItemLink)
  local buyerHash = internal:AddSalesTableData("accountNames", eventBuyer)
  local sellerHash = internal:AddSalesTableData("accountNames", eventSeller)
  local guildHash = internal:AddSalesTableData("guildNames", eventGuild)
  local formattedItemName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(eventItemLink))

  --[[The quality effects itemIndex although the ID from the
  itemLink may be the same. We will keep them separate.
  ]]--
  local itemIndex = internal.GetOrCreateIndexFromLink(eventItemLink)

  --[[theIID is used in wordData for the SRIndex, define it here.
  ]]--
  local theIID = GetItemLinkItemId(eventItemLink)
  if theIID == nil or theIID == 0 then return false end

  --[[If the ID from the itemLink doesn't exist determine which
  file or container it will belong to using SetGuildStoreData()
  ]]--
  local hashUsed = "alreadyExisted"
  if not sales_data[theIID] then
    sales_data[theIID], hashUsed = internal:SetGuildStoreData(formattedItemName, theIID)
  end
  sales_data[theIID][itemIndex] = sales_data[theIID][itemIndex] or {}
  sales_data[theIID][itemIndex].itemIcon = sales_data[theIID][itemIndex].itemIcon or GetItemLinkInfo(eventItemLink)
  sales_data[theIID][itemIndex].itemAdderText = sales_data[theIID][itemIndex].itemAdderText or internal:AddSearchToItem(eventItemLink)
  sales_data[theIID][itemIndex].itemDesc = sales_data[theIID][itemIndex].itemDesc or formattedItemName
  sales_data[theIID][itemIndex].totalCount = sales_data[theIID][itemIndex].totalCount or 0 -- assign count if if new sale
  sales_data[theIID][itemIndex].totalCount = sales_data[theIID][itemIndex].totalCount + 1 -- increment count if existing sale
  sales_data[theIID][itemIndex].wasAltered = true
  sales_data[theIID][itemIndex]['sales'] = sales_data[theIID][itemIndex]['sales'] or {}
  local searchItemDesc = sales_data[theIID][itemIndex].itemDesc -- used for searchText
  local searchItemAdderText = sales_data[theIID][itemIndex].itemAdderText -- used for searchText
  local adderDescConcat = searchItemDesc .. ' ' .. searchItemAdderText

  newEvent.itemLink = linkHash
  newEvent.buyer = buyerHash
  newEvent.seller = sellerHash
  newEvent.guild = guildHash

  local insertedIndex = 1
  local salesTable = sales_data[theIID][itemIndex]['sales']
  local nextLocation = #salesTable + 1
  --[[Note, while salesTable helps readability table.insert() can not insert
  into the local variable]]--
  if salesTable[nextLocation] == nil then
    table.insert(sales_data[theIID][itemIndex]['sales'], nextLocation, newEvent)
    insertedIndex = nextLocation
  else
    table.insert(sales_data[theIID][itemIndex]['sales'], newEvent)
    insertedIndex = #salesTable
  end

  local newestTime = sales_data[theIID][itemIndex]["newestTime"]
  local oldestTime = sales_data[theIID][itemIndex]["oldestTime"]
  if newestTime == nil or newestTime < timestamp then sales_data[theIID][itemIndex]["newestTime"] = timestamp end
  if oldestTime == nil or oldestTime > timestamp then sales_data[theIID][itemIndex]["oldestTime"] = timestamp end

  -- this section adds the sales to the lists for the MM window
  local guildSales = MMGuild:CreateGuildDataMap(internal.guildSales, eventGuild)
  guildSales:addSaleByDate(eventSeller, timestamp, newEvent.price, newEvent.quant, false, nil, nil)

  local guildPurchases = MMGuild:CreateGuildDataMap(internal.guildPurchases, eventGuild)
  guildPurchases:addSaleByDate(eventBuyer, timestamp, newEvent.price, newEvent.quant, newEvent.wasKiosk, nil, nil)

  local guildItems = MMGuild:CreateGuildDataMap(internal.guildItems, eventGuild)
  guildItems:addSaleByDate(eventItemLink, timestamp, newEvent.price, newEvent.quant, false, nil, adderDescConcat)

  local playerName = zo_strlower(GetDisplayName())
  local isSelfSale = playerName == zo_strlower(eventSeller)

  if isSelfSale then
    local guildMyItems = MMGuild:CreateGuildDataMap(internal.myItems, eventGuild)
    guildMyItems:addSaleByDate(eventItemLink, timestamp, newEvent.price, newEvent.quant, false, nil, adderDescConcat)
  end

  local searchText = internal:GenerateSearchText(theEvent, searchItemDesc, searchItemAdderText)
  local searchByWords = zo_strgmatch(searchText, '%S+')
  local wordData = { theIID, itemIndex, insertedIndex }

  -- Index each word
  for i in searchByWords do
    sr_index[i] = sr_index[i] or {}
    table.insert(sr_index[i], wordData)
    internal.sr_index_count = (internal.sr_index_count or 0) + 1
  end

  MasterMerchant.listIsDirty[ITEMS] = true
  MasterMerchant.listIsDirty[GUILDS] = true

  MasterMerchant_Internal:ClearItemCacheById(theIID, itemIndex)

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

-- Helper function to compact a table
function internal:compactTable(t)
  local compacted = {}
  for k, v in pairs(t) do
    if v ~= nil then
      compacted[k] = v
    end
  end
  return compacted
end

function internal:iterateOverSalesData(itemId, versionId, saleId, prefunc, loopfunc, postfunc, extraData)
  extraData.versionCount = (extraData.versionCount or 0)
  extraData.idCount = (extraData.idCount or 0)
  -- local currentFrameRate = GetFramerate()
  -- local clampedFrameRate = zo_max(LibExecutionQueue.frameFpsTarget, zo_min(LibExecutionQueue.UPPER_FPS_BOUND, currentFrameRate))
  -- local dynamicFrameTimeTarget = zo_min(1 / LibExecutionQueue.frameFpsTarget, zo_max(1 / LibExecutionQueue.UPPER_FPS_BOUND, 1 / clampedFrameRate))
  -- extraData.checkMilliseconds = zo_floor(dynamicFrameTimeTarget * 1000) + 1
  extraData.checkMilliseconds = (extraData.checkMilliseconds or MM_WAIT_TIME_IN_MILLISECONDS_DEFAULT)

  if prefunc then
    prefunc(extraData)
  end

  local checkTime = GetGameTimeMilliseconds()
  local versionList
  if itemId == nil then
    itemId, versionList = next(sales_data, nil)
    versionId = nil
  else
    versionList = sales_data[itemId]
  end

  while itemId do
    local versionData
    if versionId == nil then
      versionId, versionData = next(versionList, nil)
      extraData.saleRemoved = false
      saleId = nil
    else
      versionData = versionList[versionId]
    end

    --[[ begin loop over ['x:x:x:x:x'] ]]--
    while versionId do
      --[[ begin loop over ['sales'] ]]--
      if versionData['sales'] then
        local saleData
        if saleId == nil then
          saleId, saleData = next(versionData['sales'], nil)
        else
          saleData = versionData['sales'][saleId]
        end

        while saleId do
          --[[skipTheRest is true here from Truncate Sales because in that function
          you are looping over all the sales. Normally you are not and only processing
          a single sale. Therefore when skipTheRest is false you use:

          saleId, saleData = next(versionData['sales'], saleId)

          to get the next sale and process it
          ]]--
          local skipTheRest = loopfunc(itemId, versionId, versionData, saleId, saleData, extraData)
          extraData.saleRemoved = extraData.saleRemoved or (versionData['sales'][saleId] == nil)

          if skipTheRest then
            saleId = nil
          else
            saleId, saleData = next(versionData['sales'], saleId)
          end

          --[[local saleIdDebugString = string.format("[iterateOverSalesData] Breaking saleId loop: time exceeded '%d' and took '%d' for itemId '%s' but processed %s sales.",
              extraData.checkMilliseconds,
              GetGameTimeMilliseconds() - checkTime,
              tostring(itemId) or "nil itemId",
              extraData.salesProcessed and tostring(extraData.salesProcessed) or "Unassigned Count"
          )]]--

          if saleId and (GetGameTimeMilliseconds() - checkTime > extraData.checkMilliseconds) then
            --LibGuildStore_Internal:dm("Debug", saleIdDebugString)
            --extraData.salesProcessed = 0
            LibExecutionQueue:continueWith(function()
              internal:iterateOverSalesData(itemId, versionId, saleId, nil, loopfunc, postfunc, extraData)
            end, "iterateOverSalesData")
            return
          end
        end
      end
      --[[ end of loop over ['sales'] ]]--

      -- Clean up version data if a sale(s) are removed
      if extraData.saleRemoved and versionData['sales'] and next(versionData['sales']) ~= nil then
        versionData['sales'] = internal:compactTable(versionData['sales'])
        versionData['wasAltered'] = true
      end

      -- Clean up versionList if versionData['sales'] is empty
      local sales = versionData['sales']
      if sales and next(sales) == nil then
        versionList[versionId] = nil
      end

      --[[local debugString = string.format("[iterateOverSalesData] Breaking versionId loop: time exceeded '%d' and took '%d' for itemId '%s' but processed %s sales.",
          extraData.checkMilliseconds,
          GetGameTimeMilliseconds() - checkTime,
          tostring(itemId) or "nil itemId",
          extraData.salesProcessed and tostring(extraData.salesProcessed) or "Unassigned Count"
      )]]--
      -- Move to the next version
      versionId, versionData = next(versionList, versionId)
      saleId = nil

      if versionId and (GetGameTimeMilliseconds() - checkTime) > extraData.checkMilliseconds then
        --LibGuildStore_Internal:dm("Debug", debugString)
        --extraData.salesProcessed = 0
        LibExecutionQueue:continueWith(function()
          internal:iterateOverSalesData(itemId, versionId, saleId, nil, loopfunc, postfunc, extraData)
        end, "iterateOverSalesData")
        return
      end
    end
    --[[ end loop over ['x:x:x:x:x'] ]]--

    local itemData = sales_data[itemId]
    if itemData and next(itemData) == nil then
      sales_data[itemId] = nil
    end

    -- Move to the next item
    itemId, versionList = next(sales_data, itemId)
    versionId = nil
  end

  -- Execute post-processing
  if postfunc then
    postfunc(extraData)
  end
end

----------------------------------------
----- Setup                        -----
----------------------------------------

-- /script LibGuildStore_Internal:TruncateSalesHistory()
function internal:TruncateSalesHistory()
  internal:dm("Debug", "TruncateSalesHistory")

  -- DEBUG  TruncateSalesHistory
  -- do return end LEQ

  local prefunc = function(extraData)
    extraData.start = GetTimeStamp()
    extraData.deleteCount = 0
    extraData.epochBack = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * LibGuildStore_SavedVariables["historyDepth"])
    extraData.wasAltered = false
    extraData.saleRemoved = false
    extraData.minItemCount = LibGuildStore_SavedVariables["minItemCount"]
    extraData.maxItemCount = LibGuildStore_SavedVariables["maxItemCount"]
    extraData.useSalesHistory = LibGuildStore_SavedVariables["useSalesHistory"]
    extraData.useSalesInterval = LibGuildStore_SavedVariables["minSalesInterval"] > 0
    extraData.minSalesInterval = GetTimeStamp() - (LibGuildStore_SavedVariables["minSalesInterval"] * ZO_ONE_DAY_IN_SECONDS)

    internal:DatabaseBusy(true)
  end

  local loopfunc = function(itemId, versionId, versionData, saleId, saleData, extraData)
    local salesDeleted = 0
    local salesDataTable = internal:spairs(versionData['sales'], function(a, b) return internal:CleanTimestamp(a) < internal:CleanTimestamp(b) end)

    for salesId, salesData in salesDataTable do
      local removeSale = false
      local timestamp = salesData['timestamp']
      local invalidTimestamp = not timestamp or type(timestamp) ~= 'number'
      local timestampUnderHistoryRange = timestamp < extraData.epochBack
      local aboveMaximumItemRange = versionData.totalCount > extraData.maxItemCount
      local aboveMinimumItemRange = versionData.totalCount > extraData.minItemCount
      local belowMinimumSalesIntervals = timestamp < extraData.minSalesInterval
      local aboveMinimumSalesInterval = timestamp > extraData.minSalesInterval

      if invalidTimestamp then
        removeSale = true
      elseif extraData.useSalesHistory then
        removeSale = timestampUnderHistoryRange
      elseif extraData.useSalesInterval then
        if belowMinimumSalesIntervals then
          removeSale = false
        elseif aboveMinimumSalesInterval then
          removeSale = aboveMinimumItemRange and (aboveMaximumItemRange or timestampUnderHistoryRange)
        end
      else
        removeSale = aboveMinimumItemRange and (aboveMaximumItemRange or timestampUnderHistoryRange)
      end

      -- Remove it by setting it to nil
      if removeSale then
        versionData['sales'][salesId] = nil
        salesDeleted = salesDeleted + 1
        versionData.totalCount = versionData.totalCount - 1
        extraData.wasAltered = true
      end
    end

    extraData.deleteCount = extraData.deleteCount + salesDeleted
    extraData.saleRemoved = salesDeleted > 0
    --[[ for saleId, saleData in salesDataTable do is not a loop
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
    -- extraData.checkMilliseconds = MM_WAIT_TIME_IN_MILLISECONDS_SHORT
    extraData.indexCount = 0
    extraData.wordsIndexCount = 0
    extraData.wasAltered = false
    internal:DatabaseBusy(true)
  end

  local loopfunc = function(itemId, versionId, versionData, saleId, saleData, extraData)
    extraData.indexCount = extraData.indexCount + 1
    local currentItemLink = internal:GetItemLinkByIndex(saleData['itemLink'])
    local currentGuild = internal:GetGuildNameByIndex(saleData['guild'])
    local currentBuyer = internal:GetAccountNameByIndex(saleData['buyer'])
    local currentSeller = internal:GetAccountNameByIndex(saleData['seller'])

    local playerName = zo_strlower(GetDisplayName())
    local selfSale = playerName == zo_strlower(currentSeller)
    local searchText = ""
    local minimalIndexing = LibGuildStore_SavedVariables["minimalIndexing"]

    if minimalIndexing then
      if selfSale then
        searchText = internal.PlayerSpecialText
      end
    else
      versionData.itemAdderText = versionData.itemAdderText or internal:AddSearchToItem(currentItemLink)
      versionData.itemDesc = versionData.itemDesc or internal:GetFormattedItemLinkName(currentItemLink)
      versionData.itemIcon = versionData.itemIcon or GetItemLinkInfo(currentItemLink)

      -- Build the search elements dynamically
      local searchElements = {}
      if currentBuyer then table.insert(searchElements, 'b' .. currentBuyer) end
      if currentSeller then table.insert(searchElements, 's' .. currentSeller) end
      if currentGuild then table.insert(searchElements, currentGuild) end
      if versionData.itemDesc then table.insert(searchElements, versionData.itemDesc) end
      if versionData.itemAdderText then table.insert(searchElements, versionData.itemAdderText) end
      if selfSale then
        table.insert(searchElements, internal.PlayerSpecialText or '')
      end
      searchText = zo_strlower(table.concat(searchElements, ' '))
    end

    -- Index each word
    local searchByWords = zo_strgmatch(searchText, '%S+')
    local wordData = { itemId, versionId, saleId }
    for i in searchByWords do
      sr_index[i] = sr_index[i] or {}
      table.insert(sr_index[i], wordData)
      extraData.wordsIndexCount = (extraData.wordsIndexCount or 0) + 1
      internal.sr_index_count = (internal.sr_index_count or 0) + 1
    end
    return false  -- value false for return
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

  -- prefunc to define and initialize extraData
  local prefunc = function(extraData)
    extraData.playerName = zo_strlower(GetDisplayName())
    extraData.start = GetTimeStamp()
    extraData.totalRecords = 0
    extraData.wasAltered = false
    -- extraData.checkMilliseconds = MM_WAIT_TIME_IN_MILLISECONDS_SHORT

    internal:DatabaseBusy(true)

    -- Reset all tables to empty
    internal.guildItems = {}
    internal.myItems = {}
    internal.guildSales = {}
    internal.guildPurchases = {}
  end

  -- loopfunc to process each sale
  local loopfunc = function(itemId, versionId, versionData, saleId, saleData, extraData)
    extraData.totalRecords = extraData.totalRecords + 1
    local currentGuild = internal:GetGuildNameByIndex(saleData['guild'])
    if currentGuild then
      local currentSeller = internal:GetAccountNameByIndex(saleData['seller'])
      local currentBuyer = internal:GetAccountNameByIndex(saleData['buyer'])
      local isPlayerSale = zo_strlower(currentSeller) == extraData.playerName

      local _, firstSaleData = next(versionData.sales, nil)
      local firstSaleDataItemLink = internal:GetItemLinkByIndex(firstSaleData.itemLink)
      local searchDataDesc = versionData.itemDesc or zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(firstSaleDataItemLink))
      local searchDataAdder = versionData.itemAdderText or internal:AddSearchToItem(firstSaleDataItemLink)
      local searchData = searchDataDesc .. ' ' .. searchDataAdder

      local guildItems = MMGuild:CreateGuildDataMap(internal.guildItems, currentGuild)
      guildItems:addSaleByDate(firstSaleDataItemLink, saleData.timestamp, saleData.price, saleData.quant, false, false, searchData)

      if isPlayerSale then
        local guildMyItems = MMGuild:CreateGuildDataMap(internal.myItems, currentGuild)
        guildMyItems:addSaleByDate(firstSaleDataItemLink, saleData.timestamp, saleData.price, saleData.quant, false, false, searchData)
      end

      local guildSales = MMGuild:CreateGuildDataMap(internal.guildSales, currentGuild)
      guildSales:addSaleByDate(currentSeller, saleData.timestamp, saleData.price, saleData.quant, false, false, nil)

      local guildPurchases = MMGuild:CreateGuildDataMap(internal.guildPurchases, currentGuild)
      guildPurchases:addSaleByDate(currentBuyer, saleData.timestamp, saleData.price, saleData.quant, saleData.wasKiosk, false, nil)
    end
    return false
  end

  -- postfunc to finalize the process
  local postfunc = function(extraData)
    for _, guild in pairs(internal.guildItems) do
      guild:SortAllRanks()
    end
    for _, guild in pairs(internal.myItems) do
      guild:SortAllRanks()
    end
    for _, guild in pairs(internal.guildSales) do
      guild:SortAllRanks()
    end
    for _, guild in pairs(internal.guildPurchases) do
      guild:SortAllRanks()
    end

    internal:DatabaseBusy(false)

    internal.totalSales = extraData.totalRecords
    if LibGuildStore_SavedVariables["showGuildInitSummary"] then
      internal:dm("Info", string.format(GetString(GS_INIT_SALES_HISTORY_SUMMARY), GetTimeStamp() - extraData.start, internal.totalSales))
    end
  end

  -- Start processing if not busy
  if not internal.isDatabaseBusy then
    internal:iterateOverSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
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
    extraData.eventIdWasString = 0
    extraData.badItemLinkCount = 0
    extraData.wasAltered = false

    internal:DatabaseBusy(true)
  end

  local loopfunc = function(itemId, versionId, versionData, saleId, saleData, extraData)
    --saleData.itemDesc = nil
    --saleData.itemAdderText = nil
    --[[ unlike other loopfunc routines for CleanOutBad we will return false because
    we are processing only one sale under versionData['sales'] so skipTheRest needs to
    be false so that the next saleId is properly assigned.
    ]]--
    local currentItemLink = internal:GetItemLinkByIndex(saleData['itemLink'])
    local currentGuild = internal:GetGuildNameByIndex(saleData['guild'])
    local currentBuyer = internal:GetAccountNameByIndex(saleData['buyer'])
    local currentSeller = internal:GetAccountNameByIndex(saleData['seller'])
    if type(saleData) ~= 'table'
      or saleData['timestamp'] == nil
      or type(saleData['timestamp']) ~= 'number'
      or saleData['timestamp'] < 0
      or saleData['price'] == nil
      or type(saleData['price']) ~= 'number'
      or saleData['quant'] == nil
      or type(saleData['quant']) ~= 'number'
      or saleData['guild'] == nil
      or currentGuild == nil
      or currentBuyer == nil
      or type(currentBuyer) ~= 'string'
      or string.sub(currentBuyer, 1, 1) ~= '@'
      or currentSeller == nil
      or type(currentSeller) ~= 'string'
      or string.sub(currentSeller, 1, 1) ~= '@'
      or saleData['id'] == nil then
      -- Remove it
      if type(currentGuild) ~= 'string' then
        internal:dm("Warn", "currentGuild was not a string")
        internal:dm("Warn", saleData['guild'])
        internal:dm("Warn", currentGuild)
      end

      -- Store removed sales
      GS17DataSavedVariables["removedSales"] = GS17DataSavedVariables["removedSales"] or {}
      GS17DataSavedVariables["removedSales"][itemId] = GS17DataSavedVariables["removedSales"][itemId] or {}
      GS17DataSavedVariables["removedSales"][itemId][versionId] = GS17DataSavedVariables["removedSales"][itemId][versionId] or {}
      table.insert(GS17DataSavedVariables["removedSales"][itemId][versionId], saleData)

      versionData['sales'][saleId] = nil
      extraData.wasAltered = true
      extraData.deleteCount = extraData.deleteCount + 1
      return false  -- value false for return
    end

    local validLink, theIID, itemIdMatch = internal:IsValidItemLink(currentItemLink)
    if not validLink then
      local dataInfo = {
        lang = MasterMerchant.effective_lang,
        individualSale = versionData['sales'][saleId],
        namespace = internal.dataNamespace,
        timestamp = GetTimeStamp(),
        itemLink = currentItemLink,
        theIID = theIID,
        itemIdMatch = itemIdMatch,
        itemLinkLookupValue = saleData['itemLink']
      }
      GS17DataSavedVariables["erroneousLinks"] = GS17DataSavedVariables["erroneousLinks"] or {}
      GS17DataSavedVariables["erroneousLinks"][itemId] = GS17DataSavedVariables["erroneousLinks"][itemId] or {}
      table.insert(GS17DataSavedVariables["erroneousLinks"][itemId], dataInfo)
      -- Remove sale
      versionData['sales'][saleId] = nil
      extraData.wasAltered = true
      extraData.badItemLinkCount = extraData.badItemLinkCount + 1
      return false  -- value false for return
    end

    local newId = GetItemLinkItemId(currentItemLink)
    local newVersion = internal.GetOrCreateIndexFromLink(currentItemLink)
    if type(saleData['id']) == 'string' then
      saleData['id'] = internal:ConvertStringToId64ToEventId(saleData['id'])
      extraData.eventIdWasString = extraData.eventIdWasString + 1
    end
    if ((newId ~= itemId) or (newVersion ~= versionId)) then
      internal:addSalesData(saleData)
      extraData.moveCount = extraData.moveCount + 1
      -- Remove it from its current location
      versionData['sales'][saleId] = nil
      extraData.wasAltered = true
      extraData.deleteCount = extraData.deleteCount + 1
      return false  -- value false for return
    end
    return false  -- value false for return
  end

  local postfunc = function(extraData)

    internal:dm("Info", string.format(GetString(GS_CLEANING_TIME_ELAPSED), GetTimeStamp() - extraData.start))
    internal:dm("Info", string.format(GetString(GS_CLEANING_BAD_REMOVED), (extraData.badItemLinkCount + extraData.deleteCount) - extraData.moveCount))
    internal:dm("Info", string.format(GetString(GS_CLEANING_REINDEXED), extraData.moveCount))
    internal:dm("Info", string.format(GetString(GS_CLEANING_WRONG_VERSION), extraData.versionCount))
    internal:dm("Info", string.format(GetString(GS_CLEANING_WRONG_ID), extraData.idCount))
    internal:dm("Info", string.format(GetString(GS_CLEANING_STRINGS_CONVERTED), extraData.eventIdWasString))
    internal:dm("Info", string.format(GetString(GS_CLEANING_BAD_ITEMLINKS), extraData.badItemLinkCount))

    local LEQ = LibExecutionQueue:new()
    if extraData.deleteCount > 0 then
      internal:dm("Info", GetString(GS_REINDEXING_EVERYTHING))
      --rebuild everything
      local srIndex = {}
      _G["LibGuildStore_SalesIndex"] = srIndex
      internal.sr_index_count = 0

      LEQ:addTask(function() internal:RenewExtraSalesDataAllContainers() end, 'RenewExtraSalesDataAllContainers')
      LEQ:addTask(function() internal:InitSalesHistory() end, 'InitSalesHistory')
      LEQ:addTask(function() internal:IndexSalesData() end, 'indexHistoryTables')
      LEQ:addTask(function() internal:dm("Info", GetString(GS_REINDEXING_COMPLETE)) end, 'Done')
    end

    LEQ:addTask(function()
      internal:DatabaseBusy(false)
    end, '')
    LEQ:start()

  end

  if not internal.isDatabaseBusy then
    internal:iterateOverSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end
end

----------------------------------------
----- PurgeDups                   -----
----------------------------------------

function internal:PurgeDups()
  -- Create the task
  local task = ASYNC:Create("PurgeDups")

  -- Start the purge process
  task:Call(function()
    internal:dm("Info", GetString(GS_PURGING_DUPLICATES))
  end)

  if not internal.isDatabaseBusy then
    task:Call(function() internal:DatabaseBusy(true) end)
    local startTime = GetTimeStamp()
    local totalDuplicates = 0
    local deletedSales = {}
    local deletedCount = 0

    -- List of all segmented data tables
    local allTables = {
      GS00DataSavedVariables, GS01DataSavedVariables, GS02DataSavedVariables,
      GS03DataSavedVariables, GS04DataSavedVariables, GS05DataSavedVariables,
      GS06DataSavedVariables, GS07DataSavedVariables, GS08DataSavedVariables,
      GS09DataSavedVariables, GS10DataSavedVariables, GS11DataSavedVariables,
      GS12DataSavedVariables, GS13DataSavedVariables, GS14DataSavedVariables,
      GS15DataSavedVariables,
    }

    -- Loop through sales_data by itemId
    task:For(pairs(sales_data)):Do(function(itemId, _)
      local seenEventIds = {}  -- Reset for each itemId

      -- Check across all files for the current itemId
      for _, tableData in ipairs(allTables) do
        local savedVars = tableData[internal.dataNamespace]
        if savedVars and savedVars[itemId] then
          for versionId, versionData in pairs(savedVars[itemId]) do
            if versionData["sales"] then
              local validSales = {}
              local validCount = 0

              for saleId, saleData in pairs(versionData["sales"]) do
                local isDuplicate = saleData.id == nil or seenEventIds[saleData.id]

                if isDuplicate then
                  deletedCount = deletedCount + 1
                  deletedSales[deletedCount] = saleData
                  totalDuplicates = totalDuplicates + 1
                else
                  validCount = validCount + 1
                  validSales[validCount] = saleData
                  seenEventIds[saleData.id] = true
                end
              end

              -- Update versionData sales
              savedVars[itemId][versionId]["sales"] = validSales
            end
          end
        end
      end
    end)

    -- Clear temporary data after processing
    task:Then(function()
      GS16DataSavedVariables["deletedSales"] = deletedSales
    end)

    -- Final cleanup and reindexing
    task:Finally(function()
      if totalDuplicates > 0 then
        -- Rebuild everything
        sr_index = {}
        _G["LibGuildStore_SalesIndex"] = sr_index
        internal.sr_index_count = 0

        internal:InitSalesHistory()
        internal:IndexSalesData()
      end

      internal:DatabaseBusy(false)
      internal:dm("Info", string.format(GetString(GS_DUP_PURGE), GetTimeStamp() - startTime, totalDuplicates))
      internal:dm("Info", GetString(GS_REINDEXING_COMPLETE))
    end)
  end
end

----------------------------------------
----- RenameItemDescriptionss      -----
----------------------------------------

function internal:RenameItemDescriptions()
  local preFunc = function(extraData)
    extraData.start = GetTimeStamp()
    extraData.renameCount = 0 -- Tracks the number of renames

    internal:DatabaseBusy(true)
  end

  local loopFunc = function(itemId, versionId, versionData, saleId, saleData, extraData)
    -- Ensure we have a valid itemLink to process
    local itemLink = internal:GetItemLinkByIndex(saleData["itemLink"])
    if itemLink then
      versionData["itemAdderText"] = internal:AddSearchToItem(itemLink)
      versionData["itemDesc"] = internal:GetFormattedItemLinkName(itemLink)
      extraData.renameCount = extraData.renameCount + 1
      return true -- Skip remaining sales for this versionId
    end
    return false -- Continue if itemLink is not valid (unlikely in this case)
  end

  local postFunc = function(extraData)
    internal:dm("Info", string.format(GetString(GS_SLIDING_SUMMARY), GetTimeStamp() - extraData.start, extraData.renameCount))
    internal:DatabaseBusy(false)
  end

  if not internal.isDatabaseBusy then
    internal:iterateOverSalesData(nil, nil, nil, preFunc, loopFunc, postFunc, {})
  end
end

----------------------------------------
----- SlideSales                   -----
----------------------------------------

function internal:SlideSales(goBack)

  local preFunc = function(extraData)
    extraData.start = GetTimeStamp()
    extraData.moveCount = 0
    extraData.wasAltered = false
    extraData.oldName = GetDisplayName()
    extraData.newName = extraData.oldName .. 'Slid'

    if goBack then extraData.oldName, extraData.newName = extraData.newName, extraData.oldName end

    internal:DatabaseBusy(true)
  end

  local loopFunc = function(itemId, versionId, versionData, saleId, saleData, extraData)
    if saleData['seller'] == extraData.oldName then
      saleData['seller'] = extraData.newName
      extraData.moveCount = extraData.moveCount + 1
    end
    return false  -- value false for return
  end

  local postFunc = function(extraData)
    internal:dm("Info", string.format(GetString(GS_SLIDING_SUMMARY), GetTimeStamp() - extraData.start, extraData.moveCount, extraData.newName))
    sr_index[internal.PlayerSpecialText] = {}
    internal:DatabaseBusy(false)
  end

  if not internal.isDatabaseBusy then
    internal:iterateOverSalesData(nil, nil, nil, preFunc, loopFunc, postFunc, {})
  end
end

-- ReferenceSales: Merge and update sales data from different versions
-- of saved variables into a unified sales_data table.
-- @param otherData: A table containing sales data from different versions
function internal:ReferenceSales(otherData)
  local savedVars = otherData[internal.dataNamespace]

  for itemId, versionList in pairs(savedVars) do
    if not sales_data[itemId] and next(versionList) then
      sales_data[itemId] = versionList
    else
      for versionId, versionData in pairs(versionList) do
        local hasSales = versionData and versionData["sales"]
        if hasSales then
          local oldestTime, newestTime = nil, nil

          for saleId, saleData in pairs(versionData["sales"]) do
            if type(saleId) == "number" and type(saleData) == "table" and type(saleData["timestamp"]) == "number" then
              sales_data[itemId][versionId] = sales_data[itemId][versionId] or {}
              sales_data[itemId][versionId]["sales"] = sales_data[itemId][versionId]["sales"] or {}
              table.insert(sales_data[itemId][versionId]["sales"], saleData)
            end
          end

          for _, saleData in pairs(sales_data[itemId][versionId]["sales"]) do
            if oldestTime == nil or oldestTime > saleData.timestamp then oldestTime = saleData.timestamp end
            if newestTime == nil or newestTime < saleData.timestamp then newestTime = saleData.timestamp end
          end

          sales_data[itemId][versionId].totalCount = NonContiguousCount(sales_data[itemId][versionId]["sales"])
          sales_data[itemId][versionId].wasAltered = true
          sales_data[itemId][versionId].oldestTime = oldestTime
          sales_data[itemId][versionId].newestTime = newestTime

          savedVars[itemId][versionId] = nil
        end
      end
      local hasVersionId = savedVars and savedVars[itemId] and next(savedVars[itemId])
      if not hasVersionId then savedVars[itemId] = nil end
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
    [11] = GS11DataSavedVariables,
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

-- /script LibGuildStore_Internal:ParseLibDebugLoggerLog()
function internal:ParseLibDebugLoggerLog()
  -- Create a new task using LibAsync to handle parsing
  local task = LibAsync:Create("ParseLibDebugLoggerLog")

  -- Create a new table to hold the parsed logs
  LibDebugLoggerLog["parsedLogs"] = {}

  -- Initialize the counter
  local i = 1

  -- Use a LibAsync loop to process each log entry
  task:For(pairs(LibDebugLoggerLog)):Do(function(key, value)
    -- Ensure the value is a table and contains the 6th element
    if type(value) == "table" and value[6] then
      -- Store the message in the parsedLogs table
      LibDebugLoggerLog["parsedLogs"][i] = value[6]
      i = i + 1
    end
  end):Then(function()
    -- Completion message
    d("[ParseLibDebugLoggerLog] Finished parsing logs.")
  end)
end

