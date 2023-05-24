-- MasterMerchant UI Functions File
-- Last Updated September 15, 2014
-- Written August 2014 by Dan Stone (@khaibit) - dankitymao@gmail.com
-- Extended February 2015 by Chris Lasswell (@Philgo68) - Philgo68@gmail.com
-- Released under terms in license accompanying this file.
-- Distribution without license is prohibited!

-- Sort scrollList by price in 'ordering' order (asc = true as per ZOS)
-- Rather than using the built-in Lua quicksort, we use my own
-- implementation of Shellsort to save on memory.
local LMP = LibMediaProvider
local internal = _G["LibGuildStore_Internal"]
local sales_data = _G["LibGuildStore_SalesData"]
local sr_index = _G["LibGuildStore_SalesIndex"]
local listings_data = _G["LibGuildStore_ListingsData"]
local lr_index = _G["LibGuildStore_ListingsIndex"]
local purchases_data = _G["LibGuildStore_PurchaseData"]
local pr_index = _G["LibGuildStore_PurchaseIndex"]

local posted_items_data = _G["LibGuildStore_PostedItemsData"]
local pir_index = _G["LibGuildStore_PostedItemsIndex"]
local cancelled_items_data = _G["LibGuildStore_CancelledItemsData"]
local cr_index = _G["LibGuildStore_CancelledItemsIndex"]

--[[ TODO Verify this
when viewSize is 'full': then you are viewing the seller information
when viewSize if 'half': you are viewing the item information
]]--

--[[ can not use MasterMerchant.itemsViewSize for example
because that will not be available this early.
]]--
local ITEMS = 'items_vs'
local GUILDS = 'guild_vs'
local LISTINGS = 'listings_vs'
local PURCHASES = 'purchases_vs'
local REPORTS = 'reports_vs'

local SALES_WINDOW_DATAROW = "MasterMerchantDataRow"
local GUILD_WINDOW_DATAROW = "MasterMerchantGuildDataRow"
local LISTING_WINDOW_DATAROW = "MasterMerchantListingDataRow"
local PURCHASE_WINDOW_DATAROW = "MasterMerchantPurchaseDataRow"
local REPORTS_WINDOW_DATAROW = "MasterMerchantReportsDataRow"

local SALES_WINDOW_CONTROL_NAME = "MasterMerchantWindow"
local GUILD_WINDOW_CONTROL_NAME = "MasterMerchantGuildWindow"
local LISTING_WINDOW_CONTROL_NAME = "MasterMerchantListingWindow"
local PURCHASE_WINDOW_CONTROL_NAME = "MasterMerchantPurchaseWindow"
local REPORTS_WINDOW_CONTROL_NAME = "MasterMerchantReportsWindow"

local SALES_WINDOW_CONTROL_NAME_REGEX = "^MasterMerchantWindow"
local GUILD_WINDOW_CONTROL_NAME_REGEX = "^MasterMerchantGuildWindow"
local LISTING_WINDOW_CONTROL_NAME_REGEX = "^MasterMerchantListingWindow"
local PURCHASE_WINDOW_CONTROL_NAME_REGEX = "^MasterMerchantPurchaseWindow"
local REPORTS_WINDOW_CONTROL_NAME_REGEX = "^MasterMerchantReportsWindow"

function MasterMerchant:ActiveWindow()
  return ((MasterMerchant.systemSavedVariables.viewSize == ITEMS and MasterMerchantWindow) or
    (MasterMerchant.systemSavedVariables.viewSize == GUILDS and MasterMerchantGuildWindow) or
    (MasterMerchant.systemSavedVariables.viewSize == LISTINGS and MasterMerchantListingWindow) or
    (MasterMerchant.systemSavedVariables.viewSize == PURCHASES and MasterMerchantPurchaseWindow) or
    (MasterMerchant.systemSavedVariables.viewSize == REPORTS and MasterMerchantReportsWindow))
end

function MasterMerchant:ActiveFragment()
  return ((MasterMerchant.systemSavedVariables.viewSize == ITEMS and self.salesUiFragment) or
    (MasterMerchant.systemSavedVariables.viewSize == GUILDS and self.guildUiFragment) or
    (MasterMerchant.systemSavedVariables.viewSize == LISTINGS and self.listingUiFragment) or
    (MasterMerchant.systemSavedVariables.viewSize == PURCHASES and self.purchaseUiFragment) or
    (MasterMerchant.systemSavedVariables.viewSize == REPORTS and self.reportsUiFragment))
end

function MasterMerchant:GetLockButtonTooltipText()
  if MasterMerchant.systemSavedVariables.isWindowMovable then
    return GetString(MM_LOCK_TOOLTIP)
  else
    return GetString(MM_UNLOCK_TOOLTIP)
  end
end

function MasterMerchant:SetWindowLockIcon()
  local unlocked_up = "/esoui/art/miscellaneous/unlocked_up.dds"
  local unlocked_over = "/esoui/art/miscellaneous/unlocked_over.dds"
  local locked_up = "/esoui/art/miscellaneous/locked_up.dds"
  local locked_over = "/esoui/art/miscellaneous/locked_over.dds"
  if MasterMerchant.systemSavedVariables.isWindowMovable then
    MasterMerchantWindowMenuHeaderLockButton:SetNormalTexture(unlocked_up)
    MasterMerchantGuildWindowMenuHeaderLockButton:SetNormalTexture(unlocked_up)
    MasterMerchantListingWindowMenuHeaderLockButton:SetNormalTexture(unlocked_up)
    MasterMerchantPurchaseWindowMenuHeaderLockButton:SetNormalTexture(unlocked_up)
    MasterMerchantReportsWindowMenuHeaderLockButton:SetNormalTexture(unlocked_up)

    MasterMerchantWindowMenuHeaderLockButton:SetMouseOverTexture(unlocked_over)
    MasterMerchantGuildWindowMenuHeaderLockButton:SetMouseOverTexture(unlocked_over)
    MasterMerchantListingWindowMenuHeaderLockButton:SetMouseOverTexture(unlocked_over)
    MasterMerchantPurchaseWindowMenuHeaderLockButton:SetMouseOverTexture(unlocked_over)
    MasterMerchantReportsWindowMenuHeaderLockButton:SetMouseOverTexture(unlocked_over)
  else
    MasterMerchantWindowMenuHeaderLockButton:SetNormalTexture(locked_up)
    MasterMerchantGuildWindowMenuHeaderLockButton:SetNormalTexture(locked_up)
    MasterMerchantListingWindowMenuHeaderLockButton:SetNormalTexture(locked_up)
    MasterMerchantPurchaseWindowMenuHeaderLockButton:SetNormalTexture(locked_up)
    MasterMerchantReportsWindowMenuHeaderLockButton:SetNormalTexture(locked_up)

    MasterMerchantWindowMenuHeaderLockButton:SetMouseOverTexture(locked_over)
    MasterMerchantGuildWindowMenuHeaderLockButton:SetMouseOverTexture(locked_over)
    MasterMerchantListingWindowMenuHeaderLockButton:SetMouseOverTexture(locked_over)
    MasterMerchantPurchaseWindowMenuHeaderLockButton:SetMouseOverTexture(locked_over)
    MasterMerchantReportsWindowMenuHeaderLockButton:SetMouseOverTexture(locked_over)
  end
end

function MasterMerchant:SetWindowLock()
  MasterMerchantWindow:SetMovable(MasterMerchant.systemSavedVariables.isWindowMovable)
  MasterMerchantGuildWindow:SetMovable(MasterMerchant.systemSavedVariables.isWindowMovable)
  MasterMerchantListingWindow:SetMovable(MasterMerchant.systemSavedVariables.isWindowMovable)
  MasterMerchantPurchaseWindow:SetMovable(MasterMerchant.systemSavedVariables.isWindowMovable)
  MasterMerchantReportsWindow:SetMovable(MasterMerchant.systemSavedVariables.isWindowMovable)
end

function MasterMerchant:ToggleWindowLock()
  MasterMerchant.systemSavedVariables.isWindowMovable = not MasterMerchant.systemSavedVariables.isWindowMovable

  MasterMerchant:SetWindowLock()
  MasterMerchant:SetWindowLockIcon()
end

function MasterMerchant:SortByPrice(ordering, scrollList)
  local listData = ZO_ScrollList_GetDataList(scrollList.list)

  if not ordering then
    -- If they're viewing prices per-unit, then we need to sort on price / quantity.
    if MasterMerchant.systemSavedVariables.showUnitPrice then
      MasterMerchant.shellSort(listData, function(sortA, sortB)
        -- In case quantity ends up 0 or nil somehow, let's not divide by it
        if sortA.data[6] and sortA.data[6] > 0 and sortB.data[6] and sortB.data[6] > 0 then
          return ((sortA.data[5] or 0) / sortA.data[6]) > ((sortB.data[5] or 0) / sortB.data[6])
        else return (sortA.data[5] or 0) > (sortB.data[5] or 0) end
      end)
      -- Otherwise just sort on pure price.
    else
      MasterMerchant.shellSort(listData, function(sortA, sortB)
        return (sortA.data[5] or 0) > (sortB.data[5] or 0)
      end)
    end
  else
    -- And the same thing with descending sort
    if MasterMerchant.systemSavedVariables.showUnitPrice then
      MasterMerchant.shellSort(listData, function(sortA, sortB)
        -- In case quantity ends up 0 or nil somehow, let's not divide by it
        if sortA.data[6] and sortA.data[6] > 0 and sortB.data[6] and sortB.data[6] > 0 then
          return ((sortA.data[5] or 0) / sortA.data[6]) < ((sortB.data[5] or 0) / sortB.data[6])
        else return (sortA.data[5] or 0) < (sortB.data[5] or 0) end
      end)
    else
      MasterMerchant.shellSort(listData, function(sortA, sortB)
        return (sortA.data[5] or 0) < (sortB.data[5] or 0)
      end)
    end
  end
end

-- Sort the scrollList by time in 'ordering' order (asc = true as per ZOS).
function MasterMerchant:SortByTime(ordering, scrollList)
  local listData = ZO_ScrollList_GetDataList(scrollList.list)

  if not ordering then
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (sortA.data[4] or 0) < (sortB.data[4] or 0)
    end)
  else
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (sortA.data[4] or 0) > (sortB.data[4] or 0)
    end)
  end
end

function MasterMerchant:SortBySales(ordering, scrollList)
  local listData = ZO_ScrollList_GetDataList(scrollList.list)

  if not ordering then
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (sortA.data[3] or 0) > (sortB.data[3] or 0)
    end)
  else
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (sortA.data[3] or 0) < (sortB.data[3] or 0)
    end)
  end
end

function MasterMerchant:SortByRank(ordering, scrollList)
  local listData = ZO_ScrollList_GetDataList(scrollList.list)

  if not ordering then
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (sortA.data[4] or 9999) > (sortB.data[4] or 9999)
    end)
  else
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (sortA.data[4] or 9999) < (sortB.data[4] or 9999)
    end)
  end
end

function MasterMerchant:SortByCount(ordering, scrollList)
  local listData = ZO_ScrollList_GetDataList(scrollList.list)

  if not ordering then
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (sortA.data[5] or 0) > (sortB.data[5] or 0)
    end)
  else
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (sortA.data[5] or 0) < (sortB.data[5] or 0)
    end)
  end
end

function MasterMerchant:SortByTax(ordering, scrollList)
  local listData = ZO_ScrollList_GetDataList(scrollList.list)

  if not ordering then
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (sortA.data[8] or 0) > (sortB.data[8] or 0)
    end)
  else
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (sortA.data[8] or 0) < (sortB.data[8] or 0)
    end)
  end
end

--[[ TODO this is for ordering the buyer, seller name for the ranks
view. Which doesn't really work. When it is the buyer or seller name
then it's @Something. When it's the item view then it's by item link
which doesn't really sort.

zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink))

If I use zo_strformat with the Item Link name it pretty much freezes the
game
]]--
function MasterMerchant:SortByName(ordering, scrollList)
  local listData = ZO_ScrollList_GetDataList(scrollList.list)
  if not ordering then
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (sortA.data[2] or 0) > (sortB.data[2] or 0)
    end)
  else
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (sortA.data[2] or 0) < (sortB.data[2] or 0)
    end)
  end
end

function MasterMerchant:SortByPurchaseAccountName(ordering, scrollList)
  local listData = ZO_ScrollList_GetDataList(scrollList.list)
  if not ordering then
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      local actualItemA = purchases_data[sortA.data[1]][sortA.data[2]]['sales'][sortA.data[3]]
      local actualItemB = purchases_data[sortB.data[1]][sortB.data[2]]['sales'][sortB.data[3]]
      local nameA = internal:GetAccountNameByIndex(actualItemA['seller'])
      local nameB = internal:GetAccountNameByIndex(actualItemB['seller'])
      return (nameA or 0) > (nameB or 0)
    end)
  else
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      local actualItemA = purchases_data[sortA.data[1]][sortA.data[2]]['sales'][sortA.data[3]]
      local actualItemB = purchases_data[sortB.data[1]][sortB.data[2]]['sales'][sortB.data[3]]
      local nameA = internal:GetAccountNameByIndex(actualItemA['seller'])
      local nameB = internal:GetAccountNameByIndex(actualItemB['seller'])
      return (nameA or 0) < (nameB or 0)
    end)
  end
end

function MasterMerchant:SortByGuildName(ordering, scrollList)
  local listData = ZO_ScrollList_GetDataList(scrollList.list)
  if not ordering then
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (sortA.data[1] or 0) > (sortB.data[1] or 0)
    end)
  else
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (sortA.data[1] or 0) < (sortB.data[1] or 0)
    end)
  end
end

function MasterMerchant:SortBySalesItemGuildName(ordering, scrollList)
  local listData = ZO_ScrollList_GetDataList(scrollList.list)
  if not ordering then
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (sales_data[sortA.data[1]][sortA.data[2]]['sales'][sortA.data[3]]['guild'] or 0) > (sales_data[sortB.data[1]][sortB.data[2]]['sales'][sortB.data[3]]['guild'] or 0)
    end)
  else
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (sales_data[sortA.data[1]][sortA.data[2]]['sales'][sortA.data[3]]['guild'] or 0) < (sales_data[sortB.data[1]][sortB.data[2]]['sales'][sortB.data[3]]['guild'] or 0)
    end)
  end
end

function MasterMerchant:SortByListingItemGuildName(ordering, scrollList)
  local listData = ZO_ScrollList_GetDataList(scrollList.list)
  if not ordering then
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (listings_data[sortA.data[1]][sortA.data[2]]['sales'][sortA.data[3]]['guild'] or 0) > (listings_data[sortB.data[1]][sortB.data[2]]['sales'][sortB.data[3]]['guild'] or 0)
    end)
  else
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (listings_data[sortA.data[1]][sortA.data[2]]['sales'][sortA.data[3]]['guild'] or 0) < (listings_data[sortB.data[1]][sortB.data[2]]['sales'][sortB.data[3]]['guild'] or 0)
    end)
  end
end

function MasterMerchant:SortByPurchaseItemGuildName(ordering, scrollList)
  local listData = ZO_ScrollList_GetDataList(scrollList.list)
  if not ordering then
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (purchases_data[sortA.data[1]][sortA.data[2]]['sales'][sortA.data[3]]['guild'] or 0) > (purchases_data[sortB.data[1]][sortB.data[2]]['sales'][sortB.data[3]]['guild'] or 0)
    end)
  else
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (purchases_data[sortA.data[1]][sortA.data[2]]['sales'][sortA.data[3]]['guild'] or 0) < (purchases_data[sortB.data[1]][sortB.data[2]]['sales'][sortB.data[3]]['guild'] or 0)
    end)
  end
end

function MasterMerchant:SortByReportItemGuildName(ordering, scrollList)
  local listData = ZO_ScrollList_GetDataList(scrollList.list)
  local dataTable
  if MasterMerchant.reportsViewMode == MasterMerchant.reportsPostedViewMode then
    dataTable = posted_items_data
  elseif MasterMerchant.reportsViewMode == MasterMerchant.reportsCanceledViewMode then
    dataTable = cancelled_items_data
  end
  if not ordering then
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      local guildNameA = dataTable[sortA.data[1]][sortA.data[2]]['sales'][sortA.data[3]]['guild']
      local guildNameB = dataTable[sortB.data[1]][sortB.data[2]]['sales'][sortB.data[3]]['guild']
      local nameA = internal:GetGuildNameByIndex(guildNameA)
      local nameB = internal:GetGuildNameByIndex(guildNameB)
      return (nameA or 0) > (nameB or 0)
    end)
  else
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      local guildNameA = dataTable[sortA.data[1]][sortA.data[2]]['sales'][sortA.data[3]]['guild']
      local guildNameB = dataTable[sortB.data[1]][sortB.data[2]]['sales'][sortB.data[3]]['guild']
      local nameA = internal:GetGuildNameByIndex(guildNameA)
      local nameB = internal:GetGuildNameByIndex(guildNameB)
      return (nameA or 0) < (nameB or 0)
    end)
  end
end

