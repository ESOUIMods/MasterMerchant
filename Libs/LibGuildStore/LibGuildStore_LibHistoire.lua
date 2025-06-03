local LGH = LibHistoire
local ASYNC = LibAsync
local internal = _G["LibGuildStore_Internal"]
local sales_data = _G["LibGuildStore_SalesData"]

--[[ cannot use MasterMerchant.itemsViewSize for example
because that will not be available this early.
]]--
local ITEMS = 'items_vs'
local GUILDS = 'guild_vs'

local function ConvertToDateTime(timestamp)
  local function GetTimeOfDayFromTimestamp_HM(ts)
    local timeString = os.date("%H:%M", ts)
    return timeString
  end
  local dateString = GetDateStringFromTimestamp(timestamp)
  local timeOfDay = GetTimeOfDayFromTimestamp_HM(timestamp)
  return string.format("%s, %s", dateString, timeOfDay)
end

function internal:CollectAndSortGuildHistoryRanges(guildId)
  local guildName = GetGuildName(guildId)
  internal:dm("Info", string.format("[CollectAndSortGuildHistoryRanges]: for guild ID: %d (%s).", guildId, guildName))
  local category = GUILD_HISTORY_EVENT_CATEGORY_TRADER
  local numRanges = GetNumGuildHistoryEventRanges(guildId, category)

  LibGuildStore_SavedVariables = LibGuildStore_SavedVariables or {}
  LibGuildStore_SavedVariables.newestTrackedTimestamp = LibGuildStore_SavedVariables.newestTrackedTimestamp or {}
  LibGuildStore_SavedVariables.oldestTrackedTimestamp = LibGuildStore_SavedVariables.oldestTrackedTimestamp or {}
  LibGuildStore_SavedVariables.newestTrackedEventID = LibGuildStore_SavedVariables.newestTrackedEventID or {}
  LibGuildStore_SavedVariables.oldestTrackedEventID = LibGuildStore_SavedVariables.oldestTrackedEventID or {}
  LibGuildStore_SavedVariables.trackedMidnightEventID = LibGuildStore_SavedVariables.trackedMidnightEventID or {}

  -- Initialize specific guildId entries if not already set
  LibGuildStore_SavedVariables.newestTrackedTimestamp[guildId] = LibGuildStore_SavedVariables.newestTrackedTimestamp[guildId] or 0
  LibGuildStore_SavedVariables.oldestTrackedTimestamp[guildId] = LibGuildStore_SavedVariables.oldestTrackedTimestamp[guildId] or 0
  LibGuildStore_SavedVariables.newestTrackedEventID[guildId] = LibGuildStore_SavedVariables.newestTrackedEventID[guildId] or 0
  LibGuildStore_SavedVariables.oldestTrackedEventID[guildId] = LibGuildStore_SavedVariables.oldestTrackedEventID[guildId] or 0
  LibGuildStore_SavedVariables.trackedMidnightEventID[guildId] = LibGuildStore_SavedVariables.trackedMidnightEventID[guildId] or 0

  if numRanges == 0 then
    -- Set tracking variables to defaults for the specific guild
    LibGuildStore_SavedVariables.newestTrackedTimestamp[guildId] = GetTimeStamp()
    LibGuildStore_SavedVariables.oldestTrackedTimestamp[guildId] = GetTimeStamp()
    LibGuildStore_SavedVariables.newestTrackedEventID[guildId] = 0
    LibGuildStore_SavedVariables.oldestTrackedEventID[guildId] = 0
    LibGuildStore_SavedVariables.trackedMidnightEventID[guildId] = 0

    internal:dm("Warn", string.format("[CollectAndSortGuildHistoryRanges]: No ranges found for guild ID: %d (%s). Tracking variables set to defaults.", guildId, guildName))
    return
  end

  -- Collect ranges into a table
  local rangeData = {}
  for i = 1, numRanges do
    local newestTimestamp, oldestTimestamp, newestEventId, oldestEventId = GetGuildHistoryEventRangeInfo(guildId, category, i)
    table.insert(rangeData, {
      newestTimestamp = newestTimestamp,
      oldestTimestamp = oldestTimestamp,
      newestEventId = newestEventId,
      oldestEventId = oldestEventId,
    })
  end

  -- Sort the table by newestTimestamp (descending order)
  table.sort(rangeData, function(a, b)
    return a.newestTimestamp > b.newestTimestamp
  end)

  -- Debug sorted ranges
  for index, data in ipairs(rangeData) do
    internal:dm("Debug", string.format("[SortedRange]: Index %d, Newest Time = %s, Oldest Time = %s, Newest Event ID = %d, Oldest Event ID = %d for guild ID: %d (%s).",
      index,
      ConvertToDateTime(data.newestTimestamp),
      ConvertToDateTime(data.oldestTimestamp),
      data.newestEventId,
      data.oldestEventId,
      guildId,
      guildName))
  end

  -- Update tracking variables for the specific guild
  local newestEntry = rangeData[1]
  local oldestEntry = rangeData[#rangeData]

  LibGuildStore_SavedVariables.newestTrackedTimestamp[guildId] = newestEntry.newestTimestamp
  LibGuildStore_SavedVariables.oldestTrackedTimestamp[guildId] = oldestEntry.oldestTimestamp
  LibGuildStore_SavedVariables.newestTrackedEventID[guildId] = newestEntry.newestEventId
  LibGuildStore_SavedVariables.oldestTrackedEventID[guildId] = oldestEntry.oldestEventId

  internal:dm("Debug", string.format("[UpdatedTracking]: Newest Timestamp = %s, Oldest Timestamp = %s, Newest Event ID = %d, Oldest Event ID = %d for guild ID: %d (%s).",
    ConvertToDateTime(newestEntry.newestTimestamp),
    ConvertToDateTime(oldestEntry.oldestTimestamp),
    newestEntry.newestEventId,
    oldestEntry.oldestEventId,
    guildId,
    guildName))

  local midnightToday = GetTimeStamp() - GetSecondsSinceMidnight()
  local startTime = midnightToday - ZO_ONE_HOUR_IN_SECONDS
  local endTime = midnightToday + ZO_ONE_HOUR_IN_SECONDS

  -- Get event indices for the specified time range
  local newestEventIndex = GetGuildHistoryEventIndicesForTimeRange(guildId, category, endTime, startTime)

  -- Check and process the indices
  if newestEventIndex then
    local locatedEventId = GetGuildHistoryEventId(guildId, category, newestEventIndex)
    local locatedTimestamp = GetGuildHistoryEventTimestamp(guildId, category, newestEventIndex)

    -- Update tracking variables with meaningful names
    LibGuildStore_SavedVariables.trackedMidnightEventID = LibGuildStore_SavedVariables.trackedMidnightEventID or {}
    LibGuildStore_SavedVariables.trackedMidnightEventID[guildId] = LibGuildStore_SavedVariables.trackedMidnightEventID[guildId] or 0
    LibGuildStore_SavedVariables.trackedMidnightEventID[guildId] = locatedEventId or 0

    internal:dm("Debug", "[CollectAndSortGuildHistoryRanges]: (<<1>>) Midnight Event Event ID = <<2>> for guild ID: <<3>> (<<4>>).",
      ConvertToDateTime(locatedTimestamp),
      tostring(locatedEventId),
      guildId,
      guildName
    )
  else
    internal:dm("Warn", string.format(
      "[CollectAndSortGuildHistoryRanges]: No events found in the midnight time range for guild ID: %d (%s).",
      guildId,
      guildName
    ))
    LibGuildStore_SavedVariables.trackedMidnightEventID[guildId] = 0
  end
end

function internal:SetupLibHistoireContainers()
  internal:dm("Debug", "SetupLibHistoireContainers")
  for i = 1, GetNumGuilds() do
    local guildId = GetGuildId(i)
    internal.LibHistoireListener[guildId] = {}
  end
end

function internal:SetupGuildHistoryListener(guildId)
  local guildName = GetGuildName(guildId)
  internal:dm("Info", string.format("[SetupGuildHistoryListener]: for guild ID: %d (%s).", guildId, guildName))

  if not internal.LibHistoireListener then
    internal.LibHistoireListener = {}
  end

  -- Create the Guild History Processor
  internal.LibHistoireListener[guildId] = LGH:CreateGuildHistoryProcessor(guildId, GUILD_HISTORY_STORE, LibGuildStore.libName)

  if not internal.LibHistoireListener[guildId] then
    internal:dm("Warn", "Failed to create GuildHistoryProcessor for guildId: " .. tostring(guildId))
    return
  end

  -- Mark the listener as ready
  internal.LibHistoireListenerReady[guildId] = true
end

function internal:SetupListenerLibHistoire()
  internal:dm("Debug", "Setup Listeners for LibHistoire")
  for guildIndex = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildIndex)
    internal.LibHistoireListener[guildId] = {}
    internal:SetupGuildHistoryListener(guildId)
  end
