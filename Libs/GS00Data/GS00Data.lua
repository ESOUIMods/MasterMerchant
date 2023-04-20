local libName, libVersion = "GS00Data", 100
local lib = {}
lib.libName = libName
lib.defaults = {
  ['datana'] = {},
  ['dataeu'] = {},
  ["listingsna"] = {},
  ["listingseu"] = {},
}

local function Initialize()
  if not GS00DataSavedVariables then GS00DataSavedVariables = lib.defaults end
end

function lib:ResetAllData()
  GS00DataSavedVariables = lib.defaults
end

function lib:ResetSalesDataNA()
  GS00DataSavedVariables['datana'] = lib.defaults['datana']
end

function lib:ResetSalesDataEU()
  GS00DataSavedVariables['dataeu'] = lib.defaults['dataeu']
end

function lib:ResetListingsDataNA()
  GS00DataSavedVariables['listingsna'] = lib.defaults['listingsna']
end

function lib:ResetListingsDataEU()
  GS00DataSavedVariables['listingseu'] = lib.defaults['listingseu']
end

local function OnAddOnLoaded(eventCode, addonName)
  if addonName == lib.libName then
    Initialize()
  end
end

EVENT_MANAGER:RegisterForEvent(lib.libName, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

GS00Data = lib
