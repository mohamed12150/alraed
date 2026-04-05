-- Migration for Products Table (Updated with Old Price)
-- تحديث جدول المنتجات ليشمل السعر القديم والجديد

-- 1. Create or Update Products Table
CREATE TABLE IF NOT EXISTS public.products (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Add columns safely using DO block
DO $$
BEGIN
    -- Product Name (Arabic & English)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'name_ar') THEN
        ALTER TABLE public.products ADD COLUMN name_ar text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'name_en') THEN
        ALTER TABLE public.products ADD COLUMN name_en text;
    END IF;

    -- Description
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'description_ar') THEN
        ALTER TABLE public.products ADD COLUMN description_ar text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'description_en') THEN
        ALTER TABLE public.products ADD COLUMN description_en text;
    END IF;

    -- Prices (New Price & Old Price)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'price') THEN
        ALTER TABLE public.products ADD COLUMN price decimal(10, 2) DEFAULT 0; -- السعر الحالي (الجديد)
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'old_price') THEN
        ALTER TABLE public.products ADD COLUMN old_price decimal(10, 2); -- السعر القديم (قبل الخصم)
    END IF;

    -- Image (Uploaded from device -> Stored in Storage -> URL saved here)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'image_url') THEN
        ALTER TABLE public.products ADD COLUMN image_url text;
    END IF;

    -- Category Link
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'category_id') THEN
        ALTER TABLE public.products ADD COLUMN category_id uuid REFERENCES public.categories(id) ON DELETE SET NULL;
    END IF;
    
    -- Active Status
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'is_active') THEN
        ALTER TABLE public.products ADD COLUMN is_active boolean DEFAULT true;
    END IF;
END $$;

-- 2. Create Storage Bucket for Product Images (SQL for Supabase Storage)
-- Note: Usually buckets are created via Dashboard, but we can insert into storage.buckets if permissions allow.
-- This part inserts a 'products' bucket if it doesn't exist.
INSERT INTO storage.buckets (id, name, public)
VALUES ('products', 'products', true)
ON CONFLICT (id) DO NOTHING;

-- Policy to allow public access to view images
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'products' );

-- Policy to allow authenticated users to upload images
CREATE POLICY "Auth Users Upload"
ON storage.objects FOR INSERT
WITH CHECK ( bucket_id = 'products' AND auth.role() = 'authenticated' );

-- 3. Enable RLS on Products
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Public can view products" ON public.products;
CREATE POLICY "Public can view products" ON public.products FOR SELECT USING (true);

-- Allow admins/editors to update (For now, we'll allow auth users for simplicity, or you can restrict to specific IDs)
DROP POLICY IF EXISTS "Auth users can update products" ON public.products;
CREATE POLICY "Auth users can update products" ON public.products FOR UPDATE USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Auth users can insert products" ON public.products;
CREATE POLICY "Auth users can insert products" ON public.products FOR INSERT WITH CHECK (auth.role() = 'authenticated');