end

function internal:SetupNewestOldestTimestampAndEvent()
  internal:dm("Debug", "SetupNewestOldestTimestampAndEvent")
  for guildIndex = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildIndex)
    internal:CollectAndSortGuildHistoryRanges(guildId)
  end
end

function internal:SetupRefreshRoutine()
  internal:dm("Debug", "SetupNewestOldestTimestampAndEvent")
  for guildIndex = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildIndex)
    internal:SetupIteratingTimeRange(guildId)
  end
end

function internal:SetupListeners()
  internal:dm("Debug", "SetupNewestOldestTimestampAndEvent")
  for guildIndex = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildIndex)
    internal:SetupListener(guildId)
  end
end

-- /script LibGuildStore_Internal:SetupGuildHistoryListener(guildId)
function internal:SetupIteratingTimeRange(guildId)
  local guildName = GetGuildName(guildId)
  internal:dm("Info", string.format("[SetupIteratingTimeRange]: for guild ID: %d (%s).", guildId, GetGuildName(guildId)))

  local midnightToday = GetTimeStamp() - GetSecondsSinceMidnight()
  local startTimestamp = LibGuildStore_SavedVariables.oldestTrackedTimestamp[guildId]

  -- Fallback to midnight today if startTimestamp is nil or 0
  if not startTimestamp or startTimestamp == 0 then
    internal:dm("Warn", string.format("[SetupIteratingTimeRange]: startTimestamp is nil or 0, falling back to midnightToday for guild ID: %d (%s).", guildId, GetGuildName(guildId)))
    startTimestamp = midnightToday
  end

  -- Use current time as end time
  local endTime = GetTimeStamp()

  -- Start iterating time range
  local iteratingStarted = internal.LibHistoireListener[guildId]:StartIteratingTimeRange(startTimestamp, endTime, function(event)
    -- Callback for processing each event
    local eventInfo = event:GetEventInfo()
    local eventType = event:GetEventType()
    if eventType == GUILD_HISTORY_TRADER_EVENT_ITEM_SOLD then
      local guildName = GetGuildName(guildId)
      local theEvent = {
        buyer = eventInfo.buyerDisplayName,
        guild = guildName,
        itemLink = eventInfo.itemLink,
        quant = eventInfo.quantity,
        timestamp = eventInfo.timestampS,
        price = eventInfo.price,
        seller = eventInfo.sellerDisplayName,
        wasKiosk = false,
        id = eventInfo.eventId,
      }
      theEvent.wasKiosk = (internal.guildMemberInfo[guildId][zo_strlower(theEvent.buyer)] == nil)

      local thePlayer = zo_strlower(GetDisplayName())
      local isSelfSale = zo_strlower(theEvent.seller) == thePlayer
      local added = false
      local daysOfHistoryToKeep = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * LibGuildStore_SavedVariables["historyDepth"])
      if (theEvent.timestamp > daysOfHistoryToKeep) then
        local duplicate = internal:CheckForDuplicateSale(theEvent.itemLink, theEvent.id)
        if not duplicate then
          added = internal:addSalesData(theEvent)
        end
        if added and isSelfSale then
          internal:UpdateAlertQueue(guildName, theEvent)
        end
        if added then
          MasterMerchant:PostScanParallel(guildName)
        end
      end

    end
  end, function(reason)
    -- Callback for when iteration stops
    internal:dm("Debug", string.format("[StartIteratingTimeRange]: Iteration stopped. Reason: %s for guild ID: %d (%s).", reason, guildId, GetGuildName(guildId)))
  end)

  -- Log success or failure of starting iteration
  if iteratingStarted then
    internal:dm("Debug", string.format("[StartIteratingTimeRange]: initiated successfully for guild ID: %d (%s).", guildId, GetGuildName(guildId)))
  else
    internal:dm("Warn", string.format("[StartIteratingTimeRange]: failed to start for guild ID: %d (%s).", guildId, GetGuildName(guildId)))
  end

  -- Start the listener
  internal.LibHistoireListener[guildId]:Start()
  internal:dm("Debug", string.format("[SetupIteratingTimeRange]: Listener started for guild ID: %d (%s).", guildId, GetGuildName(guildId)))
