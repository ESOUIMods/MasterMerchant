-- Last Updated September 5, 2021
-- Original file Sharlikran

ZO_CreateStringId("GS_DEBUG_OPTIONS", "Debug Optionen")
ZO_CreateStringId("GS_REFRESH_BUTTON", "Aktualisieren")
ZO_CreateStringId("GS_REFRESH_DESC", "LibHistoire Daten sind nicht Account spezifisch, daher musst du dies nur 1x je Server (NA, EU) tun, nicht 1x je @account!")
ZO_CreateStringId("GS_RESET_BUTTON", "NA zurücksetzen")
ZO_CreateStringId("GS_RESET_DESC", "Dies wird nur die NA Server LibGuildStore Daten zurücksetzen")
ZO_CreateStringId("GS_RESET_EU_BUTTON", "EU zurücksetzen")
ZO_CreateStringId("GS_RESET_EU_DESC", "Dies wird nur die EU Server LibGuildStore Daten zurücksetzen")
ZO_CreateStringId("GS_REFRESH_LIBHISTOIRE_NAME", "Libhistoire aktualisieren")
ZO_CreateStringId("GS_REFRESH_LIBHISTOIRE_TIP", "Aktualisiert alle Libhistoire Daten (basierend auf deiner Gilden Verkäufen Größe).")
ZO_CreateStringId("GS_RESET_NAME", "NA zurücksetzen")
ZO_CreateStringId("GS_RESET_TIP", "Dies wird nur die NA Server LibGuildStore Daten zurücksetzen")
ZO_CreateStringId("GS_RESET_EU_NAME", "EU zurücksetzen")
ZO_CreateStringId("GS_RESET_EU_TIP", "Dies wird nur die EU Server LibGuildStore Daten zurücksetzen")

ZO_CreateStringId("GS_TRUNCATE_SALES_COMPLETE", "Trimmen der Verkäufe abgeschlossen: %s Sekunden, %s alte Einträge entfernt.")
ZO_CreateStringId("GS_TRUNCATE_LISTINGS_COMPLETE", "Trimmen der gelisteten Einträge abgeschlossen: %s Sekunden, %s alte Einträge entfernt.")
ZO_CreateStringId("GS_TRUNCATE_PURCHASE_COMPLETE", "Trimmen der Käufe abgeschlossen: %s Sekunden, %s alte Einträge entfernt.")
ZO_CreateStringId("GS_TRUNCATE_POSTED_COMPLETE", "Trimmen der gebuchten Gegenstände abgeschlossen: %s Sekunden, %s alte Einträge entfernt.")
ZO_CreateStringId("GS_TRUNCATE_CANCELLED_COMPLETE", "Trimmen der abgebrochenen Verkäufe abgeschlossen: %s Sekunden, %s alte Einträge entfernt.")

ZO_CreateStringId("GS_RESET_LISTINGS_BUTTON", "Gelistete zurücksetzen")
ZO_CreateStringId("GS_RESET_LISTINGS_DESC", "Dies wird die gelisteten Gegenstände Daten des aktuellen Servers (NA oder EU) zurücksetzen.")
ZO_CreateStringId("GS_RESET_LISTINGS_NAME", "Gelistete Daten zurücksetzen")
ZO_CreateStringId("GS_RESET_LISTINGS_DATA", "Setze gelistete Daten zurück")
ZO_CreateStringId("GS_RESET_LISTINGS_TIP", "Setzt alle LibGuildStore gelistete Daten zurück.")
ZO_CreateStringId("GS_RESET_LISTINGS_CONFIRM_TITLE", "Bestäigung: Gelistete zurücksetzen")
ZO_CreateStringId("GS_RESET_LISTINGS_CONFIRM_MAIN", "Willst du wirklich die gelisteten Gegenstände Daten zurücksetzen? Du musst Händler besuchen, um neue Daten zu sammeln.")

