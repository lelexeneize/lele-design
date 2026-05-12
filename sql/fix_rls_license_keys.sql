-- Run this in Supabase SQL Editor:
-- https://supabase.com/dashboard/project/qovtekqxruusqhscacqn/sql/new

CREATE POLICY "Allow anon inserts" ON license_keys FOR INSERT WITH CHECK (true);
