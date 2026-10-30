-- 계획 밖 장소를 계획표의 원하는 칸 다음에 끼워 넣기. null이면 '계획 밖' 칸
alter table public.visits add column after_ref text;
revoke update on public.visits from authenticated;
grant update (after_ref) on public.visits to authenticated;
create policy "visits move" on public.visits for update to authenticated
  using (public.is_member() and (user_id = auth.uid() or public.is_admin()));
