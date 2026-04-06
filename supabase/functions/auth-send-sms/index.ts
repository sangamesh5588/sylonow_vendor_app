import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { Webhook } from "https://esm.sh/standardwebhooks@1.0.0";

// Environment variables
const MSG91_AUTHKEY = Deno.env.get("MSG91_AUTHKEY") ?? "";
const MSG91_FLOW_ID = Deno.env.get("MSG91_FLOW_ID") ?? "";
const SEND_SMS_HOOK_SECRET = Deno.env.get("SEND_SMS_HOOK_SECRET") ?? "";

// Test phones - bypass MSG91 for testing
const TEST_PHONES = new Set<string>([
  "+15005550006",
  "+919999999999", // Add test numbers here
]);

/**
 * SMS Hook Handler for Supabase Auth
 *
 * This function is called by Supabase Auth whenever an SMS needs to be sent.
 * It integrates with MSG91 for Indian phone numbers.
 *
 * Security Features:
 * - Webhook signature verification using Standard Webhooks spec
 * - No OTP storage (Supabase handles that securely)
 * - Rate limiting handled by Supabase Auth
 * - Automatic retry logic for transient failures
 */
Deno.serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type, webhook-id, webhook-timestamp, webhook-signature",
  };

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders, status: 204 });
  }

  // Only accept POST requests
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({
        error: {
          http_code: 405,
          message: "Method not allowed"
        }
      }),
      {
        status: 405,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      }
    );
  }

  try {
    console.log("auth-send-sms: Hook triggered");

    // Verify webhook secret is configured
    if (!SEND_SMS_HOOK_SECRET) {
      console.error("SEND_SMS_HOOK_SECRET is not configured");
      return new Response(
        JSON.stringify({
          error: {
            http_code: 500,
            message: "SMS service configuration error"
          }
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        }
      );
    }

    // Read payload and verify webhook signature
    const payload = await req.text();
    const headers = Object.fromEntries(req.headers);

    // Remove the v1,whsec_ prefix for verification
    const secret = SEND_SMS_HOOK_SECRET.replace("v1,whsec_", "");
    const wh = new Webhook(secret);

    let verifiedPayload;
    try {
      verifiedPayload = wh.verify(payload, headers);
    } catch (error) {
      console.error("Webhook verification failed:", error);
      return new Response(
        JSON.stringify({
          error: {
            http_code: 401,
            message: "Webhook verification failed"
          }
        }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        }
      );
    }

    // Extract user and SMS data from verified payload
    const { user, sms } = verifiedPayload as {
      user: {
        id: string;
        phone: string;
        email?: string;
        aud: string;
      };
      sms: {
        otp: string; // Supabase generates this securely
      };
    };

    console.log("auth-send-sms: Verified request for phone", user.phone);

    if (!user.phone) {
      return new Response(
        JSON.stringify({
          error: {
            http_code: 400,
            message: "Phone number is required"
          }
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        }
      );
    }

    if (!sms.otp) {
      return new Response(
        JSON.stringify({
          error: {
            http_code: 400,
            message: "OTP is required"
          }
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        }
      );
    }

    const phone = user.phone;
    const otpCode = sms.otp;

    // Validate phone format (Indian numbers)
    if (!phone.match(/^\+91\d{10}$/)) {
      console.warn("Invalid phone format:", phone);
      // Return success but log warning - Supabase will handle validation
    }

    // Check if test phone - for development/testing
    if (TEST_PHONES.has(phone)) {
      console.log("auth-send-sms: Test phone detected, skipping MSG91", {
        phone,
        otp: otpCode, // Only log for test phones
      });

      return new Response(
        JSON.stringify({}),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        }
      );
    }

    // Verify MSG91 credentials
    if (!MSG91_AUTHKEY || !MSG91_FLOW_ID) {
      console.error("MSG91 credentials not configured");
      return new Response(
        JSON.stringify({
          error: {
            http_code: 500,
            message: "SMS provider not configured"
          }
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        }
      );
    }

    // Prepare MSG91 payload
    const msg91Payload = {
      flow_id: MSG91_FLOW_ID,
      recipients: [
        {
          mobiles: phone.replace("+", ""), // Remove + for MSG91
          otp: otpCode,
        },
      ],
    };

    console.log("auth-send-sms: Sending to MSG91", { phone });

    // Send SMS via MSG91
    const msg91Response = await fetch("https://control.msg91.com/api/v5/flow", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        authkey: MSG91_AUTHKEY,
      },
      body: JSON.stringify(msg91Payload),
    });

    const msg91Text = await msg91Response.text();
    console.log("auth-send-sms: MSG91 response", {
      status: msg91Response.status,
      body: msg91Text,
    });

    // Handle MSG91 errors with retry logic
    if (!msg91Response.ok) {
      console.error("MSG91 error:", msg91Text);

      // For temporary errors, return retry-able status
      if (msg91Response.status === 429 || msg91Response.status >= 500) {
        return new Response(
          JSON.stringify({
            error: {
              http_code: 503,
              message: "SMS service temporarily unavailable"
            }
          }),
          {
            status: 503,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json",
              "Retry-After": "true" // Tell Supabase to retry
            }
          }
        );
      }

      // For permanent errors (auth failed, invalid phone, etc.)
      return new Response(
        JSON.stringify({
          error: {
            http_code: msg91Response.status,
            message: msg91Response.status === 401
              ? "SMS service authentication failed"
              : "Failed to send SMS"
          }
        }),
        {
          status: msg91Response.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        }
      );
    }

    console.log("auth-send-sms: SMS sent successfully");

    // Return success - empty JSON object
    return new Response(
      JSON.stringify({}),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      }
    );

  } catch (error) {
    console.error("auth-send-sms: Unexpected error", error);

    // Return 500 for unexpected errors
    return new Response(
      JSON.stringify({
        error: {
          http_code: 500,
          message: "Internal server error"
        }
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      }
    );
  }
});
