local lib           = _G["LibGuildStore"]
local internal      = _G["LibGuildStore_Internal"]
local sales_data    = _G["LibGuildStore_SalesData"]
local listings_data = _G["LibGuildStore_ListingsData"]
local sr_index      = _G["LibGuildStore_SalesIndex"]

--/script LibGuildStore_Internal:dm("Info", LibGuildStore_Internal.LibHistoireListener[622389]:GetPendingEventMetrics())
function internal:CheckStatus()
  --internal:dm("Debug", "CheckStatus")
  for guildNum = 1, GetNumGuilds() do
    local guildId                               = GetGuildId(guildNum)
    local guildName                             = GetGuildName(guildId)
    local numEvents                             = GetNumGuildEvents(guildId, GUILD_HISTORY_STORE)
    local eventCount, processingSpeed, timeLeft = internal.LibHistoireListener[guildId]:GetPendingEventMetrics()

    timeLeft                                    = math.floor(timeLeft)

    if timeLeft ~= -1 or processingSpeed ~= -1 then internal.timeEstimated[guildId] = true end

    if (numEvents == 0 and eventCount == 1 and processingSpeed == -1 and timeLeft == -1) then
      internal.timeEstimated[guildId]        = true
      internal.eventsNeedProcessing[guildId] = false
    end

    if eventCount == 0 and internal.timeEstimated[guildId] then internal.eventsNeedProcessing[guildId] = false end

    if timeLeft == 0 and internal.timeEstimated[guildId] then internal.eventsNeedProcessing[guildId] = false end

    --[[
    if internal.eventsNeedProcessing[guildId] then
      internal:dm("Debug", string.format("%s: numEvents: %s eventCount: %s processingSpeed: %s timeLeft: %s", guildName, numEvents, eventCount, processingSpeed, timeLeft))
    end
    ]]--

  end
  for guildNum = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildNum)
    if internal.eventsNeedProcessing[guildId] then return true end
  end
  return false
end

function internal:QueueCheckStatus()
  local eventsRemaining = internal:CheckStatus()
  if eventsRemaining then
    zo_callLater(function() internal:QueueCheckStatus() end, 60000) -- 60000 1 minute
    internal:dm("Info", "LibGuildStore Refresh Not Finished Yet")
  else
    --[[
    MasterMerchant.CenterScreenAnnounce_AddMessage(
      'LibHistoireAlert',
      CSA_EVENT_SMALL_TEXT,
      LibGuildStore.systemSavedVariables.alertSoundName,
      "LibHistoire Ready"
    )
    ]]--
    internal:dm("Info", "LibGuildStore Refresh Finished")
    lib.guildStoreReady                                      = true
    LibGuildStore_SavedVariables[internal.firstrunNamespace] = false
  end
end

local function SetNamespace()
  if GetWorldName() == 'NA Megaserver' then
    internal.dataNamespace     = internal.GS_NA_NAMESPACE
    internal.listingsNamespace = "listingsna"
    internal.firstrunNamespace = "firstRunNa"
  else
    internal.dataNamespace     = internal.GS_EU_NAMESPACE
    internal.listingsNamespace = "listingseu"
    internal.firstrunNamespace = "firstRunEu"
  end
end

function internal:SetupListenerLibHistoire()
  internal:dm("Debug", "SetupListenerLibHistoire")
  for i = 1, GetNumGuilds() do
    local guildId                         = GetGuildId(i)
    internal.LibHistoireListener[guildId] = {}
    internal:SetupListener(guildId)
  end
end

local function SetupLibGuildStore()
  internal:dm("Debug", "SetupLibGuildStore For First Run")
  for guildNum = 1, GetNumGuilds() do
    local guildId                                                = GetGuildId(guildNum)
    LibGuildStore_SavedVariables["lastReceivedEventID"][guildId] = "0"
    internal.eventsNeedProcessing[guildId]                       = true
    internal.timeEstimated[guildId]                              = false
  end
end

