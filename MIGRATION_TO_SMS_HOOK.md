# Migration Guide: Custom OTP → Supabase Auth SMS Hook

This guide will help you migrate from your custom OTP system to the more secure Supabase Auth with SMS Hook approach.

## 🔒 Security Comparison

### Current Custom System (Insecure ❌)
```
User → send-otp edge function → Generate OTP → Store OTP in PLAIN TEXT → MSG91 → User
                                                        ⚠️ SECURITY RISK!
```

### New SMS Hook System (Secure ✅)
```
User → Supabase Auth → Generate & Hash OTP → SMS Hook → MSG91 → User
                       (Secure, OWASP compliant)
```

## 📋 Migration Steps

### Step 1: Deploy the SMS Hook Edge Function

```bash
# Deploy the new auth-send-sms function
cd supabase
supabase functions deploy auth-send-sms --no-verify-jwt

# You should see:
# Deployed Function auth-send-sms on project YOUR_PROJECT
```

### Step 2: Configure Secrets

Set the required environment variables:

```bash
# Set MSG91 credentials (you already have these)
supabase secrets set MSG91_AUTHKEY=your_msg91_authkey
supabase secrets set MSG91_FLOW_ID=your_msg91_flow_id

# Set the SMS Hook secret (get this from the dashboard)
supabase secrets set SEND_SMS_HOOK_SECRET=v1,whsec_YOUR_SECRET
```

### Step 3: Enable SMS Hook in Supabase Dashboard

1. Go to: https://supabase.com/dashboard/project/YOUR_PROJECT/auth/hooks
2. Click "Add hook" or "Edit hook" if you have the disabled one
3. Select "Send SMS hook"
4. Configure:
   - **Type**: HTTPS endpoint
   - **URL**: `https://YOUR_PROJECT.supabase.co/functions/v1/auth-send-sms`
   - **Secret**: Click "Generate Secret" and copy the value
5. Click "Enable hook" ✅

### Step 4: Update Flutter Code

Replace your `onboarding_service.dart` with `onboarding_service_secure.dart`:

```bash
# Backup current file
mv lib/features/onboarding/service/onboarding_service.dart \
   lib/features/onboarding/service/onboarding_service_OLD.dart

# Rename the secure version
mv lib/features/onboarding/service/onboarding_service_secure.dart \
   lib/features/onboarding/service/onboarding_service.dart
```

**No other Flutter code changes needed!** The API is compatible.

### Step 5: Test the Integration

#### Local Testing

```bash
# Start the function locally
supabase functions serve auth-send-sms --no-verify-jwt --env-file supabase/functions/.env
```

#### Test with Flutter App

1. Build and run your app
2. Try phone authentication with a test number: `+919999999999`
3. Check logs in the Supabase Dashboard → Edge Functions → Logs
4. Try with a real number

### Step 6: Verify Everything Works

Test these scenarios:

- ✅ Send OTP to valid phone number
- ✅ Verify OTP with correct code
- ✅ Verify OTP with wrong code (should fail)
- ✅ Rate limiting (try sending 3+ OTPs quickly)
- ✅ Expired OTP (wait 5+ minutes, try to verify)
- ✅ Test phone numbers (bypass MSG91)

### Step 7: Monitor and Rollback Plan

#### Monitor

Watch the Supabase Dashboard for:
- Edge Function logs: `/functions/auth-send-sms`
- Auth logs: `/auth/users`
- Error rates

#### Rollback (if needed)

If something goes wrong:

```bash
# 1. Disable the SMS hook in dashboard
# 2. Restore old service file
mv lib/features/onboarding/service/onboarding_service_OLD.dart \
   lib/features/onboarding/service/onboarding_service.dart

# 3. Rebuild and deploy
flutter clean
flutter pub get
flutter build apk --release
```

## 🗑️ Cleanup After Migration

Once everything is working (give it 1-2 weeks):

### 1. Remove Old Edge Functions

```bash
supabase functions delete send-otp
supabase functions delete verify-otp
```

### 2. Drop Old Database Table

⚠️ **DANGER**: Only do this after confirming no one is using the old system!

```sql
-- Remove the vendor_otp_verifications table
DROP TABLE IF EXISTS public.vendor_otp_verifications;
```

### 3. Remove Old Code