end


-- /script LibGuildStore_Internal.LibHistoireListener[guildId]:SetAfterEventId(StringToId64("0"))
function internal:SetupListener(guildId)
  internal:dm("Info", string.format("[SetupListener]: for guild ID: %d (%s)", guildId, GetGuildName(guildId)))

  if internal.LibHistoireListener[guildId] == nil then
    internal:dm("Warn", string.format("LibHistoire listener is nil for guild ID: %d (%s). Exiting setup.", guildId, GetGuildName(guildId)))
    return
  end

  -- Use tracking variables for listener setup
  -- local startTimestamp = LibGuildStore_SavedVariables.newestTrackedTimestamp[guildId]
  -- local startEventID = LibGuildStore_SavedVariables.newestTrackedEventID[guildId]
  local midnightToday = GetTimeStamp() - GetSecondsSinceMidnight()
  local startTimestamp = midnightToday - (ZO_ONE_DAY_IN_SECONDS * 4)
  -- internal.LibHistoireListener[guildId]:SetAfterEventTime(midnightToday)

  internal.LibHistoireListener[guildId]:SetStopOnLastCachedEvent(false)

  internal.LibHistoireListener[guildId]:SetReceiveMissedEventsOutsideIterationRange(true)
  internal:dm("Debug", string.format("Set to receive missed events outside iteration range for guild ID: %d (%s).", guildId, GetGuildName(guildId)))
  --[[
    internal.LibHistoireListener[guildId]:SetNextEventCallback(function(event)
    local eventInfo = event:GetEventInfo()
    local eventType = event:GetEventType()
    if eventType == GUILD_HISTORY_TRADER_EVENT_ITEM_SOLD then
      local guildName = GetGuildName(guildId)
      local theEvent = {
      buyer = eventInfo.buyerDisplayName,
      guild = guildName,
      itemLink = eventInfo.itemLink,
      quant = eventInfo.quantity,
      timestamp = eventInfo.timestampS,
      price = eventInfo.price,
      seller = eventInfo.sellerDisplayName,
      wasKiosk = false,
      id = eventInfo.eventId,
      }
      theEvent.wasKiosk = (internal.guildMemberInfo[guildId][zo_strlower(theEvent.buyer)] == nil)

      local thePlayer = zo_strlower(GetDisplayName())
      local isSelfSale = zo_strlower(theEvent.seller) == thePlayer
      local added = false
      local daysOfHistoryToKeep = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * LibGuildStore_SavedVariables["historyDepth"])
      if (theEvent.timestamp > daysOfHistoryToKeep) then
      local duplicate = internal:CheckForDuplicateSale(theEvent.itemLink, theEvent.id)
      if not duplicate then
        added = internal:addSalesData(theEvent)
      end
      if added and isSelfSale then
        internal:UpdateAlertQueue(guildName, theEvent)
      end
      if added then
        MasterMerchant:PostScanParallel(guildName)
      end
      end

    end
    end)
  ]]--
  internal.LibHistoireListener[guildId]:SetMissedEventCallback(function(event)
    local eventInfo = event:GetEventInfo()
    local eventType = event:GetEventType()
    if eventType == GUILD_HISTORY_TRADER_EVENT_ITEM_SOLD then
      local guildName = GetGuildName(guildId)
      local theEvent = {
        buyer = eventInfo.buyerDisplayName,
        guild = guildName,
        itemLink = eventInfo.itemLink,
        quant = eventInfo.quantity,
        timestamp = eventInfo.timestampS,
        price = eventInfo.price,
        seller = eventInfo.sellerDisplayName,
        wasKiosk = false,
        id = eventInfo.eventId,
      }
      theEvent.wasKiosk = (internal.guildMemberInfo[guildId][zo_strlower(theEvent.buyer)] == nil)

      local thePlayer = zo_strlower(GetDisplayName())
      local isSelfSale = zo_strlower(theEvent.seller) == thePlayer
      local added = false
      local daysOfHistoryToKeep = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * LibGuildStore_SavedVariables["historyDepth"])
      if (theEvent.timestamp > daysOfHistoryToKeep) then
        local duplicate = internal:CheckForDuplicateSale(theEvent.itemLink, theEvent.id)
        if not duplicate then
          added = internal:addSalesData(theEvent)
        end
        if added and isSelfSale then
          internal:UpdateAlertQueue(guildName, theEvent)
        end
        if added then
          MasterMerchant:PostScanParallel(guildName)
        end
      end

    end
  end)

  --[[
  local registeredForFutureEvents = internal.LibHistoireListener[guildId]:SetRegisteredForFutureEventsCallback(function()
    internal:dm("Debug", string.format("[SetRegisteredForFutureEventsCallback]: for guild ID: %d (%s).", guildId, GetGuildName(guildId)))
  end)

  if registeredForFutureEvents then
    -- internal:dm("Debug", string.format("[SetRegisteredForFutureEventsCallback]: initiated successfully for guild ID: %d (%s).", guildId, GetGuildName(guildId)))
  else
    internal:dm("Warn", string.format("[SetRegisteredForFutureEventsCallback]: failed to start for guild ID: %d (%s).", guildId, GetGuildName(guildId)))
  end
  ]]--

  --[[
  internal.LibHistoireListener[guildId]:SetStopOnLastCachedEvent(true)
  internal:dm("Debug", string.format("Stop on last cached event set to true for guild ID: %d (%s).", guildId, guildName))
  internal.LibHistoireListener[guildId]:SetOnStopCallback(function()
    internal:dm("Warn", string.format("[SetOnStopCallback]: for guild ID: %d (%s).", guildId, guildName))
    internal:dm("Debug", string.format("[SetOnStopCallback]: Pretend we did something."))
    internal.LibHistoireListener[guildId]:Start()
    internal:dm("Debug", string.format("[SetOnStopCallback]: Started Listener."))
  end)
  ]]--

  local startEventID = LibGuildStore_SavedVariables.trackedMidnightEventID[guildId]
  local streamingStarted = internal.LibHistoireListener[guildId]:StartStreaming(startEventID, function(event)
    local eventInfo = event:GetEventInfo()
    local eventType = event:GetEventType()
    if eventType == GUILD_HISTORY_TRADER_EVENT_ITEM_SOLD then
      local guildName = GetGuildName(guildId)
      local theEvent = {
        buyer = eventInfo.buyerDisplayName,
        guild = guildName,
        itemLink = eventInfo.itemLink,
        quant = eventInfo.quantity,
        timestamp = eventInfo.timestampS,
        price = eventInfo.price,
        seller = eventInfo.sellerDisplayName,
        wasKiosk = false,
        id = eventInfo.eventId,
      }
      theEvent.wasKiosk = (internal.guildMemberInfo[guildId][zo_strlower(theEvent.buyer)] == nil)

      local thePlayer = zo_strlower(GetDisplayName())
      local isSelfSale = zo_strlower(theEvent.seller) == thePlayer
      local added = false
      local daysOfHistoryToKeep = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * LibGuildStore_SavedVariables["historyDepth"])
      if (theEvent.timestamp > daysOfHistoryToKeep) then
        local duplicate = internal:CheckForDuplicateSale(theEvent.itemLink, theEvent.id)
        if not duplicate then
          added = internal:addSalesData(theEvent)
        end
        if added and isSelfSale then
          internal:UpdateAlertQueue(guildName, theEvent)
        end
        if added then
          MasterMerchant:PostScanParallel(guildName)
        end
      end

    end
  end)

  --[[
  if streamingStarted then
    internal:dm("Debug", string.format("[StartStreaming]: initiated successfully for guild ID: %d (%s).", guildId, GetGuildName(guildId)))
  else
    internal:dm("Warn", string.format("[StartStreaming]: failed to start for guild ID: %d (%s).", guildId, GetGuildName(guildId)))
  end
  ]]--

  --[[
  internal.LibHistoireListener[guildId]:SetStopOnLastCachedEvent(true)
  internal:dm("Debug", string.format("Stop on last cached event set to true for guild ID: %d (%s).", guildId, guildName))
  internal.LibHistoireListener[guildId]:SetOnStopCallback(function()
    internal:dm("Debug", string.format("[SetOnStopCallback]: for guild ID: %d (%s).", guildId, guildName))
  end)

  internal:dm("Debug", string.format(
    "For guild ID: %d (%s), starting with trackedTimestamp: %s (%s, %s), trackedEventID: %s",
    guildId,
    guildName,
    tostring(startTimestamp),
    GetDateStringFromTimestamp(startTimestamp),
    ConvertToDateTime(startTimestamp),
    tostring(startEventID)
  ))

  -- Set the start condition using timestamp or event ID
  if startTimestamp and startTimestamp > 0 then
    internal:dm("Debug", string.format("Listener set to use SetAfterEventTime with timestamp: %s (%s, %s) for guild ID: %d (%s).",
    tostring(startTimestamp),
    GetDateStringFromTimestamp(startTimestamp),
    ConvertToDateTime(startTimestamp),
    guildId, guildName))
  elseif startEventID and startEventID > 0 then
    internal:dm("Debug", string.format("Listener set to use SetAfterEventId with event ID: %s for guild ID: %d (%s).", tostring(startEventID), guildId, guildName))
    internal.LibHistoireListener[guildId]:SetAfterEventId(startEventID)
  else
    internal:dm("Warn", string.format("No valid start conditions found for guild ID: %d (%s).", guildId, guildName))
    return
  end

  -- Set stop on last cached event
  internal.LibHistoireListener[guildId]:SetStopOnLastCachedEvent(false)
  internal:dm("Debug", string.format("Stop on last cached event set to false for guild ID: %d (%s).", guildId, guildName))

  -- Set registered for future events callback

  -- Set to receive missed events outside the iteration range

  -- Debug for GetPendingEventMetrics
  local numEvents, processingSpeed, timeLeft = internal.LibHistoireListener[guildId]:GetPendingEventMetrics()
  internal:dm("Debug", string.format("Pending event metrics: Events Remaining = %d, Processing Speed = %d, Time Left = %d for guild ID: %d (%s).",
    numEvents,
    processingSpeed,
    timeLeft,
    guildId, guildName))

  -- Use StartStreaming
  local streamingStarted = internal.LibHistoireListener[guildId]:StartStreaming(startEventID, function(event)
    local eventInfo = event:GetEventInfo()
    internal:dm("Debug", string.format("[StartStreaming]: ID = %s, Timestamp = %s (%s, %s) for guild ID: %d (%s).",
    eventInfo.eventId,
    tostring(eventInfo.timestampS),
    GetDateStringFromTimestamp(eventInfo.timestampS),
    ConvertToDateTime(eventInfo.timestampS),
    guildId, guildName))
  end)

  if streamingStarted then
    internal:dm("Debug", string.format("[StartStreaming]: initiated successfully for guild ID: %d (%s).", guildId, guildName))
  else
    internal:dm("Warn", string.format("[StartStreaming]: failed to start for guild ID: %d (%s).", guildId, guildName))
  end
  ]]--
  -- Finally start the listener
  internal.LibHistoireListener[guildId]:Start()
  internal:dm("Debug", string.format("Listener started for guild ID: %d (%s).", guildId, GetGuildName(guildId)))
