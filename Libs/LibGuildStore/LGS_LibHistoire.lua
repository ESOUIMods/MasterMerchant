local LGH = LibHistoire
local ASYNC = LibAsync
local internal = _G["LibGuildStore_Internal"]
local sales_data = _G["LibGuildStore_SalesData"]

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
  internal:dm("Debug", "SetupListener: " .. guildId .. " : " .. GetGuildName(guildId))
  if internal.LibHistoireListener[guildId] == nil then
    internal:dm("Warn", "The Listener was still nil somehow")
    return
  end
  local newestTimestamp = LibGuildStore_SavedVariables["newestTime"][guildId]
  local newestEventID = LibGuildStore_SavedVariables["lastReceivedEventID"][internal.libHistoireNamespace][guildId]
  if LibGuildStore_SavedVariables.libHistoireScanByTimestamp then
    newestTimestamp = GetTimeStamp() - ((LibGuildStore_SavedVariables.historyDepth + 1) * ZO_ONE_DAY_IN_SECONDS)
  end

  if newestTimestamp then
    --internal:dm("Debug", string.format("Newest Timestamp: %s, guildId: (%s)", newestTimestamp, guildId))
    internal.LibHistoireListener[guildId]:SetAfterEventTime(newestTimestamp)
  elseif newestEventID then
    local lastReceivedEventID = StringToId64(LibGuildStore_SavedVariables["lastReceivedEventID"][internal.libHistoireNamespace][guildId])
    --internal:dm("Debug", string.format("Last Received EventID: %s, guildId: (%s)", lastReceivedEventID, guildId))
    internal.LibHistoireListener[guildId]:SetAfterEventId(lastReceivedEventID)
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
      local guildName = GetGuildName(guildId)
      local convertedId = Id64ToString(eventId)
      local theEvent = {
        buyer = p2,
        guild = guildName,
        itemLink = p4,
        quant = p3,
        timestamp = eventTime,
        price = p5,
        seller = p1,
        wasKiosk = false,
        id = convertedId,
      }
      theEvent.wasKiosk = (internal.guildMemberInfo[guildId][zo_strlower(theEvent.buyer)] == nil)

      local oneEventRange = GetNumGuildHistoryEventRanges(guildId, GUILD_HISTORY_EVENT_CATEGORY_TRADER) == 1
      local timeStampInRange = not LibGuildStore_SavedVariables["newestTime"][guildId] or theEvent.timestamp > LibGuildStore_SavedVariables["newestTime"][guildId]
      if oneEventRange and timeStampInRange then
        LibGuildStore_SavedVariables["newestTime"][guildId] = theEvent.timestamp
        LibGuildStore_SavedVariables["lastReceivedEventID"][internal.libHistoireNamespace][guildId] = convertedId
      end

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
    LibGuildStore_SavedVariables["newestTime"][guildId] = 0
    internal.eventsNeedProcessing[guildId] = true
    internal.timeEstimated[guildId] = false
  end
end

local function AddAtIfNeeded(str)
  if string.sub(str, 1, 1) ~= "@" then
    str = "@" .. str
  end
  return str
end

local function ConvertEventIdLibHistoireId(eventId)
  local idString = tostring(eventId)
  assert(#idString < 10, "eventId is too large to convert")
  while #idString < 9 do
    idString = "0" .. idString
  end
  return "3" .. idString
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
        if v.id == eventID then
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
  task:Call(function(task) internal:dm("Info", GetString(GS_REFRESH_STARTING)) end)
  task:Call(function(task) internal:DatabaseBusy(true) end)
  task:For(1, numGuilds):Do(function(guildNum)
    local guildId = GetGuildId(guildNum)
    local guildName = GetGuildName(guildId)
    if eventsLinkedTrader[guildId] then
      --internal:dm("Debug", "Could Process Roster: " .. tostring(guildId) .. " : " .. GetGuildName(guildId))
      --internal:dm("Debug", "Num Events Roster: " .. tostring(numEventsTrader[guildId]) .. " : " .. GetGuildName(guildId))
      local endIndex = numEventsTrader[guildId]
      task:For(1, endIndex):Do(function(eventIndex)
        local eventId, timestampS, isRedacted, eventType, sellerDisplayName, buyerDisplayName, itemLink, quantity, price, tax = GetGuildHistoryTraderEventInfo(guildId, eventIndex)
        if eventType == GUILD_HISTORY_TRADER_EVENT_ITEM_SOLD then
          local convertedId = ConvertEventIdLibHistoireId(eventId)
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
            id = convertedId,
          }
          theEvent.wasKiosk = (internal.guildMemberInfo[guildId][zo_strlower(theEvent.buyer)] == nil)

          local oneEventRange = GetNumGuildHistoryEventRanges(guildId, GUILD_HISTORY_EVENT_CATEGORY_TRADER) == 1
          local timeStampInRange = not LibGuildStore_SavedVariables["newestTime"][guildId] or theEvent.timestamp > LibGuildStore_SavedVariables["newestTime"][guildId]
          if oneEventRange and timeStampInRange then
            LibGuildStore_SavedVariables["newestTime"][guildId] = theEvent.timestamp
            LibGuildStore_SavedVariables["lastReceivedEventID"][internal.libHistoireNamespace][guildId] = convertedId
          end

          local thePlayer = zo_strlower(GetDisplayName())
          local isSelfSale = zo_strlower(theEvent.seller) == thePlayer
          local added = false
          local daysOfHistoryToKeep = GetTimeStamp() - (ZO_ONE_DAY_IN_SECONDS * LibGuildStore_SavedVariables["historyDepth"])
          if (theEvent.timestamp > daysOfHistoryToKeep) then
            local duplicate = CheckForDuplicateSale(theEvent.itemLink, theEvent.id)
            if not duplicate then
              task:Call(function(task) added = internal:addSalesData(theEvent) end)
            end
            if added and isSelfSale then
              task:Call(function(task) internal:UpdateAlertQueue(guildName, theEvent) end)
            end
            if added then
              task:Call(function(task) MasterMerchant:PostScanParallel(guildName) end)
            end
          end
        end
      end)
    end
  end)
  task:Call(function(task) internal:dm("Info", GetString(GS_REFRESH_FINISHED)) end)
  task:Call(function(task) internal:DatabaseBusy(false) end)
  task:Call(function(task) ReloadUI() end)
end

LGH:RegisterCallback(LGH.callback.INITIALIZED, function()
  LGH:RegisterCallback(LGH.callback.LINKED_RANGE_FOUND, function(guildId, category)
    if not internal.LibHistoireListenerReady[guildId] then return end
    if not internal.LibHistoireListener[guildId]:IsRunning() then
      internal:dm("Debug", "Linked Range Callback for: " .. tostring(guildId))
      internal:SetupListener(guildId)
    end
  end)
end)
