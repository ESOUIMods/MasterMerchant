local libName, libVersion = "GS05Data", 100
local lib = {}
lib.libName = libName
lib.defaults = {
  ['datana'] = {},
  ['dataeu'] = {},
  ["listingsna"] = {},
  ["listingseu"] = {},
}

local function Initialize()
  if not GS05DataSavedVariables then GS05DataSavedVariables = lib.defaults end
end

function lib:ResetAllData()
  GS05DataSavedVariables = lib.defaults
end

function lib:ResetSalesDataNA()
  GS05DataSavedVariables['datana'] = lib.defaults['datana']
end

function lib:ResetSalesDataEU()
  GS05DataSavedVariables['dataeu'] = lib.defaults['dataeu']
end

function lib:ResetListingsDataNA()
  GS05DataSavedVariables['listingsna'] = lib.defaults['listingsna']
end

function lib:ResetListingsDataEU()
  GS05DataSavedVariables['listingseu'] = lib.defaults['listingseu']
end

local function OnAddOnLoaded(eventCode, addonName)
  if addonName == lib.libName then
    Initialize()
  end
end

EVENT_MANAGER:RegisterForEvent(lib.libName, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

GS05Data = lib