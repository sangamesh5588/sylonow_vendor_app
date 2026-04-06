-- Check auth users
SELECT id, email, phone, created_at FROM auth.users ORDER BY created_at DESC LIMIT 5;

-- Check vendors table
SELECT id, user_id, email, phone, is_verified, is_onboarding_complete FROM vendors ORDER BY created_at DESC LIMIT 5;

-- Check if user 18af6a93-5e75-415b-beae-a762e5c93b57 exists
SELECT * FROM vendors WHERE user_id = '18af6a93-5e75-415b-beae-a762e5c93b57';
