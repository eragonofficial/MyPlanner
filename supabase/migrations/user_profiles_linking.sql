-- Migration: User Profiles & Smart Account Linking (Email/Google <-> Telegram OTP)

-- 1. Phone Number Normalizer (E.164 format, e.g. +998901234567)
CREATE OR REPLACE FUNCTION public.normalize_phone_e164(raw_phone TEXT)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  digits TEXT;
BEGIN
  IF raw_phone IS NULL THEN
    RETURN NULL;
  END IF;

  digits := REGEXP_REPLACE(raw_phone, '[^0-9]', '', 'g');
  IF digits = '' THEN
    RETURN NULL;
  END IF;

  IF LENGTH(digits) = 9 THEN
    RETURN '+998' || digits;
  END IF;

  RETURN '+' || digits;
END;
$$;

-- 2. Extend telegram_otp_codes to carry shared phone number from Bot Contact button
ALTER TABLE public.telegram_otp_codes
  ADD COLUMN IF NOT EXISTS phone_number TEXT;

-- 3. Unified User Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  email TEXT,
  phone_number TEXT UNIQUE,
  telegram_id BIGINT UNIQUE,
  telegram_username TEXT,
  avatar_url TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_profiles_phone_number ON public.profiles (phone_number);
CREATE INDEX IF NOT EXISTS idx_profiles_telegram_id ON public.profiles (telegram_id);

-- 4. Before Insert/Update Trigger to normalize phone_number & set updated_at
CREATE OR REPLACE FUNCTION public.handle_profile_before_write()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.phone_number := public.normalize_phone_e164(NEW.phone_number);
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_normalize_before_write ON public.profiles;
CREATE TRIGGER trg_profiles_normalize_before_write
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_profile_before_write();

-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 6. Automatically create a public.profiles row on new auth.users signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_full_name TEXT;
  v_phone TEXT;
  v_telegram_id BIGINT;
  v_telegram_username TEXT;
  v_avatar TEXT;
BEGIN
  v_full_name := NULLIF(TRIM(COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    ''
  )), '');

  v_phone := public.normalize_phone_e164(COALESCE(
    NULLIF(NEW.phone, ''),
    NEW.raw_user_meta_data->>'phone_number'
  ));

  IF (NEW.raw_user_meta_data->>'telegram_id') ~ '^[0-9]+$' THEN
    v_telegram_id := (NEW.raw_user_meta_data->>'telegram_id')::BIGINT;
  END IF;

  v_telegram_username := NULLIF(TRIM(COALESCE(
    NEW.raw_user_meta_data->>'username',
    NEW.raw_user_meta_data->>'telegram_username',
    ''
  )), '');

  v_avatar := NULLIF(TRIM(COALESCE(
    NEW.raw_user_meta_data->>'avatar_url',
    NEW.raw_user_meta_data->>'picture',
    ''
  )), '');

  INSERT INTO public.profiles (
    id,
    full_name,
    email,
    phone_number,
    telegram_id,
    telegram_username,
    avatar_url
  )
  VALUES (
    NEW.id,
    v_full_name,
    NEW.email,
    v_phone,
    v_telegram_id,
    v_telegram_username,
    v_avatar
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name),
    email = COALESCE(EXCLUDED.email, public.profiles.email),
    phone_number = COALESCE(EXCLUDED.phone_number, public.profiles.phone_number),
    telegram_id = COALESCE(EXCLUDED.telegram_id, public.profiles.telegram_id),
    telegram_username = COALESCE(EXCLUDED.telegram_username, public.profiles.telegram_username),
    avatar_url = COALESCE(EXCLUDED.avatar_url, public.profiles.avatar_url),
    updated_at = NOW();

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 7. Backfill existing auth.users into public.profiles
INSERT INTO public.profiles (
  id,
  full_name,
  email,
  phone_number,
  telegram_id,
  telegram_username,
  avatar_url
)
SELECT
  u.id,
  NULLIF(TRIM(COALESCE(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name', '')), ''),
  u.email,
  public.normalize_phone_e164(COALESCE(NULLIF(u.phone, ''), u.raw_user_meta_data->>'phone_number')),
  CASE
    WHEN (u.raw_user_meta_data->>'telegram_id') ~ '^[0-9]+$'
      THEN (u.raw_user_meta_data->>'telegram_id')::BIGINT
    ELSE NULL
  END,
  NULLIF(TRIM(COALESCE(u.raw_user_meta_data->>'username', u.raw_user_meta_data->>'telegram_username', '')), ''),
  NULLIF(TRIM(COALESCE(u.raw_user_meta_data->>'avatar_url', u.raw_user_meta_data->>'picture', '')), '')
FROM auth.users u
ON CONFLICT (id) DO NOTHING;
