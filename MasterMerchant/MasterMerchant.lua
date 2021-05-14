-- MasterMerchant Main Addon File
-- Last Updated September 15, 2014
-- Written July 2014 by Dan Stone (@khaibit) - dankitymao@gmail.com
-- Extended Feb 2015 - Oct 2016 by (@Philgo68) - Philgo68@gmail.com
-- Released under terms in license accompanying this file.
-- Distribution without license is prohibited!
local LAM                       = LibAddonMenu2
local LMP                       = LibMediaProvider
local LGH                       = LibHistoire
local ASYNC                     = LibAsync

local OriginalGetTradingHouseSearchResultItemInfo
local OriginalGetTradingHouseListingItemInfo
local OriginalSetupPendingPost
local Original_ZO_InventorySlot_OnSlotClicked
g_slotActions                   = nil

local ITEMS                     = 'full'
local GUILDS                    = 'half'
local LISTINGS                  = 'listings'

CSA_EVENT_SMALL_TEXT            = 1
CSA_EVENT_LARGE_TEXT            = 2
CSA_EVENT_COMBINED_TEXT         = 3
CSA_EVENT_NO_TEXT               = 4
CSA_EVENT_RAID_COMPLETE_TEXT    = 5
MasterMerchant.oneHour          = 3600
MasterMerchant.oneDayInSeconds  = 86400
--[[
used to temporarily ignore sales that are so new
the ammount of time in seconds causes the UI to say
the sale was made 1657 months ago or 71582789 minutes ago.
]]--
MasterMerchant.oneYearInSeconds = MasterMerchant.oneDayInSeconds * 365

------------------------------
--- MM Stuff               ---
------------------------------
function MasterMerchant:SetFontListChoices()
  if MasterMerchant.effective_lang == "pl" then
    MasterMerchant.fontListChoices = { "Arial Narrow", "Consolas",
      "Futura Condensed", "Futura Condensed Bold",
      "Futura Condensed Light", "Trajan Pro", "Univers 55",
      "Univers 57", "Univers 67", }
    if not MasterMerchant:is_in(MasterMerchant.systemSavedVariables.windowFont, MasterMerchant.fontListChoices) then
      MasterMerchant.systemSavedVariables.windowFont = "Univers 57"
    end
  else
    MasterMerchant.fontListChoices = LMP:List(LMP.MediaType.FONT)
    -- /script d(LibMediaProvider:List(LibMediaProvider.MediaType.FONT))
  end
end

function MasterMerchant.CenterScreenAnnounce_AddMessage(eventId, category, ...)
  local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(category)
  messageParams:ConvertOldParams(...)
  messageParams:SetLifespanMS(3500)
  CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
end

function MasterMerchant:setupGuildColors()
  MasterMerchant:dm("Debug", "setupGuildColors")
  local nextGuild = 0
  while nextGuild < GetNumGuilds() do
    nextGuild           = nextGuild + 1
    local nextGuildID   = GetGuildId(nextGuild)
    local nextGuildName = GetGuildName(nextGuildID)
    if nextGuildName ~= "" or nextGuildName ~= nil then
      local r, g, b                  = GetChatCategoryColor(CHAT_CHANNEL_GUILD_1 - 3 + nextGuild)
      self.guildColor[nextGuildName] = { r, g, b };
    else
      self.guildColor[nextGuildName] = { 255, 255, 255 };
    end
  end
end

function MasterMerchant:CheckTime()
  -- setup focus info
  local range = MasterMerchant.systemSavedVariables.defaultDays
  if IsControlKeyDown() and IsShiftKeyDown() then
    range = MasterMerchant.systemSavedVariables.ctrlShiftDays
  elseif IsControlKeyDown() then
    range = MasterMerchant.systemSavedVariables.ctrlDays
  elseif IsShiftKeyDown() then
    range = MasterMerchant.systemSavedVariables.shiftDays
  end

  -- 10000 for numDays is more or less like saying it is undefined
  local daysRange = 10000
  if range == GetString(MM_RANGE_NONE) then return -1, -1 end
  if range == GetString(MM_RANGE_ALL) then daysRange = 10000 end
  if range == GetString(MM_RANGE_FOCUS1) then daysRange = MasterMerchant.systemSavedVariables.focus1 end
  if range == GetString(MM_RANGE_FOCUS2) then daysRange = MasterMerchant.systemSavedVariables.focus2 end
  if range == GetString(MM_RANGE_FOCUS3) then daysRange = MasterMerchant.systemSavedVariables.focus3 end

  return GetTimeStamp() - (86400 * daysRange), daysRange
end

function RemoveSalesPerBlacklist(list)
  local dataList = { }
  local count = 0
  local lowerBlacklist = MasterMerchant.systemSavedVariables.blacklist and MasterMerchant.systemSavedVariables.blacklist:lower() or ""
  local oldestTime     = nil
  local newestTime     = nil
  for i, item in pairs(list) do
    if (not zo_plainstrfind(lowerBlacklist, item.buyer:lower())) and
      (not zo_plainstrfind(lowerBlacklist, item.seller:lower())) and
      (not zo_plainstrfind(lowerBlacklist, item.guild:lower())) then
      if oldestTime == nil or oldestTime > item.timestamp then oldestTime = item.timestamp end
      if newestTime == nil or newestTime < item.timestamp then newestTime = item.timestamp end
      count = count + 1
      table.insert(dataList, item)
    end
  end
  return dataList, count, oldestTime, newestTime
end

function UseSalesByTimestamp(list, timeCheck)
  local dataList = { }
  local count = 0
  local oldestTime     = nil
  local newestTime     = nil
  for i, item in pairs(list) do
    if item.timestamp > timeCheck then
      if oldestTime == nil or oldestTime > item.timestamp then oldestTime = item.timestamp end
      if newestTime == nil or newestTime < item.timestamp then newestTime = item.timestamp end
      count = count + 1
      table.insert(dataList, item)
    end
  end
  return dataList, count, oldestTime, newestTime
end

local stats = {}

function stats.CleanUnitPrice(salesRecord)
  local individualSale = salesRecord.price / salesRecord.quant
  return individualSale
end

function stats.GetSortedSales(t)
    local newTable = { }
    for k, v in MasterMerchant:spairs(t, function(a, b) return stats.CleanUnitPrice(a) < stats.CleanUnitPrice(b) end) do
      table.insert(newTable, v)
    end
    return newTable
end

-- Get the mean value of a table
function stats.mean( t )
  local sum = 0
  local count= 0

  for key, item in pairs(t) do
    local individualSale = item.price / item.quant
    sum = sum + individualSale
    count = count + 1
  end

  return (sum / count), count, sum
end

