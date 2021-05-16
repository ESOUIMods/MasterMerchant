local lib            = _G["LibGuildStore"]
local internal       = _G["LibGuildStore_Internal"]
local sr_index       = _G["LibGuildStore_SalesIndex"]
local mm_sales_data  = _G["LibGuildStore_MM_SalesData"]
local att_sales_data = _G["LibGuildStore_ATT_SalesData"]

local ASYNC          = LibAsync

----------------------------------------
----- iterateOverSalesData         -----
----------------------------------------

function internal:ImportMasterMerchantSales()

  local prefunc  = function(extraData)
    extraData.start             = GetTimeStamp()
    extraData.checkMilliseconds = ZO_ONE_MINUTE_IN_SECONDS
    extraData.eventIdIsNumber   = 0
    extraData.badItemLinkCount  = 0
    extraData.wasAltered        = false
    extraData.totalSales        = 0

    internal:DatabaseBusy(true)
  end

  local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData)
    local daysOfHistoryToKeep = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * LibGuildStore_SavedVariables["historyDepth"])
    if (saledata['timestamp'] > daysOfHistoryToKeep) then
      local duplicate = internal:CheckForDuplicate(saledata['itemLink'], saledata['id'])
      if not duplicate then
        local added = internal:addToHistoryTables(saledata)
      end
    end
    extraData.totalSales = extraData.totalSales + 1
  end

  local postfunc = function(extraData)
    internal:dm("Info",
      string.format("%s seconds to process %s records", GetTimeStamp() - extraData.start, extraData.totalSales))

    local LEQ = LibExecutionQueue:new()
    if extraData.totalSales > 0 then
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
    internal:IterateoverMMSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

end

function internal:ImportATTSales()
  local prefunc  = function(extraData)
    extraData.start             = GetTimeStamp()
    extraData.checkMilliseconds = ZO_ONE_MINUTE_IN_SECONDS
    extraData.eventIdIsNumber   = 0
    extraData.badItemLinkCount  = 0
    extraData.wasAltered        = false
    extraData.totalSales        = 0

    internal:DatabaseBusy(true)
  end

  local loopfunc = function(itemid, versionid, versiondata, saleid, saledata, extraData)
    local daysOfHistoryToKeep = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * LibGuildStore_SavedVariables["historyDepth"])
    if (saledata['timestamp'] > daysOfHistoryToKeep) then
      local duplicate = internal:CheckForDuplicate(saledata['itemLink'], saledata['id'])
      if not duplicate then
        local added = internal:addToHistoryTables(saledata)
      end
    end
    extraData.totalSales = extraData.totalSales + 1
  end

  local postfunc = function(extraData)
    internal:dm("Info",
      string.format("%s seconds to process %s records", GetTimeStamp() - extraData.start, extraData.totalSales))

    local LEQ = LibExecutionQueue:new()
    if extraData.totalSales > 0 then
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
    internal:IterateoverATTSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

end

----------------------------------------
----- Iterate over MM Sales Data   -----
----------------------------------------

