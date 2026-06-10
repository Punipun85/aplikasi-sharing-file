import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { hash } from 'https://deno.land/x/bcrypt@v0.4.1/mod.ts';

serve(async (req) => {
  const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const authHeader = req.headers.get('Authorization') ?? '';
  const userClient = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 });

  const { file_id, access_type, password, expired_at, recipients = [] } = await req.json();
  const token = crypto.randomUUID().replaceAll('-', '') + crypto.randomUUID().slice(0, 8);
  const password_hash = access_type === 'protected' && password ? await hash(password) : null;

  const { data, error } = await supabase.from('share_links').insert({
    file_id,
    access_type,
    token,
    password_hash,
    expired_at,
    created_by: user.id,
  }).select().single();
  if (error) return Response.json({ error: error.message }, { status: 400 });

  if (recipients.length > 0) {
    await supabase.from('share_recipients').insert(recipients.map((email: string) => ({ share_link_id: data.id, email })));
  }

  await supabase.from('activity_logs').insert({ user_id: user.id, file_id, action: 'create_share_link', status: 'success', platform: 'web' });
  return Response.json({ data });
});
