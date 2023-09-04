MM_Graph = ZO_Object:Subclass()

function MM_Graph:New(control, pointTemplate)
  local graph = ZO_Object.New(self)
  graph.control = control
  pointTemplate = pointTemplate or "MM_Point"
  graph.pointPool = ZO_ControlPool:New(pointTemplate, control, "Point")
  graph.grid = control:GetNamedChild('Grid')
  graph.x_averagePriceMarker = control:GetNamedChild('AveragePriceMarker')
  graph.x_bonanzaPriceMarker = control:GetNamedChild('BonanzaPriceMarker')
  graph.x_averagePriceLabel = control:GetNamedChild('AveragePriceLabel')
  graph.x_bonanzaPriceLabel = control:GetNamedChild('BonanzaPriceLabel')
  graph.x_startLabelMarker = control:GetNamedChild('StartTimeframe')
  graph.x_endLabelMarker = control:GetNamedChild('EndTimeframe')
  graph.y_highestPriceLabelMarker = control:GetNamedChild('HighPrice')
  graph.y_lowestPriceLabelMarker = control:GetNamedChild('LowPrice')
  return graph
end

function MM_Graph:Initialize(x_startTimeFrame, x_endTimeFrame, y_highestPriceText, y_highestPriceLabelText,
  x_oldestTimestamp, x_currentTimestamp, y_lowestPriceValue, y_highestPriceValue,
  x_averagePriceText, x_averagePriceValue, x_bonanzaPriceText, x_bonanzaPriceValue)
  
  self.x_oldestTimestamp = x_oldestTimestamp
  self.x_currentTimestamp = x_currentTimestamp
  self.y_lowestPriceValue = y_lowestPriceValue
  self.y_highestPriceValue = y_highestPriceValue
  self.x_averagePriceValue = x_averagePriceValue
  self.x_bonanzaPriceValue = x_bonanzaPriceValue

  self:Clear()

  self.paddingY = 0
  self.paddingX = 0

  local tooltipControl = self.control
  local grid = self.grid

  local function hideElements(...)
    for _, element in ipairs({...}) do
      element:SetHidden(true)
      element:ClearAnchors()
    end
  end

  local x, y = tooltipControl:GetDimensions()
  local top = self.paddingY
  local bottom = self.x_startLabelMarker:GetFontHeight() * 1.25 + self.paddingY

  self.ySize = y - (top + bottom)

  self.y_lowestPriceLabelMarker:SetText(y_highestPriceText)
  self.y_highestPriceLabelMarker:SetText(y_highestPriceLabelText)

  self.x_averagePriceValue = self:NormalizeValue(x_averagePriceValue, y_lowestPriceValue, y_highestPriceValue, self.ySize)
  self.x_averagePriceLabel:SetText(x_averagePriceText)
  self.x_averagePriceLabel:SetColor(1, 0.996, 0, 1)

  local left = zo_max(self.x_averagePriceLabel:GetTextWidth(), self.y_lowestPriceLabelMarker:GetTextWidth(),
    self.y_highestPriceLabelMarker:GetTextWidth()) + self.paddingX + 5

  self.x_startLabelMarker:SetText(x_startTimeFrame)
  self.x_endLabelMarker:SetText(x_endTimeFrame)

  local right = self.paddingX + self.x_endLabelMarker:GetTextWidth() / 2

  self.x_startLabelMarker:SetHidden(false)
  self.x_endLabelMarker:SetHidden(false)
  self.y_lowestPriceLabelMarker:SetHidden(false)
  self.y_highestPriceLabelMarker:SetHidden(false)

  self.xSize = x - (left + right)

  self.xStart = left
  self.yStart = bottom

  grid:ClearAnchors()
  grid:SetAnchor(BOTTOMLEFT, tooltipControl, BOTTOMLEFT, left, -bottom)
  grid:SetAnchor(TOPRIGHT, tooltipControl, BOTTOMLEFT, left + self.xSize, -(bottom + self.ySize))

  self.x_averagePriceValue = self:AdjustValue(self.x_averagePriceValue, self.x_bonanzaPriceValue)
  self.x_bonanzaPriceValue = self:AdjustValue(self.x_bonanzaPriceValue)

  self.x_averagePriceValue = zo_clamp(self.x_averagePriceValue, 0.01, 105)
  self.x_averagePriceLabel:SetAnchor(RIGHT, self.grid, BOTTOMLEFT, -5, -self.x_averagePriceValue)
  self.x_averagePriceMarker:SetAnchor(BOTTOMLEFT, self.grid, BOTTOMLEFT, 0, -(self.x_averagePriceValue - 1))
  self.x_averagePriceMarker:SetAnchor(TOPRIGHT, self.grid, BOTTOMRIGHT, 0, -self.x_averagePriceValue)
  self.x_averagePriceLabel:SetHidden(false)
  self.x_averagePriceMarker:SetHidden(false)

  if x_bonanzaPriceValue then
    self.x_bonanzaPriceValue = self:AdjustValue(self.x_bonanzaPriceValue, self.x_averagePriceValue)
    self.x_bonanzaPriceLabel:SetText(x_bonanzaPriceText)
    self.x_bonanzaPriceLabel:SetColor(0.21, 0.54, 0.94, 1)
    self.x_bonanzaPriceValue = zo_clamp(self.x_bonanzaPriceValue, 0.01, 105)
    self.x_bonanzaPriceLabel:SetAnchor(RIGHT, self.grid, BOTTOMLEFT, -5, -self.x_bonanzaPriceValue)
    self.x_bonanzaPriceMarker:SetAnchor(BOTTOMLEFT, self.grid, BOTTOMLEFT, 0, -(self.x_bonanzaPriceValue - 1))
    self.x_bonanzaPriceMarker:SetAnchor(TOPRIGHT, self.grid, BOTTOMRIGHT, 0, -self.x_bonanzaPriceValue)
    self.x_bonanzaPriceLabel:SetHidden(false)
    self.x_bonanzaPriceMarker:SetHidden(false)
  end

  self.textAdjustmentY = self.x_startLabelMarker:GetFontHeight() / 4
end

function MM_Graph:AdjustValue(value, otherValue)
  if otherValue and value == otherValue then
    value = value + 15
  end
  return value
end

function MM_Graph:NormalizeValue(value, minValue, maxValue, size)
  return ((value - minValue) / (maxValue - minValue)) * size
end

function MM_Graph:AddPoint(x, y, color, tipText, sellerName)
  local point = self.pointPool:AcquireObject()

  point:SetText('.')
  if color then
    point:SetColor(color[1], color[2], color[3], 1)
  end
  point:ClearAnchors()

  x = self:NormalizeValue(x, self.x_oldestTimestamp, self.x_currentTimestamp, self.xSize)
  y = self:NormalizeValue(y, self.y_lowestPriceValue, self.y_highestPriceValue, self.ySize) - self.textAdjustmentY

  point:SetAnchor(BOTTOM, self.grid, BOTTOMLEFT, x, -y)
  point:SetHidden(false)

  if tipText then
    point.data = {
      tooltipText = tipText
    }
    point.sellerName = sellerName
  end
end
