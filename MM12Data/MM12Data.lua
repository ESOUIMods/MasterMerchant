MM12Data = {}
 
MM12Data.name = "MM12Data"
 
function MM12Data:Initialize()
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM12DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM12DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')
  if (not self.savedVariables.SalesData and self.savedVariables and self.oldSavedVariables.SalesData) then
    self.savedVariables.SalesData = self.oldSavedVariables.SalesData
    self.savedVariables.ItemsConverted = (self.savedVariables and self.oldSavedVariables.ItemsConverted)
    self.oldSavedVariables.SalesData = nil
    self.oldSavedVariables.ItemsConverted = 'Moved'
  end
  if not self.savedVariables.SalesData then self.savedVariables.SalesData = {} end
end
 
function MM12Data.OnAddOnLoaded(event, addonName)
  if addonName == MM12Data.name then
    MM12Data:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(MM12Data.name, EVENT_ADD_ON_LOADED, MM12Data.OnAddOnLoaded)