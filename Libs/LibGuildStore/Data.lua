local internal = _G["LibGuildStore_Internal"]
local LGH = LibHistoire

--[[ can nout use MasterMerchant.itemsViewSize for example
because that will not be available this early.
]]--
local LISTINGS = 'listings_vs'
local PURCHASES = 'purchases_vs'

function internal:concat(...)
  local theString = MM_STRING_EMPTY
  for i = 1, select('#', ...) do
    local option = select(i, ...)
    if option ~= nil and option ~= MM_STRING_EMPTY then
      theString = theString .. tostring(option) .. MM_STRING_SEPARATOR_SPACE
    end
  end
  theString = zo_strgsub(theString, '^%s*(.-)%s*$', '%1')
  return theString
end

function internal:concatHash(a, ...)
  if a == nil and ... == nil then
    return ''
  elseif a == nil then
    return internal:concat(...)
  else
    if type(a) == 'boolean' then
      --d(tostring(a) .. ' ' .. internal:concat(...))
    end
    return tostring(a) .. ' ' .. internal:concat(...)
  end
end

function internal:GetAccountNameByIndex(index)
  if not index or not internal.accountNameByIdLookup[index] then return nil end
  return internal.accountNameByIdLookup[index]
end

function internal:GetItemLinkByIndex(index)
  if not index or not internal.itemLinkNameByIdLookup[index] then return nil end
  return internal.itemLinkNameByIdLookup[index]
end

function internal:GetGuildNameByIndex(index)
  if not index or not internal.guildNameByIdLookup[index] then return nil end
  return internal.guildNameByIdLookup[index]
end

-- uses mod to determine which save files to use
function internal:MakeHashStringByItemLink(itemLink)
  local name = zo_strlower(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink)))
  local hash = 0
  for c in zo_strgmatch(name, '.') do
    if c then hash = hash + string.byte(c) end
  end
  return hash % 16
end

-- uses mod to determine which save files to use
function internal:MakeHashStringByFormattedItemName(itemName)
  local name = zo_strlower(itemName)
  local hash = 0
  for c in zo_strgmatch(itemName, '.') do
    if c then hash = hash + string.byte(c) end
  end
  return hash % 16
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

-- The index consists of the item's required level, required vet
-- level, quality, and trait(if any), separated by colons.
-- /script d(zo_strmatch("|H1:item:6000:30:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h", '|H.-:item:.-:(%d-)|h'))
local itemIndexCache = { }

function internal:GetItemLinkParseData(itemLink)
  local itemType, specializedItemType = GetItemLinkItemType(itemLink)
  if itemType == ITEMTYPE_POISON or itemType == ITEMTYPE_POTION then
    return MasterMerchant_Internal:GetPotionEffectWritRewardField(itemLink)
  end
  if itemType == ITEMTYPE_MASTER_WRIT then
    return MasterMerchant_Internal:GetVoucherCountByItemLink(itemLink)
  end
  return 0
end

local function GetItemsTrait(itemLink, itemType)
  if itemType ~= ITEMTYPE_POISON and itemType ~= ITEMTYPE_POTION then
    return GetItemLinkTraitType(itemLink) or 0
  end
  local powerLevel = GetPotionPowerLevel(itemLink)
  return internal.potionVarientTable[powerLevel] or 0
end

local function GetRequiredLevel(itemLink, itemType)
  return itemType ~= ITEMTYPE_RECIPE and GetItemLinkRequiredLevel(itemLink) or 1
end

local function CreateIndexFromLink(itemLink)
  local itemType, specializedItemType = GetItemLinkItemType(itemLink)
  local requiredLevel = GetRequiredLevel(itemLink, itemType)
  local requiredChampionPoints = GetItemLinkRequiredChampionPoints(itemLink) / 10
  local quality = GetItemLinkDisplayQuality(itemLink)
  local trait = GetItemsTrait(itemLink, itemType)
  local parseData = internal:GetItemLinkParseData(itemLink)
  local index = requiredLevel .. ":" .. requiredChampionPoints .. ":" .. quality .. ":" .. trait .. ":" .. parseData
  return index
