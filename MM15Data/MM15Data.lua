MM15Data = {}
 
MM15Data.name = "MM15Data"
 
function MM15Data:Initialize()
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM15DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM15DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')
  if (not self.savedVariables.SalesData and self.savedVariables and self.oldSavedVariables.SalesData) then
    self.savedVariables.SalesData = self.oldSavedVariables.SalesData
    self.savedVariables.ItemsConverted = (self.savedVariables and self.oldSavedVariables.ItemsConverted)
    self.oldSavedVariables.SalesData = nil
    self.oldSavedVariables.ItemsConverted = 'Moved'
  end
  if not self.savedVariables.SalesData then self.savedVariables.SalesData = {} end
end
 
function MM15Data.OnAddOnLoaded(event, addonName)
  if addonName == MM15Data.name then
    MM15Data:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(MM15Data.name, EVENT_ADD_ON_LOADED, MM15Data.OnAddOnLoaded)