https://stats.stackexchange.com/questions/30196/using-mad-as-a-way-of-defining-a-threshold-for-significance-testing
https://stats.stackexchange.com/questions/535525/using-standardized-values-z-score-for-mae-mean-absolute-error
https://stats.stackexchange.com/questions/542188/can-i-use-a-modified-z-score-with-skewed-and-non-normal-data
https://hausetutorials.netlify.app/posts/2019-10-07-outlier-detection-with-median-absolute-deviation/

local sales = 
{
    [64] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2135661445",
        ["seller"] = 3991,
        ["buyer"] = 195059,
        ["timestamp"] = 1687327504,
        ["guild"] = 4,
        ["wasKiosk"] = true,
        ["price"] = 2995,
    },
    [1] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2139886977",
        ["seller"] = 39715,
        ["buyer"] = 198660,
        ["timestamp"] = 1687866624,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 1500,
    },
    [2] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2140092419",
        ["seller"] = 6251,
        ["buyer"] = 111491,
        ["timestamp"] = 1687889522,
        ["guild"] = 8,
        ["wasKiosk"] = true,
        ["price"] = 500,
    },
    [67] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2150125701",
        ["seller"] = 24617,
        ["buyer"] = 206769,
        ["timestamp"] = 1689134733,
        ["guild"] = 2,
        ["wasKiosk"] = false,
        ["price"] = 1600,
    },
    [4] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2122456271",
        ["seller"] = 6251,
        ["buyer"] = 26103,
        ["timestamp"] = 1685811096,
        ["guild"] = 8,
        ["wasKiosk"] = false,
        ["price"] = 500,
    },
    [69] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2147071727",
        ["seller"] = 3791,
        ["buyer"] = 10199,
        ["timestamp"] = 1688781842,
        ["guild"] = 5,
        ["wasKiosk"] = false,
        ["price"] = 14444,
    },
    [70] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2151854761",
        ["seller"] = 3448,
        ["buyer"] = 203480,
        ["timestamp"] = 1689385577,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 5000,
    },
    [7] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2125292097",
        ["seller"] = 97923,
        ["buyer"] = 202029,
        ["timestamp"] = 1686098096,
        ["guild"] = 8,
        ["wasKiosk"] = true,
        ["price"] = 1950,
    },
    [8] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2126194209",
        ["seller"] = 11039,
        ["buyer"] = 202020,
        ["timestamp"] = 1686195322,
        ["guild"] = 4,
        ["wasKiosk"] = true,
        ["price"] = 2500,
    },
    [73] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2169332919",
        ["seller"] = 21536,
        ["buyer"] = 204259,
        ["timestamp"] = 1691251922,
        ["guild"] = 2,
        ["wasKiosk"] = true,
        ["price"] = 400,
    },
    [74] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2169332945",
        ["seller"] = 21536,
        ["buyer"] = 204259,
        ["timestamp"] = 1691251923,
        ["guild"] = 2,
        ["wasKiosk"] = true,
        ["price"] = 400,
    },
    [75] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2165063217",
        ["seller"] = 5350,
        ["buyer"] = 208081,
        ["timestamp"] = 1690851741,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 2150,
    },
    [76] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2168420139",
        ["seller"] = 4816,
        ["buyer"] = 205016,
        ["timestamp"] = 1691182132,
        ["guild"] = 4,
        ["wasKiosk"] = true,
        ["price"] = 2380,
    },
    [77] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2166648313",
        ["seller"] = 95414,
        ["buyer"] = 194723,
        ["timestamp"] = 1691016962,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 2000,
    },
    [14] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2141117789",
        ["seller"] = 6251,
        ["buyer"] = 205147,
        ["timestamp"] = 1688024561,
        ["guild"] = 8,
        ["wasKiosk"] = true,
        ["price"] = 500,
    },
    [15] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2142315877",
        ["seller"] = 27879,
        ["buyer"] = 200022,
        ["timestamp"] = 1688191886,
        ["guild"] = 8,
        ["wasKiosk"] = true,
        ["price"] = 3904,
    },
    [16] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2142398715",
        ["seller"] = 6251,
        ["buyer"] = 205187,
        ["timestamp"] = 1688209189,
        ["guild"] = 8,
        ["wasKiosk"] = true,
        ["price"] = 500,
    },
    [81] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2174315121",
        ["seller"] = 209312,
        ["buyer"] = 210012,
        ["timestamp"] = 1691693990,
        ["guild"] = 4,
        ["wasKiosk"] = true,
        ["price"] = 5000,
    },
    [28] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2126607911",
        ["seller"] = 200293,
        ["buyer"] = 201574,
        ["timestamp"] = 1686247955,
        ["guild"] = 8,
        ["wasKiosk"] = true,
        ["price"] = 15000,
    },
    [30] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2130112361",
        ["seller"] = 9219,
        ["buyer"] = 192186,
        ["timestamp"] = 1686634494,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 1100,
    },
    [32] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2113666349",
        ["seller"] = 6251,
        ["buyer"] = 121549,
        ["timestamp"] = 1684717909,
        ["guild"] = 8,
        ["wasKiosk"] = true,
        ["price"] = 500,
    },
    [80] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2171662675",
        ["seller"] = 99755,
        ["buyer"] = 209671,
        ["timestamp"] = 1691450605,
        ["guild"] = 4,
        ["wasKiosk"] = false,
        ["price"] = 4045,
    },
    [79] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2169963565",
        ["seller"] = 32707,
        ["buyer"] = 209913,
        ["timestamp"] = 1691298222,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 1500,
    },
    [78] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2168983531",
        ["seller"] = 32707,
        ["buyer"] = 114916,
        ["timestamp"] = 1691222271,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 1500,
    },
    [72] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2165122283",
        ["seller"] = 16578,
        ["buyer"] = 209220,
        ["timestamp"] = 1690856286,
        ["guild"] = 4,
        ["wasKiosk"] = true,
        ["price"] = 8000,
    },
    [71] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2162826923",
        ["seller"] = 2439,
        ["buyer"] = 208932,
        ["timestamp"] = 1690640437,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 1500,
    },
    [68] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2146073117",
        ["seller"] = 3106,
        ["buyer"] = 205731,
        ["timestamp"] = 1688657683,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 25000,
    },
    [66] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2144760755",
        ["seller"] = 4090,
        ["buyer"] = 204319,
        ["timestamp"] = 1688487555,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 50000,
    },
    [42] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2096179469",
        ["seller"] = 29749,
        ["buyer"] = 197462,
        ["timestamp"] = 1682679383,
        ["guild"] = 4,
        ["wasKiosk"] = true,
        ["price"] = 225,
    },
    [43] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2096562243",
        ["seller"] = 29749,
        ["buyer"] = 197644,
        ["timestamp"] = 1682720559,
        ["guild"] = 4,
        ["wasKiosk"] = true,
        ["price"] = 225,
    },
    [44] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2097490059",
        ["seller"] = 29749,
        ["buyer"] = 194906,
        ["timestamp"] = 1682817782,
        ["guild"] = 4,
        ["wasKiosk"] = true,
        ["price"] = 225,
    },
    [45] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2098846781",
        ["seller"] = 22956,
        ["buyer"] = 100099,
        ["timestamp"] = 1682961422,
        ["guild"] = 4,
        ["wasKiosk"] = true,
        ["price"] = 500,
    },
    [65] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2144549797",
        ["seller"] = 24617,
        ["buyer"] = 206730,
        ["timestamp"] = 1688460505,
        ["guild"] = 2,
        ["wasKiosk"] = true,
        ["price"] = 1600,
    },
    [47] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2096800709",
        ["seller"] = 4508,
        ["buyer"] = 183841,
        ["timestamp"] = 1682743714,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 300,
    },
    [48] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2097538655",
        ["seller"] = 95414,
        ["buyer"] = 198575,
        ["timestamp"] = 1682823403,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 500,
    },
    [49] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2098127401",
        ["seller"] = 3256,
        ["buyer"] = 198715,
        ["timestamp"] = 1682882893,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 605,
    },
    [50] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2108886567",
        ["seller"] = 5187,
        ["buyer"] = 199710,
        ["timestamp"] = 1684163484,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 500,
    },
    [51] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2118884765",
        ["seller"] = 7234,
        ["buyer"] = 195876,
        ["timestamp"] = 1685365763,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 2010,
    },
    [52] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2120693513",
        ["seller"] = 4169,
        ["buyer"] = 198752,
        ["timestamp"] = 1685583950,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 5000,
    },
    [53] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2121100355",
        ["seller"] = 3163,
        ["buyer"] = 47356,
        ["timestamp"] = 1685639355,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 500,
    },
    [54] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2122930497",
        ["seller"] = 6251,
        ["buyer"] = 200171,
        ["timestamp"] = 1685855949,
        ["guild"] = 8,
        ["wasKiosk"] = true,
        ["price"] = 500,
    },
    [55] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2115494737",
        ["seller"] = 98447,
        ["buyer"] = 201184,
        ["timestamp"] = 1684957848,
        ["guild"] = 8,
        ["wasKiosk"] = true,
        ["price"] = 1000,
    },
    [56] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2118052271",
        ["seller"] = 6251,
        ["buyer"] = 198800,
        ["timestamp"] = 1685272192,
        ["guild"] = 8,
        ["wasKiosk"] = true,
        ["price"] = 500,
    },
    [57] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2131741233",
        ["seller"] = 80189,
        ["buyer"] = 202977,
        ["timestamp"] = 1686850676,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 5000,
    },
    [58] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2131861909",
        ["seller"] = 95414,
        ["buyer"] = 201484,
        ["timestamp"] = 1686868274,
        ["guild"] = 5,
        ["wasKiosk"] = true,
        ["price"] = 1200,
    },
    [59] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2135462337",
        ["seller"] = 66284,
        ["buyer"] = 13345,
        ["timestamp"] = 1687307038,
        ["guild"] = 8,
        ["wasKiosk"] = true,
        ["price"] = 1000,
    },
    [60] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2135665739",
        ["seller"] = 6251,
        ["buyer"] = 201720,
        ["timestamp"] = 1687328210,
        ["guild"] = 8,
        ["wasKiosk"] = false,
        ["price"] = 500,
    },
    [61] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2136525571",
        ["seller"] = 97923,
        ["buyer"] = 201235,
        ["timestamp"] = 1687442230,
        ["guild"] = 8,
        ["wasKiosk"] = true,
        ["price"] = 1950,
    },
    [62] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2136917469",
        ["seller"] = 22030,
        ["buyer"] = 203356,
        ["timestamp"] = 1687487417,
        ["guild"] = 8,
        ["wasKiosk"] = true,
        ["price"] = 5000,
    },
    [63] = 
    {
        ["itemLink"] = 6220,
        ["quant"] = 1,
        ["id"] = "2139125211",
        ["seller"] = 97923,
        ["buyer"] = 201103,
        ["timestamp"] = 1687754613,
        ["guild"] = 8,
        ["wasKiosk"] = true,
        ["price"] = 1950,
    },
}

