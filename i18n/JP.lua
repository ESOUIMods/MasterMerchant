-- MasterMerchant English Localization File
-- Last Updated September 6, 2014
-- Written July 2014 by Dan Stone (@khaibit) - dankitymao@gmail.com
-- Extended February 2015 by Chris Lasswell (@Philgo68) - Philgo68@gmail.com
-- Released under terms in license accompanying this file.
-- Distribution without license is prohibited!

--[[DO NOT Translate these strings
NIE tłumacz tych ciągów
NE PAS traduire ces chaînes
Übersetze diese Zeichenfolgen NICHT
НЕ переводите эти строки
これらの文字列を翻訳しないでください
NO traduzca estas cadenas
]]--
ZO_CreateStringId("MM_APP_TEXT_TIMES", " x ")

--[[END OF DO NOT Translate these strings
]]--

-- Options Menu
ZO_CreateStringId("SK_ALERT_ANNOUNCE_NAME", "オンスクリーンアラート")
ZO_CreateStringId("SK_ALERT_ANNOUNCE_TIP", "セールスアラートをオンスクリーンに表示します。")
ZO_CreateStringId("SK_ALERT_CYRODIIL_NAME", "シロディールでアラートを表示")
ZO_CreateStringId("SK_ALERT_CYRODIIL_TIP", "シロディール内でもオンスクリーンアラートを表示し続けます。有効化されている場合でもチャットアラートは表示されます。")
ZO_CreateStringId("SK_MULT_ALERT_NAME", "複数アラートを表示")
ZO_CreateStringId("SK_MULT_ALERT_TIP", "複数アイテムが売れた場合、概要ではなく売れたアイテム毎にアラートを表示します。")
ZO_CreateStringId("SK_OPEN_MAIL_NAME", "メールで開く")
ZO_CreateStringId("SK_OPEN_MAIL_TIP", "メールボックスを開くと同時にMaster Merchant販売概要を開きます。")
ZO_CreateStringId("SK_OPEN_STORE_NAME", "ストアで開く")
ZO_CreateStringId("SK_OPEN_STORE_TIP", "ギルドストアを開くと同時にMaster Merchant販売概要を開きます。")
ZO_CreateStringId("SK_FULL_SALE_NAME", "フルセール価格を表示")
ZO_CreateStringId("SK_FULL_SALE_TIP", "ストアが差し引く前の売れたアイテム価格を表示します。")
ZO_CreateStringId("SK_HISTORY_DEPTH_NAME", "セールス履歴サイズ")
ZO_CreateStringId("SK_HISTORY_DEPTH_TIP", "何日までセールスデータを保存するかを設定します。この値を減らすとこのaddonのパフォーマンスが改善される場合があります。")
ZO_CreateStringId("SK_SHOW_PRICING_NAME", "価格情報を表示")
ZO_CreateStringId("SK_SHOW_PRICING_TIP", "過去のセールスに基づいた価格データをツールチップに含めます。")
ZO_CreateStringId("SK_SHOW_BONANZA_PRICE_NAME", "Show Bonanza Price")
ZO_CreateStringId("SK_SHOW_BONANZA_PRICE_TIP", "Include Bonanza pricing data based on trader listings you have seen in the last 24 hours. This does not remove the Bonanza price from the Graph.")
ZO_CreateStringId("SK_SHOW_TTC_PRICE_NAME", "Show Alternate TTC Price")
ZO_CreateStringId("SK_SHOW_TTC_PRICE_TIP", "Include Alternate TTC condensed price tooltip.")
ZO_CreateStringId("SK_SHOW_CRAFT_COST_NAME", "Show Crafting Cost Info")
ZO_CreateStringId("SK_SHOW_CRAFT_COST_TIP", "Include crafting cost based on ingredient costs in item tooltips.")
ZO_CreateStringId("SK_CALC_NAME", "スタック価格電卓を表示")
ZO_CreateStringId("SK_CALC_TIP", "ギルドストアにアイテムを並べるときに小さな電卓を表示します。")
ZO_CreateStringId("SK_WINDOW_FONT_NAME", "ウィンドウフォント")
ZO_CreateStringId("SK_WINDOW_FONT_TIP", "Master Merchantウィンドウで使用するフォント。")
ZO_CreateStringId("SK_DEAL_CALC_TYPE_NAME", "Deal Calculator Type")
ZO_CreateStringId("SK_DEAL_CALC_TYPE_TIP", "Choose from the MM Average, TTC Average, TTC Suggested, Bonanza Average prices for the deal calculator.")
ZO_CreateStringId("SK_ALERT_OPTIONS_NAME", "セールスアラートオプション")
ZO_CreateStringId("SK_ALERT_OPTIONS_TIP", "アラートタイプとサウンドのオプション。")
ZO_CreateStringId("SK_ALERT_TYPE_NAME", "アラートサウンド")
ZO_CreateStringId("SK_ALERT_TYPE_TIP", "アイテムが売れた時のサウンドを選択します。もしあれば。")
ZO_CreateStringId("SK_ALERT_CHAT_NAME", "チャットアラート")
ZO_CreateStringId("SK_ALERT_CHAT_TIP", "セールスアラートをチャットボックスに表示")
ZO_CreateStringId("SK_OFFLINE_SALES_NAME", "オフラインセールスレポート")
ZO_CreateStringId("SK_OFFLINE_SALES_TIP", "次にログインした時、オフライン時に売れたアイテムのアラートをチャットに表示します。")
ZO_CreateStringId("MM_TRAVEL_TO_ZONE_TEXT", "に旅行する...")

