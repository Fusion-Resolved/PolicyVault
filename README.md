# PolicyVault

A clean, minimal policy document management platform. Stores all policies in Supabase (free tier), deployable as a PWA on Netlify.

---

## Features

- **Category navigation** — primary / secondary / tertiary hierarchy in a sidebar
- **Full-text search** — searches policy names *and* body content via PostgreSQL's built-in full-text search
- **Partial name matching** — trigram indexes let you find "Acceptable Use" by typing "acc"
- **Keyboard navigation** — ↑ / ↓ to move through results, ⌘K to focus search, N to open New Policy
- **Day / Night mode** — toggle in the header, remembered across sessions
- **Add & Edit policies** — modal form with autocomplete for existing category names
- **PWA** — installable on mobile and desktop via Netlify

---

## Setup — 5 steps

### 1. Create a Supabase project

- Go to [supabase.com](https://supabase.com) and sign up (free)
- Create a new project (choose a region close to you)
- Wait for it to provision (~60 seconds)

### 2. Run the database schema

- In your Supabase dashboard, go to **SQL Editor**
- Copy and paste the entire contents of `schema.sql`
- Click **Run**
- This creates the `policies` table, all indexes, and sample data

### 3. Copy your credentials

- Go to **Settings → API** in your Supabase dashboard
- Copy:
  - **Project URL** (looks like `https://xxxxxxxxxxxx.supabase.co`)
  - **anon public** key (long string beginning with `eyJ…`)

### 4. Update index.html

Open `index.html` and find these two lines near the top of the `<script>` block:

```js
const SUPABASE_URL      = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

Replace the placeholder strings with your actual values. Save the file.

### 5. Deploy to Netlify

**Easiest way — drag and drop:**
- Go to [netlify.com/drop](https://app.netlify.com/drop)
- Drag the entire `policyvault` folder onto the page
- Netlify gives you a live URL in seconds

**Or use Netlify CLI:**
```bash
npm install -g netlify-cli
cd policyvault
netlify deploy --prod
```

**Or connect a Git repository:**
- Push this folder to GitHub/GitLab
- In Netlify → New site → Import from Git
- Build command: *(leave blank)*
- Publish directory: `.` (the root)

---

## PWA — install on your devices

Once deployed, open the site in:
- **iOS Safari** → Share → Add to Home Screen
- **Android Chrome** → three-dot menu → Add to Home Screen / Install app
- **Desktop Chrome/Edge** → address bar install icon

The app will cache itself and the CDN libraries so it works with limited connectivity.

---

## Supabase free tier limits

| Resource       | Free limit   | PolicyVault usage |
|---------------|--------------|-------------------|
| Database       | 500 MB       | ~1 KB per policy → ~500,000 policies |
| API requests   | Unlimited    | ✓ |
| Monthly users  | 50,000       | Personal tool → ✓ |
| Bandwidth      | 5 GB / month | Text only → ✓ |

You will never hit free tier limits with this use case.

---

## Security note

The current Row Level Security policy allows read and write without authentication — suitable for a personal or small internal tool on a private URL. To add authentication:

1. Enable **Supabase Auth** (email or magic link)
2. Replace the RLS policy in `schema.sql` with:

```sql
CREATE POLICY "Authenticated users only" ON policies
  FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');
```

3. Add a login screen to the app using `supabase.auth.signInWithOtp()`

---

## File structure

```
policyvault/
├── index.html      ← Complete React app (edit SUPABASE_URL here)
├── manifest.json   ← PWA manifest
├── sw.js           ← Service worker (offline support)
├── _redirects      ← Netlify SPA routing
├── schema.sql      ← Run once in Supabase SQL Editor
└── README.md       ← This file
```

---

## Keyboard shortcuts

| Key      | Action                          |
|----------|---------------------------------|
| ↑ / ↓    | Navigate through policy list    |
| ⌘K       | Focus the search bar            |
| N        | Open "New Policy" modal         |
| Esc      | Close modal / deselect policy   |
| ⌘↵       | Save policy (inside modal)      |
