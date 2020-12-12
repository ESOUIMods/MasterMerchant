MM03Data = {}
 
MM03Data.name = "MM03Data"
 
function MM03Data:Initialize()
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM03DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM03DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')
  if (not self.savedVariables.SalesData and self.savedVariables and self.oldSavedVariables.SalesData) then
    self.savedVariables.SalesData = self.oldSavedVariables.SalesData
    self.savedVariables.ItemsConverted = (self.savedVariables and self.oldSavedVariables.ItemsConverted)
    self.oldSavedVariables.SalesData = nil
    self.oldSavedVariables.ItemsConverted = 'Moved'
  end
  if not self.savedVariables.SalesData then self.savedVariables.SalesData = {} end
end
 
function MM03Data.OnAddOnLoaded(event, addonName)
  if addonName == MM03Data.name then
    MM03Data:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(MM03Data.name, EVENT_ADD_ON_LOADED, MM03Data.OnAddOnLoaded)