local internal       = _G["LibGuildStore_Internal"]
local filter_items_data = _G["LibGuildStore_FilteredItemsData"]
local LMP                               = LibMediaProvider

IFScrollList           = ZO_SortFilterList:Subclass()
IFScrollList.defaults  = { }
-- Sort keys for the scroll lists
IFScrollList.SORT_KEYS = {
  ['name'] = { isNumeric = false, tiebreaker = "name" },
}

function IFScrollList:FilterScrollList()
  -- this will error when the MM window is open and sr_index is empty
  --if internal:is_empty_or_nil(sr_index) then return end
  local listData = ZO_ScrollList_GetDataList(self.list)
  ZO_ClearNumericallyIndexedTable(listData)
  for itemIndex, itemData in pairs(filter_items_data) do
    table.insert(listData, ZO_ScrollList_CreateDataEntry(1, { itemIndex, itemData } ))
  end
end

function IFScrollList:SortScrollList()
  if self.currentSortKey == 'name' then
    MasterMerchant:SortByName(self.currentSortOrder, self)
  else
    internal:dm("Warn", "Shit Hit the fan IFScrollList:SortScrollList")
    internal:dm("Warn", self.currentSortKey)
  end
end

function IFScrollList:SetupNameFiltersRow(control, data)

  control.icon         = GetControl(control, GetString(MM_ITEM_ICON_COLUMN))
  control.itemName     = GetControl(control, GetString(MM_ITEMNAME_COLUMN))

  if (filter_items_data[data[1]] == nil) then
    --d('MM Data Error:')
    --d(data[1])
    --d(data[2])
    --d('--------')
    return
  end
  local fontString = LMP:Fetch('font', MasterMerchant.systemSavedVariables.windowFont) .. '|%d'
  control.itemName:SetFont(string.format(fontString, 15))

  local itemName = data[1]
  local itemLink = internal:GetStringByIndex(internal.GS_CHECK_ITEMLINK, data[2])
  local itemIcon = GetItemLinkInfo(itemLink)

  -- Draw itemIcon
  control.icon:SetHidden(false)
  control.icon:SetTexture(itemIcon)

  -- Draw itemName
  control.itemName:SetHidden(false)
  control.itemName:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
  control.itemName:SetFont(string.format(fontString, 15))
  control.itemName:SetText(zo_strformat('<<t:1>>', itemLink))
end

function IFScrollList:InitializeDataType(controlName)
  self.masterList = {}
  if controlName == 'MasterMerchantFilterByNameWindow' then
    ZO_ScrollList_AddDataType(self.list, 1, 'MasterMerchantFilterByNameDataRow', 36,
      function(control, data) self:SetupNameFiltersRow(control, data) end)
  else
    internal:dm("Warn", "Shit Hit the fan IFScrollList:InitializeDataType")
    internal:dm("Warn", controlName)
  end
  self:RefreshData()
end

function IFScrollList:New(control)
  local skList = ZO_SortFilterList.New(self, control)
  skList:InitializeDataType(control:GetName())
  if control:GetName() == 'MasterMerchantFilterByNameWindow' then
    skList.sortHeaderGroup:SelectHeaderByKey('name')
    ZO_SortHeader_OnMouseExit(MasterMerchantFilterByNameWindowHeadersItemName)
  else
    internal:dm("Warn", "Shit Hit the fan IFScrollList:New")
    internal:dm("Warn", control:GetName())
  end

  ZO_PostHook(skList, 'RefreshData', function()
    local texCon = skList.list.scrollbar:GetThumbTextureControl()
    if texCon:GetHeight() < 10 then skList.list.scrollbar:SetThumbTextureHeight(10) end
  end)

  return skList
end

--[[
function INFList:SetupUnitRow(control, data)
  control.data = data
  control.icon = GetControl(control, GetString(MM_ITEM_ICON_COLUMN))
  control.itemName = GetControl(control, GetString(MM_ITEMNAME_COLUMN))

  local icon = GetItemLinkInfo(data.item)

  --- Set text ---
  control.itemName:SetText(data.item)

  ZO_SortFilterList.SetupRow(self, control, data)
end

function INFList:BuildMasterList()
  internal:dm("Debug", "BuildMasterList")
  self.masterList = {}

  for itemName, itemLink in pairs(filter_items_data) do
    local filter = {}
    filter["itemName"] = itemName
    filter["itemLink"] = internal:GetStringByIndex(internal.GS_CHECK_ITEMLINK, itemLink)
    table.insert(self.masterList, filter)
  end
end
]]--
function MasterMerchant:AddToFilterTable(itemLink)
  local itemName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink))
  local filter = {}
  filter["itemName"] = itemName
  local linkHash   = internal:AddSalesTableData("itemLink", itemLink)
  filter["itemLink"] = linkHash
  if not filter_items_data[itemName] then
    filter_items_data[itemName] = linkHash
    GS17DataSavedVariables[internal.nameFilterNamespace][itemName] = linkHash
  end
  MasterMerchant.nameFilterScrollList:RefreshData()
  -- GS17DataSavedVariables[internal.nameFilterNamespace]
  -- filter_items_data
end
