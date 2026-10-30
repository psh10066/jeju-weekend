-- 장소 없이 자유롭게 쓰는 글 + 사진 여러 장(최대 10장)
alter table public.reviews alter column visit_id drop not null;
alter table public.reviews add column photo_paths text[] not null default '{}'
  check (cardinality(photo_paths) <= 10);
update public.reviews set photo_paths = array[photo_path] where photo_path is not null;
alter table public.reviews drop column photo_path;
alter table public.reviews add constraint reviews_has_content
  check (body is not null or rating is not null or cardinality(photo_paths) > 0);
