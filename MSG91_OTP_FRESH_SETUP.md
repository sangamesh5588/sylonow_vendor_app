# MSG91 OTP Integration - Fresh Setup Guide

## ✅ Complete Fresh Implementation

This is a **completely new MSG91 OTP integration** that:
- ✅ Uses **4-digit OTP** (not 6-digit)
- ✅ Uses **MSG91 Send OTP API** (not Flow ID)
- ✅ Uses **MSG91 Verify OTP API** for verification
- ✅ **No database table** for storing OTP (MSG91 handles it)
- ✅ Clean, simple architecture

---

## 🏗️ Architecture Overview

### Components

1. **Edge Function**: `otp-handler` - Unified handler for send and verify actions
2. **Flutter Integration**: Updated onboarding flow uses the new edge function
3. **MSG91 APIs**:
   - Send OTP API (POST) - Generates and sends 4-digit OTP
   - Verify OTP API (GET) - Validates the OTP

**No database table needed!** MSG91 stores the OTP internally.

---

## 📋 MSG91 Setup Steps

### 1. Create MSG91 Account

1. Go to [https://msg91.com](https://msg91.com)
2. Sign up for an account
3. Verify your account

### 2. Get Your Auth Key

1. Login to MSG91 Dashboard
2. Go to **Settings** → **API Keys**
3. Copy your **Auth Key**
4. Save it for later: `YOUR_MSG91_AUTHKEY`

### 3. Create OTP Template

1. Go to **OTP** section in MSG91 Dashboard
2. Click **Create Template**
3. Template details:
   - **Name**: `Sylonow Vendor OTP`
   - **Message**: `Your Sylonow verification code is ##OTP##. Valid for 5 minutes.`
   - **OTP Length**: 4 digits
   - **OTP Expiry**: 5 minutes
4. Submit for approval (usually instant)
5. Copy the **Template ID** once approved
6. Save it for later: `YOUR_MSG91_TEMPLATE_ID`

---

## 🔐 Supabase Configuration

### Set Environment Variables

You need to set these secrets in your Supabase project:

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project: `txgszrxjyanazlrupaty`
3. Navigate to **Edge Functions** → **Secrets**
4. Add these secrets:

```bash
MSG91_AUTHKEY=your_msg91_auth_key_here
MSG91_TEMPLATE_ID=your_msg91_template_id_here
```

### Using Supabase CLI (Alternative)

```bash
# Navigate to project directory
cd "/Volumes/sylonow mac/sylonow/sylonow_vendor_app/sylonow_vednor_app-main"

# Set secrets
supabase secrets set MSG91_AUTHKEY=your_msg91_auth_key_here
supabase secrets set MSG91_TEMPLATE_ID=your_msg91_template_id_here
```

---

## 🚀 Deployment

### Edge Function Already Deployed ✅

The `otp-handler` function is deployed and active at:
- **Project**: txgszrxjyanazlrupaty
- **Function**: otp-handler
- **Status**: Active
- **Dashboard**: https://supabase.com/dashboard/project/txgszrxjyanazlrupaty/functions

### Redeploy if Needed

```bash
# Navigate to project root
cd "/Volumes/sylonow mac/sylonow/sylonow_vendor_app/sylonow_vednor_app-main"

# Deploy the function
supabase functions deploy otp-handler --no-verify-jwt
```

---

## 📱 How It Works

### 1. Send OTP Flow

```
User enters phone number
      ↓
Flutter calls otp-handler with action: "send"
      ↓
Edge function calls MSG91 Send OTP API
      ↓
MSG91 generates 4-digit OTP
      ↓
MSG91 sends SMS to user's phone
      ↓
MSG91 stores OTP internally (expires in 5 minutes)
      ↓
User receives SMS with 4-digit OTP
```

### 2. Verify OTP Flow

```
User enters 4-digit OTP
      ↓
Flutter calls otp-handler with action: "verify"
      ↓
Edge function calls MSG91 Verify OTP API
      ↓
MSG91 validates OTP (checks expiry, attempts, etc.)
      ↓
If valid: Create Supabase auth user
      ↓
Return success with vendor details
      ↓
User proceeds to onboarding/home
```

---

## 🔧 API Reference

### Edge Function: `otp-handler`

**Endpoint**: `https://txgszrxjyanazlrupaty.supabase.co/functions/v1/otp-handler`

#### Send OTP

**Request**:
```json
{
  "action": "send",
  "phone": "+919876543210"
}
```

**Success Response**:
```json
{
  "success": true,
  "message": "OTP sent successfully to your phone number",
  "expiresIn": 300
}
```

**Test Phone Success Response**:
```json
{
  "success": true,
  "message": "OTP sent successfully",
  "testOtp": "1234",
  "expiresIn": 300
}
```

#### Verify OTP

**Request**:
```json
{
  "action": "verify",
  "phone": "+919876543210",
  "otp": "1234"
}
```

**Success Response**:
```json
{
  "success": true,
  "message": "OTP verified successfully",
  "phone": "+919876543210",
  "vendorExists": true,
  "vendorId": "uuid",
  "authUserId": "uuid",
  "isOnboardingCompleted": false,
  "verificationStatus": "pending"
}
```

**Error Response**:
```json
{
  "error": "Invalid OTP. Please try again."
}
```

---

## 📝 Flutter Integration

### Files Updated

1. **[lib/features/onboarding/service/onboarding_service.dart](lib/features/onboarding/service/onboarding_service.dart)**
   - Already configured to use `otp-handler` function
   - `signInWithMobile()` calls with `action: 'send'`
   - `verifyOTP()` calls with `action: 'verify'`

2. **[lib/features/onboarding/screens/otp_verification_screen.dart](lib/features/onboarding/screens/otp_verification_screen.dart:519)**
   - Updated to **4-digit OTP input**
   - Field width and height adjusted for better UX
   - Auto-verification on 4-digit entry

3. **[lib/features/onboarding/helpers/otp_helper.dart](lib/features/onboarding/helpers/otp_helper.dart:26)**
   - Updated `isValidOtp()` to validate **4 digits**

### Usage Example

```dart
// Send OTP
final result = await ref
    .read(onboardingProvider.notifier)
    .signInWithMobile("+919876543210");

result.fold(
  (error) => print('Error: $error'),
  (success) => print('OTP sent successfully'),
);

// Verify OTP
final verifyResult = await ref
    .read(otpControllerProvider.notifier)
    .verifyOtp("+919876543210");

if (verifyResult) {
  // OTP verified, proceed to next screen
  context.go('/onboarding');
}
```

---

## 🧪 Testing

### Test Phone Numbers

For testing without sending real SMS:

- `+919999999999` → Returns fixed OTP: `1234`
- `+15005550006` → Returns fixed OTP: `1234`

### Test Flow

1. **Run the app**:
   ```bash
   flutter run
   ```

2. **Enter test phone number**:
   - Enter: `+919999999999`
   - Click "Send OTP"
   - Check console for: `🧪 TEST OTP: 1234`

3. **Verify OTP**:
   - Enter: `1234`
   - Click "Verify & Proceed"
   - Should succeed and navigate to next screen

### Production Testing

1. **Enter real phone number**: `+91XXXXXXXXXX`
2. **Check MSG91 Dashboard**:
   - Go to **Reports** → **OTP Logs**
   - Verify SMS was sent
   - Check delivery status
3. **Enter received OTP**
4. **Verify it works**

---

## 🔍 Debugging

### Check Supabase Logs

1. Go to [Supabase Dashboard](https://supabase.com/dashboard/project/txgszrxjyanazlrupaty/functions)
2. Click on **otp-handler** function
3. View **Logs** tab
4. Check for errors or success messages

### Common Issues

#### 1. "SMS service not configured"
**Cause**: MSG91_AUTHKEY or MSG91_TEMPLATE_ID not set
**Fix**: Add secrets in Supabase Dashboard → Edge Functions → Secrets

#### 2. "Failed to send OTP"
**Cause**: MSG91 API error (wrong credentials, template not approved, etc.)
**Fix**:
- Verify MSG91 Auth Key is correct
- Ensure Template ID is approved
- Check MSG91 account balance
- Check MSG91 Dashboard for error details

#### 3. "Invalid phone number format"
**Cause**: Phone number not in correct format
**Fix**: Use format `+91XXXXXXXXXX` (Indian numbers only)

#### 4. "Invalid OTP"
**Cause**: OTP expired or incorrect
**Fix**:
- Request new OTP (expires in 5 minutes)
- Enter correct OTP received via SMS

---

## ✨ Features

### User Experience
- ⚡ Fast OTP delivery (< 5 seconds)
- 📱 **4-digit OTP** (easy to remember and type)
- ⏱️ 5-minute expiration
- 🔄 Easy resend functionality
- 🧪 Test mode for development (no SMS charges)
- 📲 Auto-fill support for OTP

### Technical Features
- 🎯 No database table needed (MSG91 handles storage)
- 🔐 Secure - OTP never touches your database
- ⚡ Fast - Direct MSG91 API calls
- 🧹 Clean - No OTP cleanup jobs needed
- 📝 Simple - Single unified edge function
- 🔄 Automatic expiry (MSG91 handles it)

---

## 📊 MSG91 API Documentation

- **Send OTP API**: https://docs.msg91.com/p/tf9GTextN/e/S2or-h0rS/MSG91-OTP-API
- **Verify OTP API**: https://docs.msg91.com/p/tf9GTextN/e/caxGZnrJv/MSG91-Verify-Retry-Voice
- **Dashboard**: https://msg91.com/dashboard

---

## 🗑️ Old Implementation Cleanup (Optional)

### Old Files That Can Be Removed

These files are from the old implementation and are **no longer used**:

1. **Database Migration**: Remove `vendor_otp_verifications` table
   ```sql
   DROP TABLE IF EXISTS public.vendor_otp_verifications;
   ```

2. **Old Edge Functions**:
   - `supabase/functions/send-otp/` → ❌ Not used (replaced by otp-handler)
   - `supabase/functions/verify-otp/` → ❌ Not used (replaced by otp-handler)

3. **Old Documentation**:
   - `MSG91_OTP_INTEGRATION.md` → ❌ Outdated (use this file instead)

### Keep These Files
- ✅ `supabase/functions/otp-handler/` - **NEW unified function**
- ✅ All Flutter files (already updated)

---

## 📈 Monitoring

### What to Monitor

1. **Supabase Function Logs**:
   - Check for errors in otp-handler function
   - Monitor success/failure rates

2. **MSG91 Dashboard**:
   - Monitor SMS delivery rates
   - Check account balance
   - View OTP logs and reports

3. **Flutter Analytics** (if configured):
   - Track OTP send success rate
   - Track OTP verification success rate
   - Monitor user drop-off points

---

## 🎯 Next Steps

1. ✅ **Test with test phone numbers** (already working)
2. ⚠️ **Add MSG91 credentials** to Supabase secrets
3. ⚠️ **Test with real phone number**
4. ⚠️ **Monitor MSG91 dashboard** for delivery
5. ⚠️ **Remove old database table** (optional cleanup)
6. ⚠️ **Delete old edge functions** (optional cleanup)

---

## 📞 Support

### MSG91 Support
- **Email**: support@msg91.com
- **Dashboard**: https://msg91.com/dashboard
- **Documentation**: https://docs.msg91.com

### Supabase Support
- **Dashboard**: https://supabase.com/dashboard/project/txgszrxjyanazlrupaty
- **Documentation**: https://supabase.com/docs/guides/functions

---

## 📝 Summary

### What Changed from Old Implementation

| Feature | Old (Flow ID) | New (Send OTP API) |
|---------|---------------|-------------------|
| OTP Length | 6 digits | **4 digits** ✅ |
| Storage | Database table | **None (MSG91)** ✅ |
| API | Flow API | **Send OTP + Verify OTP** ✅ |
| Edge Functions | 2 separate | **1 unified** ✅ |
| Configuration | Flow ID + Auth Key | **Template ID + Auth Key** ✅ |
| Cleanup | Manual (cron job) | **Automatic (MSG91)** ✅ |

### Benefits

- ✅ Simpler architecture
- ✅ No database overhead
- ✅ Easier to maintain
- ✅ Better user experience (4-digit OTP)
- ✅ More secure (OTP never in your DB)
- ✅ Automatic cleanup (MSG91 handles it)

---

**Last Updated**: 2026-02-25
**Version**: 2.0.0
**Status**: ✅ Deployed and Ready for Testing
**Edge Function URL**: https://supabase.com/dashboard/project/txgszrxjyanazlrupaty/functions
