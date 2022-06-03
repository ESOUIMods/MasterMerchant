local libName, libVersion = "LibExecutionQueue", 200
local lib
lib = {}

function lib:new(_wait)
  -- This is a singleton

  self.Queue = self.Queue or {}
  if self.Paused == nil then self.Paused = true end
  self.Wait = _wait or self.Wait or 20

  return lib
end

function lib:Add(func, name)
  table.insert(self.Queue, 1, { func, name })
end

function lib:ContinueWith(func, name)
  table.insert(self.Queue, { func, name })
  self:Start()
end

function lib:Start()
  if self.Paused then
    self.Paused = false
    self:Next()
  end
end

function lib:Next()
  if not self.Paused then
    local nextFunc = table.remove(self.Queue)
    if nextFunc then
      nextFunc[1]()
      zo_callLater(function() self:Next() end, self.Wait)
    else
      -- Queue empty so pausing
      self.Paused = true;
    end
  end
end

function lib:Pause()
  self.Paused = true
end

LibExecutionQueue = lib