ZO_CreateStringId("MM_DISABLE_ATT_WARN_NAME", "Disable ATT Warning")
ZO_CreateStringId("MM_DISABLE_ATT_WARN_TIP", "If you enjoy using both MM and ATT together then please disable the warning that ATT files are active with this toggle.")

ZO_CreateStringId("SK_TRIM_OUTLIERS_NAME", "以上な価格を無視")
ZO_CreateStringId("SK_TRIM_OUTLIERS_TIP", "スタンダード偏差から遠い価格の取引を無視します。")

ZO_CreateStringId("SK_TRIM_DECIMALS_NAME", "価格の少数を非表示")
ZO_CreateStringId("SK_TRIM_DECIMALS_TIP", "全ての価格を四捨五入します。")

ZO_CreateStringId("SK_ROSTER_INFO_NAME", "ギルド名簿に情報を表示")
ZO_CreateStringId("SK_ROSTER_INFO_TIP", "MMウィンドウで選択した概算時間に基づいた購入と販売のトータルをギルド名簿に表示します。")

ZO_CreateStringId("SK_SHOW_GRAPH_NAME", "価格履歴グラフを表示")
ZO_CreateStringId("SK_SHOW_GRAPH_TIP", "価格履歴グラフをアイテムツールチップに含めます。")

-- Main window
-- buttons to toggle personal and guild sales
ZO_CreateStringId("SK_VIEW_ALL_SALES", "Show Guild Sales")
ZO_CreateStringId("SK_VIEW_YOUR_SALES", "Show Personal Sales")
-- window title viewMode - Personal sales
ZO_CreateStringId("SK_SELF_SALES_TITLE", "Personal Sales")
-- window title viewSize - All sales
ZO_CreateStringId("SK_GUILD_SALES_TITLE", "Guild Sales")
--  window titles - Both
ZO_CreateStringId("SK_ITEM_REPORT_TITLE", "Item Report")
ZO_CreateStringId("SK_SELER_REPORT_TITLE", "Seller’s Report")
ZO_CreateStringId("SK_LISTING_REPORT_TITLE", "Trader Listings")
-- endTimeFrameText on MM Graph
ZO_CreateStringId("MM_ENDTIMEFRAME_TEXT", "Now")

ZO_CreateStringId("SK_SHOW_UNIT", "単価を表示")
ZO_CreateStringId("SK_SHOW_TOTAL", "合計価格を表示")
ZO_CreateStringId("SK_BUYER_COLUMN", "購入者")
ZO_CreateStringId("SK_GUILD_COLUMN", "ギルド")
ZO_CreateStringId("SK_ITEM_COLUMN", "売れたアイテム")
ZO_CreateStringId("SK_TIME_COLUMN", "販売時間")
ZO_CreateStringId("SK_ITEM_LISTING_COLUMN", "Listed Item")
ZO_CreateStringId("SK_TIME_LISTING_COLUMN", "Time Seen")
ZO_CreateStringId("SK_ITEM_PURCHASE_COLUMN", "Item Purchased")
ZO_CreateStringId("SK_TIME_PURCHASE_COLUMN", "Time Purchased")
ZO_CreateStringId("SK_PRICE_COLUMN", "価格")
ZO_CreateStringId("SK_PRICE_EACH_COLUMN", "価格(1個 )")

-- button tooltips
ZO_CreateStringId("SK_ITEM_TOOLTIP", "アイテムをダブルクリックすることでチャットに表示します。")
ZO_CreateStringId("SK_BUYER_TOOLTIP", "名前をダブルクリックすることでコンタクトを取ります。")
ZO_CreateStringId("SK_SORT_TIME_TOOLTIP", "クリックして販売時間でソートします")
ZO_CreateStringId("SK_SORT_PRICE_TOOLTIP", "クリックして販売価格でソートします。")
ZO_CreateStringId("SK_STATS_TOOLTIP", "統計ウィンドウを開きます。")
ZO_CreateStringId("SK_SALES_TOOLTIP", "Sales View")
ZO_CreateStringId("MM_NO_REPORTS_RANK", "No Reports Rank View")
ZO_CreateStringId("MM_NO_LISTINGS_RANK", "No Listing Rank View")
ZO_CreateStringId("MM_NO_PURCHASES_RANK", "No Purchase Rank View")
ZO_CreateStringId("SK_PURCHASE_TOOLTIP", "Purchase View")
ZO_CreateStringId("SK_BONANZA_TOOLTIP", "Bonanza View")
ZO_CreateStringId("SK_MANAGEMENT_TOOLTIP", "Management View")
ZO_CreateStringId("SK_FEEDBACK_TOOLTIP", "Send Feedback")
ZO_CreateStringId("SK_CLOSE_TOOLTIP", "Close Window")
ZO_CreateStringId("SK_NAME_FILTER_TOOLTIP", "Filter By Name")
ZO_CreateStringId("SK_TYPE_FILTER_TOOLTIP", "Filter By Type")

