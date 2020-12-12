-- MasterMerchant Utility Functions File
-- Last Updated September 15, 2014
-- Written August 2014 by Dan Stone (@khaibit) - dankitymao@gmail.com
-- Extended February 2015 by Chris Lasswell (@Philgo68) - Philgo68@gmail.com
-- Released under terms in license accompanying this file.
-- Distribution without license is prohibited!

--  |H0:item:69359:96:50:26848:96:50:0:0:0:0:0:0:0:0:0:19:0:0:0:0:0|h|h  AUTGuild 1058 days

function MasterMerchant.v(level, ...)
  -- DEBUG
  if (level <= MasterMerchant.verboseLevel) then
    if ... then
      if CHAT_ROUTER then
        CHAT_ROUTER:AddSystemMessage(...)
      elseif RequestDebugPrintText then
        RequestDebugPrintText(...)
      else
        d(...)
      end
    end
    return true
  end
  return false
end

function MasterMerchant:ssup(inputTable, numElements)
  for _, gapVal in ipairs(MasterMerchant.shellGaps) do
    for i = gapVal + 1, numElements do
      local tableVal = inputTable[i]
      for j = i - gapVal, 1, -gapVal do
        local testVal = inputTable[j]
        if not (tableVal < testVal) then break end
        inputTable[i] = testVal;
        i = j
      end
      inputTable[i] = tableVal
    end
  end
  return inputTable
end

function MasterMerchant:ssdown(inputTable, numElements)
  for _, gapVal in ipairs(MasterMerchant.shellGaps) do
    for i = gapVal + 1, numElements do
      local tableVal = inputTable[i]
      for j = i - gapVal, 1, -gapVal do
        local testVal = inputTable[j]
        if not (tableVal > testVal) then break end
        inputTable[i] = testVal;
        i = j
      end
      inputTable[i] = tableVal
    end
  end
  return inputTable
end