function internal:RefreshLibGuildStore()
  internal:dm("Debug", "RefreshLibGuildStore")
  for guildNum = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildNum)
    internal.LibHistoireListener[guildId]:Stop()
    LibGuildStore_SavedVariables["lastReceivedEventID"][guildId] = "0"
    internal.eventsNeedProcessing[guildId]                       = true
    internal.timeEstimated[guildId]                              = false
  end
end

local function SetupDefaults()
  internal:dm("Debug", "SetupDefaults")
  if LibGuildStore_SavedVariables["firstRunNa"] == nil then LibGuildStore_SavedVariables["firstRunNa"] = true end
  if LibGuildStore_SavedVariables["firstRunEu"] == nil then LibGuildStore_SavedVariables["firstRunEu"] = true end
  if LibGuildStore_SavedVariables["updateAdditionalText"] == nil then LibGuildStore_SavedVariables["updateAdditionalText"] = internal.defaults.updateAdditionalText end
  if LibGuildStore_SavedVariables["historyDepth"] == nil then LibGuildStore_SavedVariables["historyDepth"] = internal.defaults.historyDepth end
  if LibGuildStore_SavedVariables["minItemCount"] == nil then LibGuildStore_SavedVariables["minItemCount"] = internal.defaults.minItemCount end
  if LibGuildStore_SavedVariables["maxItemCount"] == nil then LibGuildStore_SavedVariables["maxItemCount"] = internal.defaults.maxItemCount end
  if LibGuildStore_SavedVariables["showGuildInitSummary"] == nil then LibGuildStore_SavedVariables["showGuildInitSummary"] = internal.defaults.showGuildInitSummary end
  if LibGuildStore_SavedVariables["showIndexingSummary"] == nil then LibGuildStore_SavedVariables["showIndexingSummary"] = internal.defaults.showIndexingSummary end
  if LibGuildStore_SavedVariables["minimalIndexing"] == nil then LibGuildStore_SavedVariables["minimalIndexing"] = internal.defaults.minimalIndexing end
  if LibGuildStore_SavedVariables["useSalesHistory"] == nil then LibGuildStore_SavedVariables["useSalesHistory"] = internal.defaults.useSalesHistory end

  SetNamespace()
end

local function BuildLookupTables()
  internal:dm("Debug", "BuildLookupTables")
  -- Build lookup tables
  internal:BuildAccountNameLookup()
  internal:BuildItemLinkNameLookup()
  internal:BuildGuildNameLookup()
end

local function SetupData()
  internal:dm("Debug", "SetupData")
  local LEQ = LibExecutionQueue:new()
  LEQ:Add(function() BuildLookupTables() end, 'BuildLookupTables')
  LEQ:Add(function() internal:dm("Info", "LibGuildStore Initializing") end, "LibGuildStoreInitializing")
  LEQ:Add(function() internal:ReferenceSalesAllContainers() end, 'ReferenceSalesAllContainers')
  LEQ:Add(function() internal:ReferenceAllMMSales() end, 'ReferenceAllMMSales')
  LEQ:Add(function() internal:ReferenceAllATTSales() end, 'ReferenceAllATTSales')
  LEQ:Add(function() internal:AddNewDataAllContainers() end, 'AddNewDataAllContainers')
  LEQ:Add(function() internal:TruncateHistory() end, 'TruncateHistory')
  LEQ:Add(function() internal:RenewExtraDataAllContainers() end, 'RenewExtraDataAllContainers')
  LEQ:Add(function() internal:InitItemHistory() end, 'InitItemHistory')
  LEQ:Add(function() internal:indexHistoryTables() end, 'indexHistoryTables')
  LEQ:Add(function() internal:SetupListenerLibHistoire() end, 'SetupListenerLibHistoire')
  LEQ:Start()
end

