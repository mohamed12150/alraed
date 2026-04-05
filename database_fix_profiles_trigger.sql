-- Fix Profiles Trigger and Backfill
-- إصلاح التلقائي للملف الشخصي وتعبئة البيانات المفقودة

-- 1. Ensure 'email' column exists in profiles (Useful for lookups)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'email') THEN
        ALTER TABLE public.profiles ADD COLUMN email text;
    END IF;
END $$;

-- 2. Create/Update Function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, phone, role)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.email,
    NEW.phone,
    'customer'
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name),
    email = COALESCE(EXCLUDED.email, public.profiles.email),
    phone = COALESCE(EXCLUDED.phone, public.profiles.phone);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create Trigger (Drop first to avoid duplicates)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. Backfill missing profiles for existing users
-- تعبئة الملفات الشخصية للمستخدمين الموجودين مسبقاً
INSERT INTO public.profiles (id, full_name, email, phone, role)
SELECT 
    id, 
    COALESCE(raw_user_meta_data->>'full_name', email), -- Fallback to email as name if full_name is missing
    email,
    phone, 
    'customer'
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.profiles);
