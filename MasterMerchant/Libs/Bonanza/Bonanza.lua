Bonanza             = {}
Bonanza.Name        = "Bonanza"
local internal      = _G["LibGuildStore_Internal"]
local listings_data = _G["LibGuildStore_ListingsData"]

if LibDebugLogger then
  Bonanza.logger = LibDebugLogger.Create(Bonanza.Name)
end
local SDLV = DebugLogViewer
if SDLV then Bonanza.viewer = true else Bonanza.viewer = false end

local function create_log(log_type, log_content)
  if log_type == "Debug" then
    Bonanza.logger:Debug(log_content)
  end
  if log_type == "Info" then
    Bonanza.logger:Info(log_content)
  end
  if log_type == "Verbose" then
    Bonanza.logger:Verbose(log_content)
  end
  if log_type == "Warn" then
    Bonanza.logger:Warn(log_content)
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

function Bonanza:dm(log_type, ...)
  if not Bonanza.logger then return end
  for i = 1, select("#", ...) do
    local value = select(i, ...)
    if (type(value) == "table") then
      emit_table(log_type, value)
    else
      emit_message(log_type, tostring(value))
    end
  end
end

Bonanza.Version  = "1.0.3"
Bonanza.FONT     = "EsoUI/Common/Fonts/ProseAntiquePSMT.otf"
Bonanza.SavedData = {
  Account = nil,
  System  = nil
}

----- List functions
BLList           = ZO_SortFilterList:Subclass()
BLList.defaults  = {}
BLList.SORT_KEYS = { ["account"] = { tiebreaker = "time" },
                     ["guild"] = { tiebreaker = "time" },
                     ["item"] = { tiebreaker = "time" },
                     ["price"] = { tiebreaker = "time" },
                     ["time"] = {}
}

function BLList:Initialize(control)
  ZO_SortFilterList.Initialize(self, control)
  self.masterList = {}

  ZO_ScrollList_AddDataType(self.list, 1, "BonanzaDataRow", 30,
    function(control, data)
      self:SetupUnitRow(control, data)
    end
  )

  ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")

  self.sortFunction = function(listEntry1, listEntry2)
    return ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, self.SORT_KEYS,
      self.currentSortOrder)
  end

  self.sortHeaderGroup:SelectHeaderByKey("time")
  self.sortHeaderGroup:SelectHeaderByKey("time")
  self:RefreshData()
end

function BLList:SetupUnitRow(control, data)
  control.data     = data
  control.account  = GetControl(control, "Account")
  control.guild    = GetControl(control, "Guild")
  control.icon     = GetControl(control, "Icon")
  control.quantity = GetControl(control, "Quantity")
  control.item     = GetControl(control, "Item")
  control.time     = GetControl(control, "Time")
  control.price    = GetControl(control, "Price")

  local icon       = GetItemLinkInfo(data.item)

  --- Set text ---
  control.account:SetText(data.account)
  control.guild:SetText(data.guild)
  control.icon:SetTexture(icon)
  if (data.quantity <= 1) then
    control.quantity:SetHidden(true)
  else
    control.quantity:SetText(data.quantity)
    control.quantity:SetHidden(false)
  end
  control.item:SetText(data.item)

  local secsSince = GetTimeStamp() - data.time

  if secsSince < 864000 then
    control.time:SetText(ZO_FormatDurationAgo(secsSince))
  else
    control.time:SetText(zo_strformat(GetString(SK_TIME_DAYS), math.floor(secsSince / ZO_ONE_DAY_IN_SECONDS)))
  end

  control.price:SetText(data.price .. " |t16:16:EsoUI/Art/currency/currency_gold.dds|t")

  --- Set colors ---
  if (GetDisplayName() == data.account) then
    control.account.normalColor = ZO_ColorDef:New(0.18, 0.77, 0.05, 1)
  else
    control.account.normalColor = ZO_ColorDef:New(1, 1, 1, 1)
  end

  control.guild.normalColor    = ZO_ColorDef:New(1, 1, 1, 1)
  control.quantity.normalColor = ZO_ColorDef:New(1, 1, 1, 1)
  control.item.normalColor     = ZO_ColorDef:New(1, 1, 1, 1)
  control.time.normalColor     = ZO_ColorDef:New(1, 1, 1, 1)
  control.price.normalColor    = ZO_ColorDef:New(0.84, 0.71, 0.15, 1)

  control.item:SetHandler('OnMouseEnter', function()
    InitializeTooltip(ItemTooltip, control.item)
    ItemTooltip:SetLink(data.item)
    MasterMerchant:addStatsAndGraph(ItemTooltip, data.item)
  end)

  control.item:SetHandler('OnMouseExit', function()
    ClearTooltip(ItemTooltip)
  end)

  ZO_SortFilterList.SetupRow(self, control, data)
