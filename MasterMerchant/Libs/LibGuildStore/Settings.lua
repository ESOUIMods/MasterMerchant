local lib           = _G["LibGuildStore"]
local internal      = _G["LibGuildStore_Internal"]
local LAM           = LibAddonMenu2

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
    name = GetString(GS_SALES_MANAGEMENT_NAME),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#SalesManagementOptions",
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
    min = 15,
    max = 365,
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
    name = GetString(GS_DATA_MANAGEMENT_NAME),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#DataManagementOptions",
  }
  -- Size shoppinglist history
  optionsData[#optionsData + 1] = {
    type = 'slider',
    name = GetString(GS_SHOPPINGLIST_DEPTH_NAME),
    tooltip = GetString(GS_SHOPPINGLIST_DEPTH_TIP),
    min = 15,
    max = 180,
    getFunc = function() return LibGuildStore_SavedVariables.historyDepthSL end,
    setFunc = function(value) LibGuildStore_SavedVariables.historyDepthSL = value end,
    default = internal.defaults.historyDepthSL,
  }
  -- Size posteditems history
  optionsData[#optionsData + 1] = {
    type = 'slider',
    name = GetString(GS_POSTEDITEMS_DEPTH_NAME),
    tooltip = GetString(GS_POSTEDITEMS_DEPTH_TIP),
    min = 15,
    max = 180,
    getFunc = function() return LibGuildStore_SavedVariables.historyDepthPI end,
    setFunc = function(value) LibGuildStore_SavedVariables.historyDepthPI = value end,
    default = internal.defaults.historyDepthPI,
  }
  -- Size canceleditems history
  optionsData[#optionsData + 1] = {
    type = 'slider',
    name = GetString(GS_CANCELEDITEMS_DEPTH_NAME),
    tooltip = GetString(GS_CANCELEDITEMS_DEPTH_TIP),
    min = 15,
    max = 180,
    getFunc = function() return LibGuildStore_SavedVariables.historyDepthCI end,
    setFunc = function(value) LibGuildStore_SavedVariables.historyDepthCI = value end,
    default = internal.defaults.historyDepthCI,
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GS_DEBUG_OPTIONS),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#LGSDebugOptions",
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(GS_GUILD_ITEM_SUMMARY_NAME),
    tooltip = GetString(GS_GUILD_ITEM_SUMMARY_TIP),
    getFunc = function() return LibGuildStore_SavedVariables.showGuildInitSummary end,
    setFunc = function(value) LibGuildStore_SavedVariables.showGuildInitSummary = value end,
    default = internal.defaults.showGuildInitSummary,
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(GS_TRUNCATE_NAME),
    tooltip = GetString(GS_TRUNCATE_TIP),
    getFunc = function() return LibGuildStore_SavedVariables.showTruncateSummary end,
    setFunc = function(value) LibGuildStore_SavedVariables.showTruncateSummary = value end,
    default = internal.defaults.showTruncateSummary,
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
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#ImportMMData",
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
  -- Skip Indexing?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(GS_IMPORT_MM_OVERRIDE_NAME),
    tooltip = GetString(GS_IMPORT_MM_OVERRIDE_TIP),
    getFunc = function() return LibGuildStore_SavedVariables.overrideMMImport end,
    setFunc = function(value) LibGuildStore_SavedVariables.overrideMMImport = value end,
    default = internal.defaults.overrideMMImport,
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GS_IMPORT_ATT_BUTTON),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#ImportATTData",
  }
  optionsData[#optionsData + 1] = {
    type = "description",
    title = "Import ATT Sales",
    text = GetString(GS_IMPORT_ATT_DESC),
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
    name = GetString(GS_IMPORT_ATT_PURCHASE_BUTTON),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#ImportATTPurchaces",
  }
  optionsData[#optionsData + 1] = {
    type = "description",
    title = "Import ATT Purchases",
    text = [[Arkadius Trade Tools purchases data does not save the specific purchace ID. You may unintentionally import a duplicate purchace. Which could include a purchase made while both ATT and the ShoppingList (stand alone version) were active.]]
  }
  optionsData[#optionsData + 1] = {
    type = "button",
    name = GetString(GS_IMPORT_ATT_PURCHASE_NAME),
    tooltip = GetString(GS_IMPORT_ATT_PURCHASE_TIP),
    func = function()
      internal:ImportATTPurchases()
    end,
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GS_REFRESH_BUTTON),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#RefreshLibHistoire",
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
    name = GetString(GS_IMPORT_SL_BUTTON),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#ImportShoppingListData",
  }
  optionsData[#optionsData + 1] = {
    type = "description",
    title = "Import ShoppingList",
    text = [[Import ShoppingList data into LibGuildStore. Previous ShoppingList data did not save the unique ID for the purchase, you may have some duplicates until the purchase is older and becomes trimmed.]]
  }
  optionsData[#optionsData + 1] = {
    type = "button",
    name = GetString(GS_IMPORT_SL_NAME),
    tooltip = GetString(GS_IMPORT_SL_TIP),
    func = function()
      internal:ImportShoppingList()
    end,
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GS_IMPORT_PD_BUTTON),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#ImportShoppingListData",
  }
  optionsData[#optionsData + 1] = {
    type = "description",
    title = "Import MM Pricing Data",
    text = [[Import MM pricing data into LibGuildStore. Previous pricing data will only be avalable as central pricing data. It will not import the same pricing data into each seperate guild.]]
  }
  optionsData[#optionsData + 1] = {
    type = "button",
    name = GetString(GS_IMPORT_PD_NAME),
    tooltip = GetString(GS_IMPORT_PD_TIP),
    func = function()
      internal:ImportPricingData()
    end,
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GS_RESET_NA_BUTTON),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#ResetData",
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
    name = GetString(GS_RESET_EU_BUTTON),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#ResetData",
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
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GS_RESET_LISTINGS_BUTTON),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#ResetData",
  }
  optionsData[#optionsData + 1] = {
    type = "description",
    title = "Reset Listings Data",
    text = [[This will only reset listings for the current server type NA or EU.]]
  }
  optionsData[#optionsData + 1] = {
    type = "button",
    name = GetString(GS_RESET_LISTINGS_NAME),
    tooltip = GetString(GS_RESET_LISTINGS_TIP),
    func = function()
      internal.listingsToReset             = internal.listingsNamespace
      ZO_Dialogs_ShowDialog("MasterMerchantResetListingsConfirmation")
    end,
  }

  -- And make the options panel
  LAM:RegisterOptionControls('LibGuildStoreOptions', optionsData)
end
