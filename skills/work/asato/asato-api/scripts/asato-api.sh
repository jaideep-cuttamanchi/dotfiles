#!/usr/bin/env bash
# Auth + generic HTTP client for the Asato local-AiB APIs.
# Subcommands: check | login | token | call | spec
set -euo pipefail

AUTH_BASE="https://user.local.asato.ai"
API_BASE="https://api.local.asato.ai"
CACHE_DIR="/tmp/asato-api"
mkdir -p "$CACHE_DIR"

usage() {
  cat <<'EOF'
Usage:
  asato-api.sh check                                  # verify both APIs are reachable
  asato-api.sh login <sa|user>                         # force a fresh login, cache the token
  asato-api.sh token <sa|user>                         # print a valid jwtToken (login/refresh if needed)
  asato-api.sh call <sa|user> <METHOD> <path> [json]   # authenticated call to api.local.asato.ai
  asato-api.sh call-auth <sa|user> <METHOD> <path> [json]  # authenticated call to user.local.asato.ai
  asato-api.sh spec <auth|api>                         # fetch+cache openapi.json, print its path

Identities:
  sa    -> ASATO_API_SA_USERNAME / ASATO_API_SA_PASSWORD   (site-admin: siteadmin/*, tenant admin ops)
  user  -> ASATO_API_USERNAME    / ASATO_API_PASSWORD      (tenant user: everything else)
EOF
}

creds() {
  case "$1" in
    sa)   echo "${ASATO_API_SA_USERNAME:?ASATO_API_SA_USERNAME not set}" "${ASATO_API_SA_PASSWORD:?ASATO_API_SA_PASSWORD not set}" ;;
    user) echo "${ASATO_API_USERNAME:?ASATO_API_USERNAME not set}" "${ASATO_API_PASSWORD:?ASATO_API_PASSWORD not set}" ;;
    *) echo "identity must be 'sa' or 'user', got: $1" >&2; exit 2 ;;
  esac
}

token_file() { echo "$CACHE_DIR/token-$1.json"; }

do_login() {
  local identity="$1" user pass resp
  read -r user pass <<<"$(creds "$identity")"
  resp=$(curl -sk -m 15 -X POST "$AUTH_BASE/auth/manual-login" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "user_name=$user" \
    --data-urlencode "password=$pass")
  if ! echo "$resp" | python3 -c "import sys,json; json.load(sys.stdin)['jwtToken']" >/dev/null 2>&1; then
    echo "Login failed for identity '$identity': $resp" >&2
    exit 1
  fi
  echo "$resp" | python3 -c "
import json, time, sys
d = json.load(sys.stdin)
d['issuedAt'] = time.time()
json.dump(d, open('$(token_file "$identity")', 'w'))
"
}

cmd_login() {
  local identity="${1:?identity required (sa|user)}"
  do_login "$identity"
  echo "Logged in as '$identity', token cached at $(token_file "$identity")"
}

cmd_token() {
  local identity="${1:?identity required (sa|user)}"
  local f; f=$(token_file "$identity")
  if [[ -f "$f" ]]; then
    local valid
    valid=$(python3 -c "
import json, time
d = json.load(open('$f'))
# refresh 60s before actual expiry to avoid race conditions mid-call
print('yes' if time.time() < d['issuedAt'] + d['expiresIn'] - 60 else 'no')
" 2>/dev/null || echo no)
    [[ "$valid" == "yes" ]] || do_login "$identity" >/dev/null
  else
    do_login "$identity" >/dev/null
  fi
  python3 -c "import json; print(json.load(open('$f'))['jwtToken'])"
}

do_call() {
  local base="$1" identity="$2" method="$3" path="$4" body="${5:-}"
  local tok; tok=$(cmd_token "$identity")
  local args=(-sk -m 30 -X "$method" "${base}${path}" -H "Authorization: Bearer $tok")
  if [[ -n "$body" ]]; then
    args+=(-H "Content-Type: application/json" -d "$body")
  fi
  local tmp; tmp=$(mktemp)
  local code; code=$(curl "${args[@]}" -o "$tmp" -w "%{http_code}")
  cat "$tmp"
  echo
  rm -f "$tmp"
  [[ "$code" -lt 400 ]] || { echo "HTTP $code" >&2; return 1; }
}

cmd_call() {
  local identity="${1:?identity required (sa|user)}" method="${2:?METHOD required}" path="${3:?path required}" body="${4:-}"
  do_call "$API_BASE" "$identity" "$method" "$path" "$body"
}

cmd_call_auth() {
  local identity="${1:?identity required (sa|user)}" method="${2:?METHOD required}" path="${3:?path required}" body="${4:-}"
  do_call "$AUTH_BASE" "$identity" "$method" "$path" "$body"
}

cmd_check() {
  local ok=1
  for pair in "auth:$AUTH_BASE/openapi.json" "api:$API_BASE/openapi.json"; do
    local name="${pair%%:*}" url="${pair#*:}" code
    code=$(curl -sk -m 5 -o /dev/null -w "%{http_code}" "$url" || echo "000")
    if [[ "$code" == "200" ]]; then
      echo "$name: OK ($url)"
    else
      echo "$name: UNREACHABLE ($url, HTTP $code)"
      ok=0
    fi
  done
  [[ "$ok" == "1" ]] || { echo "One or more Asato APIs are unreachable. Run the aib-debug skill." >&2; exit 1; }
}

cmd_spec() {
  local which="${1:?spec required (auth|api)}" url out
  case "$which" in
    auth) url="$AUTH_BASE/openapi.json" ;;
    api)  url="$API_BASE/openapi.json" ;;
    *) echo "spec must be 'auth' or 'api', got: $which" >&2; exit 2 ;;
  esac
  out="$CACHE_DIR/openapi-$which.json"
  curl -sk -m 20 "$url" -o "$out"
  echo "$out"
}

main() {
  local cmd="${1:-}"; shift || true
  case "$cmd" in
    check)     cmd_check "$@" ;;
    login)     cmd_login "$@" ;;
    token)     cmd_token "$@" ;;
    call)      cmd_call "$@" ;;
    call-auth) cmd_call_auth "$@" ;;
    spec)      cmd_spec "$@" ;;
    *) usage; exit 2 ;;
  esac
}

main "$@"
