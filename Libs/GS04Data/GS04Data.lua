local libName, libVersion = "GS04Data", 100
local lib = {}
lib.libName = libName
lib.defaults = {
  ['datana'] = {},
  ['dataeu'] = {},
  ["listingsna"] = {},
  ["listingseu"] = {},
}

local function Initialize()
  if not GS04DataSavedVariables then GS04DataSavedVariables = lib.defaults end
end

function lib:ResetAllData()
  GS04DataSavedVariables = lib.defaults
end

function lib:ResetSalesDataNA()
  GS04DataSavedVariables['datana'] = lib.defaults['datana']
end

function lib:ResetSalesDataEU()
  GS04DataSavedVariables['dataeu'] = lib.defaults['dataeu']
end

function lib:ResetListingsDataNA()
  GS04DataSavedVariables['listingsna'] = lib.defaults['listingsna']
end

function lib:ResetListingsDataEU()
  GS04DataSavedVariables['listingseu'] = lib.defaults['listingseu']
end

local function OnAddOnLoaded(eventCode, addonName)
  if addonName == lib.libName then
    Initialize()
  end
end

EVENT_MANAGER:RegisterForEvent(lib.libName, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

GS04Data = lib