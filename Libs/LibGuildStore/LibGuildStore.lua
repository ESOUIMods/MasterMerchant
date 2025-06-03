local lib = _G["LibGuildStore"]
local internal = _G["LibGuildStore_Internal"]

--[[ cannot use MasterMerchant.itemsViewSize for example
because that will not be available this early.
]]--
local PURCHASES = 'purchases_vs'
local REPORTS = 'reports_vs'

local function SetNamespace()
  internal:dm("Debug", "SetNamespace")
  if GetWorldName() == 'NA Megaserver' then
    internal.firstrunNamespace = internal.GS_NA_FIRST_RUN_NAMESPACE
    internal.libHistoireNamespace = internal.GS_NA_LIBHISTOIRE_NAMESPACE
    internal.dataNamespace = internal.GS_NA_NAMESPACE
    internal.listingsNamespace = internal.GS_NA_LISTING_NAMESPACE
    internal.purchasesNamespace = internal.GS_NA_PURCHASE_NAMESPACE
    internal.postedNamespace = internal.GS_NA_POSTED_NAMESPACE
    internal.cancelledNamespace = internal.GS_NA_CANCELLED_NAMESPACE
    internal.visitedNamespace = internal.GS_NA_VISIT_TRADERS_NAMESPACE
    internal.pricingNamespace = internal.GS_NA_PRICING_NAMESPACE
    internal.nameFilterNamespace = internal.GS_NA_NAME_FILTER_NAMESPACE
    internal.guildListNamespace = internal.GS_NA_GUILD_LIST_NAMESPACE
  else
    internal.firstrunNamespace = internal.GS_EU_FIRST_RUN_NAMESPACE
    internal.libHistoireNamespace = internal.GS_EU_LIBHISTOIRE_NAMESPACE
    internal.dataNamespace = internal.GS_EU_NAMESPACE
    internal.listingsNamespace = internal.GS_EU_LISTING_NAMESPACE
    internal.purchasesNamespace = internal.GS_EU_PURCHASE_NAMESPACE
    internal.postedNamespace = internal.GS_EU_POSTED_NAMESPACE
    internal.cancelledNamespace = internal.GS_EU_CANCELLED_NAMESPACE
    internal.visitedNamespace = internal.GS_EU_VISIT_TRADERS_NAMESPACE
    internal.pricingNamespace = internal.GS_EU_PRICING_NAMESPACE
    internal.nameFilterNamespace = internal.GS_EU_NAME_FILTER_NAMESPACE
    internal.guildListNamespace = internal.GS_EU_GUILD_LIST_NAMESPACE
  end
end

