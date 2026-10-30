-- 계획 밖 장소도 계획표 장소처럼: '추가'와 '다녀왔어요'를 따로. visited_at이 비어 있으면 추가만 한 곳
alter table public.visits alter column visited_at drop not null;

-- 다른 가족이 추가한 곳에도 다녀왔어요/취소를 누를 수 있게. 글이 달린 곳은 추가한 사람·관리자만
drop policy "visits move" on public.visits;
create policy "visits update" on public.visits for update to authenticated
  using (public.is_member() and (user_id = auth.uid() or public.is_admin()
    or not exists (select 1 from public.reviews r where r.visit_id = visits.id)));
