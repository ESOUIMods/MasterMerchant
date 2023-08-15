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
  self:startTask(taskName)
end

function ExecutionQueue:start()
  if self.paused then
    self.paused = false
    self:executeNextTask()
  end
end

function ExecutionQueue:executeNextTask()
  if not self.paused then
    local batchSize = 10
    for _ = 1, batchSize do
      local nextTask = table.remove(self.queue)
      if nextTask then
        nextTask.func()
      else
        -- Queue is empty, pausing
        self.paused = true
        return
      end
    end
    zo_callLater(function() self:executeNextTask() end, self.waitInterval)
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