end

-- /script d(LibGuildStore_Internal.GetOrCreateIndexFromLink("|H0:item:44714:308:50:0:0:0:0:0:0:0:0:0:0:0:0:36:0:0:0:0:853248|h|h"))
function internal.GetOrCreateIndexFromLink(itemLink)
  local index = itemIndexCache[itemLink]
  if not index then
    itemIndexCache[itemLink] = CreateIndexFromLink(itemLink)
    index = itemIndexCache[itemLink]
  end
  return index
end

function internal:AddSearchToItem(itemLink)
  --Standardize Level to 1 if the level is not relevent but is stored on some items (ex: recipes)
  local requiredLevel = 1
  local itemType, specializedItemType = GetItemLinkItemType(itemLink)
  if itemType ~= ITEMTYPE_RECIPE then
    requiredLevel = GetItemLinkRequiredLevel(itemLink) -- verified
  end
  -- zo_strformat("<<t:1>>", GetString("SI_SPECIALIZEDITEMTYPE", specializedItemType))

  local requiredVeteranRank = GetItemLinkRequiredChampionPoints(itemLink) -- verified
  local vrAdder = GetString(GS_CP_RANK_SEARCH)

  local adder = ''
  if (requiredLevel > 0 or requiredVeteranRank > 0) then
    if (requiredVeteranRank > 0) then
      adder = vrAdder .. string.format('%02d', requiredVeteranRank)
    else
      adder = GetString(GS_REGULAR_RANK_SEARCH) .. string.format('%02d', requiredLevel)
    end
  else
    adder = vrAdder .. '00 ' .. GetString(GS_REGULAR_RANK_SEARCH) .. '00'
  end

  -- adds green blue
  local itemQuality = GetItemLinkDisplayQuality(itemLink) -- verified
  if (itemQuality == ITEM_DISPLAY_QUALITY_NORMAL) then adder = internal:concat(adder, GetString(GS_COLOR_WHITE)) end
  if (itemQuality == ITEM_DISPLAY_QUALITY_MAGIC) then adder = internal:concat(adder, GetString(GS_COLOR_GREEN)) end
  if (itemQuality == ITEM_DISPLAY_QUALITY_ARCANE) then adder = internal:concat(adder, GetString(GS_COLOR_BLUE)) end
  if (itemQuality == ITEM_DISPLAY_QUALITY_ARTIFACT) then adder = internal:concat(adder, GetString(GS_COLOR_PURPLE)) end
  if (itemQuality == ITEM_DISPLAY_QUALITY_LEGENDARY) then adder = internal:concat(adder, GetString(GS_COLOR_GOLD)) end
  if (itemQuality == ITEM_DISPLAY_QUALITY_MYTHIC_OVERRIDE) then adder = internal:concat(adder, GetString(GS_COLOR_ORANGE)) end

  -- adds Mythic Legendary
  adder = internal:concat(adder, zo_strformat("<<t:1>>", GetString("SI_ITEMDISPLAYQUALITY", itemQuality))) -- verified

  -- adds Heavy
  local armorType = GetItemLinkArmorType(itemLink) -- verified
  if (armorType ~= 0) then
    adder = internal:concat(adder, zo_strformat("<<t:1>>", GetString("SI_ARMORTYPE", armorType)))
  end

  -- adds Apparel
  local filterType = GetItemLinkFilterTypeInfo(itemLink) -- verified
  if (filterType ~= 0) then
    adder = internal:concat(adder, zo_strformat("<<t:1>>", GetString("SI_ITEMFILTERTYPE", filterType)))
  end
  -- declared above
  -- local itemType = GetItemLinkItemType(itemLink) -- verified
  if (itemType ~= 0) then
    adder = internal:concat(adder, zo_strformat("<<t:1>>", GetString("SI_ITEMTYPE", itemType)))
  end

  -- adds Mark of the Pariah
  local isSetItem, setName = GetItemLinkSetInfo(itemLink) -- verified
  if (isSetItem) then
    adder = internal:concat(adder, 'set', setName)
  end

  -- adds Sword, Healing Staff
  local weaponType = GetItemLinkWeaponType(itemLink) -- verified
  if (weaponType ~= 0) then
    adder = internal:concat(adder, zo_strformat("<<t:1>>", GetString("SI_WEAPONTYPE", weaponType)))
  end

  -- adds chest two-handed
  local itemEquip = GetItemLinkEquipType(itemLink) -- verified
  if (itemEquip ~= 0) then
    adder = internal:concat(adder, zo_strformat("<<t:1>>", GetString("SI_EQUIPTYPE", itemEquip)))
  end

  -- adds Precise
  local itemTrait = GetItemLinkTraitType(itemLink) -- verified
  if (itemTrait ~= 0) then
    adder = internal:concat(adder, zo_strformat("<<t:1>>", GetString("SI_ITEMTRAITTYPE", itemTrait)))
  end

  -- adds furnature category
  if itemType == ITEMTYPE_FURNISHING then
    local dataId = GetItemLinkFurnitureDataId(itemLink)
    local categoryId, subcategoryId = GetFurnitureDataCategoryInfo(dataId)
    if (categoryId ~= 0) then
      adder = internal:concat(adder, zo_strlower(GetFurnitureCategoryInfo(categoryId)))
    end
  end

  -- diagram, paraxis etc for the category is part of the name already
  --[[
  if itemType == ITEMTYPE_RECIPE then
    if (specializedItemType ~= 0) then
      typeString = zo_strlower(zo_strformat("<<t:1>>", GetString("SI_SPECIALIZEDITEMTYPE", specializedItemType)))
      typeString = zo_strgsub(typeString, 'furnishing', '')
      adder = internal:concat(adder, typeString)
    end
  end
  ]]--

  if adder:find("jewelry") then
    adder = adder:gsub("apparel", "")
  end
  if adder:find("shield") then
    adder = adder:gsub("weapon", "")
  end
  local resultTable = {}
  local resultString = zo_strgmatch(adder, '%S+')
  for word in resultString do
    if next(resultTable) == nil then
      table.insert(resultTable, word)
    elseif not internal:is_in(word, resultTable) then
      table.insert(resultTable, " " .. word)
    end
  end
  adder = table.concat(resultTable)
  return zo_strlower(adder)
