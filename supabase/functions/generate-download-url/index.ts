import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { compare } from 'https://deno.land/x/bcrypt@v0.4.1/mod.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );
  const authHeader = req.headers.get('Authorization') ?? '';
  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user } } = await userClient.auth.getUser();
  const { token, action = 'download', password } = await req.json();
  if (!user) return json({ error: 'Unauthorized' }, 401);

  const { data: link, error } = await supabase
    .from('share_links')
    .select(`
      id,
      token,
      access_type,
      password_hash,
      is_active,
      expired_at,
      can_view,
      can_download,
      file_id,
      files(
        id,
        user_id,
        original_name,
        file_type,
        file_size,
        file_path,
        status,
        download_count,
        is_encrypted,
        encryption_algorithm,
        encryption_key,
        encryption_nonce,
        encryption_mac
      )
    `)
    .eq('token', token)
    .maybeSingle();

  if (error) return json({ error: error.message }, 400);
  if (!link || !link.is_active) return json({ error: 'Link inactive' }, 404);
  if (link.expired_at && new Date(link.expired_at) < new Date()) {
    await logActivity(supabase, null, link.file_id, 'expired_link_access', 'failed');
    return json({ error: 'Link expired' }, 410);
  }

  const file = Array.isArray(link.files) ? link.files[0] : link.files;
  if (!file || file.status === 'deleted') return json({ error: 'File deleted' }, 410);
  const { data: owner } = await supabase
    .from('profiles')
    .select('email')
    .eq('id', file.user_id)
    .maybeSingle();

  const access = await validateAccess(supabase, link, file, user);
  if (!access.ok) {
    await logActivity(supabase, user?.id ?? null, link.file_id, 'access_denied', 'failed');
    return json({ error: 'Access denied' }, 403);
  }

  const metadata = {
    token: link.token,
    file_name: file.original_name,
    file_type: file.file_type,
    file_size: file.file_size,
    owner_email: owner?.email ?? null,
    access_type: link.access_type,
    can_view: link.can_view ?? true,
    can_download: link.can_download ?? true,
    requires_password: link.access_type === 'protected',
    is_active: link.is_active,
    expired_at: link.expired_at,
    is_encrypted: file.is_encrypted ?? false,
    encryption_algorithm: file.encryption_algorithm ?? null,
  };

  if (action === 'metadata') return json(metadata);
  if (action === 'view' && metadata.can_view === false) {
    return json({ error: 'View disabled' }, 403);
  }
  if (action === 'download' && metadata.can_download === false) {
    return json({ error: 'Download disabled' }, 403);
  }
  if (link.access_type === 'protected') {
    const verified = await verifyPassword(link.password_hash, password);
    if (!verified) {
      await logActivity(supabase, user?.id ?? null, link.file_id, 'wrong_password', 'failed');
      return json({ error: 'Wrong password' }, 403);
    }
  }

  const { data: signed, error: signedError } = await supabase.storage
    .from('secure-files')
    .createSignedUrl(file.file_path, 120);
  if (signedError) return json({ error: signedError.message }, 400);

  if (action === 'download') {
    await supabase
      .from('files')
      .update({ download_count: (file.download_count ?? 0) + 1 })
      .eq('id', link.file_id);
    await logActivity(supabase, user?.id ?? null, link.file_id, 'download_file', 'success');
  }

  return json({
    ...metadata,
    signed_url: signed.signedUrl,
    encryption_key: file.encryption_key ?? null,
    encryption_nonce: file.encryption_nonce ?? null,
    encryption_mac: file.encryption_mac ?? null,
  });
});

async function validateAccess(supabase: ReturnType<typeof createClient>, link: any, file: any, user: any) {
  if (link.access_type === 'public' || link.access_type === 'protected') {
    return { ok: true };
  }
  if (link.access_type === 'private') {
    return { ok: file.user_id === user?.id };
  }
  if (link.access_type === 'specific_user') {
    const { data: recipient } = await supabase
      .from('share_recipients')
      .select('id,can_view,can_download')
      .eq('share_link_id', link.id)
      .or(`user_id.eq.${user?.id ?? '00000000-0000-0000-0000-000000000000'},email.eq.${user?.email ?? ''}`)
      .maybeSingle();
    if (!recipient) return { ok: false };
    link.can_view = recipient.can_view ?? link.can_view;
    link.can_download = recipient.can_download ?? link.can_download;
    return { ok: true };
  }
  return { ok: false };
}

async function verifyPassword(passwordHash: string | null, password: string | null) {
  if (!passwordHash || !password) return false;
  if (passwordHash.startsWith('$2')) {
    return await compare(password, passwordHash);
  }
  return await sha256(password) === passwordHash;
}

async function sha256(input: string) {
  const bytes = new TextEncoder().encode(input);
  const hash = await crypto.subtle.digest('SHA-256', bytes);
  return Array.from(new Uint8Array(hash))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

async function logActivity(
  supabase: ReturnType<typeof createClient>,
  userId: string | null,
  fileId: string | null,
  action: string,
  status: string,
) {
  await supabase.from('activity_logs').insert({
    user_id: userId,
    file_id: fileId,
    action,
    status,
    platform: 'web',
  });
}

function json(body: Record<string, unknown>, status = 200) {
  return Response.json(body, { status, headers: corsHeaders });
}
