local lib = _G["LibGuildStore"]
local internal = _G["LibGuildStore_Internal"]
local purchases_data = _G["LibGuildStore_PurchaseData"]
local pr_index = _G["LibGuildStore_PurchaseIndex"]

function internal:CheckForDuplicatePurchase(itemLink, eventID)
  local theIID = GetItemLinkItemId(itemLink)
  if theIID == nil or theIID == 0 then return end
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)

  if purchases_data[theIID] and purchases_data[theIID][itemIndex] then
    for k, v in pairs(purchases_data[theIID][itemIndex]['sales']) do
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
    for k, v in pairs(purchases_data[theIID][itemIndex]['sales']) do
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
  --internal:dm("Debug", theEvent)
  local linkHash = internal:AddSalesTableData("itemLink", theEvent.itemLink)
  local buyerHash = internal:AddSalesTableData("accountNames", theEvent.buyer)
  local sellerHash = internal:AddSalesTableData("accountNames", theEvent.seller)
  local guildHash = internal:AddSalesTableData("guildNames", theEvent.guild)

  local itemIndex = internal.GetOrCreateIndexFromLink(theEvent.itemLink)
  local theIID = GetItemLinkItemId(theEvent.itemLink)
  if theIID == nil or theIID == 0 then return false end

  if not purchases_data[theIID] then
    purchases_data[theIID] = internal:SetPurchaseData(theIID)
  end
  local newEvent = ZO_DeepTableCopy(theEvent)
  newEvent.itemLink = linkHash
  newEvent.buyer = buyerHash
  newEvent.seller = sellerHash
  newEvent.guild = guildHash

  local insertedIndex = 1
  local searchItemDesc = ""
  local searchItemAdderText = ""
  if purchases_data[theIID][itemIndex] then
    searchItemDesc = purchases_data[theIID][itemIndex].itemDesc
    searchItemAdderText = purchases_data[theIID][itemIndex].itemAdderText
    table.insert(purchases_data[theIID][itemIndex]['sales'], newEvent)
    insertedIndex = #purchases_data[theIID][itemIndex]['sales']
  else
    if purchases_data[theIID][itemIndex] == nil then purchases_data[theIID][itemIndex] = {} end
    if purchases_data[theIID][itemIndex]['sales'] == nil then purchases_data[theIID][itemIndex]['sales'] = {} end
    searchItemDesc = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(theEvent.itemLink))
    searchItemAdderText = internal:AddSearchToItem(theEvent.itemLink)
    purchases_data[theIID][itemIndex] = {
      itemIcon      = GetItemLinkInfo(theEvent.itemLink),
      itemAdderText = searchItemAdderText,
      itemDesc      = searchItemDesc,
      sales         = { newEvent } }
    --internal:dm("Debug", newEvent)
  end

  local playerName = zo_strlower(GetDisplayName())
  local isSelfSale = playerName == zo_strlower(theEvent.seller)

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
    if pr_index[i] == nil then pr_index[i] = {} end
    table.insert(pr_index[i], wordData)
    internal.pr_index_count = internal.pr_index_count + 1
  end

  return true
end

----------------------------------------
----- iterateOverPurchaseData  -----
----------------------------------------

function internal:iterateOverPurchaseData(itemid, versionid, saleid, prefunc, loopfunc, postfunc, extraData)
  extraData.versionCount = (extraData.versionCount or 0)
  extraData.idCount = (extraData.idCount or 0)
  extraData.checkMilliseconds = (extraData.checkMilliseconds or 20)

  if prefunc then
    prefunc(extraData)
  end

  local checkTime = GetGameTimeMilliseconds()
  local versionlist
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
            LEQ:ContinueWith(function() internal:iterateOverPurchaseData(itemid, versionid, saleid, nil, loopfunc,
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
        LEQ:ContinueWith(function() internal:iterateOverPurchaseData(itemid, versionid, saleid, nil, loopfunc, postfunc,
          extraData) end, nil)
        return
      end
    end

    if extraData.versionRemoved then
      local versions = {}
      for vid, vd in pairs(purchases_data[itemid]) do
        if (vd ~= nil) and (type(vd) == 'table') then
          versions[vid] = vd
        end
      end
      purchases_data[itemid] = versions
    end

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
    extraData.epochBack = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * LibGuildStore_SavedVariables["historyDepthSL"])
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
    extraData.checkMilliseconds = ZO_ONE_MINUTE_IN_SECONDS
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

    local playerName = zo_strlower(GetDisplayName())
    local selfSale = playerName == zo_strlower(currentSeller)
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
      searchText = zo_strlower(table.concat(temp, ''))
    end

    -- Index each word
    local searchByWords = zo_strgmatch(searchText, '%S+')
    local wordData = { numberID, itemData, itemIndex }
    for i in searchByWords do
      if pr_index[i] == nil then
        extraData.wordsIndexCount = extraData.wordsIndexCount + 1
        pr_index[i] = {}
      end
      table.insert(pr_index[i], wordData)
      internal.pr_index_count = internal.pr_index_count + 1
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
  end

  if internal.purchasedBuyer == nil then
    internal.purchasedBuyer = {}
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

      if not internal.purchasedItems[currentGuild] then
        internal.purchasedItems[currentGuild] = MMGuild:new(currentGuild)
      end
      local guild = internal.purchasedItems[currentGuild]
      local _, firstsaledata = next(versiondata.sales, nil)
      local firstsaledataItemLink = internal:GetItemLinkByIndex(firstsaledata.itemLink)
      local searchDataDesc = versiondata.itemDesc or zo_strformat(SI_TOOLTIP_ITEM_NAME,
        GetItemLinkName(firstsaledataItemLink))
      local searchDataAdder = versiondata.itemAdderText or internal:AddSearchToItem(firstsaledataItemLink)
      local searchData = searchDataDesc .. ' ' .. searchDataAdder
      guild:addSaleByDate(firstsaledataItemLink, saledata.timestamp, saledata.price, saledata.quant, false, false, searchData)

      if not internal.purchasedBuyer[currentGuild] then
        internal.purchasedBuyer[currentGuild] = MMGuild:new(currentGuild)
      end
      local guild = internal.purchasedBuyer[currentGuild]
      guild:addSaleByDate(currentBuyer, saledata.timestamp, saledata.price, saledata.quant, saledata.wasKiosk, false)

    end
    return false
  end

  local postfunc = function(extraData)

    for _, guild in pairs(internal.purchasedItems) do
      guild:sort()
    end

    for guildName, guild in pairs(internal.purchasedBuyer) do
      guild:sort()
    end

    internal:DatabaseBusy(false)

    internal.totalPurchases = extraData.totalRecords
    if LibGuildStore_SavedVariables["showGuildInitSummary"] then
      internal:dm("Info", string.format(GetString(GS_INIT_PURCHASES_HISTORY_SUMMARY), GetTimeStamp() - extraData.start,
        internal.totalPurchases))
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