ZO_CreateStringId("GS_IMPORT_MM_BUTTON", "Importiere MM Daten")
ZO_CreateStringId("GS_IMPORT_MM_DESC", "Bis MM v3.6.x wurden die Master Merchant Daten nicht seperat je Server gespeichert. Es sollten keine Daten von einem anderen Server importiert werden, da die Preise sehr unterschiedlich sein können!")
ZO_CreateStringId("GS_IMPORT_MM_NAME", "Importiere MM Daten")
ZO_CreateStringId("GS_IMPORT_MM_TIP", "Importier alle MM Daten nach LibGuildStore.")
ZO_CreateStringId("GS_IMPORT_MM_OVERRIDE_NAME", "Überschreibe MM Import")
ZO_CreateStringId("GS_IMPORT_MM_OVERRIDE_TIP", "Überschreibe den Import der MM Daten von NA nach EU (oder andersherum), oder wenn deine alten Daten Verkäufe von mehreren Servern beinhalten.")

ZO_CreateStringId("GS_IMPORT_ATT_BUTTON", "Importiere ATT Daten")
ZO_CreateStringId("GS_IMPORT_ATT_NAME", "Importiere ATT Daten")
ZO_CreateStringId("GS_IMPORT_ATT_TIP", "Importiert alle ATT Daten nach LibGuildStore.")
ZO_CreateStringId("GS_IMPORT_ATT_DESC", "Arkadius Trade Tools Verkäufe Daten sind nicht @account spezifisch, also musst du diese nur 1x je Server importieren, und nicht je @account")
ZO_CreateStringId("GS_IMPORT_ATT_FINISHED", "Arkadius Trade Tools Verkäufe Daten wurden importiert. Wenn mehrere AddOns mit denselben Daten verwendet werden erhöht dies die Arbeitsspeicher Verwnedung sowie die Ladezeiten!")

ZO_CreateStringId("GS_IMPORT_ATT_PURCHASE_BUTTON", "Importiere ATT Käufe")
ZO_CreateStringId("GS_IMPORT_ATT_PURCHASE_DESC", "Arkadius Trade Tools Käufe Daten speichern nicht die spezifische Kauf-ID. Daher können ungewollt doppelte Verkäufe importiert werden (z.B. ein Kauf der durchgeführt wurde als ATT und ShoppingList, als eigenes AddOn, aktiv waren.")
ZO_CreateStringId("GS_IMPORT_ATT_PURCHASE_NAME", "Importiere ATT Käufe")
ZO_CreateStringId("GS_IMPORT_ATT_PURCHASE_TIP", "Importiert ATT Käufe Daten nach LibGuildStore.")

ZO_CreateStringId("GS_IMPORT_SL_BUTTON", "Importiere Shoppinglist Daten")
ZO_CreateStringId("GS_IMPORT_SL_DESC", "Importiere ShoppingList Daten nach LibGuildStore. Vorherige ShoppingList Daten haben keine eindeutige ID für die Käufe gespeichert, daher kann es zu doppelten Einträgen kommen, bis der Kauf älter und getrimmt wird.")
ZO_CreateStringId("GS_IMPORT_SL_NAME", "Importiere Shoppinglist")
ZO_CreateStringId("GS_IMPORT_SL_TIP", "Importiert Shoppinglist Daten nach LibGuildStore.")

ZO_CreateStringId("GS_IMPORT_PD_BUTTON", "Importiere Preis Daten")
ZO_CreateStringId("GS_IMPORT_PD_TITLE", "Pricing Data is your previously saved prices for listed items.")
ZO_CreateStringId("GS_IMPORT_PD_DESC", "Importiere MM Preis Daten nach LibGuildStore. Preis Daten werden nur noch als übergreifende Preis Daten verfügbar sein. Die Daten werden nicht in jede Gilde importiert werden!")
ZO_CreateStringId("GS_IMPORT_PD_NAME", "Importiere Preis Daten")
ZO_CreateStringId("GS_IMPORT_PD_TIP", "Importiert Preis Data nach LibGuildStore. Dies wird nur für die übergreifdenden Preise verfügbar sein. Um individuelle Gilden mit Preisen zu aktualisieren, musst du die Preis Daten der Gilden aufbauen.")

