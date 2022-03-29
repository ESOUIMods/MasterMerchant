-- MasterMerchant Utility Functions File
-- Last Updated September 15, 2014
-- Written August 2014 by Dan Stone (@khaibit) - dankitymao@gmail.com
-- Extended February 2015 by Chris Lasswell (@Philgo68) - Philgo68@gmail.com
-- Released under terms in license accompanying this file.
-- Distribution without license is prohibited!

--[[TODO Update DealCalculator this so it doesn't return -1 for things and makes more
sense when you view it in the guild store
]]--
function MasterMerchant.DealCalculator(setPrice, salesCount, purchasePrice, stackCount)
  if MasterMerchant.CustomDealCalc[GetDisplayName()] then
    return MasterMerchant.CustomDealCalc[GetDisplayName()](setPrice, salesCount, purchasePrice, stackCount)
  end

  local deal = -1
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
        deal = 5
      elseif (margin >= 65 and profit >= 1000) then
        deal = 5
      elseif (margin >= 50 and profit >= 3000) then
        deal = 5
      elseif (margin >= 50 and profit >= 500) then
        deal = 4
      elseif (margin >= 35 and profit >= 3000) then
        deal = 4
      elseif (margin >= 35 and profit >= 100) then
        deal = 3
      elseif (margin >= 20) then
        deal = 2
      elseif (margin >= -2.5) then
        deal = 1
      else
        deal = 0
      end
    elseif (salesCount > 5) then
      -- mid volume margins
      if (margin >= 85) then
        deal = 5
      elseif (margin >= 80 and profit >= 1000) then
        deal = 5
      elseif (margin >= 65 and profit >= 3000) then
        deal = 5
      elseif (margin >= 65 and profit >= 500) then
        deal = 4
      elseif (margin >= 50 and profit >= 3000) then
        deal = 4
      elseif (margin >= 50 and profit >= 100) then
        deal = 3
      elseif (margin >= 30) then
        deal = 2
      elseif (margin >= -5.0) then
        deal = 1
      else
        deal = 0
      end
    else
      -- low volume margins
      if (margin >= 90 and profit >= 1000) then
        deal = 5
      elseif (margin >= 75 and profit >= 500) then
        deal = 4
      elseif (margin >= 60 and profit >= 100) then
        deal = 3
      elseif (margin >= 30) then
        deal = 2
      elseif (margin >= -7.5) then
        deal = 1
      else
        deal = 0
      end
    end
  else
    -- No sales seen
    deal = MasterMerchant.systemSavedVariables.noSalesInfoDeal
  end

  return deal, margin, profit
end
