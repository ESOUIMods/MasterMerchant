local libName, libVersion = "LibGuildStore", 105
local lib = {}
local internal = {}
local mm_sales_data = {}
local att_sales_data = {}
local sales_data = {}
local sr_index = {}
local purchases_data = {}
local pr_index = {}
local listings_data = {}
local lr_index = {}
local posted_items_data = {}
local pir_index = {}
local cancelled_items_data = {}
local cr_index = {}
_G["LibGuildStore"] = lib
_G["LibGuildStore_Internal"] = internal
_G["LibGuildStore_MM_SalesData"] = mm_sales_data
_G["LibGuildStore_ATT_SalesData"] = att_sales_data
_G["LibGuildStore_SalesData"] = sales_data
_G["LibGuildStore_SalesIndex"] = sr_index
_G["LibGuildStore_PurchaseData"] = purchases_data
_G["LibGuildStore_PurchaseIndex"] = pr_index
_G["LibGuildStore_ListingsData"] = listings_data
_G["LibGuildStore_ListingsIndex"] = lr_index
_G["LibGuildStore_PostedItemsData"] = posted_items_data
_G["LibGuildStore_PostedItemsIndex"] = pir_index
_G["LibGuildStore_CancelledItemsData"] = cancelled_items_data
_G["LibGuildStore_CancelledItemsIndex"] = cr_index

internal.sr_index_count = 0
internal.pr_index_count = 0
internal.lr_index_count = 0
internal.pir_index_count = 0
internal.cr_index_count = 0

lib.libName = libName
lib.libVersion = libVersion

------------------------------
--- Debugging              ---
------------------------------

local task = LibAsync:Create("LibGuildStore_Debug")

internal.show_log = true
internal.loggerName = 'LibGuildStore'
if LibDebugLogger then
  internal.logger = LibDebugLogger.Create(internal.loggerName)
end

local logger
local viewer
if DebugLogViewer then viewer = true else viewer = false end
if LibDebugLogger then logger = true else logger = false end

local function create_log(log_type, log_content)
  if not viewer and log_type == "Info" then
    CHAT_ROUTER:AddSystemMessage(log_content)
    return
  end
  if logger and log_type == "Info" then
    internal.logger:Info(log_content)
  end
  if not internal.show_log then return end
  if logger and log_type == "Debug" then
    internal.logger:Debug(log_content)
  end
  if logger and log_type == "Verbose" then
    internal.logger:Verbose(log_content)
  end
  if logger and log_type == "Warn" then
    internal.logger:Warn(log_content)
  end
end

local function emit_message(log_type, text)
  if text == "" then
    text = "[Empty String]"
  end
  -- task:Call(function()
    create_log(log_type, text)
  -- end)
end

local function emit_table(log_type, t, indent, table_history)
  indent = indent or "."
  table_history = table_history or {}

  if not t then
    emit_message(log_type, indent .. "[Nil Table]")
    return
  end

  if next(t) == nil then
    emit_message(log_type, indent .. "[Empty Table]")
    return
  end

  for k, v in pairs(t) do
    local vType = type(v)

    emit_message(log_type, indent .. "(" .. vType .. "): " .. tostring(k) .. " = " .. tostring(v))

    if (vType == "table") then
      if (table_history[v]) then
        emit_message(log_type, indent .. "Avoiding cycle on table...")
      else
        table_history[v] = true
        emit_table(log_type, v, indent .. "  ", table_history)
      end
    end
  end
end