end

function BLList:BuildMasterList()
  Bonanza:dm("Debug", "BuildMasterList")
  self.masterList = {}

  for itemid, versionlist in pairs(listings_data) do
    if listings_data[itemid] then
      for versionid, versiondata in pairs(versionlist) do
        if listings_data[itemid][versionid] then
          if versiondata.sales then
            for saleid, saledata in pairs(versiondata.sales) do
              local purchase       = {}
              purchase["account"]  = internal:GetStringByIndex(internal.GS_CHECK_ACCOUNTNAME, saledata.seller)
              purchase["item"]     = internal:GetStringByIndex(internal.GS_CHECK_ITEMLINK, saledata.itemLink)
              purchase["guild"]    = internal:GetStringByIndex(internal.GS_CHECK_GUILDNAME, saledata.guild)
              purchase["quantity"] = saledata.quant
              purchase["price"]    = saledata.price
              purchase["time"]     = saledata.timestamp
              table.insert(self.masterList, purchase)
            end
          end
        end
      end
    end
  end
end

local function getTraitName(itemLink)
  local t = GetItemLinkTraitInfo(itemLink)

  if (t == 0) then
    return nil
  end

  return GetString("SI_ITEMTRAITTYPE", t)
end

function BLList:FilterScrollList()
  local scrollData = ZO_ScrollList_GetDataList(self.list)
  ZO_ClearNumericallyIndexedTable(scrollData)
  local searchTerms = { zo_strsplit(' ', zo_strlower(BonanzaWindowSearchBox:GetText())) }

  for i = 1, #self.masterList do
    local data = self.masterList[i]

    if (#searchTerms > 0) then
      for j = 1, #searchTerms do
        if (string.find(zo_strlower(data.account), searchTerms[j]) ~= nil) or
          (string.find(zo_strlower(data.guild), searchTerms[j]) ~= nil) or
          (string.find(zo_strlower(GetItemLinkName(data.item)), searchTerms[j]) ~= nil) or
          (string.find(zo_strlower(getTraitName(data.item)), searchTerms[j]) ~= nil) then
          if (j == #searchTerms) then
            table.insert(scrollData, ZO_ScrollList_CreateDataEntry(1, data))
          end
        else
          break
        end
      end

    else
      table.insert(scrollData, ZO_ScrollList_CreateDataEntry(1, data))
    end
  end
end

function BLList:SortScrollList()
  local scrollData = ZO_ScrollList_GetDataList(self.list)
  table.sort(scrollData, self.sortFunction)
end

function BLList:Refresh()
  self:RefreshData()
end

function Bonanza:ToggleBuyerSeller()
  self.List:Refresh()
end

function Bonanza:initialize()
  Bonanza:dm("Debug", "Bonanza Initializing")
  local MMOnWindowMoveStop = MasterMerchant.OnWindowMoveStop
  function MasterMerchant:OnWindowMoveStop(window)
    if window == BonanzaWindow then
      MasterMerchantWindow:ClearAnchors()
      MasterMerchantWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, BonanzaWindow:GetLeft(),
        BonanzaWindow:GetTop())
      MasterMerchantGuildWindow:ClearAnchors()
      MasterMerchantGuildWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, BonanzaWindow:GetLeft(),
        BonanzaWindow:GetTop())
      MMOnWindowMoveStop(MasterMerchant, MasterMerchantWindow)
    elseif (window == MasterMerchantWindow) or (window == MasterMerchantGuildWindow) then
      MMOnWindowMoveStop(MasterMerchant, window)
      BonanzaWindow:ClearAnchors()
      BonanzaWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchantWindow:GetLeft(),
        MasterMerchantWindow:GetTop())
    else
      MMOnWindowMoveStop(MasterMerchant, window)
    end
  end

  local MMToggleViewMode = MasterMerchant.ToggleViewMode
  function MasterMerchant:ToggleViewMode()
    if BonanzaWindow:IsHidden() == false then
      BonanzaWindow:SetHidden(true)
      Bonanza.CurrentMMWindow:SetHidden(false)
      if ShoppingList then
        ShoppingListWindow:SetHidden(true)
      end
    else
      MMToggleViewMode(MasterMerchant)
      if MasterMerchantWindow:IsHidden() then
        Bonanza.CurrentMMWindow = MasterMerchantGuildWindow
      else
        Bonanza.CurrentMMWindow = MasterMerchantWindow
      end
    end
  end

  BonanzaWindow:ClearAnchors()
  BonanzaWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, MasterMerchantWindow:GetLeft(), MasterMerchantWindow:GetTop())

  if MasterMerchantWindow:IsHidden() then
    Bonanza.CurrentMMWindow = MasterMerchantWindow
  else
    Bonanza.CurrentMMWindow = MasterMerchantGuildWindow
  end

  BonanzaWindowTitle:SetFont(self.FONT .. "|26")
  BonanzaWindowTitle:SetText(GetString(MM_EXTENSION_BONANZA_NAME) .. ' - ' .. GetString(BW_WINDOW_TITLE))

  BonanzaWindowHeadersAccount:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  BonanzaWindowHeadersAccount:GetNamedChild('Name'):SetFont(self.FONT .. "|17")
  BonanzaWindowHeadersAccount:GetNamedChild('Name'):SetText(GetString(BW_LISTHEADER_SELLER))

  BonanzaWindowHeadersGuild:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  BonanzaWindowHeadersGuild:GetNamedChild('Name'):SetFont(self.FONT .. "|17")
  BonanzaWindowHeadersGuild:GetNamedChild('Name'):SetText(GetString(BW_LISTHEADER_GUILD))

  BonanzaWindowHeadersItem:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  BonanzaWindowHeadersItem:GetNamedChild('Name'):SetFont(self.FONT .. "|17")
  BonanzaWindowHeadersItem:GetNamedChild('Name'):SetText(GetString(BW_LISTHEADER_ITEM))

  BonanzaWindowHeadersTime:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  BonanzaWindowHeadersTime:GetNamedChild('Name'):SetFont(self.FONT .. "|17")
  BonanzaWindowHeadersTime:GetNamedChild('Name'):SetText(GetString(BW_LISTHEADER_TIME))

  BonanzaWindowHeadersPrice:GetNamedChild('Name'):SetModifyTextType(MODIFY_TEXT_TYPE_NONE)
  BonanzaWindowHeadersPrice:GetNamedChild('Name'):SetFont(self.FONT .. "|17")
  BonanzaWindowHeadersPrice:GetNamedChild('Name'):SetText(GetString(BW_LISTHEADER_PRICE))
  BonanzaWindowHeadersPrice:GetNamedChild('Name'):SetColor(0.84, 0.71, 0.15, 1)

  Bonanza.List = BLList:New(BonanzaWindow)
