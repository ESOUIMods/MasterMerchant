local internal = _G["LibGuildStore_Internal"]
local listings_data = _G["LibGuildStore_ListingsData"]
local lr_index = _G["LibGuildStore_ListingsIndex"]

function internal:CheckForDuplicateListings(itemLink, eventID, timestamp)
  --[[ we need to be able to calculate theIID and itemIndex
  when not used with addToHistoryTables() event though
  the function will calculate them.
  ]]--
  local theIID = GetItemLinkItemId(itemLink)
  if theIID == nil or theIID == 0 then return end
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)

  if listings_data[theIID] and listings_data[theIID][itemIndex] then
    for _, v in pairs(listings_data[theIID][itemIndex]['sales']) do
      if v.id == eventID then
        v.timestamp = timestamp
        return true
      end
    end
  end
  return false
end

function internal:addListingData(theEvent)
  --internal:dm("Debug", "addListingData")
  if not MasterMerchant.isInitialized then return end
  --[[ TODO use guild ID and name for lookup table
    local theEvent            = {
      guild = listing.guildName,
      guildId = listing.guildId,
      itemLink = listing.itemLink,
      quant = listing.stackCount,
      timestamp = listing.lastSeen,
      listingTime = listedTime,
      price = listing.purchasePrice,
      seller = listing.sellerName,
      id = Id64ToString(listing.itemUniqueId),
      buyer
    }
  ]]--
  local newEvent = ZO_DeepTableCopy(theEvent)
  local eventItemLink = newEvent.itemLink
  local eventSeller = newEvent.seller
  local eventGuild = newEvent.guild
  local timestamp = newEvent.timestamp

  -- first add new data lookups to their tables
  local linkHash = internal:AddSalesTableData("itemLink", eventItemLink)
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
  if not listings_data[theIID] then
    listings_data[theIID], hashUsed = internal:SetTraderListingData(eventItemLink, theIID)
  end
  listings_data[theIID][itemIndex] = listings_data[theIID][itemIndex] or {}
  listings_data[theIID][itemIndex].itemIcon = listings_data[theIID][itemIndex].itemIcon or GetItemLinkInfo(eventItemLink)
  listings_data[theIID][itemIndex].itemAdderText = listings_data[theIID][itemIndex].itemAdderText or internal:AddSearchToItem(eventItemLink)
  listings_data[theIID][itemIndex].itemDesc = listings_data[theIID][itemIndex].itemDesc or formattedItemName
  listings_data[theIID][itemIndex].totalCount = listings_data[theIID][itemIndex].totalCount or 0 -- assign count if if new sale
  listings_data[theIID][itemIndex].totalCount = listings_data[theIID][itemIndex].totalCount + 1 -- increment count if existing sale
  listings_data[theIID][itemIndex].wasAltered = true
  listings_data[theIID][itemIndex]['sales'] = listings_data[theIID][itemIndex]['sales'] or {}
  local searchItemDesc = listings_data[theIID][itemIndex].itemDesc -- used for searchText
  local searchItemAdderText = listings_data[theIID][itemIndex].itemAdderText -- used for searchText
  local adderDescConcat = searchItemDesc .. ' ' .. searchItemAdderText

  newEvent.itemLink = linkHash
  newEvent.seller = sellerHash
  newEvent.guild = guildHash

  local insertedIndex = 1
  local salesTable = listings_data[theIID][itemIndex]['sales']
  local nextLocation = #salesTable + 1
  --[[Note, while salesTable helps readability table.insert() can not insert
  into the local variable]]--
  if salesTable[nextLocation] == nil then
    table.insert(listings_data[theIID][itemIndex]['sales'], nextLocation, newEvent)
    insertedIndex = nextLocation
  else
    table.insert(listings_data[theIID][itemIndex]['sales'], newEvent)
    insertedIndex = #salesTable
  end

  local newestTime = listings_data[theIID][itemIndex]["newestTime"]
  local oldestTime = listings_data[theIID][itemIndex]["oldestTime"]
  if newestTime == nil or newestTime < timestamp then listings_data[theIID][itemIndex]["newestTime"] = timestamp end
  if oldestTime == nil or oldestTime > timestamp then listings_data[theIID][itemIndex]["oldestTime"] = timestamp end

  -- this section adds the sales to the lists for the MM window
  local guild

  guild = internal.listedItems[eventGuild] or MMGuild:new(eventGuild)
  internal.listedItems[eventGuild] = guild
  guild:addPurchaseByDate(eventItemLink, timestamp, newEvent.price, newEvent.quant, false, nil, adderDescConcat)

  guild = internal.listedSellers[eventGuild] or MMGuild:new(eventGuild)
  internal.listedSellers[eventGuild] = guild
  guild:addPurchaseByDate(eventSeller, timestamp, newEvent.price, newEvent.quant, false)

  local temp = { '', ' ', '', ' ', '', ' ', '', } -- fewer tokens for listings
  temp[1] = eventSeller and ('s' .. eventSeller) or ''
  temp[3] = eventGuild or ''
  temp[5] = searchItemDesc or ''
  temp[7] = searchItemAdderText or ''
  local searchText = zo_strlower(table.concat(temp, ''))

  local searchByWords = zo_strgmatch(searchText, '%S+')
  local wordData = { theIID, itemIndex, insertedIndex }

  -- Index each word
  for i in searchByWords do
    lr_index[i] = lr_index[i] or {}
    table.insert(lr_index[i], wordData)
    internal.lr_index_count = (internal.lr_index_count or 0) + 1
  end

  MasterMerchant_Internal:ClearBonanzaCacheById(theIID, itemIndex)

  return true
