MM00Data = {}
 
MM00Data.name = "MM00Data"
 
function MM00Data:Initialize()
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM00DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM00DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')
  if (not self.savedVariables.SalesData and self.savedVariables and self.oldSavedVariables.SalesData) then
    self.savedVariables.SalesData = self.oldSavedVariables.SalesData
    self.savedVariables.ItemsConverted = (self.savedVariables and self.oldSavedVariables.ItemsConverted)
    self.oldSavedVariables.SalesData = nil
    self.oldSavedVariables.ItemsConverted = 'Moved'
  end
  if not self.savedVariables.SalesData then self.savedVariables.SalesData = {} end
end
 
function MM00Data.OnAddOnLoaded(event, addonName)
  if addonName == MM00Data.name then
    MM00Data:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(MM00Data.name, EVENT_ADD_ON_LOADED, MM00Data.OnAddOnLoaded)