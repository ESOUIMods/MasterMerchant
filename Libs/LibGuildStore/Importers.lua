local internal = _G["LibGuildStore_Internal"]
local mm_sales_data = _G["LibGuildStore_MM_SalesData"]
local att_sales_data = _G["LibGuildStore_ATT_SalesData"]

----------------------------------------
----- ImportPricingData           -----
----------------------------------------
function internal:ImportPricingData()
  local svFile = GS17DataSavedVariables
  local namespace = internal.pricingNamespace
  local pricingData = ShopkeeperSavedVars["Default"]["MasterMerchant"]["$AccountWide"]["pricingData"]
  svFile[namespace]["pricingdataall"] = pricingData
end

----------------------------------------
----- ImportShoppingList           -----
----------------------------------------

function internal:ImportShoppingList()
  if not ShoppingList then
    internal:dm("Info", GetString(GS_SHOPPINGLIST_MISSING))
    return
  end
  internal:dm("Debug", "ImportShoppingList")

  --[[
  ["Buyer"] = 1,
  ["itemUniqueId"] = "4872182274625497492",
  ["Price"] = 130,
  ["Quantity"] = 1,
  ["Guild"] = 30,
  ["TimeStamp"] = 1616280476,
  ["Seller"] = 60,
  ["ItemLink"] = 58,
  ]]--
  for i = 1, #ShoppingListVar.Default.ShoppingList["$AccountWide"].Purchases do
    local theEvent = {
      guild = ShoppingList.SavedData.System.Tables["Guilds"][ShoppingList.SavedData.System.Purchases[i]["Guild"]],
      itemLink = ShoppingList.SavedData.System.Tables["ItemLinks"][ShoppingList.SavedData.System.Purchases[i]["ItemLink"]],
      quant = ShoppingList.SavedData.System.Purchases[i]["Quantity"],
      timestamp = ShoppingList.SavedData.System.Purchases[i]["TimeStamp"],
      price = ShoppingList.SavedData.System.Purchases[i]["Price"],
      seller = ShoppingList.SavedData.System.Tables["Sellers"][ShoppingList.SavedData.System.Purchases[i]["Seller"]],
      buyer = ShoppingList.SavedData.System.Tables["Buyers"][ShoppingList.SavedData.System.Purchases[i]["Buyer"]],
      id = ShoppingList.SavedData.System.Purchases[i]["itemUniqueId"],
    }
    local duplicate = internal:CheckForDuplicatePurchase(theEvent.itemLink, theEvent.id)
    if not duplicate then
      internal:addPurchaseData(theEvent)
    end
  end
  MasterMerchant.purchasesScrollList:RefreshFilters()
  internal:dm("Info", GetString(GS_SHOPPINGLIST_IMPORTED))
end

----------------------------------------
----- ImportMasterMerchantSales    -----
----------------------------------------

function internal:ImportMasterMerchantSales()

  local prefunc = function(extraData)
    extraData.start = GetTimeStamp()
    extraData.checkMilliseconds = MM_WAIT_TIME_IN_MILLISECONDS_MEDIUM
    extraData.eventIdIsNumber = 0
    extraData.badItemLinkCount = 0
    extraData.wasAltered = false
    extraData.totalSales = 0

    internal:DatabaseBusy(true)
  end

  local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData)
    local daysOfHistoryToKeep = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * LibGuildStore_SavedVariables["historyDepth"])
    if (saledata['timestamp'] > daysOfHistoryToKeep) or not LibGuildStore_SavedVariables["useSalesHistory"] then
      local duplicate = internal:CheckForDuplicateSale(saledata['itemLink'], saledata['id'])
      if not duplicate then
        internal:addSalesData(saledata)
      end
    end
    extraData.totalSales = extraData.totalSales + 1
  end

  local postfunc = function(extraData)
    internal:dm("Info", string.format(GetString(GS_ELAPSED_TIME_FORMATTER), GetTimeStamp() - extraData.start, extraData.totalSales))

    local LEQ = LibExecutionQueue:new()
    if extraData.totalSales > 0 then
      internal:dm("Info", GetString(GS_REINDEXING_EVERYTHING))
      --rebuild everything
      local sr_index = {}
      _G["LibGuildStore_SalesIndex"] = sr_index
      internal.sr_index_count = 0

      internal.guildPurchases = {}
      internal.guildSales = {}
      internal.guildItems = {}
      internal.myItems = {}
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
    internal:dm("Debug", "ImportMasterMerchantSales")
    internal:IterateoverMMSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