--[[
internal.GS_NA_NAMESPACE          = "datana"
internal.GS_EU_NAMESPACE          = "dataeu"
internal.GS_NA_LIBHISTOIRE_NAMESPACE = "libhistoirena"
internal.GS_EU_LIBHISTOIRE_NAMESPACE = "libhistoireeu"
internal.GS_NA_LISTING_NAMESPACE  = "listingsna"
internal.GS_EU_LISTING_NAMESPACE  = "listingseu"
internal.GS_NA_PURCHASE_NAMESPACE = "purchasena"
internal.GS_EU_PURCHASE_NAMESPACE = "purchaseeu"
internal.GS_NA_NAME_FILTER_NAMESPACE = "namefilterna"
internal.GS_EU_NAME_FILTER_NAMESPACE = "namefiltereu"
internal.GS_NA_FIRST_RUN_NAMESPACE = "firstRunNa"
internal.GS_EU_FIRST_RUN_NAMESPACE = "firstRunEu"

internal.GS_NA_POSTED_NAMESPACE  = "posteditemsna"
internal.GS_EU_POSTED_NAMESPACE  = "posteditemseu"
internal.GS_NA_CANCELLED_NAMESPACE = "cancelleditemsna"
internal.GS_EU_CANCELLED_NAMESPACE = "cancelleditemseu"

internal.GS_NA_VISIT_TRADERS_NAMESPACE = "visitedNATraders"
internal.GS_EU_VISIT_TRADERS_NAMESPACE = "visitedEUTraders"

internal.GS_NA_PRICING_NAMESPACE = "pricingdatana"
internal.GS_EU_PRICING_NAMESPACE = "pricingdataeu"

internal.GS_NA_GUILD_LIST_NAMESPACE = "currentNAGuilds"
internal.GS_EU_GUILD_LIST_NAMESPACE = "currentEUGuilds"
]]--
local function SetupDefaults()
  internal:dm("Debug", "SetupDefaults")
  local systemDefault = {
    version = 2,
    [internal.GS_NA_FIRST_RUN_NAMESPACE] = true,
    [internal.GS_EU_FIRST_RUN_NAMESPACE] = true,
    historyDepthShoppingList = 180,
    historyDepthPostedItems = 180,
    historyDepthCanceledItems = 180,
    minimalIndexing = false,
    historyDepth = 90,
    minItemCount = 20,
    maxItemCount = 5000,
    minSalesInterval = 0,
    showIndexingSummary = false,
    showTruncateSummary = false,
    showGuildInitSummary = false,
    useSalesHistory = true,
    overrideMMImport = false,
    libHistoireScanByTimestamp = false,
    convertLegacyId64Completed = false,

    -- Simple tracking variables for testing
    newestTrackedTimestamp = {},
    oldestTrackedTimestamp = {},
    newestTrackedEventID = {},
    oldestTrackedEventID = {},
    trackedMidnightEventID = {},
  }

  internal.systemDefault = systemDefault
end

local function InitializeSavedVariables()
  -- Initialize savedVars
  local savedVars = LibGuildStore_SavedVariables

  -- Ensure LibGuildStore_SavedVariables is initialized
  if not savedVars or not savedVars.version then
    -- New user setup: Initialize with default values
    savedVars = {}
    savedVars.version = internal.systemDefault.version
    savedVars.convertLegacyId64Completed = true -- New user, skip conversion
  else
    -- Existing user: Check and initialize missing fields
    if savedVars.convertLegacyId64Completed == nil then
      savedVars.convertLegacyId64Completed = false -- Conversion required
    end
  end

  -- Clean up savedVars by removing keys not in systemDefault
  for key, _ in pairs(savedVars) do
    if key ~= "version" and internal.systemDefault[key] == nil then
      savedVars[key] = nil
    end
  end

  -- Populate missing default values from systemDefault
  for key, val in pairs(internal.systemDefault) do
    if savedVars[key] == nil then
      savedVars[key] = val
    end
  end

  -- Save back to global variable
  LibGuildStore_SavedVariables = savedVars
end

