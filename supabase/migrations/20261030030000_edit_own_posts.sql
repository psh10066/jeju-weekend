-- 본인 글은 글·별점만 수정 가능 (사진·작성자·장소는 못 바꿈)
revoke update on public.reviews from authenticated;
grant update (body, rating) on public.reviews to authenticated;
create policy "reviews edit own" on public.reviews for update to authenticated
  using (public.is_member() and user_id = auth.uid())
  with check (user_id = auth.uid());
