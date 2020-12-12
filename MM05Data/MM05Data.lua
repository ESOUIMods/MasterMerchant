MM05Data = {}
 
MM05Data.name = "MM05Data"
 
function MM05Data:Initialize()
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM05DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM05DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')
  if (not self.savedVariables.SalesData and self.savedVariables and self.oldSavedVariables.SalesData) then
    self.savedVariables.SalesData = self.oldSavedVariables.SalesData
    self.savedVariables.ItemsConverted = (self.savedVariables and self.oldSavedVariables.ItemsConverted)
    self.oldSavedVariables.SalesData = nil
    self.oldSavedVariables.ItemsConverted = 'Moved'
  end
  if not self.savedVariables.SalesData then self.savedVariables.SalesData = {} end
end
 
function MM05Data.OnAddOnLoaded(event, addonName)
  if addonName == MM05Data.name then
    MM05Data:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(MM05Data.name, EVENT_ADD_ON_LOADED, MM05Data.OnAddOnLoaded)