end

function internal:BuildAccountNameLookup()
  internal:dm("Debug", "BuildAccountNameLookup")
  if not GS17DataSavedVariables["accountNames"] then return end
  local startingCount = internal:NonContiguousNonNilCount(GS17DataSavedVariables["accountNames"])
  local count = 0
  for key, value in pairs(GS17DataSavedVariables["accountNames"]) do
    count = count + 1
    internal.accountNameByIdLookup[value] = key
  end
  internal.accountNamesCount = count
  if count ~= startingCount then internal:dm("Warn", "Account Names Count Mismatch") end
end

function internal:BuildItemLinkNameLookup()
  internal:dm("Debug", "BuildItemLinkNameLookup")
  if not GS16DataSavedVariables["itemLink"] then GS16DataSavedVariables["itemLink"] = {} end
  internal.itemLinksCount = internal:NonContiguousNonNilCount(GS16DataSavedVariables["itemLink"])
  local count = 0
  for key, value in pairs(GS16DataSavedVariables["itemLink"]) do
    count = count + 1
    internal.itemLinkNameByIdLookup[value] = key
  end
  if count ~= internal.itemLinksCount then internal:dm("Warn", "ItemLink Count Mismatch") end
end

function internal:BuildGuildNameLookup()
  internal:dm("Debug", "BuildGuildNameLookup")
  if not GS16DataSavedVariables["guildNames"] then GS16DataSavedVariables["guildNames"] = {} end
  internal.guildNamesCount = internal:NonContiguousNonNilCount(GS16DataSavedVariables["guildNames"])
  local count = 0
  for key, value in pairs(GS16DataSavedVariables["guildNames"]) do
    count = count + 1
    internal.guildNameByIdLookup[value] = key
  end
  if count ~= internal.guildNamesCount then internal:dm("Warn", "Guild Names Count Mismatch") end