end

-------------------------
----- Refresh Queue
-------------------------

--/script LibGuildStore_Internal:dm("Info", LibGuildStore_Internal.LibHistoireListener[622389]:GetPendingEventMetrics())
function internal:OldCheckStatus()
  --internal:dm("Debug", "CheckStatus")
  local maxTime = 0
  local maxEvents = 0

  for guildNum = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildNum)
    local guildName = GetGuildName(guildId)
    local numEvents = GetNumGuildHistoryEvents(guildId, GUILD_HISTORY_EVENT_CATEGORY_TRADER)
    local eventCount, processingSpeed, timeLeft = internal.LibHistoireListener[guildId]:GetPendingEventMetrics()

    timeLeft = zo_floor(timeLeft)

    if (processingSpeed > 0 and timeLeft >= 0) and not internal.timeEstimated[guildId] then
      internal.timeEstimated[guildId] = true
    end

    -- Handle the case when numEvents is 0 and eventCount is 1 (inconsistent but no events)
    -- Handle the case when numEvents is greater then 0, eventCount is 0, and timeLeft is 0
    -- Example: numEvents: 0 eventCount: 1 processingSpeed: -1 timeLeft: -1
    -- Example: numEvents: 5 eventCount: 0 processingSpeed: -1 timeLeft: 0
    if (numEvents == 0 or eventCount == 0) and (processingSpeed == -1 or timeLeft == -1) then
      internal.timeEstimated[guildId] = true
      internal.eventsNeedProcessing[guildId] = false
    end

    -- Handle the case when timeLeft or eventCount is 0 (process finished)
    if (eventCount == 0 or timeLeft == 0) and internal.timeEstimated[guildId] then
      internal.eventsNeedProcessing[guildId] = false
    end

    maxTime = zo_max(maxTime, timeLeft)
    maxEvents = zo_max(maxEvents, eventCount)
    if internal.eventsNeedProcessing[guildId] and MasterMerchant.systemSavedVariables.useLibDebugLogger then
      internal:dm("Debug", string.format("%s, %s: numEvents: %s eventCount: %s processingSpeed: %s timeLeft: %s", guildName, guildId, numEvents, eventCount, processingSpeed, timeLeft))
    end

  end
  for guildNum = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildNum)
    if internal.eventsNeedProcessing[guildId] then return true, maxTime, maxEvents end
  end
  return false, maxTime, maxEvents
