local AGS = AwesomeGuildStore

local SortOrderBase = nil
local SortOrderDealPercentSubclass = nil
MasterMerchant.SortOrderDealPercent = {}

if AwesomeGuildStore then
  SortOrderBase = AGS.class.SortOrderBase
  SortOrderDealPercentSubclass = SortOrderBase:Subclass()
  MasterMerchant.SortOrderDealPercent = SortOrderDealPercentSubclass
  local DEAL_PERCENT_ORDER = 100
  local DEAL_PERCENT_ORDER_LABEL = GetString(AGS_PERCENT_ORDER_LABEL)

  function MasterMerchant.SortOrderDealPercent:New(...)
    return SortOrderBase.New(self, ...)
  end

  function MasterMerchant.SortOrderDealPercent:Initialize()
    SortOrderBase.Initialize(self, DEAL_PERCENT_ORDER, DEAL_PERCENT_ORDER_LABEL, function(a, b)
      local index = a.itemUniqueId
      local itemLink_a = GetTradingHouseSearchResultItemLink(index)
      index = b.itemUniqueId
      local itemLink_b = GetTradingHouseSearchResultItemLink(index)

      local x, margin_a, x = MasterMerchant.GetDealInformation(itemLink_a, a.purchasePrice, a.stackCount)
      local x, margin_b, x = MasterMerchant.GetDealInformation(itemLink_b, b.purchasePrice, b.stackCount)

      margin_a = margin_a or 0.0001
      margin_b = margin_b or 0.0001
      if (margin_a == margin_b) then return 0 end

      if MasterMerchant.systemSavedVariables.agsPercentSortOrderToUse == MM_AGS_SORT_PERCENT_ASCENDING then
        return margin_a < margin_b and 1 or -1
      else
        return margin_a > margin_b and 1 or -1
      end
    end)

    self.useLocalDirection = true
  end
end
