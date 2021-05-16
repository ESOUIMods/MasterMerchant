local lib            = _G["LibGuildStore"]
local internal       = _G["LibGuildStore_Internal"]
local sales_data     = _G["LibGuildStore_SalesData"]
local listings_data  = _G["LibGuildStore_ListingsData"]
local sr_index       = _G["LibGuildStore_SalesIndex"]
local att_sales_data = _G["LibGuildStore_ATT_SalesData"]
local ASYNC          = LibAsync
local LGH            = LibHistoire

--[[ This file contains all instances of functions that utilize
iterateOverSalesData.
]]--

----------------------------------------
----- Helpers                      -----
----------------------------------------

-- /script LibGuildStore_Internal:CompareSalesIds(GS00DataSavedVariables)
-- loops over item IDs and reports duplicates
function internal:CompareSalesIds()
  internal:dm("Debug", "CompareSalesIds")
  local mmsaveData = dataset[internal.dataNamespace]
  local itemIds    = {}
  for itemID, itemData in pairs(att_sales_data) do
    for itemIndex, itemIndexData in pairs(itemData) do
      for key, sale in pairs(itemIndexData['sales']) do
        if not itemIds[sale.id] then
          itemIds[sale.id] = true
        else
          internal:dm("Debug", "Duplicate ID")
        end
      end
    end
  end
  internal:dm("Debug", "CompareSalesIds Done")
end

-- /script LibGuildStore_Internal:CompareItemIds(GS00DataSavedVariables)
-- loops over item IDs and reports duplicates
function internal:CompareItemIds(dataset)
  internal:dm("Debug", "CompareItemIds")
  local saveData = dataset[internal.dataNamespace]
  local itemIds  = {}
  for itemID, itemData in pairs(saveData) do
    for itemIndex, itemIndexData in pairs(itemData) do
      for key, sale in pairs(itemIndexData['sales']) do
        if not itemIds[sale.id] then
          itemIds[sale.id] = true
        else
          internal:dm("Debug", "Duplicate ID")
        end
      end
    end
  end
  internal:dm("Debug", "CompareItemIds Done")
end

function internal:NonContiguousNonNilCount(tableObject)
  local count = 0

  for _, v in pairs(tableObject) do
    if v ~= nil then count = count + 1 end
  end

  return count
end

function internal:CleanTimestamp(salesRecord)
  if (salesRecord == nil) or (salesRecord.timestamp == nil) or (type(salesRecord.timestamp) ~= 'number') then return 0 end
  return salesRecord.timestamp
end

function internal:spairs(t, order)
  -- all the indexes
  local indexes = {}
  for k in pairs(t) do indexes[#indexes + 1] = k end

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

function internal:IsValidItemLink(itemLink)
  -- itemLink should be the full link here
  local validLink = true
  local _, count  = string.gsub(itemLink, ':', ':')
  if count ~= 22 then
    internal:dm("Debug", "count ~= 22")
    validLink = false
  end
  local theIID      = GetItemLinkItemId(itemLink)
  local itemIdMatch = tonumber(string.match(itemLink, '|H.-:item:(.-):'))
  if not theIID then
    internal:dm("Debug", "theIID was nil I guess?")
    validLink = false
  end
  if theIID and (theIID ~= itemIdMatch) then
    validLink = false
    internal:dm("Debug", "theIID ~= itemIdMatch")
  end
  local itemlinkName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink))
  if internal:is_empty_or_nil(itemlinkName) then
    internal:dm("Debug", "itemlinkName was empty or nil")
    validLink = false
  end
  if not validLink then
    internal:dm("Debug", MasterMerchant.ItemCodeText(itemLink))
  end
  return validLink
end

----------------------------------------
----- iterateOverSalesData         -----
----------------------------------------