-- Lua's table.sort function uses quicksort.  Here I implement
-- Shellsort in Lua for better memory efficiency.
-- (http://en.wikipedia.org/wiki/Shellsort)
function MasterMerchant.shellSort(inputTable, comparison, numElements)
  numElements = numElements or #inputTable
  for _, gapVal in ipairs(MasterMerchant.shellGaps) do
    for i = gapVal + 1, numElements do
      local tableVal = inputTable[i]
      for j = i - gapVal, 1, -gapVal do
        local testVal = inputTable[j]
        if not comparison(tableVal, testVal) then break end
        inputTable[i] = testVal
        i = j
      end
      inputTable[i] = tableVal
    end
  end
  return inputTable
end

function MasterMerchant.spairs(t, order)
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

function MasterMerchant:is_empty_or_nil(t)
  if not t then return true end
  if type(t) == "table" then
    if next(t) == nil then
      return true
    else
      return false
    end
  elseif type(t) == "string" then
    if t == nil then
      return true
    elseif t == "" then
      return true
    else
      return false
    end
  elseif type(t) == "nil" then
    return true
  end
end

function MasterMerchant.hashString(name)
  local hash = 0
  for c in string.gmatch(name, '.') do
    if c then hash = hash + string.byte(c) end
  end
  return hash % 16
end

function MasterMerchant.concat(a, ...)
  if a == nil and ... == nil then
    return ''
  elseif a == nil then
    return MasterMerchant.concat(...)
  else
    if type(a) == 'boolean' then
      --d(tostring(a) .. ' ' .. MasterMerchant.concat(...))
    end
    return tostring(a) .. ' ' .. MasterMerchant.concat(...)
  end
end

function MasterMerchant.ShowChildren(control, startNum, endNum)
  local numChildren = math.min(control:GetNumChildren(), endNum)
  local numStart = math.min(startNum, numChildren)
  for i = numStart, numChildren do
    local child = control:GetChild(i)

    if child and child.GetName and child.GetText then
      d(i .. ') ' .. child:GetName() .. ' - ' .. child:GetText())
    elseif child and child.GetName then
      d(i .. ') ' .. child:GetName())
    elseif child and child.GetText then
      d(i .. ') - ' .. child:GetText())
    end
    if child then
      MasterMerchant.ShowChildren(child, 1, 100)
    end
  end
end

function MasterMerchant.GetItemLinePrice(itemLink)
  if itemLink then
    local theIID = GetItemLinkItemId(itemLink)
    local itemIndex = MasterMerchant.makeIndexFromLink(itemLink)
    local tipStats = MasterMerchant:toolTipStats(theIID, itemIndex, true, true, false)
    if tipStats.avgPrice then
      return tipStats.avgPrice
    end
  end
  return 0
end

local function GetLevelAndCPRequirementFromItemLink(itemLink)
    local link = {ZO_LinkHandler_ParseLink(itemLink)}
    return tonumber(link[5]), tonumber(link[6])
end

local function GetPotionPowerLevel(itemLink)
    local CP, level = GetLevelAndCPRequirementFromItemLink(itemLink)
    if level < 50 then
        return level
    end
    return CP
end

-- The index consists of the item's required level, required vet
-- level, quality, and trait(if any), separated by colons.
function MasterMerchant.makeIndexFromLink(itemLink)
  --Standardize Level to 1 if the level is not relevent but is stored on some items (ex: recipes)
  local levelReq = 1
  local itemType, specializedItemType = GetItemLinkItemType(itemLink)
  if itemType ~= ITEMTYPE_RECIPE then
    levelReq = GetItemLinkRequiredLevel(itemLink)
  end
  local vetReq = GetItemLinkRequiredChampionPoints(itemLink) / 10
  local itemQuality = GetItemLinkQuality(itemLink)
  local itemTrait = GetItemLinkTraitType(itemLink)
  local theLastNumber
  --Add final number in the link to handle item differences like 2 and 3 buff potions
  if itemType == ITEMTYPE_MASTER_WRIT then
    theLastNumber = 0
  else
    theLastNumber = string.match(itemLink, '|H.-:item:.-:(%d-)|h') or 0
  end
  if itemType == ITEMTYPE_POISON or itemType == ITEMTYPE_POTION then
    local value = GetPotionPowerLevel(itemLink)
    itemTrait = MasterMerchant.potionVarientTable[value] or "0"
  end
  local index = levelReq .. ':' .. vetReq .. ':' .. itemQuality .. ':' .. itemTrait .. ':' .. theLastNumber

  return index
end
--[[
  ["sales"] =
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
  /script MasterMerchant.dm("Debug", GetNumTradingHouseSearchResultItemLinkAsFurniturePreviewVariations("|H0:item:68633:363:50:0:0:0:0:0:0:0:0:0:0:0:0:13:0:0:0:10000:0|h|h"))
  /script MasterMerchant.dm("Debug", GetItemLinkRequiredChampionPoints("|H0:item:167719:2:50:0:0:0:0:0:0:0:0:0:0:0:0:111:0:0:0:10000:0|h|h"))
  /script MasterMerchant.dm("Debug", GetItemLinkReagentTraitInfo("|H1:item:45839:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"))
  armor

  /script MasterMerchant.dm("Debug", zo_strformat("<<t:1>>", GetString("SI_ITEMFILTERTYPE", GetItemLinkFilterTypeInfo("|H1:item:167644:362:50:0:0:0:0:0:0:0:0:0:0:0:0:111:0:0:0:300:0|h|h"))))


  SI_ITEMFILTERTYPE
  /script adder = ""; adder = MasterMerchant.concat(adder, "weapon"); MasterMerchant.dm(adder)

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
  MasterMerchant.concat("weapon", "weapon")
]]--

local function is_in(search_value, search_table)
    for k, v in pairs(search_table) do
        if search_value == v then return true end
        if type(search_value) == "string" then
            if string.find(string.lower(v), string.lower(search_value)) then return true end
        end
    end
    return false
end

-- Additional words tacked on to the item name for searching
function MasterMerchant.addedSearchToItem(itemLink)
  --Standardize Level to 1 if the level is not relevent but is stored on some items (ex: recipes)
  local requiredLevel = 1
  local itemType, specializedItemType = GetItemLinkItemType(itemLink)
  -- SI_ITEMTYPEDISPLAYCATEGORY21 RECIPE
  if itemType ~= ITEMTYPE_RECIPE then
    requiredLevel = GetItemLinkRequiredLevel(itemLink) -- verified
  end
  -- SI_RECIPECRAFTINGSYSTEM is like Diagram
  local requiredVeteranRank = GetItemLinkRequiredChampionPoints(itemLink) -- verified
  local vrAdder = GetString(MM_CP_RANK_SEARCH)

  local adder = ''
  if (requiredLevel > 0 or requiredVeteranRank > 0) then
    if (requiredVeteranRank > 0) then
      adder = vrAdder .. string.format('%02d', requiredVeteranRank)
    else
      adder = GetString(MM_REGULAR_RANK_SEARCH) .. string.format('%02d', requiredLevel)
    end
  else
    adder = vrAdder .. '00 ' .. GetString(MM_REGULAR_RANK_SEARCH) .. '00'
  end

  -- adds green blue
  local itemQuality = GetItemLinkDisplayQuality(itemLink) -- verified
  if (itemQuality == ITEM_DISPLAY_QUALITY_NORMAL) then adder = MasterMerchant.concat(adder, GetString(MM_COLOR_WHITE)) end
  if (itemQuality == ITEM_DISPLAY_QUALITY_MAGIC) then adder = MasterMerchant.concat(adder, GetString(MM_COLOR_GREEN)) end
  if (itemQuality == ITEM_DISPLAY_QUALITY_ARCANE) then adder = MasterMerchant.concat(adder, GetString(MM_COLOR_BLUE)) end
  if (itemQuality == ITEM_DISPLAY_QUALITY_ARTIFACT) then adder = MasterMerchant.concat(adder, GetString(MM_COLOR_PURPLE)) end
  if (itemQuality == ITEM_DISPLAY_QUALITY_LEGENDARY) then adder = MasterMerchant.concat(adder, GetString(MM_COLOR_GOLD)) end
  if (itemQuality == ITEM_DISPLAY_QUALITY_MYTHIC_OVERRIDE) then adder = MasterMerchant.concat(adder, GetString(MM_COLOR_ORANGE)) end

  -- adds Mythic Legendary
  adder = MasterMerchant.concat(adder, zo_strformat("<<t:1>>", GetString("SI_ITEMDISPLAYQUALITY", itemQuality))) -- verified

  -- adds Heavy
  local armorType = GetItemLinkArmorType(itemLink) -- verified
  if (armorType ~= 0) then
    adder = MasterMerchant.concat(adder, zo_strformat("<<t:1>>", GetString("SI_ARMORTYPE", armorType)))
  end

  -- adds Apparel
  local filterType = GetItemLinkFilterTypeInfo(itemLink) -- verified
  if (filterType ~= 0) then
    adder = MasterMerchant.concat(adder, zo_strformat("<<t:1>>", GetString("SI_ITEMFILTERTYPE", filterType)))
  end
  -- declared above
  -- local itemType = GetItemLinkItemType(itemLink) -- verified
  if (itemType ~= 0) then
    adder = MasterMerchant.concat(adder, zo_strformat("<<t:1>>", GetString("SI_ITEMTYPE", itemType)))
  end

  if (specializedItemType ~= 0) then
    adder = MasterMerchant.concat(adder, zo_strformat("<<t:1>>", GetString("SI_SPECIALIZEDITEMTYPE", specializedItemType)))
  end

  -- adds Mark of the Pariah
  local isSetItem, setName = GetItemLinkSetInfo(itemLink) -- verified
  if (isSetItem) then
    adder = MasterMerchant.concat(adder, 'set', setName)
  end

  -- adds Sword, Healing Staff
  local weaponType = GetItemLinkWeaponType(itemLink) -- verified
  if (weaponType ~= 0) then
    adder = MasterMerchant.concat(adder, zo_strformat("<<t:1>>", GetString("SI_WEAPONTYPE", weaponType)))
  end

  -- adds chest two-handed
  local itemEquip = GetItemLinkEquipType(itemLink) -- verified
  if (itemEquip ~= 0) then
    adder = MasterMerchant.concat(adder, zo_strformat("<<t:1>>", GetString("SI_EQUIPTYPE", itemEquip)))
  end

  -- adds Precise
  local itemTrait = GetItemLinkTraitType(itemLink) -- verified
  if (itemTrait ~= 0) then
    adder = MasterMerchant.concat(adder, zo_strformat("<<t:1>>", GetString("SI_ITEMTRAITTYPE", itemTrait)))
  end

  resultTable = {}
  resultString = string.gmatch(adder, '%S+')
  for word in resultString do
      if next(resultTable) == nil then
          table.insert(resultTable, word)
      elseif not is_in(word, resultTable) then
          table.insert(resultTable, " " .. word)
      end
  end
  adder = table.concat(resultTable)
  return string.lower(adder)
end

function MasterMerchant:playSounds(lastIndex)

  local index, value = next(SOUNDS, lastIndex)
  if index then
    d(index)
    PlaySound(value)

    zo_callLater(function()
      local LEQ = LibExecutionQueue:new()
      LEQ:ContinueWith(function() self:playSounds(index) end, nil)
    end, 2000)
  end
end

function MasterMerchant:setScanning(start)
  self.isScanning = start
  MasterMerchantResetButton:SetEnabled(not start)
  MasterMerchantGuildResetButton:SetEnabled(not start)
  MasterMerchantRefreshButton:SetEnabled(not start)
  MasterMerchantGuildRefreshButton:SetEnabled(not start)

  if not start then
    MasterMerchantWindowLoadingIcon.animation:Stop()
    MasterMerchantGuildWindowLoadingIcon.animation:Stop()
    MasterMerchantGuildWindowLoadingIcon.animation:Stop()
  end

  MasterMerchantWindowLoadingIcon:SetHidden(not start)
  MasterMerchantGuildWindowLoadingIcon:SetHidden(not start)
  MasterMerchantGuildWindowLoadingIcon:SetHidden(not start)

  if start then
    MasterMerchantWindowLoadingIcon.animation:PlayForward()
    MasterMerchantGuildWindowLoadingIcon.animation:PlayForward()
    MasterMerchantGuildWindowLoadingIcon.animation:PlayForward()
  end
end

function MasterMerchant:setScanningParallel(start, guildName)
  self.isScanningParallel[guildName] = start
  MasterMerchantResetButton:SetEnabled(not start)
  MasterMerchantGuildResetButton:SetEnabled(not start)
  MasterMerchantRefreshButton:SetEnabled(not start)
  MasterMerchantGuildRefreshButton:SetEnabled(not start)

  if not start then
    MasterMerchantWindowLoadingIcon.animation:Stop()
    MasterMerchantGuildWindowLoadingIcon.animation:Stop()
    MasterMerchantGuildWindowLoadingIcon.animation:Stop()
  end

  MasterMerchantWindowLoadingIcon:SetHidden(not start)
  MasterMerchantGuildWindowLoadingIcon:SetHidden(not start)
  MasterMerchantGuildWindowLoadingIcon:SetHidden(not start)

  if start then
    MasterMerchantWindowLoadingIcon.animation:PlayForward()
    MasterMerchantGuildWindowLoadingIcon.animation:PlayForward()
    MasterMerchantGuildWindowLoadingIcon.animation:PlayForward()
  end
end

-- For faster searching of large histories, we'll maintain an inverted
-- index of search terms - here we build the indexes from the existing table
function MasterMerchant:indexHistoryTables()

  -- DEBUG  Stop Indexing
  --do return end

  local prefunc = function(extraData)
    if MasterMerchant.systemSavedVariables.minimalIndexing then
      MasterMerchant.v(3, 'Minimal Indexing...')
    else
      MasterMerchant.v(3, 'Full Indexing...')
    end
    extraData.start = GetTimeStamp()
    extraData.checkMilliseconds = 60
    extraData.indexCount = 0
    extraData.wordsIndexCount = 0
    self.SRIndex = {}
    self:setScanning(true)
  end

  local tconcat = table.concat
  local tinsert = table.insert
  local tolower = string.lower
  local temp = { 'b', '', ' s', '', ' ', '', ' ', '', ' ', '', ' ', '' }
  local playerName = tolower(GetDisplayName())

  local loopfunc = function(numberID, itemData, versiondata, itemIndex, soldItem, extraData)

    extraData.indexCount = extraData.indexCount + 1

    local searchText
    if MasterMerchant.systemSavedVariables.minimalIndexing then
      if playerName == tolower(soldItem['seller']) then
        searchText = tolower(MasterMerchant.PlayerSpecialText)
      else
        searchText = ''
      end
    else
      versiondata.itemAdderText = versiondata.itemAdderText or self.addedSearchToItem(soldItem['itemLink'])
      versiondata.itemDesc = versiondata.itemDesc or GetItemLinkName(soldItem['itemLink'])
      versiondata.itemIcon = versiondata.itemIcon or GetItemLinkInfo(soldItem['itemLink'])

      temp[2] = soldItem['buyer'] or ''
      temp[4] = soldItem['seller'] or ''
      temp[6] = soldItem['guild'] or ''
      temp[8] = versiondata.itemDesc or ''
      temp[10] = versiondata.itemAdderText or ''
      if playerName == tolower(soldItem['seller']) then
        temp[12] = MasterMerchant.PlayerSpecialText
      else
        temp[12] = ''
      end
      searchText = tolower(tconcat(temp, ''))
    end

    -- Index each word
    local searchByWords = string.gmatch(searchText, '%S+')
    local wordData = { numberID, itemData, itemIndex }
    for i in searchByWords do
      if self.SRIndex[i] == nil then
        extraData.wordsIndexCount = extraData.wordsIndexCount + 1
        self.SRIndex[i] = {}
      end
      tinsert(self.SRIndex[i], wordData)
    end

  end

  local postfunc = function(extraData)
    self:setScanning(false)
    MasterMerchant.v(3, 'Indexing: ' .. GetTimeStamp() - extraData.start .. ' seconds to index:')
    MasterMerchant.v(3, '  ' .. extraData.indexCount .. ' sales records')
    if extraData.wordsIndexCount > 1 then
      MasterMerchant.v(3, '  ' .. extraData.wordsIndexCount .. ' unique words')
    end
  end

  if not self.isScanning then
    self:iterateOverSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {})
  end