ZO_CreateStringId("GS_HELP_DUPS", "/lgs dups  - Scannt die Historie nach doppelten Einträgen und entfernt diese")
ZO_CreateStringId("GS_HELP_CLEAN", "/lgs clean - Löscht falsche Verkäufe (ungültige Informationen)")
ZO_CreateStringId("GS_HELP_SLIDE", "/lgs slide  - Zieht die Verkaufs Daten zu einem anderen @accountNamen um (z.B. @kindredspiritgr to @kindredspiritgrSlid)  /mm slideback um dies rückgängig zu machen.")
ZO_CreateStringId("GS_HELP_MMIMPORT", "/lgs mmimport  - Importiert Verkäufe Daten aus Master Merchant.")
ZO_CreateStringId("GS_HELP_ATTIMPORT", "/lgs attimport  - Importiert Verkäufe Daten aus Arkadius\' Trade Tools.")

ZO_CreateStringId("GS_COLOR_WHITE", "weiss")
ZO_CreateStringId("GS_COLOR_GREEN", "grün")
ZO_CreateStringId("GS_COLOR_BLUE", "blau")
ZO_CreateStringId("GS_COLOR_PURPLE", "lila")
ZO_CreateStringId("GS_COLOR_GOLD", "gold")
ZO_CreateStringId("GS_COLOR_ORANGE", "orange")

ZO_CreateStringId("GS_SALES_MANAGEMENT_NAME", "Verkaufs-Verwaltungs Optionen")
ZO_CreateStringId("GS_DATA_MANAGEMENT_NAME", "Daten-Verwaltungs Optionen")
ZO_CreateStringId("GS_SHOPPINGLIST_DEPTH_NAME", "ShoppingList Historien Größe")
ZO_CreateStringId("GS_SHOPPINGLIST_DEPTH_TIP", "Wie viele Tage der Käufe sollen in ShoppingList gespeichert werden?")
ZO_CreateStringId("GS_HISTORY_DEPTH_NAME", "Verkaufs Historien Größe")
ZO_CreateStringId("GS_HISTORY_DEPTH_TIP", "Wie viele Tage der Verkäufe sollen gespeichert werden? Ein verringerter Wert könnte die Performance des AddOns verbessern.")
ZO_CreateStringId("GS_POSTEDITEMS_DEPTH_NAME", "Gebuchte Gegenstände Historien Größe")
ZO_CreateStringId("GS_POSTEDITEMS_DEPTH_TIP", "Wie viele Tage soll der Gebuchte Gegenstände Report speichern?")
ZO_CreateStringId("GS_CANCELEDITEMS_DEPTH_NAME", "Abgebrochene Gegenstände Historien Größe")
ZO_CreateStringId("GS_CANCELEDITEMS_DEPTH_TIP", "Wie viele Tage soll der Abgebrochene Gegenstände Report speichern?")

