-- Migration: add_reminder_time.sql
-- Description: Adds optional reminder_time column to the notes table for daily task notifications

ALTER TABLE notes 
ADD COLUMN IF NOT EXISTS reminder_time TIMESTAMPTZ;