-- toggle view mode
ZO_CreateStringId("SK_SELLER_TOOLTIP", "ランキングビュー")
ZO_CreateStringId("SK_ITEMS_TOOLTIP", "アイテム情報")

ZO_CreateStringId("SK_TIME_DAYS", "<<1[昨日/%d日前]>>")
ZO_CreateStringId("SK_THOUSANDS_SEP", ",")

-- Chat and center screen alerts/messages
ZO_CreateStringId("SK_FIRST_SCAN", "LibGuildStore にデータがありません。情報の保存方法によっては、LibHistoire からのデータのリクエストに時間がかかる場合があります。")
ZO_CreateStringId("SK_REFRESH_LABEL", "更新")
ZO_CreateStringId("SK_REFRESH_START", "更新を開始しました。")
ZO_CreateStringId("SK_REFRESH_DONE", "更新が完了しました。")
ZO_CreateStringId("SK_REFRESH_WAIT", "更新が完了するまで数分お待ちください。")
ZO_CreateStringId("SK_RESET_LABEL", "リセット")
ZO_CreateStringId("SK_RESET_CONFIRM_TITLE", "リセットを確認")
ZO_CreateStringId("SK_RESET_CONFIRM_MAIN", "本当にセールス履歴をリセットしてもよろしいですか？全てのデータは最新のサーバーデータに置換されます。")
ZO_CreateStringId("SK_RESET_DONE", "セールスヒストリーのリセットが完了しました。")
ZO_CreateStringId("SK_SALES_ALERT", "%sを%d個、%s |t16:16:EsoUI/Art/currency/currency_gold.dds|tで販売しました：%s %s")
ZO_CreateStringId("SK_SALES_ALERT_COLOR", "%sを%dこ|cD5B526%s |t16:16:EsoUI/Art/currency/currency_gold.dds|t |cFFFFFFで販売しました： %s %s")
ZO_CreateStringId("SK_SALES_ALERT_GROUP", "%d個のアイテムをトータルで%s |t16:16:EsoUI/Art/currency/currency_gold.dds|t ギルドストアから販売しました。")
ZO_CreateStringId("SK_SALES_ALERT_GROUP_COLOR", "%d個のアイテムをトータルで |cD5B526%s |t16:16:EsoUI/Art/currency/currency_gold.dds|t |cFFFFFFギルドストアから販売しました。")
ZO_CreateStringId("SK_SALES_REPORT", "セールスレポート:")
ZO_CreateStringId("SK_SALES_REPORT_END", "レポート終わり。")

-- Stats Window
ZO_CreateStringId("SK_STATS_TITLE", "セールス統計")
ZO_CreateStringId("SK_STATS_TIME_ALL", "全てのデータを使用")
ZO_CreateStringId("SK_STATS_TIME_SOME", "<<1[%d日]>>戻す")
ZO_CreateStringId("SK_STATS_ITEMS_SOLD", "アイテムが売却されました: %s (ギルドトレーダーから%s%%)")
ZO_CreateStringId("SK_STATS_TOTAL_GOLD", "トータルゴールド: %s |t16:16:EsoUI/Art/currency/currency_gold.dds|t (%s |t16:16:EsoUI/Art/currency/currency_gold.dds|t /日)")
ZO_CreateStringId("SK_STATS_BIGGEST", "最大セール: %s (%s |t16:16:EsoUI/Art/currency/currency_gold.dds|t)")
ZO_CreateStringId("SK_STATS_DAYS", "日数: ")
ZO_CreateStringId("SK_STATS_ALL_GUILDS", "全てのギルド")

-- Tooltip Pricing
ZO_CreateStringId("SK_PRICETIP_SALES", "<<1[%d セール]>>")
ZO_CreateStringId("SK_PRICETIP_ONEDAY", "Master Merchant価格　(%s, <1 日): %.2f|t16:16:EsoUI/Art/currency/currency_gold.dds|t")
ZO_CreateStringId("SK_PRICETIP_MULTDAY", "Master Merchant価格 (%s, %d 日): %.2f|t16:16:EsoUI/Art/currency/currency_gold.dds|t")

-- Keybindings
ZO_CreateStringId("SI_BINDING_NAME_MasterMerchant_TOGGLE", "メインウィンドウを表示/非表示")
ZO_CreateStringId("SI_BINDING_NAME_MasterMerchant_STATS_TOGGLE", "ステータスウィンドウを表示/非表示")
ZO_CreateStringId("SI_BINDING_NAME_MasterMerchant_GRAPH_TOGGLE", "Show/Hide Pricing History Graph")

