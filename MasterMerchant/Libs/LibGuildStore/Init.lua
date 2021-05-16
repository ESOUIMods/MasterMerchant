local libName, libVersion         = "LibGuildStore", 100
local lib                         = {}
local internal                    = {}
local sales_data                  = {}
local listings_data               = {}
local sr_index                    = {}
local mm_sales_data               = {}
local att_sales_data              = {}
_G["LibGuildStore"]               = lib
_G["LibGuildStore_Internal"]      = internal
_G["LibGuildStore_SalesData"]     = sales_data
_G["LibGuildStore_ListingsData"]  = listings_data
_G["LibGuildStore_SalesIndex"]    = sr_index
_G["LibGuildStore_MM_SalesData"]  = mm_sales_data
_G["LibGuildStore_ATT_SalesData"] = att_sales_data

lib.libName                       = libName
lib.libVersion                    = libVersion

if LibDebugLogger then
  local logger    = LibDebugLogger.Create(libName)
  internal.logger = logger
end
local SDLV = DebugLogViewer
if SDLV then internal.viewer = true else internal.viewer = false end

local function create_log(log_type, log_content)
  if not internal.viewer and log_type == "Info" then
    CHAT_ROUTER:AddSystemMessage(log_content)
    return
  end
  if not internal.logger then return end
  if log_type == "Debug" then
    internal.logger:Debug(log_content)
  end
  if log_type == "Info" then
    internal.logger:Info(log_content)
  end
  if log_type == "Verbose" then
    internal.logger:Verbose(log_content)
  end
  if log_type == "Warn" then
    internal.logger:Warn(log_content)
  end
end

local function emit_message(log_type, text)
  if (text == "") then
    text = "[Empty String]"
  end
  create_log(log_type, text)
end

local function emit_table(log_type, t, indent, table_history)
  indent        = indent or "."
  table_history = table_history or {}

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

function internal:dm(log_type, ...)
  for i = 1, select("#", ...) do
    local value = select(i, ...)
    if (type(value) == "table") then
      emit_table(log_type, value)
    else
      emit_message(log_type, tostring(value))
    end
  end
end

-------------------------------------------------
----- early helper                          -----
-------------------------------------------------

function internal:is_in(search_value, search_table)
  for k, v in pairs(search_table) do
    if search_value == v then return true end
    if type(search_value) == "string" then
      if string.find(zo_strlower(v), zo_strlower(search_value)) then return true end
    end
  end
  return false
end

-------------------------------------------------
----- lang setup                            -----
-------------------------------------------------

internal.client_lang    = GetCVar("Language.2")
internal.effective_lang = nil
internal.supported_lang = { "en", }
if internal:is_in(internal.client_lang, internal.supported_lang) then
  internal.effective_lang = internal.client_lang
else
  internal.effective_lang = "en"
end
internal.supported_lang = internal.client_lang == internal.effective_lang

function internal:is_empty_or_nil(t)
  if t == nil or t == "" then return true end
  return type(t) == "table" and ZO_IsTableEmpty(t) or false
end

internal.saveVarsDefaults = {
  lastReceivedEventID = {},
}

if not LibGuildStore_SavedVariables then LibGuildStore_SavedVariables = internal.saveVarsDefaults end
internal.LibHistoireListener     = { } -- added for debug on 10-31
internal.alertQueue              = { }
internal.guildMemberInfo         = { }
internal.accountNameByIdLookup   = { }
internal.itemLinkNameByIdLookup  = { }
internal.guildNameByIdLookup     = { }
internal.guildStoreSearchResults = { }
internal.guildStoreSales         = { } -- holds all sales
internal.guildStoreListings      = { } -- holds all listings
internal.verboseLevel            = 4
internal.eventsNeedProcessing    = {}
internal.timeEstimated           = {}
internal.isDatabaseBusy          = false
internal.guildItems              = nil
internal.myItems                 = nil
internal.guildSales              = nil
internal.guildPurchases          = nil
internal.totalRecords            = 0
internal.oneDayInSeconds         = 86400

internal.GS_NA_NAMESPACE     = "datana"
internal.GS_EU_NAMESPACE     = "dataeu"

internal.GS_CHECK_ACCOUNTNAME    = "AccountNames"
internal.GS_CHECK_ITEMLINK       = "ItemLink"
internal.GS_CHECK_GUILDNAME      = "GuildNames"
internal.PlayerSpecialText       = 'hfdkkdfunlajjamdhsiwsuwj'
internal.dataToReset             = ""

internal.dataNamespace           = ""
internal.listingsNamespace       = ""
internal.firstrunNamespace       = ""

lib.guildStoreReady              = false -- when no more events are pending

--[[TODO
local currencyFormatDealOptions = {
    [0] = { color = ZO_ColorDef:New(0.98, 0.01, 0.01) },
    [ITEM_DISPLAY_QUALITY_NORMAL] = { color = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, ITEM_DISPLAY_QUALITY_NORMAL)) },
--- the other qualities
}
]]--
internal.potionVarientTable      = {
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

internal.defaults                = {
  -- ["firstRun"] = true not needed when reset
  updateAdditionalText = false,
  historyDepth = 30,
  minItemCount = 20,
  maxItemCount = 5000,
  showGuildInitSummary = false,
  showIndexingSummary = false,
  minimalIndexing = false,
  useSalesHistory = false,
}

--[[ sr_index, originally SRIndex is an inverted indexe of the
ScanResults table. Each key is a word found in one of the sales
items' searched fields (buyer, guild, item name) and a table
of the sales_data, originally SalesData indexes that contain
that word.
]]--
