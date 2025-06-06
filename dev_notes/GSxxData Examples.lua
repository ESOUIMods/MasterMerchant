local function EmitMessage(text)
  if(text == "")
  then
    text = "[Empty String]"
  end

  print(text)
end

local function EmitTable(t, indent, tableHistory)
  indent          = indent or "."
  tableHistory    = tableHistory or {}

  for k, v in pairs(t)
  do
    local vType = type(v)

    EmitMessage(indent.."("..vType.."): "..tostring(k).." = "..tostring(v))

    if(vType == "table")
    then
      if(tableHistory[v])
      then
        EmitMessage(indent.."Avoiding cycle on table...")
      else
        tableHistory[v] = true
        EmitTable(v, indent.."  ", tableHistory)
      end
    end
  end
end

function Debug(...)
  for i = 1, select("#", ...) do
    local value = select(i, ...)
    if(type(value) == "table")
    then
      EmitTable(value)
    else
      EmitMessage(tostring (value))
    end
  end
end

-- Function to check for empty table
function isEmpty(t)
  if next(t) == nil then
    return true
  else
    return false
  end
end

dataNamespace = "datana"
purchasesNamespace = "purchasena"
postedNamespace = "posteditemsna"
sales_data = {}


GS03DataSavedVariables =
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
            ["price"] = 100000,
            ["itemLink"] = 1,
            ["wasKiosk"] = true,
            ["guild"] = 2,
            ["buyer"] = 17153,
            ["quant"] = 1,
            ["timestamp"] = 1738056564,
            ["id"] = "1978217035",
            ["seller"] = 25934,
          },
        },
        ["itemAdderText"] = "cp160 purple epic medium apparel set syvarra's scales legs divines",
        ["totalCount"] = 1,
        ["wasAltered"] = false,
        ["oldestTime"] = 1620353437,
      },
      ["50:16:4:18:0"] =
      {
        ["itemDesc"] = "Guards of Syvarra's Scales",
        ["newestTime"] = 1659287708,
        ["itemIcon"] = "/esoui/art/icons/gear_thievesguildv2_medium_legs_a.dds",
        ["sales"] =
        {
          [1] =
          {
            ["price"] = 200000,
            ["itemLink"] = 2,
            ["wasKiosk"] = true,
            ["guild"] = 1,
            ["buyer"] = 79652,
            ["quant"] = 1,
            ["timestamp"] = 1737646299,
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
            ["price"] = 300000,
            ["itemLink"] = 3,
            ["wasKiosk"] = true,
            ["guild"] = 1,
            ["buyer"] = 79652,
            ["quant"] = 1,
            ["timestamp"] = 1736713708,
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
            ["timestamp"] = 1737646299,
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
            ["timestamp"] = 1736713708,
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
            ["price"] = 400000,
            ["itemLink"] = 4,
            ["wasKiosk"] = true,
            ["guild"] = 2,
            ["buyer"] = 17153,
            ["quant"] = 1,
            ["timestamp"] = 1738494726,
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
            ["price"] = 500000,
            ["itemLink"] = 5,
            ["wasKiosk"] = true,
            ["guild"] = 5,
            ["buyer"] = 15368,
            ["quant"] = 1,
            ["timestamp"] = 1738377138,
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

  for itemId, versionList in pairs(savedVars) do
    if not sales_data[itemId] and next(versionList) then
      sales_data[itemId] = versionList
    else
      for versionId, versionData in pairs(versionList) do
        local hasSales = versionData and versionData['sales']
        if hasSales then
          -- Initialize inside this loop
          local oldestTime, newestTime = nil, nil

          for saleId, saleData in pairs(versionData['sales']) do
            if type(saleId) == 'number' and type(saleData) == 'table' and type(saleData["timestamp"]) == 'number' then
              sales_data[itemId][versionId] = sales_data[itemId][versionId] or {}
              sales_data[itemId][versionId]['sales'] = sales_data[itemId][versionId]['sales'] or {}
              table.insert(sales_data[itemId][versionId]['sales'], saleData)
            end
          end

          for _, saleData in ipairs(sales_data[itemId][versionId]['sales']) do
            if oldestTime == nil or oldestTime > saleData.timestamp then oldestTime = saleData.timestamp end
            if newestTime == nil or newestTime < saleData.timestamp then newestTime = saleData.timestamp end
          end

          Debug(string.format("oldestTime: %s", oldestTime))
          Debug(string.format("newestTime: %s", newestTime))

          sales_data[itemId][versionId].totalCount = NonContiguousCount(sales_data[itemId][versionId]['sales'])
          sales_data[itemId][versionId].wasAltered = true
          sales_data[itemId][versionId].oldestTime = oldestTime
          sales_data[itemId][versionId].newestTime = newestTime

          savedVars[itemId][versionId] = nil
        end
      end
      Debug(itemId)
      Debug(versionId)
      local hasVersionId = savedVars and savedVars[itemId] and next(savedVars[itemId])
      if not hasVersionId then savedVars[itemId] = nil end
    end
  end
end

function ProcessAndPrintSalesData()
  ReferenceSales(GS08DataSavedVariables)
  ReferenceSales(GS05DataSavedVariables)
  ReferenceSales(GS15DataSavedVariables)
  ReferenceSales(GS03DataSavedVariables)
  Debug(sales_data)
  Debug("GS08DataSavedVariables")
  Debug(GS08DataSavedVariables)
  Debug("GS05DataSavedVariables")
  Debug(GS05DataSavedVariables)
  Debug("GS15DataSavedVariables")
  Debug(GS15DataSavedVariables)
  Debug("GS03DataSavedVariables")
  Debug(GS03DataSavedVariables)
end

ProcessAndPrintSalesData()