end

function internal:BuildTraderNameLookup()
  internal:dm("Debug", "BuildTraderNameLookup")
  if not GS17DataSavedVariables[internal.visitedNamespace] then GS17DataSavedVariables[internal.visitedNamespace] = {} end
  for key, value in pairs(GS17DataSavedVariables[internal.visitedNamespace]) do
    local currentGuild = value.guildName
    internal.traderIdByNameLookup[currentGuild] = key
  end
end

function internal:SetPurchaseData(theIID)
  local dataTable = _G["GS17DataSavedVariables"]
  local savedVars = dataTable[internal.purchasesNamespace]
  savedVars[theIID] = {}
  return savedVars[theIID]
end

function internal:SetPostedItmesData(theIID)
  local dataTable = _G["GS17DataSavedVariables"]
  local savedVars = dataTable[internal.postedNamespace]
  savedVars[theIID] = {}
  return savedVars[theIID]
end

function internal:SetCancelledItmesData(theIID)
  local dataTable = _G["GS17DataSavedVariables"]
  local savedVars = dataTable[internal.cancelledNamespace]
  savedVars[theIID] = {}
  return savedVars[theIID]
end

function internal:SetVisitedGuildsData(theIID)
  local dataTable = _G["GS16DataSavedVariables"]
  local savedVars = dataTable[internal.visitedNamespace]
  savedVars[theIID] = {}
  return savedVars[theIID]
end

function internal:SetTraderListingData(itemLink, theIID)
  local hash = internal:MakeHashStringByItemLink(itemLink)
  local dataTable = _G[string.format("GS%02dDataSavedVariables", hash)]
  local savedVars = dataTable[internal.listingsNamespace]
  savedVars[theIID] = {}
  return savedVars[theIID], hash
end

function internal:SetGuildStoreData(formattedItemName, theIID)
  local hash = internal:MakeHashStringByFormattedItemName(formattedItemName)
  local dataTable = _G[string.format("GS%02dDataSavedVariables", hash)]
  local savedVars = dataTable[internal.dataNamespace]
  savedVars[theIID] = {}
  return savedVars[theIID], hash
end

-- /script d(LibGuildStore_Internal:AddSalesTableData("itemLink", "|H0:item:68212:3:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"))
-- /script d(GS16DataSavedVariables["itemLink"]["|H0:item:68212:3:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"])
function internal:AddSalesTableData(key, value)
  local saveData
  local lookupTable
  local countVariable

  if key == "accountNames" then
    saveData = GS17DataSavedVariables[key]
    lookupTable = internal.accountNameByIdLookup
    countVariable = internal.accountNamesCount
  elseif key == "itemLink" then
    saveData = GS16DataSavedVariables[key]
    lookupTable = internal.itemLinkNameByIdLookup
    countVariable = internal.itemLinksCount
  elseif key == "guildNames" then
    saveData = GS16DataSavedVariables[key]
    lookupTable = internal.guildNameByIdLookup
    countVariable = internal.guildNamesCount
  end

  if not saveData[value] then
    countVariable = countVariable + 1
    saveData[value] = countVariable
    lookupTable[countVariable] = value

    if key == "accountNames" then
      internal.accountNamesCount = countVariable
    elseif key == "itemLink" then
      internal.itemLinksCount = countVariable
    elseif key == "guildNames" then
      internal.guildNamesCount = countVariable
    end

    return countVariable
  else
    return saveData[value]
  end
end

