-- 가족 여행 기록: 구성원(역할당 1명) · 다녀온 곳 · 후기(사진)
create table public.members (
  user_id uuid primary key references auth.users on delete cascade,
  email text not null,
  role text not null unique check (role in ('아빠', '엄마', '딸', '아들')),
  created_at timestamptz not null default now()
);

create table public.visits (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.members on delete cascade,
  place_name text not null check (length(place_name) between 1 and 100),
  place_url text check (place_url ~ '^https://'),
  address text,
  plan_ref text, -- 계획표에서 가져온 곳이면 그 장소 링크
  visited_on date not null default (now() at time zone 'Asia/Seoul')::date,
  created_at timestamptz not null default now()
);

create table public.reviews (
  id bigint generated always as identity primary key,
  visit_id bigint not null references public.visits on delete cascade,
  user_id uuid not null references public.members on delete cascade,
  rating smallint check (rating between 1 and 5),
  body text check (length(body) <= 2000),
  photo_path text,
  created_at timestamptz not null default now()
);

-- 가입 = auth 사용자 생성. 고른 역할이 비어 있을 때만 통과시키고 members에 바로 넣는다
create function public.join_family() returns trigger
language plpgsql security definer set search_path = '' as $$
declare r text := new.raw_user_meta_data ->> 'role';
begin
  if r is null or r not in ('아빠', '엄마', '딸', '아들') then
    raise exception '역할을 골라주세요';
  end if;
  if exists (select 1 from public.members where role = r) then
    raise exception '이미 가입된 역할입니다: %', r;
  end if;
  insert into public.members (user_id, email, role) values (new.id, new.email, r);
  return new;
end $$;

create trigger join_family after insert on auth.users
  for each row execute function public.join_family();

-- 가입 화면에서 남은 역할 표시 (로그인 전에도 호출)
create function public.open_roles() returns text[]
language sql stable security definer set search_path = '' as $$
  select array(select x from unnest(array['아빠', '엄마', '딸', '아들']) x
               where not exists (select 1 from public.members m where m.role = x))
$$;

create function public.is_admin() returns boolean
language sql stable as $$
  select coalesce(auth.jwt() ->> 'email', '') = 'psh10066@gmail.com'
$$;

create function public.is_member() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.members where user_id = auth.uid())
$$;

-- 관리자 전용 탈퇴: 그 사람의 후기 · (다른 가족 후기가 없는) 장소 · 계정 삭제 → 역할 자리가 빈다
-- 사진 파일은 storage 테이블 직접 삭제가 막혀 있어 화면에서 storage API로 먼저 지운다
create function public.remove_member(target uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if target = auth.uid() then raise exception 'cannot remove yourself'; end if;
  delete from public.reviews where user_id = target;
  delete from public.visits v where v.user_id = target
    and not exists (select 1 from public.reviews r where r.visit_id = v.id);
  -- 남은 장소(다른 가족 후기가 달린 곳)는 관리자 소유로 넘긴다
  update public.visits set user_id = auth.uid() where user_id = target;
  delete from auth.users where id = target;
end $$;

revoke execute on function public.remove_member from public, anon;
grant execute on function public.open_roles to anon, authenticated;

alter table public.members enable row level security;
alter table public.visits enable row level security;
alter table public.reviews enable row level security;

create policy "members read" on public.members for select to authenticated using (public.is_member());

create policy "visits read" on public.visits for select to authenticated using (public.is_member());
create policy "visits add" on public.visits for insert to authenticated
  with check (public.is_member() and user_id = auth.uid());
create policy "visits delete" on public.visits for delete to authenticated
  using (public.is_member() and (user_id = auth.uid() or public.is_admin()));

create policy "reviews read" on public.reviews for select to authenticated using (public.is_member());
create policy "reviews add" on public.reviews for insert to authenticated
  with check (public.is_member() and user_id = auth.uid());
create policy "reviews delete" on public.reviews for delete to authenticated
  using (public.is_member() and (user_id = auth.uid() or public.is_admin()));

-- 사진: 비공개 버킷, 경로는 <user_id>/<파일>
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', false, 5242880, array['image/jpeg'])
on conflict (id) do nothing;

create policy "photos read" on storage.objects for select to authenticated
  using (bucket_id = 'photos' and public.is_member());
create policy "photos add" on storage.objects for insert to authenticated
  with check (bucket_id = 'photos' and public.is_member() and (storage.foldername(name))[1] = auth.uid()::text);
create policy "photos delete" on storage.objects for delete to authenticated
  using (bucket_id = 'photos' and public.is_member() and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

alter publication supabase_realtime add table public.members, public.visits, public.reviews;
