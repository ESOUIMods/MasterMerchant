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
	    local theIID = GetItemLinkItemId(itemLink)
	    local itemIndex = MasterMerchant.makeIndexFromLink(itemLink)
	    local tipStats = MasterMerchant:toolTipStats(theIID, itemIndex, true, true, false)
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
  local itemTrait = GetItemLinkTraitType(itemLink)
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

  local itemTrait = GetItemLinkTraitType(itemLink)
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

function MasterMerchant:setScanningHistory(start, guildName)
  MasterMerchant.isScanningHistory[guildName] = start
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
  local temp = {'b', '', ' s', '', ' ', '', ' ', '', ' ', '', ' ', ''}
  local playerName = tolower(GetDisplayName())

  local loopfunc = function(numberID, itemData, versiondata, itemIndex, soldItem, extraData)

    extraData.indexCount = extraData.indexCount + 1

    local searchText
    if MasterMerchant.systemSavedVariables.minimalIndexing then
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

function MasterMerchant:CheckForDuplicate(itemLink, eventID)
  local dupe = false
  --[[ we need to be able to calculate theIID and itemIndex
  when not used with addToHistoryTables() event though
  the function will calculate them.
  ]]--
  local theIID = GetItemLinkItemId(itemLink)
  if theIID == nil then return end
  local itemIndex = self.makeIndexFromLink(itemLink)

  if self.salesData[theIID] and self.salesData[theIID][itemIndex] then
    for k, v in pairs(self.salesData[theIID][itemIndex]['sales']) do
      if type(v.id) == "number" then
        if tostring(v.id) == eventID then
          dupe = true
          break
        end
      elseif v.id == eventID then
        dupe = true
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

  --[[The quality effects itemIndex although the ID from the
  itemLink may be the same. We will keep them separate.
  ]]--
  local itemIndex = self.makeIndexFromLink(theEvent.itemLink)
  --[[theIID is used in the SRIndex so define it here.
  ]]--
  local theIID = GetItemLinkItemId(theEvent.itemLink)
  if theIID == nil then return end

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
      itemIcon = GetItemLinkInfo(theEvent.itemLink),
      itemAdderText = searchItemAdderText,
      itemDesc = searchItemDesc,
      sales = {theEvent}}
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
  guild:addSaleByDate(theEvent.itemLink, theEvent.timestamp, theEvent.price, theEvent.quant, false, nil, adderDescConcat)

  local playerName = string.lower(GetDisplayName())
  local isSelfSale = playerName == string.lower(theEvent.seller)

  if isSelfSale then
    guild = MasterMerchant.myItems[theEvent.guild] or MMGuild:new(theEvent.guild)
    MasterMerchant.myItems[theEvent.guild] = guild;
    guild:addSaleByDate(theEvent.itemLink, theEvent.timestamp, theEvent.price, theEvent.quant, false, nil, adderDescConcat)
  end

  local temp = {'b', '', ' s', '', ' ', '', ' ', '', ' ', '', ' ', ''}
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
  local wordData = {theIID, itemIndex, insertedIndex}

  -- Index each word
  for i in searchByWords do
    self.SRIndex[i] = self.SRIndex[i] or {}
    table.insert(self.SRIndex[i], wordData)
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
