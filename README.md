# Attendance v1.3 — Sign in with Google

Only emails listed (and active) in `app_users` can enter. Everyone else is refused after Google.

## Setup (once)
1. Supabase → SQL Editor → run `supabase/schema.sql`.
2. Google Cloud Console → APIs & Services → OAuth consent screen (External, add your email as test user or Publish) →
   Credentials → Create OAuth client ID → Web application →
   Authorized redirect URI: `https://ruzzyvloaqbjzwzwwkzv.supabase.co/auth/v1/callback`
3. Supabase → Authentication → Sign In / Providers → Google → ON → paste Client ID + Client Secret → Save.
4. Supabase → Authentication → URL Configuration →
   Site URL: `https://bobs24.github.io/Report-Attendance/`
   Redirect URLs: add `https://bobs24.github.io/Report-Attendance/`
5. Push `index.html`, open the site, Ctrl + F5, press **Sign in with Google**.
