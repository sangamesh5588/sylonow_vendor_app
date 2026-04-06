import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const MSG91_AUTHKEY = Deno.env.get("MSG91_AUTHKEY") ?? "";
const MSG91_FLOW_ID = Deno.env.get("MSG91_FLOW_ID") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const OTP_EXPIRY_MINUTES = 5;
const MAX_ATTEMPTS = 3;

// Test phones - bypass MSG91 for testing
const TEST_PHONES = new Set<string>([
  "+15005550006",
  "+919999999999", // Add test numbers here
]);

function normalizePhone(phone: string): string {
  const trimmed = phone.trim();
  if (trimmed.startsWith("+")) return trimmed;
  if (trimmed.startsWith("0")) return "+91" + trimmed.slice(1);
  if (/^\d+$/.test(trimmed)) return "+91" + trimmed;
  return trimmed;
}

function generateOTP(): string {
  // Generate 6-digit OTP (matching Supabase default)
  return Math.floor(100000 + Math.random() * 900000).toString();
}

Deno.serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };

  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders, status: 204 });
  }

  try {
    console.log("send-vendor-otp: Request started");

    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed" }),
        { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse request body
    const { phone } = await req.json();

    if (!phone) {
      return new Response(
        JSON.stringify({ error: "Phone number is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const normalizedPhone = normalizePhone(phone);
    console.log("send-vendor-otp: Normalized phone", normalizedPhone);

    // Validate phone format (Indian numbers)
    if (!normalizedPhone.match(/^\+91\d{10}$/)) {
      return new Response(
        JSON.stringify({ error: "Invalid phone number format. Must be a valid Indian number." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Create Supabase client
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Check rate limiting - max 3 OTPs per phone per 10 minutes
    const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000).toISOString();
    const { data: recentOTPs, error: rateLimitError } = await supabase
      .from("vendor_otp_verifications")
      .select("id")
      .eq("phone", normalizedPhone)
      .gte("created_at", tenMinutesAgo);

    if (rateLimitError) {
      console.error("Rate limit check error:", rateLimitError);
    }

    if (recentOTPs && recentOTPs.length >= 3) {
      return new Response(
        JSON.stringify({
          error: "Too many OTP requests. Please try again after 10 minutes.",
          retryAfter: 600
        }),
        { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Generate 4-digit OTP
    const otpCode = generateOTP();
    const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

    console.log("send-vendor-otp: Generated OTP", { phone: normalizedPhone, otp: otpCode });

    // Store OTP in database
    const { data: otpRecord, error: insertError } = await supabase
      .from("vendor_otp_verifications")
      .insert({
        phone: normalizedPhone,
        otp_code: otpCode,
        expires_at: expiresAt.toISOString(),
        is_verified: false,
        attempts: 0,
        max_attempts: MAX_ATTEMPTS,
      })
      .select()
      .single();

    if (insertError) {
      console.error("OTP insert error:", insertError);
      return new Response(
        JSON.stringify({ error: "Failed to generate OTP. Please try again." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log("send-vendor-otp: OTP stored in database", otpRecord.id);

    // Check if test phone
    if (TEST_PHONES.has(normalizedPhone)) {
      console.log("send-vendor-otp: Test phone detected, skipping MSG91", {
        phone: normalizedPhone,
        otp: otpCode
      });

      return new Response(
        JSON.stringify({
          success: true,
          message: "OTP sent successfully",
          // Include OTP for test phones only
          testOtp: otpCode,
          expiresIn: OTP_EXPIRY_MINUTES * 60,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Send OTP via MSG91
    if (!MSG91_AUTHKEY || !MSG91_FLOW_ID) {
      console.error("MSG91 credentials not configured");
      return new Response(
        JSON.stringify({ error: "SMS service not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const msg91Payload = {
      flow_id: MSG91_FLOW_ID,
      recipients: [
        {
          mobiles: normalizedPhone.replace("+", ""),
          otp: otpCode,
        },
      ],
    };

    console.log("send-vendor-otp: Sending to MSG91", { phone: normalizedPhone });

    const msg91Response = await fetch("https://control.msg91.com/api/v5/flow", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        authkey: MSG91_AUTHKEY,
      },
      body: JSON.stringify(msg91Payload),
    });

    const msg91Text = await msg91Response.text();
    console.log("send-vendor-otp: MSG91 response", {
      status: msg91Response.status,
      body: msg91Text
    });

    if (!msg91Response.ok) {
      console.error("MSG91 error:", msg91Text);

      // Delete the OTP record since sending failed
      await supabase
        .from("vendor_otp_verifications")
        .delete()
        .eq("id", otpRecord.id);

      return new Response(
        JSON.stringify({
          error: "Failed to send OTP. Please try again.",
          details: msg91Response.status === 401 ? "SMS service authentication failed" : undefined
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log("send-vendor-otp: Success");

    return new Response(
      JSON.stringify({
        success: true,
        message: "OTP sent successfully to your phone number",
        expiresIn: OTP_EXPIRY_MINUTES * 60,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("send-vendor-otp: Unexpected error", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