end

function internal:ImportATTSales()
  local prefunc = function(extraData)
    extraData.start = GetTimeStamp()
    extraData.checkMilliseconds = MM_WAIT_TIME_IN_MILLISECONDS_MEDIUM
    extraData.eventIdIsNumber = 0
    extraData.badItemLinkCount = 0
    extraData.wasAltered = false
    extraData.totalSales = 0

    internal:DatabaseBusy(true)
  end

  local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData)
    local daysOfHistoryToKeep = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * LibGuildStore_SavedVariables["historyDepth"])
    if (saledata['timestamp'] > daysOfHistoryToKeep) then
      local duplicate = internal:CheckForDuplicateSale(saledata['itemLink'], saledata['id'])
      if not duplicate then
        internal:addSalesData(saledata)
      end
    end
    extraData.totalSales = extraData.totalSales + 1
  end

  local postfunc = function(extraData)
    internal:dm("Info", string.format(GetString(GS_ELAPSED_TIME_FORMATTER), GetTimeStamp() - extraData.start, extraData.totalSales))

    local LEQ = LibExecutionQueue:new()
    if extraData.totalSales > 0 then
      internal:dm("Info", GetString(GS_REINDEXING_EVERYTHING))
      --rebuild everything
      local sr_index = {}
      _G["LibGuildStore_SalesIndex"] = sr_index
      internal.sr_index_count = 0

      internal.guildPurchases = {}
      internal.guildSales = {}
      internal.guildItems = {}
      internal.myItems = {}
      LEQ:addTask(function() internal:RenewExtraSalesDataAllContainers() end, 'RenewExtraSalesDataAllContainers')
      LEQ:addTask(function() internal:InitSalesHistory() end, 'InitSalesHistory')
      LEQ:addTask(function() internal:IndexSalesData() end, 'indexHistoryTables')
      LEQ:addTask(function() internal:dm("Info", GetString(GS_REINDEXING_COMPLETE)) end, 'Done')
    end

    LEQ:addTask(function() internal:DatabaseBusy(false) end, 'DatabaseBusy')
    LEQ:addTask(function() internal:dm("Info", GetString(GS_IMPORT_ATT_FINISHED)) end, 'Done')
    LEQ:start()
  end

  if not internal.isDatabaseBusy then
    internal:dm("Debug", "ImportATTSales")
    internal:IterateoverATTSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

end

----------------------------------------
----- Iterate over MM Sales Data   -----
----------------------------------------

function internal:IterateoverMMSalesData(itemid, versionid, saleid, prefunc, loopfunc, postfunc, extraData)
  extraData.versionCount = (extraData.versionCount or 0)
  extraData.idCount = (extraData.idCount or 0)
  extraData.checkMilliseconds = (extraData.checkMilliseconds or MM_WAIT_TIME_IN_MILLISECONDS_DEFAULT)

  if prefunc then
    prefunc(extraData)
  end

  local checkTime = GetGameTimeMilliseconds()
  local versionlist
  if itemid == nil then
    itemid, versionlist = next(mm_sales_data, itemid)
    extraData.versionRemoved = false
    versionid = nil
  else
    versionlist = mm_sales_data[itemid]
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
            LEQ:continueWith(function() internal:IterateoverMMSalesData(itemid, versionid, saleid, nil, loopfunc, postfunc, extraData) end, nil)
            return
          end
        end

        if extraData.saleRemoved then
          local sales = {}
          for _, sd in pairs(versiondata['sales']) do
            if (sd ~= nil) and (type(sd) == 'table') then
              table.insert(sales, sd)
            end
          end
          versiondata['sales'] = sales
        end
      end

      -- If we just deleted all the sales, clear the bucket out
      if (versionlist[versionid] ~= nil and ((versiondata['sales'] == nil) or (internal:NonContiguousNonNilCount(versiondata['sales']) < 1) or (not zo_strmatch(tostring(versionid), "^%d+:%d+:%d+:%d+:%d+")))) then
        extraData.versionCount = (extraData.versionCount or 0) + 1
        versionlist[versionid] = nil
        extraData.versionRemoved = true
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
        LEQ:continueWith(function() internal:IterateoverMMSalesData(itemid, versionid, saleid, nil, loopfunc, postfunc, extraData) end, nil)
        return
      end
    end

    if extraData.versionRemoved then
      local versions = {}
      for vid, vd in pairs(mm_sales_data[itemid]) do
        if (vd ~= nil) and (type(vd) == 'table') then
          versions[vid] = vd
        end
      end
      mm_sales_data[itemid] = versions
    end

    if (mm_sales_data[itemid] ~= nil and ((internal:NonContiguousNonNilCount(versionlist) < 1) or (type(itemid) ~= 'number'))) then
      extraData.idCount = (extraData.idCount or 0) + 1
      mm_sales_data[itemid] = nil
    end

    -- Go on to the next Item
    itemid, versionlist = next(mm_sales_data, itemid)
    extraData.versionRemoved = false
    versionid = nil
  end

  if postfunc then
    postfunc(extraData)
  end
