local libName, libVersion = "GS17Data", 100
local lib = {}
lib.libName = libName
lib.defaults = {
  ["version"] = 2,
  ["accountNames"] = {},
  ["cancelleditemsna"] = {},
  ["cancelleditemseu"] = {},
  ["currentNAGuilds"] = {
    ["count"] = 0,
    ["guilds"] = {},
  },
  ["currentEUGuilds"] = {
    ["count"] = 0,
    ["guilds"] = {},
  },
  ["erroneous_links"] = {},
  ["namefilterna"] = {},
  ["namefiltereu"] = {},
  ["posteditemsna"] = {},
  ["posteditemseu"] = {},
  ["pricingdatana"] = {},
  ["pricingdataeu"] = {},
  ["purchasena"] = {},
  ["purchaseeu"] = {},
  ["visitedNATraders"] = {},
  ["visitedEUTraders"] = {},
}

local function Initialize()
  if not GS17DataSavedVariables then GS17DataSavedVariables = lib.defaults end
end

function lib:ResetAllData()
  GS17DataSavedVariables = lib.defaults
end

local function MigrateVisitedTraderData()
  GS17DataSavedVariables["visitedNATraders"] = GS17DataSavedVariables["visitedNATraders"] or {}
  GS17DataSavedVariables["visitedEUTraders"] = GS17DataSavedVariables["visitedEUTraders"] or {}
  GS17DataSavedVariables["visitedNATraders"] = GS16DataSavedVariables["visitedNATraders"] or {}
  GS17DataSavedVariables["visitedEUTraders"] = GS16DataSavedVariables["visitedEUTraders"] or {}
  GS16DataSavedVariables["visitedNATraders"] = nil
  GS16DataSavedVariables["visitedEUTraders"] = nil
end

local function MigrateAccountNameData()
  GS17DataSavedVariables["accountNames"] = GS17DataSavedVariables["accountNames"] or {}
  GS17DataSavedVariables["accountNames"] = GS16DataSavedVariables["accountNames"] or {}
  GS16DataSavedVariables["accountNames"] = nil
end

local function DeleteOldCurrentGuildsData()
  GS16DataSavedVariables["currentNAGuilds"] = nil
  GS16DataSavedVariables["currentEUGuilds"] = nil
end

local function CheckVersionNumber()
  if GS17DataSavedVariables["version"] and GS17DataSavedVariables["version"] == 2 then return end
  MigrateVisitedTraderData()
  MigrateAccountNameData()
  DeleteOldCurrentGuildsData()
  GS17DataSavedVariables["version"] = 2
end

local function OnAddOnLoaded(eventCode, addonName)
  if addonName == lib.libName then
    Initialize()
    CheckVersionNumber()
  end
end

EVENT_MANAGER:RegisterForEvent(lib.libName, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

GS17Data = lib