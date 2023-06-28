function MasterMerchant.InitDealFilterClass()

  local AGS = AwesomeGuildStore

  local FilterBase = AGS.class.FilterBase
  local ValueRangeFilterBase = AGS.class.ValueRangeFilterBase

  local FILTER_ID = AGS:GetFilterIds()

  local DealFilter = ValueRangeFilterBase:Subclass()
  MasterMerchant.DealFilter = DealFilter

  function DealFilter:New(...)
    return ValueRangeFilterBase.New(self, ...)
  end

  function DealFilter:Initialize()
    ValueRangeFilterBase.Initialize(self, FILTER_ID.MASTER_MERCHANT_DEAL_FILTER, FilterBase.GROUP_SERVER, {
      -- TRANSLATORS: label of the deal filter
      label = GetString(AGS_DEAL_RANGE_LABEL),
      min = 1,
      max = 6,
      steps = {
        {
          id = 1,
          label = GetString(AGS_OVERPRICED_LABEL),
          icon = "MasterMerchant/AGS_Integration/images/overpriced_%s.dds",
        },
        {
          id = 2,
          label = GetString(AGS_OKAY_LABEL),
          icon = "MasterMerchant/AGS_Integration/images/normal_%s.dds",
        },
        {
          id = 3,
          label = GetString(AGS_REASONABLE_LABEL),
          icon = "MasterMerchant/AGS_Integration/images/magic_%s.dds",
        },
        {
          id = 4,
          label = GetString(AGS_GOOD_LABEL),
          icon = "MasterMerchant/AGS_Integration/images/arcane_%s.dds",
        },
        {
          id = 5,
          label = GetString(AGS_GREAT_LABEL),
          icon = "MasterMerchant/AGS_Integration/images/artifact_%s.dds",
        },
        {
          id = 6,
          label = GetString(AGS_BUYIT_LABEL),
          icon = "MasterMerchant/AGS_Integration/images/legendary_%s.dds",
        }
      }
    })

    function DealFilter:CanFilter(subcategory)
      return true
    end

    local dealById = {}
    for i = 1, #self.config.steps do
      local step = self.config.steps[i]
      dealById[step.id] = step
    end
    self.dealById = dealById
  end

  function DealFilter:FilterLocalResult(result)
    local index = result.itemUniqueId
    local itemLink = GetTradingHouseSearchResultItemLink(index)
    local dealValue, margin, profit = MasterMerchant.GetDealInformation(itemLink, result.purchasePrice, result.stackCount)
    return not ((dealValue or -5) + 1 < self.localMin or (dealValue or 5) + 1 > self.localMax)
  end

  function DealFilter:GetTooltipText(min, max)
    if (min ~= self.config.min or max ~= self.config.max) then
      local out = {}
      for id = min, max do
        local step = self.dealById[id]
        out[#out + 1] = step.label
      end
      return table.concat(out, ", ")
    end
    return ""
  end

  return DealFilter
end

function MasterMerchant.InitProfitFilterClass()

  local AGS = AwesomeGuildStore

  local FilterBase = AGS.class.FilterBase
  local ValueRangeFilterBase = AGS.class.ValueRangeFilterBase

  local FILTER_ID = AGS:GetFilterIds()

  local MIN_PROFIT = 1
  local MAX_PROFIT = 2100000000

  local ProfitFilter = ValueRangeFilterBase:Subclass()
  MasterMerchant.ProfitFilter = ProfitFilter

  function ProfitFilter:New(...)
    return ValueRangeFilterBase.New(self, ...)
  end

  function ProfitFilter:Initialize()
    ValueRangeFilterBase.Initialize(self, FILTER_ID.MASTER_MERCHANT_DEAL_SELECTOR, FilterBase.GROUP_SERVER, {
      -- TRANSLATORS: label of the profit filter
      label = GetString(AGS_PROFIT_RANGE_LABEL),
      currency = CURT_MONEY,
      min = MIN_PROFIT,
      max = MAX_PROFIT,
      precision = 0,
      steps = { MIN_PROFIT, 10, 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 50000, 100000, MAX_PROFIT },
    })

    function ProfitFilter:CanFilter(subcategory)
      return true
    end
  end

  function ProfitFilter:FilterLocalResult(result)
    local index = result.itemUniqueId
    local itemLink = GetTradingHouseSearchResultItemLink(index)
    local dealValue, margin, profit = MasterMerchant.GetDealInformation(itemLink, result.purchasePrice, result.stackCount)

    if not profit or (profit < (self.localMin or MIN_PROFIT)) or (profit > (self.localMax or MAX_PROFIT)) then
      return false
    end
    return true
  end

  return ProfitFilter
end
