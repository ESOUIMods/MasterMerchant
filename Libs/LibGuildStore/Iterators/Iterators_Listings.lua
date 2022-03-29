local lib = _G["LibGuildStore"]
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
    for k, v in pairs(listings_data[theIID][itemIndex]['sales']) do
      if v.id == eventID then
        v.timestamp = timestamp
        return true
      end
    end
  end
  return false
end

function internal:addListingData(theEvent)
  if not MasterMerchant.isInitialized then return end
  --internal:dm("Debug", "addListingData")
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
  --internal:dm("Debug", theEvent)
  -- /script d(LibGuildStore_Internal:AddSalesTableData("itemLink", "|H0:item:68212:3:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"))
  local linkHash = internal:AddSalesTableData("itemLink", theEvent.itemLink)
  local sellerHash = internal:AddSalesTableData("accountNames", theEvent.seller)
  local guildHash = internal:AddSalesTableData("guildNames", theEvent.guild)

  local itemIndex = internal.GetOrCreateIndexFromLink(theEvent.itemLink)
  local theIID = GetItemLinkItemId(theEvent.itemLink)
  if theIID == nil or theIID == 0 then return false end

  local hashUsed = "alreadyExisted"
  if not listings_data[theIID] then
    listings_data[theIID], hashUsed = internal:SetTraderListingData(theEvent.itemLink, theIID)
  end

  local newEvent = ZO_DeepTableCopy(theEvent)
  newEvent.itemLink = linkHash
  newEvent.seller = sellerHash
  newEvent.guild = guildHash

  local insertedIndex = 1
  local searchItemDesc = ""
  local searchItemAdderText = ""
  if listings_data[theIID][itemIndex] then
    local nextLocation = #listings_data[theIID][itemIndex]['sales'] + 1
    searchItemDesc = listings_data[theIID][itemIndex].itemDesc
    searchItemAdderText = listings_data[theIID][itemIndex].itemAdderText
    if listings_data[theIID][itemIndex]['sales'][nextLocation] == nil then
      table.insert(listings_data[theIID][itemIndex]['sales'], nextLocation, newEvent)
      insertedIndex = nextLocation
    else
      table.insert(listings_data[theIID][itemIndex]['sales'], newEvent)
      insertedIndex = #listings_data[theIID][itemIndex]['sales']
    end
  else
    if listings_data[theIID][itemIndex] == nil then listings_data[theIID][itemIndex] = {} end
    if listings_data[theIID][itemIndex]['sales'] == nil then listings_data[theIID][itemIndex]['sales'] = {} end
    searchItemDesc = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(theEvent.itemLink))
    searchItemAdderText = internal:AddSearchToItem(theEvent.itemLink)
    listings_data[theIID][itemIndex] = {
      itemIcon      = GetItemLinkInfo(theEvent.itemLink),
      itemAdderText = searchItemAdderText,
      itemDesc      = searchItemDesc,
      sales         = { newEvent } }
    --internal:dm("Debug", newEvent)
  end
  listings_data[theIID][itemIndex].wasAltered = true
  if listings_data[theIID][itemIndex] and listings_data[theIID][itemIndex].totalCount then
    listings_data[theIID][itemIndex].totalCount = listings_data[theIID][itemIndex].totalCount + 1
  else
    listings_data[theIID][itemIndex].totalCount = 1
  end

  -- this section adds the sales to the lists for the MM window
  local guild
  local adderDescConcat = searchItemDesc .. ' ' .. searchItemAdderText

  guild = internal.listedItems[theEvent.guild] or MMGuild:new(theEvent.guild)
  internal.listedItems[theEvent.guild] = guild
  guild:addPurchaseByDate(theEvent.itemLink, theEvent.timestamp, theEvent.price, theEvent.quant, false, nil, adderDescConcat)

  guild = internal.listedSellers[theEvent.guild] or MMGuild:new(theEvent.guild)
  internal.listedSellers[theEvent.guild] = guild
  guild:addPurchaseByDate(theEvent.seller, theEvent.timestamp, theEvent.price, theEvent.quant, false)

  local temp = { '', ' ', '', ' ', '', ' ', '', ' ', '', }
  local searchText = ""
  -- if theEvent.buyer then temp[1] = 'b' .. theEvent.buyer end
  if theEvent.seller then temp[3] = 's' .. theEvent.seller end
  temp[5] = theEvent.guild or ''
  temp[7] = searchItemDesc or ''
  temp[9] = searchItemAdderText or ''
  searchText = string.lower(table.concat(temp, ''))

  local searchByWords = zo_strgmatch(searchText, '%S+')
  local wordData = { theIID, itemIndex, insertedIndex }

  -- Index each word
  for i in searchByWords do
    if lr_index[i] == nil then lr_index[i] = {} end
    table.insert(lr_index[i], wordData)
    internal.lr_index_count = internal.lr_index_count + 1
  end

  return true
end

----------------------------------------
----- iterateOverListingsData         -----
----------------------------------------

