-- Migration for Products and related tables
-- تحديث جداول المنتجات والتصنيفات

-- 1. Categories Table
CREATE TABLE IF NOT EXISTS public.categories (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name_ar text NOT NULL,
    name_en text,
    image_url text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Cutting Methods Table (Global list of methods)
CREATE TABLE IF NOT EXISTS public.cutting_methods (
    id SERIAL PRIMARY KEY, -- Using Serial for simple ID or could be UUID
    name_ar text NOT NULL,
    name_en text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Products Table
CREATE TABLE IF NOT EXISTS public.products (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    category_id uuid REFERENCES public.categories(id) ON DELETE SET NULL,
    
    name_ar text NOT NULL,
    name_en text,
    description_ar text,
    description_en text,
    
    price decimal(10, 2) NOT NULL DEFAULT 0,
    image_url text, -- Main image
    
    -- Optional: helper columns for filtering/display without joins
    weights text[], -- Array of available weights e.g. ['1kg', '5kg']
    is_active boolean DEFAULT true,
    
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Product Variants Table (Specific weights/sizes with price overrides)
CREATE TABLE IF NOT EXISTS public.product_variants (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id uuid REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
    
    price decimal(10, 2) NOT NULL, -- Price for this specific variant
    
    -- Structured attributes (weight, size, etc.)
    attributes jsonb NOT NULL, -- e.g. {"weight": "1kg", "serves": "2-3"}
    
    stock integer DEFAULT 100,
    
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. Product Images Table (Gallery)
CREATE TABLE IF NOT EXISTS public.product_images (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id uuid REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
    url text NOT NULL,
    display_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. Product <-> Cutting Methods (Many-to-Many)
CREATE TABLE IF NOT EXISTS public.product_cutting_methods (
    product_id uuid REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
    cutting_method_id integer REFERENCES public.cutting_methods(id) ON DELETE CASCADE NOT NULL,
    PRIMARY KEY (product_id, cutting_method_id)
);

-- Enable RLS
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cutting_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_cutting_methods ENABLE ROW LEVEL SECURITY;

-- Public Read Policies
DROP POLICY IF EXISTS "Public can view categories" ON public.categories;
CREATE POLICY "Public can view categories" ON public.categories FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can view cutting_methods" ON public.cutting_methods;
CREATE POLICY "Public can view cutting_methods" ON public.cutting_methods FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can view products" ON public.products;
CREATE POLICY "Public can view products" ON public.products FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can view product_variants" ON public.product_variants;
CREATE POLICY "Public can view product_variants" ON public.product_variants FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can view product_images" ON public.product_images;
CREATE POLICY "Public can view product_images" ON public.product_images FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can view product_cutting_methods" ON public.product_cutting_methods;
CREATE POLICY "Public can view product_cutting_methods" ON public.product_cutting_methods FOR SELECT USING (true);
