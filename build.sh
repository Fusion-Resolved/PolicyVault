#!/bin/bash
set -e

# Validate required env vars
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "ERROR: SUPABASE_URL and SUPABASE_ANON_KEY must be set in Netlify environment variables."
  exit 1
fi

mkdir -p dist

# Inject credentials into index.html at build time
sed \
  -e "s|__SUPABASE_URL__|${SUPABASE_URL}|g" \
  -e "s|__SUPABASE_ANON_KEY__|${SUPABASE_ANON_KEY}|g" \
  index.html > dist/index.html

# Copy PWA assets if they exist
for f in sw.js manifest.json icon-192.png icon-512.png; do
  [ -f "$f" ] && cp "$f" dist/ || true
done

echo "Build complete → dist/"
