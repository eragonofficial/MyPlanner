-- ==========================================================
-- Supabase SQL Schema for "My Planner & Pomodoro"
-- Run this in your Supabase project's SQL Editor:
-- https://supabase.com/dashboard/project/mrwwmackzhsscsozcoay/sql
-- ==========================================================

create table if not exists public.notes (
    id text primary key,
    user_id uuid references auth.users(id) on delete cascade default auth.uid(),
    title text not null,
    description text default '',
    period_type text not null default 'daily', -- 'daily', 'weekly', 'monthly', 'yearly'
    target_date timestamptz not null default now(),
    priority text not null default 'medium',    -- 'low', 'medium', 'high'
    is_completed boolean not null default false,
    reminder_time timestamptz,                  -- optional reminder notification timestamp
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Enable Row Level Security (RLS)
alter table public.notes enable row level security;

-- Policy: Authenticated users can view their own notes or shared notes
drop policy if exists "Users can view their own notes or public notes" on public.notes;
create policy "Users can view their own notes or public notes" on public.notes
    for select
    using (auth.uid() = user_id or user_id is null);

-- Policy: Users can insert their own notes
drop policy if exists "Users can insert their own notes" on public.notes;
create policy "Users can insert their own notes" on public.notes
    for insert
    with check (auth.uid() = user_id or user_id is null);

-- Policy: Users can update their own notes
drop policy if exists "Users can update their own notes" on public.notes;
create policy "Users can update their own notes" on public.notes
    for update
    using (auth.uid() = user_id or user_id is null)
    with check (auth.uid() = user_id or user_id is null);

-- Policy: Users can delete their own notes
drop policy if exists "Users can delete their own notes" on public.notes;
create policy "Users can delete their own notes" on public.notes
    for delete
    using (auth.uid() = user_id or user_id is null);

-- Fast indexing for query filters
create index if not exists idx_notes_user_id on public.notes(user_id);
create index if not exists idx_notes_period on public.notes(period_type);
create index if not exists idx_notes_date on public.notes(target_date);
