-- FiçMatik Realtime Enabler
-- Run this in your Supabase SQL Editor to enable real-time updates for critical tables.

-- 1. Enable replication for the 'receipts' table
alter publication supabase_realtime add table receipts;

-- 2. Enable replication for the 'user_settings' table
alter publication supabase_realtime add table user_settings;

-- 3. Enable replication for the 'subscriptions' table
alter publication supabase_realtime add table subscriptions;

-- 4. Enable replication for the 'user_credits' table
alter publication supabase_realtime add table user_credits;

-- 5. Enable replication for the 'household_members' table
alter publication supabase_realtime add table household_members;

-- Note: Ensure that the "Realtime" toggle is also enabled for these tables in 
-- Database -> Replication -> 'supabase_realtime' publication in the Supabase Dashboard.