function MMScrollList:SetupSalesRow(control, data)

  control.rowId = GetControl(control, 'RowId')
  control.buyer = GetControl(control, 'Buyer')
  control.guild = GetControl(control, 'Guild')
  control.icon = GetControl(control, 'ItemIcon')
  control.quant = GetControl(control, 'Quantity')
  control.itemName = GetControl(control, 'ItemName')
  control.sellTime = GetControl(control, 'SellTime')
  control.price = GetControl(control, 'Price')

  if (sales_data[data[1]] == nil) then
    -- just starting up so just bail out
    return
  end

  if (sales_data[data[1]][data[2]] == nil) then
    --d('MM Data Error:')
    --d(data[1])
    --d(data[2])
    --d('--------')
    return
  end

  if (sales_data[data[1]][data[2]]['sales'] == nil) then
    --d('MM Data Error:')
    --d(data[1])
    --d(data[2])
    --d('No Sales')
    --d('--------')
    return
  end

  if (sales_data[data[1]][data[2]]['sales'][data[3]] == nil) then
    --d('MM Data Error:')
    --d(data[1])
    --d(data[2])
    --d(data[3])
    --d('--------')
    return
  end

  --[[
  local controlName = control:GetName()
  if not string.find(controlName, SALES_WINDOW_CONTROL_NAME_REGEX) then
    MasterMerchant:dm("Warn", controlName)
    return
  else
    MasterMerchant:dm("Debug", controlName)
  end
  ]]--
  local actualItem = sales_data[data[1]][data[2]]['sales'][data[3]]
  local currentItemLink = internal:GetItemLinkByIndex(actualItem['itemLink'])
  local currentGuild = internal:GetGuildNameByIndex(actualItem['guild'])
  local currentBuyer = internal:GetAccountNameByIndex(actualItem['buyer'])
  local currentSeller = internal:GetAccountNameByIndex(actualItem['seller'])
  local actualItemIcon = sales_data[data[1]][data[2]]['itemIcon']
  local isFullSize = string.find(control:GetName(), SALES_WINDOW_CONTROL_NAME_REGEX)

  local fontString = LMP:Fetch('font', MasterMerchant.systemSavedVariables.windowFont) .. '|%d'

  control.rowId:SetFont(string.format(fontString, 12))
  control.buyer:SetFont(string.format(fontString, 15))
  control.guild:SetFont(string.format(fontString, ((isFullSize and 15) or 11)))
  control.itemName:SetFont(string.format(fontString, ((isFullSize and 15) or 11)))
  control.quant:SetFont(string.format(fontString, ((isFullSize and 15) or 10)) .. '|soft-shadow-thin')
  control.sellTime:SetFont(string.format(fontString, ((isFullSize and 15) or 11)))
  control.price:SetFont(string.format(fontString, ((isFullSize and 15) or 11)))

  control.rowId:SetText(data.sortIndex)

  -- Some extra stuff for the Buyer cell to handle double-click and color changes
  -- Plus add a marker if buyer is not in-guild (kiosk sale)

  local buyerString
  if MasterMerchant.systemSavedVariables.viewBuyerSeller == 'buyer' then
    buyerString = currentBuyer
  else
    buyerString = currentSeller
  end

  control.buyer:GetLabelControl():SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
  control.buyer:SetText(buyerString)
  -- If the seller is the player, color the buyer green.  Otherwise, blue.
  local acctName = GetDisplayName()
  if zo_strlower(currentSeller) == zo_strlower(acctName) then
    control.buyer:SetNormalFontColor(0.18, 0.77, 0.05, 1)
    control.buyer:SetPressedFontColor(0.18, 0.77, 0.05, 1)
    control.buyer:SetMouseOverFontColor(0.32, 0.90, 0.18, 1)
  else
    control.buyer:SetNormalFontColor(0.21, 0.54, 0.94, 1)
    control.buyer:SetPressedFontColor(0.21, 0.54, 0.94, 1)
    control.buyer:SetMouseOverFontColor(0.34, 0.67, 1, 1)
  end

  control.buyer:SetHandler('OnMouseUp', function(self, upInside)
    MasterMerchant:my_NameHandler_OnLinkMouseUp(buyerString, upInside, self)
  end)

  -- Guild cell
  local guildString = currentGuild
  if actualItem.wasKiosk then guildString = '|t16:16:/EsoUI/Art/icons/item_generic_coinbag.dds|t ' .. guildString else guildString = '     ' .. guildString end
  control.guild:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
  control.guild:SetText(guildString)

  -- Item Icon
  control.icon:SetHidden(false)
  control.icon:SetTexture(actualItemIcon)

  -- Item name cell
  control.itemName:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
  control.itemName:SetText(zo_strformat('<<t:1>>', currentItemLink))
  -- Insert the item link into the chat box, with a quick substitution so brackets show up
  --control.itemName:SetHandler('OnMouseDoubleClick', function()
  --  ZO_ChatWindowTextEntryEditBox:SetText(ZO_ChatWindowTextEntryEditBox:GetText() .. string.gsub(currentItemLink, '|H0', '|H1'))
  --end)
  control.itemName:SetHandler('OnMouseEnter', function() MasterMerchant.ShowToolTip(currentItemLink, control.itemName) end)
  control.itemName:SetHandler('OnMouseExit', function() ClearTooltip(ItemTooltip) end)

  -- Quantity cell
  if actualItem.quant == 1 then control.quant:SetHidden(true)
  else
    control.quant:SetHidden(false)
    control.quant:SetText(actualItem.quant)
  end

  -- Sale time cell
  control.sellTime:SetText(MasterMerchant.TextTimeSince(actualItem.timestamp))

  -- Handle the setting of whether or not to show pre-cut sale prices
  -- Insert thousands separators for the price
  local dispPrice = MasterMerchant:GetFullPriceOrProfit(actualItem.price, actualItem.quant)
  local stringPrice = MasterMerchant.LocalizedNumber(dispPrice)

  -- Finally, set the price
  control.price:SetText(stringPrice .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t')

  ZO_SortFilterList.SetupRow(self, control, data)
end

function MMScrollList:SetupGuildSalesRow(control, data)

  control.rowId = GetControl(control, 'RowId')
  control.seller = GetControl(control, 'Seller')
  control.itemName = GetControl(control, 'ItemName')
  control.guild = GetControl(control, 'Guild')
  control.rank = GetControl(control, 'Rank')
  control.sales = GetControl(control, 'Sales')
  control.tax = GetControl(control, 'Tax')
  control.count = GetControl(control, 'Count')
  control.percent = GetControl(control, 'Percent')

  if (data[1] == nil) then
    -- just starting up so just bail out
    return
  end

  --[[
  local controlName = control:GetName()
  if not string.find(controlName, GUILD_WINDOW_CONTROL_NAME_REGEX) then
    MasterMerchant:dm("Warn", controlName)
    return
  else
    MasterMerchant:dm("Debug", controlName)
  end
  ]]--
  local fontString = LMP:Fetch('font', MasterMerchant.systemSavedVariables.windowFont) .. '|%d'

  control.rowId:SetFont(string.format(fontString, 12))
  control.seller:SetFont(string.format(fontString, 15))
  control.itemName:SetFont(string.format(fontString, 15))
  control.guild:SetFont(string.format(fontString, 15))
  control.rank:SetFont(string.format(fontString, 15))
  control.sales:SetFont(string.format(fontString, 15))
  control.tax:SetFont(string.format(fontString, 15))
  control.count:SetFont(string.format(fontString, 15))
  control.percent:SetFont(string.format(fontString, 15))

  control.rowId:SetText(data.sortIndex)

  -- Some extra stuff for the Seller cell to handle double-click and color changes

  local sellerString = data[2]

  if (string.sub(sellerString, 1, 1) == '@' or sellerString == GetString(MM_ENTIRE_GUILD)) then
    control.itemName:SetHidden(true);
    control.seller:SetHidden(false);
    control.seller:GetLabelControl():SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
    control.seller:SetText(sellerString)
    -- If the seller is the player, color the buyer green.  Otherwise, blue.
    local acctName = GetDisplayName()
    if zo_strlower(sellerString) == zo_strlower(acctName) then
      control.seller:SetNormalFontColor(0.18, 0.77, 0.05, 1)
      control.seller:SetPressedFontColor(0.18, 0.77, 0.05, 1)
      control.seller:SetMouseOverFontColor(0.32, 0.90, 0.18, 1)
    else
      control.seller:SetNormalFontColor(0.21, 0.54, 0.94, 1)
      control.seller:SetPressedFontColor(0.21, 0.54, 0.94, 1)
      control.seller:SetMouseOverFontColor(0.34, 0.67, 1, 1)
    end
    control.seller:SetHandler('OnMouseUp', function(self, upInside)
      MasterMerchant:my_NameHandler_OnLinkMouseUp(sellerString, upInside, self)
    end)
  else
    -- Item name cell
    control.seller:SetHidden(true);
    control.itemName:SetHidden(false);
    control.itemName:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
    control.itemName:SetText(zo_strformat('<<t:1>>', sellerString))
    control.itemName:SetHandler('OnMouseEnter',
      function() MasterMerchant.ShowToolTip(sellerString, control.itemName) end)
    control.itemName:SetHandler('OnMouseExit', function() ClearTooltip(ItemTooltip) end)
  end

  -- Guild cell
  local guildString = ""
  if data[9] then guildString = '|t16:16:/EsoUI/Art/icons/item_generic_coinbag.dds|t ' .. data[1] else guildString = '     ' .. data[1] end
  control.guild:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
  control.guild:SetText(guildString)

  -- Rank Cell
  control.rank:SetText(data[4])

  -- Sales Cell
  local sales = data[3] or 0
  local stringSales = MasterMerchant.LocalizedNumber(sales)
  control.sales:SetText(stringSales .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t')

  -- Tax Cell
  --local taxAmount = math.floor((sales * GetTradingHouseCutPercentage() / 200))
  local taxAmount = data[8]
  local stringTax = MasterMerchant.LocalizedNumber(taxAmount)
  control.tax:SetText(stringTax .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t')

  -- Count Cell

  control.count:SetText((data[5] or '-') .. '/' .. (data[6] or '-'))

  -- Percent Cell
  if data[7] and data[7] ~= 0 then
    local percent = math.floor((1000 * sales / data[7]) + 0.5) / 10
    control.percent:SetText(percent .. GetString(MM_PERCENT_CHAR))
  else
    control.percent:SetText('--' .. GetString(MM_PERCENT_CHAR))
  end

  ZO_SortFilterList.SetupRow(self, control, data)
end

function MMScrollList:SetupListingsRow(control, data)

  control.rowId = GetControl(control, 'RowId')
  control.seller = GetControl(control, 'Seller')
  control.location = GetControl(control, 'Location')
  control.guild = GetControl(control, 'Guild')
  control.icon = GetControl(control, 'ItemIcon')
  control.quant = GetControl(control, 'Quantity')
  control.itemName = GetControl(control, 'ItemName')
  control.listTime = GetControl(control, 'ListingTime')
  control.price = GetControl(control, 'Price')

  if (listings_data[data[1]] == nil) then
    -- just starting up so just bail out
    return
  end

  if (listings_data[data[1]][data[2]] == nil) then
    --d('MM Data Error:')
    --d(data[1])
    --d(data[2])
    --d('--------')
    return
  end

  if (listings_data[data[1]][data[2]]['sales'] == nil) then
    --d('MM Data Error:')
    --d(data[1])
    --d(data[2])
    --d('No Sales')
    --d('--------')
    return
  end

  if (listings_data[data[1]][data[2]]['sales'][data[3]] == nil) then
    --d('MM Data Error:')
    --d(data[1])
    --d(data[2])
    --d(data[3])
    --d('--------')
    return
  end
  local actualItem = listings_data[data[1]][data[2]]['sales'][data[3]]
  if not actualItem.timestamp then
    MasterMerchant:dm("Warn", actualItem)
  end
  local currentItemLink = internal:GetItemLinkByIndex(actualItem['itemLink'])
  local currentGuild = internal:GetGuildNameByIndex(actualItem['guild'])
  local currentSeller = internal:GetAccountNameByIndex(actualItem['seller'])
  local actualItemIcon = listings_data[data[1]][data[2]]['itemIcon']
  local guildZone = nil
  local guildSubZone = nil
  local guildZoneId = nil
  local guildLocationInfo = {}
  local guildLocationKey = nil
  if internal.traderIdByNameLookup[currentGuild] then
    guildLocationKey = internal.traderIdByNameLookup[currentGuild]
    guildLocationInfo = GS17DataSavedVariables[internal.visitedNamespace][guildLocationKey]
    guildZone = guildLocationInfo.zoneName
    guildSubZone = guildLocationInfo.subzoneName
    guildZoneId = guildLocationInfo.zoneId
  end

  local fontString = LMP:Fetch('font', MasterMerchant.systemSavedVariables.windowFont) .. '|%d'

  control.rowId:SetFont(string.format(fontString, 12))
  control.seller:SetFont(string.format(fontString, 15))
  control.guild:SetFont(string.format(fontString, 15))
  control.location:SetFont(string.format(fontString, 15))
  control.quant:SetFont(string.format(fontString, 15) .. '|soft-shadow-thin')
  control.itemName:SetFont(string.format(fontString, 15))
  control.listTime:SetFont(string.format(fontString, 15))
  control.price:SetFont(string.format(fontString, 15))

  control.rowId:SetText(data.sortIndex)

  control.seller:SetText(currentSeller)
  control.seller:SetHandler('OnMouseUp', function(self, upInside) MasterMerchant:my_SellerColumn_OnLinkMouseUp(currentSeller, currentItemLink, upInside, self) end)

  -- Guild cell
  control.guild:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
  control.guild:SetText(currentGuild)

  -- Location cell
  local locationText = guildZone or ""
  local subZoneText = guildSubZone or ""
  local assignedZoneId = guildZoneId or 0
  control.location:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
  control.location:SetText(locationText)
  control.location:SetHandler('OnMouseEnter', function() ZO_Tooltips_ShowTextTooltip(control.location, TOP, subZoneText) end)
  control.location:SetHandler('OnMouseExit', function() ClearTooltip(InformationTooltip) end)
  control.location:SetHandler('OnMouseUp', function(self, upInside) MasterMerchant:my_GuildColumn_OnLinkMouseUp(assignedZoneId, upInside, self) end)

  -- Item Icon
  control.icon:SetHidden(false)
  control.icon:SetTexture(actualItemIcon)

  -- Item name cell
  control.itemName:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
  control.itemName:SetText(zo_strformat('<<t:1>>', currentItemLink))
  -- Insert the item link into the chat box, with a quick substitution so brackets show up
  --control.itemName:SetHandler('OnMouseDoubleClick', function()
  --  ZO_ChatWindowTextEntryEditBox:SetText(ZO_ChatWindowTextEntryEditBox:GetText() .. string.gsub(currentItemLink, '|H0', '|H1'))
  --end)
  control.itemName:SetHandler('OnMouseEnter', function() MasterMerchant.ShowToolTip(currentItemLink, control.itemName) end)
  control.itemName:SetHandler('OnMouseExit', function() ClearTooltip(ItemTooltip) end)
  control.itemName:SetHandler('OnMouseUp', function(self, upInside) MasterMerchant:my_AddFilterHandler_OnLinkMouseUp(currentItemLink, upInside, self) end)

  -- Quantity cell
  if actualItem.quant == 1 then control.quant:SetHidden(true)
  else
    control.quant:SetHidden(false)
    control.quant:SetText(actualItem.quant)
  end

  -- Sale time cell
  local dispTime = MasterMerchant.TextTimeSince(actualItem.timestamp)
  control.listTime:SetText(dispTime)

  -- Handle the setting of whether or not to show pre-cut sale prices
  -- math.floor(number + 0.5) is a quick shorthand way to round for
  -- positive values.
  local dispPrice = actualItem.price
  local quantity = actualItem.quant
  if MasterMerchant.systemSavedVariables.showUnitPrice and quantity > 0 then
    dispPrice = math.floor((dispPrice / quantity) + 0.5)
  end

  -- Insert thousands separators for the price
  local stringPrice = MasterMerchant.LocalizedNumber(dispPrice)

  -- Finally, set the price
  control.price:SetText(stringPrice .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t')

  ZO_SortFilterList.SetupRow(self, control, data)
end

function MMScrollList:SetupPurchasesRow(control, data)

  control.rowId = GetControl(control, 'RowId')
  control.seller = GetControl(control, 'Seller')
  control.guild = GetControl(control, 'Guild')
  control.icon = GetControl(control, 'ItemIcon')
  control.quant = GetControl(control, 'Quantity')
  control.itemName = GetControl(control, 'ItemName')
  control.purchaseTime = GetControl(control, 'PurchaseTime')
  control.price = GetControl(control, 'Price')

  if (purchases_data[data[1]] == nil) then
    -- just starting up so just bail out
    return
  end

  if (purchases_data[data[1]][data[2]] == nil) then
    --d('MM Data Error:')
    --d(data[1])
    --d(data[2])
    --d('--------')
    return
  end

  if (purchases_data[data[1]][data[2]]['sales'] == nil) then
    --d('MM Data Error:')
    --d(data[1])
    --d(data[2])
    --d('No Sales')
    --d('--------')
    return
  end

  if (purchases_data[data[1]][data[2]]['sales'][data[3]] == nil) then
    --d('MM Data Error:')
    --d(data[1])
    --d(data[2])
    --d(data[3])
    --d('--------')
    return
  end
  local actualItem = purchases_data[data[1]][data[2]]['sales'][data[3]]
  if not actualItem.timestamp then
    MasterMerchant:dm("Warn", actualItem)
  end
  local currentItemLink = internal:GetItemLinkByIndex(actualItem['itemLink'])
  local currentGuild = internal:GetGuildNameByIndex(actualItem['guild'])
  local currentBuyer = internal:GetAccountNameByIndex(actualItem['buyer'])
  local currentSeller = internal:GetAccountNameByIndex(actualItem['seller'])
  local actualItemIcon = purchases_data[data[1]][data[2]]['itemIcon']

  local fontString = LMP:Fetch('font', MasterMerchant.systemSavedVariables.windowFont) .. '|%d'

  control.rowId:SetFont(string.format(fontString, 12))
  control.seller:SetFont(string.format(fontString, 15))
  control.guild:SetFont(string.format(fontString, 15))
  control.quant:SetFont(string.format(fontString, 15) .. '|soft-shadow-thin')
  control.itemName:SetFont(string.format(fontString, 15))
  control.purchaseTime:SetFont(string.format(fontString, 15))
  control.price:SetFont(string.format(fontString, 15))

  control.rowId:SetText(data.sortIndex)

  -- Some extra stuff for the Buyer cell to handle double-click and color changes
  -- Plus add a marker if buyer is not in-guild (kiosk sale)

  local buyerString
  --[[TODO determine whether or not to allos both
  if MasterMerchant.systemSavedVariables.viewBuyerSeller == 'buyer' then
    buyerString = currentBuyer
  else
    buyerString = currentSeller
  end
  ]]--
  buyerString = currentSeller

  control.seller:GetLabelControl():SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
  control.seller:SetText(buyerString)
  --[[TODO determine whether or not to allos both
  If the seller is the player, color the seller green.  Otherwise, blue.
  local acctName = GetDisplayName()
  if zo_strlower(buyerString) == zo_strlower(acctName) then
    124D05
    control.seller:SetNormalFontColor(0.18, 0.77, 0.05, 1)
    control.seller:SetPressedFontColor(0.18, 0.77, 0.05, 1)
    control.seller:SetMouseOverFontColor(0.32, 0.90, 0.18, 1)
  else
    15365E
    control.seller:SetNormalFontColor(0.21, 0.54, 0.94, 1)
    control.seller:SetPressedFontColor(0.21, 0.54, 0.94, 1)
    control.seller:SetMouseOverFontColor(0.34, 0.67, 1, 1)
  end
  ]]--
  control.seller:SetNormalFontColor(0.21, 0.54, 0.94, 1)
  control.seller:SetPressedFontColor(0.21, 0.54, 0.94, 1)
  control.seller:SetMouseOverFontColor(0.34, 0.67, 1, 1)

  control.seller:SetHandler('OnMouseUp', function(self, upInside)
    MasterMerchant:my_NameHandler_OnLinkMouseUp(buyerString, upInside, self)
  end)

  -- Guild cell
  control.guild:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
  control.guild:SetText(currentGuild)

  -- Item Icon
  control.icon:SetHidden(false)
  control.icon:SetTexture(actualItemIcon)

  -- Item name cell
  control.itemName:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
  control.itemName:SetText(zo_strformat('<<t:1>>', currentItemLink))
  -- Insert the item link into the chat box, with a quick substitution so brackets show up
  --control.itemName:SetHandler('OnMouseDoubleClick', function()
  --  ZO_ChatWindowTextEntryEditBox:SetText(ZO_ChatWindowTextEntryEditBox:GetText() .. string.gsub(currentItemLink, '|H0', '|H1'))
  --end)
  control.itemName:SetHandler('OnMouseEnter',
    function() MasterMerchant.ShowToolTip(currentItemLink, control.itemName) end)
  control.itemName:SetHandler('OnMouseExit', function() ClearTooltip(ItemTooltip) end)

  -- Quantity cell
  if actualItem.quant == 1 then control.quant:SetHidden(true)
  else
    control.quant:SetHidden(false)
    control.quant:SetText(actualItem.quant)
  end

  -- Sale time cell
  local dispTime = MasterMerchant.TextTimeSince(actualItem.timestamp)
  control.purchaseTime:SetText(dispTime)

  -- Handle the setting of whether or not to show pre-cut sale prices
  -- math.floor(number + 0.5) is a quick shorthand way to round for
  -- positive values.
  local dispPrice = actualItem.price
  local quantity = actualItem.quant
  if MasterMerchant.systemSavedVariables.showUnitPrice and quantity > 0 then
    dispPrice = math.floor((dispPrice / quantity) + 0.5)
  end

  -- Insert thousands separators for the price
  local stringPrice = MasterMerchant.LocalizedNumber(dispPrice)

  -- Finally, set the price
  control.price:SetText(stringPrice .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t')

  ZO_SortFilterList.SetupRow(self, control, data)
end

function MMScrollList:SetupReportsRow(control, data)

  control.rowId = GetControl(control, 'RowId')
  control.seller = GetControl(control, 'Seller')
  control.guild = GetControl(control, 'Guild')
  control.icon = GetControl(control, 'ItemIcon')
  control.quant = GetControl(control, 'Quantity')
  control.itemName = GetControl(control, 'ItemName')
  control.sellTime = GetControl(control, 'SellTime')
  control.price = GetControl(control, 'Price')
  control.listingfee = GetControl(control, 'ListingFee')

  local dataTable
  if MasterMerchant.reportsViewMode == MasterMerchant.reportsPostedViewMode then
    dataTable = posted_items_data
  elseif MasterMerchant.reportsViewMode == MasterMerchant.reportsCanceledViewMode then
    dataTable = cancelled_items_data
  end

  if (dataTable[data[1]] == nil) then
    -- just starting up so just bail out
    return
  end

  if (dataTable[data[1]][data[2]] == nil) then
    --d('MM Data Error:')
    --d(data[1])
    --d(data[2])
    --d('--------')
    return
  end

  if (dataTable[data[1]][data[2]]['sales'] == nil) then
    --d('MM Data Error:')
    --d(data[1])
    --d(data[2])
    --d('No Sales')
    --d('--------')
    return
  end

  if (dataTable[data[1]][data[2]]['sales'][data[3]] == nil) then
    --d('MM Data Error:')
    --d(data[1])
    --d(data[2])
    --d(data[3])
    --d('--------')
    return
  end

  local actualItem = dataTable[data[1]][data[2]]['sales'][data[3]]
  local currentItemLink = internal:GetItemLinkByIndex(actualItem['itemLink'])
  local currentGuild = internal:GetGuildNameByIndex(actualItem['guild'])
  local currentBuyer = internal:GetAccountNameByIndex(actualItem['buyer'])
  local currentSeller = internal:GetAccountNameByIndex(actualItem['seller'])
  local actualItemIcon = dataTable[data[1]][data[2]]['itemIcon']

  local fontString = LMP:Fetch('font', MasterMerchant.systemSavedVariables.windowFont) .. '|%d'

  control.rowId:SetFont(string.format(fontString, 12))
  control.seller:SetFont(string.format(fontString, 15))
  control.guild:SetFont(string.format(fontString, 15))
  control.itemName:SetFont(string.format(fontString, 15))
  control.quant:SetFont(string.format(fontString, 15) .. '|soft-shadow-thin')
  control.sellTime:SetFont(string.format(fontString, 15))
  control.price:SetFont(string.format(fontString, 15))
  control.listingfee:SetFont(string.format(fontString, 15))

  control.rowId:SetText(data.sortIndex)

  control.seller:GetLabelControl():SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
  control.seller:SetText(currentSeller)
  control.seller:SetHandler('OnMouseUp', function(self, upInside)
    MasterMerchant:my_NameHandler_OnLinkMouseUp(currentSeller, upInside, self)
  end)

  -- Guild cell
  local guildString = currentGuild
  if actualItem.wasKiosk then guildString = '|t16:16:/EsoUI/Art/icons/item_generic_coinbag.dds|t ' .. guildString else guildString = '     ' .. guildString end
  control.guild:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
  control.guild:SetText(guildString)

  -- Item Icon
  control.icon:SetHidden(false)
  control.icon:SetTexture(actualItemIcon)

  -- Item name cell
  control.itemName:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
  control.itemName:SetText(zo_strformat('<<t:1>>', currentItemLink))
  -- Insert the item link into the chat box, with a quick substitution so brackets show up
  --control.itemName:SetHandler('OnMouseDoubleClick', function()
  --  ZO_ChatWindowTextEntryEditBox:SetText(ZO_ChatWindowTextEntryEditBox:GetText() .. string.gsub(currentItemLink, '|H0', '|H1'))
  --end)
  control.itemName:SetHandler('OnMouseEnter',
    function() MasterMerchant.ShowToolTip(currentItemLink, control.itemName) end)
  control.itemName:SetHandler('OnMouseExit', function() ClearTooltip(ItemTooltip) end)

  -- Quantity cell
  if actualItem.quant == 1 then control.quant:SetHidden(true)
  else
    control.quant:SetHidden(false)
    control.quant:SetText(actualItem.quant)
  end

  -- Sale time cell
  control.sellTime:SetText(MasterMerchant.TextTimeSince(actualItem.timestamp))

  -- Handle the setting of whether or not to show pre-cut sale prices
  -- math.floor(number + 0.5) is a quick shorthand way to round for
  -- positive values.
  local dispPrice = actualItem.price
  local quantity = actualItem.quant
  if MasterMerchant.systemSavedVariables.showUnitPrice and quantity > 0 then
    dispPrice = math.floor((dispPrice / quantity) + 0.5)
  end

  -- Insert thousands separators for the price
  local stringPrice = MasterMerchant.LocalizedNumber(dispPrice)

  -- set the price
  control.price:SetText(stringPrice .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t')

  -- set listing fee
  local listingFee = GetTradingHousePostPriceInfo(actualItem.price)
  control.listingfee:SetText(listingFee .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t')

  ZO_SortFilterList.SetupRow(self, control, data)
end

function MMScrollList:ColorRow(control, data, mouseIsOver)
  for i = 1, control:GetNumChildren() do
    local child = control:GetChild(i)
    if not child.nonRecolorable then
      if child:GetType() == CT_LABEL then
        if string.find(child:GetName(), 'Price$') then child:SetColor(0.84, 0.71, 0.15, 1)
        else child:SetColor(1, 1, 1, 1) end
      end
    end
  end
end

function MMScrollList:InitializeDataType(controlName)
  self.masterList = {}
  if controlName == 'MasterMerchantWindow' then
    ZO_ScrollList_AddDataType(self.list, 1, 'MasterMerchantDataRow', 36,
      function(control, data) self:SetupSalesRow(control, data) end)
  elseif controlName == 'MasterMerchantGuildWindow' then
    ZO_ScrollList_AddDataType(self.list, 1, 'MasterMerchantGuildDataRow', 36,
      function(control, data) self:SetupGuildSalesRow(control, data) end)
  elseif controlName == 'MasterMerchantListingWindow' then
    ZO_ScrollList_AddDataType(self.list, 1, 'MasterMerchantListingDataRow', 36,
      function(control, data) self:SetupListingsRow(control, data) end)
  elseif controlName == 'MasterMerchantPurchaseWindow' then
    ZO_ScrollList_AddDataType(self.list, 1, 'MasterMerchantPurchaseDataRow', 36,
      function(control, data) self:SetupPurchasesRow(control, data) end)
  elseif controlName == 'MasterMerchantReportsWindow' then
    ZO_ScrollList_AddDataType(self.list, 1, 'MasterMerchantReportsDataRow', 36,
      function(control, data) self:SetupReportsRow(control, data) end)
  else
    MasterMerchant:dm("Warn", "Shit Hit the fan MMScrollList:InitializeDataType")
    MasterMerchant:dm("Warn", controlName)
  end
  self:RefreshData()
end

function MMScrollList:New(control)
  local skList = ZO_SortFilterList.New(self, control)
  skList:InitializeDataType(control:GetName())
  if control:GetName() == 'MasterMerchantWindow' then
    skList.sortHeaderGroup:SelectHeaderByKey('time')
    ZO_SortHeader_OnMouseExit(MasterMerchantWindowHeadersSellTime)
  elseif control:GetName() == 'MasterMerchantGuildWindow' then
    skList.sortHeaderGroup:SelectHeaderByKey('sales')
    ZO_SortHeader_OnMouseExit(MasterMerchantGuildWindowHeadersSales)
  elseif control:GetName() == 'MasterMerchantListingWindow' then
    skList.sortHeaderGroup:SelectHeaderByKey('time')
    ZO_SortHeader_OnMouseExit(MasterMerchantListingWindowHeadersListingTime)
  elseif control:GetName() == 'MasterMerchantPurchaseWindow' then
    skList.sortHeaderGroup:SelectHeaderByKey('time')
    ZO_SortHeader_OnMouseExit(MasterMerchantPurchaseWindowHeadersPurchaseTime)
  elseif control:GetName() == 'MasterMerchantReportsWindow' then
    skList.sortHeaderGroup:SelectHeaderByKey('time')
    ZO_SortHeader_OnMouseExit(MasterMerchantReportsWindowHeadersSellTime)
  else
    MasterMerchant:dm("Warn", "Shit Hit the fan MMScrollList:New")
    MasterMerchant:dm("Warn", control:GetName())
  end

  --[[
  ZO_PostHook(skList, 'RefreshData', function()
    local texCon = skList.list.scrollbar:GetThumbTextureControl()
    if texCon:GetHeight() < 10 then skList.list.scrollbar:SetThumbTextureHeight(10) end
  end)
  ]]--

  return skList
end

function MasterMerchant:BuildFilterDateRangeTable()
  MasterMerchant.filterDateRanges = { }
  local daysRange = MasterMerchant.systemSavedVariables.customFilterDateRange
  local dayCutoff = MasterMerchant.dateRanges[MM_DATERANGE_TODAY].startTimestamp
  local customDayRangeStart = dayCutoff - (daysRange * ZO_ONE_DAY_IN_SECONDS)
  local customDayRangeEnd = dayCutoff + (7 * ZO_ONE_DAY_IN_SECONDS)
  local customThirtyDayRangeStart = dayCutoff - (30 * ZO_ONE_DAY_IN_SECONDS)
  local customThirtyDayRangeEnd = dayCutoff + (7 * ZO_ONE_DAY_IN_SECONDS)
  local customSixtyDayRangeStart = customThirtyDayRangeStart - (30 * ZO_ONE_DAY_IN_SECONDS)
  local customSixtyDayRangeEnd = customThirtyDayRangeStart
  local customNinetyDayRangeStart = customSixtyDayRangeStart - (30 * ZO_ONE_DAY_IN_SECONDS)
  local customNinetyDayRangeEnd = customSixtyDayRangeStart
  MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_THIRTY] = { }
  MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_THIRTY].startTimestamp = customThirtyDayRangeStart
  MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_THIRTY].endTimestamp = customThirtyDayRangeEnd
  MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_SIXTY] = { }
  MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_SIXTY].startTimestamp = customSixtyDayRangeStart
  MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_SIXTY].endTimestamp = customSixtyDayRangeEnd
  MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_NINETY] = { }
  MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_NINETY].startTimestamp = customNinetyDayRangeStart
  MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_NINETY].endTimestamp = customNinetyDayRangeEnd
  MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_CUSTOM] = { }
  MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_CUSTOM].startTimestamp = customDayRangeStart
  MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_CUSTOM].endTimestamp = customDayRangeEnd
end

local function CheckFilterTimeframe(timestamp)
  local timeframeStart
  local timeframeEnd
  local validRange = false
  if MasterMerchant.systemSavedVariables.windowTimeRange == MM_WINDOW_TIME_RANGE_DEFAULT then
    timeframeStart = MasterMerchant:CheckTimeframe()
    if (timestamp > timeframeStart) then validRange = true end
  end
  if MasterMerchant.systemSavedVariables.windowTimeRange == MM_WINDOW_TIME_RANGE_THIRTY then
    timeframeStart = MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_THIRTY].startTimestamp
    timeframeEnd = MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_THIRTY].endTimestamp
    if (timestamp >= timeframeStart and timestamp < timeframeEnd) then validRange = true end
  end
  if MasterMerchant.systemSavedVariables.windowTimeRange == MM_WINDOW_TIME_RANGE_SIXTY then
    timeframeStart = MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_SIXTY].startTimestamp
    timeframeEnd = MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_SIXTY].endTimestamp
    if (timestamp >= timeframeStart and timestamp < timeframeEnd) then validRange = true end
  end
  if MasterMerchant.systemSavedVariables.windowTimeRange == MM_WINDOW_TIME_RANGE_NINETY then
    timeframeStart = MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_NINETY].startTimestamp
    timeframeEnd = MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_NINETY].endTimestamp
    if (timestamp >= timeframeStart and timestamp < timeframeEnd) then validRange = true end
  end
  if MasterMerchant.systemSavedVariables.windowTimeRange == MM_WINDOW_TIME_RANGE_CUSTOM then
    timeframeStart = MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_CUSTOM].startTimestamp
    timeframeEnd = MasterMerchant.filterDateRanges[MM_WINDOW_TIME_RANGE_CUSTOM].endTimestamp
    if (timestamp >= timeframeStart and timestamp < timeframeEnd) then validRange = true end
  end
  return validRange
end

local function CleanTextEnglish(searchText)
  -- pass two, clean up the text
  if searchText then
    searchText = string.gsub(searchText, "'s", MM_STRING_EMPTY)
    searchText = string.gsub(searchText, "-", " ")
    searchText = string.gsub(searchText, "%p", MM_STRING_EMPTY)
  end
  return searchText
end