end

function MasterMerchant:BuildAccountNameLookup()
  if not MM16DataSavedVariables["AccountNames"] then MM16DataSavedVariables["AccountNames"] = {} end
  for key, value in pairs(MM16DataSavedVariables["AccountNames"]) do
    MasterMerchant.accountNameByIdLookup[value] = key
  end
end
function MasterMerchant:BuildItemLinkNameLookup()
  if not MM16DataSavedVariables["ItemLink"] then MM16DataSavedVariables["ItemLink"] = {} end
  for key, value in pairs(MM16DataSavedVariables["ItemLink"]) do
    MasterMerchant.itemLinkNameByIdLookup[value] = key
  end
end
function MasterMerchant:BuildGuildNameLookup()
  if not MM16DataSavedVariables["GuildNames"] then MM16DataSavedVariables["GuildNames"] = {} end
  for key, value in pairs(MM16DataSavedVariables["GuildNames"]) do
    MasterMerchant.guildNameByIdLookup[value] = key
  end
end

--[[Set MM16Data.lua file to store information to be used to reduce
the size of the saved vars.
]]--
local function setSalesTableData(key)
  local savedVars = MM16DataSavedVariables
  local lookupData = savedVars
  lookupData[key] = {}
  return lookupData[key]
end

function MasterMerchant:AddSalesTableData(key, value)
  if not MM16DataSavedVariables[key] then
    MM16DataSavedVariables[key] = setSalesTableData(key)
  end
  if not MM16DataSavedVariables[key][value] then
    local index = MasterMerchant.NonContiguousNonNilCount(MM16DataSavedVariables[key]) + 1
    MM16DataSavedVariables[key][value] = index
    if key == "AccountNames" then
      MasterMerchant.accountNameByIdLookup[index] = value
    end
    if key == "ItemLink" then
      MasterMerchant.itemLinkNameByIdLookup[index] = value
    end
    if key == "GuildNames" then
      MasterMerchant.guildNameByIdLookup[index] = value
    end
    return index
  end
  return nil
