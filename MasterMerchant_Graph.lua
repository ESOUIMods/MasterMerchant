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
  x_oldestTimestamp, x_currentTimestamp, y_lowestPriceValue, y_highestPriceValue, x_averagePriceText, x_averagePriceValue, x_bonanzaPriceText, x_bonanzaPriceValue)

  --                        (xStartLabelText, xEndLabelText, yStartLabelText, yEndLabelText, xStartValue, xEndValue, yStartValue, yEndValue, xPriceText, xPriceValue)

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
  self.x_currentTimestamp = x_currentTimestamp
  self.y_lowestPriceValue = y_lowestPriceValue
  self.y_highestPriceValue = y_highestPriceValue
  self.x_averagePriceValue = x_averagePriceValue
  self.x_bonanzaPriceValue = x_bonanzaPriceValue

  self:Clear()

  self.paddingY = 0
  self.paddingX = 0

  -- self.x_startLabel = self.labelPool:AcquireObject()
  -- self.x_endLabel   = self.labelPool:AcquireObject()
  -- self.y_lowestPriceLabel = self.labelPool:AcquireObject()
  -- self.y_highestPriceLabel   = self.labelPool:AcquireObject()

  local tooltipControl = self.control
  local grid = self.grid
  local averagePriceLabel = self.x_averagePriceLabel -- average price text
  local bonanzaPriceLabel = self.x_bonanzaPriceLabel -- bonanza price text
  local averagePriceMarker = self.x_averagePriceMarker -- xml, the line
  local bonanzaPriceMarker = self.x_bonanzaPriceMarker -- xml, the line

  -- self.x_averagePriceLabel = self.labelPool:AcquireObject() -- average price text
  self.x_averagePriceLabel:SetHidden(true) -- average price text
  -- self.x_bonanzaPriceLabel = self.labelPool:AcquireObject() -- bonanza price text
  self.x_bonanzaPriceLabel:SetHidden(true) -- bonanza price text

  self.x_averagePriceMarker:SetHidden(true)
  self.x_bonanzaPriceMarker:SetHidden(true)

  -- x days and now
  self.x_startLabelMarker:SetHidden(true) -- xml, the line
  self.x_endLabelMarker:SetHidden(true) -- xml, the line

  self.y_highestPriceLabelMarker:SetHidden(true)
  self.y_lowestPriceLabelMarker:SetHidden(true)

  -- self.x_startLabel:ClearAnchors()
  -- self.x_endLabel:ClearAnchors()
  -- self.y_lowestPriceLabelMarker:ClearAnchors()
  -- self.y_highestPriceLabel:ClearAnchors()
  self.x_averagePriceLabel:ClearAnchors()
  self.x_bonanzaPriceLabel:ClearAnchors()
  self.x_averagePriceMarker:ClearAnchors()
  self.x_bonanzaPriceMarker:ClearAnchors()

  local x, y = tooltipControl:GetDimensions()
  local top = self.paddingY
  local bottom = self.x_startLabelMarker:GetFontHeight() * 1.25 + self.paddingY

  self.ySize = y - (top + bottom)

  -- self.y_lowestPriceLabel:SetAnchor(LEFT, self.control, BOTTOMLEFT, self.paddingX, -bottom)
  self.y_lowestPriceLabelMarker:SetText(y_highestPriceText)

  -- self.y_highestPriceLabel:SetAnchor(LEFT, self.control, BOTTOMLEFT, self.paddingX, -(bottom + self.ySize))
  self.y_highestPriceLabelMarker:SetText(y_highestPriceLabelText)
  local originalAveragePriceValue = ((self.x_averagePriceValue - self.y_lowestPriceValue) / (self.y_highestPriceValue - self.y_lowestPriceValue)) * self.ySize
  self.x_averagePriceValue = originalAveragePriceValue

  self.x_averagePriceLabel:SetText(x_averagePriceText)
  self.x_averagePriceLabel:SetColor(1, 0.996, 0, 1)

  local left = math.max(self.x_averagePriceLabel:GetTextWidth(), self.y_lowestPriceLabelMarker:GetTextWidth(),
    self.y_highestPriceLabelMarker:GetTextWidth()) + self.paddingX + 5

  -- self.x_startLabel:SetAnchor(TOP, self.control, BOTTOMRIGHT, left, -self.paddingY)
  self.x_startLabelMarker:SetText(x_startTimeFrame)

  -- self.x_endLabel:SetAnchor(BOTTOMRIGHT, self.control, BOTTOMRIGHT, -self.paddingX, -self.paddingY)
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

  -- local _, point, relTo, relPoint, offsX, offsY = self.x_averagePriceLabel:GetAnchor(0)
  -- MasterMerchant
  -- PopupTooltipGraph
  if originalBonanzaPriceValue == originalAveragePriceValue then
    self.x_averagePriceValue = self.x_averagePriceValue + 15
  end
  if self.x_averagePriceValue < 15 then self.x_averagePriceValue = 15 end
  if self.x_averagePriceValue > 105 then self.x_averagePriceValue = 105 end

  self.x_averagePriceLabel:SetAnchor(RIGHT, self.grid, BOTTOMLEFT, -5, -self.x_averagePriceValue)
  self.x_averagePriceMarker:SetAnchor(BOTTOMLEFT, self.grid, BOTTOMLEFT, 0, -(self.x_averagePriceValue - 1))
  self.x_averagePriceMarker:SetAnchor(TOPRIGHT, self.grid, BOTTOMRIGHT, 0, -self.x_averagePriceValue)
  self.x_averagePriceLabel:SetHidden(false)
  self.x_averagePriceMarker:SetHidden(false)
  if x_bonanzaPriceValue then
    local originalBonanzaPriceValue = ((self.x_bonanzaPriceValue - self.y_lowestPriceValue) / (self.y_highestPriceValue - self.y_lowestPriceValue)) * self.ySize
    self.x_bonanzaPriceValue = originalBonanzaPriceValue
    if self.x_bonanzaPriceValue < 15 then self.x_bonanzaPriceValue = 15 end
    if self.x_bonanzaPriceValue > 105 then self.x_bonanzaPriceValue = 105 end

    local priceDif = math.abs(originalAveragePriceValue - originalBonanzaPriceValue)
    local isOverlapping = priceDif < 15
    if isOverlapping and originalBonanzaPriceValue > originalAveragePriceValue then
      self.x_bonanzaPriceValue = self.x_averagePriceValue + 15
    elseif isOverlapping and originalBonanzaPriceValue < originalAveragePriceValue then
      self.x_bonanzaPriceValue = self.x_averagePriceValue - 15
    elseif isOverlapping and originalBonanzaPriceValue == originalAveragePriceValue then
      self.x_bonanzaPriceValue = self.x_averagePriceValue - 15
    end
    if self.x_bonanzaPriceValue < 0.01 then self.x_bonanzaPriceValue = 0.01 end

    self.x_bonanzaPriceLabel:SetText(x_bonanzaPriceText)
    self.x_bonanzaPriceLabel:SetColor(0.21, 0.54, 0.94, 1)
    self.x_bonanzaPriceLabel:SetAnchor(RIGHT, self.grid, BOTTOMLEFT, -5, -self.x_bonanzaPriceValue)
    self.x_bonanzaPriceMarker:SetAnchor(BOTTOMLEFT, self.grid, BOTTOMLEFT, 0, -(self.x_bonanzaPriceValue - 1))
    self.x_bonanzaPriceMarker:SetAnchor(TOPRIGHT, self.grid, BOTTOMRIGHT, 0, -self.x_bonanzaPriceValue)
    self.x_bonanzaPriceLabel:SetHidden(false)
    self.x_bonanzaPriceMarker:SetHidden(false)
  end

  self.textAdjustmentY = self.x_startLabelMarker:GetFontHeight() / 4
