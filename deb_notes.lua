-- from votan for tooptip in scroll list rows
local rowData = ZO_ScrollList_GetData(control)

local currencyFormatDealOptions = {
    [0] = { color = ZO_ColorDef:New(0.98, 0.01, 0.01) },
    [ITEM_DISPLAY_QUALITY_NORMAL] = { color = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, ITEM_DISPLAY_QUALITY_NORMAL)) },
--- the other qualities
}

local numItemsOnPage, currentPage, hasMorePages = GetTradingHouseSearchResultsInfo()
local itemLink, icon, itemName, displayQuality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, itemUniqueId, purchasePricePerUnit = GetTradingHouseSearchResultItemInfo
for i=1, numItemsOnPage do
   itemLink = GetTradingHouseSearchResultItemLink(i)
   icon, itemName, displayQuality, stackCount, sellerName, timeRemaining, purchasePrice, currencyType, itemUniqueId, purchasePricePerUnit = GetTradingHouseSearchResultItemInfo
end

I believe AGS.callback.ITEM_DATABASE_UPDATE is the one that fires when new unseen results are received and AGS.callback.SEARCH_RESULTS_RECEIVED when a new page is received.

-- From Baertram for close window
--[[
MasterMerchant_OnCloseButtonCallback(buttonVar)
  buttonVar:GetParent():SetHidden(true)
end

All your close buttons should be buttons directly below the TLC(= parent)
So if you use the same func for them all they should all hide their respective parent TLCs

<TopLevelControl movable="true" mouseEnabled="true" name="MasterMerchantGuildWindow" hidden="true">
  <Button name="MasterMerchantGuildWindowCloseButton" inheritAlpha="true"  virtual="true">
  <<-- Stuff -- >>
    <OnClicked>
      MasterMerchant_OnCloseButtonCallback(self)
    </OnClicked>
  </Button>
</TopLevelControl>

<TopLevelControl movable="true" mouseEnabled="true" name="MasterMerchantWindow" hidden="true">
  <Button name="MasterMerchantWindowCloseButton" inheritAlpha="true"  virtual="true">
  <<-- Stuff -- >>
    <OnClicked>
      MasterMerchant_OnCloseButtonCallback(self)
    </OnClicked>
  </Button>
</TopLevelControl>
]]--

--[[
@Sharlikran

--In your rowSetupcallback, where the data table of the row is build, add data.tooltip ="MyTooltipText" or something like data.tooltip = data.location e.g.

--The OnMouseEnter of the rows
control.location:SetHandler('OnMouseEnter', function(controlLocationWeMouseOverAtThisMoment) 
   local rowData = ZO_ScrollList_GetData(controlLocationWeMouseOverAtThisMoment)
   if not data.tooltip then return end 
   ZO_Tooltips_ShowTextTooltip(data.tooltip, TOP, guildSubZone) --not sure where guildSubZone comes from but if it needs to be depenent on the row you mouse over also put it into the data table at the setup function, or determine it WITHIN the OnMouseEnter callback function, so that it get's build for the ACTUAL row you mouse over at the time you mouse over
end)

    but for the ZO_SortList whatever to work the child has to be $(parent)Headers.

It's for the ZO_SortFilterList and yes, it's using an XML template that expects you to specify and create a "Header" and a "List" control
Where header is a ZO_SortHeader control and List is the ZO_SortList used to draw the scroll list with it's rows
That names are fixed as the XML template of that kind of virtual template uses them
And the lua code of the ZO_SortFilterList as well
e.g. https://github.com/esoui/esoui/blob/master/esoui/libraries/zo_sortfilterlist/zo_sortfilterlist.lua#L37
The lua code searches for the control "List"
and "Headers" for teh sort header: https://github.com/esoui/esoui/blob/master/esoui/libraries/zo_sortfilterlist/zo_sortfilterlist.lua#L40
Baertram
@Baertram
07:51
If you want to change this you need to inherit the exisitng class ZO_SortFilterList again to your own class, like it does it itsself upon ZO_SortFilterListBase:Subclass:

ZO_SortFilterList = ZO_SortFilterListBase:Subclass()
--Create your own class
ZO_MyOwnSortFilterList = ZO_SortFilterList:Subclass()
--After that overwrite the functions that you want to recreate, like 
function ZO_MyOwnSortFilterList:InitializeSortFilterList(control)
 self.control = control
    self.list = GetControl(control, "MyOwnListXMLTemplateControlName") 
    ZO_ScrollList_AddResizeOnScreenResize(self.list)

    self.headersContainer = GetControl(control, "MyOwnHeaderXMLTemplateControlName")end
...

    <OnInitialized>

It's just needed if you want to call code as your control initializes
MM probably does not need/use it in the TopLevelControl, but maybe in the List control or somewhere else in the XML. If not, it can also be done within the lua code

About "rowSetupcallback" I had mentioned above in my example code with rowData:
ZO_ScrollList_AddDataType(scrollListControl, dataTypeId, templateName, rowHeight, setupFunction, rowHideCallback, dataTypeSelectSound, resetControlCallback)
I meant the parameter "setupFunction" you pass in here as you define the ZO_SortList's datatype
It's called for each row, using the XML template "templateName", defining it's rowHeight and then setupFunction can be used to transfer stuff from the data of the row to the output XML conrols like columns of the row
or to add stuff to the data tables of the row, which other functions are able to use later on via ZO_ScrollList_GetData(controlLocationWeMouseOverAtThisMoment)
Or you add the data to the datatable as you build the "masterlist" of the ZO_SortList (ZO_SortList example addon -> see :Populate function)
]]--

