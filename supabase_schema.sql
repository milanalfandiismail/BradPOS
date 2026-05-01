-- ============================================================
-- BRADPOS - Complete Database Schema for Supabase
-- Target: UMKM (Kuliner, Retail, Jasa, dll)
-- Authors: BradPOS Team
-- ============================================================

-- ============================================================
-- EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ============================================================
-- 1. KARYAWAN (Staff / Karyawan)
-- Relasi: karyawan.owner_id → auth.users.id
-- ============================================================
CREATE TABLE IF NOT EXISTS karyawan (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_karyawan_owner_id ON karyawan(owner_id);
CREATE INDEX IF NOT EXISTS idx_karyawan_email ON karyawan(email);

ALTER TABLE karyawan ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Owner can select own karyawan" ON karyawan;
CREATE POLICY "Owner can select own karyawan"
  ON karyawan FOR SELECT
  USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "Owner can insert own karyawan" ON karyawan;
CREATE POLICY "Owner can insert own karyawan"
  ON karyawan FOR INSERT
  WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "Owner can update own karyawan" ON karyawan;
CREATE POLICY "Owner can update own karyawan"
  ON karyawan FOR UPDATE
  USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "Owner can delete own karyawan" ON karyawan;
CREATE POLICY "Owner can delete own karyawan"
  ON karyawan FOR DELETE
  USING (owner_id = auth.uid());

-- ============================================================
-- 2. CATEGORIES (Kategori Produk)
-- Relasi: categories.owner_id → auth.users.id
-- ============================================================
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(owner_id, name)
);

CREATE INDEX IF NOT EXISTS idx_categories_owner_id ON categories(owner_id);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Seed default categories
INSERT INTO categories (owner_id, name, description)
SELECT id, 'Umum', 'Kategori umum'
FROM auth.users
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Umum' AND owner_id = auth.users.id);

-- ============================================================
-- 3. PRODUK (Products / Inventory)
-- Relasi: produk.owner_id → auth.users.id
--         produk.category_id → categories.id
-- ============================================================
CREATE TABLE IF NOT EXISTS produk (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'Umum',
  purchase_price DOUBLE PRECISION NOT NULL DEFAULT 0,
  selling_price DOUBLE PRECISION NOT NULL DEFAULT 0,
  stock INTEGER NOT NULL DEFAULT 0,
  unit TEXT NOT NULL DEFAULT 'pcs',
  barcode TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT stock_non_negative CHECK (stock >= 0),
  CONSTRAINT price_non_negative CHECK (purchase_price >= 0 AND selling_price >= 0)
);

CREATE INDEX IF NOT EXISTS idx_produk_owner_id ON produk(owner_id);
CREATE INDEX IF NOT EXISTS idx_produk_category_id ON produk(category_id);
CREATE INDEX IF NOT EXISTS idx_produk_barcode ON produk(barcode);
CREATE INDEX IF NOT EXISTS idx_produk_name_trgm ON produk USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_produk_active ON produk(owner_id, is_active);

ALTER TABLE produk ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 4. TRANSACTIONS (Header Penjualan)
-- Relasi: transactions.owner_id → auth.users.id
--         transactions.karyawan_id → karyawan.id
-- ============================================================
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  karyawan_id UUID REFERENCES karyawan(id) ON DELETE SET NULL,
  transaction_number TEXT NOT NULL,
  customer_name TEXT,
  customer_phone TEXT,
  subtotal DOUBLE PRECISION NOT NULL DEFAULT 0,
  discount DOUBLE PRECISION NOT NULL DEFAULT 0,
  tax DOUBLE PRECISION NOT NULL DEFAULT 0,
  total DOUBLE PRECISION NOT NULL DEFAULT 0,
  payment_method TEXT NOT NULL DEFAULT 'cash',
  payment_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
  change_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
  notes TEXT,
  status TEXT NOT NULL DEFAULT 'completed',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT valid_total CHECK (total >= 0),
  CONSTRAINT valid_payment CHECK (payment_amount >= total)
);

