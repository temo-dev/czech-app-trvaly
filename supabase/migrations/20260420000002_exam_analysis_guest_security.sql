alter table public.exam_analysis
  add column if not exists guest_token text;

create index if not exists idx_exam_analysis_guest_token
  on public.exam_analysis(guest_token);

drop policy if exists "service role can manage exam_analysis"
  on public.exam_analysis;
drop policy if exists "authenticated users can read own exam_analysis"
  on public.exam_analysis;
drop policy if exists "anon users can read anonymous exam_analysis"
  on public.exam_analysis;
drop policy if exists "guest or owner can read exam_analysis"
  on public.exam_analysis;
drop policy if exists "guest or owner can update exam_analysis"
  on public.exam_analysis;

create policy "service role can manage exam_analysis"
  on public.exam_analysis
  for all
  to service_role
  using (true)
  with check (true);

create policy "guest or owner can read exam_analysis"
  on public.exam_analysis
  for select
  to anon, authenticated
  using (
    user_id = auth.uid()
    or (
      user_id is null
      and guest_token is not null
      and guest_token = public.request_guest_token()
    )
  );

create policy "guest or owner can update exam_analysis"
  on public.exam_analysis
  for update
  to anon, authenticated
  using (
    user_id = auth.uid()
    or (
      user_id is null
      and guest_token is not null
      and guest_token = public.request_guest_token()
    )
  )
  with check (
    user_id = auth.uid()
    or (
      user_id is null
      and guest_token is not null
      and guest_token = public.request_guest_token()
    )
  );

grant select, update on public.exam_analysis to anon, authenticated;
