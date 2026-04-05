-- Fix Categories and Products, and Seed Data
-- إصلاح الجداول وإضافة البيانات الأولية

-- 1. Create Categories Table (if not exists, with Text ID)
CREATE TABLE IF NOT EXISTS public.categories (
    id text PRIMARY KEY,
    name_ar text,
    name_en text,
    image_url text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for Categories
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public view categories" ON public.categories;
CREATE POLICY "Public view categories" ON public.categories FOR SELECT USING (true);

-- 2. Update Products Table Structure
DO $$
BEGIN
    -- Fix category_id type to text to match categories.id
    -- We drop the constraint first to avoid errors
    ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_category_id_fkey;
    
    -- Change column type (using cast if necessary)
    ALTER TABLE public.products ALTER COLUMN category_id TYPE text;
    
    -- Re-add Foreign Key
    ALTER TABLE public.products ADD CONSTRAINT products_category_id_fkey 
    FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;

    -- Add missing columns for UI
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'rating') THEN
        ALTER TABLE public.products ADD COLUMN rating decimal(2, 1) DEFAULT 0.0;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'review_count') THEN
        ALTER TABLE public.products ADD COLUMN review_count integer DEFAULT 0;
    END IF;
END $$;

-- 3. Seed Categories
INSERT INTO public.categories (id, name_en, name_ar, image_url)
VALUES 
('occasions', 'Occasions Sacrifices', 'ذبائح المناسبات', 'assets/images/download (1).jpg'),
('kilo_selections', 'Kilo Selections', 'مختارات الكيلو', 'assets/images/download (3).jpg'),
('bbq_boxes', 'BBQ Boxes', 'بوكسات الشواء', 'assets/images/images (1).jpg'),
('feast', 'Aajibak Feast', 'وليمة أعجبك', 'assets/images/1.png'),
('quick_picnic', 'Quick Picnic Box', 'بوكس الكشتة السريعة', 'assets/images/images.jpg')
ON CONFLICT (id) DO UPDATE SET 
name_ar = EXCLUDED.name_ar,
name_en = EXCLUDED.name_en,
image_url = EXCLUDED.image_url;

-- 4. Seed Products
INSERT INTO public.products (name_ar, name_en, description_ar, price, image_url, category_id, rating, review_count, is_active)
VALUES 
('ذبيحة نعيمي كاملة', 'Naimi Whole Sacrifice', 'ذبيحة نعيمي طازجة وكاملة، تربية مزارعنا. تشمل خيارات التقطيع والتغليف حسب الطلب.', 1450.00, 'assets/images/download (1).jpg', 'occasions', 4.9, 156, true),
('ذبيحة حري كاملة', 'Hari Whole Sacrifice', 'ذبيحة حري طازجة، جودة عالية وطعم أصيل. مثالية للمناسبات والولائم.', 1250.00, 'assets/images/download (2).jpg', 'occasions', 4.8, 120, true),
('بوكس الشواء العائلي', 'Family BBQ Box', 'بوكس متكامل للشواء يكفي العائلة. يحتوي على تشكيلة فاخرة من اللحوم المتبلة.', 350.00, 'assets/images/images (1).jpg', 'bbq_boxes', 4.9, 85, true),
('نصف ذبيحة نعيمي', 'Half Naimi Sacrifice', 'نصف ذبيحة نعيمي طازجة.', 750.00, 'assets/images/download (1).jpg', 'occasions', 4.7, 45, true)
ON CONFLICT DO NOTHING;

-- 5. Seed Banners
INSERT INTO public.banners (title_ar, title_en, image_url, link, is_active, display_order)
VALUES 
('لحوم طازجة يومياً', 'Fresh Meat Daily', 'assets/images/download (2).jpg', '/category/occasions', true, 1),
('عروض الشواء لنهاية الأسبوع', 'Weekend BBQ Special', 'assets/images/images (1).jpg', '/category/bbq_boxes', true, 2),
('توصيل مجاني', 'Free Delivery', 'assets/images/images.jpg', '/shipping', true, 3);