local function emit_userdata(log_type, udata)
  local function_limit = 5  -- Limit the number of functions displayed
  local total_limit = 10   -- Total number of entries to display (functions + non-functions)
  local function_count = 0  -- Counter for functions
  local entry_count = 0     -- Counter for total entries displayed

  emit_message(log_type, "Userdata: " .. tostring(udata))

  local meta = getmetatable(udata)
  if meta and meta.__index then
    for k, v in pairs(meta.__index) do
      -- Show function name for functions
      if type(v) == "function" then
        if function_count < function_limit then
          emit_message(log_type, "  Function: " .. tostring(k))  -- Function name
          function_count = function_count + 1
          entry_count = entry_count + 1
        end
      elseif type(v) ~= "function" then
        -- For non-function entries (like tables or variables), show them
        emit_message(log_type, "  " .. tostring(k) .. ": " .. tostring(v))
        entry_count = entry_count + 1
      end

      -- Stop when we've reached the total limit
      if entry_count >= total_limit then
        emit_message(log_type, "  ... (output truncated due to limit)")
        break
      end
    end
  else
    emit_message(log_type, "  (No detailed metadata available)")
  end
end

local function contains_placeholders(str)
  return type(str) == "string" and str:find("<<%d+>>")
end

function internal:dm(log_type, ...)
if not internal.show_log then
    if log_type == "Info" then
    else
      -- Exit early if show_log is false and log_type is not "Info"
      return
    end
  end

  local num_args = select("#", ...)
  local first_arg = select(1, ...)  -- The first argument is always the message string

  -- Check if the first argument is a string with placeholders
  if type(first_arg) == "string" and contains_placeholders(first_arg) then
    -- Extract any remaining arguments for zo_strformat (after the message string)
    local remaining_args = { select(2, ...) }

    -- Format the string with the remaining arguments
    local formatted_value = ZO_CachedStrFormat(first_arg, unpack(remaining_args))

    -- Emit the formatted message
    emit_message(log_type, formatted_value)
  else
    -- Process other argument types (userdata, tables, etc.)
    for i = 1, num_args do
      local value = select(i, ...)
      if type(value) == "userdata" then
        emit_userdata(log_type, value)
      elseif type(value) == "table" then
        emit_table(log_type, value)
      else
        emit_message(log_type, tostring(value))
      end
    end
  end
end

-- callbackType
internal.callbackType = {}
internal.callbackType = {
  PROCESS_LIBGUILDSTORE_DATA = "ProcessLibGuildStoreData",
  LIBGUILDSTORE_READY = "LibGuildStoreReady",
  REFERENCE_SALES_DATA_CONTAINER = "ReferenceSalesDataContainer",
  REFERENCE_LISTINGS_DATA_CONTAINER = "ReferenceListingsDataContainer",
  REFERENCE_PURCHASE_DATA_CONTAINER = "ReferencePurchaseDataContainer",
  REFERENCE_POSTED_ITEMS_DATA_CONTAINER = "ReferencePostedItemsDataContainer",
  REFERENCE_CANCELLED_ITEM_DATA_CONTAINER = "ReferenceCancelledItemDataContainer",
  ADD_EXTRA_SALES_DATA = "AddExtraSalesData",
  ADD_EXTRA_LISTINGS_DATA = "AddExtraListingsData",
  ADD_EXTRA_PURCHASE_DATA = "AddExtraPurchaseData",
  ADD_EXTRA_POSTED_DATA = "AddExtraPostedData",
  ADD_EXTRA_CANCELLED_DATA = "AddExtraCancelledData",
  TRUNCATE_SALES_HISTORY = "TruncateSalesHistory",
  TRUNCATE_LISTINGS_HISTORY = "TruncateListingsHistory",
  TRUNCATE_PURCHASE_HISTORY = "TruncatePurchaseHistory",
  TRUNCATE_POSTED_ITEMS_HISTORY = "TruncatePostedItemsHistory",
  TRUNCATE_CANCELLED_ITEM_HISTORY = "TruncateCancelledItemHistory",
  RENEW_EXTRA_SALES_DATA = "RenewExtraSalesData",
  RENEW_EXTRA_LISTINGS_DATA = "RenewExtraListingsData",
  RENEW_EXTRA_PURCHASE_DATA = "RenewExtraPurchaseData",
  RENEW_EXTRA_POSTED_DATA = "RenewExtraPostedData",
  RENEW_EXTRA_CANCELLED_DATA = "RenewExtraCancelledData",
  INIT_SALES_HISTORY = "InitSalesHistory",
  INIT_LISTING_HISTORY = "InitListingHistory",
  INIT_PURCHASE_HISTORY = "InitPurchaseHistory",
  INIT_POSTED_ITEMS_HISTORY = "InitPostedItemsHistory",
  INIT_CANCELLED_ITEMS_HISTORY = "InitCancelledItemsHistory",
  INDEX_SALES_DATA = "IndexSalesData",
  INDEX_LISTINGS_DATA = "IndexListingsData",
  INDEX_PURCHASE_DATA = "IndexPurchaseData",
  INDEX_POSTED_ITEMS_DATA = "IndexPostedItemsData",
  INDEX_CANCELLED_ITEM_DATA = "IndexCancelledItemData"
}

