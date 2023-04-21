local internal = _G["LibGuildStore_Internal"]
local LAM = LibAddonMenu2

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

  local optionsData = {}
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
    setFunc = function(value)
      LibGuildStore_SavedVariables.useSalesHistory = value
      if LibGuildStore_SavedVariables.useSalesHistory then LibGuildStore_SavedVariables.useSalesHistory = 0 end
    end,
    default = internal.defaults.useSalesHistory,
    disabled = function() return LibGuildStore_SavedVariables.minSalesInterval > 0 end,
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
  -- Size of sales history
  optionsData[#optionsData + 1] = {
    type = 'slider',
    name = GetString(GS_HISTORY_DEPTH_NAME),
    tooltip = GetString(GS_HISTORY_DEPTH_TIP),
    min = 20,
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
    max = 255,
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
    min = 256,
    max = 10000,
    getFunc = function() return LibGuildStore_SavedVariables.maxItemCount end,
    setFunc = function(value) LibGuildStore_SavedVariables.maxItemCount = value end,
    disabled = function() return LibGuildStore_SavedVariables.useSalesHistory end,
    default = internal.defaults.maxItemCount,
  }
  -- Min Day Interval
  optionsData[#optionsData + 1] = {
    type = 'slider',
    name = GetString(GS_MIN_SALES_INTERVAL_NAME),
    tooltip = GetString(GS_MIN_SALES_INTERVAL_TIP),
    min = 0,
    max = 15,
    getFunc = function() return LibGuildStore_SavedVariables.minSalesInterval end,
    setFunc = function(value)
      LibGuildStore_SavedVariables.minSalesInterval = value
      if LibGuildStore_SavedVariables.minSalesInterval > 0 then LibGuildStore_SavedVariables.useSalesHistory = false end
    end,
    disabled = function() return LibGuildStore_SavedVariables.useSalesHistory end,
    default = internal.defaults.minSalesInterval,
  }
  optionsData[#optionsData + 1] = {
    type = "description",
    text = GetString(GS_MIN_SALES_INTERVAL_DESC),
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
  -- Import MM Data
  if internal:MasterMerchantDataActive() then
    optionsData[#optionsData + 1] = {
      type = "header",
      name = GetString(GS_IMPORT_MM_BUTTON),
      width = "full",
      helpUrl = "https://esouimods.github.io/3-master_merchant.html#ImportMMData",
    }
    optionsData[#optionsData + 1] = {
      type = "description",
      title = GetString(GS_IMPORT_MM_SALES),
      text = GetString(GS_IMPORT_MM_DESC),
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
      type = 'checkbox',
      name = GetString(GS_IMPORT_MM_OVERRIDE_NAME),
      tooltip = GetString(GS_IMPORT_MM_OVERRIDE_TIP),
      getFunc = function() return LibGuildStore_SavedVariables.overrideMMImport end,
      setFunc = function(value) LibGuildStore_SavedVariables.overrideMMImport = value end,
      default = internal.defaults.overrideMMImport,
    }
  end
  -- import ATT
  if internal:ArkadiusDataActive() then
    optionsData[#optionsData + 1] = {
      type = "header",
      name = GetString(GS_IMPORT_ATT_BUTTON),
      width = "full",
      helpUrl = "https://esouimods.github.io/3-master_merchant.html#ImportATTData",
    }
    optionsData[#optionsData + 1] = {
      type = "description",
      title = GetString(GS_IMPORT_ATT_SALES),
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
      helpUrl = "https://esouimods.github.io/3-master_merchant.html#ImportATTPurchases",
    }
    optionsData[#optionsData + 1] = {
      type = "description",
      title = GetString(GS_IMPORT_ATT_PURCHASES),
      text = GetString(GS_IMPORT_ATT_PURCHASE_DESC),
    }
    optionsData[#optionsData + 1] = {
      type = "button",
      name = GetString(GS_IMPORT_ATT_PURCHASE_NAME),
      tooltip = GetString(GS_IMPORT_ATT_PURCHASE_TIP),
      func = function()
        internal:ImportATTPurchases()
      end,
    }
  end
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GS_REFRESH_LIBHISTOIRE_DATA),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#RefreshLibHistoire",
  }
  optionsData[#optionsData + 1] = {
    type = "description",
    text = GetString(GS_REFRESH_DESC),
  }
  optionsData[#optionsData + 1] = {
    type = "button",
    name = GetString(GS_REFRESH_LIBHISTOIRE_NAME),
    tooltip = GetString(GS_REFRESH_LIBHISTOIRE_TIP),
    func = function()
      LibGuildStore_SavedVariables[internal.firstrunNamespace] = false
      LibGuildStore_SavedVariables.libHistoireScanByTimestamp = true
      internal:RefreshLibGuildStore()
      internal:SetupListenerLibHistoire()
      internal:StartQueue()
    end,
  }
  -- Import ShoppingList
  if ShoppingList then
    optionsData[#optionsData + 1] = {
      type = "header",
      name = GetString(GS_IMPORT_SL_BUTTON),
      width = "full",
      helpUrl = "https://esouimods.github.io/3-master_merchant.html#ImportShoppingListData",
    }
    optionsData[#optionsData + 1] = {
      type = "description",
      title = GetString(GS_IMPORT_SHOPPINGLIST),
      text = GetString(GS_IMPORT_SL_DESC),
    }
    optionsData[#optionsData + 1] = {
      type = "button",
      name = GetString(GS_IMPORT_SL_NAME),
      tooltip = GetString(GS_IMPORT_SL_TIP),
      func = function()
        internal:ImportShoppingList()
      end,
    }
  end
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GS_IMPORT_PD_BUTTON),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#ImportPricingData",
  }
  optionsData[#optionsData + 1] = {
    type = "description",
    title = GetString(GS_IMPORT_PD_TITLE),
    text = GetString(GS_IMPORT_PD_DESC),
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
    name = GetString(GS_RESET_BUTTON),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#ResetData",
  }
  optionsData[#optionsData + 1] = {
    type = "description",
    text = GetString(GS_RESET_DESC),
  }
  optionsData[#optionsData + 1] = {
    type = "button",
    name = GetString(GS_RESET_NAME),
    tooltip = GetString(GS_RESET_TIP),
    func = function()
      ZO_Dialogs_ShowDialog("MasterMerchantResetConfirmation")
    end,
    warning = GetString(MM_RESET_LISTINGS_WARN_FORCE),
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GS_RESET_LISTINGS_BUTTON),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#ResetData",
  }
  optionsData[#optionsData + 1] = {
    type = "description",
    text = GetString(GS_RESET_LISTINGS_DESC),
  }
  optionsData[#optionsData + 1] = {
    type = "button",
    name = GetString(GS_RESET_LISTINGS_NAME),
    tooltip = GetString(GS_RESET_LISTINGS_TIP),
    func = function()
      ZO_Dialogs_ShowDialog("MasterMerchantResetListingsConfirmation")
    end,
    warning = GetString(MM_RESET_LISTINGS_WARN_FORCE),
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GS_RESET_LIBGUILDSTORE_BUTTON),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#ResetData",
  }
  optionsData[#optionsData + 1] = {
    type = "description",
    text = GetString(GS_RESET_LIBGUILDSTORE_DESC),
  }
  optionsData[#optionsData + 1] = {
    type = "button",
    name = GetString(GS_RESET_LIBGUILDSTORE_NAME),
    tooltip = GetString(GS_RESET_LIBGUILDSTORE_TIP),
    func = function()
      ZO_Dialogs_ShowDialog("MasterMerchantResetLibGuildStoreConfirmation")
    end,
    warning = GetString(MM_RESET_LISTINGS_WARN_FORCE),
  }

  -- And make the options panel
  LAM:RegisterOptionControls('LibGuildStoreOptions', optionsData)
end
