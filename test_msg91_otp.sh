#!/bin/bash

# MSG91 OTP Integration Test Script
# Tests the new otp-handler edge function

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_URL="https://txgszrxjyanazlrupaty.supabase.co"
FUNCTION_NAME="otp-handler"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR4Z3N6cnhqeWFuYXpscnVwYXR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAyNzU4MjcsImV4cCI6MjA2NTg1MTgyN30.7MDiDGMCEa-E8c3HgIGxSpkOsH9kClD5i5LNSjzFul4"

# Test phone number
TEST_PHONE="+919999999999"
TEST_OTP="1234"

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}   MSG91 OTP Integration Test${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Test 1: Send OTP
echo -e "${YELLOW}Test 1: Send OTP${NC}"
echo "Phone: $TEST_PHONE"
echo ""

SEND_RESPONSE=$(curl -s -X POST "$PROJECT_URL/functions/v1/$FUNCTION_NAME" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANON_KEY" \
  -d "{\"action\":\"send\",\"phone\":\"$TEST_PHONE\"}")

echo "Response:"
echo "$SEND_RESPONSE" | jq '.'

if echo "$SEND_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Send OTP: PASSED${NC}"

  # Extract test OTP if present
  TEST_OTP_FROM_RESPONSE=$(echo "$SEND_RESPONSE" | jq -r '.testOtp // empty')
  if [ ! -z "$TEST_OTP_FROM_RESPONSE" ]; then
    echo -e "${GREEN}✓ Test OTP received: $TEST_OTP_FROM_RESPONSE${NC}"
    TEST_OTP=$TEST_OTP_FROM_RESPONSE
  fi
else
  echo -e "${RED}✗ Send OTP: FAILED${NC}"
  exit 1
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Wait a bit before verifying
sleep 2

# Test 2: Verify OTP
echo -e "${YELLOW}Test 2: Verify OTP${NC}"
echo "Phone: $TEST_PHONE"
echo "OTP: $TEST_OTP"
echo ""

VERIFY_RESPONSE=$(curl -s -X POST "$PROJECT_URL/functions/v1/$FUNCTION_NAME" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANON_KEY" \
  -d "{\"action\":\"verify\",\"phone\":\"$TEST_PHONE\",\"otp\":\"$TEST_OTP\"}")

echo "Response:"
echo "$VERIFY_RESPONSE" | jq '.'

if echo "$VERIFY_RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Verify OTP: PASSED${NC}"
else
  echo -e "${RED}✗ Verify OTP: FAILED${NC}"
  exit 1
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Test 3: Invalid OTP
echo -e "${YELLOW}Test 3: Invalid OTP (Should Fail)${NC}"
echo "Phone: $TEST_PHONE"
echo "OTP: 9999"
echo ""

INVALID_RESPONSE=$(curl -s -X POST "$PROJECT_URL/functions/v1/$FUNCTION_NAME" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANON_KEY" \
  -d "{\"action\":\"verify\",\"phone\":\"$TEST_PHONE\",\"otp\":\"9999\"}")

echo "Response:"
echo "$INVALID_RESPONSE" | jq '.'

if echo "$INVALID_RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Invalid OTP handled correctly: PASSED${NC}"
else
  echo -e "${RED}✗ Invalid OTP test: FAILED (should have returned error)${NC}"
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}All Tests Completed!${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Add MSG91_AUTHKEY to Supabase secrets"
echo "2. Add MSG91_TEMPLATE_ID to Supabase secrets"
echo "3. Test with a real phone number"
echo "4. Check MSG91 Dashboard for delivery status"
echo ""
