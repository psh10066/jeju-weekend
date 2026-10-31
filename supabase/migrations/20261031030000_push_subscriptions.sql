-- 웹 푸시 구독: 기기(브라우저)마다 한 줄. notify 함수가 글쓴이 권한으로 읽어서 나머지 가족에게 보낸다
-- endpoint·키만으로는 알림을 보낼 수 없어서(VAPID 비밀키 필요) 가족끼리는 서로 보여도 된다
create table public.push_subscriptions (
  endpoint text primary key check (endpoint ~ '^https://'),
  user_id uuid not null references public.members on delete cascade,
  p256dh text not null,
  auth text not null,
  created_at timestamptz not null default now()
);
alter table public.push_subscriptions enable row level security;

create policy "push read" on public.push_subscriptions for select to authenticated using (public.is_member());
-- 만료된 구독(앱 삭제·권한 해제)은 보내다 실패한 쪽이 지운다
create policy "push delete" on public.push_subscriptions for delete to authenticated using (public.is_member());

-- 등록: 같은 기기를 다른 가족이 이어서 쓰면 그 사람 것으로 바꾼다
create function public.save_push(sub_endpoint text, sub_p256dh text, sub_auth text) returns void
language sql security definer set search_path = '' as $$
  insert into public.push_subscriptions (endpoint, user_id, p256dh, auth)
  select sub_endpoint, auth.uid(), sub_p256dh, sub_auth where public.is_member()
  on conflict (endpoint) do update set user_id = excluded.user_id, p256dh = excluded.p256dh, auth = excluded.auth;
$$;
revoke execute on function public.save_push from public, anon;
grant execute on function public.save_push to authenticated;