ZO_CreateStringId("GS_APP_NAME", "LibGuildStore")
ZO_CreateStringId("GS_APP_AUTHOR", "Sharlikran")
ZO_CreateStringId("GS_DAYS_ONLY_NAME", "Nur Verkaufs-Historien Größe berücksichtigen")
ZO_CreateStringId("GS_DAYS_ONLY_TIP", "Es wird nur die Verkaufs-Historien Größe berücksichtigt, wenn die Historie getrimmt wird. Dies ignoriert die min- und maximale Anzahl.")
ZO_CreateStringId("GS_MIN_ITEM_COUNT_NAME", "Min. Gegenstands Anzahl")
ZO_CreateStringId("GS_MIN_ITEM_COUNT_TIP", "Minimale Anzahl der Verkäufe, damit dieser in der Historie verbleibt.")
ZO_CreateStringId("GS_MAX_ITEM_COUNT_NAME", "Max. Gegenstands Anzahl")
ZO_CreateStringId("GS_MAX_ITEM_COUNT_TIP", "Maximale Anzahl der Verkäufe, damit dieser in der Historie verbleibt.")
ZO_CreateStringId("GS_MIN_SALES_INTERVAL_NAME", "Min Sales Interval")
ZO_CreateStringId("GS_MIN_SALES_INTERVAL_TIP", "Minimum Sales Interval to evaluate prior to trimming sales. A value of 0 disables the evaluation.")
ZO_CreateStringId("GS_MIN_SALES_INTERVAL_DESC", "When this value is greater then 0 the Min item count and the sales interval (in Days) will be considered first before truncating. If the interval is set to 10 days and the sale is less then 10 days old the sale will be retained the same as a sale below the Min Item Count.")
ZO_CreateStringId("GS_SKIP_INDEX_NAME", "Minimale Indizierung")
ZO_CreateStringId("GS_SKIP_INDEX_TIP", "Verkaufsverlaufsindizes werden übersprungen, um Speicherplatz zu sparen, aber die Suche auf dem MM-Bildschirm ist viel langsamer.")
ZO_CreateStringId("GS_DUP_PURGE", "Doppelte Bereinigung: Benötigte %s Sekunden um %s Duplikate zu entfernen.")
ZO_CreateStringId("GS_REINDEXING_EVERYTHING", "Reindizierung Alles.")
ZO_CreateStringId("GS_REINDEXING_COMPLETE", "Reindizierung abgeschlossen.")
ZO_CreateStringId("GS_PURGING_DUPLICATES", "Duplikate entfernen.")
ZO_CreateStringId("GS_PURGING_DUPLICATES_DELAY", "Das Entfernen der Duplikate der Verkaufs-Einträge wird nach dem aktuellen Scan beginnen.")
ZO_CreateStringId("GS_SLIDING_SALES", "Verschiebe deine Verkäufe.")
ZO_CreateStringId("GS_SLIDING_SALES_DELAY", "Verschieben der Verkaufs-Einträge wird nach dem aktuellen Scan beginnen.")
ZO_CreateStringId("GS_CLEAN_START", "Aufräumen von falschen Einträgen.")
ZO_CreateStringId("GS_CLEAN_START_DELAY", "Das Aufräumen von falschen Einträgen wird nach dem aktuellen Scan beginnen.")
ZO_CreateStringId("GS_CLEAN_UPDATE_DESC", "LibGuildStore Clean: Aktualisiert den Suche Text.")
ZO_CreateStringId("GS_MINIMAL_INDEXING", "LibGuildStore konfiguriert für minimale Indizierung.")
ZO_CreateStringId("GS_FULL_INDEXING", "LibGuildStore konfiguriert für Komplette Indizierung.")
ZO_CreateStringId("GS_INDEXING_SUMMARY", "Indizierung: Benötigte %s Sekunden, um %s Verkäufe zu indizieren, %s eindeutige Wörter")
ZO_CreateStringId("GS_SLIDING_SUMMARY", "Umzug: Benötigte %s Sekunden, um %s Verkäufe nach %s umzuziehen.")
ZO_CreateStringId("GS_CP_RANK_SEARCH", "cp")
ZO_CreateStringId("GS_REGULAR_RANK_SEARCH", "rr")
ZO_CreateStringId("GS_INIT_SALES_HISTORY_SUMMARY", "Init Gilden und Gegenstand Summe: benöigte %s Sekunden zum initialisieren von %s Einträgen.")
ZO_CreateStringId("GS_INIT_PURCHASES_HISTORY_SUMMARY", "Init Kauf Summe: benöigte %s Sekunden zum initialisieren von %s records.")
ZO_CreateStringId("GS_INIT_LISTINGS_HISTORY_SUMMARY", "Init Gelistete Summe: benöigte %s Sekunden zum initialisieren von %s Einträgen.")
ZO_CreateStringId("GS_TRUNCATE_NAME", "Zusammenfassung kürzen aktivieren")
ZO_CreateStringId("GS_TRUNCATE_TIP", "Zeige gekürzte Zusammenfassung der Summen nachdem der Vorgang abgeschlossen wurde.")
ZO_CreateStringId("GS_GUILD_ITEM_SUMMARY_NAME", "Aktiviere Gilden und Gegenstand Zusammenfassung")
ZO_CreateStringId("GS_GUILD_ITEM_SUMMARY_TIP", "Zeige Gilden und Gegenstands Summen Zusammenfassung nachdem der Vorgang abgeschlossen wurde.")
ZO_CreateStringId("GS_INDEXING_NAME", "Aktiviere Indizierung Zusammenfassung")
ZO_CreateStringId("GS_INDEXING_TIP", "Zeige Indizierung Zusammenfassung nachdem der Vorgang abgeschlossen wurde.")
ZO_CreateStringId("GS_CLEANING_TIME_ELAPSED", "Aufräumen: benötigte %s Sekunden zum aufräumen:")
ZO_CreateStringId("GS_CLEANING_BAD_REMOVED", '  %s falsche Verkäufe entfernt')
ZO_CreateStringId("GS_CLEANING_REINDEXED", '  %s Verkäufe re-indiziert')
ZO_CreateStringId("GS_CLEANING_WRONG_VERSION", '  %s falsche Gegenstands-Versionen')
ZO_CreateStringId("GS_CLEANING_WRONG_ID", '  %s falsche Item IDs')
ZO_CreateStringId("GS_CLEANING_WRONG_MULE", '  %s falsche mule Item IDs')
ZO_CreateStringId("GS_CLEANING_STRINGS_CONVERTED", '  %s Events mit Nummern zu String konvertiert')
ZO_CreateStringId("GS_CLEANING_BAD_ITEMLINKS", '  %s falsche Itemlinks entfernt')
ZO_CreateStringId("GS_RESET_CONFIRM_TITLE", "Bestätige Zurücksetzen")
ZO_CreateStringId("GS_RESET_CONFIRM_MAIN", "Willst du wirklich deine Verkäufe Historie zurücksetzen? Du musst danach LibHistoire aktualisieren, um neue Daten zu erhalten.")

