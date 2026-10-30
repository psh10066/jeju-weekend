-- 다녀온 시각(30분 단위로 입력) + 글 없는 방문 기록은 가족 누구나 취소/삭제
alter table public.visits add column visited_at timestamptz not null default now();
update public.visits set visited_at = created_at;
grant update (visited_at, visited_on) on public.visits to authenticated;

-- 글이 달린 기록은 다른 가족 글까지 지워지니 관리자만
drop policy "visits delete" on public.visits;
create policy "visits delete" on public.visits for delete to authenticated
  using (public.is_member() and (public.is_admin()
    or not exists (select 1 from public.reviews r where r.visit_id = visits.id)));
