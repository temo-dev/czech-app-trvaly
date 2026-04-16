-- Add intro_text and intro_image_url to questions table.
-- Both are optional. intro_text holds the context/passage text shown above
-- the question prompt; intro_image_url holds a publicly-accessible image URL.
alter table questions
  add column if not exists intro_text      text,
  add column if not exists intro_image_url text;
