local LAM = LibAddonMenu2
local mmUtils = _G["MasterMerchant_Internal"]

-- Table where the guild roster columns shall be placed
MasterMerchant.guild_columns = {}
MasterMerchant.UI_GuildTime = nil

if TamrielTradeCentre then
  MasterMerchant.dealCalcChoices = {
    GetString(GS_DEAL_CALC_TTC_SUGGESTED),
    GetString(GS_DEAL_CALC_TTC_AVERAGE),
    GetString(GS_DEAL_CALC_MM_AVERAGE),
    GetString(GS_DEAL_CALC_BONANZA_PRICE),
  }
  MasterMerchant.dealCalcValues = {
    MM_PRICE_TTC_SUGGESTED,
    MM_PRICE_TTC_AVERAGE,
    MM_PRICE_MM_AVERAGE,
    MM_PRICE_BONANZA,
  }
else
  MasterMerchant.dealCalcChoices = {
    GetString(GS_DEAL_CALC_MM_AVERAGE),
    GetString(GS_DEAL_CALC_BONANZA_PRICE),
  }
  MasterMerchant.dealCalcValues = {
    MM_PRICE_MM_AVERAGE,
    MM_PRICE_BONANZA,
  }
end

MasterMerchant.agsPercentSortChoices = {
  GetString(AGS_PERCENT_ORDER_ASCENDING),
  GetString(AGS_PERCENT_ORDER_DESCENDING),
}
MasterMerchant.agsPercentSortValues = {
  MM_AGS_SORT_PERCENT_ASCENDING,
  MM_AGS_SORT_PERCENT_DESCENDING,
}

local function CheckDealCalcValue()
  if MasterMerchant.systemSavedVariables.dealCalcToUse ~= MM_PRICE_TTC_SUGGESTED then
    MasterMerchant.systemSavedVariables.modifiedSuggestedPriceDealCalc = false
  end
end

local function CheckInventoryValue()
  if MasterMerchant.systemSavedVariables.replacementTypeToUse ~= MM_PRICE_TTC_SUGGESTED then
    MasterMerchant.systemSavedVariables.modifiedSuggestedPriceInventory = false
  end
end

local function CheckVoucherValue()
  if MasterMerchant.systemSavedVariables.voucherValueTypeToUse ~= MM_PRICE_TTC_SUGGESTED then
    MasterMerchant.systemSavedVariables.modifiedSuggestedPriceVoucher = false
  end
end

--[[ can not use MasterMerchant.itemsViewSize for example
because that will not be available this early.
]]--
local ITEMS = 'items_vs'
local GUILDS = 'guild_vs'
local LISTINGS = 'listings_vs'
local PURCHASES = 'purchases_vs'
local REPORTS = 'reports_vs'