local function SetupTradingHouseCallbacks()
  if AwesomeGuildStore then
    -- Register callback for item purchased
    AwesomeGuildStore:RegisterCallback(AwesomeGuildStore.callback.ITEM_PURCHASED, function(itemData)
      local theEvent = {
        guild = itemData.guildName,
        itemLink = itemData.itemLink,
        quant = itemData.stackCount,
        timestamp = GetTimeStamp(),
        price = itemData.purchasePrice,
        seller = itemData.sellerName,
        id = Id64ToString(itemData.itemUniqueId),
        buyer = GetDisplayName(),
      }
      internal:addPurchaseData(theEvent)
      MasterMerchant.listIsDirty[PURCHASES] = true
    end)

    -- Register callback for item posted
    AwesomeGuildStore:RegisterCallback(AwesomeGuildStore.callback.ITEM_POSTED, function(guildId, itemLink, price, stackCount)
      local theEvent = {
        guild = GetGuildName(guildId),
        itemLink = itemLink,
        quant = stackCount,
        timestamp = GetTimeStamp(),
        price = price,
        seller = GetDisplayName(),
      }
      internal:addPostedItem(theEvent)
      MasterMerchant.listIsDirty[REPORTS] = true
    end)

    -- Register callback for item cancelled
    AwesomeGuildStore:RegisterCallback(AwesomeGuildStore.callback.ITEM_CANCELLED, function(guildId, itemLink, price, stackCount)
      local theEvent = {
        guild = GetGuildName(guildId),
        itemLink = itemLink,
        quant = stackCount,
        timestamp = GetTimeStamp(),
        price = price,
        seller = GetDisplayName(),
      }
      internal:addCancelledItem(theEvent)
      MasterMerchant.listIsDirty[REPORTS] = true
    end)

    -- Register callback for database update
    AwesomeGuildStore:RegisterCallback(AwesomeGuildStore.callback.ITEM_DATABASE_UPDATE, function(itemDatabase, guildId, hasAnyResultAlreadyStored)
      internal.guildStoreSearchResults = itemDatabase
      local allData = itemDatabase.data
      internal:processAwesomeGuildStore(allData, guildId)
    end)

    -- Register callback for guild selection changed
    AwesomeGuildStore:RegisterCallback(AwesomeGuildStore.callback.GUILD_SELECTION_CHANGED, function(guildData)
      if MasterMerchant.systemSavedVariables.priceCalcAll then
        MasterMerchant.systemSavedVariables.pricingData = GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"] or {}
      else
        local selectedGuildId = GetSelectedTradingHouseGuildId()
        MasterMerchant.systemSavedVariables.pricingData = GS17DataSavedVariables[internal.pricingNamespace][selectedGuildId] or {}
      end
    end)
  else
    -- Fallback for vanilla without AwesomeGuildStore
    EVENT_MANAGER:RegisterForEvent(lib.libName, EVENT_TRADING_HOUSE_CONFIRM_ITEM_PURCHASE, function(...)
      internal:onTradingHouseEvent(...)
    end)
  end
end

local function SetupLibGuildStore()
  if not LibGuildStore_SavedVariables[internal.firstrunNamespace] then
    internal:dm("Debug", "SetupLibGuildStore Not First Run")
    return
  end
  internal:dm("Debug", "SetupLibGuildStore For First Run")
  LibGuildStore_SavedVariables.libHistoireScanByTimestamp = true
  internal.isDatabaseBusy = true
  for guildNum = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildNum)
    internal.eventsNeedProcessing[guildId] = true
    internal.timeEstimated[guildId] = false
  end
end

function internal:SetupGuildContainers()
  internal:dm("Debug", "SetupGuildContainers")
  local guildListNamespace = GS17DataSavedVariables[internal.guildListNamespace]

  function initializeGuildsTable(guildsTable)
    guildsTable = guildsTable or {}
    guildsTable["count"] = guildsTable["count"] or 0
    guildsTable["guilds"] = guildsTable["guilds"] or {}
    return guildsTable
  end

  guildListNamespace = initializeGuildsTable(guildListNamespace)

  local function guildExists(guildName)
    local guilds = guildListNamespace["guilds"]
    local count = guildListNamespace["count"]

    if count == 0 then
      return false
    end

    local totalCount = NonContiguousCount(guilds)
    for i = 1, totalCount do
      local currentGuild = guilds[i]
      if currentGuild and currentGuild.guildName == guildName then
        return true
      end
    end

    return false
  end

  for guildNum = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildNum)
    local guildName = GetGuildName(guildId)
    if not guildExists(guildName) then
      guildListNamespace["count"] = guildListNamespace["count"] + 1
      local count = guildListNamespace["count"]
      guildListNamespace["guilds"][count] = { guildId = guildId, guildName = guildName }
    end
  end

  GS17DataSavedVariables[internal.guildListNamespace] = guildListNamespace
end

function internal:GetGuildListAll()
  internal:dm("Debug", "GetGuildListAll")
  if GS17DataSavedVariables[internal.guildListNamespace]["count"] == 0 then return { } end
  local guildList = ''
  for guildNum, data in pairs(GS17DataSavedVariables[internal.guildListNamespace]["guilds"]) do
    guildList = guildList .. data.guildName .. ', '
  end
  return guildList
end