local function Initilizze()
  SetupDefaults()
  for i = 1, GetNumGuilds() do
    local guildId   = GetGuildId(i)
    local guildName = GetGuildName(guildId)
    if not LibGuildStore_SavedVariables["lastReceivedEventID"][guildId] then LibGuildStore_SavedVariables["lastReceivedEventID"][guildId] = "0" end
    internal.alertQueue[guildName] = {}
    for m = 1, GetNumGuildMembers(guildId) do
      local guildMemInfo, _, _, _, _ = GetGuildMemberInfo(guildId, m)
      if internal.guildMemberInfo[guildId] == nil then internal.guildMemberInfo[guildId] = {} end
      internal.guildMemberInfo[guildId][string.lower(guildMemInfo)] = true
    end
  end
  if LibGuildStore_SavedVariables[internal.firstrunNamespace] then
    SetupLibGuildStore()
    zo_callLater(function() internal:QueueCheckStatus() end, 60000) -- 60000 1 minute
  end
  SetupData()

  internal:LibAddonInit()

  if AwesomeGuildStore then
    -- register for purchace
    AwesomeGuildStore:RegisterCallback(AwesomeGuildStore.callback.ITEM_PURCHASED, function(itemData)
      local CurrentPurchase        = {}
      CurrentPurchase.ItemLink     = itemData.itemLink
      CurrentPurchase.Quantity     = itemData.stackCount
      CurrentPurchase.Price        = itemData.purchasePrice
      CurrentPurchase.Seller       = itemData.sellerName
      CurrentPurchase.Guild        = itemData.guildName
      CurrentPurchase.itemUniqueId = Id64ToString(itemData.itemUniqueId)
      CurrentPurchase.TimeStamp    = GetTimeStamp()
      internal:addListing(CurrentPurchase)
      --ShoppingList.List:Refresh()
    end)

    AwesomeGuildStore:RegisterCallback(AwesomeGuildStore.callback.ITEM_DATABASE_UPDATE,
      function(itemDatabase, guildId, hasAnyResultAlreadyStored)
        internal.guildStoreSearchResults = itemDatabase
        local allData                    = itemDatabase.data
        internal:processAwesomeGuildStore(allData)
        --[[
        local CurrentPurchase = {}
        CurrentPurchase.ItemLink = itemData.itemLink
        CurrentPurchase.Quantity = itemData.stackCount
        CurrentPurchase.Price = itemData.purchasePrice
        CurrentPurchase.Seller = itemData.sellerName
        CurrentPurchase.Guild = itemData.guildName
        CurrentPurchase.itemUniqueId = Id64ToString(itemData.itemUniqueId)
        CurrentPurchase.TimeStamp = GetTimeStamp()
        internal:dm("Debug", CurrentPurchase)
        ]]--
        --internal:addListing(CurrentPurchase)
        --ShoppingList.List:Refresh()
      end)

    AwesomeGuildStore:RegisterCallback(AwesomeGuildStore.callback.ITEM_POSTED,
      function(guildId, itemLink, price, stackCount)
        local saveData = GS17DataSavedVariables["postedItems"]
        table.insert(saveData, {
          ItemLink = itemLink,
          Quantity = stackCount,
          Price = price,
          Guild = GetGuildName(guildId),
          TimeStamp = GetTimeStamp()
        })
        --gettext("You have cancelled your listing of <<1>>x <<t:2>> for <<3>> in <<4>>", stackCount, itemLink, price, guildName)
        --internal:dm("Debug", guildId)
        --internal:dm("Debug", itemLink)
        --internal:dm("Debug", price)
        --internal:dm("Debug", stackCount)
      end)

    AwesomeGuildStore:RegisterCallback(AwesomeGuildStore.callback.ITEM_CANCELLED,
      function(guildId, itemLink, price, stackCount)
        local saveData = GS17DataSavedVariables["cancelledItems"]
        table.insert(saveData, {
          ItemLink = itemLink,
          Quantity = stackCount,
          Price = price,
          Guild = GetGuildName(guildId),
          TimeStamp = GetTimeStamp()
        })
        --gettext("You have cancelled your listing of <<1>>x <<t:2>> for <<3>> in <<4>>", stackCount, itemLink, price, guildName)
        --internal:dm("Debug", guildId)
        --internal:dm("Debug", itemLink)
        --internal:dm("Debug", price)
        --internal:dm("Debug", stackCount)
      end)
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
  AGS.callback.ITEM_POSTED = "ItemPosted"  ]]--

  -- for vanilla without AwesomeGuildStore
  EVENT_MANAGER:RegisterForEvent(lib.libName, EVENT_TRADING_HOUSE_CONFIRM_ITEM_PURCHASE,
    function(...) internal:onTradingHouseEvent(...) end)

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
  internal:dm("Info", naDetected)
  internal:dm("Info", euDetected)
  return false
