MM16Data = {}
MM16Data.name = "MM16Data"
 
function MM16Data:Initialize()
  if not MM16DataSavedVariables then MM16DataSavedVariables = {} end
end
 
function MM16Data.OnAddOnLoaded(event, addonName)
  if addonName == MM16Data.name then
    MM16Data:Initialize()
  end
end
EVENT_MANAGER:RegisterForEvent(MM16Data.name, EVENT_ADD_ON_LOADED, MM16Data.OnAddOnLoaded)