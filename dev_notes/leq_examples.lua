local ZO_CallLaterId = 1

function zo_callLater(func, ms)
    local id = ZO_CallLaterId
    local name = "CallLaterFunction"..id
    ZO_CallLaterId = ZO_CallLaterId + 1

    EVENT_MANAGER:RegisterForUpdate(name, ms,
        function()
            EVENT_MANAGER:UnregisterForUpdate(name)
            func(id)
        end)
    return id
end

local libName, libVersion = "LibExecutionQueue", 200
local ExecutionQueue = {}

function ExecutionQueue:new(waitInterval)
  local instance = {}

  instance.queue = instance.queue or {}
  instance.paused = instance.paused == nil and true or instance.paused
  instance.waitInterval = waitInterval or instance.waitInterval or 20

  setmetatable(instance, { __index = ExecutionQueue })
  return instance
end

function ExecutionQueue:addTask(taskFunction, taskName)
  table.insert(self.queue, 1, { func = taskFunction, name = taskName })
end

function ExecutionQueue:continueWith(taskFunction, taskName)
  table.insert(self.queue, { func = taskFunction, name = taskName })
  self:start(taskName)
end

function ExecutionQueue:start()
  if self.paused then
    self.paused = false
    self:executeNextTask()
  end
end

function ExecutionQueue:executeNextTask()
  if not self.paused then
    local nextTask = table.remove(self.queue)
    if nextTask then
      nextTask.func()
      zo_callLater(function() self:executeNextTask() end, self.waitInterval)
    else
      -- Queue is empty, pausing
      self.paused = true
    end
  end
end

function ExecutionQueue:pause()
  self.paused = true
end

function ExecutionQueue:findTask(taskName)
  for _, task in ipairs(self.queue) do
    if task.name == taskName then
      return task
    end
  end
end

LibExecutionQueue = ExecutionQueue

GS15DataSavedVariables =
{
    ["datana"] = 
    {
        [114690] = 
        {
            ["50:16:2:18:0"] = 
            {
                ["itemDesc"] = "Guards of Syvarra's Scales",
                ["newestTime"] = 1664831594,
                ["itemIcon"] = "/esoui/art/icons/gear_thievesguildv2_medium_legs_a.dds",
                ["sales"] = 
                {
                    [1] = 
                    {
                        ["price"] = 29995,
                        ["itemLink"] = 50147,
                        ["wasKiosk"] = true,
                        ["guild"] = 5,
                        ["buyer"] = 15368,
                        ["quant"] = 1,
                        ["timestamp"] = 1664831594,
                        ["id"] = "1945472617",
                        ["seller"] = 4857,
                    },
                },
                ["itemAdderText"] = "cp160 green fine medium apparel set syvarra's scales legs divines",
                ["totalCount"] = 1,
                ["wasAltered"] = false,
                ["oldestTime"] = 1622077408,
            },
        },
    },
}

Okay so this provided code has all the proper function and vairable names to function properly and no expected function errors will occur?