-- Old string for compatibility
ZO_CreateStringId("MM_OLD_TIP_FORMAT_SINGLE", "M.M. price (%s, %d day): %.2f")
ZO_CreateStringId("MM_OLD_TIP_FORMAT_MULTI", "M.M. price (%s, %d days): %.2f")
ZO_CreateStringId("SK_OLD_PRICETIP_SALES", "<<1[%d sale/%d sales]>>")
ZO_CreateStringId("MM_OLD_PRICETIP_ITEMS", "/<<1[%d item/%d items]>>")

-- New values
ZO_CreateStringId("MM_TIP_FORMAT_SINGLE", "MM 価格 (%s 売上高/%s 販売商品, %s 日): %s")
ZO_CreateStringId("MM_TIP_FORMAT_MULTI", "MM 価格 (%s 売上高/%s 販売商品, %s 日々): %s")
ZO_CreateStringId("MM_BONANZA_TIP", "Bonanza price (%s リスト/%s 販売商品): %s")
ZO_CreateStringId("MM_TTC_ALT_TIP", "TTC [%s listings] Sug: %s, Avg: %s")
ZO_CreateStringId("MM_NO_TTC_PRICE", "[No TTC Pricing]")
ZO_CreateStringId("MM_TIP_FORMAT_NONE", "MM はデータがありません")
ZO_CreateStringId("MM_TIP_FORMAT_NONE_RANGE", "MM は最後の%d日間のデータがありません。")
ZO_CreateStringId("MM_BONANZATIP_FORMAT_NONE", "Bonanza has no data")
ZO_CreateStringId("MM_TIP_FOR", "のため")
ZO_CreateStringId("MM_LINK_TO_CHAT", "チャットにリンク")
ZO_CreateStringId("MM_STATS_TO_CHAT", "チャットにステータス")
ZO_CreateStringId("MM_APP_NAME", "Master Merchant")
ZO_CreateStringId("MM_APP_AUTHOR", "Sharlikran, Philgo68, Khaibit")
ZO_CreateStringId("MM_APP_MESSAGE_NAME", "[Master Merchant]")
ZO_CreateStringId("MM_ADVICE_ERROR", "Master MerchantがTrading Houseにフックすることができず購入アドバイスを提供できません。")

ZO_CreateStringId("MM_TOTAL_TITLE", "トータル: ")
ZO_CreateStringId("MM_CP_RANK_SEARCH", "cp")
ZO_CreateStringId("MM_REGULAR_RANK_SEARCH", "rr")
ZO_CreateStringId("MM_COLOR_WHITE", "白")
ZO_CreateStringId("MM_COLOR_GREEN", "緑")
ZO_CreateStringId("MM_COLOR_BLUE", "青")
ZO_CreateStringId("MM_COLOR_PURPLE", "紫")
ZO_CreateStringId("MM_COLOR_GOLD", "金")
ZO_CreateStringId("MM_COLOR_ORANGE", "orange")
ZO_CreateStringId("MM_PERCENT_CHAR", "%")
ZO_CreateStringId("MM_ENTIRE_GUILD", "ギルド全体")
ZO_CreateStringId("MM_INDEX_TODAY", "今日")
ZO_CreateStringId("MM_INDEX_YESTERDAY", "昨日")
ZO_CreateStringId("MM_INDEX_THISWEEK", "今週")
ZO_CreateStringId("MM_INDEX_LASTWEEK", "先週")
ZO_CreateStringId("MM_INDEX_PRIORWEEK", "次週")
ZO_CreateStringId("MM_INDEX_7DAY", "7日")
ZO_CreateStringId("MM_INDEX_10DAY", "10日")
ZO_CreateStringId("MM_INDEX_30DAY", "30日")
ZO_CreateStringId("SK_SELLER_COLUMN", "販売者")
ZO_CreateStringId("SK_LOCATION_COLUMN", "Location")
ZO_CreateStringId("SK_RANK_COLUMN", "ランク")
ZO_CreateStringId("SK_SALES_COLUMN", "販売")
ZO_CreateStringId("SK_PURCHASES_COLUMN", "購入")
ZO_CreateStringId("SK_TAX_COLUMN", "税")
ZO_CreateStringId("SK_COUNT_COLUMN", "カウント")
ZO_CreateStringId("SK_PERCENT_COLUMN", "パーセント")
ZO_CreateStringId("MM_NOTHING", "無し")

ZO_CreateStringId("MM_LISTING_ALERT", "販売リストに%sを%d個、%s |t16:16:EsoUI/Art/currency/currency_gold.dds|tで販売しました。（%s内）")

