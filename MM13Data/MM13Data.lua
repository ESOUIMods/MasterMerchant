MM13Data = {}
 
MM13Data.name = "MM13Data"
 
function MM13Data:Initialize()
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM13DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM13DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')
  if (not self.savedVariables.SalesData and self.savedVariables and self.oldSavedVariables.SalesData) then
    self.savedVariables.SalesData = self.oldSavedVariables.SalesData
    self.savedVariables.ItemsConverted = (self.savedVariables and self.oldSavedVariables.ItemsConverted)
    self.oldSavedVariables.SalesData = nil
    self.oldSavedVariables.ItemsConverted = 'Moved'
  end
  if not self.savedVariables.SalesData then self.savedVariables.SalesData = {} end
end
 
function MM13Data.OnAddOnLoaded(event, addonName)
  if addonName == MM13Data.name then
    MM13Data:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(MM13Data.name, EVENT_ADD_ON_LOADED, MM13Data.OnAddOnLoaded)