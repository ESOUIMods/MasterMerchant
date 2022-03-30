-- Last Updated February 7, 2022
-- Translation provided by @mychaelo (EU Server)

ZO_CreateStringId("GS_DEBUG_OPTIONS", "Параметры отладки")
ZO_CreateStringId("GS_REFRESH_BUTTON", "Обновить")
ZO_CreateStringId("GS_REFRESH_DESC", "Данные LibHistoire не привязаны к учётной записи, так что вам нужно сделать это только единожды для каждого из серверов NA и EU, а не для каждой учётной записи.")
ZO_CreateStringId("GS_RESET_NA_BUTTON", "Обнулить NA")
ZO_CreateStringId("GS_RESET_NA_DESC", "Уничтожит только данные LibGuildStore для сервера NA.")
ZO_CreateStringId("GS_RESET_EU_BUTTON", "Обнулить EU")
ZO_CreateStringId("GS_RESET_EU_DESC", "Уничтожит только данные LibGuildStore для сервера EU.")
ZO_CreateStringId("GS_REFRESH_LIBHISTOIRE_NAME", "Обновить LibHistoire")
ZO_CreateStringId("GS_REFRESH_LIBHISTOIRE_TIP", "Обновить все данные из LibHistoire на основе заданного размера журнала.")
ZO_CreateStringId("GS_RESET_NA_NAME", "Сброс данных NA")
ZO_CreateStringId("GS_RESET_NA_TIP", "Уничтожить все данные LibGuildStore для сервера NA.")
ZO_CreateStringId("GS_RESET_EU_NAME", "Сброс данных EU")
ZO_CreateStringId("GS_RESET_EU_TIP", "Уничтожить все данные LibGuildStore для сервера EU.")

ZO_CreateStringId("GS_TRUNCATE_SALES_COMPLETE", "Отсечение продаж: завершено за %s сек., удалено устаревших записей: %s.")
ZO_CreateStringId("GS_TRUNCATE_LISTINGS_COMPLETE", "Отсечение размещений: завершено за %s сек., удалено устаревших записей: %s.")
ZO_CreateStringId("GS_TRUNCATE_PURCHASE_COMPLETE", "Отсечение покупок: завершено за %s сек., удалено устаревших записей: %s.")
ZO_CreateStringId("GS_TRUNCATE_POSTED_COMPLETE", "Отсечение выставлений: завершено за %s сек., удалено устаревших записей: %s.")
ZO_CreateStringId("GS_TRUNCATE_CANCELLED_COMPLETE", "Отсечение отмен: завершено за %s сек., удалено устаревших записей: %s.")

ZO_CreateStringId("GS_RESET_LISTINGS_BUTTON", "Обнулить размещения")
ZO_CreateStringId("GS_RESET_LISTINGS_DESC", "Уничтожит архив размещений только на текущем сервере, NA или EU.")
ZO_CreateStringId("GS_RESET_LISTINGS_NAME", "Сброс размещений")
ZO_CreateStringId("GS_RESET_LISTINGS_TIP", "Уничтожить все данные LibGuildStore о размещённых предметах.")
ZO_CreateStringId("GS_RESET_LISTINGS_CONFIRM_TITLE", "Подтвердите сброс размещений")
ZO_CreateStringId("GS_RESET_LISTINGS_CONFIRM_MAIN", "Уничтожить все данные о размещённых предметах? Вам придётся заново посетить магазины для сбора данных.")

ZO_CreateStringId("GS_IMPORT_MM_BUTTON", "Импорт данных MM")
ZO_CreateStringId("GS_IMPORT_MM_DESC", "До версий 3.6.x данные Master Merchant не хранились раздельно для серверов NA и EU. Импортировать цены с разных серверов не рекомендуется из-за различий в ценообразовании.")
ZO_CreateStringId("GS_IMPORT_MM_NAME", "Импорт данных MM")
ZO_CreateStringId("GS_IMPORT_MM_TIP", "Импортировать все данные из MM в LibGuildStore.")
ZO_CreateStringId("GS_IMPORT_MM_OVERRIDE_NAME", "Снять ограничение на сервер")
ZO_CreateStringId("GS_IMPORT_MM_OVERRIDE_TIP", "Принудительно импортировать данные MM от другого сервера, а также старые данные, где продажи не разделялись по серверам.")

