local internal = _G["LibGuildStore_Internal"]

local ASYNC = LibAsync

----------------------------------------
----- Helpers                      -----
----------------------------------------

-- DEBUG CompareItemIds
function internal:CompareItemIds(dataset)
  internal:dm("Debug", "CompareItemIds")
  local saveData = dataset[internal.dataNamespace]
  local itemIds = {}
  for _, itemData in pairs(saveData) do
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

-- /script d(LibGuildStore_Internal:IsValidItemLink("|H0:item:100042:363:50:0:0:0:0:0:0:0:0:0:0:0:0:8:0:0:0:10000:0|h|h"))
-- /script d(GetItemLinkItemId("|H0:item:100042:363:50:0:0:0:0:0:0:0:0:0:0:0:0:8:0:0:0:10000:0|h|h"))
-- /script d(GetItemLinkItemId("|H0:item:69806:22:40:26582:21:35:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"))
-- /script d(tonumber(zo_strmatch("|H0:item:69806:22:40:26582:21:35:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h", '|H.-:item:(.-):')))
-- "|H0:item:69806:22:40:26582:21:35:0:0:0:0:0:0:0:0:0:1:0:0:0:10000:0|h|h"
function internal:IsValidItemLink(itemLink)
  -- itemLink should be the full link here
  local validLink = true
  local itemCodeText = MasterMerchant.ItemCodeText(itemLink)
  local theIID = GetItemLinkItemId(itemLink)
  local itemIdMatch = tonumber(zo_strmatch(itemLink, '|H.-:item:(.-):'))
  local itemlinkName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink))
  local _, count = zo_strgsub(itemLink, ':', ':')

  if count ~= 22 then
    internal:dm("Debug", "count ~= 22")
    validLink = false
  end
  if not theIID then
    internal:dm("Debug", "theIID was nil I guess?")
    validLink = false
  end
  if theIID and (theIID ~= itemIdMatch) then
    validLink = false
    internal:dm("Debug", "theIID ~= itemIdMatch")
  end
  if internal:is_empty_or_nil(itemlinkName) then
    internal:dm("Debug", "itemlinkName was empty or nil")
    validLink = false
  end
  if not validLink then
    internal:dm("Debug", itemCodeText)
    internal:dm("Debug", theIID)
    internal:dm("Debug", itemIdMatch)
  end
  return validLink, theIID, itemIdMatch
end

----------------------------------------
----- Functions                    -----
----------------------------------------

function internal:RenewExtraSalesData(otherData)
  local savedVars = otherData[internal.dataNamespace]

  for itemID, versionlist in pairs(savedVars) do
    for versionid, versiondata in pairs(versionlist) do
      if versiondata["wasAltered"] then
        local totalCount = NonContiguousCount(versiondata['sales'])  -- Count the sales entries
        local timestamps = {}  -- Gather timestamps for oldest and newest time
        for saleid, saledata in pairs(versiondata['sales']) do
          table.insert(timestamps, saledata["timestamp"])
        end

        -- Find oldest and newest time from timestamps
        local oldestTime = zo_min(unpack(timestamps))
        local newestTime = zo_max(unpack(timestamps))

        -- Update versiondata with calculated values
        savedVars[itemID][versionid].totalCount = totalCount
        savedVars[itemID][versionid].newestTime = newestTime
        savedVars[itemID][versionid].oldestTime = oldestTime
        savedVars[itemID][versionid].wasAltered = false
      end
    end
  end
end

