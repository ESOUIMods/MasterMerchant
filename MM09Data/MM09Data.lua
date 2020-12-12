MM09Data = {}
 
MM09Data.name = "MM09Data"
 
function MM09Data:Initialize()
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM09DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM09DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')
  if (not self.savedVariables.SalesData and self.savedVariables and self.oldSavedVariables.SalesData) then
    self.savedVariables.SalesData = self.oldSavedVariables.SalesData
    self.savedVariables.ItemsConverted = (self.savedVariables and self.oldSavedVariables.ItemsConverted)
    self.oldSavedVariables.SalesData = nil
    self.oldSavedVariables.ItemsConverted = 'Moved'
  end
  if not self.savedVariables.SalesData then self.savedVariables.SalesData = {} end
end
 
function MM09Data.OnAddOnLoaded(event, addonName)
  if addonName == MM09Data.name then
    MM09Data:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(MM09Data.name, EVENT_ADD_ON_LOADED, MM09Data.OnAddOnLoaded)