-- Supabase / Postgres schema for Clothes-STORE

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Helpers: update timestamps
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Helper: update tsvector for product search
CREATE OR REPLACE FUNCTION products_tsv_trigger() RETURNS trigger AS $$
BEGIN
  NEW.tsv :=
    to_tsvector('english', coalesce(NEW.name_en,'') || ' ' || coalesce(NEW.description_en,'')) ||
    to_tsvector('simple', coalesce(NEW.name_ar,'') || ' ' || coalesce(NEW.description_ar,''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Profiles (linked to auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id),
  full_name text,
  phone text,
  role text DEFAULT 'customer',
  metadata jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TRIGGER profiles_set_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Categories
CREATE TABLE IF NOT EXISTS categories (
  id serial PRIMARY KEY,
  parent_id int REFERENCES categories(id),
  slug text UNIQUE,
  name_en text,
  name_ar text,
  description_en text,
  description_ar text,
  image_url text,
  position int DEFAULT 0,
  is_active boolean DEFAULT true,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- Products
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sku text UNIQUE,
  category_id int REFERENCES categories(id),
  name_en text NOT NULL,
  name_ar text,
  description_en text,
  description_ar text,
  price numeric(12,2) NOT NULL,
  sale_price numeric(12,2),
  currency text DEFAULT 'SAR',
  unit text,
  weight numeric,
  stock integer DEFAULT 0,
  status text DEFAULT 'active',
  attributes jsonb,
  metadata jsonb,
  tsv tsvector,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TRIGGER products_set_updated_at
BEFORE UPDATE ON products
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER products_tsv_update
BEFORE INSERT OR UPDATE ON products
FOR EACH ROW EXECUTE FUNCTION products_tsv_trigger();

CREATE INDEX IF NOT EXISTS idx_products_tsv ON products USING GIN(tsv);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);

-- Product images
CREATE TABLE IF NOT EXISTS product_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid REFERENCES products(id) ON DELETE CASCADE,
  url text NOT NULL,
  position int DEFAULT 0,
  is_primary boolean DEFAULT false,
  metadata jsonb
);

-- Product variants
CREATE TABLE IF NOT EXISTS product_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid REFERENCES products(id) ON DELETE CASCADE,
  sku text,
  attributes jsonb,
  price numeric(12,2),
  stock integer DEFAULT 0,
  metadata jsonb
);

-- Cutting methods
CREATE TABLE IF NOT EXISTS cutting_methods (
  id serial PRIMARY KEY,
  name_en text NOT NULL,
  name_ar text,
  description text,
  position int DEFAULT 0,
  metadata jsonb
);

CREATE TABLE IF NOT EXISTS product_cutting_methods (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid REFERENCES products(id) ON DELETE CASCADE,
  cutting_method_id int REFERENCES cutting_methods(id) ON DELETE CASCADE,
  extra jsonb
);

-- Orders and order items
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id),
  total_amount numeric(12,2) NOT NULL,
  currency text DEFAULT 'SAR',
  status text DEFAULT 'pending',
  shipping_address jsonb,
  billing_address jsonb,
  payment_method text,
  payment_status text DEFAULT 'unpaid',
  metadata jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TRIGGER orders_set_updated_at
BEFORE UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid REFERENCES orders(id) ON DELETE CASCADE,
  product_id uuid,
  variant_id uuid,
  name_en text,
  name_ar text,
  sku text,
  qty integer NOT NULL,
  unit_price numeric(12,2) NOT NULL,
  subtotal numeric(12,2) NOT NULL,
  metadata jsonb
);

-- Carts
CREATE TABLE IF NOT EXISTS carts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES profiles(id),
  metadata jsonb,
  updated_at timestamptz DEFAULT now()
);

CREATE TRIGGER carts_set_updated_at
BEFORE UPDATE ON carts
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE IF NOT EXISTS cart_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cart_id uuid REFERENCES carts(id) ON DELETE CASCADE,
  product_id uuid,
  variant_id uuid,
  qty integer DEFAULT 1,
  added_at timestamptz DEFAULT now()
);

-- Indexes for orders and users
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);

-- Row Level Security (RLS) flags (enable/adjust policies separately)
-- The following tables should have RLS enabled in Supabase according to your request:
-- profiles, categories, products, orders, order_items, carts, cart_items
-- The following tables should NOT have RLS enabled: product_images, product_variants, cutting_methods, product_cutting_methods

-- End of schema