ZO_CreateStringId("MM_CALC_OPTIONS_NAME", "計算とヒントオプション")
ZO_CreateStringId("MM_CALC_OPTIONS_TIP", "MM価格計算と表示をカスタマイズするオプションです。")
ZO_CreateStringId("MM_DAYS_FOCUS_ONE_NAME", "1日集中")
ZO_CreateStringId("MM_DAYS_FOCUS_ONE_TIP", "何日集中して販売するかを設定します。")
ZO_CreateStringId("MM_DAYS_FOCUS_TWO_NAME", "2日集中")
ZO_CreateStringId("MM_DAYS_FOCUS_TWO_TIP", "何日集中して販売するかを設定します。")
ZO_CreateStringId("MM_DEFAULT_TIME_NAME", "デフォルト日数レンジ")
ZO_CreateStringId("MM_DEFAULT_TIME_TIP", "デフォルトで何日間の履歴を使用するかを設定します。（なしを設定すると表示されません。）")
ZO_CreateStringId("MM_SHIFT_TIME_NAME", "<Shift> 日レンジ")
ZO_CreateStringId("MM_SHIFT_TIME_TIP", "<Shift>を押下時、何日間の履歴を使用するかを設定します。")
ZO_CreateStringId("MM_CTRL_TIME_NAME", "<Crtl> 日レンジ")
ZO_CreateStringId("MM_CTRL_TIME_TIP", "<Ctrl>押下時、何日間の履歴を使用するかを設定します。")
ZO_CreateStringId("MM_CTRLSHIFT_TIME_NAME", "<Ctrl-Shift> 日レンジ")
ZO_CreateStringId("MM_CTRLSHIFT_TIME_TIP", "<Ctrl-Shift>押下時、何日間の履歴を使用するかを設定します。")
ZO_CreateStringId("MM_RANGE_ALL", "全て")
ZO_CreateStringId("MM_RANGE_FOCUS1", "集中1")
ZO_CreateStringId("MM_RANGE_FOCUS2", "集中2")
ZO_CreateStringId("MM_RANGE_FOCUS3", "集中3")
ZO_CreateStringId("MM_RANGE_NONE", "なし")
ZO_CreateStringId("MM_BLACKLIST_NAME", "Guild & Account Filter")
ZO_CreateStringId("MM_BLACKLIST_TIP", "MMが計算時、無視したいプレイヤーとギルドの名前のリストです。")
ZO_CreateStringId("MM_BLACKLIST_MENU", "Add Seller to Filter")
ZO_CreateStringId("MM_BLACKLIST_EXCEEDS", "Can not append account name. The Guild & Account Filter would exceed 2000 characters.")

ZO_CreateStringId("MM_CUSTOM_TIMEFRAME_NAME", "Custom Timeframe")
ZO_CreateStringId("MM_CUSTOM_TIMEFRAME_TIP", "An extra timeframe to choose from in the item and guild lists.")
ZO_CreateStringId("MM_CUSTOM_TIMEFRAME_SCALE_NAME", "Custom Timeframe Units")
ZO_CreateStringId("MM_CUSTOM_TIMEFRAME_SCALE_TIP", "The time unit in which the Custom Timeframe is expressed.")
ZO_CreateStringId("MM_CUSTOM_TIMEFRAME_HOURS", "Hours")
ZO_CreateStringId("MM_CUSTOM_TIMEFRAME_DAYS", "Days")
ZO_CreateStringId("MM_CUSTOM_TIMEFRAME_WEEKS", "Weeks")
ZO_CreateStringId("MM_CUSTOM_TIMEFRAME_GUILD_WEEKS", "Full Guild Weeks")

ZO_CreateStringId("MM_SAUCY_NAME", "マージンではなく利益を表示")
ZO_CreateStringId("MM_SAUCY_TIP", "ギルドストア内で、マージンパーセンテージではなく期待される利益を表示します。")
ZO_CreateStringId("MM_MIN_PROFIT_FILTER_NAME", "利益フィルタを表示")
ZO_CreateStringId("MM_MIN_PROFIT_FILTER_TIP", "利益にAGAベースの追加のフィルタを追加します。")

ZO_CreateStringId("MM_PRICETIP_ITEMS", "/<<1[%d アイテム]>>")

ZO_CreateStringId("MM_MIN_ITEM_COUNT_NAME", "最小アイテムカウント")
ZO_CreateStringId("MM_MIN_ITEM_COUNT_TIP", "履歴に残されるセールアイテムの最小数を設定します。")
ZO_CreateStringId("MM_MAX_ITEM_COUNT_NAME", "最大アイテムカウント")
ZO_CreateStringId("MM_MAX_ITEM_COUNT_TIP", "履歴に残されるアイテムの最大数を設定します。")

ZO_CreateStringId("MM_REPLACE_INVENTORY_VALUES_NAME", "インベントリ価格を置換")
ZO_CreateStringId("MM_REPLACE_INVENTORY_VALUES_TIP", "インベントリグリッドにMM価格を表示します。")
ZO_CreateStringId("MM_REPLACE_INVENTORY_VALUE_TYPE_NAME", "Replacement Value Type")
ZO_CreateStringId("MM_REPLACE_INVENTORY_VALUE_TYPE_TIP", "Choose from the MM Average, TTC Average, TTC Suggested, and Bonanza Average prices on the inventory grid.")