ZO_CreateStringId("GS_IMPORT_ATT_BUTTON", "Импорт данных ATT")
ZO_CreateStringId("GS_IMPORT_ATT_NAME", "Импорт данных ATT")
ZO_CreateStringId("GS_IMPORT_ATT_TIP", "Импортировать все данные продаж из ATT в LibGuildStore.")
ZO_CreateStringId("GS_IMPORT_ATT_DESC", "Данные продаж в Arkadius Trade Tools не привязаны к учётной записи, а потому их надо импортировать лишь для каждого сервера, а не для каждой учётной записи.")
ZO_CreateStringId("GS_IMPORT_ATT_FINISHED", "Данные продаж Arkadius Trade Tools были импортированы. Использование нескольких модификаций для одного и того же набора данных увеличивает потребление памяти и время загрузки.")

ZO_CreateStringId("GS_IMPORT_ATT_PURCHASE_BUTTON", "Импорт покупок из ATT")
ZO_CreateStringId("GS_IMPORT_ATT_PURCHASE_DESC", "Данные о продажах Arkadius Trade Tools не хранят уникальный ID продажи. Вы можете ненамеренно импортировать дубликат продажи. В том числе, товар, купленный при работающих одновременно ATT и ShoppingList (обособленная версия).")
ZO_CreateStringId("GS_IMPORT_ATT_PURCHASE_NAME", "Импорт покупок из ATT")
ZO_CreateStringId("GS_IMPORT_ATT_PURCHASE_TIP", "Импортировать данные покупок из ATT в LibGuildStore.")

ZO_CreateStringId("GS_IMPORT_SL_BUTTON", "Импорт данных ShoppingList")
ZO_CreateStringId("GS_IMPORT_SL_DESC", "Импортировать данные из ShoppingList в LibGuildStore. Обособленная версия ShoppingList не хранила уникальный ID для продаж, так что вы можете получить задвоенные данные о покупках, пока те не будут отсечены по давности.")
ZO_CreateStringId("GS_IMPORT_SL_NAME", "Импорт ShoppingList")
ZO_CreateStringId("GS_IMPORT_SL_TIP", "Импортировать данные из ShoppingList в LibGuildStore.")

ZO_CreateStringId("GS_IMPORT_PD_BUTTON", "Импорт цен выставлений")
ZO_CreateStringId("GS_IMPORT_PD_DESC", "Импортировать цены выставлений из MM в LibGuildStore. Старые данные будут доступны только как общие для всех гильдий. Эта процедура не импортирует цены для каждой гильдии по отдельности.")
ZO_CreateStringId("GS_IMPORT_PD_NAME", "Импорт цен выставлений")
ZO_CreateStringId("GS_IMPORT_PD_TIP", "Импортировать записанные при выставлении предметов на продажу цены в LibGuildStore. Доступно только, если включены общие цены выставления для всех гильдий. Если вы хотите хранить цены выставления отдельно по каждой гильдии, то вам придётся набирать их с чистого листа.")

ZO_CreateStringId("GS_HELP_DUPS", "/lgs dups  — ищет и удаляет записи-дубликаты из журнала")
ZO_CreateStringId("GS_HELP_CLEAN", "/lgs clean  — удаляет из журнала сбойные записи")
ZO_CreateStringId("GS_HELP_SLIDE", "/lgs slide  — переносит журнал продаж на указанное @имя (напр. с @kindredspiritgr на @kindredspiritgrSlid)  /lgs slideback для возврата обратно.")
ZO_CreateStringId("GS_HELP_MMIMPORT", "/lgs mmimport  — импортирует данные продаж из Master Merchant.")
ZO_CreateStringId("GS_HELP_ATTIMPORT", "/lgs attimport  — импортирует данные продаж из Arkadius’ Trade Tools.")

ZO_CreateStringId("GS_COLOR_WHITE", "обычное")
ZO_CreateStringId("GS_COLOR_GREEN", "хорошее")
ZO_CreateStringId("GS_COLOR_BLUE", "превосходное")
ZO_CreateStringId("GS_COLOR_PURPLE", "эпическое")
ZO_CreateStringId("GS_COLOR_GOLD", "легендарное")
ZO_CreateStringId("GS_COLOR_ORANGE", "мифическое")

