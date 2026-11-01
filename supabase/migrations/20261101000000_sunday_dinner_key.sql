-- 일요일 저녁 칸 제목이 '일미도 포장도 좋아요' → '공간7에서 저녁'으로 바뀌어 그 칸에 달린 기록의 키를 옮긴다
update public.visits set plan_ref = replace(plan_ref, 'sun|일미도 포장도 좋아요|', 'sun|공간7에서 저녁|') where plan_ref like 'sun|일미도 포장도 좋아요|%';
update public.visits set after_ref = 'sun|공간7에서 저녁' where after_ref = 'sun|일미도 포장도 좋아요';