end

function MasterMerchant:IsValidItemLink(itemLink)
  local validLink = true
  local _, count = string.gsub(itemLink, ':', ':')
  if count ~= 22 then validLink = false end
  local theIID = GetItemLinkItemId(itemLink)
  local itemIdMatch = tonumber(string.match(itemLink, '|H.-:item:(.-):'))
  if not theIID then validLink = false end
  if theIID and (theIID ~= itemIdMatch) then validLink = false end
  local itemlinkName = GetItemLinkName(itemLink)
  if MasterMerchant:is_empty_or_nil(itemlinkName) then validLink = false end
  return validLink
end

function MasterMerchant:CheckForDuplicate(itemLink, eventID)
  local dupe = false
  --[[ we need to be able to calculate theIID and itemIndex
  when not used with addToHistoryTables() event though
  the function will calculate them.
  ]]--
  if MasterMerchant.systemSavedVariables.verbose == 7 then
    if not MasterMerchant:IsValidItemLink(itemLink) then
      MasterMerchant.dm("Warn", string.format("malformed itemLink for event %s",eventID))
      MasterMerchant.dm("Warn", itemLink)
      --return
    end
  else
    local key, count = string.gsub(itemLink, ':', ':')
    if count ~= 22 then return end
  end
  local theIID = GetItemLinkItemId(itemLink)
  if theIID == nil or theIID == 0 then return end
  local itemIndex = self.makeIndexFromLink(itemLink)

  if self.salesData[theIID] and self.salesData[theIID][itemIndex] then
    for k, v in pairs(self.salesData[theIID][itemIndex]['sales']) do
      if v.id == eventID then
        dupe = true
        if MasterMerchant.systemSavedVariables.verbose == 7 then
          if v.itemLink ~= itemLink then
            MasterMerchant.dm("Warn", "Item link mismatch : " .. v.id)
            table.insert(MasterMerchant.purgeQueue, v.id)
          end
        end
        break
      end
    end
  end
  return dupe
