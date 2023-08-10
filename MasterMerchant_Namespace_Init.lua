-- MasterMerchant Namespace Setup
-- Written July 2014 by Dan Stone (@khaibit) - dankitymao@gmail.com
-- Extended Feb 2015 - May 2020 by (@Philgo68) - Philgo68@gmail.com
-- Released under terms in license accompanying this file.
-- Distribution without license is prohibited!

-- |H1:item:126485:5:0:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:0|h|h  -- no craft cost
-- |H1:item:126485:5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:1:0:0:0:0|h|h  -- craft cost
-- |H0:item:126485:5:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h  -- database item
-- |H0:item:57159:3:40:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h

MMScrollList = ZO_SortFilterList:Subclass()
MMScrollList.defaults = { }
-- Sort keys for the scroll lists
MMScrollList.SORT_KEYS = {
  ['price'] = { isNumeric = true },
  ['time'] = { isNumeric = true },
  ['rank'] = { isNumeric = true },
  ['sales'] = { isNumeric = true },
  ['tax'] = { isNumeric = true },
  ['count'] = { isNumeric = true },
  ['name'] = { isNumeric = false },
  ['itemGuildName'] = { isNumeric = false },
  ['guildName'] = { isNumeric = false }
}

MasterMerchant = { }
MasterMerchant.name = 'MasterMerchant'
MasterMerchant.version = '3.7.67'
MM_STRING_EMPTY = ""
MM_STRING_SEPARATOR_SPACE = " "
MM_STRING_SEPARATOR_DASHES = " -- "

local mmInternal = {}
_G["MasterMerchant_Internal"] = mmInternal

-------------------------------------------------
----- MasterMerchant Constants              -----
-------------------------------------------------
MM_COIN_ICON_NO_SPACE = "|t16:16:EsoUI/Art/currency/currency_gold.dds|t"
MM_COIN_ICON_LEADING_SPACE = " |t16:16:EsoUI/Art/currency/currency_gold.dds|t"

MM_GETPRICE_TYPE_DEALCALC = 1
MM_GETPRICE_TYPE_INV_REPLACEMENT = 2

-- Date Time Ranges for API
MM_DATERANGE_TODAY = 1
MM_DATERANGE_YESTERDAY = 2
MM_DATERANGE_THISWEEK = 3
MM_DATERANGE_LASTWEEK = 4
MM_DATERANGE_PRIORWEEK = 5
MM_DATERANGE_7DAY = 6
MM_DATERANGE_10DAY = 7
MM_DATERANGE_30DAY = 8
MM_DATERANGE_CUSTOM = 9

-- Date Time String Format
MM_MONTH_DAY_FORMAT = 1
MM_DAY_MONTH_FORMAT = 2
MM_MONTH_DAY_YEAR_FORMAT = 3
MM_YEAR_MONTH_DAY_FORMAT = 4
MM_DAY_MONTH_YEAR_FORMAT = 5

-- Window Time Ranges
MM_WINDOW_TIME_RANGE_DEFAULT = 1
MM_WINDOW_TIME_RANGE_THIRTY = 2
MM_WINDOW_TIME_RANGE_SIXTY = 3
MM_WINDOW_TIME_RANGE_NINETY = 4
MM_WINDOW_TIME_RANGE_CUSTOM = 5

-- Deal Value Ranges
MM_DEAL_VALUE_DONT_SHOW = -1
MM_DEAL_VALUE_OVERPRICED = 0
MM_DEAL_VALUE_OKAY = 1
MM_DEAL_VALUE_REASONABLE = 2
MM_DEAL_VALUE_GOOD = 3
MM_DEAL_VALUE_GREAT = 4
MM_DEAL_VALUE_BUYIT = 5

-- LibExecutionQueue wait times
MM_WAIT_TIME_IN_MILLISECONDS_DEFAULT = 20
MM_WAIT_TIME_IN_MILLISECONDS_SHORT = 50 -- longer then 50 seems to increase load times
MM_WAIT_TIME_IN_MILLISECONDS_MEDIUM = 60
MM_WAIT_TIME_IN_MILLISECONDS_LONG = 120
MM_WAIT_TIME_IN_MILLISECONDS_LIBHISTOIRE = 1000
MM_WAIT_TIME_IN_MILLISECONDS_LIBHISTOIRE_SETUP = 500

MM_PRICE_TTC_SUGGESTED = 1
MM_PRICE_TTC_AVERAGE = 2
MM_PRICE_MM_AVERAGE = 3
MM_PRICE_BONANZA = 4

MM_AGS_SORT_PERCENT_ASCENDING = 1
MM_AGS_SORT_PERCENT_DESCENDING = 2

-------------------------------------------------
----- MasterMerchant Assignments            -----
-------------------------------------------------

MasterMerchant.personalSalesViewMode = 'self_vm'
MasterMerchant.guildSalesViewMode = 'guild_vm'
MasterMerchant.reportsPostedViewMode = 'posted_vm'
MasterMerchant.reportsCanceledViewMode = 'canceled_vm'
-- TODO currently unused?
MasterMerchant.listingsViewMode = 'listings_vm'
MasterMerchant.purchasesViewMode = 'purchases_vm'