ZO_CreateStringId("MM_DISPLAY_LISTING_MESSAGE_NAME", "販売リストに追加メッセージを表示")
ZO_CreateStringId("MM_DISPLAY_LISTING_MESSAGE_TIP", "ギルドストアの販売リストに追加されたアイテム毎にチャットウィンドウにメッセージを表示します。")

ZO_CreateStringId("SK_PER_CHANGE_COLUMN", "税")
ZO_CreateStringId("SK_PER_CHANGE_TIP", "セールスで生成されたギルドのゴールド。")
ZO_CreateStringId("MM_POPUP_ITEM_DATA", "アイテムデータをポップアップ")
ZO_CreateStringId("MM_GRAPH_TIP", "%s %sで%sを%d個%sに、各%sで販売しました。")
ZO_CreateStringId("MM_GRAPH_TIP_SINGLE", "%s %sで%sを%sに、%sで販売しました。")
ZO_CreateStringId("MM_NO_DATA_DEAL_NAME", "取引レートのデータなし")
ZO_CreateStringId("MM_NO_DATA_DEAL_TIP", "セールス履歴のないアイテムの取引レート。")
ZO_CreateStringId("MM_GRAPH_INFO_NAME", "グラフポイントの詳細情報")
ZO_CreateStringId("MM_GRAPH_INFO_TIP", "有効にすると、時間、ギルド、買い手、売り手、価格情報が表示されます。無効にすると、グラフポイントの個別の価格が表示されます。")
ZO_CreateStringId("MM_LEVEL_QUALITY_NAME", "レベル/品質セレクタ")
ZO_CreateStringId("MM_LEVEL_QUALITY_TIP", "レベル/品質を調整するボタンをアイテムポップアップに表示します。")

ZO_CreateStringId("MM_SKIP_INDEX_NAME", "最小限のインデックス")
ZO_CreateStringId("MM_SKIP_INDEX_TIP", "メモリを節約するために販売履歴インデックスはスキップされますが、MM画面からの検索ははるかに遅くなります。")

ZO_CreateStringId("MM_DAYS_ONLY_NAME", "Use Sales History Size Only")
ZO_CreateStringId("MM_DAYS_ONLY_TIP", "Will use Sales History Size only when trimming sales history. This will ignore min and max count.")

ZO_CreateStringId("MM_SHOW_AMOUNT_TAXES_NAME", "Add Taxes Sales Rank Export")
ZO_CreateStringId("MM_SHOW_AMOUNT_TAXES_TIP", "Will calculate 3.5% of total sales as the amount of Taxes for a user when using /mm export.")

ZO_CreateStringId("MM_GUILD_ROSTER_OPTIONS_NAME", "Guild Roster Options")
ZO_CreateStringId("MM_GUILD_ROSTER_OPTIONS_TIP", "Enable and disable the different guild roster columns. (Requires until next update of LibGuild Roster)")

ZO_CreateStringId("MM_PURCHASES_COLUMN_NAME", "Enable Purchases Column")
ZO_CreateStringId("MM_PURCHASES_COLUMN_TIP", "Display Purchases on guild roster.")

ZO_CreateStringId("MM_SALES_COLUMN_NAME", "Enable Sales Column")
ZO_CreateStringId("MM_SALES_COLUMN_TIP", "Display Sales on guild roster.")

ZO_CreateStringId("MM_TAXES_COLUMN_NAME", "Enable Taxes Column")
ZO_CreateStringId("MM_TAXES_COLUMN_TIP", "Display Taxes on guild roster.")

ZO_CreateStringId("MM_COUNT_COLUMN_NAME", "Enable Count Column")
ZO_CreateStringId("MM_COUNT_COLUMN_TIP", "Display Count on guild roster.")

ZO_CreateStringId("MM_DAYS_FOCUS_THREE_NAME", "Focus 3 Days")
ZO_CreateStringId("MM_DAYS_FOCUS_THREE_TIP", "Number of days sales to focus on.")

ZO_CreateStringId("MM_DEBUG_LOGGER_NAME", "Activate Custom Debug Logging")
ZO_CreateStringId("MM_DEBUG_LOGGER_TIP", "Activate the optional debug logging with LibDebugLogger when requested.")

ZO_CreateStringId("MM_DATA_MANAGEMENT_NAME", "Data Management Options")
ZO_CreateStringId("MASTER_MERCHANT_WINDOW_NAME", "Master Merchant Window Options")
ZO_CreateStringId("MASTER_MERCHANT_TOOLTIP_OPTIONS", "Other Tooltip Options")
ZO_CreateStringId("GUILD_STORE_OPTIONS", "Guild Store Options")
ZO_CreateStringId("MASTER_MERCHANT_DEBUG_OPTIONS", "Debug Options")
ZO_CreateStringId("GUILD_MASTER_OPTIONS", "Guild Master Options")
ZO_CreateStringId("MASTER_MERCHANT_INVENTORY_OPTIONS", "Inventory Options")

