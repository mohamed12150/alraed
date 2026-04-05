-- Fix Schema (Columns & ID Types) and Update Menu
-- إصلاح الهيكلية (الأعمدة وأنواع المعرفات) وتحديث القائمة

-- 1. Ensure Missing Columns Exist in Products Table
DO $$
BEGIN
    -- Add rating column if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'rating') THEN
        ALTER TABLE public.products ADD COLUMN rating decimal(2, 1) DEFAULT 5.0;
    END IF;

    -- Add review_count column if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'review_count') THEN
        ALTER TABLE public.products ADD COLUMN review_count integer DEFAULT 0;
    END IF;

    -- Add image_url column if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'image_url') THEN
        ALTER TABLE public.products ADD COLUMN image_url text;
    END IF;

    -- Add is_active column if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'is_active') THEN
        ALTER TABLE public.products ADD COLUMN is_active boolean DEFAULT true;
    END IF;
END $$;

-- 2. Fix Categories Table ID Type (Change from Serial/Integer to Text)
-- We need to drop dependent foreign keys first to allow type change
ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_category_id_fkey;
ALTER TABLE public.categories DROP CONSTRAINT IF EXISTS categories_parent_id_fkey;

-- Change id type to text (using USING clause to handle conversion if data existed, though we truncate later)
ALTER TABLE public.categories ALTER COLUMN id TYPE text USING id::text;
ALTER TABLE public.categories ALTER COLUMN parent_id TYPE text USING parent_id::text;

-- Change products.category_id type to text
ALTER TABLE public.products ALTER COLUMN category_id TYPE text USING category_id::text;

-- Re-add Foreign Key
ALTER TABLE public.products ADD CONSTRAINT products_category_id_fkey 
FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;

ALTER TABLE public.categories ADD CONSTRAINT categories_parent_id_fkey 
FOREIGN KEY (parent_id) REFERENCES public.categories(id);


-- 3. Clean up existing data (Now safe with Text IDs)
TRUNCATE TABLE public.products CASCADE;
DELETE FROM public.categories; -- Delete all categories to start fresh

-- 4. Insert New Categories
INSERT INTO public.categories (id, name_ar, name_en, image_url, position)
VALUES 
('camel', 'حاشي', 'Camel', 'assets/images/download (1).jpg', 1),
('veal', 'عجل', 'Veal', 'assets/images/download (2).jpg', 2),
('sheep', 'الأغنام', 'Sheep & Goats', 'assets/images/download (3).jpg', 3),
('minced', 'مفروم وبوكسات', 'Minced & Boxes', 'assets/images/images.jpg', 4)
ON CONFLICT (id) DO UPDATE SET 
name_ar = EXCLUDED.name_ar,
name_en = EXCLUDED.name_en;

-- 5. Insert Products

-- === Camel (حاشي) ===
INSERT INTO public.products (name_ar, name_en, description_ar, category_id, price, image_url, rating, review_count, is_active) VALUES
('حاشي كامل (75 كيلو)', 'Whole Camel (75kg)', 'حاشي بلدي كامل وزن 75 كيلو تقريباً', 'camel', 3500.00, 'assets/images/download (1).jpg', 5.0, 10, true),
('نصف حاشي (35 كيلو)', 'Half Camel (35kg)', 'نصف حاشي بلدي وزن 35 كيلو تقريباً', 'camel', 1800.00, 'assets/images/download (1).jpg', 4.9, 8, true),
('ربع حاشي (18 كيلو)', 'Quarter Camel (18kg)', 'ربع حاشي بلدي وزن 18 كيلو تقريباً', 'camel', 950.00, 'assets/images/download (1).jpg', 4.8, 15, true),
('حاشي بالكيلو', 'Camel Meat per Kg', 'لحم حاشي طازج بالكيلو', 'camel', 55.00, 'assets/images/download (1).jpg', 4.7, 50, true),
('كبدة حاشي بالكيلو', 'Camel Liver per Kg', 'كبدة حاشي طازجة بالكيلو', 'camel', 60.00, 'assets/images/download (1).jpg', 4.9, 20, true),
('عرض خاص: 5 كيلو مفروم حاشي بلدي', 'Special: 5kg Minced Camel', 'عرض التوفير: 5 كيلو مفروم حاشي بلدي طازج', 'camel', 220.00, 'assets/images/download (1).jpg', 5.0, 25, true);

