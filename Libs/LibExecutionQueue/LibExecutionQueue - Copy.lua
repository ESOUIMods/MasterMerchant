local libName, libVersion = "LibExecutionQueue", 202
local lib = {}
lib.processing = false
lib.queue = lib.queue or {}

-- VSYNC Value (based on a 60Hz monitor refresh rate)
local vsyncValue = GetCVar("VSYNC") == "1" and 0.01667 or nil

-- MinFrameTime.2 Setting
local minFrameTimeValue = tonumber(GetCVar("MinFrameTime.2"))
minFrameTimeValue = (minFrameTimeValue and minFrameTimeValue > 0) and minFrameTimeValue or nil

-- Background FPS Limit Settings
local useBackgroundFpsLimit = GetCVar("USE_BACKGROUND_FPS_LIMIT") == "1"
local backgroundFpsLimitSetting = tonumber(GetCVar("BACKGROUND_FPS_LIMIT"))
local backgroundFpsLimitValue = (useBackgroundFpsLimit and backgroundFpsLimitSetting and backgroundFpsLimitSetting > 0) and (1 / backgroundFpsLimitSetting) or nil

-- Final frameTimeTarget Calculation
local frameTimeTarget = vsyncValue or minFrameTimeValue or backgroundFpsLimitValue or 0.01667

local upperSpendTimeDef = frameTimeTarget * 0.70574  -- 0.01176 (85.03 FPS)
local upperSpendTimeDefNoHUD = upperSpendTimeDef * 1.21429  -- 0.01428 (70.03 FPS)
local lowerSpendTimeDef = frameTimeTarget * 2.9994  -- 0.05000 (20.00 FPS)
local lowerSpendTimeDefNoHUD = lowerSpendTimeDef * 0.8  -- 0.04000 (25.00 FPS)

function lib:GetUpperThreshold()
  return (HUD_SCENE:IsShowing() or HUD_UI_SCENE:IsShowing()) and upperSpendTimeDef or upperSpendTimeDefNoHUD
end

function lib:GetLowerThreshold()
  return (HUD_SCENE:IsShowing() or HUD_UI_SCENE:IsShowing()) and lowerSpendTimeDef or lowerSpendTimeDefNoHUD
end
local spendTime = lib:GetUpperThreshold()

function lib:new()
  self.processing = false
  LibGuildStore_Internal:dm("Debug", string.format("[%d] [New Task] processing is false, spendTime = %.5f.", GetGameTimeMilliseconds(), spendTime))
  return lib
end

function lib:addTask(func, name)
  LibGuildStore_Internal:dm("Debug", string.format("[%d] [addTask] Adding Main Task: %s, spendTime = %.5f", GetGameTimeMilliseconds(), name or "Unnamed", spendTime))
  table.insert(self.queue, 1, { func = func, name = name, isMainTask = true })
end

function lib:continueWith(func, name)
  LibGuildStore_Internal:dm("Debug", string.format("[%d] [continueWith] Adding Sub Task: %s, spendTime = %.5f", GetGameTimeMilliseconds(), name or "Unnamed", spendTime))
  table.insert(self.queue, { func = func, name = name })
  self:start()
end

function lib:start()
  LibGuildStore_Internal:dm("Debug", string.format("[%d] [start] Starting, processing is true, spendTime = %.5f.", GetGameTimeMilliseconds(), spendTime))
  self.processing = true
end

local start, now
function lib:GetCpuLoad()
  return (now - start)
end

function lib:getCpuLoadThreshold()
  return self:GetLowerThreshold() * 3
end

function lib:processTasks()
  if not self.processing then
    spendTime = math.max(self:GetUpperThreshold(), spendTime - spendTime * 0.025)
    -- LibGuildStore_Internal:dm("Debug", string.format("[%d] [processTasks] processing is paused, spendTime = %.5f.", GetGameTimeMilliseconds(), spendTime))
    return
  end

  start, now = GetFrameTimeSeconds(), GetGameTimeSeconds()

  if (now - start) > spendTime then
    spendTime = math.min(self:GetLowerThreshold(), spendTime + spendTime * 0.05)
    LibGuildStore_Internal:dm("Debug", string.format("[%d] [processTasks] processing is suspended, spendTime = %.5f.", GetGameTimeMilliseconds(), spendTime))
    return
  end

  -- Main Task Loop
  while (now - start) <= spendTime do
    local job = (self.queue and #self.queue > 0) and self.queue[#self.queue] or nil
    if not job then
      self.processing = next(self.queue) ~= nil
      LibGuildStore_Internal:dm("Debug", string.format("[%d] [MainTask] No job to process, spendTime = %.5f", GetGameTimeMilliseconds(), spendTime))
      break
    end

    if job.isMainTask then
      job = table.remove(self.queue)
      LibGuildStore_Internal:dm("Debug", string.format("[%d] [MainTask] processing task %s, spendTime = %.5f", GetGameTimeMilliseconds(), job.name or "Unnamed", spendTime))
      job.func()  -- Execute the main task
      now = GetGameTimeSeconds()
    else
      LibGuildStore_Internal:dm("Debug", string.format("[%d] [MainTask] SubTask is encountered, spendTime = %.5f.", GetGameTimeMilliseconds(), spendTime))
      break  -- Stop when a subtask is encountered
    end
  end

  -- SubTask Loop
  while (now - start) <= spendTime do
    local job = (self.queue and #self.queue > 0) and self.queue[#self.queue] or nil
    if not job then
      self.processing = next(self.queue) ~= nil
      LibGuildStore_Internal:dm("Debug", string.format("[%d] [SubTask] No job to process, spendTime = %.5f", GetGameTimeMilliseconds(), spendTime))
      break
    end

    if not job.isMainTask then
      job = table.remove(self.queue)
      LibGuildStore_Internal:dm("Debug", string.format("[%d] [SubTask] processing task %s, spendTime = %.5f", GetGameTimeMilliseconds(), job.name or "Unnamed", spendTime))
      job.func()  -- Execute the subtask
      now = GetGameTimeSeconds()
    else
      LibGuildStore_Internal:dm("Debug", string.format("[%d] [SubTask] MainTask is encountered, spendTime = %.5f.", GetGameTimeMilliseconds(), spendTime))
      break  -- Stop when a main task is encountered
    end
  end
end

local identifier = libName .. "_tasks"
do
  -- Use another id, so that the slot for identifier is not re-used.
  local id2 = identifier .. "_2"

  local function register2()
    EVENT_MANAGER:UnregisterForUpdate(id2)
    EVENT_MANAGER:RegisterForUpdate(identifier, 0, function() lib:processTasks() end)
  end
  -- Another delay to increase the chance of being one of the last.
  local function register()
    EVENT_MANAGER:UnregisterForUpdate(id2)
    EVENT_MANAGER:RegisterForUpdate(id2, 50, register2)
  end

  EVENT_MANAGER:RegisterForEvent(
    id2,
    EVENT_PLAYER_ACTIVATED,
    function()
      EVENT_MANAGER:UnregisterForEvent(id2, EVENT_PLAYER_ACTIVATED)
      return register()
    end
  )
  EVENT_MANAGER:RegisterForUpdate(id2, 0, function() lib:processTasks() end)
end

LibExecutionQueue = lib