function MMScrollList:FilterScrollList()
  -- this will error when the MM window is open and sr_index is empty
  --if internal:is_empty_or_nil(sr_index) then return end
  local listData = ZO_ScrollList_GetDataList(self.list)
  ZO_ClearNumericallyIndexedTable(listData)
  local searchText = nil
  if MasterMerchant.systemSavedVariables.viewSize == ITEMS then
    searchText = MasterMerchantWindowMenuHeaderSearchEditBox:GetText()
  elseif MasterMerchant.systemSavedVariables.viewSize == GUILDS then
    searchText = MasterMerchantGuildWindowMenuHeaderSearchEditBox:GetText()
  elseif MasterMerchant.systemSavedVariables.viewSize == LISTINGS then
    searchText = MasterMerchantListingWindowMenuHeaderSearchEditBox:GetText()
  elseif MasterMerchant.systemSavedVariables.viewSize == PURCHASES then
    searchText = MasterMerchantPurchaseWindowMenuHeaderSearchEditBox:GetText()
  elseif MasterMerchant.systemSavedVariables.viewSize == REPORTS then
    searchText = MasterMerchantReportsWindowMenuHeaderSearchEditBox:GetText()
  end
  if MasterMerchant.bonanzaSearchText then
    searchText = MasterMerchant.bonanzaSearchText
    MasterMerchant.bonanzaSearchText = nil
    if MasterMerchant.effective_lang == "en" then searchText = CleanTextEnglish(searchText) end
    MasterMerchantListingWindowMenuHeaderSearchEditBox:SetText(searchText)
  end
  if searchText then searchText = string.gsub(string.lower(searchText), '^%s*(.-)%s*$', '%1') end
  local rankIndex = MasterMerchant.systemSavedVariables.rankIndex or MM_DATERANGE_TODAY

  if MasterMerchant.systemSavedVariables.viewSize == ITEMS then
    -- return item sales
    if MasterMerchant.salesViewMode ~= MasterMerchant.personalSalesViewMode and (searchText == nil or searchText == '') then
      -- everything unfiltered using CheckFilterTimeframe()
      for k, v in pairs(sales_data) do
        for j, dataList in pairs(v) do
          -- IPAIRS
          for i, item in pairs(dataList['sales']) do
            if (type(i) ~= 'number' or type(item) ~= 'table' or type(item.timestamp) ~= 'number') then
              --d('Bad Item:')
              --d(item)
            else
              if CheckFilterTimeframe(item.timestamp) then
                table.insert(listData, ZO_ScrollList_CreateDataEntry(1, { k, j, i, item.timestamp, item.price, item.quant }))
              end
            end
          end
        end
      end
    elseif internal.sr_index_count == 1 and (searchText ~= nil and searchText ~= '') then
      -- We just have player indexed and we have something to filter with
      if MasterMerchant.salesViewMode == MasterMerchant.personalSalesViewMode then
        -- Search all data using CheckFilterTimeframe()
        local tconcat = table.concat
        local tinsert = table.insert
        local tolower = string.lower
        local temp = { '', ' ', '', ' ', '', ' ', '', ' ', '', }

        for k, v in pairs(sr_index[internal.PlayerSpecialText]) do
          local k = v[1]
          local j = v[2]
          local i = v[3]
          local dataList = sales_data[k][j]
          local item = dataList['sales'][i]
          local currentGuild = internal:GetGuildNameByIndex(item['guild'])
          local currentBuyer = internal:GetAccountNameByIndex(item['buyer'])
          local currentSeller = internal:GetAccountNameByIndex(item['seller'])

          if (type(i) ~= 'number' or type(item) ~= 'table' or type(item.timestamp) ~= 'number') then
            --d('Bad Item:')
            --d(item)
          else
            if CheckFilterTimeframe(item.timestamp) then
              local matchesAll = true
              temp[1] = 'b' .. currentBuyer or ''
              temp[3] = 's' .. currentSeller or ''
              temp[5] = currentGuild or ''
              temp[7] = dataList['itemDesc'] or ''
              temp[9] = dataList['itemAdderText'] or ''
              local gn = tolower(tconcat(temp, ''))
              local searchByWords = string.gmatch(searchText, '%S+')
              for searchWord in searchByWords do
                matchesAll = (matchesAll and string.find(gn, searchWord))
              end
              if matchesAll then
                table.insert(listData, ZO_ScrollList_CreateDataEntry(1, { k, j, i, item.timestamp, item.price, item.quant }))
              end
            end
          end
        end
      else
        -- Search all data using CheckFilterTimeframe()
        local tconcat = table.concat
        local tinsert = table.insert
        local tolower = string.lower
        local temp = { '', ' ', '', ' ', '', ' ', '', ' ', '', }
        for k, v in pairs(sales_data) do
          for j, dataList in pairs(v) do
            for i, item in pairs(dataList['sales']) do
              local currentGuild = internal:GetGuildNameByIndex(item['guild'])
              local currentBuyer = internal:GetAccountNameByIndex(item['buyer'])
              local currentSeller = internal:GetAccountNameByIndex(item['seller'])
              if (type(i) ~= 'number' or type(item) ~= 'table' or type(item.timestamp) ~= 'number') then
                --d('Bad Item:')
                --d(item)
              else
                if CheckFilterTimeframe(item.timestamp) then
                  local matchesAll = true
                  temp[1] = 'b' .. currentBuyer or ''
                  temp[3] = 's' .. currentSeller or ''
                  temp[5] = currentGuild or ''
                  temp[7] = dataList['itemDesc'] or ''
                  temp[9] = dataList['itemAdderText'] or ''
                  local gn = tolower(tconcat(temp, ''))
                  local searchByWords = string.gmatch(searchText, '%S+')
                  for searchWord in searchByWords do
                    matchesAll = (matchesAll and string.find(gn, searchWord))
                  end
                  if matchesAll then
                    table.insert(listData, ZO_ScrollList_CreateDataEntry(1, { k, j, i, item.timestamp, item.price, item.quant }))
                  end
                end
              end
            end
          end
        end
      end
    else
      -- We have the indexes to search
      -- Break up search term into words
      --[[TODO: look into ways to display personal sales without simply
      adding the player special text to the list of search words. ]]--
      if MasterMerchant.salesViewMode == MasterMerchant.personalSalesViewMode then
        searchText = MasterMerchant.concat(searchText, internal.PlayerSpecialText)
      end
      local searchByWords = zo_strgmatch(searchText, '%S+')
      local indexToUse = sr_index
      local intersectionIndexes = {}

      -- Build up a list of indexes matching each word, then compute the intersection
      -- of those sets
      for searchWord in searchByWords do
        local addedIndexes = {}
        for key, indexes in pairs(indexToUse) do
          local findStatus, findResult = pcall(string.find, key, searchWord)
          if findStatus then
            if findResult then
              for i = 1, #indexes do
                if not addedIndexes[indexes[i][1]] then addedIndexes[indexes[i][1]] = {} end
                if not addedIndexes[indexes[i][1]][indexes[i][2]] then addedIndexes[indexes[i][1]][indexes[i][2]] = {} end
                addedIndexes[indexes[i][1]][indexes[i][2]][indexes[i][3]] = true
              end
            end
          end
        end

        -- If this is the first(or only) word, the intersection is itself
        if NonContiguousCount(intersectionIndexes) == 0 then
          intersectionIndexes = addedIndexes
        else
          -- Compute the intersection of the two
          local newIntersection = {}
          for k, val in pairs(intersectionIndexes) do
            if addedIndexes[k] then
              for j, subval in pairs(val) do
                if addedIndexes[k][j] then
                  for i in pairs(subval) do
                    if not newIntersection[k] then newIntersection[k] = {} end
                    if not newIntersection[k][j] then newIntersection[k][j] = {} end
                    newIntersection[k][j][i] = addedIndexes[k][j][i]
                  end
                end
              end
            end
          end
          intersectionIndexes = newIntersection
        end
      end

      -- Now that we have the intersection, actually build the search table
      for k, val in pairs(intersectionIndexes) do
        for j, subval in pairs(val) do
          for i in pairs(subval) do
            local actualItem = sales_data[k][j]['sales'][i]
            table.insert(listData, ZO_ScrollList_CreateDataEntry(1, { k, j, i, actualItem.timestamp, actualItem.price, actualItem.quant }))
          end
        end
      end
    end

  elseif MasterMerchant.systemSavedVariables.viewSize == GUILDS then
    local dataSet = nil
    if MasterMerchant.systemSavedVariables.viewGuildBuyerSeller == 'buyer' then
      dataSet = internal.guildPurchases
    elseif MasterMerchant.systemSavedVariables.viewGuildBuyerSeller == 'seller' then
      dataSet = internal.guildSales
    else
      if MasterMerchant.salesViewMode == MasterMerchant.personalSalesViewMode then
        dataSet = internal.myItems
      else
        dataSet = internal.guildItems
      end
    end

    if searchText == nil or searchText == '' then
      if MasterMerchant.salesViewMode == MasterMerchant.personalSalesViewMode and MasterMerchant.systemSavedVariables.viewGuildBuyerSeller ~= 'item' then
        -- my guild sales
        for gn, g in pairs(dataSet) do
          local sellerData = g.sellers[GetDisplayName()] or nil
          if (sellerData and sellerData.sales[rankIndex]) then
            if (sellerData.sales[rankIndex] > 0) or (zo_plainstrfind(MasterMerchant.guildList, gn)) then
              table.insert(listData, ZO_ScrollList_CreateDataEntry(1, { gn, sellerData.sellerName, sellerData.sales[rankIndex], sellerData.rank[rankIndex], sellerData.count[rankIndex], sellerData.stack[rankIndex], g.sales[rankIndex], sellerData.tax[rankIndex], sellerData.outsideBuyer }))
            end
          else
            if zo_plainstrfind(MasterMerchant.guildList, gn) then
              table.insert(listData, ZO_ScrollList_CreateDataEntry(1, { gn, GetDisplayName(), 0, 9999, 0, 0, g.sales[rankIndex], 0, false }))
            end
          end
        end
      else
        -- all guild sales
        for gn, g in pairs(dataSet) do
          if (MasterMerchant.systemSavedVariables.viewGuildBuyerSeller ~= 'item') then
            if ((g.sales[rankIndex] or 0) > 0) or (zo_plainstrfind(MasterMerchant.guildList, gn)) then
              table.insert(listData, ZO_ScrollList_CreateDataEntry(1, { gn, GetString(MM_ENTIRE_GUILD), g.sales[rankIndex], 0, g.count[rankIndex], g.stack[rankIndex], g.sales[rankIndex], g.tax[rankIndex] }))
            end
          end
          for sn, sellerData in pairs(g.sellers) do
            if (sellerData and sellerData.sales[rankIndex]) then
              if (sellerData.sales[rankIndex] > 0) or (zo_plainstrfind(MasterMerchant.guildList, gn)) then
                table.insert(listData, ZO_ScrollList_CreateDataEntry(1, { gn, sellerData.sellerName, sellerData.sales[rankIndex], sellerData.rank[rankIndex], sellerData.count[rankIndex], sellerData.stack[rankIndex], g.sales[rankIndex], sellerData.tax[rankIndex], sellerData.outsideBuyer }))
              end
            else
              --table.insert(listData, ZO_ScrollList_CreateDataEntry(1, {gn, sellerData.sellerName, 0, 9999, 0, 0, g.sales[rankIndex], 0, false}))
            end
          end
        end
      end
    else
      if MasterMerchant.salesViewMode == MasterMerchant.personalSalesViewMode and MasterMerchant.systemSavedVariables.viewGuildBuyerSeller ~= 'item' then
        -- my guild sales - filtered
        for gn, g in pairs(dataSet) do
          -- Search the guild name for all words
          local matchesAll = true
          -- Break up search term into words
          local searchByWords = zo_strgmatch(searchText, '%S+')
          for searchWord in searchByWords do
            matchesAll = (matchesAll and string.find(zo_strlower(gn), searchWord))
          end
          if matchesAll then
            local sellerData = g.sellers[GetDisplayName()] or nil
            if (sellerData and sellerData.sales[rankIndex]) then
              if (sellerData.sales[rankIndex] > 0) or (zo_plainstrfind(MasterMerchant.guildList, gn)) then
                table.insert(listData, ZO_ScrollList_CreateDataEntry(1, { gn, sellerData.sellerName, sellerData.sales[rankIndex], sellerData.rank[rankIndex], sellerData.count[rankIndex], sellerData.stack[rankIndex], g.sales[rankIndex], sellerData.tax[rankIndex], sellerData.outsideBuyer }))
              end
            else
              --table.insert(listData, ZO_ScrollList_CreateDataEntry(1, {gn, GetDisplayName(), 0, 9999, 0, 0, g.sales[rankIndex], 0, false}))
            end
          end
        end
      else
        -- all guild sales - filtered
        local startTimer = GetTimeStamp()

        for gn, g in pairs(dataSet) do
          -- Search the guild name for all words
          local matchesAll = true
          -- Break up search term into words
          local searchByWords = zo_strgmatch(searchText, '%S+')
          for searchWord in searchByWords do
            matchesAll = (matchesAll and string.find(zo_strlower(gn), searchWord))
          end
          if matchesAll and MasterMerchant.systemSavedVariables.viewGuildBuyerSeller ~= 'item' then
            if ((g.sales[rankIndex] or 0) > 0) or (zo_plainstrfind(MasterMerchant.guildList, gn)) then
              table.insert(listData, ZO_ScrollList_CreateDataEntry(1, { gn, GetString(MM_ENTIRE_GUILD), g.sales[rankIndex], 0, g.count[rankIndex], g.stack[rankIndex], g.sales[rankIndex], g.tax[rankIndex], false }))
            end
          end
          for sn, sellerData in pairs(g.sellers) do
            -- Search the guild name and player name for all words
            local matchesAll = true
            -- Break up search term into words
            local searchByWords = zo_strgmatch(searchText, '%S+')
            for searchWord in searchByWords do
              local txt
              if MasterMerchant.systemSavedVariables.viewGuildBuyerSeller == 'item' then
                txt = zo_strlower(MasterMerchant.concat(gn, sellerData.searchText))
              else
                txt = zo_strlower(MasterMerchant.concat(gn, sellerData.sellerName))
              end
              matchesAll = (matchesAll and string.find(txt, searchWord))
            end
            if matchesAll then
              if (sellerData.sales[rankIndex] and (sellerData.sales[rankIndex] > 0)) then
                table.insert(listData, ZO_ScrollList_CreateDataEntry(1, { gn, sellerData.sellerName, sellerData.sales[rankIndex], sellerData.rank[rankIndex], sellerData.count[rankIndex], sellerData.stack[rankIndex], g.sales[rankIndex], sellerData.tax[rankIndex], sellerData.outsideBuyer }))
              else
                --table.insert(listData, ZO_ScrollList_CreateDataEntry(1, {gn, sellerData.sellerName, 0, 9999, 0, 0, g.sales[rankIndex], 0, false}))
              end
            end
          end
        end
        -- MasterMerchant:dm("Debug", string.format(GetString(MM_FILTER_TIME), GetTimeStamp() - startTimer))

      end
    end

  elseif MasterMerchant.systemSavedVariables.viewSize == LISTINGS then
    if (searchText == nil or searchText == '') then
      for k, v in pairs(listings_data) do
        for j, dataList in pairs(v) do
          -- IPAIRS
          for i, item in pairs(dataList['sales']) do
            if (type(i) ~= 'number' or type(item) ~= 'table' or type(item.timestamp) ~= 'number') then
              --d('Bad Item:')
              --d(item)
            else
              local saveData = GS17DataSavedVariables[internal.nameFilterNamespace]
              local itemLink = internal:GetItemLinkByIndex(item.itemLink)
              local itemName = dataList.itemDesc
              local isFiltered = MasterMerchant:IsItemLinkFiltered(itemLink)
              if not saveData[itemName] and isFiltered then
                table.insert(listData, ZO_ScrollList_CreateDataEntry(1, { k, j, i, item.timestamp, item.price, item.quant }))
              end
            end
          end
        end
      end
    else
      local searchByWords = zo_strgmatch(searchText, '%S+')
      local indexToUse = lr_index
      local intersectionIndexes = {}

      -- Build up a list of indexes matching each word, then compute the intersection
      -- of those sets
      for searchWord in searchByWords do
        local addedIndexes = {}
        for key, indexes in pairs(indexToUse) do
          local findStatus, findResult = pcall(string.find, key, searchWord)
          if findStatus then
            if findResult then
              for i = 1, #indexes do
                if not addedIndexes[indexes[i][1]] then addedIndexes[indexes[i][1]] = {} end
                if not addedIndexes[indexes[i][1]][indexes[i][2]] then addedIndexes[indexes[i][1]][indexes[i][2]] = {} end
                addedIndexes[indexes[i][1]][indexes[i][2]][indexes[i][3]] = true
              end
            end
          end
        end

        -- If this is the first(or only) word, the intersection is itself
        if NonContiguousCount(intersectionIndexes) == 0 then
          intersectionIndexes = addedIndexes
        else
          -- Compute the intersection of the two
          local newIntersection = {}
          for k, val in pairs(intersectionIndexes) do
            if addedIndexes[k] then
              for j, subval in pairs(val) do
                if addedIndexes[k][j] then
                  for i in pairs(subval) do
                    if not newIntersection[k] then newIntersection[k] = {} end
                    if not newIntersection[k][j] then newIntersection[k][j] = {} end
                    newIntersection[k][j][i] = addedIndexes[k][j][i]
                  end
                end
              end
            end
          end
          intersectionIndexes = newIntersection
        end
      end

      -- Now that we have the intersection, actually build the search table
      for k, val in pairs(intersectionIndexes) do
        for j, subval in pairs(val) do
          for i in pairs(subval) do
            local listedItem = listings_data[k][j]
            local actualItem = listedItem['sales'][i]
            local saveData = GS17DataSavedVariables[internal.nameFilterNamespace]
            local itemLink = internal:GetItemLinkByIndex(actualItem.itemLink)
            local itemName = listedItem.itemDesc
            local isFiltered = MasterMerchant:IsItemLinkFiltered(itemLink)
            if not saveData[itemName] and isFiltered then
              table.insert(listData, ZO_ScrollList_CreateDataEntry(1, { k, j, i, actualItem.timestamp, actualItem.price, actualItem.quant }))
            end
          end
        end
      end
    end

  elseif MasterMerchant.systemSavedVariables.viewSize == PURCHASES then
    if (searchText == nil or searchText == '') then
      for k, v in pairs(purchases_data) do
        for j, dataList in pairs(v) do
          -- IPAIRS
          for i, item in pairs(dataList['sales']) do
            if (type(i) ~= 'number' or type(item) ~= 'table' or type(item.timestamp) ~= 'number') then
              --d('Bad Item:')
              --d(item)
            else
              table.insert(listData, ZO_ScrollList_CreateDataEntry(1, { k, j, i, item.timestamp, item.price, item.quant }))
            end
          end
        end
      end
    else
      local searchByWords = zo_strgmatch(searchText, '%S+')
      local indexToUse = pr_index
      local intersectionIndexes = {}

      -- Build up a list of indexes matching each word, then compute the intersection
      -- of those sets
      for searchWord in searchByWords do
        local addedIndexes = {}
        for key, indexes in pairs(indexToUse) do
          local findStatus, findResult = pcall(string.find, key, searchWord)
          if findStatus then
            if findResult then
              for i = 1, #indexes do
                if not addedIndexes[indexes[i][1]] then addedIndexes[indexes[i][1]] = {} end
                if not addedIndexes[indexes[i][1]][indexes[i][2]] then addedIndexes[indexes[i][1]][indexes[i][2]] = {} end
                addedIndexes[indexes[i][1]][indexes[i][2]][indexes[i][3]] = true
              end
            end
          end
        end

        -- If this is the first(or only) word, the intersection is itself
        if NonContiguousCount(intersectionIndexes) == 0 then
          intersectionIndexes = addedIndexes
        else
          -- Compute the intersection of the two
          local newIntersection = {}
          for k, val in pairs(intersectionIndexes) do
            if addedIndexes[k] then
              for j, subval in pairs(val) do
                if addedIndexes[k][j] then
                  for i in pairs(subval) do
                    if not newIntersection[k] then newIntersection[k] = {} end
                    if not newIntersection[k][j] then newIntersection[k][j] = {} end
                    newIntersection[k][j][i] = addedIndexes[k][j][i]
                  end
                end
              end
            end
          end
          intersectionIndexes = newIntersection
        end
      end

      -- Now that we have the intersection, actually build the search table
      for k, val in pairs(intersectionIndexes) do
        for j, subval in pairs(val) do
          for i in pairs(subval) do
            local actualItem = purchases_data[k][j]['sales'][i]
            table.insert(listData, ZO_ScrollList_CreateDataEntry(1, { k, j, i, actualItem.timestamp, actualItem.price, actualItem.quant }))
          end
        end
      end
    end

  elseif MasterMerchant.systemSavedVariables.viewSize == REPORTS then
    local dataTable
    local indexTable
    if MasterMerchant.reportsViewMode == MasterMerchant.reportsPostedViewMode then
      dataTable = posted_items_data
      indexTable = pir_index
    elseif MasterMerchant.reportsViewMode == MasterMerchant.reportsCanceledViewMode then
      dataTable = cancelled_items_data
      indexTable = cr_index
    end

    if (searchText == nil or searchText == '') then
      for k, v in pairs(dataTable) do
        for j, dataList in pairs(v) do
          -- IPAIRS
          for i, item in pairs(dataList['sales']) do
            if (type(i) ~= 'number' or type(item) ~= 'table' or type(item.timestamp) ~= 'number') then
              --d('Bad Item:')
              --d(item)
            else
              table.insert(listData, ZO_ScrollList_CreateDataEntry(1, { k, j, i, item.timestamp, item.price, item.quant }))
            end
          end
        end
      end
    else
      local searchByWords = zo_strgmatch(searchText, '%S+')
      local intersectionIndexes = {}

      -- Build up a list of indexes matching each word, then compute the intersection
      -- of those sets
      for searchWord in searchByWords do
        local addedIndexes = {}
        for key, indexes in pairs(indexTable) do
          local findStatus, findResult = pcall(string.find, key, searchWord)
          if findStatus then
            if findResult then
              for i = 1, #indexes do
                if not addedIndexes[indexes[i][1]] then addedIndexes[indexes[i][1]] = {} end
                if not addedIndexes[indexes[i][1]][indexes[i][2]] then addedIndexes[indexes[i][1]][indexes[i][2]] = {} end
                addedIndexes[indexes[i][1]][indexes[i][2]][indexes[i][3]] = true
              end
            end
          end
        end

        -- If this is the first(or only) word, the intersection is itself
        if NonContiguousCount(intersectionIndexes) == 0 then
          intersectionIndexes = addedIndexes
        else
          -- Compute the intersection of the two
          local newIntersection = {}
          for k, val in pairs(intersectionIndexes) do
            if addedIndexes[k] then
              for j, subval in pairs(val) do
                if addedIndexes[k][j] then
                  for i in pairs(subval) do
                    if not newIntersection[k] then newIntersection[k] = {} end
                    if not newIntersection[k][j] then newIntersection[k][j] = {} end
                    newIntersection[k][j][i] = addedIndexes[k][j][i]
                  end
                end
              end
            end
          end
          intersectionIndexes = newIntersection
        end
      end

      -- Now that we have the intersection, actually build the search table
      for k, val in pairs(intersectionIndexes) do
        for j, subval in pairs(val) do
          for i in pairs(subval) do
            local actualItem = dataTable[k][j]['sales'][i]
            table.insert(listData, ZO_ScrollList_CreateDataEntry(1, { k, j, i, actualItem.timestamp, actualItem.price, actualItem.quant }))
          end
        end
      end
    end

  end

  local texCon = self.list.scrollbar:GetThumbTextureControl()
  zo_callLater(function()
    if texCon:GetHeight() < 10 then self.list.scrollbar:SetThumbTextureHeight(10) end
  end, 100)

end

function MMScrollList:SortScrollList()
  if self.currentSortKey == 'price' then
    MasterMerchant:SortByPrice(self.currentSortOrder, self)
  elseif self.currentSortKey == 'time' then
    MasterMerchant:SortByTime(self.currentSortOrder, self)
  elseif self.currentSortKey == 'rank' then
    MasterMerchant:SortByRank(self.currentSortOrder, self)
  elseif self.currentSortKey == 'sales' then
    MasterMerchant:SortBySales(self.currentSortOrder, self)
  elseif self.currentSortKey == 'count' then
    MasterMerchant:SortByCount(self.currentSortOrder, self)
  elseif self.currentSortKey == 'tax' then
    MasterMerchant:SortByTax(self.currentSortOrder, self)
  elseif self.currentSortKey == 'name' then
    if MasterMerchant.systemSavedVariables.viewSize == GUILDS then
      MasterMerchant:SortByName(self.currentSortOrder, self)
    elseif MasterMerchant.systemSavedVariables.viewSize == PURCHASES then
      MasterMerchant:SortByPurchaseAccountName(self.currentSortOrder, self)
    end
  elseif self.currentSortKey == 'itemGuildName' then
    if MasterMerchant.systemSavedVariables.viewSize == LISTINGS then
      MasterMerchant:SortByListingItemGuildName(self.currentSortOrder, self)
    elseif MasterMerchant.systemSavedVariables.viewSize == PURCHASES then
      MasterMerchant:SortByPurchaseItemGuildName(self.currentSortOrder, self)
    elseif MasterMerchant.systemSavedVariables.viewSize == REPORTS then
      MasterMerchant:SortByReportItemGuildName(self.currentSortOrder, self)
    else
      MasterMerchant:SortBySalesItemGuildName(self.currentSortOrder, self)
    end
  elseif self.currentSortKey == 'guildName' then
    MasterMerchant:SortByGuildName(self.currentSortOrder, self)
  end
end

