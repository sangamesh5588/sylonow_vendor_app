#!/bin/bash

# Deploy SMS Hook to Supabase
# This script deploys the secure SMS hook edge function

set -e  # Exit on error

echo "🚀 Deploying SMS Hook Edge Function..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI is not installed${NC}"
    echo "Install it with: npm install -g supabase"
    exit 1
fi

echo -e "${BLUE}📦 Deploying auth-send-sms function...${NC}"
supabase functions deploy auth-send-sms --no-verify-jwt

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Function deployed successfully!${NC}"
else
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}⚙️  Next steps:${NC}"
echo ""
echo "1. Set your secrets:"
echo "   ${BLUE}supabase secrets set MSG91_AUTHKEY=your_key${NC}"
echo "   ${BLUE}supabase secrets set MSG91_FLOW_ID=your_flow_id${NC}"
echo "   ${BLUE}supabase secrets set SEND_SMS_HOOK_SECRET=v1,whsec_YOUR_SECRET${NC}"
echo ""
echo "2. Enable the SMS hook in Supabase Dashboard:"
echo "   ${BLUE}https://supabase.com/dashboard/project/_/auth/hooks${NC}"
echo ""
echo "3. Configure the hook:"
echo "   - Type: HTTPS endpoint"
echo "   - URL: https://YOUR_PROJECT.supabase.co/functions/v1/auth-send-sms"
echo "   - Generate and copy the secret"
echo ""
echo "4. Test with your Flutter app!"
echo ""
echo -e "${GREEN}📖 For detailed migration guide, see: MIGRATION_TO_SMS_HOOK.md${NC}"