end

----------------------------------------
----- iterateOverListingsData         -----
----------------------------------------

function internal:iterateOverListingsData(itemid, versionid, saleid, prefunc, loopfunc, postfunc, extraData)
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
    itemid, versionlist = next(listings_data, itemid)
    extraData.versionRemoved = false
    versionid = nil
  else
    versionlist = listings_data[itemid]
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
            LEQ:continueWith(function() internal:iterateOverListingsData(itemid, versionid, saleid, nil, loopfunc, postfunc, extraData) end, nil)
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
        LEQ:continueWith(function() internal:iterateOverListingsData(itemid, versionid, saleid, nil, loopfunc, postfunc, extraData) end, nil)
        return
      end
    end
    --[[ end loop over ['x:x:x:x:x'] ]]--

    if extraData.versionRemoved then
      local versions = {}
      for vid, vd in pairs(listings_data[itemid]) do
        if (vd ~= nil) and (type(vd) == 'table') then
          versions[vid] = vd
        end
      end
      listings_data[itemid] = versions
    end

    -- If we just deleted everything, clear the bucket out
    if (listings_data[itemid] ~= nil and ((internal:NonContiguousNonNilCount(versionlist) < 1) or (type(itemid) ~= 'number'))) then
      extraData.idCount = (extraData.idCount or 0) + 1
      listings_data[itemid] = nil
    end

    -- Go on to the next Item
    itemid, versionlist = next(listings_data, itemid)
    extraData.versionRemoved = false
    versionid = nil
  end

  if postfunc then
    postfunc(extraData)
  end
end

function internal:TruncateListingsHistory()
  internal:dm("Debug", "TruncateListingsHistory")

  -- DEBUG  TruncateListingsHistory
  -- do return end

  local prefunc = function(extraData)
    extraData.start = GetTimeStamp()
    extraData.deleteCount = 0
    extraData.newSalesCount = 0
    extraData.epochBack = GetTimeStamp() - ZO_ONE_DAY_IN_SECONDS
    extraData.wasAltered = false

    internal:DatabaseBusy(true)
  end

  local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData)

    local salesDeleted = 0
    local salesCount = versiondata.totalCount
    if salesCount == 0 then
      versiondata['sales'] = {}
      extraData.saleRemoved = false
      return true
    end
    local salesDataTable = internal:spairs(versiondata['sales'], function(a, b) return internal:CleanTimestamp(a) < internal:CleanTimestamp(b) end)
    for salesId, salesData in salesDataTable do
      if (salesData['timestamp'] < extraData.epochBack
        or salesData['timestamp'] == nil
        or type(salesData['timestamp']) ~= 'number'
      ) then
        -- Remove it by setting it to nil
        versiondata['sales'][salesId] = nil
        salesDeleted = salesDeleted + 1
        extraData.wasAltered = true
        salesCount = salesCount - 1
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
    return true
  end

  local postfunc = function(extraData)
    internal:DatabaseBusy(false)
    if LibGuildStore_SavedVariables["showTruncateSummary"] then
      internal:dm("Info", string.format(GetString(GS_TRUNCATE_LISTINGS_COMPLETE), GetTimeStamp() - extraData.start, extraData.deleteCount))
    end
  end

  if not internal.isDatabaseBusy then
    internal:iterateOverListingsData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