-- === Veal (عجل) ===
INSERT INTO public.products (name_ar, name_en, description_ar, category_id, price, image_url, rating, review_count, is_active) VALUES
('عجل بلدي كامل (80 كيلو)', 'Whole Baladi Veal (80kg)', 'عجل بلدي كامل وزن 80 كيلو تقريباً', 'veal', 4200.00, 'assets/images/download (2).jpg', 5.0, 5, true),
('نصف عجل بلدي (40 كيلو)', 'Half Baladi Veal (40kg)', 'نصف عجل بلدي وزن 40 كيلو تقريباً', 'veal', 2150.00, 'assets/images/download (2).jpg', 4.9, 7, true),
('ربع عجل بلدي (20 كيلو)', 'Quarter Baladi Veal (20kg)', 'ربع عجل بلدي وزن 20 كيلو تقريباً', 'veal', 1100.00, 'assets/images/download (2).jpg', 4.8, 12, true),
('كيلو عجل (بدون عظم)', 'Boneless Veal Kilo', 'لحم عجل صافي بدون عظم', 'veal', 75.00, 'assets/images/download (2).jpg', 4.9, 40, true),
('مفروم عجل بالكيلو', 'Minced Veal per Kg', 'مفروم عجل طازج بالكيلو', 'veal', 65.00, 'assets/images/download (2).jpg', 4.7, 30, true),
('بوكس مفروم عجل (5 كيلو)', 'Minced Veal Box (5kg)', 'بوكس مفروم عجل اقتصادي 5 كيلو', 'veal', 300.00, 'assets/images/download (2).jpg', 4.9, 18, true),
('بوكس مفروم عجل (10 كيلو)', 'Minced Veal Box (10kg)', 'بوكس مفروم عجل عائلي 10 كيلو', 'veal', 580.00, 'assets/images/download (2).jpg', 5.0, 10, true);

-- === Sheep & Goats (الأغنام) ===
INSERT INTO public.products (name_ar, name_en, description_ar, category_id, price, image_url, rating, review_count, is_active) VALUES
-- Harri (حري)
('خروف حري جذع (22-24 كيلو)', 'Harri Jatha (22-24kg)', 'خروف حري جذع وزن 22-24 كيلو', 'sheep', 1650.00, 'assets/images/download (3).jpg', 4.9, 100, true),
('نصف خروف حري وسط', 'Half Harri Medium', 'نصف خروف حري وسط', 'sheep', 850.00, 'assets/images/download (3).jpg', 4.8, 45, true),
('ربع ذبيحة حري وسط', 'Quarter Harri Medium', 'ربع ذبيحة حري وسط', 'sheep', 450.00, 'assets/images/download (3).jpg', 4.7, 30, true),
('خروف حري لباني (10-12 كيلو)', 'Harri Labani (10-12kg)', 'خروف حري لباني صغير وزن 10-12 كيلو', 'sheep', 1350.00, 'assets/images/download (3).jpg', 5.0, 60, true),
('نصف خروف حري لباني', 'Half Harri Labani', 'نصف خروف حري لباني', 'sheep', 700.00, 'assets/images/download (3).jpg', 4.9, 25, true),
('حري هرفي وسط (16 كيلو)', 'Harri Harfi Medium (16kg)', 'حري هرفي وسط وزن 16 كيلو', 'sheep', 1450.00, 'assets/images/download (3).jpg', 4.8, 40, true),
('حري بلدي جبر (25-27 كيلو)', 'Harri Baladi Jabar (25-27kg)', 'حري بلدي جبر وزن كبير 25-27 كيلو', 'sheep', 1800.00, 'assets/images/download (3).jpg', 5.0, 35, true),
('عقيقة حري طائفي (20 كيلو+)', 'Aqiqah Harri Taifi (20kg+)', 'عقيقة حري طائفي وافي الشروط وزن 20 كيلو واكثر', 'sheep', 1700.00, 'assets/images/download (3).jpg', 5.0, 15, true),