-- /script d(LibGuildStore_Internal:GetGuildList())
-- /script d(zo_plainstrfind(LibGuildStore_Internal:GetGuildList(), "Real Guild Best Guild"))
function internal:GetGuildList()
  internal:dm("Debug", "GetGuildList")
  local guildList = ''
  for guildNum = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildNum)
    local guildName = GetGuildName(guildId)
    guildList = guildList .. guildName .. ', '
  end
  return guildList
end

local function BuildLookupTables()
  -- Build lookup tables
  internal:BuildAccountNameLookup()
  internal:BuildItemLinkNameLookup()
  internal:BuildGuildNameLookup()
  internal:BuildTraderNameLookup()
end

local function SetupData()
  internal:dm("Debug", "SetupData")
  local LEQ = LibExecutionQueue:new()
  LibExecutionQueue:addTask(function() internal:dm("Info", GetString(GS_LIBGUILDSTORE_INITIALIZING)) end, "LibGuildStoreInitializing")
  LEQ:addTask(function() internal:dm("Info", GetString(GS_LIBGUILDSTORE_REFERENCE_DATA)) end, "LibGuildStoreReferenceDataContainers")
  -- Place data into containers
  LEQ:addTask(function() internal:ReferenceSalesDataContainer() end, 'ReferenceSalesDataContainer')
  LEQ:addTask(function() internal:ReferenceListingsDataContainer() end, 'ReferenceListingsDataContainer')
  LEQ:addTask(function() internal:ReferencePurchaseDataContainer() end, 'ReferencePurchaseDataContainer')
  LEQ:addTask(function() internal:ReferencePostedItemsDataContainer() end, 'ReferencePostedItemsDataContainer')
  LEQ:addTask(function() internal:ReferenceCancelledItemDataContainer() end, 'ReferenceCancelledItemDataContainer')
  -- AddNewData, which adds counts
  LEQ:addTask(function() internal:AddExtraSalesDataAllContainers() end, 'AddExtraSalesDataAllContainers')
  LEQ:addTask(function() internal:AddExtraListingsDataAllContainers() end, 'AddExtraListingsDataAllContainers')
  LEQ:addTask(function() internal:AddExtraPurchaseData() end, 'AddExtraPurchaseData')
  LEQ:addTask(function() internal:AddExtraPostedData() end, 'AddExtraPostedData')
  LEQ:addTask(function() internal:AddExtraCancelledData() end, 'AddExtraCancelledData')
  -- Truncate
  if not LibGuildStore_SavedVariables["showGuildInitSummary"] then
    LEQ:addTask(function() internal:dm("Info", GetString(GS_LIBGUILDSTORE_TRUNCATE)) end, "LibGuildStoreReferenceTables")
  end
  LEQ:addTask(function() internal:TruncateSalesHistory() end, 'TruncateSalesHistory')
  LEQ:addTask(function() internal:TruncateListingsHistory() end, 'TruncateListingsHistory')
  LEQ:addTask(function() internal:TruncatePurchaseHistory() end, 'TruncatePurchaseHistory')
  LEQ:addTask(function() internal:TruncatePostedItemsHistory() end, 'TruncatePostedItemsHistory')
  LEQ:addTask(function() internal:TruncateCancelledItemHistory() end, 'TruncateCancelledItemHistory')
  -- RenewExtraData, if was altered
  LEQ:addTask(function() internal:RenewExtraSalesDataAllContainers() end, 'RenewExtraSalesDataAllContainers')
  LEQ:addTask(function() internal:RenewExtraListingsDataAllContainers() end, 'RenewExtraListingsDataAllContainers')
  LEQ:addTask(function() internal:RenewExtraPurchaseData() end, 'RenewExtraPurchaseData')
  LEQ:addTask(function() internal:RenewExtraPostedData() end, 'RenewExtraPostedData')
  LEQ:addTask(function() internal:RenewExtraCancelledData() end, 'RenewExtraCancelledData')

  if not LibGuildStore_SavedVariables["showGuildInitSummary"] then
    LEQ:addTask(function() internal:dm("Info", GetString(GS_LIBGUILDSTORE_HISTORY_INIT)) end, "LibGuildStoreReferenceTables")
  end
  LEQ:addTask(function() internal:InitSalesHistory() end, 'InitSalesHistory')
  LEQ:addTask(function() internal:InitListingHistory() end, 'InitListingHistory')
  LEQ:addTask(function() internal:InitPurchaseHistory() end, 'InitPurchaseHistory')
  LEQ:addTask(function() internal:InitPostedItemsHistory() end, 'InitPostedItemsHistory')
  LEQ:addTask(function() internal:InitCancelledItemsHistory() end, 'InitCancelledItemsHistory')
  -- Index Data, like sr_index
  if LibGuildStore_SavedVariables["minimalIndexing"] then
    LEQ:addTask(function() internal:dm("Info", GetString(GS_MINIMAL_INDEXING)) end, "LibGuildStoreIndexData")
  else
    LEQ:addTask(function() internal:dm("Info", GetString(GS_FULL_INDEXING)) end, "LibGuildStoreIndexData")
  end
  LEQ:addTask(function() internal:IndexSalesData() end, 'IndexSalesData')
  LEQ:addTask(function() internal:IndexListingsData() end, 'IndexListingsData')
  LEQ:addTask(function() internal:IndexPurchaseData() end, 'IndexPurchaseData')
  LEQ:addTask(function() internal:IndexPostedItemsData() end, 'IndexPostedItemsData')
  LEQ:addTask(function() internal:IndexCancelledItemData() end, 'IndexCancelledItemData')

  LEQ:addTask(function() lib.guildStoreReady = true end, "LibGuildStoreIndexData")
  LEQ:addTask(function() internal:FireCallbackLibGuildStoreReady() end, "LibGuildStoreIndexData")
  -- and...
  LEQ:start()