end

--[[Set which MMxxData.lua file will store the item information
based on the modulo obtained from the hash which is based on
the itemLink information.
]]--
local function setSalesData(itemLink, theIID)
  local hash = MasterMerchant.hashString(string.lower(GetItemLinkName(itemLink)))
  local dataTable = _G[string.format("MM%02dData", hash)]
  local savedVars = dataTable.savedVariables
  local salesData = savedVars.SalesData
  salesData[theIID] = {}
  return salesData[theIID]
end

-- And here we add a new item
function MasterMerchant:addToHistoryTables(theEvent)

  -- DEBUG  Stop Adding
  --do return end

  --[[
  local theEvent = {
    buyer = p2,
    guild = guildName,
    itemName = p4,
    quant = p3,
    saleTime = eventTime,
    salePrice = p5,
    seller = p1,
    kioskSale = false,
    id = Id64ToString(eventId)
  }
  local newSalesItem =
    {buyer = theEvent.buyer,
    guild = theEvent.guild,
    itemLink = theEvent.itemName,
    quant = tonumber(theEvent.quant),
    timestamp = tonumber(theEvent.saleTime),
    price = tonumber(theEvent.salePrice),
    seller = theEvent.seller,
    wasKiosk = theEvent.kioskSale,
    id = theEvent.id
  }
  [1] =
  {
    ["price"] = 120,
    ["itemLink"] = "|H0:item:45057:359:50:26848:359:50:0:0:0:0:0:0:0:0:0:5:0:0:0:0:0|h|h",
    ["id"] = 1353657539,
    ["guild"] = "Unstable Unicorns",
    ["buyer"] = "@Traeky",
    ["quant"] = 1,
    ["wasKiosk"] = true,
    ["timestamp"] = 1597969403,
    ["seller"] = "@cherrypick",
  },
  ]]--

  local key, count = string.gsub(theEvent.itemLink, ':', ':')
  if count ~= 22 then return end
  -- first add new data looks to their tables
  local linkHash = MasterMerchant:AddSalesTableData("ItemLink", theEvent.itemLink)
  local buyerHash = MasterMerchant:AddSalesTableData("AccountNames", theEvent.buyer)
  local sellerHash = MasterMerchant:AddSalesTableData("AccountNames", theEvent.seller)
  local guildHash = MasterMerchant:AddSalesTableData("GuildNames", theEvent.guild)

  --[[The quality effects itemIndex although the ID from the
  itemLink may be the same. We will keep them separate.
  ]]--
  local itemIndex = self.makeIndexFromLink(theEvent.itemLink)
  --[[theIID is used in the SRIndex so define it here.
  ]]--
  local theIID = GetItemLinkItemId(theEvent.itemLink)
  if theIID == nil or theIID == 0 then return end

  --[[If the ID from the itemLink doesn't exist determine which
  file or container it will belong to using setSalesData()
  ]]--
  if not self.salesData[theIID] then
    self.salesData[theIID] = setSalesData(theEvent.itemLink, theIID)
  end

  local insertedIndex = 1

  local searchItemDesc = ""
  local searchItemAdderText = ""

  if self.salesData[theIID][itemIndex] then
    local nextLocation = #self.salesData[theIID][itemIndex]['sales'] + 1
    searchItemDesc = self.salesData[theIID][itemIndex].itemDesc
    searchItemAdderText = self.salesData[theIID][itemIndex].itemAdderText
    if self.salesData[theIID][itemIndex]['sales'][nextLocation] == nil then
      table.insert(self.salesData[theIID][itemIndex]['sales'], nextLocation, theEvent)
      insertedIndex = nextLocation
    else
      table.insert(self.salesData[theIID][itemIndex]['sales'], theEvent)
      insertedIndex = #self.salesData[theIID][itemIndex]['sales']
    end
  else
    searchItemDesc = GetItemLinkName(theEvent.itemLink)
    searchItemAdderText = self.addedSearchToItem(theEvent.itemLink)
    self.salesData[theIID][itemIndex] = {
      itemIcon      = GetItemLinkInfo(theEvent.itemLink),
      itemAdderText = searchItemAdderText,
      itemDesc      = searchItemDesc,
      sales         = { theEvent } }
  end

  local guild
  local adderDescConcat = searchItemDesc .. ' ' .. searchItemAdderText

  guild = MasterMerchant.guildSales[theEvent.guild] or MMGuild:new(theEvent.guild)
  MasterMerchant.guildSales[theEvent.guild] = guild;
  guild:addSaleByDate(theEvent.seller, theEvent.timestamp, theEvent.price, theEvent.quant, false)

  guild = MasterMerchant.guildPurchases[theEvent.guild] or MMGuild:new(theEvent.guild)
  MasterMerchant.guildPurchases[theEvent.guild] = guild;
  guild:addSaleByDate(theEvent.buyer, theEvent.timestamp, theEvent.price, theEvent.quant, theEvent.wasKiosk)

  guild = MasterMerchant.guildItems[theEvent.guild] or MMGuild:new(theEvent.guild)
  MasterMerchant.guildItems[theEvent.guild] = guild;
  guild:addSaleByDate(theEvent.itemLink, theEvent.timestamp, theEvent.price, theEvent.quant, false, nil,
    adderDescConcat)

  local playerName = string.lower(GetDisplayName())
  local isSelfSale = playerName == string.lower(theEvent.seller)

  if isSelfSale then
    guild = MasterMerchant.myItems[theEvent.guild] or MMGuild:new(theEvent.guild)
    MasterMerchant.myItems[theEvent.guild] = guild;
    guild:addSaleByDate(theEvent.itemLink, theEvent.timestamp, theEvent.price, theEvent.quant, false, nil,
      adderDescConcat)
  end

  local temp = { 'b', '', ' s', '', ' ', '', ' ', '', ' ', '', ' ', '' }
  local searchText = ""
  if MasterMerchant.systemSavedVariables.minimalIndexing then
    if isSelfSale then
      searchText = MasterMerchant.PlayerSpecialText
    else
      searchText = ''
    end
  else
    temp[2] = theEvent.buyer or ''
    temp[4] = theEvent.seller or ''
    temp[6] = theEvent.guild or ''
    temp[8] = searchItemDesc or ''
    temp[10] = searchItemAdderText or ''
    if isSelfSale then
      temp[12] = MasterMerchant.PlayerSpecialText
    else
      temp[12] = ''
    end
    searchText = string.lower(table.concat(temp, ''))
  end

  local searchByWords = string.gmatch(searchText, '%S+')
  local wordData = { theIID, itemIndex, insertedIndex }

  -- Index each word
  for i in searchByWords do
    self.SRIndex[i] = self.SRIndex[i] or {}
    table.insert(self.SRIndex[i], wordData)
  end

  -- set lookuptable to nil more or less
  if MasterMerchant.itemAverageLookupTable[theIID] == nil then
    MasterMerchant.itemAverageLookupTable[theIID] = {}
  end
  if MasterMerchant.itemAverageLookupTable[theIID][itemIndex] == nil then
    MasterMerchant.itemAverageLookupTable[theIID][itemIndex] = {}
  end
  MasterMerchant.itemAverageLookupTable[theIID][itemIndex] = { }

  return true
