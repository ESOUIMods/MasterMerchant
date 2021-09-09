MM_Graph = ZO_Object:Subclass()
MM_Graph.itemLink = nil

function MM_Graph:New(control, pointTemplate, labelTemplate)
  local graph     = ZO_Object.New(self)

  graph.control   = control

  pointTemplate   = pointTemplate or "MMGraphLabel"
  labelTemplate   = labelTemplate or "MMGraphLabel"

  graph.pointPool = ZO_ControlPool:New(pointTemplate, control, "Point")
  graph.labelPool = ZO_ControlPool:New(labelTemplate, control, "Label")

  return graph
end

function MM_Graph:Initialize(x_startTimeFrame, x_endTimeFrame, y_lowestPriceText, y_highestPriceText, x_oldestTimestamp, x_currentTimestamp, y_lowestPriceValue, y_highestPriceValue, x_averagePriceText, x_averagePriceValue, x_bonanzaPriceText, x_bonanzaPriceValue)

  -- (xStartLabelText, xEndLabelText, yStartLabelText, yEndLabelText, xStartValue, xEndValue, yStartValue, yEndValue, xPriceText, xPriceValue)

  -- xStartLabelText / x_startTimeFrame = "5 days ago"
  -- xEndLabelText / x_endTimeFrame = "Now"

  -- yStartLabelText / y_lowestPriceText = "55.00" with DDS gold
  -- yEndLabelText / y_highestPriceText = "365.00" with DDS gold

  -- xStartValue / x_oldestTimestamp, probably epoch time
  -- xEndValue / x_currentTimestamp, epoch time from GetTimeStamp()

  -- yStartValue / y_lowestPriceValue = 55.00 without DDS
  -- yEndValue / y_highestPriceValue = 365.00 without DDS

  -- xPriceText / x_averagePriceText = "200.00" with DDS gold
  -- xPriceValue / x_averagePriceValue = 200.00 without DDS
  -- xxxxxxxxxx / x_bonanzaPriceText = "215.00" with DDS gold
  -- xxxxxxxxxxx / x_bonanzaPriceValue = 215.00 without DDS

  --

  -- xStartLabel / x_startLabel
  -- xEndLabel / x_endLabel
  -- yStartLabel / y_lowestPriceLabel
  -- yEndLabel / y_highestPriceLabel
  -- xPriceLabel / x_averagePriceLabel
  -- xxxxxxxxxxx / x_bonanzaPriceLabel

  --

  -- self.marker / self.x_averagePriceMarker
  -- self.xxxxxx / self.x_bonanzaPriceMarker

  self.x_oldestTimestamp = x_oldestTimestamp
  self.x_currentTimestamp   = x_currentTimestamp
  self.y_lowestPriceValue = y_lowestPriceValue
  self.y_highestPriceValue   = y_highestPriceValue
  self.x_averagePriceValue = x_averagePriceValue
  self.x_bonanzaPriceValue = x_bonanzaPriceValue

  self:Clear()

  self.paddingY    = 0
  self.paddingX    = 0

  self.x_startLabel = self.labelPool:AcquireObject()
  self.x_endLabel   = self.labelPool:AcquireObject()
  self.y_lowestPriceLabel = self.labelPool:AcquireObject()
  self.y_highestPriceLabel   = self.labelPool:AcquireObject()
  self.x_averagePriceLabel = self.labelPool:AcquireObject()
  self.x_averagePriceLabel:SetHidden(true)

  self.x_averagePriceMarker = self.control:GetNamedChild('AveragePrice')
  self.x_averagePriceMarker:SetHidden(true)

  self.x_startLabel:ClearAnchors()
  self.x_endLabel:ClearAnchors()
  self.y_lowestPriceLabel:ClearAnchors()
  self.y_highestPriceLabel:ClearAnchors()
  self.x_averagePriceLabel:ClearAnchors()
  self.x_averagePriceMarker:ClearAnchors()

  local x, y   = self.control:GetDimensions()
  local top    = self.paddingY
  local bottom = self.x_startLabel:GetFontHeight() * 1.25 + self.paddingY

  self.ySize   = y - (top + bottom)

  self.y_lowestPriceLabel:SetAnchor(LEFT, self.control, BOTTOMLEFT, self.paddingX, -bottom)
  self.y_lowestPriceLabel:SetText(y_lowestPriceText)

  self.y_highestPriceLabel:SetAnchor(LEFT, self.control, BOTTOMLEFT, self.paddingX, -(bottom + self.ySize))
  self.y_highestPriceLabel:SetText(y_highestPriceText)

  local originalAveragePriceValue = ((self.x_averagePriceValue - self.y_lowestPriceValue) / (self.y_highestPriceValue - self.y_lowestPriceValue)) * self.ySize
  self.x_averagePriceValue = originalAveragePriceValue

  self.x_averagePriceLabel:SetText(x_averagePriceText)

  local left = math.max(self.x_averagePriceLabel:GetTextWidth(), self.y_lowestPriceLabel:GetTextWidth(), self.y_highestPriceLabel:GetTextWidth()) + self.paddingX + 5

  self.x_startLabel:SetAnchor(BOTTOM, self.control, BOTTOMLEFT, left, -self.paddingY)
  self.x_startLabel:SetText(x_startTimeFrame)

  self.x_endLabel:SetAnchor(BOTTOMRIGHT, self.control, BOTTOMRIGHT, -self.paddingX, -self.paddingY)
  self.x_endLabel:SetText(x_endTimeFrame)

  local right = self.paddingX + self.x_endLabel:GetTextWidth() / 2

  self.x_startLabel:SetHidden(false)
  self.x_endLabel:SetHidden(false)
  self.y_lowestPriceLabel:SetHidden(false)
  self.y_highestPriceLabel:SetHidden(false)

  self.xSize  = x - (left + right)

  self.xStart = left
  self.yStart = bottom

  self.grid   = self.control:GetNamedChild('Grid')
  local grid  = self.grid
  grid:ClearAnchors()
  grid:SetAnchor(BOTTOMLEFT, self.control, BOTTOMLEFT, left, -bottom)
  grid:SetAnchor(TOPRIGHT, self.control, BOTTOMLEFT, left + self.xSize, -(bottom + self.ySize))

  self.x_averagePriceLabel:SetAnchor(RIGHT, self.grid, BOTTOMLEFT, -5, -self.x_averagePriceValue)
  self.x_averagePriceMarker:SetAnchor(BOTTOMLEFT, self.grid, BOTTOMLEFT, 0, -(self.x_averagePriceValue - 1))
  self.x_averagePriceMarker:SetAnchor(TOPRIGHT, self.grid, BOTTOMRIGHT, 0, -self.x_averagePriceValue)
  self.x_averagePriceLabel:SetHidden(false)
  self.x_averagePriceMarker:SetHidden(false)

  self.textAdjustmentY = self.x_startLabel:GetFontHeight() / 4