end

function internal:ProcessLibGuildStoreData()
  SetupData()
end

function internal:FireCallbackProcessLibGuildstoreData()
  internal:dm("Debug", "Fire LMD Callback PROCESS_LIBGUILDSTORE_DATA")
  internal.callbackObject:FireCallbacks(internal.callbackType.PROCESS_LIBGUILDSTORE_DATA)
end

function internal:FireCallbackLibGuildStoreReady()
  internal:dm("Debug", "Fire LMD Callback LIBGUILDSTORE_READY")
  internal.callbackObject:FireCallbacks(internal.callbackType.LIBGUILDSTORE_READY)
end

local function LibGuildStoreInitialize()
  internal.guildList = internal:GetGuildList()
  internal:SetupGuildContainers()
  internal:SetupLibHistoireContainers()
  SetupLibGuildStore()
  internal:LibAddonInit()
  SetupTradingHouseCallbacks()
  internal:RegisterCallback(internal.callbackType.PROCESS_LIBGUILDSTORE_DATA,
    function()
      internal:ProcessLibGuildStoreData()
    end)
  BuildLookupTables()

  for i = 1, GetNumGuilds() do
    local guildId = GetGuildId(i)
    local guildName = GetGuildName(guildId)
    internal.currentGuilds[guildId] = guildName
    internal.alertQueue[guildName] = {}
    for m = 1, GetNumGuildMembers(guildId) do
      local name, _, _, _, _ = GetGuildMemberInfo(guildId, m)
      if internal.guildMemberInfo[guildId] == nil then internal.guildMemberInfo[guildId] = {} end
      internal.guildMemberInfo[guildId][zo_strlower(name)] = true
    end
  end
  internal:ConvertLegacyEventIds()
end

local function CheckImportStatus()
  local naDetected = false
  local euDetected = false
  local dataLocale = MM00DataSavedVariables.Default.MasterMerchant["$AccountWide"].dataLocations
  if dataLocale and dataLocale["NA Megaserver"] then naDetected = true end
  if dataLocale and dataLocale["EU Megaserver"] then euDetected = true end

  if naDetected and euDetected then return true end
  return false
