-- 글마다 댓글 · 좋아요 (누가, 언제)
create table public.comments (
  id bigint generated always as identity primary key,
  review_id bigint not null references public.reviews on delete cascade,
  user_id uuid not null references public.members on delete cascade,
  body text not null check (length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);
create table public.likes (
  review_id bigint not null references public.reviews on delete cascade,
  user_id uuid not null references public.members on delete cascade,
  created_at timestamptz not null default now(),
  primary key (review_id, user_id)
);
alter table public.comments enable row level security;
alter table public.likes enable row level security;

create policy "comments read" on public.comments for select to authenticated using (public.is_member());
create policy "comments add" on public.comments for insert to authenticated
  with check (public.is_member() and user_id = auth.uid());
revoke update on public.comments from authenticated;
grant update (body) on public.comments to authenticated;
create policy "comments edit own" on public.comments for update to authenticated
  using (public.is_member() and user_id = auth.uid()) with check (user_id = auth.uid());
create policy "comments delete" on public.comments for delete to authenticated
  using (public.is_member() and (user_id = auth.uid() or public.is_admin()));

create policy "likes read" on public.likes for select to authenticated using (public.is_member());
create policy "likes add" on public.likes for insert to authenticated
  with check (public.is_member() and user_id = auth.uid());
create policy "likes delete own" on public.likes for delete to authenticated
  using (public.is_member() and user_id = auth.uid());

alter publication supabase_realtime add table public.comments, public.likes;