local callbackObject = ZO_CallbackObject:New()
internal.callbackObject = {}
internal.callbackObject = callbackObject

function internal:RegisterCallback(...)
  return internal.callbackObject:RegisterCallback(...)
end

function internal:UnregisterCallback(...)
  return internal.callbackObject:UnregisterCallback(...)
end

function internal:FireCallbacks(...)
  return callbackObject:FireCallbacks(...)
end

-------------------------------------------------
----- early helper                          -----
-------------------------------------------------

function internal:is_empty_or_nil(t)
  if t == nil or t == "" then return true end
  return type(t) == "table" and ZO_IsTableEmpty(t) or false
end

function internal:is_in(search_value, search_table)
  if internal:is_empty_or_nil(search_value) then return false end
  for k, v in pairs(search_table) do
    if search_value == v then return true end
    if type(search_value) == "string" then
      if string.find(string.lower(v), string.lower(search_value)) then return true end
    end
  end
  return false
end

-------------------------------------------------
----- lang setup                            -----
-------------------------------------------------

internal.client_lang = GetCVar("Language.2")
internal.effective_lang = nil
local supported_languages = { "de", "en", "fr", "it", "ru", "tr", }
if internal:is_in(internal.client_lang, supported_languages) then
  internal.effective_lang = internal.client_lang
else
  internal.effective_lang = "en"
end
internal.supported_lang = internal.client_lang == internal.effective_lang

-------------------------------------------------
----- LAM Menu Defaults                     -----
-------------------------------------------------
-- These defaults are used with the Lam menu not the startup routine
internal.libAddonMenuDefaults = {
  -- ["firstRun"] = true not needed when reset
  historyDepth = 90,
  minItemCount = 20,
  maxItemCount = 5000,
  showGuildInitSummary = false,
  showIndexingSummary = false,
  showTruncateSummary = false,
  minimalIndexing = false,
  useSalesHistory = false,
  overrideMMImport = false,
  historyDepthShoppingList = 60, -- History Depth Shopping List
  historyDepthPostedItems = 180, -- History Depth Posted Items
  historyDepthCanceledItems = 180, -- History Depth Canceled Items
  libHistoireScanByTimestamp = false,
}

-------------------------------------------------
----- Internal Global variables             -----
-------------------------------------------------
internal.LibHistoireListener = { } -- added for debug on 10-31
internal.LibHistoireListenerReady = { } -- added 6-19-22
internal.alertQueue = { }
internal.guildMemberInfo = { }
internal.accountNameByIdLookup = { }
internal.traderIdByNameLookup = { }
internal.itemLinkNameByIdLookup = { }
internal.guildNameByIdLookup = { }
internal.guildStoreSearchResults = { }
internal.guildStoreSales = { } -- holds all sales
internal.guildStoreListings = { } -- holds all listings
internal.verboseLevel = 4
internal.eventsNeedProcessing = {}
internal.timeEstimated = {}
internal.isDatabaseBusy = false
internal.guildItems = nil
internal.myItems = nil
internal.guildSales = nil
internal.guildPurchases = nil
internal.currentGuilds = {}
internal.guildList = {}

internal.totalSales = 0
internal.totalPurchases = 0
internal.totalListings = 0
internal.totalPosted = 0
internal.totalCanceled = 0

