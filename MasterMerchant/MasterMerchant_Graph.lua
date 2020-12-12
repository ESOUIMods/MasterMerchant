local function OnMouseEnter(control)
  ZO_Options_OnMouseEnter(control)
end

local function OnMouseExit(control)
  ZO_Options_OnMouseExit(control)
end

MM_Graph = ZO_Object:Subclass()

function MM_Graph:New(control, pointTemplate, labelTemplate)
  local graph     = ZO_Object.New(self)

  graph.control   = control

  pointTemplate   = pointTemplate or "MMGraphLabel"
  labelTemplate   = labelTemplate or "MMGraphLabel"

  graph.pointPool = ZO_ControlPool:New(pointTemplate, control, "Point")
  graph.labelPool = ZO_ControlPool:New(labelTemplate, control, "Label")

  return graph
end

function MM_Graph:Initialize(xStartLabelText, xEndLabelText, yStartLabelText, yEndLabelText,
  xStartValue, xEndValue, yStartValue, yEndValue, xPriceText, xPriceValue)

  self.xStartValue = xStartValue
  self.xEndValue   = xEndValue
  self.yStartValue = yStartValue
  self.yEndValue   = yEndValue
  self.xPriceValue = xPriceValue

  self:Clear();

  self.paddingY    = 0
  self.paddingX    = 0

  self.xStartLabel = self.labelPool:AcquireObject()
  self.xEndLabel   = self.labelPool:AcquireObject()
  self.yStartLabel = self.labelPool:AcquireObject()
  self.yEndLabel   = self.labelPool:AcquireObject()
  self.xPriceLabel = self.labelPool:AcquireObject()
  self.xPriceLabel:SetHidden(true)

  self.marker = self.control:GetNamedChild('Marker')
  self.marker:SetHidden(true)

  self.xStartLabel:ClearAnchors()
  self.xEndLabel:ClearAnchors()
  self.yStartLabel:ClearAnchors()
  self.yEndLabel:ClearAnchors()
  self.xPriceLabel:ClearAnchors()
  self.marker:ClearAnchors()

  local x, y   = self.control:GetDimensions()
  local top    = self.paddingY
  local bottom = self.xStartLabel:GetFontHeight() * 1.25 + self.paddingY

  self.ySize   = y - (top + bottom)

  self.yStartLabel:SetAnchor(LEFT, self.control, BOTTOMLEFT, self.paddingX, -bottom)
  self.yStartLabel:SetText(yStartLabelText)

  self.yEndLabel:SetAnchor(LEFT, self.control, BOTTOMLEFT, self.paddingX, -(bottom + self.ySize))
  self.yEndLabel:SetText(yEndLabelText)

  self.xPriceValue = ((self.xPriceValue - self.yStartValue) / (self.yEndValue - self.yStartValue)) * self.ySize

  self.xPriceLabel:SetText(xPriceText)

  local left = math.max(self.xPriceLabel:GetTextWidth(), self.yStartLabel:GetTextWidth(),
    self.yEndLabel:GetTextWidth()) + self.paddingX + 5

  self.xStartLabel:SetAnchor(BOTTOM, self.control, BOTTOMLEFT, left, -self.paddingY)
  self.xStartLabel:SetText(xStartLabelText)

  self.xEndLabel:SetAnchor(BOTTOMRIGHT, self.control, BOTTOMRIGHT, -self.paddingX, -self.paddingY)
  self.xEndLabel:SetText(xEndLabelText)

  local right = self.paddingX + self.xEndLabel:GetTextWidth() / 2

  self.xStartLabel:SetHidden(false)
  self.xEndLabel:SetHidden(false)
  self.yStartLabel:SetHidden(false)
  self.yEndLabel:SetHidden(false)

  self.xSize  = x - (left + right)

  self.xStart = left
  self.yStart = bottom

  self.grid   = self.control:GetNamedChild('Grid')
  local grid  = self.grid
  grid:ClearAnchors()
  grid:SetAnchor(BOTTOMLEFT, self.control, BOTTOMLEFT, left, -bottom)
  grid:SetAnchor(TOPRIGHT, self.control, BOTTOMLEFT, left + self.xSize, -(bottom + self.ySize))

  self.xPriceLabel:SetAnchor(RIGHT, self.grid, BOTTOMLEFT, -5, -self.xPriceValue)
  self.marker:SetAnchor(BOTTOMLEFT, self.grid, BOTTOMLEFT, 0, -(self.xPriceValue - 1))
  self.marker:SetAnchor(TOPRIGHT, self.grid, BOTTOMRIGHT, 0, -self.xPriceValue)
  self.xPriceLabel:SetHidden(false)
  self.marker:SetHidden(false)

  self.textAdjustmentY = self.xStartLabel:GetFontHeight() / 4
end

function MM_Graph:AddPoint(x, y, color, tipText)
  local point = self.pointPool:AcquireObject()

  point:SetText('.')
  if color then
    point:SetColor(color[1], color[2], color[3], 1)
  end
  point:ClearAnchors()

  x = ((x - self.xStartValue) / (self.xEndValue - self.xStartValue)) * self.xSize
  y = (((y - self.yStartValue) / (self.yEndValue - self.yStartValue)) * self.ySize) - self.textAdjustmentY

  point:SetAnchor(BOTTOM, self.grid, BOTTOMLEFT, x, -y)
  point:SetHidden(false)

  if tipText then
    point.data = {
      tooltipText = tipText
    }
    point:SetMouseEnabled(true)

    point:SetHandler("OnMouseEnter", ZO_Options_OnMouseEnter)
    point:SetHandler("OnMouseExit", ZO_Options_OnMouseExit)
  end

end

function MM_Graph:AddYLabel(text, y)
  local label = self.labelPool:AcquireObject()

  label:SetText('|cFFFFFF' .. text .. '|r')
  label:ClearAnchors()

  y = ((y - self.yStartValue) / (self.yEndValue - self.yStartValue)) * self.ySize

  label:SetAnchor(RIGHT, self.grid, BOTTOMLEFT, -5, -y)
  label:SetHidden(false)

  local marker = self.marker
  marker:ClearAnchors()
  marker:SetAnchor(BOTTOMLEFT, self.grid, BOTTOMLEFT, 0, -(y - 1))
  marker:SetAnchor(TOPRIGHT, self.grid, BOTTOMRIGHT, 0, -y)
  marker:SetHidden(false)
end

function MM_Graph:Clear()
  self.pointPool:ReleaseAllObjects()
  self.labelPool:ReleaseAllObjects()
end
