local libName, libVersion = "LibExecutionQueue", 201
local lib = {}

function lib:new(_wait)
  -- This is a singleton

  self.Queue = self.Queue or {}
  if self.Paused == nil then self.Paused = true end
  self.Wait = _wait or self.Wait or 20

  return lib
end

function lib:addTask(func, name)
  table.insert(self.Queue, 1, { func, name })
end

function lib:continueWith(func, name)
  table.insert(self.Queue, { func, name })
  self:start()
end

function lib:start()
  if self.Paused then
    self.Paused = false
    self:executeNextTask()
  end
end

function lib:executeNextTask()
  if not self.Paused then
    local nextFunc = table.remove(self.Queue)
    if nextFunc then
      nextFunc[1]()
      zo_callLater(function() self:executeNextTask() end, self.Wait)
    else
      -- Queue empty so pausing
      self.Paused = true;
    end
  end
end

function lib:pause()
  self.Paused = true
end

LibExecutionQueue = lib
