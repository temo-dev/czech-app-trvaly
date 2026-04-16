-- Create cms-assets storage bucket for CMS uploads (thumbnails, audio, etc.)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('cms-assets', 'cms-assets', true, 10485760, ARRAY['image/*', 'audio/*', 'video/*'])
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated admins to upload
CREATE POLICY "admin_upload_cms_assets"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'cms-assets'
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Allow authenticated admins to update/delete
CREATE POLICY "admin_update_cms_assets"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'cms-assets'
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "admin_delete_cms_assets"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'cms-assets'
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Public read (bucket is public, but explicit policy for SELECT)
CREATE POLICY "public_read_cms_assets"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'cms-assets');
