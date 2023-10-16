local lib = _G["LibGuildStore"]
local internal = _G["LibGuildStore_Internal"]

--[[ can nout use MasterMerchant.itemsViewSize for example
because that will not be available this early.
]]--
local ITEMS = 'items_vs'
local GUILDS = 'guild_vs'
local PURCHASES = 'purchases_vs'
local REPORTS = 'reports_vs'

--/script LibGuildStore_Internal:dm("Info", LibGuildStore_Internal.LibHistoireListener[622389]:GetPendingEventMetrics())
function internal:CheckStatus()
  --internal:dm("Debug", "CheckStatus")
  local maxTime = 0
  local maxEvents = 0

  for guildNum = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildNum)
    local guildName = GetGuildName(guildId)
    local numEvents = GetNumGuildEvents(guildId, GUILD_HISTORY_STORE)
    local eventCount, processingSpeed, timeLeft = internal.LibHistoireListener[guildId]:GetPendingEventMetrics()

    timeLeft = zo_floor(timeLeft)

    if (processingSpeed > 0 and timeLeft >= 0) and not internal.timeEstimated[guildId] then
      internal.timeEstimated[guildId] = true
    end

    -- Handle the case when numEvents is 0 and eventCount is 1 (inconsistent but no events)
    -- Handle the case when numEvents is greater then 0, eventCount is 0, and timeLeft is 0
    -- Example: numEvents: 0 eventCount: 1 processingSpeed: -1 timeLeft: -1
    -- Example: numEvents: 5 eventCount: 0 processingSpeed: -1 timeLeft: 0
    if (numEvents == 0 or eventCount == 0) and (processingSpeed == -1 or timeLeft == -1) then
      internal.timeEstimated[guildId] = true
      internal.eventsNeedProcessing[guildId] = false
    end

    -- Handle the case when timeLeft or eventCount is 0 (process finished)
    if (eventCount == 0 or timeLeft == 0) and internal.timeEstimated[guildId] then
      internal.eventsNeedProcessing[guildId] = false
    end

    maxTime = zo_max(maxTime, timeLeft)
    maxEvents = zo_max(maxEvents, eventCount)
    if internal.eventsNeedProcessing[guildId] and MasterMerchant.systemSavedVariables.useLibDebugLogger then
      internal:dm("Debug", string.format("%s, %s: numEvents: %s eventCount: %s processingSpeed: %s timeLeft: %s", guildName, guildId, numEvents, eventCount, processingSpeed, timeLeft))
    end

  end
  for guildNum = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildNum)
    if internal.eventsNeedProcessing[guildId] then return true, maxTime, maxEvents end
  end
  return false, maxTime, maxEvents
end

function internal:StartQueue()
  internal:dm("Debug", "StartQueue")
  internal:DatabaseBusy(true)
  zo_callLater(function() internal:QueueCheckStatus() end, ZO_ONE_MINUTE_IN_MILLISECONDS)
end

function internal:QueueCheckStatus()
  local eventsRemaining, timeRemaining, estimatedEvents = internal:CheckStatus()
  if eventsRemaining then
    zo_callLater(function() internal:QueueCheckStatus() end, ZO_ONE_MINUTE_IN_MILLISECONDS)
    internal:dm("Info", GetString(GS_REFRESH_NOT_FINISHED) .. string.format(GetString(GS_REFRESH_ESTIMATE), estimatedEvents, zo_ceil(timeRemaining / ZO_ONE_MINUTE_IN_SECONDS)))
  else
    --[[
    MasterMerchant.CenterScreenAnnounce_AddMessage(
      'LibHistoireAlert',
      CSA_CATEGORY_SMALL_TEXT,
      LibGuildStore.systemSavedVariables.alertSoundName,
      "LibHistoire Ready"
    )
    ]]--
    internal:dm("Info", GetString(GS_REFRESH_FINISHED))
    LibGuildStore_SavedVariables[internal.firstrunNamespace] = false
    LibGuildStore_SavedVariables.libHistoireScanByTimestamp = false
    internal:DatabaseBusy(false)
    MasterMerchant.listIsDirty[ITEMS] = true
    MasterMerchant.listIsDirty[GUILDS] = true
  end
end

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