end

local function CheckServerImportType()
  local naDetected = false
  local euDetected = false
  local dataLocale = MM00DataSavedVariables.Default.MasterMerchant["$AccountWide"].dataLocations
  if dataLocale and dataLocale["NA Megaserver"] then naDetected = true end
  if dataLocale and dataLocale["EU Megaserver"] then euDetected = true end

  if internal.dataNamespace == internal.GS_NA_NAMESPACE and euDetected then return true end
  if internal.dataNamespace == internal.GS_EU_NAMESPACE and naDetected then return true end
  return false
end

function internal:CheckMasterMerchantData()
  local mmDataSavedVariablesList = {
    MM00DataSavedVariables, MM01DataSavedVariables, MM02DataSavedVariables,
    MM03DataSavedVariables, MM04DataSavedVariables, MM05DataSavedVariables,
    MM06DataSavedVariables, MM07DataSavedVariables, MM08DataSavedVariables,
    MM09DataSavedVariables, MM10DataSavedVariables, MM11DataSavedVariables,
    MM12DataSavedVariables, MM13DataSavedVariables, MM14DataSavedVariables,
    MM15DataSavedVariables
  }

  for _, mmDataSavedVariables in ipairs(mmDataSavedVariablesList) do
    if mmDataSavedVariables then
      return false
    end
  end

  return true
end

function internal:CheckArkadiusData()
  local arkadiusSalesDataList = {
    ArkadiusTradeToolsSalesData01, ArkadiusTradeToolsSalesData02, ArkadiusTradeToolsSalesData03,
    ArkadiusTradeToolsSalesData04, ArkadiusTradeToolsSalesData05, ArkadiusTradeToolsSalesData06,
    ArkadiusTradeToolsSalesData07, ArkadiusTradeToolsSalesData08, ArkadiusTradeToolsSalesData09,
    ArkadiusTradeToolsSalesData10, ArkadiusTradeToolsSalesData11, ArkadiusTradeToolsSalesData12,
    ArkadiusTradeToolsSalesData13, ArkadiusTradeToolsSalesData14, ArkadiusTradeToolsSalesData15,
    ArkadiusTradeToolsSalesData16
  }

  for _, salesData in ipairs(arkadiusSalesDataList) do
    if salesData then
      return false
    end
  end

  return true
end

function internal:MasterMerchantDataActive()
  local mmDataSavedVariablesList = {
    MM00DataSavedVariables, MM01DataSavedVariables, MM02DataSavedVariables,
    MM03DataSavedVariables, MM04DataSavedVariables, MM05DataSavedVariables,
    MM06DataSavedVariables, MM07DataSavedVariables, MM08DataSavedVariables,
    MM09DataSavedVariables, MM10DataSavedVariables, MM11DataSavedVariables,
    MM12DataSavedVariables, MM13DataSavedVariables, MM14DataSavedVariables,
    MM15DataSavedVariables
  }

  for _, mmData in ipairs(mmDataSavedVariablesList) do
    if mmData then
      return true
    end
  end

  return false
end

function internal:ArkadiusDataActive()
  local arkadiusDataSavedVariablesList = {
    ArkadiusTradeToolsSalesData01, ArkadiusTradeToolsSalesData02, ArkadiusTradeToolsSalesData03,
    ArkadiusTradeToolsSalesData04, ArkadiusTradeToolsSalesData05, ArkadiusTradeToolsSalesData06,
    ArkadiusTradeToolsSalesData07, ArkadiusTradeToolsSalesData08, ArkadiusTradeToolsSalesData09,
    ArkadiusTradeToolsSalesData10, ArkadiusTradeToolsSalesData11, ArkadiusTradeToolsSalesData12,
    ArkadiusTradeToolsSalesData13, ArkadiusTradeToolsSalesData14, ArkadiusTradeToolsSalesData15,
    ArkadiusTradeToolsSalesData16
  }

  for _, arkadiusData in ipairs(arkadiusDataSavedVariablesList) do
    if arkadiusData then
      return true
    end
  end

  return false