function internal:iterateOverSalesData(itemid, versionid, saleid, prefunc, loopfunc, postfunc, extraData)
  extraData.versionCount      = (extraData.versionCount or 0)
  extraData.idCount           = (extraData.idCount or 0)
  extraData.checkMilliseconds = (extraData.checkMilliseconds or 20)

  if prefunc then
    prefunc(extraData)
  end

  local checkTime = GetGameTimeMilliseconds()
  local versionlist
  if itemid == nil then
    itemid, versionlist      = next(sales_data, itemid)
    extraData.versionRemoved = false
    versionid                = nil
  else
    versionlist = sales_data[itemid]
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
          local skipTheRest     = loopfunc(itemid, versionid, versiondata, saleid, saledata, extraData)
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
      if (versionlist[versionid] ~= nil and ((versiondata['sales'] == nil) or (internal:NonContiguousNonNilCount(versiondata['sales']) < 1) or (not string.match(tostring(versionid),
        "^%d+:%d+:%d+:%d+:%d+")))) then
        extraData.versionCount   = (extraData.versionCount or 0) + 1
        versionlist[versionid]   = nil
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
          itemLink = internal:GetStringByIndex(internal.GS_CHECK_ITEMLINK, itemData["itemLink"])
          if itemLink then
            versiondata['itemAdderText'] = internal:AddSearchToItem(itemLink)
            versiondata['itemDesc']      = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink))
          end
        end
      end
      if extraData.wasAltered then
        versiondata["wasAltered"] = true
        extraData.wasAltered      = false
      end
      -- Go onto the next Version
      versionid, versiondata = next(versionlist, versionid)
      extraData.saleRemoved  = false
      saleid                 = nil
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
      extraData.idCount  = (extraData.idCount or 0) + 1
      sales_data[itemid] = nil
    end

    -- Go on to the next Item
    itemid, versionlist      = next(sales_data, itemid)
    extraData.versionRemoved = false
    versionid                = nil
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
function internal:TruncateHistory()
  internal:dm("Debug", "TruncateHistory")

  -- DEBUG  TruncateHistory
  -- do return end

  local prefunc  = function(extraData)
    extraData.start       = GetTimeStamp()
    extraData.deleteCount = 0
    extraData.epochBack   = GetTimeStamp() - (86400 * LibGuildStore_SavedVariables["historyDepth"])
    extraData.wasAltered  = false

    internal:DatabaseBusy(true)
  end

  local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData)

    local salesDeleted   = 0
    salesCount           = versiondata.totalCount
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
          salesDeleted                 = salesDeleted + 1
          extraData.wasAltered         = true
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
          salesDeleted                 = salesDeleted + 1
          salesCount                   = salesCount - 1
          extraData.wasAltered         = true
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
    internal:dm("Info",
      string.format(GetString(GS_TRUNCATE_COMPLETE), GetTimeStamp() - extraData.start, extraData.deleteCount))
  end

  if not internal.isDatabaseBusy then
    internal:iterateOverSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

end

-- TODO is sr_index important here
function internal:InitItemHistory()
  internal:dm("Info", GetString(GS_INIT_ITEM_HISTORY))

  local extradata = {}

  if internal.guildItems == nil then
    internal.guildItems    = {}
    extradata.doGuildItems = true
  end

  if internal.myItems == nil then
    internal.myItems     = {}
    extradata.doMyItems  = true
    extradata.playerName = string.lower(GetDisplayName())
  end

  if internal.guildSales == nil then
    internal.guildSales    = {}
    extradata.doGuildSales = true
  end

  if internal.guildPurchases == nil then
    internal.guildPurchases    = {}
    extradata.doGuildPurchases = true
  end

  if (extradata.doGuildItems or extradata.doMyItems or extradata.doGuildSales or extradata.doGuildPurchases) then

    local prefunc  = function(extraData)
      extraData.start = GetTimeStamp()
      internal:DatabaseBusy(true)
      extraData.totalRecords = 0
      extraData.wasAltered   = false
    end

    local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData)
      extraData.totalRecords = extraData.totalRecords + 1
      if (not (saledata == {})) and saledata.guild then
        local currentGuild  = internal:GetStringByIndex(internal.GS_CHECK_GUILDNAME, saledata['guild'])
        local currentSeller = internal:GetStringByIndex(internal.GS_CHECK_ACCOUNTNAME, saledata['seller'])
        local currentBuyer  = internal:GetStringByIndex(internal.GS_CHECK_ACCOUNTNAME, saledata['buyer'])

        if (extradata.doGuildItems) then
          internal.guildItems[currentGuild] = internal.guildItems[currentGuild] or MMGuild:new(currentGuild)
          local guild                       = internal.guildItems[currentGuild]
          local _, firstsaledata            = next(versiondata.sales, nil)
          local firstsaledataItemLink       = internal:GetStringByIndex(internal.GS_CHECK_ITEMLINK,
            firstsaledata.itemLink)
          local searchDataDesc              = versiondata.itemDesc or zo_strformat(SI_TOOLTIP_ITEM_NAME,
            GetItemLinkName(firstsaledataItemLink))
          local searchDataAdder             = versiondata.itemAdderText or internal:AddSearchToItem(firstsaledataItemLink)
          local searchData                  = searchDataDesc .. ' ' .. searchDataAdder
          guild:addSaleByDate(firstsaledataItemLink, saledata.timestamp, saledata.price, saledata.quant, false, false,
            searchData)
        end

        if (extradata.doMyItems and string.lower(currentSeller) == extradata.playerName) then
          internal.myItems[currentGuild] = internal.myItems[currentGuild] or MMGuild:new(currentGuild)
          local guild                    = internal.myItems[currentGuild]
          local _, firstsaledata         = next(versiondata.sales, nil)
          local firstsaledataItemLink    = internal:GetStringByIndex(internal.GS_CHECK_ITEMLINK, firstsaledata.itemLink)
          local searchDataDesc           = versiondata.itemDesc or zo_strformat(SI_TOOLTIP_ITEM_NAME,
            GetItemLinkName(firstsaledataItemLink))
          local searchDataAdder          = versiondata.itemAdderText or internal:AddSearchToItem(firstsaledataItemLink)
          local searchData               = searchDataDesc .. ' ' .. searchDataAdder
          guild:addSaleByDate(firstsaledataItemLink, saledata.timestamp, saledata.price, saledata.quant, false, false,
            searchData)
        end

        if (extradata.doGuildSales) then
          internal.guildSales[currentGuild] = internal.guildSales[currentGuild] or MMGuild:new(currentGuild)
          local guild                       = internal.guildSales[currentGuild]
          guild:addSaleByDate(currentSeller, saledata.timestamp, saledata.price, saledata.quant, false, false)
        end

        if (extradata.doGuildPurchases) then
          internal.guildPurchases[currentGuild] = internal.guildPurchases[currentGuild] or MMGuild:new(currentGuild)
          local guild                           = internal.guildPurchases[currentGuild]
          guild:addSaleByDate(currentBuyer, saledata.timestamp, saledata.price, saledata.quant, saledata.wasKiosk,
            false)
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

      internal.totalRecords = extraData.totalRecords
      if LibGuildStore_SavedVariables["showGuildInitSummary"] then
        internal:dm("Info", string.format(GetString(GS_INIT_ITEM_HISTORY_SUMMARY), GetTimeStamp() - extraData.start,
          internal.totalRecords))
      end
    end

    if not internal.isDatabaseBusy then
      internal:iterateOverSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, extradata)
    end

  end
