MM14Data = {}
 
MM14Data.name = "MM14Data"
 
function MM14Data:Initialize()
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM14DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM14DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')
  if (not self.savedVariables.SalesData and self.savedVariables and self.oldSavedVariables.SalesData) then
    self.savedVariables.SalesData = self.oldSavedVariables.SalesData
    self.savedVariables.ItemsConverted = (self.savedVariables and self.oldSavedVariables.ItemsConverted)
    self.oldSavedVariables.SalesData = nil
    self.oldSavedVariables.ItemsConverted = 'Moved'
  end
  if not self.savedVariables.SalesData then self.savedVariables.SalesData = {} end
end
 
function MM14Data.OnAddOnLoaded(event, addonName)
  if addonName == MM14Data.name then
    MM14Data:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(MM14Data.name, EVENT_ADD_ON_LOADED, MM14Data.OnAddOnLoaded)