-- Naimi (نعيمي)
('نعيمي بلدي جذع وسط', 'Naimi Baladi Jatha Medium', 'نعيمي بلدي جذع وسط', 'sheep', 1750.00, 'assets/images/download (1).jpg', 4.9, 80, true),
('نصف جذع نعيمي وسط', 'Half Naimi Jatha Medium', 'نصف جذع نعيمي وسط', 'sheep', 900.00, 'assets/images/download (1).jpg', 4.8, 35, true),
('نعيمي هرفي لباني (12 كيلو)', 'Naimi Harfi Labani (12kg)', 'نعيمي هرفي لباني وزن 12 كيلو', 'sheep', 1400.00, 'assets/images/download (1).jpg', 5.0, 50, true),
('نصف نعيمي لباني', 'Half Naimi Labani', 'نصف نعيمي لباني', 'sheep', 720.00, 'assets/images/download (1).jpg', 4.9, 20, true),
('نعيمي صغير طيب (17 كيلو)', 'Naimi Small Good (17kg)', 'نعيمي صغير طيب وزن 17 كيلو', 'sheep', 1500.00, 'assets/images/download (1).jpg', 4.8, 30, true),
('نعيمي بلدي جذع وسط (22 كيلو) وافي', 'Naimi Baladi Jatha (22kg) Wafi', 'نعيمي بلدي جذع وسط وزن 22 كيلو وافي الشروط', 'sheep', 1800.00, 'assets/images/download (1).jpg', 5.0, 20, true),

-- Swakni (سواكني)
('سواكني حمري جذع (22-24 كيلو)', 'Swakni Hamri Jatha (22-24kg)', 'سواكني حمري جذع وزن 22-24 كيلو', 'sheep', 1100.00, 'assets/images/images (1).jpg', 4.7, 55, true),
('نصف سواكني حمري', 'Half Swakni Hamri', 'نصف سواكني حمري', 'sheep', 580.00, 'assets/images/images (1).jpg', 4.6, 25, true),
('خروف سواكني مرابي (20 كيلو)', 'Swakni Marabi (20kg)', 'خروف سواكني مرابي وزن بعد الذبح 20 كيلو', 'sheep', 1050.00, 'assets/images/images (1).jpg', 4.7, 40, true),
('سواكني جذع مرابي (24 كيلو) وافي', 'Swakni Jatha Marabi (24kg) Wafi', 'سواكني جذع مرابي وزن 24 كيلو وافي الشروط', 'sheep', 1200.00, 'assets/images/images (1).jpg', 4.8, 15, true),

-- Goats (تيس)
('تيس بلدي (12 كيلو)', 'Baladi Goat (12kg)', 'تيس بلدي وزن بعد الذبح 12 كيلو', 'sheep', 1100.00, 'assets/images/images.jpg', 4.8, 30, true),
('نصف تيس', 'Half Goat', 'نصف تيس بلدي', 'sheep', 600.00, 'assets/images/images.jpg', 4.7, 15, true),

-- Other
('كبدة غنم كاملة', 'Whole Sheep Liver', 'كبدة غنم طازجة كاملة', 'sheep', 45.00, 'assets/images/download (3).jpg', 4.9, 50, true),
('بوكس التوفير مفروم غنم (5 كيلو)', 'Savings Box: Minced Sheep (5kg)', 'بوكس التوفير مفروم غنم 5 كيلو', 'sheep', 250.00, 'assets/images/images (1).jpg', 4.9, 40, true);