end

-- For faster searching of large histories, we'll maintain an inverted
-- index of search terms - here we build the indexes from the existing table
function internal:indexHistoryTables()

  -- DEBUG  Stop Indexing
  --do return end

  local prefunc    = function(extraData)
    if LibGuildStore_SavedVariables["minimalIndexing"] then
      internal:dm("Info", GetString(GS_MINIMAL_INDEXING))
    else
      internal:dm("Info", GetString(GS_FULL_INDEXING))
    end
    extraData.start             = GetTimeStamp()
    extraData.checkMilliseconds = 60
    extraData.indexCount        = 0
    extraData.wordsIndexCount   = 0
    extraData.wasAltered        = false
    internal:DatabaseBusy(true)
  end

  local temp       = { 'b', '', ' s', '', ' ', '', ' ', '', ' ', '', ' ', '' }
  local playerName = string.lower(GetDisplayName())

  local loopfunc   = function(numberID, itemData, versiondata, itemIndex, soldItem, extraData)

    extraData.indexCount  = extraData.indexCount + 1

    local searchText
    local currentItemLink = internal:GetStringByIndex(internal.GS_CHECK_ITEMLINK, soldItem['itemLink'])
    local currentGuild    = internal:GetStringByIndex(internal.GS_CHECK_GUILDNAME, soldItem['guild'])
    local currentBuyer    = internal:GetStringByIndex(internal.GS_CHECK_ACCOUNTNAME, soldItem['buyer'])
    local currentSeller   = internal:GetStringByIndex(internal.GS_CHECK_ACCOUNTNAME, soldItem['seller'])

    if LibGuildStore_SavedVariables["minimalIndexing"] then
      if playerName == string.lower(currentSeller) then
        searchText = string.lower(internal.PlayerSpecialText)
      else
        searchText = ''
      end
    else
      versiondata.itemAdderText = versiondata.itemAdderText or internal:AddSearchToItem(currentItemLink)
      versiondata.itemDesc      = versiondata.itemDesc or zo_strformat(SI_TOOLTIP_ITEM_NAME,
        GetItemLinkName(currentItemLink))
      versiondata.itemIcon      = versiondata.itemIcon or GetItemLinkInfo(currentItemLink)

      temp[2]                   = currentBuyer or ''
      temp[4]                   = currentSeller or ''
      temp[6]                   = currentGuild or ''
      temp[8]                   = versiondata.itemDesc or ''
      temp[10]                  = versiondata.itemAdderText or ''
      if playerName == string.lower(currentSeller) then
        temp[12] = internal.PlayerSpecialText
      else
        temp[12] = ''
      end
      searchText = string.lower(table.concat(temp, ''))
    end

    -- Index each word
    local searchByWords = string.gmatch(searchText, '%S+')
    local wordData      = { numberID, itemData, itemIndex }
    for i in searchByWords do
      if sr_index[i] == nil then
        extraData.wordsIndexCount = extraData.wordsIndexCount + 1
        sr_index[i]               = {}
      end
      table.insert(sr_index[i], wordData)
    end

  end

  local postfunc   = function(extraData)
    internal:DatabaseBusy(false)
    if LibGuildStore_SavedVariables["showGuildInitSummary"] then
      internal:dm("Info",
        string.format(GetString(GS_INDEXING_SUMMARY), GetTimeStamp() - extraData.start, extraData.indexCount,
          extraData.wordsIndexCount))
    end
  end

  if not internal.isDatabaseBusy then
    internal:iterateOverSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

end

----------------------------------------
----- CleanOutBad                  -----
----------------------------------------

