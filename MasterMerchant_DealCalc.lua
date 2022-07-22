-- MasterMerchant Utility Functions File
-- Last Updated September 15, 2014
-- Written August 2014 by Dan Stone (@khaibit) - dankitymao@gmail.com
-- Extended February 2015 by Chris Lasswell (@Philgo68) - Philgo68@gmail.com
-- Released under terms in license accompanying this file.
-- Distribution without license is prohibited!

function MasterMerchant.CustomDealCalc(setPrice, salesCount, purchasePrice, stackCount)
  local deal = MM_DEAL_VALUE_DONT_SHOW
  local margin = 0
  local profit = -1
  if (setPrice) then
    local unitPrice = purchasePrice / stackCount
    profit = (setPrice - unitPrice) * stackCount
    margin = tonumber(string.format('%.2f', ((setPrice - unitPrice) / setPrice) * 100))

    if (margin >= MasterMerchant.systemSavedVariables.customDealBuyIt) then
      deal = MM_DEAL_VALUE_BUYIT
    elseif (margin >= MasterMerchant.systemSavedVariables.customDealSeventyFive) then
      deal = MM_DEAL_VALUE_GREAT
    elseif (margin >= MasterMerchant.systemSavedVariables.customDealFifty) then
      deal = MM_DEAL_VALUE_GOOD
    elseif (margin >= MasterMerchant.systemSavedVariables.customDealTwentyFive) then
      deal = MM_DEAL_VALUE_REASONABLE
    elseif (margin >= MasterMerchant.systemSavedVariables.customDealZero) then
      deal = MM_DEAL_VALUE_OKAY
    else
      deal = MM_DEAL_VALUE_OVERPRICED
    end
  else
    -- No sales seen
    margin = nil
  end
  return deal, margin, profit
end

--[[TODO Update DealCalculator this so it doesn't return -1 for things and makes more
sense when you view it in the guild store
]]--
function MasterMerchant.DealCalculator(setPrice, salesCount, purchasePrice, stackCount)
  if MasterMerchant.systemSavedVariables.customDealCalc then
    return MasterMerchant.CustomDealCalc(setPrice, salesCount, purchasePrice, stackCount)
  end

  local deal = MM_DEAL_VALUE_DONT_SHOW
  local margin = 0
  local profit = -1
  if (setPrice) then
    local unitPrice = purchasePrice / stackCount
    profit = (setPrice - unitPrice) * stackCount
    margin = tonumber(string.format('%.2f', ((setPrice - unitPrice) / setPrice) * 100))

    margin = (margin or 0)
    profit = (profit or 0)
    unitPrice = (unitPrice or 0)

    if (salesCount > 15) then
      -- high volume margins
      if (margin >= 85) then
        deal = MM_DEAL_VALUE_BUYIT
      elseif (margin >= 65 and profit >= 1000) then
        deal = MM_DEAL_VALUE_BUYIT
      elseif (margin >= 50 and profit >= 3000) then
        deal = MM_DEAL_VALUE_BUYIT
      elseif (margin >= 50 and profit >= 500) then
        deal = MM_DEAL_VALUE_GREAT
      elseif (margin >= 35 and profit >= 3000) then
        deal = MM_DEAL_VALUE_GREAT
      elseif (margin >= 35 and profit >= 100) then
        deal = MM_DEAL_VALUE_GOOD
      elseif (margin >= 20) then
        deal = MM_DEAL_VALUE_REASONABLE
      elseif (margin >= -2.5) then
        deal = MM_DEAL_VALUE_OKAY
      else
        deal = MM_DEAL_VALUE_OVERPRICED
      end
    elseif (salesCount > 5) then
      -- mid volume margins
      if (margin >= 85) then
        deal = MM_DEAL_VALUE_BUYIT
      elseif (margin >= 80 and profit >= 1000) then
        deal = MM_DEAL_VALUE_BUYIT
      elseif (margin >= 65 and profit >= 3000) then
        deal = MM_DEAL_VALUE_BUYIT
      elseif (margin >= 65 and profit >= 500) then
        deal = MM_DEAL_VALUE_GREAT
      elseif (margin >= 50 and profit >= 3000) then
        deal = MM_DEAL_VALUE_GREAT
      elseif (margin >= 50 and profit >= 100) then
        deal = MM_DEAL_VALUE_GOOD
      elseif (margin >= 30) then
        deal = MM_DEAL_VALUE_REASONABLE
      elseif (margin >= -5.0) then
        deal = MM_DEAL_VALUE_OKAY
      else
        deal = MM_DEAL_VALUE_OVERPRICED
      end
    else
      -- low volume margins
      if (margin >= 90 and profit >= 1000) then
        deal = MM_DEAL_VALUE_BUYIT
      elseif (margin >= 75 and profit >= 500) then
        deal = MM_DEAL_VALUE_GREAT
      elseif (margin >= 60 and profit >= 100) then
        deal = MM_DEAL_VALUE_GOOD
      elseif (margin >= 30) then
        deal = MM_DEAL_VALUE_REASONABLE
      elseif (margin >= -7.5) then
        deal = MM_DEAL_VALUE_OKAY
      else
        deal = MM_DEAL_VALUE_OVERPRICED
      end
    end
  else
    -- No sales seen
    margin = nil
  end

  return deal, margin, profit
end
