# Graph Report - .  (2026-07-15)

## Corpus Check
- 201 files · ~128,537 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2673 nodes · 3581 edges · 131 communities (108 shown, 23 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 41 edges (avg confidence: 0.83)
- Token cost: 85,189 input · 0 output

## Community Hubs (Navigation)
- Localization — Bengali strings
- Localization — delegate/API
- Localization — English strings
- Drift DAO query builders
- Drift columns & converters
- Windows plugin registrant (native)
- Products & stock-adjust UI
- Riverpod core providers
- Drift data classes/companions
- Business-type & branch controllers
- Session & orders providers
- Receipt rendering
- POS cart & checkout UI
- Settings & staff dialog UI
- Product picker widget
- Order editor (KOT) UI
- Product CSV import/export
- Design doc — architecture rules
- Cart controller logic
- Sales DAO
- Printer transport
- Reports dashboard
- Drift DAO accessors
- DB & inventory tests
- Demo catalog seed
- ESC/POS print service
- Core unit tests
- Router & feature wiring
- Drift table definitions
- Linux GTK runner (native)
- Returns DAO & converters
- Purchases screen UI
- Customers screen UI
- Login screen UI
- iOS app delegate (native)
- History & returns UI
- Orders DAO
- App loader animation
- PIN hashing (PBKDF2)
- Products/Settings DAO
- Stock DAO
- Invoice export (PDF/PNG)
- Money type
- Sale draft models
- App bootstrap & router files
- Purchases DAO
- Linux Flutter texture (native)
- KOT rendering
- Receipt dialog UI
- Product visuals & theme
- Onboarding screen UI
- Shared UI widgets
- Inventory screen UI
- Linux Flutter engine headers (native)
- Taka formatting
- Platform build config (CMake)
- Printing tests
- Cart tests
- Windows runner (native)
- Staff DAO
- Device store
- Database open/wipe/restore
- SMS DAO
- Settings providers & app root
- Customers DAO
- SMS templates
- Logo raster
- App shell & permission providers
- Analytics tests
- Logo raster tests
- Module picker & app gate
- Qty type
- Invoice numbering
- Design doc — business model/licensing
- Linux Flutter method response (native)
- Linux Flutter plugin registrar (native)
- Linux Flutter texture registrar (native)
- App loader widgets
- Permissions / RBAC model
- Returns companion
- LLDB helper (native)
- iOS plugin registrant (native)
- Brand constants
- Localizations delegate
- Android plugin registrant (native)
- Gradle wrapper
- App icon design (images)
- PrinterUnavailable exception
- Linux generated plugin registrant
- UUIDv7 IDs
- Linux Flutter codec classes (native)
- Returns DAO tests
- build
- MainActivity.kt
- l10n every string (bn + en) rule
- Multi-module POS (business_type)
- _FlMethodCodecClass
- flutter_lints ruleset
- Money integer paisa type
- Backup / Restore (.db snapshot)
- PrinterBackend Plugin Interface
- Package.swift
- flutter_export_environment.sh
- Default Flutter Splash Screen (unbranded
- Android Launcher Icon Set
- Branding from brand.dart rule
- Feature-first layout (data/logic/ui)
- Settings
- Shop Logo Raster Header
- BD SMS Gateway Dispatch
- Release Pipeline (Windows zip + Android 
- iOS App Icon Set
- iOS Launch Image Set
- iOS Launch Screen Assets README
- l10n Codegen Config
- String?
- intl dependency
- Qty (Integer Milli-Units)
- Staff PINs & Roles (Offline Login)

## God Nodes (most connected - your core abstractions)
1. `databaseProvider` - 60 edges
2. `AppDatabase` - 23 edges
3. `Win32Window` - 22 edges
4. `SyncColumns` - 21 edges
5. `currentStaffProvider` - 18 edges
6. `Return` - 15 edges
7. `businessTypeProvider` - 14 edges
8. `_SettingsScreenState` - 13 edges
9. `MessageHandler` - 12 edges
10. `FlutterWindow` - 10 edges

## Surprising Connections (you probably didn't know these)
- `Offline-first rule` --semantically_similar_to--> `Offline-first rule (design)`  [INFERRED] [semantically similar]
  CLAUDE.md → docs/DESIGN.md
- `Last-write-wins conflict resolution` --semantically_similar_to--> `Stock is derived rule`  [INFERRED] [semantically similar]
  docs/DESIGN.md → CLAUDE.md
- `CSV Product Import/Export` --conceptually_related_to--> `Data model (Drift/SQLite mirrored in Postgres)`  [INFERRED]
  README.md → docs/DESIGN.md
- `Analytics Dashboard` --conceptually_related_to--> `Data model (Drift/SQLite mirrored in Postgres)`  [INFERRED]
  README.md → docs/DESIGN.md
- `Finalized sales immutable rule` --conceptually_related_to--> `Sync engine (Cloud Plan)`  [INFERRED]
  CLAUDE.md → docs/DESIGN.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Thermal Printing Stack** — docs_design_thermal_printer_escpos, docs_operations_printer_transport, docs_operations_printer_backend, docs_operations_shop_logo_raster, docs_design_cash_drawer_kick [INFERRED 0.85]
- **Conflict-free sync via append-only movements** — docs_design_sync_engine, docs_design_outbox_pattern, docs_design_stock_movements, claude_sync_contract [EXTRACTED 0.90]
- **Offline-first local source of truth** — docs_design_offline_first_rule, pubspec_drift, docs_design_data_model, docs_design_supabase [INFERRED 0.80]
- **Multi-module POS sharing one sales engine** — docs_design_modules, docs_design_restaurant_module, docs_design_supershop_module, docs_design_data_model [EXTRACTED 0.85]

## Communities (131 total, 23 thin omitted)

### Community 0 - "Localization — Bengali strings"
Cohesion: 0.01
Nodes (268): app_localizations_bn.dart, app_localizations_en.dart, class, dart:async, addBranch, addCustomer, addLine, addProduct (+260 more)

### Community 1 - "Localization — delegate/API"
Cohesion: 0.01
Nodes (253): app_localizations.dart, addBranch, addCustomer, addLine, addProduct, addStaff, addSupplier, addTable (+245 more)

### Community 2 - "Localization — English strings"
Cohesion: 0.01
Nodes (253): addBranch, addCustomer, addLine, addProduct, addStaff, addSupplier, addTable, addToOrder (+245 more)

### Community 3 - "Drift DAO query builders"
Cohesion: 0.01
Nodes (204): ColumnFilters, ColumnOrderings, ColumnWithTypeConverterFilters, daos/customers_dao.dart, daos/orders_dao.dart, daos/products_dao.dart, daos/purchases_dao.dart, daos/sales_dao.dart (+196 more)

### Community 4 - "Drift columns & converters"
Cohesion: 0.02
Nodes (94): BoolColumn get, converters.dart, DateTimeColumn get, ../ids.dart, IntColumn get, address, amount, area (+86 more)

### Community 5 - "Windows plugin registrant (native)"
Cohesion: 0.06
Nodes (54): FlutterViewController, PluginRegistry, Point, RECT, Size, unique_ptr, RegisterPlugins(), DartProject (+46 more)

### Community 6 - "Products & stock-adjust UI"
Cohesion: 0.05
Nodes (46): ../../../core/csv/product_csv.dart, catalogScopeProvider, AdjustStockDialog, _AdjustStockDialogState, _applyFilters, _barcode, _categoryId, controller (+38 more)

### Community 7 - "Riverpod core providers"
Cohesion: 0.06
Nodes (45): ConsumerWidget, ../../../core/qty.dart, branchId, build, categoriesProvider, customerDueProvider, customersProvider, databaseProvider (+37 more)

### Community 8 - "Drift data classes/companions"
Cohesion: 0.09
Nodes (43): DataClass, CategoriesCompanion, Category, Customer, CustomersCompanion, DineOrder, DineOrderItem, DineOrderItemsCompanion (+35 more)

### Community 9 - "Business-type & branch controllers"
Cohesion: 0.05
Nodes (40): await, build, BusinessType, BusinessTypeController, businessTypeFromString, clear, markOnboarded, ref (+32 more)

### Community 10 - "Session & orders providers"
Cohesion: 0.07
Nodes (37): app/providers.dart, ../../auth/logic/session.dart, ../../../core/db/database.dart, diningTablesProvider, openOrdersProvider, build, login, logout (+29 more)

### Community 11 - "Receipt rendering"
Cohesion: 0.06
Nodes (32): address, center, change, copyWith, dateTime, discount, divider, due (+24 more)

### Community 12 - "POS cart & checkout UI"
Cohesion: 0.09
Nodes (29): ../../../app/widgets/product_picker.dart, ConsumerState, cartProvider, _bkash, _card, _CartPane, _cash, CheckoutDialog (+21 more)

### Community 13 - "Settings & staff dialog UI"
Cohesion: 0.07
Nodes (29): ../../../core/printing/printer_transport.dart, StaffRole, _AddStaffDialog, _AddStaffDialogState, _buildLogoRow, createState, _currentConfig, _device (+21 more)

### Community 14 - "Product picker widget"
Cohesion: 0.09
Nodes (26): app/brand.dart, ../../../core/seed/demo_catalog.dart, build, category, _clearSearch, createState, dispose, emptyBuilder (+18 more)

### Community 15 - "Order editor (KOT) UI"
Cohesion: 0.07
Nodes (27): ../../../core/printing/kot.dart, _bkash, _card, _cash, createState, _customerId, dispose, _formKey (+19 more)

### Community 16 - "Product CSV import/export"
Cohesion: 0.07
Nodes (27): barcode, cell, _columns, encodeCsv, endField, endRow, errors, field (+19 more)

### Community 17 - "Design doc — architecture rules"
Cohesion: 0.08
Nodes (27): Finalized sales immutable rule, Stock is derived rule, Row sync contract (UUIDv7 id, updatedAt, deletedAt, deviceId), Architecture (Flutter app + Supabase), Baki khata (customer credit), Barcode scanner (USB HID keyboard-wedge), Data model (Drift/SQLite mirrored in Postgres), Hardware integration (scanner/printer/drawer) (+19 more)

### Community 18 - "Cart controller logic"
Cohesion: 0.08
Nodes (26): ../../../core/db/sale_draft.dart, addManual, addProduct, billDiscount, build, CartController, CartLine, CartState (+18 more)

### Community 19 - "Sales DAO"
Cohesion: 0.07
Nodes (26): _, managers, SalesDaoManager, ../../invoice_number.dart, byId, count, DailyTotal, dailyTotals (+18 more)

### Community 20 - "Printer transport"
Cohesion: 0.08
Nodes (26): DefaultPrinterBackend, device, discover, discoverPrinters, encodeType, host, id, loadPrinterConfig (+18 more)

### Community 21 - "Reports dashboard"
Cohesion: 0.07
Nodes (26): avg, child, color, _compact, count, DashboardData, days, db (+18 more)

### Community 22 - "Drift DAO accessors"
Cohesion: 0.14
Nodes (25): _, @DriftAccessor, @DriftDatabase, _$CustomersDaoMixin, DatabaseAccessor, CustomersDao, OrdersDao, ProductsDao (+17 more)

### Community 23 - "DB & inventory tests"
Cohesion: 0.11
Nodes (19): package:bechakena/core/db/database.dart, package:bechakena/core/db/sale_draft.dart, package:bechakena/features/auth/logic/permissions.dart, package:drift/drift.dart, package:drift/native.dart, addProduct, db, main (+11 more)

### Community 24 - "Demo catalog seed"
Cohesion: 0.08
Nodes (23): ../db/database.dart, barcode, bn, cat, _categories, colorHex, _DemoCategory, _DemoProduct (+15 more)

### Community 25 - "ESC/POS print service"
Cohesion: 0.08
Nodes (23): escpos.dart, address, bytes, cfg, change, composeReceiptBytes, escPosBytes, kickDrawer (+15 more)

### Community 26 - "Core unit tests"
Cohesion: 0.10
Nodes (17): package:bechakena/core/auth/pin.dart, package:bechakena/core/csv/product_csv.dart, package:bechakena/core/format.dart, package:bechakena/core/invoice_number.dart, package:bechakena/core/money.dart, package:bechakena/core/seed/demo_catalog.dart, package:bechakena/core/sms/templates.dart, package:flutter_test/flutter_test.dart (+9 more)

### Community 27 - "Router & feature wiring"
Cohesion: 0.09
Nodes (22): business_type.dart, ../features/auth/logic/permissions.dart, ../features/customers/ui/customers_screen.dart, ../features/history/ui/history_screen.dart, ../features/inventory/ui/inventory_screen.dart, ../features/pos/ui/pos_screen.dart, ../features/products/ui/products_screen.dart, ../features/purchases/ui/purchases_screen.dart (+14 more)

### Community 28 - "Drift table definitions"
Cohesion: 0.16
Nodes (23): Categories, Customers, DineOrderItems, DineOrders, DiningTables, DuePayments, Products, PurchaseItems (+15 more)

### Community 29 - "Linux GTK runner (native)"
Cohesion: 0.12
Nodes (19): FlView, GApplication, gboolean, gchar, GtkApplication, main(), GObject, first_frame_cb() (+11 more)

### Community 30 - "Returns DAO & converters"
Cohesion: 0.10
Nodes (20): _, managers, ReturnsDaoManager, fromSql, MoneyConverter, QtyConverter, toSql, createReturn (+12 more)

### Community 31 - "Purchases screen UI"
Cohesion: 0.12
Nodes (21): productsProvider, _addSupplier, build, cost, createState, dispose, _draftItems, expiry (+13 more)

### Community 32 - "Customers screen UI"
Cohesion: 0.11
Nodes (20): ConsumerStatefulWidget, ../../../core/sms/templates.dart, AddCustomerDialog, _AddCustomerDialogState, _amount, createState, customer, customerId (+12 more)

### Community 33 - "Login screen UI"
Cohesion: 0.12
Nodes (20): FormState, currentStaffProvider, _busy, _confirm, _create, createState, dispose, _error (+12 more)

### Community 34 - "iOS app delegate (native)"
Cohesion: 0.11
Nodes (14): Any, Bool, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate (+6 more)

### Community 35 - "History & returns UI"
Cohesion: 0.13
Nodes (19): ../../auth/logic/permissions.dart, ../../../core/money.dart, ../../../core/printing/receipt.dart, recentSalesProvider, canProvider, build, createState, HistoryScreen (+11 more)

### Community 36 - "Orders DAO"
Cohesion: 0.10
Nodes (19): _, managers, OrdersDaoManager, addManual, addProduct, byId, cancelOrder, createOrder (+11 more)

### Community 37 - "App loader animation"
Cohesion: 0.11
Nodes (18): AnimationController, ../brand.dart, Color, CustomPainter, build, _c, core, createState (+10 more)

### Community 38 - "PIN hashing (PBKDF2)"
Cohesion: 0.11
Nodes (18): dart:math, actual, _constantTimeEquals, diff, digest, expected, hashPin, hmac (+10 more)

### Community 39 - "Products/Settings DAO"
Cohesion: 0.11
Nodes (17): database.dart, _, managers, ProductsDaoManager, _, managers, SettingsDaoManager, byBarcode (+9 more)

### Community 40 - "Stock DAO"
Cohesion: 0.11
Nodes (18): Expression, _, managers, StockDaoManager, addMovement, _deltaSum, ExpiringBatch, expiringSoon (+10 more)

### Community 41 - "Invoice export (PDF/PNG)"
Cohesion: 0.11
Nodes (17): dart:ui, boundary, captureInvoicePng, dir, doc, file, _fileStem, image (+9 more)

### Community 42 - "Money type"
Cohesion: 0.12
Nodes (16): int get, const, _divRound, isNegative, isZero, netOfVat, paisaPart, parse (+8 more)

### Community 43 - "Sale draft models"
Cohesion: 0.12
Nodes (16): amount, lineDiscount, lineTotal, method, nameSnapshot, productId, qty, refNo (+8 more)

### Community 44 - "App bootstrap & router files"
Cohesion: 0.12
Nodes (15): app/router.dart, app/theme.dart, app/widgets/app_loader.dart, core/db/device_store.dart, core/db/open.dart, features/auth/logic/session.dart, features/auth/ui/login_screen.dart, features/onboarding/ui/module_picker_screen.dart (+7 more)

### Community 45 - "Purchases DAO"
Cohesion: 0.12
Nodes (15): DateTime, _, managers, PurchasesDaoManager, createPurchase, expiryDate, insertSupplier, itemsOf (+7 more)

### Community 46 - "Linux Flutter texture (native)"
Cohesion: 0.12
Nodes (13): fl_texture, FlTexture, _FlPixelBufferTextureClass, parent_class, GObjectClass, G_DECLARE_INTERFACE(), _FlTextureGLClass, parent_class (+5 more)

### Community 47 - "KOT rendering"
Cohesion: 0.12
Nodes (15): _center, _fit, _formatDateTime, join, KotLine, lines, name, note (+7 more)

### Community 49 - "Receipt dialog UI"
Cohesion: 0.14
Nodes (14): ../../../core/printing/invoice_export.dart, ../../../core/printing/print_service.dart, l10n/gen/app_localizations.dart, _boundaryKey, build, createState, invoiceNo, kickDrawer (+6 more)

### Community 50 - "Product visuals & theme"
Cohesion: 0.13
Nodes (13): colorFromHex, path, productEmoji, substring, value, _base, darkTheme, light (+5 more)

### Community 51 - "Onboarding screen UI"
Cohesion: 0.15
Nodes (13): app/business_type.dart, IconData, body, _controller, createState, dispose, _finish, icon (+5 more)

### Community 52 - "Shared UI widgets"
Cohesion: 0.14
Nodes (14): SplashScreen, _EmptyLine, _ExpiringTile, _LowStockTile, _SectionHeader, _ModuleCard, _TourPage, _ProductThumb (+6 more)

### Community 53 - "Inventory screen UI"
Cohesion: 0.18
Nodes (12): ../../../app/product_visuals.dart, ../../../core/format.dart, expiringSoonProvider, lowStockProvider, batch, build, color, icon (+4 more)

### Community 54 - "Linux Flutter engine headers (native)"
Cohesion: 0.19
Nodes (6): GtkApplicationClass, GTypeInterface, _FlApplicationClass, parent_class, _FlPluginRegistryInterface, g_iface

### Community 55 - "Taka formatting"
Cohesion: 0.15
Nodes (12): abs, _banglaDigits, decimals, formatAmount, formatTaka, grouped, groups, join (+4 more)

### Community 56 - "Platform build config (CMake)"
Cohesion: 0.21
Nodes (13): Linux Project CMake Config, com.newell.bechakena GTK Application ID, bechakena Linux Executable (BINARY_NAME), Linux Flutter Build Config, Linux flutter Library Target, Linux flutter_assemble Target, Linux Runner Executable Build, Windows Project CMake Config (+5 more)

### Community 57 - "Printing tests"
Cohesion: 0.15
Nodes (10): package:bechakena/core/printing/escpos.dart, package:bechakena/core/printing/receipt.dart, package:bechakena/core/qty.dart, db, main, _containsSeq, false, main (+2 more)

### Community 58 - "Cart tests"
Cohesion: 0.15
Nodes (12): package:bechakena/features/pos/logic/cart_controller.dart, ProviderContainer, cart, container, id, main, name, now (+4 more)

### Community 59 - "Windows runner (native)"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 60 - "Staff DAO"
Cohesion: 0.18
Nodes (10): ../../auth/pin.dart, _, managers, StaffDaoManager, createStaff, hasAnyStaff, softDelete, verifyPin (+2 more)

### Community 61 - "Device store"
Cohesion: 0.18
Nodes (10): dart:convert, File, DeviceStore, _file, _fileName, load, _values, package:path/path.dart (+2 more)

### Community 62 - "Database open/wipe/restore"
Cohesion: 0.18
Nodes (10): dart:io, archived, archiveLegacyDatabase, databaseFile, dir, legacy, openAppDatabase, pendingRestoreFile (+2 more)

### Community 63 - "SMS DAO"
Cohesion: 0.18
Nodes (10): _, managers, SmsDaoManager, enqueue, markFailed, markSent, _setStatus, watchLog (+2 more)

### Community 64 - "Settings providers & app root"
Cohesion: 0.27
Nodes (11): branchesProvider, currentBranchProvider, localeProvider, themeModeProvider, routerProvider, build, _buildBranchSection, SettingsScreen (+3 more)

### Community 65 - "Customers DAO"
Cohesion: 0.20
Nodes (9): CustomersDaoManager get, _, CustomersDaoManager, managers, addDuePayment, dueFor, insertCustomer, watchAll (+1 more)

### Community 66 - "SMS templates"
Cohesion: 0.20
Nodes (9): ../format.dart, amount, dueClause, locale, renderDueReminderSms, renderReceiptSms, _smsAmount, totalStr (+1 more)

### Community 67 - "Logo raster"
Cohesion: 0.20
Nodes (9): Image?, bytesPerRow, data, decoded, escPosRaster, height, image, tryEscPosRasterFromImage (+1 more)

### Community 68 - "App shell & permission providers"
Cohesion: 0.27
Nodes (10): isRestaurantProvider, AppShell, build, capabilitiesProvider, hasStaffProvider, staffListProvider, build, LoginScreen (+2 more)

### Community 69 - "Analytics tests"
Cohesion: 0.20
Nodes (9): day1, day2, day3, db, end, main, product, sell (+1 more)

### Community 70 - "Logo raster tests"
Cohesion: 0.22
Nodes (8): dart:typed_data, package:bechakena/core/printing/logo_raster.dart, package:image/image.dart, _contains, false, image, main, _solid

### Community 71 - "Module picker & app gate"
Cohesion: 0.22
Nodes (9): businessTypeProvider, onboardedProvider, ModulePickerScreen, _pick, build, _backup, _clearData, _restore (+1 more)

### Community 72 - "Qty type"
Cohesion: 0.25
Nodes (7): bool get, const, isNegative, isZero, parse, zero, static const Qty

### Community 73 - "Invoice numbering"
Cohesion: 0.25
Nodes (7): dd, deviceNo, devicePrefix, formatInvoiceNo, mm, yy, required int seq,
  int

### Community 74 - "Design doc — business model/licensing"
Cohesion: 0.29
Nodes (7): BechaKena (POS product), Business model (one-time license + Cloud Plan), Licensing & activation (Ed25519), Product thesis, Operations Guide, CI Pipeline (analyze + test), crypto dependency

### Community 75 - "Linux Flutter method response (native)"
Cohesion: 0.29
Nodes (7): fl_method_response, FlMethodResponse, G_MODULE_EXPORT, G_DECLARE_DERIVABLE_TYPE(), FL, GObject, METHOD_RESPONSE

### Community 76 - "Linux Flutter plugin registrar (native)"
Cohesion: 0.29
Nodes (7): fl_plugin_registrar, FlPluginRegistrar, G_DECLARE_INTERFACE(), FL, G_BEGIN_DECLS, GObject, PLUGIN_REGISTRAR

### Community 77 - "Linux Flutter texture registrar (native)"
Cohesion: 0.29
Nodes (7): fl_texture_registrar, FlTextureRegistrar, G_DECLARE_INTERFACE(), FL, G_BEGIN_DECLS, GObject, TEXTURE_REGISTRAR

### Community 78 - "App loader widgets"
Cohesion: 0.33
Nodes (7): AppLoader, _AppLoaderState, _GuestNameDialog, _GuestNameDialogState, SingleTickerProviderStateMixin, State, StatefulWidget

### Community 79 - "Permissions / RBAC model"
Cohesion: 0.29
Nodes (6): can, Capability, _matrix, role, Map, session.dart

### Community 80 - "Returns companion"
Cohesion: 0.33
Nodes (5): Return, ReturnsCompanion, bytes, escPosBytes, kickDrawer

### Community 81 - "LLDB helper (native)"
Cohesion: 0.33
Nodes (5): handle_new_rx_page(), __lldb_init_module(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages., SBDebugger, SBFrame

### Community 82 - "iOS plugin registrant (native)"
Cohesion: 0.40
Nodes (3): GeneratedPluginRegistrant, +registerWithRegistry, NSObject

### Community 83 - "Brand constants"
Cohesion: 0.33
Nodes (5): Brand, company, name, nameBn, static const String

### Community 84 - "Localizations delegate"
Cohesion: 0.40
Nodes (6): AppLocalizations, _AppLocalizationsDelegate, AppLocalizationsBn, AppLocalizationsEn, of, LocalizationsDelegate

### Community 85 - "Android plugin registrant (native)"
Cohesion: 0.60
Nodes (3): GeneratedPluginRegistrant, FlutterEngine, Keep

### Community 86 - "Gradle wrapper"
Cohesion: 0.60
Nodes (3): gradlew script, die(), warn()

### Community 87 - "App icon design (images)"
Cohesion: 0.60
Nodes (5): Blue Gradient Color Palette, Default Placeholder App Branding, Flutter Logo Mark, Stylized Angular F / Chevron Glyph, BechaKena App Launcher Icon (1024px)

### Community 88 - "PrinterUnavailable exception"
Cohesion: 0.40
Nodes (4): Exception, PrinterUnavailable, package:bechakena/core/printing/printer_transport.dart, main

### Community 89 - "Linux generated plugin registrant"
Cohesion: 0.40
Nodes (3): FlPluginRegistry, fl_register_plugins(), my_application_activate()

### Community 90 - "UUIDv7 IDs"
Cohesion: 0.40
Nodes (4): currentDeviceId, newUuidV7, _uuid, package:uuid/uuid.dart

### Community 91 - "Linux Flutter codec classes (native)"
Cohesion: 0.40
Nodes (5): _FlMessageCodecClass, parent_class, GObjectClass, _FlStandardMessageCodecClass, parent_class

### Community 93 - "Returns DAO tests"
Cohesion: 0.40
Nodes (4): addProduct, db, main, sell

### Community 94 - "build"
Cohesion: 0.67
Nodes (4): build, _dashboardProvider, _rangeDaysProvider, ReportsScreen

### Community 96 - "l10n every string (bn + en) rule"
Cohesion: 0.67
Nodes (3): l10n every string (bn + en) rule, Offline-first rule, Offline-first rule (design)

### Community 97 - "Multi-module POS (business_type)"
Cohesion: 1.00
Nodes (3): Multi-module POS (business_type), Restaurant module (dining floor + KOT), Supershop / retail module

### Community 98 - "_FlMethodCodecClass"
Cohesion: 0.67
Nodes (3): _FlMethodCodecClass, parent_class, GObjectClass

## Ambiguous Edges - Review These
- `BechaKena iOS Launch Image (default blank white)` → `Default Flutter Splash Screen (unbranded)`  [AMBIGUOUS]
  ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png · relation: conceptually_related_to
- `l10n every string (bn + en) rule` → `Offline-first rule (design)`  [AMBIGUOUS]
  CLAUDE.md · relation: conceptually_related_to
- `Generated files committed convention` → `flutter_lints ruleset`  [AMBIGUOUS]
  CLAUDE.md · relation: conceptually_related_to

## Knowledge Gaps
- **1818 isolated node(s):** `PackageDescription`, `flutter_export_environment.sh script`, `+registerWithRegistry`, `XCTest`, `Brand` (+1813 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **23 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `BechaKena iOS Launch Image (default blank white)` and `Default Flutter Splash Screen (unbranded)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `l10n every string (bn + en) rule` and `Offline-first rule (design)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Generated files committed convention` and `flutter_lints ruleset`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `Return` connect `Returns companion` to `Drift DAO query builders`, `PIN hashing (PBKDF2)`, `Riverpod core providers`, `Drift data classes/companions`, `Business-type & branch controllers`, `Money type`, `Logo raster tests`, `Permissions / RBAC model`, `Product CSV import/export`, `Demo catalog seed`, `Printing tests`?**
  _High betweenness centrality (0.060) - this node is a cross-community bridge._
- **Why does `AppDatabase` connect `Drift DAO accessors` to `Drift DAO query builders`, `Analytics tests`, `Riverpod core providers`, `DB & inventory tests`, `Printing tests`, `Core unit tests`, `Returns DAO tests`?**
  _High betweenness centrality (0.035) - this node is a cross-community bridge._
- **Why does `StaffRole` connect `Settings & staff dialog UI` to `Drift DAO query builders`, `Drift columns & converters`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **What connects `PackageDescription`, `flutter_export_environment.sh script`, `+registerWithRegistry` to the rest of the system?**
  _1818 weakly-connected nodes found - possible documentation gaps or missing edges._