-- Fix: infinite recursion in chat_members RLS policies
-- Root cause: chat_members SELECT policy referenced itself via EXISTS subquery.
-- Solution: SECURITY DEFINER function that bypasses RLS for membership lookups.

-- ── Helper function (runs as postgres, bypasses RLS) ─────────────────────
CREATE OR REPLACE FUNCTION public.get_my_chat_ids()
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT chat_id FROM public.chat_members WHERE user_id = auth.uid();
$$;

-- ── chat_members: fix self-referential policy ──────────────────────────────
DROP POLICY IF EXISTS "Members can view chat membership" ON public.chat_members;
CREATE POLICY "Members can view chat membership"
  ON public.chat_members FOR SELECT USING (
    chat_id IN (SELECT public.get_my_chat_ids())
  );

-- ── chats: replace with function-based check ─────────────────────────────
DROP POLICY IF EXISTS "Members can view their chats" ON public.chats;
CREATE POLICY "Members can view their chats"
  ON public.chats FOR SELECT USING (
    id IN (SELECT public.get_my_chat_ids())
  );

-- ── messages: replace with function-based check ───────────────────────────
DROP POLICY IF EXISTS "Members can read messages" ON public.messages;
CREATE POLICY "Members can read messages"
  ON public.messages FOR SELECT USING (
    chat_id IN (SELECT public.get_my_chat_ids())
  );

DROP POLICY IF EXISTS "Members can send messages" ON public.messages;
CREATE POLICY "Members can send messages"
  ON public.messages FOR INSERT WITH CHECK (
    sender_id = auth.uid() AND
    chat_id IN (SELECT public.get_my_chat_ids())
  );
