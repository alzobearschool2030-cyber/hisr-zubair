-- شواهدي: إعداد قاعدة البيانات في Supabase
-- الصق هذا الملف كاملاً في SQL Editor ثم اضغط Run مرة واحدة.
-- أسماء الجداول تبدأ بـ sh_ فلا تتعارض مع تطبيقات المدرسة الأخرى في المشروع نفسه.

create table if not exists public.sh_programs (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.sh_state (
  program_id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.sh_evidence (
  id text primary key,
  program_id text not null,
  kind text,
  title text,
  note text,
  link text,
  file_path text,
  file_name text,
  mime text,
  size bigint,
  added_by text,
  device text,
  event_date text,
  created_at timestamptz not null default now()
);

create index if not exists sh_evidence_program_idx on public.sh_evidence (program_id);

alter table public.sh_programs enable row level security;
alter table public.sh_state enable row level security;
alter table public.sh_evidence enable row level security;

drop policy if exists sh_programs_all on public.sh_programs;
create policy sh_programs_all on public.sh_programs for all to anon, authenticated using (true) with check (true);

drop policy if exists sh_state_all on public.sh_state;
create policy sh_state_all on public.sh_state for all to anon, authenticated using (true) with check (true);

drop policy if exists sh_evidence_all on public.sh_evidence;
create policy sh_evidence_all on public.sh_evidence for all to anon, authenticated using (true) with check (true);

-- مخزن الملفات (الشواهد والتقارير): الحد الأعلى للملف الواحد 50 ميجابايت
insert into storage.buckets (id, name, public, file_size_limit)
values ('shawahidi', 'shawahidi', true, 52428800)
on conflict (id) do nothing;

drop policy if exists shawahidi_read on storage.objects;
create policy shawahidi_read on storage.objects for select to anon, authenticated using (bucket_id = 'shawahidi');

drop policy if exists shawahidi_insert on storage.objects;
create policy shawahidi_insert on storage.objects for insert to anon, authenticated with check (bucket_id = 'shawahidi');

drop policy if exists shawahidi_delete on storage.objects;
create policy shawahidi_delete on storage.objects for delete to anon, authenticated using (bucket_id = 'shawahidi');

-- التحديث التلقائي: إرسال التغييرات لجميع المستخدمين فور حفظها
do $$ begin
  alter publication supabase_realtime add table public.sh_programs, public.sh_state, public.sh_evidence;
exception when duplicate_object then null;
end $$;
