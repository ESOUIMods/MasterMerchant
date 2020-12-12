MM11Data = {}
 
MM11Data.name = "MM11Data"
 
function MM11Data:Initialize()
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM11DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM11DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')
  if (not self.savedVariables.SalesData and self.savedVariables and self.oldSavedVariables.SalesData) then
    self.savedVariables.SalesData = self.oldSavedVariables.SalesData
    self.savedVariables.ItemsConverted = (self.savedVariables and self.oldSavedVariables.ItemsConverted)
    self.oldSavedVariables.SalesData = nil
    self.oldSavedVariables.ItemsConverted = 'Moved'
  end
  if not self.savedVariables.SalesData then self.savedVariables.SalesData = {} end
end
 
function MM11Data.OnAddOnLoaded(event, addonName)
  if addonName == MM11Data.name then
    MM11Data:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(MM11Data.name, EVENT_ADD_ON_LOADED, MM11Data.OnAddOnLoaded)