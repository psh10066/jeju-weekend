-- 같은 장소에 같은 사람이 글을 여러 번 올려도 된다
drop index public.reviews_one_per_place;

-- 배포 직전 화면(예전 코드)이 링크만으로 다시 만든 중복 방문 기록을 원래 기록으로 합친다
update public.reviews set visit_id = 39 where visit_id = 47; -- 김녕빵집
update public.reviews set visit_id = 40 where visit_id = 46; -- 김녕해변
delete from public.visits where id in (46, 47) and not exists (select 1 from public.reviews r where r.visit_id in (46, 47));

-- 계획 장소 기록은 '요일|칸 제목|링크' 형식만 받는다 (예전 코드가 열린 화면이 또 중복을 만들지 못하게)
alter table public.visits add constraint visits_plan_ref_format check (plan_ref is null or plan_ref like '%|%|%');
