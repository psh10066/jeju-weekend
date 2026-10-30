-- 추가한 장소의 한 줄 코멘트 (계획표 장소 설명처럼)
alter table public.visits add column note text check (length(note) <= 100);
grant update (note) on public.visits to authenticated;
