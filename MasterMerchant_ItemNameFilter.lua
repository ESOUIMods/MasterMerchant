local internal = _G["LibGuildStore_Internal"]
local LMP = LibMediaProvider

IFScrollList = ZO_SortFilterList:Subclass()
IFScrollList.defaults = { }
-- Sort keys for the scroll lists
IFScrollList.SORT_KEYS = {
  ['itemName'] = { isNumeric = false, tiebreaker = "itemName" },
}
ITEM_DATA = 1

function MasterMerchant:SortByItemFilterName(ordering, scrollList)
  local listData = ZO_ScrollList_GetDataList(scrollList.list)
  if not ordering then
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (sortA.data.itemName or 0) > (sortB.data.itemName or 0)
    end)
  else
    MasterMerchant.shellSort(listData, function(sortA, sortB)
      return (sortA.data.itemName or 0) < (sortB.data.itemName or 0)
    end)
  end
end

function IFScrollList:BuildMasterList()
  self.masterList = {}
  local saveData = GS17DataSavedVariables[internal.nameFilterNamespace]
  for name, link in pairs(saveData) do
    table.insert(self.masterList, { itemName = name, itemLink = link })
  end
  local listControl = self:GetListControl()
  ZO_ScrollList_Clear(listControl)
  local scrollDataList = ZO_ScrollList_GetDataList(listControl)
  for i, itemData in ipairs(self.masterList) do
    table.insert(scrollDataList, ZO_ScrollList_CreateDataEntry(ITEM_DATA, itemData))
  end
end

function IFScrollList:SortScrollList()
  if self.currentSortKey == 'itemName' then
    MasterMerchant:SortByItemFilterName(self.currentSortOrder, self)
  else
    MasterMerchant:dm("Warn", "Shit Hit the fan IFScrollList:SortScrollList")
    MasterMerchant:dm("Warn", self.currentSortKey)
  end
end

function MasterMerchant:my_RemoveFilterHandler_OnLinkMouseUp(itemName, button, control)
  if (button == 2 and itemName ~= '') then
    ClearMenu()
    AddMenuItem(GetString(MM_FILTER_MENU_REMOVE_ITEM), function() MasterMerchant:RemoveFilterFromTable(itemName) end)
    ShowMenu(control)
  end
end

function IFScrollList:SetupNameFiltersRow(control, data)
  control.icon = GetControl(control, "ItemIcon")
  control.itemName = GetControl(control, "ItemName")

  local fontString = LMP:Fetch('font', MasterMerchant.systemSavedVariables.windowFont) .. '|%d'
  control.itemName:SetFont(string.format(fontString, 15))

  local itemName = data.itemName
  local itemLink = internal:GetItemLinkByIndex(data.itemLink)
  local itemIcon = GetItemLinkInfo(itemLink)

  -- Draw itemIcon
  control.icon:SetHidden(false)
  control.icon:SetTexture(itemIcon)

  -- Draw itemName
  control.itemName:SetHidden(false)
  control.itemName:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
  control.itemName:SetFont(string.format(fontString, 15))
  control.itemName:SetText(zo_strformat('<<t:1>>', itemLink))
  control.itemName:SetHandler('OnMouseEnter', function() MasterMerchant.ShowToolTip(itemLink, control.itemName) end)
  control.itemName:SetHandler('OnMouseExit', function() ClearTooltip(ItemTooltip) end)
  control.itemName:SetHandler('OnMouseUp', function(self, upInside) MasterMerchant:my_RemoveFilterHandler_OnLinkMouseUp(itemName, upInside, self) end)
end

function IFScrollList:InitializeDataType(controlName)
  self.masterList = {}
  if controlName == 'MasterMerchantFilterByNameWindow' then
    ZO_ScrollList_AddDataType(self.list, 1, 'MasterMerchantFilterByNameDataRow', 36,
      function(control, data) self:SetupNameFiltersRow(control, data) end)
  else
    MasterMerchant:dm("Warn", "Shit Hit the fan IFScrollList:InitializeDataType")
    MasterMerchant:dm("Warn", controlName)
  end
  self.currentSortKey = "itemName"
  self.currentSortOrder = ZO_SORT_ORDER_UP
  self:RefreshData()
end

function IFScrollList:New(control)
  local skList = ZO_SortFilterList.New(self, control)
  skList:InitializeDataType(control:GetName())
  if control:GetName() == 'MasterMerchantFilterByNameWindow' then
    skList.sortHeaderGroup:SelectHeaderByKey('name')
    ZO_SortHeader_OnMouseExit(MasterMerchantFilterByNameWindowHeadersItemName)
  else
    MasterMerchant:dm("Warn", "Shit Hit the fan IFScrollList:New")
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

function MasterMerchant:AddToFilterTable(itemLink)
  local itemName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink))
  local linkHash = internal:AddSalesTableData("itemLink", itemLink)

  if not GS17DataSavedVariables[internal.nameFilterNamespace][itemName] then
    GS17DataSavedVariables[internal.nameFilterNamespace][itemName] = linkHash
  end
  MasterMerchant.nameFilterScrollList:RefreshData()
  MasterMerchant.listingsScrollList:RefreshFilters()
end

function MasterMerchant:RemoveFilterFromTable(itemName)
  if GS17DataSavedVariables[internal.nameFilterNamespace][itemName] then
    GS17DataSavedVariables[internal.nameFilterNamespace][itemName] = nil
  end
  MasterMerchant.nameFilterScrollList:RefreshData()
  MasterMerchant.listingsScrollList:RefreshFilters()
end

function MasterMerchant:ClearFilterList()
  GS17DataSavedVariables[internal.nameFilterNamespace] = {}
  MasterMerchant.nameFilterScrollList:RefreshData()
  MasterMerchant.listingsScrollList:RefreshFilters()
end