function internal:CleanOutBad()
  internal:dm("Debug", "CleanOutBad")

  local prefunc  = function(extraData)
    extraData.start             = GetTimeStamp()
    extraData.moveCount         = 0
    extraData.deleteCount       = 0
    extraData.checkMilliseconds = 120
    extraData.eventIdIsNumber   = 0
    extraData.badItemLinkCount  = 0
    extraData.wasAltered        = false

    internal:DatabaseBusy(true)
    if LibGuildStore_SavedVariables["updateAdditionalText"] then
      internal:dm("Debug", "Description Text Will be updated")
    end
  end

  local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData)
    --saledata.itemDesc = nil
    --saledata.itemAdderText = nil

    local currentItemLink = internal:GetStringByIndex(internal.GS_CHECK_ITEMLINK, saledata['itemLink'])
    local currentGuild    = internal:GetStringByIndex(internal.GS_CHECK_GUILDNAME, saledata['guild'])
    local currentBuyer    = internal:GetStringByIndex(internal.GS_CHECK_ACCOUNTNAME, saledata['buyer'])
    local currentSeller   = internal:GetStringByIndex(internal.GS_CHECK_ACCOUNTNAME, saledata['seller'])
    if type(saledata) ~= 'table'
      or saledata['timestamp'] == nil
      or type(saledata['timestamp']) ~= 'number'
      or saledata['timestamp'] < 0
      or saledata['price'] == nil
      or type(saledata['price']) ~= 'number'
      or saledata['quant'] == nil
      or type(saledata['quant']) ~= 'number'
      or currentGuild == nil
      or currentBuyer == nil
      or type(currentBuyer) ~= 'string'
      or string.sub(currentBuyer, 1, 1) ~= '@'
      or currentSeller == nil
      or type(currentSeller) ~= 'string'
      or string.sub(currentSeller, 1, 1) ~= '@'
      or saledata['id'] == nil then
      -- Remove it
      versiondata['sales'][saleid] = nil
      extraData.wasAltered         = true
      extraData.deleteCount        = extraData.deleteCount + 1
      return
    end
    local key, count   = string.gsub(currentItemLink, ':', ':')
    local theIID       = GetItemLinkItemId(currentItemLink)
    local itemIdMatch  = tonumber(string.match(currentItemLink, '|H.-:item:(.-):'))
    local itemlinkName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(currentItemLink))
    --[[
    if LibGuildStore_SavedVariables["updateAdditionalText"] then
      local itemIndex = internal:MakeIndexFromLink(currentItemLink)
      sales_data[theIID][itemIndex]['itemAdderText'] = internal:AddSearchToItem(currentItemLink)
      sales_data[theIID][itemIndex]['itemDesc'] = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(currentItemLink))
    end
    ]]--
    -- /script internal:dm("Debug", zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName("|H0:item:69354:363:50:0:0:0:0:0:0:0:0:0:0:0:0:19:0:0:0:0:0|h|h")))
    -- /script internal:dm("Debug", internal:AddSearchToItem("|H0:item:69354:363:50:0:0:0:0:0:0:0:0:0:0:0:0:19:0:0:0:0:0|h|h"))
    if not internal:IsValidItemLink(currentItemLink) then
      -- Remove it
      versiondata['sales'][saleid] = nil
      extraData.wasAltered         = true
      extraData.badItemLinkCount   = extraData.badItemLinkCount + 1
      return
    end
    local newid      = GetItemLinkItemId(currentItemLink)
    local newversion = internal:MakeIndexFromLink(currentItemLink)
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
      internal:addToHistoryTables(theEvent)
      extraData.moveCount          = extraData.moveCount + 1
      -- Remove it from it's current location
      versiondata['sales'][saleid] = nil
      extraData.wasAltered         = true
      extraData.deleteCount        = extraData.deleteCount + 1
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
      local sr_index                 = {}
      _G["LibGuildStore_SalesIndex"] = sr_index

      internal.guildPurchases        = {}
      internal.guildSales            = {}
      internal.guildItems            = {}
      internal.myItems               = {}
      LEQ:Add(function() internal:RenewExtraDataAllContainers() end, 'RenewExtraDataAllContainers')
      LEQ:Add(function() internal:InitItemHistory() end, 'InitItemHistory')
      LEQ:Add(function() internal:indexHistoryTables() end, 'indexHistoryTables')
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
    local sr_index                 = {}
    _G["LibGuildStore_SalesIndex"] = sr_index

    internal.guildPurchases        = {}
    internal.guildSales            = {}
    internal.guildItems            = {}
    internal.myItems               = {}
    LEQ:Add(function() internal:InitItemHistory() end, 'InitItemHistory')
    LEQ:Add(function() internal:indexHistoryTables() end, 'indexHistoryTables')
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

    local start        = GetTimeStamp()
    local eventArray   = { }
    local count        = 0
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
            local currentItemLink = internal:GetStringByIndex(internal.GS_CHECK_ITEMLINK, checking.itemLink)
            local validLink       = internal:IsValidItemLink(currentItemLink)
            dup                   = false
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
    eventArray                             = {} -- clear array
    GS16DataSavedVariables["deletedSales"] = deletedSales
    task:Then(function(task) internal:dm("Info",
      string.format(GetString(GS_DUP_PURGE), GetTimeStamp() - start, count)) end)
    task:Then(function(task) internal:dm("Info", GetString(GS_REINDEXING_EVERYTHING)) end)
    task:Finally(function(task) FinalizePurge(count) end)
  end
end

