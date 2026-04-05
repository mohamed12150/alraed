-- Migration: Update Cutting and Packaging Options
-- Description: Adds combined cutting and packaging options for Camel/Veal and Sheep
-- Updated to include specific packaging for Mufattah/Butterfly (Carton/Big Bag) and Hadrami/Joints (Wrapped)

-- 0. Ensure schema is correct (Fix for missing columns and constraints)
DO $$
BEGIN
    -- Add name_ar column if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'cutting_methods' AND column_name = 'name_ar') THEN
        ALTER TABLE public.cutting_methods ADD COLUMN name_ar text;
    END IF;

    -- Add name_en column if not exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'cutting_methods' AND column_name = 'name_en') THEN
        ALTER TABLE public.cutting_methods ADD COLUMN name_en text;
    END IF;

    -- Fix: Drop NOT NULL constraint on 'name' column if it exists (Legacy column causing issues)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'cutting_methods' AND column_name = 'name') THEN
        ALTER TABLE public.cutting_methods ALTER COLUMN name DROP NOT NULL;
    END IF;

    -- Fix: Drop NOT NULL constraint on 'animal_type' column if it exists (Legacy/Unknown column causing issues)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'cutting_methods' AND column_name = 'animal_type') THEN
        ALTER TABLE public.cutting_methods ALTER COLUMN animal_type DROP NOT NULL;
    END IF;
END $$;

-- 1. Clear existing links and methods to ensure a clean slate
TRUNCATE TABLE public.product_cutting_methods CASCADE;
TRUNCATE TABLE public.cutting_methods CASCADE;

-- 2. Insert New Cutting Methods (Combined with Packaging)

-- Camel/Veal Options
INSERT INTO public.cutting_methods (name_ar, name_en) VALUES
('تقطيع ثلاجه كبير (تكيس)', 'Fridge Cut Big (Bagged)'),
('تقطيع ثلاجه كبير (اطباق مغلفه)', 'Fridge Cut Big (Plates)'),
('تقطيع ثلاجه صغير (تكيس)', 'Fridge Cut Small (Bagged)'),
('تقطيع ثلاجه صغير (اطباق مغلفه)', 'Fridge Cut Small (Plates)');

-- Sheep Options
INSERT INTO public.cutting_methods (name_ar, name_en) VALUES
('مفطح (كرتونة)', 'Mufattah (Carton)'),
('مفطح (كيس كبير)', 'Mufattah (Big Bag)'),
('فراشه (كرتونة)', 'Butterfly (Carton)'),
('فراشه (كيس كبير)', 'Butterfly (Big Bag)'),
('حضرمي (تغليف)', 'Hadrami (Wrapped)'),
('مفاصل (تغليف)', 'Joints (Wrapped)');


-- 3. Link Options to Products

-- Link Camel/Veal Options to Camel and Veal Products
INSERT INTO public.product_cutting_methods (product_id, cutting_method_id)
SELECT p.id, cm.id
FROM public.products p
CROSS JOIN public.cutting_methods cm
WHERE 
    (p.category_id IN ('camel', 'veal') OR p.category_id LIKE '%camel%' OR p.category_id LIKE '%veal%')
    AND cm.name_ar IN (
        'تقطيع ثلاجه كبير (تكيس)',
        'تقطيع ثلاجه كبير (اطباق مغلفه)',
        'تقطيع ثلاجه صغير (تكيس)',
        'تقطيع ثلاجه صغير (اطباق مغلفه)'
    );

-- Link Sheep Options to Sheep Products
INSERT INTO public.product_cutting_methods (product_id, cutting_method_id)
SELECT p.id, cm.id
FROM public.products p
CROSS JOIN public.cutting_methods cm
WHERE 
    (p.category_id IN ('sheep') OR p.category_id LIKE '%sheep%')
    AND cm.name_ar IN (
        'مفطح (كرتونة)',
        'مفطح (كيس كبير)',
        'فراشه (كرتونة)',
        'فراشه (كيس كبير)',
        'حضرمي (تغليف)',
        'مفاصل (تغليف)'
    );
