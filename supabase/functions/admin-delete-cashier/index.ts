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

    const { data: callerProfile, error: callerProfileError } =
      await serviceClient
        .from("profiles")
        .select("id, role, store_owner_user_id")
        .eq("id", caller.id)
        .single();

    if (callerProfileError || !callerProfile) {
      return jsonResponse({ error: "Profil admin tidak ditemukan." }, 403);
    }

    if (callerProfile.role !== "admin") {
      return jsonResponse(
        { error: "Hanya admin owner yang bisa menghapus akun kasir." },
        403,
      );
    }

    const body = await req.json();
    const userId = String(body.user_id ?? "").trim();
    if (!userId) {
      return jsonResponse({ error: "Akun kasir belum dipilih." }, 400);
    }
    if (userId === caller.id) {
      return jsonResponse({ error: "Akun admin tidak bisa dihapus di sini." }, 400);
    }

    const storeOwnerUserId = callerProfile.store_owner_user_id ?? caller.id;
    const { data: cashierProfile, error: cashierProfileError } =
      await serviceClient
        .from("profiles")
        .select("id, role, store_owner_user_id")
        .eq("id", userId)
        .single();

    if (cashierProfileError || !cashierProfile) {
      return jsonResponse({ error: "Akun kasir tidak ditemukan." }, 404);
    }

    if (cashierProfile.role !== "kasir") {
      return jsonResponse({ error: "Hanya akun kasir yang bisa dihapus." }, 400);
    }

    if (cashierProfile.store_owner_user_id !== storeOwnerUserId) {
      return jsonResponse(
        { error: "Akun kasir bukan bagian dari toko admin ini." },
        403,
      );
    }

    const { error: deleteError } =
      await serviceClient.auth.admin.deleteUser(userId);

    if (deleteError) {
      return jsonResponse(
        { error: deleteError.message ?? "Akun kasir gagal dihapus." },
        400,
      );
    }

    return jsonResponse({ id: userId, deleted: true });
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
