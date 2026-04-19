create or replace function public.request_guest_token()
returns text
language sql
stable
as $$
  select nullif(current_setting('request.headers', true)::json->>'x-guest-token', '');
$$;

alter table public.exam_attempts
  add column if not exists guest_token text;

alter table public.exam_results
  add column if not exists guest_token text;

alter table public.ai_speaking_attempts
  add column if not exists guest_token text;

alter table public.ai_writing_attempts
  add column if not exists guest_token text;

alter table public.ai_teacher_reviews
  add column if not exists guest_token text;

create index if not exists idx_exam_attempts_guest_token
  on public.exam_attempts(guest_token);

create index if not exists idx_exam_results_guest_token
  on public.exam_results(guest_token);

create index if not exists idx_ai_speaking_attempts_guest_token
  on public.ai_speaking_attempts(guest_token);

create index if not exists idx_ai_writing_attempts_guest_token
  on public.ai_writing_attempts(guest_token);

create index if not exists idx_ai_teacher_reviews_guest_token
  on public.ai_teacher_reviews(guest_token);

drop policy if exists "Anyone can create attempt" on public.exam_attempts;
drop policy if exists "Owner or anon can read attempt" on public.exam_attempts;
drop policy if exists "Owner or anon can update attempt" on public.exam_attempts;
drop policy if exists "exam_attempts_select" on public.exam_attempts;
drop policy if exists "exam_attempts_insert" on public.exam_attempts;
drop policy if exists "exam_attempts_update" on public.exam_attempts;

create policy "exam_attempts_select"
  on public.exam_attempts
  for select
  using (
    user_id = auth.uid()
    or (
      user_id is null
      and guest_token is not null
      and guest_token = public.request_guest_token()
    )
  );

create policy "exam_attempts_insert"
  on public.exam_attempts
  for insert
  with check (
    user_id = auth.uid()
    or (
      user_id is null
      and guest_token is not null
      and guest_token = public.request_guest_token()
    )
  );

create policy "exam_attempts_update"
  on public.exam_attempts
  for update
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

drop policy if exists "Owner can read own result" on public.exam_results;
drop policy if exists "Anyone can insert result" on public.exam_results;
drop policy if exists "Owner can update own result" on public.exam_results;
drop policy if exists "exam_results_select" on public.exam_results;
drop policy if exists "exam_results_insert" on public.exam_results;
drop policy if exists "exam_results_update" on public.exam_results;

create policy "exam_results_select"
  on public.exam_results
  for select
  using (
    user_id = auth.uid()
    or (
      user_id is null
      and guest_token is not null
      and guest_token = public.request_guest_token()
    )
  );

create policy "exam_results_insert"
  on public.exam_results
  for insert
  with check (
    user_id = auth.uid()
    or (
      user_id is null
      and guest_token is not null
      and guest_token = public.request_guest_token()
    )
  );

create policy "exam_results_update"
  on public.exam_results
  for update
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

drop policy if exists "ai_speaking_select" on public.ai_speaking_attempts;
drop policy if exists "ai_speaking_insert" on public.ai_speaking_attempts;
drop policy if exists "ai_speaking_update" on public.ai_speaking_attempts;

create policy "ai_speaking_select"
  on public.ai_speaking_attempts
  for select
  using (
    user_id = auth.uid()
    or (
      user_id is null
      and guest_token is not null
      and guest_token = public.request_guest_token()
    )
  );

create policy "ai_speaking_insert"
  on public.ai_speaking_attempts
  for insert
  with check (
    user_id = auth.uid()
    or (
      user_id is null
      and guest_token is not null
      and guest_token = public.request_guest_token()
    )
  );

create policy "ai_speaking_update"
  on public.ai_speaking_attempts
  for update
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

drop policy if exists "ai_writing_select" on public.ai_writing_attempts;
drop policy if exists "ai_writing_insert" on public.ai_writing_attempts;
drop policy if exists "ai_writing_update" on public.ai_writing_attempts;

create policy "ai_writing_select"
  on public.ai_writing_attempts
  for select
  using (
    user_id = auth.uid()
    or (
      user_id is null
      and guest_token is not null
      and guest_token = public.request_guest_token()
    )
  );

create policy "ai_writing_insert"
  on public.ai_writing_attempts
  for insert
  with check (
    user_id = auth.uid()
    or (
      user_id is null
      and guest_token is not null
      and guest_token = public.request_guest_token()
    )
  );

create policy "ai_writing_update"
  on public.ai_writing_attempts
  for update
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

drop policy if exists "service role can manage ai_teacher_reviews"
  on public.ai_teacher_reviews;
drop policy if exists "guest or owner can read ai_teacher_reviews"
  on public.ai_teacher_reviews;
drop policy if exists "guest or owner can update ai_teacher_reviews"
  on public.ai_teacher_reviews;

create policy "service role can manage ai_teacher_reviews"
  on public.ai_teacher_reviews
  for all
  to service_role
  using (true)
  with check (true);

create policy "guest or owner can read ai_teacher_reviews"
  on public.ai_teacher_reviews
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

create policy "guest or owner can update ai_teacher_reviews"
  on public.ai_teacher_reviews
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

grant select, update on public.ai_teacher_reviews to anon, authenticated;