function internal:QueueGuildHistoryListener(guildId, guildIndex)
  local multiplier = guildIndex
  if not guildIndex then multiplier = 1 end
  internal:SetupGuildHistoryListener(guildId)
  if not internal.LibHistoireListenerReady[guildId] then
    internal:dm("Debug", "LibHistoireListener not ready")
    zo_callLater(function() internal:QueueGuildHistoryListener(guildId) end, (MM_WAIT_TIME_IN_MILLISECONDS_LIBHISTOIRE * multiplier))
  else
    zo_callLater(function() internal:SetupListener(guildId) end, (MM_WAIT_TIME_IN_MILLISECONDS_LIBHISTOIRE_SETUP * multiplier))
  end
end

-- /script LibGuildStore_Internal:SetupGuildHistoryListener(guildId)
function internal:SetupGuildHistoryListener(guildId)
  --internal:dm("Debug", "SetupGuildHistoryListener: " .. guildId)
  if internal.LibHistoireListener == nil then internal.LibHistoireListener = { } end
  if internal.LibHistoireListener[guildId] == nil then internal.LibHistoireListener[guildId] = { } end

  internal.LibHistoireListener[guildId] = LGH:CreateGuildHistoryListener(guildId, GUILD_HISTORY_STORE)
  if internal.LibHistoireListener[guildId] == nil then
    --internal:dm("Warn", "The Listener was nil")
  elseif internal.LibHistoireListener[guildId] ~= nil then
    --internal:dm("Debug", "The Listener was not nil, Listener ready.")
    internal.LibHistoireListenerReady[guildId] = true
  end
end

function internal:UpdateAlertQueue(guildName, theEvent)
  --internal:dm("Debug", "UpdateAlertQueue: " .. guildName)
  local doAlert = MasterMerchant.systemSavedVariables.showChatAlerts or MasterMerchant.systemSavedVariables.showAnnounceAlerts
  if not internal.alertQueue[guildName] or not doAlert then return end
  table.insert(internal.alertQueue[guildName], theEvent)
end

-- /script LibGuildStore_Internal.LibHistoireListener[guildId]:SetAfterEventId(StringToId64("0"))
function internal:SetupListener(guildId)
  internal:dm("Debug", "SetupListener: " .. guildId)
  --internal:SetupGuildHistoryListener(guildId)
  local lastReceivedEventID
  if internal.LibHistoireListener[guildId] == nil then
    internal:dm("Warn", "The Listener was still nil somehow")
    return
  end

  if LibGuildStore_SavedVariables.libHistoireScanByTimestamp then
    local setAfterTimestamp = GetTimeStamp() - ((LibGuildStore_SavedVariables.historyDepth + 1) * ZO_ONE_DAY_IN_SECONDS)
    internal.LibHistoireListener[guildId]:SetAfterEventTime(setAfterTimestamp)
  else
    if LibGuildStore_SavedVariables["lastReceivedEventID"][internal.libHistoireNamespace][guildId] then
      --internal:dm("Info", string.format("internal Saved Var: %s, guildId: (%s)", LibGuildStore_SavedVariables["lastReceivedEventID"][internal.libHistoireNamespace][guildId], guildId))
      lastReceivedEventID = StringToId64(LibGuildStore_SavedVariables["lastReceivedEventID"][internal.libHistoireNamespace][guildId])
      --internal:dm("Info", string.format("lastReceivedEventID set to: %s", lastReceivedEventID))
      internal.LibHistoireListener[guildId]:SetAfterEventId(lastReceivedEventID)
    end
  end
  internal.LibHistoireListener[guildId]:SetEventCallback(function(eventType, eventId, eventTime, p1, p2, p3, p4, p5, p6)
    --internal:dm("Info", "SetEventCallback")
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
    if eventType == GUILD_EVENT_ITEM_SOLD then
      if not lastReceivedEventID or CompareId64s(eventId, lastReceivedEventID) > 0 then
        LibGuildStore_SavedVariables["lastReceivedEventID"][internal.libHistoireNamespace][guildId] = Id64ToString(eventId)
        lastReceivedEventID = eventId
      end
      local guildName = GetGuildName(guildId)
      local theEvent = {
        buyer = p2,
        guild = guildName,
        itemLink = p4,
        quant = p3,
        timestamp = eventTime,
        price = p5,
        seller = p1,
        wasKiosk = false,
        id = Id64ToString(eventId)
      }
      theEvent.wasKiosk = (internal.guildMemberInfo[guildId][zo_strlower(theEvent.buyer)] == nil)

      local thePlayer = zo_strlower(GetDisplayName())
      local isSelfSale = zo_strlower(theEvent.seller) == thePlayer
      local added = false
      local daysOfHistoryToKeep = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * LibGuildStore_SavedVariables["historyDepth"])
      if (theEvent.timestamp > daysOfHistoryToKeep) then
        local duplicate = internal:CheckForDuplicateSale(theEvent.itemLink, theEvent.id)
        if not duplicate then
          added = internal:addSalesData(theEvent)
        end
        if added and isSelfSale then
          internal:UpdateAlertQueue(guildName, theEvent)
        end
        if added then
          MasterMerchant:PostScanParallel(guildName)
        end
      end
    end
  end)
  internal.LibHistoireListener[guildId]:Start()