ZO_CreateStringId("GS_SALES_MANAGEMENT_NAME", "Настройки хранения продаж")
ZO_CreateStringId("GS_DATA_MANAGEMENT_NAME", "Настройки хранения данных")
ZO_CreateStringId("GS_SHOPPINGLIST_DEPTH_NAME", "Размер журнала покупок")
ZO_CreateStringId("GS_SHOPPINGLIST_DEPTH_TIP", "Сколько дней должны храниться данные о покупках в ShoppingList.")
ZO_CreateStringId("GS_HISTORY_DEPTH_NAME", "Размер журнала продаж")
ZO_CreateStringId("GS_HISTORY_DEPTH_TIP", "Сколько дней должны храниться данные о продажах. Снижение этого параметра может уменьшить влияние данным модом на быстродействие клиента.")
ZO_CreateStringId("GS_POSTEDITEMS_DEPTH_NAME", "Размер журнала выставленных товаров")
ZO_CreateStringId("GS_POSTEDITEMS_DEPTH_TIP", "Сколько дней должны храниться выставленные на продажу предметы.")
ZO_CreateStringId("GS_CANCELEDITEMS_DEPTH_NAME", "Размер журнала отменённых товаров")
ZO_CreateStringId("GS_CANCELEDITEMS_DEPTH_TIP", "Сколько дней должны храниться снятые с продажи предметы.")

ZO_CreateStringId("GS_APP_NAME", "LibGuildStore")
ZO_CreateStringId("GS_APP_AUTHOR", "Sharlikran")
ZO_CreateStringId("GS_DAYS_ONLY_NAME", "Хранить продажи только по времени")
ZO_CreateStringId("GS_DAYS_ONLY_TIP", "В процессе отсечения устаревших продаж будет использоваться только Размер журнала продаж. Таким образом, параметры мин. и макс. количества продаж перестанут действовать.")
ZO_CreateStringId("GS_MIN_ITEM_COUNT_NAME", "Мин. количество продаж")
ZO_CreateStringId("GS_MIN_ITEM_COUNT_TIP", "Минимальное количество продаж для каждого предмета, хранимое в журнале.")
ZO_CreateStringId("GS_MAX_ITEM_COUNT_NAME", "Макс. количество продаж")
ZO_CreateStringId("GS_MAX_ITEM_COUNT_TIP", "Максимальное количество продаж для каждого предмета, хранимое в журнале.")
ZO_CreateStringId("GS_SKIP_INDEX_NAME", "Щадящая индексация")
ZO_CreateStringId("GS_SKIP_INDEX_TIP", "Индексы журнала продаж будут пропущены для экономии памяти и ускорения запуска. Поиск на экране MM при этом будет происходить намного медленнее.")
ZO_CreateStringId("GS_DUP_PURGE", "Очистка от дубликатов: завершена за %s сек., найдено дубликатов: %s.")
ZO_CreateStringId("GS_REINDEXING_EVERYTHING", "Начата полная переиндексация.")
ZO_CreateStringId("GS_REINDEXING_COMPLETE", "Переиндексация завершена.")
ZO_CreateStringId("GS_PURGING_DUPLICATES", "Идёт очистка от дубликатов.")
ZO_CreateStringId("GS_PURGING_DUPLICATES_DELAY", "Очистка от дубликатов начнётся по окончании текущего сканирования.")
ZO_CreateStringId("GS_SLIDING_SALES", "Начат перенос ваших продаж.")
ZO_CreateStringId("GS_SLIDING_SALES_DELAY", "Перенос ваших продаж начнётся по окончании текущего сканирования.")
ZO_CreateStringId("GS_CLEAN_START", "Начата очистка от сбойных записей.")
ZO_CreateStringId("GS_CLEAN_START_DELAY", "Очистка от сбойных записей начнётся по окончании текущего сканирования.")
ZO_CreateStringId("GS_CLEAN_UPDATE_DESC", "LibGuildStore Clean обновляет текстовые индексы для поиска.")
ZO_CreateStringId("GS_MINIMAL_INDEXING", "LibGuildStore настроена на щадящий режим индексации.")
ZO_CreateStringId("GS_FULL_INDEXING", "LibGuildStore настроена на полную индексацию.")
ZO_CreateStringId("GS_INDEXING_SUMMARY", "Индексация: завершена за %s сек., записей: %s, уник. слов: %s")
ZO_CreateStringId("GS_SLIDING_SUMMARY", "Перенос: завершён за %s сек., записей: %s, новая учётная запись: %s.")
ZO_CreateStringId("GS_CP_RANK_SEARCH", "ог")
ZO_CreateStringId("GS_REGULAR_RANK_SEARCH", "ур")
ZO_CreateStringId("GS_INIT_SALES_HISTORY_SUMMARY", "Запуск, подсчёт продаж: завершён за %s сек., обработано записей: %s.")
ZO_CreateStringId("GS_INIT_PURCHASES_HISTORY_SUMMARY", "Запуск, подсчёт покупок: завершён за %s сек., обработано записей: %s.")
ZO_CreateStringId("GS_INIT_LISTINGS_HISTORY_SUMMARY", "Запуск, подсчёт размещений: завершён за %s сек., обработано записей: %s.")
ZO_CreateStringId("GS_TRUNCATE_NAME", "Включить сводку по отсечению")
ZO_CreateStringId("GS_TRUNCATE_TIP", "Вывести сводку по отсечению старых записей после завершения процесса.")
ZO_CreateStringId("GS_GUILD_ITEM_SUMMARY_NAME", "Включить сводку по подсчёту сумм")
ZO_CreateStringId("GS_GUILD_ITEM_SUMMARY_TIP", "Вывести сводку по подсчитанным суммам после завершения процесса.")
ZO_CreateStringId("GS_INDEXING_NAME", "Включить сводку по индексации")
ZO_CreateStringId("GS_INDEXING_TIP", "Вывести сводку по индексации поиска после завершения процесса.")
ZO_CreateStringId("GS_CLEANING_TIME_ELAPSED", "Очистка: завершена за %s сек.:")
ZO_CreateStringId("GS_CLEANING_BAD_REMOVED", '  убрано сбойных записей продаж: %s')
ZO_CreateStringId("GS_CLEANING_REINDEXED", '  переиндексировано записей продаж: %s')
ZO_CreateStringId("GS_CLEANING_WRONG_VERSION", '  сбойных версий предметов: %s')
ZO_CreateStringId("GS_CLEANING_WRONG_ID", '  сбойных п/н предметов: %s')
ZO_CreateStringId("GS_CLEANING_WRONG_MULE", '  сбойных п/н предметов-носителей: %s')
ZO_CreateStringId("GS_CLEANING_STRINGS_CONVERTED", '  событий с числами в виде строк: %s')
ZO_CreateStringId("GS_CLEANING_BAD_ITEMLINKS", '  убрано сбойных ссылок на предметы: %s')
ZO_CreateStringId("GS_RESET_CONFIRM_TITLE", "Подтвердите сброс")
ZO_CreateStringId("GS_RESET_CONFIRM_MAIN", "Уничтожить весь журнал продаж? Вам придётся заново обновить данные из LibHistoire.")

