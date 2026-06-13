/// 数据库完整 DDL 定义
class DatabaseSchema {
  DatabaseSchema._();

  static const String v1Initial = '''
-- ==================== 账本 ====================
CREATE TABLE IF NOT EXISTS books (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  color TEXT DEFAULT '#2196F3',
  sort_order INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER DEFAULT NULL
);
CREATE INDEX IF NOT EXISTS idx_books_uuid ON books(uuid);
CREATE INDEX IF NOT EXISTS idx_books_updated ON books(updated_at);

-- ==================== 账户 ====================
CREATE TABLE IF NOT EXISTS accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  book_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  type INTEGER NOT NULL,
  balance INTEGER DEFAULT 0,
  currency TEXT DEFAULT 'CNY',
  icon TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER DEFAULT NULL,
  FOREIGN KEY (book_id) REFERENCES books(id)
);
CREATE INDEX IF NOT EXISTS idx_accounts_uuid ON accounts(uuid);
CREATE INDEX IF NOT EXISTS idx_accounts_book ON accounts(book_id);
CREATE INDEX IF NOT EXISTS idx_accounts_updated ON accounts(updated_at);

-- ==================== 分类 ====================
CREATE TABLE IF NOT EXISTS categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  parent_id INTEGER DEFAULT NULL,
  name TEXT NOT NULL,
  type INTEGER NOT NULL,
  icon TEXT,
  color TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER DEFAULT NULL,
  FOREIGN KEY (parent_id) REFERENCES categories(id)
);
CREATE INDEX IF NOT EXISTS idx_categories_uuid ON categories(uuid);
CREATE INDEX IF NOT EXISTS idx_categories_type ON categories(type);
CREATE INDEX IF NOT EXISTS idx_categories_updated ON categories(updated_at);

-- ==================== 标签 ====================
CREATE TABLE IF NOT EXISTS tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL UNIQUE,
  color TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER DEFAULT NULL
);
CREATE INDEX IF NOT EXISTS idx_tags_uuid ON tags(uuid);

-- ==================== 账单 ====================
CREATE TABLE IF NOT EXISTS transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  book_id INTEGER NOT NULL,
  type INTEGER NOT NULL,
  amount INTEGER NOT NULL,
  category_id INTEGER NOT NULL,
  from_account_id INTEGER,
  to_account_id INTEGER,
  date INTEGER NOT NULL,
  timezone_utc_offset INTEGER,
  comment TEXT,
  payer TEXT,
  description TEXT,
  images TEXT,
  location TEXT,
  is_reimbursable INTEGER DEFAULT 0,
  is_scheduled INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER DEFAULT NULL,
  FOREIGN KEY (book_id) REFERENCES books(id),
  FOREIGN KEY (category_id) REFERENCES categories(id),
  FOREIGN KEY (from_account_id) REFERENCES accounts(id),
  FOREIGN KEY (to_account_id) REFERENCES accounts(id)
);
CREATE INDEX IF NOT EXISTS idx_transactions_uuid ON transactions(uuid);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date);
CREATE INDEX IF NOT EXISTS idx_transactions_book ON transactions(book_id);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_updated ON transactions(updated_at);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);

-- ==================== 账单-标签关联 ====================
CREATE TABLE IF NOT EXISTS transaction_tags (
  transaction_id INTEGER NOT NULL,
  tag_id INTEGER NOT NULL,
  PRIMARY KEY (transaction_id, tag_id),
  FOREIGN KEY (transaction_id) REFERENCES transactions(id),
  FOREIGN KEY (tag_id) REFERENCES tags(id)
);

-- ==================== 预算 ====================
CREATE TABLE IF NOT EXISTS budgets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  book_id INTEGER NOT NULL,
  category_id INTEGER,
  amount INTEGER NOT NULL,
  period_type INTEGER NOT NULL,
  start_date INTEGER,
  end_date INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER DEFAULT NULL,
  FOREIGN KEY (book_id) REFERENCES books(id),
  FOREIGN KEY (category_id) REFERENCES categories(id)
);
CREATE INDEX IF NOT EXISTS idx_budgets_uuid ON budgets(uuid);

-- ==================== 借贷 ====================
CREATE TABLE IF NOT EXISTS loans (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  type INTEGER NOT NULL,
  person TEXT NOT NULL,
  amount INTEGER NOT NULL,
  date INTEGER NOT NULL,
  due_date INTEGER,
  is_repaid INTEGER DEFAULT 0,
  description TEXT,
  book_id INTEGER,
  account_id INTEGER,
  exclude_from_io INTEGER DEFAULT 1,
  exclude_from_budget INTEGER DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER DEFAULT NULL
);
CREATE INDEX IF NOT EXISTS idx_loans_uuid ON loans(uuid);

-- ==================== 设置 ====================
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value TEXT,
  updated_at INTEGER NOT NULL
);
''';

  static const String v8ScheduledTransactions = '''
CREATE TABLE IF NOT EXISTS scheduled_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL UNIQUE,
  book_id INTEGER NOT NULL,
  type INTEGER NOT NULL,
  amount INTEGER NOT NULL,
  category_id INTEGER NOT NULL,
  from_account_id INTEGER,
  to_account_id INTEGER,
  description TEXT,
  comment TEXT,
  location TEXT,
  is_reimbursable INTEGER DEFAULT 0,
  frequency INTEGER NOT NULL,
  interval_count INTEGER DEFAULT 1,
  day_of_month INTEGER,
  weekday INTEGER,
  start_date INTEGER NOT NULL,
  end_date INTEGER,
  next_run_at INTEGER NOT NULL,
  last_run_at INTEGER,
  is_paused INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER DEFAULT NULL,
  FOREIGN KEY (book_id) REFERENCES books(id),
  FOREIGN KEY (category_id) REFERENCES categories(id),
  FOREIGN KEY (from_account_id) REFERENCES accounts(id),
  FOREIGN KEY (to_account_id) REFERENCES accounts(id)
);
CREATE INDEX IF NOT EXISTS idx_scheduled_uuid ON scheduled_transactions(uuid);
CREATE INDEX IF NOT EXISTS idx_scheduled_next_run ON scheduled_transactions(next_run_at);
CREATE INDEX IF NOT EXISTS idx_scheduled_book ON scheduled_transactions(book_id);
ALTER TABLE transactions ADD COLUMN scheduled_transaction_id INTEGER;
CREATE INDEX IF NOT EXISTS idx_transactions_scheduled ON transactions(scheduled_transaction_id);
''';

  static const String v9LoanExtensions = '''
ALTER TABLE loans ADD COLUMN book_id INTEGER;
ALTER TABLE loans ADD COLUMN account_id INTEGER;
ALTER TABLE loans ADD COLUMN exclude_from_io INTEGER DEFAULT 1;
ALTER TABLE loans ADD COLUMN exclude_from_budget INTEGER DEFAULT 1;
''';
}