-- Handle the OnMoveStop event for the windows
function MasterMerchant:OnWindowMoveStop(windowMoved)
  if windowMoved == MasterMerchantWindow then
    MasterMerchant.systemSavedVariables.salesWinLeft = MasterMerchantWindow:GetLeft()
    MasterMerchant.systemSavedVariables.salesWinTop = MasterMerchantWindow:GetTop()

    MasterMerchant.systemSavedVariables.guildWinLeft = MasterMerchantWindow:GetLeft()
    MasterMerchant.systemSavedVariables.guildWinTop = MasterMerchantWindow:GetTop()
    MasterMerchant.systemSavedVariables.listingWinLeft = MasterMerchantWindow:GetLeft()
    MasterMerchant.systemSavedVariables.listingWinTop = MasterMerchantWindow:GetTop()
    MasterMerchant.systemSavedVariables.purchaseWinLeft = MasterMerchantWindow:GetLeft()
    MasterMerchant.systemSavedVariables.purchaseWinTop = MasterMerchantWindow:GetTop()
    MasterMerchant.systemSavedVariables.reportsWinLeft = MasterMerchantWindow:GetLeft()
    MasterMerchant.systemSavedVariables.reportsWinTop = MasterMerchantWindow:GetTop()

    MasterMerchantGuildWindow:ClearAnchors()
    MasterMerchantGuildWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.guildWinLeft, MasterMerchant.systemSavedVariables.guildWinTop)

    MasterMerchantListingWindow:ClearAnchors()
    MasterMerchantListingWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.listingWinLeft, MasterMerchant.systemSavedVariables.listingWinTop)

    MasterMerchantPurchaseWindow:ClearAnchors()
    MasterMerchantPurchaseWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.purchaseWinLeft, MasterMerchant.systemSavedVariables.purchaseWinTop)

    MasterMerchantReportsWindow:ClearAnchors()
    MasterMerchantReportsWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.reportsWinLeft, MasterMerchant.systemSavedVariables.reportsWinTop)

  elseif windowMoved == MasterMerchantGuildWindow then
    MasterMerchant.systemSavedVariables.guildWinLeft = MasterMerchantGuildWindow:GetLeft()
    MasterMerchant.systemSavedVariables.guildWinTop = MasterMerchantGuildWindow:GetTop()

    MasterMerchant.systemSavedVariables.salesWinLeft = MasterMerchantGuildWindow:GetLeft()
    MasterMerchant.systemSavedVariables.salesWinTop = MasterMerchantGuildWindow:GetTop()
    MasterMerchant.systemSavedVariables.listingWinLeft = MasterMerchantGuildWindow:GetLeft()
    MasterMerchant.systemSavedVariables.listingWinTop = MasterMerchantGuildWindow:GetTop()
    MasterMerchant.systemSavedVariables.purchaseWinLeft = MasterMerchantGuildWindow:GetLeft()
    MasterMerchant.systemSavedVariables.purchaseWinTop = MasterMerchantGuildWindow:GetTop()
    MasterMerchant.systemSavedVariables.reportsWinLeft = MasterMerchantGuildWindow:GetLeft()
    MasterMerchant.systemSavedVariables.reportsWinTop = MasterMerchantGuildWindow:GetTop()

    MasterMerchantWindow:ClearAnchors()
    MasterMerchantWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.salesWinLeft, MasterMerchant.systemSavedVariables.salesWinTop)

    MasterMerchantListingWindow:ClearAnchors()
    MasterMerchantListingWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.listingWinLeft, MasterMerchant.systemSavedVariables.listingWinTop)

    MasterMerchantPurchaseWindow:ClearAnchors()
    MasterMerchantPurchaseWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.purchaseWinLeft, MasterMerchant.systemSavedVariables.purchaseWinTop)

    MasterMerchantReportsWindow:ClearAnchors()
    MasterMerchantReportsWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.reportsWinLeft, MasterMerchant.systemSavedVariables.reportsWinTop)

  elseif windowMoved == MasterMerchantListingWindow then
    MasterMerchant.systemSavedVariables.listingWinLeft = MasterMerchantListingWindow:GetLeft()
    MasterMerchant.systemSavedVariables.listingWinTop = MasterMerchantListingWindow:GetTop()

    MasterMerchant.systemSavedVariables.salesWinLeft = MasterMerchantListingWindow:GetLeft()
    MasterMerchant.systemSavedVariables.salesWinTop = MasterMerchantListingWindow:GetTop()
    MasterMerchant.systemSavedVariables.guildWinLeft = MasterMerchantListingWindow:GetLeft()
    MasterMerchant.systemSavedVariables.guildWinTop = MasterMerchantListingWindow:GetTop()
    MasterMerchant.systemSavedVariables.purchaseWinLeft = MasterMerchantListingWindow:GetLeft()
    MasterMerchant.systemSavedVariables.purchaseWinTop = MasterMerchantListingWindow:GetTop()
    MasterMerchant.systemSavedVariables.reportsWinLeft = MasterMerchantListingWindow:GetLeft()
    MasterMerchant.systemSavedVariables.reportsWinTop = MasterMerchantListingWindow:GetTop()

    MasterMerchantWindow:ClearAnchors()
    MasterMerchantWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.salesWinLeft, MasterMerchant.systemSavedVariables.salesWinTop)

    MasterMerchantGuildWindow:ClearAnchors()
    MasterMerchantGuildWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.guildWinLeft, MasterMerchant.systemSavedVariables.guildWinTop)

    MasterMerchantPurchaseWindow:ClearAnchors()
    MasterMerchantPurchaseWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.purchaseWinLeft, MasterMerchant.systemSavedVariables.purchaseWinTop)

    MasterMerchantReportsWindow:ClearAnchors()
    MasterMerchantReportsWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.reportsWinLeft, MasterMerchant.systemSavedVariables.reportsWinTop)

  elseif windowMoved == MasterMerchantPurchaseWindow then
    MasterMerchant.systemSavedVariables.purchaseWinLeft = MasterMerchantPurchaseWindow:GetLeft()
    MasterMerchant.systemSavedVariables.purchaseWinTop = MasterMerchantPurchaseWindow:GetTop()

    MasterMerchant.systemSavedVariables.salesWinLeft = MasterMerchantPurchaseWindow:GetLeft()
    MasterMerchant.systemSavedVariables.salesWinTop = MasterMerchantPurchaseWindow:GetTop()
    MasterMerchant.systemSavedVariables.guildWinLeft = MasterMerchantPurchaseWindow:GetLeft()
    MasterMerchant.systemSavedVariables.guildWinTop = MasterMerchantPurchaseWindow:GetTop()
    MasterMerchant.systemSavedVariables.listingWinLeft = MasterMerchantPurchaseWindow:GetLeft()
    MasterMerchant.systemSavedVariables.listingWinTop = MasterMerchantPurchaseWindow:GetTop()
    MasterMerchant.systemSavedVariables.reportsWinLeft = MasterMerchantPurchaseWindow:GetLeft()
    MasterMerchant.systemSavedVariables.reportsWinTop = MasterMerchantPurchaseWindow:GetTop()

    MasterMerchantWindow:ClearAnchors()
    MasterMerchantWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.salesWinLeft, MasterMerchant.systemSavedVariables.salesWinTop)

    MasterMerchantGuildWindow:ClearAnchors()
    MasterMerchantGuildWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.guildWinLeft, MasterMerchant.systemSavedVariables.guildWinTop)

    MasterMerchantListingWindow:ClearAnchors()
    MasterMerchantListingWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.listingWinLeft, MasterMerchant.systemSavedVariables.listingWinTop)

    MasterMerchantReportsWindow:ClearAnchors()
    MasterMerchantReportsWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.reportsWinLeft, MasterMerchant.systemSavedVariables.reportsWinTop)

  elseif windowMoved == MasterMerchantReportsWindow then
    MasterMerchant.systemSavedVariables.reportsWinLeft = MasterMerchantReportsWindow:GetLeft()
    MasterMerchant.systemSavedVariables.reportsWinTop = MasterMerchantReportsWindow:GetTop()

    MasterMerchant.systemSavedVariables.salesWinLeft = MasterMerchantReportsWindow:GetLeft()
    MasterMerchant.systemSavedVariables.salesWinTop = MasterMerchantReportsWindow:GetTop()
    MasterMerchant.systemSavedVariables.guildWinLeft = MasterMerchantReportsWindow:GetLeft()
    MasterMerchant.systemSavedVariables.guildWinTop = MasterMerchantReportsWindow:GetTop()
    MasterMerchant.systemSavedVariables.listingWinLeft = MasterMerchantReportsWindow:GetLeft()
    MasterMerchant.systemSavedVariables.listingWinTop = MasterMerchantReportsWindow:GetTop()
    MasterMerchant.systemSavedVariables.purchaseWinLeft = MasterMerchantReportsWindow:GetLeft()
    MasterMerchant.systemSavedVariables.purchaseWinTop = MasterMerchantReportsWindow:GetTop()

    MasterMerchantWindow:ClearAnchors()
    MasterMerchantWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.salesWinLeft, MasterMerchant.systemSavedVariables.salesWinTop)

    MasterMerchantGuildWindow:ClearAnchors()
    MasterMerchantGuildWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.guildWinLeft, MasterMerchant.systemSavedVariables.guildWinTop)

    MasterMerchantListingWindow:ClearAnchors()
    MasterMerchantListingWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.listingWinLeft, MasterMerchant.systemSavedVariables.listingWinTop)

    MasterMerchantPurchaseWindow:ClearAnchors()
    MasterMerchantPurchaseWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.purchaseWinLeft, MasterMerchant.systemSavedVariables.purchaseWinTop)

  elseif windowMoved == MasterMerchantStatsWindow then
    MasterMerchant.systemSavedVariables.statsWinLeft = MasterMerchantStatsWindow:GetLeft()
    MasterMerchant.systemSavedVariables.statsWinTop = MasterMerchantStatsWindow:GetTop()
  else
    MasterMerchant.systemSavedVariables.feedbackWinLeft = MasterMerchantFeedback:GetLeft()
    MasterMerchant.systemSavedVariables.feedbackWinTop = MasterMerchantFeedback:GetTop()
  end
end

-- Restore the window positions from saved vars
function MasterMerchant:RestoreWindowPosition()
  MasterMerchant:dm("Debug", "RestoreWindowPosition")
  MasterMerchantWindow:ClearAnchors()
  MasterMerchantGuildWindow:ClearAnchors()
  MasterMerchantListingWindow:ClearAnchors()
  MasterMerchantPurchaseWindow:ClearAnchors()
  MasterMerchantReportsWindow:ClearAnchors()

  MasterMerchantStatsWindow:ClearAnchors()
  MasterMerchantFeedback:ClearAnchors()

  MasterMerchantWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.salesWinLeft,
    MasterMerchant.systemSavedVariables.salesWinTop)
  MasterMerchantGuildWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.guildWinLeft,
    MasterMerchant.systemSavedVariables.guildWinTop)
  MasterMerchantListingWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.listingWinLeft,
    MasterMerchant.systemSavedVariables.listingWinTop)
  MasterMerchantPurchaseWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.purchaseWinLeft,
    MasterMerchant.systemSavedVariables.purchaseWinTop)
  MasterMerchantReportsWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.reportsWinLeft,
    MasterMerchant.systemSavedVariables.reportsWinTop)

  MasterMerchantStatsWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.statsWinLeft,
    MasterMerchant.systemSavedVariables.statsWinTop)
  MasterMerchantFeedback:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchant.systemSavedVariables.feedbackWinLeft,
    MasterMerchant.systemSavedVariables.feedbackWinTop)
end

-- Handle the changing of window font settings
function MasterMerchant:UpdateFonts()
  MasterMerchant:dm("Debug", "UpdateFonts")
  MasterMerchant:RegisterFonts()
  local font = LMP:Fetch('font', MasterMerchant.systemSavedVariables.windowFont)
  local fontString = font .. '|%d'
  local windowTitle = 26
  local windowButtonLabel = 14
  local windowHeader = 17
  local windowEditBox = 19

  -- Main Window (Sales)
  MasterMerchantWindowMenuHeaderTitle:SetFont(string.format(fontString, windowTitle))
  MasterMerchantWindowMenuFooterSwitchViewButton:SetFont(string.format(fontString, windowButtonLabel))
  MasterMerchantWindowMenuFooterPriceSwitchButton:SetFont(string.format(fontString, windowButtonLabel))
  MasterMerchantWindowMenuFooterFullPriceSwitchButton:SetFont(string.format(fontString, windowButtonLabel))
  MasterMerchantWindowMenuHeaderSearchEditBox:SetFont(string.format(fontString, windowEditBox))
  MasterMerchantWindowHeadersBuyer:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantWindowHeadersGuild:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantWindowHeadersItemName:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantWindowHeadersSellTime:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantWindowHeadersPrice:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))

  -- Guild Window
  MasterMerchantGuildWindowMenuHeaderTitle:SetFont(string.format(fontString, windowTitle))
  MasterMerchantGuildWindowMenuFooterSwitchViewButton:SetFont(string.format(fontString, windowButtonLabel))
  MasterMerchantGuildWindowMenuHeaderSearchEditBox:SetFont(string.format(fontString, windowEditBox))
  MasterMerchantGuildWindowHeadersGuild:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantGuildWindowHeadersSeller:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantGuildWindowHeadersRank:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantGuildWindowHeadersSales:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantGuildWindowHeadersTax:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantGuildWindowHeadersCount:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantGuildWindowHeadersPercent:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))

  -- Listing Window
  MasterMerchantListingWindowMenuHeaderTitle:SetFont(string.format(fontString, windowTitle))
  MasterMerchantListingWindowMenuFooterPriceSwitchButton:SetFont(string.format(fontString, windowButtonLabel))
  MasterMerchantListingWindowMenuHeaderSearchEditBox:SetFont(string.format(fontString, windowEditBox))
  MasterMerchantListingWindowHeadersSeller:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantListingWindowHeadersGuild:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantListingWindowHeadersLocation:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantListingWindowHeadersItemName:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantListingWindowHeadersListingTime:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantListingWindowHeadersPrice:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))

  -- Purchase Window
  MasterMerchantPurchaseWindowMenuHeaderTitle:SetFont(string.format(fontString, windowTitle))
  MasterMerchantPurchaseWindowMenuFooterPriceSwitchButton:SetFont(string.format(fontString, windowButtonLabel))
  MasterMerchantPurchaseWindowMenuHeaderSearchEditBox:SetFont(string.format(fontString, windowEditBox))
  MasterMerchantPurchaseWindowHeadersSeller:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantPurchaseWindowHeadersGuild:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantPurchaseWindowHeadersItemName:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantPurchaseWindowHeadersPurchaseTime:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantPurchaseWindowHeadersPrice:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))

  -- Reports Window
  MasterMerchantReportsWindowMenuHeaderTitle:SetFont(string.format(fontString, windowTitle))
  MasterMerchantReportsWindowMenuFooterSwitchReportsViewButton:SetFont(string.format(fontString, windowButtonLabel))
  MasterMerchantReportsWindowMenuFooterPriceSwitchButton:SetFont(string.format(fontString, windowButtonLabel))
  MasterMerchantReportsWindowMenuHeaderSearchEditBox:SetFont(string.format(fontString, windowEditBox))
  MasterMerchantReportsWindowHeadersSeller:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantReportsWindowHeadersGuild:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantReportsWindowHeadersItemName:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantReportsWindowHeadersSellTime:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantReportsWindowHeadersPrice:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))
  MasterMerchantReportsWindowHeadersListingFee:GetNamedChild('Name'):SetFont(string.format(fontString, windowHeader))

  -- Stats Window
  MasterMerchantStatsWindowTitle:SetFont(string.format(fontString, windowTitle))
  MasterMerchantStatsWindowSliderLabel:SetFont(string.format(fontString, windowButtonLabel))
  MasterMerchantStatsWindowGuildChooserLabel:SetFont(string.format(fontString, windowHeader))
  MasterMerchantStatsGuildChooser.m_comboBox:SetFont(string.format(fontString, windowHeader))
  MasterMerchantStatsWindowItemsSoldLabel:SetFont(string.format(fontString, windowHeader))
  MasterMerchantStatsWindowTotalGoldLabel:SetFont(string.format(fontString, windowHeader))
  MasterMerchantStatsWindowBiggestSaleLabel:SetFont(string.format(fontString, windowHeader))
  MasterMerchantStatsWindowSliderSettingLabel:SetFont(string.format(fontString, windowHeader))

  MasterMerchantFeedbackTitle:SetFont(string.format(fontString, windowTitle))
  MasterMerchantFeedbackNote:SetFont(string.format(fontString, windowHeader))
  MasterMerchantFeedbackNote:SetText(GetString(SK_FEEDBACK_MESSAGE))

  --[[TODO Setup New Filter windows
  ]]--
  MasterMerchantFilterByTypeWindowMenuHeaderTitle:SetFont(string.format(fontString, windowTitle))
  MasterMerchantFilterByNameWindowMenuHeaderTitle:SetFont(string.format(fontString, windowTitle))
  MasterMerchantFilterByNameWindowMenuFooterClearFilterButton:SetFont(string.format(fontString, windowButtonLabel))

end

function MasterMerchant:updateCalc()
  local stackSize = zo_strmatch(MasterMerchantPriceCalculatorStack:GetText(), 'x (%d+)')
  local unitPrice = MasterMerchantPriceCalculatorUnitCostAmount:GetText()
  if not stackSize or tonumber(stackSize) < 1 then
    MasterMerchant:dm("Info", string.format("%s is not a valid stack size", stackSize))
    return
  end
  if not unitPrice or tonumber(unitPrice) < 0.01 then
    MasterMerchant:dm("Info", string.format("%s is not a valid unit price", unitPrice))
    return
  end
  local totalPrice = math.floor(tonumber(unitPrice) * tonumber(stackSize))
  MasterMerchantPriceCalculatorTotal:SetText(GetString(MM_TOTAL_TITLE) .. MasterMerchant.LocalizedNumber(totalPrice) .. ' |t16:16:EsoUI/Art/currency/currency_gold.dds|t')
  TRADING_HOUSE:SetPendingPostPrice(totalPrice)
end

function MasterMerchant:remStatsItemTooltip()
  self.tippingControl = nil
  if ItemTooltip.graphPool then
    ItemTooltip.graphPool:ReleaseAllObjects()
  end
  ItemTooltip.mmGraph = nil
  if ItemTooltip.textPool then
    ItemTooltip.textPool:ReleaseAllObjects()
  end
  if ItemTooltip.tooltipTextPool then
    ItemTooltip.tooltipTextPool:ReleaseAllObjects()
  end
  ItemTooltip.warnText = nil
  ItemTooltip.vendorWarnText = nil
  ItemTooltip.mmText = nil
  ItemTooltip.mmBonanzaText = nil
  ItemTooltip.mmTTCText = nil
  ItemTooltip.mmVoucherText = nil
  ItemTooltip.mmCraftText = nil
  ItemTooltip.mmMatText = nil
  ItemTooltip.mmTextDebug = nil
  ItemTooltip.mmQualityDown = nil
  ItemTooltip.mmQualityUp = nil
  ItemTooltip.mmLevelDown = nil
  ItemTooltip.mmLevelUp = nil
  ItemTooltip.mmSalesDataDown = nil
  ItemTooltip.mmSalesDataUp = nil
end