end

function internal:GenerateSearchText(theEvent, itemDesc, adderText)
  local temp = { '', ' ', '', ' ', '', ' ', '', ' ', '', ' ', '', }
  local searchText = ""
  local playerName = zo_strlower(GetDisplayName())
  local isSelfSale = playerName == zo_strlower(theEvent.seller)
  local minimalIndexing = LibGuildStore_SavedVariables["minimalIndexing"]

  if minimalIndexing then
    if isSelfSale then
      searchText = internal.PlayerSpecialText or ""
    end
  else
    temp[1] = theEvent.buyer and ('b' .. theEvent.buyer) or ''
    temp[3] = theEvent.seller and ('s' .. theEvent.seller) or ''
    temp[5] = theEvent.guild or ''
    temp[7] = itemDesc or ''
    temp[9] = adderText or ''

    if selfSale and addPlayer then
      temp[11] = internal.PlayerSpecialText or ""
    end

    searchText = zo_strlower(table.concat(temp, ''))
  end

  return searchText
end

function internal:GenerateBasicSearchText(theEvent, itemDesc, adderText)
  local temp = { '', ' ', '', ' ', '', ' ', '', } -- fewer tokens for Basic version
  local searchText = ""

  temp[1] = theEvent.seller and ('s' .. theEvent.seller) or ''
  temp[3] = theEvent.guild or ''
  temp[5] = itemDesc or ''
  temp[7] = adderText or ''

  searchText = zo_strlower(table.concat(temp, ''))

  return searchText
end

----------------------------------------
----- Event Functions              -----
----------------------------------------

-- this is for vanilla to add purchace data
function internal:onTradingHouseEvent(eventCode, slotId, isPending)
  --internal:dm("Debug", "onTradingHouseEvent")
  if not MasterMerchant.isInitialized then return end
  if not AwesomeGuildStore then
    --internal:dm("Debug", "not AwesomeGuildStore")
    local icon, itemName, displayQuality, quantity, seller, timeRemaining, price, currencyType, itemUniqueId, purchasePricePerUnit = GetTradingHouseSearchResultItemInfo(slotId)
    local guildId, guild, guildAlliance = GetCurrentTradingHouseGuildDetails()
    local listedTime = GetTimeStamp() - (2592000 - timeRemaining)
    local theEvent = {
      guild = guild,
      guildId = guildId,
      itemLink = GetTradingHouseSearchResultItemLink(slotId),
      quant = quantity,
      timestamp = GetTimeStamp(),
      listingTime = listedTime,
      price = price,
      seller = seller,
      id = Id64ToString(itemUniqueId),
      buyer = GetDisplayName()
    }
    --internal:dm("Debug", theEvent)
    internal:addPurchaseData(theEvent)
    MasterMerchant.listIsDirty[PURCHASES] = true
  end
