-- 장소 리뷰는 사람당 장소마다 1개 (장소 없는 자유 글은 제한 없음), 같은 링크의 장소는 하나로
create unique index reviews_one_per_place on public.reviews (visit_id, user_id) where visit_id is not null;
create unique index visits_place_url_key on public.visits (place_url) where place_url is not null;