ZO_CreateStringId("GS_REFRESH_NOT_FINISHED", "LibGuildStore Aktualisierung nicht beendet")
ZO_CreateStringId("GS_REFRESH_FINISHED", "LibGuildStore Aktualisierung beendet")
ZO_CreateStringId("GS_REFRESH_STARTING", "Beginne LibGuildStore Aktualisierung")

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
ZO_CreateStringId("GS_KNOWN_BUTTON", "Bekannt")

-- buttons to toggle personal and guild sales
ZO_CreateStringId("GS_VIEW_POSTED_ITEMS", "Zeige gebuchte Gegenstände")
ZO_CreateStringId("GS_VIEW_CANCELED_ITEMS", "Zeige abgebrochene Gegenstände")
-- window title viewMode - Personal sales
ZO_CreateStringId("GS_POSTED_ITEMS_TITLE", "Gebuchte Gegenstände")
-- window title viewSize - All sales
ZO_CreateStringId("GS_CANCELED_ITEMS_TITLE", "Abgebrochene Gegenstände")

ZO_CreateStringId("GS_LIBGUILDSTORE_INITIALIZING", "LibGuildStore Initialisierung")
ZO_CreateStringId("GS_LIBGUILDSTORE_REFERENCE_DATA", "LibGuildStore Referencing Sales Data Containers")
ZO_CreateStringId("GS_LIBGUILDSTORE_TRUNCATE", "LibGuildStore Abschneiden der Einträge begonnen...")
ZO_CreateStringId("GS_LIBGUILDSTORE_HISTORY_INIT", "LibGuildStore Historie Initialisierung begonnen...")
ZO_CreateStringId("GS_LIBGUILDSTORE_BUSY", "LibGuildStore ist beschäftigt")