end

function internal:AddAwesomeGuildStoreListing(listing)
  --internal:dm("Debug", "AddAwesomeGuildStoreListing")
  local listedTime = GetTimeStamp() - (2592000 - listing.timeRemaining)
  local theEvent = {
    guild = listing.guildName,
    guildId = listing.guildId,
    itemLink = listing.itemLink,
    quant = listing.stackCount,
    timestamp = GetTimeStamp(),
    listingTime = listedTime,
    price = listing.purchasePrice,
    seller = listing.sellerName,
    id = Id64ToString(listing.itemUniqueId),
  }
  internal:addTraderInfo(listing.guildId, listing.guildName)
  local added = false
  local duplicate = internal:CheckForDuplicateListings(theEvent.itemLink, theEvent.id, theEvent.timestamp)
  if not duplicate then
    added = internal:addListingData(theEvent)
    MasterMerchant.listIsDirty[LISTINGS] = true
  end
end

-- this is for the vanilla UI
function internal:processGuildStore()
  --internal:dm("Debug", "processGuildStore")
  local numItemsOnPage, currentPage, hasMorePages = GetTradingHouseSearchResultsInfo()
  local itemLink, icon, itemName, displayQuality, stackCount, sellerName, timeRemaining, purchasePrice,
  currencyType, itemUniqueId, purchasePricePerUnit
  local guildId, guildName = GetCurrentTradingHouseGuildDetails()
  for i = 1, numItemsOnPage do
    itemLink = GetTradingHouseSearchResultItemLink(i)
    icon, itemName, displayQuality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType,
    itemUniqueId, purchasePricePerUnit = GetTradingHouseSearchResultItemInfo(i)
    local listedTime = GetTimeStamp() - (2592000 - timeRemaining)
    local theEvent = {
      guild = guildName,
      guildId = lguildId,
      itemLink = itemLink,
      quant = stackCount,
      timestamp = GetTimeStamp(),
      listingTime = listedTime,
      price = purchasePrice,
      seller = sellerName,
      id = Id64ToString(itemUniqueId),
    }
    internal:addTraderInfo(guildId, guildName)
    local duplicate = internal:CheckForDuplicateListings(theEvent.itemLink, theEvent.id, theEvent.timestamp)
    if not duplicate then
      local added = internal:addListingData(theEvent)
      MasterMerchant.listIsDirty[LISTINGS] = true
    end
  end
end

if not AwesomeGuildStore then
  ZO_PreHook(TRADING_HOUSE, "RebuildSearchResultsPage", function()
    internal:processGuildStore()
  end)
end

-- this should loop over the data from AGS to be converted to theEvent
function internal:processAwesomeGuildStore(itemDatabase, guildId)
  local guildCounts = {}
  for guildIndex, guildData in pairs(itemDatabase) do
    local guildName = GetGuildName(guildIndex)
    guildCounts[guildName] = internal:NonContiguousNonNilCount(itemDatabase[guildIndex])
    for dataIndex, listingData in pairs(guildData) do
      local index = Id64ToString(dataIndex)
      if listingData.guildId == guildId then
        internal:AddAwesomeGuildStoreListing(listingData)
      end
    end
  end

end

local function ResetListingsDataNA()
  GS00Data:ResetListingsDataNA()
  GS01Data:ResetListingsDataNA()
  GS02Data:ResetListingsDataNA()
  GS03Data:ResetListingsDataNA()
  GS04Data:ResetListingsDataNA()
  GS05Data:ResetListingsDataNA()
  GS06Data:ResetListingsDataNA()
  GS07Data:ResetListingsDataNA()
  GS08Data:ResetListingsDataNA()
  GS09Data:ResetListingsDataNA()
  GS10Data:ResetListingsDataNA()
  GS11Data:ResetListingsDataNA()
  GS12Data:ResetListingsDataNA()
  GS13Data:ResetListingsDataNA()
  GS14Data:ResetListingsDataNA()
  GS15Data:ResetListingsDataNA()