ZO_CreateStringId("MM_EXTENSION_SHOPPINGLIST_NAME", "Shopping List")
ZO_CreateStringId("MM_EXTENSION_BONANZA_NAME", "Bonanza")

-- new notification messages
ZO_CreateStringId("MM_INITIALIZING", "Master Merchant Initializing...")
ZO_CreateStringId("MM_INITIALIZED", "Master Merchant Initialized: retaining %s Sales, %s Purchases, %s Listings, %s Posted, %s Canceled.")
ZO_CreateStringId("MM_MINIMAL_INDEXING", "Minimal Indexing Started...")
ZO_CreateStringId("MM_FULL_INDEXING", "Full Indexing Started...")
ZO_CreateStringId("MM_INDEXING_SUMMARY", "Indexing: %s seconds to index %s sales records, %s unique words")
ZO_CreateStringId("MM_TRUNCATE_COMPLETE", "Trimming Complete: %s seconds to trim, %s old records removed.")
ZO_CreateStringId("MM_SLIDING_SUMMARY", "Sliding: %s seconds to slide %s sales records to %s.")
ZO_CreateStringId("MM_REINDEXING_COMPLETE", "Reindexing Complete.")
ZO_CreateStringId("MM_REINDEXING_EVERYTHING", "Reindexing Everything.")
ZO_CreateStringId("MM_CLEANING_TIME_ELAPSED", "Cleaning: %s seconds to clean:")
ZO_CreateStringId("MM_CLEANING_BAD_REMOVED", '  %s bad sales records removed')
ZO_CreateStringId("MM_CLEANING_REINDEXED", '  %s sales records re-indexed')
ZO_CreateStringId("MM_CLEANING_WRONG_VERSION", '  %s bad item versions')
ZO_CreateStringId("MM_CLEANING_WRONG_ID", '  %s bad item IDs')
ZO_CreateStringId("MM_CLEANING_WRONG_MULE", '  %s bad mule item IDs')
ZO_CreateStringId("MM_CLEANING_STRINGS_CONVERTED", '  %s events with numbers converted to strings')
ZO_CreateStringId("MM_CLEANING_BAD_ITEMLINKS", '  %s bad item links removed')
ZO_CreateStringId("MM_LIBHISTOIRE_REFRESH_FINISHED", "LibHistoire Refresh Finished")
ZO_CreateStringId("MM_LIBHISTOIRE_ACTIVATED", 'LibHistoire Activated, listening for guild sales...')
ZO_CreateStringId("MM_STILL_INITIALIZING", "Master Merchant is still initializing.")
ZO_CreateStringId("MM_LIBHISTOIRE_REFRESHING", "LibHistoire refreshing...")
ZO_CreateStringId("MM_LIBHISTOIRE_REFRESH_ONCE", "LibHistoire can only be refreshed once per session.")
ZO_CreateStringId("MM_EXPORTING", "Exporting: %s")
ZO_CreateStringId("MM_EXPORTING_INVALID", "Invalid! Valid guild numbers, 1 to 5.")
ZO_CreateStringId("MM_DUP_PURGE", "Dup purge: %s seconds to clear %s duplicates.")
ZO_CreateStringId("MM_CHECK_STATUS", "Guild Name: %s ; Numevents loaded: %s ; Event Count: %s ; Speed: %s ; Time Left: %s")

-- new debug messages
ZO_CreateStringId("MM_FILTER_TIME", "Filter Time: %s")

-- new slash and help command strings
ZO_CreateStringId("MM_GUILD_DEAL_TYPE", "Guild listing display switched.")
ZO_CreateStringId("MM_RESET_POSITION", "Your MM window positions have been reset.")
ZO_CreateStringId("MM_CLEAR_SAVED_PRICES", "Your prices have been cleared.")
ZO_CreateStringId("MM_CLEAN_UPDATE_DESC", "MM Clean is set to update search text.")
ZO_CreateStringId("MM_CLEAN_START", "Cleaning Out Bad Records.")
ZO_CreateStringId("MM_CLEAN_START_DELAY", "Cleaning out bad sales records will begin when current scan completes.")
ZO_CreateStringId("MM_GUILD_INDEX_NAME", "[%s] - %s")
ZO_CreateStringId("MM_GUILD_INDEX_INCLUDE", "Please include the guild number you wish to export.")
ZO_CreateStringId("MM_GUILD_SALES_EXAMPLE", "For example '/mm sales 1' to export guild 1.")
ZO_CreateStringId("MM_SALES_EXPORT_START", "Exporting' sales activity.")
ZO_CreateStringId("MM_EXPORT_COMPLETE", "Export complete.  /reloadui to save the file.")
ZO_CreateStringId("MM_GUILD_EXPORT_EXAMPLE", "For example '/mm export 1' to export guild 1.")
ZO_CreateStringId("MM_EXPORT_START", "Exporting selected weeks sales/purchase/taxes/rank data.")
ZO_CreateStringId("MM_SLIDING_SALES", "Sliding your sales.")
ZO_CreateStringId("MM_SLIDING_SALES_DELAY", "Sliding of your sales records will begin when current scan completes.")
ZO_CreateStringId("MM_PURGING_DUPLICATES", "Purging duplicates.")
ZO_CreateStringId("MM_PURGING_DUPLICATES_DELAY", "Purging of duplicate sales records will begin when current scan completes.")