function internal:iterateOverListingsData(itemid, versionid, saleid, prefunc, loopfunc, postfunc, extraData)
  extraData.versionCount = (extraData.versionCount or 0)
  extraData.idCount = (extraData.idCount or 0)
  extraData.checkMilliseconds = (extraData.checkMilliseconds or 20)

  if prefunc then
    prefunc(extraData)
  end

  local checkTime = GetGameTimeMilliseconds()
  local versionlist
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
            LEQ:ContinueWith(function() internal:iterateOverListingsData(itemid, versionid, saleid, nil, loopfunc,
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
        LEQ:ContinueWith(function() internal:iterateOverListingsData(itemid, versionid, saleid, nil, loopfunc, postfunc,
          extraData) end, nil)
        return
      end
    end

    if extraData.versionRemoved then
      local versions = {}
      for vid, vd in pairs(listings_data[itemid]) do
        if (vd ~= nil) and (type(vd) == 'table') then
          versions[vid] = vd
        end
      end
      listings_data[itemid] = versions
    end

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

  -- DEBUG  TruncateHistory
  -- do return end

  local prefunc = function(extraData)
    extraData.start = GetTimeStamp()
    extraData.deleteCount = 0
    extraData.epochBack = GetTimeStamp() - ZO_ONE_DAY_IN_SECONDS
    extraData.wasAltered = false

    internal:DatabaseBusy(true)
  end

  local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData)

    local salesDeleted = 0
    salesCount = versiondata.totalCount
    local salesDataTable = internal:spairs(versiondata['sales'],
      function(a, b) return internal:CleanTimestamp(a) < internal:CleanTimestamp(b) end)
    for saleid, saledata in salesDataTable do
      if (saledata['timestamp'] < extraData.epochBack
        or saledata['timestamp'] == nil
        or type(saledata['timestamp']) ~= 'number'
      ) then
        -- Remove it by setting it to nil
        versiondata['sales'][saleid] = nil
        salesDeleted = salesDeleted + 1
        extraData.wasAltered = true
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
      internal:dm("Info", string.format(GetString(GS_TRUNCATE_LISTINGS_COMPLETE), GetTimeStamp() - extraData.start,
        extraData.deleteCount))
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
    extraData.checkMilliseconds = ZO_ONE_MINUTE_IN_SECONDS
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

      -- if currentBuyer then temp[1] = 'b' .. currentBuyer end
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
      if lr_index[i] == nil then
        extraData.wordsIndexCount = extraData.wordsIndexCount + 1
        lr_index[i] = {}
      end
      table.insert(lr_index[i], wordData)
      internal.lr_index_count = internal.lr_index_count + 1
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
  end

  if internal.listedSellers == nil then
    internal.listedSellers = {}
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
      local currentBuyer = internal:GetAccountNameByIndex(saledata['buyer'])

      if not internal.listedItems[currentGuild] then
        internal.listedItems[currentGuild] = MMGuild:new(currentGuild)
      end
      local guild = internal.listedItems[currentGuild]
      local _, firstsaledata = next(versiondata.sales, nil)
      local firstsaledataItemLink = internal:GetItemLinkByIndex(firstsaledata.itemLink)
      local searchDataDesc = versiondata.itemDesc or zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(firstsaledataItemLink))
      local searchDataAdder = versiondata.itemAdderText or internal:AddSearchToItem(firstsaledataItemLink)
      local searchData = searchDataDesc .. ' ' .. searchDataAdder
      guild:addPurchaseByDate(firstsaledataItemLink, saledata.timestamp, saledata.price, saledata.quant, false, nil, searchData)

      if not internal.listedSellers[currentGuild] then
        internal.listedSellers[currentGuild] = MMGuild:new(currentGuild)
      end
      local guild = internal.listedSellers[currentGuild]
      guild:addPurchaseByDate(currentSeller, saledata.timestamp, saledata.price, saledata.quant, false, nil)

    end
    return false
  end

  local postfunc = function(extraData)

    for _, guild in pairs(internal.listedItems) do
      guild:sort()
    end

    for guildName, guild in pairs(internal.listedSellers) do
      guild:sort()
    end

    internal:DatabaseBusy(false)

    internal.totalListings = extraData.totalRecords
    if LibGuildStore_SavedVariables["showGuildInitSummary"] then
      internal:dm("Info", string.format(GetString(GS_INIT_LISTINGS_HISTORY_SUMMARY), GetTimeStamp() - extraData.start,
        internal.totalListings))
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

function internal:ReferenceListings(otherData)
  local savedVars = otherData[internal.listingsNamespace]

  for itemid, versionlist in pairs(savedVars) do
    if listings_data[itemid] then
      for versionid, versiondata in pairs(versionlist) do
        if listings_data[itemid][versionid] then
          if versiondata['sales'] then
            listings_data[itemid][versionid]['sales'] = listings_data[itemid][versionid]['sales'] or {}
            -- IPAIRS
            for saleid, saledata in pairs(versiondata['sales']) do
              if (type(saleid) == 'number' and type(saledata) == 'table' and type(saledata.timestamp) == 'number') then
                table.insert(listings_data[itemid][versionid]['sales'], saledata)
              end
            end
            local _, first = next(versiondata['sales'], nil)
            if first then
              listings_data[itemid][versionid].itemIcon = GetItemLinkInfo(first.itemLink)
              listings_data[itemid][versionid].itemAdderText = internal:AddSearchToItem(first.itemLink)
              listings_data[itemid][versionid].itemDesc = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(first.itemLink))
            end
          end
        else
          listings_data[itemid][versionid] = versiondata
        end
      end
      savedVars[itemid] = nil
    else
      listings_data[itemid] = versionlist
    end
  end
end
