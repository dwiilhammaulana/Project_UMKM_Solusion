import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const supabaseUrl = requireEnv("SUPABASE_URL");
    const anonKey = requireEnv("SUPABASE_ANON_KEY");
    const serviceRoleKey = requireEnv("SUPABASE_SERVICE_ROLE_KEY");
    const authorization = req.headers.get("Authorization");

    if (!authorization) {
      return jsonResponse({ error: "Sesi admin tidak ditemukan." }, 401);
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
    });
    const serviceClient = createClient(supabaseUrl, serviceRoleKey);

    const {
      data: { user: caller },
      error: callerError,
    } = await userClient.auth.getUser();

    if (callerError || !caller) {
      return jsonResponse({ error: "Sesi admin tidak valid." }, 401);
    }

    const { data: callerProfile, error: profileError } = await serviceClient
      .from("profiles")
      .select("id, role, store_owner_user_id")
      .eq("id", caller.id)
      .single();

    if (profileError || !callerProfile) {
      return jsonResponse({ error: "Profil admin tidak ditemukan." }, 403);
    }

    if (callerProfile.role !== "admin") {
      return jsonResponse(
        { error: "Hanya admin owner yang bisa membuat akun kasir." },
        403,
      );
    }

    const body = await req.json();
    const email = String(body.email ?? "").trim().toLowerCase();
    const password = String(body.password ?? "");
    const fullName = String(body.full_name ?? "").trim();

    if (!email || !email.includes("@")) {
      return jsonResponse({ error: "Email kasir belum valid." }, 400);
    }
    if (password.length < 8) {
      return jsonResponse({ error: "Password minimal 8 karakter." }, 400);
    }
    if (!fullName) {
      return jsonResponse({ error: "Nama kasir wajib diisi." }, 400);
    }

    const storeOwnerUserId = callerProfile.store_owner_user_id ?? caller.id;
    const { data: created, error: createError } =
      await serviceClient.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: {
          full_name: fullName,
          role: "kasir",
          store_owner_user_id: storeOwnerUserId,
        },
      });

    if (createError || !created.user) {
      return jsonResponse(
        { error: createError?.message ?? "Akun kasir gagal dibuat." },
        400,
      );
    }

    const { error: upsertError } = await serviceClient.from("profiles").upsert({
      id: created.user.id,
      email,
      full_name: fullName,
      role: "kasir",
      store_owner_user_id: storeOwnerUserId,
    });

    if (upsertError) {
      return jsonResponse({ error: upsertError.message }, 400);
    }

    return jsonResponse({
      id: created.user.id,
      email,
      role: "kasir",
      store_owner_user_id: storeOwnerUserId,
    });
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : String(error) },
      500,
    );
  }
});

function requireEnv(name: string) {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`${name} belum tersedia di environment Supabase.`);
  }
  return value;
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
