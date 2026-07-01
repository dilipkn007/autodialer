import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
  try {
    const { token } = await req.json()
    if (!token || typeof token !== "string") {
      return new Response(JSON.stringify({ error: "Token is required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      })
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    )

    // Validate token — only check revoked and expiration
    const { data: tokenData, error: tokenError } = await supabase
      .from("access_token")
      .select("id, contact_id, mobile_number, expires_at, revoked, login_count")
      .eq("token", token.trim())
      .single()

    if (tokenError || !tokenData) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      })
    }

    if (tokenData.revoked) {
      return new Response(JSON.stringify({ error: "Token revoked" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      })
    }

    if (tokenData.expires_at && new Date(tokenData.expires_at) < new Date()) {
      return new Response(JSON.stringify({ error: "Token expired" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      })
    }

    // Normalise phone to E.164
    let phone = (tokenData.mobile_number as string).trim()
    if (!phone.startsWith("+")) {
      if (phone.length === 12 && phone.startsWith("91")) {
        phone = `+${phone}`
      } else if (phone.startsWith("0")) {
        phone = `+91${phone.substring(1)}`
      } else {
        phone = `+91${phone}`
      }
    }

    // Look up the contact
    const { data: contact } = await supabase
      .from("contact")
      .select("id, name, role, email")
      .eq("id", tokenData.contact_id)
      .maybeSingle()

    if (!contact) {
      return new Response(JSON.stringify({ error: "Contact not found" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      })
    }

    const otpPassword = crypto.randomUUID().replace(/-/g, "").substring(0, 24)

    // Check if auth user exists (contact.id matches auth.uid from OTP registration)
    const { data: existingUser } = await supabase.auth.admin.getUserById(contact.id)

    if (existingUser?.user) {
      await supabase.auth.admin.updateUserById(existingUser.user.id, {
        password: otpPassword,
      })
    } else {
      // Create auth user with auto-generated ID
      const { data: newUser, error: createError } =
        await supabase.auth.admin.createUser({
          phone,
          phone_confirm: true,
          password: otpPassword,
          user_metadata: { name: contact.name },
        })

      if (createError || !newUser?.user) {
        return new Response(
          JSON.stringify({
            error: `Failed to create user: ${createError?.message ?? "Unknown"}`,
          }),
          { status: 500, headers: { "Content-Type": "application/json" } },
        )
      }

      // Create contact row matching the new auth user's ID
      const { error: upsertError } = await supabase.from("contact").upsert(
        {
          id: newUser.user.id,
          name: contact.name,
          mobile: phone,
          email: contact.email ?? null,
          role: contact.role ?? "ENABLER",
        },
        { onConflict: "id" },
      )

      if (upsertError) {
        return new Response(
          JSON.stringify({
            error: `Failed to create contact: ${upsertError.message}`,
          }),
          { status: 500, headers: { "Content-Type": "application/json" } },
        )
      }
    }

    // Track login — token remains valid until expiration
    const currentCount = (tokenData.login_count as number) ?? 0
    await supabase
      .from("access_token")
      .update({
        last_login_at: new Date().toISOString(),
        login_count: currentCount + 1,
      })
      .eq("id", tokenData.id)

    return new Response(
      JSON.stringify({ phone, password: otpPassword }),
      { headers: { "Content-Type": "application/json" } },
    )
  } catch (err) {
    return new Response(
      JSON.stringify({
        error: err instanceof Error ? err.message : "Unknown error",
      }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    )
  }
})
