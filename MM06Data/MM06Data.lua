MM06Data = {}
 
MM06Data.name = "MM06Data"
 
function MM06Data:Initialize()
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM06DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM06DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')
  if (not self.savedVariables.SalesData and self.savedVariables and self.oldSavedVariables.SalesData) then
    self.savedVariables.SalesData = self.oldSavedVariables.SalesData
    self.savedVariables.ItemsConverted = (self.savedVariables and self.oldSavedVariables.ItemsConverted)
    self.oldSavedVariables.SalesData = nil
    self.oldSavedVariables.ItemsConverted = 'Moved'
  end
  if not self.savedVariables.SalesData then self.savedVariables.SalesData = {} end
end
 
function MM06Data.OnAddOnLoaded(event, addonName)
  if addonName == MM06Data.name then
    MM06Data:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(MM06Data.name, EVENT_ADD_ON_LOADED, MM06Data.OnAddOnLoaded)