end

function internal:SlashImportMMSales()
  if internal.isDatabaseBusy then
    internal:dm("Info", GetString(GS_LIBGUILDSTORE_BUSY))
    return
  end
  if internal:CheckMasterMerchantData() then
    internal:dm("Info", GetString(GS_MM_MISSING))
    return
  end
  if CheckImportStatus() and not LibGuildStore_SavedVariables.overrideMMImport then
    internal:dm("Info", GetString(GS_MM_EU_NA_IMPORT_WARN))
    return
  end
  if CheckServerImportType() and not LibGuildStore_SavedVariables.overrideMMImport then
    internal:dm("Info", GetString(GS_MM_EU_NA_DIFFERENT_SERVER_WARN))
    return
  end
  internal:dm("Info", GetString(GS_IMPORTING_MM_SALES))
  local LEQ = LibExecutionQueue:new()
  LEQ:addTask(function() internal:ReferenceAllMMSales() end, 'ReferenceAllMMSales')
  LEQ:addTask(function() internal:ImportMasterMerchantSales() end, 'ImportMasterMerchantSales')
  LEQ:start()
end

function internal:SlashImportATTSales()
  if internal.isDatabaseBusy then
    internal:dm("Info", GetString(GS_LIBGUILDSTORE_BUSY))
    return
  end
  if internal:CheckArkadiusData() then
    internal:dm("Info", GetString(GS_ATT_MISSING))
    return
  end
  internal:dm("Info", GetString(GS_IMPORTING_ATT_SALES))
  local LEQ = LibExecutionQueue:new()
  LEQ:addTask(function() internal:ReferenceAllATTSales() end, 'ReferenceAllATTSales')
  LEQ:addTask(function() internal:ImportATTSales() end, 'ImportATTSales')
  LEQ:start()
end

function internal.Slash(allArgs)
  local args = ""
  local guildNumber = 0
  local hoursBack = 0
  local argNum = 0
  for w in zo_strgmatch(allArgs, "%w+") do
    argNum = argNum + 1
    if argNum == 1 then args = w end
    if argNum == 2 then guildNumber = tonumber(w) end
    if argNum == 3 then hoursBack = tonumber(w) end
  end
  args = zo_strlower(args)

  if args == 'help' then
    internal:dm("Info", GetString(GS_HELP_DUPS))
    internal:dm("Info", GetString(GS_HELP_CLEAN))
    internal:dm("Info", GetString(GS_HELP_SLIDE))
    internal:dm("Info", GetString(GS_HELP_MMIMPORT))
    internal:dm("Info", GetString(GS_HELP_ATTIMPORT))
    return
  end
  if args == 'dups' or args == 'stilldups' then
    if internal.isDatabaseBusy then
      if args == 'dups' then internal:dm("Info", GetString(GS_PURGING_DUPLICATES_DELAY)) end
      zo_callLater(function() internal.Slash('stilldups') end, 10000)
      return
    end
    internal:PurgeDups()
    return
  end
  if args == 'slide' or args == 'stillslide' then
    if internal.isDatabaseBusy then
      if args ~= 'stillslide' then internal:dm("Info", GetString(GS_SLIDING_SALES_DELAY)) end
      zo_callLater(function() internal.Slash('stillslide') end, 10000)
      return
    end
    internal:dm("Info", GetString(GS_SLIDING_SALES))
    internal:SlideSales(false)
    return
  end

  if args == 'slideback' or args == 'stillslideback' then
    if internal.isDatabaseBusy then
      if args ~= 'stillslideback' then internal:dm("Info", GetString(GS_SLIDING_SALES_DELAY)) end
      zo_callLater(function() internal.Slash('stillslideback') end, 10000)
      return
    end
    internal:dm("Info", GetString(GS_SLIDING_SALES))
    internal:SlideSales(true)
    return
  end

  if args == 'clean' or args == 'stillclean' then
    if internal.isDatabaseBusy then
      if args == 'clean' then internal:dm("Info", GetString(GS_CLEAN_START_DELAY)) end
      zo_callLater(function() internal.Slash('stillclean') end, 10000)
      return
    end
    internal:dm("Info", GetString(GS_CLEAN_START))
    internal:CleanOutBad()
    return
  end
  if args == 'mmimport' then
    internal:SlashImportMMSales()
    return
  end
  if args == 'attimport' then
    internal:SlashImportATTSales()
    return
  end
  --[[TODO Why is there the need for an empty space here? ]]--
  args = MM_STRING_EMPTY