function internal:RenewExtraListingsData(otherData)
  local savedVars = otherData[internal.listingsNamespace]

  for itemID, versionlist in pairs(savedVars) do
    for versionid, versiondata in pairs(versionlist) do
      if versiondata["wasAltered"] then
        local totalCount = NonContiguousCount(versiondata['sales'])  -- Count the sales entries
        local timestamps = {}  -- Gather timestamps for oldest and newest time
        for saleid, saledata in pairs(versiondata['sales']) do
          table.insert(timestamps, saledata["timestamp"])
        end

        -- Find oldest and newest time from timestamps
        local oldestTime = zo_min(unpack(timestamps))
        local newestTime = zo_max(unpack(timestamps))

        -- Update versiondata with calculated values
        savedVars[itemID][versionid].totalCount = totalCount
        savedVars[itemID][versionid].newestTime = newestTime
        savedVars[itemID][versionid].oldestTime = oldestTime
        savedVars[itemID][versionid].wasAltered = false
      end
    end
  end
end

function internal:RenewExtraPurchaseData(otherData)
  internal:dm("Debug", "RenewExtraPurchaseData")
  local savedVars = GS17DataSavedVariables[internal.purchasesNamespace]

  for itemID, versionlist in pairs(savedVars) do
    for versionid, versiondata in pairs(versionlist) do
      if versiondata["wasAltered"] then
        local totalCount = NonContiguousCount(versiondata['sales'])  -- Count the sales entries
        local timestamps = {}  -- Gather timestamps for oldest and newest time
        for saleid, saledata in pairs(versiondata['sales']) do
          table.insert(timestamps, saledata["timestamp"])
        end

        -- Find oldest and newest time from timestamps
        local oldestTime = zo_min(unpack(timestamps))
        local newestTime = zo_max(unpack(timestamps))

        -- Update versiondata with calculated values
        savedVars[itemID][versionid].totalCount = totalCount
        savedVars[itemID][versionid].newestTime = newestTime
        savedVars[itemID][versionid].oldestTime = oldestTime
        savedVars[itemID][versionid].wasAltered = false
      end
    end
  end
end

function internal:RenewExtraPostedData(otherData)
  internal:dm("Debug", "RenewExtraPostedData")
  local savedVars = GS17DataSavedVariables[internal.postedNamespace]

  for itemID, versionlist in pairs(savedVars) do
    for versionid, versiondata in pairs(versionlist) do
      if versiondata["wasAltered"] then
        local totalCount = NonContiguousCount(versiondata['sales'])  -- Count the sales entries
        local timestamps = {}  -- Gather timestamps for oldest and newest time
        for saleid, saledata in pairs(versiondata['sales']) do
          table.insert(timestamps, saledata["timestamp"])
        end

        -- Find oldest and newest time from timestamps
        local oldestTime = zo_min(unpack(timestamps))
        local newestTime = zo_max(unpack(timestamps))

        -- Update versiondata with calculated values
        savedVars[itemID][versionid].totalCount = totalCount
        savedVars[itemID][versionid].newestTime = newestTime
        savedVars[itemID][versionid].oldestTime = oldestTime
        savedVars[itemID][versionid].wasAltered = false
      end
    end
  end
end

function internal:RenewExtraCancelledData(otherData)
  internal:dm("Debug", "RenewExtraCancelledData")
  local savedVars = GS17DataSavedVariables[internal.cancelledNamespace]

  for itemID, versionlist in pairs(savedVars) do
    for versionid, versiondata in pairs(versionlist) do
      if versiondata["wasAltered"] then
        local totalCount = NonContiguousCount(versiondata['sales'])  -- Count the sales entries
        local timestamps = {}  -- Gather timestamps for oldest and newest time
        for saleid, saledata in pairs(versiondata['sales']) do
          table.insert(timestamps, saledata["timestamp"])
        end

        -- Find oldest and newest time from timestamps
        local oldestTime = zo_min(unpack(timestamps))
        local newestTime = zo_max(unpack(timestamps))

        -- Update versiondata with calculated values
        savedVars[itemID][versionid].totalCount = totalCount
        savedVars[itemID][versionid].newestTime = newestTime
        savedVars[itemID][versionid].oldestTime = oldestTime
        savedVars[itemID][versionid].wasAltered = false
      end
    end
  end
end

