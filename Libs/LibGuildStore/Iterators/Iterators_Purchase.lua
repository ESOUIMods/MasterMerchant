local internal = _G["LibGuildStore_Internal"]
local purchases_data = _G["LibGuildStore_PurchaseData"]
local pr_index = _G["LibGuildStore_PurchaseIndex"]

function internal:CheckForDuplicatePurchase(itemLink, eventID)
  local theIID = GetItemLinkItemId(itemLink)
  if theIID == nil or theIID == 0 then return end
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)

  if purchases_data[theIID] and purchases_data[theIID][itemIndex] then
    for _, v in pairs(purchases_data[theIID][itemIndex]['sales']) do
      if v.id == eventID then
        return true
      end
    end
  end
  return false
end

function internal:CheckForDuplicateATTPurchase(theEvent)
  local theIID = GetItemLinkItemId(itemLink)
  if theIID == nil or theIID == 0 then return end
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  --[[
    theEvent         = {
      buyer = saleData["buyerName"],
      guild = saleData["guildName"],
      itemLink = saleData["itemLink"],
      quant = saleData["quantity"],
      timestamp = saleData["timeStamp"],
      price = saleData["price"],
      seller = saleData["sellerName"],
    }
  ]]--
  if purchases_data[theIID] and purchases_data[theIID][itemIndex] then
    for _, v in pairs(purchases_data[theIID][itemIndex]['sales']) do
      if v.buyer == theEvent.buyer and
        v.guild == theEvent.guild and
        v.itemLink == theEvent.itemLink and
        v.quant == theEvent.quant and
        v.timestamp == theEvent.timestamp and
        v.price == theEvent.price and
        v.seller == theEvent.seller then
        return true
      end
    end
  end
  return false
end

----------------------------------------
----- Adding New Data              -----
----------------------------------------

