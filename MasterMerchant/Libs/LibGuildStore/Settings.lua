local lib           = _G["LibGuildStore"]
local internal      = _G["LibGuildStore_Internal"]
local sales_data    = _G["LibGuildStore_SalesData"]
local listings_data = _G["LibGuildStore_ListingsData"]
local sr_index      = _G["LibGuildStore_SalesIndex"]
local LAM           = LibAddonMenu2

function internal:StartQueue()
  internal:dm("Debug", "StartQueue")
  zo_callLater(function() internal:QueueCheckStatus() end, ZO_ONE_MINUTE_IN_MILLISECONDS ) -- 60000 1 minute
end

function internal:LibAddonInit()
  internal:dm("Debug", "LibGuildStore LAM Init")
  local panelData = {
    type = 'panel',
    name = 'LibGuildStore',
    displayName = GetString(GS_APP_NAME),
    author = GetString(GS_APP_AUTHOR),
    version = "1.00",
    --website             = "https://www.esoui.com/downloads/fileinfo.php?id=2753",
    --feedback            = "https://www.esoui.com/downloads/fileinfo.php?id=2753",
    donation = "https://sharlikran.github.io/",
    registerForRefresh = true,
    registerForDefaults = true,
  }
  LAM:RegisterAddonPanel('LibGuildStoreOptions', panelData)

  local optionsData             = {}
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GS_DATA_MANAGEMENT_NAME),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#DataManagementOptions",
  }
  -- use size of sales history only
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(GS_DAYS_ONLY_NAME),
    tooltip = GetString(GS_DAYS_ONLY_TIP),
    getFunc = function() return LibGuildStore_SavedVariables.useSalesHistory end,
    setFunc = function(value) LibGuildStore_SavedVariables.useSalesHistory = value end,
    default = internal.defaults.useSalesHistory,
  }
  -- Size of sales history
  optionsData[#optionsData + 1] = {
    type = 'slider',
    name = GetString(GS_HISTORY_DEPTH_NAME),
    tooltip = GetString(GS_HISTORY_DEPTH_TIP),
    min = 1,
    max = MasterMerchant.oneYearInSeconds,
    getFunc = function() return LibGuildStore_SavedVariables.historyDepth end,
    setFunc = function(value) LibGuildStore_SavedVariables.historyDepth = value end,
    default = internal.defaults.historyDepth,
  }
  -- Min Number of Items before Purge
  optionsData[#optionsData + 1] = {
    type = 'slider',
    name = GetString(GS_MIN_ITEM_COUNT_NAME),
    tooltip = GetString(GS_MIN_ITEM_COUNT_TIP),
    min = 0,
    max = 100,
    getFunc = function() return LibGuildStore_SavedVariables.minItemCount end,
    setFunc = function(value) LibGuildStore_SavedVariables.minItemCount = value end,
    disabled = function() return LibGuildStore_SavedVariables.useSalesHistory end,
    default = internal.defaults.minItemCount,
  }
  -- Max number of Items
  optionsData[#optionsData + 1] = {
    type = 'slider',
    name = GetString(GS_MAX_ITEM_COUNT_NAME),
    tooltip = GetString(GS_MAX_ITEM_COUNT_TIP),
    min = 100,
    max = 10000,
    getFunc = function() return LibGuildStore_SavedVariables.maxItemCount end,
    setFunc = function(value) LibGuildStore_SavedVariables.maxItemCount = value end,
    disabled = function() return LibGuildStore_SavedVariables.useSalesHistory end,
    default = internal.defaults.maxItemCount,
  }
  -- Skip Indexing?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(GS_SKIP_INDEX_NAME),
    tooltip = GetString(GS_SKIP_INDEX_TIP),
    getFunc = function() return LibGuildStore_SavedVariables.minimalIndexing end,
    setFunc = function(value) LibGuildStore_SavedVariables.minimalIndexing = value end,
    default = internal.defaults.minimalIndexing,
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GS_DEBUG_OPTIONS),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#DebugOptions",
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(GS_GUILD_ITEM_SUMMARY_NAME),
    tooltip = GetString(GS_GUILD_ITEM_SUMMARY_TIP),
    getFunc = function() return LibGuildStore_SavedVariables.showGuildInitSummary end,
    setFunc = function(value) LibGuildStore_SavedVariables.showGuildInitSummary = value end,
    default = MasterMerchant.systemDefault.showGuildInitSummary,
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(GS_INDEXING_NAME),
    tooltip = GetString(GS_INDEXING_TIP),
    getFunc = function() return LibGuildStore_SavedVariables.showIndexingSummary end,
    setFunc = function(value) LibGuildStore_SavedVariables.showIndexingSummary = value end,
    default = internal.defaults.showIndexingSummary,
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GS_IMPORT_MM_BUTTON),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#DebugOptions",
  }
  optionsData[#optionsData + 1] = {
    type = "description",
    title = "Import MM Sales",
    text = [[Until MM 3.6.x Master Merchant data was not saved separately for NA and EU servers. It is not recomended to import data from a different server type as the prices can be different.]]
  }
  optionsData[#optionsData + 1] = {
    type = "button",
    name = GetString(GS_IMPORT_MM_NAME),
    tooltip = GetString(GS_IMPORT_MM_TIP),
    func = function()
      internal:SlashImportMMSales()
    end,
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GS_IMPORT_ATT_BUTTON),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#DebugOptions",
  }
  optionsData[#optionsData + 1] = {
    type = "description",
    title = "Import ATT Sales",
    text = [[Arkadius Trade Tools sales data is not account specific so you only need to do this once per server NA or EU, not once per account.]]
  }
  optionsData[#optionsData + 1] = {
    type = "button",
    name = GetString(GS_IMPORT_ATT_NAME),
    tooltip = GetString(GS_IMPORT_ATT_TIP),
    func = function()
      internal:SlashImportATTSales()
    end,
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GS_REFRESH_BUTTON),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#DebugOptions",
  }
  optionsData[#optionsData + 1] = {
    type = "description",
    title = "Refresh LibHistoire Database",
    text = [[LibHistoire data is not account specific so you only need to do this once per server NA or EU, not once per account.]]
  }
  optionsData[#optionsData + 1] = {
    type = "button",
    name = GetString(GS_REFRESH_LIBHISTOIRE_NAME),
    tooltip = GetString(GS_REFRESH_LIBHISTOIRE_TIP),
    func = function()
      internal:RefreshLibGuildStore()
      internal:SetupListenerLibHistoire()
      internal:StartQueue()
    end,
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GS_RESET_NA_BUTTON),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#DebugOptions",
  }
  optionsData[#optionsData + 1] = {
    type = "description",
    title = "Reset NA LibGuildStore",
    text = [[This will only reset NA LibGuildStore Data.]]
  }
  optionsData[#optionsData + 1] = {
    type = "button",
    name = GetString(GS_RESET_NA_NAME),
    tooltip = GetString(GS_RESET_NA_TIP),
    func = function()
      internal.dataToReset             = internal.GS_NA_NAMESPACE
      ZO_Dialogs_ShowDialog("MasterMerchantResetConfirmation")
    end,
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GS_RESET_RU_BUTTON),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#DebugOptions",
  }
  optionsData[#optionsData + 1] = {
    type = "description",
    title = "Reset EU LibGuildStore",
    text = [[This will only reset EU LibGuildStore Data.]]
  }
  optionsData[#optionsData + 1] = {
    type = "button",
    name = GetString(GS_RESET_EU_NAME),
    tooltip = GetString(GS_RESET_EU_TIP),
    func = function()
      internal.dataToReset             = internal.GS_EU_NAMESPACE
      ZO_Dialogs_ShowDialog("MasterMerchantResetConfirmation")
    end,
  }

  -- And make the options panel
  LAM:RegisterOptionControls('LibGuildStoreOptions', optionsData)
end
