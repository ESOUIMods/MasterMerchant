local lib = _G["LibGuildStore"]
local internal = _G["LibGuildStore_Internal"]

local LGH = LibHistoire

--[[ can nout use MasterMerchant.itemsViewSize for example
because that will not be available this early.
]]--
local ITEMS = 'items_vs'
local GUILDS = 'guild_vs'
local LISTINGS = 'listings_vs'
local PURCHASES = 'purchases_vs'
local REPORTS = 'reports_vs'

function internal:concat(a, ...)
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

function internal:GetGuildNameByIndex(index)
  if not index or not internal.guildNameByIdLookup[index] then return nil end
  return internal.guildNameByIdLookup[index]
end

function internal:GetItemLinkByIndex(index)
  if not index or not internal.itemLinkNameByIdLookup[index] then return nil end
  return internal.itemLinkNameByIdLookup[index]
end

function internal:GetAccountNameByIndex(index)
  if not index or not internal.accountNameByIdLookup[index] then return nil end
  return internal.accountNameByIdLookup[index]
end

-- uses mod to determine which save files to use
function internal:MakeHashString(itemLink)
  local name = string.lower(zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink)))
  local hash = 0
  for c in zo_strgmatch(name, '.') do
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
local itemIndexCache = { }

local function GetItemLinkParseData(itemLink, itemType)
  if itemType ~= ITEMTYPE_MASTER_WRIT then
    return zo_strmatch(itemLink, '|H.-:item:.-:(%d-)|h') or 0
  end
  return 0
end

local function GetItemsTrait(itemLink, itemType)
  if itemType ~= ITEMTYPE_POISON and itemType ~= ITEMTYPE_POTION then
    return GetItemLinkTraitType(itemLink) or 0
  end
  local powerLevel = GetPotionPowerLevel(itemLink)
  return MasterMerchant.potionVarientTable[powerLevel] or 0
end

local function GetRequiredLevel(itemLink, itemType)
  return itemType ~= ITEMTYPE_RECIPE and GetItemLinkRequiredLevel(itemLink) or 1
end

local function CreateIndexFromLink(itemLink)
  local itemType, specializedItemType = GetItemLinkItemType(itemLink)
  return GetRequiredLevel(itemLink,
    itemType) .. ":" .. GetItemLinkRequiredChampionPoints(itemLink) / 10 .. ":" .. GetItemLinkQuality(itemLink) .. ":" .. GetItemsTrait(itemLink,
    itemType) .. ":" .. GetItemLinkParseData(itemLink, itemType)
