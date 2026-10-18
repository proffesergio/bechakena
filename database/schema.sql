-- ─────────────────────────────────────────────────────────────────────────────
-- BechaKena — complete SQLite schema, schema version 6.
--
-- This file creates the database from scratch. It is generated from the Drift
-- table definitions in lib/core/db/tables.dart, which remain the source of
-- truth; upgrade migrations for older installs live in
-- lib/core/db/database.dart (MigrationStrategy).
--
-- How the app uses it:
--   • Each business module owns its own SQLite file — 'bechakena_superShop.db'
--     / 'bechakena_restaurant.db' in the app support directory — and creates
--     this schema on first launch. Nothing here needs to be run by hand.
--   • `dart run tool/dump_schema.dart` regenerates this file.
--
-- Conventions you can rely on:
--   • Money columns are INTEGER paisa (1 BDT = 100 paisa); never floats.
--   • Quantity columns are INTEGER milli-units (1 pc = 1000; 250 g = 250 kg).
--   • Stock is derived: stock = SUM(stock_movements.qty_delta) per product
--     and branch. There is no stored stock column anywhere.
--   • Finalized sales are immutable; corrections are returns/adjustments.
--   • Every synced row carries id (UUIDv7), updated_at, deleted_at and
--     device_id for the optional multi-device Cloud Plan.
--   • id/updated_at/device_id defaults are applied by the app, not by SQLite,
--     so this script always receives explicit values on insert.
-- ─────────────────────────────────────────────────────────────────────────────
-- Schema version: v6
-- Generated:      dart run tool/dump_schema.dart
-- Tables:         21

CREATE TABLE "categories" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "name" TEXT NOT NULL, "name_bn" TEXT NULL, "color_hex" TEXT NULL, "sort_order" INTEGER NOT NULL DEFAULT 0, "business_type" TEXT NOT NULL DEFAULT 'superShop', PRIMARY KEY ("id"));

CREATE TABLE "customers" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "name" TEXT NOT NULL, "phone" TEXT NULL, "address" TEXT NULL, "sms_opt_in" INTEGER NOT NULL DEFAULT 1 CHECK ("sms_opt_in" IN (0, 1)), PRIMARY KEY ("id"));

CREATE TABLE "dine_order_items" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "order_id" TEXT NOT NULL REFERENCES dine_orders (id), "product_id" TEXT NULL REFERENCES products (id), "name_snapshot" TEXT NOT NULL, "qty" INTEGER NOT NULL, "unit_price" INTEGER NOT NULL, "vat_rate_bp" INTEGER NOT NULL DEFAULT 0, "note" TEXT NULL, "kot_sent" INTEGER NOT NULL DEFAULT 0 CHECK ("kot_sent" IN (0, 1)), "created_at" INTEGER NOT NULL, PRIMARY KEY ("id"));

CREATE TABLE "dine_orders" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "table_id" TEXT NULL REFERENCES dining_tables (id), "order_type" TEXT NOT NULL, "status" TEXT NOT NULL DEFAULT 'open', "branch_id" TEXT NULL REFERENCES shops (id), "staff_id" TEXT NULL REFERENCES staff (id), "customer_name" TEXT NULL, "customer_phone" TEXT NULL, "note" TEXT NULL, "sale_id" TEXT NULL REFERENCES sales (id), "created_at" INTEGER NOT NULL, PRIMARY KEY ("id"));

CREATE TABLE "dining_tables" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "name" TEXT NOT NULL, "area" TEXT NULL, "seats" INTEGER NOT NULL DEFAULT 0, "sort_order" INTEGER NOT NULL DEFAULT 0, "is_active" INTEGER NOT NULL DEFAULT 1 CHECK ("is_active" IN (0, 1)), PRIMARY KEY ("id"));

CREATE TABLE "due_payments" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "customer_id" TEXT NOT NULL REFERENCES customers (id), "amount" INTEGER NOT NULL, "method" TEXT NOT NULL, "note" TEXT NULL, "created_at" INTEGER NOT NULL, PRIMARY KEY ("id"));

CREATE TABLE "products" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "barcode" TEXT NULL, "sku" TEXT NULL, "name" TEXT NOT NULL, "name_bn" TEXT NULL, "category_id" TEXT NULL REFERENCES categories (id), "unit" TEXT NOT NULL DEFAULT 'pcs', "sale_price" INTEGER NOT NULL, "cost_price" INTEGER NOT NULL DEFAULT 0, "vat_rate_bp" INTEGER NOT NULL DEFAULT 0, "low_stock_level" INTEGER NOT NULL DEFAULT 0, "image_path" TEXT NULL, "is_active" INTEGER NOT NULL DEFAULT 1 CHECK ("is_active" IN (0, 1)), "business_type" TEXT NOT NULL DEFAULT 'superShop', PRIMARY KEY ("id"));

