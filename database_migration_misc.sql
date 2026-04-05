-- Migration for Banners and App Settings
-- تحديث جداول الإعلانات وإعدادات التطبيق

-- 1. Banners Table (Sliders)
CREATE TABLE IF NOT EXISTS public.banners (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    image_url text NOT NULL,
    title_ar text,
    title_en text,
    link text, -- Deep link or external link (optional)
    is_active boolean DEFAULT true,
    display_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. App Settings Table (Global Configurations)
-- This table usually has one row with key-value pairs or specific columns
CREATE TABLE IF NOT EXISTS public.app_settings (
    id integer PRIMARY KEY DEFAULT 1, -- Single row enforcement
    delivery_fee decimal(10, 2) DEFAULT 0,
    tax_percentage decimal(5, 2) DEFAULT 15.0,
    
    -- Contact Info
    contact_phone text,
    whatsapp_number text,
    support_email text,
    
    -- Social Media Links
    instagram_url text,
    twitter_url text,
    snapchat_url text,
    
    -- App Status
    is_app_active boolean DEFAULT true,
    maintenance_message_ar text,
    maintenance_message_en text,
    
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- Constraint to ensure only one row in app_settings
ALTER TABLE public.app_settings ADD CONSTRAINT app_settings_single_row CHECK (id = 1);

-- Insert default settings row if not exists
INSERT INTO public.app_settings (id, delivery_fee, tax_percentage)
VALUES (1, 15.00, 15.0)
ON CONFLICT (id) DO NOTHING;

-- 3. Storage Bucket for Banners
INSERT INTO storage.buckets (id, name, public)
VALUES ('banners', 'banners', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies for Banners
CREATE POLICY "Public Access Banners"
ON storage.objects FOR SELECT
USING ( bucket_id = 'banners' );

CREATE POLICY "Auth Users Upload Banners"
ON storage.objects FOR INSERT
WITH CHECK ( bucket_id = 'banners' AND auth.role() = 'authenticated' );

-- 4. Enable RLS
ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- 5. Policies
-- Public Read Access
DROP POLICY IF EXISTS "Public can view banners" ON public.banners;
CREATE POLICY "Public can view banners" ON public.banners FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public can view settings" ON public.app_settings;
CREATE POLICY "Public can view settings" ON public.app_settings FOR SELECT USING (true);

-- Admin/Auth Write Access (Simplified to auth for now)
DROP POLICY IF EXISTS "Auth users can manage banners" ON public.banners;
CREATE POLICY "Auth users can manage banners" ON public.banners FOR ALL USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Auth users can manage settings" ON public.app_settings;
CREATE POLICY "Auth users can manage settings" ON public.app_settings FOR ALL USING (auth.role() = 'authenticated');
