#!/usr/bin/env bash
set -euo pipefail
for p in packages/rxflare_core packages/rxflare_router packages/rxflare_i18n packages/rxflare; do
  echo "=== pub get $p ==="
  (cd "$p" && flutter pub get)
done
echo "=== analyze + test core ==="
(cd packages/rxflare_core && flutter analyze && flutter test)
echo "Done."