end

local function ResetListingsDataEU()
  GS00Data:ResetListingsDataEU()
  GS01Data:ResetListingsDataEU()
  GS02Data:ResetListingsDataEU()
  GS03Data:ResetListingsDataEU()
  GS04Data:ResetListingsDataEU()
  GS05Data:ResetListingsDataEU()
  GS06Data:ResetListingsDataEU()
  GS07Data:ResetListingsDataEU()
  GS08Data:ResetListingsDataEU()
  GS09Data:ResetListingsDataEU()
  GS10Data:ResetListingsDataEU()
  GS11Data:ResetListingsDataEU()
  GS12Data:ResetListingsDataEU()
  GS13Data:ResetListingsDataEU()
  GS14Data:ResetListingsDataEU()
  GS15Data:ResetListingsDataEU()
end
-- Handle the reset button - clear out the search and scan tables,
-- and set the time of the last scan to nil, then force a scan.
function internal:ResetListingsData()
  internal:dm("Debug", "ResetListingsData")
  if GetWorldName() == 'NA Megaserver' then
    ResetListingsDataNA()
  else
    ResetListingsDataEU()
  end
  internal:DatabaseBusy(true)
  ReloadUI()
end

local function ResetAllData()
  GS00Data:ResetAllData()
  GS01Data:ResetAllData()
  GS02Data:ResetAllData()
  GS03Data:ResetAllData()
  GS04Data:ResetAllData()
  GS05Data:ResetAllData()
  GS06Data:ResetAllData()
  GS07Data:ResetAllData()
  GS08Data:ResetAllData()
  GS09Data:ResetAllData()
  GS10Data:ResetAllData()
  GS11Data:ResetAllData()
  GS12Data:ResetAllData()
  GS13Data:ResetAllData()
  GS14Data:ResetAllData()
  GS15Data:ResetAllData()
  GS16Data:ResetAllData()
  GS17Data:ResetAllData()
end

function internal:resetAllLibGuildStoreData()
  internal:dm("Debug", "ResetAllData")
  ResetAllData()
  internal:DatabaseBusy(true)
  LibGuildStore_SavedVariables[internal.firstrunNamespace] = true
  LibGuildStore_SavedVariables.libHistoireScanByTimestamp = true
  ReloadUI()
end

function internal:addTraderInfo(guildId, guildName)
  -- GetPlayerActiveSubzoneName() Southpoint in Grahtwood
  -- GetPlayerActiveZoneName() Grahtwood
  -- GetUnitZone("player") Grahtwood
  -- GetMapName() Grahtwood
  -- GetPlayerLocationName() Southpoint in Grahtwood
  local interactTypeKiosk = IsUnitGuildKiosk("interact")
  if not interactTypeKiosk then return end

  local zoneName = GetPlayerActiveZoneName()
  local subzoneName = GetPlayerActiveSubzoneName()
  local local_x, local_y = GetMapPlayerPosition("player")
  local zoneIndex = GetCurrentMapZoneIndex()
  local zoneId = GetZoneId(zoneIndex)
  if subzoneName == MM_STRING_EMPTY then subzoneName = zoneName end
  local theInfo = {
    guildName = guildName,
    local_x = local_x,
    local_y = local_y,
    zoneName = zoneName,
    subzoneName = subzoneName,
    zoneId = zoneId,
  }

  GS17DataSavedVariables[internal.visitedNamespace] = GS17DataSavedVariables[internal.visitedNamespace] or {}
  GS17DataSavedVariables[internal.visitedNamespace][guildId] = GS17DataSavedVariables[internal.visitedNamespace][guildId] or {}

  GS17DataSavedVariables[internal.visitedNamespace][guildId] = theInfo
  internal.traderIdByNameLookup[guildName] = guildId
end