-- DEBUG VerifyItemLinks
function internal:VerifyItemLinks(hash, task)
  local saveFile = _G[string.format("GS%02dDataSavedVariables", hash)]
  local fileString = string.format("GS%02dDataSavedVariables", hash)
  task:Then(function(task) internal:dm("Debug", string.format("VerifyItemLinks for: %s", fileString)) end)
  task:Then(function(task) internal:dm("Debug", hash) end)
  local savedVars = saveFile[internal.dataNamespace]

  task:For(pairs(savedVars)):Do(function(_, itemIndex)
    task:For(pairs(itemIndex)):Do(function(_, itemIndexData)
      task:For(pairs(itemIndexData['sales'])):Do(function(_, saleData)
        local currentLink = internal:GetItemLinkByIndex(saleData.itemLink)
        local currentHash = internal:MakeHashStringByItemLink(currentLink)
        if currentHash ~= hash then
          task:Then(function(task) internal:dm("Debug", "sale in wrong file") end)
        end
      end)
    end)
  end)
end

-- Adds extra sales data to the provided sales data structure.
-- @param otherData The sales data from which to extract and add extra data.
function internal:AddExtraSalesData(otherData)
  local savedVars = otherData[internal.dataNamespace]

  -- Iterate through each itemID and versionlist pair in the savedVars.
  for itemID, versionlist in pairs(savedVars) do
    for versionid, versiondata in pairs(versionlist) do
      -- Check if the current versiondata has sales data.
      local hasSalesData = versiondata and versiondata['sales'] and next(versiondata['sales'])

      -- Check if totalCount is missing or if savedVars[itemID] is missing.
      if hasSalesData and (not savedVars[itemID] or not savedVars[itemID][versionid].totalCount) then
        local oldestTime = nil
        local newestTime = nil
        local totalCount = 0

        -- Iterate through each saleData in the versiondata's sales.
        for _, saleData in pairs(versiondata['sales']) do
          if saleData and saleData["timestamp"] then
            totalCount = totalCount + 1
            if oldestTime == nil or oldestTime > saleData["timestamp"] then
              oldestTime = saleData["timestamp"]
            end
            if newestTime == nil or newestTime < saleData["timestamp"] then
              newestTime = saleData["timestamp"]
            end
          end
        end

        -- Assign the calculated values to the savedVars data structure.
        savedVars[itemID][versionid].totalCount = totalCount
        savedVars[itemID][versionid].oldestTime = oldestTime
        savedVars[itemID][versionid].newestTime = newestTime
        savedVars[itemID][versionid].wasAltered = false
      -- If there is no sales data but the savedVars still exist.
      elseif not hasSalesData and savedVars[itemID] then
        -- Create dataInfo for erroneous records.
        local dataInfo = {
          lang = MasterMerchant.effective_lang,
          itemIndexData = versiondata,
          namespace = internal.dataNamespace,
          timestamp = GetTimeStamp(),
        }

        -- Initialize GS17DataSavedVariables if not already initialized.
        GS17DataSavedVariables["erroneous_records"] = GS17DataSavedVariables["erroneous_records"] or {}
        GS17DataSavedVariables["erroneous_records"][itemID] = GS17DataSavedVariables["erroneous_records"][itemID] or {}

        -- Insert dataInfo into erroneous_records for the specific itemID.
        table.insert(GS17DataSavedVariables["erroneous_records"][itemID], dataInfo)

        -- Remove the versionid entry from savedVars.
        savedVars[itemID][versionid] = nil
      end
    end
  end
end

