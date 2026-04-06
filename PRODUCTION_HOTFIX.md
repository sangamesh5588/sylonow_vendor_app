# 🚨 PRODUCTION HOTFIX - OTP Issue

## Problem Summary
Production app is stuck because:
1. ❌ Functions `send-otp` and `verify-otp` exist locally but may not be deployed
2. ❌ OR they're deployed but secrets are missing
3. ❌ OR there's an issue with the MSG91 configuration

## Immediate Fix Steps

### Step 1: Check Deployed Functions

Go to: https://supabase.com/dashboard/project/txgszrxjyanazlrupaty/functions

**You should see:**
- `send-otp` (or `msg91-send-otp`)
- `verify-otp` (or `msg91-verify-otp`)

**If you DON'T see `send-otp` and `verify-otp`:**
Deploy them immediately!

### Step 2: Deploy Missing Functions (Run This NOW!)

```bash
cd "/Volumes/sylonow mac/sylonow/sylonow_vendor_app/sylonow_vednor_app-main"

# Deploy send-otp
supabase functions deploy send-otp --no-verify-jwt

# Deploy verify-otp
supabase functions deploy verify-otp --no-verify-jwt
```

### Step 3: Verify Secrets Are Configured

Go to: https://supabase.com/dashboard/project/txgszrxjyanazlrupaty/settings/vault

**Required secrets:**
- ✅ `MSG91_AUTHKEY` - Your MSG91 auth key
- ✅ `MSG91_FLOW_ID` - Your MSG91 flow/template ID
- ✅ `SUPABASE_URL` (auto-configured)
- ✅ `SUPABASE_SERVICE_ROLE_KEY` (auto-configured)

**If missing, set them:**
```bash
supabase secrets set MSG91_AUTHKEY=your_msg91_auth_key
supabase secrets set MSG91_FLOW_ID=your_msg91_flow_id
```

### Step 4: Test OTP Flow

1. Open your production app
2. Go to phone authentication
3. Enter phone: `+919999999999` (test number)
4. Click "Send OTP"
5. Check logs: https://supabase.com/dashboard/project/txgszrxjyanazlrupaty/functions/send-otp/logs

**Expected result:**
- SMS sent successfully
- OTP stored in database
- Function returns 200

### Step 5: Monitor Production

Watch these logs:
- **Edge Functions**: https://supabase.com/dashboard/project/txgszrxjyanazlrupaty/functions
- **Auth Logs**: https://supabase.com/dashboard/project/txgszrxjyanazlrupaty/auth/users
- **Database**: Check `vendor_otp_verifications` table

---

## Quick Commands for Terminal

```bash
# 1. Deploy functions
cd "/Volumes/sylonow mac/sylonow/sylonow_vendor_app/sylonow_vednor_app-main"
supabase functions deploy send-otp --no-verify-jwt
supabase functions deploy verify-otp --no-verify-jwt

# 2. Set secrets (if needed)
supabase secrets set MSG91_AUTHKEY=your_key_here
supabase secrets set MSG91_FLOW_ID=your_flow_id_here

# 3. Check function status
supabase functions list

# 4. View logs
# Go to dashboard: https://supabase.com/dashboard/project/txgszrxjyanazlrupaty/functions/send-otp/logs
```

---

## What Each Secret Does

| Secret | Purpose | Where to Find |
|--------|---------|---------------|
| `MSG91_AUTHKEY` | Authenticates with MSG91 API | MSG91 Dashboard → Settings → API Keys |
| `MSG91_FLOW_ID` | Template for SMS message | MSG91 Dashboard → SMS → Flow/Templates |
| `SUPABASE_URL` | Your Supabase project URL | Auto-configured by Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | Admin access to database | Auto-configured by Supabase |

---

## Alternative: Check Existing Deployed Functions

Your dashboard shows you have `msg91-send-otp` and `msg91-verify-otp` deployed.

**Quick Fix Option:** Just rename the deployed functions to match what your app expects:

**Option A - Redeploy with correct names:**
```bash
# This will create send-otp from existing code
supabase functions deploy send-otp --no-verify-jwt
supabase functions deploy verify-otp --no-verify-jwt
```

**Option B - Update secrets for msg91 functions:**
```bash
# Make sure msg91 functions have correct secrets
supabase secrets set MSG91_AUTH_KEY=your_key
supabase secrets set MSG91_TEMPLATE_ID=your_template_id
supabase secrets set MSG91_OTP_API_BASE=https://control.msg91.com/api/v5/otp
supabase secrets set MSG91_VERIFY_API_BASE=https://control.msg91.com/api/v5/otp/verify
```

---

## Expected Behavior After Fix

### When User Requests OTP:
```
User enters phone → App calls send-otp → Function stores OTP → MSG91 sends SMS → User receives OTP
```

### When User Verifies OTP:
```
User enters OTP → App calls verify-otp → Function checks database → OTP matches → User authenticated
```

---

## Troubleshooting

### Issue: "Function not found"
**Solution:** Deploy the functions using commands above

### Issue: "MSG91 authentication failed"
**Solution:** Check `MSG91_AUTHKEY` is correct in secrets

### Issue: "SMS service not configured"
**Solution:** Set `MSG91_AUTHKEY` and `MSG91_FLOW_ID` secrets

### Issue: "OTP not received"
**Solution:**
1. Check MSG91 dashboard for delivery status
2. Check MSG91 account balance
3. Try test phone number: +919999999999

---

## ⏱️ Time Estimate

- Deploying functions: **2 minutes**
- Setting secrets: **1 minute**
- Testing: **2 minutes**
- **Total: ~5 minutes to fix production!**

---

## Status Checklist

- [ ] Functions deployed (`send-otp`, `verify-otp`)
- [ ] Secrets configured (`MSG91_AUTHKEY`, `MSG91_FLOW_ID`)
- [ ] Test OTP sent successfully
- [ ] Production app working
- [ ] Users can authenticate

---

**URGENT: Run the deploy commands NOW to fix production!**

```bash
cd "/Volumes/sylonow mac/sylonow/sylonow_vendor_app/sylonow_vednor_app-main"
supabase functions deploy send-otp --no-verify-jwt
supabase functions deploy verify-otp --no-verify-jwt
```