function MasterMerchant:GenerateStatsAndGraph(tooltip, itemLink, purchasePrice, stackCount)
  if not MasterMerchant.isInitialized then return end

  local function GetVendorPricing(itemType, itemId)
    if MasterMerchant["vendor_price_table"][itemType] then
      if MasterMerchant["vendor_price_table"][itemType][itemId] then return MasterMerchant["vendor_price_table"][itemType][itemId] end
    end
    return nil
  end

  local showTooltipInformation = (MasterMerchant.systemSavedVariables.showPricing or MasterMerchant.systemSavedVariables.showGraph or MasterMerchant.systemSavedVariables.showCraftCost or MasterMerchant.systemSavedVariables.showBonanzaPricing or MasterMerchant.systemSavedVariables.showAltTtcTipline or MasterMerchant.systemSavedVariables.showMaterialCost)
  local bindType = GetItemLinkBindType(itemLink)
  local bindOnPickup = bindType == BIND_TYPE_ON_PICKUP or bindType == BIND_TYPE_ON_PICKUP_BACKPACK

  if not showTooltipInformation or bindOnPickup then return end

  local itemType = GetItemLinkItemType(itemLink)
  local itemId = GetItemLinkItemId(itemLink)
  local masterMerchantTipline = nil
  local craftCostLine = nil
  local bonanzaTipline = nil
  local ttcTipline = nil
  local voucherTipline = nil
  local materialCostLine = nil
  local removedWarningTipline = nil
  local vendorWarningTipline = nil
  local vendorWarningPricing = GetVendorPricing(itemType, itemId)
  -- the removedItemIdTable table has only true values, no function needed
  local showRemovedWarning = MasterMerchant.removedItemIdTable[itemId]
  local showVendorWarning = false
  local hasGraphInfo = false
  local validAnalysisButtonType = itemType == ITEMTYPE_WEAPON or itemType == ITEMTYPE_ARMOR or itemType == ITEMTYPE_GLYPH_WEAPON or itemType == ITEMTYPE_GLYPH_ARMOR or itemType == ITEMTYPE_GLYPH_JEWELRY
  -- old values: tipLine, bonanzaTipline, numDays, avgPrice, bonanzaPrice, graphInfo
  -- input: avgPrice, legitSales, daysHistory, countSold, bonanzaPrice, bonanzaListings, bonanzaItemCount, graphInfo
  -- return: avgPrice, numSales, numDays, numItems, bonanzaPrice, bonanzaListings, bonanzaItemCount, graphInfo
  -- input ['graphInfo']: oldestTime, lowPrice, highPrice, salesPoints
  -- return ['graphInfo']: oldestTime, low, high, points
  local statsInfo = self:GetTooltipStats(itemLink, false, true)
  local priceStats
  local useTTCPrice = MasterMerchant.systemSavedVariables.showAltTtcTipline or (MasterMerchant.systemSavedVariables.includeVoucherAverage and (MasterMerchant.systemSavedVariables.voucherValueTypeToUse == MM_PRICE_TTC_SUGGESTED or MasterMerchant.systemSavedVariables.voucherValueTypeToUse == MM_PRICE_TTC_AVERAGE))
  if TamrielTradeCentre and useTTCPrice then
    priceStats = TamrielTradeCentrePrice:GetPriceInfo(itemLink)
  end
  local graphInfo = statsInfo.graphInfo
  if graphInfo and graphInfo.points ~= nil then
    hasGraphInfo = true
  end

  local xBonanza = ""
  if purchasePrice and stackCount and vendorWarningPricing then
    local storeItemUnitPrice = purchasePrice / stackCount
    if storeItemUnitPrice > vendorWarningPricing then showVendorWarning = true end
  end
  if showVendorWarning then
    vendorWarningTipline = string.format(GetString(MM_VENDOR_ITEM_WARN), vendorWarningPricing) .. MM_COIN_ICON_NO_SPACE
  end
  if showRemovedWarning ~= nil then
    removedWarningTipline = GetString(MM_REMOVED_ITEM_WARN)
  end
  if MasterMerchant.systemSavedVariables.showCraftCost then
    craftCostLine = self:CraftCostPriceTip(itemLink, false)
  end
  if MasterMerchant.systemSavedVariables.showMaterialCost and itemType == ITEMTYPE_MASTER_WRIT then
    materialCostLine = MasterMerchant:MaterialCostPriceTip(itemLink, purchasePrice)
  end
  masterMerchantTipline = MasterMerchant:AvgPricePriceTip(statsInfo, false)
  if statsInfo.bonanzaPrice then
    bonanzaTipline = MasterMerchant:BonanzaPriceTip(statsInfo, false)
  end
  if MasterMerchant.systemSavedVariables.showAltTtcTipline and TamrielTradeCentre then
    ttcTipline = MasterMerchant:TTCPriceTip(priceStats, false)
  end
  if statsInfo.bonanzaListings and (statsInfo.bonanzaListings < 6) and MasterMerchant.systemSavedVariables.omitBonanzaPricingGraphLessThanSix then
    statsInfo.bonanzaPrice = nil
    statsInfo.bonanzaListings = nil
    statsInfo.bonanzaItemCount = nil
  end
  local useVoucherCount = statsInfo and statsInfo.numVouchers and statsInfo.numVouchers > 0 and MasterMerchant.systemSavedVariables.includeVoucherAverage
  if useVoucherCount then
    voucherTipline = MasterMerchant:VoucherAveragePriceTip(statsInfo, priceStats, false)
  end

  if validAnalysisButtonType and MasterMerchant.systemSavedVariables.displayItemAnalysisButtons then
    if not tooltip.textPool then
      tooltip.textPool = ZO_ControlPool:New('MMQualityLabel', tooltip, 'Text')
    end

    if not tooltip.mmQualityDown then
      tooltip.mmQualityDown = tooltip.textPool:AcquireObject()
      tooltip:AddControl(tooltip.mmQualityDown, 1, true)
      tooltip.mmQualityDown:SetText('<<')
      tooltip.mmQualityDown:SetMouseEnabled(true)
      tooltip.mmQualityDown:SetHandler("OnMouseUp", MasterMerchant.NextItem)
      tooltip.mmQualityDown.mmData = {}
      tooltip.mmQualityDown:SetHidden(true)
    end

    if not tooltip.mmQualityUp then
      tooltip.mmQualityUp = tooltip.textPool:AcquireObject()
      tooltip:AddControl(tooltip.mmQualityUp, 1, true)
      tooltip.mmQualityUp:SetText('>>')
      tooltip.mmQualityUp:SetMouseEnabled(true)
      tooltip.mmQualityUp:SetHandler("OnMouseUp", MasterMerchant.NextItem)
      tooltip.mmQualityUp.mmData = {}
      tooltip.mmQualityUp:SetHidden(true)
    end

    if not tooltip.mmLevelDown then
      tooltip.mmLevelDown = tooltip.textPool:AcquireObject()
      tooltip:AddControl(tooltip.mmLevelDown, 1, true)
      tooltip.mmLevelDown:SetText('< L')
      tooltip.mmLevelDown:SetColor(1, 1, 1, 1)
      tooltip.mmLevelDown:SetMouseEnabled(true)
      tooltip.mmLevelDown:SetHandler("OnMouseUp", MasterMerchant.NextItem)
      tooltip.mmLevelDown.mmData = {}
      tooltip.mmLevelDown:SetHidden(true)
    end

    if not tooltip.mmLevelUp then
      tooltip.mmLevelUp = tooltip.textPool:AcquireObject()
      tooltip:AddControl(tooltip.mmLevelUp, 1, true)
      tooltip.mmLevelUp:SetText('L >')
      tooltip.mmLevelUp:SetColor(1, 1, 1, 1)
      tooltip.mmLevelUp:SetMouseEnabled(true)
      tooltip.mmLevelUp:SetHandler("OnMouseUp", MasterMerchant.NextItem)
      tooltip.mmLevelUp.mmData = {}
      tooltip.mmLevelUp:SetHidden(true)
    end

    if not tooltip.mmSalesDataDown then
      tooltip.mmSalesDataDown = tooltip.textPool:AcquireObject()
      tooltip:AddControl(tooltip.mmSalesDataDown, 1, true)
      tooltip.mmSalesDataDown:SetText('<SI')
      tooltip.mmSalesDataDown:SetColor(1, 1, 1, 1)
      tooltip.mmSalesDataDown:SetMouseEnabled(true)
      tooltip.mmSalesDataDown:SetHandler("OnMouseUp", MasterMerchant.NextItem)
      tooltip.mmSalesDataDown.mmData = {}
      tooltip.mmSalesDataDown:SetHidden(true)
    end

    if not tooltip.mmSalesDataUp then
      tooltip.mmSalesDataUp = tooltip.textPool:AcquireObject()
      tooltip:AddControl(tooltip.mmSalesDataUp, 1, true)
      tooltip.mmSalesDataUp:SetText('SI>')
      tooltip.mmSalesDataUp:SetColor(1, 1, 1, 1)
      tooltip.mmSalesDataUp:SetMouseEnabled(true)
      tooltip.mmSalesDataUp:SetHandler("OnMouseUp", MasterMerchant.NextItem)
      tooltip.mmSalesDataUp.mmData = {}
      tooltip.mmSalesDataUp:SetHidden(true)
    end
  end

  if validAnalysisButtonType and MasterMerchant.systemSavedVariables.displayItemAnalysisButtons then

    local itemQuality = GetItemLinkQuality(itemLink)
    tooltip.mmQualityDown.mmData.nextItem = MasterMerchant.QualityDown(itemLink)
    --d(tooltip.mmQualityDown.mmData.nextItem)
    if tooltip.mmQualityDown.mmData.nextItem then
      local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, itemQuality - 1)
      tooltip.mmQualityDown:SetColor(r, g, b, 1)
      tooltip.mmQualityDown:ClearAnchors()
      tooltip.mmQualityDown:SetAnchor(LEFT, tooltip, LEFT)
      tooltip.mmQualityDown:SetHidden(false)
    else
      tooltip.mmQualityDown:SetHidden(true)
    end

    tooltip.mmQualityUp.mmData.nextItem = MasterMerchant.QualityUp(itemLink)
    --d(tooltip.mmQualityUp.mmData.nextItem)
    if tooltip.mmQualityUp.mmData.nextItem then
      local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, itemQuality + 1)
      tooltip.mmQualityUp:SetColor(r, g, b, 1)
      tooltip.mmQualityUp:ClearAnchors()
      tooltip.mmQualityUp:SetAnchor(RIGHT, tooltip, RIGHT)
      tooltip.mmQualityUp:SetHidden(false)
    else
      tooltip.mmQualityUp:SetHidden(true)
    end

    tooltip.mmLevelDown.mmData.nextItem = MasterMerchant.LevelDown(itemLink)
    --d(tooltip.mmLevelDown.mmData.nextItem)
    if tooltip.mmLevelDown.mmData.nextItem then
      tooltip.mmLevelDown:ClearAnchors()
      tooltip.mmLevelDown:SetAnchor(LEFT, tooltip, LEFT, 0, 25)
      tooltip.mmLevelDown:SetHidden(false)
    else
      tooltip.mmLevelDown:SetHidden(true)
    end

    tooltip.mmLevelUp.mmData.nextItem = MasterMerchant.LevelUp(itemLink)
    --d(tooltip.mmLevelUp.mmData.nextItem)
    if tooltip.mmLevelUp.mmData.nextItem then
      tooltip.mmLevelUp:ClearAnchors()
      tooltip.mmLevelUp:SetAnchor(RIGHT, tooltip, RIGHT, 0, 25)
      tooltip.mmLevelUp:SetHidden(false)
    else
      tooltip.mmLevelUp:SetHidden(true)
    end

    tooltip.mmSalesDataDown.mmData.nextItem = MasterMerchant.Down(itemLink)
    while tooltip.mmSalesDataDown.mmData.nextItem and not self:itemLinkHasSales(tooltip.mmSalesDataDown.mmData.nextItem) do
      tooltip.mmSalesDataDown.mmData.nextItem = MasterMerchant.Down(tooltip.mmSalesDataDown.mmData.nextItem)
    end
    --d(tooltip.mmSalesDataDown.mmData.nextItem)
    if tooltip.mmSalesDataDown.mmData.nextItem then
      tooltip.mmSalesDataDown:ClearAnchors()
      tooltip.mmSalesDataDown:SetAnchor(LEFT, tooltip, LEFT, 0, -25)
      tooltip.mmSalesDataDown:SetHidden(false)
    else
      tooltip.mmSalesDataDown:SetHidden(true)
    end

    tooltip.mmSalesDataUp.mmData.nextItem = MasterMerchant.Up(itemLink)
    while tooltip.mmSalesDataUp.mmData.nextItem and not self:itemLinkHasSales(tooltip.mmSalesDataUp.mmData.nextItem) do
      tooltip.mmSalesDataUp.mmData.nextItem = MasterMerchant.Up(tooltip.mmSalesDataUp.mmData.nextItem)
    end
    --d(tooltip.mmSalesDataUp.mmData.nextItem)
    if tooltip.mmSalesDataUp.mmData.nextItem then
      tooltip.mmSalesDataUp:ClearAnchors()
      tooltip.mmSalesDataUp:SetAnchor(RIGHT, tooltip, RIGHT, 0, -25)
      tooltip.mmSalesDataUp:SetHidden(false)
    else
      tooltip.mmSalesDataUp:SetHidden(true)
    end

  end

  if not tooltip.tooltipTextPool then
    tooltip.tooltipTextPool = ZO_ControlPool:New("MMTooltipText", tooltip, "MMTooltipLine")
  end

  local hasTiplineOrGraph = vendorWarningTipline or removedWarningTipline or masterMerchantTipline or hasGraphInfo or craftCostLine or bonanzaTipline or ttcTipline or voucherTipline or materialCostLine
  local hasTiplineControls = tooltip.vendorWarnText or tooltip.warnText or tooltip.mmText or tooltip.mmBonanzaText or tooltip.mmTTCText or tooltip.mmVoucherText or tooltip.mmCraftText or tooltip.mmMatText or tooltip.mmGraph or tooltip.mmTextDebug

  if hasTiplineOrGraph and not hasTiplineControls then
    tooltip:AddVerticalPadding(2)
    ZO_Tooltip_AddDivider(tooltip)
  end

  if removedWarningTipline then
    if not tooltip.warnText then
      tooltip:AddVerticalPadding(2)
      tooltip.warnText = tooltip.tooltipTextPool:AcquireObject()
      tooltip:AddControl(tooltip.warnText)
      tooltip.warnText:SetAnchor(CENTER)
    end

    if tooltip.warnText then
      tooltip.warnText:SetText(removedWarningTipline)
      tooltip.warnText:SetColor(0.87, 0.11, 0.14, 1)
    end

  end

  if vendorWarningTipline then
    if not tooltip.vendorWarnText then
      tooltip:AddVerticalPadding(2)
      tooltip.vendorWarnText = tooltip.tooltipTextPool:AcquireObject()
      tooltip:AddControl(tooltip.vendorWarnText)
      tooltip.vendorWarnText:SetAnchor(CENTER)
    end

    if tooltip.vendorWarnText then
      tooltip.vendorWarnText:SetText(vendorWarningTipline)
    end

  end

  if masterMerchantTipline and MasterMerchant.systemSavedVariables.showPricing then

    if not tooltip.mmText then
      tooltip:AddVerticalPadding(2)
      tooltip.mmText = tooltip.tooltipTextPool:AcquireObject()
      tooltip:AddControl(tooltip.mmText)
      tooltip.mmText:SetAnchor(CENTER)
    end

    if tooltip.mmText then
      tooltip.mmText:SetText(masterMerchantTipline)
      tooltip.mmText:SetColor(1, 1, 1, 1)
    end

  end

  if bonanzaTipline and MasterMerchant.systemSavedVariables.showBonanzaPricing then

    if not tooltip.mmBonanzaText then
      tooltip:AddVerticalPadding(2)
      tooltip.mmBonanzaText = tooltip.tooltipTextPool:AcquireObject()
      tooltip:AddControl(tooltip.mmBonanzaText)
      tooltip.mmBonanzaText:SetAnchor(CENTER)
    end

    if tooltip.mmBonanzaText then
      tooltip.mmBonanzaText:SetText(bonanzaTipline)
      tooltip.mmBonanzaText:SetColor(1, 1, 1, 1)
    end

  end

  if ttcTipline and MasterMerchant.systemSavedVariables.showAltTtcTipline then

    if not tooltip.mmTTCText then
      tooltip:AddVerticalPadding(2)
      tooltip.mmTTCText = tooltip.tooltipTextPool:AcquireObject()
      tooltip:AddControl(tooltip.mmTTCText)
      tooltip.mmTTCText:SetAnchor(CENTER)
    end

    if tooltip.mmTTCText then
      tooltip.mmTTCText:SetText(ttcTipline)
      tooltip.mmTTCText:SetColor(1, 1, 1, 1)
    end

  end

  if voucherTipline and MasterMerchant.systemSavedVariables.includeVoucherAverage then

    if not tooltip.mmVoucherText then
      tooltip:AddVerticalPadding(2)
      tooltip.mmVoucherText = tooltip.tooltipTextPool:AcquireObject()
      tooltip:AddControl(tooltip.mmVoucherText)
      tooltip.mmVoucherText:SetAnchor(CENTER)
    end

    if tooltip.mmVoucherText then
      tooltip.mmVoucherText:SetText(voucherTipline)
      tooltip.mmVoucherText:SetColor(1, 1, 1, 1)
    end

  end

  if craftCostLine and MasterMerchant.systemSavedVariables.showCraftCost then

    if not tooltip.mmCraftText then
      tooltip:AddVerticalPadding(2)
      tooltip.mmCraftText = tooltip.tooltipTextPool:AcquireObject()
      tooltip:AddControl(tooltip.mmCraftText)
      tooltip.mmCraftText:SetAnchor(CENTER)
    end

    if tooltip.mmCraftText then
      tooltip.mmCraftText:SetText(craftCostLine)
      tooltip.mmCraftText:SetColor(1, 1, 1, 1)
    end

  end

  if materialCostLine and MasterMerchant.systemSavedVariables.showMaterialCost then

    if not tooltip.mmMatText then
      tooltip:AddVerticalPadding(2)
      tooltip.mmMatText = tooltip.tooltipTextPool:AcquireObject()
      tooltip:AddControl(tooltip.mmMatText)
      tooltip.mmMatText:SetAnchor(CENTER)
    end

    if tooltip.mmMatText then
      tooltip.mmMatText:SetText(materialCostLine)
      tooltip.mmMatText:SetColor(1, 1, 1, 1)
    end

  end

  if hasGraphInfo and MasterMerchant.systemSavedVariables.showGraph then

    if not tooltip.graphPool then
      tooltip.graphPool = ZO_ControlPool:New('MasterMerchantGraph', tooltip, 'MMGraph')
    end

    if not tooltip.mmGraph then
      tooltip:AddVerticalPadding(2)
      tooltip.mmGraph = tooltip.graphPool:AcquireObject()
      tooltip:AddControl(tooltip.mmGraph)
      tooltip.mmGraph:SetAnchor(CENTER)
    end

    if tooltip.mmGraph then
      local graph = tooltip.mmGraph
      graph.itemLink = itemLink

      if not graph.points then
        graph.points = MM_Graph:New(graph, "MM_Point", "MMGraphLabel")
      end

      if graphInfo.low == graphInfo.high then
        graphInfo.low = statsInfo.avgPrice * 0.85
        graphInfo.high = statsInfo.avgPrice * 1.15
      end

      if graphInfo.low < 0 then
        graphInfo.low = 0
      end
      if graphInfo.high < 1 then
        graphInfo.high = 1
      end

      if statsInfo.bonanzaPrice then
        local lowRange = nil
        local highRange = nil
        lowRange = math.min(statsInfo.avgPrice, statsInfo.bonanzaPrice)
        highRange = math.max(statsInfo.avgPrice, statsInfo.bonanzaPrice)
        if graphInfo.low > lowRange then
          graphInfo.low = lowRange * 0.95
        end
        if graphInfo.high < highRange then
          graphInfo.high = highRange * 1.05
        end
        xBonanza = MasterMerchant.LocalizedNumber(statsInfo.bonanzaPrice) .. MM_COIN_ICON_NO_SPACE
      else
        xBonanza = nil
        statsInfo.bonanzaPrice = nil
      end

      local xLow = MasterMerchant.LocalizedNumber(graphInfo.low) .. MM_COIN_ICON_NO_SPACE
      local xHigh = MasterMerchant.LocalizedNumber(graphInfo.high) .. MM_COIN_ICON_NO_SPACE
      local xPrice = MasterMerchant.LocalizedNumber(statsInfo.avgPrice) .. MM_COIN_ICON_NO_SPACE
      local endTimeFrameText = GetString(MM_ENDTIMEFRAME_TEXT)
      -- (x_startTimeFrame, x_endTimeFrame, y_highestPriceText, y_highestPriceLabelText, x_oldestTimestamp, x_currentTimestamp, y_lowestPriceValue, y_highestPriceValue, x_averagePriceText, x_averagePriceValue, x_bonanzaPriceText, x_bonanzaPriceValue)
      -- (MasterMerchant.TextTimeSince(graphInfo.oldestTime), "Now", xLow, xHigh, graphInfo.oldestTime, GetTimeStamp(), graphInfo.low, graphInfo.high, xPrice, statsInfo.avgPrice, x_bonanzaPriceText, x_bonanzaPriceValue)
      graph.points:Initialize(MasterMerchant.TextTimeSince(graphInfo.oldestTime), endTimeFrameText, xLow, xHigh,
        graphInfo.oldestTime, GetTimeStamp(), graphInfo.low, graphInfo.high, xPrice, statsInfo.avgPrice, xBonanza, statsInfo.bonanzaPrice)
      for _, point in ipairs(graphInfo.points) do
        graph.points:AddPoint(point[1], point[2], point[3], point[4], point[5])
      end

    end
  end

  if MasterMerchant.systemSavedVariables.useLibDebugLogger then
    if not tooltip.mmTextDebug then
      tooltip.mmTextDebug = tooltip.tooltipTextPool:AcquireObject()
      tooltip:AddControl(tooltip.mmTextDebug)
      tooltip.mmTextDebug:SetAnchor(CENTER)
    end

    local itemInfo = MasterMerchant.ItemCodeText(itemLink)
    --local itemInfo = zo_strmatch(itemLink, '|H.-:item:(.-):')
    itemInfo = itemInfo .. ' - ' .. internal.GetOrCreateIndexFromLink(itemLink)
    itemInfo = itemInfo .. ' - ' .. internal:AddSearchToItem(itemLink)
    --local itemType = GetItemLinkItemType(itemLink)
    --itemInfo = '(' .. itemType .. ')' .. itemInfo
    if itemInfo then
      tooltip.mmTextDebug:SetText(string.format('%s', itemInfo))
      tooltip.mmTextDebug:SetColor(1, 1, 1, 1)
    else
      tooltip.mmTextDebug:SetText('What')
      tooltip.mmTextDebug:SetColor(1, 1, 1, 1)
    end
  end

end

function MasterMerchant.NextItem(control, button)
  if control and button == MOUSE_BUTTON_INDEX_LEFT and ZO_PopupTooltip_SetLink then
    ZO_PopupTooltip_SetLink(control.mmData.nextItem)
  end
end

function MasterMerchant.ThisItem(control, button)
  if button == MOUSE_BUTTON_INDEX_RIGHT then
    ZO_LinkHandler_OnLinkMouseUp(PopupTooltip.lastLink, button, control)
  end
end


-- |H<style>:<type>[:<data>...]|h<text>|h
function MasterMerchant:addStatsPopupTooltip(Popup)
  local showTooltipInformation = (MasterMerchant.systemSavedVariables.showPricing or MasterMerchant.systemSavedVariables.showGraph or MasterMerchant.systemSavedVariables.showCraftCost or MasterMerchant.systemSavedVariables.showBonanzaPricing or MasterMerchant.systemSavedVariables.showAltTtcTipline or MasterMerchant.systemSavedVariables.showMaterialCost)

  if Popup == ZO_ProvisionerTopLevelTooltip then
    local recipeListIndex, recipeIndex = PROVISIONER:GetSelectedRecipeListIndex(), PROVISIONER:GetSelectedRecipeIndex()
    Popup.lastLink = GetRecipeResultItemLink(recipeListIndex, recipeIndex)
  end

  --Make sure Info Tooltip and Context Menu is on top of the popup
  --InformationTooltip:GetOwningWindow():BringWindowToTop()
  Popup:GetOwningWindow():SetDrawTier(ZO_Menus:GetDrawTier() - 1)
  Popup:SetHandler("OnMouseUp", MasterMerchant.ThisItem)

  -- Make sure we don't double-add stats (or double-calculate them if they bring
  -- up the same link twice) since we have to call this on Update rather than Show
  if not showTooltipInformation or Popup.lastLink == nil or (Popup.mmActiveTip and Popup.mmActiveTip == Popup.lastLink and self.isShiftPressed == IsShiftKeyDown() and self.isCtrlPressed == IsControlKeyDown()) then
    -- thanks Garkin
    return
  end

  if Popup.mmActiveTip ~= Popup.lastLink then
    if Popup.graphPool then
      Popup.graphPool:ReleaseAllObjects()
    end
    Popup.mmGraph = nil
    if Popup.textPool then
      Popup.textPool:ReleaseAllObjects()
    end
    if Popup.tooltipTextPool then
      Popup.tooltipTextPool:ReleaseAllObjects()
    end
    Popup.warnText = nil
    Popup.vendorWarnText = nil
    Popup.mmText = nil
    Popup.mmBonanzaText = nil
    Popup.mmTTCText = nil
    Popup.mmVoucherText = nil
    Popup.mmCraftText = nil
    Popup.mmMatText = nil
    Popup.mmTextDebug = nil
    Popup.mmQualityDown = nil
    Popup.mmQualityUp = nil
    Popup.mmLevelDown = nil
    Popup.mmLevelUp = nil
    Popup.mmSalesDataDown = nil
    Popup.mmSalesDataUp = nil
  end
  Popup.mmActiveTip = Popup.lastLink
  self.isShiftPressed = IsShiftKeyDown()
  self.isCtrlPressed = IsControlKeyDown()

  self:GenerateStatsAndGraph(Popup, Popup.mmActiveTip)
end

function MasterMerchant:addStatsProvisionerTooltip(Popup)
  if not MasterMerchant.isInitialized then return end
  local showTooltipInformation = (MasterMerchant.systemSavedVariables.showPricing or MasterMerchant.systemSavedVariables.showGraph or MasterMerchant.systemSavedVariables.showCraftCost or MasterMerchant.systemSavedVariables.showBonanzaPricing or MasterMerchant.systemSavedVariables.showAltTtcTipline or MasterMerchant.systemSavedVariables.showMaterialCost)

  local recipeListIndex, recipeIndex = PROVISIONER:GetSelectedRecipeListIndex(), PROVISIONER:GetSelectedRecipeIndex()
  Popup.lastLink = GetRecipeResultItemLink(recipeListIndex, recipeIndex)

  --Make sure Info Tooltip and Context Menu is on top of the popup
  --InformationTooltip:GetOwningWindow():BringWindowToTop()
  Popup:GetOwningWindow():SetDrawTier(ZO_Menus:GetDrawTier() - 1)

  -- Make sure we don't double-add stats (or double-calculate them if they bring
  -- up the same link twice) since we have to call this on Update rather than Show
  if not showTooltipInformation or Popup.lastLink == nil or (Popup.mmActiveTip and Popup.mmActiveTip == Popup.lastLink and self.isShiftPressed == IsShiftKeyDown() and self.isCtrlPressed == IsControlKeyDown()) then
    -- thanks Garkin
    return
  end

  if Popup.mmActiveTip ~= Popup.lastLink then
    if Popup.graphPool then
      Popup.graphPool:ReleaseAllObjects()
    end
    Popup.mmGraph = nil
    if Popup.textPool then
      Popup.textPool:ReleaseAllObjects()
    end
    if Popup.tooltipTextPool then
      Popup.tooltipTextPool:ReleaseAllObjects()
    end
    Popup.warnText = nil
    Popup.vendorWarnText = nil
    Popup.mmText = nil
    Popup.mmBonanzaText = nil
    Popup.mmTTCText = nil
    Popup.mmVoucherText = nil
    Popup.mmCraftText = nil
    Popup.mmMatText = nil
    Popup.mmTextDebug = nil
    Popup.mmQualityDown = nil
    Popup.mmQualityUp = nil
    Popup.mmLevelDown = nil
    Popup.mmLevelUp = nil
    Popup.mmSalesDataDown = nil
    Popup.mmSalesDataUp = nil
  end
  Popup.mmActiveTip = Popup.lastLink
  self.isShiftPressed = IsShiftKeyDown()
  self.isCtrlPressed = IsControlKeyDown()

  self:GenerateStatsAndGraph(Popup, Popup.mmActiveTip)
end

function MasterMerchant:remStatsPopupTooltip(Popup)
  if Popup.graphPool then
    Popup.graphPool:ReleaseAllObjects()
  end
  Popup.mmGraph = nil
  if Popup.textPool then
    Popup.textPool:ReleaseAllObjects()
  end
  if Popup.tooltipTextPool then
    Popup.tooltipTextPool:ReleaseAllObjects()
  end

  Popup.warnText = nil
  Popup.vendorWarnText = nil
  Popup.mmText = nil
  Popup.mmBonanzaText = nil
  Popup.mmTTCText = nil
  Popup.mmVoucherText = nil
  Popup.mmCraftText = nil
  Popup.mmMatText = nil
  Popup.mmTextDebug = nil
  Popup.mmQualityDown = nil
  Popup.mmQualityUp = nil
  Popup.mmLevelDown = nil
  Popup.mmLevelUp = nil
  Popup.mmSalesDataDown = nil
  Popup.mmSalesDataUp = nil
  Popup.mmActiveTip = nil
end

local function GetTopControl(control)
  local controlName = control:GetName()
  MasterMerchant:dm("Verbose", controlName)
  local count = 0
  while control and control.GetParent ~= nil do
    control = control:GetParent()
    count = count + 1
    if control and control.GetName then
      controlName = control:GetName()
      MasterMerchant:dm("Verbose", controlName)
      if controlName == "GuiRoot" then break end
      if count >= 3 then break end
    end
  end
end

function MasterMerchant:SetCrafted(itemLink)
  local linkParse = { ZO_LinkHandler_ParseLink(itemLink) }
  local craftedlink = string.format("|H1:item:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s|h|h", linkParse[4],
    linkParse[5], linkParse[6], linkParse[7], linkParse[8], linkParse[9], linkParse[10], linkParse[11],
    linkParse[12], linkParse[13], linkParse[14], linkParse[15], linkParse[16], linkParse[17], linkParse[18],
    linkParse[19], "1", linkParse[21], linkParse[22], linkParse[23], linkParse[24])
  return craftedlink
end

function MasterMerchant:SetLevelAndQuality(itemLink)
  local linkParse = { ZO_LinkHandler_ParseLink(itemLink) }
  local itemLevel = GetItemLinkDisplayQuality(itemLink) + 1
  local craftedlink = string.format("|H1:item:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s|h|h", linkParse[4],
    itemLevel, "1", linkParse[7], linkParse[8], linkParse[9], linkParse[10], linkParse[11],
    linkParse[12], linkParse[13], linkParse[14], linkParse[15], linkParse[16], linkParse[17], linkParse[18],
    linkParse[19], linkParse[20], linkParse[21], linkParse[22], linkParse[23], linkParse[24])
  return craftedlink
end

-- ItemTooltips get used all over the place, we have to figure out
-- who the control generating the tooltip is so we know
-- how to grab the item data
function MasterMerchant:GenerateStatsItemTooltip()
  if not MasterMerchant.isInitialized then return end
  local showTooltipInformation = (MasterMerchant.systemSavedVariables.showPricing or MasterMerchant.systemSavedVariables.showGraph or MasterMerchant.systemSavedVariables.showCraftCost or MasterMerchant.systemSavedVariables.showBonanzaPricing or MasterMerchant.systemSavedVariables.showAltTtcTipline or MasterMerchant.systemSavedVariables.showMaterialCost)
  -- local skMoc = moc()
  local mouseOverControl = moc()
  -- Make sure we don't double-add stats or try to add them to nothing
  -- Since we call this on Update rather than Show it gets called a lot
  -- even after the tip appears
  if not showTooltipInformation or (not mouseOverControl or not mouseOverControl:GetParent()) or (mouseOverControl == self.tippingControl and self.isShiftPressed == IsShiftKeyDown() and self.isCtrlPressed == IsControlKeyDown()) then
    return
  end

  local itemLink = nil
  local purchasePrice = nil
  local stackCount = nil
  local mouseOverControlParent
  local mouseOverControlGrandparent
  local mocOwner

  if mouseOverControl.GetParent then mouseOverControlParent = mouseOverControl:GetParent() end
  if mouseOverControlParent and mouseOverControlParent.GetParent then mouseOverControlGrandparent = mouseOverControlParent:GetParent() end
  if mouseOverControl and mouseOverControl.GetOwningWindow then mocOwner = mouseOverControl:GetOwningWindow() end

  local mocName = mouseOverControl:GetName()
  local mocParentName
  local mocGPName
  local mocOwnerName

  if mouseOverControlParent then mocParentName = mouseOverControlParent:GetName() end
  if mouseOverControlGrandparent then mocGPName = mouseOverControlGrandparent:GetName() end
  if mocOwner then mocOwnerName = mocOwner:GetName() end

  local hasDataEntryData = mouseOverControl and mouseOverControl.dataEntry and mouseOverControl.dataEntry.data
  local hasParentData = mouseOverControlParent and mouseOverControlParent.data
  local hasMocData = mouseOverControl and mouseOverControl.data

  if mocParentName == 'ZO_CraftBagListContents' or
    mocParentName == 'ZO_PlayerInventoryListContents' or
    mocParentName == 'ZO_EnchantingTopLevelInventoryBackpackContents' or
    mocParentName == 'ZO_SmithingTopLevelRefinementPanelInventoryBackpackContents' or
    mocParentName == 'ZO_SmithingTopLevelDeconstructionPanelInventoryBackpackContents' or
    mocParentName == 'ZO_SmithingTopLevelImprovementPanelInventoryBackpackContents' or
    mocParentName == 'ZO_QuickSlot_Keyboard_TopLevelListContents' or
    mocParentName == 'ZO_PlayerBankBackpackContents' or
    mocParentName == 'ZO_GuildBankBackpackContents' or
    mocParentName == 'ZO_HouseBankBackpackContents' or
    mocParentName == 'ZO_UniversalDeconstructionTopLevel_KeyboardPanelInventoryBackpackContents' or
    mocParentName == 'ZO_CompanionEquipment_Panel_KeyboardListContents' then
    if not hasDataEntryData then return end
    local rowData = mouseOverControl.dataEntry.data
    itemLink = GetItemLink(rowData.bagId, rowData.slotIndex, LINK_STYLE_BRACKETS)

  elseif mocParentName == "ZO_Character" then
    -- is worn item
    itemLink = GetItemLink(mouseOverControl.bagId, mouseOverControl.slotIndex, LINK_STYLE_BRACKETS)

  elseif mocParentName == "ZO_CompanionCharacterWindow_Keyboard_TopLevel" then
    -- is worn item
    itemLink = GetItemLink(mouseOverControl.bagId, mouseOverControl.slotIndex, LINK_STYLE_BRACKETS)

  elseif mocParentName == "ZO_LootAlphaContainerListContents" then
    -- is loot item
    if not hasDataEntryData then return end
    local rowData = mouseOverControl.dataEntry.data
    itemLink = GetLootItemLink(rowData.lootId, LINK_STYLE_BRACKETS)

  elseif mocParentName == "ZO_BuyBackListContents" then
    -- is buyback item
    itemLink = GetBuybackItemLink(mouseOverControl.index, LINK_STYLE_BRACKETS)

  elseif mocParentName == "ZO_StoreWindowListContents" then
    -- is store item
    local collectibleId = GetStoreCollectibleInfo(mouseOverControl.index)
    local isCollectible = collectibleId and collectibleId > 0
    if isCollectible then return end
    itemLink = GetStoreItemLink(mouseOverControl.index, LINK_STYLE_BRACKETS)

  elseif mocParentName == 'ZO_MailInboxMessageAttachments' then
    -- MAIL_INBOX:GetOpenMailId() is the id64 of the mail
    itemLink = GetAttachedItemLink(MAIL_INBOX:GetOpenMailId(), mouseOverControl.id, LINK_STYLE_DEFAULT)

  elseif mocParentName == 'ZO_MailSendAttachments' then
    itemLink = GetMailQueuedAttachmentLink(mouseOverControl.id, LINK_STYLE_DEFAULT)

    -- following 4 if's derived directly from MasterMerchant
  elseif mocOwnerName == 'MasterMerchantWindow' or
    mocOwnerName == 'MasterMerchantGuildWindow' or
    mocOwnerName == 'MasterMerchantPurchaseWindow' or
    mocOwnerName == 'MasterMerchantListingWindow' or
    mocOwnerName == 'MasterMerchantFilterByNameWindow' or
    mocOwnerName == 'MasterMerchantReportsWindow' then
    if mouseOverControl.GetText then
      itemLink = mouseOverControl:GetText()
    end

  elseif mocOwnerName == "IIFA_GUI" then
    itemLink = mouseOverControl.itemLink

  elseif mocOwnerName == "FurCGui" then
    itemLink = MasterMerchant:SetLevelAndQuality(mouseOverControl.itemLink)

  elseif mocParentName == "ZO_TradingHouseBrowseItemsRightPaneSearchResultsContents" then
    if not hasDataEntryData then return end
    local rowData = mouseOverControl.dataEntry.data
    if not rowData or rowData.timeRemaining == 0 then return end
    purchasePrice = rowData.purchasePrice
    stackCount = rowData.stackCount
    itemLink = GetTradingHouseSearchResultItemLink(rowData.slotIndex)

  elseif mocParentName == "ZO_TradingHousePostedItemsListContents" then
    if not hasDataEntryData then return end
    local rowData = mouseOverControl.dataEntry.data
    if not rowData or rowData.timeRemaining == 0 then return end
    purchasePrice = rowData.purchasePrice
    stackCount = rowData.stackCount
    itemLink = GetTradingHouseListingItemLink(rowData.slotIndex)

  elseif mocParentName == 'DolgubonSetCrafterWindowMaterialListListContents' then
    if not hasMocData then return end
    local rowData = mouseOverControl.data[1]
    if not rowData then return end
    itemLink = rowData.Name

  elseif mocGPName == "CraftingQueueScrollListContents" then
    if not hasParentData then return end
    local rowData = mouseOverControlParent.data[1]
    local rowDataLink = rowData.Link
    if not rowDataLink then return end
    itemLink = MasterMerchant:SetCrafted(rowDataLink)

  elseif mocParentName == "ZO_InteractWindowRewardArea" then
    -- is reward item
    itemLink = GetQuestRewardItemLink(mouseOverControl.index, LINK_STYLE_BRACKETS)

  elseif mocOwnerName == 'CraftStoreFixed_Cook' or
    mocOwnerName == 'CraftStoreFixed_Rune' or
    mocOwnerName == 'CraftStoreFixed_Blueprint_Window' then
    if not hasMocData then return end
    local rowData = mouseOverControl.data
    itemLink = rowData.link

  elseif mocOwnerName == 'ZO_ClaimLevelUpRewardsScreen_Keyboard' then
    if not hasMocData then return end
    local rowData = mouseOverControl.data
    itemLink = rowData.itemLink
  end

  --[[TODO verified to here ]]--
  if itemLink then
    if self.tippingControl ~= mouseOverControl then
      if ItemTooltip.graphPool then
        ItemTooltip.graphPool:ReleaseAllObjects()
      end
      ItemTooltip.mmGraph = nil
      if ItemTooltip.textPool then
        ItemTooltip.textPool:ReleaseAllObjects()
      end
      if ItemTooltip.tooltipTextPool then
        ItemTooltip.tooltipTextPool:ReleaseAllObjects()
      end

      ItemTooltip.warnText = nil
      ItemTooltip.vendorWarnText = nil
      ItemTooltip.mmText = nil
      ItemTooltip.mmBonanzaText = nil
      ItemTooltip.mmTTCText = nil
      ItemTooltip.mmVoucherText = nil
      ItemTooltip.mmCraftText = nil
      ItemTooltip.mmMatText = nil
      ItemTooltip.mmTextDebug = nil
      ItemTooltip.mmQualityDown = nil
      ItemTooltip.mmQualityUp = nil
      ItemTooltip.mmLevelDown = nil
      ItemTooltip.mmLevelUp = nil
      ItemTooltip.mmSalesDataDown = nil
      ItemTooltip.mmSalesDataUp = nil
    end

    self.tippingControl = mouseOverControl
    self.isShiftPressed = IsShiftKeyDown()
    self.isCtrlPressed = IsControlKeyDown()
    self:GenerateStatsAndGraph(ItemTooltip, itemLink, purchasePrice, stackCount)
  end

