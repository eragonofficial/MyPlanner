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

function normalizePhoneE164(raw?: string | null): string | null {
  if (!raw) return null;
  const digits = raw.replace(/\D/g, '');
  if (!digits) return null;
  if (digits.length === 9) {
    return `+998${digits}`;
  }
  return `+${digits}`;
}

function generateSixDigitCode(): string {
  const array = new Uint32Array(1);
  crypto.getRandomValues(array);
  const num = 100000 + (array[0] % 900000);
  return String(num);
}

async function sendTelegramMessage(
  chatId: number | string,
  text: string,
  replyMarkup?: Record<string, unknown>,
): Promise<boolean> {
  try {
    const payload: Record<string, unknown> = {
      chat_id: chatId,
      text,
    };
    if (replyMarkup) {
      payload.reply_markup = replyMarkup;
    }

    const res = await fetch(
      `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      },
    );
    if (!res.ok) {
      const errText = await res.text();
      console.error('Telegram sendMessage failed:', res.status, errText);
    }
    return res.ok;
  } catch (err) {
    console.error('Telegram sendMessage fetch exception:', err);
    return false;
  }
}

async function insertOtpWithSchemaFallback(
  supabaseAdmin: ReturnType<typeof createClient>,
  payload: {
    code: string;
    telegram_id: number;
    full_name: string | null;
    username: string | null;
    phone_number: string | null;
    expires_at: string;
  },
): Promise<{ ok: boolean; isDuplicate: boolean }> {
  const primaryRow: Record<string, unknown> = {
    code: payload.code,
    telegram_id: payload.telegram_id,
    full_name: payload.full_name,
    username: payload.username,
    expires_at: payload.expires_at,
  };
  if (payload.phone_number) {
    primaryRow.phone_number = payload.phone_number;
  }

  const { error: firstErr } = await supabaseAdmin
    .from('telegram_otp_codes')
    .insert(primaryRow);

  if (!firstErr) {
    return { ok: true, isDuplicate: false };
  }

  // Unique code collision -> caller can retry with a fresh code
  if (firstErr.code === '23505') {
    return { ok: false, isDuplicate: true };
  }

  console.error('telegram_otp_codes primary insert error:', firstErr.message);

  // Fallback without phone_number (if user_profiles_linking.sql has not been applied yet)
  const fallbackRowWithoutPhone = {
    code: payload.code,
    telegram_id: payload.telegram_id,
    full_name: payload.full_name,
    username: payload.username,
    expires_at: payload.expires_at,
  };
  const { error: secondErr } = await supabaseAdmin
    .from('telegram_otp_codes')
    .insert(fallbackRowWithoutPhone);

  if (!secondErr) {
    return { ok: true, isDuplicate: false };
  }
  if (secondErr.code === '23505') {
    return { ok: false, isDuplicate: true };
  }
  console.error('telegram_otp_codes secondary insert error:', secondErr.message);

  // Minimal fallback containing only required columns
  const minimalRow = {
    code: payload.code,
    telegram_id: payload.telegram_id,
    expires_at: payload.expires_at,
  };
  const { error: thirdErr } = await supabaseAdmin
    .from('telegram_otp_codes')
    .insert(minimalRow);

  if (!thirdErr) {
    return { ok: true, isDuplicate: false };
  }
  console.error('telegram_otp_codes minimal insert error:', thirdErr.message);
  return { ok: false, isDuplicate: thirdErr.code === '23505' };
}

async function createUniqueOtpCode(
  supabaseAdmin: ReturnType<typeof createClient>,
  rowData: {
    telegram_id: number;
    full_name: string | null;
    username: string | null;
    phone_number: string | null;
  },
): Promise<string | null> {
  // Cleanup queries wrapped safely so transient failures never abort code generation
  try {
    await supabaseAdmin
      .from('telegram_otp_codes')
      .delete()
      .lt('expires_at', new Date().toISOString());
  } catch (cleanupErr) {
    console.error('Expired OTP cleanup warning:', cleanupErr);
  }

  try {
    await supabaseAdmin
      .from('telegram_otp_codes')
      .delete()
      .eq('telegram_id', rowData.telegram_id);
  } catch (cleanupUserErr) {
    console.error('Previous user OTP cleanup warning:', cleanupUserErr);
  }

  const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

  for (let attempt = 0; attempt < 5; attempt++) {
    const code = generateSixDigitCode();
    const res = await insertOtpWithSchemaFallback(supabaseAdmin, {
      code,
      telegram_id: rowData.telegram_id,
      full_name: rowData.full_name,
      username: rowData.username,
      phone_number: rowData.phone_number,
      expires_at: expiresAt,
    });
    if (res.ok) return code;
    if (!res.isDuplicate) break;
  }

  return null;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const supabaseUrl =
    Deno.env.get('SUPABASE_URL') ?? 'https://mrwwmackzhsscsozcoay.supabase.co';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

  let body: Record<string, any> = {};
  try {
    body = await req.json();
  } catch (parseErr) {
    console.error('Failed to parse JSON body:', parseErr);
    return jsonResponse({ ok: true, error: 'Invalid JSON' }, 200);
  }

  // 1. Telegram Bot Webhook Updates MUST ALWAYS return HTTP 200 OK
  if (body?.message || body?.edited_message || body?.callback_query) {
    try {
      const message = body.message ?? body.edited_message;
      if (!message) {
        return jsonResponse({ ok: true }, 200);
      }

      const text = typeof message.text === 'string' ? message.text.trim() : '';
      const chatId = message.chat?.id;
      const from = message.from;

      if (!chatId || !from?.id) {
        return jsonResponse({ ok: true }, 200);
      }

      if (!supabaseUrl || !serviceRoleKey) {
        console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in Edge Function env');
        await sendTelegramMessage(
          chatId,
          'Tizim vaqtinchalik texnik sozlanmoqda. Birozdan so‘ng qayta urinib ko‘ring.',
        );
        return jsonResponse({ ok: true }, 200);
      }

      const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      });

      const telegramId = Number(from.id);
      const fullName =
        [from.first_name, from.last_name]
          .filter((part) => typeof part === 'string' && part.trim().length > 0)
          .join(' ')
          .trim() || null;
      const username = typeof from.username === 'string' ? from.username : null;

      // 1a. Handle shared phone number via Contact button
      if (message.contact?.phone_number) {
        const contactUserId = message.contact.user_id ?? from.id;
        if (Number(contactUserId) !== telegramId) {
          await sendTelegramMessage(
            chatId,
            "Iltimos, o'zingizning telefon raqamingizni ulashing.",
          );
          return jsonResponse({ ok: true }, 200);
        }

        const phone = normalizePhoneE164(String(message.contact.phone_number));
        let activeCode: string | null = null;

        try {
          const { data: existingOtp } = await supabaseAdmin
            .from('telegram_otp_codes')
            .select('code, expires_at')
            .eq('telegram_id', telegramId)
            .gt('expires_at', new Date().toISOString())
            .maybeSingle();

          if (existingOtp?.code) {
            activeCode = existingOtp.code;
            const { error: updErr } = await supabaseAdmin
              .from('telegram_otp_codes')
              .update({
                phone_number: phone,
                full_name: fullName,
                username,
              })
              .eq('code', activeCode);
            if (updErr) {
              console.error('OTP phone update warning:', updErr.message);
            }
          }
        } catch (lookupErr) {
          console.error('Existing OTP lookup error:', lookupErr);
        }

        if (!activeCode) {
          activeCode = await createUniqueOtpCode(supabaseAdmin, {
            telegram_id: telegramId,
            full_name: fullName,
            username,
            phone_number: phone,
          });
        }

        // Safely pre-link profile if phone matches an existing user
        if (phone) {
          try {
            const { data: matchedByPhone } = await supabaseAdmin
              .from('profiles')
              .select('id, telegram_id')
              .eq('phone_number', phone)
              .maybeSingle();

            if (matchedByPhone?.id && !matchedByPhone.telegram_id) {
              await supabaseAdmin
                .from('profiles')
                .update({
                  telegram_id: telegramId,
                  telegram_username: username,
                })
                .eq('id', matchedByPhone.id);
            }
          } catch (profileErr) {
            console.error('Profiles phone match skipped:', profileErr);
          }
        }

        if (activeCode) {
          await sendTelegramMessage(
            chatId,
            `✅ Raqam tasdiqlandi (${phone ?? ''})!\nMy Planner kirish kodi: ${activeCode}`,
            { remove_keyboard: true },
          );
        } else {
          await sendTelegramMessage(
            chatId,
            'Kodni yaratishda xatolik yuz berdi. Iltimos /start buyrug‘ini qayta yuboring.',
            { remove_keyboard: true },
          );
        }

        return jsonResponse({ ok: true }, 200);
      }

      // 1b. Handle /start command
      if (text.startsWith('/start')) {
        let existingPhone: string | null = null;
        try {
          const { data: existingProfile } = await supabaseAdmin
            .from('profiles')
            .select('phone_number')
            .eq('telegram_id', telegramId)
            .maybeSingle();
          existingPhone = existingProfile?.phone_number ?? null;
        } catch (profileErr) {
          console.error('Profiles pre-lookup skipped:', profileErr);
        }

        const code = await createUniqueOtpCode(supabaseAdmin, {
          telegram_id: telegramId,
          full_name: fullName,
          username,
          phone_number: existingPhone,
        });

        if (code) {
          await sendTelegramMessage(
            chatId,
            `My Planner kirish kodi: ${code}\n\n📱 Email yoki Google hisobingizni telefon raqam orqali ulash uchun quyidagi tugmani bosing:`,
            {
              keyboard: [
                [
                  {
                    text: '📱 Raqamni ulashish / Share Phone Number',
                    request_contact: true,
                  },
                ],
              ],
              resize_keyboard: true,
              one_time_keyboard: true,
            },
          );
        } else {
          await sendTelegramMessage(
            chatId,
            'Kirish kodini yaratishda xatolik yuz berdi. Iltimos birozdan so‘ng /start buyrug‘ini qayta yuboring.',
          );
        }
      }
    } catch (webhookErr) {
      console.error('Unhandled Telegram webhook error:', webhookErr);
    }

    // Never return 500 to Telegram webhook updates
    return jsonResponse({ ok: true }, 200);
  }

  // 2. Handle OTP Verification from Flutter App
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

      if (fetchError) {
        console.error('OTP select error:', fetchError.message);
        return jsonResponse({ error: 'Failed to verify OTP code' }, 500);
      }

      if (!row) {
        return jsonResponse({ error: 'Invalid or expired code' }, 400);
      }

      if (new Date(row.expires_at).getTime() < Date.now()) {
        await supabaseAdmin.from('telegram_otp_codes').delete().eq('code', code);
        return jsonResponse({ error: 'Invalid or expired code' }, 400);
      }

      // Single-use OTP: delete immediately once verified
      await supabaseAdmin.from('telegram_otp_codes').delete().eq('code', code);

      const normalizedPhone = normalizePhoneE164(
        (row.phone_number as string | null) ?? (body.phone_number as string | null),
      );

      // Mode A: Link Telegram directly to an already-signed-in user
      if (body.link_user_id) {
        const authHeader = req.headers.get('authorization') ?? '';
        const jwt = authHeader.replace(/^Bearer\s+/i, '').trim();
        if (!jwt) {
          return jsonResponse({ error: 'Unauthorized' }, 401);
        }

        const { data: authData, error: authErr } =
          await supabaseAdmin.auth.getUser(jwt);
        if (authErr || !authData?.user || authData.user.id !== body.link_user_id) {
          return jsonResponse({ error: 'Unauthorized user session' }, 401);
        }

        const callerUser = authData.user;
        try {
          const { data: otherTelegramOwner } = await supabaseAdmin
            .from('profiles')
            .select('id')
            .eq('telegram_id', row.telegram_id)
            .neq('id', callerUser.id)
            .maybeSingle();

          if (otherTelegramOwner?.id) {
            return jsonResponse(
              {
                error:
                  'This Telegram account is already linked to another My Planner account.',
              },
              409,
            );
          }
        } catch (checkErr) {
          console.error('Profiles check error:', checkErr);
        }

        let resolvedPhone: string | null = normalizedPhone;
        let resolvedName: string | null =
          (callerUser.user_metadata?.full_name as string | undefined) ??
          (row.full_name as string | null) ??
          null;

        try {
          const { data: callerProfile } = await supabaseAdmin
            .from('profiles')
            .select('full_name, phone_number, email')
            .eq('id', callerUser.id)
            .maybeSingle();

          resolvedPhone = normalizedPhone ?? callerProfile?.phone_number ?? null;
          resolvedName = callerProfile?.full_name ?? resolvedName;

          const { error: upsertErr } = await supabaseAdmin.from('profiles').upsert({
            id: callerUser.id,
            email: callerProfile?.email ?? callerUser.email ?? null,
            full_name: resolvedName,
            phone_number: resolvedPhone,
            telegram_id: row.telegram_id,
            telegram_username: row.username ?? null,
          });

          if (upsertErr) {
            console.error('Profiles upsert warning on link:', upsertErr.message);
          }
        } catch (profileUpsertErr) {
          console.error('Profiles upsert skipped on link:', profileUpsertErr);
        }

        const updatedMeta = {
          ...(callerUser.user_metadata ?? {}),
          telegram_id: row.telegram_id,
          username: row.username ?? null,
          telegram_username: row.username ?? null,
          ...(resolvedName ? { full_name: resolvedName } : {}),
          ...(resolvedPhone ? { phone_number: resolvedPhone } : {}),
        };

        await supabaseAdmin.auth.admin.updateUserById(callerUser.id, {
          user_metadata: updatedMeta,
        });

        return jsonResponse({
          linked: true,
          telegram_id: row.telegram_id,
          telegram_username: row.username ?? null,
          phone_number: resolvedPhone,
        });
      }

      // Mode B: Smart Profile Lookup by telegram_id OR normalized phone_number
      let matchedProfile: {
        id: string;
        email: string | null;
        full_name: string | null;
        phone_number: string | null;
        telegram_id: number | null;
        telegram_username: string | null;
      } | null = null;

      try {
        const { data: byTelegram } = await supabaseAdmin
          .from('profiles')
          .select('id, email, full_name, phone_number, telegram_id, telegram_username')
          .eq('telegram_id', row.telegram_id)
          .maybeSingle();

        if (byTelegram?.id) {
          matchedProfile = byTelegram;
        } else if (normalizedPhone) {
          const { data: byPhone } = await supabaseAdmin
            .from('profiles')
            .select('id, email, full_name, phone_number, telegram_id, telegram_username')
            .eq('phone_number', normalizedPhone)
            .maybeSingle();

          if (byPhone?.id) {
            matchedProfile = byPhone;
          }
        }
      } catch (profileLookupErr) {
        console.error('Smart profile lookup skipped:', profileLookupErr);
      }

      if (matchedProfile) {
        const { data: targetUserRes, error: targetUserErr } =
          await supabaseAdmin.auth.admin.getUserById(matchedProfile.id);

        if (targetUserErr || !targetUserRes?.user) {
          return jsonResponse(
            { error: targetUserErr?.message || 'Matched account not found' },
            500,
          );
        }

        const existingUser = targetUserRes.user;
        const targetEmail =
          existingUser.email ||
          matchedProfile.email ||
          `tg_${row.telegram_id}@my-planner.uz`;
        const mergedPhone = normalizedPhone ?? matchedProfile.phone_number ?? null;
        const mergedFullName =
          matchedProfile.full_name ||
          (existingUser.user_metadata?.full_name as string | undefined) ||
          (row.full_name as string | null) ||
          null;
        const mergedMeta = {
          ...(existingUser.user_metadata ?? {}),
          telegram_id: row.telegram_id,
          username: row.username ?? matchedProfile.telegram_username ?? null,
          telegram_username: row.username ?? matchedProfile.telegram_username ?? null,
          ...(mergedFullName ? { full_name: mergedFullName } : {}),
          ...(mergedPhone ? { phone_number: mergedPhone } : {}),
        };

        try {
          await supabaseAdmin.from('profiles').upsert({
            id: existingUser.id,
            email: targetEmail,
            full_name: mergedFullName,
            phone_number: mergedPhone,
            telegram_id: row.telegram_id,
            telegram_username:
              row.username ?? matchedProfile.telegram_username ?? null,
          });
        } catch (upsertErr) {
          console.error('Profile upsert skipped on existing login:', upsertErr);
        }

        await supabaseAdmin.auth.admin.updateUserById(existingUser.id, {
          user_metadata: mergedMeta,
        });

        const { data: linkData, error: linkError } =
          await supabaseAdmin.auth.admin.generateLink({
            type: 'magiclink',
            email: targetEmail,
          });

        if (linkError || !linkData?.properties?.hashed_token) {
          return jsonResponse(
            { error: linkError?.message || 'Failed to generate login session' },
            500,
          );
        }

        const { data: verifyData, error: verifyError } =
          await supabaseAdmin.auth.verifyOtp({
            token_hash: linkData.properties.hashed_token,
            type: 'magiclink',
          });

        if (verifyError || !verifyData?.session) {
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
          linked_existing_account: true,
        });
      }

      // No matching profile found: create/load deterministic Telegram Auth user
      const fallbackEmail = `tg_${row.telegram_id}@my-planner.uz`;
      const newMetadata = {
        telegram_id: row.telegram_id,
        full_name: row.full_name,
        username: row.username,
        telegram_username: row.username,
        ...(normalizedPhone ? { phone_number: normalizedPhone } : {}),
        auth_provider: 'telegram',
      };

      const { error: createError } = await supabaseAdmin.auth.admin.createUser({
        email: fallbackEmail,
        email_confirm: true,
        user_metadata: newMetadata,
      });

      if (
        createError &&
        !createError.message.toLowerCase().includes('already') &&
        !createError.message.toLowerCase().includes('exists')
      ) {
        console.error('createUser error:', createError.message);
        return jsonResponse({ error: createError.message }, 500);
      }

      const { data: linkData, error: linkError } =
        await supabaseAdmin.auth.admin.generateLink({
          type: 'magiclink',
          email: fallbackEmail,
        });

      if (linkError || !linkData?.user || !linkData?.properties?.hashed_token) {
        console.error('generateLink error:', linkError?.message);
        return jsonResponse(
          { error: linkError?.message || 'Failed to generate login session' },
          500,
        );
      }

      await supabaseAdmin.auth.admin.updateUserById(linkData.user.id, {
        user_metadata: newMetadata,
      });

      try {
        await supabaseAdmin.from('profiles').upsert({
          id: linkData.user.id,
          email: fallbackEmail,
          full_name: row.full_name ?? null,
          phone_number: normalizedPhone,
          telegram_id: row.telegram_id,
          telegram_username: row.username ?? null,
        });
      } catch (profileUpsertErr) {
        console.error('Profiles upsert skipped on new Telegram login:', profileUpsertErr);
      }

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
        linked_existing_account: false,
      });
    }

    return jsonResponse({ error: 'Invalid request payload' }, 400);
  } catch (err) {
    console.error('telegram-otp error:', err);
    return jsonResponse({ error: 'Internal server error' }, 500);
  }
});
