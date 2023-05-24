local libName, libVersion = "GS16Data", 100
local lib = {}
lib.libName = libName
lib["itemLink"] = {}
lib["accountNames"] = {}
lib["guildNames"] = {}
lib.accountNamesCount = 0
lib.itemLinksCount = 0
lib.guildNamesCount = 0
lib.defaults = {
  ["version"] = 2,
  ["itemLink"] = {},
  ["accountNames"] = {},
  ["guildNames"] = {},
  ["visitedNATraders"] = {},
  ["visitedEUTraders"] = {},
}

local function RebuildItemLinkData()
  local rebuiltTable = {}
  for key, value in pairs(GS16DataSavedVariables["itemLink"]) do
    rebuiltTable[value] = key
  end
  GS16DataSavedVariables["itemLink"] = rebuiltTable
end

local function RebuildAccountNameData()
  local rebuiltTable = {}
  for key, value in pairs(GS16DataSavedVariables["accountNames"]) do
    rebuiltTable[value] = key
  end
  GS16DataSavedVariables["accountNames"] = rebuiltTable
end

local function RebuildGuildNameData()
  local rebuiltTable = {}
  for key, value in pairs(GS16DataSavedVariables["guildNames"]) do
    rebuiltTable[value] = key
  end
  GS16DataSavedVariables["guildNames"] = rebuiltTable
end

local function CheckVersionNumber()
  if GS16DataSavedVariables["version"] and GS16DataSavedVariables["version"] == 2 then return end
  RebuildItemLinkData()
  RebuildAccountNameData()
  RebuildGuildNameData()
  GS16DataSavedVariables["version"] = 2
end

local function BuildAccountNameLookup()
  if not GS16DataSavedVariables["accountNames"] then return end
  local startingCount = NonContiguousCount(GS16DataSavedVariables["accountNames"])
  local count = 0
  for key, value in pairs(GS16DataSavedVariables["accountNames"]) do
    count = count + 1
    lib["accountNames"][value] = key
  end
  lib.accountNamesCount = count
end

local function BuildItemLinkNameLookup()
  if not GS16DataSavedVariables["itemLink"] then return end
  local startingCount = NonContiguousCount(GS16DataSavedVariables["itemLink"])
  local count = 0
  for key, value in pairs(GS16DataSavedVariables["itemLink"]) do
    count = count + 1
    lib["itemLink"][value] = key
  end
  lib.itemLinksCount = count
end

local function BuildGuildNameLookup()
  if not GS16DataSavedVariables["guildNames"] then return end
  local startingCount = NonContiguousCount(GS16DataSavedVariables["guildNames"])
  local count = 0
  for key, value in pairs(GS16DataSavedVariables["guildNames"]) do
    count = count + 1
    lib["guildNames"][value] = key
  end
  lib.guildNamesCount = count
end

local function Initialize()
  if not GS16DataSavedVariables then GS16DataSavedVariables = lib.defaults end
end

function lib:ResetAllData()
  GS16DataSavedVariables = lib.defaults
end

local function OnAddOnLoaded(eventCode, addonName)
  if addonName == lib.libName then
    Initialize()
    CheckVersionNumber()
    BuildAccountNameLookup()
    BuildItemLinkNameLookup()
    BuildGuildNameLookup()
  end
end

EVENT_MANAGER:RegisterForEvent(lib.libName, EVENT_ADD_ON_LOADED, OnAddOnLoaded)

GS16Data = lib