-- Adds extra sales data to the provided sales data structure.
-- @param otherData The sales data from which to extract and add extra data.
function internal:AddExtraListingsData(otherData)
  local savedVars = otherData[internal.listingsNamespace]

  -- Iterate through each itemID and versionlist pair in the savedVars.
  for itemID, versionlist in pairs(savedVars) do
    for versionid, versiondata in pairs(versionlist) do
      -- Check if the current versiondata has sales data.
      local hasSalesData = versiondata and versiondata['sales'] and next(versiondata['sales'])

      -- Check if totalCount is missing or if savedVars[itemID] is missing.
      if hasSalesData and (not savedVars[itemID] or not savedVars[itemID][versionid].totalCount) then
        local oldestTime = nil
        local newestTime = nil
        local totalCount = 0

        -- Iterate through each saleData in the versiondata's sales.
        for _, saleData in pairs(versiondata['sales']) do
          if saleData and saleData["timestamp"] then
            totalCount = totalCount + 1
            if oldestTime == nil or oldestTime > saleData["timestamp"] then
              oldestTime = saleData["timestamp"]
            end
            if newestTime == nil or newestTime < saleData["timestamp"] then
              newestTime = saleData["timestamp"]
            end
          end
        end

        -- Assign the calculated values to the savedVars data structure.
        savedVars[itemID][versionid].totalCount = totalCount
        savedVars[itemID][versionid].oldestTime = oldestTime
        savedVars[itemID][versionid].newestTime = newestTime
        savedVars[itemID][versionid].wasAltered = false
      -- If there is no sales data but the savedVars still exist.
      elseif not hasSalesData and savedVars[itemID] then
        -- Create dataInfo for erroneous records.
        local dataInfo = {
          lang = MasterMerchant.effective_lang,
          itemIndexData = versiondata,
          namespace = internal.dataNamespace,
          timestamp = GetTimeStamp(),
        }

        -- Initialize GS17DataSavedVariables if not already initialized.
        GS17DataSavedVariables["erroneous_records"] = GS17DataSavedVariables["erroneous_records"] or {}
        GS17DataSavedVariables["erroneous_records"][itemID] = GS17DataSavedVariables["erroneous_records"][itemID] or {}

        -- Insert dataInfo into erroneous_records for the specific itemID.
        table.insert(GS17DataSavedVariables["erroneous_records"][itemID], dataInfo)

        -- Remove the versionid entry from savedVars.
        savedVars[itemID][versionid] = nil
      end
    end
  end
end

function internal:AddExtraPurchaseData(otherData)
  internal:dm("Debug", "AddExtraPurchaseData")
  local savedVars = GS17DataSavedVariables[internal.purchasesNamespace]
  local oldestTime = nil
  local newestTime = nil
  local totalCount = 0
  local firstEntry = nil
  local salesHasEntry = false

  for itemID, itemIndex in pairs(savedVars) do
    for field, itemIndexData in pairs(itemIndex) do
      oldestTime = nil
      newestTime = nil
      totalCount = 0
      firstEntry = nil
      salesHasEntry = false
      if itemIndexData and itemIndexData['sales'] then
        _, firstEntry = next(itemIndexData['sales'], nil)
        if firstEntry and type(firstEntry) == 'table' then salesHasEntry = true end
      end -- if ['sales'] has a table in it
      if salesHasEntry then
        for _, saleData in pairs(itemIndexData['sales']) do
          if saleData and saleData["timestamp"] then
            totalCount = totalCount + 1
            if oldestTime == nil or oldestTime > saleData["timestamp"] then oldestTime = saleData["timestamp"] end
            if newestTime == nil or newestTime < saleData["timestamp"] then newestTime = saleData["timestamp"] end
          end
        end

        if savedVars[itemID][field] then
          savedVars[itemID][field].totalCount = totalCount
          savedVars[itemID][field].oldestTime = oldestTime
          savedVars[itemID][field].newestTime = newestTime
          savedVars[itemID][field].wasAltered = false
        end
      else
        local dataInfo = {
          lang = MasterMerchant.effective_lang,
          itemIndexData = itemIndexData,
          namespace = internal.dataNamespace,
          timestamp = GetTimeStamp(),
        }
        if GS17DataSavedVariables["erroneous_purchases"] == nil then GS17DataSavedVariables["erroneous_purchases"] = {} end
        if GS17DataSavedVariables["erroneous_purchases"][itemID] == nil then GS17DataSavedVariables["erroneous_purchases"][itemID] = {} end
        table.insert(GS17DataSavedVariables["erroneous_purchases"][itemID], dataInfo)
        savedVars[itemID][field] = nil
      end -- salesHasEntry

    end -- itemIndex
  end -- savedVars
