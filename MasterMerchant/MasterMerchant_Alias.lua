local internal = _G["LibGuildStore_Internal"]

-- A simple utility function to return which set of settings are active,
-- based on the allSettingsAccount option setting.
function MasterMerchant:ActiveSettings()
  return MasterMerchant.systemSavedVariables
end

-- alias for previous function
function MasterMerchant.makeIndexFromLink(itemLink)
  return internal.GetOrCreateIndexFromLink(itemLink)
end

function MasterMerchant:TimeCheck()
  --[[
  this does nothing because LibPrice has no idea what MM
  is doing. Don't mess with it or I'll make it local.
  ]]--
end