end

----------------------------------------
----- Iterate over ATT Sales Data   -----
----------------------------------------

function internal:IterateoverATTSalesData(itemid, versionid, saleid, prefunc, loopfunc, postfunc, extraData)
  extraData.versionCount = (extraData.versionCount or 0)
  extraData.idCount = (extraData.idCount or 0)
  extraData.checkMilliseconds = (extraData.checkMilliseconds or MM_WAIT_TIME_IN_MILLISECONDS_DEFAULT)

  if prefunc then
    prefunc(extraData)
  end

  local checkTime = GetGameTimeMilliseconds()
  local versionlist
  if itemid == nil then
    itemid, versionlist = next(att_sales_data, itemid)
    extraData.versionRemoved = false
    versionid = nil
  else
    versionlist = att_sales_data[itemid]
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
            LEQ:continueWith(function() internal:IterateoverATTSalesData(itemid, versionid, saleid, nil, loopfunc,
              postfunc,
              extraData) end, nil)
            return
          end
        end

        if extraData.saleRemoved then
          local sales = {}
          for _, sd in pairs(versiondata['sales']) do
            if (sd ~= nil) and (type(sd) == 'table') then
              table.insert(sales, sd)
            end
          end
          versiondata['sales'] = sales
        end
      end

      -- If we just deleted all the sales, clear the bucket out
      if (versionlist[versionid] ~= nil and ((versiondata['sales'] == nil) or (internal:NonContiguousNonNilCount(versiondata['sales']) < 1) or (not zo_strmatch(tostring(versionid), "^%d+:%d+:%d+:%d+:%d+")))) then
        extraData.versionCount = (extraData.versionCount or 0) + 1
        versionlist[versionid] = nil
        extraData.versionRemoved = true
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
        LEQ:continueWith(function() internal:IterateoverATTSalesData(itemid, versionid, saleid, nil, loopfunc, postfunc,
          extraData) end, nil)
        return
      end
    end

    if extraData.versionRemoved then
      local versions = {}
      for vid, vd in pairs(att_sales_data[itemid]) do
        if (vd ~= nil) and (type(vd) == 'table') then
          versions[vid] = vd
        end
      end
      att_sales_data[itemid] = versions
    end

    if (att_sales_data[itemid] ~= nil and ((internal:NonContiguousNonNilCount(versionlist) < 1) or (type(itemid) ~= 'number'))) then
      extraData.idCount = (extraData.idCount or 0) + 1
      att_sales_data[itemid] = nil
    end

    -- Go on to the next Item
    itemid, versionlist = next(att_sales_data, itemid)
    extraData.versionRemoved = false
    versionid = nil
  end

  if postfunc then
    postfunc(extraData)
  end
end

----------------------------------------
----- Reference MM Sales Data      -----
----------------------------------------