end

-- the result as a string.
-- ||cffffff38||r
-- ||u0:6%:currency:||u
-- ||t80%:80%:/esoui/art/currency/gold_mipmap.dds||t
-- '|r |t16:16:EsoUI/Art/currency/currency_gold.dds|t'
function MasterMerchant.LocalizedNumber(numberValue, chatText)
  if not numberValue then return '0' end
  if (numberValue > 100) or MasterMerchant.systemSavedVariables.trimDecimals then
    stringPrice = string.format('%.0f', numberValue)
  else
    stringPrice = string.format('%.2f', numberValue)
  end
  local subString = '%1' .. GetString(SK_THOUSANDS_SEP) .. '%2'
  -- Insert thousands separators for the price
  while true do
    stringPrice, k = string.gsub(stringPrice, '^(-?%d+)(%d%d%d)', subString)
    if (k == 0) then break end
  end
  return stringPrice
end

function MasterMerchant:UpdateItemLink(itemLink)
  if GetAPIVersion() == 100011 then
    local linkTable = { ZO_LinkHandler_ParseLink(itemLink) }
    if #linkTable == 23 and linkTable[3] == ITEM_LINK_TYPE then
      linkTable[24] = linkTable[23]
      linkTable[23] = linkTable[22]
      linkTable[22] = '0'
      if linkTable[4] == '32311' then
        itemLink = '|H1:collectible:34|hSkeleton Polymorph|h'
      else
        itemLink = ('|H%d:%s|h%s|h'):format(linkTable[2], table.concat(linkTable, ':', 3), '')
        linkTable[1] = GetItemLinkName(itemLink)
        itemLink = ("|H%d:%s|h%s|h"):format(linkTable[2], table.concat(linkTable, ':', 3), linkTable[1])
      end
    end
  end
  return itemLink
