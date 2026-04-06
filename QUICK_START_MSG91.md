# 🚀 Quick Start - MSG91 OTP Integration

## ✅ What's Done

Your app now has a **completely fresh MSG91 OTP integration** with:

- ✅ **4-digit OTP** (easier to type and remember)
- ✅ **No database storage** (MSG91 handles everything)
- ✅ **Clean MSG91 APIs** (Send OTP + Verify OTP)
- ✅ **Single edge function** (`otp-handler`)
- ✅ **Flutter UI updated** (4-digit input fields)
- ✅ **Already deployed** to Supabase

## 🎯 What You Need to Do

### Step 1: Get MSG91 Credentials (5 minutes)

1. **Create MSG91 Account**
   - Go to: https://msg91.com
   - Sign up and verify your account

2. **Get Your Auth Key**
   - Login → Settings → API Keys
   - Copy your **Auth Key**
   - Save it: `YOUR_MSG91_AUTHKEY`

3. **Create OTP Template**
   - Go to: OTP section
   - Click "Create Template"
   - **Message**: `Your Sylonow verification code is ##OTP##. Valid for 5 minutes.`
   - **OTP Length**: 4 digits
   - **OTP Expiry**: 5 minutes
   - Submit and get approval
   - Copy **Template ID**
   - Save it: `YOUR_MSG91_TEMPLATE_ID`

### Step 2: Add Secrets to Supabase (2 minutes)

#### Option A: Using Supabase Dashboard (Recommended)

1. Go to: https://supabase.com/dashboard/project/txgszrxjyanazlrupaty
2. Click: **Edge Functions** → **Secrets**
3. Add these two secrets:
   ```
   MSG91_AUTHKEY = your_msg91_auth_key_here
   MSG91_TEMPLATE_ID = your_msg91_template_id_here
   ```

#### Option B: Using Supabase CLI

```bash
cd "/Volumes/sylonow mac/sylonow/sylonow_vendor_app/sylonow_vednor_app-main"

supabase secrets set MSG91_AUTHKEY=your_msg91_auth_key_here
supabase secrets set MSG91_TEMPLATE_ID=your_msg91_template_id_here
```

### Step 3: Test It! (2 minutes)

#### Test with Test Phone (No SMS)

1. **Run your Flutter app**:
   ```bash
   flutter run
   ```

2. **Enter test phone**: `+919999999999`
3. **Click "Send OTP"**
4. **Check console** for test OTP: `1234`
5. **Enter OTP**: `1234`
6. **Click "Verify & Proceed"**
7. **Should work!** ✅

#### Test with Real Phone (SMS)

1. **Enter your real phone**: `+91XXXXXXXXXX`
2. **Click "Send OTP"**
3. **Check your phone** for SMS with 4-digit OTP
4. **Enter the OTP** you received
5. **Click "Verify & Proceed"**
6. **Should work!** ✅

## 📊 Verify It's Working

### Check Supabase Logs

1. Go to: https://supabase.com/dashboard/project/txgszrxjyanazlrupaty/functions
2. Click on **otp-handler**
3. View **Logs** tab
4. You should see:
   - `otp-handler: Sending OTP to +919999999999`
   - `otp-handler: Test phone detected`
   - `otp-handler: Verifying OTP for +919999999999`
   - `otp-handler: Test OTP verified successfully`

### Check MSG91 Dashboard

1. Go to: https://msg91.com/dashboard
2. Click: **Reports** → **OTP Logs**
3. You should see:
   - OTP requests
   - Delivery status
   - Success/failure rates

## 🎉 That's It!

Your OTP system is now:
- ✅ **Simpler** - No database tables to manage
- ✅ **Faster** - Direct MSG91 API calls
- ✅ **Cleaner** - Single unified edge function
- ✅ **Better UX** - 4-digit OTP is easier to type
- ✅ **More Secure** - OTP never touches your database

## 📚 Full Documentation

For detailed information, see:
- **[MSG91_OTP_FRESH_SETUP.md](MSG91_OTP_FRESH_SETUP.md)** - Complete setup guide
- **[test_msg91_otp.sh](test_msg91_otp.sh)** - Test script

## 🆘 Need Help?

### Common Issues

**"SMS service not configured"**
→ Add MSG91_AUTHKEY and MSG91_TEMPLATE_ID to Supabase secrets

**"Invalid phone number format"**
→ Use format: `+91XXXXXXXXXX` (Indian numbers only)

**"Failed to send OTP"**
→ Check MSG91 credentials and template approval

**OTP not received**
→ Check MSG91 Dashboard → Reports → OTP Logs for delivery status

### Support

- **MSG91**: support@msg91.com
- **Supabase**: https://supabase.com/dashboard/project/txgszrxjyanazlrupaty

---

**Ready to go!** 🚀 Just add your MSG91 credentials and start testing!