-- Bring seperate lists together we can still access the sales history all together
function internal:ReferenceAllMMSales()
  if not MM00Data then return end
  internal:dm("Debug", "Bring AllMMSales data together")
  internal:ReferenceMMSales(MM00DataSavedVariables)
  internal:ReferenceMMSales(MM01DataSavedVariables)
  internal:ReferenceMMSales(MM02DataSavedVariables)
  internal:ReferenceMMSales(MM03DataSavedVariables)
  internal:ReferenceMMSales(MM04DataSavedVariables)
  internal:ReferenceMMSales(MM05DataSavedVariables)
  internal:ReferenceMMSales(MM06DataSavedVariables)
  internal:ReferenceMMSales(MM07DataSavedVariables)
  internal:ReferenceMMSales(MM08DataSavedVariables)
  internal:ReferenceMMSales(MM09DataSavedVariables)
  internal:ReferenceMMSales(MM10DataSavedVariables)
  internal:ReferenceMMSales(MM11DataSavedVariables)
  internal:ReferenceMMSales(MM12DataSavedVariables)
  internal:ReferenceMMSales(MM13DataSavedVariables)
  internal:ReferenceMMSales(MM14DataSavedVariables)
  internal:ReferenceMMSales(MM15DataSavedVariables)
end

function internal:ReferenceMMSales(otherData)
  local savedVars = otherData.Default.MasterMerchant["$AccountWide"].SalesData

  for itemid, versionlist in pairs(savedVars) do
    if mm_sales_data[itemid] then
      for versionid, versiondata in pairs(versionlist) do
        if mm_sales_data[itemid][versionid] then
          if versiondata['sales'] then
            mm_sales_data[itemid][versionid]['sales'] = mm_sales_data[itemid][versionid]['sales'] or {}
            -- IPAIRS
            for saleid, saledata in pairs(versiondata['sales']) do
              if (type(saleid) == 'number' and type(saledata) == 'table' and type(saledata.timestamp) == 'number') then
                table.insert(mm_sales_data[itemid][versionid]['sales'], saledata)
              end
            end
            local _, first = next(versiondata['sales'], nil)
            if first then
              mm_sales_data[itemid][versionid].itemIcon = GetItemLinkInfo(first.itemLink)
              mm_sales_data[itemid][versionid].itemAdderText = internal:AddSearchToItem(first.itemLink)
              mm_sales_data[itemid][versionid].itemDesc = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(first.itemLink))
            end
          end
        else
          mm_sales_data[itemid][versionid] = versiondata
        end
      end
      savedVars[itemid] = nil
    else
      mm_sales_data[itemid] = versionlist
    end
  end
end

----------------------------------------
----- Reference ATT Sales Data      -----
----------------------------------------
local idNumbers = {}
local idData = {}
-- Bring seperate lists together we can still access the sales history all together
function internal:ReferenceAllATTSales()
  if not MasterMerchant then return end
  if not ArkadiusTradeToolsSalesData01 then return end
  internal:dm("Debug", "Bring AllATTSales data together")
  internal:ReferenceATTSales(ArkadiusTradeToolsSalesData01)
  internal:ReferenceATTSales(ArkadiusTradeToolsSalesData02)
  internal:ReferenceATTSales(ArkadiusTradeToolsSalesData03)
  internal:ReferenceATTSales(ArkadiusTradeToolsSalesData04)
  internal:ReferenceATTSales(ArkadiusTradeToolsSalesData05)
  internal:ReferenceATTSales(ArkadiusTradeToolsSalesData06)
  internal:ReferenceATTSales(ArkadiusTradeToolsSalesData07)
  internal:ReferenceATTSales(ArkadiusTradeToolsSalesData08)
  internal:ReferenceATTSales(ArkadiusTradeToolsSalesData09)
  internal:ReferenceATTSales(ArkadiusTradeToolsSalesData10)
  internal:ReferenceATTSales(ArkadiusTradeToolsSalesData11)
  internal:ReferenceATTSales(ArkadiusTradeToolsSalesData12)
  internal:ReferenceATTSales(ArkadiusTradeToolsSalesData13)
  internal:ReferenceATTSales(ArkadiusTradeToolsSalesData14)
  internal:ReferenceATTSales(ArkadiusTradeToolsSalesData15)
  internal:ReferenceATTSales(ArkadiusTradeToolsSalesData16)
  internal.aa_temp = idData
end

