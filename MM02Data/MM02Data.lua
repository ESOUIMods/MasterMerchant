MM02Data = {}
 
MM02Data.name = "MM02Data"
 
function MM02Data:Initialize()
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM02DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM02DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')
  if (not self.savedVariables.SalesData and self.savedVariables and self.oldSavedVariables.SalesData) then
    self.savedVariables.SalesData = self.oldSavedVariables.SalesData
    self.savedVariables.ItemsConverted = (self.savedVariables and self.oldSavedVariables.ItemsConverted)
    self.oldSavedVariables.SalesData = nil
    self.oldSavedVariables.ItemsConverted = 'Moved'
  end
  if not self.savedVariables.SalesData then self.savedVariables.SalesData = {} end
end
 
function MM02Data.OnAddOnLoaded(event, addonName)
  if addonName == MM02Data.name then
    MM02Data:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(MM02Data.name, EVENT_ADD_ON_LOADED, MM02Data.OnAddOnLoaded)