ZO_CreateStringId("GS_REFRESH_NOT_FINISHED", "LibGuildStore: обновление ещё не окончено")
ZO_CreateStringId("GS_REFRESH_FINISHED", "LibGuildStore: обновление завершено")
ZO_CreateStringId("GS_REFRESH_STARTING", "LibGuildStore: обновление начато")

ZO_CreateStringId("GS_ALL_BUTTON", GetString(SI_ITEMTYPEDISPLAYCATEGORY0))
ZO_CreateStringId("GS_WEAPONS_BUTTON", GetString(SI_ITEMTYPEDISPLAYCATEGORY1))
ZO_CreateStringId("GS_ARMOR_BUTTON", GetString(SI_ITEMTYPEDISPLAYCATEGORY2))
ZO_CreateStringId("GS_JEWELRY_BUTTON", GetString(SI_ITEMTYPEDISPLAYCATEGORY3))
ZO_CreateStringId("GS_CONSUMABLE_BUTTON", GetString(SI_ITEMTYPEDISPLAYCATEGORY4))
ZO_CreateStringId("GS_CRAFTING_BUTTON", GetString(SI_ITEMTYPEDISPLAYCATEGORY5))
ZO_CreateStringId("GS_FURNISHING_BUTTON", GetString(SI_ITEMTYPEDISPLAYCATEGORY6))
ZO_CreateStringId("GS_MISCELLANEOUS_BUTTON", GetString(SI_ITEMTYPEDISPLAYCATEGORY7))
ZO_CreateStringId("GS_COMPANION_BUTTON", GetString(SI_QUESTTYPE16))
ZO_CreateStringId("GS_UNKNOWN_BUTTON", GetString(SI_INPUT_LANGUAGE_UNKNOWN))
ZO_CreateStringId("GS_KNOWN_BUTTON", "Изучено")