end

function internal:OldQueueCheckStatus()
  local eventsRemaining, timeRemaining, estimatedEvents = internal:CheckStatus()
  if eventsRemaining then
    zo_callLater(function() internal:QueueCheckStatus() end, ZO_ONE_MINUTE_IN_MILLISECONDS)
    internal:dm("Info", GetString(GS_REFRESH_NOT_FINISHED) .. string.format(GetString(GS_REFRESH_ESTIMATE), estimatedEvents, zo_ceil(timeRemaining / ZO_ONE_MINUTE_IN_SECONDS)))
  else
    --[[
    MasterMerchant.CenterScreenAnnounce_AddMessage(
      'LibHistoireAlert',
      CSA_CATEGORY_SMALL_TEXT,
      LibGuildStore.systemSavedVariables.alertSoundName,
      "LibHistoire Ready"
    )
    ]]--
    internal:dm("Info", GetString(GS_REFRESH_FINISHED))
    LibGuildStore_SavedVariables[internal.firstrunNamespace] = false
    LibGuildStore_SavedVariables.libHistoireScanByTimestamp = false
    internal:DatabaseBusy(false)
    MasterMerchant.listIsDirty[ITEMS] = true
    MasterMerchant.listIsDirty[GUILDS] = true
  end
end

function internal:OldQueueGuildHistoryListener(guildId, guildIndex)
  local multiplier = guildIndex or 1
  internal:SetupGuildHistoryListener(guildId)

  if not internal.LibHistoireListenerReady[guildId] then
    internal:dm("Debug", "LibHistoireListener not ready for guildId: " .. tostring(guildId))
    zo_callLater(function() internal:QueueGuildHistoryListener(guildId) end, (MM_WAIT_TIME_IN_MILLISECONDS_LIBHISTOIRE * multiplier))
  else
    zo_callLater(function() internal:SetupListener(guildId) end, (MM_WAIT_TIME_IN_MILLISECONDS_LIBHISTOIRE_SETUP * multiplier))
  end
