import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

function normalizePhone(phone: string): string {
  const trimmed = phone.trim();
  if (trimmed.startsWith("+")) return trimmed;
  if (trimmed.startsWith("0")) return "+91" + trimmed.slice(1);
  if (/^\d+$/.test(trimmed)) return "+91" + trimmed;
  return trimmed;
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
    console.log("verify-vendor-otp: Request started");

    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed" }),
        { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse request body
    const { phone, otp } = await req.json();

    if (!phone || !otp) {
      return new Response(
        JSON.stringify({ error: "Phone number and OTP are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const normalizedPhone = normalizePhone(phone);
    const otpCode = otp.toString().trim();

    console.log("verify-vendor-otp: Verifying", { phone: normalizedPhone, otp: otpCode });

    // Validate OTP format (4 digits)
    if (!otpCode.match(/^\d{4}$/)) {
      return new Response(
        JSON.stringify({ error: "Invalid OTP format. Must be 4 digits." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Create Supabase client
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Find the most recent non-verified OTP for this phone
    const { data: otpRecords, error: fetchError } = await supabase
      .from("vendor_otp_verifications")
      .select("*")
      .eq("phone", normalizedPhone)
      .eq("is_verified", false)
      .order("created_at", { ascending: false })
      .limit(1);

    if (fetchError) {
      console.error("verify-vendor-otp: Fetch error", fetchError);
      return new Response(
        JSON.stringify({ error: "Failed to verify OTP. Please try again." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!otpRecords || otpRecords.length === 0) {
      return new Response(
        JSON.stringify({ error: "No OTP found. Please request a new OTP." }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const otpRecord = otpRecords[0];

    // Check if OTP has expired
    const now = new Date();
    const expiresAt = new Date(otpRecord.expires_at);

    if (now > expiresAt) {
      console.log("verify-vendor-otp: OTP expired", { now, expiresAt });

      return new Response(
        JSON.stringify({ error: "OTP has expired. Please request a new OTP." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Check max attempts
    if (otpRecord.attempts >= otpRecord.max_attempts) {
      console.log("verify-vendor-otp: Max attempts exceeded", otpRecord.attempts);

      return new Response(
        JSON.stringify({ error: "Maximum verification attempts exceeded. Please request a new OTP." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Verify OTP code
    if (otpRecord.otp_code !== otpCode) {
      console.log("verify-vendor-otp: Invalid OTP", {
        expected: otpRecord.otp_code,
        received: otpCode
      });

      // Increment attempts
      await supabase
        .from("vendor_otp_verifications")
        .update({ attempts: otpRecord.attempts + 1 })
        .eq("id", otpRecord.id);

      const remainingAttempts = otpRecord.max_attempts - (otpRecord.attempts + 1);

      return new Response(
        JSON.stringify({
          error: "Invalid OTP. Please try again.",
          remainingAttempts: Math.max(0, remainingAttempts)
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // OTP is valid - mark as verified
    const { error: updateError } = await supabase
      .from("vendor_otp_verifications")
      .update({
        is_verified: true,
        verified_at: new Date().toISOString(),
        attempts: otpRecord.attempts + 1,
      })
      .eq("id", otpRecord.id);

    if (updateError) {
      console.error("verify-vendor-otp: Update error", updateError);
      return new Response(
        JSON.stringify({ error: "Failed to verify OTP. Please try again." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log("verify-vendor-otp: Success", { phone: normalizedPhone });

    // Check if vendor exists or create new one
    const { data: existingVendor } = await supabase
      .from("vendors")
      .select("id, auth_user_id, is_onboarding_completed, verification_status")
      .eq("phone", normalizedPhone)
      .single();

    // Create auth user for the vendor if they don't have one
    let authUserId = existingVendor?.auth_user_id;

    if (!authUserId) {
      // Create a dummy auth user (since we're not using Supabase auth anymore)
      // We'll use phone number as the identifier
      const { data: authData, error: authError } = await supabase.auth.admin.createUser({
        phone: normalizedPhone,
        phone_confirm: true,
      });

      if (authError) {
        console.error("verify-vendor-otp: Auth user creation error", authError);
        // Continue anyway - we can create vendor without auth_user_id
      } else {
        authUserId = authData.user.id;
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "OTP verified successfully",
        phone: normalizedPhone,
        vendorExists: !!existingVendor,
        vendorId: existingVendor?.id,
        authUserId: authUserId,
        isOnboardingCompleted: existingVendor?.is_onboarding_completed ?? false,
        verificationStatus: existingVendor?.verification_status ?? "pending",
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("verify-vendor-otp: Unexpected error", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