end

function internal:CheckMasterMerchantData()
  if not MM00DataSavedVariables and not MM01DataSavedVariables and not MM02DataSavedVariables and
     not MM03DataSavedVariables and not MM04DataSavedVariables and not MM05DataSavedVariables and
     not MM06DataSavedVariables and not MM07DataSavedVariables and not MM08DataSavedVariables and
     not MM09DataSavedVariables and not MM10DataSavedVariables and not MM11DataSavedVariables and
     not MM12DataSavedVariables and not MM13DataSavedVariables and not MM14DataSavedVariables and
     not MM15DataSavedVariables then return true end
  return false
end

function internal:CheckArkadiusData()
  if not ArkadiusTradeToolsSalesData01 and not ArkadiusTradeToolsSalesData02 and not ArkadiusTradeToolsSalesData03 and
     not ArkadiusTradeToolsSalesData04 and not ArkadiusTradeToolsSalesData05 and not ArkadiusTradeToolsSalesData06 and
     not ArkadiusTradeToolsSalesData07 and not ArkadiusTradeToolsSalesData08 and not ArkadiusTradeToolsSalesData09 and
     not ArkadiusTradeToolsSalesData10 and not ArkadiusTradeToolsSalesData11 and not ArkadiusTradeToolsSalesData12 and
     not ArkadiusTradeToolsSalesData13 and not ArkadiusTradeToolsSalesData14 and not ArkadiusTradeToolsSalesData15 and
     not ArkadiusTradeToolsSalesData16 then return true end
  return false
end

function internal:ImportMMSales()
    if internal.isDatabaseBusy then
      internal:dm("Info", "LibGuildStore is busy")
      return
    end
    if internal:CheckMasterMerchantData() then
      internal:dm("Info", "Old Master Merchant sales not detected.")
      return
    end
    if CheckImportStatus() then
      internal:dm("Info", "Your MM data contains values from both NA and EU servers.")
      internal:dm("Info", "All versions prior to 3.6.x did not separate NA and EU sales data.")
      internal:dm("Info", "You must override this in the LibGuildStore settings.")
      return
    end
    if CheckServerImportType() then
      internal:dm("Info", "You are attempting to import NA or EU MM data,")
      internal:dm("Info", "however you logged into a different server type.")
      internal:dm("Info", "You must override this in the LibGuildStore settings.")
      return
    end
    internal:dm("Info", "Import MasterMerchant Sales")
    internal:ImportMasterMerchantSales()
end

function internal:ImportATTSales()
    if internal.isDatabaseBusy then
      internal:dm("Info", "LibGuildStore is busy")
      return
    end
    if internal:CheckArkadiusData() then
      internal:dm("Info", "Arkadius Trade Tools Sales Data not detected.")
      return
    end
    internal:dm("Info", "Import ATT Sales")
    internal:ImportATTSales()
end

function internal.Slash(allArgs)
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
    internal:ImportMMSales()
    return
  end
  if args == 'attimport' then
    internal:ImportATTSales()
    return
  end
  args = ""
end

local function OnAddOnLoaded(eventCode, addonName)
  if addonName == lib.libName then
    SLASH_COMMANDS['/lgs'] = internal.Slash
    internal:dm("Debug", "LibGuildStore Loaded")
    Initilizze()
  end
end

EVENT_MANAGER:RegisterForEvent(lib.libName, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
