-- from votan for tooptip in scroll list rows
local rowData = ZO_ScrollList_GetData(control)

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