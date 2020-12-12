MM07Data = {}
 
MM07Data.name = "MM07Data"
 
function MM07Data:Initialize()
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM07DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM07DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')
  if (not self.savedVariables.SalesData and self.savedVariables and self.oldSavedVariables.SalesData) then
    self.savedVariables.SalesData = self.oldSavedVariables.SalesData
    self.savedVariables.ItemsConverted = (self.savedVariables and self.oldSavedVariables.ItemsConverted)
    self.oldSavedVariables.SalesData = nil
    self.oldSavedVariables.ItemsConverted = 'Moved'
  end
  if not self.savedVariables.SalesData then self.savedVariables.SalesData = {} end
end
 
function MM07Data.OnAddOnLoaded(event, addonName)
  if addonName == MM07Data.name then
    MM07Data:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(MM07Data.name, EVENT_ADD_ON_LOADED, MM07Data.OnAddOnLoaded)