-- 관리자 전용: 가족 계정 비밀번호를 임시 비밀번호로 바꾸고 돌려준다 (메일 없이 카톡으로 전달)
-- 기존 로그인은 모두 끊는다. 본인은 로그인 후 '비밀번호 바꾸기'로 직접 변경
create function public.reset_password(target uuid) returns text
language plpgsql security definer set search_path = '' as $$
declare pw text := encode(extensions.gen_random_bytes(4), 'hex'); -- 8자리 영문 소문자+숫자, 폰으로 치기 쉽게
begin
  if not public.is_admin() then raise exception 'admin only'; end if;
  if not exists (select 1 from public.members where user_id = target) then raise exception 'not a member'; end if;
  update auth.users set encrypted_password = extensions.crypt(pw, extensions.gen_salt('bf')), updated_at = now() where id = target;
  delete from auth.sessions where user_id = target;
  return pw;
end $$;

revoke execute on function public.reset_password from public, anon;
grant execute on function public.reset_password to authenticated;
