# Auth Send SMS Hook

This Edge Function is a **Supabase Auth Hook** that intercepts SMS sending requests and uses MSG91 as the SMS provider for Indian phone numbers.

## Security Features

✅ **Webhook Signature Verification** - Uses Standard Webhooks specification to verify requests
✅ **No OTP Storage** - OTPs are generated and stored securely by Supabase Auth (hashed)
✅ **Rate Limiting** - Handled automatically by Supabase Auth
✅ **Automatic Retry** - Retry-able errors for transient failures
✅ **Test Phone Support** - Bypass SMS sending for development

## How It Works

```
User Requests OTP
       ↓
Supabase Auth generates OTP (hashed)
       ↓
Auth Hook triggered → this function
       ↓
SMS sent via MSG91
       ↓
User receives OTP
       ↓
User enters OTP
       ↓
Supabase Auth verifies (automatic)
       ↓
User authenticated ✅
```

## Environment Variables

Add these to your Supabase project secrets:

```bash
# MSG91 Configuration
MSG91_AUTHKEY=your_msg91_auth_key
MSG91_FLOW_ID=your_msg91_flow_id

# Webhook Secret (generated from Supabase Dashboard)
SEND_SMS_HOOK_SECRET=v1,whsec_YOUR_SECRET_HERE
```

## Deployment

1. Deploy the function:
```bash
supabase functions deploy auth-send-sms --no-verify-jwt
```

2. Set the secrets:
```bash
supabase secrets set MSG91_AUTHKEY=your_key
supabase secrets set MSG91_FLOW_ID=your_flow_id
supabase secrets set SEND_SMS_HOOK_SECRET=v1,whsec_your_secret
```

3. Configure the hook in Supabase Dashboard:
   - Go to Authentication → Hooks
   - Select "Send SMS hook"
   - Type: HTTPS endpoint
   - URL: `https://YOUR_PROJECT.supabase.co/functions/v1/auth-send-sms`
   - Secret: Generate and copy the secret
   - Click "Enable hook"

## Testing

### Test Phones
Add test phone numbers to the `TEST_PHONES` set in the code to bypass MSG91:

```typescript
const TEST_PHONES = new Set<string>([
  "+15005550006",
  "+919999999999",
]);
```

### Local Testing
```bash
supabase functions serve auth-send-sms --no-verify-jwt --env-file .env
```

## Flutter Integration

Use Supabase's built-in phone authentication:

```dart
// Send OTP
await supabase.auth.signInWithOtp(
  phone: '+919876543210',
);

// Verify OTP
await supabase.auth.verifyOTP(
  type: OtpType.sms,
  phone: '+919876543210',
  token: userEnteredOtp,
);
```

## Error Handling

| Error Code | Meaning | Action |
|------------|---------|--------|
| 200 | Success | SMS sent |
| 401 | Webhook verification failed | Check SEND_SMS_HOOK_SECRET |
| 503 | Temporary failure | Supabase will retry |
| 500 | Configuration error | Check MSG91 credentials |

## Advantages Over Custom OTP System

1. **Security**: OTPs are hashed by Supabase, never stored in plain text
2. **Rate Limiting**: Built-in protection against abuse
3. **Session Management**: Automatic JWT generation and refresh
4. **Compliance**: OWASP compliant, regularly audited
5. **Less Code**: You only handle SMS delivery, not OTP logic
6. **Better UX**: Automatic verification flow

## Migration from Custom OTP

If you're migrating from a custom OTP system:

1. Deploy this function
2. Update your Flutter app to use `supabase.auth.signInWithOtp()`
3. Enable the SMS hook in the dashboard
4. Test with test phone numbers
5. Gradually migrate users
6. Remove old `send-otp` and `verify-otp` functions

## Support

For issues with:
- MSG91 integration: Check MSG91 logs
- Webhook verification: Ensure secret matches dashboard
- Phone format: Must be E.164 format (+919876543210)