end


-- Display item tooltips
function MasterMerchant.ShowToolTip(itemName, itemButton)
  InitializeTooltip(ItemTooltip, itemButton)
  ItemTooltip:SetLink(itemName)
end

function MasterMerchant:HeaderToolTip(control, tipString)
  InitializeTooltip(InformationTooltip, control, BOTTOM, 0, -5)
  SetTooltipText(InformationTooltip, tipString)
end

-- Update Time Range for filtering the Guild Sales window
function MasterMerchant:UpdateGuildWindowTimerange(timeRange)
  if not timeRange or timeRange == 0 then timeRange = MM_WINDOW_TIME_RANGE_DEFAULT end
  MasterMerchant.systemSavedVariables.windowTimeRange = timeRange
  MasterMerchant:RefreshAlteredWindowData(true)
end

-- Update Guild Sales window to use the selected date range
function MasterMerchant:UpdateGuildWindow(rankIndex)
  -- MasterMerchant:dm("Debug", "UpdateGuildWindow")
  if not rankIndex or rankIndex == 0 then rankIndex = MM_DATERANGE_TODAY end
  MasterMerchant.systemSavedVariables.rankIndex = rankIndex
  MasterMerchant:RefreshAlteredWindowData(true)
end


-- Update Guild Roster window to use the selected date range
function MasterMerchant:UpdateRosterWindow(rankIndex)
  if not rankIndex or rankIndex == 0 then rankIndex = MM_DATERANGE_TODAY end
  MasterMerchant.systemSavedVariables.rankIndexRoster = rankIndex
  GUILD_ROSTER_MANAGER:RefreshData()
end

-- Update all the fields of the stats window based on the response from SalesStats()
function MasterMerchant:UpdateStatsWindow(guildName)
  if not guildName or guildName == '' then guildName = 'SK_STATS_TOTAL' end
  local sliderLevel = MasterMerchantStatsWindowSlider:GetValue()
  self.newStats = self:SalesStats(sliderLevel)

  self.newStats['totalDays'] = self.newStats['totalDays'] or 1
  self.newStats['numSold'][guildName] = self.newStats['numSold'][guildName] or 0
  self.newStats['kioskPercent'][guildName] = self.newStats['kioskPercent'][guildName] or 0
  self.newStats['totalGold'][guildName] = self.newStats['totalGold'][guildName] or 0
  self.newStats['avgGold'][guildName] = self.newStats['avgGold'][guildName] or 0
  self.newStats['biggestSale'][guildName] = self.newStats['biggestSale'][guildName] or {}
  self.newStats['biggestSale'][guildName][1] = self.newStats['biggestSale'][guildName][1] or 0
  self.newStats['biggestSale'][guildName][2] = self.newStats['biggestSale'][guildName][2] or GetString(MM_NOTHING)

  -- Hide the slider if there's less than a day of data
  -- and set the slider's range for the new day range returned
  MasterMerchantStatsWindowSliderLabel:SetHidden(false)
  MasterMerchantStatsWindowSlider:SetHidden(false)
  MasterMerchantStatsWindowSlider:SetMinMax(1, (self.newStats['totalDays']))

  if self.newStats['totalDays'] == nil or self.newStats['totalDays'] < 2 then
    MasterMerchantStatsWindowSlider:SetHidden(true)
    MasterMerchantStatsWindowSliderLabel:SetHidden(true)
    sliderLevel = 1
  elseif sliderLevel > (self.newStats['totalDays']) then sliderLevel = self.newStats['totalDays'] end

  -- Set the time range label appropriately
  if sliderLevel == self.newStats['totalDays'] then MasterMerchantStatsWindowSliderSettingLabel:SetText(GetString(SK_STATS_TIME_ALL))
  else MasterMerchantStatsWindowSliderSettingLabel:SetText(zo_strformat(GetString(SK_STATS_TIME_SOME), sliderLevel)) end

  -- Grab which guild is selected
  local guildSelected = GetString(SK_STATS_ALL_GUILDS)
  if guildName ~= 'SK_STATS_TOTAL' then guildSelected = guildName end
  local guildDropdown = ZO_ComboBox_ObjectFromContainer(MasterMerchantStatsGuildChooser)
  guildDropdown:SetSelectedItem(guildSelected)

  -- And set the rest of the stats window up with data from the appropriate
  -- guild (or overall data)
  MasterMerchantStatsWindowItemsSoldLabel:SetText(string.format(GetString(SK_STATS_ITEMS_SOLD),
    self.LocalizedNumber(self.newStats['numSold'][guildName]), (self.newStats['kioskPercent'][guildName])))
  MasterMerchantStatsWindowTotalGoldLabel:SetText(string.format(GetString(SK_STATS_TOTAL_GOLD),
    self.LocalizedNumber(self.newStats['totalGold'][guildName]),
    self.LocalizedNumber(self.newStats['avgGold'][guildName])))
  MasterMerchantStatsWindowBiggestSaleLabel:SetText(string.format(GetString(SK_STATS_BIGGEST),
    zo_strformat('<<t:1>>', self.newStats['biggestSale'][guildName][2]), (self.newStats['biggestSale'][guildName][1])))

end

-- Switch Sales window to display buyer or seller
function MasterMerchant:ToggleBuyerSeller()
  -- MasterMerchant:dm("Debug", "ToggleBuyerSeller")
  --[[TODO Make this also change the title of the window
  ]]--
  if MasterMerchant.systemSavedVariables.viewSize == ITEMS then
    if MasterMerchant.systemSavedVariables.viewBuyerSeller == 'buyer' then
      MasterMerchant.systemSavedVariables.viewBuyerSeller = 'seller'
      MasterMerchantWindowHeadersBuyer:GetNamedChild('Name'):SetText(GetString(SK_SELLER_COLUMN))
    else
      MasterMerchant.systemSavedVariables.viewBuyerSeller = 'buyer'
      MasterMerchantWindowHeadersBuyer:GetNamedChild('Name'):SetText(GetString(SK_BUYER_COLUMN))
    end

    MasterMerchant:RefreshAlteredWindowData(true)
  elseif MasterMerchant.systemSavedVariables.viewSize == GUILDS then
    if MasterMerchant.systemSavedVariables.viewGuildBuyerSeller == 'buyer' then
      MasterMerchant.systemSavedVariables.viewGuildBuyerSeller = 'seller'
      MasterMerchantGuildWindowHeadersSeller:GetNamedChild('Name'):SetText(GetString(SK_SELLER_COLUMN))
      MasterMerchantGuildWindowHeadersSales:GetNamedChild('Name'):SetText(GetString(SK_SALES_COLUMN))
    elseif MasterMerchant.systemSavedVariables.viewGuildBuyerSeller == 'seller' then
      MasterMerchant.systemSavedVariables.viewGuildBuyerSeller = 'item'
      MasterMerchantGuildWindowHeadersSeller:GetNamedChild('Name'):SetText(GetString(SK_ITEM_COLUMN))
      MasterMerchantGuildWindowHeadersSales:GetNamedChild('Name'):SetText(GetString(SK_SALES_COLUMN))
    else
      MasterMerchant.systemSavedVariables.viewGuildBuyerSeller = 'buyer'
      MasterMerchantGuildWindowHeadersSeller:GetNamedChild('Name'):SetText(GetString(SK_BUYER_COLUMN))
      MasterMerchantGuildWindowHeadersSales:GetNamedChild('Name'):SetText(GetString(SK_PURCHASES_COLUMN))
    end

    MasterMerchant:RefreshAlteredWindowData(true)
  elseif MasterMerchant.systemSavedVariables.viewSize == PURCHASES then
    if MasterMerchant.systemSavedVariables.viewBuyerSeller == 'buyer' then
      MasterMerchant.systemSavedVariables.viewBuyerSeller = 'seller'
      MasterMerchantPurchaseWindowHeadersSeller:GetNamedChild('Name'):SetText(GetString(SK_SELLER_COLUMN))
    else
      MasterMerchant.systemSavedVariables.viewBuyerSeller = 'buyer'
      MasterMerchantPurchaseWindowHeadersSeller:GetNamedChild('Name'):SetText(GetString(SK_BUYER_COLUMN))
    end

    MasterMerchant:RefreshAlteredWindowData(true)
  else
    MasterMerchant:dm("Warn", "Shit Hit the fan ToggleBuyerSeller")
    MasterMerchant:dm("Warn", MasterMerchant.systemSavedVariables.viewSize)
  end
end

-- Switches the main window between full and half size.  Really this is hiding one
-- and showing the other, but close enough ;)  Also makes the scene adjustments
-- necessary to maintain the desired mail/trading house behaviors.  Copies the
-- contents of the search box and the current sorting settings so they're the
-- same on the other window when it appears.
function MasterMerchant:ToggleViewMode()
  -- MasterMerchant:dm("Debug", "ToggleViewMode")
  -- Switching to 'guild_vs' view
  local theFragment = MasterMerchant:ActiveFragment()
  if MasterMerchant.systemSavedVariables.viewSize == LISTINGS or MasterMerchant.systemSavedVariables.viewSize == PURCHASES then
    MasterMerchant:ToggleMasterMerchantWindow()
    MAIL_INBOX_SCENE:RemoveFragment(theFragment)
    MAIL_SEND_SCENE:RemoveFragment(theFragment)
    TRADING_HOUSE_SCENE:RemoveFragment(theFragment)
    MasterMerchant.systemSavedVariables.viewSize = GUILDS
  end
  if MasterMerchant.systemSavedVariables.viewSize == ITEMS then
    MasterMerchant:ActiveWindow():SetHidden(true)
    MasterMerchant.systemSavedVariables.viewSize = GUILDS
    MasterMerchant:RefreshAlteredWindowData(true)
    MasterMerchant:ToggleMasterMerchantWindow()

    if MasterMerchant.systemSavedVariables.openWithMail then
      MAIL_INBOX_SCENE:RemoveFragment(self.salesUiFragment)
      MAIL_SEND_SCENE:RemoveFragment(self.salesUiFragment)
      MAIL_INBOX_SCENE:AddFragment(self.guildUiFragment)
      MAIL_SEND_SCENE:AddFragment(self.guildUiFragment)
    end

    if MasterMerchant.systemSavedVariables.openWithStore then
      TRADING_HOUSE_SCENE:RemoveFragment(self.salesUiFragment)
      TRADING_HOUSE_SCENE:AddFragment(self.guildUiFragment)
    end
    -- Switching to 'items_vs' view
  elseif MasterMerchant.systemSavedVariables.viewSize == GUILDS then
    MasterMerchant:ActiveWindow():SetHidden(true)
    MasterMerchant.systemSavedVariables.viewSize = ITEMS
    MasterMerchant:RefreshAlteredWindowData(true)
    MasterMerchant:ToggleMasterMerchantWindow()

    if MasterMerchant.systemSavedVariables.openWithMail then
      MAIL_INBOX_SCENE:RemoveFragment(self.guildUiFragment)
      MAIL_SEND_SCENE:RemoveFragment(self.guildUiFragment)
      MAIL_INBOX_SCENE:AddFragment(self.salesUiFragment)
      MAIL_SEND_SCENE:AddFragment(self.salesUiFragment)
    end

    if MasterMerchant.systemSavedVariables.openWithStore then
      TRADING_HOUSE_SCENE:RemoveFragment(self.guildUiFragment)
      TRADING_HOUSE_SCENE:AddFragment(self.salesUiFragment)
    end
  else
    MasterMerchant:dm("Warn", "Shit Hit the fan ToggleViewMode")
  end
end

function MasterMerchant:CloseMasterMerchantListingWindow()
  MasterMerchantListingWindow:SetHidden(true)
  MasterMerchantFilterByNameWindow:SetHidden(true)
  MasterMerchantFilterByTypeWindow:SetHidden(true)
end

-- Set the visibility status of the main window to the opposite of its current status
function MasterMerchant:ToggleMasterMerchantWindow()
  --MasterMerchant:dm("Debug", "ToggleMasterMerchantWindow")
  if not MasterMerchant.isInitialized then
    MasterMerchant:dm("Debug", "And Gretzky is denied!")
    return
  end
  MasterMerchant:ActiveWindow():SetHidden(not MasterMerchant:ActiveWindow():IsHidden())
  if not MasterMerchantFilterByNameWindow:IsHidden() then MasterMerchantFilterByNameWindow:SetHidden(true) end
  if not MasterMerchantFilterByTypeWindow:IsHidden() then MasterMerchantFilterByTypeWindow:SetHidden(true) end
end

-- /script MasterMerchant:RefreshAlteredWindowData()
function MasterMerchant:RefreshAlteredWindowData(forceRefresh, refreshMode)
  -- MasterMerchant:dm("Debug", "RefreshAlteredWindowData")
  -- viewMode is like "listings_vm" or "self_vt" for use with the listIsDirty[] table
  if not MasterMerchant.isInitialized then
    -- MasterMerchant:dm("Debug", "Master Merchant was not Initialized")
    return
  end
  local view
  if refreshMode then
    view = refreshMode
  else
    view = MasterMerchant.systemSavedVariables.viewSize
  end
  -- MasterMerchant:dm("Debug", MasterMerchant.systemSavedVariables.viewSize)
  if MasterMerchant.listIsDirty[view] or forceRefresh then
    MasterMerchant.listIsDirty[view] = false
    if forceRefresh then
      -- MasterMerchant:dm("Debug", "the refresh was forced")
    else
      -- MasterMerchant:dm("Debug", "the viewMode was dirty")
    end
    if view == ITEMS then
      MasterMerchant.scrollList:RefreshFilters()
    elseif view == GUILDS then
      MasterMerchant.guildScrollList:RefreshFilters()
    elseif view == LISTINGS then
      MasterMerchant.listingsScrollList:RefreshFilters()
    elseif view == PURCHASES then
      MasterMerchant.purchasesScrollList:RefreshFilters()
    elseif view == REPORTS then
      MasterMerchant.reportsScrollList:RefreshFilters()
    end
  else
    -- MasterMerchant:dm("Debug", "viewMode was not dirty")
  end
end

function MasterMerchant:SwitchToMasterMerchantSalesView()
  -- MasterMerchant:dm("Debug", "SwitchToMasterMerchantSalesView")
  if MasterMerchant.systemSavedVariables.viewSize == ITEMS then return end
  local theFragment = MasterMerchant:ActiveFragment()
  MasterMerchant:ActiveWindow():SetHidden(true)
  MasterMerchant.systemSavedVariables.viewSize = ITEMS
  if MasterMerchant.systemSavedVariables.openWithMail then
    MAIL_INBOX_SCENE:RemoveFragment(theFragment)
    MAIL_SEND_SCENE:RemoveFragment(theFragment)
    MAIL_INBOX_SCENE:AddFragment(self.salesUiFragment)
    MAIL_SEND_SCENE:AddFragment(self.salesUiFragment)
  end

  if MasterMerchant.systemSavedVariables.openWithStore then
    TRADING_HOUSE_SCENE:RemoveFragment(theFragment)
    TRADING_HOUSE_SCENE:AddFragment(self.salesUiFragment)
  end

  MasterMerchantGuildWindow:SetHidden(true)
  MasterMerchantListingWindow:SetHidden(true)
  MasterMerchantPurchaseWindow:SetHidden(true)
  MasterMerchantReportsWindow:SetHidden(true)
  MasterMerchantFilterByNameWindow:SetHidden(true)
  MasterMerchantFilterByTypeWindow:SetHidden(true)

  MasterMerchant:CheckFilterTimerangeState()
  MasterMerchant:ActiveWindow():SetHidden(false)
end

function MasterMerchant:SwitchToMasterMerchantPurchaseView()
  -- MasterMerchant:dm("Debug", "SwitchToMasterMerchantPurchaseView")
  if MasterMerchant.systemSavedVariables.viewSize == PURCHASES then return end
  local theFragment = MasterMerchant:ActiveFragment()
  MasterMerchant:ActiveWindow():SetHidden(true)
  MasterMerchant.systemSavedVariables.viewSize = PURCHASES
  if MasterMerchant.systemSavedVariables.openWithMail then
    MAIL_INBOX_SCENE:RemoveFragment(theFragment)
    MAIL_SEND_SCENE:RemoveFragment(theFragment)
    MAIL_INBOX_SCENE:AddFragment(self.purchaseUiFragment)
    MAIL_SEND_SCENE:AddFragment(self.purchaseUiFragment)
  end

  if MasterMerchant.systemSavedVariables.openWithStore then
    TRADING_HOUSE_SCENE:RemoveFragment(theFragment)
    TRADING_HOUSE_SCENE:AddFragment(self.purchaseUiFragment)
  end

  MasterMerchantWindow:SetHidden(true)
  MasterMerchantGuildWindow:SetHidden(true)
  MasterMerchantListingWindow:SetHidden(true)
  MasterMerchantReportsWindow:SetHidden(true)
  MasterMerchantFilterByNameWindow:SetHidden(true)
  MasterMerchantFilterByTypeWindow:SetHidden(true)

  MasterMerchant:ActiveWindow():SetHidden(false)
end

function MasterMerchant:SwitchToMasterMerchantListingsView()
  -- MasterMerchant:dm("Debug", "SwitchToMasterMerchantListingsView")
  local listingsView = MasterMerchant.systemSavedVariables.viewSize == LISTINGS
  local isHidden = MasterMerchantListingWindow:IsHidden()
  if listingsView and not isHidden then return end
  local theFragment = MasterMerchant:ActiveFragment()
  MasterMerchant:ActiveWindow():SetHidden(true)
  MasterMerchant.systemSavedVariables.viewSize = LISTINGS
  if MasterMerchant.systemSavedVariables.openWithMail then
    MAIL_INBOX_SCENE:RemoveFragment(theFragment)
    MAIL_SEND_SCENE:RemoveFragment(theFragment)
    MAIL_INBOX_SCENE:AddFragment(self.listingUiFragment)
    MAIL_SEND_SCENE:AddFragment(self.listingUiFragment)
  end

  if MasterMerchant.systemSavedVariables.openWithStore then
    TRADING_HOUSE_SCENE:RemoveFragment(theFragment)
    TRADING_HOUSE_SCENE:AddFragment(self.listingUiFragment)
  end

  MasterMerchantWindow:SetHidden(true)
  MasterMerchantGuildWindow:SetHidden(true)
  MasterMerchantPurchaseWindow:SetHidden(true)
  MasterMerchantReportsWindow:SetHidden(true)
  MasterMerchantFilterByNameWindow:SetHidden(true)
  MasterMerchantFilterByTypeWindow:SetHidden(true)

  MasterMerchant:ActiveWindow():SetHidden(false)
end

function MasterMerchant:SwitchToMasterMerchantReportsView()
  -- MasterMerchant:dm("Debug", "SwitchToMasterMerchantListingsView")
  if MasterMerchant.systemSavedVariables.viewSize == REPORTS then return end
  local theFragment = MasterMerchant:ActiveFragment()
  MasterMerchant:ActiveWindow():SetHidden(true)
  MasterMerchant.systemSavedVariables.viewSize = REPORTS
  if MasterMerchant.systemSavedVariables.openWithMail then
    MAIL_INBOX_SCENE:RemoveFragment(theFragment)
    MAIL_SEND_SCENE:RemoveFragment(theFragment)
    MAIL_INBOX_SCENE:AddFragment(self.reportsUiFragment)
    MAIL_SEND_SCENE:AddFragment(self.reportsUiFragment)
  end

  if MasterMerchant.systemSavedVariables.openWithStore then
    TRADING_HOUSE_SCENE:RemoveFragment(theFragment)
    TRADING_HOUSE_SCENE:AddFragment(self.reportsUiFragment)
  end

  MasterMerchantWindow:SetHidden(true)
  MasterMerchantGuildWindow:SetHidden(true)
  MasterMerchantPurchaseWindow:SetHidden(true)
  MasterMerchantListingWindow:SetHidden(true)
  MasterMerchantFilterByNameWindow:SetHidden(true)
  MasterMerchantFilterByTypeWindow:SetHidden(true)

  MasterMerchant:ActiveWindow():SetHidden(false)
end

-- Set the visibility status of the feebback window to the opposite of its current status
function MasterMerchant:ToggleMasterMerchantFeedback()
  MasterMerchantFeedback:SetDrawLayer(DL_OVERLAY)
  MasterMerchantFeedback:SetHidden(not MasterMerchantFeedback:IsHidden())
end

-- Set the visibility status of the stats window to the opposite of its current status
function MasterMerchant:ToggleMasterMerchantStatsWindow()
  if MasterMerchantStatsWindow:IsHidden() then MasterMerchant:UpdateStatsWindow('SK_STATS_TOTAL') end
  MasterMerchantStatsWindow:SetHidden(not MasterMerchantStatsWindow:IsHidden())
end

function MasterMerchant:ToggleMasterMerchantNameFilterWindow()
  MasterMerchantFilterByTypeWindow:SetHidden(true)
  MasterMerchantFilterByNameWindow:SetHidden(not MasterMerchantFilterByNameWindow:IsHidden())
end

-- Set the visibility status of the stats window to the opposite of its current status
function MasterMerchant:ToggleMasterMerchantTypeFilterWindow()
  MasterMerchantFilterByNameWindow:SetHidden(true)
  MasterMerchantFilterByTypeWindow:SetHidden(not MasterMerchantFilterByTypeWindow:IsHidden())
end

-- Set the visibility status of the filter windows
function MasterMerchant:ToggleMasterMerchantFilterWindows()
  MasterMerchantFilterByNameWindow:SetHidden(true)
  MasterMerchantFilterByTypeWindow:SetHidden(true)
end

-- Set the visibility status of the stats window to the opposite of its current status
function MasterMerchant:ToggleMasterMerchantPricingHistoryGraph()
  MasterMerchant.systemSavedVariables.showGraph = not MasterMerchant.systemSavedVariables.showGraph
end

function MasterMerchant:CheckFilterTimerangeState()
  if self.salesViewMode == MasterMerchant.personalSalesViewMode then
    MasterMerchantGuildWindowFilterTimerangeChooser:SetHidden(true)
  end
  if self.salesViewMode == MasterMerchant.guildSalesViewMode then
    MasterMerchantGuildWindowFilterTimerangeChooser:SetHidden(false)
  end
end