----------------------------------------
----- SlideSales                   -----
----------------------------------------

function internal:SlideSales(goback)

  local prefunc  = function(extraData)
    extraData.start      = GetTimeStamp()
    extraData.moveCount  = 0
    extraData.wasAltered = false
    extraData.oldName    = GetDisplayName()
    extraData.newName    = extraData.oldName .. 'Slid'
    if extraData.oldName == '@kindredspiritgr' then extraData.newName = '@kindredthesexybiotch' end

    if goback then extraData.oldName, extraData.newName = extraData.newName, extraData.oldName end

    internal:DatabaseBusy(true)
  end

  local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData)
    if saledata['seller'] == extraData.oldName then
      saledata['seller']  = extraData.newName
      extraData.moveCount = extraData.moveCount + 1
    end
  end

  local postfunc = function(extraData)

    internal:dm("Info",
      string.format(GetString(GS_SLIDING_SUMMARY), GetTimeStamp() - extraData.start, extraData.moveCount,
        extraData.newName))
    sr_index[internal.PlayerSpecialText] = {}
    internal:DatabaseBusy(false)

  end

  if not internal.isDatabaseBusy then
    internal:iterateOverSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

end

----------------------------------------
----- Functions                    -----
----------------------------------------
-- TODO No idea what to name this section

function internal:ReferenceSales(otherData)
  local savedVars = otherData[internal.dataNamespace]

  for itemid, versionlist in pairs(savedVars) do
    if sales_data[itemid] then
      for versionid, versiondata in pairs(versionlist) do
        if sales_data[itemid][versionid] then
          if versiondata.sales then
            sales_data[itemid][versionid].sales = sales_data[itemid][versionid].sales or {}
            -- IPAIRS
            for saleid, saledata in pairs(versiondata.sales) do
              if (type(saleid) == 'number' and type(saledata) == 'table' and type(saledata.timestamp) == 'number') then
                table.insert(sales_data[itemid][versionid].sales, saledata)
              end
            end
            local _, first = next(versiondata.sales, nil)
            if first then
              sales_data[itemid][versionid].itemIcon      = GetItemLinkInfo(first.itemLink)
              sales_data[itemid][versionid].itemAdderText = internal:AddSearchToItem(first.itemLink)
              sales_data[itemid][versionid].itemDesc      = zo_strformat(SI_TOOLTIP_ITEM_NAME,
                GetItemLinkName(first.itemLink))
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

function internal:RenewExtraData(otherData)
  local savedVars = otherData[internal.dataNamespace]

  for itemID, itemIndex in pairs(savedVars) do
    for field, itemIndexData in pairs(itemIndex) do
      if itemIndexData.wasAltered then
        local oldestTime = nil
        local totalCount = 0
        for sale, saleData in pairs(itemIndexData['sales']) do
          totalCount = totalCount + 1
          if oldestTime == nil or oldestTime > saleData.timestamp then oldestTime = saleData.timestamp end
        end
        if savedVars[itemID][field] then
          savedVars[itemID][field].totalCount = totalCount
          savedVars[itemID][field].oldestTime = oldestTime
          savedVars[itemID][field].wasAltered = false
        else
          --internal:dm("Warn", "Empty or nil savedVars[internal.dataNamespace]")
        end
      end
    end
  end
end

function internal:VerifyItemLinks(hash, task)
  local saveFile   = _G[string.format("GS%02dDataSavedVariables", hash)]
  local fileString = string.format("GS%02dDataSavedVariables", hash)
  task:Then(function(task) internal:dm("Debug", string.format("VerifyItemLinks for: %s", fileString)) end)
  task:Then(function(task) internal:dm("Debug", hash) end)
  local savedVars = saveFile[internal.dataNamespace]

  task:For(pairs(savedVars)):Do(function(itemID, itemIndex)
    task:For(pairs(itemIndex)):Do(function(field, itemIndexData)
      task:For(pairs(itemIndexData['sales'])):Do(function(sale, saleData)
        local currentLink = internal:GetStringByIndex(internal.GS_CHECK_ITEMLINK, saleData.itemLink)
        local currentHash = internal:MakeHashString(currentLink)
        if currentHash ~= hash then
          task:Then(function(task) internal:dm("Debug", "sale in wrong file") end)
        end
      end)
    end)
  end)
end

function internal:AddNewData(otherData)
  local savedVars = otherData[internal.dataNamespace]

  for itemID, itemIndex in pairs(savedVars) do
    for field, itemIndexData in pairs(itemIndex) do
      local oldestTime = nil
      local totalCount = 0
      for sale, saleData in pairs(itemIndexData['sales']) do
        totalCount = totalCount + 1
        if saleData.timestamp then
          if oldestTime == nil or oldestTime > saleData.timestamp then oldestTime = saleData.timestamp end
        else
          if internal:is_empty_or_nil(saleData) then
            internal:dm("Warn", "Empty Table Detected!")
            internal:dm("Warn", itemID)
            internal:dm("Warn", sale)
            itemIndexData['sales'][sale] = nil
          end
        end
      end
      if savedVars[itemID][field] then
        savedVars[itemID][field].totalCount = totalCount
        savedVars[itemID][field].oldestTime = oldestTime
        savedVars[itemID][field].wasAltered = false
      else
        --internal:dm("Warn", "Empty or nil savedVars[internal.dataNamespace]")
      end
    end
  end