end

function internal:AddExtraPostedData(otherData)
  internal:dm("Debug", "AddExtraPostedData")
  local savedVars = GS17DataSavedVariables[internal.postedNamespace]
  local oldestTime = nil
  local newestTime = nil
  local totalCount = 0
  local firstEntry = nil
  local salesHasEntry = false

  for itemID, itemIndex in pairs(savedVars) do
    for field, itemIndexData in pairs(itemIndex) do
      oldestTime = nil
      newestTime = nil
      totalCount = 0
      firstEntry = nil
      salesHasEntry = false
      if itemIndexData and itemIndexData['sales'] then
        _, firstEntry = next(itemIndexData['sales'], nil)
        if firstEntry and type(firstEntry) == 'table' then salesHasEntry = true end
      end -- if ['sales'] has a table in it
      if salesHasEntry then
        for _, saleData in pairs(itemIndexData['sales']) do
          if saleData and saleData["timestamp"] then
            totalCount = totalCount + 1
            if oldestTime == nil or oldestTime > saleData["timestamp"] then oldestTime = saleData["timestamp"] end
            if newestTime == nil or newestTime < saleData["timestamp"] then newestTime = saleData["timestamp"] end
          end
        end

        if savedVars[itemID][field] then
          savedVars[itemID][field].totalCount = totalCount
          savedVars[itemID][field].oldestTime = oldestTime
          savedVars[itemID][field].newestTime = newestTime
          savedVars[itemID][field].wasAltered = false
        end
      else
        local dataInfo = {
          lang = MasterMerchant.effective_lang,
          itemIndexData = itemIndexData,
          namespace = internal.dataNamespace,
          timestamp = GetTimeStamp(),
        }
        if GS17DataSavedVariables["erroneous_posted_records"] == nil then GS17DataSavedVariables["erroneous_posted_records"] = {} end
        if GS17DataSavedVariables["erroneous_posted_records"][itemID] == nil then GS17DataSavedVariables["erroneous_posted_records"][itemID] = {} end
        table.insert(GS17DataSavedVariables["erroneous_posted_records"][itemID], dataInfo)
        savedVars[itemID][field] = nil
      end -- salesHasEntry

    end -- itemIndex
  end -- savedVars
end

function internal:AddExtraCancelledData(otherData)
  internal:dm("Debug", "AddExtraCancelledData")
  local savedVars = GS17DataSavedVariables[internal.cancelledNamespace]
  local oldestTime = nil
  local newestTime = nil
  local totalCount = 0
  local firstEntry = nil
  local salesHasEntry = false

  for itemID, itemIndex in pairs(savedVars) do
    for field, itemIndexData in pairs(itemIndex) do
      oldestTime = nil
      newestTime = nil
      totalCount = 0
      firstEntry = nil
      salesHasEntry = false
      if itemIndexData and itemIndexData['sales'] then
        _, firstEntry = next(itemIndexData['sales'], nil)
        if firstEntry and type(firstEntry) == 'table' then salesHasEntry = true end
      end -- if ['sales'] has a table in it
      if salesHasEntry then
        for _, saleData in pairs(itemIndexData['sales']) do
          if saleData and saleData["timestamp"] then
            totalCount = totalCount + 1
            if oldestTime == nil or oldestTime > saleData["timestamp"] then oldestTime = saleData["timestamp"] end
            if newestTime == nil or newestTime < saleData["timestamp"] then newestTime = saleData["timestamp"] end
          end
        end

        if savedVars[itemID][field] then
          savedVars[itemID][field].totalCount = totalCount
          savedVars[itemID][field].oldestTime = oldestTime
          savedVars[itemID][field].newestTime = newestTime
          savedVars[itemID][field].wasAltered = false
        end
      else
        local dataInfo = {
          lang = MasterMerchant.effective_lang,
          itemIndexData = itemIndexData,
          namespace = internal.dataNamespace,
          timestamp = GetTimeStamp(),
        }
        if GS17DataSavedVariables["erroneous_cancelled_records"] == nil then GS17DataSavedVariables["erroneous_cancelled_records"] = {} end
        if GS17DataSavedVariables["erroneous_cancelled_records"][itemID] == nil then GS17DataSavedVariables["erroneous_cancelled_records"][itemID] = {} end
        table.insert(GS17DataSavedVariables["erroneous_cancelled_records"][itemID], dataInfo)
        savedVars[itemID][field] = nil
      end -- salesHasEntry

    end -- itemIndex
  end -- savedVars
