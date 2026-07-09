SkySource KRA Live — Vercel + Supabase Scaffold
This is a secure production scaffold for the SkySource KRA dashboard.
What is included
Vite + React app
Supabase Auth integration
Supabase database service layer
Admin / Supervisor / Associate role model
Associate read-only dashboard flow
Professional login page
Employee home dashboard
Employee detail dashboard with Overview / Parameters / Monthly Trend
Reports page with XLSX export
Admin Config section
Admin user creation through Supabase Edge Function
Admin/Supervisor password reset Edge Function scaffold
Bulk Excel upload parser and database upsert flow
Settings panel scaffold
Senior-only Leadership/Communication parameter rules
Supabase SQL schema with RLS policies
Production folder structure ready for Vercel
Important
This scaffold intentionally replaces the offline HTML/localStorage model with Supabase.
The current rich UI from the offline HTML can be migrated component-by-component into this structure.
Setup
```bash
cd skysource-kra-live
npm install
cp .env.example .env.local
```
Add your Supabase values to `.env.local`:
```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```
Supabase setup
Create a Supabase project.
Open SQL Editor.
Run `supabase_schema.sql`.
Create your first admin user in Supabase Auth.
Insert that user into `profiles`:
```sql
insert into public.profiles (id, email, full_name, role)
values ('AUTH_USER_UUID', 'admin@skysource.com', 'Admin Supervisor', 'admin');
```
Run locally
```bash
npm run dev
```
Build
```bash
npm run build
```
Deploy to Vercel
Push this folder to GitHub.
Import repo in Vercel.
Add environment variables:
`VITE_SUPABASE_URL`
`VITE_SUPABASE_ANON_KEY`
Deploy.
Supabase Edge Functions
The included Edge Functions require service-role permissions and should be deployed through Supabase CLI.
```bash
supabase functions deploy admin-create-user
supabase functions deploy admin-reset-password
```
Required Supabase secrets:
```bash
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```
Remaining production hardening tasks
This scaffold is now full-stack and deployment-ready, but before final company rollout you should still complete:
Import real employee/KRA data into Supabase.
Verify Supabase Row Level Security with real accounts.
Deploy Edge Functions using Supabase CLI.
Add a polished archive/recover UI if needed.
Add email SMTP/notification automation if required.
Connect your custom domain in Vercel.
