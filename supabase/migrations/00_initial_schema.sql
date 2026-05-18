-- ============================================================
-- SRC (수원러닝크루) 초기 DB 스키마
-- Supabase SQL Editor에서 순서대로 실행하세요.
-- ============================================================

-- -----------------------------------------------
-- 1. ENUM 타입 정의
-- -----------------------------------------------
create type public.user_role as enum ('WAITING', 'REGULAR', 'PACER', 'ADMIN');
create type public.run_type as enum ('PERSONAL', 'REGULAR');
create type public.marathon_category as enum ('10K', 'HALF', 'FULL');

-- -----------------------------------------------
-- 2. profiles 테이블
--    auth.users와 1:1 연동. 강퇴/탈퇴는 is_active=false (Soft Delete)
-- -----------------------------------------------
create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  kakao_id     text unique,
  nickname     text not null,
  avatar_url   text,
  role         public.user_role not null default 'WAITING',
  is_active    boolean not null default true,    -- false = 강퇴/탈퇴 (Soft Delete)
  is_exempted  boolean not null default false,   -- true = 생존 조건 면제
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

comment on table public.profiles is '사용자 프로필. auth.users와 1:1 연동.';
comment on column public.profiles.is_active is 'Soft Delete: 강퇴/탈퇴 시 false. 재가입 시 기록 복구 가능.';
comment on column public.profiles.is_exempted is '생존 조건 면제 여부. ADMIN이 수동 설정. 월 자동 초기화 없음.';

-- updated_at 자동 갱신 트리거
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.handle_updated_at();

-- -----------------------------------------------
-- 3. 신규 카카오 로그인 시 profiles row 자동 생성
-- -----------------------------------------------
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, kakao_id, nickname, avatar_url)
  values (
    new.id,
    new.raw_user_meta_data ->> 'provider_id',
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', '멤버'),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;  -- 재가입 시 기존 row 유지 (is_active만 ADMIN이 복구)
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- -----------------------------------------------
-- 4. places 테이블 (장소 목록, ADMIN 관리, Soft Delete)
-- -----------------------------------------------
create table public.places (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  is_deleted  boolean not null default false,   -- Soft Delete
  created_at  timestamptz not null default now()
);

comment on table public.places is '러닝 장소 목록. ADMIN이 관리. is_deleted=true는 숨김 처리.';

-- -----------------------------------------------
-- 5. running_records 테이블 (러닝 인증 기록)
-- -----------------------------------------------
create table public.running_records (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id),
  distance    numeric(5,1) not null check (distance >= 3.0),
  place_id    uuid references public.places(id) on delete set null,
  place_name  text not null,     -- 스냅샷: 장소 Soft Delete 후에도 텍스트 보존
  run_date    date not null,
  run_type    public.run_type not null,
  is_paced    boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

comment on table public.running_records is '러닝 인증 기록. place_name은 장소 삭제 후에도 보존되는 스냅샷.';

create trigger running_records_updated_at
  before update on public.running_records
  for each row execute function public.handle_updated_at();

-- 성능 인덱스
create index idx_running_records_user_date on public.running_records(user_id, run_date);
create index idx_running_records_run_date on public.running_records(run_date);

-- -----------------------------------------------
-- 6. marathon_pbs 테이블 (마라톤 PB)
-- -----------------------------------------------
create table public.marathon_pbs (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id),
  category    public.marathon_category not null,
  record_sec  integer not null check (record_sec > 0),  -- 기록(초 단위)
  updated_at  timestamptz not null default now(),
  unique (user_id, category)   -- 종목당 1개 row만 유지 (upsert 사용)
);

comment on table public.marathon_pbs is '마라톤 PB. 종목당 1개 row. record_sec는 초 단위 저장.';

create trigger marathon_pbs_updated_at
  before update on public.marathon_pbs
  for each row execute function public.handle_updated_at();
