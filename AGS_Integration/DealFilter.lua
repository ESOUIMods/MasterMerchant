function MasterMerchant.InitDealFilterClass()

  local AGS                  = AwesomeGuildStore

  local FilterBase           = AGS.class.FilterBase
  local ValueRangeFilterBase = AGS.class.ValueRangeFilterBase

  local FILTER_ID            = AGS:GetFilterIds()

  local DealFilter           = ValueRangeFilterBase:Subclass()
  MasterMerchant.DealFilter  = DealFilter

  function DealFilter:New(...)
    return ValueRangeFilterBase.New(self, ...)
  end

  function DealFilter:Initialize()
    ValueRangeFilterBase.Initialize(self, FILTER_ID.MASTER_MERCHANT_DEAL_FILTER, FilterBase.GROUP_SERVER, {
      -- TRANSLATORS: label of the deal filter
      label = "Deal Range",
      min   = 1,
      max   = 6,
      steps = {
        {
          id    = 1,
          label = "Overpriced",
          icon  = "MasterMerchant/AGS_Integration/overpriced_%s.dds",
        },
        {
          id    = 2,
          label = "Ok",
          icon  = "AwesomeGuildStore/images/qualitybuttons/normal_%s.dds",
        },
        {
          id    = 3,
          label = "Reasonable",
          icon  = "AwesomeGuildStore/images/qualitybuttons/magic_%s.dds",
        },
        {
          id    = 4,
          label = "Good",
          icon  = "AwesomeGuildStore/images/qualitybuttons/arcane_%s.dds",
        },
        {
          id    = 5,
          label = "Great",
          icon  = "AwesomeGuildStore/images/qualitybuttons/artifact_%s.dds",
        },
        {
          id    = 6,
          label = "Buy it!",
          icon  = "AwesomeGuildStore/images/qualitybuttons/legendary_%s.dds",
        }
      }
    })

    function DealFilter:CanFilter(subcategory)
      return true
    end

    local dealById = {}
    for i = 1, #self.config.steps do
      local step        = self.config.steps[i]
      dealById[step.id] = step
    end
    self.dealById = dealById
  end

  function DealFilter:FilterLocalResult(result)
    local index                     = result.itemUniqueId
    local itemLink                  = GetTradingHouseSearchResultItemLink(index)
    local dealValue, margin, profit = MasterMerchant.GetDealInformation(itemLink, result.purchasePrice, result.stackCount)
    return not ((dealValue or -5) + 1 < self.localMin or (dealValue or 5) + 1 > self.localMax)
  end

  function DealFilter:GetTooltipText(min, max)
    if (min ~= self.config.min or max ~= self.config.max) then
      local out = {}
      for id = min, max do
        local step    = self.dealById[id]
        out[#out + 1] = step.label
      end
      return table.concat(out, ", ")
    end
    return ""
  end

  return DealFilter
end

function MasterMerchant.InitProfitFilterClass()

  local AGS                   = AwesomeGuildStore

  local FilterBase            = AGS.class.FilterBase
  local ValueRangeFilterBase  = AGS.class.ValueRangeFilterBase

  local FILTER_ID             = AGS:GetFilterIds()

  local MIN_PROFIT            = 1
  local MAX_PROFIT            = 2100000000

  local ProfitFilter          = ValueRangeFilterBase:Subclass()
  MasterMerchant.ProfitFilter = ProfitFilter

  function ProfitFilter:New(...)
    return ValueRangeFilterBase.New(self, ...)
  end

  function ProfitFilter:Initialize()
    ValueRangeFilterBase.Initialize(self, FILTER_ID.MASTER_MERCHANT_DEAL_SELECTOR, FilterBase.GROUP_SERVER, {
      -- TRANSLATORS: label of the profit filter
      label     = "Profit Range",
      currency  = CURT_MONEY,
      min       = MIN_PROFIT,
      max       = MAX_PROFIT,
      precision = 0,
      steps     = { MIN_PROFIT, 10, 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 50000, 100000, MAX_PROFIT },
    })

    function ProfitFilter:CanFilter(subcategory)
      return true
    end
  end

  function ProfitFilter:FilterLocalResult(result)
    local index                     = result.itemUniqueId
    local itemLink                  = GetTradingHouseSearchResultItemLink(index)
    local dealValue, margin, profit = MasterMerchant.GetDealInformation(itemLink, result.purchasePrice, result.stackCount)

    if not profit or (profit < (self.localMin or MIN_PROFIT)) or (profit > (self.localMax or MAX_PROFIT)) then
      return false
    end
    return true
  end

  return ProfitFilter
end
