MM08Data = {}
 
MM08Data.name = "MM08Data"
 
function MM08Data:Initialize()
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM08DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM08DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')
  if (not self.savedVariables.SalesData and self.savedVariables and self.oldSavedVariables.SalesData) then
    self.savedVariables.SalesData = self.oldSavedVariables.SalesData
    self.savedVariables.ItemsConverted = (self.savedVariables and self.oldSavedVariables.ItemsConverted)
    self.oldSavedVariables.SalesData = nil
    self.oldSavedVariables.ItemsConverted = 'Moved'
  end
  if not self.savedVariables.SalesData then self.savedVariables.SalesData = {} end
end
 
function MM08Data.OnAddOnLoaded(event, addonName)
  if addonName == MM08Data.name then
    MM08Data:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(MM08Data.name, EVENT_ADD_ON_LOADED, MM08Data.OnAddOnLoaded)