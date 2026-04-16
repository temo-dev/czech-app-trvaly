-- exercises.skill should be nullable (vocab/grammar blocks have no specific skill)
ALTER TABLE public.exercises ALTER COLUMN skill DROP NOT NULL;
