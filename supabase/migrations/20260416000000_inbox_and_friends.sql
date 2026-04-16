-- ============================================================
-- Trvalý Prep — Inbox DM + Bạn bè
-- ============================================================

-- ══════════════════════════════════════════════════════════
-- FRIENDSHIPS
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.friendships (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  addressee_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status       text NOT NULL DEFAULT 'pending'
               CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (requester_id, addressee_id),
  CHECK (requester_id <> addressee_id)
);

CREATE INDEX IF NOT EXISTS idx_friendships_requester ON public.friendships (requester_id);
CREATE INDEX IF NOT EXISTS idx_friendships_addressee ON public.friendships (addressee_id);

-- ══════════════════════════════════════════════════════════
-- DM ROOMS — mỗi cuộc trò chuyện 1-1 là 1 row
-- ══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.dm_rooms (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.dm_members (
  room_id      uuid NOT NULL REFERENCES public.dm_rooms(id) ON DELETE CASCADE,
  user_id      uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  last_read_at timestamptz,
  joined_at    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (room_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.dm_messages (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id          uuid NOT NULL REFERENCES public.dm_rooms(id) ON DELETE CASCADE,
  sender_id        uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  message_type     text NOT NULL DEFAULT 'text'
                   CHECK (message_type IN ('text', 'image', 'file')),
  body             text,
  attachment_url   text,
  attachment_name  text,
  attachment_size  int,
  attachment_mime  text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  -- body bắt buộc với text; với image/file có thể null
  CHECK (
    (message_type = 'text' AND body IS NOT NULL AND char_length(body) BETWEEN 1 AND 4000)
    OR (message_type IN ('image', 'file') AND attachment_url IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_dm_messages_room ON public.dm_messages (room_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_dm_members_user  ON public.dm_members (user_id);

-- ══════════════════════════════════════════════════════════
-- RLS — Friendships
-- ══════════════════════════════════════════════════════════
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "view own friendships"
  ON public.friendships FOR SELECT
  USING (requester_id = auth.uid() OR addressee_id = auth.uid());

CREATE POLICY "send friend request"
  ON public.friendships FOR INSERT
  WITH CHECK (requester_id = auth.uid());

CREATE POLICY "update friendship status"
  ON public.friendships FOR UPDATE
  USING (addressee_id = auth.uid())
  WITH CHECK (addressee_id = auth.uid());

CREATE POLICY "delete own friendship"
  ON public.friendships FOR DELETE
  USING (requester_id = auth.uid() OR addressee_id = auth.uid());

-- ══════════════════════════════════════════════════════════
-- RLS — DM rooms / members / messages
-- ══════════════════════════════════════════════════════════
ALTER TABLE public.dm_rooms    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dm_members  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dm_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members view dm rooms"
  ON public.dm_rooms FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.dm_members
    WHERE room_id = dm_rooms.id AND user_id = auth.uid()
  ));

CREATE POLICY "members view dm_members"
  ON public.dm_members FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.dm_members dm2
    WHERE dm2.room_id = dm_members.room_id AND dm2.user_id = auth.uid()
  ));

CREATE POLICY "members update own last_read_at"
  ON public.dm_members FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "members read messages"
  ON public.dm_messages FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.dm_members
    WHERE room_id = dm_messages.room_id AND user_id = auth.uid()
  ));

CREATE POLICY "members send messages"
  ON public.dm_messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.dm_members
      WHERE room_id = dm_messages.room_id AND user_id = auth.uid()
    )
  );

-- ══════════════════════════════════════════════════════════
-- Realtime
-- ══════════════════════════════════════════════════════════
ALTER PUBLICATION supabase_realtime ADD TABLE public.dm_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.dm_members;
ALTER PUBLICATION supabase_realtime ADD TABLE public.friendships;

-- ══════════════════════════════════════════════════════════
-- RPC: find_or_create_dm
-- Tìm hoặc tạo DM room giữa 2 bạn bè đã accepted.
-- SECURITY DEFINER để insert dm_members cho cả 2 phía.
-- ══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.find_or_create_dm(other_user_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_room_id uuid;
  v_me      uuid := auth.uid();
BEGIN
  -- Kiểm tra đã là bạn bè chưa
  IF NOT EXISTS (
    SELECT 1 FROM public.friendships
    WHERE status = 'accepted'
      AND (
        (requester_id = v_me AND addressee_id = other_user_id)
        OR (requester_id = other_user_id AND addressee_id = v_me)
      )
  ) THEN
    RAISE EXCEPTION 'not_friends';
  END IF;

  -- Tìm room đã tồn tại
  SELECT dm1.room_id INTO v_room_id
  FROM public.dm_members dm1
  JOIN public.dm_members dm2 ON dm1.room_id = dm2.room_id
  WHERE dm1.user_id = v_me AND dm2.user_id = other_user_id
  LIMIT 1;

  IF v_room_id IS NOT NULL THEN
    RETURN v_room_id;
  END IF;

  -- Tạo room mới
  INSERT INTO public.dm_rooms DEFAULT VALUES RETURNING id INTO v_room_id;
  INSERT INTO public.dm_members (room_id, user_id) VALUES (v_room_id, v_me);
  INSERT INTO public.dm_members (room_id, user_id) VALUES (v_room_id, other_user_id);

  RETURN v_room_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.find_or_create_dm(uuid) TO authenticated;

-- ══════════════════════════════════════════════════════════
-- View: public_profiles — để search/discover user
-- Expose tối giản: id, display_name, avatar_url, total_xp
-- ══════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW public.public_profiles AS
  SELECT id, display_name, avatar_url, total_xp
  FROM public.profiles;

GRANT SELECT ON public.public_profiles TO authenticated;

-- ══════════════════════════════════════════════════════════
-- NOTE: Supabase Storage bucket 'chat-attachments'
-- Tạo thủ công trong Dashboard → Storage → New bucket
--   Name: chat-attachments
--   Public: true (dùng UUID trong path thay cho signed URL)
-- Storage Policies (trong Dashboard → Storage → Policies):
--   INSERT authenticated:
--     (storage.foldername(name))[1] = auth.uid()::text
--   SELECT public:
--     true
-- ══════════════════════════════════════════════════════════
