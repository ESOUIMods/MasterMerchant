MM04Data = {}
 
MM04Data.name = "MM04Data"
 
function MM04Data:Initialize()
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM04DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM04DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')
  if (not self.savedVariables.SalesData and self.savedVariables and self.oldSavedVariables.SalesData) then
    self.savedVariables.SalesData = self.oldSavedVariables.SalesData
    self.savedVariables.ItemsConverted = (self.savedVariables and self.oldSavedVariables.ItemsConverted)
    self.oldSavedVariables.SalesData = nil
    self.oldSavedVariables.ItemsConverted = 'Moved'
  end
  if not self.savedVariables.SalesData then self.savedVariables.SalesData = {} end
end
 
function MM04Data.OnAddOnLoaded(event, addonName)
  if addonName == MM04Data.name then
    MM04Data:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(MM04Data.name, EVENT_ADD_ON_LOADED, MM04Data.OnAddOnLoaded)