```bash
# Remove backup file
rm lib/features/onboarding/service/onboarding_service_OLD.dart

# Remove old edge function directories
rm -rf supabase/functions/send-otp
rm -rf supabase/functions/verify-otp
```

## 📊 Security Improvements Summary

| Feature | Custom OTP ❌ | SMS Hook ✅ |
|---------|---------------|-------------|
| OTP Storage | Plain text | Hashed (bcrypt) |
| Rate Limiting | Manual (can have bugs) | Built-in (tested) |
| Session Management | Manual JWT creation | Automatic (secure) |
| Account Lockout | None | Automatic |
| CAPTCHA Support | None | Available |
| Audit Logs | Custom | Built-in |
| Token Refresh | Manual | Automatic |
| Security Audits | None | Regular (Supabase) |
| OWASP Compliance | ❓ Unknown | ✅ Compliant |
| SOC 2 | ❌ No | ✅ Yes (Enterprise) |

## 🎯 Expected Outcomes

After migration:

1. **Better Security**: OTPs never stored in plain text
2. **Less Code**: ~300 lines of code removed
3. **Better UX**: Faster authentication flow
4. **Compliance**: OWASP and SOC 2 compliant
5. **Less Maintenance**: Supabase handles security updates
6. **Better Analytics**: Auth events tracked in Supabase dashboard

## 🐛 Troubleshooting

### Issue: SMS Hook Not Firing

**Symptoms**: OTP not being sent, no logs in edge function

**Solutions**:
1. Check hook is enabled in dashboard
2. Verify `SEND_SMS_HOOK_SECRET` matches dashboard
3. Check edge function deployment: `supabase functions list`
4. Review auth logs in dashboard

### Issue: Webhook Verification Failed

**Symptoms**: Edge function logs show "Webhook verification failed"

**Solutions**:
1. Regenerate secret in dashboard
2. Update `SEND_SMS_HOOK_SECRET` with new value (include `v1,whsec_` prefix)
3. Redeploy function: `supabase functions deploy auth-send-sms`

### Issue: MSG91 Authentication Failed

**Symptoms**: "SMS service authentication failed" error

**Solutions**:
1. Verify `MSG91_AUTHKEY` is correct
2. Check MSG91 account status
3. Verify `MSG91_FLOW_ID` exists and is active

### Issue: Phone Number Format Error

**Symptoms**: "Invalid phone number format" error

**Solutions**:
1. Ensure phone is in E.164 format: `+919876543210`
2. Check country code is included
3. Remove spaces and dashes from phone number

## 📞 Support

If you encounter issues:

1. Check Supabase Dashboard → Edge Functions → Logs
2. Check Supabase Dashboard → Authentication → Logs
3. Review this guide again
4. Check Supabase docs: https://supabase.com/docs/guides/auth/auth-hooks/send-sms-hook

## ✅ Migration Checklist

Use this checklist to track your progress:

- [ ] Deploy `auth-send-sms` edge function
- [ ] Configure secrets (MSG91_AUTHKEY, MSG91_FLOW_ID, SEND_SMS_HOOK_SECRET)
- [ ] Enable SMS hook in Supabase dashboard
- [ ] Update Flutter code (use onboarding_service_secure.dart)
- [ ] Test with test phone numbers
- [ ] Test with real phone numbers
- [ ] Monitor for 1-2 weeks
- [ ] Remove old edge functions (send-otp, verify-otp)
- [ ] Drop vendor_otp_verifications table
- [ ] Remove old code files
- [ ] Update documentation
- [ ] Celebrate improved security! 🎉

## 🎓 Key Learnings

**Why SMS Hook is Better:**

1. **Separation of Concerns**:
   - Supabase handles authentication logic
   - Your edge function only handles SMS delivery

2. **Security by Default**:
   - OTPs are hashed using industry-standard bcrypt
   - Rate limiting prevents abuse
   - Account lockout prevents brute force attacks

3. **Less Code to Maintain**:
   - No custom OTP generation logic
   - No custom verification logic
   - No custom session management

4. **Professional Grade**:
   - Battle-tested by thousands of apps
   - Regular security audits
   - Compliance certifications

---

**Migration Date**: _____________________

**Completed By**: _____________________

**Status**: ⬜ Not Started | ⬜ In Progress | ⬜ Completed | ⬜ Rolled Back
