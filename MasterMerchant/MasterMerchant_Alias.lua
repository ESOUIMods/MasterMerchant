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

function MasterMerchant:TimeCheck()
  --[[
  this does nothing because LibPrice has no idea what MM
  is doing. Don't mess with it or I'll make it local.
  ]]--
end

function MasterMerchant:CheckTime()
  --[[
  this does nothing because LibPrice has no idea what MM
  is doing. Don't mess with it or I'll make it local.
  ]]--
end

function MasterMerchant:itemPriceTip(itemLink, chatText, clickable)
  --MasterMerchant:dm("Info", "Please inform me of any mods that use MM information. The author should not access itemPriceTip directly.")

  local tipStats = MasterMerchant:itemStats(itemLink, false)
  if tipStats.avgPrice then

    local tipFormat
    if tipStats['numDays'] < 2 then
      tipFormat = GetString(MM_OLD_TIP_FORMAT_SINGLE)
    else
      tipFormat = GetString(MM_OLD_TIP_FORMAT_MULTI)
    end

    local avePriceString = self.LocalizedNumber(tipStats['avgPrice'])
    tipFormat            = string.gsub(tipFormat, '.2f', 's')
    tipFormat            = string.gsub(tipFormat, 'M.M.', 'MM')
    -- chatText
    if not chatText then tipFormat = tipFormat .. '|t16:16:EsoUI/Art/currency/currency_gold.dds|t' end
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
  --MasterMerchant:dm("Info", "Please inform me of any mods that use MM information. The author should not access itemStats directly.")
  local itemID    = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  return MasterMerchant:GetTooltipStats(itemID, itemIndex, true, true)
end

function MasterMerchant:toolTipStats(theIID, itemIndex, skipDots, goBack, clickable)
  --MasterMerchant:dm("Info", "Please inform me of any mods that use MM information. The author should not access toolTipStats directly.")
  return MasterMerchant:GetTooltipStats(itemID, itemIndex, true, true)
end

function MasterMerchant:addStatsAndGraph(tooltip, itemLink)
  --MasterMerchant:dm("Info", "Please inform me of any mods that use MM information. The author should not access addStatsAndGraph directly.")
  MasterMerchant:GenerateStatsAndGraph(tooltip, itemLink)
end

function MasterMerchant:addStatsItemTooltip()
  --MasterMerchant:dm("Info", "Please inform me of any mods that use MM information. The author should not access addStatsItemTooltip directly.")
  MasterMerchant:GenerateStatsItemTooltip()
end

function MasterMerchant:onItemActionLinkStatsLink(itemLink)
  --MasterMerchant:dm("Info", "Please inform me of any mods that use MM information. The author should not access onItemActionLinkStatsLink directly.")
  MasterMerchant:OnItemLinkAction(itemLink)
end

function MasterMerchant:SwitchPrice(control, slot)
  --MasterMerchant:dm("Info", "Please inform me of any mods that use MM information. The author should not access SwitchPrice directly.")
  MasterMerchant:SwitchUnitPrice(control, slot)
end
