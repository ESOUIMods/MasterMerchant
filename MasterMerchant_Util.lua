-- MasterMerchant Utility Functions File
-- Last Updated September 15, 2014
-- Written August 2014 by Dan Stone (@khaibit) - dankitymao@gmail.com
-- Extended February 2015 by Chris Lasswell (@Philgo68) - Philgo68@gmail.com
-- Released under terms in license accompanying this file.
-- Distribution without license is prohibited!

--  |H0:item:69359:96:50:26848:96:50:0:0:0:0:0:0:0:0:0:19:0:0:0:0:0|h|h  AUTGuild 1058 days

function MasterMerchant.v(level, ...)
  -- DEBUG
  if (level <= MasterMerchant:ActiveSettings().verbose) then
    if ... then d(...) end
    return true
  end
  return false
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

  -- Don't really *need* to do this but for consistency's sake...
  return inputTable
end

function MasterMerchant.spairs(t, order)
  -- all the indexes
  local indexes = {}
  for k in pairs(t) do indexes[#indexes+1] = k end

  -- if order function given, sort by it by passing the table's a, b values
  -- otherwise just sort by the index values
  if order then
    table.sort(indexes, function(a,b) return order(t[a], t[b]) end)
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

function MasterMerchant.hashString(name)
  local hash = 0
  for c in string.gmatch(name, '.') do
    if c then hash = hash + string.byte(c) end
  end
  return hash % 16
end

function MasterMerchant.concat(a,...)
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
        d(i .. ') ' .. child:GetName() .. ' - ' .. child:GetText() )
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
	    local theIID = string.match(itemLink, '|H.-:item:(.-):')
	    local itemIndex = MasterMerchant.makeIndexFromLink(itemLink)
	    local tipStats = MasterMerchant:toolTipStats(tonumber(theIID), itemIndex, true, true, false)
	    if tipStats.avgPrice then
		    return tipStats.avgPrice
        end
    end
    return 0
end

-- The index consists of the item's required level, required vet
-- level, quality, and trait(if any), separated by colons.
function MasterMerchant.makeIndexFromLink(itemLink)
  --Standardize Level to 1 if the level is not relevent but is stored on some items (ex: recipes)
  local levelReq = 1
  local itemType = GetItemLinkItemType(itemLink)
  if itemType ~= ITEMTYPE_RECIPE then
    levelReq = GetItemLinkRequiredLevel(itemLink)
  end
  local vetReq = GetItemLinkRequiredChampionPoints(itemLink) / 10
  local itemQuality = GetItemLinkQuality(itemLink)
  local itemTrait = GetItemLinkTraitInfo(itemLink)
  --Add final number in the link to handle item differences like 2 and 3 buff potions
  local theLastNumber = string.match(itemLink, '|H.-:item:.-:(%d-)|h') or 0

  local index = levelReq .. ':' .. vetReq .. ':' .. itemQuality .. ':' .. itemTrait .. ':' .. theLastNumber

  return index
end

-- Additional words tacked on to the item name for searching
function MasterMerchant.addedSearchToItem(itemLink)
  --Standardize Level to 1 if the level is not relevent but is stored on some items (ex: recipes)
  local requiredLevel = 1
  local itemType = GetItemLinkItemType(itemLink)
  if itemType ~= ITEMTYPE_RECIPE then
    requiredLevel = GetItemLinkRequiredLevel(itemLink)
  end

  local requiredVeteranRank = GetItemLinkRequiredChampionPoints(itemLink)
  local vrAdder = GetString(MM_CP_RANK_SEARCH)

  local adder = ''
  if(requiredLevel > 0 or requiredVeteranRank > 0) then
    if(requiredVeteranRank > 0) then
      adder = vrAdder  .. string.format('%02d',requiredVeteranRank)
    else
      adder = GetString(MM_REGULAR_RANK_SEARCH) .. string.format('%02d',requiredLevel)
    end
  else
    adder = vrAdder  .. '00 ' .. GetString(MM_REGULAR_RANK_SEARCH) .. '00'
  end

  local itemQuality = GetItemLinkQuality(itemLink)
  if (itemQuality == ITEM_QUALITY_NORMAL) then adder = MasterMerchant.concat(adder, GetString(MM_COLOR_WHITE)) end
  if (itemQuality == ITEM_QUALITY_MAGIC) then adder = MasterMerchant.concat(adder, GetString(MM_COLOR_GREEN)) end
  if (itemQuality == ITEM_QUALITY_ARCANE) then adder = MasterMerchant.concat(adder, GetString(MM_COLOR_BLUE)) end
  if (itemQuality == ITEM_QUALITY_ARTIFACT) then adder = MasterMerchant.concat(adder, GetString(MM_COLOR_PURPLE)) end
  if (itemQuality == ITEM_QUALITY_LEGENDARY) then adder = MasterMerchant.concat(adder, GetString(MM_COLOR_GOLD)) end

  adder = MasterMerchant.concat(adder, zo_strformat("<<t:1>>", GetString("SI_ITEMQUALITY", itemQuality)))

  local isSetItem, setName = GetItemLinkSetInfo(itemLink)
  if (isSetItem) then
    adder = MasterMerchant.concat(adder, 'set', setName)
  end

  local itemType = GetItemLinkItemType(itemLink)
  if (itemType ~= 0) then
    adder = MasterMerchant.concat(adder, zo_strformat("<<t:1>>", GetString("SI_ITEMTYPE", itemType)))
  end

  local itemTrait = GetItemLinkTraitInfo(itemLink)
  if (itemTrait ~= 0) then
    adder = MasterMerchant.concat(adder, zo_strformat("<<t:1>>", GetString("SI_ITEMTRAITTYPE", itemTrait)))
  end

  local itemEquip = GetItemLinkEquipType(itemLink)
  if (itemEquip ~= 0) then
    adder = MasterMerchant.concat(adder, zo_strformat("<<t:1>>", GetString("SI_EQUIPTYPE", itemEquip)))
  end

  return string.lower(adder)
end

function MasterMerchant:playSounds(lastIndex)

    local index, value = next(SOUNDS, lastIndex)
    if index then
      d(index)
      PlaySound(value)

      zo_callLater(function()
        local LEQ = LibExecutionQueue:new()
        LEQ:ContinueWith(function () self:playSounds(index) end, nil)
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

function MasterMerchant:setDigging(start)
  self.isDigging = start
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

  local prefunc = function(extraData)
    if MasterMerchant:ActiveSettings().minimalIndexing then
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
  local temp = {'b', '', ' s', '', ' ', '', ' ', '', ' ', '', ' ', ''}
  local playerName = tolower(GetDisplayName())

  local loopfunc = function(numberID, itemData, versiondata, itemIndex, soldItem, extraData)

    extraData.indexCount = extraData.indexCount + 1

    local searchText
    if MasterMerchant:ActiveSettings().minimalIndexing then
      if playerName == tolower(soldItem['seller']) then
        searchText = MasterMerchant.PlayerSpecialText
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
    local wordData = {numberID, itemData, itemIndex}
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
    self:iterateOverSalesData(nil, nil, nil, prefunc, loopfunc, postfunc, {} )
  end

end

-- And here we add a new item
function MasterMerchant:addToHistoryTables(theEvent, checkForDups)

  local theIID = string.match(theEvent.itemName, '|H.-:item:(.-):')
  if theIID == nil then return end
  theIID = tonumber(theIID)
  local itemIndex = self.makeIndexFromLink(theEvent.itemName)

  local newSalesItem =
    {buyer = theEvent.buyer,
    guild = theEvent.guild,
    itemLink = theEvent.itemName,
    quant = theEvent.quant,
    timestamp = theEvent.saleTime,
    price = theEvent.salePrice,
    seller = theEvent.seller,
    wasKiosk = theEvent.kioskSale,
    id = theEvent.id}

  if (checkForDups and self.salesData[theIID] and self.salesData[theIID][itemIndex]) then
    for k, v in pairs(self.salesData[theIID][itemIndex]['sales']) do
      if v.id == newSalesItem.id then
        return false
      end
      if v.id == nil and
          v.buyer == newSalesItem.buyer and
          v.guild == newSalesItem.guild and
          v.quant == newSalesItem.quant and
          v.price == newSalesItem.price and
          v.seller == newSalesItem.seller and
          string.match(v.itemLink, '|H(.-)|h') == string.match(newSalesItem.itemLink, '|H(.-)|h') and
          (math.abs(v.timestamp - newSalesItem.timestamp) < 2) then
        v.id = newSalesItem.id
        return false
      end
    end
  end

  if not self.salesData[theIID] then
    -- Add to the split memory set
    local action = {
      [0] = function (k) MM00Data.savedVariables.SalesData[k] = {}; return MM00Data.savedVariables.SalesData[k] end,
      [1] = function (k) MM01Data.savedVariables.SalesData[k] = {}; return MM01Data.savedVariables.SalesData[k]  end,
      [2] = function (k) MM02Data.savedVariables.SalesData[k] = {}; return MM02Data.savedVariables.SalesData[k]  end,
      [3] = function (k) MM03Data.savedVariables.SalesData[k] = {}; return MM03Data.savedVariables.SalesData[k]  end,
      [4] = function (k) MM04Data.savedVariables.SalesData[k] = {}; return MM04Data.savedVariables.SalesData[k]  end,
      [5] = function (k) MM05Data.savedVariables.SalesData[k] = {}; return MM05Data.savedVariables.SalesData[k]  end,
      [6] = function (k) MM06Data.savedVariables.SalesData[k] = {}; return MM06Data.savedVariables.SalesData[k]  end,
      [7] = function (k) MM07Data.savedVariables.SalesData[k] = {}; return MM07Data.savedVariables.SalesData[k]  end,
      [8] = function (k) MM08Data.savedVariables.SalesData[k] = {}; return MM08Data.savedVariables.SalesData[k]  end,
      [9] = function (k) MM09Data.savedVariables.SalesData[k] = {}; return MM09Data.savedVariables.SalesData[k]  end,
      [10] = function (k) MM10Data.savedVariables.SalesData[k] = {}; return MM10Data.savedVariables.SalesData[k]  end,
      [11] = function (k) MM11Data.savedVariables.SalesData[k] = {}; return MM11Data.savedVariables.SalesData[k]  end,
      [12] = function (k) MM12Data.savedVariables.SalesData[k] = {}; return MM12Data.savedVariables.SalesData[k]  end,
      [13] = function (k) MM13Data.savedVariables.SalesData[k] = {}; return MM13Data.savedVariables.SalesData[k]  end,
      [14] = function (k) MM14Data.savedVariables.SalesData[k] = {}; return MM14Data.savedVariables.SalesData[k]  end,
      [15] = function (k) MM15Data.savedVariables.SalesData[k] = {}; return MM15Data.savedVariables.SalesData[k]  end
    }

    local hash = MasterMerchant.hashString(string.lower(GetItemLinkName(theEvent.itemName)))

    self.salesData[theIID] = action[hash](theIID)
  end

  local insertedIndex = 1

  if self.salesData[theIID][itemIndex] then
    table.insert(self.salesData[theIID][itemIndex]['sales'], newSalesItem)
    insertedIndex = #self.salesData[theIID][itemIndex]['sales']
  else
    self.salesData[theIID][itemIndex] = {
      itemIcon = GetItemLinkInfo(newSalesItem.itemLink),
      itemAdderText = self.addedSearchToItem(newSalesItem.itemLink),
      itemDesc = GetItemLinkName(newSalesItem.itemLink),
      sales = {newSalesItem}}
  end

  local guild = MasterMerchant.guildSales[newSalesItem.guild] or MMGuild:new(newSalesItem.guild)
  MasterMerchant.guildSales[newSalesItem.guild] = guild;
  guild:addSaleByDate(newSalesItem.seller, newSalesItem.timestamp, newSalesItem.price, newSalesItem.quant, false)

  guild = MasterMerchant.guildPurchases[newSalesItem.guild] or MMGuild:new(newSalesItem.guild)
  MasterMerchant.guildPurchases[newSalesItem.guild] = guild;
  guild:addSaleByDate(newSalesItem.buyer, newSalesItem.timestamp, newSalesItem.price, newSalesItem.quant, newSalesItem.wasKiosk)

  guild = MasterMerchant.guildItems[newSalesItem.guild] or MMGuild:new(newSalesItem.guild)
  MasterMerchant.guildItems[newSalesItem.guild] = guild;
  guild:addSaleByDate(self.salesData[theIID][itemIndex].sales[1].itemLink, newSalesItem.timestamp, newSalesItem.price, newSalesItem.quant, false, nil, MasterMerchant.concat(self.salesData[theIID][itemIndex].itemDesc, self.salesData[theIID][itemIndex].itemAdderText))

  local isSelfSale = playerName == string.lower(theEvent.seller)
  if isSelfSale then
    guild = MasterMerchant.myItems[newSalesItem.guild] or MMGuild:new(newSalesItem.guild)
    MasterMerchant.myItems[newSalesItem.guild] = guild;
    guild:addSaleByDate(self.salesData[theIID][itemIndex].sales[1].itemLink, newSalesItem.timestamp, newSalesItem.price, newSalesItem.quant, false, nil, MasterMerchant.concat(self.salesData[theIID][itemIndex].itemDesc, self.salesData[theIID][itemIndex].itemAdderText))
  end

  local tconcat = table.concat
  local tinsert = table.insert
  local tolower = string.lower
  local temp = {'b', '', ' s', '', ' ', '', ' ', '', ' ', '', ' ', ''}
  local playerName = tolower(GetDisplayName())


  local searchText
  if MasterMerchant:ActiveSettings().minimalIndexing then
    if isSelfSale then
      searchText = MasterMerchant.PlayerSpecialText
    else
      searchText = ''
    end
  else
    temp[2] = tolower(theEvent.buyer) or ''
    temp[4] = tolower(theEvent.seller) or ''
    temp[6] = tolower(theEvent.guild) or ''
    temp[8] = tolower(GetItemLinkName(theEvent.itemName)) or ''
    temp[10] = self.addedSearchToItem(theEvent.itemName) or ''
    if isSelfSale then
      temp[12] = MasterMerchant.PlayerSpecialText
    else
      temp[12] = ''
    end
    searchText = tolower(tconcat(temp, ''))
  end

  -- Index each word
  local searchByWords = string.gmatch(searchText, '%S+')
  local wordData = {theIID, itemIndex, insertedIndex}
  --[[
  extraData.wordsIndexCount isn't used the same here as
  it is in indexHistoryTables() so it is not available.

  Was the intention to print out about report? If not then
  couldn't extraData.wordsIndexCount be removed?

  searchByWords is a function at this point
  ]]--
  for i in searchByWords do
    -- extraData.wordsIndexCount = extraData.wordsIndexCount + 1
    self.SRIndex[i] = self.SRIndex[i] or {}
    tinsert(self.SRIndex[i], wordData)
  end

  return true
end

-- Inserts a comma or period as appropriate every 3 numbers and returns
-- the result as a string.
function MasterMerchant.LocalizedNumber(numberValue)
  if not numberValue then return '0' end

  local stringPrice = numberValue
  local subString = '%1' .. GetString(SK_THOUSANDS_SEP) ..'%2'

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
  return ((self:ActiveSettings().viewSize == 'full' and MasterMerchantWindow) or MasterMerchantGuildWindow)
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
  for _,theSound in ipairs(self.alertSounds) do
    if theSound.name == name then return theSound.sound end
  end
end

-- ZOS provides prehook functions, but not posthook.  So here they are.
function MasterMerchant.functionPostHook(control, funcName, callback)
  local tmp = control[funcName]
  if ((tmp ~= nil) and (type(tmp) == 'function')) then
    local newFunc = function(...)
      if (not tmp(...)) then return callback(...) end
    end
    control[funcName] = newFunc
  end
end

function MasterMerchant.handlerPostHook(control, handName, callback)
    local tmp = control:GetHandler(handName)
    local newFunc
    if(tmp) then
        newFunc = function(...)
            if(not tmp(...)) then return callback(...) end
        end
    else newFunc = callback end
    control:SetHandler(handName, newFunc)
end

