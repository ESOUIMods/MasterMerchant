local libName, libVersion = "MM00Data", 100
local lib = {}
lib.libName = libName
lib.defaults = {}

local function Initialize()
  lib.oldSavedVariables = ZO_SavedVars:NewAccountWide("MM00DataSavedVariables", 1, nil, {})
  lib.savedVariables = ZO_SavedVars:NewAccountWide("MM00DataSavedVariables", 1, nil, {}, nil, 'MasterMerchant')
  if (not lib.savedVariables.SalesData and lib.savedVariables and lib.oldSavedVariables.SalesData) then
    lib.savedVariables.SalesData = lib.oldSavedVariables.SalesData
    lib.savedVariables.ItemsConverted = (lib.savedVariables and lib.oldSavedVariables.ItemsConverted)
    lib.oldSavedVariables.SalesData = nil
    lib.oldSavedVariables.ItemsConverted = 'Moved'
  end
  if not lib.savedVariables.SalesData then lib.savedVariables.SalesData = {} end
end

local function OnAddOnLoaded(eventCode, addonName)
  if addonName == lib.libName then
    Initialize()
  end
end

EVENT_MANAGER:RegisterForEvent(lib.libName, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

MM00Data = lib
