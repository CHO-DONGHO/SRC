-- ============================================================
-- SRC (수원러닝크루) RLS (Row Level Security) 정책
-- 00_initial_schema.sql 실행 후 실행하세요.
-- ============================================================

-- -----------------------------------------------
-- 헬퍼 함수: 현재 로그인 유저의 role 조회
-- -----------------------------------------------
create or replace function public.get_my_role()
returns public.user_role as $$
  select role from public.profiles where id = auth.uid();
$$ language sql security definer stable;

create or replace function public.is_active_member()
returns boolean as $$
  select is_active from public.profiles where id = auth.uid();
$$ language sql security definer stable;

-- -----------------------------------------------
-- profiles RLS
-- -----------------------------------------------
alter table public.profiles enable row level security;

-- 본인 row: 전체 컬럼 SELECT 가능
create policy "profiles: 본인 전체 조회"
  on public.profiles for select
  using (id = auth.uid() and is_active = true);

-- 타인 row: 민감 정보 제외한 공개 컬럼만 SELECT
-- (nickname, role, avatar_url, is_exempted만 노출. kakao_id 등 제외)
-- → View를 통해 노출하는 방식 사용 (아래 View 참고)
create policy "profiles: 정회원+ 타인 조회"
  on public.profiles for select
  using (
    public.get_my_role() in ('REGULAR', 'PACER', 'ADMIN')
    and is_active = true
  );

-- 본인 row: nickname, avatar_url만 본인이 UPDATE 가능
create policy "profiles: 본인 정보 수정"
  on public.profiles for update
  using (id = auth.uid())
  with check (id = auth.uid());

-- ADMIN: 모든 프로필 수정 가능 (role, is_active, is_exempted 등)
create policy "profiles: ADMIN 전체 수정"
  on public.profiles for update
  using (public.get_my_role() = 'ADMIN');

-- 민감 정보 마스킹용 View (정회원이 타인 프로필 조회 시 이 View 사용)
create or replace view public.public_profiles as
  select
    id,
    nickname,
    avatar_url,
    role,
    is_exempted,
    created_at
  from public.profiles
  where is_active = true;

-- -----------------------------------------------
-- places RLS
-- -----------------------------------------------
alter table public.places enable row level security;

-- 정회원+: is_deleted=false인 장소만 SELECT 가능
create policy "places: 정회원+ 조회"
  on public.places for select
  using (
    public.get_my_role() in ('REGULAR', 'PACER', 'ADMIN')
    and is_deleted = false
  );

-- ADMIN: 장소 INSERT 가능
create policy "places: ADMIN 등록"
  on public.places for insert
  with check (public.get_my_role() = 'ADMIN');

-- ADMIN: 장소 UPDATE 가능 (Soft Delete 포함)
create policy "places: ADMIN 수정"
  on public.places for update
  using (public.get_my_role() = 'ADMIN');

-- Hard Delete는 허용하지 않음 (Soft Delete 정책)

-- -----------------------------------------------
-- running_records RLS
-- -----------------------------------------------
alter table public.running_records enable row level security;

-- 정회원+: 모든 기록 SELECT 가능
create policy "running_records: 정회원+ 전체 조회"
  on public.running_records for select
  using (public.get_my_role() in ('REGULAR', 'PACER', 'ADMIN'));

-- 정회원+: 본인 기록 INSERT 가능
create policy "running_records: 본인 기록 등록"
  on public.running_records for insert
  with check (
    user_id = auth.uid()
    and public.get_my_role() in ('REGULAR', 'PACER', 'ADMIN')
  );

-- 본인: 본인 기록 UPDATE 가능
create policy "running_records: 본인 기록 수정"
  on public.running_records for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ADMIN: 모든 기록 UPDATE 가능
create policy "running_records: ADMIN 전체 수정"
  on public.running_records for update
  using (public.get_my_role() = 'ADMIN');

-- 본인: 본인 기록 DELETE 가능
create policy "running_records: 본인 기록 삭제"
  on public.running_records for delete
  using (user_id = auth.uid());

-- ADMIN: 모든 기록 DELETE 가능
create policy "running_records: ADMIN 전체 삭제"
  on public.running_records for delete
  using (public.get_my_role() = 'ADMIN');

-- -----------------------------------------------
-- marathon_pbs RLS
-- -----------------------------------------------
alter table public.marathon_pbs enable row level security;

-- 정회원+: 모든 PB SELECT 가능
create policy "marathon_pbs: 정회원+ 전체 조회"
  on public.marathon_pbs for select
  using (public.get_my_role() in ('REGULAR', 'PACER', 'ADMIN'));

-- 본인: 본인 PB INSERT 가능
create policy "marathon_pbs: 본인 PB 등록"
  on public.marathon_pbs for insert
  with check (
    user_id = auth.uid()
    and public.get_my_role() in ('REGULAR', 'PACER', 'ADMIN')
  );

-- 본인: 본인 PB UPDATE 가능
create policy "marathon_pbs: 본인 PB 수정"
  on public.marathon_pbs for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ADMIN: 모든 PB UPDATE 가능
create policy "marathon_pbs: ADMIN 전체 수정"
  on public.marathon_pbs for update
  using (public.get_my_role() = 'ADMIN');

-- 본인: 본인 PB DELETE 가능
create policy "marathon_pbs: 본인 PB 삭제"
  on public.marathon_pbs for delete
  using (user_id = auth.uid());