function internal:IterateoverMMSalesData(itemid, versionid, saleid, prefunc, loopfunc, postfunc, extraData)
  extraData.versionCount      = (extraData.versionCount or 0)
  extraData.idCount           = (extraData.idCount or 0)
  extraData.checkMilliseconds = (extraData.checkMilliseconds or 20)

  if prefunc then
    prefunc(extraData)
  end

  local checkTime = GetGameTimeMilliseconds()
  local versionlist
  if itemid == nil then
    itemid, versionlist      = next(mm_sales_data, itemid)
    extraData.versionRemoved = false
    versionid                = nil
  else
    versionlist = mm_sales_data[itemid]
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
            LEQ:ContinueWith(function() internal:IterateoverMMSalesData(itemid, versionid, saleid, nil, loopfunc,
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
        extraData.versionCount   = (extraData.versionCount or 0) + 1
        versionlist[versionid]   = nil
        extraData.versionRemoved = true
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
        LEQ:ContinueWith(function() internal:IterateoverMMSalesData(itemid, versionid, saleid, nil, loopfunc, postfunc,
          extraData) end, nil)
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
      extraData.idCount     = (extraData.idCount or 0) + 1
      mm_sales_data[itemid] = nil
    end

    -- Go on to the next Item
    itemid, versionlist      = next(mm_sales_data, itemid)
    extraData.versionRemoved = false
    versionid                = nil
  end

  if postfunc then
    postfunc(extraData)
  end
end

----------------------------------------
----- Iterate over ATT Sales Data   -----
----------------------------------------

function internal:IterateoverATTSalesData(itemid, versionid, saleid, prefunc, loopfunc, postfunc, extraData)
  extraData.versionCount      = (extraData.versionCount or 0)
  extraData.idCount           = (extraData.idCount or 0)
  extraData.checkMilliseconds = (extraData.checkMilliseconds or 20)

  if prefunc then
    prefunc(extraData)
  end

  local checkTime = GetGameTimeMilliseconds()
  local versionlist
  if itemid == nil then
    itemid, versionlist      = next(att_sales_data, itemid)
    extraData.versionRemoved = false
    versionid                = nil
  else
    versionlist = att_sales_data[itemid]
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
            LEQ:ContinueWith(function() internal:IterateoverATTSalesData(itemid, versionid, saleid, nil, loopfunc,
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
        extraData.versionCount   = (extraData.versionCount or 0) + 1
        versionlist[versionid]   = nil
        extraData.versionRemoved = true
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
        LEQ:ContinueWith(function() internal:IterateoverATTSalesData(itemid, versionid, saleid, nil, loopfunc, postfunc,
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
      extraData.idCount      = (extraData.idCount or 0) + 1
      att_sales_data[itemid] = nil
    end

    -- Go on to the next Item
    itemid, versionlist      = next(att_sales_data, itemid)
    extraData.versionRemoved = false
    versionid                = nil
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
          if versiondata.sales then
            mm_sales_data[itemid][versionid].sales = mm_sales_data[itemid][versionid].sales or {}
            -- IPAIRS
            for saleid, saledata in pairs(versiondata.sales) do
              if (type(saleid) == 'number' and type(saledata) == 'table' and type(saledata.timestamp) == 'number') then
                table.insert(mm_sales_data[itemid][versionid].sales, saledata)
              end
            end
            local _, first = next(versiondata.sales, nil)
            if first then
              mm_sales_data[itemid][versionid].itemIcon      = GetItemLinkInfo(first.itemLink)
              mm_sales_data[itemid][versionid].itemAdderText = internal:AddSearchToItem(first.itemLink)
              mm_sales_data[itemid][versionid].itemDesc      = zo_strformat(SI_TOOLTIP_ITEM_NAME,
                GetItemLinkName(first.itemLink))
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
local idData    = {}
-- Bring seperate lists together we can still access the sales history all together
function internal:ReferenceAllATTSales()
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
  local savedVars    = otherData[attMegaserver]["sales"]

  local theEvent     = {}
  local addedCount   = 0
  local skippedCount = 0
  local guildId      = 0
  for saleId, saleData in pairs(savedVars) do
    theEvent         = {
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
    local guildFound = false
    for k, v in pairs(LibHistoire_GuildNames[attMegaserver]) do
      if theEvent.guild == v then
        guildId    = k
        guildFound = true
        break
      end
    end
    if guildFound then
      theEvent.wasKiosk = (internal.guildMemberInfo[guildId][zo_strlower(theEvent.buyer)] == nil)
    end
    local theIID    = GetItemLinkItemId(theEvent.itemLink)
    local itemIndex = internal.GetOrCreateIndexFromLink(theEvent.itemLink)
    if att_sales_data[theIID] == nil then att_sales_data[theIID] = {} end
    if att_sales_data[theIID][itemIndex] == nil then
      att_sales_data[theIID][itemIndex]               = {}
      att_sales_data[theIID][itemIndex].itemIcon      = GetItemLinkInfo(theEvent.itemLink)
      att_sales_data[theIID][itemIndex].itemAdderText = internal:AddSearchToItem(theEvent.itemLink)
      att_sales_data[theIID][itemIndex].itemDesc      = zo_strformat(SI_TOOLTIP_ITEM_NAME,
        GetItemLinkName(theEvent.itemLink))
    end
    if att_sales_data[theIID][itemIndex]["sales"] == nil then att_sales_data[theIID][itemIndex]["sales"] = {} end
    if not idNumbers[saleId] then
      idNumbers[saleId] = true
      table.insert(idData, { saleId })
    else
      internal:dm("Info", "Id exists")
    end
    table.insert(att_sales_data[theIID][itemIndex]["sales"], theEvent)
  end
end
