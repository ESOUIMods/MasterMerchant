-- A simple utility function to return which set of settings are active,
-- based on the allSettingsAccount option setting.
function MasterMerchant:ActiveSettings()
  return MasterMerchant.systemSavedVariables
end

function MasterMerchant:TimeCheck()
  --[[
  this does nothing because LibPrice has no idea what it going on
  don't mess with it or I'll make it local
  ]]--
end