CREATE INDEX IF NOT EXISTS idx_transactions_owner_id ON transactions(owner_id);
CREATE INDEX IF NOT EXISTS idx_transactions_karyawan_id ON transactions(karyawan_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(owner_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(created_at);

ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Owner can select own transactions" ON transactions;
CREATE POLICY "Owner can select own transactions"
  ON transactions FOR SELECT
  USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "Owner can insert own transactions" ON transactions;
CREATE POLICY "Owner can insert own transactions"
  ON transactions FOR INSERT
  WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "Owner can update own transactions" ON transactions;
CREATE POLICY "Owner can update own transactions"
  ON transactions FOR UPDATE
  USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "Owner can delete own transactions" ON transactions;
CREATE POLICY "Owner can delete own transactions"
  ON transactions FOR DELETE
  USING (owner_id = auth.uid());

-- ============================================================
-- 5. TRANSACTION ITEMS (Detail Baris Penjualan)
-- Relasi: transaction_items.transaction_id → transactions.id
--         transaction_items.produk_id → produk.id
-- ============================================================
CREATE TABLE IF NOT EXISTS transaction_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  produk_id UUID REFERENCES produk(id) ON DELETE SET NULL,
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price DOUBLE PRECISION NOT NULL DEFAULT 0,
  discount DOUBLE PRECISION NOT NULL DEFAULT 0,
  subtotal DOUBLE PRECISION NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT quantity_positive CHECK (quantity > 0)
);

CREATE INDEX IF NOT EXISTS idx_transaction_items_transaction_id ON transaction_items(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_items_produk_id ON transaction_items(produk_id);

ALTER TABLE transaction_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Owner can select own transaction_items" ON transaction_items;
CREATE POLICY "Owner can select own transaction_items"
  ON transaction_items FOR SELECT
  USING (
    transaction_id IN (SELECT id FROM transactions WHERE owner_id = auth.uid())
  );

DROP POLICY IF EXISTS "Owner can insert own transaction_items" ON transaction_items;
CREATE POLICY "Owner can insert own transaction_items"
  ON transaction_items FOR INSERT
  WITH CHECK (
    transaction_id IN (SELECT id FROM transactions WHERE owner_id = auth.uid())
  );

DROP POLICY IF EXISTS "Owner can update own transaction_items" ON transaction_items;
CREATE POLICY "Owner can update own transaction_items"
  ON transaction_items FOR UPDATE
  USING (
    transaction_id IN (SELECT id FROM transactions WHERE owner_id = auth.uid())
  );

DROP POLICY IF EXISTS "Owner can delete own transaction_items" ON transaction_items;
CREATE POLICY "Owner can delete own transaction_items"
  ON transaction_items FOR DELETE
  USING (
    transaction_id IN (SELECT id FROM transactions WHERE owner_id = auth.uid())
  );

-- ============================================================
-- FUNCTIONS (RPC)
-- ============================================================

-- 5a. Generate nomor transaksi otomatis
-- Format: INV-YYYYMMDD-XXXX
DROP FUNCTION IF EXISTS generate_transaction_number();
CREATE OR REPLACE FUNCTION generate_transaction_number()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  today_date TEXT;
  next_seq INTEGER;
  lock_key BIGINT;
BEGIN
  today_date := TO_CHAR(NOW(), 'YYYYMMDD');
  lock_key := hashtext('trx_number_' || today_date)::bigint;

  PERFORM pg_advisory_xact_lock(lock_key);

  SELECT COALESCE(MAX(SPLIT_PART(transaction_number, '-', 3)::INTEGER), 0) + 1
  INTO next_seq
  FROM transactions
  WHERE transaction_number LIKE 'INV-' || today_date || '-%';

  RETURN 'INV-' || today_date || '-' || LPAD(next_seq::TEXT, 4, '0');
END;
$$;

-- 5b. Create karyawan (dipanggil dari Flutter saat Owner menambah karyawan)
DROP FUNCTION IF EXISTS create_karyawan(TEXT, TEXT, TEXT);
CREATE OR REPLACE FUNCTION create_karyawan(
  p_full_name TEXT,
  p_email TEXT,
  p_password TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO karyawan (owner_id, full_name, email, password_hash)
  VALUES (auth.uid(), p_full_name, p_email, crypt(p_password, gen_salt('bf')))
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

-- 5c. Verify karyawan login (dipanggil dari Flutter saat Karyawan login)
DROP FUNCTION IF EXISTS verify_karyawan_login(TEXT, TEXT);
CREATE OR REPLACE FUNCTION verify_karyawan_login(
  p_email TEXT,
  p_password TEXT
)
RETURNS TABLE (
  id UUID,
  email TEXT,
  full_name TEXT,
  owner_id UUID,
  is_active BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT k.id, k.email, k.full_name, k.owner_id, k.is_active
  FROM karyawan k
  WHERE k.email = p_email
    AND k.password_hash = crypt(p_password, k.password_hash)
    AND k.is_active = true;
END;
$$;

-- 5d. Get dashboard stats (total sales hari ini, jumlah transaksi, dll)
DROP FUNCTION IF EXISTS get_dashboard_stats();
CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS TABLE (
  total_sales DOUBLE PRECISION,
  sales_growth DOUBLE PRECISION,
  total_transactions BIGINT,
  transactions_growth DOUBLE PRECISION,
  avg_ticket_size DOUBLE PRECISION,
  ticket_size_growth DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  today_sales DOUBLE PRECISION;
  yesterday_sales DOUBLE PRECISION;
  today_count BIGINT;
  yesterday_count BIGINT;
  today_avg DOUBLE PRECISION;
  yesterday_avg DOUBLE PRECISION;
BEGIN
  -- Today
  SELECT COALESCE(SUM(total), 0), COUNT(*), COALESCE(AVG(total), 0)
  INTO today_sales, today_count, today_avg
  FROM transactions
  WHERE owner_id = auth.uid()
    AND created_at::DATE = CURRENT_DATE
    AND status = 'completed';

  -- Yesterday
  SELECT COALESCE(SUM(total), 0), COUNT(*), COALESCE(AVG(total), 0)
  INTO yesterday_sales, yesterday_count, yesterday_avg
  FROM transactions
  WHERE owner_id = auth.uid()
    AND created_at::DATE = CURRENT_DATE - INTERVAL '1 day'
    AND status = 'completed';

  RETURN QUERY
  SELECT
    today_sales,
    CASE WHEN yesterday_sales > 0 THEN ((today_sales - yesterday_sales) / yesterday_sales * 100) ELSE 0 END,
    today_count,
    CASE WHEN yesterday_count > 0 THEN ((today_count - yesterday_count)::DOUBLE PRECISION / yesterday_count * 100) ELSE 0 END,
    today_avg,
    CASE WHEN yesterday_avg > 0 THEN ((today_avg - yesterday_avg) / yesterday_avg * 100) ELSE 0 END;
END;
$$;

-- ============================================================
-- TRIGGERS
-- ============================================================

-- 6. Auto-update updated_at column
DROP FUNCTION IF EXISTS update_updated_at_column();
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Apply to tables with updated_at
DROP TRIGGER IF EXISTS trg_update_karyawan_updated_at ON karyawan;
CREATE TRIGGER trg_update_karyawan_updated_at
  BEFORE UPDATE ON karyawan
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_update_categories_updated_at ON categories;
CREATE TRIGGER trg_update_categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_update_produk_updated_at ON produk;
CREATE TRIGGER trg_update_produk_updated_at
  BEFORE UPDATE ON produk
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_update_transactions_updated_at ON transactions;
CREATE TRIGGER trg_update_transactions_updated_at
  BEFORE UPDATE ON transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_update_transaction_items_updated_at ON transaction_items;
CREATE TRIGGER trg_update_transaction_items_updated_at
  BEFORE UPDATE ON transaction_items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 6a. Auto-set transaction_number sebelum insert
DROP FUNCTION IF EXISTS set_transaction_number();
CREATE OR REPLACE FUNCTION set_transaction_number()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.transaction_number IS NULL THEN
    NEW.transaction_number := generate_transaction_number();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_transaction_number ON transactions;
CREATE TRIGGER trg_set_transaction_number
  BEFORE INSERT ON transactions
  FOR EACH ROW
  EXECUTE FUNCTION set_transaction_number();

-- 6b. Auto-update stok produk setelah insert transaction_items
DROP FUNCTION IF EXISTS update_stock_on_sale();
CREATE OR REPLACE FUNCTION update_stock_on_sale()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_current_stock INTEGER;
  v_product_name TEXT;
BEGIN
  SELECT stock, name INTO v_current_stock, v_product_name
  FROM produk
  WHERE id = NEW.produk_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Produk dengan ID % tidak ditemukan', NEW.produk_id;
  END IF;

  IF v_current_stock < NEW.quantity THEN
    RAISE EXCEPTION 'Stok produk % tidak mencukupi (sisa: %, diminta: %)',
      v_product_name, v_current_stock, NEW.quantity;
  END IF;

  UPDATE produk
  SET stock = stock - NEW.quantity,
      updated_at = NOW()
  WHERE id = NEW.produk_id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_update_stock_on_sale ON transaction_items;
CREATE TRIGGER trg_update_stock_on_sale
  AFTER INSERT ON transaction_items
  FOR EACH ROW
  EXECUTE FUNCTION update_stock_on_sale();

-- ============================================================
-- SAMPLE DATA (Testing)
-- ============================================================
-- INSERT INTO categories (owner_id, name, description) VALUES
--   ('<OWNER_UUID>', 'Makanan', 'Makanan ringan & berat'),
--   ('<OWNER_UUID>', 'Minuman', 'Minuman kemasan & segar'),
--   ('<OWNER_UUID>', 'Snack', 'Camilan & kudapan'),
--   ('<OWNER_UUID>', 'Sembako', 'Sembilan bahan pokok'),
--   ('<OWNER_UUID>', 'ATK', 'Alat tulis kantor'),
--   ('<OWNER_UUID>', 'Layanan Jasa', 'Jasa service & lainnya');
--
-- INSERT INTO produk (owner_id, category_id, name, purchase_price, selling_price, stock, unit, barcode)
-- SELECT
--   '<OWNER_UUID>',
--   id,
--   'Indomie Goreng',
--   2500, 3500, 100, 'pcs', '8991002101234'
-- FROM categories WHERE name = 'Makanan' AND owner_id = '<OWNER_UUID>';

-- ============================================================
-- STORAGE & ADDITIONAL COLUMNS
-- ============================================================

-- Tambahkan kolom image_url pada tabel produk
ALTER TABLE produk ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Buat bucket Storage 'produk_images' (Jika error karna sudah ada, abaikan)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('produk_images', 'produk_images', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- ROW LEVEL SECURITY (Tables)
-- ============================================================

-- Aktifkan RLS pada tabel utama
ALTER TABLE produk ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Policy untuk Tabel Produk
-- SELECT: semua bisa lihat (Owner & Karyawan)
-- UPDATE: authenticated/anon bisa edit stok (Owner & Karyawan)
-- INSERT/DELETE: authenticated only (Owner saja)
DROP POLICY IF EXISTS "Users can select products" ON produk;
CREATE POLICY "Users can select products" ON produk
FOR SELECT USING (auth.role() IN ('authenticated', 'anon'));

DROP POLICY IF EXISTS "Users can update products" ON produk;
CREATE POLICY "Users can update products" ON produk
FOR UPDATE USING (auth.role() IN ('authenticated', 'anon'));

DROP POLICY IF EXISTS "Owner can insert products" ON produk;
CREATE POLICY "Owner can insert products" ON produk
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Owner can delete products" ON produk;
CREATE POLICY "Owner can delete products" ON produk
FOR DELETE USING (auth.role() = 'authenticated');

-- Policy untuk Tabel Kategori (sama: Owner only insert/delete)
DROP POLICY IF EXISTS "Users can select categories" ON categories;
CREATE POLICY "Users can select categories" ON categories
FOR SELECT USING (auth.role() IN ('authenticated', 'anon'));

DROP POLICY IF EXISTS "Users can update categories" ON categories;
CREATE POLICY "Users can update categories" ON categories
FOR UPDATE USING (auth.role() IN ('authenticated', 'anon'));

DROP POLICY IF EXISTS "Owner can insert categories" ON categories;
CREATE POLICY "Owner can insert categories" ON categories
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Owner can delete categories" ON categories;
CREATE POLICY "Owner can delete categories" ON categories
FOR DELETE USING (auth.role() = 'authenticated');

-- ============================================================
-- STORAGE ACCESS (produk_images)
-- ============================================================

-- SELECT: semua bisa lihat gambar (Owner & Karyawan)
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
CREATE POLICY "Public Access"
  ON storage.objects FOR SELECT
  USING ( bucket_id = 'produk_images' );

-- INSERT: authenticated only (Owner saja)
DROP POLICY IF EXISTS "Owner Upload" ON storage.objects;
CREATE POLICY "Owner Upload"
  ON storage.objects FOR INSERT
  WITH CHECK ( bucket_id = 'produk_images' AND auth.role() = 'authenticated' );

-- UPDATE: authenticated only (Owner saja)
DROP POLICY IF EXISTS "Owner Update" ON storage.objects;
CREATE POLICY "Owner Update"
  ON storage.objects FOR UPDATE
  USING ( bucket_id = 'produk_images' AND auth.role() = 'authenticated' );

-- DELETE: authenticated only (Owner saja)
DROP POLICY IF EXISTS "Owner Delete" ON storage.objects;
CREATE POLICY "Owner Delete"
  ON storage.objects FOR DELETE
  USING ( bucket_id = 'produk_images' AND auth.role() = 'authenticated' );

-- ============================================================
-- 7. PROFILES (Public Profile for Shop Name)
-- Relasi: profiles.id -> auth.users.id
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  shop_name TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW())
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policies for Profiles
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Profiles are viewable by everyone" ON public.profiles
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- Trigger untuk bikin profil otomatis saat Owner baru daftar
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, shop_name)
  VALUES (new.id, COALESCE(new.raw_user_meta_data->>'shop_name', 'BradPOS'));
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Jalankan trigger ini otomatis setiap ada user baru di auth.users
DROP TRIGGER IF EXISTS trg_on_auth_user_created ON auth.users;
CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
