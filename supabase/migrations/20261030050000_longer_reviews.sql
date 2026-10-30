-- 리뷰·글 길이 2000 → 5000자
alter table public.reviews drop constraint reviews_body_check;
alter table public.reviews add constraint reviews_body_check check (length(body) <= 5000);
