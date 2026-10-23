# cpd-index

The list of everything on `cpd.dev`, live at **[cpd.dev](https://cpd.dev)**.

It is one hand-written HTML file with no CSS and no JavaScript, in the spirit of [nat.org](https://nat.org). There's no build step either, since Vercel serves `index.html` as it is.

## Add a site

1. Add a `<li>` to [index.html](index.html) in the right group. Link the full host (`https://name.cpd.dev`), then a colon and a one-line description.
2. Add the name to its host under **Where they live**.
3. Check that the page matches DNS:

   ```bash
   scripts/check.sh
   ```

4. Commit and push. Vercel deploys `main` to production on every push.

The `/ship` skill does steps 1 to 4 for every new subdomain it sets up.

## scripts/check.sh

It compares the Cloudflare DNS zone with the links on the page. It prints any web subdomain (an `A`, `AAAA` or `CNAME` record without a leading `_` label) that has no link, and any link whose record is gone. It exits 1 when they disagree.

- Needs: `CLOUDFLARE_API_TOKEN` with DNS read access to `cpd.dev`. `CLOUDFLARE_ZONE_ID` is optional; the script looks it up from the token when it is not set.
- Ignores: `cpd.dev` and `www.cpd.dev`, which serve this page (it does not link to itself).
- Records that are not websites (email, verification) have no link, so list them as plain text under **Not websites**.

## Hosting

| Piece | Where |
| --- | --- |
| Repo | [cpdis/cpd-index](https://github.com/cpdis/cpd-index) |
| Hosting | Vercel project `cpd-index`, Git-connected (pushes to `main` deploy to production) |
| Domains | `cpd.dev` (primary) and `www.cpd.dev` (redirects to `cpd.dev`) |
| DNS | Cloudflare `cpd.dev` zone: apex `A` → Vercel, and CNAME `www` → Vercel (both DNS only, not proxied) |
| Firewall | Bot Protection on challenge and AI bots on deny, so `curl` gets a 429 "Security Checkpoint" while browsers load normally |

## Debug

- **A link 404s or doesn't resolve:** run `scripts/check.sh` to see whether the DNS record still exists. Then run `dig <name>.cpd.dev +short` to see where it points.
- **The page didn't update after a push:** run `vercel ls cpd-index` and check that the newest production deployment is `Ready`.
