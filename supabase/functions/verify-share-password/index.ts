import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { compare } from 'https://deno.land/x/bcrypt@v0.4.1/mod.ts';

serve(async (req) => {
  const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { token, password } = await req.json();
  const { data: link } = await supabase.from('share_links').select('id,file_id,password_hash,is_active,expired_at').eq('token', token).maybeSingle();

  if (!link || !link.is_active) return Response.json({ ok: false, error: 'Link inactive' }, { status: 404 });
  if (link.expired_at && new Date(link.expired_at) < new Date()) return Response.json({ ok: false, error: 'Link expired' }, { status: 410 });

  const ok = link.password_hash ? await compare(password, link.password_hash) : false;
  await supabase.from('activity_logs').insert({ file_id: link.file_id, action: ok ? 'verify_password' : 'wrong_password', status: ok ? 'success' : 'failed', platform: 'web' });
  return Response.json({ ok });
});
