"""SQL evidence for audit #972: real foreign keys, indexes and deletion rules."""
from pathlib import Path
import sqlite3
import unittest

ROOT = Path(__file__).resolve().parent.parent


class SchemaTests(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        self.addCleanup(self.db.close)
        self.db.execute('PRAGMA foreign_keys = ON')
        self.db.executescript((ROOT / 'database/schema.sql').read_text(encoding='utf-8'))
        self.db.executescript((ROOT / 'database/seed.sql').read_text(encoding='utf-8'))

    def test_every_foreign_key_is_restrictive_and_has_an_index_prefix(self):
        count = 0
        for (table,) in self.db.execute("SELECT name FROM sqlite_master WHERE type='table'"):
            prefixes = {
                row[2]
                for index in self.db.execute(f'PRAGMA index_list("{table}")')
                for row in self.db.execute(f'PRAGMA index_info("{index[1]}")')
                if row[0] == 0
            }
            for fk in self.db.execute(f'PRAGMA foreign_key_list("{table}")'):
                count += 1
                self.assertEqual(fk[6], 'RESTRICT', f'{table}.{fk[3]}')
                self.assertIn(fk[3], prefixes, f'{table}.{fk[3]}')
        self.assertEqual(count, 25)
        self.assertEqual(self.db.execute('PRAGMA user_version').fetchone()[0], 9)
        self.assertEqual(self.db.execute('PRAGMA foreign_key_check').fetchall(), [])

    def test_referenced_branch_and_sale_cannot_be_deleted(self):
        for table, column in [('shops', 'branch_id'), ('sales', 'sale_id')]:
            child = 'stock_movements' if table == 'shops' else 'sale_items'
            key = self.db.execute(f'SELECT {column} FROM {child} LIMIT 1').fetchone()[0]
            with self.assertRaises(sqlite3.IntegrityError):
                self.db.execute(f'DELETE FROM {table} WHERE id = ?', (key,))

    def test_stock_lookup_uses_existing_composite_index(self):
        plan = self.db.execute('EXPLAIN QUERY PLAN SELECT SUM(qty_delta) FROM stock_movements '
                               'WHERE product_id = ? AND branch_id = ?', ('product', 'branch')).fetchall()
        self.assertIn('idx_stock_movements_branch_product', str(plan))


if __name__ == '__main__':
    unittest.main()