function internal:SetupListenerLibHistoire()
  internal:dm("Debug", "SetupListenerLibHistoire")
  for guildIndex = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildIndex)
    internal.LibHistoireListener[guildId] = {}
    internal:QueueGuildHistoryListener(guildId, guildIndex)
  end
  if LibGuildStore_SavedVariables[internal.firstrunNamespace] then
    internal:StartQueue()
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
    LibGuildStore_SavedVariables["lastReceivedEventID"][internal.libHistoireNamespace][guildId] = "0"
    internal.eventsNeedProcessing[guildId] = true
    internal.timeEstimated[guildId] = false
  end
end

-- DEBUG RefreshLibGuildStore
function internal:RefreshLibGuildStore()
  internal:dm("Debug", "RefreshLibGuildStore")
  internal:dm("Info", GetString(GS_REFRESH_STARTING))
  internal:DatabaseBusy(true)
  LibGuildStore_SavedVariables.libHistoireScanByTimestamp = true
  for guildNum = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildNum)
    internal.LibHistoireListener[guildId]:Stop()
    LibGuildStore_SavedVariables["lastReceivedEventID"][internal.libHistoireNamespace][guildId] = "0"
    internal.eventsNeedProcessing[guildId] = true
    internal.timeEstimated[guildId] = false
  end
end

local function SetupLibHistoireContainers()
  internal:dm("Debug", "SetupLibHistoireContainers")
  for i = 1, GetNumGuilds() do
    local guildId = GetGuildId(i)
    internal.LibHistoireListener[guildId] = {}
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
  --internal:dm("Debug", "GetGuildList")
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

local function SetupDefaults()
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
  internal:dm("Debug", "SetupDefaults")
  SetNamespace()
  local systemDefault = {
    version = 2,
    [internal.GS_NA_FIRST_RUN_NAMESPACE] = true,
    [internal.GS_EU_FIRST_RUN_NAMESPACE] = true,
    lastReceivedEventID = {},
    historyDepthSL = 180, -- History Depth Shopping List
    historyDepthPI = 180, -- History Depth Posted Items
    historyDepthCI = 180, -- History Depth Canceled Items
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
    updateAdditionalText = false,
    libHistoireScanByTimestamp = false,
  }
  internal.systemDefault = systemDefault
  local savedVars = LibGuildStore_SavedVariables
  local lastEventKey = "lastReceivedEventID"
  local namespace = internal.libHistoireNamespace
  for key, _ in pairs(savedVars) do
    -- Delete key-value pair if the key can't also be found in the default settings (except for version)
    if (key ~= lastEventKey and key ~= "version") and systemDefault[key] == nil then
      savedVars[key] = nil
    end
  end

  for key, val in pairs(systemDefault) do
    if savedVars[key] == nil then savedVars[key] = val end
  end

  for guildNum = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildNum)
    savedVars[lastEventKey] = savedVars[lastEventKey] or {}
    savedVars[lastEventKey][namespace] = savedVars[lastEventKey][namespace] or {}
    savedVars[lastEventKey][namespace][guildId] = savedVars[lastEventKey][namespace][guildId] or "0"
  end

  MasterMerchant.guildList = internal:GetGuildList()

  -- set to false on startup in case previous process did not complete
  LibGuildStore_SavedVariables["updateAdditionalText"] = false

  internal:SetupGuildContainers()
  SetupLibHistoireContainers()
  SetupLibGuildStore()
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
  LEQ:addTask(function() internal:dm("Info", GetString(GS_LIBGUILDSTORE_INITIALIZING)) end, "LibGuildStoreInitializing")
  LEQ:addTask(function() BuildLookupTables() end, 'BuildLookupTables')
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
  -- and...
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
  -- and...
  LEQ:start()
end