end

function MM_Graph:OnGraphPointClicked(self, mouseButton, sellerName)
  local lengthBlacklist = string.len(MasterMerchant.systemSavedVariables.blacklist)
  local lengthSellerName = string.len(sellerName) + 2
  if lengthBlacklist + lengthSellerName > 2000 then
    MasterMerchant:v(1, "Can not append account name. The Blacklist would exceed 2000 characters.")
  else
    if not string.find(MasterMerchant.systemSavedVariables.blacklist, sellerName) then
      MasterMerchant.systemSavedVariables.blacklist = MasterMerchant.systemSavedVariables.blacklist .. sellerName .. "\n"
      MasterMerchant:ClearItemCacheByItemLink(MM_Graph.itemLink)
    end
  end
end

function MM_Graph:MyGraphPointClickHandler(self, button, upInside, sellerName)
  if upInside and button == MOUSE_BUTTON_INDEX_RIGHT then
    ClearMenu()
    AddMenuItem(GetString(MM_BLACKLIST_MENU), function() MM_Graph:OnGraphPointClicked(self, button, sellerName) end)
    ShowMenu()
  end
end

function MM_Graph:AddPoint(x, y, color, tipText, sellerName)
  local point = self.pointPool:AcquireObject()

  point:SetText('.')
  if color then
    point:SetColor(color[1], color[2], color[3], 1)
  end
  point:ClearAnchors()

  x = ((x - self.x_oldestTimestamp) / (self.x_currentTimestamp - self.x_oldestTimestamp)) * self.xSize
  y = (((y - self.y_lowestPriceValue) / (self.y_highestPriceValue - self.y_lowestPriceValue)) * self.ySize) - self.textAdjustmentY

  point:SetAnchor(BOTTOM, self.grid, BOTTOMLEFT, x, -y)
  point:SetHidden(false)

  if tipText then
    point.data = {
      tooltipText = tipText
    }
    point.sellerName = sellerName
    point:SetMouseEnabled(true)

    point:SetHandler("OnMouseEnter", ZO_Options_OnMouseEnter)
    point:SetHandler("OnMouseExit", ZO_Options_OnMouseExit)
  end

end

function MM_Graph:AddYLabel(text, y)
  local label = self.labelPool:AcquireObject()

  label:SetText('|cFFFFFF' .. text .. '|r')
  label:ClearAnchors()

  y = ((y - self.y_lowestPriceValue) / (self.y_highestPriceValue - self.y_lowestPriceValue)) * self.ySize

  label:SetAnchor(RIGHT, self.grid, BOTTOMLEFT, -5, -y)
  label:SetHidden(false)

  local x_averagePriceMarker = self.x_averagePriceMarker
  x_averagePriceMarker:ClearAnchors()
  x_averagePriceMarker:SetAnchor(BOTTOMLEFT, self.grid, BOTTOMLEFT, 0, -(y - 1))
  x_averagePriceMarker:SetAnchor(TOPRIGHT, self.grid, BOTTOMRIGHT, 0, -y)
  x_averagePriceMarker:SetHidden(false)
end

function MM_Graph:Clear()
  self.pointPool:ReleaseAllObjects()
  self.labelPool:ReleaseAllObjects()
end
