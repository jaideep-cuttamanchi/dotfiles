---
name: asato-api
description: Call the Asato local-AiB REST APIs (auth/user-management service and the main asato-api) as either a site-admin or a tenant user. Use when the user asks to query, inspect, or mutate anything via the asato API — tenants, users, dashboards, data products, agents, notifications, entitlements, etc. — or mentions api.local.asato.ai / user.local.asato.ai.
---

# Asato API

Generic authenticated HTTP client for the two Asato local-AiB services. Login, token caching/refresh, and reachability checks are handled by `scripts/asato-api.sh`. Endpoint discovery is done live against each service's OpenAPI spec — do not assume a path, look it up.

## Services

| Service | Base URL | Purpose |
| --- | --- | --- |
| auth | `https://user.local.asato.ai` | login, tokens, tenant/user/IDP management |
| api  | `https://api.local.asato.ai`  | everything else (260+ endpoints): dashboards, data products, agents, entitlements, notifications, tasks, siteadmin/*, etc. |

## Identities

Two credential pairs are expected in the environment (already exported by the user, never print them):

| Identity | Env vars | Use for |
| --- | --- | --- |
| `sa` | `ASATO_API_SA_USERNAME`, `ASATO_API_SA_PASSWORD` | `siteadmin/*` tags (site-admin, tenant provisioning, db-ops) |
| `user` | `ASATO_API_USERNAME`, `ASATO_API_PASSWORD` | everything else (tenant-scoped data: dashboards, data products, users, notifications, ...) |

If a call 500s/403s under one identity, retry under the other before concluding the endpoint is broken — plenty of endpoints are identity-scoped.

## Step 0: reachability check

Before doing any real work, run:

```bash
skills/work/asato/asato-api/scripts/asato-api.sh check
```

If either service is unreachable (non-200/timeout), **do not** debug this yourself — read and follow the `aib-debug` skill (`~/.claude/skills/aib-debug/SKILL.md` or wherever it's installed) to get local AiB healthy, then re-run `check`.

## Step 1: find the endpoint

Fetch (and cache to `/tmp/asato-api/openapi-{auth,api}.json`) the spec you need, then grep/jq it — never try to inline these into context, `openapi-api.json` is ~900KB / 260 endpoints.

```bash
skills/work/asato/asato-api/scripts/asato-api.sh spec api    # -> /tmp/asato-api/openapi-api.json
skills/work/asato/asato-api/scripts/asato-api.sh spec auth   # -> /tmp/asato-api/openapi-auth.json
```

Useful jq/python queries against the cached file:

```bash
# list paths for a tag
python3 -c "
import json
d = json.load(open('/tmp/asato-api/openapi-api.json'))
for p, m in d['paths'].items():
    for meth, info in m.items():
        if 'dashboards' in info.get('tags', []):
            print(meth.upper(), p)
"

# full definition (params/body/response) for one path
python3 -c "
import json
d = json.load(open('/tmp/asato-api/openapi-api.json'))
print(json.dumps(d['paths']['/dashboards/'], indent=2))
"
```

Known top-level tags on `api`: `siteadmin/admin`, `siteadmin/tenant`, `siteadmin/db-ops`, `dataproducts/*`, `dataconnectors*`, `mkb`, `dashboards`, `notifications`, `entity`, `tasks`, `datasets`, `kpis`, `survey`, `slack`, `jira`, `servicenow`, `entra`, `entitlements`, `teams`, `users`, `reports`, `agents/memories`, `mcp-oauth`, `audits`, `jobs`, `recommendations`, `healthcheck`. On `auth`: `/auth/*`, `/token/*`, `/user/*`, `/tenant/*`, `/idp/*`, `/onboarding/*`.

## Step 2: call it

```bash
# GET/DELETE (no body)
skills/work/asato/asato-api/scripts/asato-api.sh call <sa|user> GET /users/?limit=5
skills/work/asato/asato-api/scripts/asato-api.sh call <sa|user> GET /dashboards/

# POST/PUT/PATCH with a JSON body
skills/work/asato/asato-api/scripts/asato-api.sh call <sa|user> POST /notifications/ '{"title": "hi"}'

# management endpoints live on the auth service, not api
skills/work/asato/asato-api/scripts/asato-api.sh call-auth sa GET /tenant/
```

`call` / `call-auth` transparently log in (and re-login when the cached token is within 60s of expiry — tokens last ~1h) and print the raw response body. A non-2xx status is echoed to stderr as `HTTP <code>` and the command exits non-zero — treat that as a real error, not something to silently retry with a modified request unless the body/params were actually wrong.

## Script reference

```
scripts/asato-api.sh check                                    # verify both services are reachable
scripts/asato-api.sh login <sa|user>                           # force a fresh login
scripts/asato-api.sh token <sa|user>                           # print a valid jwtToken (rarely needed directly)
scripts/asato-api.sh call <sa|user> <METHOD> <path> [json]     # authenticated call to api.local.asato.ai
scripts/asato-api.sh call-auth <sa|user> <METHOD> <path> [json]# authenticated call to user.local.asato.ai
scripts/asato-api.sh spec <auth|api>                           # fetch+cache openapi.json, print its path
```

Token cache lives at `/tmp/asato-api/token-{sa,user}.json`; spec cache at `/tmp/asato-api/openapi-{auth,api}.json`. Both are safe to delete to force a refresh.