--[[
btw, if you want to find the virtual templates like ZO_ScrollList, just search in ESOUI source code (github or local) for

name="ZO_ScrollList"

It should find you the defined xml template files then
https://github.com/esoui/esoui/blob/ea3a42c9344a610a1a49293f417b7c24db0da546/esoui/libraries/zo_templates/scrolltemplates.xml#L112

<Control name="ZO_ScrollList" inherits="ZO_ScrollAreaBarBehavior" virtual="true">

Some are defined in this folder: https://github.com/esoui/esoui/tree/ea3a42c9344a610a1a49293f417b7c24db0da546/esoui/libraries/zo_templates
ZO_SortFilterList is in this folder: https://github.com/esoui/esoui/tree/ea3a42c9344a610a1a49293f417b7c24db0da546/esoui/libraries/zo_sortfilterlist
AFAIK for the ZO_SortFilterList in your XML code there needs to be a control name "List" where it will be added to via the lua function
e.g. like this:

<Control name="$(parent)List" inherits="ZO_ScrollList">
                    <Anchor point="TOPLEFT" relativeTo="$(parent)Headers" relativePoint="BOTTOMLEFT" offsetY="3" />
                    <Anchor point="BOTTOMRIGHT" offsetX="-35" offsetY="-32" />
                </Control>

Baertram
@Baertram
May 24 07:43
The Headers need to be some ZO_SortHeader controls containing the sort header columns, like "Name", "Date," "Value" etc. (columns of your output scroll list row)

        <!--Sort headers - VIRTUAL -->
        <Control name="WhisListSortHeader" inherits="ZO_SortHeaderBehavior" virtual="true">
            <Controls>
                <Label name="$(parent)Name" font="MyFontGame20" color="INTERFACE_COLOR_TYPE_TEXT_COLORS:INTERFACE_TEXT_COLOR_NORMAL"  horizontalAlignment="CENTER" verticalAlignment="CENTER" wrapMode="ELLIPSIS">
                        <AnchorFill />
                </Label>
            </Controls>
        </Control>

<!-- Sort headers - NON VIRTUAL ->
                <Control name="$(parent)Headers">
                    <Anchor point="TOPLEFT" offsetX="30" offsetY="51" />
                    <Anchor point="TOPRIGHT" offsetY="51" />
                    <Dimensions y="32" />
                    <Controls>
                        <Control name="$(parent)DateTime" inherits="WhisListSortHeader">
                            <OnInitialized>
                                ZO_SortHeader_Initialize(self, GetString(WISHLIST_HEADER_DATE), "timestamp", ZO_SORT_ORDER_UP, TEXT_ALIGN_LEFT, "ZoFontGameLargeBold")
                            </OnInitialized>
                            <Anchor point="TOPLEFT" />
                            <Dimensions x="135" y="32" />
                        </Control>
                        <Control name="$(parent)Name" inherits="WhisListSortHeader">
                            <OnInitialized>
                                ZO_SortHeader_Initialize(self, GetString(WISHLIST_HEADER_NAME), "name", ZO_SORT_ORDER_UP, TEXT_ALIGN_LEFT, "ZoFontGameLargeBold")
                            </OnInitialized>
                            <Anchor point="TOPLEFT" relativePoint="TOPRIGHT" relativeTo="$(parent)DateTime" />
                            <Dimensions x="200" y="32" />
                        </Control>
                        <Control name="$(parent)ArmorOrWeaponType" inherits="WhisListSortHeader">
                            <OnInitialized>
                                ZO_SortHeader_Initialize(self, GetString(WISHLIST_HEADER_TYPE), "armorOrWeaponTypeName", ZO_SORT_ORDER_UP, TEXT_ALIGN_LEFT, "ZoFontGameLargeBold")
                            </OnInitialized>
                            <Anchor point="TOPLEFT" relativePoint="TOPRIGHT" relativeTo="$(parent)Name" />
                            <Dimensions x="100" y="32" />
                        </Control>
                        <Control name="$(parent)Slot" inherits="WhisListSortHeader">
                            <OnInitialized>
                                ZO_SortHeader_Initialize(self, GetString(WISHLIST_HEADER_SLOT), "slotName", ZO_SORT_ORDER_UP, TEXT_ALIGN_LEFT, "ZoFontGameLargeBold")
                            </OnInitialized>
                            <Anchor point="TOPLEFT" relativePoint="TOPRIGHT" relativeTo="$(parent)ArmorOrWeaponType" />
                            <Dimensions x="90" y="32" />
                        </Control>
                        <Control name="$(parent)Trait" inherits="WhisListSortHeader">
                            <OnInitialized>
                                ZO_SortHeader_Initialize(self, GetString(WISHLIST_HEADER_TRAIT), "traitName", ZO_SORT_ORDER_UP, TEXT_ALIGN_LEFT, "ZoFontGameLargeBold")
                            </OnInitialized>
                            <Anchor point="TOPLEFT" relativePoint="TOPRIGHT" relativeTo="$(parent)Slot" />
                            <Dimensions x="130" y="32" />
                        </Control>
                        <Control name="$(parent)UserName" inherits="WhisListSortHeader">
                            <OnInitialized>
                                ZO_SortHeader_Initialize(self, GetString(WISHLIST_HEADER_USERNAME), "username", ZO_SORT_ORDER_UP, TEXT_ALIGN_LEFT, "ZoFontGameLargeBold")
                            </OnInitialized>
                            <Anchor point="TOPLEFT" relativePoint="TOPRIGHT" relativeTo="$(parent)Trait" />
                            <Dimensions x="80" y="32" />
                        </Control>
                        <Control name="$(parent)Locality" inherits="WhisListSortHeader">
                            <OnInitialized>
                                ZO_SortHeader_Initialize(self, GetString(WISHLIST_HEADER_LOCALITY), "locality", ZO_SORT_ORDER_UP, TEXT_ALIGN_LEFT, "ZoFontGameLargeBold")
                            </OnInitialized>
                            <Anchor point="TOPLEFT" relativePoint="TOPRIGHT" relativeTo="$(parent)UserName" />
                            <Dimensions x="100" y="32" />
                        </Control>
...

Only an example from WishList
check the WishListWindow.xml for the definitions
]]--

