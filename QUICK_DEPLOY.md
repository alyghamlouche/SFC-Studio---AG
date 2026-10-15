# SFC Studio - deploy checklist

1. In GitHub repository root, you must see `package.json`, `app/`, `lib/`, `components/` (not a single nested `sfc-studio/` folder).
2. In Vercel Project Settings > General, set Root Directory to `./` if the contents are in repo root. If you uploaded the entire `sfc-studio` folder as one folder, set Root Directory to `sfc-studio` instead.
3. Framework: Next.js. Build command: `npm run build`.
4. Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` under Project Settings > Environment Variables. Redeploy after changes.
5. Supabase: run `supabase/schema.sql` once in SQL Editor on a new project; create admin Auth user and admin profile as explained in README. Do not run the SQL twice without checking existing tables.
6. In Vercel, open the newest deployment, inspect the FIRST red error and confirm commit SHA matches your latest GitHub commit. Old deployments retain old errors.

Build verification: package installation was blocked by unavailable npm registry in the preparation environment. This ZIP is source-reviewed but not production-build-verified.
