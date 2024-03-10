local internal = _G["LibGuildStore_Internal"]
local currentNumEvents = {}
local categoryText = {
  [GUILD_HISTORY_EVENT_CATEGORY_ACTIVITY] = "Activity",
  [GUILD_HISTORY_EVENT_CATEGORY_AVA_ACTIVITY] = "Ava  Activity",
  [GUILD_HISTORY_EVENT_CATEGORY_BANKED_CURRENCY] = "Banked Currency",
  [GUILD_HISTORY_EVENT_CATEGORY_BANKED_ITEM] = "Banked Item",
  [GUILD_HISTORY_EVENT_CATEGORY_MILESTONE] = "Milestone",
  [GUILD_HISTORY_EVENT_CATEGORY_ROSTER] = "Roster",
  [GUILD_HISTORY_EVENT_CATEGORY_TRADER] = "Trader",
}
local function ConvertEventIdToId64String(eventId)
  local idString = tostring(eventId)
  while #idString < 9 do
    idString = "0" .. idString
  end
  local convertedId = StringToId64("3" .. idString)
  return Id64ToString(convertedId)
end

local function ProcessGuildHistoryResponse(guildId, eventIndex)
  local eventId, timestampS, eventType, sellerDisplayName, buyerDisplayName, itemLink, quantity, price, tax = GetGuildHistoryTraderEventInfo(guildId, eventIndex)
  local guildName = GetGuildName(guildId)

  local theEvent = {
    buyer = buyerDisplayName,
    guild = guildName,
    itemLink = itemLink,
    quant = quantity,
    timestamp = timestampS,
    price = price,
    seller = sellerDisplayName,
    wasKiosk = false,
    id = ConvertEventIdToId64String(eventId),
  }
  theEvent.wasKiosk = (internal.guildMemberInfo[guildId][zo_strlower(theEvent.buyer)] == nil)
  internal:dm("Debug", theEvent)
end

local function ProcessCategoryUpdate(eventCode, guildId, eventCategory, flags)
  local eventDifference = 0
  local guildName = GetGuildName(guildId)
  local numEvents = GetNumGuildHistoryEvents(guildId, eventCategory)

  if numEvents > (currentNumEvents[guildId] or 0) then
    eventDifference = numEvents - (currentNumEvents[guildId] or 0)
  end
  currentNumEvents[guildId] = numEvents

  local theEvent = {}
  local eventsAdded = 0
  local duplicateEvents = 0
  -- always update global number of events
  -- GUILD_HISTORY_STORE
  if eventCategory == GUILD_HISTORY_EVENT_CATEGORY_TRADER then
    internal:dm("Debug", string.format('Process Guild History Response for: %s (%s) from category: %s', guildName, numEvents, categoryText[eventCategory]))
    internal:dm("Debug", string.format('Event Difference: %s', eventDifference))
    if eventDifference < 500 then
      for eventIndex = 1, eventDifference do
        internal:dm("Debug", string.format('ProcessCategoryUpdate (%s): %s', eventIndex, categoryText[eventCategory]))
        ProcessGuildHistoryResponse(guildId, eventIndex)
      end
    end
  end
  --[[
for i = 1, eventDifference do
  if eventCategory == GUILD_HISTORY_EVENT_CATEGORY_TRADER then
    -- /script d({ GetGuildHistoryTraderEventInfo(622389, 13563) })
    theEvent = { GetGuildHistoryTraderEventInfo(guildId, i) }
    local id, lostPrecisionUseStringToId64 = NumberToId64(theEvent[LibGuildHistoryCache.traderEventEnum.TRADER_HISTORY_EVENT_ID])
    if lostPrecisionUseStringToId64 then
      LibGuildHistoryCache.dm("Debug", string.format('Lost Precision: %s (%s)', id, theEvent[LibGuildHistoryCache.traderEventEnum.TRADER_HISTORY_EVENT_ID]))
    end
    local index = Id64ToString(id)
    if LibGuildHistoryCache_SavedVariables[megaserver][index] == nil then
      eventsAdded = eventsAdded + 1
      LibGuildHistoryCache_SavedVariables[megaserver][index] = {}
      LibGuildHistoryCache_SavedVariables[megaserver][index] = LibGuildHistoryCache:BuildSavedVarsTable(theEvent, eventCategory)
    else
      duplicateEvents = duplicateEvents + 1
    end
  end

  if i == 1 then LibGuildHistoryCache.newestEvent = GetTimeStamp() - theEvent[LibGuildHistoryCache.traderEventEnum.TRADER_HISTORY_SECONDS_SINCE_EVENT] end
  if i == numEvents then LibGuildHistoryCache.oldestEvent = GetTimeStamp() - theEvent[LibGuildHistoryCache.traderEventEnum.TRADER_HISTORY_SECONDS_SINCE_EVENT] end

  timeSinceInSeconds < LibGuildHistoryCache.oneYearInSeconds to
  prevent adding an event with an erroneous ammount of time in seconds
  since the sale was made.
end
  ]]--

  --[[
LibGuildHistoryCache.dm("Debug", string.format("%s Processed (%s) events: New Events (%s): Duplicate Events (%s)", guildName, numEvents, eventsAdded, duplicateEvents))

local totalRecordsInGuild = LibGuildHistoryCache.NonContiguousNonNilCount(LibGuildHistoryCache_SavedVariables[megaserver])

LibGuildHistoryCache.dm("Debug", string.format("Total %s Events for %s [%s] : (%s)", LibGuildHistoryCache.categoryText[eventCategory], guildName, guildId, totalRecordsInGuild))
  ]]--
end

local function OnGuildHistoryEvent(eventCode, guildId, eventCategory, flags)
  if (eventCode ~= EVENT_GUILD_HISTORY_CATEGORY_UPDATED) then
    return
  end
  ProcessCategoryUpdate(eventCode, guildId, eventCategory, flags)
end
-- EVENT_MANAGER:RegisterForEvent(LibGuildStore.libName, EVENT_GUILD_HISTORY_CATEGORY_UPDATED, OnGuildHistoryEvent)