-- Get the median of a table.
function stats.median( t, index, range )
  local temp={}
  local sortedSales = stats.GetSortedSales(t)
  index = index or 1
  range = range or #t

  for i = index, range do
    local individualSale = sortedSales[i].price / sortedSales[i].quant
    table.insert( temp, individualSale )
  end

  table.sort( temp )

  -- If we have an even number of table elements or odd.
  if math.fmod(#temp,2) == 0 then
    -- return mean value of middle two elements
    return ( temp[#temp/2] + temp[(#temp/2)+1] ) / 2
  else
    -- return middle element
    return temp[math.ceil(#temp/2)]
  end
end

function stats.maxmin( t )
  local max = -math.huge
  local min = math.huge

  for key, item in pairs(t) do
    local individualSale = item.price / item.quant
    max = math.max( max, individualSale )
    min = math.min( min, individualSale )
  end

  return max, min
end

function stats.range( t )
  local highest, lowest = stats.maxmin( t )
  return highest - lowest
end

-- Get the mode of a table.  Returns a table of values.
-- Works on anything (not just numbers).
function stats.mode( t )
  local counts={}

  for key, item in pairs(t) do
    local individualSale = item.price / item.quant
    if counts[individualSale] == nil then
      counts[individualSale] = 1
    else
      counts[individualSale] = counts[individualSale] + 1
    end
  end

  local biggestCount = 0

  for k, v  in pairs( counts ) do
    if v > biggestCount then
      biggestCount = v
    end
  end

  local temp={}

  for k,v in pairs( counts ) do
    if v == biggestCount then
      table.insert( temp, k )
    end
  end

  return temp
end

function stats.getMiddleIndex( count )
    local evenNumber = false
    local quotient, remainder = math.modf(count / 2)
    if remainder == 0 then evenNumber = true end
    local middleIndex = quotient + math.floor(0.5+remainder)
    return middleIndex, evenNumber
end

--[[ we do not use this function in there are less then three
items in the table.

middleIndex will be rounded up when odd
]]--
function stats.interquartileRange( t )
    local middleIndex, evenNumber = stats.getMiddleIndex( #t )
    -- 1,2,3,4
    if evenNumber then
      quartile1 = stats.median( t , 1, middleIndex )
      quartile3 = stats.median( t , middleIndex + 1, #t )
    else
      -- 1,2,3,4,5
      -- odd number
      quartile1 = stats.median( t , 1, middleIndex )
      quartile3 = stats.median( t , middleIndex, #t )
    end
    return quartile1, quartile3, quartile3 - quartile1
end

function stats.evaluateQuartileRangeTable( list , quartile1, quartile3, quartileRange)
  local dataList = { }
  local count = 0
  local oldestTime     = nil
  local newestTime     = nil

  local eval = { }
  for i, item in pairs(list) do
    local individualSale = item.price / item.quant
    if (individualSale < (quartile1 - 1.5 * quartileRange)) or (individualSale > (quartile3 + 1.5 * quartileRange)) then
        --Debug(string.format("%s : %s was not in range",k,individualSale))
    else
        --Debug(string.format("%s : %s was in range",k,individualSale))
        if oldestTime == nil or oldestTime > item.timestamp then oldestTime = item.timestamp end
        if newestTime == nil or newestTime < item.timestamp then newestTime = item.timestamp end
        count = count + 1
        table.insert(dataList, item)
    end
  end
  return dataList, count, oldestTime, newestTime
end

-- Computes the weighted moving average across available data
function MasterMerchant:toolTipStats(theIID, itemIndex, skipDots, goBack, clickable)
  -- 10000 for numDays is more or less like saying it is undefined
  local returnData        = { ['avgPrice'] = nil, ['numSales'] = nil, ['numDays'] = 10000, ['numItems'] = nil, ['craftCost'] = nil }
  if not MasterMerchant.isInitialized then return returnData end
  --[[TODO why is there a days range of 10000. I get that it kinda means
  all days but the daysHistory seems to be the actual number to be using.
  For example when you press SHIFT or CTRL then daysHistory and daysRange
  are the same. However, when you do not modify the data, then daysRange
  is 10000 and daysHistory is however many days you have.
  ]]--
  local legitSales        = 0
  local daysHistory       = 0

  -- make sure we have a list of sales to work with
  if self.salesData[theIID] and self.salesData[theIID][itemIndex] and self.salesData[theIID][itemIndex]['sales'] and #self.salesData[theIID][itemIndex]['sales'] > 0 then

    local oldestTime  = nil
    local newestTime  = nil
    local initCount   = 0
    local list           = self.salesData[theIID][itemIndex]['sales']

    timeCheck, daysRange = self:CheckTime()

    if timeCheck == -1 then return returnData end

    list, initCount, oldestTime, newestTime = RemoveSalesPerBlacklist(list)

    if daysRange ~= 10000 then
      list, initCount, oldestTime, newestTime = UseSalesByTimestamp(list, timeCheck)
    end

    --[[1-2-2021 Our sales data is now ready to be trimmed if
    trim outliers is active.
    ]]--

    if MasterMerchant.systemSavedVariables.trimOutliers then
      if #list < 3 then
        -- MasterMerchant:dm("Debug", "There are less then 3 items, we can not trim outliers")
      else
        local quartile1, quartile3, quartileRange = stats.interquartileRange( list )
        list, initCount, oldestTime, newestTime = stats.evaluateQuartileRangeTable( list , quartile1, quartile3, quartileRange)
      end
    end
    --[[TODO: what is goBack

    if no sales were found do it again but don't worry about
    item.timestamp being greater then timeCheck.
    if no sales are found this way, returnData will indicate
    no sales using MM's undefind value constants

    possible use for goBack. goBack is an argument in SlideSales
    which is used when a player changes there account name.
    goBack is also used in SwitchPrice, and GetItemLinePrice

    1-2-2021 Another theroy is that goBack my be a means with which
    to specify the amount of days. Meaning /mm missing 100 might
    have been 100 days only. Code throughout MM does not seem to
    fully support this functionality or this theroy
    ]]--

    if initCount == 0 then
      return returnData
    end

    -- 10000 for numDays seems to be like saying it is all sales
    --[[TODO: how is daysRange used here. This could be this way if
        the first loop returned no sales but the second loop did

    TODO:2 Figure out what this does considering the above comment when
    daysRange might be 10000 but daysHistory is about how much history
    you have. Might be because of oldestTime.
    ]]--
    if (daysRange == 10000) then
      local quotient, remainder = math.modf((GetTimeStamp() - oldestTime) / 86400.0)
      daysHistory = quotient + math.floor(0.5 + remainder)
    else
      daysHistory = daysRange
    end

    --[[1-2-2021 We have determined that there is more then one sale
    in the table and the dayshistory using the daysrange.

    We can now trim outliers if the uses has that active
    ]]--

    --[[1-2-2021 First we will see if the data is already
    calculated.

    1-2-2021 Needs updated

    local lookupDataFound = dataPresent(theIID, itemIndex, daysRange)
    ]]--

    local timeInterval     = newestTime - oldestTime
    local lowPrice         = nil
    local highPrice        = nil
    local avgPrice         = 0
    local countSold        = 0
    local weigtedCountSold = 0
    local salesPoints      = {}
    local weightValue      = 0
    local dayInterval      = 0
    if timeInterval > 86400 then
      dayInterval = math.floor((GetTimeStamp() - oldestTime) / 86400.0) + 1
    end
    -- start loop
    for i, item in pairs(list) do
      -- get individualSale
      local individualSale = item.price / item.quant
      -- determine if it is an outlier, if toggle is on
      countSold = countSold + item.quant
      if timeInterval > 86400 then
        weightValue      = dayInterval - math.floor((GetTimeStamp() - item.timestamp) / 86400.0)
        avgPrice         = avgPrice + (item.price * weightValue)
        weigtedCountSold = weigtedCountSold + (item.quant * weightValue)
      else
        avgPrice = avgPrice + item.price
      end
      legitSales = legitSales + 1
      if lowPrice == nil then lowPrice = individualSale else lowPrice = math.min(lowPrice, individualSale) end
      if highPrice == nil then highPrice = individualSale else highPrice = math.max(highPrice, individualSale) end
      if not skipDots then
        local tooltip = nil
        --[[ clickable probably means to add the tooltip to the dot
        rather then actually click anything
        ]]--
        if clickable then
          local stringPrice = self.LocalizedNumber(individualSale)
          if item.quant == 1 then
            tooltip = zo_strformat(GetString(SK_TIME_DAYS),
              math.floor((GetTimeStamp() - item.timestamp) / 86400.0)) .. " " ..
              string.format(GetString(MM_GRAPH_TIP_SINGLE), item.guild, item.seller,
                zo_strformat('<<t:1>>', GetItemLinkName(item.itemLink)), item.buyer, stringPrice)
          else
            tooltip = zo_strformat(GetString(SK_TIME_DAYS),
              math.floor((GetTimeStamp() - item.timestamp) / 86400.0)) .. " " ..
              string.format(GetString(MM_GRAPH_TIP), item.guild, item.seller,
                zo_strformat('<<t:1>>', GetItemLinkName(item.itemLink)), item.quant, item.buyer, stringPrice)
          end
        end -- clickable
        table.insert(salesPoints, { item.timestamp, individualSale, self.guildColor[item.guild], tooltip })
      end -- end skip dots
    end -- end new loop
    if timeInterval > 86400 then
      avgPrice = avgPrice / weigtedCountSold
    else
      avgPrice = avgPrice / countSold
    end
    if legitSales >= 1 then
      returnData = { ['avgPrice']  = avgPrice, ['numSales'] = legitSales, ['numDays'] = daysHistory, ['numItems'] = countSold,
                     ['graphInfo'] = { ['oldestTime'] = oldestTime, ['low'] = lowPrice, ['high'] = highPrice, ['points'] = salesPoints } }
    end
  end
  return returnData
end

function MasterMerchant:itemStats(itemLink, clickable)
  local itemID    = GetItemLinkItemId(itemLink)
  local itemIndex = MasterMerchant.makeIndexFromLink(itemLink)
  return MasterMerchant:toolTipStats(itemID, itemIndex, nil, nil, clickable)
end

function MasterMerchant:itemHasSales(itemLink)
  local itemID    = GetItemLinkItemId(itemLink)
  local itemIndex = MasterMerchant.makeIndexFromLink(itemLink)
  return self.salesData[itemID] and self.salesData[itemID][itemIndex] and self.salesData[itemID][itemIndex]['sales'] and #self.salesData[itemID][itemIndex]['sales'] > 0
end

function MasterMerchant:itemPriceTip(itemLink, chatText, clickable)

  local tipStats = MasterMerchant:itemStats(itemLink, clickable)
  if tipStats.avgPrice then

    local tipFormat
    if tipStats['numDays'] < 2 then
      tipFormat = GetString(MM_TIP_FORMAT_SINGLE)
    else
      tipFormat = GetString(MM_TIP_FORMAT_MULTI)
    end

    local avePriceString = self.LocalizedNumber(tipStats['avgPrice'])
    tipFormat            = string.gsub(tipFormat, '.2f', 's')
    tipFormat            = string.gsub(tipFormat, 'M.M.', 'MM')
    -- chatText
    if not chatText then tipFormat = tipFormat .. '|t16:16:EsoUI/Art/currency/currency_gold.dds|t' end
    local salesString = zo_strformat(GetString(SK_PRICETIP_SALES), tipStats['numSales'])
    if tipStats['numSales'] ~= tipStats['numItems'] then
      salesString = salesString .. zo_strformat(GetString(MM_PRICETIP_ITEMS), tipStats['numItems'])
    end
    return string.format(tipFormat, salesString, tipStats['numDays'],
      avePriceString), tipStats['avgPrice'], tipStats['graphInfo']
    --return string.format(tipFormat, zo_strformat(GetString(SK_PRICETIP_SALES), tipStats['numSales']), tipStats['numDays'], tipStats['avgPrice']), tipStats['avgPrice'], tipStats['graphInfo']
  else
    return nil, tipStats['numDays'], nil
  end
end

function MasterMerchant.GetItemLinkRecipeNumIngredients(itemLink)
  local numIngredients = GetItemLinkRecipeNumIngredients(itemLink)
  if numIngredients > 0 then
    return numIngredients
  end

  -- Clear player crafted flag and switch to H0 and see if this is an item resulting from a fixed recipe.
  local switchItemLink = string.gsub(string.gsub(itemLink, '0:1:0:0:0:0|h', '0:0:0:0:0:0|h'), '|H1:', '|H0:')
  if MasterMerchant.recipeData[switchItemLink] then
    return GetItemLinkRecipeNumIngredients(MasterMerchant.recipeData[switchItemLink])
  end


  --switch to MM pricing Item style
  local mmStyleLink = string.match(switchItemLink, '|H.-:item:(.-):')
  if mmStyleLink then
    mmStyleLink = mmStyleLink .. ':' .. MasterMerchant.makeIndexFromLink(switchItemLink)
    if MasterMerchant.virtualRecipe[mmStyleLink] then
      return #MasterMerchant.virtualRecipe[mmStyleLink]
    end
  end

  --[[
  -- See if it's a craftable thingy: potion, armor, weapon
  local itemType, specializedItemType = GetItemLinkItemType('itemLink')


  --]]

  --[[
local itemType = GetItemLinkItemType(itemLink)
  local equipType = GetItemLinkEquipType(itemLink)
local weaponType = GetItemLinkWeaponType(itemLink)
local armorType = GetItemLinkArmorType(itemLink)
local trait = GetItemLinkTraitInfo(itemLink)
local quality = GetItemLinkQuality(itemLink)
local level = GetItemLinkRequiredLevel(itemLink)


  --]]
  return 0
end

function MasterMerchant.GetItemLinkRecipeIngredientInfo(itemLink, i)
  local ingLink = GetItemLinkRecipeIngredientItemLink(itemLink, i)
  if ingLink ~= '' then
    local _, _, numRequired = GetItemLinkRecipeIngredientInfo(itemLink, i)
    return ingLink, numRequired
  end

  local switchItemLink = string.gsub(string.gsub(itemLink, '0:1:0:0:0:0|h', '0:0:0:0:0:0|h'), '|H1:', '|H0:')
  if MasterMerchant.recipeData[switchItemLink] then
    return MasterMerchant.GetItemLinkRecipeIngredientInfo(MasterMerchant.recipeData[switchItemLink], i)
  end

  local mmStyleLink = string.match(switchItemLink, '|H.-:item:(.-):')
  if mmStyleLink then
    mmStyleLink = mmStyleLink .. ':' .. MasterMerchant.makeIndexFromLink(switchItemLink)
    if MasterMerchant.virtualRecipe[mmStyleLink] then
      return MasterMerchant.virtualRecipe[mmStyleLink][i].item, MasterMerchant.virtualRecipe[mmStyleLink][i].required
    end
  end

  return nil, nil

  --[[
  -- See if it's something for which we've built a recipe
  local itemType, specializedItemType = GetItemLinkItemType('itemLink')

  -- script /d(GetItemLinkRequiredLevel('

  -- Glyph |H1:item:5365:145:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h
  -- /script d(GetItemLinkItemType('|H1:item:5365:145:50:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h'))
  if itemType == ITEMTYPE_GLYPH_ARMOR or itemType == ITEMTYPE_GLYPH_JEWELRY or itemType == ITEMTYPE_GLYPH_WEAPON then
      if i == 3 then
          -- Aspect : Quality / Color
          return MasterMerchant.AspectRunes[GetItemLinkQuality(itemLink)], 1
      end
      local level = GetItemLinkRequiredLevel(itemLink)
      local cp = GetItemLinkRequiredChampionPoints(itemLink)

      if i == 1 then
          -- Potency : Level & Positive/Negative
      end
      if i == 2 then
          -- Essence : Attibute
      end
  end
  --]]
end

-- TODO fix craft cost
function MasterMerchant:itemCraftPrice(itemLink)

  local itemType = GetItemLinkItemType(itemLink)

  if (itemType == ITEMTYPE_POTION) or (itemType == ITEMTYPE_POISON) then

    -- Potions/Posions aren't done yet
    if true then
      return nil
    end

    if not IsItemLinkCrafted(itemLink) then
      return nil
    end
    local level   = GetItemLinkRequiredLevel(itemLink) + GetItemLinkRequiredChampionPoints(itemLink)
    local solvent = (itemType == ITEMTYPE_POTION and MasterMerchant.potionSolvents[level]) or MasterMerchant.poisonSolvents[level]
    local ingLink = string.format('|H1:item:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h', solvent)
    local cost    = MasterMerchant.GetItemLinePrice(ingLink)

    --for i = 1, GetMaxTraits() do
    --    local hasTraitAbility, traitAbilityDescription, traitCooldown, traitHasScaling, traitMinLevel, traitMaxLevel, traitIsChampionPoints = GetItemLinkTraitOnUseAbilityInfo(itemLink, i)
    --    if(hasTraitAbility) then
    --    end
    --end
    return cost / 4
  end

  local numIngredients = MasterMerchant.GetItemLinkRecipeNumIngredients(itemLink)
  if ((numIngredients or 0) == 0) then
    -- Try to clean up item link by moving it to level 1
    itemLink       = itemLink:gsub(":0", ":1", 1)
    numIngredients = MasterMerchant.GetItemLinkRecipeNumIngredients(itemLink)
  end
  if ((numIngredients or 0) > 0) then
    local cost = 0
    for i = 1, numIngredients do
      local ingLink, numRequired = MasterMerchant.GetItemLinkRecipeIngredientInfo(itemLink, i)
      if ingLink then
        cost = cost + (MasterMerchant.GetItemLinePrice(ingLink) * numRequired)
      end
    end

    local itemType, specializedItemType = GetItemLinkItemType(itemLink)
    -- Food or Drink or Recipe Food/Drink
    if ((itemType == ITEMTYPE_DRINK) or (itemType == ITEMTYPE_FOOD)
      or (itemType == ITEMTYPE_RECIPE and (specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_FOOD or specializedItemType == SPECIALIZED_ITEMTYPE_RECIPE_PROVISIONING_STANDARD_DRINK))) then
      cost = cost / 4
    end
    return cost
  else
    return nil
  end
end

function MasterMerchant:itemCraftPriceTip(itemLink, chatText)
  local cost = self:itemCraftPrice(itemLink)
  if cost then
    craftTip             = "Craft Cost: %s"
    local craftTipString = self.LocalizedNumber(cost)
    -- chatText
    if not chatText then craftTip = craftTip .. '|t16:16:EsoUI/Art/currency/currency_gold.dds|t' end

    return string.format(craftTip, craftTipString)
  else
    return nil
  end
end

function MasterMerchant.loadRecipesFrom(startNumber, endNumber)
  local checkTime = GetGameTimeMilliseconds()
  local recNumber = startNumber - 1
  local resultLink
  local itemLink
  while true do
    recNumber      = recNumber + 1

    itemLink       = string.format('|H1:item:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h', recNumber)
    local itemType = GetItemLinkItemType(itemLink)
    if itemType == ITEMTYPE_ENCHANTING_RUNE_ESSENCE then
      table.insert(MasterMerchant.essenceRunes, recNumber)
    elseif itemType == ITEMTYPE_ENCHANTING_RUNE_POTENCY then
      table.insert(MasterMerchant.potencyRunes, recNumber)
    elseif itemType == ITEMTYPE_ENCHANTING_RUNE_ASPECT then
      table.insert(MasterMerchant.aspectRunes, recNumber)
    elseif itemType == ITEMTYPE_POTION_BASE then
      MasterMerchant.potionSolvents[GetItemLinkRequiredLevel(itemLink) + GetItemLinkRequiredChampionPoints(itemLink)] = recNumber
    elseif itemType == ITEMTYPE_POISON_BASE then
      MasterMerchant.poisonSolvents[GetItemLinkRequiredLevel(itemLink) + GetItemLinkRequiredChampionPoints(itemLink)] = recNumber
    elseif itemType == ITEMTYPE_REAGENT then
      --[[
      MasterMerchant.reagents[recNumber] = {}
      for i = 1, GetMaxTraits() do
          local _, traitName = GetItemLinkReagentTraitInfo(itemLink, i)
          table.insert(MasterMerchant.reagents[recNumber], traitName)
          -- If you get an error here, you don't know all the flower/rune traits....
          MasterMerchant.traits[traitName] = MasterMerchant.traits[traitName] or {}
          table.insert(MasterMerchant.traits[traitName], recNumber)
      end
      --]]
    elseif itemType == ITEMTYPE_RECIPE then
      resultLink = GetItemLinkRecipeResultItemLink(itemLink)

      if (resultLink ~= "") then
        MasterMerchant.recipeData[resultLink] = itemLink
        MasterMerchant.recipeCount            = MasterMerchant.recipeCount + 1
        --DEBUG
        --d(MasterMerchant.recipeCount .. ') ' .. itemLink .. ' --> ' .. resultLink  .. ' ('  .. recNumber .. ')')
      end
    end

    if (recNumber >= endNumber) then
      MasterMerchant:dm("Info", '|cFFFF00Recipes Initialized -- Found information on ' .. MasterMerchant.recipeCount .. ' recipes.|r')
      MasterMerchant.systemSavedVariables.recipeData = MasterMerchant.recipeData
      break
    end

    if (GetGameTimeMilliseconds() - checkTime) > 20 then
      local LEQ = LibExecutionQueue:new()
      LEQ:ContinueWith(function() MasterMerchant.loadRecipesFrom(recNumber + 1, endNumber) end, 'Recipe Cont')
      break
    end
  end
end

--[[
 ITEMTYPE_GLYPH_ARMOR
 ITEMTYPE_GLYPH_JEWELRY
 ITEMTYPE_GLYPH_WEAPON

 ITEMTYPE_POISON
 ITEMTYPE_POTION

 ITEMTYPE_ALCHEMY_BASE

 ITEMTYPE_INGREDIENT
 ITEMTYPE_RECIPE

 TRAIT
 /script MasterMerchant:dm("Debug", GetString(ITEMTYPE_ADDITIVE))

 GetString("SI_ITEMTYPE", ITEMTYPE_FOOD)
 GetString("SI_SPECIALIZEDITEMTYPE", SPECIALIZED_ITEMTYPE_BLACKSMITHING_BOOSTER)
 /script MasterMerchant:dm("Debug", GetString("SPECIALIZED_ITEMTYPE_", GetItemLinkItemType(|H0:item:68633:363:50:0:0:0:0:0:0:0:0:0:0:0:0:13:0:0:0:10000:0|h|h)))
 SPECIALIZED_ITEMTYPE_RECIPE_BLACKSMITHING_DIAGRAM_FURNISHING

 GetItemLinkItemType(itemLink)

 33 - ITEMTYPE_POTION_BASE
 58 - ITEMTYPE_POISON_BASE
 31 - ITEMTYPE_REAGENT

 for i = 1, GetMaxTraits() do
  local known, name = GetItemLinkReagentTraitInfo("|H1:item:77583:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", i)
  d(name)
end


|H1:item:45806:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h
|H1:item:45844:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h
|H1:item:45850:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h

]]--
-- LOAD RECIPES
-- /script MasterMerchant.virtualRecipe = nil; MasterMerchant.recipeData = nil; MasterMerchant.setupRecipeInfo()


function MasterMerchant.setupRecipeInfo()
  if not MasterMerchant.recipeData then
    MasterMerchant.recipeData         = {}
    MasterMerchant.recipeCount        = 0

    MasterMerchant.essenceRunes       = {}
    MasterMerchant.aspectRunes        = {}
    MasterMerchant.potencyRunes       = {}

    MasterMerchant.virtualRecipe      = {}
    MasterMerchant.virtualRecipeCount = 0

    MasterMerchant.reagents           = {}
    MasterMerchant.traits             = {}
    MasterMerchant.potionSolvents     = {}
    MasterMerchant.poisonSolvents     = {}

    MasterMerchant:dm("Info", '|cFFFF00Searching Items|r')
    local LEQ = LibExecutionQueue:new()
    LEQ:Add(function() MasterMerchant.loadRecipesFrom(1, 450000) end, 'Search Items')
    LEQ:Add(function() MasterMerchant.BuildEnchantingRecipes(1, 1, 0) end, 'Enchanting Recipes')
    LEQ:Start()
  end
end

function MasterMerchant.BuildEnchantingRecipes(potency, essence, aspect)

  local checkTime = GetGameTimeMilliseconds()

  while true do
    aspect = aspect + 1
    if aspect > #MasterMerchant.aspectRunes then
      aspect  = 1
      essence = essence + 1
    end
    if essence > #MasterMerchant.essenceRunes then
      essence = 1
      potency = potency + 1
    end
    if potency > #MasterMerchant.potencyRunes then
      d('|cFFFF00Glyphs Initialized -- Created information on ' .. MasterMerchant.virtualRecipeCount .. ' glyphs.|r')
      MasterMerchant.systemSavedVariables.virtualRecipe = MasterMerchant.virtualRecipe
      break
    end

    MasterMerchant.virtualRecipeCount = MasterMerchant.virtualRecipeCount + 1
    -- Make Glyph
    local potencyNum                  = MasterMerchant.potencyRunes[potency]
    local essenceNum                  = MasterMerchant.essenceRunes[essence]
    local aspectNum                   = MasterMerchant.aspectRunes[aspect]

    local glyph                       = GetEnchantingResultingItemLink(5, potencyNum, 5, essenceNum, 5, aspectNum)
    --d(glyph)
    --d(potencyNum .. '.' .. essenceNum .. '.' .. aspectNum)
    if (glyph ~= '') then
      local mmGlyph                         = string.match(glyph,
        '|H.-:item:(.-):') .. ':' .. MasterMerchant.makeIndexFromLink(glyph)

      MasterMerchant.virtualRecipe[mmGlyph] = {
        [1] = { ['item']            = string.format('|H1:item:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h',
          potencyNum), ['required'] = 1 },
        [2] = { ['item']            = string.format('|H1:item:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h',
          essenceNum), ['required'] = 1 },
        [3] = { ['item']           = string.format('|H1:item:%d:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h',
          aspectNum), ['required'] = 1 }
      }
    end

    --DEBUG
    --d(glyph)
    --d(MasterMerchant.virtualRecipe[glyph])

    if (GetGameTimeMilliseconds() - checkTime) > 20 then
      local LEQ = LibExecutionQueue:new()
      LEQ:ContinueWith(function() MasterMerchant.BuildEnchantingRecipes(potency, essence, aspect) end,
        'Enchanting Recipes Cont')
      break
    end
  end
end

-- Copyright (c) 2014 Matthew Miller (Mattmillus)
--
-- Permission is hereby granted, free of charge, to any person
-- obtaining a copy of this software and associated documentation
-- files (the "Software"), to deal in the Software without
-- restriction, including without limitation the rights to use,
-- copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following
-- conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.

function MasterMerchant:onItemActionLinkStatsLink(itemLink)
  local tipLine, days = MasterMerchant:itemPriceTip(itemLink, true)
  if not tipLine then
    -- 10000 for numDays is more or less like saying it is undefined
    if days == 10000 then
      tipLine = GetString(MM_TIP_FORMAT_NONE)
    else
      tipLine = string.format(GetString(MM_TIP_FORMAT_NONE_RANGE), days)
    end
  end
  if tipLine then
    tipLine               = string.gsub(tipLine, 'M.M.', 'MM')
    local ChatEditControl = CHAT_SYSTEM.textEntry.editControl
    if (not ChatEditControl:HasFocus()) then StartChatInput() end
    local itemText = string.gsub(itemLink, '|H0', '|H1')
    ChatEditControl:InsertText(MasterMerchant.concat(tipLine, GetString(MM_TIP_FOR), itemText))
  end
end

function MasterMerchant:onItemActionLinkCCLink(itemLink)
  local tipLine = MasterMerchant:itemCraftPriceTip(itemLink, true)
  if not tipLine then
    tipLine = "No Crafting Price Available"
  end
  if tipLine then
    local ChatEditControl = CHAT_SYSTEM.textEntry.editControl
    if (not ChatEditControl:HasFocus()) then StartChatInput() end
    local itemText = string.gsub(itemLink, '|H0', '|H1')
    ChatEditControl:InsertText(MasterMerchant.concat(tipLine, GetString(MM_TIP_FOR), itemText))
  end
end

function MasterMerchant:onItemActionPopupInfoLink(itemLink)
  ZO_PopupTooltip_SetLink(itemLink)
end

-- Adjusted Per AssemblerManiac request 2019-2-20
--[[This function adds menu items to the master merchant window
and somehow adds this to the tooltip as well when you don't
really need it there.
]]--
function MasterMerchant.LinkHandler_OnLinkMouseUp(link, button, _, _, linkType, ...)
  if button == MOUSE_BUTTON_INDEX_RIGHT and linkType == ITEM_LINK_TYPE and type(link) == 'string' and #link > 0 and link ~= '' then
    zo_callLater(function()
      if MasterMerchant:itemCraftPrice(link) then
        AddMenuItem("Craft Cost to Chat", function() MasterMerchant:onItemActionLinkCCLink(link) end)
      end
      AddMenuItem(GetString(MM_STATS_TO_CHAT), function() MasterMerchant:onItemActionLinkStatsLink(link) end)
      AddMenuItem(GetString(MM_POPUP_ITEM_DATA), function() MasterMerchant:onItemActionPopupInfoLink(link) end,
        MENU_ADD_OPTION_LABEL)

      ShowMenu()
    end)
  end
end

--[[This function adds menu items to the popup of the item
when you are at a crafting station
]]--
function MasterMerchant.myOnTooltipMouseUp(control, button, upInside, linkFunction, scene)
  if upInside and button == MOUSE_BUTTON_INDEX_RIGHT then

    local link = linkFunction()

    if (link ~= "" and string.match(link, '|H.-:item:(.-):')) then
      ClearMenu()

      AddMenuItem("Craft Cost to Chat", function() MasterMerchant:onItemActionLinkCCLink(link) end)
      AddMenuItem(GetString(MM_STATS_TO_CHAT), function() MasterMerchant:onItemActionLinkStatsLink(link) end)
      AddMenuItem(GetString(SI_ITEM_ACTION_LINK_TO_CHAT),
        function() ZO_LinkHandler_InsertLink(zo_strformat(SI_TOOLTIP_ITEM_NAME, link)) end)

      ShowMenu(scene)
    end
  end
end

function MasterMerchant.myProvisionerOnTooltipMouseUp(control, button, upInside)
  MasterMerchant.myOnTooltipMouseUp(control, button, upInside,
    function()
      local recipeListIndex, recipeIndex = PROVISIONER:GetSelectedRecipeListIndex(), PROVISIONER:GetSelectedRecipeIndex()
      return ZO_LinkHandler_CreateChatLink(GetRecipeResultItemLink, recipeListIndex, recipeIndex)
    end,
    PROVISIONER
  )
end
PROVISIONER.resultTooltip:SetHandler("OnMouseUp", MasterMerchant.myProvisionerOnTooltipMouseUp)
PROVISIONER.resultTooltip:GetNamedChild("Icon"):SetHandler("OnMouseUp", MasterMerchant.myProvisionerOnTooltipMouseUp)

function MasterMerchant.myAlchemyOnTooltipMouseUp(control, button, upInside)
  MasterMerchant.myOnTooltipMouseUp(control, button, upInside,
    function()
      return ZO_LinkHandler_CreateChatLink(GetAlchemyResultingItemLink, ALCHEMY:GetAllCraftingBagAndSlots())
    end,
    ALCHEMY
  )
end
ALCHEMY.tooltip:SetHandler("OnMouseUp", MasterMerchant.myAlchemyOnTooltipMouseUp)
ALCHEMY.tooltip:GetNamedChild("Icon"):SetHandler("OnMouseUp", MasterMerchant.myAlchemyOnTooltipMouseUp)

function MasterMerchant.mySmithingOnTooltipMouseUp(control, button, upInside)
  MasterMerchant.myOnTooltipMouseUp(control, button, upInside,
    function()
      return ZO_LinkHandler_CreateChatLink(GetSmithingPatternResultLink,
        SMITHING.creationPanel:GetSelectedPatternIndex(), SMITHING.creationPanel:GetSelectedMaterialIndex(),
        SMITHING.creationPanel:GetSelectedMaterialQuantity(), SMITHING.creationPanel:GetSelectedItemStyleId(),
        SMITHING.creationPanel:GetSelectedTraitIndex())
    end,
    SMITHING.creationPanel
  )
end
SMITHING.creationPanel.resultTooltip:SetHandler("OnMouseUp", MasterMerchant.mySmithingOnTooltipMouseUp)
SMITHING.creationPanel.resultTooltip:GetNamedChild("Icon"):SetHandler("OnMouseUp",
  MasterMerchant.mySmithingOnTooltipMouseUp)

function MasterMerchant.myEnchantingOnTooltipMouseUp(control, button, upInside)
  MasterMerchant.myOnTooltipMouseUp(control, button, upInside,
    function()
      return ZO_LinkHandler_CreateChatLink(GetEnchantingResultingItemLink, ENCHANTING:GetAllCraftingBagAndSlots())
    end,
    ENCHANTING
  )
end
ENCHANTING.resultTooltip:SetHandler("OnMouseUp", MasterMerchant.myEnchantingOnTooltipMouseUp)
ENCHANTING.resultTooltip:GetNamedChild("Icon"):SetHandler("OnMouseUp", MasterMerchant.myEnchantingOnTooltipMouseUp)

function MasterMerchant:my_NameHandler_OnLinkMouseUp(player, button, control)
  if (type(player) == 'string' and #player > 0) then
    if (button == 2 and player ~= '') then
      ClearMenu()
      AddMenuItem(GetString(SI_SOCIAL_LIST_SEND_MESSAGE),
        function() StartChatInput(nil, CHAT_CHANNEL_WHISPER, player) end)
      AddMenuItem(GetString(SI_SOCIAL_MENU_SEND_MAIL), function() MAIL_SEND:ComposeMailTo(player) end)
      ShowMenu(control)
    end
  end
end

function MasterMerchant.PostPendingItem(self)
  MasterMerchant:dm("Debug", "PostPendingItem")
  if self.pendingItemSlot and self.pendingSaleIsValid then
    local itemLink                                                     = GetItemLink(BAG_BACKPACK, self.pendingItemSlot)
    local _, stackCount, _                                             = GetItemInfo(BAG_BACKPACK, self.pendingItemSlot)

    local theIID                                                       = GetItemLinkItemId(itemLink)
    local itemIndex                                                    = MasterMerchant.makeIndexFromLink(itemLink)

    MasterMerchant.systemSavedVariables.pricingData                    = MasterMerchant.systemSavedVariables.pricingData or {}
    MasterMerchant.systemSavedVariables.pricingData[theIID]            = MasterMerchant.systemSavedVariables.pricingData[theIID] or {}
    MasterMerchant.systemSavedVariables.pricingData[theIID][itemIndex] = self.invoiceSellPrice.sellPrice / stackCount

    if MasterMerchant.systemSavedVariables.displayListingMessage then
      local selectedGuildId = GetSelectedTradingHouseGuildId()
      MasterMerchant:dm("Info", string.format(MasterMerchant.concat(GetString(MM_APP_MESSAGE_NAME), GetString(MM_LISTING_ALERT)),
          zo_strformat('<<t:1>>', itemLink), stackCount, self.invoiceSellPrice.sellPrice,
          GetGuildName(selectedGuildId)))
    end
  end
end

-- End Copyright (c) 2014 Matthew Miller (Mattmillus)



MasterMerchant.CustomDealCalc                 = {
  ['@Causa'] = function(setPrice, salesCount, purchasePrice, stackCount)
    local deal   = -1
    local margin = 0
    local profit = -1
    if (setPrice) then
      local unitPrice = purchasePrice / stackCount
      profit          = (setPrice - unitPrice) * stackCount
      margin          = tonumber(string.format('%.2f', (((setPrice * .92) - unitPrice) / unitPrice) * 100))

      if (margin >= 100) then
        deal = 5
      elseif (margin >= 75) then
        deal = 4
      elseif (margin >= 50) then
        deal = 3
      elseif (margin >= 25) then
        deal = 2
      elseif (margin >= 0) then
        deal = 1
      else
        deal = 0
      end
    else
      -- No sales seen
      deal   = -2
      margin = nil
    end
    return deal, margin, profit
  end
}

MasterMerchant.CustomDealCalc['@freakyfreak'] = MasterMerchant.CustomDealCalc['@Causa']

function MasterMerchant:myZO_InventorySlot_ShowContextMenu(inventorySlot)
  local st = ZO_InventorySlot_GetType(inventorySlot)
  link     = nil
  if st == SLOT_TYPE_ITEM or st == SLOT_TYPE_EQUIPMENT or st == SLOT_TYPE_BANK_ITEM or st == SLOT_TYPE_GUILD_BANK_ITEM or
    st == SLOT_TYPE_TRADING_HOUSE_POST_ITEM or st == SLOT_TYPE_REPAIR or st == SLOT_TYPE_CRAFTING_COMPONENT or st == SLOT_TYPE_PENDING_CRAFTING_COMPONENT or
    st == SLOT_TYPE_PENDING_CRAFTING_COMPONENT or st == SLOT_TYPE_PENDING_CRAFTING_COMPONENT or st == SLOT_TYPE_CRAFT_BAG_ITEM then
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    link             = GetItemLink(bag, index)
  end
  if st == SLOT_TYPE_TRADING_HOUSE_ITEM_RESULT then
    link = GetTradingHouseSearchResultItemLink(ZO_Inventory_GetSlotIndex(inventorySlot))
  end
  if st == SLOT_TYPE_TRADING_HOUSE_ITEM_LISTING then
    link = GetTradingHouseListingItemLink(ZO_Inventory_GetSlotIndex(inventorySlot), linkStyle)
  end
  if (link and string.match(link, '|H.-:item:(.-):')) then
    zo_callLater(function()
      if MasterMerchant:itemCraftPrice(link) then
        AddMenuItem("Craft Cost to Chat", function() self:onItemActionLinkCCLink(link) end, MENU_ADD_OPTION_LABEL)
      end
      AddMenuItem(GetString(MM_POPUP_ITEM_DATA), function() self:onItemActionPopupInfoLink(link) end,
        MENU_ADD_OPTION_LABEL)
      AddMenuItem(GetString(MM_STATS_TO_CHAT), function() self:onItemActionLinkStatsLink(link) end,
        MENU_ADD_OPTION_LABEL)
      ShowMenu(self)
    end, 50)
  end
end

-- Calculate some stats based on the player's sales
-- and return them as a table.
function MasterMerchant:SalesStats(statsDays)
  -- Initialize some values as we'll be using accumulation in the loop
  -- SK_STATS_TOTAL is a key for the overall stats as a guild is unlikely
  -- to be named that, except maybe just to mess with me :D
  local itemsSold         = { ['SK_STATS_TOTAL'] = 0 }
  local goldMade          = { ['SK_STATS_TOTAL'] = 0 }
  local largestSingle     = { ['SK_STATS_TOTAL'] = { 0, nil } }
  local oldestTime        = 0
  local newestTime        = 0
  local overallOldestTime = 0
  local kioskSales        = { ['SK_STATS_TOTAL'] = 0 }

  -- Set up the guild chooser, with the all guilds/overall option first
  --(other guilds will be added below)
  local guildDropdown     = ZO_ComboBox_ObjectFromContainer(MasterMerchantStatsGuildChooser)
  guildDropdown:ClearItems()
  local allGuilds = guildDropdown:CreateItemEntry(GetString(SK_STATS_ALL_GUILDS),
    function() self:UpdateStatsWindow('SK_STATS_TOTAL') end)
  guildDropdown:AddItem(allGuilds)

  -- 86,400 seconds in a day; this will be the epoch time statsDays ago
  -- (roughly, actual time computations are a LOT more complex but meh)
  local statsDaysEpoch = GetTimeStamp() - (86400 * statsDays)

  -- Loop through the player's sales and create the stats as appropriate
  -- (everything or everything with a timestamp after statsDaysEpoch)

  indexes              = self.SRIndex[MasterMerchant.PlayerSpecialText]
  if indexes then
    for i = 1, #indexes do
      local itemID    = indexes[i][1]
      local itemData  = indexes[i][2]
      local itemIndex = indexes[i][3]

      local theItem   = self.salesData[itemID][itemData]['sales'][itemIndex]
      if theItem.timestamp > statsDaysEpoch then
        -- Items Sold
        itemsSold['SK_STATS_TOTAL'] = itemsSold['SK_STATS_TOTAL'] + 1
        if itemsSold[theItem.guild] ~= nil then
          itemsSold[theItem.guild] = itemsSold[theItem.guild] + 1
        else
          itemsSold[theItem.guild] = 1
        end

        -- Kiosk sales
        if theItem.wasKiosk then
          kioskSales['SK_STATS_TOTAL'] = kioskSales['SK_STATS_TOTAL'] + 1
          if kioskSales[theItem.guild] ~= nil then
            kioskSales[theItem.guild] = kioskSales[theItem.guild] + 1
          else
            kioskSales[theItem.guild] = 1
          end
        end

        -- Gold made
        goldMade['SK_STATS_TOTAL'] = goldMade['SK_STATS_TOTAL'] + theItem.price
        if goldMade[theItem.guild] ~= nil then
          goldMade[theItem.guild] = goldMade[theItem.guild] + theItem.price
        else
          goldMade[theItem.guild] = theItem.price
        end

        -- Check to see if we need to update the newest or oldest timestamp we've seen
        if oldestTime == 0 or theItem.timestamp < oldestTime then oldestTime = theItem.timestamp end
        if newestTime == 0 or theItem.timestamp > newestTime then newestTime = theItem.timestamp end

        -- Largest single sale
        if theItem.price > largestSingle['SK_STATS_TOTAL'][1] then largestSingle['SK_STATS_TOTAL'] = { theItem.price, theItem.itemLink } end
        if largestSingle[theItem.guild] == nil or theItem.price > largestSingle[theItem.guild][1] then
          largestSingle[theItem.guild] = { theItem.price, theItem.itemLink }
        end
      end
      -- Check to see if we need to update the overall oldest time (used to set slider range)
      if overallOldestTime == 0 or theItem.timestamp < overallOldestTime then overallOldestTime = theItem.timestamp end
    end
  end
  -- Newest timestamp seen minus oldest timestamp seen is the number of seconds between
  -- them; divided by 86,400 it's the number of days (or at least close enough for this)
  local timeWindow = newestTime - oldestTime
  local dayWindow  = 1
  if timeWindow > 86400 then dayWindow = math.floor(timeWindow / 86400) + 1 end

  local overallTimeWindow = GetTimeStamp() - overallOldestTime
  local overallDayWindow  = 1
  if overallTimeWindow > 86400 then overallDayWindow = math.floor(overallTimeWindow / 86400) + 1 end

  local goldPerDay      = {}
  local kioskPercentage = {}
  local showFullPrice   = MasterMerchant.systemSavedVariables.showFullPrice

  -- Here we'll tweak stats as needed as well as add guilds to the guild chooser
  for theGuildName, guildItemsSold in pairs(itemsSold) do
    goldPerDay[theGuildName] = math.floor(goldMade[theGuildName] / dayWindow)
    local kioskSalesTemp     = 0
    if kioskSales[theGuildName] ~= nil then kioskSalesTemp = kioskSales[theGuildName] end
    if guildItemsSold == 0 then
      kioskPercentage[theGuildName] = 0
    else
      kioskPercentage[theGuildName] = math.floor((kioskSalesTemp / guildItemsSold) * 100)
    end

    if theGuildName ~= 'SK_STATS_TOTAL' then
      local guildEntry = guildDropdown:CreateItemEntry(theGuildName,
        function() self:UpdateStatsWindow(theGuildName) end)
      guildDropdown:AddItem(guildEntry)
    end

    -- If they have the option set to show prices post-cut, calculate that here
    if not showFullPrice then
      local cutMult                  = 1 - (GetTradingHouseCutPercentage() / 100)
      goldMade[theGuildName]         = math.floor(goldMade[theGuildName] * cutMult + 0.5)
      goldPerDay[theGuildName]       = math.floor(goldPerDay[theGuildName] * cutMult + 0.5)
      largestSingle[theGuildName][1] = math.floor(largestSingle[theGuildName][1] * cutMult + 0.5)
    end
  end

  -- Return the statistical data in a convenient table
  return { numSold      = itemsSold,
           numDays      = dayWindow,
           totalDays    = overallDayWindow,
           totalGold    = goldMade,
           avgGold      = goldPerDay,
           biggestSale  = largestSingle,
           kioskPercent = kioskPercentage, }
end

-- Table where the guild roster columns shall be placed
MasterMerchant.guild_columns = {}
MasterMerchant.UI_GuildTime  = nil

-- LibAddon init code
function MasterMerchant:LibAddonInit()
  -- configure font choices
  MasterMerchant:SetFontListChoices()
  MasterMerchant:dm("Debug", "LibAddonInit")
  local panelData = {
    type                = 'panel',
    name                = 'Master Merchant',
    displayName         = GetString(MM_APP_NAME),
    author              = GetString(MM_APP_AUTHOR),
    version             = self.version,
    website             = "https://www.esoui.com/downloads/fileinfo.php?id=2753",
    feedback            = "https://www.esoui.com/downloads/fileinfo.php?id=2753",
    donation            = "https://sharlikran.github.io/",
    registerForRefresh  = true,
    registerForDefaults = true,
  }
  LAM:RegisterAddonPanel('MasterMerchantOptions', panelData)

  local optionsData = {
    [1]  = {
      type    = "header",
      name    = GetString(MASTER_MERCHANT_WINDOW_NAME),
      width   = "full",
      helpUrl = "https://esouimods.github.io/3-master_merchant.html#MastermerchantWindowOptions",
    },
    -- Open main window with mailbox scenes
    [2]  = {
      type    = 'checkbox',
      name    = GetString(SK_OPEN_MAIL_NAME),
      tooltip = GetString(SK_OPEN_MAIL_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.openWithMail end,
      setFunc = function(value)
        MasterMerchant.systemSavedVariables.openWithMail = value
        local theFragment                                = ((MasterMerchant.systemSavedVariables.viewSize == ITEMS) and self.uiFragment) or ((MasterMerchant.systemSavedVariables.viewSize == GUILDS) and self.guildUiFragment) or self.listingUiFragment
        if value then
          -- Register for the mail scenes
          MAIL_INBOX_SCENE:AddFragment(theFragment)
          MAIL_SEND_SCENE:AddFragment(theFragment)
        else
          -- Unregister for the mail scenes
          MAIL_INBOX_SCENE:RemoveFragment(theFragment)
          MAIL_SEND_SCENE:RemoveFragment(theFragment)
        end
      end,
      default = MasterMerchant.systemDefault.openWithMail,
    },
    -- Open main window with trading house scene
    [3]  = {
      type    = 'checkbox',
      name    = GetString(SK_OPEN_STORE_NAME),
      tooltip = GetString(SK_OPEN_STORE_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.openWithStore end,
      setFunc = function(value)
        MasterMerchant.systemSavedVariables.openWithStore = value
        local theFragment                                 = ((MasterMerchant.systemSavedVariables.viewSize == ITEMS) and self.uiFragment) or ((MasterMerchant.systemSavedVariables.viewSize == GUILDS) and self.guildUiFragment) or self.listingUiFragment
        if value then
          -- Register for the store scene
          TRADING_HOUSE_SCENE:AddFragment(theFragment)
        else
          -- Unregister for the store scene
          TRADING_HOUSE_SCENE:RemoveFragment(theFragment)
        end
      end,
      default = MasterMerchant.systemDefault.openWithStore,
    },
    -- Show full sale price or post-tax price
    [4]  = {
      type    = 'checkbox',
      name    = GetString(SK_FULL_SALE_NAME),
      tooltip = GetString(SK_FULL_SALE_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.showFullPrice end,
      setFunc = function(value)
        MasterMerchant.systemSavedVariables.showFullPrice = value
        MasterMerchant.listIsDirty[ITEMS]                 = true
        MasterMerchant.listIsDirty[GUILDS]                = true
        MasterMerchant.listIsDirty[LISTINGS]              = true
      end,
      default = MasterMerchant.systemDefault.showFullPrice,
    },
    -- Font to use
    [5]  = {
      type    = 'dropdown',
      name    = GetString(SK_WINDOW_FONT_NAME),
      tooltip = GetString(SK_WINDOW_FONT_TIP),
      choices = MasterMerchant.fontListChoices,
      getFunc = function() return MasterMerchant.systemSavedVariables.windowFont end,
      setFunc = function(value)
        MasterMerchant.systemSavedVariables.windowFont = value
        self:UpdateFonts()
        if MasterMerchant.systemSavedVariables.viewSize == ITEMS then self.scrollList:RefreshVisible()
        elseif MasterMerchant.systemSavedVariables.viewSize == GUILDS then self.guildScrollList:RefreshVisible()
        else self.listingScrollList:RefreshVisible() end
      end,
      default = MasterMerchant.systemDefault.windowFont,
    },
    -- Sound and Alert options
    [6]  = {
      type     = 'submenu',
      name     = GetString(SK_ALERT_OPTIONS_NAME),
      tooltip  = GetString(SK_ALERT_OPTIONS_TIP),
      helpUrl  = "https://esouimods.github.io/3-master_merchant.html#AlertOptions",
      controls = {
        -- On-Screen Alerts
        [1] = {
          type    = 'checkbox',
          name    = GetString(SK_ALERT_ANNOUNCE_NAME),
          tooltip = GetString(SK_ALERT_ANNOUNCE_TIP),
          getFunc = function() return MasterMerchant.systemSavedVariables.showAnnounceAlerts end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.showAnnounceAlerts = value end,
          default = MasterMerchant.systemDefault.showAnnounceAlerts,
        },
        [2] = {
          type    = 'checkbox',
          name    = GetString(SK_ALERT_CYRODIIL_NAME),
          tooltip = GetString(SK_ALERT_CYRODIIL_TIP),
          getFunc = function() return MasterMerchant.systemSavedVariables.showCyroAlerts end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.showCyroAlerts = value end,
          default = MasterMerchant.systemDefault.showCyroAlerts,
        },
        -- Chat Alerts
        [3] = {
          type    = 'checkbox',
          name    = GetString(SK_ALERT_CHAT_NAME),
          tooltip = GetString(SK_ALERT_CHAT_TIP),
          getFunc = function() return MasterMerchant.systemSavedVariables.showChatAlerts end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.showChatAlerts = value end,
          default = MasterMerchant.systemDefault.showChatAlerts,
        },
        -- Sound to use for alerts
        [4] = {
          type    = 'dropdown',
          name    = GetString(SK_ALERT_TYPE_NAME),
          tooltip = GetString(SK_ALERT_TYPE_TIP),
          choices = self:SoundKeys(),
          getFunc = function() return self:SearchSounds(MasterMerchant.systemSavedVariables.alertSoundName) end,
          setFunc = function(value)
            MasterMerchant.systemSavedVariables.alertSoundName = self:SearchSoundNames(value)
            PlaySound(MasterMerchant.systemSavedVariables.alertSoundName)
          end,
          default = self:SearchSounds(MasterMerchant.systemDefault.alertSoundName),
        },
        -- Whether or not to show multiple alerts for multiple sales
        [5] = {
          type    = 'checkbox',
          name    = GetString(SK_MULT_ALERT_NAME),
          tooltip = GetString(SK_MULT_ALERT_TIP),
          getFunc = function() return MasterMerchant.systemSavedVariables.showMultiple end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.showMultiple = value end,
          default = MasterMerchant.systemDefault.showMultiple,
        },
        -- Offline sales report
        [6] = {
          type    = 'checkbox',
          name    = GetString(SK_OFFLINE_SALES_NAME),
          tooltip = GetString(SK_OFFLINE_SALES_TIP),
          getFunc = function() return MasterMerchant.systemSavedVariables.offlineSales end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.offlineSales = value end,
          default = MasterMerchant.systemDefault.offlineSales,
        },
        -- should we display the item listed message?
        [7] = {
          type     = 'checkbox',
          name     = GetString(MM_DISPLAY_LISTING_MESSAGE_NAME),
          tooltip  = GetString(MM_DISPLAY_LISTING_MESSAGE_TIP),
          getFunc  = function() return MasterMerchant.systemSavedVariables.displayListingMessage end,
          setFunc  = function(value) MasterMerchant.systemSavedVariables.displayListingMessage = value end,
          default  = MasterMerchant.systemDefault.displayListingMessage,
          disabled = function() return MasterMerchant.AwesomeGuildStoreDetected end,
        },
      },
    },
    -- Tip display and calculation options
    [7]  = {
      type     = 'submenu',
      name     = GetString(MM_CALC_OPTIONS_NAME),
      tooltip  = GetString(MM_CALC_OPTIONS_TIP),
      helpUrl  = "https://esouimods.github.io/3-master_merchant.html#CalculationDisplayOptions",
      controls = {
        -- On-Screen Alerts
        [1]  = {
          type    = 'slider',
          name    = GetString(MM_DAYS_FOCUS_ONE_NAME),
          tooltip = GetString(MM_DAYS_FOCUS_ONE_TIP),
          min     = 1,
          max     = 90,
          getFunc = function() return MasterMerchant.systemSavedVariables.focus1 end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.focus1 = value end,
          default = MasterMerchant.systemDefault.focus1,
        },
        [2]  = {
          type    = 'slider',
          name    = GetString(MM_DAYS_FOCUS_TWO_NAME),
          tooltip = GetString(MM_DAYS_FOCUS_TWO_TIP),
          min     = 1,
          max     = 90,
          getFunc = function() return MasterMerchant.systemSavedVariables.focus2 end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.focus2 = value end,
          default = MasterMerchant.systemDefault.focus2,
        },
        [3]  = {
          type    = 'slider',
          name    = GetString(MM_DAYS_FOCUS_THREE_NAME),
          tooltip = GetString(MM_DAYS_FOCUS_THREE_TIP),
          min     = 1,
          max     = 90,
          getFunc = function() return MasterMerchant.systemSavedVariables.focus3 end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.focus3 = value end,
          default = MasterMerchant.systemDefault.focus3,
        },
        -- default time range
        [4]  = {
          type    = 'dropdown',
          name    = GetString(MM_DEFAULT_TIME_NAME),
          tooltip = GetString(MM_DEFAULT_TIME_TIP),
          choices = { GetString(MM_RANGE_ALL), GetString(MM_RANGE_FOCUS1), GetString(MM_RANGE_FOCUS2), GetString(MM_RANGE_FOCUS3), GetString(MM_RANGE_NONE) },
          getFunc = function() return MasterMerchant.systemSavedVariables.defaultDays end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.defaultDays = value end,
          default = MasterMerchant.systemDefault.defaultDays,
        },
        -- shift time range
        [5]  = {
          type    = 'dropdown',
          name    = GetString(MM_SHIFT_TIME_NAME),
          tooltip = GetString(MM_SHIFT_TIME_TIP),
          choices = { GetString(MM_RANGE_ALL), GetString(MM_RANGE_FOCUS1), GetString(MM_RANGE_FOCUS2), GetString(MM_RANGE_FOCUS3), GetString(MM_RANGE_NONE) },
          getFunc = function() return MasterMerchant.systemSavedVariables.shiftDays end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.shiftDays = value end,
          default = MasterMerchant.systemDefault.shiftDays,
        },
        -- ctrl time range
        [6]  = {
          type    = 'dropdown',
          name    = GetString(MM_CTRL_TIME_NAME),
          tooltip = GetString(MM_CTRL_TIME_TIP),
          choices = { GetString(MM_RANGE_ALL), GetString(MM_RANGE_FOCUS1), GetString(MM_RANGE_FOCUS2), GetString(MM_RANGE_FOCUS3), GetString(MM_RANGE_NONE) },
          getFunc = function() return MasterMerchant.systemSavedVariables.ctrlDays end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.ctrlDays = value end,
          default = MasterMerchant.systemDefault.ctrlDays,
        },
        -- ctrl-shift time range
        [7]  = {
          type    = 'dropdown',
          name    = GetString(MM_CTRLSHIFT_TIME_NAME),
          tooltip = GetString(MM_CTRLSHIFT_TIME_TIP),
          choices = { GetString(MM_RANGE_ALL), GetString(MM_RANGE_FOCUS1), GetString(MM_RANGE_FOCUS2), GetString(MM_RANGE_FOCUS3), GetString(MM_RANGE_NONE) },
          getFunc = function() return MasterMerchant.systemSavedVariables.ctrlShiftDays end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.ctrlShiftDays = value end,
          default = MasterMerchant.systemDefault.ctrlShiftDays,
        },
        [8]  = {
          type    = 'slider',
          name    = GetString(MM_NO_DATA_DEAL_NAME),
          tooltip = GetString(MM_NO_DATA_DEAL_TIP),
          min     = 0,
          max     = 5,
          getFunc = function() return MasterMerchant.systemSavedVariables.noSalesInfoDeal end,
          setFunc = function(value) MasterMerchant.systemSavedVariables.noSalesInfoDeal = value end,
          default = MasterMerchant.systemDefault.noSalesInfoDeal,
        },
        -- blacklisted players and guilds
        [9]  = {
          type        = 'editbox',
          name        = GetString(MM_BLACKLIST_NAME),
          tooltip     = GetString(MM_BLACKLIST_TIP),
          getFunc     = function() return MasterMerchant.systemSavedVariables.blacklist end,
          setFunc     = function(value) MasterMerchant.systemSavedVariables.blacklist = value end,
          default     = MasterMerchant.systemDefault.blacklist,
          isMultiline = true,
          textType    = TEXT_TYPE_ALL,
          width       = "full"
        },
        -- customTimeframe
        [10] = {
          type    = 'slider',
          name    = GetString(MM_CUSTOM_TIMEFRAME_NAME),
          tooltip = GetString(MM_CUSTOM_TIMEFRAME_TIP),
          min     = 1,
          max     = 24 * 31,
          getFunc = function() return MasterMerchant.systemSavedVariables.customTimeframe end,
          setFunc = function(value)
            MasterMerchant.systemSavedVariables.customTimeframe = value
            MasterMerchant.customTimeframeText                  = MasterMerchant.systemSavedVariables.customTimeframe .. ' ' .. MasterMerchant.systemSavedVariables.customTimeframeType
            MasterMerchant:BuildRosterTimeDropdown()
            MasterMerchant:BuildGuiTimeDropdown()
          end,
          default = MasterMerchant.systemDefault.customTimeframe,
        },
        -- shift time range
        [11] = {
          type    = 'dropdown',
          name    = GetString(MM_CUSTOM_TIMEFRAME_SCALE_NAME),
          tooltip = GetString(MM_CUSTOM_TIMEFRAME_SCALE_TIP),
          choices = { GetString(MM_CUSTOM_TIMEFRAME_HOURS), GetString(MM_CUSTOM_TIMEFRAME_DAYS), GetString(MM_CUSTOM_TIMEFRAME_WEEKS), GetString(MM_CUSTOM_TIMEFRAME_GUILD_WEEKS) },
          getFunc = function() return MasterMerchant.systemSavedVariables.customTimeframeType end,
          setFunc = function(value)
            MasterMerchant.systemSavedVariables.customTimeframeType = value
            MasterMerchant.customTimeframeText                      = MasterMerchant.systemSavedVariables.customTimeframe .. ' ' .. MasterMerchant.systemSavedVariables.customTimeframeType
            MasterMerchant:BuildRosterTimeDropdown()
            MasterMerchant:BuildGuiTimeDropdown()
          end,
          default = MasterMerchant.systemDefault.customTimeframeType,
        },
      },
    },
    -- guild roster menu
    [8]  = {
      type     = 'submenu',
      name     = GetString(MM_GUILD_ROSTER_OPTIONS_NAME),
      tooltip  = GetString(MM_GUILD_ROSTER_OPTIONS_TIP),
      controls = {
        -- should we display info on guild roster?
        [1] = {
          type    = 'checkbox',
          name    = GetString(SK_ROSTER_INFO_NAME),
          tooltip = GetString(SK_ROSTER_INFO_TIP),
          getFunc = function() return MasterMerchant.systemSavedVariables.diplayGuildInfo end,
          setFunc = function(value)

            MasterMerchant.systemSavedVariables.diplayGuildInfo = value

            if self.UI_GuildTime then
              self.UI_GuildTime:SetHidden(not value)
            end

            for key, column in pairs(self.guild_columns) do
              column:IsDisabled(not value)
            end

          end,
          default = MasterMerchant.systemDefault.diplayGuildInfo,
        },
        [2] = {
          type     = 'checkbox',
          name     = GetString(MM_SALES_COLUMN_NAME),
          tooltip  = GetString(MM_SALES_COLUMN_TIP),
          getFunc  = function() return MasterMerchant.systemSavedVariables.diplaySalesInfo end,
          setFunc  = function(value)
            MasterMerchant.systemSavedVariables.diplaySalesInfo = value
            MasterMerchant.guild_columns['sold']:IsDisabled(not value)
          end,
          disabled = function() return not MasterMerchant.systemSavedVariables.diplayGuildInfo end,
          default  = MasterMerchant.systemDefault.diplaySalesInfo,
        },
        -- guild roster options
        [3] = {
          type     = 'checkbox',
          name     = GetString(MM_PURCHASES_COLUMN_NAME),
          tooltip  = GetString(MM_PURCHASES_COLUMN_TIP),
          getFunc  = function() return MasterMerchant.systemSavedVariables.diplayPurchasesInfo end,
          setFunc  = function(value)
            MasterMerchant.systemSavedVariables.diplayPurchasesInfo = value
            MasterMerchant.guild_columns['bought']:IsDisabled(not value)
          end,
          disabled = function() return not MasterMerchant.systemSavedVariables.diplayGuildInfo end,
          default  = MasterMerchant.systemDefault.diplayPurchasesInfo,
        },
        [4] = {
          type     = 'checkbox',
          name     = GetString(MM_TAXES_COLUMN_NAME),
          tooltip  = GetString(MM_TAXES_COLUMN_TIP),
          getFunc  = function() return MasterMerchant.systemSavedVariables.diplayTaxesInfo end,
          setFunc  = function(value)
            MasterMerchant.systemSavedVariables.diplayTaxesInfo = value
            MasterMerchant.guild_columns['per']:IsDisabled(not value)
          end,
          disabled = function() return not MasterMerchant.systemSavedVariables.diplayGuildInfo end,
          default  = MasterMerchant.systemDefault.diplayTaxesInfo,
        },
        [5] = {
          type     = 'checkbox',
          name     = GetString(MM_COUNT_COLUMN_NAME),
          tooltip  = GetString(MM_COUNT_COLUMN_TIP),
          getFunc  = function() return MasterMerchant.systemSavedVariables.diplayCountInfo end,
          setFunc  = function(value)
            MasterMerchant.systemSavedVariables.diplayCountInfo = value
            MasterMerchant.guild_columns['count']:IsDisabled(not value)
          end,
          disabled = function() return not MasterMerchant.systemSavedVariables.diplayGuildInfo end,
          default  = MasterMerchant.systemDefault.diplayCountInfo,
        },
      },
    },
    -- 9 -------------------------------------------
    [9]  = {
      type    = "header",
      name    = GetString(MM_DATA_MANAGEMENT_NAME),
      width   = "full",
      helpUrl = "https://esouimods.github.io/3-master_merchant.html#DataManagementOptions",
    },
    -- use size of sales history only
    [10] = {
      type    = 'checkbox',
      name    = GetString(MM_DAYS_ONLY_NAME),
      tooltip = GetString(MM_DAYS_ONLY_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.useSalesHistory end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.useSalesHistory = value end,
      default = MasterMerchant.systemDefault.useSalesHistory,
    },
    -- Size of sales history
    [11] = {
      type    = 'slider',
      name    = GetString(SK_HISTORY_DEPTH_NAME),
      tooltip = GetString(SK_HISTORY_DEPTH_TIP),
      min     = 1,
      max     = 365,
      getFunc = function() return MasterMerchant.systemSavedVariables.historyDepth end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.historyDepth = value end,
      default = MasterMerchant.systemDefault.historyDepth,
    },
    -- Min Number of Items before Purge
    [12] = {
      type     = 'slider',
      name     = GetString(MM_MIN_ITEM_COUNT_NAME),
      tooltip  = GetString(MM_MIN_ITEM_COUNT_TIP),
      min      = 0,
      max      = 100,
      getFunc  = function() return MasterMerchant.systemSavedVariables.minItemCount end,
      setFunc  = function(value) MasterMerchant.systemSavedVariables.minItemCount = value end,
      disabled = function() return MasterMerchant.systemSavedVariables.useSalesHistory end,
      default  = MasterMerchant.systemDefault.minItemCount,
    },
    -- Max number of Items
    [13] = {
      type     = 'slider',
      name     = GetString(MM_MAX_ITEM_COUNT_NAME),
      tooltip  = GetString(MM_MAX_ITEM_COUNT_TIP),
      min      = 100,
      max      = 10000,
      getFunc  = function() return MasterMerchant.systemSavedVariables.maxItemCount end,
      setFunc  = function(value) MasterMerchant.systemSavedVariables.maxItemCount = value end,
      disabled = function() return MasterMerchant.systemSavedVariables.useSalesHistory end,
      default  = MasterMerchant.systemDefault.maxItemCount,
    },
    -- Skip Indexing?
    [14] = {
      type    = 'checkbox',
      name    = GetString(MM_SKIP_INDEX_NAME),
      tooltip = GetString(MM_SKIP_INDEX_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.minimalIndexing end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.minimalIndexing = value end,
      default = MasterMerchant.systemDefault.minimalIndexing,
    },
    [15] = {
      type    = "header",
      name    = GetString(MASTER_MERCHANT_TOOLTIP_OPTIONS),
      width   = "full",
      helpUrl = "https://esouimods.github.io/3-master_merchant.html#OtherTooltipOptions",
    },
    ---------------------------------------------
    -- Whether or not to show the pricing graph in tooltips
    [16] = {
      type    = 'checkbox',
      name    = GetString(SK_SHOW_GRAPH_NAME),
      tooltip = GetString(SK_SHOW_GRAPH_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.showGraph end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.showGraph = value end,
      default = MasterMerchant.systemDefault.showGraph,
    },
    -- Whether or not to show the pricing data in tooltips
    [17] = {
      type    = 'checkbox',
      name    = GetString(SK_SHOW_PRICING_NAME),
      tooltip = GetString(SK_SHOW_PRICING_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.showPricing end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.showPricing = value end,
      default = MasterMerchant.systemDefault.showPricing,
    },
    -- Whether or not to show tooltips on the graph points
    [18] = {
      type    = 'checkbox',
      name    = GetString(MM_GRAPH_INFO_NAME),
      tooltip = GetString(MM_GRAPH_INFO_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.displaySalesDetails end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.displaySalesDetails = value end,
      default = MasterMerchant.systemDefault.displaySalesDetails,
    },
    -- Whether or not to show the crafting costs data in tooltips
    [19] = {
      type    = 'checkbox',
      name    = GetString(SK_SHOW_CRAFT_COST_NAME),
      tooltip = GetString(SK_SHOW_CRAFT_COST_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.showCraftCost end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.showCraftCost = value end,
      default = MasterMerchant.systemDefault.showCraftCost,
    },
    -- Whether or not to show the quality/level adjustment buttons
    [20] = {
      type    = 'checkbox',
      name    = GetString(MM_LEVEL_QUALITY_NAME),
      tooltip = GetString(MM_LEVEL_QUALITY_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.displayItemAnalysisButtons end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.displayItemAnalysisButtons = value end,
      default = MasterMerchant.systemDefault.displayItemAnalysisButtons,
    },
    -- should we trim outliers prices?
    [21] = {
      type    = 'checkbox',
      name    = GetString(SK_TRIM_OUTLIERS_NAME),
      tooltip = GetString(SK_TRIM_OUTLIERS_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.trimOutliers end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.trimOutliers = value end,
      default = MasterMerchant.systemDefault.trimOutliers,
    },
    -- should we trim off decimals?
    [22] = {
      type    = 'checkbox',
      name    = GetString(SK_TRIM_DECIMALS_NAME),
      tooltip = GetString(SK_TRIM_DECIMALS_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.trimDecimals end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.trimDecimals = value end,
      default = MasterMerchant.systemDefault.trimDecimals,
    },
    [23] = {
      type    = "header",
      name    = GetString(MASTER_MERCHANT_INVENTORY_OPTIONS),
      width   = "full",
      helpUrl = "https://esouimods.github.io/3-master_merchant.html#InventoryOptions",
    },
    -- should we replace inventory values?
    [24] = {
      type    = 'checkbox',
      name    = GetString(MM_REPLACE_INVENTORY_VALUES_NAME),
      tooltip = GetString(MM_REPLACE_INVENTORY_VALUES_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.replaceInventoryValues end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.replaceInventoryValues = value end,
      default = MasterMerchant.systemDefault.replaceInventoryValues,
    },
    [25] = {
      type    = "header",
      name    = GetString(GUILD_STORE_OPTIONS),
      width   = "full",
      helpUrl = "https://esouimods.github.io/3-master_merchant.html#GuildStoreOptions",
    },
    -- Should we show the stack price calculator?
    [26] = {
      type    = 'checkbox',
      name    = GetString(SK_CALC_NAME),
      tooltip = GetString(SK_CALC_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.showCalc end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.showCalc = value end,
      default = MasterMerchant.systemDefault.showCalc,
    },
    -- should we display a Min Profit Filter in AGS?
    [27] = {
      type    = 'checkbox',
      name    = GetString(MM_MIN_PROFIT_FILTER_NAME),
      tooltip = GetString(MM_MIN_PROFIT_FILTER_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.minProfitFilter end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.minProfitFilter = value end,
      default = MasterMerchant.systemDefault.minProfitFilter,
    },
    -- should we display profit instead of margin?
    [28] = {
      type    = 'checkbox',
      name    = GetString(MM_SAUCY_NAME),
      tooltip = GetString(MM_SAUCY_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.saucy end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.saucy = value end,
      default = MasterMerchant.systemDefault.saucy,
    },
    [29] = {
      type    = "header",
      name    = GetString(GUILD_MASTER_OPTIONS),
      width   = "full",
      helpUrl = "https://esouimods.github.io/3-master_merchant.html#ExportSalesReport",
    },
    -- should we add taxes to the export?
    [30] = {
      type    = 'checkbox',
      name    = GetString(MM_SHOW_AMOUNT_TAXES_NAME),
      tooltip = GetString(MM_SHOW_AMOUNT_TAXES_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.showAmountTaxes end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.showAmountTaxes = value end,
      default = MasterMerchant.systemDefault.showAmountTaxes,
    },
    [31] = {
      type    = "header",
      name    = GetString(MASTER_MERCHANT_DEBUG_OPTIONS),
      width   = "full",
      helpUrl = "https://esouimods.github.io/3-master_merchant.html#DebugOptions",
    },
    [32] = {
      type    = 'checkbox',
      name    = GetString(MM_DEBUG_LOGGER_NAME),
      tooltip = GetString(MM_DEBUG_LOGGER_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.useLibDebugLogger end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.useLibDebugLogger = value end,
      default = MasterMerchant.systemDefault.useLibDebugLogger,
    },
    [33] = {
      type    = 'checkbox',
      name    = GetString(MM_GUILD_ITEM_SUMMARY_NAME),
      tooltip = GetString(MM_GUILD_ITEM_SUMMARY_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.showGuildInitSummary end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.showGuildInitSummary = value end,
      default = MasterMerchant.systemDefault.showGuildInitSummary,
    },
    [34] = {
      type    = 'checkbox',
      name    = GetString(MM_INDEXING_NAME),
      tooltip = GetString(MM_INDEXING_TIP),
      getFunc = function() return MasterMerchant.systemSavedVariables.showIndexingSummary end,
      setFunc = function(value) MasterMerchant.systemSavedVariables.showIndexingSummary = value end,
      default = MasterMerchant.systemDefault.showIndexingSummary,
    },
  }

  -- And make the options panel
  LAM:RegisterOptionControls('MasterMerchantOptions', optionsData)
end

function MasterMerchant:PurgeDups()

  if not self.isScanning then
    local LEQ = LibExecutionQueue:new()
    self:setScanning(true)

    local start      = GetTimeStamp()
    local eventArray = { }
    local count      = 0
    local newSales

    --spin thru history and remove dups
    for itemNumber, itemNumberData in pairs(self.salesData) do
      for itemIndex, itemData in pairs(itemNumberData) do
        if itemData['sales'] then
          local dup
          newSales = {}
          for _, checking in pairs(itemData['sales']) do
            local validLink = MasterMerchant:IsValidItemLink(checking.itemLink)
            dup             = false
            if checking.id == nil then
              --[[
              if MasterMerchant.systemSavedVariables.useLibDebugLogger then
                MasterMerchant:dm("Debug", 'Nil ID found')
              end
              ]]--
              dup = true
            end
            if eventArray[checking.id] then
              --[[
              if MasterMerchant.systemSavedVariables.useLibDebugLogger then
                MasterMerchant:dm("Debug", 'Dupe found: ' .. checking.id .. ': ' .. checking.itemLink)
                MasterMerchant:Expected(checking.id)
              end
              ]]--
              dup = true
            end
            if not validLink then dup = true end
            if dup then
              -- Remove it by not putting it in the new list, but keep a count
              count = count + 1
            else
              table.insert(newSales, checking)
              eventArray[checking.id] = true
            end
          end
          itemData['sales'] = newSales
        end
      end
    end
    MasterMerchant:dm("Verbose", MasterMerchant:NonContiguousNonNilCount(eventArray, currentTask))
    eventArray = {} -- clear array

    MasterMerchant:dm("Info", string.format(GetString(MM_DUP_PURGE), GetTimeStamp() - start, count))
    MasterMerchant:dm("Info", GetString(MM_REINDEXING_EVERYTHING))
    if count > 0 then
      --rebuild everything
      self.SRIndex        = {}

      self.guildPurchases = nil
      self.guildSales     = nil
      self.guildItems     = nil
      self.myItems        = {}
      LEQ:Add(function() self:InitItemHistory() end, 'InitItemHistory')
      LEQ:Add(function() self:indexHistoryTables() end, 'indexHistoryTables')
    end
    LEQ:Add(function()
      self:setScanning(false);
      MasterMerchant:dm("Info", GetString(MM_REINDEXING_COMPLETE))
    end, 'LetScanningContinue')
    LEQ:Start()
  end
end

function MasterMerchant:checkForDoubles()

  local dataList = {
    [0]  = MM00Data.savedVariables.SalesData,
    [1]  = MM01Data.savedVariables.SalesData,
    [2]  = MM02Data.savedVariables.SalesData,
    [3]  = MM03Data.savedVariables.SalesData,
    [4]  = MM04Data.savedVariables.SalesData,
    [5]  = MM05Data.savedVariables.SalesData,
    [6]  = MM06Data.savedVariables.SalesData,
    [7]  = MM07Data.savedVariables.SalesData,
    [8]  = MM08Data.savedVariables.SalesData,
    [9]  = MM09Data.savedVariables.SalesData,
    [10] = MM10Data.savedVariables.SalesData,
    [11] = MM11Data.savedVariables.SalesData,
    [12] = MM12Data.savedVariables.SalesData,
    [13] = MM13Data.savedVariables.SalesData,
    [14] = MM14Data.savedVariables.SalesData,
    [15] = MM15Data.savedVariables.SalesData
  }

  for i = 0, 14, 1 do
    for itemid, versionlist in pairs(dataList[i]) do
      for versionid, _ in pairs(versionlist) do
        for j = i + 1, 15, 1 do
          if dataList[j][itemid] and dataList[j][itemid][versionid] then
            MasterMerchant:dm("Info", itemid .. '/' .. versionid .. ' is in ' .. i .. ' and ' .. j .. '.')
          end
        end
      end
    end
  end
end

function MasterMerchant:SpecialMessage(force)
  if GetDisplayName() == '@sylviermoone' or (GetDisplayName() == '@Philgo68' and force) then
    local daysCount = math.floor(((GetTimeStamp() - (1460980800 + 38 * 86400 + 19 * 3600)) / 86400) * 4) / 4
    if (daysCount > (MasterMerchant.systemSavedVariables.daysPast or 0)) or force then
      MasterMerchant.systemSavedVariables.daysPast = daysCount

      local rem                                    = daysCount - math.floor(daysCount)
      daysCount                                    = math.floor(daysCount)

      if rem == 0 then
        MasterMerchant.CenterScreenAnnounce_AddMessage('MasterMerchantAlert', CSA_EVENT_SMALL_TEXT,
          "Objective_Complete",
          string.format("Keep it up!!  You've made it %s complete days!!", daysCount))
      end

      if rem == 0.25 then
        MasterMerchant.CenterScreenAnnounce_AddMessage('MasterMerchantAlert', CSA_EVENT_SMALL_TEXT,
          "Objective_Complete",
          string.format("Working your way through day %s...", daysCount + 1))
      end

      if rem == 0.5 then
        MasterMerchant.CenterScreenAnnounce_AddMessage('MasterMerchantAlert', CSA_EVENT_SMALL_TEXT,
          "Objective_Complete",
          string.format("Day %s half way done!", daysCount + 1))
      end

      if rem == 0.75 then
        MasterMerchant.CenterScreenAnnounce_AddMessage('MasterMerchantAlert', CSA_EVENT_SMALL_TEXT,
          "Objective_Complete",
          string.format("Just a little more to go in day %s...", daysCount + 1))
      end

    end
  end
end

function MasterMerchant:ExportLastWeek()
  local export    = ZO_SavedVars:NewAccountWide('ShopkeeperSavedVars', 1, "EXPORT", {}, nil)

  local dataSet   = MasterMerchant.guildPurchases
  local dataSet   = MasterMerchant.guildSales

  local numGuilds = GetNumGuilds()
  local guildNum  = self.guildNumber
  if guildNum > numGuilds then
    MasterMerchant:dm("Info", GetString(MM_EXPORTING_INVALID))
    return
  end

  local guildID   = GetGuildId(guildNum)
  local guildName = GetGuildName(guildID)

  MasterMerchant:dm("Info", string.format(GetString(MM_EXPORTING), guildName))
  export[guildName]     = {}
  local list            = export[guildName]

  local numGuildMembers = GetNumGuildMembers(guildID)
  for guildMemberIndex = 1, numGuildMembers do
    local displayName, note, rankIndex, status, secsSinceLogoff = GetGuildMemberInfo(guildID, guildMemberIndex)
    local online                                                = (status ~= PLAYER_STATUS_OFFLINE)
    local rankId                                                = GetGuildRankId(guildID, rankIndex)

    local amountBought                                          = 0
    if MasterMerchant.guildPurchases and
      MasterMerchant.guildPurchases[guildName] and
      MasterMerchant.guildPurchases[guildName].sellers and
      MasterMerchant.guildPurchases[guildName].sellers[displayName] and
      MasterMerchant.guildPurchases[guildName].sellers[displayName].sales then
      amountBought = MasterMerchant.guildPurchases[guildName].sellers[displayName].sales[MasterMerchant.systemSavedVariables.rankIndexRoster] or 0
    end

    local amountSold = 0
    if MasterMerchant.guildSales and
      MasterMerchant.guildSales[guildName] and
      MasterMerchant.guildSales[guildName].sellers and
      MasterMerchant.guildSales[guildName].sellers[displayName] and
      MasterMerchant.guildSales[guildName].sellers[displayName].sales then
      amountSold = MasterMerchant.guildSales[guildName].sellers[displayName].sales[MasterMerchant.systemSavedVariables.rankIndexRoster] or 0
    end

    -- sample [2] = "@Name&Sales&Purchases&Rank"
    local amountTaxes = 0
    amountTaxes       = math.floor(amountSold * 0.035)
    if MasterMerchant.systemSavedVariables.showAmountTaxes then
      table.insert(list,
        displayName .. "&" .. amountSold .. "&" .. amountBought .. "&" .. amountTaxes .. "&" .. rankIndex)
    else
      table.insert(list, displayName .. "&" .. amountSold .. "&" .. amountBought .. "&" .. rankIndex)
    end
  end

end

function MasterMerchant:ExportSalesData()
  local export    = ZO_SavedVars:NewAccountWide('ShopkeeperSavedVars', 1, "SALES", {}, nil)

  local numGuilds = GetNumGuilds()
  local guildNum  = self.guildNumber
  local guildID
  local guildName

  if guildNum > numGuilds then
    guildName = 'ALL'
  else
    guildID   = GetGuildId(guildNum)
    guildName = GetGuildName(guildID)
  end
  export[guildName] = {}
  local list        = export[guildName]

  local epochBack   = GetTimeStamp() - (86400 * 10)
  for k, v in pairs(self.salesData) do
    for j, dataList in pairs(v) do
      if dataList['sales'] then
        for _, sale in pairs(dataList['sales']) do
          if sale.timestamp >= epochBack and (guildName == 'ALL' or guildName == sale.guild) then
            local itemDesc = dataList['itemDesc']
            itemDesc       = itemDesc:gsub("%^.*$", "", 1)
            itemDesc       = string.gsub(" " .. itemDesc, "%s%l", string.upper):sub(2)

            table.insert(list,
              sale.seller .. "&" ..
                sale.buyer .. "&" ..
                sale.itemLink .. "&" ..
                sale.quant .. "&" ..
                sale.timestamp .. "&" ..
                tostring(sale.wasKiosk) .. "&" ..
                sale.price .. "&" ..
                sale.guild .. "&" ..
                itemDesc .. "&" ..
                dataList['itemAdderText']
            )

          end
        end
      end
    end
  end

end

-- We only have to refresh scroll list data if the window is actually visible; methods
-- to show these windows refresh data before display
function MasterMerchant:RefreshMasterMerchantWindow()
  local currentView = MasterMerchant.systemSavedVariables.viewSize
  if currentView == ITEMS then
    if not MasterMerchantWindow:IsHidden() and not self.isScanning then
      self.scrollList:RefreshData()
    else
      self.listIsDirty[ITEMS] = true
    end
    self.listIsDirty[GUILDS]   = true
    self.listIsDirty[LISTINGS] = true
  elseif currentView == GUILDS then
    if not MasterMerchantGuildWindow:IsHidden() and not self.isScanning then
      self.guildScrollList:RefreshData()
    else
      self.listIsDirty[GUILDS] = true
    end
    self.listIsDirty[ITEMS]    = true
    self.listIsDirty[LISTINGS] = true
  else
    if not MasterMerchantListingWindow:IsHidden() and not self.isScanning then
      self.listingScrollList:RefreshData()
    else
      self.listIsDirty[LISTINGS] = true
    end
    self.listIsDirty[ITEMS]  = true
    self.listIsDirty[GUILDS] = true
  end
end

-- don't refresh just set whether or not the list needs updated.
function MasterMerchant:SetMasterMerchantWindowDirty()
  self.listIsDirty[ITEMS]    = true
  self.listIsDirty[GUILDS]   = true
  self.listIsDirty[LISTINGS] = true
end

-- Called after store scans complete, re-creates indexes if need be,
-- and updates the slider range. Once this is done it updates the
-- displayed table, sending a message to chat if the scan was initiated
-- via the 'refresh' or 'reset' buttons.

function MasterMerchant:PostScanParallel(guildName, doAlert)
  -- If the index is blank (first scan after login or after reset),
  -- build the indexes now that we have a scanned table.
  -- self:setScanningParallel(false, guildName)

  -- If there's anything in the alert queue, handle it.
  if #MasterMerchant.alertQueue[guildName] > 0 then
    -- Play an alert chime once if there are any alerts in the queue
    if MasterMerchant.systemSavedVariables.showChatAlerts or MasterMerchant.systemSavedVariables.showAnnounceAlerts then
      PlaySound(MasterMerchant.systemSavedVariables.alertSoundName)
    end

    local numSold   = 0
    local totalGold = 0
    local numAlerts = #MasterMerchant.alertQueue[guildName]
    local lastEvent = {}
    for i = 1, numAlerts do
      local theEvent  = table.remove(MasterMerchant.alertQueue[guildName], 1)
      numSold         = numSold + 1
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

      -- Adjust the price if they want the post-cut prices instead
      local dispPrice = theEvent.price
      if not MasterMerchant.systemSavedVariables.showFullPrice then
        local cutPrice = dispPrice * (1 - (GetTradingHouseCutPercentage() / 100))
        dispPrice      = math.floor(cutPrice + 0.5)
      end
      totalGold = totalGold + dispPrice

      -- If they want multiple alerts, we'll alert on each loop iteration
      -- or if there's only one.
      if MasterMerchant.systemSavedVariables.showMultiple or numAlerts == 1 then
        -- Insert thousands separators for the price
        local stringPrice = self.LocalizedNumber(dispPrice)

        -- On-screen alert; map index 37 is Cyrodiil
        if MasterMerchant.systemSavedVariables.showAnnounceAlerts and
          (MasterMerchant.systemSavedVariables.showCyroAlerts or GetCurrentMapZoneIndex ~= 37) then

          -- We'll add a numerical suffix to avoid queueing two identical messages in a row
          -- because the alerts will 'miss' if we do
          local textTime    = self.TextTimeSince(theEvent.timestamp, true)
          local alertSuffix = ''
          if lastEvent[1] ~= nil and theEvent.itemLink == lastEvent[1].itemLink and textTime == lastEvent[2] then
            lastEvent[3] = lastEvent[3] + 1
            alertSuffix  = ' (' .. lastEvent[3] .. ')'
          else
            lastEvent[1] = theEvent
            lastEvent[2] = textTime
            lastEvent[3] = 1
          end
          -- German word order differs so argument order also needs to be changed
          -- Also due to plurality differences in German, need to differentiate
          -- single item sold vs. multiple of an item sold.
          if MasterMerchant.effective_lang == 'de' then
            if theEvent.quant > 1 then
              MasterMerchant.CenterScreenAnnounce_AddMessage('MasterMerchantAlert', CSA_EVENT_SMALL_TEXT, SOUNDS.NONE,
                string.format(GetString(SK_SALES_ALERT_COLOR), theEvent.quant,
                  zo_strformat('<<t:1>>', theEvent.itemLink),
                  stringPrice, theEvent.guild, textTime) .. alertSuffix)
            else
              MasterMerchant.CenterScreenAnnounce_AddMessage('MasterMerchantAlert', CSA_EVENT_SMALL_TEXT, SOUNDS.NONE,
                string.format(GetString(SK_SALES_ALERT_SINGLE_COLOR), zo_strformat('<<t:1>>', theEvent.itemLink),
                  stringPrice, theEvent.guild, textTime) .. alertSuffix)
            end
          else
            MasterMerchant.CenterScreenAnnounce_AddMessage('MasterMerchantAlert', CSA_EVENT_SMALL_TEXT, SOUNDS.NONE,
              string.format(GetString(SK_SALES_ALERT_COLOR), zo_strformat('<<t:1>>', theEvent.itemLink),
                theEvent.quant, stringPrice, theEvent.guild, textTime) .. alertSuffix)
          end
        end

        -- Chat alert
        if MasterMerchant.systemSavedVariables.showChatAlerts then
          if MasterMerchant.effective_lang == 'de' then
            if theEvent.quant > 1 then
              MasterMerchant:dm("Info", string.format(MasterMerchant.concat(GetString(MM_APP_MESSAGE_NAME), GetString(SK_SALES_ALERT)), theEvent.quant, zo_strformat('<<t:1>>', theEvent.itemLink), stringPrice, theEvent.guild, self.TextTimeSince(theEvent.timestamp, true)))
            else
              MasterMerchant:dm("Info", string.format(MasterMerchant.concat(GetString(MM_APP_MESSAGE_NAME), GetString(SK_SALES_ALERT_SINGLE)), zo_strformat('<<t:1>>', theEvent.itemLink), stringPrice, theEvent.guild, self.TextTimeSince(theEvent.timestamp, true)))
            end
          else
            MasterMerchant:dm("Info", string.format(MasterMerchant.concat(GetString(MM_APP_MESSAGE_NAME), GetString(SK_SALES_ALERT)), zo_strformat('<<t:1>>', theEvent.itemLink), theEvent.quant, stringPrice, theEvent.guild, self.TextTimeSince(theEvent.timestamp, true)))
          end
        end
      end

      -- Otherwise, we'll just alert once with a summary at the end
      if not MasterMerchant.systemSavedVariables.showMultiple and numAlerts > 1 then
        -- Insert thousands separators for the price
        local stringPrice = self.LocalizedNumber(totalGold)

        if MasterMerchant.systemSavedVariables.showAnnounceAlerts then
          MasterMerchant.CenterScreenAnnounce_AddMessage('MasterMerchantAlert', CSA_EVENT_SMALL_TEXT,
            MasterMerchant.systemSavedVariables.alertSoundName,
            string.format(GetString(SK_SALES_ALERT_GROUP_COLOR), numSold, stringPrice))
        else
          MasterMerchant:dm("Info", string.format(MasterMerchant.concat(GetString(MM_APP_MESSAGE_NAME), GetString(SK_SALES_ALERT_GROUP)),
              numSold, stringPrice))
        end
      end
    end
  end

  --self:SpecialMessage(false)

  -- Set the stats slider past the max if this is brand new data
  --if self.isFirstScan and doAlert then MasterMerchantStatsWindowSlider:SetValue(15) end
  --self.isFirstScan = false
end

-- /script d(MasterMerchant.LibHistoireListener[622389]:GetPendingEventMetrics())
function MasterMerchant:CheckStatus()
  for i = 1, GetNumGuilds() do
    local guildID                               = GetGuildId(i)
    local numEvents                             = GetNumGuildEvents(guildID, GUILD_HISTORY_STORE)
    local eventCount, processingSpeed, timeLeft = MasterMerchant.LibHistoireListener[guildID]:GetPendingEventMetrics()
    if timeLeft > -1 or (eventCount == 1 and numEvents == 0) then MasterMerchant.timeEstimated[guildID] = true end
    if (timeLeft == -1 and eventCount == 1 and numEvents == 0) and MasterMerchant.timeEstimated[guildID] then MasterMerchant.eventsNeedProcessing[guildID] = false end
    if eventCount == 0 and MasterMerchant.timeEstimated[guildID] then MasterMerchant.eventsNeedProcessing[guildID] = false end
    if eventCount > 1 then
      MasterMerchant:dm("Verbose", string.format(GetString(MM_CHECK_STATUS), GetGuildName(guildID), numEvents, eventCount, processingSpeed, timeLeft))
    end
  end
  for i = 1, GetNumGuilds() do
    local guildID = GetGuildId(i)
    if MasterMerchant.eventsNeedProcessing[guildID] then return true end
  end
  return false
end

function MasterMerchant:QueueCheckStatus()
  local eventsRemaining = MasterMerchant:CheckStatus()
  if eventsRemaining then
    zo_callLater(function() MasterMerchant:QueueCheckStatus()
    end, 500) -- 2 minutes
  else
    self:setScanning(false)
    MasterMerchant:RefreshMasterMerchantWindow()
    MasterMerchant.CenterScreenAnnounce_AddMessage(
      'MasterMerchantAlert',
      CSA_EVENT_SMALL_TEXT,
      MasterMerchant.systemSavedVariables.alertSoundName,
      "LibHistoire Refresh Finished"
    )
    MasterMerchant:dm("Info", GetString(MM_LIBHISTOIRE_REFRESH_FINISHED))
  end
end

-- Handle the refresh button
function MasterMerchant:DoRefresh()
  if not MasterMerchant.isInitialized then
    MasterMerchant:dm("Info", GetString(MM_STILL_INITIALIZING))
    return
  end
  if MasterMerchant.LibHistoireRefreshed then
    MasterMerchant:dm("Info", GetString(MM_LIBHISTOIRE_REFRESH_ONCE))
    return
  end
  self:setScanning(true)
  MasterMerchant:dm("Info", GetString(MM_LIBHISTOIRE_REFRESHING))
  numGuilds = GetNumGuilds()
  for i = 1, numGuilds do
    local guildID = GetGuildId(i)
    MasterMerchant.LibHistoireListener[guildID]:Stop()
    MasterMerchant.LibHistoireListener[guildID]  = nil
    MasterMerchant.eventsNeedProcessing[guildID] = true
    MasterMerchant.timeEstimated[guildID]        = false
  end
  for i = 1, numGuilds do
    local guildID                                                       = GetGuildId(i)
    MasterMerchant.systemSavedVariables["lastReceivedEventID"][guildID] = "0"
    MasterMerchant:SetupListener(guildID)
  end
  MasterMerchant.LibHistoireRefreshed = true
  MasterMerchant:QueueCheckStatus()
end

function MasterMerchant:initGMTools()
  MasterMerchant:dm("Debug", "initGMTools")
  -- Stub for GM Tools init
end

function MasterMerchant:initPurchaseTracking()
  MasterMerchant:dm("Debug", "initPurchaseTracking")
  -- Stub for Purchase Tracking init
end

function MasterMerchant:initSellingAdvice()
  if MasterMerchant.originalSellingSetupCallback then return end

  if TRADING_HOUSE and TRADING_HOUSE.postedItemsList then

    local dataType                              = TRADING_HOUSE.postedItemsList.dataTypes[2]

    MasterMerchant.originalSellingSetupCallback = dataType.setupCallback
    if MasterMerchant.originalSellingSetupCallback then
      dataType.setupCallback = function(...)
        local row, data = ...
        MasterMerchant.originalSellingSetupCallback(...)
        zo_callLater(function() MasterMerchant.AddSellingAdvice(row, data) end, 1)
      end
    else
      MasterMerchant:dm("Debug", GetString(MM_ADVICE_ERROR))
    end
  end

  if TRADING_HOUSE_GAMEPAD then
  end
end

function MasterMerchant.AddSellingAdvice(rowControl, result)
  local sellingAdvice = rowControl:GetNamedChild('SellingAdvice')
  if (not sellingAdvice) then
    local controlName                             = rowControl:GetName() .. 'SellingAdvice'
    sellingAdvice                                 = rowControl:CreateControl(controlName, CT_LABEL)

    local anchorControl                           = rowControl:GetNamedChild('TimeRemaining')
    local _, point, relTo, relPoint, offsX, offsY = anchorControl:GetAnchor(0)
    anchorControl:ClearAnchors()
    anchorControl:SetAnchor(point, relTo, relPoint, offsX, offsY - 10)

    sellingAdvice:SetAnchor(TOPLEFT, anchorControl, BOTTOMLEFT, 0, 0)
    sellingAdvice:SetFont('/esoui/common/fonts/univers67.otf|14|soft-shadow-thin')
  end

  local itemLink                  = GetTradingHouseListingItemLink(result.slotIndex)
  local dealValue, margin, profit = MasterMerchant.GetDealInfo(itemLink, result.purchasePrice, result.stackCount)
  if dealValue then
    if dealValue > -1 then
      if MasterMerchant.systemSavedVariables.saucy then
        sellingAdvice:SetText(MasterMerchant.LocalizedNumber(profit) .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t')
      else
        sellingAdvice:SetText(string.format('%.2f', margin) .. '%')
      end
      -- TODO I think this colors the number in the guild store
      --[[
      ZO_Currency_FormatPlatform(CURT_MONEY, tonumber(stringPrice), ZO_CURRENCY_FORMAT_AMOUNT_ICON, {color: someColorDef})
      ]]--
      local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, dealValue)
      if dealValue == 0 then
        r = 0.98;
        g = 0.01;
        b = 0.01;
      end
      sellingAdvice:SetColor(r, g, b, 1)
      sellingAdvice:SetHidden(false)
    else
      sellingAdvice:SetHidden(true)
    end
  else
    sellingAdvice:SetHidden(true)
  end
  sellingAdvice = nil
end

function MasterMerchant:initBuyingAdvice()
  --MasterMerchant.a_test_var = TRADING_HOUSE
  --MasterMerchant.b_test_var = TRADING_HOUSE_GAMEPAD
  --[[Keyboard Mode has a TRADING_HOUSE.searchResultsList
  that is set to
  ZO_TradingHouseBrowseItemsRightPaneSearchResults and
  then from there, there is a
  dataTypes[1].dataType.setupCallback.

  This does not exist in GamepadMode
  ]]--
  if MasterMerchant.originalSetupCallback then return end
  if TRADING_HOUSE and TRADING_HOUSE.searchResultsList then

    local dataType                       = TRADING_HOUSE.searchResultsList.dataTypes[1]

    MasterMerchant.originalSetupCallback = dataType.setupCallback
    if MasterMerchant.originalSetupCallback then
      dataType.setupCallback = function(...)
        local row, data = ...
        MasterMerchant.originalSetupCallback(...)
        zo_callLater(function() MasterMerchant.AddBuyingAdvice(row, data) end, 1)
      end
    else
      MasterMerchant:dm("Debug", GetString(MM_ADVICE_ERROR))
    end
  end

  if TRADING_HOUSE_GAMEPAD then
  end
end

function MasterMerchant.AddBuyingAdvice(rowControl, result)
  local buyingAdvice = rowControl:GetNamedChild('BuyingAdvice')
  if (not buyingAdvice) then
    local controlName = rowControl:GetName() .. 'BuyingAdvice'
    buyingAdvice      = rowControl:CreateControl(controlName, CT_LABEL)

    if (not AwesomeGuildStore) then
      local anchorControl                           = rowControl:GetNamedChild('SellPricePerUnit')
      local _, point, relTo, relPoint, offsX, offsY = anchorControl:GetAnchor(0)
      anchorControl:ClearAnchors()
      anchorControl:SetAnchor(point, relTo, relPoint, offsX, offsY + 10)
    end

    local anchorControl                           = rowControl:GetNamedChild('TimeRemaining')
    local _, point, relTo, relPoint, offsX, offsY = anchorControl:GetAnchor(0)
    anchorControl:ClearAnchors()
    anchorControl:SetAnchor(point, relTo, relPoint, offsX, offsY - 10)
    buyingAdvice:SetAnchor(TOPLEFT, anchorControl, BOTTOMLEFT, 0, 0)
    buyingAdvice:SetFont('/esoui/common/fonts/univers67.otf|14|soft-shadow-thin')
  end

  local index = result.slotIndex
  if (AwesomeGuildStore) then index = result.itemUniqueId end
  local itemLink                  = GetTradingHouseSearchResultItemLink(index)
  local dealValue, margin, profit = MasterMerchant.GetDealInfo(itemLink, result.purchasePrice, result.stackCount)
  if dealValue then
    if dealValue > -1 then
      if MasterMerchant.systemSavedVariables.saucy then
        buyingAdvice:SetText(MasterMerchant.LocalizedNumber(profit) .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t')
      else
        buyingAdvice:SetText(string.format('%.2f', margin) .. '%')
      end
      -- TODO I think this colors the number in the guild store
      local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, dealValue)
      if dealValue == 0 then
        r = 0.98;
        g = 0.01;
        b = 0.01;
      end
      buyingAdvice:SetColor(r, g, b, 1)
      buyingAdvice:SetHidden(false)
    else
      buyingAdvice:SetHidden(true)
    end
  else
    buyingAdvice:SetHidden(true)
  end
  buyingAdvice = nil
end

function MasterMerchant:BuildRosterTimeDropdown()
  local timeDropdown = ZO_ComboBox_ObjectFromContainer(MasterMerchantRosterTimeChooser)
  timeDropdown:ClearItems()

  MasterMerchant.systemSavedVariables.rankIndexRoster = MasterMerchant.systemSavedVariables.rankIndexRoster or 1

  local timeEntry                                     = timeDropdown:CreateItemEntry(GetString(MM_INDEX_TODAY),
    function() self:UpdateRosterWindow(1) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == 1 then timeDropdown:SetSelectedItem(GetString(MM_INDEX_TODAY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_3DAY), function() self:UpdateRosterWindow(2) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == 2 then timeDropdown:SetSelectedItem(GetString(MM_INDEX_3DAY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_THISWEEK), function() self:UpdateRosterWindow(3) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == 3 then timeDropdown:SetSelectedItem(GetString(MM_INDEX_THISWEEK)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_LASTWEEK), function() self:UpdateRosterWindow(4) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == 4 then timeDropdown:SetSelectedItem(GetString(MM_INDEX_LASTWEEK)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_PRIORWEEK), function() self:UpdateRosterWindow(5) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == 5 then timeDropdown:SetSelectedItem(GetString(MM_INDEX_PRIORWEEK)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_7DAY), function() self:UpdateRosterWindow(8) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == 8 then timeDropdown:SetSelectedItem(GetString(MM_INDEX_7DAY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_10DAY), function() self:UpdateRosterWindow(6) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == 6 then timeDropdown:SetSelectedItem(GetString(MM_INDEX_10DAY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_28DAY), function() self:UpdateRosterWindow(7) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == 7 then timeDropdown:SetSelectedItem(GetString(MM_INDEX_28DAY)) end

  timeEntry = timeDropdown:CreateItemEntry(MasterMerchant.customTimeframeText,
    function() self:UpdateRosterWindow(9) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndexRoster == 9 then timeDropdown:SetSelectedItem(MasterMerchant.customTimeframeText) end
end

--/script ZO_SharedRightBackground:SetWidth(1088)
function MasterMerchant:InitRosterChanges()
  MasterMerchant:dm("Debug", "InitRosterChanges")
  -- LibGuildRoster adding the Sold Column
  MasterMerchant.guild_columns['sold']   = LibGuildRoster:AddColumn({
    key      = 'MM_Sold',
    disabled = not MasterMerchant.systemSavedVariables.diplayGuildInfo or not MasterMerchant.systemSavedVariables.diplaySalesInfo,
    width    = 110,
    header   = {
      title = GetString(SK_SALES_COLUMN),
      align = TEXT_ALIGN_RIGHT
    },
    row      = {
      align  = TEXT_ALIGN_RIGHT,
      data   = function(guildId, data, index)

        local amountSold = 0

        if MasterMerchant.guildSales and
          MasterMerchant.guildSales[GUILD_ROSTER_MANAGER.guildName] and
          MasterMerchant.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers and
          MasterMerchant.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName] and
          MasterMerchant.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales then

          amountSold = MasterMerchant.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales[MasterMerchant.systemSavedVariables.rankIndexRoster or 1] or 0

        end

        return amountSold

      end,
      format = function(value)
        return MasterMerchant.LocalizedNumber(value) .. " |t16:16:EsoUI/Art/currency/currency_gold.dds|t"
      end
    }
  })

  -- LibGuildRoster adding the Bought Column
  MasterMerchant.guild_columns['bought'] = LibGuildRoster:AddColumn({
    key      = 'MM_Bought',
    disabled = not MasterMerchant.systemSavedVariables.diplayGuildInfo or not MasterMerchant.systemSavedVariables.diplayPurchasesInfo,
    width    = 110,
    header   = {
      title = GetString(SK_PURCHASES_COLUMN),
      align = TEXT_ALIGN_RIGHT
    },
    row      = {
      align  = TEXT_ALIGN_RIGHT,
      data   = function(guildId, data, index)

        local amountBought = 0

        if MasterMerchant.guildPurchases and
          MasterMerchant.guildPurchases[GUILD_ROSTER_MANAGER.guildName] and
          MasterMerchant.guildPurchases[GUILD_ROSTER_MANAGER.guildName].sellers and
          MasterMerchant.guildPurchases[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName] and
          MasterMerchant.guildPurchases[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales then

          amountBought = MasterMerchant.guildPurchases[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales[MasterMerchant.systemSavedVariables.rankIndexRoster or 1] or 0

        end

        return amountBought

      end,
      format = function(value)
        return MasterMerchant.LocalizedNumber(value) .. " |t16:16:EsoUI/Art/currency/currency_gold.dds|t"
      end
    }
  })

  -- LibGuildRoster adding the Tax Column
  MasterMerchant.guild_columns['per']    = LibGuildRoster:AddColumn({
    key      = 'MM_PerChg',
    disabled = not MasterMerchant.systemSavedVariables.diplayGuildInfo or not MasterMerchant.systemSavedVariables.diplayTaxesInfo,
    width    = 90,
    header   = {
      title   = GetString(SK_PER_CHANGE_COLUMN),
      align   = TEXT_ALIGN_RIGHT,
      tooltip = GetString(SK_PER_CHANGE_TIP)
    },
    row      = {
      align  = TEXT_ALIGN_RIGHT,
      data   = function(guildId, data, index)

        local amountSold = 0

        if MasterMerchant.guildSales and
          MasterMerchant.guildSales[GUILD_ROSTER_MANAGER.guildName] and
          MasterMerchant.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers and
          MasterMerchant.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName] and
          MasterMerchant.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales then

          amountSold = MasterMerchant.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales[MasterMerchant.systemSavedVariables.rankIndexRoster or 1] or 0
        end

        return math.floor(amountSold * 0.035)

      end,
      format = function(value)
        return MasterMerchant.LocalizedNumber(value) .. " |t16:16:EsoUI/Art/currency/currency_gold.dds|t"
      end
    }
  })

  -- LibGuildRoster adding the Count Column
  MasterMerchant.guild_columns['count']  = LibGuildRoster:AddColumn({
    key      = 'MM_Count',
    disabled = not MasterMerchant.systemSavedVariables.diplayGuildInfo or not MasterMerchant.systemSavedVariables.diplayCountInfo,
    width    = 70,
    header   = {
      title = GetString(SK_COUNT_COLUMN),
      align = TEXT_ALIGN_RIGHT
    },
    row      = {
      align  = TEXT_ALIGN_RIGHT,
      data   = function(guildId, data, index)

        local saleCount = 0

        if MasterMerchant.guildSales and
          MasterMerchant.guildSales[GUILD_ROSTER_MANAGER.guildName] and
          MasterMerchant.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers and
          MasterMerchant.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName] and
          MasterMerchant.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].sales then

          saleCount = MasterMerchant.guildSales[GUILD_ROSTER_MANAGER.guildName].sellers[data.displayName].count[MasterMerchant.systemSavedVariables.rankIndexRoster or 1] or 0

        end

        return saleCount

      end,
      format = function(value)
        return MasterMerchant.LocalizedNumber(value) .. " |t16:16:EsoUI/Art/currency/currency_gold.dds|t"
      end
    }
  })

  -- Guild Time dropdown choice box
  MasterMerchant.UI_GuildTime            = CreateControlFromVirtual('MasterMerchantRosterTimeChooser', ZO_GuildRoster,
    'MasterMerchantStatsGuildDropdown')

  -- Placing Guild Time dropdown at the bottom of the Count Column when it has been generated
  LibGuildRoster:OnRosterReady(function()
    MasterMerchant.UI_GuildTime:SetAnchor(TOP, MasterMerchant.guild_columns['count']:GetHeader(), BOTTOMRIGHT, -80, 570)
    MasterMerchant.UI_GuildTime:SetDimensions(180, 25)

    -- Don't render the dropdown this cycle if the settings have columns disabled
    if not MasterMerchant.systemSavedVariables.diplayGuildInfo then
      MasterMerchant.UI_GuildTime:SetHidden(true)
    end

  end)

  MasterMerchant.UI_GuildTime.m_comboBox:SetSortsItems(false)

  MasterMerchant:BuildRosterTimeDropdown()

end

-- Handle the reset button - clear out the search and scan tables,
-- and set the time of the last scan to nil, then force a scan.
function MasterMerchant:DoReset()
  self.salesData                    = {}
  self.SRIndex                      = {}

  MM00Data.savedVariables.SalesData = {}
  MM01Data.savedVariables.SalesData = {}
  MM02Data.savedVariables.SalesData = {}
  MM03Data.savedVariables.SalesData = {}
  MM04Data.savedVariables.SalesData = {}
  MM05Data.savedVariables.SalesData = {}
  MM06Data.savedVariables.SalesData = {}
  MM07Data.savedVariables.SalesData = {}
  MM08Data.savedVariables.SalesData = {}
  MM09Data.savedVariables.SalesData = {}
  MM10Data.savedVariables.SalesData = {}
  MM11Data.savedVariables.SalesData = {}
  MM12Data.savedVariables.SalesData = {}
  MM13Data.savedVariables.SalesData = {}
  MM14Data.savedVariables.SalesData = {}
  MM15Data.savedVariables.SalesData = {}

  self.guildPurchases               = {}
  self.guildSales                   = {}
  self.guildItems                   = {}
  self.myItems                      = {}
  if MasterMerchantGuildWindow:IsHidden() then
    MasterMerchant.scrollList:RefreshData()
  else
    MasterMerchant.guildScrollList:RefreshData()
  end
  self:setScanning(false)
  MasterMerchant:dm("Info", MasterMerchant.concat(GetString(MM_APP_MESSAGE_NAME), GetString(SK_RESET_DONE)))
  MasterMerchant:dm("Info", MasterMerchant.concat(GetString(MM_APP_MESSAGE_NAME), GetString(SK_REFRESH_START)))
  self.veryFirstScan = true
  -- self:ScanStoresParallel(true)
  --[[needs updating so start and stop the listener then
  init everyting
  ]]--
end

--[[TODO Use this to convert IDs to strings]]--
function MasterMerchant:AdjustItems(otherData)
  for itemID, itemIndex in pairs(otherData.savedVariables.SalesData) do
    for field, itemIndexData in pairs(itemIndex) do
      for sale, saleData in pairs(itemIndexData['sales']) do
        if type(saleData.id) ~= 'string' then
          saleData.id = tostring(saleData.id)
        end
      end
    end
  end
end

function MasterMerchant:ReferenceSales(otherData)
  otherData.savedVariables.dataLocations                 = otherData.savedVariables.dataLocations or {}
  otherData.savedVariables.dataLocations[GetWorldName()] = true

  for itemid, versionlist in pairs(otherData.savedVariables.SalesData) do
    if self.salesData[itemid] then
      for versionid, versiondata in pairs(versionlist) do
        if self.salesData[itemid][versionid] then
          if versiondata.sales then
            self.salesData[itemid][versionid].sales = self.salesData[itemid][versionid].sales or {}
            -- IPAIRS
            for saleid, saledata in pairs(versiondata.sales) do
              if (type(saleid) == 'number' and type(saledata) == 'table' and type(saledata.timestamp) == 'number') then
                table.insert(self.salesData[itemid][versionid].sales, saledata)
              end
            end
            local _, first = next(versiondata.sales, nil)
            if first then
              self.salesData[itemid][versionid].itemIcon      = GetItemLinkInfo(first.itemLink)
              self.salesData[itemid][versionid].itemAdderText = self.addedSearchToItem(first.itemLink)
              self.salesData[itemid][versionid].itemDesc      = GetItemLinkName(first.itemLink)
            end
          end
        else
          self.salesData[itemid][versionid] = versiondata
        end
      end
      otherData.savedVariables.SalesData[itemid] = nil
    else
      self.salesData[itemid] = versionlist
    end
  end
end

function MasterMerchant:AddNewData(otherData)
  for itemID, itemIndex in pairs(otherData.savedVariables.SalesData) do
    for field, itemIndexData in pairs(itemIndex) do
      local oldestTime = nil
      local totalCount = 0
      for sale, saleData in pairs(itemIndexData['sales']) do
        totalCount = totalCount +1
        if saleData.timestamp then
          if oldestTime == nil or oldestTime > saleData.timestamp then oldestTime = saleData.timestamp end
        else
          if MasterMerchant:is_empty_or_nil(saleData) then
            MasterMerchant:dm("Warn", "Empty Table Detected!")
            MasterMerchant:dm("Warn", itemID)
            MasterMerchant:dm("Warn", sale)
            itemIndexData['sales'][sale] = nil
          end
        end
      end
      self.salesData[itemID][field].totalCount = totalCount
      self.salesData[itemID][field].oldestTime = oldestTime
      self.salesData[itemID][field].wasAltered = false
    end
  end
end

function MasterMerchant:RenewExtraData(otherData)
  for itemID, itemIndex in pairs(otherData.savedVariables.SalesData) do
    for field, itemIndexData in pairs(itemIndex) do
      if itemIndexData.wasAltered then
        local oldestTime = nil
        local totalCount = 0
        for sale, saleData in pairs(itemIndexData['sales']) do
          totalCount = totalCount +1
          if oldestTime == nil or oldestTime > saleData.timestamp then oldestTime = saleData.timestamp end
        end
        self.salesData[itemID][field].totalCount = totalCount
        self.salesData[itemID][field].oldestTime = oldestTime
        self.salesData[itemID][field].wasAltered = false
      end
    end
  end
end

-- TODO Check This
function MasterMerchant:ReIndexSales(otherData)
  --[[This uses the first itemIndex ["50:16:4:7:0"] found
  if it does not have 4 colons, then the data needs to be
  updated. As if there was a time when the itemIndex was
  shorter.

  It also looks to see if there is an itemDesc and
  itemAdderText for the first item in the database. If not
  found then the next step would be to add those fields.

  This is no longer needed
  ]]--
  --[[ added 11-21-2020 because this could be used for something
  else in the future
  ]]--
  --if (GetAPIVersion() >= 100015) then return end

  local needToReindex          = false
  for _, v in pairs(otherData.savedVariables.SalesData) do
    if v then
      for j, dataList in pairs(v) do
        local key, count       = string.gsub(j, ':', ':')
        needToReindex          = (count ~= 4)
        break
      end
      break
    end
  end
  if needToReindex or not MasterMerchant.systemSavedVariables.shouldReindex then
    --MasterMerchant:dm("Debug", "needToReindex")
    local tempSales                    = otherData.savedVariables.SalesData
    otherData.savedVariables.SalesData = {}

    for k, v in pairs(tempSales) do
      if k ~= 0 then
        for j, dataList in pairs(v) do
          -- IPAIRS
          for i, item in pairs(dataList['sales']) do
            if (type(i) == 'number' and type(item) == 'table' and type(item.timestamp) == 'number') then
              local itemIndex = self.makeIndexFromLink(item.itemLink)
              if not otherData.savedVariables.SalesData[k] then otherData.savedVariables.SalesData[k] = {} end
              if otherData.savedVariables.SalesData[k][itemIndex] then
                table.insert(otherData.savedVariables.SalesData[k][itemIndex]['sales'], item)
              else
                otherData.savedVariables.SalesData[k][itemIndex] = {
                  ['itemIcon']      = dataList.itemIcon,
                  ['itemAdderText'] = self.addedSearchToItem(item.itemLink),
                  ['sales']         = { item },
                  ['itemDesc']      = GetItemLinkName(item.itemLink)
                }
              end
            end
          end
        end
      end
    end
  end
end

function MasterMerchant:ReAddDescription(otherData)
  local count = 0
  if not MasterMerchant.systemSavedVariables.shouldAdderText then
    for _, v in pairs(otherData.savedVariables.SalesData) do
      for _, dataList in pairs(v) do
        _, item              = next(dataList['sales'], nil)
        local textToAdd = GetItemLinkName(item.itemLink)
        if dataList['itemDesc'] ~= textToAdd then count = count + 1 end
        dataList['itemDesc'] = textToAdd
      end
    end
  end
  MasterMerchant:dm("Verbose", count)
end

function MasterMerchant:ReAdderText(otherData)
  local count = 0
  if not MasterMerchant.systemSavedVariables.shouldAdderText then
    for _, v in pairs(otherData.savedVariables.SalesData) do
      for _, dataList in pairs(v) do
        _, item                   = next(dataList['sales'], nil)
        local textToAdd = self.addedSearchToItem(item.itemLink)
        if dataList['itemAdderText'] ~= textToAdd then count = count + 1 end
        dataList['itemAdderText'] = textToAdd
      end
    end
  end
  MasterMerchant:dm("Verbose", count)
end

function MasterMerchant.SetupPendingPost(self)
  MasterMerchant:dm("Debug", "SetupPendingPost")
  OriginalSetupPendingPost(self)

  if (self.pendingItemSlot) then
    local itemLink         = GetItemLink(BAG_BACKPACK, self.pendingItemSlot)
    local _, stackCount, _ = GetItemInfo(BAG_BACKPACK, self.pendingItemSlot)

    local theIID           = GetItemLinkItemId(itemLink)
    local itemIndex        = MasterMerchant.makeIndexFromLink(itemLink)

    if MasterMerchant.systemSavedVariables.pricingData and MasterMerchant.systemSavedVariables.pricingData[theIID] and MasterMerchant.systemSavedVariables.pricingData[theIID][itemIndex] then
      self:SetPendingPostPrice(math.floor(MasterMerchant.systemSavedVariables.pricingData[theIID][itemIndex] * stackCount))
    else
      local tipStats = MasterMerchant:itemStats(itemLink, false)
      if (tipStats.avgPrice) then
        self:SetPendingPostPrice(math.floor(tipStats.avgPrice * stackCount))
      end
    end
  end
end

--[[ register event monitor
local function OnPlayerDeactivated(eventCode)
  EVENT_MANAGER:UnregisterForEvent(MasterMerchant.name.."_EventMon", EVENT_GUILD_HISTORY_RESPONSE_RECEIVED)
end
EVENT_MANAGER:RegisterForEvent(MasterMerchant.name.."_EventDisable", EVENT_PLAYER_DEACTIVATED, OnPlayerDeactivated)

local function OnPlayerActivated(eventCode)
  EVENT_MANAGER:RegisterForEvent(MasterMerchant.name.."_EventMon", EVENT_GUILD_HISTORY_RESPONSE_RECEIVED, function(...) MasterMerchant:ProcessGuildHistoryResponse(...) end)
end
EVENT_MANAGER:RegisterForEvent(MasterMerchant.name.."_EventEnable", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
]]--

function MasterMerchant:MoveFromOldAcctSavedVariables()
  -- Move the old single addon sales history to the multi addon sales history
  --[[TODO This is old and saved vars are not stored in this from
  what I understand. 12-13-2020
  ]]--
  if self.acctSavedVariables.SalesData then
    MasterMerchant:dm("Debug", "Move the old single addon sales history")
    local action = {
      [0]  = function(k, v) MM00Data.savedVariables.SalesData[k] = v end,
      [1]  = function(k, v) MM01Data.savedVariables.SalesData[k] = v end,
      [2]  = function(k, v) MM02Data.savedVariables.SalesData[k] = v end,
      [3]  = function(k, v) MM03Data.savedVariables.SalesData[k] = v end,
      [4]  = function(k, v) MM04Data.savedVariables.SalesData[k] = v end,
      [5]  = function(k, v) MM05Data.savedVariables.SalesData[k] = v end,
      [6]  = function(k, v) MM06Data.savedVariables.SalesData[k] = v end,
      [7]  = function(k, v) MM07Data.savedVariables.SalesData[k] = v end,
      [8]  = function(k, v) MM08Data.savedVariables.SalesData[k] = v end,
      [9]  = function(k, v) MM09Data.savedVariables.SalesData[k] = v end,
      [10] = function(k, v) MM10Data.savedVariables.SalesData[k] = v end,
      [11] = function(k, v) MM11Data.savedVariables.SalesData[k] = v end,
      [12] = function(k, v) MM12Data.savedVariables.SalesData[k] = v end,
      [13] = function(k, v) MM13Data.savedVariables.SalesData[k] = v end,
      [14] = function(k, v) MM14Data.savedVariables.SalesData[k] = v end,
      [15] = function(k, v) MM15Data.savedVariables.SalesData[k] = v end
    }

    for k, v in pairs(self.acctSavedVariables.SalesData) do
      local hash
      for j, dataList in pairs(v) do
        local item = dataList['sales'][1]
        hash       = MasterMerchant.hashString(string.lower(GetItemLinkName(item.itemLink)))
        break
      end
      action[hash](k, v)
    end
    self.acctSavedVariables.SalesData = nil
  end
end

function MasterMerchant:AdjustItemsAllContainers()
  -- Convert event IDs to string if not converted
  MasterMerchant:dm("Debug", "Convert event IDs to string if not converted")
  if not MasterMerchant.systemSavedVariables.verThreeItemIDConvertedToString then
    self:AdjustItems(MM00Data)
    self:AdjustItems(MM01Data)
    self:AdjustItems(MM02Data)
    self:AdjustItems(MM03Data)
    self:AdjustItems(MM04Data)
    self:AdjustItems(MM05Data)
    self:AdjustItems(MM06Data)
    self:AdjustItems(MM07Data)
    self:AdjustItems(MM08Data)
    self:AdjustItems(MM09Data)
    self:AdjustItems(MM10Data)
    self:AdjustItems(MM11Data)
    self:AdjustItems(MM12Data)
    self:AdjustItems(MM13Data)
    self:AdjustItems(MM14Data)
    self:AdjustItems(MM15Data)
    MasterMerchant.systemSavedVariables.verThreeItemIDConvertedToString = true
  end
end

function MasterMerchant:ReIndexSalesAllContainers()
  -- Update indexs because of Writs
  MasterMerchant:dm("Debug", "Update indexs if not converted")
  if not MasterMerchant.systemSavedVariables.shouldReindex then
    self:ReIndexSales(MM00Data)
    self:ReIndexSales(MM01Data)
    self:ReIndexSales(MM02Data)
    self:ReIndexSales(MM03Data)
    self:ReIndexSales(MM04Data)
    self:ReIndexSales(MM05Data)
    self:ReIndexSales(MM06Data)
    self:ReIndexSales(MM07Data)
    self:ReIndexSales(MM08Data)
    self:ReIndexSales(MM09Data)
    self:ReIndexSales(MM10Data)
    self:ReIndexSales(MM11Data)
    self:ReIndexSales(MM12Data)
    self:ReIndexSales(MM13Data)
    self:ReIndexSales(MM14Data)
    self:ReIndexSales(MM15Data)
    MasterMerchant.systemSavedVariables.shouldReindex   = true
  end
end

function MasterMerchant:ReAdderTextAllContainers()
  -- Update indexs because of Writs
  MasterMerchant:dm("Debug", "Update indexs if not converted")
  if not MasterMerchant.systemSavedVariables.shouldAdderText then
    self:ReAdderText(MM00Data)
    self:ReAdderText(MM01Data)
    self:ReAdderText(MM02Data)
    self:ReAdderText(MM03Data)
    self:ReAdderText(MM04Data)
    self:ReAdderText(MM05Data)
    self:ReAdderText(MM06Data)
    self:ReAdderText(MM07Data)
    self:ReAdderText(MM08Data)
    self:ReAdderText(MM09Data)
    self:ReAdderText(MM10Data)
    self:ReAdderText(MM11Data)
    self:ReAdderText(MM12Data)
    self:ReAdderText(MM13Data)
    self:ReAdderText(MM14Data)
    self:ReAdderText(MM15Data)
    MasterMerchant.systemSavedVariables.shouldAdderText = true
  end
end

function MasterMerchant:ReAddDescriptionAllContainers()
  -- Update indexs because of Writs
  MasterMerchant:dm("Debug", "Update indexs if not converted")
  if not MasterMerchant.systemSavedVariables.shouldAdderText then
    self:ReAddDescription(MM00Data)
    self:ReAddDescription(MM01Data)
    self:ReAddDescription(MM02Data)
    self:ReAddDescription(MM03Data)
    self:ReAddDescription(MM04Data)
    self:ReAddDescription(MM05Data)
    self:ReAddDescription(MM06Data)
    self:ReAddDescription(MM07Data)
    self:ReAddDescription(MM08Data)
    self:ReAddDescription(MM09Data)
    self:ReAddDescription(MM10Data)
    self:ReAddDescription(MM11Data)
    self:ReAddDescription(MM12Data)
    self:ReAddDescription(MM13Data)
    self:ReAddDescription(MM14Data)
    self:ReAddDescription(MM15Data)
    MasterMerchant.systemSavedVariables.shouldAdderText = true
  end
end

-- Bring seperate lists together we can still access the sales history all together
function MasterMerchant:ReferenceSalesAllContainers()
  MasterMerchant:dm("Debug", "Bring seperate lists together")
  self:ReferenceSales(MM00Data)
  self:ReferenceSales(MM01Data)
  self:ReferenceSales(MM02Data)
  self:ReferenceSales(MM03Data)
  self:ReferenceSales(MM04Data)
  self:ReferenceSales(MM05Data)
  self:ReferenceSales(MM06Data)
  self:ReferenceSales(MM07Data)
  self:ReferenceSales(MM08Data)
  self:ReferenceSales(MM09Data)
  self:ReferenceSales(MM10Data)
  self:ReferenceSales(MM11Data)
  self:ReferenceSales(MM12Data)
  self:ReferenceSales(MM13Data)
  self:ReferenceSales(MM14Data)
  self:ReferenceSales(MM15Data)
  self.systemSavedVariables.dataLocations                 = self.systemSavedVariables.dataLocations or {}
  self.systemSavedVariables.dataLocations[GetWorldName()] = true
end

-- Add new data to concatanated data array
function MasterMerchant:AddNewDataAllContainers()
  MasterMerchant:dm("Debug", "Add new data to concatanated data array")
  self:AddNewData(MM00Data)
  self:AddNewData(MM01Data)
  self:AddNewData(MM02Data)
  self:AddNewData(MM03Data)
  self:AddNewData(MM04Data)
  self:AddNewData(MM05Data)
  self:AddNewData(MM06Data)
  self:AddNewData(MM07Data)
  self:AddNewData(MM08Data)
  self:AddNewData(MM09Data)
  self:AddNewData(MM10Data)
  self:AddNewData(MM11Data)
  self:AddNewData(MM12Data)
  self:AddNewData(MM13Data)
  self:AddNewData(MM14Data)
  self:AddNewData(MM15Data)
end

-- Renew extra data if list was altered
function MasterMerchant:RenewExtraDataAllContainers()
  MasterMerchant:dm("Debug", "Add new data to concatanated data array")
  self:RenewExtraData(MM00Data)
  self:RenewExtraData(MM01Data)
  self:RenewExtraData(MM02Data)
  self:RenewExtraData(MM03Data)
  self:RenewExtraData(MM04Data)
  self:RenewExtraData(MM05Data)
  self:RenewExtraData(MM06Data)
  self:RenewExtraData(MM07Data)
  self:RenewExtraData(MM08Data)
  self:RenewExtraData(MM09Data)
  self:RenewExtraData(MM10Data)
  self:RenewExtraData(MM11Data)
  self:RenewExtraData(MM12Data)
  self:RenewExtraData(MM13Data)
  self:RenewExtraData(MM14Data)
  self:RenewExtraData(MM15Data)
end

-- Setup LibHistoire listeners
function MasterMerchant:SetupListenerLibHistoire()
  MasterMerchant:dm("Debug", "SetupListenerLibHistoire")
  MasterMerchant:dm("Info", GetString(MM_LIBHISTOIRE_ACTIVATED))
  -- do not start listening until mm is fully Initialized
  MasterMerchant.isInitialized = true -- moved in 3.2.7
  for i = 1, GetNumGuilds() do
    local guildID = GetGuildId(i)
    MasterMerchant.LibHistoireListener[guildID] = {}
    MasterMerchant:SetupListener(guildID)
  end
end

-- ShopkeeperSavedVars["Default"]["MasterMerchant"]["$AccountWide"]
-- self.savedVariables.verbose = value
-- self.acctSavedVariables.delayInit = nil
-- self:ActiveSettings().verbose = value
-- self.systemSavedVariables.verbose = value
-- MasterMerchant.systemSavedVariables.verbose = value
-- Init function
function MasterMerchant:Initialize()
  MasterMerchant:dm("Debug", "Initialize")
  -- SavedVar defaults
  old_defaults        = {}

  local systemDefault = {
    -- old settings
    dataLocations              = {},
    pricingData                = {}, -- added 12-31 but has always been there
    showChatAlerts             = false,
    showMultiple               = true,
    openWithMail               = true,
    openWithStore              = true,
    showFullPrice              = true,
    winLeft                    = 30,
    winTop                     = 85,
    guildWinLeft               = 30,
    guildWinTop                = 85,
    statsWinLeft               = 720,
    statsWinTop                = 820,
    feedbackWinLeft            = 720,
    feedbackWinTop             = 420,
    windowFont                 = "ProseAntique",
    showAnnounceAlerts         = true,
    showCyroAlerts             = true,
    alertSoundName             = "Book_Acquired",
    showUnitPrice              = false,
    viewSize                   = ITEMS,
    offlineSales               = true,
    showPricing                = true,
    showCraftCost              = true,
    showGraph                  = true,
    showCalc                   = true,
    minProfitFilter            = true,
    rankIndex                  = 1,
    rankIndexRoster            = 1,
    viewBuyerSeller            = 'buyer',
    viewGuildBuyerSeller       = 'seller',
    trimOutliers               = false,
    trimDecimals               = false,
    replaceInventoryValues     = false,
    displaySalesDetails        = false,
    displayItemAnalysisButtons = false,
    noSalesInfoDeal            = 2,
    focus1                     = 10,
    focus2                     = 3,
    focus3                     = 30,
    blacklist                  = '',
    defaultDays                = GetString(MM_RANGE_ALL),
    shiftDays                  = GetString(MM_RANGE_FOCUS1),
    ctrlDays                   = GetString(MM_RANGE_FOCUS2),
    ctrlShiftDays              = GetString(MM_RANGE_FOCUS3),
    saucy                      = false,
    displayListingMessage      = false,
    -- settingsToUse
    viewSize                   = ITEMS,
    customTimeframe            = 90,
    customTimeframeType        = GetString(MM_CUSTOM_TIMEFRAME_DAYS),
    --[[you can assign this as the default but it needs to be a global var
    customTimeframeText = tostring(90) .. ' ' .. GetString(MM_CUSTOM_TIMEFRAME_DAYS),
    ]]--
    minimalIndexing            = false,
    useSalesHistory            = false,
    historyDepth               = 30,
    minItemCount               = 20,
    maxItemCount               = 5000,
    diplayGuildInfo            = false,
    diplayPurchasesInfo        = true,
    diplaySalesInfo            = true,
    diplayTaxesInfo            = true,
    diplayCountInfo            = true,
    lastReceivedEventID        = {},
    showAmountTaxes            = false,
    useLibDebugLogger          = false, -- added 11-28
    -- conversion vars
    verThreeItemIDConvertedToString    = false, -- this only converts id64 at this time
    shouldReindex              = false,
    shouldAdderText            = false,
    showGuildInitSummary       = false,
    showIndexingSummary        = false,
  }

  for i = 1, GetNumGuilds() do
    local guildID                                 = GetGuildId(i)
    local guildName                               = GetGuildName(guildID)
    systemDefault["lastReceivedEventID"][guildID] = "0"
    MasterMerchant.alertQueue[guildName]          = {}
  end

  -- Finished setting up defaults, assign to global
  MasterMerchant.systemDefault                        = systemDefault
  -- Populate savedVariables
  --[[TODO address saved vars
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM00DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM00DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')

  The above two lines from one of the
  ]]--
  --[[TODO Pick one
  self.savedVariables is used by the containers but with 'MasterMerchant' for the namespace
  self.acctSavedVariables seems to be no longer used
  self.systemSavedVariables is what is used when you are supposedly swaping between acoutwide
  or not such as

  example: MasterMerchant.systemSavedVariables.showChatAlerts = MasterMerchant.systemSavedVariables.showChatAlerts
  ]]--
  self.savedVariables = ZO_SavedVars:New('ShopkeeperSavedVars', 1, GetDisplayName(), old_defaults)
  --[[ MasterMerchant.systemSavedVariables.scanHistory is no longer used for MasterMerchant.systemSavedVariables.scanHistory
  acording to the comment below but elf.acctSavedVariables is used when you are supposedly
  swaping between acoutwide or not such as mentioned above
  ]]--
  self.acctSavedVariables = ZO_SavedVars:NewAccountWide('ShopkeeperSavedVars', 1, GetDisplayName(), old_defaults)
  self.systemSavedVariables = ZO_SavedVars:NewAccountWide('ShopkeeperSavedVars', 1, nil, systemDefault, nil, 'MasterMerchant')
  MasterMerchant.show_log = self.systemSavedVariables.useLibDebugLogger

  local sv = ShopkeeperSavedVars["Default"]["MasterMerchant"]["$AccountWide"]
  -- Clean up saved variables (from previous versions)
  for key, val in pairs(sv) do
      -- Delete key-value pair if the key can't also be found in the default settings (except for version)
      if key ~= "version" and systemDefault[key] == nil then
          sv[key] = nil
      end
  end

  self.currentGuildID                                 = GetGuildId(1) or 0

  MasterMerchant.systemSavedVariables.diplayGuildInfo = MasterMerchant.systemSavedVariables.diplayGuildInfo or false

  --MasterMerchant:CreateControls()

  -- updated 11-22 needs to be here to make string
  MasterMerchant.customTimeframeText                  = MasterMerchant.systemSavedVariables.customTimeframe .. ' ' .. MasterMerchant.systemSavedVariables.customTimeframeType

  --[[TODO find a better way then these hacks
  ]]--
  -- History Depth
  if self.acctSavedVariables.historyDepth then
    MasterMerchant.systemSavedVariables.historyDepth = math.max(MasterMerchant.systemSavedVariables.historyDepth,
      self.acctSavedVariables.historyDepth)
    self.acctSavedVariables.historyDepth             = nil
  end
  if self.savedVariables.historyDepth then
    MasterMerchant.systemSavedVariables.historyDepth = math.max(MasterMerchant.systemSavedVariables.historyDepth,
      self.savedVariables.historyDepth)
    self.savedVariables.historyDepth                 = nil
  end

  -- Min Count
  if self.acctSavedVariables.minItemCount then
    MasterMerchant.systemSavedVariables.minItemCount = math.max(MasterMerchant.systemSavedVariables.minItemCount,
      self.acctSavedVariables.minItemCount)
    self.acctSavedVariables.minItemCount             = nil
  end
  if self.savedVariables.minItemCount then
    MasterMerchant.systemSavedVariables.minItemCount = math.max(MasterMerchant.systemSavedVariables.minItemCount,
      self.savedVariables.minItemCount)
    self.savedVariables.minItemCount                 = nil
  end

  -- Max Count
  if self.acctSavedVariables.maxItemCount then
    MasterMerchant.systemSavedVariables.maxItemCount = math.max(MasterMerchant.systemSavedVariables.maxItemCount,
      self.acctSavedVariables.maxItemCount)
    self.acctSavedVariables.maxItemCount             = nil
  end
  if self.savedVariables.maxItemCount then
    MasterMerchant.systemSavedVariables.maxItemCount = math.max(MasterMerchant.systemSavedVariables.maxItemCount,
      self.savedVariables.maxItemCount)
    self.savedVariables.maxItemCount                 = nil
  end

  -- Blacklist
  if not MasterMerchant:is_empty_or_nil(self.acctSavedVariables.blacklist) then
    MasterMerchant.systemSavedVariables.blacklist = self.acctSavedVariables.blacklist
    self.acctSavedVariables.blacklist             = nil
  end
  if not MasterMerchant:is_empty_or_nil(self.savedVariables.blacklist) then
    MasterMerchant.systemSavedVariables.blacklist = self.savedVariables.blacklist
    self.savedVariables.blacklist                 = nil
  end


  -- MoveFromOldAcctSavedVariables STEP
  -- AdjustItemsAllContainers() STEP
  -- ReIndexSalesAllContainers() STEP
  -- ReferenceSalesAllContainers() STEP
  -- New, added 9/26
  self:InitRosterChanges()

  self:setupGuildColors()

  -- Setup the options menu and main windows
  self:LibAddonInit()
  self:SetupMasterMerchantWindow()
  self:RestoreWindowPosition()

  -- Add the MasterMerchant window to the mail and trading house scenes if the
  -- player's settings indicate they want that behavior
  self.uiFragment      = ZO_FadeSceneFragment:New(MasterMerchantWindow)
  self.guildUiFragment = ZO_FadeSceneFragment:New(MasterMerchantGuildWindow)

  LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, self.LinkHandler_OnLinkMouseUp)

  ZO_PreHook('ZO_InventorySlot_ShowContextMenu',
    function(rowControl) self:myZO_InventorySlot_ShowContextMenu(rowControl) end)

  local theFragment = ((MasterMerchant.systemSavedVariables.viewSize == ITEMS) and self.uiFragment) or ((MasterMerchant.systemSavedVariables.viewSize == GUILDS) and self.guildUiFragment) or self.listingUiFragment
  if MasterMerchant.systemSavedVariables.openWithMail then
    MAIL_INBOX_SCENE:AddFragment(theFragment)
    MAIL_SEND_SCENE:AddFragment(theFragment)
  end

  if MasterMerchant.systemSavedVariables.openWithStore then
    TRADING_HOUSE_SCENE:AddFragment(theFragment)
  end

  -- Because we allow manual toggling of the MasterMerchant window in those scenes (without
  -- making that setting permanent), we also have to hide the window on closing them
  -- if they're not part of the scene.
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_MAIL_CLOSE_MAILBOX, function()
    if not MasterMerchant.systemSavedVariables.openWithMail then
      self:ActiveWindow():SetHidden(true)
      MasterMerchantStatsWindow:SetHidden(true)
    end
  end)
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLOSE_TRADING_HOUSE, function()
    MasterMerchant.ClearDealInfoCache()
    if not MasterMerchant.systemSavedVariables.openWithStore then
      self:ActiveWindow():SetHidden(true)
      MasterMerchantStatsWindow:SetHidden(true)
    end
  end)

  -- We also want to make sure the MasterMerchant windows are hidden in the game menu
  ZO_PreHookHandler(ZO_GameMenu_InGame, 'OnShow', function()
    self:ActiveWindow():SetHidden(true)
    MasterMerchantStatsWindow:SetHidden(true)
    MasterMerchantFeedback:SetHidden(true)
  end)

  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_TRADING_HOUSE_PENDING_ITEM_UPDATE,
    function(eventCode, slotId, isPending)
      if MasterMerchant.systemSavedVariables.showCalc and isPending and GetSlotStackSize(1, slotId) > 1 then
        local theLink     = GetItemLink(1, slotId, LINK_STYLE_DEFAULT)
        local theIID      = GetItemLinkItemId(theLink)
        local theIData    = self.makeIndexFromLink(theLink)
        local postedStats = self:toolTipStats(theIID, theIData)
        MasterMerchantPriceCalculatorStack:SetText(GetString(MM_APP_TEXT_TIMES) .. GetSlotStackSize(1, slotId))
        local floorPrice = 0
        if postedStats.avgPrice then floorPrice = string.format('%.2f', postedStats['avgPrice']) end
        MasterMerchantPriceCalculatorUnitCostAmount:SetText(floorPrice)
        MasterMerchantPriceCalculatorTotal:SetText(GetString(MM_TOTAL_TITLE) .. self.LocalizedNumber(math.floor(floorPrice * GetSlotStackSize(1,
          slotId))) .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t')
        MasterMerchantPriceCalculator:SetHidden(false)
      else MasterMerchantPriceCalculator:SetHidden(true) end
    end)

  --TODO see if this or something else can be used in Gamepad mode
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_TRADING_HOUSE_RESPONSE_RECEIVED, function(_, responseType, result)
    if responseType == TRADING_HOUSE_RESULT_POST_PENDING and result == TRADING_HOUSE_RESULT_SUCCESS then MasterMerchantPriceCalculator:SetHidden(true) end
    -- Set up guild store buying advice
    self:initBuyingAdvice()
    self:initSellingAdvice()
  end)

  -- I could do this with action layer pop/push, but it's kind've a pain
  -- when it's just these I want to hook
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLOSE_BANK, function() self:ActiveWindow():SetHidden(true) end)
  --    MasterMerchantWindow:SetHidden(true)
  --    MasterMerchantGuildWindow:SetHidden(true)
  --  end)
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLOSE_GUILD_BANK, function() self:ActiveWindow():SetHidden(true) end)
  --    MasterMerchantWindow:SetHidden(true)
  --    MasterMerchantGuildWindow:SetHidden(true)
  --  end)
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CLOSE_STORE, function() self:ActiveWindow():SetHidden(true) end)
  --    MasterMerchantWindow:SetHidden(true)
  --    MasterMerchantGuildWindow:SetHidden(true)
  --  end)
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_END_CRAFTING_STATION_INTERACT,
    function() self:ActiveWindow():SetHidden(true) end)
  --    MasterMerchantWindow:SetHidden(true)
  --    MasterMerchantGuildWindow:SetHidden(true)
  --  end)

  -- We'll add stats to tooltips for items we have data for, if desired
  ZO_PreHookHandler(PopupTooltip, 'OnUpdate', function() self:addStatsPopupTooltip(PopupTooltip) end)
  ZO_PreHookHandler(PopupTooltip, 'OnHide', function() self:remStatsPopupTooltip(PopupTooltip) end)
  ZO_PreHookHandler(ItemTooltip, 'OnUpdate', function() self:addStatsItemTooltip() end)
  ZO_PreHookHandler(ItemTooltip, 'OnHide', function() self:remStatsItemTooltip() end)

  ZO_PreHookHandler(ZO_ProvisionerTopLevelTooltip, 'OnUpdate',
    function() self:addStatsPopupTooltip(ZO_ProvisionerTopLevelTooltip) end)
  ZO_PreHookHandler(ZO_ProvisionerTopLevelTooltip, 'OnHide',
    function() self:remStatsPopupTooltip(ZO_ProvisionerTopLevelTooltip) end)


  if AwesomeGuildStore then
    AwesomeGuildStore:RegisterCallback(AwesomeGuildStore.callback.ITEM_POSTED, function(guildId, itemLink, price, stackCount)
      local theIID = GetItemLinkItemId(itemLink)
      local itemIndex = MasterMerchant.makeIndexFromLink(itemLink)
      MasterMerchant.systemSavedVariables.pricingData  = MasterMerchant.systemSavedVariables.pricingData or {}
      MasterMerchant.systemSavedVariables.pricingData[theIID] = MasterMerchant.systemSavedVariables.pricingData[theIID] or {}
      MasterMerchant.systemSavedVariables.pricingData[theIID][itemIndex] = price / stackCount
    end)
  else
    if TRADING_HOUSE then
      OriginalSetupPendingPost       = TRADING_HOUSE.SetupPendingPost
      TRADING_HOUSE.SetupPendingPost = MasterMerchant.SetupPendingPost
      ZO_PreHook(TRADING_HOUSE, 'PostPendingItem', MasterMerchant.PostPendingItem)
    end
  end
  -- Set up GM Tools, if also installed
  self:initGMTools()

  -- Set up purchase tracking, if also installed
  self:initPurchaseTracking()

  -- Build new lookup tables
  MasterMerchant:BuildAccountNameLookup()
  MasterMerchant:BuildItemLinkNameLookup()
  MasterMerchant:BuildGuildNameLookup()

  --Watch inventory listings
  for _, i in pairs(PLAYER_INVENTORY.inventories) do
    local listView = i.listView
    if listView and listView.dataTypes and listView.dataTypes[1] then
      local originalCall                  = listView.dataTypes[1].setupCallback

      listView.dataTypes[1].setupCallback = function(control, slot)
        originalCall(control, slot)
        self:SwitchPrice(control, slot)
      end
    end
  end

  -- Watch Decon list
  local originalCall                                                                 = ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack.dataTypes[1].setupCallback
  ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack.dataTypes[1].setupCallback = function(control, slot)
    originalCall(control, slot)
    self:SwitchPrice(control, slot)
  end

  --[[
  Order of events:

  OnAddOnLoaded
  Initialize
  Move the old single addon sales history
  Convert event IDs to string if not converted
  Update indexs if not converted
  Bring seperate lists together
  InitRosterChanges
  setupGuildColors
  LibAddonInit
  SetupMasterMerchantWindow
  UpdateFonts
  RegisterFonts
  RestoreWindowPosition
  initGMTools
  initPurchaseTracking
  BuildAccountNameLookup
  BuildItemLinkNameLookup
  BuildGuildNameLookup
  TruncateHistory
  TruncateHistory iterateOverSalesData
  InitItemHistory
  InitItemHistory iterateOverSalesData
  indexHistoryTables
  indexHistoryTables iterateOverSalesData
  InitScrollLists
  SetupScrollLists
  SetupListenerLibHistoire
  ]]--
  -- Right, we're all set up, so wait for the player activated event
  -- and then do an initial (deep) scan in case it's been a while since the player
  -- logged on, then use RegisterForUpdate to set up a timed scan.
  zo_callLater(function()
    local LEQ = LibExecutionQueue:new()
    LEQ:Add(function() MasterMerchant:dm("Info", GetString(MM_INITIALIZING)) end, 'MMInitializing')
    LEQ:Add(function() MasterMerchant:MoveFromOldAcctSavedVariables() end, 'MoveFromOldAcctSavedVariables')
    LEQ:Add(function() MasterMerchant:AdjustItemsAllContainers() end, 'AdjustItemsAllContainers')
    -- LEQ:Add(function() MasterMerchant:ReIndexSalesAllContainers() end, 'ReIndexSalesAllContainers')
    LEQ:Add(function() MasterMerchant:ReAdderTextAllContainers() end, 'ReAdderTextAllContainers')
    LEQ:Add(function() MasterMerchant:ReferenceSalesAllContainers() end, 'ReferenceSalesAllContainers')
    LEQ:Add(function() MasterMerchant:AddNewDataAllContainers() end, 'AddNewDataAllContainers')
    LEQ:Add(function() MasterMerchant:TruncateHistory() end, 'TruncateHistory')
    LEQ:Add(function() MasterMerchant:RenewExtraDataAllContainers() end, 'RenewExtraDataAllContainers')
    LEQ:Add(function() MasterMerchant:InitItemHistory() end, 'InitItemHistory')
    LEQ:Add(function() MasterMerchant:indexHistoryTables() end, 'indexHistoryTables')
    LEQ:Add(function() MasterMerchant:InitScrollLists() end, 'InitScrollLists')
    LEQ:Add(function() MasterMerchant:SetupListenerLibHistoire() end, 'SetupListenerLibHistoire')
    LEQ:Start()
  end, 10)
end

function MasterMerchant:SwitchPrice(control, slot)
  if MasterMerchant.systemSavedVariables.replaceInventoryValues then
    local bagId     = control.dataEntry.data.bagId
    local slotIndex = control.dataEntry.data.slotIndex
    local itemLink  = bagId and GetItemLink(bagId, slotIndex) or GetItemLink(slotIndex)

    if itemLink then
      local theIID    = GetItemLinkItemId(itemLink)
      local itemIndex = MasterMerchant.makeIndexFromLink(itemLink)
      local tipStats  = MasterMerchant:toolTipStats(theIID, itemIndex, true, true)
      if tipStats.avgPrice then
        --[[
        if control.dataEntry.data.rawName == "Fortified Nirncrux" then
        MasterMerchant.ShowChildren(control, 20)
        --d(control.dataEntry.data.rawName)
        d(control.dataEntry.data.bagId)
        d(control.dataEntry.data.slotIndex)
        d(control.dataEntry.data.statPrice)
        d(control.dataEntry.data.sellPrice)
        d(control.dataEntry.data.stackSellPrice)
        --d(control.dataEntry.data)
        end
        --]]
        if not control.dataEntry.data.mmOriginalPrice then
          control.dataEntry.data.mmOriginalPrice      = control.dataEntry.data.sellPrice
          control.dataEntry.data.mmOriginalStackPrice = control.dataEntry.data.stackSellPrice
        end

        control.dataEntry.data.mmPrice        = tonumber(string.format('%.0f', tipStats.avgPrice))
        control.dataEntry.data.stackSellPrice = tonumber(string.format('%.0f',
          tipStats.avgPrice * control.dataEntry.data.stackCount))
        control.dataEntry.data.sellPrice      = control.dataEntry.data.mmPrice

        local sellPriceControl                = control:GetNamedChild("SellPrice")
        if (sellPriceControl) then
          sellPrice = MasterMerchant.LocalizedNumber(control.dataEntry.data.stackSellPrice)
          sellPrice = '|cEEEE33' .. sellPrice .. '|r |t16:16:EsoUI/Art/currency/currency_gold.dds|t'
          sellPriceControl:SetText(sellPrice)
        end
      else
        if control.dataEntry.data.mmOriginalPrice then
          control.dataEntry.data.sellPrice      = control.dataEntry.data.mmOriginalPrice
          control.dataEntry.data.stackSellPrice = control.dataEntry.data.mmOriginalStackPrice
        end
        local sellPriceControl = control:GetNamedChild("SellPrice")
        if (sellPriceControl) then
          sellPrice = MasterMerchant.LocalizedNumber(control.dataEntry.data.stackSellPrice)
          sellPrice = sellPrice .. '|t16:16:EsoUI/Art/currency/currency_gold.dds|t'
          sellPriceControl:SetText(sellPrice)
        end
      end
    end
  end
end

function MasterMerchant:SetupListener(guildID)
  -- listener
  MasterMerchant.LibHistoireListener[guildID] = LGH:CreateGuildHistoryListener(guildID, GUILD_HISTORY_STORE)
  local lastReceivedEventID
  if MasterMerchant.systemSavedVariables["lastReceivedEventID"][guildID] then
    --MasterMerchant:dm("Info", string.format("MasterMerchant Saved Var: %s, GuildID: (%s)", MasterMerchant.systemSavedVariables["lastReceivedEventID"][guildID], guildID))
    lastReceivedEventID = StringToId64(MasterMerchant.systemSavedVariables["lastReceivedEventID"][guildID]) or "0"
    --MasterMerchant:dm("Info", string.format("lastReceivedEventID set to: %s", lastReceivedEventID))
    MasterMerchant.LibHistoireListener[guildID]:SetAfterEventId(lastReceivedEventID)
  end
  MasterMerchant.LibHistoireListener[guildID]:SetEventCallback(function(eventType, eventId, eventTime, p1, p2, p3, p4, p5, p6)
    if eventType == GUILD_EVENT_ITEM_SOLD then
      if not lastReceivedEventID or CompareId64s(eventId, lastReceivedEventID) > 0 then
        MasterMerchant.systemSavedVariables["lastReceivedEventID"][guildID] = Id64ToString(eventId)
        lastReceivedEventID                                                 = eventId
      end
      local guildName   = GetGuildName(guildID)
      local thePlayer   = string.lower(GetDisplayName())
      local added = false
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
      local theEvent    = {
        buyer     = p2,
        guild     = guildName,
        itemLink  = p4,
        quant     = p3,
        timestamp = eventTime,
        price     = p5,
        seller    = p1,
        wasKiosk  = false,
        id        = Id64ToString(eventId)
      }
      theEvent.wasKiosk = (MasterMerchant.guildMemberInfo[guildID][string.lower(theEvent.buyer)] == nil)

      local daysOfHistoryToKeep = GetTimeStamp() - MasterMerchant.oneDayInSeconds * MasterMerchant.systemSavedVariables.historyDepth
      if (theEvent.timestamp > daysOfHistoryToKeep) then
        local isNotDuplicate = MasterMerchant:IsNotDuplicateSale(theEvent.itemLink, theEvent.id)
        if isNotDuplicate then
          added = MasterMerchant:addToHistoryTables(theEvent)
        end
        -- (doAlert and (MasterMerchant.systemSavedVariables.showChatAlerts or MasterMerchant.systemSavedVariables.showAnnounceAlerts))
        if added and string.lower(theEvent.seller) == thePlayer then
          --MasterMerchant:dm("Debug", "alertQueue updated")
          table.insert(MasterMerchant.alertQueue[theEvent.guild], theEvent)
        end
        if added then
          MasterMerchant:PostScanParallel(guildName, true)
          MasterMerchant:SetMasterMerchantWindowDirty()
        end
      end
    end
  end)
  MasterMerchant.LibHistoireListener[guildID]:Start()
end

function MasterMerchant:InitScrollLists()
  MasterMerchant:dm("Debug", "InitScrollLists")

  self:SetupScrollLists()

  local numGuilds = GetNumGuilds()
  if numGuilds > 0 then
    MasterMerchant.currentGuildID = GetGuildId(1) or 0
    --MasterMerchant:UpdateControlData()
    --MasterMerchant:dm("Debug", "MasterMerchant.currentGuildID: " .. MasterMerchant.currentGuildID)
  else
    -- used for event index on guild history tab
    MasterMerchant.currentGuildID = 0
  end
  for i = 1, numGuilds do
    local guildID                        = GetGuildId(i)
    local guildName                      = GetGuildName(guildID)
    MasterMerchant.alertQueue[guildName] = {}
    for m = 1, GetNumGuildMembers(guildID) do
      local guildMemInfo, _, _, _, _ = GetGuildMemberInfo(guildID, m)
      if MasterMerchant.guildMemberInfo[guildID] == nil then MasterMerchant.guildMemberInfo[guildID] = {} end
      MasterMerchant.guildMemberInfo[guildID][string.lower(guildMemInfo)] = true
    end
  end

  MasterMerchant:dm("Info", string.format(GetString(MM_INITIALIZED), self.totalRecords))

  self.isFirstScan = MasterMerchant.systemSavedVariables.offlineSales
  if NonContiguousCount(self.salesData) > 0 then
    self.veryFirstScan = false
  else
    -- most of this stuff was unused
    self.veryFirstScan = true

    MasterMerchant:dm("Info", MasterMerchant.concat(GetString(MM_APP_MESSAGE_NAME), GetString(SK_FIRST_SCAN)))
  end

  -- MasterMerchant.isInitialized = true
  -- CALLBACK_MANAGER:RegisterCallback("OnGuildSelected", function() MasterMerchant:NewGuildSelected() end)
end

local dealInfoCache               = {}
MasterMerchant.ClearDealInfoCache = function()
  ZO_ClearTable(dealInfoCache)
end

MasterMerchant.GetDealInfo        = function(itemLink, purchasePrice, stackCount)
  local key = string.format("%s_%d_%d", itemLink, purchasePrice, stackCount)
  if (not dealInfoCache[key]) then
    local setPrice   = nil
    local salesCount = 0
    local theIID     = GetItemLinkItemId(itemLink)
    local itemIndex  = MasterMerchant.makeIndexFromLink(itemLink)
    local tipStats   = MasterMerchant:toolTipStats(theIID, itemIndex, true)
    if tipStats.avgPrice then
      setPrice   = tipStats['avgPrice']
      salesCount = tipStats['numSales']
    end
    dealInfoCache[key] = { MasterMerchant.DealCalc(setPrice, salesCount, purchasePrice, stackCount) }
  end
  return unpack(dealInfoCache[key])
end

function MasterMerchant:SendNote(gold)
  MasterMerchantFeedback:SetHidden(true)
  SCENE_MANAGER:Show('mailSend')
  ZO_MailSendToField:SetText('@Sharlikran')
  ZO_MailSendSubjectField:SetText('Master Merchant')
  QueueMoneyAttachment(gold)
  ZO_MailSendBodyField:TakeFocus()
end

Original_ZO_InventorySlotActions_Show = ZO_InventorySlotActions.Show

function ZO_InventorySlotActions:Show()
  g_slotActions = self
  Original_ZO_InventorySlotActions_Show(self)
end

function OnItemSelected()
  local isPlayerViewingTrader = GAMEPAD_TRADING_HOUSE_SELL.itemList.list.active
  local selectedItem          = GAMEPAD_TRADING_HOUSE_SELL.itemList.list.selectedIndex
  local searchData            = ZO_TradingHouse_GamepadMaskContainerSellList.scrollList.dataList.itemData.searchData
  local itemSelected          = searchData[selectedItem]
  local bagId                 = itemInventorySlot.bagId
  local slotId                = itemInventorySlot.slotId
  local itemLink              = GetItemLink(bagId, slotId)
  -- << alter price on scroll list >>
end

--[[TODO verify when player is using Gamepad
IsInGamepadPreferredMode()
]]--

-------------------------------------------------------------------------------
-- LMP - Removed Fonts v1.1
-------------------------------------------------------------------------------
--
-- Copyright (c) 2014 Ales Machat (Garkin)
--
-- Permission is hereby granted, free of charge, to any person
-- obtaining a copy of this software and associated documentation
-- files (the 'Software'), to deal in the Software without
-- restriction, including without limitation the rights to use,
-- copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following
-- conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
-- OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
-- HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
-- OTHER DEALINGS IN THE SOFTWARE.
function MasterMerchant:RegisterFonts()
  MasterMerchant:dm("Debug", "RegisterFonts")
  LMP:Register("font", "Arial Narrow", [[MasterMerchant/Fonts/arialn.ttf]])
  LMP:Register("font", "ESO Cartographer", [[MasterMerchant/Fonts/esocartographer-bold.otf]])
  LMP:Register("font", "Fontin Bold", [[MasterMerchant/Fonts/fontin_sans_b.otf]])
  LMP:Register("font", "Fontin Italic", [[MasterMerchant/Fonts/fontin_sans_i.otf]])
  LMP:Register("font", "Fontin Regular", [[MasterMerchant/Fonts/fontin_sans_r.otf]])
  LMP:Register("font", "Fontin SmallCaps", [[MasterMerchant/Fonts/fontin_sans_sc.otf]])
end

local function OnAddOnLoaded(eventCode, addOnName)
  if addOnName:find('^ZO_') then return end
  if addOnName == MasterMerchant.name then
    MasterMerchant:dm("Debug", "OnAddOnLoaded")
    MasterMerchant:Initialize()
    -- Set up /mm as a slash command toggle for the main window
    SLASH_COMMANDS['/mm'] = MasterMerchant.Slash
  elseif addOnName == "AwesomeGuildStore" then
    -- Set up AGS integration, if it's installed
    MasterMerchant:initAGSIntegration()
  end
end
local function loop1()
  for i = 1, 5 do
    d(i)
  end
end
local function loop2()
  for i = 11, 15 do
    d(i)
  end
end
local function loop3()
  for i = 21, 25 do
    d(i)
  end
end
local function loop4()
  for i = 31, 35 do
    d(i)
  end
end

function MasterMerchant:loopFunction(itemId, count, task)
  itemId = 123456
  count = 0
  task:While(function() return itemId ~= nil end):Do(function()
                      d(itemId)
                      count = count + 1
                      if count > 100 then itemId = nil end
                  end)
end

function MasterMerchant:TestLibAsync()
  local task = ASYNC:Create("example1")

  task:Call(function() MasterMerchant:loopFunction(nil, nil, task) end)
  task:Then(function()
    d("end")
  end)
end

function MasterMerchant.Slash(allArgs)
  local args        = ""
  local guildNumber = 0
  local hoursBack   = 0
  local argNum      = 0
  for w in string.gmatch(allArgs, "%w+") do
    argNum = argNum + 1
    if argNum == 1 then args = w end
    if argNum == 2 then guildNumber = tonumber(w) end
    if argNum == 3 then hoursBack = tonumber(w) end
  end
  args = string.lower(args)

  if args == 'help' then
    MasterMerchant:dm("Info", GetString(MM_HELP_WINDOW))
    MasterMerchant:dm("Info", GetString(MM_HELP_DUPS))
    MasterMerchant:dm("Info", GetString(MM_HELP_CLEAN))
    MasterMerchant:dm("Info", GetString(MM_HELP_CLEARPRICES))
    MasterMerchant:dm("Info", GetString(MM_HELP_INVISIBLE))
    MasterMerchant:dm("Info", GetString(MM_HELP_EXPORT))
    MasterMerchant:dm("Info", GetString(MM_HELP_SALES))
    MasterMerchant:dm("Info", GetString(MM_HELP_DEAL))
    MasterMerchant:dm("Info", GetString(MM_HELP_TYPES))
    MasterMerchant:dm("Info", GetString(MM_HELP_TRAITS))
    MasterMerchant:dm("Info", GetString(MM_HELP_QUALITY))
    MasterMerchant:dm("Info", GetString(MM_HELP_EQUIP))
    MasterMerchant:dm("Info", GetString(MM_HELP_SLIDE))
    return
  end
  --[[
  if args == 'atest' then
    MasterMerchant:TestLibAsync()
    return
  end
  ]]--
  if args == 'dups' or args == 'stilldups' then
    if MasterMerchant.isScanning then
      if args == 'dups' then MasterMerchant:dm("Info", GetString(MM_PURGING_DUPLICATES_DELAY)) end
      zo_callLater(function() MasterMerchant.Slash('stilldups') end, 10000)
      return
    end
    MasterMerchant:dm("Info", GetString(MM_PURGING_DUPLICATES))
    MasterMerchant:PurgeDups()
    return
  end
  if args == 'slide' or args == 'kindred' or args == 'stillslide' then
    if MasterMerchant.isScanning then
      if args ~= 'stillslide' then MasterMerchant:dm("Info", GetString(MM_SLIDING_SALES_DELAY)) end
      zo_callLater(function() MasterMerchant.Slash('stillslide') end, 10000)
      return
    end
    MasterMerchant:dm("Info", GetString(MM_SLIDING_SALES))
    MasterMerchant:SlideSales(false)
    return
  end

  if args == 'slideback' or args == 'kindredback' or args == 'stillslideback' then
    if MasterMerchant.isScanning then
      if args ~= 'stillslideback' then MasterMerchant:dm("Info", GetString(MM_SLIDING_SALES_DELAY)) end
      zo_callLater(function() MasterMerchant.Slash('stillslideback') end, 10000)
      return
    end
    MasterMerchant:dm("Info", GetString(MM_SLIDING_SALES))
    MasterMerchant:SlideSales(true)
    return
  end

  if args == 'export' then
    if not MasterMerchant.isInitialized then
      MasterMerchant:dm("Info", GetString(MM_STILL_INITIALIZING))
      return
    end
    MasterMerchant.guildNumber = guildNumber
    if (MasterMerchant.guildNumber > 0) and (GetNumGuilds() > 0) then
      MasterMerchant:dm("Info", GetString(MM_EXPORT_START))
      MasterMerchant:ExportLastWeek()
      MasterMerchant:dm("Info", GetString(MM_EXPORT_COMPLETE))
    else
      MasterMerchant:dm("Info", GetString(MM_GUILD_INDEX_INCLUDE))
      MasterMerchant:dm("Info", GetString(MM_GUILD_EXPORT_EXAMPLE))
      for i = 1, GetNumGuilds() do
        local guildID   = GetGuildId(i)
        local guildName = GetGuildName(guildID)
        MasterMerchant:dm("Info", string.format(GetString(MM_GUILD_INDEX_NAME), i, guildName))
      end
    end
    return
  end

  if args == 'sales' then
    if not MasterMerchant.isInitialized then
      MasterMerchant:dm("Info", GetString(MM_STILL_INITIALIZING))
      return
    end
    MasterMerchant.guildNumber = guildNumber
    if (MasterMerchant.guildNumber > 0) and (GetNumGuilds() > 0) then
      MasterMerchant:dm("Info", GetString(MM_SALES_EXPORT_START))
      MasterMerchant:ExportSalesData()
      MasterMerchant:dm("Info", GetString(MM_EXPORT_COMPLETE))
    else
      MasterMerchant:dm("Info", GetString(MM_GUILD_INDEX_INCLUDE))
      MasterMerchant:dm("Info", GetString(MM_GUILD_SALES_EXAMPLE))
      for i = 1, GetNumGuilds() do
        local guildID   = GetGuildId(i)
        local guildName = GetGuildName(guildID)
        MasterMerchant:dm("Info", string.format(GetString(MM_GUILD_INDEX_NAME), i, guildName))
      end
    end
    return
  end

  if args == '42' then
    MasterMerchant:SpecialMessage(true)
    return
  end

  if args == 'clean' or args == 'stillclean' then
    if MasterMerchant.isScanning then
      if args == 'clean' then MasterMerchant:dm("Info", GetString(MM_CLEAN_START_DELAY)) end
      zo_callLater(function() MasterMerchant.Slash('stillclean') end, 10000)
      return
    end
    MasterMerchant:dm("Info", GetString(MM_CLEAN_START))
    MasterMerchant:CleanOutBad()
    return
  end
  if args == 'redesc' then
    MasterMerchant.systemSavedVariables.shouldAdderText = false
    MasterMerchant:dm("Info", GetString(MM_CLEAN_UPDATE_DESC))
    return
  end
  if args == 'clearprices' then
    MasterMerchant.systemSavedVariables.pricingData = {}
    MasterMerchant:dm("Info", GetString(MM_CLEAR_SAVED_PRICES))
    return
  end
  if args == 'invisible' then
    MasterMerchantWindow:ClearAnchors()
    MasterMerchantWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, 30, 85)
    MasterMerchantGuildWindow:ClearAnchors()
    MasterMerchantGuildWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, 30, 85)
    MasterMerchant.systemSavedVariables.winLeft      = 30
    MasterMerchant.systemSavedVariables.guildWinLeft = 30
    MasterMerchant.systemSavedVariables.winTop       = 85
    MasterMerchant.systemSavedVariables.guildWinTop  = 85
    MasterMerchant:dm("Info", GetString(MM_RESET_POSITION))
    return
  end
  if args == 'deal' or args == 'saucy' then
    MasterMerchant.systemSavedVariables.saucy = not MasterMerchant.systemSavedVariables.saucy
    MasterMerchant:dm("Info", GetString(MM_GUILD_DEAL_TYPE))
    return
  end
  if args == 'types' then
    local message = 'Item types: '
    for i = 0, 71 do
      message = message .. i .. ')' .. GetString("SI_ITEMTYPE", i) .. ', '
    end
    MasterMerchant:dm("Info", message)
    return
  end
  if args == 'traits' then
    local message = 'Item traits: '
    for i = 0, 33 do
      message = message .. i .. ')' .. GetString("SI_ITEMTRAITTYPE", i) .. ', '
    end
    MasterMerchant:dm("Info", message)
    return
  end
  if args == 'quality' then
    local message = 'Item quality: '
    for i = 0, 5 do
      message = message .. GetString("SI_ITEMQUALITY", i) .. ', '
    end
    MasterMerchant:dm("Info", message)
    return
  end
  --[[
  if args == 'addr' then
    if MasterMerchant.isScanning then
      MasterMerchant:dm("Info", "Master Merchant is busy, wait for the current process to finish.")
      return
    end
    MasterMerchant.systemSavedVariables.shouldAdderText = false
    MasterMerchant:ReAddDescriptionAllContainers()
    return
  end
  ]]--
  if args == 'equip' then
    local message = 'Equipment types: '
    for i = 1, 15 do
      message = message .. GetString("SI_EQUIPTYPE", i) .. ', '
    end
    MasterMerchant:dm("Info", message)
    return
  end

  MasterMerchant:ToggleMasterMerchantWindow()
end

-- Register for the OnAddOnLoaded event
EVENT_MANAGER:RegisterForEvent(MasterMerchant.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