-- help
ZO_CreateStringId("MM_HELP_WINDOW", "/mm  - show/hide the main Master Merchant window")
ZO_CreateStringId("MM_HELP_DUPS", "/mm dups  - scans your history to purge duplicate entries")
ZO_CreateStringId("MM_HELP_CLEAN", "/mm clean - cleans out bad sales records (invalid information)")
ZO_CreateStringId("MM_HELP_CLEARPRICES", "/mm clearprices  - clears your historical listing prices")
ZO_CreateStringId("MM_HELP_INVISIBLE", "/mm invisible  - resets the MM window positions in case they are invisible (aka off the screen)")
ZO_CreateStringId("MM_HELP_EXPORT", "/mm export <Guild number>  - 'exports' last weeks sales/purchase totals for the guild")
ZO_CreateStringId("MM_HELP_SALES", "/mm sales <Guild number>  - 'exports' sales activity data for your guild")
ZO_CreateStringId("MM_HELP_DEAL", "/mm deal  - toggles deal display between margin % and profit in the guild stores")
ZO_CreateStringId("MM_HELP_TYPES", "/mm types  - list the item type filters that are available")
ZO_CreateStringId("MM_HELP_TRAITS", "/mm traits  - list the item trait filters that are available")
ZO_CreateStringId("MM_HELP_QUALITY", "/mm quality  - list the item quality filters that are available")
ZO_CreateStringId("MM_HELP_EQUIP", "/mm equip  - list the item equipment type filters that are available")
ZO_CreateStringId("MM_HELP_SLIDE", "/mm slide  - relocates your sales records to a new @name (Ex. @kindredspiritgr to @kindredspiritgrSlid)  /mm slideback to reverse.")

-- new summary toggle
ZO_CreateStringId("MM_GUILD_ITEM_SUMMARY_NAME", "Enable Guild and Item Summary")
ZO_CreateStringId("MM_GUILD_ITEM_SUMMARY_TIP", "Show Guild and Item totals after process is complete.")

ZO_CreateStringId("MM_INDEXING_NAME", "Enable Indexing Summary")
ZO_CreateStringId("MM_INDEXING_TIP", "Show Indexing totals after process is complete.")

-- Bonanza filter windows
ZO_CreateStringId("MM_FILTERBY_LINK_TITLE", "Filter By Item Name")
ZO_CreateStringId("MM_FILTERBY_TYPE_TITLE", "Filter By Item Type")
ZO_CreateStringId("MM_ITEMNAME_TEXT", "Item Name")
ZO_CreateStringId("MM_FILTER_MENU_ADD_ITEM", "Add Name To Filter")
ZO_CreateStringId("MM_CRAFT_COST_TO_CHAT", "Craft Cost to Chat")
ZO_CreateStringId("MM_FILTER_MENU_REMOVE_ITEM", "Remove From Filter")
ZO_CreateStringId("MM_CLEAR_FILTER_BUTTON", "Clear Filter")

ZO_CreateStringId("MM_LGS_NOT_INITIALIZED_AGS_REFRESH", "LibGuildStore not initialized. Information will not be refreshed.")
ZO_CreateStringId("MM_CRAFTCOST_PRICE_TIP", "Craft Cost: %s")

ZO_CreateStringId("SK_ALL_CALC_NAME", "Save Central Priceing Data")
ZO_CreateStringId("SK_ALL_CALC_TIP", "Enabled, all pricing data is the same for all guilds. If disabled then pricing data is saved differently per guild.")

-- notifications
ZO_CreateStringId("MM_ATT_DATA_ENABLED", "[MasterMerchant] You can import ATT data into Master Merchat from the LibGuildStore settings menu. You can disable this notification from MasterMerchant settings under Debug Options.")
ZO_CreateStringId("MM_RESET_LISTINGS_WARN_FORCE", "This will force a UI reload when complete.")
ZO_CreateStringId("MM_RESET_LISTINGS_WARN", "You will need to reload your UI after changing this value.")
ZO_CreateStringId("MM_ZONE_INVALID", "You will need to reload your UI after changing this value.")
ZO_CreateStringId("MM_BEAM_ME_UP_MISSING", "You will need to reload your UI after changing this value.")
ZO_CreateStringId("MM_MMXXDATA_OBSOLETE", "The old MMxxData modules are only needed for importing MM data. Please disable all MMxxData modules to increase performance and reduce load times.")
ZO_CreateStringId("MM_SHOPPINGLIST_OBSOLETE", "ShoppingList is only needed for importing old data. Please disable ShoppingList after you import its data.")
ZO_CreateStringId("MM_RELOADUI_WARN", "This will force a UI reload when changed.")
