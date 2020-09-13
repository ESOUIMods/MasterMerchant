This Add-on is not created by, affiliated with or sponsored by ZeniMax Media
Inc. or its affiliates. The Elder Scrolls&reg; and related logos are registered
trademarks or trademarks of ZeniMax Media Inc. in the United States and/or
other countries. All rights reserved.

## Intent

Repository for personal changes as I am not trying to take over Master Merchant. If at such time @Philgo68 and @khaibit return to ESO then they are welcome to use my changes.

## ChangeLog for 3.0.9

- Fix for error generated guild finder rather then guild history

## ChangeLog for 3.0.8

- Added localization strings for new "Use Sales History Size Only" to the rest of the languages

## ChangeLog for 3.0.7

- Fix Price Calculator Bug
- Add toggle to ignore min and max count when trimming sales data

## ChangeLog for 3.0.6

- Same as 3.0.4
- More recipe updates from - Dolgubon
- Fix for Lua errors for new saved vars - Dolgubon

## ChangeLog for 3.0.5

- Reverted back to 3.0.3 until a fix for Lua errors can be implemented

## ChangeLog for 3.0.4

- Adjustment to item link trait discovery Aldanga
- Update to recipe calculations Dolgubon (Still some recipes may not show mat price)
- Added event index count to guild history tab and the amount of history loaded in hours, days. Using a built in Zenimax routine. It does not show 1d 3h, just 1 day or 2 days.

## ChangeLog for 3.0.3

- Updated event monitor so it will properly activate after zoning

## ChangeLog for 3.0.2

- Added decrement button since background scan is no longer present. It will deduct 50 from the event index, more like a rewind just a bit if you think you missed a sale.

## ChangeLog for 3.0.1

- Uncommented a few things in MM clean when checking for numbers that should not be strings

## ChangeLog for 3.0.0

- Initial changes to add an event monitor for guild history as it comes in. This is the same feature as introduced in 2.4.8.

## ChangeLog for 2.5.0

- Reverted MM to the sate of Philgo's last update 2.3.1
- Fix for MasterMerchant_Util.lua:466 to fix bug introduced in 2.3.1
- Reverted all scanning mechanics to 2.3.1
- Reverted indexing and filtering mechanics to 2.2.1
- By reverting indexing and filtering mechanics this fixes the issues with personal sales not appearing in the master merchant window
- Updated Kiosk flip times for Tuesday. Which includes the removal of tracking the 9 day week prior to the kiosk flip.

## ChangeLog for 2.4.9

- Updated /mm help
- Typecast certain variables for comparisons. Which hopefully will not allow anymore duplicate sales entries.
- Changed verbose level for Event Monitor (Now verbose 5) Default verbose is 4
- Hopefully fixed bug with MasterMerchant.lua line:2218

## ChangeLog for 2.4.8

- Simple indexing and scanning removed (introduced in 2.3.1)
- Background scan removed (See NOTE1)
- /mm missing removed (See NOTE2)
- Added guild history monitoring
- Improved duplicate checking when using /mm dups

NOTE1: During testing the requests from the server were denied 1440 times and granted 30 times over a course of 40 minutes for 3 different guilds.

NOTE2: Guild history is not sorted. Therefore you can not start at a certain place by tracking a specific time or event and scan from that point. The only viable option is to track the number of events and then avoid scanning the same events.

## ChangeLog for 2.4.7

- Left a debug message active sorry

## ChangeLog for 2.4.6

- Left a debug message active sorry

## ChangeLog for 2.4.5

- Revised Kiosk cut off time routines

## ChangeLog for 2.4.4

- Removed Philgo's Simple Indexing and Simple Scanning.

Note: At this time there are still performance issues. I will be addressing them as time permits. Removing Simple Indexing and Simple Scanning will introduce old performance issues. There isn't anything I can do about that at this time. I went with functionality over performance for now.

## ChangeLog for 2.4.3

- Fixed some typos

## ChangeLog for 2.4.2

- Revised Kiosk cut off time routines

NOTE: Needs testing for EU

## ChangeLog for 2.4.1