end

function internal:IndexListingsData()
  internal:dm("Debug", "IndexListingsData")

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

  local loopfunc = function(numberID, itemData, versiondata, itemIndex, viewedItem, extraData)

    extraData.indexCount = extraData.indexCount + 1

    local currentItemLink = internal:GetItemLinkByIndex(viewedItem['itemLink'])
    local currentGuild = internal:GetGuildNameByIndex(viewedItem['guild'])
    local currentSeller = internal:GetAccountNameByIndex(viewedItem['seller'])

    versiondata.itemAdderText = versiondata.itemAdderText or self.addedSearchToItem(currentItemLink)
    versiondata.itemDesc = versiondata.itemDesc or zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(currentItemLink))
    versiondata.itemIcon = versiondata.itemIcon or GetItemLinkInfo(currentItemLink)

    local temp = { '', ' ', '', ' ', '', ' ', '', } -- fewer tokens for listings

    temp[1] = currentSeller and ('s' .. currentSeller) or ''
    temp[3] = currentGuild or ''
    temp[5] = versiondata.itemDesc or ''
    temp[7] = versiondata.itemAdderText or ''

    local searchText = zo_strlower(table.concat(temp, ''))
    local searchByWords = zo_strgmatch(searchText, '%S+')
    local wordData = { numberID, itemData, itemIndex }

    -- Index each word
    for i in searchByWords do
      lr_index[i] = lr_index[i] or {}
      table.insert(lr_index[i], wordData)
      extraData.wordsIndexCount = (extraData.wordsIndexCount or 0) + 1
      internal.lr_index_count = (internal.lr_index_count or 0) + 1
    end


  end

  local postfunc = function(extraData)
    internal:DatabaseBusy(false)
    if LibGuildStore_SavedVariables["showIndexingSummary"] then
      internal:dm("Info", string.format(GetString(GS_INDEXING_SUMMARY), GetTimeStamp() - extraData.start, extraData.indexCount, extraData.wordsIndexCount))
    end
  end

  if not internal.isDatabaseBusy then
    internal:iterateOverListingsData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

end

function internal:InitListingHistory()
  internal:dm("Debug", "InitListingHistory")

  local extradata = {}

  if internal.listedItems == nil then
    internal.listedItems = {}
    extradata.doListedItems = true
  end

  if internal.listedSellers == nil then
    internal.listedSellers = {}
    extradata.doListedSellers = true
  end

  local prefunc = function(extraData)
    extraData.start = GetTimeStamp()
    internal:DatabaseBusy(true)
    extraData.totalRecords = 0
  end

  local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData)
    extraData.totalRecords = extraData.totalRecords + 1
    local currentGuild = internal:GetGuildNameByIndex(saledata['guild'])
    if currentGuild then
      local currentSeller = internal:GetAccountNameByIndex(saledata['seller'])

      if (extradata.doListedItems) then
        if not internal.listedItems[currentGuild] then
          internal.listedItems[currentGuild] = MMGuild:new(currentGuild)
        end
        local _, firstsaledata = next(versiondata.sales, nil)
        local firstsaledataItemLink = internal:GetItemLinkByIndex(firstsaledata.itemLink)
        local searchDataDesc = versiondata.itemDesc or zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(firstsaledataItemLink))
        local searchDataAdder = versiondata.itemAdderText or internal:AddSearchToItem(firstsaledataItemLink)
        local searchData = searchDataDesc .. ' ' .. searchDataAdder
        local guild = internal.listedItems[currentGuild]
        guild:addPurchaseByDate(firstsaledataItemLink, saledata.timestamp, saledata.price, saledata.quant, false, nil, searchData)
      end

      if (extradata.doListedSellers) then
        if not internal.listedSellers[currentGuild] then
          internal.listedSellers[currentGuild] = MMGuild:new(currentGuild)
        end
        local guild = internal.listedSellers[currentGuild]
        guild:addPurchaseByDate(currentSeller, saledata.timestamp, saledata.price, saledata.quant, false, nil)
      end

    end
    return false
  end

  local postfunc = function(extraData)

    for _, guild in pairs(internal.listedItems) do
      guild:SortAllRanks()
    end

    for _, guild in pairs(internal.listedSellers) do
      guild:SortAllRanks()
    end

    internal:DatabaseBusy(false)

    internal.totalListings = extraData.totalRecords
    if LibGuildStore_SavedVariables["showGuildInitSummary"] then
      internal:dm("Info", string.format(GetString(GS_INIT_LISTINGS_HISTORY_SUMMARY), GetTimeStamp() - extraData.start, internal.totalListings))
    end
  end

  if not internal.isDatabaseBusy then
    internal:iterateOverListingsData(nil, nil, nil, prefunc, loopfunc, postfunc, extradata)
  end