-- Switch between all sales and your sales
function MasterMerchant:SwitchSalesViewMode()
  -- MasterMerchant:dm("Debug", "SwitchSalesViewMode")
  -- /script MasterMerchant:dm("Debug", MasterMerchant.systemSavedVariables.viewSize)
  -- /script MasterMerchant:dm("Debug", MasterMerchant.salesViewMode)
  -- default is self
  --[[ MasterMerchant.salesViewMode
  when viewMode is 'self': (MasterMerchant.personalSalesViewMode) then you are viewing personal sales
  when viewMode if 'all'/'guild': (MasterMerchant.guildSalesViewMode) you are viewing guild sales
  ]]--

  if self.salesViewMode == MasterMerchant.personalSalesViewMode then
    -- switching to All Guild Sales
    MasterMerchantWindowMenuFooterSwitchViewButton:SetText(GetString(SK_VIEW_YOUR_SALES))
    MasterMerchantWindowMenuHeaderTitle:SetText(GetString(SK_GUILD_SALES_TITLE) .. ' - ' .. GetString(SK_ITEM_REPORT_TITLE))
    MasterMerchantGuildWindowMenuFooterSwitchViewButton:SetText(GetString(SK_VIEW_YOUR_SALES))
    MasterMerchantGuildWindowMenuHeaderTitle:SetText(GetString(SK_GUILD_SALES_TITLE) .. ' - ' .. GetString(SK_SELER_REPORT_TITLE))
    self.salesViewMode = MasterMerchant.guildSalesViewMode
    MasterMerchant:CheckFilterTimerangeState()
  else
    MasterMerchantWindowMenuFooterSwitchViewButton:SetText(GetString(SK_VIEW_ALL_SALES))
    MasterMerchantWindowMenuHeaderTitle:SetText(GetString(SK_SELF_SALES_TITLE) .. ' - ' .. GetString(SK_ITEM_REPORT_TITLE))
    MasterMerchantGuildWindowMenuFooterSwitchViewButton:SetText(GetString(SK_VIEW_ALL_SALES))
    MasterMerchantGuildWindowMenuHeaderTitle:SetText(GetString(SK_SELF_SALES_TITLE) .. ' - ' .. GetString(SK_SELER_REPORT_TITLE))
    self.salesViewMode = MasterMerchant.personalSalesViewMode
    MasterMerchant:CheckFilterTimerangeState()
  end

  --[[ TODO Verify this
  when viewsize is 'half': then you are viewing the seller information
  when viewsize if 'full': you are viewing the item information

  5-21: viewsize was 'half' viewing personal sales regardless whether
  or not I was looking at the times sold from an Item Report
  or personal sales but a Sellers Report

  viewMode was self for item report and self for sellers report

  Either that or tbug didn't update
  ]]--
  if MasterMerchant.systemSavedVariables.viewSize == ITEMS then
    MasterMerchant:RefreshAlteredWindowData(true)
    ZO_Scroll_ResetToTop(self.scrollList.list)
  elseif MasterMerchant.systemSavedVariables.viewSize == GUILDS then
    MasterMerchant:RefreshAlteredWindowData(true)
    ZO_Scroll_ResetToTop(self.guildScrollList.list)
  elseif MasterMerchant.systemSavedVariables.viewSize == LISTINGS then
    MasterMerchant:RefreshAlteredWindowData(true)
    ZO_Scroll_ResetToTop(self.listingsScrollList.list)
  elseif MasterMerchant.systemSavedVariables.viewSize == PURCHASES then
    MasterMerchant:RefreshAlteredWindowData(true)
    ZO_Scroll_ResetToTop(self.purchasesScrollList.list)
  else
    MasterMerchant:dm("Warn", "Shit Hit the fan SwitchSalesViewMode")
    MasterMerchant:dm("Warn", MasterMerchant.systemSavedVariables.viewSize)
  end
end

-- Switch between all sales and your sales
function MasterMerchant:SwitchReportsViewMode()
  -- MasterMerchant:dm("Debug", "SwitchReportsViewMode")
  -- /script MasterMerchant:dm("Debug", MasterMerchant.systemSavedVariables.viewSize)
  -- /script MasterMerchant:dm("Debug", MasterMerchant.salesViewMode)

  if self.reportsViewMode == MasterMerchant.reportsPostedViewMode then
    -- switching to All Guild Sales
    MasterMerchantReportsWindowMenuFooterSwitchReportsViewButton:SetText(GetString(GS_VIEW_POSTED_ITEMS))
    MasterMerchantReportsWindowMenuHeaderTitle:SetText(GetString(GS_CANCELED_ITEMS_TITLE) .. ' - ' .. GetString(SK_ITEM_REPORT_TITLE))
    self.reportsViewMode = MasterMerchant.reportsCanceledViewMode
  else
    -- reportsCanceledViewMode
    MasterMerchantReportsWindowMenuFooterSwitchReportsViewButton:SetText(GetString(GS_VIEW_CANCELED_ITEMS))
    MasterMerchantReportsWindowMenuHeaderTitle:SetText(GetString(GS_POSTED_ITEMS_TITLE) .. ' - ' .. GetString(SK_ITEM_REPORT_TITLE))
    self.reportsViewMode = MasterMerchant.reportsPostedViewMode
  end

  --[[ TODO Verify this
  when viewsize is 'half': then you are viewing the seller information
  when viewsize if 'full': you are viewing the item information

  5-21: viewsize was 'half' viewing personal sales regardless whether
  or not I was looking at the times sold from an Item Report
  or personal sales but a Sellers Report

  viewMode was self for item report and self for sellers report

  Either that or tbug didn't update
  ]]--
  if MasterMerchant.systemSavedVariables.viewSize == ITEMS then
    MasterMerchant:RefreshAlteredWindowData(true)
    ZO_Scroll_ResetToTop(self.scrollList.list)
  elseif MasterMerchant.systemSavedVariables.viewSize == GUILDS then
    MasterMerchant:RefreshAlteredWindowData(true)
    ZO_Scroll_ResetToTop(self.guildScrollList.list)
  elseif MasterMerchant.systemSavedVariables.viewSize == LISTINGS then
    MasterMerchant:RefreshAlteredWindowData(true)
    ZO_Scroll_ResetToTop(self.listingsScrollList.list)
  elseif MasterMerchant.systemSavedVariables.viewSize == PURCHASES then
    MasterMerchant:RefreshAlteredWindowData(true)
    ZO_Scroll_ResetToTop(self.purchasesScrollList.list)
  elseif MasterMerchant.systemSavedVariables.viewSize == REPORTS then
    MasterMerchant:RefreshAlteredWindowData(true)
    ZO_Scroll_ResetToTop(self.reportsScrollList.list)
  else
    MasterMerchant:dm("Warn", "Shit Hit the fan SwitchReportsViewMode")
    MasterMerchant:dm("Warn", MasterMerchant.systemSavedVariables.viewSize)
  end
end

-- Switch between full price mode and price after store cut
function MasterMerchant:SwitchFullPriceMode()
  MasterMerchant:dm("Debug", "SwitchFullPriceMode")
  if MasterMerchant.systemSavedVariables.showFullPrice then
    MasterMerchant.systemSavedVariables.showFullPrice = false
    MasterMerchantWindowMenuFooterFullPriceSwitchButton:SetText(GetString(SK_FULL_PRICE_BUTTON))
    --[[
    MasterMerchantPurchaseWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_UNIT))
    MasterMerchantListingWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_UNIT))
    MasterMerchantReportsWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_UNIT))
    ]]--
  else
    MasterMerchant.systemSavedVariables.showFullPrice = true
    MasterMerchantWindowMenuFooterFullPriceSwitchButton:SetText(GetString(SK_YOUR_PROFIT_BUTTON))
    --[[
    MasterMerchantPurchaseWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_TOTAL))
    MasterMerchantListingWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_TOTAL))
    MasterMerchantReportsWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_TOTAL))
    ]]--
  end

  if MasterMerchant.systemSavedVariables.viewSize == ITEMS then
    MasterMerchant:RefreshAlteredWindowData(true)
  elseif MasterMerchant.systemSavedVariables.viewSize == GUILDS then
    MasterMerchant:RefreshAlteredWindowData(true)
  elseif MasterMerchant.systemSavedVariables.viewSize == LISTINGS then
    MasterMerchant:RefreshAlteredWindowData(true)
  elseif MasterMerchant.systemSavedVariables.viewSize == PURCHASES then
    MasterMerchant:RefreshAlteredWindowData(true)
  elseif MasterMerchant.systemSavedVariables.viewSize == REPORTS then
    MasterMerchant:RefreshAlteredWindowData(true)
  else
    MasterMerchant:dm("Debug", "Shit Hit The Fan SwitchFullPriceMode")
  end
end

-- Switch between total price mode and unit price mode
function MasterMerchant:SwitchPriceMode()
  MasterMerchant:dm("Debug", "SwitchPriceMode")
  if MasterMerchant.systemSavedVariables.showUnitPrice then
    MasterMerchant.systemSavedVariables.showUnitPrice = false
    MasterMerchantWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_UNIT))
    MasterMerchantPurchaseWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_UNIT))
    MasterMerchantListingWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_UNIT))
    MasterMerchantReportsWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_UNIT))
    MasterMerchantWindowHeadersPrice:GetNamedChild('Name'):SetText(GetString(SK_PRICE_COLUMN))
    MasterMerchantPurchaseWindowHeadersPrice:GetNamedChild('Name'):SetText(GetString(SK_PRICE_COLUMN))
    MasterMerchantListingWindowHeadersPrice:GetNamedChild('Name'):SetText(GetString(SK_PRICE_COLUMN))
    MasterMerchantReportsWindowHeadersPrice:GetNamedChild('Name'):SetText(GetString(SK_PRICE_COLUMN))
  else
    MasterMerchant.systemSavedVariables.showUnitPrice = true
    MasterMerchantWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_TOTAL))
    MasterMerchantPurchaseWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_TOTAL))
    MasterMerchantListingWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_TOTAL))
    MasterMerchantReportsWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_TOTAL))
    MasterMerchantWindowHeadersPrice:GetNamedChild('Name'):SetText(GetString(SK_PRICE_EACH_COLUMN))
    MasterMerchantPurchaseWindowHeadersPrice:GetNamedChild('Name'):SetText(GetString(SK_PRICE_EACH_COLUMN))
    MasterMerchantListingWindowHeadersPrice:GetNamedChild('Name'):SetText(GetString(SK_PRICE_EACH_COLUMN))
    MasterMerchantReportsWindowHeadersPrice:GetNamedChild('Name'):SetText(GetString(SK_PRICE_EACH_COLUMN))
  end

  if MasterMerchant.systemSavedVariables.viewSize == ITEMS then
    MasterMerchant:RefreshAlteredWindowData(true)
  elseif MasterMerchant.systemSavedVariables.viewSize == GUILDS then
    MasterMerchant:RefreshAlteredWindowData(true)
  elseif MasterMerchant.systemSavedVariables.viewSize == LISTINGS then
    MasterMerchant:RefreshAlteredWindowData(true)
  elseif MasterMerchant.systemSavedVariables.viewSize == PURCHASES then
    MasterMerchant:RefreshAlteredWindowData(true)
  elseif MasterMerchant.systemSavedVariables.viewSize == REPORTS then
    MasterMerchant:RefreshAlteredWindowData(true)
  else
    MasterMerchant:dm("Debug", "Shit Hit The Fan SwitchPriceMode")
  end
end

-- Update the stats window if the slider in it moved
function MasterMerchant.OnStatsSliderMoved(self, sliderLevel, eventReason)
  local guildDropdown = ZO_ComboBox_ObjectFromContainer(MasterMerchantStatsGuildChooser)
  local selectedGuild = guildDropdown:GetSelectedItem()
  if selectedGuild == GetString(SK_STATS_ALL_GUILDS) then selectedGuild = 'SK_STATS_TOTAL' end
  MasterMerchant:UpdateStatsWindow(selectedGuild)
end

function MasterMerchant:BuildFilterTimerangeDropdown()
  local timeDropdown = ZO_ComboBox_ObjectFromContainer(MasterMerchantGuildWindowFilterTimerangeChooser)
  timeDropdown:ClearItems()
  local timeEntry

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_WINDOW_TIME_RANGE_LABEL_DEFAULT), function() self:UpdateGuildWindowTimerange(MM_WINDOW_TIME_RANGE_DEFAULT) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.windowTimeRange == MM_WINDOW_TIME_RANGE_DEFAULT then timeDropdown:SetSelectedItem(GetString(MM_WINDOW_TIME_RANGE_LABEL_DEFAULT)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_WINDOW_TIME_RANGE_LABEL_THIRTY), function() self:UpdateGuildWindowTimerange(MM_WINDOW_TIME_RANGE_THIRTY) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.windowTimeRange == MM_WINDOW_TIME_RANGE_THIRTY then timeDropdown:SetSelectedItem(GetString(MM_WINDOW_TIME_RANGE_LABEL_THIRTY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_WINDOW_TIME_RANGE_LABEL_SIXTY), function() self:UpdateGuildWindowTimerange(MM_WINDOW_TIME_RANGE_SIXTY) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.windowTimeRange == MM_WINDOW_TIME_RANGE_SIXTY then timeDropdown:SetSelectedItem(GetString(MM_WINDOW_TIME_RANGE_LABEL_SIXTY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_WINDOW_TIME_RANGE_LABEL_NINETY), function() self:UpdateGuildWindowTimerange(MM_WINDOW_TIME_RANGE_NINETY) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.windowTimeRange == MM_WINDOW_TIME_RANGE_NINETY then timeDropdown:SetSelectedItem(GetString(MM_WINDOW_TIME_RANGE_LABEL_NINETY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_WINDOW_TIME_RANGE_LABEL_CUSTOM), function() self:UpdateGuildWindowTimerange(MM_WINDOW_TIME_RANGE_CUSTOM) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.windowTimeRange == MM_WINDOW_TIME_RANGE_CUSTOM then timeDropdown:SetSelectedItem(GetString(MM_WINDOW_TIME_RANGE_LABEL_CUSTOM)) end
end

function MasterMerchant:BuildGuiTimeDropdown()
  local timeDropdown = ZO_ComboBox_ObjectFromContainer(MasterMerchantGuildWindowTimeframeChooser)
  timeDropdown:ClearItems()

  local timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_TODAY), function() self:UpdateGuildWindow(MM_DATERANGE_TODAY) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndex == MM_DATERANGE_TODAY then timeDropdown:SetSelectedItem(GetString(MM_INDEX_TODAY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_YESTERDAY), function() self:UpdateGuildWindow(MM_DATERANGE_YESTERDAY) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndex == MM_DATERANGE_YESTERDAY then timeDropdown:SetSelectedItem(GetString(MM_INDEX_YESTERDAY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_THISWEEK), function() self:UpdateGuildWindow(MM_DATERANGE_THISWEEK) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndex == MM_DATERANGE_THISWEEK then timeDropdown:SetSelectedItem(GetString(MM_INDEX_THISWEEK)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_LASTWEEK), function() self:UpdateGuildWindow(MM_DATERANGE_LASTWEEK) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndex == MM_DATERANGE_LASTWEEK then timeDropdown:SetSelectedItem(GetString(MM_INDEX_LASTWEEK)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_PRIORWEEK), function() self:UpdateGuildWindow(MM_DATERANGE_PRIORWEEK) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndex == MM_DATERANGE_PRIORWEEK then timeDropdown:SetSelectedItem(GetString(MM_INDEX_PRIORWEEK)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_7DAY), function() self:UpdateGuildWindow(MM_DATERANGE_7DAY) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndex == MM_DATERANGE_7DAY then timeDropdown:SetSelectedItem(GetString(MM_INDEX_7DAY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_10DAY), function() self:UpdateGuildWindow(MM_DATERANGE_10DAY) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndex == MM_DATERANGE_10DAY then timeDropdown:SetSelectedItem(GetString(MM_INDEX_10DAY)) end

  timeEntry = timeDropdown:CreateItemEntry(GetString(MM_INDEX_30DAY), function() self:UpdateGuildWindow(MM_DATERANGE_30DAY) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndex == MM_DATERANGE_30DAY then timeDropdown:SetSelectedItem(GetString(MM_INDEX_30DAY)) end

  timeEntry = timeDropdown:CreateItemEntry(MasterMerchant.customTimeframeText, function() self:UpdateGuildWindow(MM_DATERANGE_CUSTOM) end)
  timeDropdown:AddItem(timeEntry)
  if MasterMerchant.systemSavedVariables.rankIndex == MM_DATERANGE_CUSTOM then timeDropdown:SetSelectedItem(MasterMerchant.customTimeframeText) end
end

-- Set up the labels and tooltips from translation files and do a couple other UI
-- setup routines
function MasterMerchant:SetupMasterMerchantWindow()
  MasterMerchant:dm("Debug", "SetupMasterMerchantWindow")
  -- MasterMerchant button in guild store screen
  local reopenMasterMerchant = CreateControlFromVirtual('MasterMerchantReopenButton', ZO_TradingHouseBrowseItemsLeftPane, 'ZO_DefaultButton')
  reopenMasterMerchant:SetAnchor(TOP, ZO_TradingHouseBrowseItemsLeftPane, BOTTOM, 0, 10)
  reopenMasterMerchant:SetWidth(200)
  reopenMasterMerchant:SetText(GetString(MM_APP_NAME))
  reopenMasterMerchant:SetHandler('OnClicked', self.ToggleMasterMerchantWindow)

  local skCalc = CreateControlFromVirtual('MasterMerchantPriceCalculator', ZO_TradingHousePostItemPane, 'MasterMerchantPriceCalc')
  skCalc:SetAnchor(BOTTOM, reopenMasterMerchant, TOP, 0, -4)

  -- MasterMerchant button in mail screen
  local MasterMerchantMail = CreateControlFromVirtual('MasterMerchantMailButton', ZO_MailInbox, 'ZO_DefaultButton')
  MasterMerchantMail:SetAnchor(TOPLEFT, ZO_MailInbox, TOPLEFT, 100, 4)
  MasterMerchantMail:SetWidth(200)
  MasterMerchantMail:SetText(GetString(MM_APP_NAME))
  MasterMerchantMail:SetHandler('OnClicked', self.ToggleMasterMerchantWindow)

  -- Stats dropdown choice box
  local MasterMerchantStatsGuild = CreateControlFromVirtual('MasterMerchantStatsGuildChooser', MasterMerchantStatsWindow, 'MasterMerchantStatsGuildDropdown')
  MasterMerchantStatsGuild:SetDimensions(270, 25)
  MasterMerchantStatsGuild:SetAnchor(LEFT, MasterMerchantStatsWindowGuildChooserLabel, RIGHT, 5, 0)
  MasterMerchantStatsGuild.m_comboBox:SetSortsItems(false)

  -- Guild Time dropdown choice box
  local MasterMerchantGuildTimeframe = CreateControlFromVirtual('MasterMerchantGuildWindowTimeframeChooser', MasterMerchantGuildWindow, 'MasterMerchantStatsGuildDropdown')
  MasterMerchantGuildTimeframe:SetDimensions(180, 25)
  MasterMerchantGuildTimeframe:SetAnchor(LEFT, MasterMerchantGuildWindowMenuFooterSwitchViewButton, RIGHT, 5, 0)
  MasterMerchantGuildTimeframe.m_comboBox:SetSortsItems(false)

  -- Guild Window Filter Timeframe dropdown choice box
  local MasterMerchantGuildFilterTimeframe = CreateControlFromVirtual('MasterMerchantGuildWindowFilterTimerangeChooser', MasterMerchantWindow, 'MasterMerchantStatsGuildDropdown')
  MasterMerchantGuildFilterTimeframe:SetDimensions(180, 25)
  MasterMerchantGuildFilterTimeframe:SetAnchor(LEFT, MasterMerchantGuildWindowMenuFooterLoadingIcon, RIGHT, 5, 0)
  MasterMerchantGuildFilterTimeframe.m_comboBox:SetSortsItems(false)

  MasterMerchant.systemSavedVariables.rankIndex = MasterMerchant.systemSavedVariables.rankIndex or MM_DATERANGE_TODAY

  MasterMerchant:BuildGuiTimeDropdown()
  MasterMerchant:BuildFilterTimerangeDropdown()

  -- Set sort column headers and search label from translation
  local fontString = 'ZoFontGameLargeBold'
  local guildFontString = 'ZoFontGameLargeBold'
  local font = LMP:Fetch('font', MasterMerchant.systemSavedVariables.windowFont)
  fontString = font .. '|17'
  guildFontString = font .. '|17'

  --[[TODO Setup New Filter windows
  ]]--
  MasterMerchantFilterByTypeWindowMenuHeaderTitle:SetText(GetString(MM_FILTERBY_TYPE_TITLE))
  MasterMerchantFilterByNameWindowMenuHeaderTitle:SetText(GetString(MM_FILTERBY_LINK_TITLE))
  MasterMerchantFilterByNameWindowHeadersItemName:GetNamedChild('Name'):SetText(GetString(MM_ITEMNAME_TEXT))
  MasterMerchantFilterByNameWindowMenuFooterClearFilterButton:SetText(GetString(MM_CLEAR_FILTER_BUTTON))

  if MasterMerchant.systemSavedVariables.viewBuyerSeller == 'buyer' then
    MasterMerchantWindowHeadersBuyer:GetNamedChild('Name'):SetText(GetString(SK_BUYER_COLUMN))
  else
    MasterMerchantWindowHeadersBuyer:GetNamedChild('Name'):SetText(GetString(SK_SELLER_COLUMN))
  end

  if MasterMerchant.systemSavedVariables.viewGuildBuyerSeller == 'buyer' then
    MasterMerchantGuildWindowHeadersSeller:GetNamedChild('Name'):SetText(GetString(SK_BUYER_COLUMN))
  elseif MasterMerchant.systemSavedVariables.viewGuildBuyerSeller == 'seller' then
    MasterMerchantGuildWindowHeadersSeller:GetNamedChild('Name'):SetText(GetString(SK_SELLER_COLUMN))
  else
    -- this makes it such that the first column is the items link
    MasterMerchantGuildWindowHeadersSeller:GetNamedChild('Name'):SetText(GetString(SK_ITEM_COLUMN))
  end

  -- listings Seller: first column
  MasterMerchantListingWindowHeadersSeller:GetNamedChild('Name'):SetText(GetString(SK_SELLER_COLUMN))
  ZO_SortHeader_Initialize(MasterMerchantListingWindowHeadersSeller, GetString(SK_SELLER_COLUMN), 'name',
    ZO_SORT_ORDER_DOWN, TEXT_ALIGN_LEFT, fontString)
  -- listings Location: first column
  MasterMerchantListingWindowHeadersLocation:GetNamedChild('Name'):SetText(GetString(SK_LOCATION_COLUMN))
  -- listings Guild: second column
  MasterMerchantListingWindowHeadersGuild:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ZO_SortHeader_Initialize(MasterMerchantListingWindowHeadersGuild, GetString(SK_GUILD_COLUMN), 'itemGuildName',
    ZO_SORT_ORDER_DOWN, TEXT_ALIGN_LEFT, fontString)
  -- listings ItemName: third column
  MasterMerchantListingWindowHeadersItemName:GetNamedChild('Name'):SetText(GetString(SK_ITEM_LISTING_COLUMN))
  -- listings SellTime: fourth column
  MasterMerchantListingWindowHeadersListingTime:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ZO_SortHeader_Initialize(MasterMerchantListingWindowHeadersListingTime, GetString(SK_TIME_LISTING_COLUMN), 'time', ZO_SORT_ORDER_UP, TEXT_ALIGN_LEFT, fontString)
  -- listings Price: fifth column
  MasterMerchantListingWindowHeadersPrice:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  MasterMerchantListingWindowHeadersPrice:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)
  if MasterMerchant.systemSavedVariables.showUnitPrice then
    ZO_SortHeader_Initialize(MasterMerchantListingWindowHeadersPrice, GetString(SK_PRICE_EACH_COLUMN), 'price',
      ZO_SORT_ORDER_DOWN, TEXT_ALIGN_LEFT, fontString)
  else
    ZO_SortHeader_Initialize(MasterMerchantListingWindowHeadersPrice, GetString(SK_PRICE_COLUMN), 'price', ZO_SORT_ORDER_DOWN, TEXT_ALIGN_LEFT, fontString)
  end
  -- Total / unit price switch button
  if MasterMerchant.systemSavedVariables.showUnitPrice then
    MasterMerchantListingWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_TOTAL))
  else
    MasterMerchantListingWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_UNIT))
  end

  -- Purchase Seller: first column
  MasterMerchantPurchaseWindowHeadersSeller:GetNamedChild('Name'):SetText(GetString(SK_SELLER_COLUMN))
  ZO_SortHeader_Initialize(MasterMerchantPurchaseWindowHeadersSeller, GetString(SK_SELLER_COLUMN), 'name',
    ZO_SORT_ORDER_DOWN, TEXT_ALIGN_LEFT, fontString)
  -- Purchase Guild: second column
  MasterMerchantPurchaseWindowHeadersGuild:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ZO_SortHeader_Initialize(MasterMerchantPurchaseWindowHeadersGuild, GetString(SK_GUILD_COLUMN), 'itemGuildName',
    ZO_SORT_ORDER_DOWN, TEXT_ALIGN_LEFT, fontString)
  -- Purchase ItemName: third column
  MasterMerchantPurchaseWindowHeadersItemName:GetNamedChild('Name'):SetText(GetString(SK_ITEM_PURCHASE_COLUMN))
  -- Purchase SellTime: fourth column
  MasterMerchantPurchaseWindowHeadersPurchaseTime:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ZO_SortHeader_Initialize(MasterMerchantPurchaseWindowHeadersPurchaseTime, GetString(SK_TIME_PURCHASE_COLUMN), 'time', ZO_SORT_ORDER_UP, TEXT_ALIGN_LEFT, fontString)
  -- Purchase Price: fifth column
  MasterMerchantPurchaseWindowHeadersPrice:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  MasterMerchantPurchaseWindowHeadersPrice:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)
  if MasterMerchant.systemSavedVariables.showUnitPrice then
    ZO_SortHeader_Initialize(MasterMerchantPurchaseWindowHeadersPrice, GetString(SK_PRICE_EACH_COLUMN), 'price',
      ZO_SORT_ORDER_DOWN, TEXT_ALIGN_LEFT, fontString)
  else
    ZO_SortHeader_Initialize(MasterMerchantPurchaseWindowHeadersPrice, GetString(SK_PRICE_COLUMN), 'price', ZO_SORT_ORDER_DOWN, TEXT_ALIGN_LEFT, fontString)
  end
  -- Purchase Total / unit price switch button
  if MasterMerchant.systemSavedVariables.showUnitPrice then
    MasterMerchantPurchaseWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_TOTAL))
  else
    MasterMerchantPurchaseWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_UNIT))
  end

  -- reports Seller: first column
  MasterMerchantReportsWindowHeadersSeller:GetNamedChild('Name'):SetText(GetString(SK_SELLER_COLUMN))
  ZO_SortHeader_Initialize(MasterMerchantReportsWindowHeadersSeller, GetString(SK_SELLER_COLUMN), 'name',
    ZO_SORT_ORDER_DOWN, TEXT_ALIGN_LEFT, fontString)
  -- reports Guild: second column
  MasterMerchantReportsWindowHeadersGuild:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ZO_SortHeader_Initialize(MasterMerchantReportsWindowHeadersGuild, GetString(SK_GUILD_COLUMN), 'itemGuildName', ZO_SORT_ORDER_DOWN, TEXT_ALIGN_LEFT, fontString)
  -- reports ItemName: third column
  MasterMerchantReportsWindowHeadersItemName:GetNamedChild('Name'):SetText(GetString(SK_ITEM_LISTING_COLUMN))
  -- reports SellTime: fourth column
  MasterMerchantReportsWindowHeadersSellTime:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ZO_SortHeader_Initialize(MasterMerchantReportsWindowHeadersSellTime, GetString(SK_TIME_LISTING_COLUMN), 'time', ZO_SORT_ORDER_UP, TEXT_ALIGN_LEFT, fontString)
  -- reports Price: fifth column
  MasterMerchantReportsWindowHeadersPrice:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  MasterMerchantReportsWindowHeadersPrice:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)
  if MasterMerchant.systemSavedVariables.showUnitPrice then
    ZO_SortHeader_Initialize(MasterMerchantReportsWindowHeadersPrice, GetString(SK_PRICE_EACH_COLUMN), 'price', ZO_SORT_ORDER_DOWN, TEXT_ALIGN_LEFT, fontString)
  else
    ZO_SortHeader_Initialize(MasterMerchantReportsWindowHeadersPrice, GetString(SK_PRICE_COLUMN), 'price', ZO_SORT_ORDER_DOWN, TEXT_ALIGN_LEFT, fontString)
  end
  -- reports ListingFee: sixth column
  MasterMerchantReportsWindowHeadersListingFee:GetNamedChild('Name'):SetText(GetString(SK_REPORTS_LISTING_FEE_COLUMN))
  -- Total / unit price switch button
  if MasterMerchant.systemSavedVariables.showUnitPrice then
    MasterMerchantReportsWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_TOTAL))
  else
    MasterMerchantReportsWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_UNIT))
  end

  MasterMerchantWindowHeadersGuild:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ZO_SortHeader_Initialize(MasterMerchantWindowHeadersGuild, GetString(SK_GUILD_COLUMN), 'itemGuildName',
    ZO_SORT_ORDER_DOWN, TEXT_ALIGN_LEFT, fontString)
  MasterMerchantWindowHeadersItemName:GetNamedChild('Name'):SetText(GetString(SK_ITEM_COLUMN))
  MasterMerchantWindowHeadersSellTime:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ZO_SortHeader_Initialize(MasterMerchantWindowHeadersSellTime, GetString(SK_TIME_COLUMN), 'time', ZO_SORT_ORDER_UP,
    TEXT_ALIGN_LEFT, fontString)
  MasterMerchantWindowHeadersPrice:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)

  MasterMerchantWindowHeadersPrice:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)
  if MasterMerchant.systemSavedVariables.showUnitPrice then
    ZO_SortHeader_Initialize(MasterMerchantWindowHeadersPrice, GetString(SK_PRICE_EACH_COLUMN), 'price',
      ZO_SORT_ORDER_DOWN, TEXT_ALIGN_LEFT, fontString)
  else
    ZO_SortHeader_Initialize(MasterMerchantWindowHeadersPrice, GetString(SK_PRICE_COLUMN), 'price', ZO_SORT_ORDER_DOWN,
      TEXT_ALIGN_LEFT, fontString)
  end

  MasterMerchantGuildWindowHeadersGuild:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ZO_SortHeader_Initialize(MasterMerchantGuildWindowHeadersGuild, GetString(SK_GUILD_COLUMN), 'guildName',
    ZO_SORT_ORDER_DOWN, TEXT_ALIGN_LEFT, fontString)

  MasterMerchantGuildWindowHeadersRank:GetNamedChild('Name'):SetText(GetString(SK_RANK_COLUMN))
  MasterMerchantGuildWindowHeadersRank:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ZO_SortHeader_Initialize(MasterMerchantGuildWindowHeadersRank, GetString(SK_RANK_COLUMN), 'rank', ZO_SORT_ORDER_DOWN,
    TEXT_ALIGN_RIGHT, guildFontString)

  MasterMerchantGuildWindowHeadersSales:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ZO_SortHeader_Initialize(MasterMerchantGuildWindowHeadersSales, GetString(SK_SALES_COLUMN), 'sales',
    ZO_SORT_ORDER_DOWN, TEXT_ALIGN_RIGHT, guildFontString)
  local ctrl = GetControl(MasterMerchantGuildWindowHeadersSales, "Name")

  if MasterMerchant.systemSavedVariables.viewGuildBuyerSeller == 'buyer' then
    ctrl:SetText(GetString(SK_PURCHASES_COLUMN))
  elseif MasterMerchant.systemSavedVariables.viewGuildBuyerSeller == 'seller' then
    ctrl:SetText(GetString(SK_SALES_COLUMN))
  else
    ctrl:SetText(GetString(SK_SALES_COLUMN))
  end

  MasterMerchantGuildWindowHeadersSales:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)

  local txt
  if MasterMerchant.systemSavedVariables.viewGuildBuyerSeller == 'buyer' then
    txt = GetString(SK_BUYER_COLUMN)
  elseif MasterMerchant.systemSavedVariables.viewGuildBuyerSeller == 'seller' then
    txt = GetString(SK_SELLER_COLUMN)
  else
    txt = GetString(SK_ITEM_COLUMN)
  end
  MasterMerchantGuildWindowHeadersSeller:GetNamedChild('Name'):SetText(GetString(txt))
  MasterMerchantGuildWindowHeadersSeller:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ZO_SortHeader_Initialize(MasterMerchantGuildWindowHeadersSeller, txt, 'name', ZO_SORT_ORDER_DOWN, TEXT_ALIGN_LEFT,
    guildFontString)

  MasterMerchantGuildWindowHeadersTax:GetNamedChild('Name'):SetText(GetString(SK_TAX_COLUMN))
  MasterMerchantGuildWindowHeadersTax:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ZO_SortHeader_Initialize(MasterMerchantGuildWindowHeadersTax, GetString(SK_TAX_COLUMN), 'tax', ZO_SORT_ORDER_DOWN,
    TEXT_ALIGN_RIGHT, guildFontString)

  MasterMerchantGuildWindowHeadersCount:GetNamedChild('Name'):SetText(GetString(SK_COUNT_COLUMN))
  MasterMerchantGuildWindowHeadersCount:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  ZO_SortHeader_Initialize(MasterMerchantGuildWindowHeadersCount, GetString(SK_COUNT_COLUMN), 'count',
    ZO_SORT_ORDER_DOWN, TEXT_ALIGN_RIGHT, guildFontString)

  MasterMerchantGuildWindowHeadersPercent:GetNamedChild('Name'):SetText(GetString(SK_PERCENT_COLUMN))
  MasterMerchantGuildWindowHeadersPercent:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)

  -- Set second half of window title from translation
  --[[TODO setup master merchant window title
  WindowTitle - Item Info
  GuildWindowTitle - Seller Info
  ]]--
  MasterMerchantWindowMenuHeaderTitle:SetText(GetString(SK_SELF_SALES_TITLE) .. ' - ' .. GetString(SK_ITEM_REPORT_TITLE))
  MasterMerchantGuildWindowMenuHeaderTitle:SetText(GetString(SK_SELF_SALES_TITLE) .. ' - ' .. GetString(SK_SELER_REPORT_TITLE))
  MasterMerchantListingWindowMenuHeaderTitle:SetText(GetString(MM_EXTENSION_BONANZA_NAME) .. ' - ' .. GetString(SK_LISTING_REPORT_TITLE))
  MasterMerchantPurchaseWindowMenuHeaderTitle:SetText(GetString(MM_EXTENSION_SHOPPINGLIST_NAME) .. ' - ' .. GetString(SK_PURCHASES_COLUMN))
  MasterMerchantReportsWindowMenuHeaderTitle:SetText(GetString(GS_POSTED_ITEMS_TITLE) .. ' - ' .. GetString(SK_ITEM_REPORT_TITLE))

  -- And set the stats window title and slider label from translation
  MasterMerchantStatsWindowTitle:SetText(GetString(MM_APP_NAME) .. ' - ' .. GetString(SK_STATS_TITLE))
  MasterMerchantStatsWindowGuildChooserLabel:SetText(GetString(SK_GUILD_COLUMN) .. ': ')
  MasterMerchantStatsWindowSliderLabel:SetText(GetString(SK_STATS_DAYS))

  -- Set up some helpful tooltips for the Time and Price column headers
  ZO_SortHeader_SetTooltip(MasterMerchantWindowHeadersSellTime, GetString(SK_SORT_TIME_TOOLTIP))
  ZO_SortHeader_SetTooltip(MasterMerchantWindowHeadersPrice, GetString(SK_SORT_PRICE_TOOLTIP))
  --ZO_SortHeader_SetTooltip(MasterMerchantGuildWindowHeadersSellTime, GetString(SK_SORT_TIME_TOOLTIP))
  --ZO_SortHeader_SetTooltip(MasterMerchantGuildWindowHeadersPrice, GetString(SK_SORT_PRICE_TOOLTIP))

  -- View switch button
  MasterMerchantWindowMenuFooterSwitchViewButton:SetText(GetString(SK_VIEW_ALL_SALES))
  MasterMerchantGuildWindowMenuFooterSwitchViewButton:SetText(GetString(SK_VIEW_ALL_SALES))
  MasterMerchantReportsWindowMenuFooterSwitchReportsViewButton:SetText(GetString(GS_VIEW_CANCELED_ITEMS))

  -- Total / unit price switch button
  if MasterMerchant.systemSavedVariables.showUnitPrice then
    MasterMerchantWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_TOTAL))
  else
    MasterMerchantWindowMenuFooterPriceSwitchButton:SetText(GetString(SK_SHOW_UNIT))
  end

  -- Full Price / Price after house cut switch button
  if MasterMerchant.systemSavedVariables.showFullPrice then
    MasterMerchantWindowMenuFooterFullPriceSwitchButton:SetText(GetString(SK_YOUR_PROFIT_BUTTON))
  else
    MasterMerchantWindowMenuFooterFullPriceSwitchButton:SetText(GetString(SK_FULL_PRICE_BUTTON))
  end

  -- Spinny animations that display while SK is scanning
  MasterMerchantWindowMenuFooterLoadingIcon.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual('LoadIconAnimation',
    MasterMerchantWindowMenuFooterLoadingIcon)
  MasterMerchantGuildWindowMenuFooterLoadingIcon.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual('LoadIconAnimation',
    MasterMerchantGuildWindowMenuFooterLoadingIcon)
  MasterMerchantListingWindowMenuFooterLoadingIcon.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual('LoadIconAnimation',
    MasterMerchantListingWindowMenuFooterLoadingIcon)
  MasterMerchantPurchaseWindowMenuFooterLoadingIcon.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual('LoadIconAnimation',
    MasterMerchantPurchaseWindowMenuFooterLoadingIcon)
  MasterMerchantReportsWindowMenuFooterLoadingIcon.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual('LoadIconAnimation',
    MasterMerchantReportsWindowMenuFooterLoadingIcon)

  --[[ TODO this may be used for something else
  -- Refresh button
  MasterMerchantRefreshButton:SetText(GetString(SK_REFRESH_LABEL))
  MasterMerchantGuildRefreshButton:SetText(GetString(SK_REFRESH_LABEL))

  -- Reset button and confirmation dialog
  MasterMerchantResetButton:SetText(GetString(SK_RESET_LABEL))
  MasterMerchantGuildResetButton:SetText(GetString(SK_RESET_LABEL))
  ]]--
  local resetSalesDialog = {
    title = { text = GetString(GS_RESET_CONFIRM_TITLE) },
    mainText = { text = GetString(GS_RESET_CONFIRM_MAIN) },
    buttons = {
      {
        text = SI_DIALOG_ACCEPT,
        callback = function() internal:ResetSalesData() end
      },
      { text = SI_DIALOG_CANCEL }
    }
  }
  ZO_Dialogs_RegisterCustomDialog('MasterMerchantResetConfirmation', resetSalesDialog)
  local resetListingsDialog = {
    title = { text = GetString(GS_RESET_LISTINGS_CONFIRM_TITLE) },
    mainText = { text = GetString(GS_RESET_LISTINGS_CONFIRM_MAIN) },
    buttons = {
      {
        text = SI_DIALOG_ACCEPT,
        callback = function() internal:ResetListingsData() end
      },
      { text = SI_DIALOG_CANCEL }
    }
  }
  ZO_Dialogs_RegisterCustomDialog('MasterMerchantResetListingsConfirmation', resetListingsDialog)
  local resetLibGuildStoreDialog = {
    title = { text = GetString(GS_RESET_LIBGUILDSTORE_CONFIRM_TITLE) },
    mainText = { text = GetString(GS_RESET_LIBGUILDSTORE_CONFIRM_MAIN) },
    buttons = {
      {
        text = SI_DIALOG_ACCEPT,
        callback = function() internal:resetAllLibGuildStoreData() end
      },
      { text = SI_DIALOG_CANCEL }
    }
  }
  ZO_Dialogs_RegisterCustomDialog('MasterMerchantResetLibGuildStoreConfirmation', resetLibGuildStoreDialog)

  -- Slider setup
  MasterMerchantStatsWindowSlider:SetValue(100)

  -- We're all set, so make sure we're using the right font to finish up
  --[[TODO Will register new fonts and then update font usage prior
  to Restoring the MM window position
  ]]--
  self:UpdateFonts()