end

function MM_Graph:OnGraphPointClicked(graphPointControl, mouseButton, sellerName)
  local lengthBlacklist = string.len(MasterMerchant.systemSavedVariables.blacklist)
  local lengthSellerName = string.len(sellerName) + 2
  local parentControl = graphPointControl:GetParent()
  local itemLink = parentControl.itemLink
  if not itemLink then MasterMerchant:dm("Warn", "OnGraphPointClicked has no itemLink") end
  if lengthBlacklist + lengthSellerName > 2000 then
    MasterMerchant:dm("Info", GetString(MM_BLACKLIST_EXCEEDS))
  else
    if not MasterMerchant:IsInBlackList(sellerName) then
      MasterMerchant.systemSavedVariables.blacklist = MasterMerchant.systemSavedVariables.blacklist .. sellerName .. "\n"
      MasterMerchant:ResetItemInformationCache()
      MasterMerchant.blacklistTable = MasterMerchant:BuildTableFromString(MasterMerchant.systemSavedVariables.blacklist)
    end
  end
end

function MM_Graph:OnSellerNameClicked(self, mouseButton, sellerName, itemLink)
  local lengthBlacklist = string.len(MasterMerchant.systemSavedVariables.blacklist)
  local lengthSellerName = string.len(sellerName) + 2
  if lengthBlacklist + lengthSellerName > 2000 then
    MasterMerchant:dm("Info", GetString(MM_BLACKLIST_EXCEEDS))
  else
    if not MasterMerchant:IsInBlackList(sellerName) then
      MasterMerchant.systemSavedVariables.blacklist = MasterMerchant.systemSavedVariables.blacklist .. sellerName .. "\n"
      MasterMerchant:ResetItemInformationCache()
      MasterMerchant.blacklistTable = MasterMerchant:BuildTableFromString(MasterMerchant.systemSavedVariables.blacklist)
    end
  end
end

function MM_Graph:MyGraphPointClickHandler(self, button, upInside, sellerName)
  if upInside and button == MOUSE_BUTTON_INDEX_RIGHT then
    ClearMenu()
    AddMenuItem(GetString(MM_BLACKLIST_MENU_SELLER), function() MM_Graph:OnGraphPointClicked(self, button, sellerName) end)
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
  end

end

function MM_Graph:Clear()
  self.pointPool:ReleaseAllObjects()
end
