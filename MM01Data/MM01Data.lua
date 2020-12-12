MM01Data = {}
 
MM01Data.name = "MM01Data"
 
function MM01Data:Initialize()
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM01DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM01DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')
  if (not self.savedVariables.SalesData and self.savedVariables and self.oldSavedVariables.SalesData) then
    self.savedVariables.SalesData = self.oldSavedVariables.SalesData
    self.savedVariables.ItemsConverted = (self.savedVariables and self.oldSavedVariables.ItemsConverted)
    self.oldSavedVariables.SalesData = nil
    self.oldSavedVariables.ItemsConverted = 'Moved'
  end
  if not self.savedVariables.SalesData then self.savedVariables.SalesData = {} end
end
 
function MM01Data.OnAddOnLoaded(event, addonName)
  if addonName == MM01Data.name then
    MM01Data:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(MM01Data.name, EVENT_ADD_ON_LOADED, MM01Data.OnAddOnLoaded)