end

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
  if (itemQuality == ITEM_DISPLAY_QUALITY_MYTHIC_OVERRIDE) then adder = internal:concat(adder,
    GetString(GS_COLOR_ORANGE)) end

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
      adder = internal:concat(adder, string.lower(GetFurnitureCategoryInfo(categoryId)))
    end
  end

  -- diagram, paraxis etc for the category is part of the name already
  --[[
  if itemType == ITEMTYPE_RECIPE then
    if (specializedItemType ~= 0) then
      typeString = string.lower(zo_strformat("<<t:1>>", GetString("SI_SPECIALIZEDITEMTYPE", specializedItemType)))
      typeString = string.gsub(typeString, 'furnishing', '')
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
  return string.lower(adder)
end

function internal:BuildTraderNameLookup()
  internal:dm("Debug", "BuildTraderNameLookup")
  if not GS17DataSavedVariables[internal.visitedNamespace] then GS17DataSavedVariables[internal.visitedNamespace] = {} end
  for key, value in pairs(GS17DataSavedVariables[internal.visitedNamespace]) do
    local currentGuild = value.guildName
    internal.traderIdByNameLookup[currentGuild] = key
  end
end

function internal:BuildAccountNameLookup()
  internal:dm("Debug", "BuildAccountNameLookup")
  if not GS16DataSavedVariables["accountNames"] then GS16DataSavedVariables["accountNames"] = {} end
  for key, value in pairs(GS16DataSavedVariables["accountNames"]) do
    internal.accountNameByIdLookup[value] = key
  end
end

function internal:BuildItemLinkNameLookup()
  internal:dm("Debug", "BuildItemLinkNameLookup")
  if not GS16DataSavedVariables["itemLink"] then GS16DataSavedVariables["itemLink"] = {} end
  for key, value in pairs(GS16DataSavedVariables["itemLink"]) do
    internal.itemLinkNameByIdLookup[value] = key
  end
end
function internal:BuildGuildNameLookup()
  internal:dm("Debug", "BuildGuildNameLookup")
  if not GS16DataSavedVariables["guildNames"] then GS16DataSavedVariables["guildNames"] = {} end
  for key, value in pairs(GS16DataSavedVariables["guildNames"]) do
    internal.guildNameByIdLookup[value] = key
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
  local hash = internal:MakeHashString(itemLink)
  local dataTable = _G[string.format("GS%02dDataSavedVariables", hash)]
  local savedVars = dataTable[internal.listingsNamespace]
  savedVars[theIID] = {}
  return savedVars[theIID], hash
end

function internal:SetGuildStoreData(itemLink, theIID)
  local hash = internal:MakeHashString(itemLink)
  local dataTable = _G[string.format("GS%02dDataSavedVariables", hash)]
  local savedVars = dataTable[internal.dataNamespace]
  savedVars[theIID] = {}
  return savedVars[theIID], hash
end

-- /script d(LibGuildStore_Internal:AddSalesTableData("itemLink", "|H0:item:68212:3:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"))
-- /script d(GS16DataSavedVariables["itemLink"]["|H0:item:68212:3:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"])
function internal:AddSalesTableData(key, value)
  local saveData = GS16DataSavedVariables[key]
  if not saveData[value] then
    local index = internal:NonContiguousNonNilCount(GS16DataSavedVariables[key]) + 1
    saveData[value] = index
    if key == "accountNames" then
      internal.accountNameByIdLookup[index] = value
    end
    if key == "itemLink" then
      internal.itemLinkNameByIdLookup[index] = value
    end
    if key == "guildNames" then
      internal.guildNameByIdLookup[index] = value
    end
    return index
  else
    return saveData[value]
  end
end

function internal:SetupListener(guildId)
  internal:dm("Debug", "SetupListener: " .. guildId)
  -- listener
  internal.LibHistoireListener[guildId] = LGH:CreateGuildHistoryListener(guildId, GUILD_HISTORY_STORE)
  local lastReceivedEventID
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
    if eventType == GUILD_EVENT_ITEM_SOLD then
      if not lastReceivedEventID or CompareId64s(eventId, lastReceivedEventID) > 0 then
        LibGuildStore_SavedVariables["lastReceivedEventID"][internal.libHistoireNamespace][guildId] = Id64ToString(eventId)
        lastReceivedEventID = eventId
      end
      local guildName = GetGuildName(guildId)
      local thePlayer = string.lower(GetDisplayName())
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
      local theEvent = {
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
      theEvent.wasKiosk = (internal.guildMemberInfo[guildId][string.lower(theEvent.buyer)] == nil)

      local daysOfHistoryToKeep = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * LibGuildStore_SavedVariables["historyDepth"])
      if (theEvent.timestamp > daysOfHistoryToKeep) then
        local duplicate = internal:CheckForDuplicateSale(theEvent.itemLink, theEvent.id)
        if not duplicate then
          added = internal:addSalesData(theEvent)
        end
        -- (doAlert and (internal.systemSavedVariables.showChatAlerts or internal.systemSavedVariables.showAnnounceAlerts))
        if added and string.lower(theEvent.seller) == thePlayer then
          --internal:dm("Debug", "alertQueue updated")
          table.insert(internal.alertQueue[theEvent.guild], theEvent)
        end
        if added then
          MasterMerchant:PostScanParallel(guildName, true)
        end
      end
    end
  end)
  internal.LibHistoireListener[guildId]:Start()
end

function internal:GetSearchText(buyer, seller, guild, itemDesc, adderText, addPlayer)
  local temp = { '', ' ', '', ' ', '', ' ', '', ' ', '', ' ', '', }
  local playerName = GetDisplayName()
  local searchText = ""
  local selfSale = playerName == seller
  if LibGuildStore_SavedVariables["minimalIndexing"] then
    if selfSale and addPlayer then
      searchText = internal.PlayerSpecialText
    end
  else
    if buyer then temp[1] = 'b' .. buyer end
    if seller then temp[3] = 's' .. seller end
    temp[5] = guild or ''
    temp[7] = itemDesc or ''
    temp[9] = adderText or ''
    if selfSale and addPlayer then
      temp[11] = internal.PlayerSpecialText
    end
    searchText = string.lower(table.concat(temp, ''))
  end
  return searchText
end

----------------------------------------
----- Event Functions              -----
----------------------------------------

-- this is for vanilla to add purchace data
function internal:onTradingHouseEvent(eventCode, slotId, isPending)
  --internal:dm("Debug", "onTradingHouseEvent")
  if not AwesomeGuildStore then
    --internal:dm("Debug", "not AwesomeGuildStore")
    local icon, itemName, displayQuality, quantity, seller, timeRemaining, price, currencyType, itemUniqueId, purchasePricePerUnit = GetTradingHouseSearchResultItemInfo(slotId)
    local guildId, guild, guildAlliance = GetCurrentTradingHouseGuildDetails()
    local listedTime = GetTimeStamp() - (2592000 - timeRemaining)
    local theEvent = {
      guild       = guild,
      guildId     = guildId,
      itemLink    = GetTradingHouseSearchResultItemLink(slotId),
      quant       = quantity,
      timestamp   = GetTimeStamp(),
      listingTime = listedTime,
      price       = price,
      seller      = seller,
      id          = Id64ToString(itemUniqueId),
      buyer       = GetDisplayName()
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
    guild       = listing.guildName,
    guildId     = listing.guildId,
    itemLink    = listing.itemLink,
    quant       = listing.stackCount,
    timestamp   = GetTimeStamp(),
    listingTime = listedTime,
    price       = listing.purchasePrice,
    seller      = listing.sellerName,
    id          = Id64ToString(listing.itemUniqueId),
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
      guild       = guildName,
      guildId     = lguildId,
      itemLink    = itemLink,
      quant       = stackCount,
      timestamp   = GetTimeStamp(),
      listingTime = listedTime,
      price       = purchasePrice,
      seller      = sellerName,
      id          = Id64ToString(itemUniqueId),
    }
    internal:addTraderInfo(guildId, guildName)
    local duplicate = internal:CheckForDuplicateListings(theEvent.itemLink, theEvent.id, theEvent.timestamp)
    if not duplicate then
      added = internal:addListingData(theEvent)
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

-- Handle the reset button - clear out the search and scan tables,
-- and set the time of the last scan to nil, then force a scan.
function internal:ResetListingsData()
  internal:dm("Debug", "ResetListingsData")

  GS00DataSavedVariables[internal.listingsToReset] = {}
  GS01DataSavedVariables[internal.listingsToReset] = {}
  GS02DataSavedVariables[internal.listingsToReset] = {}
  GS03DataSavedVariables[internal.listingsToReset] = {}
  GS04DataSavedVariables[internal.listingsToReset] = {}
  GS05DataSavedVariables[internal.listingsToReset] = {}
  GS06DataSavedVariables[internal.listingsToReset] = {}
  GS07DataSavedVariables[internal.listingsToReset] = {}
  GS08DataSavedVariables[internal.listingsToReset] = {}
  GS09DataSavedVariables[internal.listingsToReset] = {}
  GS10DataSavedVariables[internal.listingsToReset] = {}
  GS11DataSavedVariables[internal.listingsToReset] = {}
  GS12DataSavedVariables[internal.listingsToReset] = {}
  GS13DataSavedVariables[internal.listingsToReset] = {}
  GS14DataSavedVariables[internal.listingsToReset] = {}
  GS15DataSavedVariables[internal.listingsToReset] = {}
  MasterMerchant.listIsDirty[LISTINGS] = true

  local lr_index = {}
  _G["LibGuildStore_ListingsIndex"] = lr_index
  internal.lr_index_count = 0
  local listings_data = {}
  _G["LibGuildStore_ListingsData"] = listings_data
  internal.listedItems = {}
  internal.listedSellers = {}

  local LEQ = LibExecutionQueue:new()
  LEQ:Add(function() internal:DatabaseBusy(true) end, 'DatabaseBusy_true')
  LEQ:Add(function() internal:ReferenceListingsDataContainer() end, 'ReferenceListingsDataContainer')
  LEQ:Add(function() internal:InitListingHistory() end, 'InitListingHistory')
  LEQ:Add(function() internal:IndexListingsData() end, 'IndexListingsData')
  LEQ:Add(function() internal:DatabaseBusy(false) end, 'DatabaseBusy_false')
  LEQ:Add(function() MasterMerchant.listingsScrollList:RefreshFilters() end, 'RefreshFilters')
  LEQ:Add(function() internal:dm("Info", GetString(GS_REINDEXING_COMPLETE)) end, 'Done')
  LEQ:Add(function() ReloadUI() end, 'Done')
  LEQ:Start()
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
  if subzoneName == "" then subzoneName = zoneName end
  local theInfo = {
    guildName   = guildName,
    local_x     = local_x,
    local_y     = local_y,
    zoneName    = zoneName,
    subzoneName = subzoneName,
    zoneId      = zoneId,
  }
  if GS17DataSavedVariables[internal.visitedNamespace] == nil then GS17DataSavedVariables[internal.visitedNamespace] = {} end
  if GS17DataSavedVariables[internal.visitedNamespace][guildId] == nil then GS17DataSavedVariables[internal.visitedNamespace][guildId] = {} end
  GS17DataSavedVariables[internal.visitedNamespace][guildId] = theInfo
  internal.traderIdByNameLookup[guildName] = guildId
end