-- buttons to toggle personal and guild sales
ZO_CreateStringId("GS_VIEW_POSTED_ITEMS", "Показать выставленные товары")
ZO_CreateStringId("GS_VIEW_CANCELED_ITEMS", "Показать отменённые товары")
-- window title viewMode - Personal sales
ZO_CreateStringId("GS_POSTED_ITEMS_TITLE", "Выставленные товары")
-- window title viewSize - All sales
ZO_CreateStringId("GS_CANCELED_ITEMS_TITLE", "Отменённые товары")

ZO_CreateStringId("GS_LIBGUILDSTORE_INITIALIZING", "LibGuildStore запускается")
ZO_CreateStringId("GS_LIBGUILDSTORE_TRUNCATE", "LibGuildStore отсекает старые записи…")
ZO_CreateStringId("GS_LIBGUILDSTORE_HISTORY_INIT", "LibGuildStore подготавливает журналирование к работе…")
ZO_CreateStringId("GS_LIBGUILDSTORE_INDEX_DATA", "LibGuildStore закончила индексировать данные")
ZO_CreateStringId("GS_LIBGUILDSTORE_BUSY", "LibGuildStore занята")

ZO_CreateStringId("GS_IMPORTING_ATT_SALES", "Импорт продаж ATT")
ZO_CreateStringId("GS_ATT_MISSING", "Данные продаж Arkadius Trade Tools не обнаружены.")
ZO_CreateStringId("GS_IMPORTING_MM_SALES", "Импорт продаж MasterMerchant")
ZO_CreateStringId("GS_MM_MISSING", "Старые данные Master Merchant не обнаружены.")
ZO_CreateStringId("GS_MM_EU_NA_IMPORT_WARN", "Ваш архив MM содержит данные с обоих серверов — NA и EU. Версии до 3.6.x не разделяли продажи по серверам. Вам требуется принудительно задать сервер в настройках LibGuildStore.")
ZO_CreateStringId("GS_MM_EU_NA_DIFFERENT_SERVER_WARN", "Вы пытаетесь импортировать данные MM с NA или EU, находясь на сервере, отличном от импортируемого. Для продолжения принудительно задайте сервер в настройках LibGuildStore.")
ZO_CreateStringId("GS_RESET_EU_INSTEAD", "Уничтожение отменено, т.к. LibHistoire тогда обновила бы данные EU.")
ZO_CreateStringId("GS_RESET_NA_INSTEAD", "Уничтожение отменено, т.к. LibHistoire тогда обновила бы данные NA.")
ZO_CreateStringId("GS_SHOPPINGLIST_MISSING", "ShoppingList не активирован")
ZO_CreateStringId("GS_SHOPPINGLIST_IMPORTED", "Данные ShoppingList импортированы.")
ZO_CreateStringId("GS_ELAPSED_TIME_FORMATTER", "%s сек. на обработку %s зап.")
ZO_CreateStringId("GS_ATT_PURCHASE_DATA_MISSING", "Данные покупок Arkadius Trade Tools не найдены.")
ZO_CreateStringId("GS_ATT_PURCHASE_DATA_IMPORTED", "Данные покупок Arkadius Trade Tools не найдены.")

-- dropdown choices
ZO_CreateStringId("GS_DEAL_CALC_TTC_SUGGESTED", "Рекомендуемая TTC")
ZO_CreateStringId("GS_DEAL_CALC_TTC_AVERAGE", "Средняя по TTC")
ZO_CreateStringId("GS_DEAL_CALC_MM_AVERAGE", "Средняя по MM")
ZO_CreateStringId("GS_DEAL_CALC_BONANZA_PRICE", "Bonanza-цена")

-- description menu text
ZO_CreateStringId("GS_IMPORT_MM_SALES", "Импорт продаж MM")
ZO_CreateStringId("GS_IMPORT_ATT_SALES", "Импорт продаж ATT")
ZO_CreateStringId("GS_IMPORT_ATT_PURCHASES", "Импорт покупок ATT")
ZO_CreateStringId("GS_REFRESH_LIBHISTOIRE_DATA", "Обновить базу данных LibHistoire")
ZO_CreateStringId("GS_IMPORT_SHOPPINGLIST", "Импорт из ShoppingList")
ZO_CreateStringId("GS_IMPORT_MM_PRICING", "Импорт выставленных цен MM")
ZO_CreateStringId("GS_RESET_NA_LIBGUILDSTORE", "Обнулить NA LibGuildStore")
ZO_CreateStringId("GS_RESET_EU_LIBGUILDSTORE", "Обнулить EU LibGuildStore")
ZO_CreateStringId("GS_RESET_LISTINGS_DATA", "Обнулить цены выставлений")