end

function Bonanza:StartInitialize()
  Bonanza:dm("Debug", "Bonanza StartInitialize")
  if ShoppingList.isReady then
    Bonanza:initialize()
  else
    zo_callLater(function() Bonanza:StartInitialize() end, (ZO_ONE_MINUTE_IN_MILLISECONDS / 3)) -- 60000 1 minute
  end
end

local function onPlayerActivated(eventCode)
  EVENT_MANAGER:UnregisterForEvent(Bonanza.Name, eventCode)
  Bonanza:dm("Debug", "onPlayerActivated")

  if (MasterMerchant == nil) then
    d("Bonanza: Master Merchant not found!")
    return
  end

  Bonanza:StartInitialize()

  EVENT_MANAGER:RegisterForEvent(Bonanza.Name, EVENT_MAIL_CLOSE_MAILBOX, function()
    BonanzaWindow:SetHidden(true)
  end)

  EVENT_MANAGER:RegisterForEvent(Bonanza.Name, EVENT_CLOSE_TRADING_HOUSE, function()
    BonanzaWindow:SetHidden(true)
  end)
end

local function onAddOnLoaded(eventCode, addonName)
  if (addonName ~= Bonanza.Name) then
    return
  end
  Bonanza:dm("Debug", "onAddOnLoaded")
  
  Bonanza.SavedData.System = ZO_SavedVars:NewAccountWide("Bonanza_SavedVariables", 1, nil,
    { Tables = {}, Purchases = {}, Settings = { KeepDays = 60 } }, nil, "Bonanza")

  EVENT_MANAGER:RegisterForEvent(Bonanza.Name, EVENT_PLAYER_ACTIVATED, onPlayerActivated)
  EVENT_MANAGER:UnregisterForEvent(Bonanza.Name, EVENT_ADD_ON_LOADED)
end

EVENT_MANAGER:RegisterForEvent(Bonanza.Name, EVENT_ADD_ON_LOADED, onAddOnLoaded)
