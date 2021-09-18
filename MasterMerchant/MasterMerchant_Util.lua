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
  local numStart = zo_min(startNum, numChildren)
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
    local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
    local tipStats = MasterMerchant:GetTooltipStats(theIID, itemIndex, true, true)
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

-- the result as a string.
-- ||cffffff38||r
-- ||u0:6%:currency:||u
-- ||t80%:80%:/esoui/art/currency/gold_mipmap.dds||t
-- '|r |t16:16:EsoUI/Art/currency/currency_gold.dds|t'
local function IsValueInteger(value)
  return value % 2 == 0
end

function MasterMerchant.LocalizedNumber(amount)
  if not amount then
    return tostring(0)
  end
  -- Check if amount is an integer
  if MasterMerchant.systemSavedVariables.trimDecimals or amount > 100 or IsValueInteger(amount) then
    return ZO_CommaDelimitNumber(zo_floor(amount))
  end
  -- Round to two decimal values
  return ZO_CommaDelimitDecimalNumber(zo_roundToNearest(amount, .01))
end

-- Create a textual representation of a time interval
function MasterMerchant.TextTimeSince(theTime, useLowercase)
  local secsSince = GetTimeStamp() - theTime

  if secsSince < 864000 then
    return ZO_FormatDurationAgo(secsSince)
  else
    return zo_strformat(GetString(SK_TIME_DAYS), math.floor(secsSince / ZO_ONE_DAY_IN_SECONDS))
  end
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
