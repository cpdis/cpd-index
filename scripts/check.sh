#!/usr/bin/env bash
# Compare the cpd.dev DNS zone with the links on index.html.
#
# Lists web subdomains (A, AAAA, CNAME records whose labels do not start with "_")
# that have no link on the page, and linked subdomains that DNS no longer has.
# Exits 1 when the two disagree, so it can gate a commit.
#
#   CLOUDFLARE_API_TOKEN=... scripts/check.sh
set -euo pipefail
cd "$(dirname "$0")/.."
: "${CLOUDFLARE_API_TOKEN:?set CLOUDFLARE_API_TOKEN (Cloudflare token with DNS read access to cpd.dev)}"

api() { curl -s --fail-with-body "https://api.cloudflare.com/client/v4/$1" --header "Authorization: Bearer $CLOUDFLARE_API_TOKEN"; }

# the zone ID is optional: look it up from the token when it is not set
zone="${CLOUDFLARE_ZONE_ID:-$(api "zones?name=cpd.dev" | python3 -c "import json,sys; print(json.load(sys.stdin)['result'][0]['id'])")}"

# web hosts in DNS; this page's own host is excluded (it does not link to itself)
dns=$(api "zones/$zone/dns_records?per_page=500" | python3 -c "
import json, sys
for d in json.load(sys.stdin)['result']:
    name = d['name']
    if d['type'] in ('A', 'AAAA', 'CNAME') and not any(l.startswith('_') for l in name.split('.')) and name not in ('cpd.dev', 'index.cpd.dev'):
        print(name)" | sort -u)

# hosts the page links to
page=$(grep -o 'href="https://[a-z0-9.-]*\.cpd\.dev' index.html | sed 's|href="https://||' | sort -u)

missing=$(comm -23 <(echo "$dns") <(echo "$page"))
stale=$(comm -13 <(echo "$dns") <(echo "$page"))
[ -n "$missing" ] && printf 'In DNS but not on the page:\n%s\n' "$missing"
[ -n "$stale" ] && printf 'On the page but not in DNS:\n%s\n' "$stale"
[ -z "$missing$stale" ] && echo "index.html matches DNS ($(echo "$dns" | wc -l | tr -d ' ') subdomains)" || exit 1
