local libName, libVersion = "GS01Data", 100
local lib = {}
lib.libName = libName
lib.defaults = {
  ['datana'] = {},
  ['dataeu'] = {},
  ["listingsna"] = {},
  ["listingseu"] = {},
}

local function Initialize()
  if not GS01DataSavedVariables then GS01DataSavedVariables = lib.defaults end
end

function lib:ResetAllData()
  GS01DataSavedVariables = lib.defaults
end

function lib:ResetSalesDataNA()
  GS01DataSavedVariables['datana'] = lib.defaults['datana']
end

function lib:ResetSalesDataEU()
  GS01DataSavedVariables['dataeu'] = lib.defaults['dataeu']
end

function lib:ResetListingsDataNA()
  GS01DataSavedVariables['listingsna'] = lib.defaults['listingsna']
end

function lib:ResetListingsDataEU()
  GS01DataSavedVariables['listingseu'] = lib.defaults['listingseu']
end

local function OnAddOnLoaded(eventCode, addonName)
  if addonName == lib.libName then
    Initialize()
  end
end

EVENT_MANAGER:RegisterForEvent(lib.libName, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

GS01Data = lib