--[[
In your lua code you define a subclass of the ZO_SortFilterList e.g.

WishListWindow = ZO_SortFilterList:Subclass()

and then you can build a New function, which calls e.g. a Setup or Initialize function of the ZO_SortFilterList control you create there:

function WishListWindow:New( control )
    local list = ZO_SortFilterList.New(self, control)
    list.frame = control
    list:Initialize()
    return(list)
end

function WishListWindow:Initialize( )
--Scroll UI
    ZO_ScrollList_AddDataType(self.list, WISHLIST_DATA, "WishListRow", 30, function(control, data)
        self:SetupItemRow(control, data)
    end)
    ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight")
    self:SetAlternateRowBackgrounds(true)
...
--Sort headers
--Sort headers
    self.headers = self.frame:GetNamedChild("Headers")
    self.headerDate = self.headers:GetNamedChild("DateTime")
    self.headerSetItemCollectionState = self.headers:GetNamedChild("SetItemCollectionState")
    self.headerName = self.headers:GetNamedChild("Name")
    self.headerArmorOrWeaponType = self.headers:GetNamedChild("ArmorOrWeaponType")
    self.headerSlot = self.headers:GetNamedChild("Slot")
    self.headerTrait = self.headers:GetNamedChild("Trait")
    self.headerQuality = self.headers:GetNamedChild("Quality")
    self.headerUsername = self.headers:GetNamedChild("UserName")
    self.headerLocality = self.headers:GetNamedChild("Locality")

   --Commit/draw the list. RefreshData > calls function BuildMasterList
   self:RefreshData()
end

In the initialize function you define the datatype of the list (used for a unique search possiblity e.g. and other stuff) and youd efine the row virtual template to use for the list (virtual template name from your XML files, here: "WishListRow")

The function WishListWindow:BuildMasterList is reponsible to build your table "masterList" of the sortlist

self.masterList = {}
        local setsData = WL.accData.sets
        for setId, setData in pairs(setsData) do
            table.insert(self.masterList, WL.CreateEntryForSet(setId, setData))
        end

WL.CreateEntryForSet will just create a table entry filling the needed columns for the output stuff
In function WishListWindow:SetupItemRow() you define what column in your row of the XML virtual template "WishListRow" will get what data from the masteList dataTable row
You can set columns hidden here, change the text size, add textures, and so on.
Maybe someone got a pure example of the ZO_SortFilterList and it#s functions somewhere, like the ZO_ScrollListExample addon?
]]--