function internal:addPurchaseData(theEvent)
  --internal:dm("Debug", "addPurchaseData")
  if not MasterMerchant.isInitialized then return end
  --[[
        local theEvent            = {
          guild = itemData.guildName,
          itemLink = itemData.itemLink,
          quant = itemData.stackCount,
          timestamp = GetTimeStamp(),
          price = itemData.purchasePrice,
          seller = itemData.sellerName,
          id = Id64ToString(itemData.itemUniqueId),
          buyer = GetDisplayName()
        }
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
  if not purchases_data[theIID] then
    purchases_data[theIID] = internal:SetPurchaseData(theIID)
  end
  purchases_data[theIID][itemIndex] = purchases_data[theIID][itemIndex] or {}
  purchases_data[theIID][itemIndex].itemIcon = purchases_data[theIID][itemIndex].itemIcon or GetItemLinkInfo(eventItemLink)
  purchases_data[theIID][itemIndex].itemAdderText = purchases_data[theIID][itemIndex].itemAdderText or internal:AddSearchToItem(eventItemLink)
  purchases_data[theIID][itemIndex].itemDesc = purchases_data[theIID][itemIndex].itemDesc or formattedItemName
  purchases_data[theIID][itemIndex].totalCount = purchases_data[theIID][itemIndex].totalCount or 0 -- assign count if if new sale
  purchases_data[theIID][itemIndex].totalCount = purchases_data[theIID][itemIndex].totalCount + 1 -- increment count if existing sale
  purchases_data[theIID][itemIndex].wasAltered = true
  purchases_data[theIID][itemIndex]['sales'] = purchases_data[theIID][itemIndex]['sales'] or {}
  local searchItemDesc = purchases_data[theIID][itemIndex].itemDesc -- used for searchText
  local searchItemAdderText = purchases_data[theIID][itemIndex].itemAdderText -- used for searchText

  newEvent.itemLink = linkHash
  newEvent.buyer = buyerHash
  newEvent.seller = sellerHash
  newEvent.guild = guildHash

  local insertedIndex = 1
  local salesTable = purchases_data[theIID][itemIndex]['sales']
  local nextLocation = #salesTable + 1
  --[[Note, while salesTable helps readability table.insert() can not insert
  into the local variable]]--
  if salesTable[nextLocation] == nil then
    table.insert(purchases_data[theIID][itemIndex]['sales'], nextLocation, newEvent)
    insertedIndex = nextLocation
  else
    table.insert(purchases_data[theIID][itemIndex]['sales'], newEvent)
    insertedIndex = #salesTable
  end

  local newestTime = purchases_data[theIID][itemIndex]["newestTime"]
  local oldestTime = purchases_data[theIID][itemIndex]["oldestTime"]
  if newestTime == nil or newestTime < timestamp then purchases_data[theIID][itemIndex]["newestTime"] = timestamp end
  if oldestTime == nil or oldestTime > timestamp then purchases_data[theIID][itemIndex]["oldestTime"] = timestamp end

  local temp = { '', ' ', '', ' ', '', ' ', '', ' ', '', } -- no player text for purchases

  temp[1] = eventBuyer and ('b' .. eventBuyer) or ''
  temp[3] = eventSeller and ('s' .. eventSeller) or ''
  temp[5] = eventGuild or ''
  temp[7] = searchItemDesc or ''
  temp[9] = searchItemAdderText or ''
  local searchText = zo_strlower(table.concat(temp, ''))

  local searchByWords = zo_strgmatch(searchText, '%S+')
  local wordData = { theIID, itemIndex, insertedIndex }

  -- Index each word
  for i in searchByWords do
    pr_index[i] = pr_index[i] or {}
    table.insert(pr_index[i], wordData)
    internal.pr_index_count = (internal.pr_index_count or 0) + 1
  end

  return true
end

----------------------------------------
----- iterateOverPurchaseData  -----
----------------------------------------

function internal:iterateOverPurchaseData(itemid, versionid, saleid, prefunc, loopfunc, postfunc, extraData)
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
    itemid, versionlist = next(purchases_data, itemid)
    extraData.versionRemoved = false
    versionid = nil
  else
    versionlist = purchases_data[itemid]
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
            LEQ:continueWith(function() internal:iterateOverPurchaseData(itemid, versionid, saleid, nil, loopfunc, postfunc, extraData) end, nil)
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
        LEQ:continueWith(function() internal:iterateOverPurchaseData(itemid, versionid, saleid, nil, loopfunc, postfunc, extraData) end, nil)
        return
      end
    end
    --[[ end loop over ['x:x:x:x:x'] ]]--

    if extraData.versionRemoved then
      local versions = {}
      for vid, vd in pairs(purchases_data[itemid]) do
        if (vd ~= nil) and (type(vd) == 'table') then
          versions[vid] = vd
        end
      end
      purchases_data[itemid] = versions
    end

    -- If we just deleted everything, clear the bucket out
    if (purchases_data[itemid] ~= nil and ((internal:NonContiguousNonNilCount(versionlist) < 1) or (type(itemid) ~= 'number'))) then
      extraData.idCount = (extraData.idCount or 0) + 1
      purchases_data[itemid] = nil
    end

    -- Go on to the next Item
    itemid, versionlist = next(purchases_data, itemid)
    extraData.versionRemoved = false
    versionid = nil
  end

  if postfunc then
    postfunc(extraData)
  end
end

function internal:TruncatePurchaseHistory()
  internal:dm("Debug", "TruncatePurchaseHistory")

  -- DEBUG  TruncateHistory
  -- do return end

  local prefunc = function(extraData)
    extraData.start = GetTimeStamp()
    extraData.deleteCount = 0
    extraData.newSalesCount = 0
    extraData.epochBack = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * LibGuildStore_SavedVariables["historyDepthSL"])
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
      internal:dm("Info", string.format(GetString(GS_TRUNCATE_PURCHASE_COMPLETE), GetTimeStamp() - extraData.start, extraData.deleteCount))
    end
  end

  if not internal.isDatabaseBusy then
    internal:iterateOverPurchaseData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

end

function internal:IndexPurchaseData()
  internal:dm("Debug", "IndexPurchaseData")

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

  local loopfunc = function(numberID, itemData, versiondata, itemIndex, purchasedItem, extraData)

    extraData.indexCount = extraData.indexCount + 1

    local currentItemLink = internal:GetItemLinkByIndex(purchasedItem['itemLink'])
    local currentGuild = internal:GetGuildNameByIndex(purchasedItem['guild'])
    local currentBuyer = internal:GetAccountNameByIndex(purchasedItem['buyer'])
    local currentSeller = internal:GetAccountNameByIndex(purchasedItem['seller'])

    versiondata.itemAdderText = versiondata.itemAdderText or self.addedSearchToItem(currentItemLink)
    versiondata.itemDesc = versiondata.itemDesc or zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(currentItemLink))
    versiondata.itemIcon = versiondata.itemIcon or GetItemLinkInfo(currentItemLink)

    local temp = { '', ' ', '', ' ', '', ' ', '', ' ', '', } -- no player text for purchases

    temp[1] = currentBuyer and ('b' .. currentBuyer) or ''
    temp[3] = currentSeller and ('s' .. currentSeller) or ''
    temp[5] = currentGuild or ''
    temp[7] = versiondata.itemDesc or ''
    temp[9] = versiondata.itemAdderText or ''

    local searchText = zo_strlower(table.concat(temp, ''))

    -- Index each word
    local searchByWords = zo_strgmatch(searchText, '%S+')
    local wordData = { numberID, itemData, itemIndex }

    for i in searchByWords do
      pr_index[i] = pr_index[i] or {}
      table.insert(pr_index[i], wordData)
      extraData.wordsIndexCount = (extraData.wordsIndexCount or 0) + 1
      internal.pr_index_count = (internal.pr_index_count or 0) + 1
    end
  end

  local postfunc = function(extraData)
    internal:DatabaseBusy(false)
    if LibGuildStore_SavedVariables["showIndexingSummary"] then
      internal:dm("Info", string.format(GetString(GS_INDEXING_SUMMARY), GetTimeStamp() - extraData.start, extraData.indexCount, extraData.wordsIndexCount))
    end
  end

  if not internal.isDatabaseBusy then
    internal:iterateOverPurchaseData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

