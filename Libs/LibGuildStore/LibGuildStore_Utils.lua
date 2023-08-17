local internal = _G["LibGuildStore_Internal"]
-- itemCache: formerly MasterMerchant.itemInformationCache
local itemCache = _G["LibGuildStore_ItemCache"]
local bonanzaCache = _G["LibGuildStore_BonanzaCache"]

local MM_EFFECT_REWARD_FIELD = 24

-- /script _G["LibGuildStore_ItemInformationCache"] = {}

function internal:GetPotionEffectWritRewardField(itemLink)
  local data = { ZO_LinkHandler_ParseLink(itemLink) }
  local field24 = tonumber(data[MM_EFFECT_REWARD_FIELD] or 0)
  return field24
end

function internal:GetVoucherCountByItemLink(itemLink)
  local data = internal:GetPotionEffectWritRewardField(itemLink)
  local itemType, _ = GetItemLinkItemType(itemLink)
  if itemType == ITEMTYPE_MASTER_WRIT then
    local quotient, remainder = math.modf(data / 10000)
    local voucherCount = quotient + math.floor(0.5 + remainder)
    return voucherCount
  end
  return 0
end

-- Formerly ResetItemInformationCache
function internal:ResetItemCache()
  itemCache = { }
end

function internal:ResetBonanzaCache()
  bonanzaCache = { }
end

function internal:ResetItemAndBonanzaCache()
  internal:ResetItemCache()
  internal:ResetBonanzaCache()
end

function internal:ItemCacheHasPriceInfoById(theIID, itemIndex, daysRange)
  local cache = itemCache
  local itemInfo = cache[theIID] and cache[theIID][itemIndex] and cache[theIID][itemIndex][daysRange]
  if itemInfo and itemInfo.avgPrice then return true end
  return false
end

function internal:ItemCacheHasInfoByItemLink(itemLink, daysRange)
  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  return internal:ItemCacheHasPriceInfoById(itemID, itemIndex, daysRange)
end

-- Formerly ItemCacheHasBonanzaInfoById
function internal:BonanzaCacheHasPriceInfoById(theIID, itemIndex, daysRange)
  local cache = bonanzaCache
  local itemInfo = cache[theIID] and cache[theIID][itemIndex] and cache[theIID][itemIndex][daysRange]
  if itemInfo and itemInfo.bonanzaPrice then return true end
  return false
end

function internal:BonanzaCacheHasInfoByItemLink(itemLink, daysRange)
  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  return internal:BonanzaCacheHasPriceInfoById(itemID, itemIndex, daysRange)
end

-- Formerly ItemCacheStats
function internal:GetItemCacheStats(itemLink, daysRange)
  local cache = itemCache
  if internal:ItemCacheHasInfoByItemLink(itemLink, daysRange) then
    local itemID = GetItemLinkItemId(itemLink)
    local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
    return cache[itemID][itemIndex][daysRange]
  end
  return nil
end

function internal:GetBonanzaCacheStats(itemLink, daysRange)
  local cache = bonanzaCache
  if internal:BonanzaCacheHasInfoByItemLink(itemLink, daysRange) then
    local itemID = GetItemLinkItemId(itemLink)
    local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
    return cache[itemID][itemIndex][daysRange]
  end
  return nil
end

-- This function is used to set item information in the cache.
-- It accepts the item's ID, itemIndex, daysRange, and itemInfo table.
-- The itemInfo table contains various information about the item.
function internal:SetItemCacheById(itemID, itemIndex, daysRange, itemInfo)
  -- Get the cache table for item information
  local cache = itemCache

  -- Initialize the cache structure if it doesn't exist yet
  -- This ensures that the necessary nested tables are in place to store the item information
  cache[itemID] = cache[itemID] or {}
  cache[itemID][itemIndex] = cache[itemID][itemIndex] or {}
  cache[itemID][itemIndex][daysRange] = cache[itemID][itemIndex][daysRange] or {}

  -- Loop over each key-value pair in the itemInfo table
  for key, value in pairs(itemInfo) do
    -- Assign the value to the corresponding key in the cache
    -- Note: We use a loop to assign individual values to the cache,
    --       as graphInfo is assigned to the cache separately
    cache[itemID][itemIndex][daysRange][key] = value
  end
end

-- Formerly ItemCacheHasGraphInfoById
function internal:CacheHasGraphInfoById(theIID, itemIndex, daysRange)
  local cache = itemCache
  local itemInfo = cache[theIID] and cache[theIID][itemIndex] and cache[theIID][itemIndex][daysRange]
  if itemInfo and itemInfo.graphInfo then return true end
  return false
end

function internal:SetGraphInfoCacheById(itemID, itemIndex, daysRange, graphInfo)
  local cache = itemCache
  cache[itemID] = cache[itemID] or {}
  cache[itemID][itemIndex] = cache[itemID][itemIndex] or {}
  cache[itemID][itemIndex][daysRange] = cache[itemID][itemIndex][daysRange] or {}
  cache[itemID][itemIndex][daysRange].graphInfo = graphInfo
end

function internal:SetItemCacheByItemLink(itemLink, daysRange, itemInfo)
  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  internal:SetItemCacheById(itemID, itemIndex, daysRange, itemInfo)
end

function internal:SetBonanzaCacheById(itemID, itemIndex, daysRange, itemInfo)
  local cache = itemCache
  cache[itemID] = cache[itemID] or {}
  cache[itemID][itemIndex] = cache[itemID][itemIndex] or {}
  cache[itemID][itemIndex][daysRange] = itemInfo
end

function internal:SetBonanzaCacheByItemLink(itemLink, daysRange, itemInfo)
  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  internal:SetBonanzaCacheById(itemID, itemIndex, daysRange, itemInfo)
end

-- Formerly ClearPriceCacheById
function internal:ClearItemCacheById(itemID, itemIndex)
  local cache = itemCache
  local itemInfo = cache[itemID] and cache[itemID][itemIndex]
  if itemInfo then
    for daysRange, info in pairs(itemInfo) do
      info.avgPrice = nil
      info.numSales = nil
      info.numDays = nil
      info.numItems = nil
      info.numVouchers = nil
      info.graphInfo = nil
    end
  end
end

-- Formerly ClearBonanzaCachePriceById
function internal:ClearBonanzaCacheById(itemID, itemIndex)
  local cache = bonanzaCache
  local itemInfo = cache[itemID] and cache[itemID][itemIndex]
  if itemInfo then
    for daysRange, info in pairs(itemInfo) do
      info.bonanzaPrice = nil
      info.bonanzaListings = nil
      info.bonanzaItemCount = nil
    end
  end
end

function internal:ClearItemCacheByItemLink(itemLink)
  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  internal:ClearItemCacheById(itemID, itemIndex)
end

-- /script internal:ClearBonanzaPriceCacheByItemLink("|H1:item:54173:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h")
function internal:ClearBonanzaPriceCacheByItemLink(itemLink)
  local itemID = GetItemLinkItemId(itemLink)
  local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)
  internal:ClearBonanzaCacheById(itemID, itemIndex)
end
