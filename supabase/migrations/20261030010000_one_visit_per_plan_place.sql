-- 계획표 장소는 가족 공용 방문 기록 1개에 후기를 모은다
create unique index visits_plan_ref_key on public.visits (plan_ref) where plan_ref is not null;
