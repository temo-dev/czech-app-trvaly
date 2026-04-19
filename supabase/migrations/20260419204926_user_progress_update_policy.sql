-- Allow authenticated users to update their own user_progress rows.
-- Required because the app uses `upsert(..., onConflict: 'user_id,lesson_block_id')`
-- to mark lesson blocks complete. Without an UPDATE policy, the conflict path
-- fails under RLS with code 42501.

drop policy if exists "user_progress_update" on public.user_progress;

create policy "user_progress_update"
  on public.user_progress
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