function internal:ReferenceATTSales(otherData)
  local attMegaserver = ""
  if GetWorldName() == 'NA Megaserver' then
    attMegaserver = "NA Megaserver"
  else
    attMegaserver = "EU Megaserver"
  end
  local savedVars = otherData[attMegaserver]['sales']

  local theEvent = {}
  local guildId = 0
  for saleId, saleData in pairs(savedVars) do
    theEvent = {
      buyer = saleData["buyerName"],
      guild = saleData["guildName"],
      itemLink = saleData["itemLink"],
      quant = saleData["quantity"],
      timestamp = saleData["timeStamp"],
      price = saleData["price"],
      seller = saleData["sellerName"],
      wasKiosk = false,
      id = tostring(saleId),
    }
    --[[ TODO come up with a way to use wasKiosk when possible. The
    issue is that you only have access to the guilds you belong to
    for the account you are logged into at the time. Meaning, someone
    on an NA server importing data from EU would not have access
    to guild member information.

    Likewise if someone is on account A and not account B then any guild
    member names from account B will not be found, and wasKiosk won't
    be accurate. Should possibly use 3 constants and update sales when
    someone loggs into another account.

    internal.NON_GUILD_MEMBER_PURCHASE = 0
    internal.GUILD_MEMBER_PURCHASE = 1
    internal.IMPORTED_PURCHASE = 2
    ]]--
    local guildFound = false
    for k, v in pairs(internal.currentGuilds) do
      if theEvent.guild == v then
        guildId = k
        guildFound = true
        break
      end
    end
    if guildFound then
      theEvent.wasKiosk = (internal.guildMemberInfo[guildId][zo_strlower(theEvent.buyer)] == nil)
    end
    local theIID = GetItemLinkItemId(theEvent.itemLink)
    local itemIndex = internal.GetOrCreateIndexFromLink(theEvent.itemLink)
    if att_sales_data[theIID] == nil then att_sales_data[theIID] = {} end
    if att_sales_data[theIID][itemIndex] == nil then
      att_sales_data[theIID][itemIndex] = {}
      att_sales_data[theIID][itemIndex].itemIcon = GetItemLinkInfo(theEvent.itemLink)
      att_sales_data[theIID][itemIndex].itemAdderText = internal:AddSearchToItem(theEvent.itemLink)
      att_sales_data[theIID][itemIndex].itemDesc = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(theEvent.itemLink))
    end
    if att_sales_data[theIID][itemIndex]['sales'] == nil then att_sales_data[theIID][itemIndex]['sales'] = {} end
    if not idNumbers[saleId] then
      idNumbers[saleId] = true
      table.insert(idData, { saleId })
    else
      --internal:dm("Info", "Id exists")
    end
    table.insert(att_sales_data[theIID][itemIndex]['sales'], theEvent)
  end
end

-- /script LibGuildStore_Internal:CompareItemIds(GS00DataSavedVariables)
-- loops over item IDs and reports duplicates
-- DEBUG CompareSalesIds
function internal:CompareSalesIds()
  internal:dm("Debug", "CompareSalesIds")
  local itemIds = {}
  for _, itemData in pairs(att_sales_data) do
    for _, itemIndexData in pairs(itemData) do
      for _, sale in pairs(itemIndexData['sales']) do
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

function internal:ImportATTPurchases()
  if not ArkadiusTradeToolsPurchasesData then
    internal:dm("Info", GetString(GS_ATT_PURCHASE_DATA_MISSING))
    return
  end
  local attMegaserver = ""
  if GetWorldName() == 'NA Megaserver' then
    attMegaserver = "NA Megaserver"
  else
    attMegaserver = "EU Megaserver"
  end
  local savedVars = ArkadiusTradeToolsPurchasesData["purchases"][attMegaserver]

  --[[
  [1] =
  {
      ["buyerName"] = "@Sharlikran",
      ["timeStamp"] = 1621734922,
      ["unitPrice"] = 2500,
      ["quantity"] = 1,
      ["price"] = 2500,
      ["guildName"] = "The Descendants",
      ["itemLink"] = "|H0:item:167362:4:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h",
      ["sellerName"] = "@mscherer400",
  },
  ]]--
  local theEvent = {}
  for _, saleData in pairs(savedVars) do
    theEvent = {
      buyer = saleData["buyerName"],
      guild = saleData["guildName"],
      itemLink = saleData["itemLink"],
      quant = saleData["quantity"],
      timestamp = saleData["timeStamp"],
      price = saleData["price"],
      seller = saleData["sellerName"],
    }
    local duplicate = internal:CheckForDuplicateATTPurchase(theEvent)
    if not duplicate then
      internal:addPurchaseData(theEvent)
    end
  end
  MasterMerchant.purchasesScrollList:RefreshFilters()
  internal:dm("Info", GetString(GS_ATT_PURCHASE_DATA_IMPORTED))
end
