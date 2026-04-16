-- Storage policies for chat-attachments bucket
-- Apply manually in Supabase Dashboard → SQL Editor
-- (MCP is in read-only mode)

-- INSERT: authenticated users can only upload to their own folder
-- Path format enforced by app: {user_id}/{room_id}/{uuid}_{filename}
DROP POLICY IF EXISTS "users upload to own folder"    ON storage.objects;
DROP POLICY IF EXISTS "public read chat attachments"  ON storage.objects;
DROP POLICY IF EXISTS "users delete own uploads"      ON storage.objects;

CREATE POLICY "users upload to own folder"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'chat-attachments'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- SELECT: public read (bucket is already marked public)
CREATE POLICY "public read chat attachments"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'chat-attachments');

-- DELETE: users can delete their own uploads
CREATE POLICY "users delete own uploads"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'chat-attachments'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
