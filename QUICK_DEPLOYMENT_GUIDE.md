# Quick Deployment Guide - SMS Hook

## Current Status

✅ SMS Hook is ENABLED in Supabase Dashboard
✅ Hook is pointing to: `smart-function`
❓ `smart-function` doesn't exist locally (may be deployed already)

## Option 1: Check if smart-function is working

Try sending an OTP from your Flutter app:

```dart
await supabase.auth.signInWithOtp(phone: '+919999999999');
```

**If it works**: Your existing setup is fine! No changes needed.

**If it fails**: Continue to Option 2.

---

## Option 2: Deploy the New Secure SMS Hook (Recommended)

### Step 1: Deploy the Function

```bash
cd "/Volumes/sylonow mac/sylonow/sylonow_vendor_app/sylonow_vednor_app-main"

# Deploy the new auth-send-sms function
supabase functions deploy auth-send-sms --no-verify-jwt
```

### Step 2: Set Environment Variables

```bash
# Get these values from your existing MSG91 account
supabase secrets set MSG91_AUTHKEY=your_msg91_authkey
supabase secrets set MSG91_FLOW_ID=your_msg91_flow_id

# Get this from the dashboard (you already have it)
supabase secrets set SEND_SMS_HOOK_SECRET=v1,whsec_YOUR_SECRET_HERE
```

### Step 3: Update SMS Hook URL in Dashboard

1. Go to: https://supabase.com/dashboard/project/txgszrxjyanazlrupaty/auth/hooks
2. Click "Configure hook" on the "Send SMS hook"
3. Update the endpoint URL to:
   ```
   https://txgszrxjyanazlrupaty.supabase.co/functions/v1/auth-send-sms
   ```
4. Keep the same secret (or regenerate if needed)
5. Click "Save"

### Step 4: Enable Phone Provider

1. Go to: https://supabase.com/dashboard/project/txgszrxjyanazlrupaty/auth/providers
2. Click on "Phone"
3. Toggle "Enable Phone provider" to ON
4. Click "Save"

### Step 5: Test

In your Flutter app:

```dart
// Send OTP
await supabase.auth.signInWithOtp(
  phone: '+919999999999', // Test number
);

// Verify OTP
await supabase.auth.verifyOTP(
  type: OtpType.sms,
  phone: '+919999999999',
  token: '123456', // OTP received
);
```

---

## Troubleshooting

### Check Edge Function Logs

1. Go to: https://supabase.com/dashboard/project/txgszrxjyanazlrupaty/functions/auth-send-sms
2. Click on "Logs" tab
3. Send an OTP and watch for logs

### Common Issues

**Issue**: "Function not found"
- **Solution**: Make sure you deployed: `supabase functions deploy auth-send-sms --no-verify-jwt`

**Issue**: "Webhook verification failed"
- **Solution**: Make sure `SEND_SMS_HOOK_SECRET` matches the secret in the dashboard

**Issue**: "MSG91 authentication failed"
- **Solution**: Check `MSG91_AUTHKEY` and `MSG91_FLOW_ID` are correct

**Issue**: "Phone provider disabled"
- **Solution**: Go to Auth → Providers → Phone and enable it

---

## Quick Commands

```bash
# Deploy function
supabase functions deploy auth-send-sms --no-verify-jwt

# Set secrets
supabase secrets set MSG91_AUTHKEY=your_key
supabase secrets set MSG91_FLOW_ID=your_flow_id
supabase secrets set SEND_SMS_HOOK_SECRET=v1,whsec_YOUR_SECRET

# Check function status
supabase functions list

# View function logs (in browser)
# https://supabase.com/dashboard/project/txgszrxjyanazlrupaty/functions/auth-send-sms
```

---

## What Should Happen

When everything is working:

1. User enters phone number in Flutter app
2. App calls `supabase.auth.signInWithOtp()`
3. Supabase Auth generates OTP (hashed, secure)
4. Supabase calls your SMS hook (`auth-send-sms`)
5. Your function sends SMS via MSG91
6. User receives OTP
7. User enters OTP
8. App calls `supabase.auth.verifyOTP()`
9. Supabase verifies and creates session
10. User is authenticated ✅

---

## Status Checklist

- [ ] Phone provider enabled in dashboard
- [ ] SMS hook enabled in dashboard
- [ ] `auth-send-sms` function deployed
- [ ] Secrets configured (MSG91_AUTHKEY, MSG91_FLOW_ID, SEND_SMS_HOOK_SECRET)
- [ ] Hook URL points to `auth-send-sms`
- [ ] Tested with test phone number
- [ ] Tested with real phone number
- [ ] Edge function logs show success

---

**Ready to deploy?** Run: `./deploy_sms_hook.sh`