end

-- Bring seperate lists together we can still access the sales history all together
function internal:ReferenceListingsDataContainer()
  internal:dm("Debug", "Reference Listings Data Containers")
  internal:ReferenceListings(GS00DataSavedVariables)
  internal:ReferenceListings(GS01DataSavedVariables)
  internal:ReferenceListings(GS02DataSavedVariables)
  internal:ReferenceListings(GS03DataSavedVariables)
  internal:ReferenceListings(GS04DataSavedVariables)
  internal:ReferenceListings(GS05DataSavedVariables)
  internal:ReferenceListings(GS06DataSavedVariables)
  internal:ReferenceListings(GS07DataSavedVariables)
  internal:ReferenceListings(GS08DataSavedVariables)
  internal:ReferenceListings(GS09DataSavedVariables)
  internal:ReferenceListings(GS10DataSavedVariables)
  internal:ReferenceListings(GS11DataSavedVariables)
  internal:ReferenceListings(GS12DataSavedVariables)
  internal:ReferenceListings(GS13DataSavedVariables)
  internal:ReferenceListings(GS14DataSavedVariables)
  internal:ReferenceListings(GS15DataSavedVariables)
end

-- ReferenceSales: Merge and update sales data from different versions
-- of saved variables into a unified listings_data table.
-- @param otherData: A table containing sales data from different versions
function internal:ReferenceListings(otherData)
  local savedVars = otherData[internal.listingsNamespace]
  local oldestTime = nil
  local newestTime = nil

  for itemid, versionlist in pairs(savedVars) do
    if not listings_data[itemid] and next(versionlist) then
      listings_data[itemid] = versionlist
    else
      for versionid, versiondata in pairs(versionlist) do
        if not listings_data[itemid][versionid] and next(versiondata) then
          listings_data[itemid][versionid] = versiondata
        else
          if next(versiondata['sales']) then
            listings_data[itemid][versionid]['sales'] = listings_data[itemid][versionid]['sales'] or {}
            for saleid, saledata in pairs(versiondata['sales']) do
              if (type(saleid) == 'number' and type(saledata) == 'table' and type(saledata["timestamp"]) == 'number') then
                table.insert(listings_data[itemid][versionid]['sales'], saledata)
              end
            end
            local _, firstSale = next(versiondata['sales'], nil)
            if firstSale then
              local itemLink = internal:GetItemLinkByIndex(firstSale.itemLink)
              listings_data[itemid][versionid].itemIcon = versiondata.itemIcon or GetItemLinkInfo(itemLink)
              listings_data[itemid][versionid].itemAdderText = versiondata.itemAdderText or internal:AddSearchToItem(itemLink)
              listings_data[itemid][versionid].itemDesc = versiondata.itemDesc or zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink))
            end
            for _, saledata in ipairs(listings_data[itemid][versionid]['sales']) do
              if oldestTime == nil or oldestTime > saledata.timestamp then oldestTime = saledata.timestamp end
              if newestTime == nil or newestTime < saledata.timestamp then newestTime = saledata.timestamp end
            end
            listings_data[itemid][versionid].totalCount = NonContiguousCount(listings_data[itemid][versionid]['sales'])
            listings_data[itemid][versionid].wasAltered = true
            listings_data[itemid][versionid].oldestTime = oldestTime
            listings_data[itemid][versionid].newestTime = newestTime
          end
        end
      end
      savedVars[itemid] = nil
    end
  end
end
