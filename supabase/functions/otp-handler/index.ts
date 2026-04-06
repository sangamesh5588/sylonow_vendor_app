import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const MSG91_AUTHKEY = Deno.env.get("MSG91_AUTHKEY") ?? "";
const MSG91_TEMPLATE_ID = Deno.env.get("MSG91_TEMPLATE_ID") ?? "";

// Test phones — Supabase Auth verifies the OTP itself, we just skip MSG91 delivery
const TEST_PHONES = new Set<string>([
  "+15005550006",
  "+919999999999",
]);

Deno.serve(async (req) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  };

  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders, status: 204 });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  try {
    const body = await req.json();

    // Supabase Auth SMS Hook sends a nested payload:
    // { user: { id, phone, ... }, sms: { otp, phone } }
    const phone: string = body.sms?.phone ?? body.user?.phone ?? body.phone ?? "";
    const otp: string = String(body.sms?.otp ?? body.otp ?? "");

    console.log("otp-handler: Hook invoked", { phone, hasOtp: !!otp });

    if (!phone || !otp) {
      console.error("otp-handler: Missing phone or otp in hook payload");
      return new Response(
        JSON.stringify({ error: "Phone and OTP are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Skip MSG91 for test phones — Supabase verifies the OTP itself
    if (TEST_PHONES.has(phone)) {
      console.log("otp-handler: Test phone detected, skipping SMS", { phone });
      return new Response(JSON.stringify({}), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!MSG91_AUTHKEY || !MSG91_TEMPLATE_ID) {
      console.error("otp-handler: MSG91 credentials not configured");
      return new Response(
        JSON.stringify({ error: "SMS service not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // MSG91 expects mobile without '+' prefix: e.g. 919876543210
    const mobile = phone.replace("+", "");

    // Forward the Supabase-generated OTP to MSG91 for SMS delivery
    const msg91Payload = {
      template_id: MSG91_TEMPLATE_ID,
      mobile: mobile,
      authkey: MSG91_AUTHKEY,
      otp: otp,
    };

    console.log("otp-handler: Calling MSG91", { phone });

    const msg91Response = await fetch("https://control.msg91.com/api/v5/otp", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(msg91Payload),
    });

    const msg91Data = await msg91Response.json();
    console.log("otp-handler: MSG91 response", {
      status: msg91Response.status,
      data: msg91Data,
    });

    // MSG91 can return HTTP 200 but with type:"error" in the body
    if (!msg91Response.ok || msg91Data?.type === "error") {
      console.error("otp-handler: MSG91 error", msg91Data);
      return new Response(
        JSON.stringify({ error: msg91Data?.message ?? "Failed to send SMS" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Supabase Auth Hook requires an empty JSON object on success
    return new Response(JSON.stringify({}), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("otp-handler: Unexpected error", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
