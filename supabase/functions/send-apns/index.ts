import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

// Production APNs endpoint for App Store builds
const APNS_HOST = "https://api.push.apple.com";
// Sandbox APNs for debug/TestFlight builds:
// const APNS_HOST = "https://api.sandbox.push.apple.com";

serve(async (req) => {
  try {
    const {
      deviceToken,
      title,
      body,
    } = await req.json();

    // Load from Supabase Secrets
    const key = Deno.env.get("APNS_KEY_P8")!;
    const keyId = Deno.env.get("APNS_KEY_ID")!;               // 2MSPSWCM8
    const teamId = Deno.env.get("APNS_TEAM_ID")!;             // TUKQ9KBCN8
    const bundleId = Deno.env.get("APNS_BUNDLE_ID")!;         // com.sylonow.sylonowVendor

    // ----- Create JWT for APNs -----
    const header = { alg: "ES256", kid: keyId };
    const payload = { iss: teamId, iat: Math.floor(Date.now() / 1000) };

    const jwtHeader = btoa(JSON.stringify(header));
    const jwtPayload = btoa(JSON.stringify(payload));
    const signData = `${jwtHeader}.${jwtPayload}`;

    const cryptoKey = await crypto.subtle.importKey(
      "pkcs8",
      decodePEM(key),
      { name: "ECDSA", namedCurve: "P-256" },
      false,
      ["sign"]
    );

    const signature = await crypto.subtle.sign(
      { name: "ECDSA", hash: "SHA-256" },
      cryptoKey,
      new TextEncoder().encode(signData)
    );

    const jwt = `${signData}.${btoa(String.fromCharCode(...new Uint8Array(signature)))}`;

    // ----- APNs Notification Payload -----
    const notification = {
      aps: {
        alert: { title, body },
        sound: "default",
      },
    };

    // ----- Send to APNs -----
    const response = await fetch(`${APNS_HOST}/3/device/${deviceToken}`, {
      method: "POST",
      headers: {
        authorization: `bearer ${jwt}`,
        "apns-topic": bundleId,
        "content-type": "application/json",
      },
      body: JSON.stringify(notification),
    });

    const result = await response.text();

    return new Response(JSON.stringify({ ok: true, apns: result }), {
      headers: { "Content-Type": "application/json" },
    });

  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
});

function decodePEM(pem: string) {
  const contents = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");
  return decodeBase64(contents);
}

function decodeBase64(str: string) {
  return Uint8Array.from(atob(str), (c) => c.charCodeAt(0));
}