MasterMerchant.itemsViewSize = 'items_vs'
MasterMerchant.guildsViewSize = 'guild_vs'
MasterMerchant.listingsViewSize = 'listings_vs'
MasterMerchant.purchasesViewSize = 'purchases_vs'
MasterMerchant.reportsViewSize = 'reports_vs'

-- default is self
MasterMerchant.gamepadVendorSceneRefreshed = false
MasterMerchant.tradingHouseBrowseMarkerHooked = false
MasterMerchant.inventoryMarkersHooked = false
MasterMerchant.tradingHouseOpened = false
MasterMerchant.wwDetected = false
MasterMerchant.mwimDetected = false
MasterMerchant.salesViewMode = MasterMerchant.personalSalesViewMode
MasterMerchant.reportsViewMode = MasterMerchant.reportsPostedViewMode
MasterMerchant.isInitialized = false -- added 8-25 used
MasterMerchant.guildMemberInfo = { } -- added 10-17 used as lookup
MasterMerchant.customTimeframeText = MM_STRING_EMPTY -- added 11-21 used as lookup for tooltips
MasterMerchant.systemDefault = {} -- added 11-26 placeholder for init routine
MasterMerchant.fontListChoices = {} -- added 12-16 but always there
MasterMerchant.isFirstScan = false -- added again 5-14-2021 but used previously
MasterMerchant.removedItemIdTable = {} -- added 11-21-2022
MasterMerchant.guildList = {}
MasterMerchant.blacklistTable = {}
MasterMerchant.filterDateRanges = nil
MasterMerchant.dateRanges = nil

MasterMerchant.a_test = {}
MasterMerchant.aa_test = {}
MasterMerchant.aaa_test = {}
MasterMerchant.aaaa_test = {}
MasterMerchant.aaaaa_test = {}
MasterMerchant.aaaaaa_test = {}

if AwesomeGuildStore then
  MasterMerchant.AwesomeGuildStoreDetected = true -- added 12-2
else
  MasterMerchant.AwesomeGuildStoreDetected = false -- added 12-2
end

-- We do 'lazy' updates on the scroll lists, this is used to
-- mark whether we need to RefreshData() before showing
-- ITEMS, GUILDS, LISTINGS, PURCHASES, REPORTS
MasterMerchant.listIsDirty = {
  [MasterMerchant.itemsViewSize] = false,
  [MasterMerchant.guildsViewSize] = false,
  [MasterMerchant.listingsViewSize] = false,
  [MasterMerchant.purchasesViewSize] = false,
  [MasterMerchant.reportsViewSize] = false,
}

MasterMerchant.scrollList = nil
MasterMerchant.guildScrollList = nil
MasterMerchant.listingsScrollList = nil
MasterMerchant.purchasesScrollList = nil
MasterMerchant.reportsScrollList = nil
MasterMerchant.calcInput = nil
MasterMerchant.nameFilterScrollList = nil

MasterMerchant.guildSales = nil
MasterMerchant.guildPurchases = nil
MasterMerchant.guildColor = { }

MasterMerchant.curSort = { 'time', 'desc' }
MasterMerchant.curGuildSort = { 'rank', 'asc' }
MasterMerchant.curFilterSort = { 'name', 'asc' }
MasterMerchant.salesUiFragment = { }
MasterMerchant.guildUiFragment = { }
MasterMerchant.listingUiFragment = { }
MasterMerchant.purchaseUiFragment = { }
MasterMerchant.reportsUiFragment = { }
MasterMerchant.statsFragment = { }
MasterMerchant.activeTip = nil
MasterMerchant.tippingControl = nil
MasterMerchant.isShiftPressed = nil
MasterMerchant.isCtrlPressed = nil

MasterMerchant.originalSetupCallback = nil
MasterMerchant.originalSellingSetupCallback = nil
MasterMerchant.originalRosterStatsCallback = nil
MasterMerchant.originalRosterBuildMasterList = nil

MasterMerchant.itemInformationCache = { }

-- Price formatters
MasterMerchant.formatterNumSalesSingle = nil
MasterMerchant.formatterNumSalesPlural = nil
MasterMerchant.formatterNumItemsSingle = nil
MasterMerchant.formatterNumItemsPlural = nil
MasterMerchant.formatterNumListingsSingle = nil
MasterMerchant.formatterNumListingsPlural = nil

-------------------------------------------------
----- helpers                               -----
-------------------------------------------------

function MasterMerchant:is_in(search_value, search_table)
  for k, v in pairs(search_table) do
    if search_value == v then return true end
    if type(search_value) == "string" then
      if string.find(zo_strlower(v), zo_strlower(search_value)) then return true end
    end
  end
  return false
end

-------------------------------------------------
----- MasterMerchant Localization           -----
-------------------------------------------------

MasterMerchant.client_lang = GetCVar("Language.2")
MasterMerchant.effective_lang = nil
MasterMerchant.supported_lang = true
local supported_lang = { "br", "de", "en", "fr", "jp", "ru", "pl", }
if MasterMerchant:is_in(MasterMerchant.client_lang, supported_lang) then
  MasterMerchant.effective_lang = MasterMerchant.client_lang
