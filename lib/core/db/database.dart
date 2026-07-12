import 'package:drift/drift.dart';

import '../ids.dart';
import '../money.dart';
import '../qty.dart';
import 'converters.dart';
import 'daos/customers_dao.dart';
import 'daos/products_dao.dart';
import 'daos/purchases_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/staff_dao.dart';
import 'daos/stock_dao.dart';
import 'tables.dart';

export 'daos/customers_dao.dart';
export 'daos/products_dao.dart';
export 'daos/purchases_dao.dart';
export 'daos/sales_dao.dart';
export 'daos/settings_dao.dart';
export 'daos/staff_dao.dart';
export 'daos/stock_dao.dart';
export 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Shops,
    Staff,
    Categories,
    Products,
    StockMovements,
    Customers,
    Sales,
    SaleItems,
    SalePayments,
    DuePayments,
    Suppliers,
    Purchases,
    PurchaseItems,
    SmsLog,
    SyncOutbox,
    Settings,
  ],
  daos: [
    ProductsDao,
    StockDao,
    SalesDao,
    CustomersDao,
    PurchasesDao,
    SettingsDao,
    StaffDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