- Oops missed a few debug message thresholds

## ChangeLog for 2.4.0

- Time between scans 5 minutes minimum now because data is provided by the server without requesting it.
- Time between requests for data 30 seconds because the server already gives you data about once a minute.

NOTE: After more testing with my new cache library there is no reason to send frequent requests to the server for more data because the request is denied. Data is already provided about every minute. My cache library shows that with that kind of interval, 2 to 3 minutes you would be caught up as far as sales for your guild. After that you would just receive data you already have plus any new sales. This includes being logged out for 5 hours.

## ChangeLog for 2.3.9

- Removed some of the additional delays.

## ChangeLog for 2.3.8

- Added debug framework for odd reported errors

## ChangeLog for 2.3.7

- First adjustment for 9 day week, then regular 7 day weeks.
- More updates as information is confirmed.

## ChangeLog for 2.3.6

- Adjusted position of UI element 'Hide Offline' when viewing guild sales from guild roster

## ChangeLog for 2.3.5

- Adjusted routine to account for when the guild store is offline and we are waiting for Zenimax to resolve the issue

## ChangeLog for 2.3.4

- Use Zenimax API function GetGuildKioskCycleTimes() instead of previous method

## ChangeLog for 2.3.3

- Removed left over debug routines for mouse over controls when verbose was set to 5

## ChangeLog for 2.3.2

- Fix for MasterMerchant_Util.lua:466
- More refactoring for how Libraries load

## ChangeLog for 2.3.1

- Switched Guild cut-over time.
- Added new recipes for Craft Cost calculations.
- Added 'Simple Guild History Scanning' setting which makes guild scanning much simpler, but may leave gaps in your historical data.
- Added 'Minimal Indexing' setting option to conserve memory at the expense of search flexibility and speed in the MM window.
- Reworked Libraries

## ChangeLog for 2.2.1

Turbo Mode removed at ZOS's request.

## ChangeLog for 2.2.0

Turbo Mode
-  '/mm turbo' will toggle Guild Scanning Turbo Mode on/off.
-  Please use Turbo mode sparingly, think of the poor servers!
-  Turbo mode is not available from 1 hour before trader flip until 1 hour after trader flip.
-  Turbo mode status is NOT remembered across reloads/logins and must be manually activated.
When you join a new guild, MM scans back only 3 days to get you started. You can manually load more with the '/mm missing' command.
Added new recipes to Craft Cost calculations.
Please visit tinyurl.com/MMIssueGuide if you are having any issues with MM.
'/mm help' gives some details on MM options and functions.


## ChangeLog for 2.1.0a
Updated for LibExecutionQueue for Scalebreaker / 100028
Change guild history call to try to avoid getting kicked on slow machines.  Should not affect data loading times.

## ChangeLog for 2.1.0
Update for Scalebreaker / 100028
Adjusted sales history API calls.

## ChangeLog for 2.0.8b
Adjusted Chat and Center screen announcements timing.

## ChangeLog for 2.0.8a
Eliminated error when /mm missing tries to scan a guild with no sales.

## ChangeLog for 2.0.8
Changed guild history scanning to happen in parallel.
Adjusted "verbose" setting, creating different levels of messages MM will provide:  0 - Nearly Silent to 5 - Debugging Level Messages.
Added scan status (in %) for each guild, if your "verbose" setting is 4 or higher.
Scanning for the first time after install or after doing a reset will now go back only 3 days. (You can use /mm missing to scan back further if you would like.)
(Note: /reloadui or switching characters retains the downloaded guild sales history, and MM will pick up from there.)
(Note: If you are getting FPS pauses when scanning, make sure the Guild History tab is not on the SALES Category.)

## ChangeLog for 2.0.7
Update for Elsweyr / 100027
Indexing speed adjustments (with sirnsidiator.)  Indexing now 5 times faster, and takes less memory.
Changed /mm missing to allow for guild and time designation.
Fixed MM Statistics Window.
Adjusted scanning for new ZOS API limitations.