end

-- Add new Sales data to concatanated data array
function internal:AddExtraSalesDataAllContainers()
  internal:dm("Debug", "AddExtraSalesDataAllContainers")
  internal:AddExtraSalesData(GS00DataSavedVariables)
  internal:AddExtraSalesData(GS01DataSavedVariables)
  internal:AddExtraSalesData(GS02DataSavedVariables)
  internal:AddExtraSalesData(GS03DataSavedVariables)
  internal:AddExtraSalesData(GS04DataSavedVariables)
  internal:AddExtraSalesData(GS05DataSavedVariables)
  internal:AddExtraSalesData(GS06DataSavedVariables)
  internal:AddExtraSalesData(GS07DataSavedVariables)
  internal:AddExtraSalesData(GS08DataSavedVariables)
  internal:AddExtraSalesData(GS09DataSavedVariables)
  internal:AddExtraSalesData(GS10DataSavedVariables)
  internal:AddExtraSalesData(GS11DataSavedVariables)
  internal:AddExtraSalesData(GS12DataSavedVariables)
  internal:AddExtraSalesData(GS13DataSavedVariables)
  internal:AddExtraSalesData(GS14DataSavedVariables)
  internal:AddExtraSalesData(GS15DataSavedVariables)
end

-- Add new Listings data to concatanated data array
function internal:AddExtraListingsDataAllContainers()
  internal:dm("Debug", "AddExtraListingsDataAllContainers")
  internal:AddExtraListingsData(GS00DataSavedVariables)
  internal:AddExtraListingsData(GS01DataSavedVariables)
  internal:AddExtraListingsData(GS02DataSavedVariables)
  internal:AddExtraListingsData(GS03DataSavedVariables)
  internal:AddExtraListingsData(GS04DataSavedVariables)
  internal:AddExtraListingsData(GS05DataSavedVariables)
  internal:AddExtraListingsData(GS06DataSavedVariables)
  internal:AddExtraListingsData(GS07DataSavedVariables)
  internal:AddExtraListingsData(GS08DataSavedVariables)
  internal:AddExtraListingsData(GS09DataSavedVariables)
  internal:AddExtraListingsData(GS10DataSavedVariables)
  internal:AddExtraListingsData(GS11DataSavedVariables)
  internal:AddExtraListingsData(GS12DataSavedVariables)
  internal:AddExtraListingsData(GS13DataSavedVariables)
  internal:AddExtraListingsData(GS14DataSavedVariables)
  internal:AddExtraListingsData(GS15DataSavedVariables)
end

