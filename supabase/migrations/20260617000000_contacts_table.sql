-- ────────────────────────────────────────────────────────────
-- CONTACTS TABLE — users must add contacts before they appear
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.contacts (
  id         uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id    uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  contact_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, contact_id)
);

ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own contacts"
  ON public.contacts FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can add own contacts"
  ON public.contacts FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can remove own contacts"
  ON public.contacts FOR DELETE USING (user_id = auth.uid());
