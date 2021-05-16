-- MasterMerchant Utility Functions File
-- Last Updated September 15, 2014
-- Written August 2014 by Dan Stone (@khaibit) - dankitymao@gmail.com
-- Extended February 2015 by Chris Lasswell (@Philgo68) - Philgo68@gmail.com
-- Released under terms in license accompanying this file.
-- Distribution without license is prohibited!

--  |H0:item:69359:96:50:26848:96:50:0:0:0:0:0:0:0:0:0:19:0:0:0:0:0|h|h  AUTGuild 1058 days
local internal = _G["LibGuildStore_Internal"]

function MasterMerchant:ssup(inputTable, numElements)
  for _, gapVal in ipairs(MasterMerchant.shellGaps) do
    for i = gapVal + 1, numElements do
      local tableVal = inputTable[i]
      for j = i - gapVal, 1, -gapVal do
        local testVal = inputTable[j]
        if not (tableVal < testVal) then break end
        inputTable[i] = testVal;
        i             = j
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
        i             = j
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
        i             = j
      end
      inputTable[i] = tableVal
    end
  end
  return inputTable
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
  local numChildren = zo_min(control:GetNumChildren(), endNum)
  local numStart    = zo_min(startNum, numChildren)
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
    local theIID    = GetItemLinkItemId(itemLink)
    local itemIndex = internal:MakeIndexFromLink(itemLink)
    local tipStats  = MasterMerchant:toolTipStats(theIID, itemIndex, true, true, false)
    if tipStats.avgPrice then
      return tipStats.avgPrice
    end
  end
  return 0
end

local function GetLevelAndCPRequirementFromItemLink(itemLink)
  local link = { ZO_LinkHandler_ParseLink(itemLink) }
  return tonumber(link[5]), tonumber(link[6])
end

local function GetPotionPowerLevel(itemLink)
  local CP, level = GetLevelAndCPRequirementFromItemLink(itemLink)
  if level < 50 then
    return level
  end
  return CP
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

function MasterMerchant:Expected(eventID)
  for itemNumber, itemNumberData in pairs(sales_data) do
    for itemIndex, itemData in pairs(itemNumberData) do
      if itemData['sales'] then
        for _, checking in pairs(itemData['sales']) do
          local checkIdString = checking.id
          if type(checking.id) ~= 'string' then
            checkIdString = tostring(checking.id)
          end
          if checkIdString == eventID then
            local itemType, specializedItemType = GetItemLinkItemType(checking.itemLink)
            MasterMerchant:dm("Debug", "Expected: " .. checking.itemLink .. " found in " .. itemIndex)
            if (specializedItemType ~= 0) then
              MasterMerchant:dm("Debug", MasterMerchant.concat("For",
                zo_strformat("<<t:1>>", GetString("SI_SPECIALIZEDITEMTYPE", specializedItemType))))
            end
          end
        end
      end
    end
  end
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
        itemLink     = ('|H%d:%s|h%s|h'):format(linkTable[2], table.concat(linkTable, ':', 3), '')
        linkTable[1] = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink))
        itemLink     = ("|H%d:%s|h%s|h"):format(linkTable[2], table.concat(linkTable, ':', 3), linkTable[1])
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
  local numEvents                           = GetNumGuildEvents(guildID, GUILD_HISTORY_STORE)
  local _, secsSinceFirst, _, _, _, _, _, _ = GetGuildEventInfo(guildID, GUILD_HISTORY_STORE, 1)
  local _, secsSinceLast, _, _, _, _, _, _  = GetGuildEventInfo(guildID, GUILD_HISTORY_STORE, numEvents)
  return (secsSinceFirst < secsSinceLast)
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