-- Renew extra Sales data if list was altered
function internal:RenewExtraSalesDataAllContainers()
  internal:dm("Debug", "RenewExtraSalesDataAllContainers")
  internal:RenewExtraSalesData(GS00DataSavedVariables)
  internal:RenewExtraSalesData(GS01DataSavedVariables)
  internal:RenewExtraSalesData(GS02DataSavedVariables)
  internal:RenewExtraSalesData(GS03DataSavedVariables)
  internal:RenewExtraSalesData(GS04DataSavedVariables)
  internal:RenewExtraSalesData(GS05DataSavedVariables)
  internal:RenewExtraSalesData(GS06DataSavedVariables)
  internal:RenewExtraSalesData(GS07DataSavedVariables)
  internal:RenewExtraSalesData(GS08DataSavedVariables)
  internal:RenewExtraSalesData(GS09DataSavedVariables)
  internal:RenewExtraSalesData(GS10DataSavedVariables)
  internal:RenewExtraSalesData(GS11DataSavedVariables)
  internal:RenewExtraSalesData(GS12DataSavedVariables)
  internal:RenewExtraSalesData(GS13DataSavedVariables)
  internal:RenewExtraSalesData(GS14DataSavedVariables)
  internal:RenewExtraSalesData(GS15DataSavedVariables)
end

-- Renew extra Listings data if list was altered
function internal:RenewExtraListingsDataAllContainers()
  internal:dm("Debug", "RenewExtraListingsDataAllContainers")
  internal:RenewExtraListingsData(GS00DataSavedVariables)
  internal:RenewExtraListingsData(GS01DataSavedVariables)
  internal:RenewExtraListingsData(GS02DataSavedVariables)
  internal:RenewExtraListingsData(GS03DataSavedVariables)
  internal:RenewExtraListingsData(GS04DataSavedVariables)
  internal:RenewExtraListingsData(GS05DataSavedVariables)
  internal:RenewExtraListingsData(GS06DataSavedVariables)
  internal:RenewExtraListingsData(GS07DataSavedVariables)
  internal:RenewExtraListingsData(GS08DataSavedVariables)
  internal:RenewExtraListingsData(GS09DataSavedVariables)
  internal:RenewExtraListingsData(GS10DataSavedVariables)
  internal:RenewExtraListingsData(GS11DataSavedVariables)
  internal:RenewExtraListingsData(GS12DataSavedVariables)
  internal:RenewExtraListingsData(GS13DataSavedVariables)
  internal:RenewExtraListingsData(GS14DataSavedVariables)
  internal:RenewExtraListingsData(GS15DataSavedVariables)
end

-- /script LibGuildStore_Internal:VerifyAllItemLinks()
-- DEBUG VerifyAllItemLinks
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
  if not MasterMerchant then return end

  if not start then
    MasterMerchantWindowMenuFooterLoadingIcon.animation:Stop()
    MasterMerchantGuildWindowMenuFooterLoadingIcon.animation:Stop()
    MasterMerchantListingWindowMenuFooterLoadingIcon.animation:Stop()
    MasterMerchantPurchaseWindowMenuFooterLoadingIcon.animation:Stop()
    MasterMerchantReportsWindowMenuFooterLoadingIcon.animation:Stop()
  end

  MasterMerchantWindowMenuFooterLoadingIcon:SetHidden(not start)
  MasterMerchantGuildWindowMenuFooterLoadingIcon:SetHidden(not start)
  MasterMerchantListingWindowMenuFooterLoadingIcon:SetHidden(not start)
  MasterMerchantPurchaseWindowMenuFooterLoadingIcon:SetHidden(not start)
  MasterMerchantReportsWindowMenuFooterLoadingIcon:SetHidden(not start)

  if start then
    MasterMerchantWindowMenuFooterLoadingIcon.animation:PlayForward()
    MasterMerchantGuildWindowMenuFooterLoadingIcon.animation:PlayForward()
    MasterMerchantListingWindowMenuFooterLoadingIcon.animation:PlayForward()
    MasterMerchantPurchaseWindowMenuFooterLoadingIcon.animation:PlayForward()
    MasterMerchantReportsWindowMenuFooterLoadingIcon.animation:PlayForward()
  end
end

--[[
  Reference for internal:AddSearchToItem

  ['sales'] =
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
