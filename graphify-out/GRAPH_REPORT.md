# Graph Report - .  (2026-07-12)

## Corpus Check
- 185 files · ~100,743 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2004 nodes · 2664 edges · 90 communities (84 shown, 6 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 29 edges (avg confidence: 0.82)
- Token cost: 73,500 input · 9,100 output

## Community Hubs (Navigation)
- Drift DAOs & Query Builders
- Localization (Bengali/English)
- Localization Getters (English)
- Localization Getters (Bengali)
- Drift Table Schema
- Windows Runner Shell
- ESC/POS Printing Pipeline
- Database Open & Backup/Restore
- POS Sales Screen & Checkout
- Auth PIN & Crypto Utils
- Drift Data Classes / Companions
- Staff Auth & Login
- Product Design Concepts
- Receipt Layout
- Printer Transport & Discovery
- Products Screen & CSV
- Core Package Imports
- Sales DAO & Reporting
- Product CSV Encoding
- Analytics Dashboard
- Drift/Analytics Tests
- Cart Controller
- Customers & Due Screen
- Purchases DAO & Converters
- App Shell (Router/Theme/Brand)
- Receipt Providers & Money/Qty
- DAO Accessors (Generated)
- Linux Runner Shell
- Purchases Screen
- iOS/macOS App Delegate
- Categories
- Customers Screen
- Product Visuals
-  
- Expression
- Int Get
- Sale Draft
- Database
- Fl Texture
- Main
-  
- Gtkapplicationclass
- Format
- Cart Controller
- Utils
- Pin
-  
-  
- Appshell
- Format
- Bool Get
- Localecontroller
- Invoice Number
- Fl Method Response
- Fl Plugin Registrar
- Fl Texture Registrar
- Escpos
- Return
- Flutter Lldb Helper
- Generatedpluginregistran
- Brand
- Applocalizations
- Generatedpluginregistran
- Gradlew
- Blue Gradient Color Pale
- Cash Drawer Kick (Dle Dc
- Generated Plugin Registr
- Ids
- Parent Class
- Returns Dao Test
- Build
- Mainactivity
-  Flmethodcodecclass
- English L10N (Arb)
- Package
- Flutter Export Environme
- Default Flutter Splash S
- String?

## God Nodes (most connected - your core abstractions)
1. `databaseProvider` - 37 edges
2. `Win32Window` - 22 edges
3. `AppDatabase` - 21 edges
4. `SyncColumns` - 18 edges
5. `Return` - 13 edges
6. `currentStaffProvider` - 13 edges
7. `MessageHandler` - 12 edges
8. `FlutterWindow` - 10 edges
9. `Create` - 10 edges
10. `WndProc` - 10 edges

## Surprising Connections (you probably didn't know these)
- `Qty (Integer Milli-Units)` --semantically_similar_to--> `Money as Integer Paisa`  [INFERRED] [semantically similar]
  README.md → docs/DESIGN.md
- `Analytics Dashboard` --conceptually_related_to--> `Data Model (Drift/SQLite)`  [INFERRED]
  README.md → docs/DESIGN.md
- `CSV Product Import/Export` --conceptually_related_to--> `Data Model (Drift/SQLite)`  [INFERRED]
  README.md → docs/DESIGN.md
- `CI Pipeline (analyze + test)` --references--> `BechaKena`  [INFERRED]
  .github/workflows/ci.yml → docs/DESIGN.md
- `Staff PINs & Roles (Offline Login)` --conceptually_related_to--> `Offline-First Rule`  [INFERRED]
  README.md → docs/DESIGN.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Conflict-Free Sync Architecture** — docs_design_sync_engine, docs_design_sync_outbox_table, docs_design_sync_contract, docs_design_derived_stock, docs_design_immutable_sales [EXTRACTED 0.85]
- **Thermal Printing Stack** — docs_design_thermal_printer_escpos, docs_operations_printer_transport, docs_operations_printer_backend, docs_operations_shop_logo_raster, docs_design_cash_drawer_kick [INFERRED 0.85]
- **Offline-First Data Guarantees** — docs_design_offline_first, docs_design_money_integer_paisa, docs_design_derived_stock, docs_design_immutable_sales [EXTRACTED 0.90]

## Communities (90 total, 6 thin omitted)

### Community 0 - "Drift DAOs & Query Builders"
Cohesion: 0.01
Nodes (178): ColumnFilters, ColumnOrderings, ColumnWithTypeConverterFilters, daos/customers_dao.dart, daos/products_dao.dart, daos/purchases_dao.dart, daos/sales_dao.dart, daos/settings_dao.dart (+170 more)

### Community 1 - "Localization (Bengali/English)"
Cohesion: 0.01
Nodes (173): app_localizations_bn.dart, app_localizations_en.dart, class, dart:async, addCustomer, addLine, addProduct, addStaff (+165 more)

### Community 2 - "Localization Getters (English)"
Cohesion: 0.01
Nodes (159): app_localizations.dart, addCustomer, addLine, addProduct, addStaff, addSupplier, adjustStock, allCategories (+151 more)

### Community 3 - "Localization Getters (Bengali)"
Cohesion: 0.01
Nodes (158): addCustomer, addLine, addProduct, addStaff, addSupplier, adjustStock, allCategories, alreadyReturned (+150 more)

### Community 4 - "Drift Table Schema"
Cohesion: 0.02
Nodes (83): BoolColumn get, converters.dart, DateTimeColumn get, ../ids.dart, IntColumn get, address, amount, barcode (+75 more)

### Community 5 - "Windows Runner Shell"
Cohesion: 0.06
Nodes (54): FlutterViewController, PluginRegistry, Point, RECT, Size, unique_ptr, RegisterPlugins(), DartProject (+46 more)

### Community 6 - "ESC/POS Printing Pipeline"
Cohesion: 0.04
Nodes (43): ../db/database.dart, escpos.dart, address, bytes, cfg, change, composeReceiptBytes, escPosBytes (+35 more)

### Community 7 - "Database Open & Backup/Restore"
Cohesion: 0.05
Nodes (38): ../../../core/printing/printer_transport.dart, dart:io, databaseFile, dir, openAppDatabase, pendingRestoreFile, pendingWipeFile, StaffRole (+30 more)

### Community 8 - "POS Sales Screen & Checkout"
Cohesion: 0.07
Nodes (39): ../../../core/seed/demo_catalog.dart, categoriesProvider, cartProvider, _bkash, build, _card, _CartPane, _cash (+31 more)

### Community 9 - "Auth PIN & Crypto Utils"
Cohesion: 0.05
Nodes (36): dart:convert, dart:math, dart:typed_data, Image?, actual, _constantTimeEquals, diff, digest (+28 more)

### Community 10 - "Drift Data Classes / Companions"
Cohesion: 0.10
Nodes (37): DataClass, CategoriesCompanion, Category, Customer, CustomersCompanion, DuePayment, DuePaymentsCompanion, Product (+29 more)

### Community 11 - "Staff Auth & Login"
Cohesion: 0.08
Nodes (34): ConsumerState, ConsumerStatefulWidget, currentStaffProvider, hasStaffProvider, staffListProvider, build, _busy, _confirm (+26 more)

### Community 12 - "Product Design Concepts"
Cohesion: 0.07
Nodes (35): Baki Khata (Customer Credit), USB HID Keyboard-Wedge Barcode Scanner, BechaKena, Cloud Plan, Data Model (Drift/SQLite), Derived Stock (SUM of qtyDelta), Drift (SQLite) Local DB, Flutter (+27 more)

### Community 13 - "Receipt Layout"
Cohesion: 0.06
Nodes (32): address, center, change, copyWith, dateTime, discount, divider, due (+24 more)

### Community 14 - "Printer Transport & Discovery"
Cohesion: 0.06
Nodes (30): Exception, DefaultPrinterBackend, device, discover, discoverPrinters, encodeType, host, id (+22 more)

### Community 15 - "Products Screen & CSV"
Cohesion: 0.09
Nodes (30): ../../../core/csv/product_csv.dart, databaseProvider, productsProvider, stockProvider, AddProductDialog, _AddProductDialogState, AdjustStockDialog, _AdjustStockDialogState (+22 more)

### Community 16 - "Core Package Imports"
Cohesion: 0.09
Nodes (21): package:bechakena/core/auth/pin.dart, package:bechakena/core/csv/product_csv.dart, package:bechakena/core/format.dart, package:bechakena/core/invoice_number.dart, package:bechakena/core/money.dart, package:bechakena/core/qty.dart, package:bechakena/core/seed/demo_catalog.dart, package:bechakena/core/sms/templates.dart (+13 more)

### Community 17 - "Sales DAO & Reporting"
Cohesion: 0.07
Nodes (27): _, managers, SalesDaoManager, ../../invoice_number.dart, byId, count, DailyTotal, dailyTotals (+19 more)

### Community 18 - "Product CSV Encoding"
Cohesion: 0.07
Nodes (27): barcode, cell, _columns, encodeCsv, endField, endRow, errors, field (+19 more)

### Community 19 - "Analytics Dashboard"
Cohesion: 0.07
Nodes (27): avg, child, color, _compact, count, DashboardData, days, db (+19 more)

### Community 20 - "Drift/Analytics Tests"
Cohesion: 0.09
Nodes (23): package:bechakena/core/db/database.dart, package:bechakena/core/db/sale_draft.dart, package:drift/drift.dart, package:drift/native.dart, day1, day2, day3, db (+15 more)

### Community 21 - "Cart Controller"
Cohesion: 0.08
Nodes (26): ../../../core/db/sale_draft.dart, addManual, addProduct, billDiscount, build, CartController, CartLine, CartState (+18 more)

### Community 22 - "Customers & Due Screen"
Cohesion: 0.09
Nodes (25): ConsumerWidget, ../../../core/sms/templates.dart, FormState, customerDueProvider, customersProvider, _amount, build, createState (+17 more)

### Community 23 - "Purchases DAO & Converters"
Cohesion: 0.09
Nodes (24): DateTime, _, managers, PurchasesDaoManager, fromSql, MoneyConverter, QtyConverter, toSql (+16 more)

### Community 24 - "App Shell (Router/Theme/Brand)"
Cohesion: 0.10
Nodes (22): app/brand.dart, app/providers.dart, app/router.dart, app/theme.dart, ../../../core/printing/print_service.dart, features/auth/logic/session.dart, features/auth/ui/login_screen.dart, l10n/gen/app_localizations.dart (+14 more)

### Community 25 - "Receipt Providers & Money/Qty"
Cohesion: 0.10
Nodes (23): ../../auth/logic/session.dart, ../../../core/db/open.dart, ../../../core/money.dart, ../../../core/printing/receipt.dart, ../../../core/qty.dart, dart:ui, build, db (+15 more)

### Community 26 - "DAO Accessors (Generated)"
Cohesion: 0.15
Nodes (23): _, @DriftAccessor, @DriftDatabase, _$CustomersDaoMixin, DatabaseAccessor, CustomersDao, ProductsDao, PurchasesDao (+15 more)

### Community 27 - "Linux Runner Shell"
Cohesion: 0.12
Nodes (19): FlView, GApplication, gboolean, gchar, GtkApplication, main(), GObject, first_frame_cb() (+11 more)

### Community 28 - "Purchases Screen"
Cohesion: 0.12
Nodes (20): _addSupplier, build, cost, createState, dispose, _draftItems, expiry, _invoiceRef (+12 more)

### Community 29 - "iOS/macOS App Delegate"
Cohesion: 0.11
Nodes (14): Any, Bool, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate, FlutterSceneDelegate, AppDelegate (+6 more)

### Community 30 - "Categories"
Cohesion: 0.18
Nodes (20): Categories, Customers, DuePayments, Products, PurchaseItems, Purchases, ReturnItems, Returns (+12 more)

### Community 31 - "Customers Screen"
Cohesion: 0.11
Nodes (17): ../features/customers/ui/customers_screen.dart, ../features/history/ui/history_screen.dart, ../features/inventory/ui/inventory_screen.dart, ../features/pos/ui/pos_screen.dart, ../features/products/ui/products_screen.dart, ../features/purchases/ui/purchases_screen.dart, ../features/reports/ui/reports_screen.dart, ../features/settings/ui/settings_screen.dart (+9 more)

### Community 32 - "Product Visuals"
Cohesion: 0.13
Nodes (16): ../../../app/product_visuals.dart, Color, ../../../core/format.dart, IconData, expiringSoonProvider, lowStockProvider, ExpiringBatch, LowStockRow (+8 more)

### Community 33 - " "
Cohesion: 0.12
Nodes (15): CustomersDaoManager get, database.dart, _, CustomersDaoManager, managers, _, managers, SettingsDaoManager (+7 more)

### Community 34 - "Expression"
Cohesion: 0.12
Nodes (16): Expression, _, managers, StockDaoManager, addMovement, _deltaSum, expiringSoon, expiryDate (+8 more)

### Community 35 - "Int Get"
Cohesion: 0.12
Nodes (16): int get, const, _divRound, isNegative, isZero, netOfVat, paisaPart, parse (+8 more)

### Community 36 - "Sale Draft"
Cohesion: 0.12
Nodes (16): amount, lineDiscount, lineTotal, method, nameSnapshot, productId, qty, refNo (+8 more)

### Community 37 - "Database"
Cohesion: 0.12
Nodes (14): ../../../core/db/database.dart, colorFromHex, path, productEmoji, substring, value, _base, darkTheme (+6 more)

### Community 38 - "Fl Texture"
Cohesion: 0.12
Nodes (13): fl_texture, FlTexture, _FlPixelBufferTextureClass, parent_class, GObjectClass, G_DECLARE_INTERFACE(), _FlTextureGLClass, parent_class (+5 more)

### Community 40 - "Main"
Cohesion: 0.13
Nodes (14): package:bechakena/app/providers.dart, package:bechakena/features/auth/logic/session.dart, package:bechakena/main.dart, package:flutter/widgets.dart, build, db, main, _owner (+6 more)

### Community 41 - " "
Cohesion: 0.14
Nodes (13): _, managers, ReturnsDaoManager, createReturn, itemsOf, nameSnapshot, productId, qty (+5 more)

### Community 42 - "Gtkapplicationclass"
Cohesion: 0.19
Nodes (6): GtkApplicationClass, GTypeInterface, _FlApplicationClass, parent_class, _FlPluginRegistryInterface, g_iface

### Community 43 - "Format"
Cohesion: 0.15
Nodes (12): abs, _banglaDigits, decimals, formatAmount, formatTaka, grouped, groups, join (+4 more)

### Community 44 - "Cart Controller"
Cohesion: 0.15
Nodes (12): package:bechakena/features/pos/logic/cart_controller.dart, ProviderContainer, cart, container, id, main, name, now (+4 more)

### Community 45 - "Utils"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 46 - "Pin"
Cohesion: 0.18
Nodes (10): ../../auth/pin.dart, _, managers, StaffDaoManager, createStaff, hasAnyStaff, softDelete, verifyPin (+2 more)

### Community 47 - " "
Cohesion: 0.18
Nodes (10): _, managers, ProductsDaoManager, byBarcode, byId, insertProduct, softDelete, updateProduct (+2 more)

### Community 48 - " "
Cohesion: 0.18
Nodes (10): _, managers, SmsDaoManager, enqueue, markFailed, markSent, _setStatus, watchLog (+2 more)

### Community 49 - "Appshell"
Cohesion: 0.18
Nodes (11): AppShell, _EmptyLine, _ExpiringTile, _LowStockTile, _SectionHeader, _ChartCard, _PaymentSplit, _StatCard (+3 more)

### Community 50 - "Format"
Cohesion: 0.20
Nodes (9): ../format.dart, amount, dueClause, locale, renderDueReminderSms, renderReceiptSms, _smsAmount, totalStr (+1 more)

### Community 51 - "Bool Get"
Cohesion: 0.25
Nodes (7): bool get, const, isNegative, isZero, parse, zero, static const Qty

### Community 52 - "Localecontroller"
Cohesion: 0.25
Nodes (8): LocaleController, SessionController, _SearchQuery, _SelectedCategory, _RangeDays, Locale?, Notifier, _LoggedInSession

### Community 53 - "Invoice Number"
Cohesion: 0.25
Nodes (7): dd, deviceNo, devicePrefix, formatInvoiceNo, mm, yy, required int seq,
  int

### Community 54 - "Fl Method Response"
Cohesion: 0.29
Nodes (7): fl_method_response, FlMethodResponse, G_MODULE_EXPORT, G_DECLARE_DERIVABLE_TYPE(), FL, GObject, METHOD_RESPONSE

### Community 55 - "Fl Plugin Registrar"
Cohesion: 0.29
Nodes (7): fl_plugin_registrar, FlPluginRegistrar, G_DECLARE_INTERFACE(), FL, G_BEGIN_DECLS, GObject, PLUGIN_REGISTRAR

### Community 56 - "Fl Texture Registrar"
Cohesion: 0.29
Nodes (7): fl_texture_registrar, FlTextureRegistrar, G_DECLARE_INTERFACE(), FL, G_BEGIN_DECLS, GObject, TEXTURE_REGISTRAR

### Community 57 - "Escpos"
Cohesion: 0.29
Nodes (6): package:bechakena/core/printing/escpos.dart, package:bechakena/core/printing/receipt.dart, _containsSeq, false, main, sampleReceipt

### Community 58 - "Return"
Cohesion: 0.33
Nodes (5): Return, ReturnsCompanion, bytes, escPosBytes, kickDrawer

### Community 59 - "Flutter Lldb Helper"
Cohesion: 0.33
Nodes (5): handle_new_rx_page(), __lldb_init_module(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages., SBDebugger, SBFrame

### Community 60 - "Generatedpluginregistran"
Cohesion: 0.40
Nodes (3): GeneratedPluginRegistrant, +registerWithRegistry, NSObject

### Community 61 - "Brand"
Cohesion: 0.33
Nodes (5): Brand, company, name, nameBn, static const String

### Community 62 - "Applocalizations"
Cohesion: 0.40
Nodes (6): AppLocalizations, _AppLocalizationsDelegate, AppLocalizationsBn, AppLocalizationsEn, of, LocalizationsDelegate

### Community 63 - "Generatedpluginregistran"
Cohesion: 0.60
Nodes (3): GeneratedPluginRegistrant, FlutterEngine, Keep

### Community 64 - "Gradlew"
Cohesion: 0.60
Nodes (3): gradlew script, die(), warn()

### Community 65 - "Blue Gradient Color Pale"
Cohesion: 0.60
Nodes (5): Blue Gradient Color Palette, Default Placeholder App Branding, Flutter Logo Mark, Stylized Angular F / Chevron Glyph, BechaKena App Launcher Icon (1024px)

### Community 66 - "Cash Drawer Kick (Dle Dc"
Cohesion: 0.40
Nodes (5): Cash Drawer Kick (DLE DC4), ESC/POS Thermal Printer, PrinterBackend Plugin Interface, Printer Transport (LAN/USB/Bluetooth), Shop Logo Raster Header

### Community 67 - "Generated Plugin Registr"
Cohesion: 0.40
Nodes (3): FlPluginRegistry, fl_register_plugins(), my_application_activate()

### Community 68 - "Ids"
Cohesion: 0.40
Nodes (4): currentDeviceId, newUuidV7, _uuid, package:uuid/uuid.dart

### Community 69 - "Parent Class"
Cohesion: 0.40
Nodes (5): _FlMessageCodecClass, parent_class, GObjectClass, _FlStandardMessageCodecClass, parent_class

### Community 71 - "Returns Dao Test"
Cohesion: 0.40
Nodes (4): addProduct, db, main, sell

### Community 72 - "Build"
Cohesion: 0.67
Nodes (4): build, _dashboardProvider, _rangeDaysProvider, ReportsScreen

### Community 74 - " Flmethodcodecclass"
Cohesion: 0.67
Nodes (3): _FlMethodCodecClass, parent_class, GObjectClass

## Ambiguous Edges - Review These
- `BechaKena iOS Launch Image (default blank white)` → `Default Flutter Splash Screen (unbranded)`  [AMBIGUOUS]
  ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png · relation: conceptually_related_to

## Knowledge Gaps
- **1303 isolated node(s):** `PackageDescription`, `flutter_export_environment.sh script`, `+registerWithRegistry`, `XCTest`, `Brand` (+1298 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `BechaKena iOS Launch Image (default blank white)` and `Default Flutter Splash Screen (unbranded)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `Return` connect `Return` to `Drift DAOs & Query Builders`, `Int Get`, `ESC/POS Printing Pipeline`, `Main`, `Auth PIN & Crypto Utils`, `Drift Data Classes / Companions`, `Product CSV Encoding`, `Receipt Providers & Money/Qty`, `Escpos`?**
  _High betweenness centrality (0.068) - this node is a cross-community bridge._
- **Why does `StaffRole` connect `Database Open & Backup/Restore` to `Drift DAOs & Query Builders`, `Drift Table Schema`?**
  _High betweenness centrality (0.029) - this node is a cross-community bridge._
- **Why does `AppDatabase` connect `DAO Accessors (Generated)` to `Drift DAOs & Query Builders`, `Returns Dao Test`, `Core Package Imports`, `Drift/Analytics Tests`, `Receipt Providers & Money/Qty`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **What connects `PackageDescription`, `flutter_export_environment.sh script`, `+registerWithRegistry` to the rest of the system?**
  _1303 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Drift DAOs & Query Builders` be split into smaller, more focused modules?**
  _Cohesion score 0.0111731843575419 - nodes in this community are weakly interconnected._
- **Should `Localization (Bengali/English)` be split into smaller, more focused modules?**
  _Cohesion score 0.011494252873563218 - nodes in this community are weakly interconnected._