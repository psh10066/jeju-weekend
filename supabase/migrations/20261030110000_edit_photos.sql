-- 글 수정 때 사진·동영상도 빼고 더하기. 남의 파일 경로를 끼워 넣지 못하게 본인 폴더(<user_id>/)만 허용
create function public.own_paths(uid uuid, paths text[]) returns boolean
language sql immutable as $$
  select coalesce(bool_and(p like uid::text || '/%'), true) from unnest(paths) p
$$;
alter table public.reviews add constraint reviews_own_paths check (public.own_paths(user_id, photo_paths));
grant update (photo_paths) on public.reviews to authenticated;