end

local function OnGuildMemberAdded(eventCode, guildId, displayName)
  if internal.guildMemberInfo[guildId] == nil then internal.guildMemberInfo[guildId] = {} end
  internal.guildMemberInfo[guildId][zo_strlower(displayName)] = true
end
EVENT_MANAGER:RegisterForEvent(lib.libName .. "_MemberAdded", EVENT_GUILD_MEMBER_ADDED, OnGuildMemberAdded)

local function OnGuildMemberRemoved(eventCode, guildId, displayName, characterName)
  if internal.guildMemberInfo[guildId] == nil then internal.guildMemberInfo[guildId] = {} end
  internal.guildMemberInfo[guildId][zo_strlower(displayName)] = nil
end
EVENT_MANAGER:RegisterForEvent(lib.libName .. "_MemberRemoved", EVENT_GUILD_MEMBER_REMOVED, OnGuildMemberRemoved)

-- LibGuildStore_Internal
local function OnPlayerJoinedGuild(eventCode, guildId, guildName)
  --MasterMerchant:dm("Debug", "OnPlayerJoinedGuild")
  internal:SetupGuildContainers()
  internal.guildList = internal:GetGuildList()
  internal.LibHistoireListener[guildId] = { }
  internal.eventsNeedProcessing[guildId] = true
  internal.timeEstimated[guildId] = false
  internal.currentGuilds[guildId] = guildName
  internal.alertQueue[guildName] = {}
  for m = 1, GetNumGuildMembers(guildId) do
    local name, _, _, _, _ = GetGuildMemberInfo(guildId, m)
    if internal.guildMemberInfo[guildId] == nil then internal.guildMemberInfo[guildId] = {} end
    internal.guildMemberInfo[guildId][zo_strlower(name)] = true
  end

  internal.LibHistoireListenerReady[guildId] = false
  internal:QueueGuildHistoryListener(guildId, nil)
end
EVENT_MANAGER:RegisterForEvent(lib.libName .. "_JoinedGuild", EVENT_GUILD_SELF_JOINED_GUILD, OnPlayerJoinedGuild)

local function OnPlayerLeaveGuild(eventCode, guildId, guildName)
  --MasterMerchant:dm("Debug", "OnPlayerLeaveGuild")
  if internal.LibHistoireListener[guildId] ~= nil and internal.LibHistoireListener[guildId].running then
    MasterMerchant:dm("Debug", "Stopping listener")
    internal.LibHistoireListener[guildId]:Stop()
  end
  internal.guildList = internal:GetGuildList()
  internal.eventsNeedProcessing[guildId] = nil
  internal.timeEstimated[guildId] = nil
  internal.LibHistoireListener[guildId] = nil
  internal.currentGuilds[guildId] = nil
  internal.alertQueue[guildName] = nil
  internal.guildMemberInfo[guildId] = nil
end
EVENT_MANAGER:RegisterForEvent(lib.libName .. "_LeaveGuild", EVENT_GUILD_SELF_LEFT_GUILD, OnPlayerLeaveGuild)

local function OnAddOnLoaded(eventCode, addonName)
  if addonName == lib.libName then
    SLASH_COMMANDS['/lgs'] = internal.Slash
    internal:dm("Debug", "LibGuildStore Loaded")
    SetNamespace()
    SetupDefaults()
    InitializeSavedVariables()

    LibGuildStoreInitialize()
  end
end
EVENT_MANAGER:RegisterForEvent(lib.libName, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
