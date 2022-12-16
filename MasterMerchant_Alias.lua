local internal = _G["LibGuildStore_Internal"]

-- A simple utility function to return which set of settings are active,
-- based on the allSettingsAccount option setting.
function MasterMerchant:ActiveSettings()
  return MasterMerchant.systemSavedVariables
end

-- alias for previous function
function MasterMerchant.makeIndexFromLink(itemLink)
  return internal.GetOrCreateIndexFromLink(itemLink)
end

MasterMerchant.messageLogTable = {}
local function GenerateLogMessage(key)
  if not MasterMerchant.messageLogTable[key] then
    MasterMerchant.messageLogTable[key] = true
    MasterMerchant:dm("Debug", string.format("The author accessed %s.", key))
  end
end

function MasterMerchant:TimeCheck()
  GenerateLogMessage("ColonTimeCheck")
  --[[
  this does nothing because LibPrice has no idea what MM
  is doing. Don't mess with it or I'll make it local.
  ]]--
end

function MasterMerchant.TimeCheck()
  GenerateLogMessage("DotTimeCheck")
  --[[
  this does nothing because LibPrice has no idea what MM
  is doing. Don't mess with it or I'll make it local.
  ]]--
end

function MasterMerchant:CheckTime()
  GenerateLogMessage("CheckTime")
  --[[
  this does nothing because LibPrice has no idea what MM
  is doing. Don't mess with it or I'll make it local.
  ]]--
end

-- /script d(MasterMerchant:itemPriceTip("|H1:item:42867:25:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", true, false))
function MasterMerchant:itemPriceTip(itemLink, chatText, clickable)
  GenerateLogMessage("itemPriceTip")

  local tipStats = MasterMerchant:itemStats(itemLink, false)
  if tipStats.avgPrice then

    local tipFormat
    if tipStats['numDays'] < 2 then
      tipFormat = GetString(MM_OLD_TIP_FORMAT_SINGLE)
    else
      tipFormat = GetString(MM_OLD_TIP_FORMAT_MULTI)
    end

    local avePriceString = self.LocalizedNumber(tipStats['avgPrice'])
    tipFormat = string.gsub(tipFormat, '.2f', 's')
    tipFormat = string.gsub(tipFormat, 'M.M.', 'MM')
    -- chatText
    if not chatText then tipFormat = tipFormat .. MM_COIN_ICON_NO_SPACE end
    local salesString = zo_strformat(GetString(SK_OLD_PRICETIP_SALES), tipStats['numSales'])
    if tipStats['numSales'] ~= tipStats['numItems'] then
      salesString = salesString .. zo_strformat(GetString(MM_OLD_PRICETIP_ITEMS), tipStats['numItems'])
    end
    return string.format(tipFormat, salesString, tipStats['numDays'],
      avePriceString), tipStats['avgPrice'], tipStats['graphInfo']
    --return string.format(tipFormat, zo_strformat(GetString(SK_OLD_PRICETIP_SALES), tipStats['numSales']), tipStats['numDays'], tipStats['avgPrice']), tipStats['avgPrice'], tipStats['graphInfo']
  else
    return nil, tipStats['numDays'], nil
  end
end

function MasterMerchant:itemStats(itemLink, clickable)
  GenerateLogMessage("itemStats")
  return MasterMerchant:GetTooltipStats(itemLink, true, false)
end

function MasterMerchant:toolTipStats(theIID, itemIndex, skipDots, goBack, clickable)
  GenerateLogMessage("toolTipStats")
  return { }
end

function MasterMerchant:addStatsAndGraph(tooltip, itemLink)
  GenerateLogMessage("addStatsAndGraph")
  MasterMerchant:GenerateStatsAndGraph(tooltip, itemLink)
end

function MasterMerchant:addStatsItemTooltip()
  GenerateLogMessage("addStatsItemTooltip")
  MasterMerchant:GenerateStatsItemTooltip()
end

function MasterMerchant:onItemActionLinkStatsLink(itemLink)
  GenerateLogMessage("onItemActionLinkStatsLink")
  MasterMerchant:OnItemLinkAction(itemLink)
end

function MasterMerchant:SwitchPrice(control, slot)
  GenerateLogMessage("SwitchPrice")
  return
end

function MasterMerchant:SwitchUnitPrice(control, slot)
  GenerateLogMessage("SwitchUnitPrice")
  return
end
