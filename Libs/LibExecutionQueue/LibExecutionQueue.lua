local libName, libVersion = "LibExecutionQueue", 202
local lib = {}
lib.processing = false
lib.queue = lib.queue or {}

local UPPER_FPS_BOUND = 240
local LEQ_DEFAULT_STALL_THRESHOLD = 15
local LEQ_STALL_THRESHOLD = LEQ_DEFAULT_STALL_THRESHOLD
local LEQ_MIN_STALL_THRESHOLD = 15
local CPU_ADJUSTMENT_RATE = 0.03
local IDLE_UI_ADJUSTMENT_FACTOR = 0.8335
local IDLE_NO_UI_ADJUSTMENT_FACTOR = 1.0
local THROTTLE_UI_ADJUSTMENT_FACTOR = 0.75
local THROTTLE_NO_UI_ADJUSTMENT_FACTOR = 1.0
local frameFpsTarget

lib.UPPER_FPS_BOUND = UPPER_FPS_BOUND
lib.frameFpsTarget = frameFpsTarget

do
  -- Initialize LEQSavedVars if not already defined
  LEQSavedVars = LEQSavedVars or {}

  -- Ensure LEQ_STALL_THRESHOLD exists and defaults to 0
  LEQSavedVars.LEQ_STALL_THRESHOLD = LEQSavedVars.LEQ_STALL_THRESHOLD or LEQ_DEFAULT_STALL_THRESHOLD

  -- Create local variables from LEQSavedVars
  LEQ_STALL_THRESHOLD = LEQSavedVars.LEQ_STALL_THRESHOLD
end

function lib:GetDynamicFrameTarget()
  local currentFrameRate = GetFramerate()
  local upperFrameRate = zo_min(zo_max(LEQ_STALL_THRESHOLD, currentFrameRate) + zo_floor(currentFrameRate * 0.25), UPPER_FPS_BOUND)
  local upperFrameTimeTarget = (1 / upperFrameRate)

  return upperFrameTimeTarget
end
local spendTime = lib:GetDynamicFrameTarget()

function lib:GetSpendTime()
  return spendTime
end

function lib:GetSpendTimeInMilliseconds()
  return zo_floor(spendTime * 1000)
end

function lib:new()
  self.processing = false
  -- LibGuildStore_Internal:dm("Debug", string.format("[%d] [New Task] processing is false, spendTime = %.5f.", GetGameTimeMilliseconds(), spendTime))
  return lib
end

function lib:addTask(func, name)
  -- LibGuildStore_Internal:dm("Debug", string.format("[%d] [addTask] Adding Main Task: %s, spendTime = %.5f", GetGameTimeMilliseconds(), name or "Unnamed", spendTime))
  table.insert(self.queue, 1, { func = func, name = name, isMainTask = true })
end

function lib:continueWith(func, name)
  -- LibGuildStore_Internal:dm("Debug", string.format("[%d] [continueWith] Adding Sub Task: %s, spendTime = %.5f", GetGameTimeMilliseconds(), name or "Unnamed", spendTime))
  table.insert(self.queue, { func = func, name = name })
  self:start()
end

function lib:start()
  -- LibGuildStore_Internal:dm("Debug", string.format("[%d] [start] Starting, processing is true, spendTime = %.5f.", GetGameTimeMilliseconds(), spendTime))
  self.processing = true
end

local start, now, cpuLoad
function lib:GetCpuLoad()
  return (now - start)
end

