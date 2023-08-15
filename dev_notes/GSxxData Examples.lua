dataNamespace = "datana"
purchasesNamespace = "purchasena"
postedNamespace = "posteditemsna"
sales_data = {}

GS08DataSavedVariables =
{
    ["datana"] = 
    {
        [114690] = 
        {
            ["50:16:4:18:0"] = 
            {
                ["itemDesc"] = "Guards of Syvarra's Scales",
                ["newestTime"] = 1659287708,
                ["itemIcon"] = "/esoui/art/icons/gear_thievesguildv2_medium_legs_a.dds",
                ["sales"] = 
                {
                    [1] = 
                    {
                        ["price"] = 2000,
                        ["itemLink"] = 50147,
                        ["wasKiosk"] = true,
                        ["guild"] = 1,
                        ["buyer"] = 79652,
                        ["quant"] = 1,
                        ["timestamp"] = 1659287708,
                        ["id"] = "2187175832",
                        ["seller"] = 259,
                    },
                },
                ["itemAdderText"] = "cp160 green fine medium apparel set syvarra's scales legs divines",
                ["totalCount"] = 1,
                ["wasAltered"] = false,
                ["oldestTime"] = 1659287708,
            },
        },
    },
}

GS17DataSavedVariables =
{
    ["purchasena"] = 
    {
        [188166] = 
        {
            ["1:0:3:0:0"] = 
            {
                ["itemAdderText"] = "rr01 blue superior consumable recipe",
                ["wasAltered"] = false,
                ["totalCount"] = 1,
                ["newestTime"] = 1688289861,
                ["itemIcon"] = "/esoui/art/icons/crafting_planfurniture_woodworking_3.dds",
                ["oldestTime"] = 1688289861,
                ["itemDesc"] = "Blueprint: High Isle Trunk, Sturdy",
                ["sales"] = 
                {
                    [1] = 
                    {
                        ["itemLink"] = 1942,
                        ["id"] = "4658408953302721107",
                        ["seller"] = 26506,
                        ["quant"] = 1,
                        ["buyer"] = 2439,
                        ["timestamp"] = 1688289861,
                        ["price"] = 6300,
                        ["guild"] = 12,
                    },
                },
            },
        },
    },
    ["posteditemsna"] = 
    {
        [134998] = 
        {
            ["1:0:4:0:0"] = 
            {
                ["itemAdderText"] = "rr01 purple epic consumable recipe",
                ["wasAltered"] = false,
                ["totalCount"] = 1,
                ["newestTime"] = 1680478501,
                ["itemIcon"] = "/esoui/art/icons/crafting_planfurniture_clothier_4.dds",
                ["oldestTime"] = 1680478501,
                ["itemDesc"] = "Pattern: Jester's Pavilion, Open",
                ["sales"] = 
                {
                    [1] = 
                    {
                        ["price"] = 950,
                        ["quant"] = 1,
                        ["itemLink"] = 7347,
                        ["timestamp"] = 1680478501,
                        ["seller"] = 2439,
                        ["guild"] = 5,
                    },
                },
            },
        },
    },
}

GS05DataSavedVariables =
{
    ["datana"] = 
    {
        [114690] = 
        {
            ["50:16:2:18:0"] = 
            {
                ["itemDesc"] = "Guards of Syvarra's Scales",
                ["newestTime"] = 1682194027,
                ["itemIcon"] = "/esoui/art/icons/gear_thievesguildv2_medium_legs_a.dds",
                ["sales"] = 
                {
                    [1] = 
                    {
                        ["price"] = 72000,
                        ["itemLink"] = 23120,
                        ["wasKiosk"] = true,
                        ["guild"] = 2,
                        ["buyer"] = 17153,
                        ["quant"] = 1,
                        ["timestamp"] = 1669140811,
                        ["id"] = "1978217035",
                        ["seller"] = 25934,
                    },
                },
                ["itemAdderText"] = "cp160 purple epic medium apparel set syvarra's scales legs divines",
                ["totalCount"] = 1,
                ["wasAltered"] = false,
                ["oldestTime"] = 1620353437,
            },
        },
    },
}

