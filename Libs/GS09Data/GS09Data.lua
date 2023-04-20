local libName, libVersion = "GS09Data", 100
local lib = {}
lib.libName = libName
lib.defaults = {
  ['datana'] = {},
  ['dataeu'] = {},
  ["listingsna"] = {},
  ["listingseu"] = {},
}

local function Initialize()
  if not GS09DataSavedVariables then GS09DataSavedVariables = lib.defaults end
end

function lib:ResetAllData()
  GS09DataSavedVariables = lib.defaults
end

function lib:ResetSalesDataNA()
  GS09DataSavedVariables['datana'] = lib.defaults['datana']
end

function lib:ResetSalesDataEU()
  GS09DataSavedVariables['dataeu'] = lib.defaults['dataeu']
end

function lib:ResetListingsDataNA()
  GS09DataSavedVariables['listingsna'] = lib.defaults['listingsna']
end

function lib:ResetListingsDataEU()
  GS09DataSavedVariables['listingseu'] = lib.defaults['listingseu']
end

local function OnAddOnLoaded(eventCode, addonName)
  if addonName == lib.libName then
    Initialize()
  end
end

EVENT_MANAGER:RegisterForEvent(lib.libName, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

GS09Data = lib