ZO_CreateStringId("GS_IMPORTING_ATT_SALES", "Importiere ATT Verkäufe")
ZO_CreateStringId("GS_ATT_MISSING", "Arkadius Trade Tools Verkäufe-Daten wurden nicht gefunden.")
ZO_CreateStringId("GS_IMPORTING_MM_SALES", "Importiere MasterMerchant Verkäufe")
ZO_CreateStringId("GS_MM_MISSING", "Alte Master Merchant Verkäufe wurden nicht gefunden.")
ZO_CreateStringId("GS_MM_EU_NA_IMPORT_WARN", "Deine MM Daten beinhalten Werte von verschiedenen Servern. Alle MM Versionen vor v3.6.x haben diese Verkäufe Daten nicht je Server separiert. Du musst diese in den LibGuildStore Einstellungen überschreiben.")
ZO_CreateStringId("GS_MM_EU_NA_DIFFERENT_SERVER_WARN", "Du versuchst MM Daten zu importieren, aber du bist auf einem davon abweichendem Server eingeloggt. Du musst diese in den LibGuildStore Einstellungen überschreiben.")
ZO_CreateStringId("GS_RESET_EU_INSTEAD", "Zurücksetzen abgebrochen, da LibHistoire EU Server Daten stattdessen aktualisieren würde.")
ZO_CreateStringId("GS_RESET_NA_INSTEAD", "Zurücksetzen abgebrochen, da LibHistoire NA Server Daten stattdessen aktualisieren würde.")
ZO_CreateStringId("GS_SHOPPINGLIST_MISSING", "ShoppingList ist nicht aktiv")
ZO_CreateStringId("GS_SHOPPINGLIST_IMPORTED", "ShoppingList Daten importiert.")
ZO_CreateStringId("GS_ELAPSED_TIME_FORMATTER", "%s Sekunden um %s Einträge zu verarbeiten")
ZO_CreateStringId("GS_ATT_PURCHASE_DATA_MISSING", "Arkadius Trade Tools Käufe Daten wurden nicht gefunden.")
ZO_CreateStringId("GS_ATT_PURCHASE_DATA_IMPORTED", "Arkadius Trade Tools Käufe Daten wurde importiert.")

-- dropdown choices
ZO_CreateStringId("GS_DEAL_CALC_TTC_SUGGESTED", "TTC Vorgeschlagen")
ZO_CreateStringId("GS_DEAL_CALC_TTC_AVERAGE", "TTC Durchschnitt")
ZO_CreateStringId("GS_DEAL_CALC_MM_AVERAGE", "MM Durchschnitt")
ZO_CreateStringId("GS_DEAL_CALC_BONANZA_PRICE", "Bonanza Preis")

-- description menu text
ZO_CreateStringId("GS_IMPORT_MM_SALES", "Importiere MM Verkäufe")
ZO_CreateStringId("GS_IMPORT_ATT_SALES", "Importiere ATT Verkäufe")
ZO_CreateStringId("GS_IMPORT_ATT_PURCHASES", "Importiere ATT Käufe")
ZO_CreateStringId("GS_REFRESH_LIBHISTOIRE_DATA", "Aktualisiere LibHistoire Datenbank")
ZO_CreateStringId("GS_IMPORT_SHOPPINGLIST", "Importiere ShoppingList")
ZO_CreateStringId("GS_RESET_LIBGUILDSTORE", "Setze NA LibGuildStore zurück")
ZO_CreateStringId("GS_RESET_EU_LIBGUILDSTORE", "Setze EU LibGuildStore zurück")
