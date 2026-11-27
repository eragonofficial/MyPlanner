import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const TELEGRAM_BOT_TOKEN =
  Deno.env.get('TELEGRAM_BOT_TOKEN') || '9015300127:AAEPfRC_zVutbRXX7-7GSlhh2MrdqlN04z8';

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function generateSixDigitCode(): string {
  const array = new Uint32Array(1);
  crypto.getRandomValues(array);
  const num = 100000 + (array[0] % 900000);
  return String(num);
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: 'Server configuration error' }, 500);
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  try {
    const body = await req.json();

    // 1. Handle Telegram Bot Webhook (/start command)
    if (body?.message) {
      const message = body.message;
      const text = typeof message.text === 'string' ? message.text.trim() : '';
      const chatId = message.chat?.id;
      const from = message.from;

      if (!chatId || !from?.id) {
        return jsonResponse({ ok: true });
      }

      if (text.startsWith('/start')) {
        const telegramId = Number(from.id);
        const fullName = [from.first_name, from.last_name]
          .filter((part) => typeof part === 'string' && part.trim().length > 0)
          .join(' ')
          .trim() || null;
        const username = typeof from.username === 'string' ? from.username : null;

        // Clean up expired codes globally and any active code previously issued for this user
        await supabaseAdmin
          .from('telegram_otp_codes')
          .delete()
          .lt('expires_at', new Date().toISOString());

        await supabaseAdmin
          .from('telegram_otp_codes')
          .delete()
          .eq('telegram_id', telegramId);

        const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();
        let code = '';
        let insertSuccess = false;

        // Retry a few times in case of random 6-digit collision
        for (let attempt = 0; attempt < 5; attempt++) {
          code = generateSixDigitCode();
          const { error: insertError } = await supabaseAdmin
            .from('telegram_otp_codes')
            .insert({
              code,
              telegram_id: telegramId,
              full_name: fullName,
              username,
              expires_at: expiresAt,
            });

          if (!insertError) {
            insertSuccess = true;
            break;
          }
        }

        if (!insertSuccess) {
          return jsonResponse({ error: 'Could not generate OTP code' }, 500);
        }

        const telegramRes = await fetch(
          `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              chat_id: chatId,
              text: `My Planner kirish kodi: ${code}`,
            }),
          },
        );

        if (!telegramRes.ok) {
          const errText = await telegramRes.text();
          console.error('Telegram sendMessage failed:', errText);
          return jsonResponse({ error: 'Failed to send Telegram message' }, 500);
        }
      }

      return jsonResponse({ ok: true });
    }

    // 2. Handle OTP Verification from Flutter App
    if (body?.code !== undefined) {
      const code = String(body.code).trim();
      if (!/^\d{6}$/.test(code)) {
        return jsonResponse({ error: 'Invalid or expired code' }, 400);
      }

      const { data: row, error: fetchError } = await supabaseAdmin
        .from('telegram_otp_codes')
        .select('*')
        .eq('code', code)
        .maybeSingle();

      if (fetchError || !row) {
        return jsonResponse({ error: 'Invalid or expired code' }, 400);
      }

      if (new Date(row.expires_at).getTime() < Date.now()) {
        await supabaseAdmin.from('telegram_otp_codes').delete().eq('code', code);
        return jsonResponse({ error: 'Invalid or expired code' }, 400);
      }

      // Single-use OTP: delete immediately once verified
      await supabaseAdmin.from('telegram_otp_codes').delete().eq('code', code);

      const email = `tg_${row.telegram_id}@my-planner.uz`;
      const metadata = {
        telegram_id: row.telegram_id,
        full_name: row.full_name,
        username: row.username,
        auth_provider: 'telegram',
      };

      // Find or create user in Supabase Auth
      const { error: createError } = await supabaseAdmin.auth.admin.createUser({
        email,
        email_confirm: true,
        user_metadata: metadata,
      });

      if (
        createError &&
        !createError.message.toLowerCase().includes('already') &&
        !createError.message.toLowerCase().includes('exists')
      ) {
        console.error('createUser error:', createError.message);
        return jsonResponse({ error: createError.message }, 500);
      }

      // Generate magiclink token to mint a real Supabase session for the user
      const { data: linkData, error: linkError } =
        await supabaseAdmin.auth.admin.generateLink({
          type: 'magiclink',
          email,
        });

      if (linkError || !linkData?.user || !linkData?.properties?.hashed_token) {
        console.error('generateLink error:', linkError?.message);
        return jsonResponse(
          { error: linkError?.message || 'Failed to generate login session' },
          500,
        );
      }

      // Keep Telegram metadata fresh on every login
      await supabaseAdmin.auth.admin.updateUserById(linkData.user.id, {
        user_metadata: metadata,
      });

      const { data: verifyData, error: verifyError } =
        await supabaseAdmin.auth.verifyOtp({
          token_hash: linkData.properties.hashed_token,
          type: 'magiclink',
        });

      if (verifyError || !verifyData?.session) {
        console.error('verifyOtp error:', verifyError?.message);
        return jsonResponse(
          { error: verifyError?.message || 'Failed to create user session' },
          500,
        );
      }

      return jsonResponse({
        session: verifyData.session,
        user: verifyData.user,
        refresh_token: verifyData.session.refresh_token,
        access_token: verifyData.session.access_token,
      });
    }

    return jsonResponse({ error: 'Invalid request payload' }, 400);
  } catch (err) {
    console.error('telegram-otp error:', err);
    return jsonResponse({ error: 'Internal server error' }, 500);
  }
});