end

function internal:InitPurchaseHistory()
  internal:dm("Debug", "InitPurchaseHistory")

  local extradata = {}

  if internal.purchasedItems == nil then
    internal.purchasedItems = {}
    extradata.doPurchasedItems = true
  end

  if internal.purchasedBuyer == nil then
    internal.purchasedBuyer = {}
    extradata.doPurchasedBuyer = true
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
      local currentBuyer = internal:GetAccountNameByIndex(saledata['buyer'])

      if (extradata.doPurchasedItems) then
        if not internal.purchasedItems[currentGuild] then
          internal.purchasedItems[currentGuild] = MMGuild:new(currentGuild)
        end
        local _, firstsaledata = next(versiondata.sales, nil)
        local firstsaledataItemLink = internal:GetItemLinkByIndex(firstsaledata.itemLink)
        local searchDataDesc = versiondata.itemDesc or zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(firstsaledataItemLink))
        local searchDataAdder = versiondata.itemAdderText or internal:AddSearchToItem(firstsaledataItemLink)
        local searchData = searchDataDesc .. ' ' .. searchDataAdder
        local guild = internal.purchasedItems[currentGuild]
        guild:addSaleByDate(firstsaledataItemLink, saledata.timestamp, saledata.price, saledata.quant, false, false, searchData)
      end

      if (extradata.doPurchasedBuyer) then
        if not internal.purchasedBuyer[currentGuild] then
          internal.purchasedBuyer[currentGuild] = MMGuild:new(currentGuild)
        end
        local guild = internal.purchasedBuyer[currentGuild]
        guild:addSaleByDate(currentBuyer, saledata.timestamp, saledata.price, saledata.quant, saledata.wasKiosk, false)
      end

    end
    return false
  end

  local postfunc = function(extraData)

    for _, guild in pairs(internal.purchasedItems) do
      guild:SortAllRanks()
    end

    for _, guild in pairs(internal.purchasedBuyer) do
      guild:SortAllRanks()
    end

    internal:DatabaseBusy(false)

    internal.totalPurchases = extraData.totalRecords
    if LibGuildStore_SavedVariables["showGuildInitSummary"] then
      internal:dm("Info", string.format(GetString(GS_INIT_PURCHASES_HISTORY_SUMMARY), GetTimeStamp() - extraData.start, internal.totalPurchases))
    end
  end

  if not internal.isDatabaseBusy then
    internal:iterateOverPurchaseData(nil, nil, nil, prefunc, loopfunc, postfunc, extradata)
  end

end

----------------------------------------
----- Reference Purchase Data      -----
----------------------------------------

function internal:ReferencePurchaseDataContainer()
  internal:dm("Debug", "Reference Purchase Data Container")
  local savedVars = GS17DataSavedVariables[internal.purchasesNamespace]
  for itemid, versionlist in pairs(savedVars) do
    if purchases_data[itemid] then
      for versionid, versiondata in pairs(versionlist) do
        if purchases_data[itemid][versionid] then
          if versiondata['sales'] then
            purchases_data[itemid][versionid]['sales'] = purchases_data[itemid][versionid]['sales'] or {}
            -- IPAIRS
            for saleid, saledata in pairs(versiondata['sales']) do
              if (type(saleid) == 'number' and type(saledata) == 'table' and type(saledata.timestamp) == 'number') then
                table.insert(purchases_data[itemid][versionid]['sales'], saledata)
              end
            end
            local _, first = next(versiondata['sales'], nil)
            if first then
              purchases_data[itemid][versionid].itemIcon = GetItemLinkInfo(first.itemLink)
              purchases_data[itemid][versionid].itemAdderText = internal:AddSearchToItem(first.itemLink)
              purchases_data[itemid][versionid].itemDesc = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(first.itemLink))
            end
          end
        else
          purchases_data[itemid][versionid] = versiondata
        end
      end
      savedVars[itemid] = nil
    else
      purchases_data[itemid] = versionlist
    end
  end
end
