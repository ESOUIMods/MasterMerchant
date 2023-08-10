function CombinedSalesIndexing()
  local extraData = {}
  local itemid, versionid, saleid = nil, nil, nil

  extraData.start = GetTimeStamp()
  extraData.checkMilliseconds = MM_WAIT_TIME_IN_MILLISECONDS_SHORT
  extraData.indexCount = 0
  extraData.wordsIndexCount = 0
  extraData.wasAltered = false

  -- Main loop through items
  for itemid, versionlist in pairs(sales_data) do
    extraData.versionRemoved = false
    versionid = nil

    -- Loop through versions
    for versionid, versiondata in pairs(versionlist) do
      extraData.saleRemoved = false
      saleid = nil

      -- Loop through sales
      for saleid, saledata in pairs(versiondata['sales']) do
        extraData.indexCount = extraData.indexCount + 1

        local currentItemLink = GetItemLinkByIndex(saledata['itemLink'])
        local currentGuild = GetGuildNameByIndex(saledata['guild'])
        local currentBuyer = GetAccountNameByIndex(saledata['buyer'])
        local currentSeller = GetAccountNameByIndex(saledata['seller'])

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
        local wordData = { itemid, versiondata, saleid }
        for i in searchByWords do
          if sr_index[i] == nil then
            extraData.wordsIndexCount = extraData.wordsIndexCount + 1
            sr_index[i] = {}
          end
          table.insert(sr_index[i], wordData)
          internal.sr_index_count = internal.sr_index_count + 1
        end

        -- Continue processing next sale
        saleid, saledata = next(versiondata['sales'], saleid)
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
        LEQ:ContinueWith(function() iterateOverSalesData(itemid, versionid, saleid, nil, loopfunc, postfunc, extraData) end, nil)
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

    -- If we just deleted everything, clear the bucket out
    if (sales_data[itemid] ~= nil and ((NonContiguousNonNilCount(versionlist) < 1) or (type(itemid) ~= 'number'))) then
      extraData.idCount = (extraData.idCount or 0) + 1
      sales_data[itemid] = nil
    end

    -- Go on to the next Item
    itemid, versionlist = next(sales_data, itemid)
    extraData.versionRemoved = false
    versionid = nil
  end

  print("Finished")
end