end

function internal:OldStartQueue()
  internal:dm("Debug", "StartQueue")
  internal:DatabaseBusy(true)
  zo_callLater(function() internal:QueueCheckStatus() end, ZO_ONE_MINUTE_IN_MILLISECONDS)
end

-- DEBUG RefreshLibGuildStore
function internal:OldRefreshLibGuildStore()
  internal:dm("Debug", "RefreshLibGuildStore")
  internal:dm("Info", GetString(GS_REFRESH_STARTING))
  internal:DatabaseBusy(true)
  LibGuildStore_SavedVariables.libHistoireScanByTimestamp = true
  for guildNum = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildNum)
    internal.LibHistoireListener[guildId]:Stop()
    internal.eventsNeedProcessing[guildId] = true
    internal.timeEstimated[guildId] = false
  end
end

----------------------------------------
-----   ConvertLegacyId64ToId53    -----
----------------------------------------

function internal:ConvertStringToId64ToEventId(inputString)
  local id64 = StringToId64(inputString)
  local id64Toid53, id64PrecisionLost = Id64ToNumber(id64)
  if not id64Toid53 or id64PrecisionLost then return end
  return id64Toid53
end

function internal:ConvertLegacyEventIds()
  -- Check if conversion is necessary
  if LibGuildStore_SavedVariables.convertLegacyId64Completed then
    internal:dm("Info", "Conversion of legacy id64 to id53 has already been completed. Skipping.")
    internal:FireCallbackProcessLibGuildstoreData()
    return
  end

  local allTables = {
    GS00DataSavedVariables = GS00DataSavedVariables,
    GS01DataSavedVariables = GS01DataSavedVariables,
    GS02DataSavedVariables = GS02DataSavedVariables,
    GS03DataSavedVariables = GS03DataSavedVariables,
    GS04DataSavedVariables = GS04DataSavedVariables,
    GS05DataSavedVariables = GS05DataSavedVariables,
    GS06DataSavedVariables = GS06DataSavedVariables,
    GS07DataSavedVariables = GS07DataSavedVariables,
    GS08DataSavedVariables = GS08DataSavedVariables,
    GS09DataSavedVariables = GS09DataSavedVariables,
    GS10DataSavedVariables = GS10DataSavedVariables,
    GS11DataSavedVariables = GS11DataSavedVariables,
    GS12DataSavedVariables = GS12DataSavedVariables,
    GS13DataSavedVariables = GS13DataSavedVariables,
    GS14DataSavedVariables = GS14DataSavedVariables,
    GS15DataSavedVariables = GS15DataSavedVariables,
  }

  local task = ASYNC:Create("ConvertLegacyEventIds")
  local start = GetTimeStamp()
  local count = 0
  local alreadyConverted = 0

  task:Call(function()
    internal:dm("Info", "Converting legacy id64 to id53 format across all data tables.")
  end)

  -- Loop through all tables
  task:For(pairs(allTables)):Do(function(tableName, tableData)
    internal:dm("Info", string.format("Procesing (%s)...", tableName))
    local savedVars = tableData[internal.dataNamespace]
    if savedVars then
      -- Iterate through sales data and convert id64 to id53
      task:For(pairs(savedVars)):Do(function(itemId, versionList)
        task:For(pairs(versionList)):Do(function(versionId, versionData)
          if next(versionData['sales']) then
            task:For(pairs(versionData['sales'])):Do(function(saleId, salesData)
              -- Check if the ID is a string before converting
              if type(salesData.id) == "string" then
                local newId53 = internal:ConvertStringToId64ToEventId(salesData.id)
                if newId53 then
                  salesData.id = newId53
                  count = count + 1
                else
                end
              else
                alreadyConverted = alreadyConverted + 1
              end
            end)
          end
        end)
      end)
    end
  end)

  -- Final debug message
  task:Then(function()
    local elapsedTime = GetTimeStamp() - start
    internal:dm("Info", string.format("Converted %d sales to id53 format. %d sales were already converted. Completed in %d seconds.", count, alreadyConverted, elapsedTime))
    -- Mark conversion as completed
    LibGuildStore_SavedVariables.convertLegacyId64Completed = true
  end)

  -- Fire callback at the end
  task:Finally(function()
    internal:FireCallbackProcessLibGuildstoreData()
  end)