## ChangeLog for 2.0.6
Added some protection around Guild Store listing screen to avoid "user:/AddOns/MasterMerchant/MasterMerchant_UI.lua:1454: attempt to index a nil value"
Adjusted "In Combat" scan pausing a bit more (Please let me know if this help in dungeons/Cyrodiil for those few that were having issues.)
Fixed some odd item links that did not show craft costs
Added MM info to housing storage chest item popups
Added MM info to recipe/furniture crafting item popups
Added some protection around TRADING_HOUSE use to help gamepad mode users

## ChangeLog for 2.0.5
Reworked the Awesome Guild Store integration for Wrathstone version (Thanks sirinsidiator for this Awesome addon)
The MM Deal and Profit filters will be available when AGS updates to Wrathstone
Fixed "In Combat" scan pausing (thanks mubcrabs)

## ChangeLog for 2.0.4a
Restore sales data on guild store listings
Fix typo in the item right click menu
(Some other addons may cause the menu items to double up (ex. Furniture Preview))

## ChangeLog for 2.0.4
Update for Wrathstone / 100026
Adjusted for new Guild Store layout/features
Adjusted Scan Frequency setting to wait up to 1 hour
Adjusted right click menus for AssemblerManiac
Paused guild store scanning/processing while in combat (thanks mubcrabs)
Updated recipe/glyph list for Crafting Cost calculations
Added depends on LibExecutionQueue
Added protection code around customTimeframe / customTimeframeType

## ChangeLog for 2.0.3b
Fixed GuildSalesAssistant call.

## ChangeLog for 2.0.3a
Made explicit dependency on LibExecutionQueue
Added protection to avoid "operator * is not supported for nil * number" error in AddRosterStats
Updated the APIVersion in the LibExecutionQueue library

## ChangeLog for 2.0.3
Update for Murkmire / 100025
Completed smoothing of loading and scanning code to avoid choppiness while loading
Adjusted History and Cleaning routines to be more accurate/pick up more data
Added "verbose" setting, to adjust MM feedback during processing (defaults to "ON")
Added "/mm slide" function for kindred
Added translation BR for Brazilian Portuguese, provided by mlsevero
Updated recipe/glyph list for Crafting Cost calculations

## ChangeLog for 2.0.2
Update for Wolfhunter / 100024
Enhanced "/mm clean" to re-index recipes that had irrelevent level information, making each level recipe price out as a different item
Smoothed out loading code to try to avoid choppiness while loading  (More to come)
Updated recipe/glyph list for Crafting Cost calculations
*** Run "/mm clean" to fix Alinor Patterns ***

## ChangeLog for 2.0.1
Update for Summerset / 100023
Made Delay Initialization Startup Standard (Should help those having login issue with MM on and large data sets)
Updated recipe/glyph list for Crafting Cost calculations
Updated Ranges for History Depth, Min Item Count
Enhanced "/mm clean" to remove more bad data
Enhanced TruncateHistory to properly remove some old data that was missed
Kept the scroll thumb selector in the MM window from getting so small you can't see it
Fixed error that would abort indexing early in some circumstances (Your MM Initialization will be back up to the time it needs to be, and filtering will be fast and accurate)

## ChangeLog for 2.0.0
Update for Dragon Bones / 100022
Adjusted  /mm clean  and  /mm dups  to catch and remove more types of bad data
Updated recipe/glyph list for Crafting Cost calculations

## ChangeLog for 1.9.9
Update for Clockwork City / 100021
Fixed overrides of TradingHouse functions so you can buy from guild stores again!!

## ChangeLog for 1.9.8
Update for Horn of the Reach / 3.1.x / 100020
Added protection code around custom timeframe selection.
Update to latest LibAddonMenu Library
Added MM Options to Craft Bag Right Click Menu (For Sylvie)
Corrected the Gear Creation Link to Chat (Thanks AssemblerManiac)

## ChangeLog for 1.9.7
Update to new Awesome Guild Store filtering interface  (Thanks sirnsidiator)
Added Setting to turn Crafting Costs On/Off (Still need translations for SK_SHOW_CRAFT_COST_NAME and SK_SHOW_CRAFT_COST_TIP)
Enhanced mouse over text on graph (for AssemblerManiac)
Added support for MM info in Inventory Insight listings (for AssemblerManiac)
Made /MM functions case insensitive (For Sylvie)

