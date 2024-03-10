local LGH = LibHistoire
local internal = _G["LibGuildStore_Internal"]

--[[ cannot use MasterMerchant.itemsViewSize for example
because that will not be available this early.
]]--
local ITEMS = 'items_vs'
local GUILDS = 'guild_vs'

function internal:SetupLibHistoireContainers()
  internal:dm("Debug", "SetupLibHistoireContainers")
  for i = 1, GetNumGuilds() do
    local guildId = GetGuildId(i)
    internal.LibHistoireListener[guildId] = {}
  end
end

function internal:SetupListenerLibHistoire()
  internal:dm("Debug", "SetupListenerLibHistoire")
  for guildIndex = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildIndex)
    internal.LibHistoireListener[guildId] = {}
    internal:QueueGuildHistoryListener(guildId, guildIndex)
  end
  if LibGuildStore_SavedVariables[internal.firstrunNamespace] then
    internal:StartQueue()
  end
end

-- /script LibGuildStore_Internal:SetupGuildHistoryListener(guildId)
function internal:SetupGuildHistoryListener(guildId)
  --internal:dm("Debug", "SetupGuildHistoryListener: " .. guildId)
  if internal.LibHistoireListener == nil then internal.LibHistoireListener = { } end
  if internal.LibHistoireListener[guildId] == nil then internal.LibHistoireListener[guildId] = { } end

  internal.LibHistoireListener[guildId] = LGH:CreateGuildHistoryListener(guildId, GUILD_HISTORY_STORE)
  if internal.LibHistoireListener[guildId] == nil then
    --internal:dm("Warn", "The Listener was nil")
  elseif internal.LibHistoireListener[guildId] ~= nil then
    --internal:dm("Debug", "The Listener was not nil, Listener ready.")
    internal.LibHistoireListenerReady[guildId] = true
  end
end

-- /script LibGuildStore_Internal.LibHistoireListener[guildId]:SetAfterEventId(StringToId64("0"))
function internal:SetupListener(guildId)
  internal:dm("Debug", "SetupListener: " .. guildId)
  --internal:SetupGuildHistoryListener(guildId)
  local lastReceivedEventID
  if internal.LibHistoireListener[guildId] == nil then
    internal:dm("Warn", "The Listener was still nil somehow")
    return
  end

  if LibGuildStore_SavedVariables.libHistoireScanByTimestamp then
    local setAfterTimestamp = GetTimeStamp() - ((LibGuildStore_SavedVariables.historyDepth + 1) * ZO_ONE_DAY_IN_SECONDS)
    internal.LibHistoireListener[guildId]:SetAfterEventTime(setAfterTimestamp)
  else
    if LibGuildStore_SavedVariables["lastReceivedEventID"][internal.libHistoireNamespace][guildId] then
      --internal:dm("Info", string.format("internal Saved Var: %s, guildId: (%s)", LibGuildStore_SavedVariables["lastReceivedEventID"][internal.libHistoireNamespace][guildId], guildId))
      lastReceivedEventID = StringToId64(LibGuildStore_SavedVariables["lastReceivedEventID"][internal.libHistoireNamespace][guildId])
      --internal:dm("Info", string.format("lastReceivedEventID set to: %s", lastReceivedEventID))
      internal.LibHistoireListener[guildId]:SetAfterEventId(lastReceivedEventID)
    end
  end
  internal.LibHistoireListener[guildId]:SetEventCallback(function(eventType, eventId, eventTime, p1, p2, p3, p4, p5, p6)
    --internal:dm("Info", "SetEventCallback")
    --[[
    local theEvent = {
      buyer = p2,
      guild = guildName,
      itemName = p4,
      quant = p3,
      saleTime = eventTime,
      salePrice = p5,
      seller = p1,
      kioskSale = false,
      id = Id64ToString(eventId)
    }
    local newSalesItem =
      {buyer = theEvent.buyer,
      guild = theEvent.guild,
      itemLink = theEvent.itemName,
      quant = tonumber(theEvent.quant),
      timestamp = tonumber(theEvent.saleTime),
      price = tonumber(theEvent.salePrice),
      seller = theEvent.seller,
      wasKiosk = theEvent.kioskSale,
      id = theEvent.id
    }
    [1] =
    {
      ["price"] = 120,
      ["itemLink"] = "|H0:item:45057:359:50:26848:359:50:0:0:0:0:0:0:0:0:0:5:0:0:0:0:0|h|h",
      ["id"] = 1353657539,
      ["guild"] = "Unstable Unicorns",
      ["buyer"] = "@Traeky",
      ["quant"] = 1,
      ["wasKiosk"] = true,
      ["timestamp"] = 1597969403,
      ["seller"] = "@cherrypick",
    },
    ]]--

    if eventType == GUILD_EVENT_ITEM_SOLD then
      if not lastReceivedEventID or CompareId64s(eventId, lastReceivedEventID) > 0 then
        LibGuildStore_SavedVariables["lastReceivedEventID"][internal.libHistoireNamespace][guildId] = Id64ToString(eventId)
        lastReceivedEventID = eventId
      end
      local guildName = GetGuildName(guildId)
      local theEvent = {
        buyer = p2,
        guild = guildName,
        itemLink = p4,
        quant = p3,
        timestamp = eventTime,
        price = p5,
        seller = p1,
        wasKiosk = false,
        id = Id64ToString(eventId)
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
  internal.LibHistoireListener[guildId]:Start()
end

-------------------------
----- Refresh Queue
-------------------------

--/script LibGuildStore_Internal:dm("Info", LibGuildStore_Internal.LibHistoireListener[622389]:GetPendingEventMetrics())
function internal:CheckStatus()
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

function internal:QueueCheckStatus()
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

function internal:QueueGuildHistoryListener(guildId, guildIndex)
  local multiplier = guildIndex
  if not guildIndex then multiplier = 1 end
  internal:SetupGuildHistoryListener(guildId)
  if not internal.LibHistoireListenerReady[guildId] then
    internal:dm("Debug", "LibHistoireListener not ready")
    zo_callLater(function() internal:QueueGuildHistoryListener(guildId) end, (MM_WAIT_TIME_IN_MILLISECONDS_LIBHISTOIRE * multiplier))
  else
    zo_callLater(function() internal:SetupListener(guildId) end, (MM_WAIT_TIME_IN_MILLISECONDS_LIBHISTOIRE_SETUP * multiplier))
  end
end

function internal:StartQueue()
  internal:dm("Debug", "StartQueue")
  internal:DatabaseBusy(true)
  zo_callLater(function() internal:QueueCheckStatus() end, ZO_ONE_MINUTE_IN_MILLISECONDS)
end

-- DEBUG RefreshLibGuildStore
function internal:RefreshLibGuildStore()
  internal:dm("Debug", "RefreshLibGuildStore")
  internal:dm("Info", GetString(GS_REFRESH_STARTING))
  internal:DatabaseBusy(true)
  LibGuildStore_SavedVariables.libHistoireScanByTimestamp = true
  for guildNum = 1, GetNumGuilds() do
    local guildId = GetGuildId(guildNum)
    internal.LibHistoireListener[guildId]:Stop()
    LibGuildStore_SavedVariables["lastReceivedEventID"][internal.libHistoireNamespace][guildId] = "0"
    internal.eventsNeedProcessing[guildId] = true
    internal.timeEstimated[guildId] = false
  end
end