else
  MasterMerchant.effective_lang = "en"
end
MasterMerchant.supported_lang = MasterMerchant.client_lang == MasterMerchant.effective_lang

if LibDebugLogger then
  local logger = LibDebugLogger.Create(MasterMerchant.name)
  MasterMerchant.logger = logger
end
local SDLV = DebugLogViewer
if SDLV then MasterMerchant.viewer = true else MasterMerchant.viewer = false end

local function create_log(log_type, log_content)
  if not MasterMerchant.viewer and log_type == "Info" then
    CHAT_ROUTER:AddSystemMessage(log_content)
    return
  end
  if log_type == "Debug" then
    MasterMerchant.logger:Debug(log_content)
  end
  if log_type == "Info" then
    MasterMerchant.logger:Info(log_content)
  end
  if log_type == "Verbose" then
    MasterMerchant.logger:Verbose(log_content)
  end
  if log_type == "Warn" then
    MasterMerchant.logger:Warn(log_content)
  end
end

local function emit_message(log_type, text)
  if (text == MM_STRING_EMPTY) then
    text = "[Empty String]"
  end
  create_log(log_type, text)
end

local function emit_table(log_type, t, indent, table_history)
  indent = indent or "."
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

function MasterMerchant:dm(log_type, ...)
  for i = 1, select("#", ...) do
    local value = select(i, ...)
    if (type(value) == "table") then
      emit_table(log_type, value)
    else
      emit_message(log_type, tostring(value))
    end
  end
end

----------------------------------------
----- Gamepad                      -----
----------------------------------------

----------------------------------------
----- Setup                        -----
----------------------------------------

--[[TODO change color for deals with zo formatting
local currencyFormatDealOptions = {
    [0] = { color = ZO_ColorDef:New(0.98, 0.01, 0.01) },
    [ITEM_DISPLAY_QUALITY_NORMAL] = { color = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, ITEM_DISPLAY_QUALITY_NORMAL)) },
--- the other qualities
}
]]--

-- Sound table for mapping readable names to sound names
MasterMerchant.alertSounds = {
  [1] = { name = "None", sound = 'No_Sound' },
  [2] = { name = "Add Guild Member", sound = 'GuildRoster_Added' },
  [3] = { name = "Armor Glyph", sound = 'Enchanting_ArmorGlyph_Placed' },
  [4] = { name = "Book Acquired", sound = 'Book_Acquired' },
  [5] = { name = "Book Collection Completed", sound = 'Book_Collection_Completed' },
  [6] = { name = "Boss Killed", sound = 'SkillXP_BossKilled' },
  [7] = { name = "Charge Item", sound = 'InventoryItem_ApplyCharge' },
  [8] = { name = "Completed Event", sound = 'ScriptedEvent_Completion' },
  [9] = { name = "Dark Fissure Closed", sound = 'SkillXP_DarkFissureClosed' },
  [10] = { name = "Emperor Coronated", sound = 'Emperor_Coronated_Ebonheart' },
  [11] = { name = "Gate Closed", sound = 'AvA_Gate_Closed' },
  [12] = { name = "Lockpicking Stress", sound = 'Lockpicking_chamber_stress' },
  [13] = { name = "Mail Attachment", sound = 'Mail_ItemSelected' },
  [14] = { name = "Mail Sent", sound = 'Mail_Sent' },
  [15] = { name = "Money", sound = 'Money_Transact' },
  [16] = { name = "Morph Ability", sound = 'Ability_MorphPurchased' },
  [17] = { name = "Not Enough Gold", sound = 'PlayerAction_NotEnoughMoney' },
  [18] = { name = "Not Junk", sound = 'InventoryItem_NotJunk' },
  [19] = { name = "Not Ready", sound = 'Ability_NotReady' },
  [20] = { name = "Objective Complete", sound = 'Objective_Complete' },
  [21] = { name = "Open System Menu", sound = 'System_Open' },
  [22] = { name = "Quest Abandoned", sound = 'Quest_Abandon' },
  [23] = { name = "Quest Complete", sound = 'Quest_Complete' },
  [24] = { name = "Quickslot Empty", sound = 'Quickslot_Use_Empty' },
  [25] = { name = "Quickslot Open", sound = 'Quickslot_Open' },
  [26] = { name = "Raid Life", sound = 'Raid_Life_Display_Shown' },
  [27] = { name = "Remove Guild Member", sound = 'GuildRoster_Removed' },
  [28] = { name = "Repair Item", sound = 'InventoryItem_Repair' },
  [29] = { name = "Rune Removed", sound = 'Enchanting_PotencyRune_Removed' },
  [30] = { name = "Skill Added", sound = 'SkillLine_Added' },
  [31] = { name = "Skill Leveled", sound = 'SkillLine_Leveled' },
  [32] = { name = "Stat Purchase", sound = 'Stats_Purchase' },
  [33] = { name = "Synergy Ready", sound = 'Ability_Synergy_Ready_Sound' },
}