internal.accountNamesCount = 0
internal.itemLinksCount = 0
internal.guildNamesCount = 0

internal.purchasedItems = nil
internal.purchasedBuyer = nil
internal.listedItems = nil
internal.listedSellers = nil

internal.cancelledItems = nil
internal.cancelledSellers = nil
internal.postedItems = nil
internal.postedSellers = nil

internal.GS_NA_NAMESPACE = "datana"
internal.GS_EU_NAMESPACE = "dataeu"
internal.GS_NA_LIBHISTOIRE_NAMESPACE = "libhistoirena"
internal.GS_EU_LIBHISTOIRE_NAMESPACE = "libhistoireeu"
internal.GS_NA_LISTING_NAMESPACE = "listingsna"
internal.GS_EU_LISTING_NAMESPACE = "listingseu"
internal.GS_NA_PURCHASE_NAMESPACE = "purchasena"
internal.GS_EU_PURCHASE_NAMESPACE = "purchaseeu"
internal.GS_NA_NAME_FILTER_NAMESPACE = "namefilterna"
internal.GS_EU_NAME_FILTER_NAMESPACE = "namefiltereu"
internal.GS_NA_FIRST_RUN_NAMESPACE = "firstRunNa"
internal.GS_EU_FIRST_RUN_NAMESPACE = "firstRunEu"

internal.GS_NA_POSTED_NAMESPACE = "posteditemsna"
internal.GS_EU_POSTED_NAMESPACE = "posteditemseu"
internal.GS_NA_CANCELLED_NAMESPACE = "cancelleditemsna"
internal.GS_EU_CANCELLED_NAMESPACE = "cancelleditemseu"

internal.GS_NA_VISIT_TRADERS_NAMESPACE = "visitedNATraders"
internal.GS_EU_VISIT_TRADERS_NAMESPACE = "visitedEUTraders"

internal.GS_NA_PRICING_NAMESPACE = "pricingdatana"
internal.GS_EU_PRICING_NAMESPACE = "pricingdataeu"
internal.GS_ALL_PRICING_NAMESPACE = "pricingdataall"

internal.GS_NA_GUILD_LIST_NAMESPACE = "currentNAGuilds"
internal.GS_EU_GUILD_LIST_NAMESPACE = "currentEUGuilds"

internal.NON_GUILD_MEMBER_PURCHASE = 0
internal.GUILD_MEMBER_PURCHASE = 1
internal.IMPORTED_PURCHASE = 2

internal.GS_CHECK_ACCOUNTNAME = "accountNames"
internal.GS_CHECK_ITEMLINK = "itemLink"
internal.GS_CHECK_GUILDNAME = "guildNames"
internal.PlayerSpecialText = 'hfdkkdfunlajjamdhsiwsuwj'

internal.dataNamespace = ""
internal.libHistoireNamespace = ""
internal.listingsNamespace = ""
internal.purchasesNamespace = ""
internal.firstrunNamespace = ""
internal.postedNamespace = ""
internal.cancelledNamespace = ""
internal.visitedNamespace = ""
internal.pricingNamespace = ""
internal.nameFilterNamespace = ""
internal.guildListNamespace = ""

lib.guildStoreReady = false -- when no more events are pending

--[[TODO
local currencyFormatDealOptions = {
    [0] = { color = ZO_ColorDef:New(0.98, 0.01, 0.01) },
    [ITEM_DISPLAY_QUALITY_NORMAL] = { color = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, ITEM_DISPLAY_QUALITY_NORMAL)) },
--- the other qualities
}
]]--
internal.potionVarientTable = {
  [0] = 0,
  [1] = 0,
  [3] = 1,
  [10] = 2,
  [19] = 2, -- level 19 pots I found
  [20] = 3,
  [24] = 3, -- level 24 pots I found
  [30] = 4,
  [39] = 4, -- level 39 pots I found
  [40] = 5,
  [44] = 5, -- level 44 pots I found
  [125] = 6,
  [129] = 7,
  [134] = 8,
  [307] = 9, -- health potion I commonly find
  [308] = 9,
}
