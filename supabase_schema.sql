-- BRAD POS SUPABASE SCHEMA (PostgreSQL)
-- ============================================================
-- NOTE FOR MIGRATION TO OTHER DB (MySQL/SQL Server):
-- 1. Change UUID PRIMARY KEY to VARCHAR(36) PRIMARY KEY
-- 2. Change JSONB to JSON or LONGTEXT
-- 3. Change TIMESTAMPTZ to TIMESTAMP or DATETIME
-- 4. Remove EXTENSION and RLS Policies (Postgres specific)
-- ============================================================

-- ============================================================
-- EXTENSIONS (PG-OPTIONAL)
-- ============================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ============================================================
-- 1. PROFILES (Toko / Shop Profile)
-- ============================================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shop_name TEXT,
  full_name TEXT,
  address TEXT,
  phone TEXT,
  remote_image TEXT,
  local_image TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 2. CATEGORIES (Inventory Categories)
-- ============================================================
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_categories_owner_id ON categories(owner_id);

-- ============================================================
-- 3. PRODUK (Products / Inventory)
-- ============================================================
CREATE TABLE IF NOT EXISTS produk (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL,
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'Umum',
  purchase_price DOUBLE PRECISION NOT NULL DEFAULT 0,
  selling_price DOUBLE PRECISION NOT NULL DEFAULT 0,
  stock INTEGER NOT NULL DEFAULT 0,
  unit TEXT NOT NULL DEFAULT 'pcs',
  barcode TEXT,
  image_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT stock_non_negative CHECK (stock >= -1),
  CONSTRAINT price_non_negative CHECK (purchase_price >= 0 AND selling_price >= 0)
);

CREATE INDEX IF NOT EXISTS idx_produk_owner_id ON produk(owner_id);
CREATE INDEX IF NOT EXISTS idx_produk_category_id ON produk(category_id);
CREATE INDEX IF NOT EXISTS idx_produk_barcode ON produk(barcode);
CREATE INDEX IF NOT EXISTS idx_produk_name_trgm ON produk USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_produk_active ON produk(owner_id, is_active);

-- ============================================================
-- 4. KARYAWAN (Staff)
-- ============================================================
CREATE TABLE IF NOT EXISTS karyawan (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_karyawan_owner_id ON karyawan(owner_id);
CREATE INDEX IF NOT EXISTS idx_karyawan_email ON karyawan(email);

-- ============================================================
-- 5. TRANSACTIONS (Header Penjualan + Items JSON)
-- ============================================================
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL,
  karyawan_id UUID REFERENCES karyawan(id) ON DELETE SET NULL,
  cashier_name TEXT,
  transaction_number TEXT NOT NULL,
  customer_name TEXT,
  customer_phone TEXT,
  items JSONB NOT NULL,
  subtotal DOUBLE PRECISION NOT NULL DEFAULT 0,
  discount DOUBLE PRECISION NOT NULL DEFAULT 0,
  tax DOUBLE PRECISION NOT NULL DEFAULT 0,
  total DOUBLE PRECISION NOT NULL DEFAULT 0,
  payment_method TEXT NOT NULL,
  payment_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
  change_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
  notes TEXT,
  status TEXT NOT NULL DEFAULT 'completed',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_transactions_owner_id ON transactions(owner_id);
CREATE INDEX IF NOT EXISTS idx_transactions_karyawan_id ON transactions(karyawan_id);
CREATE INDEX IF NOT EXISTS idx_transactions_number ON transactions(transaction_number);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at);

-- ============================================================
-- TRIGGERS
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON profiles;
CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_categories_updated_at ON categories;
CREATE TRIGGER trg_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_produk_updated_at ON produk;
CREATE TRIGGER trg_produk_updated_at BEFORE UPDATE ON produk FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_karyawan_updated_at ON karyawan;
CREATE TRIGGER trg_karyawan_updated_at BEFORE UPDATE ON karyawan FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_transactions_updated_at ON transactions;
CREATE TRIGGER trg_transactions_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE produk ENABLE ROW LEVEL SECURITY;
ALTER TABLE karyawan ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Profiles
DROP POLICY IF EXISTS "Profiles select all" ON profiles;
CREATE POLICY "Profiles select all" ON profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Profiles update own" ON profiles;
CREATE POLICY "Profiles update own" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Categories
DROP POLICY IF EXISTS "Categories owner" ON categories;
CREATE POLICY "Categories owner" ON categories FOR ALL USING (owner_id = auth.uid());

-- Produk
DROP POLICY IF EXISTS "Produk owner" ON produk;
CREATE POLICY "Produk owner" ON produk FOR ALL USING (owner_id = auth.uid());

-- Karyawan
DROP POLICY IF EXISTS "Karyawan owner" ON karyawan;
CREATE POLICY "Karyawan owner" ON karyawan FOR ALL USING (owner_id = auth.uid());

-- Transactions
DROP POLICY IF EXISTS "Transactions owner" ON transactions;
CREATE POLICY "Transactions owner" ON transactions FOR ALL USING (owner_id = auth.uid());

-- ============================================================
-- STORAGE
-- ============================================================
-- 2. STORAGE BUCKETS
INSERT INTO storage.buckets (id, name, public) VALUES ('produk_images', 'produk_images', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('profile_images', 'profile_images', true) ON CONFLICT DO NOTHING;

DROP POLICY IF EXISTS "Public Read Access" ON storage.objects;
CREATE POLICY "Public Read Access" ON storage.objects FOR SELECT TO public USING (bucket_id IN ('produk_images', 'profile_images'));

-- 11. INCREMENTAL UPDATE (Run this on existing projects)
DO $$ 
BEGIN
    -- Add columns to profiles if they don't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='full_name') THEN
        ALTER TABLE public.profiles ADD COLUMN full_name TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='remote_image') THEN
        ALTER TABLE public.profiles ADD COLUMN remote_image TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='local_image') THEN
        ALTER TABLE public.profiles ADD COLUMN local_image TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='address') THEN
        ALTER TABLE public.profiles ADD COLUMN address TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='phone') THEN
        ALTER TABLE public.profiles ADD COLUMN phone TEXT;
    END IF;
END $$;

-- Re-apply trigger function to ensure it's the latest version
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, shop_name, full_name, address, phone)
    VALUES (
        new.id, 
        COALESCE(new.raw_user_meta_data->>'shop_name', 'BradPOS'),
        new.raw_user_meta_data->>'full_name',
        new.raw_user_meta_data->>'address',
        new.raw_user_meta_data->>'phone'
    )
    ON CONFLICT (id) DO UPDATE SET
        shop_name = EXCLUDED.shop_name,
        full_name = EXCLUDED.full_name,
        address = EXCLUDED.address,
        phone = EXCLUDED.phone;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP POLICY IF EXISTS "Owner Insert Access" ON storage.objects;
CREATE POLICY "Owner Insert Access" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id IN ('produk_images', 'profile_images'));

DROP POLICY IF EXISTS "Owner Update Access" ON storage.objects;
CREATE POLICY "Owner Update Access" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id IN ('produk_images', 'profile_images'));

DROP POLICY IF EXISTS "Owner Delete Access" ON storage.objects;
CREATE POLICY "Owner Delete Access" ON storage.objects FOR DELETE TO authenticated USING (bucket_id IN ('produk_images', 'profile_images'));

-- ============================================================
-- 12. AUTH TRIGGER (Auto Create Profile)
-- ============================================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
