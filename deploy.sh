#!/usr/bin/env bash
# Deploy koulu to the .195 VPS. Requires VPS_SSH_KEY + CF_MATE_DNS_TOKEN in env.
set -euo pipefail

VPS=94.249.179.195
APP=/opt/koulu

cd "$(dirname "$0")"
npm --prefix web run build

printf '%s\n' "$VPS_SSH_KEY" | ssh-add - >/dev/null 2>&1 || true
SSH="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new root@$VPS"

# Ship code
$SSH "mkdir -p $APP/server $APP/web"
rsync -az --delete --exclude .venv server/ "root@$VPS:$APP/server/"
rsync -az --delete web/dist/ "root@$VPS:$APP/web/dist/"

# Deps + unit (idempotent)
$SSH "cd $APP/server && python3 -m venv .venv && .venv/bin/pip install -q -r requirements.txt"
[ -f /etc/koulu.env ] || true
if ! $SSH "test -f /etc/koulu.env"; then
  SECRET=$(openssl rand -hex 32)
  $SSH "printf 'KOULU_SECRET=%s\nKOULU_DB=/var/lib/koulu/koulu.db\n' '$SECRET' > /etc/koulu.env && chmod 600 /etc/koulu.env && mkdir -p /var/lib/koulu"
fi
$SSH "cp $APP/server/koulu.service /etc/systemd/system/koulu.service && systemctl daemon-reload && systemctl enable --now koulu && systemctl restart koulu"

# Caddy
$SSH "cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.pre-koulu-\$(date +%s) 2>/dev/null || true"
if ! $SSH "grep -q 'koulu.kreatix.dev' /etc/caddy/Caddyfile"; then
  $SSH "cat >> /etc/caddy/Caddyfile" < deploy/Caddyfile.koulu
fi
$SSH "caddy validate --config /etc/caddy/Caddyfile && systemctl reload caddy"

# DNS via Cloudflare
ZONE=$(curl -s "https://api.cloudflare.com/client/v4/zones?name=kreatix.dev" \
  -H "Authorization: Bearer $CF_MATE_DNS_TOKEN" | python3 -c 'import json,sys;print(json.load(sys.stdin)["result"][0]["id"])')
EXISTING=$(curl -s "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records?name=koulu.kreatix.dev" \
  -H "Authorization: Bearer $CF_MATE_DNS_TOKEN" | python3 -c 'import json,sys;r=json.load(sys.stdin)["result"];print(r[0]["id"] if r else "")')
if [ -z "$EXISTING" ]; then
  curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE/dns_records" \
    -H "Authorization: Bearer $CF_MATE_DNS_TOKEN" -H "Content-Type: application/json" \
    -d '{"type":"A","name":"koulu","content":"94.249.179.195","proxied":true}' | python3 -c 'import json,sys;r=json.load(sys.stdin);print("dns:",r.get("success"))'
fi

echo "Deployed https://koulu.kreatix.dev"
