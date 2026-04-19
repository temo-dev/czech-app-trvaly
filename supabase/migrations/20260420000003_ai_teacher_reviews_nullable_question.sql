-- Allow question_id to be null in ai_teacher_reviews.
-- Exercises store question content in content_json (not in the questions table),
-- so question_id may not reference a row in questions when the review is for an exercise.
alter table public.ai_teacher_reviews alter column question_id drop not null;
