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