local function LibGuildStoreInitialize()
  SetupDefaults()
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
  internal:LibAddonInit()

  if AwesomeGuildStore then
    -- register for purchace
    AwesomeGuildStore:RegisterCallback(AwesomeGuildStore.callback.ITEM_PURCHASED, function(itemData)
      local theEvent = {
        guild = itemData.guildName,
        itemLink = itemData.itemLink,
        quant = itemData.stackCount,
        timestamp = GetTimeStamp(),
        price = itemData.purchasePrice,
        seller = itemData.sellerName,
        id = Id64ToString(itemData.itemUniqueId),
        buyer = GetDisplayName()
      }
      internal:addPurchaseData(theEvent)
      MasterMerchant.listIsDirty[PURCHASES] = true
    end)

    AwesomeGuildStore:RegisterCallback(AwesomeGuildStore.callback.ITEM_DATABASE_UPDATE,
      function(itemDatabase, guildId, hasAnyResultAlreadyStored)
        internal.guildStoreSearchResults = itemDatabase
        local allData = itemDatabase.data
        internal:processAwesomeGuildStore(allData, guildId)
      end)

    AwesomeGuildStore:RegisterCallback(AwesomeGuildStore.callback.ITEM_POSTED,
      function(guildId, itemLink, price, stackCount)
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

    AwesomeGuildStore:RegisterCallback(AwesomeGuildStore.callback.ITEM_CANCELLED,
      function(guildId, itemLink, price, stackCount)
        -- opps needs the names since addCanceledItem handles the hasing
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
    AwesomeGuildStore:RegisterCallback(AwesomeGuildStore.callback.GUILD_SELECTION_CHANGED,
      function(guildData)
        if MasterMerchant.systemSavedVariables.priceCalcAll then
          MasterMerchant.systemSavedVariables.pricingData = GS17DataSavedVariables[internal.pricingNamespace]["pricingdataall"] or {}
        else
          local selectedGuildId = GetSelectedTradingHouseGuildId()
          MasterMerchant.systemSavedVariables.pricingData = GS17DataSavedVariables[internal.pricingNamespace][selectedGuildId] or {}
        end
      end)
  else
    -- for vanilla without AwesomeGuildStore to add purchace data
    EVENT_MANAGER:RegisterForEvent(lib.libName, EVENT_TRADING_HOUSE_CONFIRM_ITEM_PURCHASE, function(...) internal:onTradingHouseEvent(...) end)
  end
  --[[
    AGS.callback.BEFORE_INITIAL_SETUP = "BeforeInitialSetup"
    AGS.callback.AFTER_INITIAL_SETUP = "AfterInitialSetup"
    AGS.callback.AFTER_FILTER_SETUP = "AfterFilterSetup"

    AGS.callback.STORE_TAB_CHANGED = "StoreTabChanged"
    AGS.callback.GUILD_SELECTION_CHANGED = "SelectedGuildChanged"
    AGS.callback.AVAILABLE_GUILDS_CHANGED = "AvailableGuildsChanged"
    AGS.callback.SELECTED_SEARCH_CHANGED = "SelectedSearchChanged"
    AGS.callback.SEARCH_LIST_CHANGED = "SearchChangedChanged"
    AGS.callback.SEARCH_LOCK_STATE_CHANGED = "SearchLockStateChanged"
    AGS.callback.ITEM_DATABASE_UPDATE = "ItemDatabaseUpdated"
    AGS.callback.CURRENT_ACTIVITY_CHANGED = "CurrentActivityChanged"
    AGS.callback.SEARCH_RESULT_UPDATE = "SearchResultUpdate"
    AGS.callback.SEARCH_RESULTS_RECEIVED = "SearchResultsReceived"

    -- fires when a filter value has changed
    -- filterId, ... (filter values)
    AGS.callback.FILTER_VALUE_CHANGED = "FilterValueChanged"
    -- fires when a filter is attached or detached
    -- filter
    AGS.callback.FILTER_ACTIVE_CHANGED = "FilterActiveChanged"
    -- fires on the next frame after any filter has changed. In other words after all FILTER_VALUE_CHANGED and FILTER_ACTIVE_CHANGED callbacks have fired
    -- activeFilters
    AGS.callback.FILTER_UPDATE = "FilterUpdate"
    AGS.callback.FILTER_PREPARED = "FilterPrepared"

    AGS.callback.ITEM_PURCHASED = "ItemPurchased"
    AGS.callback.ITEM_PURCHASE_FAILED = "ItemPurchaseFailed"
    AGS.callback.ITEM_CANCELLED = "ItemCancelled"
    AGS.callback.ITEM_POSTED = "ItemPosted"
  ]]--
  SetupData()
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
  if args == 'redesc' then
    LibGuildStore_SavedVariables["updateAdditionalText"] = true
    internal:dm("Info", GetString(GS_CLEAN_UPDATE_DESC))
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

local function OnAddOnLoaded(eventCode, addonName)
  if addonName == lib.libName then
    SLASH_COMMANDS['/lgs'] = internal.Slash
    internal:dm("Debug", "LibGuildStore Loaded")
    LibGuildStoreInitialize()
  end
end

EVENT_MANAGER:RegisterForEvent(lib.libName, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
