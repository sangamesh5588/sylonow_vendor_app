import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const MSG91_AUTHKEY = Deno.env.get("MSG91_AUTH_TOKEN") || Deno.env.get("MSG91_AUTHKEY") || "";

const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

Deno.serve(async (req) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Content-Type": "application/json",
  };

  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders, status: 204 });
  }

  try {
    const { msg91_access_token, phone } = await req.json();

    if (!msg91_access_token || !phone) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), { status: 400, headers: corsHeaders });
    }

    // 1. Verify MSG91 Token
    const verifyResp = await fetch("https://control.msg91.com/api/v5/widget/verifyAccessToken", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ "authkey": MSG91_AUTHKEY, "access-token": msg91_access_token }),
    });
    const verifyData = await verifyResp.json();

    if (verifyData?.type !== "success") {
      console.error("msg91-auth: MSG91 Reject", verifyData);
      return new Response(JSON.stringify({ error: "Invalid MSG91 token", details: verifyData?.message }), { status: 401, headers: corsHeaders });
    }

    // 2. Find or Create User (PAGINATED EXHAUSTIVE SEARCH)
    const normalizedPhone = phone.startsWith("+") ? phone : `+${phone}`;
    const cleanPhone = normalizedPhone.replace(/\D/g, "");
    let userId: string | null = null;

    console.log(`msg91-auth: Processing lookup for ${normalizedPhone}`);

    // FUNCTION: Paginated search through ALL users
    const findUserPaginating = async () => {
      let page = 1;
      const perPage = 1000; // Max per page for performance
      
      while (true) {
        console.log(`msg91-auth: Searching page ${page}...`);
        const { data: listData, error: listErr } = await supabaseAdmin.auth.admin.listUsers({
          page: page,
          perPage: perPage,
        });

        if (listErr) {
          console.error("msg91-auth: listUsers error on page " + page, listErr);
          break;
        }

        const users = listData.users;
        if (!users || users.length === 0) break;

        const found = users.find(u => {
          if (!u.phone) return false;
          const uClean = u.phone.replace(/\D/g, "");
          return uClean === cleanPhone || uClean.endsWith(cleanPhone) || cleanPhone.endsWith(uClean);
        });

        if (found) return found.id;
        
        if (users.length < perPage) break; // Last page
        page++;
      }
      return null;
    };

    userId = await findUserPaginating();

    if (userId) {
      console.log("msg91-auth: Found existing user", userId);
    } else {
      // Attempt Creation
      console.log("msg91-auth: Creating new user...");
      const { data: createData, error: createErr } = await supabaseAdmin.auth.admin.createUser({
        phone: normalizedPhone,
        phone_confirm: true,
        user_metadata: { app_type: "vendor" },
      });

      if (createErr) {
        if (createErr.status === 422 || createErr.message?.includes("already registered")) {
          console.log("msg91-auth: Create reported phone_exists. Doing one final emergency lookup...");
          userId = await findUserPaginating(); // Try once more in case of race condition
        } else {
          throw createErr;
        }
      } else {
        userId = createData.user.id;
        console.log("msg91-auth: Created new user successfully", userId);
      }
    }

    if (!userId) throw new Error("Could not identify User ID after exhaustive paginated search.");

    // 3. Create Session using signInWithPassword simulation
    // Update the user to have a temporary password, then sign them in
    const tempPassword = crypto.randomUUID();

    // Update user with password
    await supabaseAdmin.auth.admin.updateUserById(userId, {
      password: tempPassword,
    });

    // Sign in with the temporary password to get a valid session
    const { data: signInData, error: signInError } = await supabaseAdmin.auth.signInWithPassword({
      phone: normalizedPhone,
      password: tempPassword,
    });

    if (signInError || !signInData.session) {
      console.error("msg91-auth: Failed to create session", signInError);
      throw new Error("Failed to create session");
    }

    const refreshToken = signInData.session.refresh_token;

    // 4. Sync Tables
    await supabaseAdmin.from("user_profiles").upsert({ auth_user_id: userId, app_type: "vendor", phone_number: normalizedPhone }, { onConflict: "auth_user_id" });
    await supabaseAdmin.from("vendors").upsert({ auth_user_id: userId, phone: normalizedPhone }, { onConflict: "auth_user_id" });

    return new Response(JSON.stringify({ refresh_token: refreshToken, user: { id: userId, phone: normalizedPhone } }), { status: 200, headers: corsHeaders });

  } catch (err) {
    console.error("msg91-auth: FATAL", err);
    return new Response(JSON.stringify({ error: "Auth failed", details: String(err) }), { status: 500, headers: corsHeaders });
  }
});