## ChangeLog for 1.9.6
Update for Morrowind / 3.0.x / 100019
Fixed Center Screen Announcements
Added Crafting Costs for Recipes, Patterns, etc. and Glyphs
Slight Adjustment to Trim Decimal processing
Added more checks in the "/mm clean" function
Fixed Sales Time Ordering
Added protection around links that are not Items (Books, Achievements, etc..)

## ChangeLog for 1.9.5
Update for Homestead / 2.7.x / 100018
One small change to ignore some potential bad data

## ChangeLog for 1.9.4
Update for Guild Trader change over time change.
Inserted updated Russian translation.

## ChangeLog for 1.9.3
Update for One Tamriel / 2.6.x / 100017
Added Sort by Guild to MM windows.
Added User defined time range to the MM windows and the Guild Roster.  Check MM addon settings under deal and calculation options.

## ChangeLog for 1.9.2
Update for Shadows of the Hist / 2.5.x / 100016
Some protection code in DealCalc function to avoid DealCalc.lua:65: operator < is not supported for number < nil type errors.
Japanese translation by k0ta0uchi
Experimental export function

## ChangeLog for 1.9.1
Adjustments/fixes to information displayed on guild roster.

## ChangeLog for 1.9.0
Dark Brotherhood compatibility - changed filtering from VR to CP  (ex. VR15 = CP150)
Added total line to offline sales report
Fixed odd error when holding down <ctrl><shift>
Changed % change column on the roster to Generated Gold for the Guild (The portion of the sales tax that goes to the guild)
Added EU Megaserver calc for Guild Trader switch over time
Added prefix (b,s) to player name for additional filtering  (EX. s@Philgo68 will just show Phil's sales, b@Philgo68 will show records where Phil is the buyer)
Easy MM turn off - Made all Master Merchant addon files dependant on MM00Data, so you just have to unselect MM00Data and all of MM with turn off

## ChangeLog for 1.8.6
Got rid of the odd number at the end of Stats to Chat messages

## ChangeLog for 1.8.5
Added some protection code around the new item description

## ChangeLog for 1.8.4
Updated LibAddonMenu and LibStub libraries

## ChangeLog for 1.8.3
Fix for searching in MM windows.
Adjusted method for adding description to saved data hoping to help resolve startup issue some are having.

## ChangeLog for 1.8.2
Updated for Thieves Guild
Adjusted item description in saved data
Handle some more Items when changing Level/Quality
Beginnings of listings features.   Coming Soon (tm)

## ChangeLog for 1.8.1
Added sales information text tips to sales chart. (Setting: Tips on Graph Points)
Added item sales info/quality/level selector in tooltip. (Setting: Level/Quality Selectors)
Added a "deal" setting for items with no sales history, to replace the hardcoded green deal for items with no sales data. (Setting: No Data Deal Rating)
Added item right click option to show item info in the popup tooltip.
Added item popup right click option to send item/sales stats to chat.
Added "/mm invisible" to reset window locations in case they get positioned off the screen.  Try this if your MM windows are not showing up.

## ChangeLog for 1.8.0
Update compatibility to API version 100013 (Orsinium)
Added new GetGuildEventId instead of having to rely on timestamp system
Adjusted matching code to handle changes in ItemLink format

## ChangeLog for 1.7.2
Added an option to turn on/off the Display Listings chat message.
Adjusted Standard Deviation calculation for stacked items. (Thanks @croachroach)
Added a % change column on the guild roster.  Today, This Week and Last Week timeframes now calculate a % change from the period before. (sponsored by @mjromeo and ETU)
Slight adjustment in anticipation of new AGS fix.

## ChangeLog for 1.7.1d
Added support for Imperial City/1.7 release.
Added Min/Max Item Sale count to better manage fast selling and slow selling items.  MM will only purge sales records by date if you have more than the min, and will not keep more than the max number of sales for one item.
Added an option to put the MM value of items on your inventory and deconstruction item lists.
Added a "/mm clean" option to scan for and remove malformed sales records.
Created an Execution Queue library for long running/sequential operations.

## ChangeLog for 1.6.21/1.6.21a
** Dedicated to Amy and her puppies!! Please say a prayer for them.  **
Adjusted tooltips to show item count for stackable items.
Adjusted Auto Advance to Next Page to handle going backward to previous pages. Fixed in 1.6.21a.
Fixed Buyer blacklist checking.
Adjusted Outlier price checking.
Removed Outlier transactions from scatter chart also.
Added additional duplication checking and added /mm dups command to check for and remove duplicate records if they exist.
Russian translation from KirX - let me know if this works and is correct please.  I'm not sure the file came through properly.

## ChangeLog for 1.6.20
SPEED - Initialization is now 3 times faster and filtering the guild item summary list is at least 15 times faster.

## ChangeLog for 1.6.19
Adjusted Guild Item to summarize better and show count of both transactions and items.  Ex.  4 sales totaling 400 items. (Per @eg0b0y's specs - IBoB auction)
Buyers are now checked against the blacklist (You can blacklist yourself to keep your great finds from pulling down the average.)
Added some new filters to the item list. (Trait, type, quality.  see /mm help)
Made Item list only display your default number of days worth of sales.  Loading 380k records was too slow...

## ChangeLog for 1.6.18a
Fix for user:/AddOns/MasterMerchant/MasterMerchant_Util.lua:383: attempt to index a nil value

## ChangeLog for 1.6.18
Added Auto Next Page Option: If all items are filtered out on a guild store page, auto advance to the next page.
Fixed UI error on <ctrl-shift>.
Fixed Average cost not getting into price box when listing stackable items.
Fix crash when trying to filter MM Item Sales Summary info (I think.)

## ChangeLog for 1.6.17
Changed the Guild Item list to have a personal view as well as the guilds wide view.
Removed "0" lines from the MM to make them cleaner since you can see members with no sales/purchases on the guild tab now.
Adjusted Items and People in the MM windows to have right click menus.
Added grid lines to the scatter chart.  Looks much cleaner.
Adjusted tip text slightly
Saucy features
-Added Profit/Margin % switch for the guild store listings
-Added a Potential Profit Filter to the AGS integration

## ChangeLog for 1.6.16
Fix for Guild Rankings Bug
Scatter Chart dots are now colored to match your guild chat color.  Easily see where things are selling!!

New Calculation and Tip Options:
- Focus: Set days ranges to focus on recent sales, and assign them to Ctrl / Shift keys.
- Blacklist: List player(s) and/or guild(s) you would like to have excluded from pricing calculations.

Guild Ranking View by Items - See what Items are hot in your guilds!!

## ChangeLog for 1.6.15
Integration with new Awesome Guild Store. - Thanks sirinsidiator!!

## ChangeLog for 1.6.14
Roster display improvements including sorting and better compatibility with other roster addons.
Improved German translation - Thanks Balver

## ChangeLog for 1.6.13
Happy Easter!!!
Added a Pricing History Scatter Chart - enable it in the Settings/Addon Settings/Master Merchant options page.
All the dots are a graph of all the sales you've seen.  Price on the left, timeframe on the bottom.  Each dot is a unit price of a sale.

This release is dedicated to @freakyfreak for his awesome support with testing and gold!!

## ChangeLog for 1.6.12
Added a settings option for The Guild Roster Info.
Removed a debug line I forgot to remove.
Honors Price Tracker "Show only if key is pressed" option if it is installed


## ChangeLog for 1.6.11
Significantly improved the initialization after character load.
Moved Sales and Scanning related storage to the system level, so all accounts on the machine will share sales history data.
Added the pricing tooltips onto a few more windows.
Added enhanced duplication checking code to help capture all sales without duplicates. (Thanks Arkadius for the beginnings of this.)
Added "/mm help"
Added "/mm missing" feature to scan for sales that may have been missed.
Added "/mm clearprices" to remove your listings price history.
Made adjustments to the timeframes on the MM guild page.
Show Purchases/Sales on the guild tab also.
Upgrades to the latest LibMediaProvider library.


## ChangeLog for 1.6.10
Moved initialization code back to before character display and reduced init time greatly.
Added settings option to move the initialization to after character load for those that have problems logging in.

## ChangeLog for 1.6.9
Removed the chat messages during scanning, except for the initial scan or after a complete reset.

## ChangeLog for 1.6.8
Adjusted initial scan logic to be smoother and not timeout for large initial 10 day scan.
Adjust initialization to login faster to avoid timeout, but NOTE: The screen will hang for up to 20 seconds on initial setup.
Fixed mini stats window for large number of sales.
Icons will update as new sales are seen.
Added options to ignore outlier prices and to round prices to the near gold piece.

## ChangeLog for 1.6.7
Went to Europe for a while, or at least the EU server...
Fix for guild that would not return history correctly, would just scan forever.
Another fix for Stat window slider errors.
Adjusted special characters in the translation files.

## ChangeLog for 1.6.6
Additional fix for UI issue when you filter out all items on the page with the Deal Range
Adjusted sorting and added sort by name on guild list
Disconnected Buyer/Seller toggle so item list and guild list are independent
Possible fix for Stat window slider errors.

## ChangeLog for 1.6.4
Fix for issue when turning Show Full Price Off
Fix for UI issue when you filter out all items on the page with the Deal Range

## ChangeLog for 1.6.3
Awesome Guild Store Integration
Adjusted White Deal Range to include slightly below market listings
Added Feedback Window

## ChangeLog for 1.6.2
Updated Libraries
Stopped /reloadui in ESO 1.6 if it's a fresh install

## ChangeLog for 1.6.1
Added custom Deal Calculation for @freakyfreak
Added row numbers to grids
Adjusted listings notification format
Clarified ESO 1.6 conversion message

## ChangeLog for 1.6.0
Changed the guild history scanning code a little to try to avoid drops/dupes
Updated to 1.6 API (100011)
**Please note the first time, and only the first time, you run ESO 1.6 your history must be converted to the new item format.  The app will automatically /reloadui 16 times and then you will be converted.

## ChangeLog for 1.0.3
Added Buyer listing to guild window (just click the column header to switch back and forth, like the item window)
Added Custom Deal Calculations for @Causa

## ChangeLog for 1.0.2
GSA support (with dopiates help)
Set name searching on Item Window  (ex. Vr14 leech)
Broke out deal calculation code into MasterMerchant_DealCalc.lua if anyone wants to play with that code
Minor formatting adjustments

## ChangeLog for 1.0.1
Added the missing MM00Data Sub addon

## ChangeLog for 1.0.0
Fixed Right click menu to avoid protection error
Added 60 day history (adjustable in Addon Settings)
Added a 28 Day Ranking chart
Added support for upcoming GSA update - MM will be the Data collection UI for GSA offline application

## ChangeLog for 0.9.9
Added deal tip to your listings page so you can easily check your listings against the market.
Added "Stats to Chat" to the right click menu in a number of places.


## ChangeLog for 0.9.8a
  Fixed typo

## ChangeLog for 0.9.8
  First version by @Philgo68
  A bunch of new features
  Update for patch 1.5; updated API version


--Shopkeeper ChangeLog:

## ChangeLog for 0.9.7(a)
  Update for patch 1.4; updated API version
  Modified stats slider so "Using all data" is at the right-most limit instead of left-most.
  0.9.7a filters out the guild trader hiring events that are now apparently included in purchases.

## ChangeLog for 0.9.6
  Big re-write of how data is stored, searched, and sorted to improve memory usage
    (for the morbidly curious: implemented an inverted index for searching, replaced Lua's default quicksort implementation for
     tables with Shellshort, and reduced redundant copies of sale event info in tables.)
  Added new option to disable on-screen alerts while in Cyrodiil.  (Chat alerts still show, if enabled.)
  Moved the item quantities in the sales history window to more closely match the default UI presentation.
  Increased maximum history size since memory usage has been reduced.

## ChangeLog for 0.9.5
  Bug fix to handle other addons requesting sales events (leading to dupes in Shopkeeper)
  0.9.5a is a re-release to fix an unfortunate typo

## ChangeLog for 0.9.4
  Offline sales report (optional report in chat of what you sold while offline)
  Reset button now has a confirmation dialog associated with it
  Reset and Refresh buttons will now be disabled (dimmed out) and a 'wait' animation will play when a scan is in progress
  Fixed bugs related to me making a typo in the sorting functions
  Fixed bugs related to the search box, updating the slider range, and correctly carrying over your search between full and mini windows
  Further refined the store searching - login search will be faster again now, and better handle the upcoming changes in Update 4
  Increased maximum history size to 15000 - if you use several other memory intensive addons this may cause issues!
  Optimized searching and sorting routines to be a little more efficient with large sales histories
  French localization updates (thanks jupi!)

## ChangeLog for 0.9.3
  Fix for statistics window throwing an error if you have sales events in your history from guilds you're no longer in
  (Possible) fix for the "occasional item duplication upon login" bug
  Internationalization tweaks

## ChangeLog for 0.9.2
  Fix to event-based scanning to (hopefully) stop the dupes people are seeing
  Fix to alerts to (hopefully!) stop the stuck on screen alerts people would see when alt-tabbing
  French localization is now live!  Merci bien to jupiter126/Otxics on the EU Server for the translation work!
  New option in the addon settings to make all your settings account-wide, rather than character-specific.
  Statistics window resized slightly to accomodate...per-guild filters!
  The day range slider is also smarter and will hide entirely if you have less than 2 days' worth of your sales to work with.
  Some UI tweaks to make all languages fit better

## ChangeLog for 0.9.1
Nothing major here, but either I or esoui.com may have borked 0.9b's files so uploading a new release with some minor tweaks here and there to get a version that doesn't seem to intermittently be missing bindings.xml and LibAddonMenu

## ChangeLog for 0.9b
  Further rewrite of part of the scanning routines to be more accurate
  Some small tweaks to the time display routines (will go up to 90 seconds before saying 1 minute, 90 minutes before 1 hour, etc.)
  Fixes to on-screen alerts to avoid 'missing' multiple identical alerts
  GUILD TRADER SUPPORT! Buyer names now have a gold bag icon next to them if they are not in the guild (i.e. bought at your guild's trader kiosk)
  Stats Window now also shows you percentage of sales made at the guild trader
  Other minor tweaks and optimizations as we push towards a fully-translated, fully-functional 1.0 release!

## ChangeLog for 0.9a
  Rewrite of part of the scanning routines to be more accurate
  Fixes for odd behavior in the stats window
  Fixes for the "Alert flood" issue if you sell multiple items between scans
  Misc. other small bugfixes

## ChangeLog for 0.9 (version jump due to being nearly feature-complete):
  Added a new smaller view mode for the main window
  Added sales stats!  Click on the "list" icon at the top of the main window to toggle.
  Search field now searches item names
  Fixes for one case where items bought close together don't all trigger alerts; there are still some odd cases I'm working on

## ChangeLog for 0.3:
  Added ability to toggle between gross/total sales price and per-unit price displays
  Better support for multiple accounts that use the same computer
  Further improvements to store scanning
  UI improvements - Shopkeeper closes along with most other UI scenes now (bank, crafting station, etc.)

## ChangeLog for 0.2a:
  German localization updated/fixed (Credit to Urbs of the EU Server for his hard work on this!)

## ChangeLog for 0.2:
  German localization is complete!
  Fixed missing localizations on Reset/Refresh buttons.
  Fixed a minor license issue.
  Sound options added for alerts.
  On-screen and chat alert options separated.
  Shopkeeper button on guild store screen moved down slightly.
  Fixed alert swarm after resetting listings.
  Main window now has X to close button and a hotkey binding.
  Main window now closes when you open the game menu.
  Eliminated cases where slider could get confused as to number of items in the list.
  LibAddonMenu updated to version 2.0r9 (thanks Seerah!)
