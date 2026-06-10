import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const authHeader = req.headers.get('Authorization') ?? '';
  const userClient = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user } } = await userClient.auth.getUser();
  const { token } = await req.json();

  const { data: link } = await supabase
    .from('share_links')
    .select('id,access_type,is_active,expired_at,file_id,files(id,user_id,file_path,status,download_count)')
    .eq('token', token)
    .maybeSingle();

  if (!link || !link.is_active) return Response.json({ error: 'Link inactive' }, { status: 404 });
  if (link.expired_at && new Date(link.expired_at) < new Date()) return Response.json({ error: 'Link expired' }, { status: 410 });
  if (link.files.status === 'deleted') return Response.json({ error: 'File deleted' }, { status: 410 });
  if (link.access_type === 'private' && link.files.user_id !== user?.id) return Response.json({ error: 'Access denied' }, { status: 403 });

  if (link.access_type === 'specific_user') {
    const { data: recipient } = await supabase
      .from('share_recipients')
      .select('id')
      .eq('share_link_id', link.id)
      .or(`user_id.eq.${user?.id ?? '00000000-0000-0000-0000-000000000000'},email.eq.${user?.email ?? ''}`)
      .maybeSingle();
    if (!recipient) return Response.json({ error: 'Access denied' }, { status: 403 });
  }

  const { data, error } = await supabase.storage.from('secure-files').createSignedUrl(link.files.file_path, 60);
  if (error) return Response.json({ error: error.message }, { status: 400 });

  await supabase.from('files').update({ download_count: link.files.download_count + 1 }).eq('id', link.file_id);
  await supabase.from('activity_logs').insert({ user_id: user?.id, file_id: link.file_id, action: 'download_file', status: 'success', platform: 'web' });
  return Response.json({ signed_url: data.signedUrl });
});