end

----------------------------------------
-----    Refresh LibGuildStore     -----
----------------------------------------

local function AddAtIfNeeded(str)
  if string.sub(str, 1, 1) ~= "@" then
    str = "@" .. str
  end
  return str
end

-- /script LibGuildStore_Internal:TestRefresh()
function internal:TestRefresh()
  local function CheckForDuplicateSale(itemLink, eventID)
    --[[ we need to be able to calculate theIID and itemIndex
    when not used with addToHistoryTables() event though
    the function will calculate them.
    ]]--
    local theIID = GetItemLinkItemId(itemLink)
    if theIID == nil or theIID == 0 then return end
    local itemIndex = internal.GetOrCreateIndexFromLink(itemLink)

    if sales_data[theIID] and sales_data[theIID][itemIndex] then
      for _, v in pairs(sales_data[theIID][itemIndex]['sales']) do
        if type(v.id) == "string" or v.id == eventID then
          return true
        end
      end
    end
    return false
  end

  local numEventsTrader = {}
  local hasEventsTrader = {}
  local eventRangesTrader = {}
  local eventsLinkedTrader = {}
  local eventsLinked = true
  local numGuilds = GetNumGuilds()
  local daysOfHistoryToKeep = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * LibGuildStore_SavedVariables["historyDepth"])

  -- Set up event ranges and linkage checks
  for guildNum = 1, numGuilds do
    local guildId = GetGuildId(guildNum)
    numEventsTrader[guildId] = GetNumGuildHistoryEvents(guildId, GUILD_HISTORY_EVENT_CATEGORY_TRADER)
    hasEventsTrader[guildId] = numEventsTrader[guildId] >= 1
    eventRangesTrader[guildId] = GetNumGuildHistoryEventRanges(guildId, GUILD_HISTORY_EVENT_CATEGORY_TRADER)
    eventsLinkedTrader[guildId] = hasEventsTrader[guildId] and eventRangesTrader[guildId] == 1
    if not eventRangesTrader[guildId] == 1 then eventsLinked = false end
  end

  if not eventsLinked then
    internal:dm("Info", GetString(GS_EVENTS_NOT_LINKED))
    return
  end

  local task = ASYNC:Create("TestRefresh")
  task:Call(function() internal:dm("Info", GetString(GS_REFRESH_STARTING)) end)
  task:Then(function() internal:DatabaseBusy(true) end)

  task:For(1, numGuilds):Do(function(guildNum)
    local guildId = GetGuildId(guildNum)
    local guildName = GetGuildName(guildId)
    if eventsLinkedTrader[guildId] then
      --internal:dm("Debug", "Could Process Roster: " .. tostring(guildId) .. " : " .. GetGuildName(guildId))
      --internal:dm("Debug", "Num Events Roster: " .. tostring(numEventsTrader[guildId]) .. " : " .. GetGuildName(guildId))
      local endIndex = numEventsTrader[guildId]
      local oneEventRange = GetNumGuildHistoryEventRanges(guildId, GUILD_HISTORY_EVENT_CATEGORY_TRADER) == 1

      task:For(1, endIndex):Do(function(eventIndex)
        local eventId, timestampS, isRedacted, eventType, sellerDisplayName, buyerDisplayName, itemLink, quantity, price, tax = GetGuildHistoryTraderEventInfo(guildId, eventIndex)

        if eventType == GUILD_HISTORY_TRADER_EVENT_ITEM_SOLD then
          sellerDisplayName = AddAtIfNeeded(sellerDisplayName)
          buyerDisplayName = AddAtIfNeeded(buyerDisplayName)
          local theEvent = {
            buyer = buyerDisplayName,
            guild = guildName,
            itemLink = itemLink,
            quant = quantity,
            timestamp = timestampS,
            price = price,
            seller = sellerDisplayName,
            wasKiosk = false,
            id = eventId,
          }
          theEvent.wasKiosk = (internal.guildMemberInfo[guildId][zo_strlower(theEvent.buyer)] == nil)

          local duplicate = CheckForDuplicateSale(theEvent.itemLink, theEvent.id)
          if theEvent.timestamp > daysOfHistoryToKeep and not duplicate then
            task:Call(function()
              local added = internal:addSalesData(theEvent)
              if added then
                if zo_strlower(theEvent.seller) == zo_strlower(GetDisplayName()) then
                  internal:UpdateAlertQueue(guildName, theEvent)
                end
                MasterMerchant:PostScanParallel(guildName)
              end
            end)
          end
        end
      end)
    end
  end)

  task:Then(function()
    internal:dm("Info", GetString(GS_REFRESH_FINISHED))
    internal:DatabaseBusy(false)
  end)
  task:Finally(function() ReloadUI() end)

end

-- LibGuildStore_Internal.LibHistoireListener[57409]:IsRunning()
LGH:RegisterCallback(LGH.callback.INITIALIZED, function()
  LGH:RegisterCallback(LGH.callback.MANAGED_RANGE_FOUND, function(guildId, category)
    if not internal.LibHistoireListenerReady[guildId] then return end
    if not internal.LibHistoireListener[guildId]:IsRunning() then
      internal:dm("Debug", "Linked Range Callback for: " .. tostring(guildId))
      internal:SetupListener(guildId)
    end
  end)
end)