CREATE TABLE "purchase_items" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "purchase_id" TEXT NOT NULL REFERENCES purchases (id), "product_id" TEXT NOT NULL REFERENCES products (id), "qty" INTEGER NOT NULL, "unit_cost" INTEGER NOT NULL, "expiry_date" INTEGER NULL, PRIMARY KEY ("id"));

CREATE TABLE "purchases" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "branch_id" TEXT NULL REFERENCES shops (id), "supplier_id" TEXT NULL REFERENCES suppliers (id), "invoice_ref" TEXT NULL, "total_cost" INTEGER NOT NULL DEFAULT 0, "created_at" INTEGER NOT NULL, PRIMARY KEY ("id"));

CREATE TABLE "return_items" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "return_id" TEXT NOT NULL REFERENCES returns (id), "product_id" TEXT NULL REFERENCES products (id), "name_snapshot" TEXT NOT NULL, "qty" INTEGER NOT NULL, "refund_amount" INTEGER NOT NULL, PRIMARY KEY ("id"));

CREATE TABLE "returns" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "original_sale_id" TEXT NULL REFERENCES sales (id), "staff_id" TEXT NULL REFERENCES staff (id), "refund_total" INTEGER NOT NULL, "note" TEXT NULL, "created_at" INTEGER NOT NULL, PRIMARY KEY ("id"));

CREATE TABLE "sale_items" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "sale_id" TEXT NOT NULL REFERENCES sales (id), "product_id" TEXT NULL REFERENCES products (id), "name_snapshot" TEXT NOT NULL, "qty" INTEGER NOT NULL, "unit_price" INTEGER NOT NULL, "line_discount" INTEGER NOT NULL DEFAULT 0, "vat_rate_bp" INTEGER NOT NULL DEFAULT 0, "line_total" INTEGER NOT NULL, PRIMARY KEY ("id"));

CREATE TABLE "sale_payments" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "sale_id" TEXT NOT NULL REFERENCES sales (id), "method" TEXT NOT NULL, "amount" INTEGER NOT NULL, "ref_no" TEXT NULL, PRIMARY KEY ("id"));

CREATE TABLE "sales" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "invoice_no" TEXT NOT NULL UNIQUE, "branch_id" TEXT NULL REFERENCES shops (id), "staff_id" TEXT NULL REFERENCES staff (id), "customer_id" TEXT NULL REFERENCES customers (id), "subtotal" INTEGER NOT NULL, "discount" INTEGER NOT NULL DEFAULT 0, "vat" INTEGER NOT NULL DEFAULT 0, "total" INTEGER NOT NULL, "paid" INTEGER NOT NULL, "due" INTEGER NOT NULL DEFAULT 0, "status" TEXT NOT NULL, "created_at" INTEGER NOT NULL, PRIMARY KEY ("id"));

CREATE TABLE "settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, PRIMARY KEY ("key"));

CREATE TABLE "shops" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "name" TEXT NOT NULL, "name_bn" TEXT NULL, "logo_path" TEXT NULL, "address" TEXT NULL, "phone" TEXT NULL, "vat_rate_bp" INTEGER NOT NULL DEFAULT 0, "receipt_footer" TEXT NULL, "invoice_prefix" TEXT NOT NULL DEFAULT 'BK', PRIMARY KEY ("id"));

CREATE TABLE "sms_log" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "customer_id" TEXT NULL REFERENCES customers (id), "phone" TEXT NOT NULL, "kind" TEXT NOT NULL, "body" TEXT NOT NULL, "status" TEXT NOT NULL, "created_at" INTEGER NOT NULL, PRIMARY KEY ("id"));

CREATE TABLE "staff" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "name" TEXT NOT NULL, "pin_hash" TEXT NOT NULL, "role" TEXT NOT NULL, PRIMARY KEY ("id"));

CREATE TABLE "stock_movements" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "product_id" TEXT NOT NULL REFERENCES products (id), "branch_id" TEXT NULL REFERENCES shops (id), "qty_delta" INTEGER NOT NULL, "type" TEXT NOT NULL, "ref_id" TEXT NULL, "expiry_date" INTEGER NULL, "note" TEXT NULL, "created_at" INTEGER NOT NULL, PRIMARY KEY ("id"));

CREATE TABLE "suppliers" ("id" TEXT NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "device_id" TEXT NOT NULL, "name" TEXT NOT NULL, "phone" TEXT NULL, "address" TEXT NULL, PRIMARY KEY ("id"));

CREATE TABLE "sync_outbox" ("seq" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "table_name" TEXT NOT NULL, "row_id" TEXT NOT NULL, "op" TEXT NOT NULL, "payload" TEXT NOT NULL, "queued_at" INTEGER NOT NULL);

PRAGMA user_version = 6;