-- LibAddon init code
function MasterMerchant:LibAddonInit()
  -- configure font choices
  MasterMerchant:SetFontListChoices()
  MasterMerchant:dm("Debug", "LibAddonInit")
  local panelData = {
    type = 'panel',
    name = 'Master Merchant',
    displayName = GetString(MM_APP_NAME),
    author = GetString(MM_APP_AUTHOR),
    version = self.version,
    website = "https://www.esoui.com/downloads/fileinfo.php?id=2753",
    feedback = "https://www.esoui.com/downloads/fileinfo.php?id=2753",
    donation = "https://sharlikran.github.io/",
    registerForRefresh = true,
    registerForDefaults = true,
  }
  LAM:RegisterAddonPanel('MasterMerchantOptions', panelData)

  local optionsData = {}
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(MASTER_MERCHANT_WINDOW_NAME),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#MasterMerchantWindowOptions",
  }
  -- Open main window with mailbox scenes
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_OPEN_MAIL_NAME),
    tooltip = GetString(SK_OPEN_MAIL_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.openWithMail end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.openWithMail = value
      local theFragment = MasterMerchant:ActiveFragment()
      if value then
        -- Register for the mail scenes
        MAIL_INBOX_SCENE:AddFragment(theFragment)
        MAIL_SEND_SCENE:AddFragment(theFragment)
      else
        -- Unregister for the mail scenes
        MAIL_INBOX_SCENE:RemoveFragment(theFragment)
        MAIL_SEND_SCENE:RemoveFragment(theFragment)
      end
    end,
    default = MasterMerchant.systemDefault.openWithMail,
  }
  -- Open main window with trading house scene
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_OPEN_STORE_NAME),
    tooltip = GetString(SK_OPEN_STORE_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.openWithStore end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.openWithStore = value
      local theFragment = MasterMerchant:ActiveFragment()
      if value then
        -- Register for the store scene
        TRADING_HOUSE_SCENE:AddFragment(theFragment)
      else
        -- Unregister for the store scene
        TRADING_HOUSE_SCENE:RemoveFragment(theFragment)
      end
    end,
    default = MasterMerchant.systemDefault.openWithStore,
  }
  -- Show full sale price or post-tax price
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_FULL_SALE_NAME),
    tooltip = GetString(SK_FULL_SALE_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showFullPrice end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.showFullPrice = value
      MasterMerchant.listIsDirty[ITEMS] = true
      MasterMerchant.listIsDirty[GUILDS] = true
      MasterMerchant.listIsDirty[LISTINGS] = true
      MasterMerchant.listIsDirty[PURCHASES] = true
    end,
    default = MasterMerchant.systemDefault.showFullPrice,
  }
  -- Font to use
  optionsData[#optionsData + 1] = {
    type = 'dropdown',
    name = GetString(SK_WINDOW_FONT_NAME),
    tooltip = GetString(SK_WINDOW_FONT_TIP),
    choices = MasterMerchant.fontListChoices,
    getFunc = function() return MasterMerchant.systemSavedVariables.windowFont end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.windowFont = value
      self:UpdateFonts()
      if MasterMerchant.systemSavedVariables.viewSize == ITEMS then self.scrollList:RefreshVisible()
      elseif MasterMerchant.systemSavedVariables.viewSize == GUILDS then self.guildScrollList:RefreshVisible()
      else self.listingScrollList:RefreshVisible() end
    end,
    default = MasterMerchant.systemDefault.windowFont,
  }
  optionsData[#optionsData + 1] = {
    type = 'slider',
    name = GetString(MM_WINDOW_CUSTOM_TIMEFRAME_NAME),
    tooltip = GetString(MM_WINDOW_CUSTOM_TIMEFRAME_TIP),
    min = 15,
    max = 365,
    getFunc = function() return MasterMerchant.systemSavedVariables.customFilterDateRange end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.customFilterDateRange = value end,
    default = MasterMerchant.systemDefault.customFilterDateRange,
  }
  -- Timeformat Options -----------------------------------
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(MASTER_MERCHANT_TIMEFORMAT_OPTIONS),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#TimeFormatOptions",
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_SHOW_TIME_NAME),
    tooltip = GetString(MM_SHOW_TIME_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.useFormatedTime end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.useFormatedTime = value end,
    default = MasterMerchant.systemDefault.useFormatedTime,
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_USE_TWENTYFOUR_HOUR_TIME_NAME),
    tooltip = GetString(MM_USE_TWENTYFOUR_HOUR_TIME_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.useTwentyFourHourTime end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.useTwentyFourHourTime = value end,
    default = MasterMerchant.systemDefault.useTwentyFourHourTime,
    disabled = function() return not MasterMerchant.systemSavedVariables.useFormatedTime end,
  }
  optionsData[#optionsData + 1] = {
    type = 'dropdown',
    name = GetString(MM_DATE_FORMAT_NAME),
    tooltip = GetString(MM_DATE_FORMAT_TIP),
    choices = { GetString(MM_USE_MONTH_DAY_FORMAT), GetString(MM_USE_DAY_MONTH_FORMAT), GetString(MM_USE_MONTH_DAY_YEAR_FORMAT), GetString(MM_USE_YEAR_MONTH_DAY_FORMAT), GetString(MM_USE_DAY_MONTH_YEAR_FORMAT), },
    choicesValues = { MM_MONTH_DAY_FORMAT, MM_DAY_MONTH_FORMAT, MM_MONTH_DAY_YEAR_FORMAT, MM_YEAR_MONTH_DAY_FORMAT, MM_DAY_MONTH_YEAR_FORMAT, },
    getFunc = function() return MasterMerchant.systemSavedVariables.dateFormatMonthDay end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.dateFormatMonthDay = value end,
    default = self:SearchSounds(MasterMerchant.systemDefault.dateFormatMonthDay),
    disabled = function() return not MasterMerchant.systemSavedVariables.useFormatedTime end,
  }
  -- 6 Sound and Alert options
  optionsData[#optionsData + 1] = {
    type = 'submenu',
    name = GetString(SK_ALERT_OPTIONS_NAME),
    tooltip = GetString(SK_ALERT_OPTIONS_TIP),
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#AlertOptions",
    controls = {
      -- On-Screen Alerts
      [1] = {
        type = 'checkbox',
        name = GetString(SK_ALERT_ANNOUNCE_NAME),
        tooltip = GetString(SK_ALERT_ANNOUNCE_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.showAnnounceAlerts end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.showAnnounceAlerts = value end,
        default = MasterMerchant.systemDefault.showAnnounceAlerts,
      },
      [2] = {
        type = 'checkbox',
        name = GetString(SK_ALERT_CYRODIIL_NAME),
        tooltip = GetString(SK_ALERT_CYRODIIL_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.showCyroAlerts end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.showCyroAlerts = value end,
        default = MasterMerchant.systemDefault.showCyroAlerts,
      },
      -- Chat Alerts
      [3] = {
        type = 'checkbox',
        name = GetString(SK_ALERT_CHAT_NAME),
        tooltip = GetString(SK_ALERT_CHAT_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.showChatAlerts end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.showChatAlerts = value end,
        default = MasterMerchant.systemDefault.showChatAlerts,
      },
      -- Sound to use for alerts
      [4] = {
        type = 'dropdown',
        name = GetString(SK_ALERT_TYPE_NAME),
        tooltip = GetString(SK_ALERT_TYPE_TIP),
        choices = self:SoundKeys(),
        getFunc = function() return self:SearchSounds(MasterMerchant.systemSavedVariables.alertSoundName) end,
        setFunc = function(value)
          MasterMerchant.systemSavedVariables.alertSoundName = self:SearchSoundNames(value)
          PlaySound(MasterMerchant.systemSavedVariables.alertSoundName)
        end,
        default = self:SearchSounds(MasterMerchant.systemDefault.alertSoundName),
      },
      -- Whether or not to show multiple alerts for multiple sales
      [5] = {
        type = 'checkbox',
        name = GetString(SK_MULT_ALERT_NAME),
        tooltip = GetString(SK_MULT_ALERT_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.showMultiple end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.showMultiple = value end,
        default = MasterMerchant.systemDefault.showMultiple,
      },
      -- Offline sales report
      [6] = {
        type = 'checkbox',
        name = GetString(SK_OFFLINE_SALES_NAME),
        tooltip = GetString(SK_OFFLINE_SALES_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.offlineSales end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.offlineSales = value end,
        default = MasterMerchant.systemDefault.offlineSales,
      },
      -- should we display the item listed message?
      [7] = {
        type = 'checkbox',
        name = GetString(MM_DISPLAY_LISTING_MESSAGE_NAME),
        tooltip = GetString(MM_DISPLAY_LISTING_MESSAGE_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.displayListingMessage end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.displayListingMessage = value end,
        default = MasterMerchant.systemDefault.displayListingMessage,
        disabled = function() return MasterMerchant.AwesomeGuildStoreDetected end,
      },
    },
  }
  -- 7 Tip display and calculation options
  optionsData[#optionsData + 1] = {
    type = 'submenu',
    name = GetString(MM_CALC_OPTIONS_NAME),
    tooltip = GetString(MM_CALC_OPTIONS_TIP),
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#CalculationDisplayOptions",
    controls = {
      -- On-Screen Alerts
      [1] = {
        type = 'slider',
        name = GetString(MM_DAYS_FOCUS_ONE_NAME),
        tooltip = GetString(MM_DAYS_FOCUS_ONE_TIP),
        min = 1,
        max = 90,
        getFunc = function() return MasterMerchant.systemSavedVariables.focus1 end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.focus1 = value end,
        default = MasterMerchant.systemDefault.focus1,
      },
      [2] = {
        type = 'slider',
        name = GetString(MM_DAYS_FOCUS_TWO_NAME),
        tooltip = GetString(MM_DAYS_FOCUS_TWO_TIP),
        min = 1,
        max = 90,
        getFunc = function() return MasterMerchant.systemSavedVariables.focus2 end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.focus2 = value end,
        default = MasterMerchant.systemDefault.focus2,
      },
      [3] = {
        type = 'slider',
        name = GetString(MM_DAYS_FOCUS_THREE_NAME),
        tooltip = GetString(MM_DAYS_FOCUS_THREE_TIP),
        min = 1,
        max = 90,
        getFunc = function() return MasterMerchant.systemSavedVariables.focus3 end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.focus3 = value end,
        default = MasterMerchant.systemDefault.focus3,
      },
      -- default time range
      [4] = {
        type = 'dropdown',
        name = GetString(MM_DEFAULT_TIME_NAME),
        tooltip = GetString(MM_DEFAULT_TIME_TIP),
        choices = MasterMerchant.daysRangeChoices,
        choicesValues = MasterMerchant.daysRangeValues,
        getFunc = function() return MasterMerchant.systemSavedVariables.defaultDays end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.defaultDays = value end,
        default = MasterMerchant.systemDefault.defaultDays,
      },
      -- shift time range
      [5] = {
        type = 'dropdown',
        name = GetString(MM_SHIFT_TIME_NAME),
        tooltip = GetString(MM_SHIFT_TIME_TIP),
        choices = MasterMerchant.daysRangeChoices,
        choicesValues = MasterMerchant.daysRangeValues,
        getFunc = function() return MasterMerchant.systemSavedVariables.shiftDays end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.shiftDays = value end,
        default = MasterMerchant.systemDefault.shiftDays,
      },
      -- ctrl time range
      [6] = {
        type = 'dropdown',
        name = GetString(MM_CTRL_TIME_NAME),
        tooltip = GetString(MM_CTRL_TIME_TIP),
        choices = MasterMerchant.daysRangeChoices,
        choicesValues = MasterMerchant.daysRangeValues,
        getFunc = function() return MasterMerchant.systemSavedVariables.ctrlDays end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.ctrlDays = value end,
        default = MasterMerchant.systemDefault.ctrlDays,
      },
      -- ctrl-shift time range
      [7] = {
        type = 'dropdown',
        name = GetString(MM_CTRLSHIFT_TIME_NAME),
        tooltip = GetString(MM_CTRLSHIFT_TIME_TIP),
        choices = MasterMerchant.daysRangeChoices,
        choicesValues = MasterMerchant.daysRangeValues,
        getFunc = function() return MasterMerchant.systemSavedVariables.ctrlShiftDays end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.ctrlShiftDays = value end,
        default = MasterMerchant.systemDefault.ctrlShiftDays,
      },
      -- blacklisted players and guilds
      [8] = {
        type = 'editbox',
        name = GetString(MM_BLACKLIST_NAME),
        tooltip = GetString(MM_BLACKLIST_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.blacklist end,
        setFunc = function(value)
          MasterMerchant.systemSavedVariables.blacklist = value
          mmUtils:ResetItemAndBonanzaCache()
          MasterMerchant.blacklistTable = MasterMerchant:BuildTableFromString(MasterMerchant.systemSavedVariables.blacklist)
        end,
        default = MasterMerchant.systemDefault.blacklist,
        isMultiline = true,
        textType = TEXT_TYPE_ALL,
        width = "full"
      },
      -- customTimeframe
      [9] = {
        type = 'slider',
        name = GetString(MM_CUSTOM_TIMEFRAME_NAME),
        tooltip = GetString(MM_CUSTOM_TIMEFRAME_TIP),
        min = 1,
        max = 24 * 31,
        getFunc = function() return MasterMerchant.systemSavedVariables.customTimeframe end,
        setFunc = function(value)
          MasterMerchant.systemSavedVariables.customTimeframe = value
          MasterMerchant.customTimeframeText = MasterMerchant.systemSavedVariables.customTimeframe .. ' ' .. MasterMerchant.systemSavedVariables.customTimeframeType
          MasterMerchant:BuildRosterTimeDropdown()
          MasterMerchant:BuildGuidTimeDropdown()
        end,
        default = MasterMerchant.systemDefault.customTimeframe,
        warning = GetString(MM_CUSTOM_TIMEFRAME_WARN),
        requiresReload = true,
      },
      -- shift time range
      [10] = {
        type = 'dropdown',
        name = GetString(MM_CUSTOM_TIMEFRAME_SCALE_NAME),
        tooltip = GetString(MM_CUSTOM_TIMEFRAME_SCALE_TIP),
        choices = { GetString(MM_CUSTOM_TIMEFRAME_HOURS), GetString(MM_CUSTOM_TIMEFRAME_DAYS), GetString(MM_CUSTOM_TIMEFRAME_WEEKS), GetString(MM_CUSTOM_TIMEFRAME_GUILD_WEEKS) },
        getFunc = function() return MasterMerchant.systemSavedVariables.customTimeframeType end,
        setFunc = function(value)
          MasterMerchant.systemSavedVariables.customTimeframeType = value
          MasterMerchant.customTimeframeText = MasterMerchant.systemSavedVariables.customTimeframe .. ' ' .. MasterMerchant.systemSavedVariables.customTimeframeType
          MasterMerchant:BuildRosterTimeDropdown()
          MasterMerchant:BuildGuidTimeDropdown()
        end,
        default = MasterMerchant.systemDefault.customTimeframeType,
        warning = GetString(MM_CUSTOM_TIMEFRAME_WARN),
        requiresReload = true,
      },
    },
  }
  -- 8 Custom Deal Calc
  optionsData[#optionsData + 1] = {
    type = 'submenu',
    name = GetString(MM_DEALCALC_OPTIONS_NAME),
    tooltip = GetString(MM_DEALCALC_OPTIONS_TIP),
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#DealCalculatorOptions",
    controls = {
      -- Enable DealCalc
      [1] = {
        type = 'checkbox',
        name = GetString(MM_DEALCALC_ENABLE_NAME),
        tooltip = GetString(MM_DEALCALC_ENABLE_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.customDealCalc end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.customDealCalc = value end,
        default = MasterMerchant.systemDefault.customDealCalc,
      },
      -- custom customDealBuyIt
      [2] = {
        type = 'slider',
        name = GetString(MM_DEALCALC_BUYIT_NAME),
        tooltip = GetString(MM_DEALCALC_BUYIT_TIP),
        min = 0,
        max = 100,
        getFunc = function() return MasterMerchant.systemSavedVariables.customDealBuyIt end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.customDealBuyIt = value end,
        default = MasterMerchant.systemDefault.customDealBuyIt,
        disabled = function() return not MasterMerchant.systemSavedVariables.customDealCalc end,
      },
      -- customDealSeventyFive
      [3] = {
        type = 'slider',
        name = GetString(MM_DEALCALC_SEVENTYFIVE_NAME),
        tooltip = GetString(MM_DEALCALC_SEVENTYFIVE_TIP),
        min = 0,
        max = 100,
        getFunc = function() return MasterMerchant.systemSavedVariables.customDealSeventyFive end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.customDealSeventyFive = value end,
        default = MasterMerchant.systemDefault.customDealSeventyFive,
        disabled = function() return not MasterMerchant.systemSavedVariables.customDealCalc end,
      },
      -- customDealFifty
      [4] = {
        type = 'slider',
        name = GetString(MM_DEALCALC_FIFTY_NAME),
        tooltip = GetString(MM_DEALCALC_FIFTY_TIP),
        min = 0,
        max = 100,
        getFunc = function() return MasterMerchant.systemSavedVariables.customDealFifty end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.customDealFifty = value end,
        default = MasterMerchant.systemDefault.customDealFifty,
        disabled = function() return not MasterMerchant.systemSavedVariables.customDealCalc end,
      },
      -- customDealTwentyFive
      [5] = {
        type = 'slider',
        name = GetString(MM_DEALCALC_TWENTYFIVE_NAME),
        tooltip = GetString(MM_DEALCALC_TWENTYFIVE_TIP),
        min = 0,
        max = 100,
        getFunc = function() return MasterMerchant.systemSavedVariables.customDealTwentyFive end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.customDealTwentyFive = value end,
        default = MasterMerchant.systemDefault.customDealTwentyFive,
        disabled = function() return not MasterMerchant.systemSavedVariables.customDealCalc end,
      },
      -- customDealZero
      [6] = {
        type = 'slider',
        name = GetString(MM_DEALCALC_ZERO_NAME),
        tooltip = GetString(MM_DEALCALC_ZERO_TIP),
        min = 0,
        max = 100,
        getFunc = function() return MasterMerchant.systemSavedVariables.customDealZero end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.customDealZero = value end,
        default = MasterMerchant.systemDefault.customDealZero,
        disabled = function() return not MasterMerchant.systemSavedVariables.customDealCalc end,
      },
      [7] = {
        type = "description",
        text = GetString(MM_DEALCALC_OKAY_TEXT),
      },
      -- Deal Filter Price
      [8] = {
        type = 'dropdown',
        name = GetString(SK_DEAL_CALC_TYPE_NAME),
        tooltip = GetString(SK_DEAL_CALC_TYPE_TIP),
        choices = MasterMerchant.dealCalcChoices,
        choicesValues = MasterMerchant.dealCalcValues,
        getFunc = function() return MasterMerchant.systemSavedVariables.dealCalcToUse end,
        setFunc = function(value)
          MasterMerchant.systemSavedVariables.dealCalcToUse = value
          CheckDealCalcValue()
        end,
        default = MasterMerchant.systemDefault.dealCalcToUse,
      },
      [9] = {
        type = 'checkbox',
        name = GetString(MM_MODIFIED_TTC_SUGGESTED_NAME),
        tooltip = GetString(MM_MODIFIED_TTC_SUGGESTED_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.modifiedSuggestedPriceDealCalc end,
        setFunc = function(value) MasterMerchant.systemSavedVariables.modifiedSuggestedPriceDealCalc = value end,
        default = MasterMerchant.systemDefault.modifiedSuggestedPriceDealCalc,
        disabled = function() return not (MasterMerchant.systemSavedVariables.dealCalcToUse == MM_PRICE_TTC_SUGGESTED) end,
      },
    },
  }
  -- 9 guild roster menu
  optionsData[#optionsData + 1] = {
    type = 'submenu',
    name = GetString(MM_GUILD_ROSTER_OPTIONS_NAME),
    tooltip = GetString(MM_GUILD_ROSTER_OPTIONS_TIP),
    controls = {
      -- should we display info on guild roster?
      [1] = {
        type = 'checkbox',
        name = GetString(SK_ROSTER_INFO_NAME),
        tooltip = GetString(SK_ROSTER_INFO_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.diplayGuildInfo end,
        setFunc = function(value)

          MasterMerchant.systemSavedVariables.diplayGuildInfo = value
          --[[
          if self.UI_GuildTime then
            self.UI_GuildTime:SetHidden(not value)
          end

          for key, column in pairs(self.guild_columns) do
            column:IsDisabled(not value)
          end
          ]]--

          ReloadUI()

        end,
        default = MasterMerchant.systemDefault.diplayGuildInfo,
        warning = GetString(MM_RELOADUI_WARN),
      },
      [2] = {
        type = 'checkbox',
        name = GetString(MM_SALES_COLUMN_NAME),
        tooltip = GetString(MM_SALES_COLUMN_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.diplaySalesInfo end,
        setFunc = function(value)
          MasterMerchant.systemSavedVariables.diplaySalesInfo = value
          MasterMerchant.guild_columns['sold']:IsDisabled(not value)
        end,
        disabled = function() return not MasterMerchant.systemSavedVariables.diplayGuildInfo end,
        default = MasterMerchant.systemDefault.diplaySalesInfo,
      },
      -- guild roster options
      [3] = {
        type = 'checkbox',
        name = GetString(MM_PURCHASES_COLUMN_NAME),
        tooltip = GetString(MM_PURCHASES_COLUMN_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.diplayPurchasesInfo end,
        setFunc = function(value)
          MasterMerchant.systemSavedVariables.diplayPurchasesInfo = value
          MasterMerchant.guild_columns['bought']:IsDisabled(not value)
        end,
        disabled = function() return not MasterMerchant.systemSavedVariables.diplayGuildInfo end,
        default = MasterMerchant.systemDefault.diplayPurchasesInfo,
      },
      [4] = {
        type = 'checkbox',
        name = GetString(MM_TAXES_COLUMN_NAME),
        tooltip = GetString(MM_TAXES_COLUMN_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.diplayTaxesInfo end,
        setFunc = function(value)
          MasterMerchant.systemSavedVariables.diplayTaxesInfo = value
          MasterMerchant.guild_columns['per']:IsDisabled(not value)
        end,
        disabled = function() return not MasterMerchant.systemSavedVariables.diplayGuildInfo end,
        default = MasterMerchant.systemDefault.diplayTaxesInfo,
      },
      [5] = {
        type = 'checkbox',
        name = GetString(MM_COUNT_COLUMN_NAME),
        tooltip = GetString(MM_COUNT_COLUMN_TIP),
        getFunc = function() return MasterMerchant.systemSavedVariables.diplayCountInfo end,
        setFunc = function(value)
          MasterMerchant.systemSavedVariables.diplayCountInfo = value
          MasterMerchant.guild_columns['count']:IsDisabled(not value)
        end,
        disabled = function() return not MasterMerchant.systemSavedVariables.diplayGuildInfo end,
        default = MasterMerchant.systemDefault.diplayCountInfo,
      },
    },
  }
  -- 10 Other Tooltips -----------------------------------
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(MASTER_MERCHANT_TOOLTIP_OPTIONS),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#OtherTooltipOptions",
  }
  -- Whether or not to show the pricing graph in tooltips
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_SHOW_GRAPH_NAME),
    tooltip = GetString(SK_SHOW_GRAPH_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showGraph end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showGraph = value end,
    default = MasterMerchant.systemDefault.showGraph,
  }
  -- Whether or not to show the pricing data in tooltips
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_SHOW_PRICING_NAME),
    tooltip = GetString(SK_SHOW_PRICING_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showPricing end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showPricing = value end,
    default = MasterMerchant.systemDefault.showPricing,
  }
  -- Whether or not to show the alternate TTC price in tooltips
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_SHOW_TTC_PRICE_NAME),
    tooltip = GetString(SK_SHOW_TTC_PRICE_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showAltTtcTipline end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showAltTtcTipline = value end,
    default = MasterMerchant.systemDefault.showAltTtcTipline,
  }
  -- Whether or not to show the bonanza price in tooltips
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_SHOW_BONANZA_PRICE_NAME),
    tooltip = GetString(SK_SHOW_BONANZA_PRICE_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showBonanzaPricing end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showBonanzaPricing = value end,
    default = MasterMerchant.systemDefault.showBonanzaPricing,
  }
  -- Whether or not to show the bonanza price if less then 6 listings
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_BONANZA_PRICEONGRAPH_NAME),
    tooltip = GetString(MM_BONANZA_PRICEONGRAPH_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.omitBonanzaPricingGraphLessThanSix end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.omitBonanzaPricingGraphLessThanSix = value end,
    default = MasterMerchant.systemDefault.omitBonanzaPricingGraphLessThanSix,
  }
  -- Whether or not to show tooltips on the graph points
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_GRAPH_INFO_NAME),
    tooltip = GetString(MM_GRAPH_INFO_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.displaySalesDetails end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.displaySalesDetails = value
    end,
    default = MasterMerchant.systemDefault.displaySalesDetails,
  }
  -- Whether or not to show the crafting costs data in tooltips
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_SHOW_CRAFT_COST_NAME),
    tooltip = GetString(SK_SHOW_CRAFT_COST_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showCraftCost end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showCraftCost = value end,
    default = MasterMerchant.systemDefault.showCraftCost,
  }
  -- Whether or not to show the material cost data in tooltips
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_SHOW_MATERIAL_COST_NAME),
    tooltip = GetString(SK_SHOW_MATERIAL_COST_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showMaterialCost end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showMaterialCost = value end,
    default = MasterMerchant.systemDefault.showMaterialCost,
  }
  -- Whether or not to show the quality/level adjustment buttons
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_LEVEL_QUALITY_NAME),
    tooltip = GetString(MM_LEVEL_QUALITY_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.displayItemAnalysisButtons end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.displayItemAnalysisButtons = value end,
    default = MasterMerchant.systemDefault.displayItemAnalysisButtons,
  }
  -- should we trim off decimals?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_TRIM_DECIMALS_NAME),
    tooltip = GetString(SK_TRIM_DECIMALS_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.trimDecimals end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.trimDecimals = value end,
    default = MasterMerchant.systemDefault.trimDecimals,
  }
  -- Section: Outlier Options
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(MM_OUTLIER_OPTIONS_HEADER),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#OutlierOptions",
  }
  -- should we remove outer percentiles
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_OUTLIER_PERCENTILE_NAME),
    tooltip = GetString(MM_OUTLIER_PERCENTILE_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.trimOutliersWithPercentile end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.trimOutliersWithPercentile = value
      mmUtils:ResetItemAndBonanzaCache()
    end,
    default = MasterMerchant.systemDefault.trimOutliersWithPercentile,
    disabled = function() return MasterMerchant.systemSavedVariables.trimOutliers end,
  }
  -- remove outer percentiles percentile
  optionsData[#optionsData + 1] = {
    type = 'slider',
    name = GetString(MM_OUTLIER_PERCENTILE_VALUE_NAME),
    tooltip = GetString(MM_OUTLIER_PERCENTILE_VALUE_TIP),
    min = 1,
    max = 15,
    getFunc = function() return MasterMerchant.systemSavedVariables.outlierPercentile end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.outlierPercentile = value
      mmUtils:ResetItemAndBonanzaCache()
    end,
    default = MasterMerchant.systemDefault.outlierPercentile,
    disabled = function() return not MasterMerchant.systemSavedVariables.trimOutliersWithPercentile end,
  }
  -- should we trim outliers prices?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_TRIM_OUTLIERS_NAME),
    tooltip = GetString(SK_TRIM_OUTLIERS_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.trimOutliers end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.trimOutliers = value
      mmUtils:ResetItemAndBonanzaCache()
    end,
    default = MasterMerchant.systemDefault.trimOutliers,
    disabled = function() return MasterMerchant.systemSavedVariables.trimOutliersWithPercentile end,
  }
  -- use agressive triming for outliers
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_AGRESSIVE_TRIM_OUTLIERS_NAME),
    tooltip = GetString(MM_AGRESSIVE_TRIM_OUTLIERS_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.trimOutliersAgressive end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.trimOutliersAgressive = value
      mmUtils:ResetItemAndBonanzaCache()
    end,
    default = MasterMerchant.systemDefault.trimOutliersAgressive,
    disabled = function() return not MasterMerchant.systemSavedVariables.trimOutliers end,
  }
  -- Section: Price To Chat and Graphtip Options
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(MM_PTC_OPTIONS_HEADER),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#PriceToChatOptions",
  }
  -- Whether or not to show individual item count
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_PTC_CONDENSED_FORMAT_NAME),
    tooltip = GetString(MM_PTC_CONDENSED_FORMAT_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.useCondensedPriceToChat end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.useCondensedPriceToChat = value end,
    default = MasterMerchant.systemDefault.useCondensedPriceToChat,
  }
  -- Whether or not to show ttc info
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_PTC_TTC_DATA_NAME),
    tooltip = GetString(MM_PTC_TTC_DATA_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.includeTTCDataPriceToChat end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.includeTTCDataPriceToChat = value end,
    default = MasterMerchant.systemDefault.includeTTCDataPriceToChat,
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_PTC_ITEM_COUNT_NAME),
    tooltip = GetString(MM_PTC_ITEM_COUNT_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.includeItemCountPriceToChat end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.includeItemCountPriceToChat = value end,
    default = MasterMerchant.systemDefault.includeItemCountPriceToChat,
    disabled = function() return MasterMerchant.systemSavedVariables.useCondensedPriceToChat end,
  }
  -- Whether or not to show the bonanza price if less then 6 listings
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_PTC_BONANZA_NAME),
    tooltip = GetString(MM_PTC_BONANZA_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.omitBonanzaPricingChatLessThanSix end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.omitBonanzaPricingChatLessThanSix = value end,
    default = MasterMerchant.systemDefault.omitBonanzaPricingChatLessThanSix,
  }
  -- should we ommit price per voucher?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_PTC_ADD_VOUCHER_NAME),
    tooltip = GetString(MM_PTC_ADD_VOUCHER_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.includeVoucherAverage end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.includeVoucherAverage = value end,
    default = MasterMerchant.systemDefault.includeVoucherAverage,
  }
  -- replace inventory value type
  optionsData[#optionsData + 1] = {
    type = 'dropdown',
    name = GetString(MM_PTC_VOUCHER_VALUE_TYPE_NAME),
    tooltip = GetString(MM_PTC_VOUCHER_VALUE_TYPE_TIP),
    choices = MasterMerchant.dealCalcChoices,
    choicesValues = MasterMerchant.dealCalcValues,
    getFunc = function() return MasterMerchant.systemSavedVariables.voucherValueTypeToUse end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.voucherValueTypeToUse = value
      CheckVoucherValue()
    end,
    default = MasterMerchant.systemDefault.voucherValueTypeToUse,
    disabled = function() return not MasterMerchant.systemSavedVariables.includeVoucherAverage end,
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_MODIFIED_TTC_SUGGESTED_NAME),
    tooltip = GetString(MM_MODIFIED_TTC_SUGGESTED_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.modifiedSuggestedPriceVoucher end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.modifiedSuggestedPriceVoucher = value end,
    default = MasterMerchant.systemDefault.modifiedSuggestedPriceVoucher,
    disabled = function() return (not MasterMerchant.systemSavedVariables.includeVoucherAverage) or (MasterMerchant.systemSavedVariables.voucherValueTypeToUse ~= MM_PRICE_TTC_SUGGESTED) end,
  }
  -- Section: Inventory Options
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(MASTER_MERCHANT_INVENTORY_OPTIONS),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#InventoryOptions",
  }
  -- should we replace inventory values?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_REPLACE_INVENTORY_VALUES_NAME),
    tooltip = GetString(MM_REPLACE_INVENTORY_VALUES_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.replaceInventoryValues end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.replaceInventoryValues = value end,
    default = MasterMerchant.systemDefault.replaceInventoryValues,
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_REPLACE_INVENTORY_SHOW_UNITPRICE_NAME),
    tooltip = GetString(MM_REPLACE_INVENTORY_SHOW_UNITPRICE_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showUnitPrice end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showUnitPrice = value end,
    default = MasterMerchant.systemDefault.showUnitPrice,
    disabled = function() return not MasterMerchant.systemSavedVariables.replaceInventoryValues end,
  }
  -- replace inventory value type
  optionsData[#optionsData + 1] = {
    type = 'dropdown',
    name = GetString(MM_REPLACE_INVENTORY_VALUE_TYPE_NAME),
    tooltip = GetString(MM_REPLACE_INVENTORY_VALUE_TYPE_TIP),
    choices = MasterMerchant.dealCalcChoices,
    choicesValues = MasterMerchant.dealCalcValues,
    getFunc = function() return MasterMerchant.systemSavedVariables.replacementTypeToUse end,
    setFunc = function(value)
      MasterMerchant.systemSavedVariables.replacementTypeToUse = value
      CheckInventoryValue()
    end,
    default = MasterMerchant.systemDefault.replacementTypeToUse,
    disabled = function() return not MasterMerchant.systemSavedVariables.replaceInventoryValues end,
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_MODIFIED_TTC_SUGGESTED_NAME),
    tooltip = GetString(MM_MODIFIED_TTC_SUGGESTED_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.modifiedSuggestedPriceInventory end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.modifiedSuggestedPriceInventory = value end,
    default = MasterMerchant.systemDefault.modifiedSuggestedPriceInventory,
    disabled = function() return (not MasterMerchant.systemSavedVariables.replaceInventoryValues) or (MasterMerchant.systemSavedVariables.replacementTypeToUse ~= MM_PRICE_TTC_SUGGESTED) end,
  }
  -- hide Bonanza context menu
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_SHOW_SEARCH_BONANZA_NAME),
    tooltip = GetString(MM_SHOW_SEARCH_BONANZA_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showSearchBonanza end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showSearchBonanza = value end,
    default = MasterMerchant.systemDefault.showSearchBonanza,
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GUILD_STORE_OPTIONS),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#GuildStoreOptions",
  }
  -- Should we show the stack price calculator in the Vanilla UI?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_CALC_NAME),
    tooltip = GetString(SK_CALC_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showCalc end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showCalc = value end,
    default = MasterMerchant.systemDefault.showCalc,
    disabled = function() return MasterMerchant.AwesomeGuildStoreDetected end,
  }
  -- Should we use one price for all or save by guild?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(SK_ALL_CALC_NAME),
    tooltip = GetString(SK_ALL_CALC_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.priceCalcAll end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.priceCalcAll = value end,
    default = MasterMerchant.systemDefault.priceCalcAll,
  }
  -- should we display a Min Profit Filter in AGS?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_MIN_PROFIT_FILTER_NAME),
    tooltip = GetString(MM_MIN_PROFIT_FILTER_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.minProfitFilter end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.minProfitFilter = value end,
    default = MasterMerchant.systemDefault.minProfitFilter,
    disabled = function() return not MasterMerchant.AwesomeGuildStoreDetected end,
    warning = GetString(MM_RELOADUI_WARN),
  }
  -- should we display profit instead of margin?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_DISPLAY_PROFIT_NAME),
    tooltip = GetString(MM_DISPLAY_PROFIT_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.displayProfit end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.displayProfit = value end,
    default = MasterMerchant.systemDefault.displayProfit,
  }
  -- ascending vs descending sort order with AGS
  optionsData[#optionsData + 1] = {
    type = 'dropdown',
    name = GetString(AGS_PERCENT_ORDER_NAME),
    tooltip = GetString(AGS_PERCENT_ORDER_DESC),
    choices = MasterMerchant.agsPercentSortChoices,
    choicesValues = MasterMerchant.agsPercentSortValues,
    getFunc = function() return MasterMerchant.systemSavedVariables.agsPercentSortOrderToUse end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.agsPercentSortOrderToUse = value end,
    default = MasterMerchant.systemDefault.agsPercentSortOrderToUse,
    disabled = function() return not MasterMerchant.AwesomeGuildStoreDetected end,
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(GUILD_MASTER_OPTIONS),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#GuildMasterOptions",
  }
  -- should we add taxes to the export?
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_SHOW_AMOUNT_TAXES_NAME),
    tooltip = GetString(MM_SHOW_AMOUNT_TAXES_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.showAmountTaxes end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.showAmountTaxes = value end,
    default = MasterMerchant.systemDefault.showAmountTaxes,
  }
  optionsData[#optionsData + 1] = {
    type = "header",
    name = GetString(MASTER_MERCHANT_DEBUG_OPTIONS),
    width = "full",
    helpUrl = "https://esouimods.github.io/3-master_merchant.html#MMDebugOptions",
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_DEBUG_LOGGER_NAME),
    tooltip = GetString(MM_DEBUG_LOGGER_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.useLibDebugLogger end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.useLibDebugLogger = value end,
    default = MasterMerchant.systemDefault.useLibDebugLogger,
  }
  optionsData[#optionsData + 1] = {
    type = 'checkbox',
    name = GetString(MM_DISABLE_ATT_WARN_NAME),
    tooltip = GetString(MM_DISABLE_ATT_WARN_TIP),
    getFunc = function() return MasterMerchant.systemSavedVariables.disableAttWarn end,
    setFunc = function(value) MasterMerchant.systemSavedVariables.disableAttWarn = value end,
    default = MasterMerchant.systemDefault.disableAttWarn,
  }

  -- And make the options panel
  LAM:RegisterOptionControls('MasterMerchantOptions', optionsData)
end