-- 같은 장소라도 계획표 칸(시기)이 다르면 다른 기록: plan_ref = 요일|칸 제목|링크
-- 그래서 계획 장소끼리는 place_url이 겹칠 수 있고, 링크 중복 막기는 추가한 장소에만
drop index public.visits_place_url_key;
create unique index visits_place_url_key on public.visits (place_url) where place_url is not null and plan_ref is null;
update public.visits set plan_ref = case plan_ref
  when 'https://map.naver.com/p/entry/place/11576965' then 'sat|제주공항|https://map.naver.com/p/entry/place/11576965'
  when 'https://naver.me/FVFkwbwp' then 'sat|신제주보말칼국수 제주본점|https://naver.me/FVFkwbwp'
  when 'https://naver.me/xBwHH9Be' then 'sat|김녕빵집 + 김녕해변|https://naver.me/xBwHH9Be'
  when 'https://map.naver.com/p/entry/place/13491485' then 'sat|김녕빵집 + 김녕해변|https://map.naver.com/p/entry/place/13491485'
  else plan_ref end
where plan_ref not like '%|%';

-- 안 갔어요: 접어서 보이게. 계획 장소는 visited_at 없이 skipped 기록을 만든다
alter table public.visits add column skipped boolean not null default false;
grant update (skipped) on public.visits to authenticated;