local stats = {}

function stats.CleanUnitPrice(salesRecord)
  return salesRecord.price / salesRecord.quant
end

function stats.GetSortedSales(t)
  local sortedTable = {}
  for _, v in internal:spairs(t, function(a, b) return stats.CleanUnitPrice(a) < stats.CleanUnitPrice(b) end) do
    sortedTable[#sortedTable + 1] = v
  end
  return sortedTable
end

-- Get the mean value of a table
function stats.mean(t)
  local sum = 0
  local count = 0

  for _, sale in pairs(t) do
    sum = sum + sale
    count = count + 1
  end

  return (sum / count), count, sum
end

-- Get the mode of a table.  Returns a table of values.
-- Works on anything (not just numbers).
function stats.mode(t)
  local counts = {}

  for _, sale in pairs(t) do
    if counts[sale] == nil then
      counts[sale] = 1
    else
      counts[sale] = counts[sale] + 1
    end
  end

  local biggestCount = 0

  for _, v in pairs(counts) do
    if v > biggestCount then
      biggestCount = v
    end
  end

  local modeValues = {}

  for k, v in pairs(counts) do
    if v == biggestCount then
      table.insert(modeValues, k)
    end
  end

  return modeValues
end

--[[ Get the median of a table.
Modified: Requires the table to be sorted already
]]--
--(190 –z = (x – μ) / σ 150) / 25 = 1.6.
function stats.median(t, index, range)
  local temp = {}
  local hasRange = index ~= nil and range ~= nil

  if hasRange then
    for i = index, range do
      local individualSale = t[i]
      temp[#temp + 1] = individualSale
    end
  else
    temp = t
  end
  table.sort(temp)

  -- If we have an even number of table elements or odd.
  if math.fmod(#temp, 2) == 0 then
    -- Return mean value of middle two elements
    local middleIndex = math.ceil(#temp / 2)
    return (temp[middleIndex] + temp[middleIndex + 1]) / 2
  else
    -- Return middle element
    local middleIndex = math.ceil(#temp / 2)
    return temp[middleIndex]
  end
end

-- /script d({MasterMerchant.stats.mean(MasterMerchant.a_test)})
function stats.standardDeviation(t)
  local mean
  local vm
  local sum = 0
  local count = 0
  local result

  mean = stats.mean(t)

  for _, individualSale in pairs(t) do
    if type(individualSale) == 'number' then
      vm = individualSale - mean
      sum = sum + (vm * vm)
      count = count + 1
    end
  end

  result = math.sqrt(sum / (count - 1))

  return result
end

function stats.zscore(individualSale, mean, standardDeviation)
  return (individualSale - mean) / standardDeviation
end

function stats.findMinMax(t)
  local maxVal = -math.huge
  local minVal = math.huge

  for _, individualSale in pairs(t) do
    maxVal = math.max(maxVal, individualSale)
    minVal = math.min(minVal, individualSale)
  end

  return maxVal, minVal
end

function stats.range(t)
  local highest, lowest = stats.findMinMax(t)
  return highest - lowest
end

function stats.medianAbsoluteDeviation(t)
  local medianValue = stats.median(t)
  local absoluteDeviations = {}

  for _, value in pairs(t) do
    local absoluteDeviation = math.abs(value - medianValue)
    table.insert(absoluteDeviations, absoluteDeviation)
  end

  return stats.median(absoluteDeviations)
end

function stats.getMiddleIndex(count)
  local evenNumber = false
  local quotient, remainder = math.modf(count / 2)
  if remainder == 0 then evenNumber = true end
  local middleIndex = quotient + math.floor(0.5 + remainder)
  return middleIndex, evenNumber
end

--[[ we do not use this function in there are less then three
items in the table.

middleIndex will be rounded up when odd
]]--
function stats.interquartileRange(statsData)
  local statsDataCount = #statsData
  local middleIndex, evenNumber = stats.getMiddleIndex(statsDataCount)
  local quartile1, quartile3
  -- 1,2,3,4
  if evenNumber then
    quartile1 = stats.median(statsData, 1, middleIndex)
    quartile3 = stats.median(statsData, middleIndex + 1, #statsData)
  else
    -- 1,2,3,4,5
    -- odd number
    quartile1 = stats.median(statsData, 1, middleIndex)
    quartile3 = stats.median(statsData, middleIndex, #statsData)
  end
  return quartile1, quartile3, quartile3 - quartile1
end

function stats.calculateMADScore(statsData)
  local medianAbsoluteDev = stats.medianAbsoluteDeviation(statsData)
  local median = stats.median(statsData)
  local madScore = medianAbsoluteDev / median
  return madScore
end

function stats.calculateMADScoreWithStdDev(statsData)
  local medianAbsoluteDev = stats.medianAbsoluteDeviation(statsData)
  local stdev = stats.standardDeviation(statsData)
  local madScore = medianAbsoluteDev / stdev
  return madScore
end

function stats.calculateMADThreshold(statsData)
  local medianAbsoluteDev = stats.medianAbsoluteDeviation(statsData)
  local madScore = stats.calculateMADScore(statsData)
  local median = stats.median(statsData)
  local madThreshold = median + madScore * medianAbsoluteDev
  return madThreshold
end

function stats.calculateDomainPriceThreshold(statsData)
  local median = stats.median(statsData)
  local medianAbsoluteDev = stats.medianAbsoluteDeviation(statsData)
  local madScore = stats.calculateMADScore(statsData)
  local madThreshold = 3
  local domainPriceThreshold = median + madScore * medianAbsoluteDev * madThreshold
  return domainPriceThreshold
end

function stats.calculateDynamicMADThreshold(statsData, contextFactor)
  local median = stats.median(statsData)
  local medianAbsoluteDev = stats.medianAbsoluteDeviation(statsData)
  local madScore = stats.calculateMADScore(statsData)
  local dynamicMadThreshold = median + madScore * medianAbsoluteDev * contextFactor
  return dynamicMadThreshold
end

function stats.calculatePercentileContextFactor(statsData, percentile)
  local contextIndex = math.ceil(#statsData * percentile)
  local contextFactor = statsData[contextIndex]
  return contextFactor
end

function stats.IdentifyOutliers(dataList, statsData)
  local madThreshold = 2.7
  local iqrMultiplier = 1.5
  local zScoreThreshold = 1.881

  local nonOutliers = {}
  local nonOutliersCount = 0
  local oldestTime = nil

  local median = stats.median(statsData)
  local medianAbsoluteDev = stats.medianAbsoluteDeviation(statsData)
  local domainPriceThreshold = median + medianAbsoluteDev * madThreshold
  local quartile1, quartile3, quartileRange = stats.interquartileRange(statsData)
  local mean = stats.mean(statsData)
  local stdev = stats.standardDeviation(statsData)

  for _, item in pairs(dataList) do
    local individualSale = item.price / item.quant
    local zScore = stats.zscore(individualSale, mean, stdev)
    local isWithinMAD = individualSale <= domainPriceThreshold
    local isWithinIQR = individualSale >= quartile1 - iqrMultiplier * quartileRange and individualSale <= quartile3 + iqrMultiplier * quartileRange
    local isZScoreValid = zScore <= zScoreThreshold and zScore >= -zScoreThreshold

    if isWithinMAD then
      if isWithinIQR then
        if isZScoreValid then
          if oldestTime == nil or oldestTime > item.timestamp then oldestTime = item.timestamp end
          nonOutliersCount = nonOutliersCount + 1
          table.insert(nonOutliers, item)
        end
      end
    end
  end

  return nonOutliers, oldestTime, nonOutliersCount
end

function stats.IdentifyOutliersWithContextFactor(dataList, statsData)
  local iqrMultiplier = 1.5
  local zScoreThreshold = 2.054
  local percentile = 0.95

  local nonOutliers = {}
  local nonOutliersCount = 0
  local oldestTime = nil

  local madScore = stats.calculateMADScore(statsData)
  local median = stats.median(statsData)
  local percentileContextFactor = stats.calculatePercentileContextFactor(statsData, percentile)

  local quartile1, quartile3, quartileRange = stats.interquartileRange(statsData)
  local mean = stats.mean(statsData)
  local stdev = stats.standardDeviation(statsData)

  for _, item in pairs(dataList) do
    local individualSale = item.price / item.quant
    local zScore = stats.zscore(individualSale, mean, stdev)
    local isWithinMAD = individualSale <= percentileContextFactor
    local isWithinIQR = individualSale >= quartile1 - iqrMultiplier * quartileRange and individualSale <= quartile3 + iqrMultiplier * quartileRange
    local isZScoreValid = zScore <= zScoreThreshold and zScore >= -zScoreThreshold

    if isWithinMAD then
      if isWithinIQR then
        if isZScoreValid then
          if oldestTime == nil or oldestTime > item.timestamp then oldestTime = item.timestamp end
          nonOutliersCount = nonOutliersCount + 1
          table.insert(nonOutliers, item)
        end
      end
    end
  end

  return nonOutliers, oldestTime, nonOutliersCount
end

local statsData = {}
local function BuildStatsData(item)
    local individualSale = item.price / item.quant
    statsData[#statsData + 1] = individualSale
end

local function SortStatsData()
    statsDataCount = #statsData
    table.sort(statsData)
end

for _, item in pairs(sales) do
    BuildStatsData(item)
end
SortStatsData()

local meanValue, count, sum = stats.mean(statsData)
local medianValue = stats.median(statsData)
local modeValues = stats.mode(statsData)
local standardDev = stats.standardDeviation(statsData)
local medianAbsDev = stats.medianAbsoluteDeviation(statsData)
local quartile1, quartile3, interquartileRange = stats.interquartileRange(statsData)
local nonOutliers, oldestTime, nonOutliersCount = stats.IdentifyOutliers(sales, statsData)
local range = stats.range(statsData)
local madScore = stats.calculateMADScore(statsData)
local madScoreDev = stats.calculateMADScoreWithStdDev(statsData)
local madThreshold = stats.calculateMADThreshold(statsData)
local domainPriceThreshold = stats.calculateDomainPriceThreshold(statsData)

print("Data Count: ", statsDataCount)
print("Mean: ", meanValue)
print("Median: ", medianValue)
print("Mode: ", table.concat(modeValues, ", "))
print("Standard Deviation: ", standardDev)
print("Median Absolute Deviation: ", medianAbsDev)
print("Interquartile Range: ", interquartileRange)
print("Range: ", range)
print("MAD Score: ", madScore)
print("MAD Threshold: ", madThreshold)
print("Domain Price Threshold: ", domainPriceThreshold)

local outStatsData = {}
print("Identified Outliers: ")
local nonOutliersCount = #nonOutliers
print("Data Count: ", nonOutliersCount)

for _, item in pairs(nonOutliers) do
    local individualSale = item.price / item.quant
    outStatsData[#outStatsData + 1] = individualSale
end
table.sort(outStatsData)


local outMeanValue, count, sum = stats.mean(outStatsData)
local outRange = stats.range(outStatsData)
local outMadScore = stats.calculateMADScore(outStatsData)
local outMadThreshold = stats.calculateMADThreshold(outStatsData)
print("Mean: ", outMeanValue)
print("Range: ", outRange)
print("MAD Score: ", outMadScore)
print("MAD Threshold: ", outMadThreshold)
for _, sale in pairs(nonOutliers) do
  print("Price:", sale.price)
  print("--------------")
end

print("Contextually Identified Outliers: ")

local conStatsData = {}
for _, item in pairs(sales) do
    local individualSale = item.price / item.quant
    conStatsData[#conStatsData + 1] = individualSale
end
table.sort(conStatsData)
local conOutliers, oldestTime, nonOutliersCount = stats.IdentifyOutliersWithContextFactor(sales, conStatsData)

local conMeanValue, count, sum = stats.mean(conStatsData)
local conRange = stats.range(conStatsData)
local conMadScore = stats.calculateMADScore(conStatsData)
local conMadThreshold = stats.calculateMADThreshold(conStatsData)
local conPercentileContextFactor = stats.calculatePercentileContextFactor(conStatsData, 0.95)
print("Mean: ", conMeanValue)
print("Range: ", conRange)
print("MAD Score: ", conMadScore)
print("MAD Threshold: ", conMadThreshold)
print("Percentile ContextFactor: ", conPercentileContextFactor)
for _, sale in pairs(conOutliers) do
  print("Price:", sale.price)
  print("--------------")
end

GS08DataSavedVariables =
{
    ["datana"] =
    {
        [114690] =
        {
            ["50:16:4:18:0"] =
            {
                ["itemDesc"] = "Guards of Syvarra's Scales",
                ["newestTime"] = 1659287708,
                ["itemIcon"] = "/esoui/art/icons/gear_thievesguildv2_medium_legs_a.dds",
                ["sales"] =
                {
                    [1] =
                    {
                        ["price"] = 2000,
                        ["itemLink"] = 50147,
                        ["wasKiosk"] = true,
                        ["guild"] = 1,
                        ["buyer"] = 79652,
                        ["quant"] = 1,
                        ["timestamp"] = 1659287708,
                        ["id"] = "2187175832",
                        ["seller"] = 259,
                    },
                },
                ["itemAdderText"] = "cp160 green fine medium apparel set syvarra's scales legs divines",
                ["totalCount"] = 1,
                ["wasAltered"] = false,
                ["oldestTime"] = 1659287708,
            },
        },
    },
}
