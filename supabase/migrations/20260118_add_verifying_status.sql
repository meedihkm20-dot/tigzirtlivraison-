-- Migration: Add 'verifying' status to order_status enum
-- This allows the new Secure Verification Flow where livreur validates the order before restaurant receives it

-- Add 'verifying' value to order_status enum (PostgreSQL)
ALTER TYPE order_status ADD VALUE IF NOT EXISTS 'verifying' AFTER 'pending';

-- Note: In PostgreSQL, new enum values can only be added, not removed or reordered easily.
-- The 'verifying' status sits between 'pending' and 'confirmed' in the order flow.