end

-- Create a textual representation of a time interval
function MasterMerchant.TextTimeSince(theTime, useLowercase)
  local secsSince = GetTimeStamp() - theTime

  if secsSince < 864000 then
    return ZO_FormatDurationAgo(secsSince)
  else
    return zo_strformat(GetString(SK_TIME_DAYS), math.floor(secsSince / 86400.0))
  end
end

-- Grabs the first and last events in guildID's sales history and compares the secsSince
-- values returned.  Returns true if the first event (ID 1) is newer than the last event,
-- false otherwise.
function MasterMerchant.IsNewestFirst(guildID)
  local numEvents = GetNumGuildEvents(guildID, GUILD_HISTORY_STORE)
  local _, secsSinceFirst, _, _, _, _, _, _ = GetGuildEventInfo(guildID, GUILD_HISTORY_STORE, 1)
  local _, secsSinceLast, _, _, _, _, _, _ = GetGuildEventInfo(guildID, GUILD_HISTORY_STORE, numEvents)
  return (secsSinceFirst < secsSinceLast)
end

-- A simple utility function to return which set of settings are active,
-- based on the allSettingsAccount option setting.
function MasterMerchant:ActiveSettings()
  return ((self.acctSavedVariables.allSettingsAccount and self.acctSavedVariables) or
    self.savedVariables)
end

function MasterMerchant:ActiveWindow()
  return ((MasterMerchant.systemSavedVariables.viewSize == 'full' and MasterMerchantWindow) or MasterMerchantGuildWindow)
end

-- A utility function to grab all the keys of the sound table
-- to populate the options dropdown
function MasterMerchant:SoundKeys()
  local keyList = {}
  for i = 1, #self.alertSounds do table.insert(keyList, self.alertSounds[i].name) end
  return keyList
end

-- A utility function to find the key associated with a given value in
-- the sounds table.  Best we can do is a linear search unfortunately,
-- but it's a small table.
function MasterMerchant:SearchSounds(sound)
  for _, theSound in ipairs(self.alertSounds) do
    if theSound.sound == sound then return theSound.name end
  end

  -- If we hit this point, we didn't find what we were looking for
  return nil
end

-- Same as searchSounds, above, but compares names instead of sounds.
function MasterMerchant:SearchSoundNames(name)
  for _, theSound in ipairs(self.alertSounds) do
    if theSound.name == name then return theSound.sound end
  end
end