end

-- Bring seperate lists together we can still access the sales history all together
function internal:ReferenceSalesAllContainers()
  internal:dm("Debug", "Bring LibGuildStore data together")
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

-- Renew extra data if list was altered
function internal:RenewExtraDataAllContainers()
  internal:dm("Debug", "Add new data to LibGuildStore concatanated data array")
  internal:RenewExtraData(GS00DataSavedVariables)
  internal:RenewExtraData(GS01DataSavedVariables)
  internal:RenewExtraData(GS02DataSavedVariables)
  internal:RenewExtraData(GS03DataSavedVariables)
  internal:RenewExtraData(GS04DataSavedVariables)
  internal:RenewExtraData(GS05DataSavedVariables)
  internal:RenewExtraData(GS06DataSavedVariables)
  internal:RenewExtraData(GS07DataSavedVariables)
  internal:RenewExtraData(GS08DataSavedVariables)
  internal:RenewExtraData(GS09DataSavedVariables)
  internal:RenewExtraData(GS10DataSavedVariables)
  internal:RenewExtraData(GS11DataSavedVariables)
  internal:RenewExtraData(GS12DataSavedVariables)
  internal:RenewExtraData(GS13DataSavedVariables)
  internal:RenewExtraData(GS14DataSavedVariables)
  internal:RenewExtraData(GS15DataSavedVariables)
end

-- Add new data to concatanated data array
function internal:AddNewDataAllContainers()
  internal:dm("Debug", "Add new data to concatanated data array")
  internal:AddNewData(GS00DataSavedVariables)
  internal:AddNewData(GS01DataSavedVariables)
  internal:AddNewData(GS02DataSavedVariables)
  internal:AddNewData(GS03DataSavedVariables)
  internal:AddNewData(GS04DataSavedVariables)
  internal:AddNewData(GS05DataSavedVariables)
  internal:AddNewData(GS06DataSavedVariables)
  internal:AddNewData(GS07DataSavedVariables)
  internal:AddNewData(GS08DataSavedVariables)
  internal:AddNewData(GS09DataSavedVariables)
  internal:AddNewData(GS10DataSavedVariables)
  internal:AddNewData(GS11DataSavedVariables)
  internal:AddNewData(GS12DataSavedVariables)
  internal:AddNewData(GS13DataSavedVariables)
  internal:AddNewData(GS14DataSavedVariables)
  internal:AddNewData(GS15DataSavedVariables)
end

-- Add new data to concatanated data array
-- /script LibGuildStore_Internal:VerifyAllItemLinks()
function internal:VerifyAllItemLinks()
  local task = ASYNC:Create("VerifyAllItemLinks")
  task:Call(function(task) internal:DatabaseBusy(true) end)
      :Then(function(task) internal:VerifyItemLinks(00, task) end)
      :Then(function(task) internal:VerifyItemLinks(01, task) end)
      :Then(function(task) internal:VerifyItemLinks(02, task) end)
      :Then(function(task) internal:VerifyItemLinks(03, task) end)
      :Then(function(task) internal:VerifyItemLinks(04, task) end)
      :Then(function(task) internal:VerifyItemLinks(05, task) end)
      :Then(function(task) internal:VerifyItemLinks(06, task) end)
      :Then(function(task) internal:VerifyItemLinks(07, task) end)
      :Then(function(task) internal:VerifyItemLinks(08, task) end)
      :Then(function(task) internal:VerifyItemLinks(09, task) end)
      :Then(function(task) internal:VerifyItemLinks(10, task) end)
      :Then(function(task) internal:VerifyItemLinks(11, task) end)
      :Then(function(task) internal:VerifyItemLinks(12, task) end)
      :Then(function(task) internal:VerifyItemLinks(13, task) end)
      :Then(function(task) internal:VerifyItemLinks(14, task) end)
      :Then(function(task) internal:VerifyItemLinks(15, task) end)
      :Then(function(task) internal:dm("Debug", "VerifyAllItemLinks Done") end)
      :Finally(function(task) internal:DatabaseBusy(false) end)
end

function internal:DatabaseBusy(start)
  internal.isDatabaseBusy = start
  --[[
  if start then
    for i = 1, GetNumGuilds() do
      local guildId = GetGuildId(i)
      internal.LibHistoireListener[guildId]:Stop()
      internal.LibHistoireListener[guildId] = {}
    end
  end
  if not start then
    internal:SetupListenerLibHistoire()
  end
  ]]--
  if not MasterMerchant then return end

  --[[ TODO this may be used for something else
  MasterMerchantResetButton:SetEnabled(not start)
  MasterMerchantGuildResetButton:SetEnabled(not start)
  MasterMerchantRefreshButton:SetEnabled(not start)
  MasterMerchantGuildRefreshButton:SetEnabled(not start)
  ]]--

  if not start then
    MasterMerchantWindowLoadingIcon.animation:Stop()
    MasterMerchantGuildWindowLoadingIcon.animation:Stop()
    MasterMerchantGuildWindowLoadingIcon.animation:Stop()
  end

  MasterMerchantWindowLoadingIcon:SetHidden(not start)
  MasterMerchantGuildWindowLoadingIcon:SetHidden(not start)
  MasterMerchantGuildWindowLoadingIcon:SetHidden(not start)

  if start then
    MasterMerchantWindowLoadingIcon.animation:PlayForward()
    MasterMerchantGuildWindowLoadingIcon.animation:PlayForward()
    MasterMerchantGuildWindowLoadingIcon.animation:PlayForward()
  end
