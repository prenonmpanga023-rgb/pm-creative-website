# PM Creative Studio website
Plain HTML/CSS/JS + Supabase.

## Upload to GitHub
Upload the **contents** of this folder (index.html, schema.sql, images/, supabase/, README.md) to the repo root.

## Setup
1. Supabase: run `schema.sql` in the SQL Editor.
2. In `index.html`, set `SUPABASE_URL` and `SUPABASE_ANON_KEY` (the anon key is public by design; never put the service-role key here).
3. Sign up on the site, then run the commented SQL line at the bottom of `schema.sql` to make yourself admin.
4. Emails: deploy `supabase/functions/notify-order` (secrets listed at the top of the file) and add a Database Webhook on `orders` (insert + update).
5. Host with GitHub Pages: Settings > Pages > deploy from `main`, root. Add the Pages URL to Supabase Auth > URL Configuration.