end

function MasterMerchant:SetupScrollLists()
  MasterMerchant:dm("Debug", "SetupScrollLists")
  -- Scroll list init
  self.scrollList = MMScrollList:New(MasterMerchantWindow)
  --self.scrollList:Initialize()
  ZO_PostHook(self.scrollList.sortHeaderGroup, 'OnHeaderClicked', function(self, header, suppressCallbacks)
    if header == MasterMerchantWindowHeadersPrice then
      if header.mouseIsOver then MasterMerchantWindowHeadersPrice:GetNamedChild('Name'):SetColor(0.95, 0.92, 0.26, 1)
      else MasterMerchantWindowHeadersPrice:GetNamedChild('Name'):SetColor(0.84, 0.81, 0.15, 1) end
    else MasterMerchantWindowHeadersPrice:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1) end
  end)
  ZO_PostHookHandler(MasterMerchantWindowHeadersPrice, 'OnMouseExit', function()
    if MasterMerchantWindowHeadersPrice.selected then MasterMerchantWindowHeadersPrice:GetNamedChild('Name'):SetColor(0.84,
      0.81, 0.15, 1)
    else MasterMerchantWindowHeadersPrice:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1) end
  end)
  ZO_PostHookHandler(MasterMerchantWindowHeadersPrice, 'OnMouseEnter', function(control)
    if control == MasterMerchantWindowHeadersPrice then MasterMerchantWindowHeadersPrice:GetNamedChild('Name'):SetColor(0.84,
      0.81, 0.15, 1)
    else MasterMerchantWindowHeadersPrice:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1) end
  end)

  self.guildScrollList = MMScrollList:New(MasterMerchantGuildWindow)
  --self.guildScrollList:Initialize()
  ZO_PostHook(self.guildScrollList.sortHeaderGroup, 'OnHeaderClicked', function()
    MasterMerchantGuildWindowHeadersSales:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)
  end)
  ZO_PostHookHandler(MasterMerchantGuildWindowHeadersSales, 'OnMouseExit', function()
    MasterMerchantGuildWindowHeadersSales:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)
  end)
  ZO_PostHookHandler(MasterMerchantGuildWindowHeadersSales, 'OnMouseEnter', function()
    MasterMerchantGuildWindowHeadersSales:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)
  end)

  self.listingsScrollList = MMScrollList:New(MasterMerchantListingWindow)
  --self.listingsScrollList:Initialize()
  ZO_PostHook(self.listingsScrollList.sortHeaderGroup, 'OnHeaderClicked', function()
    MasterMerchantListingWindowHeadersItemName:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)
  end)
  ZO_PostHookHandler(MasterMerchantListingWindowHeadersItemName, 'OnMouseExit', function()
    MasterMerchantListingWindowHeadersItemName:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)
  end)
  ZO_PostHookHandler(MasterMerchantListingWindowHeadersItemName, 'OnMouseEnter', function()
    MasterMerchantListingWindowHeadersItemName:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)
  end)

  self.purchasesScrollList = MMScrollList:New(MasterMerchantPurchaseWindow)
  --self.purchasesScrollList:Initialize()
  ZO_PostHook(self.purchasesScrollList.sortHeaderGroup, 'OnHeaderClicked', function()
    MasterMerchantPurchaseWindowHeadersItemName:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)
  end)
  ZO_PostHookHandler(MasterMerchantPurchaseWindowHeadersItemName, 'OnMouseExit', function()
    MasterMerchantPurchaseWindowHeadersItemName:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)
  end)
  ZO_PostHookHandler(MasterMerchantPurchaseWindowHeadersItemName, 'OnMouseEnter', function()
    MasterMerchantPurchaseWindowHeadersItemName:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)
  end)

  self.reportsScrollList = MMScrollList:New(MasterMerchantReportsWindow)
  --self.reportsScrollList:Initialize()
  ZO_PostHook(self.reportsScrollList.sortHeaderGroup, 'OnHeaderClicked', function()
    MasterMerchantReportsWindowHeadersItemName:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)
  end)
  ZO_PostHookHandler(MasterMerchantReportsWindowHeadersItemName, 'OnMouseExit', function()
    MasterMerchantReportsWindowHeadersItemName:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)
  end)
  ZO_PostHookHandler(MasterMerchantReportsWindowHeadersItemName, 'OnMouseEnter', function()
    MasterMerchantReportsWindowHeadersItemName:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)
  end)

  -- setup filter window
  self.nameFilterScrollList = IFScrollList:New(MasterMerchantFilterByNameWindow)
end

local function OnGuildMemberAdded(eventCode, guildId, displayName)
  if internal.guildMemberInfo[guildId] == nil then internal.guildMemberInfo[guildId] = {} end
  internal.guildMemberInfo[guildId][string.lower(displayName)] = true
end
EVENT_MANAGER:RegisterForEvent(MasterMerchant.name .. "_MemberAdded", EVENT_GUILD_MEMBER_ADDED, OnGuildMemberAdded)

local function OnGuildMemberRemoved(eventCode, guildId, displayName, characterName)
  if internal.guildMemberInfo[guildId] == nil then internal.guildMemberInfo[guildId] = {} end
  internal.guildMemberInfo[guildId][string.lower(displayName)] = nil
end
EVENT_MANAGER:RegisterForEvent(MasterMerchant.name .. "_MemberRemoved", EVENT_GUILD_MEMBER_REMOVED, OnGuildMemberRemoved)

-- LibGuildStore_Internal
local function OnPlayerJoinedGuild(eventCode, guildId, guildName)
  --MasterMerchant:dm("Debug", "OnPlayerJoinedGuild")
  internal:SetupGuildContainers()
  MasterMerchant.guildList = internal:GetGuildList()
  internal.LibHistoireListener[guildId] = { }
  LibGuildStore_SavedVariables["lastReceivedEventID"][internal.libHistoireNamespace][guildId] = "0"
  internal.eventsNeedProcessing[guildId] = true
  internal.timeEstimated[guildId] = false
  internal.currentGuilds[guildId] = guildName
  internal.alertQueue[guildName] = {}
  for m = 1, GetNumGuildMembers(guildId) do
    local name, _, _, _, _ = GetGuildMemberInfo(guildId, m)
    if internal.guildMemberInfo[guildId] == nil then internal.guildMemberInfo[guildId] = {} end
    internal.guildMemberInfo[guildId][string.lower(name)] = true
  end

  internal.LibHistoireListenerReady[guildId] = false
  internal:QueueGuildHistoryListener(guildId, nil)
end
EVENT_MANAGER:RegisterForEvent(MasterMerchant.name .. "_JoinedGuild", EVENT_GUILD_SELF_JOINED_GUILD, OnPlayerJoinedGuild)

local function OnPlayerLeaveGuild(eventCode, guildId, guildName)
  --MasterMerchant:dm("Debug", "OnPlayerLeaveGuild")
  if internal.LibHistoireListener[guildId] ~= nil and internal.LibHistoireListener[guildId].running then
    MasterMerchant:dm("Debug", "Stopping listener")
    internal.LibHistoireListener[guildId]:Stop()
  end
  MasterMerchant.guildList = internal:GetGuildList()
  LibGuildStore_SavedVariables["lastReceivedEventID"][internal.libHistoireNamespace][guildId] = nil
  internal.eventsNeedProcessing[guildId] = nil
  internal.timeEstimated[guildId] = nil
  internal.LibHistoireListener[guildId] = nil
  internal.currentGuilds[guildId] = nil
  internal.alertQueue[guildName] = nil
  internal.guildMemberInfo[guildId] = nil
end
EVENT_MANAGER:RegisterForEvent(MasterMerchant.name .. "_LeaveGuild", EVENT_GUILD_SELF_LEFT_GUILD, OnPlayerLeaveGuild)

function MasterMerchant:GetMeetsRequirements(itemLink)
  if (not WritWorthy) then return false end
  local hasKnowledge = true
  local hasMaterials = true
  local parser = WritWorthy.CreateParser(itemLink)
  if (not parser or not parser:ParseItemLink(itemLink) or not parser.ToKnowList) then
    return false
  end
  local knowList = parser:ToKnowList()
  if (knowList) then
    for _, know in ipairs(knowList) do
      if (not know.is_known) then
        hasKnowledge = false
      end
    end
  end

  local matList = parser:ToMatList()
  if (matList) then
    for _, mat in ipairs(matList) do
      if (WritWorthy.Util.MatHaveCt(mat.link) < mat.ct) then
        hasMaterials = false
      end
    end
  end

  return hasKnowledge, hasMaterials
end

function MasterMerchant:ToggleWritMarkerBrowseResults(rowControl, slot)
  local markerControl = rowControl:GetNamedChild(MasterMerchant.name .. "Writ")
  local rData = rowControl.dataEntry and rowControl.dataEntry.data or nil
  local itemLink = rData and rData.itemLink or nil
  local hasKnowledge, hasMaterials = MasterMerchant:GetMeetsRequirements(itemLink)

  if (not markerControl) then
    if not hasKnowledge then return end
    markerControl = WINDOW_MANAGER:CreateControl(rowControl:GetName() .. MasterMerchant.name .. "Writ", rowControl, CT_TEXTURE)
    markerControl:SetDimensions(22, 22)
    markerControl:SetInheritScale(false)
    markerControl:SetAnchor(LEFT, rowControl, LEFT)
    markerControl:SetDrawTier(DT_HIGH)
  end

  if hasKnowledge and hasMaterials then
    markerControl:SetTexture("mastermerchant/img/does_meet.dds")
    markerControl:SetColor(0.17, 0.93, 0.17, 1)
    markerControl:SetHidden(false)
  elseif hasKnowledge and not hasMaterials then
    markerControl:SetTexture("esoui/art/miscellaneous/help_icon.dds")
    markerControl:SetColor(1, 0.99, 0, 1)
    markerControl:SetHidden(false)
  else markerControl:SetHidden(true) end
end

function MasterMerchant:ToggleWritMarkerInventoryList(rowControl, slot)
  local markerControl = rowControl:GetNamedChild(MasterMerchant.name .. "Writ")
  local relativeToPoint = rowControl:GetNamedChild("Button")
  local bagId = rowControl.dataEntry.data.bagId
  local slotIndex = rowControl.dataEntry.data.slotIndex
  local itemLink = GetItemLink(bagId, slotIndex)
  local hasKnowledge, hasMaterials = MasterMerchant:GetMeetsRequirements(itemLink)

  if (not markerControl) then
    if not hasKnowledge then return end
    markerControl = WINDOW_MANAGER:CreateControl(rowControl:GetName() .. MasterMerchant.name .. "Writ", rowControl, CT_TEXTURE)
    markerControl:SetDimensions(22, 22)
    markerControl:SetInheritScale(false)
    markerControl:SetAnchor(LEFT, relativeToPoint, LEFT)
    markerControl:SetDrawTier(DT_HIGH)
  end

  if hasKnowledge and hasMaterials and MasterMerchant.tradingHouseOpened then
    markerControl:SetTexture("MasterMerchant/img/does_meet.dds")
    markerControl:SetColor(0.17, 0.93, 0.17, 1)
    markerControl:SetHidden(false)
  elseif hasKnowledge and not hasMaterials and MasterMerchant.tradingHouseOpened then
    markerControl:SetTexture("esoui/art/miscellaneous/help_icon.dds")
    markerControl:SetColor(1, 0.99, 0, 1)
    markerControl:SetHidden(false)
  else markerControl:SetHidden(true) end
end

function MasterMerchant:ToggleVendorMarker(rowControl, slot)
  local markerControl = rowControl:GetNamedChild(MasterMerchant.name .. "Warn")
  local relativeToPoint = rowControl:GetNamedChild("SellPrice")
  local showVendorWarning = false
  local vendorWarningPricing = nil
  local rData = rowControl.dataEntry and rowControl.dataEntry.data or nil
  local itemLink = rData and rData.itemLink or nil
  if not itemLink and rowControl.slotIndex then
    itemLink = GetItemLink(rowControl.bagId, rowControl.slotIndex)
  end
  local purchasePrice = rData and rData.purchasePrice or nil
  local stackCount = rData and rData.stackCount or nil
  local itemType = GetItemLinkItemType(itemLink)
  local itemId = GetItemLinkItemId(itemLink)

  if MasterMerchant["vendor_price_table"][itemType] then
    if MasterMerchant["vendor_price_table"][itemType][itemId] then vendorWarningPricing = MasterMerchant["vendor_price_table"][itemType][itemId] end
  end
  if purchasePrice and stackCount and vendorWarningPricing then
    local storeItemUnitPrice = purchasePrice / stackCount
    if storeItemUnitPrice > vendorWarningPricing then showVendorWarning = true end
  end

  if (not markerControl) then
    if not showVendorWarning then return end
    markerControl = WINDOW_MANAGER:CreateControl(rowControl:GetName() .. MasterMerchant.name .. "Warn", rowControl, CT_TEXTURE)
    markerControl:SetDimensions(22, 22)
    markerControl:SetInheritScale(false)
    markerControl:SetAnchor(LEFT, relativeToPoint, LEFT)
    markerControl:SetDrawTier(DT_HIGH)
  end

  if (showVendorWarning) then
    markerControl:SetTexture("/esoui/art/inventory/newitem_icon.dds")
    markerControl:SetColor(0.9, 0.3, 0.2, 1)
    markerControl:SetHidden(false)
  else
    markerControl:SetHidden(true)
  end
end

function MasterMerchant:InitializeHooks()
  if (not MasterMerchant.tradingHouseBrowseMarkerHooked) then
    SecurePostHook(TRADING_HOUSE, "OpenTradingHouse", function()
      local oldCallback = ZO_TradingHouseBrowseItemsRightPaneSearchResults.dataTypes[1].setupCallback
      ZO_TradingHouseBrowseItemsRightPaneSearchResults.dataTypes[1].setupCallback = function(rowControl, slot)
        oldCallback(rowControl, slot)
        MasterMerchant:ToggleVendorMarker(rowControl, slot)
        if MasterMerchant.wwDetected and not MasterMerchant.mwimDetected then
          MasterMerchant:ToggleWritMarkerBrowseResults(rowControl, slot)
        end
      end
    end)
  end
  if (not MasterMerchant.inventoryMarkersHooked) then
    local originalCall = ZO_PlayerInventoryList.dataTypes[1].setupCallback
    SecurePostHook(ZO_PlayerInventoryList.dataTypes[1], "setupCallback", function(rowControl, slot)
      originalCall(rowControl, slot)
      if MasterMerchant.wwDetected and not MasterMerchant.mwimDetected then
        MasterMerchant:ToggleWritMarkerInventoryList(rowControl, slot)
      end
    end)
  end
  MasterMerchant.tradingHouseBrowseMarkerHooked = true
  MasterMerchant.inventoryMarkersHooked = true
end