end

--[[
  Reference for internal:AddSearchToItem

  ["sales"] =
  {
      [1] =
      {
          ["itemLink"] = "|H0:item:68633:359:50:0:0:0:0:0:0:0:0:0:0:0:0:13:0:0:0:10000:0|h|h",
          ["timestamp"] = 1604974613,
          ["guild"] = "Unstable Unicorns",
          ["buyer"] = "@misscastalot",
          ["seller"] = "@thecloakgirl",
          ["wasKiosk"] = true,
          ["price"] = 500,
          ["id"] = "1414605555",
          ["quant"] = 1,
      },
  },
  ["itemDesc"] = "Helm of the Pariah",
  ["itemAdderText"] = "cp160 green  fine  set mark of the pariah  apparel  well-fitted  head ",
  ["itemIcon"] = "/esoui/art/icons/gear_malacath_heavy_head_a.dds",

  weapon
  /script internal:dm("Debug", GetNumTradingHouseSearchResultItemLinkAsFurniturePreviewVariations("|H0:item:68633:363:50:0:0:0:0:0:0:0:0:0:0:0:0:13:0:0:0:10000:0|h|h"))
  /script internal:dm("Debug", GetItemLinkRequiredChampionPoints("|H0:item:167719:2:50:0:0:0:0:0:0:0:0:0:0:0:0:111:0:0:0:10000:0|h|h"))
  /script internal:dm("Debug", GetItemLinkReagentTraitInfo("|H1:item:45839:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"))
  armor

  /script internal:dm("Debug", zo_strformat("<<t:1>>", GetString("SI_ITEMFILTERTYPE", GetItemLinkFilterTypeInfo("|H1:item:167644:362:50:0:0:0:0:0:0:0:0:0:0:0:0:111:0:0:0:300:0|h|h"))))


  SI_ITEMFILTERTYPE
  /script adder = ""; adder = internal:concat(adder, "weapon"); internal:dm(adder)

  What is Done:
	Line 16112: * GetItemLinkItemType(*string* _itemLink_)
	Line 16130: * GetItemLinkRequiredLevel(*string* _itemLink_)
	Line 16133: * GetItemLinkRequiredChampionPoints(*string* _itemLink_)
	Line 16214: * GetItemLinkDisplayQuality(*string* _itemLink_)
	Line 16118: * GetItemLinkArmorType(*string* _itemLink_)
	Line 15863: * GetItemLinkFilterTypeInfo(*string* _itemLink_)
	Line 16181: * GetItemLinkSetInfo(*string* _itemLink_, *bool* _equipped_)
	Line 16121: * GetItemLinkWeaponType(*string* _itemLink_)
	Line 16226: * GetItemLinkEquipType(*string* _itemLink_)
	Line 15966: * GetItemLinkTraitType(*string* _itemLink_)



	Line 10252: * GetComparisonEquipSlotsFromItemLink(*string* _itemLink_)
	Line 10278: * GetItemLinkInfo(*string* _itemLink_)
	Line 11409: * GetItemTraitInformationFromItemLink(*string* _itemLink_)
	Line 13353: * SetCustomerServiceTicketItemTargetByLink(*string* _itemLink_)
	Line 15728: * GetLinkType(*string* _itemLink_)
	Line 15963: * GetItemLinkTraitCategory(*string* _itemLink_)
	Line 16103: * GetItemLinkName(*string* _itemLink_)
	Line 16106: * GetItemLinkItemId(*string* _itemLink_)
	Line 16109: * GetItemLinkIcon(*string* _itemLink_)
	Line 16115: * GetItemLinkItemUseType(*string* _itemLink_)
	Line 16124: * GetItemLinkWeaponPower(*string* _itemLink_)
	Line 16127: * GetItemLinkArmorRating(*string* _itemLink_, *bool* _considerCondition_)
	Line 16136: * GetItemLinkValue(*string* _itemLink_, *bool* _considerCondition_)
	Line 16139: * GetItemLinkCondition(*string* _itemLink_)
	Line 16145: * GetItemLinkMaxEnchantCharges(*string* _itemLink_)
	Line 16148: * GetItemLinkNumEnchantCharges(*string* _itemLink_)
	Line 16154: * GetItemLinkEnchantInfo(*string* _itemLink_)
	Line 16157: * GetItemLinkDefaultEnchantId(*string* _itemLink_)
	Line 16160: * GetItemLinkAppliedEnchantId(*string* _itemLink_)
	Line 16163: * GetItemLinkFinalEnchantId(*string* _itemLink_)
	Line 16172: * GetItemLinkOnUseAbilityInfo(*string* _itemLink_)
	Line 16175: * GetItemLinkTraitOnUseAbilityInfo(*string* _itemLink_, *luaindex* _index_)
	Line 16178: * GetItemLinkTraitInfo(*string* _itemLink_)
	Line 16187: * GetItemLinkSetBonusInfo(*string* _itemLink_, *bool* _equipped_, *luaindex* _index_)
	Line 16190: * GetItemLinkNumContainerSetIds(*string* _itemLink_)
	Line 16193: * GetItemLinkContainerSetInfo(*string* _itemLink_, *luaindex* _containerSetIndex_)
	Line 16196: * GetItemLinkContainerSetBonusInfo(*string* _itemLink_, *luaindex* _containerSetIndex_, *luaindex* _bonusIndex_)
	Line 16199: * GetItemLinkFlavorText(*string* _itemLink_)
	Line 16208: * GetItemLinkSiegeMaxHP(*string* _itemLink_)
	Line 16211: * GetItemLinkFunctionalQuality(*string* _itemLink_)
	Line 16217: * GetItemLinkSiegeType(*string* _itemLink_)
	Line 16232: * GetItemLinkCraftingSkillType(*string* _itemLink_)
	Line 16238: * GetItemLinkEnchantingRuneName(*string* _itemLink_)
	Line 16241: * GetItemLinkEnchantingRuneClassification(*string* _itemLink_)
	Line 16244: * GetItemLinkRequiredCraftingSkillRank(*string* _itemLink_)
	Line 16250: * GetItemLinkBindType(*string* _itemLink_)
	Line 16253: * GetItemLinkGlyphMinLevels(*string* _itemLink_)
	Line 16262: * GetItemLinkFurnishingLimitType(*string* _itemLink_)
	Line 16268: * GetItemLinkBookTitle(*string* _itemLink_)
	Line 16286: * GetItemLinkRecipeResultItemLink(*string* _itemLink_, *[LinkStyle|#LinkStyle]* _linkStyle_)
	Line 16289: * GetItemLinkRecipeNumIngredients(*string* _itemLink_)
	Line 16292: * GetItemLinkRecipeIngredientInfo(*string* _itemLink_, *luaindex* _index_)
	Line 16295: * GetItemLinkRecipeIngredientItemLink(*string* _itemLink_, *luaindex* _index_, *[LinkStyle|#LinkStyle]* _linkStyle_)
	Line 16298: * GetItemLinkRecipeNumTradeskillRequirements(*string* _itemLink_)
	Line 16301: * GetItemLinkRecipeTradeskillRequirement(*string* _itemLink_, *luaindex* _tradeskillIndex_)
	Line 16304: * GetItemLinkRecipeQualityRequirement(*string* _itemLink_)
	Line 16307: * GetItemLinkRecipeCraftingSkillType(*string* _itemLink_)
	Line 16310: * GetItemLinkReagentTraitInfo(*string* _itemLink_, *luaindex* _index_)
	Line 16313: * GetItemLinkItemStyle(*string* _itemLink_)
	Line 16316: * GetItemLinkShowItemStyleInTooltip(*string* _itemLink_)
	Line 16319: * GetItemLinkRefinedMaterialItemLink(*string* _itemLink_, *[LinkStyle|#LinkStyle]* _linkStyle_)
	Line 16322: * GetItemLinkMaterialLevelDescription(*string* _itemLink_)
	Line 16343: * GetItemLinkStacks(*string* _itemLink_)
	Line 16349: * GetItemLinkDyeIds(*string* _itemLink_)
	Line 16352: * GetItemLinkDyeStampId(*string* _itemLink_)
	Line 16355: * GetItemLinkFurnitureDataId(*string* _itemLink_)
	Line 16358: * GetItemLinkGrantedRecipeIndices(*string* _itemLink_)
	Line 16364: * GetItemLinkOutfitStyleId(*string* _itemLink_)
	Line 16367: * GetItemLinkTooltipRequiresCollectibleId(*string* _itemLink_)
	Line 16376: * GetItemLinkCombinationId(*string* _itemLink_)
	Line 16379: * GetItemLinkCombinationDescription(*string* _itemLink_)
	Line 16382: * GetItemLinkTradingHouseItemSearchName(*string* _itemLink_)
	Line 16385: * GetItemLinkContainerCollectibleId(*string* _itemLink_)
	Line 16422: * GetItemLinkNumItemTags(*string* _itemLink_)
	Line 16425: * GetItemLinkItemTagInfo(*string* _itemLink_, *luaindex* _itemTagIndex_)
	Line 16484: * GetItemLinkSellInformation(*string* _itemLink_)
	Line 17329: * GetNumTradingHouseSearchResultItemLinkAsFurniturePreviewVariations(*string* _itemLink_)
	Line 17332: * GetTradingHouseSearchResultItemLinkAsFurniturePreviewVariationDisplayName(*string* _itemLink_, *luaindex* _variation_)
  internal:concat("weapon", "weapon")
]]--