GS15DataSavedVariables =
{
    ["datana"] = 
    {
        [114690] = 
        {
            ["50:16:2:18:0"] = 
            {
                ["itemDesc"] = "Guards of Syvarra's Scales",
                ["newestTime"] = 1664831594,
                ["itemIcon"] = "/esoui/art/icons/gear_thievesguildv2_medium_legs_a.dds",
                ["sales"] = 
                {
                    [1] = 
                    {
                        ["price"] = 29995,
                        ["itemLink"] = 50147,
                        ["wasKiosk"] = true,
                        ["guild"] = 5,
                        ["buyer"] = 15368,
                        ["quant"] = 1,
                        ["timestamp"] = 1664831594,
                        ["id"] = "1945472617",
                        ["seller"] = 4857,
                    },
                },
                ["itemAdderText"] = "cp160 green fine medium apparel set syvarra's scales legs divines",
                ["totalCount"] = 1,
                ["wasAltered"] = false,
                ["oldestTime"] = 1622077408,
            },
        },
    },
}

function NonContiguousCount(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

function ReferenceSales(otherData)
  local savedVars = otherData[dataNamespace]
  
  for itemid, versionlist in pairs(savedVars) do
    if not sales_data[itemid] and next(versionlist) then
      sales_data[itemid] = versionlist
    else
      for versionid, versiondata in pairs(versionlist) do
        if not sales_data[itemid][versionid] then
          sales_data[itemid][versionid] = {}
        end
        
        local sales = versiondata['sales'] or {}
        
        for saleid, saledata in pairs(versiondata['sales']) do
          if (type(saleid) == 'number' and type(saledata) == 'table' and type(saledata["timestamp"]) == 'number') then
            table.insert(sales, saledata)
          end
        end
        
        local firstSale = next(versiondata['sales'], nil)
        if firstSale then
          local itemLink = firstSale.itemLink
          sales_data[itemid][versionid].itemIcon = versiondata.itemIcon or GetItemLinkInfo(itemLink)
          sales_data[itemid][versionid].itemAdderText = versiondata.itemAdderText or AddSearchToItem(itemLink)
          sales_data[itemid][versionid].itemDesc = versiondata.itemDesc or zo_strformat(itemLink)
        end
        
        if not sales_data[itemid][versionid]['sales'] then
          sales_data[itemid][versionid]['sales'] = {}
        end
        for _, saledata in ipairs(sales) do
          table.insert(sales_data[itemid][versionid]['sales'], saledata)
        end
      end
      savedVars[itemid] = nil
    end
  end
end

function RenewExtraSalesData(otherData)
  local savedVars = otherData[dataNamespace]

  for itemID, versionlist in pairs(savedVars) do
    for versionid, versiondata in pairs(versionlist) do
      if versiondata["wasAltered"] then
        local sales = versiondata['sales'] or {}
        local totalCount = NonContiguousCount(sales)  -- Count the sales entries

        local timestamps = {}  -- Gather timestamps for oldest and newest time
        for _, saleData in pairs(sales) do
          table.insert(timestamps, saleData["timestamp"])
        end

        -- Find oldest and newest time from timestamps
        local oldestTime = math.min(unpack(timestamps))
        local newestTime = math.max(unpack(timestamps))

        -- Update versiondata with calculated values
        savedVars[itemID][versionid].totalCount = totalCount
        savedVars[itemID][versionid].newestTime = newestTime
        savedVars[itemID][versionid].oldestTime = oldestTime
        savedVars[itemID][versionid].wasAltered = false
      end
    end
  end
end

function RenewExtraPostedData(otherData)
  local savedVars = GS17DataSavedVariables[postedNamespace]

  for itemID, versionlist in pairs(savedVars) do
    for versionid, versiondata in pairs(versionlist) do
      if versiondata["wasAltered"] then
        local sales = versiondata['sales'] or {}
        local totalCount = NonContiguousCount(sales)  -- Count the sales entries

        local oldestTime = math.huge  -- Initialize to a large value
        local newestTime = 0  -- Initialize to 0

        for _, saleData in pairs(sales) do
          local timestamp = saleData["timestamp"]
          oldestTime = math.min(oldestTime, timestamp)
          newestTime = math.max(newestTime, timestamp)
        end

        -- Update versiondata with calculated values
        savedVars[itemID][versionid].totalCount = totalCount
        savedVars[itemID][versionid].newestTime = newestTime
        savedVars[itemID][versionid].oldestTime = oldestTime
        savedVars[itemID][versionid].wasAltered = false
      end
    end
  end
end

RenewExtraPostedData is very similar to RenewExtraSalesData with the exception that savedVars is assigned `GS17DataSavedVariables[postedNamespace]`. However, would you make the same optimization for RenewExtraPostedData as you did RenewExtraSalesData where you gather timestamps in a loop and then use `math.min` and `math.max`?