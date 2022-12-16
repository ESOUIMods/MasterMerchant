-- MasterMerchant Utility Functions File
-- Last Updated September 15, 2014
-- Written August 2014 by Dan Stone (@khaibit) - dankitymao@gmail.com
-- Extended February 2015 by Chris Lasswell (@Philgo68) - Philgo68@gmail.com
-- Released under terms in license accompanying this file.
-- Distribution without license is prohibited!

--  |H0:item:69359:96:50:26848:96:50:0:0:0:0:0:0:0:0:0:19:0:0:0:0:0|h|h  AUTGuild 1058 days
local internal = _G["LibGuildStore_Internal"]

-- Gap values for Shell sort
MasterMerchant.shellGaps = {
  1391376, 463792, 198768, 86961, 33936, 13776, 4592, 1968, 861, 336, 112, 48, 21, 7, 3, 1
}

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

-- MM has no data   for |H1:item:86987:363:50:0:0:0:0:0:0:0:0:0:0:0:1:3:0:1:0:400:0|h|h

function MasterMerchant.concat(...)
  local theString = MM_STRING_EMPTY
  for i = 1, select('#', ...) do
    local option = select(i, ...)
    if option ~= nil and option ~= MM_STRING_EMPTY then
      theString = theString .. tostring(option) .. MM_STRING_SEPARATOR_SPACE
    end
  end
  theString = string.gsub(theString, '^%s*(.-)%s*$', '%1')
  return theString
end

function MasterMerchant.concatTooltip(...)
  local theString = MM_STRING_EMPTY
  for i = 1, select('#', ...) do
    local option = select(i, ...)
    if option ~= nil and option ~= MM_STRING_EMPTY then
      theString = theString .. tostring(option)
    end
  end
  return theString
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
    local tipStats = MasterMerchant:GetTooltipStats(itemLink, true, false)
    if tipStats.avgPrice then
      return tipStats.avgPrice
    end
  end
  return 0
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
  local function comma_value(amount)
    local formatted = amount
    local k
    while true do
      formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1' .. GetString(SK_THOUSANDS_SEP) .. '%2')
      if (k == 0) then
        break
      end
    end
    return formatted
  end

  if not amount then
    return tostring(0)
  end
  -- Check if amount is an integer
  if (IsInGamepadPreferredMode() or MasterMerchant.systemSavedVariables.trimDecimals) or amount > 100 or IsValueInteger(amount) then
    return comma_value(zo_floor(amount))
  end
  -- Round to two decimal values
  return comma_value(zo_roundToNearest(amount, .01))
end

function MasterMerchant:GetFullPriceOrProfit(dispPrice, quantity)
  local _, _, expectedProfit = GetTradingHousePostPriceInfo(dispPrice)
  if MasterMerchant.systemSavedVariables.showFullPrice then
    if MasterMerchant.systemSavedVariables.showUnitPrice and quantity > 0 then
      return dispPrice / (quantity or 1)
    end
    return dispPrice
  else
    if MasterMerchant.systemSavedVariables.showUnitPrice and quantity > 0 then
      return expectedProfit / (quantity or 1)
    end
    return expectedProfit
  end
end

local function GetTimeAgo(timestamp)
  local secsSince = GetTimeStamp() - timestamp
  local formatedTime = nil
  if secsSince < ZO_ONE_DAY_IN_SECONDS then
    formatedTime = ZO_FormatDurationAgo(secsSince)
  else
    formatedTime = zo_strformat(GetString(SK_TIME_DAYS), math.floor(secsSince / ZO_ONE_DAY_IN_SECONDS))
  end
  return formatedTime
end

local function GetDateFormattedString(month, day, yearString)
  local dateString = ""
  if MasterMerchant.systemSavedVariables.dateFormatMonthDay == MM_MONTH_DAY_FORMAT then
    dateString = string.format("%s/%s", month, day)
  elseif MasterMerchant.systemSavedVariables.dateFormatMonthDay == MM_DAY_MONTH_FORMAT then
    dateString = string.format("%s/%s", day, month)
  elseif MasterMerchant.systemSavedVariables.dateFormatMonthDay == MM_MONTH_DAY_YEAR_FORMAT then
    dateString = string.format("%s/%s/%s", month, day, yearString)
  elseif MasterMerchant.systemSavedVariables.dateFormatMonthDay == MM_YEAR_MONTH_DAY_FORMAT then
    dateString = string.format("%s/%s/%s", yearString, month, day)
  elseif MasterMerchant.systemSavedVariables.dateFormatMonthDay == MM_DAY_MONTH_YEAR_FORMAT then
    dateString = string.format("%s/%s/%s", day, month, yearString)
  end
  return dateString
end

local function GetTimeDateString(timestamp)
  local timeData = os.date("*t", timestamp)
  local month = timeData.month
  local day = timeData.day
  local hour = timeData.hour
  local minute = timeData.min
  local year = timeData.year
  local postMeridiem = hour >= 12
  local yearString = string.sub(tostring(year), 3, 4)
  local meridiemString = ""
  local dateString = GetDateFormattedString(month, day, yearString)
  if not MasterMerchant.systemSavedVariables.useTwentyFourHourTime and postMeridiem then
    meridiemString = "PM"
  elseif not MasterMerchant.systemSavedVariables.useTwentyFourHourTime and not postMeridiem then
    meridiemString = "AM"
  end
  if not MasterMerchant.systemSavedVariables.useTwentyFourHourTime and (hour > 12) then
    hour = hour - 12
  end
  if minute < 10 then
    minute = "0" .. tostring(minute)
  end
  return string.format("%s %s:%s%s", dateString, hour, minute, meridiemString)
end

-- Create a textual representation of a time interval
function MasterMerchant.TextTimeSince(timestamp)
  if MasterMerchant.systemSavedVariables.useFormatedTime then
    return GetTimeDateString(timestamp)
  else
    return GetTimeAgo(timestamp)
  end
end

function MasterMerchant:BuildTableFromString(str)
  local t = {}
  local function helper(line)
    if line ~= MM_STRING_EMPTY then
      t[line] = true
    end
    return MM_STRING_EMPTY
  end
  helper((str:gsub("(.-)\r?\n", helper)))
  if next(t) then return t end
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