function lib:processTasks()
  local currentFrameRate = GetFramerate()
  local lowerFrameRate = zo_max(LEQ_STALL_THRESHOLD, zo_floor(currentFrameRate * 0.25))
  local upperFrameRate = zo_min(zo_max(LEQ_STALL_THRESHOLD, currentFrameRate) + zo_floor(currentFrameRate * 0.25), UPPER_FPS_BOUND)
  local lowerFrameTimeTarget = (1 / lowerFrameRate)
  local upperFrameTimeTarget = (1 / upperFrameRate)
  
  if not self.processing then
    local hudUiAdjustmentFactor = (not HUD_SCENE:IsShowing() and not HUD_UI_SCENE:IsShowing()) and IDLE_UI_ADJUSTMENT_FACTOR or IDLE_NO_UI_ADJUSTMENT_FACTOR
    spendTime = zo_max(upperFrameTimeTarget * hudUiAdjustmentFactor, spendTime - spendTime * CPU_ADJUSTMENT_RATE)
    -- LibGuildStore_Internal:dm("Debug", string.format("[%d] [processTasks] processing is paused, spendTime = %.5f.", GetGameTimeMilliseconds(), spendTime))
    return
  end

  start, now = GetFrameTimeSeconds(), GetGameTimeSeconds()

  cpuLoad = (now - start)
  if cpuLoad > spendTime then
    local hudUiAdjustmentFactor = (not HUD_SCENE:IsShowing() and not HUD_UI_SCENE:IsShowing()) and THROTTLE_UI_ADJUSTMENT_FACTOR or THROTTLE_NO_UI_ADJUSTMENT_FACTOR
    spendTime = zo_min(lowerFrameTimeTarget * hudUiAdjustmentFactor, spendTime + spendTime * CPU_ADJUSTMENT_RATE)
    LibGuildStore_Internal:dm("Debug", string.format("[%.5f] [processTasks] processing is suspended, spendTime = %.5f.", cpuLoad, spendTime))
    return
  end

  -- Main Task Loop
  while (now - start) <= spendTime do
    local job = (self.queue and #self.queue > 0) and self.queue[#self.queue] or nil
    if not job then
      self.processing = next(self.queue) ~= nil
      -- LibGuildStore_Internal:dm("Debug", string.format("[%d] [MainTask] No job to process, spendTime = %.5f", GetGameTimeMilliseconds(), spendTime))
      break
    end

    if job.isMainTask then
      job = table.remove(self.queue)
      -- LibGuildStore_Internal:dm("Debug", string.format("[%d] [MainTask] processing task %s, spendTime = %.5f", GetGameTimeMilliseconds(), job.name or "Unnamed", spendTime))
      job.func()  -- Execute the main task
      now = GetGameTimeSeconds()
    else
      -- LibGuildStore_Internal:dm("Debug", string.format("[%d] [MainTask] SubTask is encountered, spendTime = %.5f.", GetGameTimeMilliseconds(), spendTime))
      break  -- Stop when a subtask is encountered
    end
  end

  -- SubTask Loop
  while (now - start) <= spendTime do
    local job = (self.queue and #self.queue > 0) and self.queue[#self.queue] or nil
    if not job then
      self.processing = next(self.queue) ~= nil
      -- LibGuildStore_Internal:dm("Debug", string.format("[%d] [SubTask] No job to process, spendTime = %.5f", GetGameTimeMilliseconds(), spendTime))
      break
    end

    if not job.isMainTask then
      job = table.remove(self.queue)
      -- LibGuildStore_Internal:dm("Debug", string.format("[%d] [SubTask] processing task %s, spendTime = %.5f", GetGameTimeMilliseconds(), job.name or "Unnamed", spendTime))
      job.func()  -- Execute the subtask
      now = GetGameTimeSeconds()
    else
      -- LibGuildStore_Internal:dm("Debug", string.format("[%d] [SubTask] MainTask is encountered, spendTime = %.5f.", GetGameTimeMilliseconds(), spendTime))
      break  -- Stop when a main task is encountered
    end
  end
end

function lib:GetSchedulerState()
  local currentFrameRate = GetFramerate()
  local lowerFrameRate = zo_max(LEQ_STALL_THRESHOLD, zo_floor(currentFrameRate * 0.25))
  local upperFrameRate = zo_min(zo_max(LEQ_STALL_THRESHOLD, currentFrameRate) + zo_floor(currentFrameRate * 0.25), UPPER_FPS_BOUND)
  local lowerFrameTimeTarget = 1 / lowerFrameRate
  local upperFrameTimeTarget = 1 / upperFrameRate

  return {
    processing = self.processing,
    cpuLoad = cpuLoad,
    spendTime = spendTime,
    lowerFrameRate = lowerFrameRate,
    upperFrameRate = upperFrameRate,
    lowerFrameTimeTarget = lowerFrameTimeTarget,
    upperFrameTimeTarget = upperFrameTimeTarget,
    framerate = currentFrameRate,
  }
end

function lib.Slash(...)
  local num_args = select("#", ...)
	local allArgs = ""

	-- Concatenate arguments into a single string
	if num_args > 0 then
		for i = 1, num_args do
			local value = select(i, ...)
			if type(value) == "string" then
				allArgs = allArgs .. " " .. value
			elseif type(value) == "number" then
				allArgs = allArgs .. " " .. tostring(value)
			end
		end
		allArgs = zo_strtrim(allArgs)
	end

	local args, argValue = "", nil
	for w in zo_strgmatch(allArgs, "%w+") do
		if args == "" then
			args = w
		else
			argValue = tonumber(w) or zo_strlower(w)
		end
	end

	args = zo_strlower(args)

	if args == "stall" then
		if type(argValue) == "number" then
			-- Validate the FPS number
			if argValue < LEQ_MIN_STALL_THRESHOLD then
				d(string.format("[LEQ] Invalid FPS value. The stall threshold must be at least %d FPS. Use /leq stall <number>.", LEQ_MIN_STALL_THRESHOLD))
				return
			elseif argValue > UPPER_FPS_BOUND then
				d(string.format("[LEQ] Invalid FPS value. The stall threshold must be no greater than %d FPS. Use /leq stall <number>.", UPPER_FPS_BOUND))
				return
			end

			-- Clamp and apply the value
			local adjustedFps = zo_min(UPPER_FPS_BOUND, zo_max(LEQ_MIN_STALL_THRESHOLD, argValue))
			LEQSavedVars.LEQ_STALL_THRESHOLD = adjustedFps
			LEQ_STALL_THRESHOLD = LEQSavedVars.LEQ_STALL_THRESHOLD

			-- Notify the user of the updated stall threshold
			d(string.format("[LEQ] Stall threshold set to %d FPS.", adjustedFps))

		elseif type(argValue) == "string" and argValue == "default" then
			-- Set to the default stall threshold
			LEQSavedVars.LEQ_STALL_THRESHOLD = LEQ_DEFAULT_STALL_THRESHOLD
			LEQ_STALL_THRESHOLD = LEQSavedVars.LEQ_STALL_THRESHOLD

			-- Notify the user of the reset to default
			d(string.format("[LEQ] Stall threshold reset to the default value of %d FPS.", LEQ_DEFAULT_STALL_THRESHOLD))
		else
			-- Invalid argument
			d("[LEQ] Invalid argument. Use /leq stall <number> or /leq stall default.")
		end
	else
		-- Unknown command
		d("[LEQ] Unknown command. Use /leq stall <number> or /leq stall default.")
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

  SLASH_COMMANDS['/leq'] = function(...) lib:Slash(...) end
end

LibExecutionQueue = lib
