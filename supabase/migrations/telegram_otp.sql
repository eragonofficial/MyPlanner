-- Migration: Telegram OTP Authentication Codes Table
CREATE TABLE IF NOT EXISTS public.telegram_otp_codes (
  code TEXT PRIMARY KEY,
  telegram_id BIGINT NOT NULL,
  full_name TEXT,
  username TEXT,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_telegram_otp_codes_telegram_id
  ON public.telegram_otp_codes (telegram_id);

CREATE INDEX IF NOT EXISTS idx_telegram_otp_codes_expires_at
  ON public.telegram_otp_codes (expires_at);

-- Enable RLS so only Service Role (Edge Function) can access OTP codes
ALTER TABLE public.telegram_otp_codes ENABLE ROW LEVEL SECURITY;
