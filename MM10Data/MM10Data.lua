MM10Data = {}
 
MM10Data.name = "MM10Data"
 
function MM10Data:Initialize()
  self.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM10DataSavedVariables", 1, nil, {})
  self.savedVariables = ZO_SavedVars:NewAccountWide("MM10DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')
  if (not self.savedVariables.SalesData and self.savedVariables and self.oldSavedVariables.SalesData) then
    self.savedVariables.SalesData = self.oldSavedVariables.SalesData
    self.savedVariables.ItemsConverted = (self.savedVariables and self.oldSavedVariables.ItemsConverted)
    self.oldSavedVariables.SalesData = nil
    self.oldSavedVariables.ItemsConverted = 'Moved'
  end
  if not self.savedVariables.SalesData then self.savedVariables.SalesData = {} end
end
 
function MM10Data.OnAddOnLoaded(event, addonName)
  if addonName == MM10Data.name then
    MM10Data:Initialize()
  end
end
 
EVENT_MANAGER:RegisterForEvent(MM10Data.name, EVENT_ADD_ON_LOADED, MM10Data.OnAddOnLoaded)